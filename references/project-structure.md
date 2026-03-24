# Project Structure Reference

## Maven Multi-Module Structure

```
{project-name}/
├── pom.xml                          # Parent POM
├── {project}-types/                 # Common types
│   ├── pom.xml
│   └── src/main/java/
│       └── cn/{company}/types/
│           ├── enums/               # Enums
│           ├── exception/           # Exceptions
│           └── common/              # Common utils
│
├── {project}-domain/                # Domain layer
│   ├── pom.xml
│   └── src/main/java/
│       └── cn/{company}/domain/
│           ├── {domain1}/
│           │   ├── adapter/
│           │   │   ├── port/         # Port interfaces
│           │   │   └── repository/   # Repository interfaces
│           │   ├── model/
│           │   │   ├── aggregate/    # Aggregates
│           │   │   ├── entity/       # Entities
│           │   │   └── valobj/       # Value objects
│           │   └── service/          # Domain services
│           │       ├── I{Domain}Service.java
│           │       └── impl/
│           └── {domain2}/
│               └── ...
│
├── {project}-infrastructure/        # Infrastructure layer
│   ├── pom.xml
│   └── src/main/java/
│       └── cn/{company}/infrastructure/
│           ├── adapter/
│           │   ├── port/             # Port implementations
│           │   └── repository/       # Repository implementations
│           ├── dao/                  # DAO interfaces
│           ├── dataobject/           # PO classes
│           ├── gateway/              # External service clients
│           └── config/               # Configurations
│
├── {project}-api/                   # API layer
│   ├── pom.xml
│   └── src/main/java/
│       └── cn/{company}/api/
│           ├── I{Domain}Service.java # RPC interfaces
│           ├── dto/                  # DTOs
│           └── error/                # Error codes
│
├── {project}-case/                  # Case layer
│   ├── pom.xml
│   └── src/main/java/
│       └── cn/{company}/cases/
│           └── {domain}/
│               ├── I{Domain}CaseService.java
│               └── impl/
│
├── {project}-trigger/               # Trigger layer
│   ├── pom.xml
│   └── src/main/java/
│       └── cn/{company}/trigger/
│           ├── http/                 # Controllers
│           ├── mq/                   # MQ listeners
│           └── job/                  # Scheduled jobs
│
└── {project}-app/                   # Application (main)
    ├── pom.xml
    └── src/main/
        ├── java/
        │   └── cn/{company}/
        │       └── Application.java
        └── resources/
            └── application.yml
```

## POM Dependencies

### Parent POM

```xml
<project>
    <groupId>cn.{company}</groupId>
    <artifactId>{project}</artifactId>
    <version>1.0.0</version>
    <packaging>pom</packaging>
    
    <modules>
        <module>{project}-types</module>
        <module>{project}-domain</module>
        <module>{project}-infrastructure</module>
        <module>{project}-api</module>
        <module>{project}-case</module>
        <module>{project}-trigger</module>
        <module>{project}-app</module>
    </modules>
    
    <dependencyManagement>
        <dependencies>
            <!-- Internal modules -->
            <dependency>
                <groupId>${project.groupId}</groupId>
                <artifactId>{project}-types</artifactId>
                <version>${project.version}</version>
            </dependency>
            <dependency>
                <groupId>${project.groupId}</groupId>
                <artifactId>{project}-domain</artifactId>
                <version>${project.version}</version>
            </dependency>
            <!-- ... -->
        </dependencies>
    </dependencyManagement>
</project>
```

### Domain POM

```xml
<project>
    <artifactId>{project}-domain</artifactId>
    
    <dependencies>
        <!-- Only types, no infrastructure! -->
        <dependency>
            <groupId>${project.groupId}</groupId>
            <artifactId>{project}-types</artifactId>
        </dependency>
    </dependencies>
</project>
```

### Infrastructure POM

```xml
<project>
    <artifactId>{project}-infrastructure</artifactId>
    
    <dependencies>
        <!-- Domain for interfaces -->
        <dependency>
            <groupId>${project.groupId}</groupId>
            <artifactId>{project}-domain</artifactId>
        </dependency>
        
        <!-- Infrastructure frameworks -->
        <dependency>
            <groupId>org.mybatis.spring.boot</groupId>
            <artifactId>mybatis-spring-boot-starter</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-redis</artifactId>
        </dependency>
    </dependencies>
</project>
```

### Trigger POM

```xml
<project>
    <artifactId>{project}-trigger</artifactId>
    
    <dependencies>
        <dependency>
            <groupId>${project.groupId}</groupId>
            <artifactId>{project}-api</artifactId>
        </dependency>
        <dependency>
            <groupId>${project.groupId}</groupId>
            <artifactId>{project}-case</artifactId>
        </dependency>
    </dependencies>
</project>
```

## Dependency Rules

```
┌─────────────────────────────────────────────────────────────┐
│                       app                                   │
│                    (all modules)                            │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                     trigger                                 │
│                   (api, case)                               │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                      case                                   │
│                   (api, domain)                             │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                      api                                    │
│                    (types)                                  │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                     domain                                  │
│                    (types)                                  │
└─────────────────────────┬───────────────────────────────────┘
                          ▲
                          │
┌─────────────────────────────────────────────────────────────┐
│                  infrastructure                             │
│                   (domain)                                  │
└─────────────────────────────────────────────────────────────┘
```

## Critical Rules

1. **Domain has NO infrastructure dependencies**
2. **Infrastructure implements Domain interfaces**
3. **Trigger depends on API and Case only**
4. **All modules depend on Types**