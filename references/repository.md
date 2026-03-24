# Repository Pattern Reference

## Table of Contents

1. [What is a Repository](#1-what-is-a-repository)
2. [Interface Definition](#2-interface-definition)
3. [Implementation](#3-implementation)
4. [Object Conversion](#4-object-conversion)
5. [Query Patterns](#5-query-patterns)
6. [Best Practices](#6-best-practices)

---

## 1. What is a Repository

A Repository:
- Mediates between domain and persistence
- Provides collection-like interface
- Hides persistence details
- Works with aggregates

### Key Principles

| Principle | Description |
|-----------|-------------|
| Collection semantics | Treat as in-memory collection |
| Aggregate focused | One repository per aggregate |
| Interface in Domain | Domain defines, Infrastructure implements |
| No business logic | Only persistence operations |

---

## 2. Interface Definition

### Location

**Domain Layer** - Define interface here

```
domain/
└── {domain}/
    └── adapter/
        └── repository/
            └── I{Domain}Repository.java
```

### Template

```java
/**
 * {Domain} Repository Interface
 * 
 * Provides persistence operations for {Domain}Aggregate.
 * Defined in Domain layer, implemented in Infrastructure.
 */
public interface I{Domain}Repository {

    // ==================== Single Operations ====================
    
    /**
     * Find by ID
     */
    {Domain}Aggregate findById(Long id);
    
    /**
     * Find by business ID
     */
    {Domain}Aggregate findByBizId(String bizId);
    
    /**
     * Save (create)
     */
    void save({Domain}Aggregate aggregate);
    
    /**
     * Update
     */
    void update({Domain}Aggregate aggregate);
    
    /**
     * Delete
     */
    void delete(Long id);

    // ==================== Batch Operations ====================
    
    /**
     * Batch save
     */
    void batchSave(List<{Domain}Aggregate> aggregates);
    
    /**
     * Find by IDs
     */
    List<{Domain}Aggregate> findByIds(List<Long> ids);

    // ==================== Query Operations ====================
    
    /**
     * Find by condition
     */
    List<{Domain}Aggregate> findByCondition({Query}Entity query);
    
    /**
     * Paginated query
     */
    PageResult<{Domain}Aggregate> findPage({Query}Entity query, int page, int size);
    
    /**
     * Count
     */
    long count({Query}Entity query);
}
```

### Complete Example

```java
/**
 * Order Repository Interface
 */
public interface IOrderRepository {
    
    // Single operations
    OrderAggregate findById(Long id);
    OrderAggregate findByOrderId(String orderId);
    void save(OrderAggregate aggregate);
    void update(OrderAggregate aggregate);
    void delete(Long id);
    
    // Query operations
    List<OrderAggregate> findByUserId(Long userId);
    List<OrderAggregate> findByStatus(OrderStatusEnum status);
    List<OrderAggregate> findPendingOrders();
    PageResult<OrderAggregate> findPage(OrderQuery query, int page, int size);
    
    // Existence check
    boolean existsByOrderId(String orderId);
}
```

---

## 3. Implementation

### Location

**Infrastructure Layer** - Implement here

```
infrastructure/
└── adapter/
    └── repository/
        └── {Domain}RepositoryImpl.java
```

### Template

```java
/**
 * {Domain} Repository Implementation
 */
@Slf4j
@Repository
public class {Domain}RepositoryImpl implements I{Domain}Repository {

    @Resource
    private I{Domain}Dao {domain}Dao;
    
    @Resource
    private I{Item}Dao itemDao;

    @Override
    public {Domain}Aggregate findById(Long id) {
        // 1. Query main table
        {PO} po = {domain}Dao.selectById(id);
        if (po == null) {
            return null;
        }
        
        // 2. Query related tables
        List<{ItemPO}> itemPOs = itemDao.selectByMainId(id);
        
        // 3. Convert to aggregate
        return toAggregate(po, itemPOs);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void save({Domain}Aggregate aggregate) {
        // 1. Save main table
        {PO} po = toMainPO(aggregate);
        {domain}Dao.insert(po);
        
        // 2. Save related tables
        for ({Item}Entity item : aggregate.getItems()) {
            {ItemPO} itemPO = toItemPO(item, po.getId());
            itemDao.insert(itemPO);
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void update({Domain}Aggregate aggregate) {
        // 1. Update main table
        {PO} po = toMainPO(aggregate);
        int count = {domain}Dao.update(po);
        if (count != 1) {
            throw new BusinessException("Update failed, record not found");
        }
        
        // 2. Update related tables (strategy depends on requirements)
        // Option A: Delete and re-insert
        // Option B: Diff and update
    }

    // ==================== Conversion Methods ====================
    
    private {Domain}Aggregate toAggregate({PO} po, List<{ItemPO}> itemPOs) {
        return {Domain}Aggregate.builder()
            .root(toEntity(po))
            .items(toItems(itemPOs))
            .build();
    }
    
    private {Domain}Entity toEntity({PO} po) {
        return {Domain}Entity.builder()
            .id(po.getId())
            .bizId(po.getBizId())
            .status(StatusEnum.valueOf(po.getStatus()))
            .build();
    }
    
    private {PO} toMainPO({Domain}Aggregate aggregate) {
        {PO}.Builder builder = {PO}.builder()
            .bizId(aggregate.getBizId())
            .status(aggregate.getStatus().getCode());
        
        if (aggregate.getId() != null) {
            builder.id(aggregate.getId());
        }
        
        return builder.build();
    }
}
```

### Complete Example

```java
@Slf4j
@Repository
public class OrderRepositoryImpl implements IOrderRepository {

    @Resource
    private IOrderDao orderDao;
    
    @Resource
    private IOrderItemDao orderItemDao;
    
    @Resource
    private IAddressDao addressDao;

    @Override
    public OrderAggregate findById(Long id) {
        OrderPO orderPO = orderDao.selectById(id);
        if (orderPO == null) {
            return null;
        }
        
        List<OrderItemPO> itemPOs = orderItemDao.selectByOrderId(id);
        AddressPO addressPO = addressDao.selectByOrderId(id);
        
        return toAggregate(orderPO, itemPOs, addressPO);
    }

    @Override
    public OrderAggregate findByOrderId(String orderId) {
        OrderPO orderPO = orderDao.selectByOrderId(orderId);
        if (orderPO == null) {
            return null;
        }
        return findById(orderPO.getId());
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void save(OrderAggregate aggregate) {
        // Save order
        OrderPO orderPO = toOrderPO(aggregate);
        orderDao.insert(orderPO);
        
        // Save items
        for (OrderItemEntity item : aggregate.getItems()) {
            OrderItemPO itemPO = toItemPO(item, orderPO.getId());
            orderItemDao.insert(itemPO);
        }
        
        // Save address
        if (aggregate.getShippingAddress() != null) {
            AddressPO addressPO = toAddressPO(
                aggregate.getShippingAddress(), 
                orderPO.getId()
            );
            addressDao.insert(addressPO);
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void update(OrderAggregate aggregate) {
        OrderPO orderPO = toOrderPO(aggregate);
        int count = orderDao.update(orderPO);
        if (count != 1) {
            throw new BusinessException("Order not found: " + aggregate.getOrderId());
        }
    }

    @Override
    public List<OrderAggregate> findByUserId(Long userId) {
        List<OrderPO> orderPOs = orderDao.selectByUserId(userId);
        return orderPOs.stream()
            .map(po -> findById(po.getId()))
            .collect(Collectors.toList());
    }

    @Override
    public PageResult<OrderAggregate> findPage(OrderQuery query, int page, int size) {
        int offset = (page - 1) * size;
        List<OrderPO> orderPOs = orderDao.selectPage(query, offset, size);
        long total = orderDao.count(query);
        
        List<OrderAggregate> aggregates = orderPOs.stream()
            .map(po -> findById(po.getId()))
            .collect(Collectors.toList());
        
        return PageResult.of(aggregates, total, page, size);
    }

    // ==================== Conversions ====================
    
    private OrderAggregate toAggregate(OrderPO orderPO, 
                                        List<OrderItemPO> itemPOs,
                                        AddressPO addressPO) {
        return OrderAggregate.builder()
            .order(toOrderEntity(orderPO))
            .items(toItemEntities(itemPOs))
            .shippingAddress(addressPO != null ? toAddressVO(addressPO) : null)
            .build();
    }
    
    private OrderEntity toOrderEntity(OrderPO po) {
        return OrderEntity.builder()
            .id(po.getId())
            .orderId(po.getOrderId())
            .userId(po.getUserId())
            .status(OrderStatusEnum.valueOf(po.getStatus()))
            .totalAmount(po.getTotalAmount())
            .createdAt(po.getCreatedAt())
            .build();
    }
    
    private OrderPO toOrderPO(OrderAggregate aggregate) {
        OrderEntity order = aggregate.getOrder();
        return OrderPO.builder()
            .id(order.getId())
            .orderId(order.getOrderId())
            .userId(order.getUserId())
            .status(order.getStatus().getCode())
            .totalAmount(order.getTotalAmount())
            .build();
    }
}
```

---

## 4. Object Conversion

### Conversion Direction

```
Domain Object (Aggregate/Entity/VO)
          ↕
Persistence Object (PO)
```

### Rules

| From | To | Where |
|------|-----|-------|
| Aggregate | PO | Repository.save() |
| PO | Aggregate | Repository.findById() |
| Entity | PO | Private helper |
| PO | Entity | Private helper |

### Never

- ❌ Return PO from Repository
- ❌ Pass PO to Domain Service
- ❌ Mix PO and Entity in business logic

---

## 5. Query Patterns

### Specification Pattern

```java
// Query object
@Data
@Builder
public class OrderQuery {
    private Long userId;
    private OrderStatusEnum status;
    private LocalDateTime startTime;
    private LocalDateTime endTime;
}

// Repository
List<OrderAggregate> findByCondition(OrderQuery query);
```

### Pagination

```java
@Getter
public class PageResult<T> {
    private final List<T> data;
    private final long total;
    private final int page;
    private final int size;
    private final int totalPages;
    
    public static <T> PageResult<T> of(List<T> data, long total, int page, int size) {
        return new PageResult<>(data, total, page, size, (int) Math.ceil((double) total / size));
    }
}
```

---

## 6. Best Practices

### Do

```java
// ✅ Interface in Domain
public interface IOrderRepository {
    OrderAggregate findById(Long id);
}

// ✅ Implementation in Infrastructure
@Repository
public class OrderRepositoryImpl implements IOrderRepository { }

// ✅ Work with aggregates
void save(OrderAggregate aggregate);

// ✅ Use meaningful names
List<OrderAggregate> findPendingOrders();
```

### Don't

```java
// ❌ Don't return PO
OrderPO findById(Long id);

// ❌ Don't put business logic
public void save(OrderAggregate aggregate) {
    if (aggregate.getTotal() > 10000) { // ❌ Business logic
        throw new BusinessException("Too large");
    }
}

// ❌ Don't expose DAO directly
IOrderDao getOrderDao();

// ❌ Don't use generic methods
<T> T find(String query);  // Too generic
```