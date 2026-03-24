# Case Layer - 业务编排层

## 概述

Case 层（用例层/编排层）是 DDD 六边形架构中的关键层，负责：
1. **分摊 Trigger 层压力**：将业务编排逻辑从 Controller/Listener 中移出
2. **串联 Domain 层**：组合调用多个 Domain Service、Repository、Port
3. **流程编排**：使用 Node 模式编排复杂业务流程

## 核心职责

```
Trigger 层 (HTTP/MQ/Job)
        │
        ▼
    Case 层 ← 业务编排、流程串联、结果封装
        │
        ▼
    Domain 层 (Entity/Aggregate/VO/Domain Service)
```

**Trigger 层只做三件事**：
1. 调用 Case Service
2. 封装请求参数
3. 封装响应结果

**Case 层负责**：
1. 编排业务流程
2. 调用多个 Domain Service
3. 处理事务边界
4. 组合多个领域能力

## 命名规范

```java
// 接口命名
public interface I{Domain}CaseService {}

// 实现类命名
@Service
public class {Domain}CaseServiceImpl implements I{Domain}CaseService {}

// 内部 Node 命名（复杂流程时使用）
@Service("{domain}{业务}Node")
public class {业务}Node extends AbstractCaseSupport {}

// Factory 命名（流程编排工厂）
@Service
public class Default{Domain}CaseFactory {}
```

## 包结构

```
{project}-case/
├── pom.xml
└── src/main/java/
    └── cn/{company}/cases/
        └── {domain}/
            ├── I{Domain}CaseService.java           # 接口
            ├── impl/
            │   ├── {Domain}CaseServiceImpl.java   # 简单流程实现
            │   └── {Domain}CaseServiceImpl.java    # 复杂流程：Node 编排
            ├── node/                                # 复杂流程节点
            │   ├── AbstractCaseSupport.java        # Node 基类
            │   ├── RootNode.java                   # 开始节点
            │   ├── {业务}Node.java                  # 业务节点
            │   └── EndNode.java                    # 结束节点
            └── factory/
                └── Default{Domain}CaseFactory.java # 流程工厂
```

## 简单 Case 实现

适用于单一业务流程，不需要复杂编排的场景：

```java
/**
 * 订单用例服务接口
 */
public interface IOrderCaseService {

    /**
     * 创建订单
     */
    Response<OrderDTO> createOrder(CreateOrderRequest request);
    
    /**
     * 取消订单
     */
    Response<Void> cancelOrder(Long orderId);
}

/**
 * 订单用例服务实现
 */
@Service
@Slf4j
public class OrderCaseServiceImpl implements IOrderCaseService {

    @Resource
    private IOrderDomainService orderDomainService;
    
    @Resource
    private IOrderRepository orderRepository;
    
    @Resource
    private INotificationPort notificationPort;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Response<OrderDTO> createOrder(CreateOrderRequest request) {
        log.info("创建订单开始, request: {}", request);
        
        try {
            // 1. 构建领域实体
            OrderAggregate orderAggregate = OrderAggregate.builder()
                    .orderId(IdUtil.get())
                    .userId(request.getUserId())
                    .items(request.getItems())
                    .build();
            
            // 2. 调用领域服务处理业务逻辑
            orderAggregate.create();
            
            // 3. 持久化
            orderRepository.save(orderAggregate);
            
            // 4. 发送领域事件（通过 Port）
            notificationPort.sendOrderCreated(new OrderCreatedEvent(orderAggregate));
            
            // 5. 封装返回
            return Response.ok(OrderDTO.fromAggregate(orderAggregate));
            
        } catch (BusinessException e) {
            log.error("创建订单业务异常", e);
            return Response.fail(e.getCode(), e.getMessage());
        } catch (Exception e) {
            log.error("创建订单系统异常", e);
            return Response.fail("ORDER_CREATE_ERROR", "创建订单失败");
        }
    }
}
```

## 复杂 Case 实现 - Node 编排模式

适用于复杂业务流程，需要多步骤、多分支、并行处理的场景：

### 1. 抽象基类

```java
/**
 * Case 流程节点抽象基类
 * 使用策略树模式实现流程编排
 * 
 * @param <T> 请求参数类型
 * @param <C> 上下文类型（DynamicContext）
 * @param <R> 返回结果类型
 */
public abstract class AbstractCaseSupport<T, C, R> 
        extends AbstractMultiThreadStrategyRouter<T, C, R> {

    @Resource
    protected IDomainService domainService;  // 注入需要的 Domain Service

    /**
     * 执行当前节点的业务逻辑
     */
    protected abstract R doApply(T requestParameter, C dynamicContext) throws Exception;

    /**
     * 获取下一个处理器（返回 null 表示流程结束）
     */
    public abstract StrategyHandler<T, C, R> get(T requestParameter, C dynamicContext) throws Exception;

    /**
     * 默认返回空处理器（流程结束）
     */
    protected StrategyHandler<T, C, R> defaultStrategyHandler = null;

    /**
     * 路由到下一个节点
     */
    protected R router(T requestParameter, C dynamicContext) throws Exception {
        StrategyHandler<T, C, R> nextHandler = get(requestParameter, dynamicContext);
        if (nextHandler == null) {
            return null; // 流程结束
        }
        return nextHandler.apply(requestParameter, dynamicContext);
    }
}
```

### 2. 工厂类

```java
/**
 * Case 流程工厂
 * 负责创建流程上下文和管理流程入口
 */
@Service
public class DefaultOrderCaseFactory {

    @Resource(name = "orderRootNode")
    private RootNode rootNode;

    /**
     * 获取流程处理器
     */
    public StrategyHandler<String, DynamicContext, Response<OrderDTO>> strategyHandler() {
        return rootNode;
    }

    /**
     * 动态上下文
     * 携带流程执行过程中的共享数据
     */
    @Data
    @Builder
    @AllArgsConstructor
    @NoArgsConstructor
    public static class DynamicContext {
        private String userId;
        private String apiKey;
        private OrderAggregate orderAggregate;
        private PaymentConfigVO paymentConfig;
        // ... 其他上下文数据
    }
}
```

### 3. 根节点

```java
/**
 * 根节点 - 流程入口
 */
@Slf4j
@Service("orderRootNode")
public class RootNode extends AbstractCaseSupport<String, DynamicContext, Response<OrderDTO>> {

    @Resource(name = "orderVerifyNode")
    private VerifyNode verifyNode;

    @Override
    protected Response<OrderDTO> doApply(String requestParameter, DynamicContext dynamicContext) throws Exception {
        try {
            log.info("创建订单 RootNode 开始, request: {}", requestParameter);
            
            // 初始化上下文
            dynamicContext.setUserId(requestParameter);
            
            // 路由到下一个节点
            return router(requestParameter, dynamicContext);
            
        } catch (Exception e) {
            log.error("创建订单 RootNode 异常", e);
            throw e;
        }
    }

    @Override
    public StrategyHandler<String, DynamicContext, Response<OrderDTO>> get(
            String requestParameter, DynamicContext dynamicContext) throws Exception {
        return verifyNode;
    }
}
```

### 4. 业务节点

```java
/**
 * 验证节点
 */
@Slf4j
@Service("orderVerifyNode")
public class VerifyNode extends AbstractCaseSupport<String, DynamicContext, Response<OrderDTO>> {

    @Resource(name = "orderCreateNode")
    private CreateNode createNode;

    @Resource
    private IUserService userService;

    @Override
    protected Response<OrderDTO> doApply(String requestParameter, DynamicContext dynamicContext) throws Exception {
        log.info("创建订单-VerifyNode: {}", requestParameter);

        // 验证用户
        UserEntity user = userService.findById(dynamicContext.getUserId());
        if (user == null) {
            return Response.fail("USER_NOT_FOUND", "用户不存在");
        }

        // 验证库存（可并行调用）
        // ...

        return router(requestParameter, dynamicContext);
    }

    @Override
    public StrategyHandler<String, DynamicContext, Response<OrderDTO>> get(
            String requestParameter, DynamicContext dynamicContext) throws Exception {
        return createNode;
    }
}

/**
 * 创建节点
 */
@Slf4j
@Service("orderCreateNode")
public class CreateNode extends AbstractCaseSupport<String, DynamicContext, Response<OrderDTO>> {

    @Resource(name = "orderPaymentNode")
    private PaymentNode paymentNode;

    @Resource
    private IOrderDomainService orderDomainService;
    
    @Resource
    private IOrderRepository orderRepository;

    @Override
    protected Response<OrderDTO> doApply(String requestParameter, DynamicContext dynamicContext) throws Exception {
        log.info("创建订单-CreateNode: {}", requestParameter);

        // 1. 构建订单聚合
        OrderAggregate aggregate = OrderAggregate.builder()
                .orderId(IdUtil.get())
                .userId(dynamicContext.getUserId())
                .build();
        
        // 2. 调用领域服务
        aggregate.create();
        
        // 3. 保存
        orderRepository.save(aggregate);
        
        // 4. 设置上下文
        dynamicContext.setOrderAggregate(aggregate);

        return router(requestParameter, dynamicContext);
    }

    @Override
    public StrategyHandler<String, DynamicContext, Response<OrderDTO>> get(
            String requestParameter, DynamicContext dynamicContext) throws Exception {
        return paymentNode;
    }
}
```

### 5. 结束节点

```java
/**
 * 结束节点 - 流程终点
 */
@Slf4j
@Service("orderEndNode")
public class EndNode extends AbstractCaseSupport<String, DynamicContext, Response<OrderDTO>> {

    @Override
    protected Response<OrderDTO> doApply(String requestParameter, DynamicContext dynamicContext) throws Exception {
        log.info("创建订单-EndNode 完成, orderId: {}", 
                dynamicContext.getOrderAggregate().getOrderId());

        // 发送通知
        notificationPort.sendOrderCreated(
                new OrderCreatedEvent(dynamicContext.getOrderAggregate()));

        // 返回最终结果
        return Response.ok(OrderDTO.fromAggregate(dynamicContext.getOrderAggregate()));
    }

    @Override
    public StrategyHandler<String, DynamicContext, Response<OrderDTO>> get(
            String requestParameter, DynamicContext dynamicContext) throws Exception {
        return defaultStrategyHandler; // null，表示流程结束
    }
}
```

### 6. Case 实现类

```java
/**
 * 订单用例服务实现（复杂流程）
 */
@Service
@Slf4j
public class OrderCaseServiceImpl implements IOrderCaseService {

    @Resource
    private DefaultOrderCaseFactory orderCaseFactory;

    @Override
    public Response<OrderDTO> createOrder(CreateOrderRequest request) {
        // 1. 获取流程处理器
        StrategyHandler<String, DynamicContext, Response<OrderDTO>> handler = 
                orderCaseFactory.strategyHandler();

        // 2. 构建上下文
        DynamicContext context = DynamicContext.builder()
                .userId(request.getUserId())
                .apiKey(request.getApiKey())
                .build();

        // 3. 执行流程
        try {
            return handler.apply(request.getOrderId(), context);
        } catch (Exception e) {
            log.error("创建订单流程执行异常", e);
            return Response.fail("ORDER_CREATE_ERROR", "创建订单失败: " + e.getMessage());
        }
    }
}
```

## 流程图

```
┌─────────────┐
│  HTTP API   │
└──────┬──────┘
       │ createOrder(request)
       ▼
┌─────────────┐
│   Case      │  ← 职责：编排流程、调用 Domain、封装结果
│  Service    │
└──────┬──────┘
       │ strategyHandler.apply()
       ▼
┌─────────────┐
│  RootNode   │  ← 初始化上下文、入口
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ VerifyNode  │  ← 验证用户、权限、前置条件
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ CreateNode  │  ← 创建聚合根、调用领域服务
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ PaymentNode │  ← 支付处理（可并行）
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  EndNode    │  ← 发送通知、返回结果
└─────────────┘
```

## 设计要点

### 1. Trigger 极简原则

```java
@RestController
@Slf4j
public class OrderController {

    @Resource
    private IOrderCaseService orderCaseService;

    @PostMapping("/create")
    public Response<OrderDTO> create(@RequestBody @Valid CreateOrderRequest request) {
        // 只做三件事：
        // 1. 参数校验（@Valid）
        // 2. 调用 Case
        // 3. 返回结果
        return orderCaseService.createOrder(request);
    }
}
```

### 2. Context 传递数据

```java
// 避免长参数列表，使用 Context 传递
DynamicContext context = DynamicContext.builder()
        .userId(userId)
        .orderId(orderId)
        .items(items)
        .build();
```

### 3. 异常处理

```java
// Case 层统一异常处理
try {
    return handler.apply(request, context);
} catch (BusinessException e) {
    return Response.fail(e.getCode(), e.getMessage());
} catch (Exception e) {
    log.error("系统异常", e);
    return Response.fail("SYSTEM_ERROR", "系统繁忙");
}
```

### 4. 事务边界

```java
// Case 层控制事务
@Override
@Transactional(rollbackFor = Exception.class)
public Response<OrderDTO> createOrder(CreateOrderRequest request) {
    // 所有数据库操作在同一个事务中
    orderRepository.save(aggregate);
    inventoryService.deduct(request.getItems());
    return Response.ok(OrderDTO.fromAggregate(aggregate));
}
```

## 何时使用 Node 编排

| 场景 | 推荐方案 |
|------|----------|
| 简单 CRUD | 直接 Case 实现 |
| 单流程多步骤 | Case + private 方法 |
| 复杂多分支 | Node 编排 |
| 需要并行处理 | Node + async |
| 需要策略路由 | Node + 策略模式 |

## 参考实现

- [ai-mcp-gateway-case](file:///Users/fuzhengwei/Documents/project/ddd-demo/ai-mcp-gateway/ai-mcp-gateway-case) - MCP 网关用例层完整实现
