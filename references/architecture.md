# DDD Architecture Reference

## Table of Contents

1. [Hexagonal Architecture Overview](#1-hexagonal-architecture-overview)
2. [Layer Responsibilities](#2-layer-responsibilities)
3. [Dependency Rules](#3-dependency-rules)
4. [Anti-Corruption Layer](#4-anti-corruption-layer)
5. [Bounded Context](#5-bounded-context)
6. [Transaction Boundaries](#6-transaction-boundaries)

---

## 1. Hexagonal Architecture Overview

Hexagonal Architecture (also called Ports and Adapters) isolates the domain from external concerns.

```
         ┌─────────────────────────────────────────────────────┐
         │                    Application                        │
         │  ┌───────────────────────────────────────────────┐  │
         │  │                    Ports                        │  │
         │  │  ┌─────────────────────────────────────────┐│  │
         │  │  │                                       ││  │
         │  │  │            Domain Core                 ││  │
         │  │  │         (Business Logic)               ││  │
         │  │  │                                       ││  │
         │  │  └─────────────────────────────────────────┘│  │
         │  │                    Ports                    │  │
         │  └───────────────────────────────────────────────┘  │
         └─────────────────────────────────────────────────────┘
                      ▲                           ▲
                      │                           │
         ┌────────────┴───────┐       ┌───────────┴────────┐
         │   Driving Adapters  │       │  Driven Adapters   │
         │   (Primary Ports)   │       │ (Secondary Ports)  │
         │  Controller/RPC     │       │  Repository/Port   │
         └────────────────────┘       └────────────────────┘
```

### Why Hexagonal?

- **Domain isolation**: Business logic independent of frameworks
- **Testability**: Easy to mock adapters for testing
- **Flexibility**: Swap infrastructure without changing domain
- **Maintainability**: Clear boundaries between layers

---

## 2. Layer Responsibilities

### Trigger Layer

**Purpose**: Entry points for external requests

**Contains**:
- HTTP Controllers
- MQ Listeners
- Scheduled Jobs
- RPC Providers

**Rules**:
- No business logic
- Only request routing and DTO conversion
- Calls Case or Domain layer

```java
@Slf4j
@RestController
public class OrderController {
    @Resource private IOrderService orderService;
    
    @PostMapping("/orders")
    public Response create(@RequestBody CreateOrderRequest request) {
        // Only routing, no business logic
        return orderService.create(request);
    }
}
```

### API Layer

**Purpose**: Define contracts and data structures

**Contains**:
- DTO classes (Request/Response)
- Interface definitions
- Error codes
- Validation annotations

**Rules**:
- No implementation logic
- Pure data structures
- Shared with external systems

```java
@Data
public class CreateOrderRequest {
    @NotBlank private String productId;
    @Min(1) private Integer quantity;
}
```

### Case Layer

**Purpose**: Orchestrate business workflows

**Contains**:
- Application services
- Workflow orchestration
- Transaction management
- Strategy routing

**Rules**:
- Coordinates multiple domain services
- No direct infrastructure calls
- Manages use case flow

```java
@Service
public class OrderCaseService {
    @Resource private IOrderService orderService;
    @Resource private IPaymentService paymentService;
    
    @Transactional
    public Result createAndPay(CreateOrderCommand cmd) {
        OrderAggregate order = orderService.create(cmd);
        paymentService.process(order);
        return Result.success(order);
    }
}
```

### Domain Layer

**Purpose**: Core business logic

**Contains**:
- Entities
- Aggregates
- Value Objects
- Domain Services
- Repository Interfaces
- Port Interfaces

**Rules**:
- No infrastructure dependencies
- Rich domain model (data + behavior)
- All business rules here

```java
// Entity with behavior
public class OrderEntity {
    private OrderStatus status;
    
    public void pay() {
        if (status != PENDING) throw new BusinessException("Invalid state");
        status = PAID;
    }
}
```

### Infrastructure Layer

**Purpose**: Technical implementations

**Contains**:
- Repository implementations
- Port adapters
- DAO/PO classes
- External service clients
- Configuration

**Rules**:
- Implements domain interfaces
- No business logic
- Handles technical concerns

```java
@Repository
public class OrderRepositoryImpl implements IOrderRepository {
    @Resource private OrderDao dao;
    
    @Override
    public void save(OrderAggregate aggregate) {
        dao.insert(toPO(aggregate));
    }
}
```

---

## 3. Dependency Rules

### Allowed Dependencies

```
Trigger → API → Case → Domain ← Infrastructure
                ↓            ↑
                └────────────┘
```

### Dependency Matrix

| From | Can depend on |
|------|--------------|
| Trigger | API, Case, Domain |
| API | Types |
| Case | API, Domain |
| Domain | Nothing (only interfaces) |
| Infrastructure | Domain (interfaces) |

### Critical Rule

**Domain layer must NOT depend on**:
- MyBatis, JPA, JDBC
- Spring Framework
- Redis, MQ clients
- HTTP clients
- Any infrastructure framework

**Instead**, Domain defines interfaces:
```java
// Domain layer
public interface IOrderRepository {
    void save(OrderAggregate aggregate);
}

// Infrastructure layer implements
@Repository
public class OrderRepositoryImpl implements IOrderRepository {
    // Uses MyBatis, Redis, etc.
}
```

---

## 4. Anti-Corruption Layer

### Purpose

Prevent external system changes from affecting domain model.

### Pattern

```
Domain ────calls────> Port Interface ────implemented by───> Port Adapter
  │                                                    │
  │                                                    ▼
  │                                              External System
  │                                              (HTTP/DB/MQ)
  ▼
No external dependencies
```

### Implementation

```java
// Domain Layer: Define Port
public interface IUserPort {
    boolean userExists(Long userId);
    UserInfoVO getUserInfo(Long userId);
}

// Infrastructure Layer: Implement Adapter
@Service
public class UserHttpPortImpl implements IUserPort {
    @Resource private RestTemplate restTemplate;
    
    @Override
    public boolean userExists(Long userId) {
        // Call external service
        // Convert DTO to domain object
        return restTemplate.getForObject(url, Boolean.class);
    }
}
```

### Benefits

- External DTO never enters domain
- Easy to mock for testing
- Can swap implementations
- Domain stays pure

---

## 5. Bounded Context

### Concept

Divide large system into independent contexts with clear boundaries.

```
┌─────────────────────────────────────────────────────────────┐
│                    System Boundary                          │
│  ┌─────────────────┐  ┌─────────────────┐                  │
│  │  Order Context  │  │ Inventory Ctx   │                  │
│  │  ┌───────────┐ │  │  ┌───────────┐ │                  │
│  │  │ Aggregate │ │  │  │ Aggregate │ │                  │
│  │  │ Service   │ │  │  │ Service   │ │                  │
│  │  └───────────┘ │  │  └───────────┘ │                  │
│  └────────┬────────┘  └────────┬────────┘                  │
│           │                    │                           │
│           └────────────────────┘                           │
│                  Context Map                                │
└─────────────────────────────────────────────────────────────┘
```

### Context Communication

Contexts communicate through:
- Domain Events
- Port interfaces
- Shared kernels (minimal)

```java
// Order context publishes event
eventPublisher.publish(new OrderCreatedEvent(orderId));

// Inventory context handles event
@EventListener
public void onOrderCreated(OrderCreatedEvent event) {
    inventoryService.reserve(event.getProducts());
}
```

---

## 6. Transaction Boundaries

### Inside Aggregate

All operations within an aggregate are atomic.

```java
@Transactional
public void save(OrderAggregate aggregate) {
    // All these succeed or fail together
    orderDao.insert(aggregate.getOrder());
    for (OrderItem item : aggregate.getItems()) {
        itemDao.insert(item);
    }
}
```

### Between Aggregates

Use eventual consistency for cross-aggregate operations.

```java
// Don't: One transaction across aggregates
@Transactional
public void process(OrderAggregate order, InventoryAggregate inventory) {
    orderRepository.save(order);      // ❌ Too large
    inventoryRepository.save(inventory);
}

// Do: Separate transactions with events
@Transactional
public void process(OrderAggregate order) {
    orderRepository.save(order);
    eventPublisher.publish(new OrderCreatedEvent(order));
}

// Inventory handles event in own transaction
@EventListener
@Transactional
public void handle(OrderCreatedEvent event) {
    inventoryService.reserve(event);
}
```

### Transaction Rules

| Scope | Consistency |
|-------|-------------|
| Inside Aggregate | ACID (strong) |
| Between Aggregates | Eventual |
| Between Contexts | Eventual |