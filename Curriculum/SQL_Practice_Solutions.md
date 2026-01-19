# SQL 실습 문제 정답 및 핵심 포인트

> **XAMPP MySQL `practice` 데이터베이스 기준**
> 이 문서는 로컬 환경에서 실습할 수 있는 문제와 정답입니다.

---

## 사용 가능한 테이블

| 테이블 | 컬럼 | 설명 |
|--------|------|------|
| `users` | id, name, email, birth_date, created_at, utm_source | 고객 30명 |
| `stores` | id, name, region, opened_at | 매장 5개 |
| `products` | id, name, category, size, price | 상품 15개 |
| `orders` | id, user_id, store_id, order_datetime, total_amount | 주문 100건 |
| `order_items` | id, order_id, product_id, quantity, unit_price | 주문상세 15건 |
| `app_logs` | id, user_id, event_name, event_date, event_time | 앱로그 47건 |
| `marketing_costs` | id, ym, channel, cost | 마케팅비용 12건 |
| `campaigns` | id, name, target_segment, budget, sent_at | 캠페인 4건 |
| `campaign_sends` | id, campaign_id, user_id, sent_at | 발송 20건 |
| `campaign_opens` | id, send_id, opened_at | 오픈 13건 |
| `campaign_clicks` | id, send_id, clicked_at | 클릭 7건 |

---

## 유형 A: JOIN + 집계 복합

### A-1. 매장별 매출 통계 ★★★

**문제**: 2024년 각 매장별로 매장명, 총 주문 건수, 총 매출액, 평균 주문 금액(소수점 첫째자리)을 매출액 높은 순으로 출력하세요.

```sql
SELECT
    s.name AS store_name,
    COUNT(*) AS order_count,
    SUM(o.total_amount) AS total_revenue,
    ROUND(AVG(o.total_amount), 1) AS avg_order_amount
FROM stores s
JOIN orders o ON s.id = o.store_id
GROUP BY s.id, s.name
ORDER BY total_revenue DESC;
```

**핵심 포인트**:
- `JOIN`으로 테이블 연결
- `GROUP BY`로 매장별 그룹화
- `ROUND(AVG(), 1)`로 소수점 처리
- `ORDER BY DESC`로 내림차순 정렬

---

### A-2. 채널별 고객 획득 및 매출 ★★★

**문제**: 유입 채널(utm_source)별로 고객 수, 총 주문 건수, 총 매출액, 고객당 평균 매출(ARPU)을 구하세요.

```sql
SELECT
    u.utm_source AS channel,
    COUNT(DISTINCT u.id) AS user_count,
    COUNT(o.id) AS order_count,
    COALESCE(SUM(o.total_amount), 0) AS total_revenue,
    ROUND(COALESCE(SUM(o.total_amount), 0) / COUNT(DISTINCT u.id), 0) AS arpu
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
GROUP BY u.utm_source
ORDER BY total_revenue DESC;
```

**핵심 포인트**:
- `LEFT JOIN` 사용 (주문 없는 고객도 포함)
- `COUNT(DISTINCT)` 중복 제거
- `COALESCE`로 NULL 처리
- ARPU = 총 매출 / 고객 수

---

### A-3. 미구매 회원 조회 ★★

**문제**: 2024년 1월에 가입했지만 아직 한 번도 구매하지 않은 회원의 회원ID, 이름, 가입일을 출력하세요.

```sql
SELECT
    u.id AS user_id,
    u.name,
    u.created_at
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
WHERE u.created_at >= '2024-01-01'
  AND u.created_at < '2024-02-01'
  AND o.id IS NULL
ORDER BY u.created_at;
```

**핵심 포인트**:
- `LEFT JOIN + IS NULL` 패턴 (미구매 찾기)
- 날짜 범위 조건 정확히 설정
- `o.id IS NULL`로 매칭 안 된 행 필터

---

### A-4. 지역별 매장 실적 비교 ★★

**문제**: 지역별로 매장 수, 총 매출, 평균 매장 매출을 구하세요.

```sql
SELECT
    s.region,
    COUNT(DISTINCT s.id) AS store_count,
    SUM(o.total_amount) AS total_revenue,
    ROUND(SUM(o.total_amount) / COUNT(DISTINCT s.id), 0) AS avg_store_revenue
FROM stores s
JOIN orders o ON s.id = o.store_id
GROUP BY s.region
ORDER BY total_revenue DESC;
```

**핵심 포인트**:
- `COUNT(DISTINCT s.id)` 매장 수 계산
- 평균 매장 매출 = 총 매출 / 매장 수

---

### A-5. 상품 카테고리별 매출 분석 ★★

**문제**: 상품 카테고리별 판매 수량, 총 매출, 평균 단가를 구하세요.

```sql
SELECT
    p.category,
    SUM(oi.quantity) AS total_qty,
    SUM(oi.quantity * oi.unit_price) AS total_revenue,
    ROUND(AVG(oi.unit_price), 0) AS avg_unit_price
FROM products p
JOIN order_items oi ON p.id = oi.product_id
GROUP BY p.category
ORDER BY total_revenue DESC;
```

**핵심 포인트**:
- 매출 = 수량 * 단가
- `AVG(unit_price)` 평균 단가

---

## 유형 B: 윈도우 함수 - 순위

### B-1. 매장별 매출 순위 ★★

**문제**: 각 매장의 총 매출과 전체 매장 중 순위를 구하세요.

```sql
SELECT
    s.name AS store_name,
    SUM(o.total_amount) AS total_revenue,
    RANK() OVER (ORDER BY SUM(o.total_amount) DESC) AS revenue_rank
FROM stores s
JOIN orders o ON s.id = o.store_id
GROUP BY s.id, s.name
ORDER BY revenue_rank;
```

**핵심 포인트**:
- `RANK() OVER (ORDER BY ... DESC)` 순위 함수
- 동일 매출 시 같은 순위 부여
- GROUP BY 후 윈도우 함수 적용

---

### B-2. 카테고리별 상품 매출 TOP 3 ★★★

**문제**: 각 카테고리 내에서 상품별 매출 상위 3개를 출력하세요.

```sql
SELECT *
FROM (
    SELECT
        p.category,
        p.name AS product_name,
        SUM(oi.quantity * oi.unit_price) AS revenue,
        ROW_NUMBER() OVER (PARTITION BY p.category ORDER BY SUM(oi.quantity * oi.unit_price) DESC) AS rn
    FROM products p
    JOIN order_items oi ON p.id = oi.product_id
    GROUP BY p.category, p.id, p.name
) ranked
WHERE rn <= 3;
```

**핵심 포인트**:
- `PARTITION BY category` 카테고리별 순위
- `ROW_NUMBER()` 중복 없이 순차 번호
- 서브쿼리에서 순위 매기고 WHERE로 필터

---

### B-3. 고객별 구매금액 순위 및 등급 ★★★

**문제**: 고객별 총 구매금액과 순위를 구하고, 상위 20%는 'VIP', 나머지는 'Regular'로 분류하세요.

```sql
SELECT
    user_id,
    name,
    total_amount,
    amount_rank,
    CASE
        WHEN amount_rank <= CEIL(total_users * 0.2) THEN 'VIP'
        ELSE 'Regular'
    END AS grade
FROM (
    SELECT
        u.id AS user_id,
        u.name,
        SUM(o.total_amount) AS total_amount,
        RANK() OVER (ORDER BY SUM(o.total_amount) DESC) AS amount_rank,
        COUNT(*) OVER () AS total_users
    FROM users u
    JOIN orders o ON u.id = o.user_id
    GROUP BY u.id, u.name
) ranked;
```

**핵심 포인트**:
- `COUNT(*) OVER ()` 전체 행 수
- `CEIL(total_users * 0.2)` 상위 20% 계산
- `CASE WHEN`으로 등급 분류

---

## 유형 C: 윈도우 함수 - 집계/LAG/LEAD

### C-1. 월별 매출 및 누적 매출 ★★

**문제**: 월별 매출과 연초부터의 누적 매출을 구하세요.

```sql
SELECT
    DATE_FORMAT(order_datetime, '%Y-%m') AS ym,
    SUM(total_amount) AS monthly_revenue,
    SUM(SUM(total_amount)) OVER (ORDER BY DATE_FORMAT(order_datetime, '%Y-%m')) AS cumulative_revenue
FROM orders
GROUP BY DATE_FORMAT(order_datetime, '%Y-%m')
ORDER BY ym;
```

**핵심 포인트**:
- `DATE_FORMAT(date, '%Y-%m')` 연월 추출
- `SUM() OVER (ORDER BY)` 누적합
- GROUP BY 후 윈도우 함수 가능

---

### C-2. 전월 대비 매출 증감 ★★★

**문제**: 월별 매출과 전월 대비 증감액, 증감률(%)을 구하세요.

```sql
WITH monthly AS (
    SELECT
        DATE_FORMAT(order_datetime, '%Y-%m') AS ym,
        SUM(total_amount) AS revenue
    FROM orders
    GROUP BY DATE_FORMAT(order_datetime, '%Y-%m')
)
SELECT
    ym,
    revenue,
    LAG(revenue) OVER (ORDER BY ym) AS prev_revenue,
    revenue - LAG(revenue) OVER (ORDER BY ym) AS diff,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY ym))
        / LAG(revenue) OVER (ORDER BY ym) * 100, 1
    ) AS change_rate_pct
FROM monthly;
```

**핵심 포인트**:
- `LAG(col) OVER (ORDER BY)` 이전 행 값
- CTE로 월별 집계 먼저 수행
- 증감률 = (현재 - 이전) / 이전 * 100

---

### C-3. 고객별 이전 주문과의 간격 ★★★

**문제**: 각 고객의 주문별로 이전 주문으로부터의 일수 간격을 구하세요.

```sql
SELECT
    user_id,
    order_datetime,
    total_amount,
    LAG(order_datetime) OVER (PARTITION BY user_id ORDER BY order_datetime) AS prev_order,
    DATEDIFF(
        order_datetime,
        LAG(order_datetime) OVER (PARTITION BY user_id ORDER BY order_datetime)
    ) AS days_since_last_order
FROM orders
ORDER BY user_id, order_datetime;
```

**핵심 포인트**:
- `PARTITION BY user_id` 고객별로 구분
- `DATEDIFF(date1, date2)` 일수 차이
- 첫 주문은 NULL (이전 주문 없음)

---

## 유형 D: 비즈니스 로직 - 코호트/리텐션

### D-1. 월별 코호트 분석 ★★★

**문제**: 가입 월(코호트) 기준으로 월별 주문 고객 수를 구하세요.

```sql
WITH cohort AS (
    SELECT
        id AS user_id,
        DATE_FORMAT(created_at, '%Y-%m') AS cohort_month
    FROM users
),
monthly_orders AS (
    SELECT DISTINCT
        user_id,
        DATE_FORMAT(order_datetime, '%Y-%m') AS order_month
    FROM orders
)
SELECT
    c.cohort_month,
    TIMESTAMPDIFF(MONTH,
        STR_TO_DATE(CONCAT(c.cohort_month, '-01'), '%Y-%m-%d'),
        STR_TO_DATE(CONCAT(m.order_month, '-01'), '%Y-%m-%d')
    ) AS months_since_signup,
    COUNT(DISTINCT m.user_id) AS active_users
FROM cohort c
JOIN monthly_orders m ON c.user_id = m.user_id
WHERE m.order_month >= c.cohort_month
GROUP BY c.cohort_month, months_since_signup
ORDER BY c.cohort_month, months_since_signup;
```

**핵심 포인트**:
- 코호트 = 가입 월 기준 그룹
- `TIMESTAMPDIFF(MONTH, ...)` 월 차이 계산
- `COUNT(DISTINCT user_id)` 활성 유저 수

---

### D-2. User Type 분류 ★★★★

**문제**: 월별로 신규(New), 유지(Current), 복귀(Resurrected) 유저 수를 구하세요.

```sql
WITH monthly_users AS (
    SELECT DISTINCT
        user_id,
        DATE_FORMAT(order_datetime, '%Y-%m') AS year_month
    FROM orders
),
first_order AS (
    SELECT
        user_id,
        MIN(year_month) AS first_month
    FROM monthly_users
    GROUP BY user_id
),
with_prev AS (
    SELECT
        m.user_id,
        m.year_month,
        f.first_month,
        LAG(m.year_month) OVER (PARTITION BY m.user_id ORDER BY m.year_month) AS prev_month
    FROM monthly_users m
    JOIN first_order f ON m.user_id = f.user_id
)
SELECT
    year_month,
    SUM(CASE WHEN year_month = first_month THEN 1 ELSE 0 END) AS new_users,
    SUM(CASE
        WHEN year_month != first_month
         AND prev_month = DATE_FORMAT(DATE_SUB(STR_TO_DATE(CONCAT(year_month, '-01'), '%Y-%m-%d'), INTERVAL 1 MONTH), '%Y-%m')
        THEN 1 ELSE 0
    END) AS current_users,
    SUM(CASE
        WHEN year_month != first_month
         AND (prev_month IS NULL OR prev_month < DATE_FORMAT(DATE_SUB(STR_TO_DATE(CONCAT(year_month, '-01'), '%Y-%m-%d'), INTERVAL 1 MONTH), '%Y-%m'))
        THEN 1 ELSE 0
    END) AS resurrected_users
FROM with_prev
GROUP BY year_month
ORDER BY year_month;
```

**핵심 포인트**:
- New: 해당 월 첫 구매
- Current: 직전 월에도 구매
- Resurrected: 직전 월 구매 없음 (복귀)

---

## 유형 G: 그로스해킹/CRM

### G-1. 고객별 평균 구매 주기 ★★★

**문제**: 2회 이상 구매한 고객의 평균 구매 주기(일)를 구하세요.

```sql
WITH order_with_prev AS (
    SELECT
        user_id,
        order_datetime,
        LAG(order_datetime) OVER (PARTITION BY user_id ORDER BY order_datetime) AS prev_order
    FROM orders
),
intervals AS (
    SELECT
        user_id,
        DATEDIFF(order_datetime, prev_order) AS days_interval
    FROM order_with_prev
    WHERE prev_order IS NOT NULL
)
SELECT
    i.user_id,
    u.name,
    COUNT(*) + 1 AS order_count,
    ROUND(AVG(days_interval), 1) AS avg_interval_days
FROM intervals i
JOIN users u ON i.user_id = u.id
GROUP BY i.user_id, u.name
ORDER BY avg_interval_days;
```

**핵심 포인트**:
- `LAG`로 이전 주문일 가져오기
- `DATEDIFF`로 간격 계산
- 평균 간격이 짧을수록 충성 고객

---

### G-2. CAC (Customer Acquisition Cost) ★★★

**문제**: 월별 CAC(신규 고객 1명 획득 비용)를 계산하세요.

```sql
WITH monthly_new_users AS (
    SELECT
        DATE_FORMAT(created_at, '%Y-%m') AS ym,
        COUNT(*) AS new_users
    FROM users
    GROUP BY DATE_FORMAT(created_at, '%Y-%m')
),
monthly_costs AS (
    SELECT
        ym,
        SUM(cost) AS total_cost
    FROM marketing_costs
    GROUP BY ym
)
SELECT
    c.ym AS year_month,
    c.total_cost AS marketing_cost,
    COALESCE(u.new_users, 0) AS new_users,
    CASE
        WHEN COALESCE(u.new_users, 0) > 0
        THEN ROUND(c.total_cost / u.new_users, 0)
        ELSE NULL
    END AS cac
FROM monthly_costs c
LEFT JOIN monthly_new_users u ON c.ym = u.ym
ORDER BY c.ym;
```

**핵심 포인트**:
- CAC = 마케팅 비용 / 신규 고객 수
- 낮을수록 효율적인 고객 획득

---

### G-3. ROAS (Return on Ad Spend) 채널별 ★★★

**문제**: 마케팅 채널별 ROAS를 계산하세요.

```sql
WITH channel_revenue AS (
    SELECT
        u.utm_source AS channel,
        SUM(o.total_amount) AS revenue
    FROM users u
    JOIN orders o ON u.id = o.user_id
    GROUP BY u.utm_source
),
channel_cost AS (
    SELECT
        channel,
        SUM(cost) AS ad_spend
    FROM marketing_costs
    GROUP BY channel
)
SELECT
    c.channel,
    c.ad_spend,
    COALESCE(r.revenue, 0) AS attributed_revenue,
    ROUND(COALESCE(r.revenue, 0) / c.ad_spend * 100, 1) AS roas_pct
FROM channel_cost c
LEFT JOIN channel_revenue r ON c.channel = r.channel
ORDER BY roas_pct DESC;
```

**핵심 포인트**:
- ROAS = 매출 / 광고비 * 100
- 100% 이상이면 투자 대비 이익

---

### G-4. CRM 캠페인 성과 ★★★

**문제**: 캠페인별 오픈율, 클릭율을 구하세요.

```sql
SELECT
    c.name AS campaign_name,
    COUNT(DISTINCT cs.id) AS sent_count,
    COUNT(DISTINCT co.id) AS open_count,
    COUNT(DISTINCT cc.id) AS click_count,
    ROUND(COUNT(DISTINCT co.id) / COUNT(DISTINCT cs.id) * 100, 1) AS open_rate,
    ROUND(COUNT(DISTINCT cc.id) / COUNT(DISTINCT cs.id) * 100, 1) AS click_rate
FROM campaigns c
JOIN campaign_sends cs ON c.id = cs.campaign_id
LEFT JOIN campaign_opens co ON cs.id = co.send_id
LEFT JOIN campaign_clicks cc ON cs.id = cc.send_id
GROUP BY c.id, c.name
ORDER BY open_rate DESC;
```

**핵심 포인트**:
- 오픈율 = 오픈 수 / 발송 수 * 100
- 클릭율 = 클릭 수 / 발송 수 * 100
- `LEFT JOIN` 으로 오픈/클릭 없는 경우 포함

---

### G-5. 시간대별 주문 패턴 ★★

**문제**: 시간대별 주문 건수와 평균 주문금액을 분석하세요.

```sql
SELECT
    HOUR(order_datetime) AS hour,
    COUNT(*) AS order_count,
    ROUND(AVG(total_amount), 0) AS avg_amount,
    CASE
        WHEN HOUR(order_datetime) BETWEEN 0 AND 5 THEN '새벽'
        WHEN HOUR(order_datetime) BETWEEN 6 AND 11 THEN '오전'
        WHEN HOUR(order_datetime) BETWEEN 12 AND 17 THEN '오후'
        ELSE '저녁'
    END AS time_slot
FROM orders
GROUP BY HOUR(order_datetime)
ORDER BY hour;
```

**핵심 포인트**:
- `HOUR()` 함수로 시간 추출
- `CASE WHEN`으로 시간대 구분

---

### G-6. 재주문율 분석 ★★★

**문제**: 첫 구매 월별로 재주문한 고객 비율을 구하세요.

```sql
WITH first_orders AS (
    SELECT
        user_id,
        MIN(order_datetime) AS first_order_date,
        DATE_FORMAT(MIN(order_datetime), '%Y-%m') AS first_month
    FROM orders
    GROUP BY user_id
),
repeat_check AS (
    SELECT
        f.user_id,
        f.first_month,
        CASE WHEN COUNT(o.id) > 1 THEN 1 ELSE 0 END AS is_repeat
    FROM first_orders f
    JOIN orders o ON f.user_id = o.user_id
    GROUP BY f.user_id, f.first_month
)
SELECT
    first_month,
    COUNT(*) AS first_purchasers,
    SUM(is_repeat) AS repeat_purchasers,
    ROUND(SUM(is_repeat) / COUNT(*) * 100, 1) AS repeat_rate_pct
FROM repeat_check
GROUP BY first_month
ORDER BY first_month;
```

**핵심 포인트**:
- 재주문율 = 재구매 고객 / 전체 고객 * 100
- 높을수록 고객 충성도 높음

---

## 핵심 문법 요약

### 자주 쓰는 패턴

```sql
-- 1. 그룹별 TOP N (윈도우 함수)
SELECT * FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY group_col ORDER BY sort_col DESC) AS rn
    FROM table
) sub WHERE rn <= N;

-- 2. 미존재 데이터 찾기 (LEFT JOIN + IS NULL)
SELECT a.* FROM table_a a
LEFT JOIN table_b b ON a.id = b.a_id
WHERE b.id IS NULL;

-- 3. 누적합
SUM(col) OVER (ORDER BY date_col)

-- 4. 전월 대비
LAG(col) OVER (ORDER BY month_col)

-- 5. 코호트 (첫 활동 월)
MIN(DATE_FORMAT(date_col, '%Y-%m')) AS cohort_month
```

### 실수 방지 체크리스트

- [ ] `COUNT(*)`와 `COUNT(col)` 차이 (NULL 포함 여부)
- [ ] `GROUP BY` 컬럼과 `SELECT` 컬럼 일치
- [ ] `NULL` 비교는 `= NULL` 대신 `IS NULL`
- [ ] `JOIN` 시 ON 조건 누락 확인
- [ ] `ORDER BY` 방향 (ASC/DESC) 확인

---

*Last Updated: 2026-01-20*
