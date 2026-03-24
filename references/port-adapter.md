# Port & Adapter Reference

## What is a Port

A Port is an interface defined in Domain layer that:
- Describes interaction with external systems
- Keeps domain isolated from infrastructure
- Enables dependency inversion

## What is an Adapter

An Adapter implements a Port in Infrastructure layer:
- Handles actual external calls
- Converts between domain and external formats
- Isolates external system changes

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Domain Layer                           │
│  ┌─────────────────────────────────────────────────────┐  │
│  │  Domain Service                                      │  │
│  │  calls: userPort.checkUser(userId)                   │  │
│  └─────────────────────────────────────────────────────┘  │
│                          │                                  │
│                          ▼                                  │
│  ┌─────────────────────────────────────────────────────┐  │
│  │  Port Interface (IUserPort)                         │  │
│  │  - checkUser(userId): boolean                       │  │
│  │  - getUserInfo(userId): UserInfoVO                  │  │
│  └─────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                          │
                          │ implements
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                  Infrastructure Layer                       │
│  ┌─────────────────────────────────────────────────────┐  │
│  │  Port Adapter (UserHttpPortImpl)                    │  │
│  │  - Calls HTTP service                               │  │
│  │  - Converts DTO ↔ Domain Object                     │  │
│  └─────────────────────────────────────────────────────┘  │
│                          │                                  │
│                          ▼                                  │
│  ┌─────────────────────────────────────────────────────┐  │
│  │  External System (HTTP / RPC / MQ / DB)            │  │
│  └─────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Port Interface Template

```java
// Domain Layer
public interface I{Domain}Port {
    
    /**
     * {Operation description}
     * 
     * @param command Input (domain object)
     * @return result Output (domain object)
     */
    ResultVO operation(CommandVO command);
}
```

## Port Adapter Templates

### HTTP Adapter

```java
@Service
public class {Domain}HttpPortImpl implements I{Domain}Port {
    
    @Resource
    private RestTemplate restTemplate;
    
    @Value("${external.service.url}")
    private String serviceUrl;

    @Override
    public ResultVO operation(CommandVO command) {
        try {
            // Convert domain object to DTO
            RequestDTO request = toDTO(command);
            
            // Call external service
            ResponseDTO response = restTemplate.postForObject(
                serviceUrl + "/api/operation",
                request,
                ResponseDTO.class
            );
            
            // Convert DTO to domain object
            return toDomainObject(response);
            
        } catch (Exception e) {
            log.error("External call failed", e);
            throw new ExternalServiceException("Service unavailable");
        }
    }
    
    private RequestDTO toDTO(CommandVO command) {
        RequestDTO dto = new RequestDTO();
        dto.setField(command.getField());
        return dto;
    }
    
    private ResultVO toDomainObject(ResponseDTO response) {
        return ResultVO.of(response.getData());
    }
}
```

### Redis Adapter

```java
@Service
public class {Domain}CachePortImpl implements I{Domain}CachePort {
    
    @Resource
    private RedisTemplate<String, Object> redisTemplate;
    
    private static final String KEY_PREFIX = "domain:";

    @Override
    public void cache(String key, {Domain}VO value) {
        String fullKey = KEY_PREFIX + key;
        redisTemplate.opsForValue().set(fullKey, value, Duration.ofHours(24));
    }

    @Override
    public {Domain}VO get(String key) {
        String fullKey = KEY_PREFIX + key;
        Object value = redisTemplate.opsForValue().get(fullKey);
        return value instanceof {Domain}VO ? ({Domain}VO) value : null;
    }

    @Override
    public void evict(String key) {
        String fullKey = KEY_PREFIX + key;
        redisTemplate.delete(fullKey);
    }
}
```

### MQ Adapter

```java
@Service
public class {Domain}MessagePortImpl implements I{Domain}MessagePort {
    
    @Resource
    private RocketMQTemplate rocketMQTemplate;
    
    @Value("${mq.topic}")
    private String topic;

    @Override
    public void send(MessageVO message) {
        rocketMQTemplate.asyncSend(topic, message, new SendCallback() {
            @Override
            public void onSuccess(SendResult result) {
                log.info("Message sent: {}", result.getMsgId());
            }
            
            @Override
            public void onException(Throwable e) {
                log.error("Message send failed", e);
            }
        });
    }
}
```

## Anti-Corruption Layer

The Port/Adapter pattern creates an anti-corruption layer that:
- Prevents external concepts from leaking into domain
- Allows domain to stay pure
- Makes external system changes manageable

```java
// External system returns different status codes
// Port adapter translates to domain concepts

@Override
public OrderStatusVO getOrderStatus(String orderId) {
    ExternalOrderDTO external = externalService.getOrder(orderId);
    
    // Translate external status to domain status
    switch (external.getStatusCode()) {
        case "ORDER_CREATED":
            return OrderStatusVO.PENDING;
        case "PAYMENT_DONE":
            return OrderStatusVO.PAID;
        case "SHIPPED":
            return OrderStatusVO.DELIVERED;
        default:
            return OrderStatusVO.UNKNOWN;
    }
}
```

## Best Practices

### Do
- ✅ Define port interface in Domain layer
- ✅ Implement adapter in Infrastructure layer
- ✅ Convert between domain and external formats
- ✅ Handle exceptions gracefully
- ✅ Log external calls

### Don't
- ❌ Let external DTO leak into domain
- ❌ Put business logic in adapters
- ❌ Skip error handling
- ❌ Hardcode URLs/config