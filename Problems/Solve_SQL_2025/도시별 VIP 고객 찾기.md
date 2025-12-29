# 1227_도시별 VIP 고객 찾기

### 특정 그룹의 MAX 값만 도출하는 것이 POINT

#### 언제 구조를 바꿔야 하나? (바로 HAVING 못씀)
1. **DB에서 특정 집계를 해**
2. **집계 단위에서 XX별 MAX만 필터링하고 싶다**

#### 구조 전환 트리거
이 말이 나오면 자동으로 떠올려야 할 생각:
> “아, 이건 행 간 비교구나”

-   → WHERE / HAVING 단독 ❌
-   → **기준 테이블 필요** ⭕

#### 3. 기본 테이블 – MAX 테이블을 만들어 JOIN
**완벽한 결론**
이건 사실 SQL에서 **가장 안전한 패턴**이야.
-   명시적
-   디버깅 쉬움
-   확장 쉬움 (TOP 3, 평균 대비 등)

그리고 네가 말한 이 문장:
> “도시의 MAX 수치를 뽑으면 그 수치를 가진 사람이 누구인지는 바로 알 수 있다”

👉 **관계형 사고의 핵심 문장이야.**

---

### SQL Code
```sql
WITH
  city_customer AS (
    SELECT
      city_id,
      customer_id,
      SUM(total_price - discount_amount) AS total_spent
    FROM
      transactions
    where
      is_returned = 0
    GROUP BY
      city_id,
      customer_id
  ),
  city_max AS (
    SELECT
      city_id,
      MAX(total_spent) AS MAX_SPENT
    FROM
      city_customer
    GROUP BY
      city_id
  )
SELECT
  cc.city_id,
  cc.customer_id,
  cc.total_spent
FROM
  city_customer cc
  JOIN city_max cm ON cc.city_id = cm.city_id
  AND cc.total_spent = cm.MAX_SPENT
```
