# Aggregate Design Reference

## Table of Contents

1. [What is an Aggregate](#1-what-is-an-aggregate)
2. [Aggregate Root](#2-aggregate-root)
3. [Design Principles](#3-design-principals)
4. [Aggregate Template](#4-aggregate-template)
5. [Transaction Boundary](#5-transaction-boundary)
6. [Aggregate References](#6-aggregate-references)
7. [Best Practices](#7-best-practices)

---

## 1. What is an Aggregate

An Aggregate is a cluster of domain objects that:
- Are treated as a single unit
- Have a defined consistency boundary
- Share a common lifecycle

### Visual Representation

```
┌─────────────────────────────────────────────────────────────┐
│                     Order Aggregate                         │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐  │
│  │              Order (Root Entity)                     │  │
│  │  - orderId                                          │  │
│  │  - status                                           │  │
│  │  - totalAmount                                      │  │
│  └─────────────────────────────────────────────────────┘  │
│                          │                                  │
│                          │ owns                             │
│                          ▼                                  │
│  ┌─────────────────┐  ┌─────────────────┐                  │
│  │  OrderItem 1    │  │  OrderItem 2    │                  │
│  │  - productId    │  │  - productId    │                  │
│  │  - quantity     │  │  - quantity     │                  │
│  │  - price        │  │  - price        │                  │
│  └─────────────────┘  └─────────────────┘                  │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐  │
│  │           ShippingAddress (Value Object)            │  │
│  └─────────────────────────────────────────────────────┘  │
│                                                             │
│  Transaction Boundary: All saved together atomically       │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Aggregate Root

The Aggregate Root is:
- The only entry point to the aggregate
- Responsible for maintaining invariants
- The entity that external objects reference

### Rules

1. **Only root has global identity** - Other entities have local identity
2. **Access only through root** - Cannot modify internal entities directly
3. **Root maintains consistency** - All invariants checked by root

```java
// ✅ Correct: Access through root
OrderAggregate order = orderRepository.findById(1L);
order.addItem(item);  // Root controls addition

// ❌ Wrong: Direct access to internal entity
OrderItemEntity item = order.getItems().get(0);
item.setQuantity(100);  // Bypasses root validation
```

---

## 3. Design Principles

### Keep Aggregates Small

```java
// ❌ Too large - too many objects in one transaction
OrderAggregate {
    Order order;
    List<OrderItem> items;        // 100 items
    User user;                    // Full user object
    List<Payment> payments;       // Payment history
    List<Shipment> shipments;     // Shipment history
    Address billingAddress;
    Address shippingAddress;
}

// ✅ Small - focused on essential data
OrderAggregate {
    Order order;                  // Root
    List<OrderItem> items;        // Current items only
    ShippingAddressVO address;    // Value object
    UserIdVO userId;              // Reference to user
}
```

### Reference Other Aggregates by Identity

```java
// ❌ Wrong: Reference by object
@Data
public class OrderAggregate {
    private UserAggregate user;  // Full aggregate
}

// ✅ Correct: Reference by identity
@Data
public class OrderAggregate {
    private Long userId;         // Just the ID
    // or
    private UserIdVO userId;     // Value object with ID
}
```

---

## 4. Aggregate Template

### Basic Template

```java
/**
 * {Domain} Aggregate
 * 
 * Consistency boundary for {business concept}.
 */
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class {Domain}Aggregate {

    /** Root entity */
    private {Domain}Entity root;
    
    /** Related entities */
    private List<{Item}Entity> items;
    
    /** Value objects */
    private {Value}VO valueObject;

    // ==================== Root Access ====================
    
    public Long getId() {
        return root != null ? root.getId() : null;
    }
    
    public String getBizId() {
        return root != null ? root.getBizId() : null;
    }

    // ==================== Invariants ====================
    
    public void validate() {
        if (root == null) {
            throw new IllegalArgumentException("Root required");
        }
        root.validate();
    }

    // ==================== Factory Methods ====================
    
    public static {Domain}Aggregate create(CreateCommand cmd) {
        {Domain}Aggregate aggregate = {Domain}Aggregate.builder()
            .root({Domain}Entity.create(cmd))
            .items(new ArrayList<>())
            .build();
        aggregate.validate();
        return aggregate;
    }
}
```

### Complete Example

```java
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class OrderAggregate {

    private OrderEntity order;
    private List<OrderItemEntity> items;
    private ShippingAddressVO shippingAddress;

    // ==================== Root Access ====================
    
    public Long getOrderId() {
        return order != null ? order.getId() : null;
    }
    
    public String getOrderNo() {
        return order != null ? order.getOrderNo() : null;
    }

    // ==================== Business Operations ====================
    
    /**
     * Create new order
     */
    public static OrderAggregate create(String orderNo, Long userId) {
        OrderAggregate aggregate = OrderAggregate.builder()
            .order(OrderEntity.builder()
                .orderNo(orderNo)
                .userId(userId)
                .status(OrderStatusEnum.PENDING)
                .createdAt(LocalDateTime.now())
                .build())
            .items(new ArrayList<>())
            .build();
        aggregate.validate();
        return aggregate;
    }
    
    /**
     * Add item (root controls)
     */
    public void addItem(OrderItemEntity item) {
        // Invariant: Max 100 items
        if (items.size() >= 100) {
            throw new BusinessException("Max items reached");
        }
        // Invariant: No duplicate products
        boolean exists = items.stream()
            .anyMatch(i -> i.getProductId().equals(item.getProductId()));
        if (exists) {
            throw new BusinessException("Product already in order");
        }
        items.add(item);
        recalculateTotal();
    }
    
    /**
     * Remove item
     */
    public void removeItem(Long itemId) {
        items.removeIf(i -> i.getId().equals(itemId));
        recalculateTotal();
    }
    
    /**
     * Pay order
     */
    public void pay() {
        if (order.getStatus() != OrderStatusEnum.PENDING) {
            throw new BusinessException("Only pending orders can be paid");
        }
        if (items.isEmpty()) {
            throw new BusinessException("Cannot pay empty order");
        }
        order.pay();
    }
    
    /**
     * Cancel order
     */
    public void cancel(String reason) {
        if (order.getStatus() == OrderStatusEnum.DELIVERED) {
            throw new BusinessException("Cannot cancel delivered order");
        }
        order.cancel(reason);
    }

    // ==================== Queries ====================
    
    public BigDecimal getTotalAmount() {
        return order != null ? order.getTotalAmount() : BigDecimal.ZERO;
    }
    
    public int getItemCount() {
        return items != null ? items.size() : 0;
    }
    
    public boolean canPay() {
        return order != null && order.canPay() && !items.isEmpty();
    }

    // ==================== Private Helpers ====================
    
    private void recalculateTotal() {
        BigDecimal total = items.stream()
            .map(i -> i.getPrice().multiply(BigDecimal.valueOf(i.getQuantity())))
            .reduce(BigDecimal.ZERO, BigDecimal::add);
        order.setTotalAmount(total);
    }
    
    private void validate() {
        if (order == null) {
            throw new IllegalArgumentException("Order required");
        }
        order.validate();
    }
}
```

---

## 5. Transaction Boundary

### Inside Aggregate: Strong Consistency

```java
@Repository
public class OrderRepositoryImpl implements IOrderRepository {
    
    @Transactional
    @Override
    public void save(OrderAggregate aggregate) {
        // All these succeed or fail together
        orderDao.insert(aggregate.getOrder());
        
        for (OrderItemEntity item : aggregate.getItems()) {
            itemDao.insert(item);
        }
        
        if (aggregate.getShippingAddress() != null) {
            addressDao.insert(aggregate.getShippingAddress());
        }
    }
}
```

### Between Aggregates: Eventual Consistency

```java
@Service
public class OrderService {
    
    @Transactional
    public void createOrder(CreateOrderCommand cmd) {
        // Save order aggregate
        OrderAggregate order = OrderAggregate.create(cmd);
        orderRepository.save(order);
        
        // Publish event for other aggregates
        eventPublisher.publish(new OrderCreatedEvent(order.getOrderId()));
        
        // Inventory will handle in its own transaction
    }
}
```

---

## 6. Aggregate References

### By ID

```java
@Data
public class OrderAggregate {
    private OrderEntity order;
    private Long userId;  // Reference to UserAggregate
}

// Load separately when needed
OrderAggregate order = orderRepository.findById(orderId);
UserAggregate user = userRepository.findById(order.getUserId());
```

### By Value Object

```java
@Getter
public class UserIdVO {
    private final Long id;
    
    public static UserIdVO of(Long id) {
        return new UserIdVO(id);
    }
}

@Data
public class OrderAggregate {
    private OrderEntity order;
    private UserIdVO userId;  // Value object reference
}
```

---

## 7. Best Practices

### Do

```java
// ✅ Keep aggregates small
OrderAggregate { order, items, address }

// ✅ Reference by ID
private Long userId;

// ✅ Control through root
public void addItem(OrderItemEntity item) {
    validateItem(item);
    items.add(item);
}

// ✅ Maintain invariants
private void validateItem(OrderItemEntity item) {
    if (items.size() >= MAX_ITEMS) {
        throw new BusinessException("Max reached");
    }
}
```

### Don't

```java
// ❌ Don't make aggregates too large
OrderAggregate { order, items, user, payments, shipments, ... }

// ❌ Don't reference other aggregates by object
private UserAggregate user;

// ❌ Don't expose internal collection
public List<OrderItemEntity> getItems() {
    return items;  // Caller can modify directly
}

// ✅ Return unmodifiable copy
public List<OrderItemEntity> getItems() {
    return Collections.unmodifiableList(items);
}
```