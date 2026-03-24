# Value Object Design Reference

## Table of Contents

1. [What is a Value Object](#1-what-is-a-value-object)
2. [Immutability](#2-immutability)
3. [Equality](#3-equality)
4. [Value Object Template](#4-value-object-template)
5. [Common Patterns](#5-common-patterns)
6. [When to Use](#6-when-to-use)

---

## 1. What is a Value Object

A Value Object is:
- **Immutable** - Cannot change after creation
- **No identity** - Equality based on properties, not ID
- **Describes things** - Measures, quantities, ranges

### Entity vs Value Object

| Aspect | Entity | Value Object |
|--------|--------|--------------|
| Identity | Has unique ID | No identity |
| Equality | By identity | By all properties |
| Mutability | Mutable | Immutable |
| Lifecycle | Has lifecycle | No lifecycle |
| Example | Order, User | Money, Address, DateRange |

---

## 2. Immutability

### Why Immutable?

- **Thread-safe** - No synchronization needed
- **Predictable** - No unexpected changes
- **Hash-safe** - Safe as HashMap keys
- **Simple** - No state management

### Implementation

```java
// ✅ Immutable: No setters, final fields
@Getter
public final class MoneyVO {
    private final BigDecimal amount;
    private final String currency;
    
    private MoneyVO(BigDecimal amount, String currency) {
        this.amount = amount;
        this.currency = currency;
    }
    
    // Operations return new instances
    public MoneyVO add(MoneyVO other) {
        return new MoneyVO(amount.add(other.amount), currency);
    }
}
```

---

## 3. Equality

### Override equals and hashCode

```java
@Getter
public final class AddressVO {
    private final String province;
    private final String city;
    private final String district;
    private final String detail;
    
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        AddressVO that = (AddressVO) o;
        return Objects.equals(province, that.province)
            && Objects.equals(city, that.city)
            && Objects.equals(district, that.district)
            && Objects.equals(detail, that.detail);
    }
    
    @Override
    public int hashCode() {
        return Objects.hash(province, city, district, detail);
    }
}
```

---

## 4. Value Object Template

### Basic Template

```java
/**
 * {Domain} Value Object
 * 
 * Immutable representation of {concept}.
 */
@Getter
public final class {Domain}VO {

    private final {Type} property1;
    private final {Type} property2;

    private {Domain}VO({Type} property1, {Type} property2) {
        this.property1 = property1;
        this.property2 = property2;
    }
    
    /**
     * Factory method
     */
    public static {Domain}VO of({Type} property1, {Type} property2) {
        // Validation
        if (property1 == null) {
            throw new IllegalArgumentException("property1 required");
        }
        return new {Domain}VO(property1, property2);
    }
    
    /**
     * Operations return new instances
     */
    public {Domain}VO withProperty1({Type} newValue) {
        return new {Domain}VO(newValue, this.property2);
    }
    
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        {Domain}VO that = ({Domain}VO) o;
        return Objects.equals(property1, that.property1)
            && Objects.equals(property2, that.property2);
    }
    
    @Override
    public int hashCode() {
        return Objects.hash(property1, property2);
    }
}
```

### Complete Examples

#### Money Value Object

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
        if (amount == null) {
            throw new IllegalArgumentException("amount required");
        }
        if (currency == null || currency.isEmpty()) {
            currency = "CNY";
        }
        return new MoneyVO(amount, currency);
    }
    
    public static MoneyVO zero(String currency) {
        return new MoneyVO(BigDecimal.ZERO, currency);
    }
    
    public MoneyVO add(MoneyVO other) {
        validateSameCurrency(other);
        return new MoneyVO(amount.add(other.amount), currency);
    }
    
    public MoneyVO subtract(MoneyVO other) {
        validateSameCurrency(other);
        return new MoneyVO(amount.subtract(other.amount), currency);
    }
    
    public MoneyVO multiply(BigDecimal factor) {
        return new MoneyVO(amount.multiply(factor), currency);
    }
    
    public boolean isPositive() {
        return amount.compareTo(BigDecimal.ZERO) > 0;
    }
    
    public boolean isZero() {
        return amount.compareTo(BigDecimal.ZERO) == 0;
    }
    
    private void validateSameCurrency(MoneyVO other) {
        if (!currency.equals(other.currency)) {
            throw new IllegalArgumentException("Currency mismatch");
        }
    }
    
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        MoneyVO moneyVO = (MoneyVO) o;
        return Objects.equals(amount, moneyVO.amount)
            && Objects.equals(currency, moneyVO.currency);
    }
    
    @Override
    public int hashCode() {
        return Objects.hash(amount, currency);
    }
}
```

#### Address Value Object

```java
@Getter
public final class AddressVO {
    private final String province;
    private final String city;
    private final String district;
    private final String detail;
    private final String postalCode;
    
    private AddressVO(String province, String city, String district, 
                      String detail, String postalCode) {
        this.province = province;
        this.city = city;
        this.district = district;
        this.detail = detail;
        this.postalCode = postalCode;
    }
    
    public static AddressVO of(String province, String city, 
                               String district, String detail) {
        return new AddressVO(province, city, district, detail, null);
    }
    
    public static AddressVO full(String province, String city, 
                                 String district, String detail, 
                                 String postalCode) {
        return new AddressVO(province, city, district, detail, postalCode);
    }
    
    public AddressVO withDetail(String newDetail) {
        return new AddressVO(province, city, district, newDetail, postalCode);
    }
    
    public String fullAddress() {
        StringBuilder sb = new StringBuilder();
        if (province != null) sb.append(province);
        if (city != null) sb.append(city);
        if (district != null) sb.append(district);
        if (detail != null) sb.append(detail);
        return sb.toString();
    }
    
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        AddressVO addressVO = (AddressVO) o;
        return Objects.equals(province, addressVO.province)
            && Objects.equals(city, addressVO.city)
            && Objects.equals(district, addressVO.district)
            && Objects.equals(detail, addressVO.detail)
            && Objects.equals(postalCode, addressVO.postalCode);
    }
    
    @Override
    public int hashCode() {
        return Objects.hash(province, city, district, detail, postalCode);
    }
}
```

---

## 5. Common Patterns

### Enum as Value Object

```java
@Getter
@AllArgsConstructor
public enum OrderStatusEnum {
    PENDING(0, "待支付"),
    PAID(1, "已支付"),
    DELIVERED(2, "已发货"),
    CANCELLED(9, "已取消");
    
    private final Integer code;
    private final String desc;
    
    public static OrderStatusEnum valueOf(Integer code) {
        if (code == null) return PENDING;
        for (OrderStatusEnum status : values()) {
            if (status.code.equals(code)) {
                return status;
            }
        }
        return PENDING;
    }
    
    public boolean canPay() {
        return this == PENDING;
    }
    
    public boolean canCancel() {
        return this == PENDING || this == PAID;
    }
}
```

### Composite Value Object

```java
@Getter
public final class DateRangeVO {
    private final LocalDateTime start;
    private final LocalDateTime end;
    
    private DateRangeVO(LocalDateTime start, LocalDateTime end) {
        if (start != null && end != null && start.isAfter(end)) {
            throw new IllegalArgumentException("Start must be before end");
        }
        this.start = start;
        this.end = end;
    }
    
    public static DateRangeVO of(LocalDateTime start, LocalDateTime end) {
        return new DateRangeVO(start, end);
    }
    
    public boolean contains(LocalDateTime date) {
        if (date == null) return false;
        boolean afterStart = start == null || !date.isBefore(start);
        boolean beforeEnd = end == null || !date.isAfter(end);
        return afterStart && beforeEnd;
    }
    
    public long days() {
        if (start == null || end == null) return 0;
        return ChronoUnit.DAYS.between(start, end);
    }
}
```

---

## 6. When to Use

### Use Value Object when:

- Describing measurements (Money, Weight, Distance)
- Representing ranges (DateRange, NumberRange)
- Composite attributes (Address, FullName)
- Type-safe identifiers (OrderId, UserId)
- Enumerated types (Status, Type)

### Don't use Value Object when:

- Object needs identity (use Entity)
- State changes over time (use Entity)
- Need to track lifecycle (use Entity)