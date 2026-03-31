# xfg-ddd-skills · DDD 六边形架构技能包

> 基于领域驱动设计（DDD）与六边形架构（Hexagonal Architecture）的软件设计与实现指南。
> 配套 Maven 脚手架 `ddd-scaffold-std-jdk17`，一键生成标准多模块工程。

---

## 目录

- [快速开始](#快速开始)
  - [方式一：AI 一键生成（推荐）](#方式一ai-一键生成推荐)
  - [方式二：Maven 命令行生成](#方式二maven-命令行生成)
  - [方式三：配置在线脚手架仓库](#方式三配置在线脚手架仓库)
- [架构概览](#架构概览)
- [模块结构](#模块结构)
- [核心设计原则](#核心设计原则)
- [参考文档](#参考文档)
- [参考项目](#参考项目)

---

## 快速开始

### 方式一：AI 一键生成（推荐）

在 QClaw 中直接说：

```
帮我在 /path/to/workspace 创建一个 DDD 项目，名称为 xfg-xxx
```

AI 会自动调用脚手架，生成完整的多模块工程。

---

### 方式二：Maven 命令行生成

确保已安装 **JDK 17+** 和 **Maven 3.8+**，执行：

```bash
mvn archetype:generate \
  -DarchetypeGroupId=io.github.fuzhengwei \
  -DarchetypeArtifactId=ddd-scaffold-std-jdk17 \
  -DarchetypeVersion=1.8 \
  -DarchetypeRepository=https://maven.xiaofuge.cn/ \
  -DgroupId=cn.bugstack \
  -DartifactId=your-project-name \
  -Dversion=1.0.0-SNAPSHOT \
  -Dpackage=cn.bugstack.your.project \
  -B
```

| 参数 | 说明 | 示例 |
|------|------|------|
| `groupId` | Maven 组织标识 | `cn.bugstack` |
| `artifactId` | 项目名称 | `xfg-form` |
| `version` | 版本号 | `1.0.0-SNAPSHOT` |
| `package` | Java 根包名 | `cn.bugstack.xfg.form` |

---

### 方式三：配置在线脚手架仓库

将脚手架仓库配置到 Maven `settings.xml`，之后可在 IDEA 的 **New Project → Maven Archetype** 中直接选用，无需每次手动指定 `-DarchetypeRepository`。

#### 1. 编辑 `~/.m2/settings.xml`

在 `<profiles>` 节点中添加以下配置：

```xml
<profiles>
  <profile>
    <id>xfg-archetype</id>
    <repositories>
      <repository>
        <id>xfg-archetype-repo</id>
        <name>小傅哥 DDD 脚手架仓库</name>
        <url>https://maven.xiaofuge.cn/</url>
        <releases>
          <enabled>true</enabled>
        </releases>
        <snapshots>
          <enabled>false</enabled>
        </snapshots>
      </repository>
    </repositories>
    <pluginRepositories>
      <pluginRepository>
        <id>xfg-archetype-plugin-repo</id>
        <name>小傅哥 DDD 脚手架插件仓库</name>
        <url>https://maven.xiaofuge.cn/</url>
        <releases>
          <enabled>true</enabled>
        </releases>
        <snapshots>
          <enabled>false</enabled>
        </snapshots>
      </pluginRepository>
    </pluginRepositories>
  </profile>
</profiles>

<activeProfiles>
  <activeProfile>xfg-archetype</activeProfile>
</activeProfiles>
```

#### 2. 更新本地 Archetype 目录

```bash
mvn archetype:update-local-catalog
```

或直接拉取 Archetype 到本地缓存：

```bash
mvn dependency:get \
  -Dartifact=io.github.fuzhengwei:ddd-scaffold-std-jdk17:1.8:jar:archetype \
  -DremoteRepositories=xfg-archetype-repo::::https://maven.xiaofuge.cn/
```

#### 3. 在 IDEA 中使用

1. `File → New → Project → Maven Archetype`
2. 在 Archetype 列表中搜索 `ddd-scaffold-std-jdk17`
3. 填写 `groupId`、`artifactId`、`version`，点击 Create

> 如果列表中未出现，点击 **Add Archetype** 手动填写：
> - **GroupId**：`io.github.fuzhengwei`
> - **ArtifactId**：`ddd-scaffold-std-jdk17`
> - **Version**：`1.8`
> - **Repository**：`https://maven.xiaofuge.cn/`

---

## 架构概览

```
┌─────────────────────────────────────────────────────────────┐
│                      触发层 Trigger                          │
│              (HTTP Controller / MQ Listener / Job)           │
└─────────────────────────┬───────────────────────────────────┘
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                       API 层                                 │
│                  (DTO / Request / Response)                  │
└─────────────────────────┬───────────────────────────────────┘
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                      编排层 Case                             │
│              (业务编排 / 流程串联 / 跨域协作)                 │
└─────────────────────────┬───────────────────────────────────┘
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                      领域层 Domain                           │
│          (Entity / Aggregate / VO / Domain Service)         │
└─────────────────────────┬───────────────────────────────────┘
                          ▲
┌─────────────────────────────────────────────────────────────┐
│                  基础设施层 Infrastructure                   │
│        (Repository Impl / Port Adapter / DAO / PO)          │
└─────────────────────────────────────────────────────────────┘
```

**依赖规则**：`Trigger → API → Case → Domain ← Infrastructure`

---

## 模块结构

脚手架生成的标准多模块工程：

```
your-project/
├── your-project-api/           # 对外接口层：DTO、Request、Response
├── your-project-app/           # 启动入口：Spring Boot Application
├── your-project-case/          # 编排层：跨域业务流程编排
├── your-project-domain/        # 领域层：Entity、Aggregate、VO、Service
├── your-project-infrastructure/# 基础设施层：Repository 实现、DAO、PO
├── your-project-trigger/       # 触发层：HTTP Controller、MQ Listener、Job
├── your-project-types/         # 公共类型：枚举、常量、通用 VO
├── docs/
│   └── dev-ops/
│       ├── docker-compose-environment.yml        # 基础环境（MySQL/Redis/MQ）
│       ├── docker-compose-environment-aliyun.yml # 阿里云加速版
│       └── docker-compose-app.yml                # 应用服务
└── pom.xml                     # 父 POM
```

### Domain 层目录规范

```
domain/{bounded-context}/
├── adapter/
│   ├── port/                   # 外部系统端口接口（防腐层）
│   │   └── IXxxPort.java
│   └── repository/             # 仓储接口
│       └── IXxxRepository.java
├── model/
│   ├── aggregate/              # 聚合对象
│   ├── entity/                 # 实体（含命令实体 XxxCommandEntity）
│   └── valobj/                 # 值对象（含枚举 XxxEnumVO）
└── service/                    # 领域服务
    ├── IXxxService.java
    └── {capability}/
        └── XxxServiceImpl.java
```

---

## 核心设计原则

| 原则 | 描述 |
|------|------|
| **依赖倒置** | Domain 定义接口，Infrastructure 实现，依赖永远指向 Domain |
| **富领域模型** | Entity 同时包含数据与行为，避免贫血模型 |
| **聚合边界** | 聚合内强一致性，聚合间通过领域事件实现最终一致性 |
| **防腐层** | 通过 Port 接口隔离外部系统，防止外部概念污染领域 |
| **轻量触发** | Trigger 层只做路由与参数转换，不含业务逻辑 |
| **策略模式** | 多种处理方式用 `IXxxStrategy` + `Map<String, IXxxStrategy>` 注入 |
| **责任链模式** | 多步校验/过滤用 `IXxxFilter` + Factory 组装链 |

---

## 参考文档

| 主题 | 文档 |
|------|------|
| 架构概览 | [references/architecture.md](references/architecture.md) |
| 实体设计 | [references/entity.md](references/entity.md) |
| 聚合根设计 | [references/aggregate.md](references/aggregate.md) |
| 值对象设计 | [references/value-object.md](references/value-object.md) |
| 仓储模式 | [references/repository.md](references/repository.md) |
| 端口与适配器 | [references/port-adapter.md](references/port-adapter.md) |
| 领域服务 | [references/domain-service.md](references/domain-service.md) |
| 编排层设计 | [references/case-layer.md](references/case-layer.md) |
| 触发层设计 | [references/trigger-layer.md](references/trigger-layer.md) |
| 基础设施层 | [references/infrastructure-layer.md](references/infrastructure-layer.md) |
| 领域设计指南 | [references/domain-design-guide.md](references/domain-design-guide.md) |
| 领域核心模式 | [references/domain-patterns.md](references/domain-patterns.md) |
| 基础设施模式 | [references/infrastructure-patterns.md](references/infrastructure-patterns.md) |
| DevOps 部署 | [references/devops-deployment.md](references/devops-deployment.md) |
| 项目结构 | [references/project-structure.md](references/project-structure.md) |
| 命名规范 | [references/naming.md](references/naming.md) |
| Docker 镜像 | [references/docker-images.md](references/docker-images.md) |

---

## 参考项目

| 项目 | 说明 |
|------|------|
| [group-buy-market](https://bugstack.cn/md/project/group-buy-market/group-buy-market.html) | 拼团营销领域完整实现，含策略模式、责任链、领域事件 |
| [ai-mcp-gateway](https://bugstack.cn/md/project/ai-mcp-gateway/ai-mcp-gateway.html) | AI MCP 网关领域完整实现，含端口适配器、多模型路由 |

---

## License

MIT © [小傅哥 bugstack.cn](https://bugstack.cn)
