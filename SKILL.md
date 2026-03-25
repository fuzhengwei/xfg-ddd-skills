---
name: ddd-skills
version: 2.0.0
description: "DDD 六边形架构设计与开发技能包。当你需要设计或实现 DDD 领域驱动设计项目时使用，包括：六边形架构、端口与适配器、领域层设计（Entity/Aggregate/Value Object/Repository/Domain Service）、业务编排层（Case Layer）、触发层（Trigger Layer）、基础设施层（Infrastructure Layer）。触发词：'DDD'、'六边形架构'、'领域驱动设计'、'创建 DDD 项目'、'新建项目'。不要用于简单 CRUD 应用或没有领域复杂度的微服务。@小傅哥"
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
  - "创建 DDD 项目"
  - "新建项目"
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

**流程:**

1. **第一步：选择项目生成目录**

   脚本会自动扫描可写目录（当前工作目录、用户 home 目录、home/workspace、home/Documents/projects 等），列出选项供用户选择，或输入自定义绝对路径。

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
    @Resource private IOrderCaseService orderCaseService;
    
    @PostMapping("/create")
    public Response<OrderDTO> create(@RequestBody @Valid CreateOrderRequest request) {
        return orderCaseService.createOrder(request);
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
