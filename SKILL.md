---
name: "xfg-ddd-skills"
description: "DDD 六边形架构设计与部署技能包。提供 Domain/Case/Infrastructure 层设计模式与代码模板，以及 Docker 环境部署脚本。当用户询问 DDD 架构、设计模式或需要部署项目时调用。"
version: 2.2.1
author: xiaofuge
license: MIT
triggers:
  # DDD 架构设计
  - "DDD"
  - "六边形架构"
  - "domain-driven design"
  - "领域驱动设计"
  - "ports and adapters"
  - "创建 Entity"
  - "创建聚合根"
  - "创建 DDD 项目"
  - "新建项目"
  - "Aggregate"
  - "ValueObject"
  - "值对象"
  - "聚合根"
  # DevOps 部署相关
  - "部署"
  - "deploy"
  - "Docker"
  - "docker-compose"
  - "容器化"
  - "发布"
  - "上线"
  - "打包"
  - "build"
  - "运维部署"
  - "启动服务"
  - "停止服务"
  - "重启服务"
  - "环境配置"
  - "生产环境"
  - "测试环境"
  - "数据库部署"
  - "MySQL"
  - "Redis"
  - "RabbitMQ"
metadata:
  openclaw:
    emoji: "🏗️"
---

# DDD Hexagonal Architecture

Design and implement software using Domain-Driven Design with Hexagonal Architecture. This skill provides patterns, templates, and best practices for building maintainable domain-centric applications.

## Scripts

### 创建 DDD 项目

当用户说"创建 DDD 项目"、"新建项目"、"创建项目"、"创建ddd项目"时，**必须使用 `scripts/create-ddd-project.sh` 脚本**。

**脚本支持系统**: Windows (Git Bash/MSYS2)、Mac (macOS)、Linux，自动检测并适配。

**⚠️ 环境提醒**: 建议提前安装 JDK 17+ 和 Maven 3.8.*，脚本启动时会自动检测并给出各平台安装指引，未安装也可继续但可能导致生成失败。

**⚠️ 重要提醒：必须询问用户项目创建地址**

**在创建项目前，如果用户没有明确给出工程创建地址，必须询问用户在哪里创建项目。** 不能随意创建到默认目录，必须获得用户确认。

示例对话：
```
用户：帮我创建一个 DDD 项目
AI：好的，我来帮您创建 DDD 项目。请问您希望将项目创建在哪个目录？
     例如：
     1) /Users/xxx/projects
     2) /Users/xxx/Documents
     3) /home/xxx/workspace
     4) 其他路径（请直接输入）

用户：创建在 /Users/xxx/projects 下
AI：确认在 /Users/xxx/projects 下创建项目，开始执行...
```

**流程:**

1. **第一步：确认项目创建目录**

   **必须询问用户**，如果用户未指定，列出可选项供用户选择。

   示例：
   ```
   📂 选择项目生成目录
   ──────────────────────────────
   1) /Users/xxx/projects
   2) /Users/xxx/Documents
   3) /home/xxx/workspace
   4) 自定义路径（直接输入路径）

   直接回车 = 选择 [1]
   ```

2. **第二步：填写项目配置**（逐一询问，直接回车使用默认值）

   | 参数 | 说明 | 默认值 | 示例 |
   |------|------|--------|------|
   | GroupId | Maven 坐标 groupId，标识组织或公司 | `com.yourcompany` | `cn.bugstack` |
   | ArtifactId | 项目模块唯一标识名称 | `your-project-name` | `order-system` |
   | Version | 项目版本号 | `1.0.0-SNAPSHOT` | `1.0.0-RELEASE` |
   | Package | Java 代码根包名 | 自动从 GroupId + ArtifactId 推导 | `cn.bugstack.order` |
   | Archetype 版本 | 脚手架模板版本 | `1.3` | - |

3. **第三步：确认并生成**

   显示所有配置，确认后执行 Maven Archetype 生成项目。

**脚本执行方式**（在 `ddd-skills-v2` 项目根目录下运行）:
```bash
bash scripts/create-ddd-project.sh
```

> ⚠️ **必须先 cd 到 `ddd-skills-v2` 项目目录下再执行**，脚本会自动定位自身路径。
> AI 负责引导用户选择目录、填写参数，无需手动拼凑 Maven 命令。
> **⚠️ 再次强调：创建项目前必须询问用户项目创建地址，不能随意创建！**

---

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
| Infrastructure layer | [references/infrastructure-layer.md](references/infrastructure-layer.md) |
| **Domain 层设计指南（避免常见错误）** | **[references/domain-design-guide.md](references/domain-design-guide.md)** |
| **Domain 层核心模式** | **[references/domain-patterns.md](references/domain-patterns.md)** |
| **Infrastructure 层核心模式** | **[references/infrastructure-patterns.md](references/infrastructure-patterns.md)** |
| **DevOps 部署** | **[references/devops-deployment.md](references/devops-deployment.md)** |
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
│            (Orchestration / Business Flow)                   │
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

## ⚠️ Domain 层设计自检清单

在生成 Domain 层代码前，必须逐项检查：

**1. 是否有多种处理方式（if-else 判断类型）？**
→ 是：使用**策略模式**（`IXxxStrategy` 接口 + 实现类 + `Map<String, IXxxStrategy>` 注入）

**2. 是否有多个独立的校验/过滤步骤（3步以上）？**
→ 是：使用**责任链模式**（`IXxxFilter` 接口 + Factory 组装链）

**3. Service 方法是否超过 60 行？**
→ 是：拆分为过滤器（校验）+ 策略（执行）+ 私有方法（保存）

**4. Infrastructure 层是否包含业务判断逻辑？**
→ 是：将业务校验移到 Domain 层的过滤器中，Infrastructure 只做数据读写

**5. 是否跨域直接依赖另一个 Domain 的 Repository？**
→ 是：通过 Case 层编排，或在本域 Repository 接口中聚合所需数据

**6. Infrastructure 包名是否正确？**
→ Repository 实现：`adapter/repository/`（❌ 不是 `persistent/repository/`）
→ DAO 操作：`dao/`（❌ 不是 `scenario/dao/` 或其他包）
→ Redis 操作：`redis/`（❌ 不是 `config/`）

## Domain Layer 目录结构

```
model/
├── aggregate/              # 聚合对象
│   └── XxxAggregate.java
├── entity/               # 实体对象
│   ├── XxxEntity.java          # 普通实体
│   └── XxxCommandEntity.java  # 命令实体
└── valobj/               # 值对象
    ├── XxxVO.java             # 普通值对象
    └── XxxEnumVO.java         # 枚举值对象
```

**⚠️ 注意**：`model/` 下没有单独的 `command/` 包，命令实体统一放在 `entity/` 包下。

---

## 📦 新功能开发规范

当用户需要增加新功能时，按照以下决策流程进行开发：

### 决策流程图

```
用户需要新功能
        │
        ▼
┌───────────────────┐
│ 检查现有领域服务   │ ──是──→ 扩展现有 Service
│ domain/xxx/service│
│ 是否有支持？      │
└─────────┬─────────┘
          │否
          ▼
┌───────────────────┐
│ 创建新的领域？     │ ──是──→ 创建新领域（完整结构）
│ domain/xxx/       │
│                   │
└─────────┬─────────┘
          │
          ▼
┌───────────────────┐
│ Case 层是否需要？  │ ──是──→ 创建 Case 层编排
│ 业务复杂？多领域？  │
└─────────┬─────────┘
          │否（轻量工程）
          ▼
┌───────────────────┐
│ Trigger 直接调用   │ ←── Trigger → Domain
│ Domain 领域层     │
└───────────────────┘
```

### 决策指南

| 问题 | 答案 | 处理方式 |
|------|------|----------|
| 现有领域能否支持新功能？ | ✅ 是 | 在现有 Service 中添加方法 |
| 是否需要跨多个领域？ | ✅ 是 | 创建 Case 层编排 |
| 业务逻辑是否复杂？ | ✅ 是 | 创建 Case 层编排 |
| 是否是轻量工程？ | ✅ 是 | Trigger 直接调用 Domain |
| Trigger 是否越来越复杂？ | ✅ 是 | 询问用户是否创建 Case 层 |

---

### 场景一：扩展现有领域服务

**判断条件**：新功能属于现有领域的业务范围。

**开发步骤**：

1. **检查现有领域服务**
   - 查看 `domain/{domain}/service/` 目录
   - 确认是否有相关的 Service 接口

2. **扩展现有 Service**
   - 在现有接口中添加新方法
   - 在实现类中实现新方法

**示例**：在交易域添加一个"查询订单列表"功能

```java
// 1. 在现有接口中添加方法
public interface ITradeRepository {
    // 现有方法...
    
    // 新增：查询订单列表
    List<MarketPayOrderEntity> queryOrderList(QueryOrderRequest request);
}

// 2. 在实现类中实现
@Repository
public class TradeRepository implements ITradeRepository {
    
    @Resource
    private IMcpGatewayDao mcpGatewayDao;
    
    @Override
    public List<MarketPayOrderEntity> queryOrderList(QueryOrderRequest request) {
        // 实现查询逻辑
    }
}
```

---

### 场景二：创建新的领域

**判断条件**：新功能涉及全新的业务领域，与现有领域无关。

**开发步骤**：

1. **创建完整的领域结构**
   ```
   domain/
   └── {new-domain}/                    # 新领域
       ├── adapter/                    # 适配器接口
       │   ├── port/                  # 端口接口
       │   │   └── I{Xxx}Port.java
       │   └── repository/            # 仓储接口
       │       └── I{Xxx}Repository.java
       ├── model/                     # 领域模型
       │   ├── aggregate/            # 聚合根
       │   ├── entity/               # 实体
       │   └── valobj/               # 值对象
       └── service/                   # 领域服务
           ├── I{Xxx}Service.java     # 服务接口
           └── {能力}/
               └── {Xxx}ServiceImpl.java
   ```

2. **定义 Adapter 接口**
   ```java
   // Repository 接口
   public interface I{Xxx}Repository {
       XxxEntity queryById(Long id);
       void save(XxxEntity entity);
   }
   
   // Port 接口
   public interface I{Xxx}Port {
       void notify(XxxEntity entity) throws Exception;
   }
   ```

3. **定义 Model**
   ```java
   // 实体
   @Data
   public class XxxEntity {
       private Long id;
       private String name;
   }
   
   // 值对象
   @Getter
   public enum XxxStatusEnumVO {
       CREATED("created", "已创建"),
       PROCESSING("processing", "处理中"),
       COMPLETED("completed", "已完成");
       private String code;
       private String info;
   }
   ```

4. **实现 Service**
   ```java
   public interface I{Xxx}Service {
       void process(XxxEntity entity) throws Exception;
   }
   
   @Slf4j
   @Service
   public class XxxServiceImpl implements I{Xxx}Service {
       
       @Resource
       private I{Xxx}Repository repository;
       
       @Resource
       private I{Xxx}Port port;
       
       @Override
       public void process(XxxEntity entity) throws Exception {
           log.info("处理业务:{}", entity.getId());
           // 业务逻辑
           repository.save(entity);
           port.notify(entity);
       }
   }
   ```

---

### 场景三：创建 Case 层

**判断条件**：业务涉及多个领域协作，或需要编排多个领域服务。

**开发步骤**：

1. **创建 Case 模块结构**
   ```
   case/
   └── {domain}/
       └── {capability}/
           ├── I{Xxx}Case.java           # Case 接口
           └── impl/
               └── {Xxx}CaseImpl.java    # Case 实现
   ```

2. **定义 Case 接口**
   ```java
   /**
    * XXX 业务编排接口
    * 
    * 职责：编排多个领域服务，完成复杂业务场景
    */
   public interface I{Xxx}Case {
       
       /**
        * 执行 XXX 业务
        */
       void execute(XxxRequest request) throws Exception;
   }
   ```

3. **实现 Case 编排**
   ```java
   /**
    * XXX 业务编排实现
    * 
    * @author xiaofuge
    */
   @Slf4j
   @Service
   public class XxxCaseImpl implements I{Xxx}Case {
       
       @Resource
       private IDomain1Service domain1Service;
       
       @Resource
       private IDomain2Service domain2Service;
       
       @Override
       public void execute(XxxRequest request) throws Exception {
           log.info("执行 XXX 业务");
           
           // 1. 调用领域服务1
           Domain1Result r1 = domain1Service.method1(request.getParam1());
           
           // 2. 调用领域服务2
           domain2Service.method2(r1.getData());
           
           // 3. 组装结果
           // ...
       }
   }
   ```

**Case 层命名规范**：
- 接口命名：`I{Xxx}Case`
- 实现类命名：`{Xxx}CaseImpl`

---

### 场景四：Trigger 直接调用 Domain

**判断条件**：轻量工程，业务简单，不需要 Case 层编排。

**开发步骤**：

1. **在 Trigger 层直接调用 Domain**
   ```java
   @RestController
   @RequestMapping("/api/xxx")
   public class XxxController {
       
       @Resource
       private I{Xxx}Service xxxService;
       
       @PostMapping("/process")
       public Response<XxxResponse> process(@RequestBody XxxRequest request) {
           try {
               xxxService.process(request.toEntity());
               return Response.success();
           } catch (Exception e) {
               return Response.fail(e.getMessage());
           }
       }
   }
   ```

2. **Trigger 层职责**
   - 接收请求参数
   - 参数校验
   - 调用 Domain 层
   - 处理异常
   - 返回响应

---

### 场景五：Trigger 复杂化后重构为 Case 层

**判断条件**：Trigger 层代码越来越复杂，包含大量业务逻辑。

**警告信号**：
- Controller 代码超过 100 行
- Controller 中有大量 if-else 判断
- Controller 依赖多个 Domain Service
- 业务逻辑难以测试

**重构步骤**：

1. **询问用户**
   ```
   AI：检测到 Trigger 层代码比较复杂，是否需要创建 Case 层来分摊业务逻辑？
       这样可以：
       1. 将业务逻辑从 Controller 移到 Case 层
       2. 提高代码可测试性
       3. 更好的职责分离
   ```

2. **创建 Case 层**
   - 按照场景三的方式创建 Case 模块
   - 将 Controller 中的业务逻辑移到 Case 层

3. **简化 Trigger 层**
   ```java
   // 重构前
   @RestController
   public class XxxController {
       @Resource private IDomain1Service d1;
       @Resource private IDomain2Service d2;
       @Resource private IDomain3Service d3;
       
       public Response process(Request req) {
           // 100+ 行业务逻辑...
       }
   }
   
   // 重构后
   @RestController
   public class XxxController {
       @Resource private I{Xxx}Case xxxCase;
       
       public Response process(Request req) {
           xxxCase.execute(req);
           return Response.success();
       }
   }
   ```

---

### 完整开发流程示例

**需求**：在拼团系统中添加"订单超时取消"功能

**步骤 1：检查现有领域**
```
trade/
├── adapter/repository/ITradeRepository.java  ← 可以复用
├── model/entity/TradeLockRuleCommandEntity.java
└── service/
    ├── lock/TradeLockOrderService.java     ← 部分相关
    └── refund/TradeRefundOrderService.java  ← 退单逻辑可参考
```

**步骤 2：决策**
- 现有领域（trade）已有相关服务
- 需要扩展现有 Service
- 不需要创建新领域

**步骤 3：实现**

```java
// 1. 扩展 ITradeRepository
public interface ITradeRepository {
    // 现有方法...
    
    // 新增：查询超时未支付订单
    List<MarketPayOrderEntity> queryTimeoutUnpaidOrders();
    
    // 新增：取消订单
    void cancelOrder(String orderId);
}

// 2. 扩展 TradeLockOrderService
public interface ITradeLockOrderService {
    // 现有方法...
    
    // 新增：处理超时订单
    void handleTimeoutOrders();
}

@Slf4j
@Service
public class TradeLockOrderService implements ITradeLockOrderService {
    
    @Resource
    private ITradeRepository repository;
    
    @Override
    public void handleTimeoutOrders() {
        log.info("处理超时未支付订单");
        
        // 1. 查询超时订单
        List<MarketPayOrderEntity> orders = repository.queryTimeoutUnpaidOrders();
        
        // 2. 遍历取消
        for (MarketPayOrderEntity order : orders) {
            repository.cancelOrder(order.getOrderId());
        }
    }
}
```

**步骤 4：添加 Trigger**
```java
@Component
public class OrderTimeoutJob {
    
    @Resource
    private ITradeLockOrderService tradeLockOrderService;
    
    @Scheduled(cron = "0 */5 * * * ?")  // 每5分钟执行
    public void execute() {
        try {
            tradeLockOrderService.handleTimeoutOrders();
        } catch (Exception e) {
            log.error("订单超时处理异常", e);
        }
    }
}
```

---

### 规范速查表

| 场景 | 判断条件 | 实现位置 |
|------|---------|----------|
| 扩展现有服务 | 功能属于现有领域 | `domain/{domain}/service/` |
| 创建新领域 | 全新业务领域 | 创建完整的 `domain/{new}/` 结构 |
| 创建 Case 层 | 多领域协作、复杂业务 | `case/{domain}/{capability}/` |
| Trigger 调用 | 轻量工程、简单业务 | `trigger/{domain}/controller/` |
| 重构为 Case | Trigger 越来越复杂 | 询问用户后重构 |

**核心原则**：
1. **优先复用**：先检查现有领域是否能支持
2. **单一职责**：新功能归到对应领域，不随意扩张
3. **适度分层**：简单场景直接调用，复杂场景创建 Case
4. **持续演进**：Trigger 复杂化时，询问用户是否重构

---

## Quick Templates

### Aggregate 聚合对象

```java
@Data @Builder @AllArgsConstructor @NoArgsConstructor
public class GroupBuyOrderAggregate {
    /** 用户实体对象 */
    private UserEntity userEntity;
    /** 支付活动实体对象 */
    private PayActivityEntity payActivityEntity;
    /** 支付优惠实体对象 */
    private PayDiscountEntity payDiscountEntity;
    /** 已参与拼团量 */
    private Integer userTakeOrderCount;
}
```

### Entity 普通实体

```java
@Data @Builder @AllArgsConstructor @NoArgsConstructor
public class MarketPayOrderEntity {
    private String teamId;
    private String orderId;
    private BigDecimal originalPrice;
    private BigDecimal deductionPrice;
    private BigDecimal payPrice;
    private TradeOrderStatusEnumVO tradeOrderStatusEnumVO;
}
```

### Entity 命令实体（放在 entity 包）

```java
/** 命令实体放在 entity 包，使用 CommandEntity 后缀 */
@Data @Builder @AllArgsConstructor @NoArgsConstructor
public class TradeLockRuleCommandEntity {
    private String userId;
    private Long activityId;
    private String teamId;
}
```

### Value Object 值对象

```java
@Getter @Builder @AllArgsConstructor @NoArgsConstructor
public class NotifyConfigVO {
    private NotifyTypeEnumVO notifyType;
    private String notifyMQ;
    private String notifyUrl;
}
```

### EnumVO 枚举值对象（可包含策略逻辑）

```java
@Getter @AllArgsConstructor
public enum RefundTypeEnumVO {

    UNPAID_UNLOCK("unpaid_unlock", "Unpaid2RefundStrategy", "未支付，未成团") {
        @Override
        public boolean matches(GroupBuyOrderEnumVO groupBuyOrderEnumVO, TradeOrderStatusEnumVO tradeOrderStatusEnumVO) {
            return GroupBuyOrderEnumVO.PROGRESS.equals(groupBuyOrderEnumVO) 
                && TradeOrderStatusEnumVO.CREATE.equals(tradeOrderStatusEnumVO);
        }
    },
    
    PAID_UNFORMED("paid_unformed", "Paid2RefundStrategy", "已支付，未成团") {
        @Override
        public boolean matches(GroupBuyOrderEnumVO groupBuyOrderEnumVO, TradeOrderStatusEnumVO tradeOrderStatusEnumVO) {
            return GroupBuyOrderEnumVO.PROGRESS.equals(groupBuyOrderEnumVO) 
                && TradeOrderStatusEnumVO.COMPLETE.equals(tradeOrderStatusEnumVO);
        }
    };

    private String code;
    private String strategy;
    private String info;

    public abstract boolean matches(GroupBuyOrderEnumVO groupBuyOrderEnumVO, TradeOrderStatusEnumVO tradeOrderStatusEnumVO);

    public static RefundTypeEnumVO getRefundStrategy(GroupBuyOrderEnumVO g, TradeOrderStatusEnumVO t) {
        return Arrays.stream(values()).filter(v -> v.matches(g, t)).findFirst()
                .orElseThrow(() -> new RuntimeException("不支持的退款状态组合"));
    }
}
```

### Domain Service 完整编码

```java
/** 1. 定义服务接口 */
public interface ITradeLockOrderService {
    MarketPayOrderEntity lockMarketPayOrder(UserEntity user, PayActivityEntity activity, PayDiscountEntity discount) throws Exception;
}

/** 2. 实现服务（放在子包中） */
@Slf4j @Service
public class TradeLockOrderService implements ITradeLockOrderService {

    @Resource private ITradeRepository repository;
    @Resource private BusinessLinkedList<TradeLockRuleCommandEntity, TradeLockRuleFilterFactory.DynamicContext, TradeLockRuleFilterBackEntity> tradeRuleFilter;

    @Override
    public MarketPayOrderEntity lockMarketPayOrder(UserEntity userEntity, PayActivityEntity payActivityEntity, PayDiscountEntity payDiscountEntity) throws Exception {
        log.info("锁定营销优惠支付订单:{} activityId:{}", userEntity.getUserId(), payActivityEntity.getActivityId());

        // 1. 交易规则过滤（责任链）
        TradeLockRuleFilterBackEntity back = tradeRuleFilter.apply(TradeLockRuleCommandEntity.builder()
                .activityId(payActivityEntity.getActivityId())
                .userId(userEntity.getUserId())
                .teamId(payActivityEntity.getTeamId()).build(),
                new TradeLockRuleFilterFactory.DynamicContext());

        // 2. 构建聚合对象
        GroupBuyOrderAggregate aggregate = GroupBuyOrderAggregate.builder()
                .userEntity(userEntity)
                .payActivityEntity(payActivityEntity)
                .payDiscountEntity(payDiscountEntity)
                .userTakeOrderCount(back.getUserTakeOrderCount())
                .build();

        // 3. 锁定聚合订单
        return repository.lockMarketPayOrder(aggregate);
    }
}
```

### 策略模式实现

```java
/** 1. 策略接口 */
public interface IRefundOrderStrategy {
    void refundOrder(TradeRefundOrderEntity entity) throws Exception;
    void reverseStock(TeamRefundSuccess success) throws Exception;
}

/** 2. 抽象基类（模板方法） */
@Slf4j
public abstract class AbstractRefundOrderStrategy implements IRefundOrderStrategy {
    @Resource protected ITradeRepository repository;
    @Resource protected ThreadPoolExecutor threadPoolExecutor;

    protected void doReverseStock(TeamRefundSuccess s, String type) throws Exception {
        log.info("退单恢复锁单量 - {}", type);
        repository.refund2AddRecovery(s.getActivityId() + ":" + s.getTeamId(), s.getOrderId());
    }
}

/** 3. 具体策略 */
@Slf4j @Service("paid2RefundStrategy")
public class Paid2RefundStrategy extends AbstractRefundOrderStrategy {
    @Override
    public void refundOrder(TradeRefundOrderEntity e) throws Exception {
        log.info("退单-已支付，未成团 userId:{}", e.getUserId());
        NotifyTaskEntity n = repository.paid2Refund(GroupBuyRefundAggregate.buildPaid2RefundAggregate(e, -1, -1));
        if (n != null) threadPoolExecutor.execute(() -> tradeTaskService.execNotifyJob(n));
    }
    @Override
    public void reverseStock(TeamRefundSuccess s) throws Exception {
        doReverseStock(s, "已支付，但有锁单记录，恢复锁单库存");
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

---

# 🚀 DevOps 部署完整流程

## 📋 部署检查清单

当用户需要部署 DDD 项目时，按照以下流程执行：

### 1. 确认项目信息
- [ ] 项目名称（artifactId）
- [ ] 项目路径（代码根目录）
- [ ] 部署环境（开发/测试/生产）
- [ ] 基础依赖（MySQL/Redis/RabbitMQ）

### 2. 打包构建
```bash
cd /path/to/project
mvn clean package -Dmaven.test.skip=true
```

### 3. 基础镜像拉取（加速）
```bash
# 使用阿里云加速镜像
docker pull registry.cn-hangzhou.aliyuncs.com/xfg-studio/openjdk:17-jdk-slim
docker pull registry.cn-hangzhou.aliyuncs.com/xfg-studio/mysql:8.0.32
docker pull registry.cn-hangzhou.aliyuncs.com/xfg-studio/redis:6.2
```

### 4. 数据库部署
```bash
cd docs/dev-ops
docker-compose -f docker-compose-environment-aliyun.yml up -d mysql

# 等待 MySQL 就绪后初始化数据库
docker exec -it mysql mysql -uroot -p123456 -e "source /docker-entrypoint-initdb.d/xxx.sql"
```

### 5. 应用容器构建
```bash
cd ai-mcp-gateway-app
docker build -t system/{artifactId}:1.0.0 .
```

### 6. 应用启动
```bash
cd docs/dev-ops
docker-compose -f docker-compose-app.yml up -d
```

### 7. 验证部署
```bash
# 查看容器状态
docker ps -a | grep {artifactId}

# 查看应用日志
docker logs -f {artifactId}

# 健康检查
curl http://localhost:{port}/actuator/health
```

---

## 📁 标准部署目录结构

```
{project}/
├── docs/
│   └── dev-ops/
│       ├── docker-compose-environment-aliyun.yml  # 基础环境（MySQL/Redis/RabbitMQ）
│       ├── docker-compose-app.yml                  # 应用服务
│       ├── mysql/
│       │   ├── my.cnf                              # MySQL 配置
│       │   └── sql/
│       │       └── {project}.sql                  # 数据库初始化脚本
│       ├── redis/
│       │   └── redis.conf                          # Redis 配置
│       ├── app/
│       │   ├── start.sh                            # 启动脚本
│       │   └── stop.sh                             # 停止脚本
│       └── README.md                               # 部署说明
├── {project}-app/
│   ├── Dockerfile                                   # 应用 Dockerfile
│   ├── pom.xml
│   └── src/main/resources/
│       ├── application.yml
│       ├── application-dev.yml
│       ├── application-test.yml
│       ├── application-prod.yml
│       └── logback-spring.xml
```

---

## 🐳 Dockerfile 标准模板

```dockerfile
# 基础镜像
FROM registry.cn-hangzhou.aliyuncs.com/xfg-studio/openjdk:17-jdk-slim

# 作者
MAINTAINER xiaofuge

# 时区配置
ENV TZ=PRC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 添加应用 JAR
ADD target/{artifactId}.jar /{artifactId}.jar

# 暴露端口
EXPOSE {port}

# 启动命令
ENTRYPOINT ["sh","-c","java -jar $JAVA_OPTS /{artifactId}.jar $PARAMS"]
```

---

## 📦 docker-compose-app.yml 标准模板

```yaml
version: '3.8'

services:
  {artifactId}:
    image: system/{artifactId}:1.0.0
    container_name: {artifactId}
    restart: on-failure
    ports:
      - "{port}:{port}"
    environment:
      - TZ=PRC
      - SERVER_PORT={port}
      - SPRING_PROFILES_ACTIVE=prod
    volumes:
      - ./logs:/data/log
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    networks:
      - my-network
    depends_on:
      - mysql
      - redis

networks:
  my-network:
    driver: bridge
```

---

## 🗄️ docker-compose-environment-aliyun.yml 标准模板

```yaml
version: '3.9'

services:
  # MySQL 8.0
  mysql:
    image: registry.cn-hangzhou.aliyuncs.com/xfg-studio/mysql:8.0.32
    container_name: mysql
    command: --default-authentication-plugin=mysql_native_password
    restart: always
    environment:
      TZ: Asia/Shanghai
      MYSQL_ROOT_PASSWORD: 123456
    ports:
      - "13306:3306"
    volumes:
      - ./mysql/my.cnf:/etc/mysql/conf.d/mysql.cnf:ro
      - ./mysql/sql:/docker-entrypoint-initdb.d
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 5s
      timeout: 10s
      retries: 10
      start_period: 15s
    networks:
      - my-network

  # phpMyAdmin（可选）
  phpmyadmin:
    image: registry.cn-hangzhou.aliyuncs.com/xfg-studio/phpmyadmin:5.2.1
    container_name: phpmyadmin
    ports:
      - "8899:80"
    environment:
      - PMA_HOST=mysql
      - PMA_PORT=3306
      - MYSQL_ROOT_PASSWORD=123456
    depends_on:
      mysql:
        condition: service_healthy
    networks:
      - my-network

  # Redis 6.2
  redis:
    image: registry.cn-hangzhou.aliyuncs.com/xfg-studio/redis:6.2
    container_name: redis
    restart: always
    ports:
      - "16379:6379"
    networks:
      - my-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 3

  # Redis Commander（可选）
  redis-admin:
    image: registry.cn-hangzhou.aliyuncs.com/xfg-studio/redis-commander:0.8.0
    container_name: redis-admin
    ports:
      - "8081:8081"
    environment:
      - REDIS_HOSTS=local:redis:6379
      - HTTP_USER=admin
      - HTTP_PASSWORD=admin
    depends_on:
      redis:
        condition: service_healthy
    networks:
      - my-network

networks:
  my-network:
    driver: bridge
```

---

## 🚀 快速启动/停止脚本

### start.sh
```bash
#!/bin/bash

CONTAINER_NAME={artifactId}
IMAGE_NAME=system/{artifactId}:1.0.0
PORT={port}

echo "容器部署开始 ${CONTAINER_NAME}"

# 停止容器
docker stop ${CONTAINER_NAME}

# 删除容器
docker rm ${CONTAINER_NAME}

# 启动容器
docker run --name ${CONTAINER_NAME} \
  --network my-network \
  -p ${PORT}:${PORT} \
  -e SPRING_PROFILES_ACTIVE=prod \
  -v $(pwd)/logs:/data/log \
  -d ${IMAGE_NAME}

echo "容器部署成功 ${CONTAINER_NAME}"

# 查看日志
docker logs -f ${CONTAINER_NAME}
```

### stop.sh
```bash
#!/bin/bash

CONTAINER_NAME={artifactId}

echo "停止容器 ${CONTAINER_NAME}"
docker stop ${CONTAINER_NAME}
docker rm ${CONTAINER_NAME}

echo "容器已停止"
```

---

## 🔧 application-prod.yml 标准配置

```yaml
server:
  port: {port}

spring:
  application:
    name: {artifactId}
  datasource:
    driver-class-name: com.mysql.cj.jdbc.Driver
    url: jdbc:mysql://${MYSQL_HOST:mysql}:${MYSQL_PORT:3306}/${MYSQL_DATABASE:{database}}?useUnicode=true&characterEncoding=utf8&serverTimezone=Asia/Shanghai&useSSL=false
    username: ${MYSQL_USER:root}
    password: ${MYSQL_PASSWORD:123456}
    hikari:
      pool-name: {artifactId}-hikari
      minimum-idle: 10
      maximum-pool-size: 50
      idle-timeout: 300000
      connection-timeout: 30000
      max-lifetime: 1800000
  redis:
    host: ${REDIS_HOST:redis}
    port: ${REDIS_PORT:6379}
  rabbitmq:
    host: ${RABBITMQ_HOST:rabbitmq}
    port: ${RABBITMQ_PORT:5672}
    username: ${RABBITMQ_USER:admin}
    password: ${RABBITMQ_PASSWORD:admin123}

logging:
  level:
    root: INFO
    cn.bugstack: INFO
  file:
    name: /data/log/{artifactId}.log
```

---

## 📊 阿里云镜像加速仓库

所有镜像已同步到阿里云，使用前缀 `registry.cn-hangzhou.aliyuncs.com/xfg-studio/`

> 📦 镜像来源：[docker-image-pusher](https://github.com/fuzhengwei/docker-image-pusher)
> 添加新镜像：在 images.txt 添加镜像名，等待1分钟同步

### 常用镜像速查表

| 原始镜像 | 阿里云加速地址 | 用途 |
|---------|--------------|------|
| **JDK/Java** | | |
| openjdk:8-jre-slim | `registry.cn-hangzhou.aliyuncs.com/xfg-studio/openjdk:8-jre-slim` | Java 8 运行环境 |
| openjdk:8-jdk | `registry.cn-hangzhou.aliyuncs.com/xfg-studio/openjdk:8-jdk` | Java 8 开发镜像 |
| openjdk:17-jdk-slim | `registry.cn-hangzhou.aliyuncs.com/xfg-studio/openjdk:17-jdk-slim` | Java 17 运行环境 |
| openjdk:17-ea-17-jdk-slim-buster | `registry.cn-hangzhou.aliyuncs.com/xfg-studio/openjdk:17-ea-17-jdk-slim-buster` | Java 17 EA 版本 |
| **数据库** | | |
| mysql:8.0.32 | `registry.cn-hangzhou.aliyuncs.com/xfg-studio/mysql:8.0.32` | MySQL 8.0 |
| mysql:8.4.4 | `registry.cn-hangzhou.aliyuncs.com/xfg-studio/mysql:8.4.4` | MySQL 8.4 |
| postgres:14.18 | `registry.cn-hangzhou.aliyuncs.com/xfg-studio/postgres:14.18` | PostgreSQL 14 |
| pgvector/pgvector:pg17 | `registry.cn-hangzhou.aliyuncs.com/xfg-studio/pgvector:pg17` | PostgreSQL 向量库 |
| **缓存** | | |
| redis:6.2 | `registry.cn-hangzhou.aliyuncs.com/xfg-studio/redis:6.2` | Redis 6.2 |
| redis:7.2 | `registry.cn-hangzhou.aliyuncs.com/xfg-studio/redis:7.2` | Redis 7.2 |
| redis:7.4.13 | `registry.cn-hangzhou.aliyuncs.com/xfg-studio/redis:7.2/7.4.13` | Redis 7.4 |
| **数据库管理** | | |
| phpmyadmin:5.2.1 | `registry.cn-hangzhou.aliyuncs.com/xfg-studio/phpmyadmin:5.2.1` | MySQL Web 管理 |
| redis-commander:0.8.0 | `registry.cn-hangzhou.aliyuncs.com/xfg-studio/redis-commander:0.8.0` | Redis Web 管理 |
| dpage/pgadmin4:9.1.0 | `registry.cn-hangzhou.aliyuncs.com/xfg-studio/pgadmin4:9.1.0` | PostgreSQL Web 管理 |
| **消息队列** | | |
| rabbitmq:3.12.9 | `registry.cn-hangzhou.aliyuncs.com/xfg-studio/rabbitmq:3.12.9` | RabbitMQ |
| rocketmq:5.1.0 | `registry.cn-hangzhou.aliyuncs.com/xfg-studio/rocketmq:5.1.0` | RocketMQ |
| kafka:3.7.0 | `registry.cn-hangzhou.aliyuncs.com/xfg-studio/kafka:3.7.0` | Kafka |
| kafka-eagle:3.0.2 | `registry.cn-hangzhou.aliyuncs.com/xfg-studio/kafka-eagle:3.0.2` | Kafka Eagle |
| **注册中心/配置中心** | | |
| nacos-server:v2.2.3-slim | `registry.cn-hangzhou.aliyuncs.com/xfg-studio/nacos-server:v2.2.3-slim` | Nacos 2.2.3 |
| nacos-server:v3.1.1 | `registry.cn-hangzhou.aliyuncs.com/xfg-studio/nacos-server:v3.1.1` | Nacos 3.1.1 |
| **Web 服务器** | | |
| nginx:1.25.1 | `registry.cn-hangzhou.aliyuncs.com/xfg-studio/nginx:1.25.1` | Nginx 1.25 |
| nginx:1.28.0-alpine | `registry.cn-hangzhou.aliyuncs.com/xfg-studio/nginx:1.28.0-alpine` | Nginx 1.28 Alpine |
| **任务调度** | | |
| xxl-job-admin:2.4.0 | `registry.cn-hangzhou.aliyuncs.com/xfg-studio/xxl-job-admin:2.4.0` | XXL-Job 管理端 |
| xxl-job-aarch64:2.4.0 | `registry.cn-hangzhou.aliyuncs.com/xfg-studio/xxl-job-aarch64:2.4.0` | XXL-Job ARM 版本 |
| **监控** | | |
| prometheus:2.47.2 | `registry.cn-hangzhou.aliyuncs.com/xfg-studio/prometheus:2.47.2` | Prometheus |
| grafana:10.2.0 | `registry.cn-hangzhou.aliyuncs.com/xfg-studio/grafana:10.2.0` | Grafana |
| skywalking-oap-server:9.3.0 | `registry.cn-hangzhou.aliyuncs.com/xfg-studio/skywalking-oap-server:9.3.0` | SkyWalking OAP |
| skywalking-ui:9.3.0 | `registry.cn-hangzhou.aliyuncs.com/xfg-studio/skywalking-ui:9.3.0` | SkyWalking UI |
| **搜索引擎** | | |
| elasticsearch:7.17.14 | `registry.cn-hangzhou.aliyuncs.com/xfg-studio/elasticsearch:7.17.14` | Elasticsearch |
| kibana:7.17.14 | `registry.cn-hangzhou.aliyuncs.com/xfg-studio/kibana:7.17.14` | Kibana |
| **Node** | | |
| node:18-alpine | `registry.cn-hangzhou.aliyuncs.com/xfg-studio/node:18-alpine` | Node 18 |
| node:20-alpine | `registry.cn-hangzhou.aliyuncs.com/xfg-studio/node:20-alpine` | Node 20 |
| **AI/工具** | | |
| ollama/ollama:0.5.10 | `registry.cn-hangzhou.aliyuncs.com/xfg-studio/ollama:0.5.10` | Ollama |
| n8nio/n8n:1.88.0 | `registry.cn-hangzhou.aliyuncs.com/xfg-studio/n8n:1.88.0` | N8N 工作流 |
| **其他** | | |
| alpine:3.20.1 | `registry.cn-hangzhou.aliyuncs.com/xfg-studio/alpine:3.20.1` | Alpine Linux |
| portainer:latest | `registry.cn-hangzhou.aliyuncs.com/xfg-studio/portainer:latest` | Docker 可视化管理 |
| jenkins:2.439 | `registry.cn-hangzhou.aliyuncs.com/xfg-studio/jenkins:2.439` | Jenkins |
| sentinel-dashboard:1.8.7 | `registry.cn-hangzhou.aliyuncs.com/xfg-studio/sentinel-dashboard:1.8.7` | Sentinel 流量控制 |
| canal-server:v1.1.6 | `registry.cn-hangzhou.aliyuncs.com/xfg-studio/canal-server:v1.1.6` | Canal |
| zookeeper:3.9.0 | `registry.cn-hangzhou.aliyuncs.com/xfg-studio/zookeeper:3.9.0` | Zookeeper |

### 拉取镜像示例

```bash
# 拉取 MySQL
docker pull registry.cn-hangzhou.aliyuncs.com/xfg-studio/mysql:8.0.32

# 拉取 Redis
docker pull registry.cn-hangzhou.aliyuncs.com/xfg-studio/redis:6.2

# 拉取 Java 17
docker pull registry.cn-hangzhou.aliyuncs.com/xfg-studio/openjdk:17-jdk-slim
```

---

## ⚠️ 常见问题处理

### 1. MySQL 8.0 认证问题
```bash
docker exec mysql mysql -uroot -p123456 -e "ALTER USER 'root'@'%' IDENTIFIED WITH mysql_native_password BY '123456'; FLUSH PRIVILEGES;"
```

### 2. 容器网络不通
确保所有容器在同一个网络：
```yaml
networks:
  - my-network
```

### 3. 端口冲突
修改 docker-compose.yml 中的端口映射：
```yaml
ports:
  - "13306:3306"  # 改为非标准端口
```

### 4. 应用无法连接数据库
检查环境变量配置和健康检查依赖：
```yaml
depends_on:
  mysql:
    condition: service_healthy
```

---

## 📝 部署操作流程示例

当用户说"帮我部署 ai-mcp-gateway"时，执行：

1. **确认项目信息**
   - 项目路径：`/Users/fuzhengwei/Documents/project/ddd-demo/ai-mcp-gateway`
   - 端口：`8091`
   - 镜像：`system/ai-mcp-gateway:1.0.0`

2. **执行部署**
```bash
# 进入项目目录
cd /Users/fuzhengwei/Documents/project/ddd-demo/ai-mcp-gateway

# 打包
mvn clean package -Dmaven.test.skip=true

# 构建 Docker 镜像
cd ai-mcp-gateway-app
docker build -t system/ai-mcp-gateway:1.0.0 .

# 部署基础环境
cd ../docs/dev-ops
docker-compose -f docker-compose-environment-aliyun.yml up -d

# 等待 MySQL 就绪
sleep 30

# 初始化数据库
docker exec -i mysql mysql -uroot -p123456 < mysql/sql/ai_mcp_gateway_v2.sql

# 启动应用
docker-compose -f docker-compose-app.yml up -d

# 验证
docker ps | grep ai-mcp-gateway
curl http://localhost:8091/api/gateway/list
```

3. **部署完成检查**
   - 容器状态正常
   - 日志无报错
   - 健康检查通过
