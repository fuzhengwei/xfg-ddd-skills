# Entity Design Reference

## Table of Contents

1. [What is an Entity](#1-what-is-an-entity)
2. [Entity vs Value Object](#2-entity-vs-value-object)
3. [Rich Domain Model](#3-rich-domain-model)
4. [Entity Template](#4-entity-template)
5. [Behavior Methods](#5-behavior-methods)
6. [Factory Methods](#6-factory-methods)
7. [Best Practices](#7-best-practices)

---

## 1. What is an Entity

An Entity is a domain object with:
- **Unique identity** (distinguishes it from other entities)
- **Lifecycle** (created, modified, eventually deleted)
- **State** (properties that can change)
- **Behavior** (methods that operate on its state)

### Key Characteristics

| Characteristic | Description |
|---------------|-------------|
| Identity | Has a unique identifier (id, orderId, etc.) |
| Equality | Compared by identity, not properties |
| Mutability | State can change over time |
| Continuity | Same identity throughout lifecycle |

---

## 2. Entity vs Value Object

| Aspect | Entity | Value Object |
|--------|--------|--------------|
| Identity | Has unique ID | No identity |
| Equality | By identity | By properties |
| Mutability | Mutable | Immutable |
| Lifecycle | Has lifecycle | No lifecycle |
| Example | Order, User | Money, Address |

```java
// Entity: Has identity
OrderEntity order1 = new OrderEntity(1L, "ORD-001");
OrderEntity order2 = new OrderEntity(1L, "ORD-002");
order1.equals(order2); // true - same ID

// Value Object: No identity
MoneyVO money1 = MoneyVO.of(BigDecimal.TEN, "USD");
MoneyVO money2 = MoneyVO.of(BigDecimal.TEN, "USD");
money1.equals(money2); // true - same properties
```

---

## 3. Rich Domain Model

### Anemic Model (Avoid)

```java
// ❌ Anemic: Data only, no behavior
@Data
public class OrderEntity {
    private Long id;
    private OrderStatus status;
    private BigDecimal amount;
}

// Logic in service
@Service
public class OrderService {
    public void pay(OrderEntity order) {
        if (order.getStatus() != PENDING) {
            throw new BusinessException("Cannot pay");
        }
        order.setStatus(PAID);
    }
}
```

### Rich Model (Recommended)

```java
// ✅ Rich: Data + behavior
@Data
@Builder
public class OrderEntity {
    private Long id;
    private OrderStatus status;
    private BigDecimal amount;
    
    // Behavior in entity
    public void pay() {
        if (status != PENDING) {
            throw new BusinessException("Cannot pay");
        }
        this.status = PAID;
    }
    
    public boolean canPay() {
        return status == PENDING;
    }
}
```

### Why Rich Model?

- **Encapsulation**: Logic close to data
- **Reusability**: Same logic everywhere
- **Maintainability**: Single source of truth
- **Testability**: Easy to unit test

---

## 4. Entity Template

### Basic Template

```java
/**
 * {Domain} Entity
 * 
 * Represents a {business concept} in the domain.
 */
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class {Domain}Entity {

    /** Unique identifier */
    private Long id;
    
    /** Business identifier */
    private String bizId;
    
    /** Current status */
    private {Domain}StatusEnum status;
    
    /** Business properties */
    private String property1;
    private BigDecimal property2;

    // ==================== Behavior Methods ====================
    
    /**
     * Validate entity state
     */
    public void validate() {
        if (property1 == null || property1.isEmpty()) {
            throw new IllegalArgumentException("property1 required");
        }
    }
    
    /**
     * Check if operation is allowed
     */
    public boolean canOperate() {
        return status == {Domain}StatusEnum.ACTIVE;
    }
    
    /**
     * Change state
     */
    public void activate() {
        if (status != {Domain}StatusEnum.INIT) {
            throw new BusinessException("Only INIT can be activated");
        }
        this.status = {Domain}StatusEnum.ACTIVE;
    }
}
```

### Complete Example

```java
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class OrderEntity {

    private Long id;
    private String orderId;
    private Long userId;
    private OrderStatusEnum status;
    private BigDecimal amount;
    private LocalDateTime createdAt;

    // ==================== Validation ====================
    
    public void validate() {
        if (orderId == null || orderId.isEmpty()) {
            throw new IllegalArgumentException("orderId required");
        }
        if (amount == null || amount.compareTo(BigDecimal.ZERO) <= 0) {
            throw new IllegalArgumentException("amount must be positive");
        }
    }

    // ==================== State Queries ====================
    
    public boolean canPay() {
        return status == OrderStatusEnum.PENDING;
    }
    
    public boolean canCancel() {
        return status == OrderStatusEnum.PENDING 
            || status == OrderStatusEnum.PAID;
    }
    
    public boolean isPaid() {
        return status == OrderStatusEnum.PAID;
    }

    // ==================== State Changes ====================
    
    public void pay() {
        if (!canPay()) {
            throw new BusinessException("Order cannot be paid");
        }
        this.status = OrderStatusEnum.PAID;
    }
    
    public void cancel() {
        if (!canCancel()) {
            throw new BusinessException("Order cannot be cancelled");
        }
        this.status = OrderStatusEnum.CANCELLED;
    }
    
    public void deliver() {
        if (status != OrderStatusEnum.PAID) {
            throw new BusinessException("Only paid orders can be delivered");
        }
        this.status = OrderStatusEnum.DELIVERED;
    }

    // ==================== Conversions ====================
    
    public OrderVO toVO() {
        return OrderVO.builder()
            .orderId(orderId)
            .status(status)
            .amount(amount)
            .build();
    }
}
```

---

## 5. Behavior Methods

### Method Categories

| Category | Purpose | Naming |
|----------|---------|--------|
| Validation | Check state validity | `validate()` |
| Query | Check if action allowed | `canXxx()`, `isXxx()` |
| Command | Change state | `activate()`, `pay()` |
| Conversion | Transform to other types | `toVO()`, `toEntity()` |
| Business | Domain logic | `calculateTotal()` |

### Validation Methods

```java
// Throw exception if invalid
public void validate() {
    if (amount == null) {
        throw new IllegalArgumentException("amount required");
    }
}

// Return boolean
public boolean isValid() {
    return amount != null && amount.compareTo(BigDecimal.ZERO) > 0;
}
```

### Query Methods

```java
// State queries
public boolean canPay() { return status == PENDING; }
public boolean canCancel() { return status != DELIVERED; }
public boolean isPaid() { return status == PAID; }
public boolean isActive() { return status == ACTIVE; }
```

### Command Methods

```java
// State changes with validation
public void pay() {
    if (!canPay()) throw new BusinessException("Cannot pay");
    this.status = PAID;
    this.paidAt = LocalDateTime.now();
}

public void cancel(String reason) {
    if (!canCancel()) throw new BusinessException("Cannot cancel");
    this.status = CANCELLED;
    this.cancelReason = reason;
}
```

---

## 6. Factory Methods

### Static Factory in Entity

```java
public class OrderEntity {
    // Private constructor
    private OrderEntity() {}
    
    // Factory method
    public static OrderEntity create(String orderId, BigDecimal amount) {
        OrderEntity entity = new OrderEntity();
        entity.orderId = orderId;
        entity.amount = amount;
        entity.status = OrderStatusEnum.PENDING;
        entity.createdAt = LocalDateTime.now();
        entity.validate();
        return entity;
    }
    
    // Reconstruct from persistence
    public static OrderEntity from(OrderPO po) {
        OrderEntity entity = new OrderEntity();
        entity.id = po.getId();
        entity.orderId = po.getOrderId();
        entity.status = OrderStatusEnum.valueOf(po.getStatus());
        entity.amount = po.getAmount();
        return entity;
    }
}
```

---

## 7. Best Practices

### Do

```java
// ✅ Keep behavior in entity
public void pay() { /* ... */ }

// ✅ Use meaningful names
public boolean canBePaidBy(UserEntity user) { /* ... */ }

// ✅ Validate before state change
public void activate() {
    validate();
    this.status = ACTIVE;
}

// ✅ Make invariants explicit
public void addItem(OrderItemEntity item) {
    if (items.size() >= MAX_ITEMS) {
        throw new BusinessException("Max items reached");
    }
    items.add(item);
}
```

### Don't

```java
// ❌ Don't inject services
@Resource
private IOrderRepository repository; // ❌

// ❌ Don't call external systems
public void pay() {
    paymentService.process(); // ❌
}

// ❌ Don't use anemic model
// All logic in OrderService, none in OrderEntity

// ❌ Don't expose setters freely
public void setStatus(OrderStatusEnum status) { // ❌
    this.status = status;
}
```