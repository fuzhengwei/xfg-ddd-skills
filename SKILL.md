---
name: ddd-skills
version: 2.0.0
description: "Use this skill whenever you need to design or implement software using Domain-Driven Design (DDD) with Hexagonal Architecture. Triggers include 'DDD', 'domain-driven design', 'hexagonal architecture', 'ports and adapters', '六边形架构', '领域驱动设计'. Use when creating Entity, Aggregate, Value Object, Repository, Domain Service, or implementing business logic. Also use when setting up project structure for DDD, implementing rich domain models, or need guidance on layer responsibilities (Trigger/API/Case/Domain/Infrastructure). Do not use for simple CRUD applications, microservices without domain complexity, or general Spring Boot patterns without DDD."
author: xiaofuge
license: MIT
triggers:
  - "DDD"
  - "六边形架构"
  - "domain-driven design"
  - "领域驱动设计"
  - "ports and adapters"
  - "创建 Entity"
  - "创建聚合根"
metadata:
  openclaw:
    emoji: "🏗️"
---
# DDD Hexagonal Architecture

Design and implement software using Domain-Driven Design with Hexagonal Architecture. This skill provides patterns, templates, and best practices for building maintainable domain-centric applications.

## Quick Reference

| Task | Reference |
|------|-----------|
| Architecture overview | [references/architecture.md](references/architecture.md) |
| Entity design | [references/entity.md](references/entity.md) |
| Aggregate design | [references/aggregate.md](references/aggregate.md) |
| Value Object design | [references/value-object.md](references/value-object.md) |
| Repository pattern | [references/repository.md](references/repository.md) |
| Port & Adapter | [references/port-adapter.md](references/port-adapter.md) |
| Domain Service | [references/domain-service.md](references/domain-service.md) |
| Case layer orchestration | [references/case-layer.md](references/case-layer.md) |
| Trigger layer | [references/trigger-layer.md](references/trigger-layer.md) |
| Domain Service | [references/domain-service.md](references/domain-service.md) |
| **Infrastructure layer** | [references/infrastructure-layer.md](references/infrastructure-layer.md) |
| Project structure | [references/project-structure.md](references/project-structure.md) |
| Naming conventions | [references/naming.md](references/naming.md) |
| Docker Images | [references/docker-images.md](references/docker-images.md) |

## Architecture Layers

```
┌─────────────────────────────────────────────────────────────┐
│                     Trigger Layer                            │
│         (HTTP Controller / MQ Listener / Job)               │
└─────────────────────────┬───────────────────────────────────┘
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                       API Layer                              │
│              (DTO / Request / Response)                     │
└─────────────────────────┬───────────────────────────────────┘
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                      Case Layer                              │
│            (Orchestration / Business Flow)                  │
└─────────────────────────┬───────────────────────────────────┘
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                     Domain Layer                             │
│        (Entity / Aggregate / VO / Domain Service)           │
└─────────────────────────┬───────────────────────────────────┘
                          ▲
┌─────────────────────────────────────────────────────────────┐
│                  Infrastructure Layer                        │
│      (Repository Impl / Port Adapter / DAO / PO)            │
└─────────────────────────────────────────────────────────────┘
```

**Dependency Rule**: `Trigger → API → Case → Domain ← Infrastructure`

## Quick Templates

### Entity (Rich Domain Model)

```java
@Data @Builder
public class OrderEntity {
    private Long id;
    private String orderId;
    private OrderStatus status;
    private BigDecimal amount;
    
    // Rich behavior methods
    public boolean canPay() {
        return status == OrderStatus.PENDING;
    }
    
    public void pay() {
        if (!canPay()) throw new BusinessException("Cannot pay");
        this.status = OrderStatus.PAID;
    }
    
    public void validate() {
        if (amount == null || amount.compareTo(BigDecimal.ZERO) <= 0) {
            throw new IllegalArgumentException("Invalid amount");
        }
    }
}
```

### Aggregate

```java
@Data @Builder
public class OrderAggregate {
    private OrderEntity order;           // Root
    private List<OrderItemEntity> items; // Related entities
    private ShippingAddressVO address;   // Value object
    
    public void create() {
        order.validate();
        this.order.setStatus(OrderStatus.CREATED);
    }
    
    public BigDecimal totalAmount() {
        return items.stream()
            .map(OrderItemEntity::getPrice)
            .reduce(BigDecimal.ZERO, BigDecimal::add);
    }
}
```

### Value Object (Immutable)

```java
@Getter
public final class MoneyVO {
    private final BigDecimal amount;
    private final String currency;
    
    private MoneyVO(BigDecimal amount, String currency) {
        this.amount = amount;
        this.currency = currency;
    }
    
    public static MoneyVO of(BigDecimal amount, String currency) {
        return new MoneyVO(amount, currency);
    }
    
    public MoneyVO add(MoneyVO other) {
        return new MoneyVO(amount.add(other.amount), currency);
    }
}
```

### Repository Interface (Domain Layer)

```java
public interface IOrderRepository {
    OrderAggregate findById(Long id);
    OrderAggregate findByOrderId(String orderId);
    void save(OrderAggregate aggregate);
    void update(OrderAggregate aggregate);
}
```

### Repository Implementation (Infrastructure Layer)

```java
@Repository
public class OrderRepositoryImpl implements IOrderRepository {
    @Resource private IOrderDao orderDao;
    
    @Override
    @Transactional
    public void save(OrderAggregate aggregate) {
        OrderPO po = toPO(aggregate);
        orderDao.insert(po);
    }
    
    private OrderPO toPO(OrderAggregate aggregate) {
        // Convert domain object to persistence object
    }
}
```

### Port Interface (Domain Layer)

```java
public interface INotificationPort {
    void sendOrderCreated(OrderCreatedEvent event);
}
```

### Port Adapter (Infrastructure Layer)

```java
@Service
public class NotificationPortImpl implements INotificationPort {
    @Resource private RestTemplate restTemplate;
    
    @Override
    public void sendOrderCreated(OrderCreatedEvent event) {
        restTemplate.postForObject(url, event, Void.class);
    }
}
```

### Controller (Trigger Layer)

```java
@Slf4j
@RestController
@RequestMapping("/api/v1/orders/")
public class OrderController {
    @Resource private IOrderService orderService;
    
    @PostMapping("/create")
    public Response<OrderDTO> create(@RequestBody @Valid CreateOrderRequest request) {
        return orderService.create(request);
    }
}
```

## Core Principles

| Principle | Description |
|-----------|-------------|
| **Dependency Inversion** | Domain defines interfaces, Infrastructure implements |
| **Rich Domain Model** | Entity contains both data and behavior |
| **Aggregate Boundary** | Transaction consistency inside, eventual consistency outside |
| **Anti-Corruption Layer** | Use Port to isolate external systems |
| **Lightweight Trigger** | Trigger layer only routes requests, no business logic |

## When to Use DDD

**Use DDD when:**
- Complex business domain with rich rules
- Need to capture domain knowledge in code
- Long-lived project with evolving requirements
- Team needs shared domain language

**Don't use DDD when:**
- Simple CRUD operations
- Prototype or throwaway code
- Domain logic is trivial
- Team unfamiliar with DDD concepts

## Example Projects

- [group-buy-market](file:///Users/fuzhengwei/Documents/project/ddd-demo/group-buy-market) - E-commerce domain
- [ai-mcp-gateway](file:///Users/fuzhengwei/Documents/project/ddd-demo/ai-mcp-gateway) - API gateway domain