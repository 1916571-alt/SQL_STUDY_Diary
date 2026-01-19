# SQL 실습 문제 정답 및 핵심 포인트

> **XAMPP MySQL `practice` 데이터베이스 기준**
> 총 52문제 정답 수록 (테스트 완료)

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

## 유형 A: JOIN + 집계 복합 (8문제)

### A-1. 매장별 매출 통계 ★★★

**문제**: 각 매장별로 매장명, 총 주문 건수, 총 매출액, 평균 주문 금액을 매출액 높은 순으로 출력하세요.

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

**핵심**: JOIN + GROUP BY + 집계함수 조합

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

**핵심**: LEFT JOIN (주문 없는 고객 포함), COUNT(DISTINCT), ARPU 계산

---

### A-3. 미구매 회원 조회 ★★

**문제**: 가입했지만 한 번도 구매하지 않은 회원을 출력하세요.

```sql
SELECT
    u.id AS user_id,
    u.name,
    u.created_at
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
WHERE o.id IS NULL
ORDER BY u.created_at;
```

**핵심**: LEFT JOIN + IS NULL 패턴

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

**핵심**: COUNT(DISTINCT) 중복 제거

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

**핵심**: 매출 = 수량 * 단가

---

### A-6. 재구매율 계산 ★★★

**문제**: 2회 이상 구매한 고객 비율을 구하세요.

```sql
SELECT
    COUNT(*) AS total_customers,
    SUM(CASE WHEN order_count >= 2 THEN 1 ELSE 0 END) AS repeat_customers,
    ROUND(SUM(CASE WHEN order_count >= 2 THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS repeat_rate_pct
FROM (
    SELECT user_id, COUNT(*) AS order_count
    FROM orders
    GROUP BY user_id
) user_orders;
```

**핵심**: 서브쿼리 + CASE WHEN 조합

---

### A-7. 월별 신규/기존 고객 매출 비교 ★★★

**문제**: 월별로 신규 고객(해당 월 첫 구매)과 기존 고객의 매출액을 구하세요.

```sql
WITH first_order AS (
    SELECT user_id, MIN(DATE_FORMAT(order_datetime, '%Y-%m')) AS first_month
    FROM orders GROUP BY user_id
)
SELECT
    DATE_FORMAT(o.order_datetime, '%Y-%m') AS ym,
    SUM(CASE WHEN DATE_FORMAT(o.order_datetime, '%Y-%m') = f.first_month THEN o.total_amount ELSE 0 END) AS new_customer_revenue,
    SUM(CASE WHEN DATE_FORMAT(o.order_datetime, '%Y-%m') != f.first_month THEN o.total_amount ELSE 0 END) AS existing_customer_revenue
FROM orders o
JOIN first_order f ON o.user_id = f.user_id
GROUP BY DATE_FORMAT(o.order_datetime, '%Y-%m')
ORDER BY ym;
```

**핵심**: CTE로 첫 구매월 계산 후 CASE WHEN 분기

---

### A-8. 동시 구매 상품 분석 ★★★

**문제**: 특정 상품(id=1)과 같은 주문에서 함께 구매된 상품들을 구하세요.

```sql
SELECT
    p.name AS product_name,
    COUNT(*) AS co_purchase_count
FROM order_items oi1
JOIN order_items oi2 ON oi1.order_id = oi2.order_id AND oi2.product_id = 1
JOIN products p ON oi1.product_id = p.id
WHERE oi1.product_id != 1
GROUP BY oi1.product_id, p.name
ORDER BY co_purchase_count DESC;
```

**핵심**: SELF JOIN으로 같은 주문 내 다른 상품 찾기

---

## 유형 B: 윈도우 함수 - 순위 (7문제)

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

**핵심**: RANK() OVER (ORDER BY)

---

### B-2. 카테고리별 상품 매출 TOP 3 ★★★

**문제**: 각 카테고리 내에서 상품별 매출 상위 3개를 출력하세요.

```sql
SELECT * FROM (
    SELECT
        p.category,
        p.name AS product_name,
        SUM(oi.quantity * oi.unit_price) AS revenue,
        ROW_NUMBER() OVER (PARTITION BY p.category ORDER BY SUM(oi.quantity * oi.unit_price) DESC) AS rn
    FROM products p
    JOIN order_items oi ON p.id = oi.product_id
    GROUP BY p.category, p.id, p.name
) ranked WHERE rn <= 3;
```

**핵심**: PARTITION BY로 그룹별 순위, 서브쿼리에서 필터

---

### B-3. 고객별 구매금액 순위 및 등급 ★★★

**문제**: 고객별 총 구매금액 순위를 구하고, 상위 20%는 'VIP'로 분류하세요.

```sql
SELECT
    user_id, name, total_amount, amount_rank,
    CASE WHEN amount_rank <= CEIL(total_users * 0.2) THEN 'VIP' ELSE 'Regular' END AS grade
FROM (
    SELECT
        u.id AS user_id, u.name,
        SUM(o.total_amount) AS total_amount,
        RANK() OVER (ORDER BY SUM(o.total_amount) DESC) AS amount_rank,
        COUNT(*) OVER () AS total_users
    FROM users u JOIN orders o ON u.id = o.user_id
    GROUP BY u.id, u.name
) ranked;
```

**핵심**: COUNT(*) OVER ()로 전체 행 수 계산

---

### B-4. 월별 매출 순위 변화 ★★★

**문제**: 각 매장의 월별 매출 순위를 구하세요.

```sql
SELECT
    DATE_FORMAT(o.order_datetime, '%Y-%m') AS ym,
    s.name AS store_name,
    SUM(o.total_amount) AS monthly_revenue,
    RANK() OVER (PARTITION BY DATE_FORMAT(o.order_datetime, '%Y-%m') ORDER BY SUM(o.total_amount) DESC) AS monthly_rank
FROM stores s
JOIN orders o ON s.id = o.store_id
GROUP BY DATE_FORMAT(o.order_datetime, '%Y-%m'), s.id, s.name
ORDER BY ym, monthly_rank;
```

**핵심**: PARTITION BY 월별로 순위 리셋

---

### B-5. 연속 1위 기간 (일별 매출 1위 매장) ★★★★

**문제**: 일별 매출 1위 매장을 구하세요.

```sql
SELECT * FROM (
    SELECT
        DATE(o.order_datetime) AS order_date,
        s.name AS store_name,
        SUM(o.total_amount) AS daily_revenue,
        RANK() OVER (PARTITION BY DATE(o.order_datetime) ORDER BY SUM(o.total_amount) DESC) AS daily_rank
    FROM stores s
    JOIN orders o ON s.id = o.store_id
    GROUP BY DATE(o.order_datetime), s.id, s.name
) ranked WHERE daily_rank = 1;
```

**핵심**: 일별 PARTITION + RANK = 1 필터

---

### B-6. 분기별 실적 순위 ★★

**문제**: 분기별 매출과 순위를 구하세요.

```sql
SELECT
    CONCAT(YEAR(order_datetime), '-Q', QUARTER(order_datetime)) AS quarter,
    s.name AS store_name,
    SUM(total_amount) AS quarterly_revenue,
    RANK() OVER (PARTITION BY YEAR(order_datetime), QUARTER(order_datetime) ORDER BY SUM(total_amount) DESC) AS quarter_rank
FROM orders o
JOIN stores s ON o.store_id = s.id
GROUP BY YEAR(order_datetime), QUARTER(order_datetime), s.id, s.name
ORDER BY quarter, quarter_rank;
```

**핵심**: QUARTER() 함수, CONCAT으로 분기 표시

---

### B-7. 그룹별 중앙값 구하기 ★★★

**문제**: 각 채널별 고객 총 구매금액의 중앙값을 구하세요.

```sql
WITH ranked AS (
    SELECT
        u.utm_source AS channel,
        SUM(o.total_amount) AS total_amount,
        ROW_NUMBER() OVER (PARTITION BY u.utm_source ORDER BY SUM(o.total_amount)) AS rn,
        COUNT(*) OVER (PARTITION BY u.utm_source) AS cnt
    FROM users u
    JOIN orders o ON u.id = o.user_id
    GROUP BY u.id, u.utm_source
)
SELECT channel, AVG(total_amount) AS median_amount
FROM ranked
WHERE rn IN (FLOOR((cnt + 1) / 2), CEIL((cnt + 1) / 2))
GROUP BY channel;
```

**핵심**: ROW_NUMBER + 중앙 위치 계산

---

## 유형 C: 윈도우 함수 - 집계/LAG/LEAD (7문제)

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

**핵심**: SUM() OVER (ORDER BY) 누적합

---

### C-2. 전월 대비 매출 증감 ★★★

**문제**: 월별 매출과 전월 대비 증감액, 증감률(%)을 구하세요.

```sql
WITH monthly AS (
    SELECT DATE_FORMAT(order_datetime, '%Y-%m') AS ym, SUM(total_amount) AS revenue
    FROM orders GROUP BY DATE_FORMAT(order_datetime, '%Y-%m')
)
SELECT
    ym, revenue,
    LAG(revenue) OVER (ORDER BY ym) AS prev_revenue,
    revenue - LAG(revenue) OVER (ORDER BY ym) AS diff,
    ROUND((revenue - LAG(revenue) OVER (ORDER BY ym)) / LAG(revenue) OVER (ORDER BY ym) * 100, 1) AS change_rate_pct
FROM monthly;
```

**핵심**: LAG()로 이전 행 값 가져오기

---

### C-3. 고객별 이전 주문과의 간격 ★★★

**문제**: 각 고객의 주문별로 이전 주문으로부터의 일수 간격을 구하세요.

```sql
SELECT
    user_id, order_datetime, total_amount,
    LAG(order_datetime) OVER (PARTITION BY user_id ORDER BY order_datetime) AS prev_order,
    DATEDIFF(order_datetime, LAG(order_datetime) OVER (PARTITION BY user_id ORDER BY order_datetime)) AS days_since_last_order
FROM orders
ORDER BY user_id, order_datetime;
```

**핵심**: PARTITION BY user_id로 고객별 구분

---

### C-4. 전일 대비 주문 증감 ★★

**문제**: 일별 주문 건수와 전일 대비 증감을 구하세요.

```sql
WITH daily AS (
    SELECT DATE(order_datetime) AS order_date, COUNT(*) AS order_count
    FROM orders GROUP BY DATE(order_datetime)
)
SELECT
    order_date, order_count,
    LAG(order_count) OVER (ORDER BY order_date) AS prev_count,
    order_count - LAG(order_count) OVER (ORDER BY order_date) AS diff
FROM daily;
```

**핵심**: DATE() 함수로 일별 집계

---

### C-5. 이동 평균 (7일) ★★★

**문제**: 일별 매출의 최근 7일 이동평균을 구하세요.

```sql
WITH daily AS (
    SELECT DATE(order_datetime) AS order_date, SUM(total_amount) AS daily_revenue
    FROM orders GROUP BY DATE(order_datetime)
)
SELECT
    order_date, daily_revenue,
    ROUND(AVG(daily_revenue) OVER (ORDER BY order_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 0) AS moving_avg_7d
FROM daily;
```

**핵심**: ROWS BETWEEN N PRECEDING AND CURRENT ROW

---

### C-6. 연속 증가 기간 ★★★

**문제**: 일별 매출이 전일보다 증가한 날을 표시하세요.

```sql
WITH daily AS (
    SELECT DATE(order_datetime) AS order_date, SUM(total_amount) AS daily_revenue
    FROM orders GROUP BY DATE(order_datetime)
)
SELECT
    order_date, daily_revenue,
    LAG(daily_revenue) OVER (ORDER BY order_date) AS prev_revenue,
    CASE WHEN daily_revenue > LAG(daily_revenue) OVER (ORDER BY order_date) THEN 'UP'
         WHEN daily_revenue < LAG(daily_revenue) OVER (ORDER BY order_date) THEN 'DOWN'
         ELSE 'SAME' END AS trend
FROM daily;
```

**핵심**: CASE WHEN + LAG 조합

---

### C-7. 구간별 매출 비중 (파레토) ★★

**문제**: 각 매장이 전체 매출에서 차지하는 비중과 누적 비중을 구하세요.

```sql
SELECT
    s.name AS store_name,
    SUM(o.total_amount) AS revenue,
    ROUND(SUM(o.total_amount) / SUM(SUM(o.total_amount)) OVER () * 100, 1) AS revenue_pct,
    ROUND(SUM(SUM(o.total_amount)) OVER (ORDER BY SUM(o.total_amount) DESC) / SUM(SUM(o.total_amount)) OVER () * 100, 1) AS cumulative_pct
FROM stores s
JOIN orders o ON s.id = o.store_id
GROUP BY s.id, s.name
ORDER BY revenue DESC;
```

**핵심**: SUM() OVER ()로 전체 합계, 누적 비중 계산

---

## 유형 D: 비즈니스 로직 - 코호트/리텐션 (6문제)

### D-1. 월별 코호트 분석 ★★★

**문제**: 가입 월(코호트) 기준으로 월별 주문 고객 수를 구하세요.

```sql
WITH cohort AS (
    SELECT id AS user_id, DATE_FORMAT(created_at, '%Y-%m') AS cohort_month FROM users
),
monthly_orders AS (
    SELECT DISTINCT user_id, DATE_FORMAT(order_datetime, '%Y-%m') AS order_month FROM orders
)
SELECT
    c.cohort_month,
    TIMESTAMPDIFF(MONTH, STR_TO_DATE(CONCAT(c.cohort_month, '-01'), '%Y-%m-%d'),
                         STR_TO_DATE(CONCAT(m.order_month, '-01'), '%Y-%m-%d')) AS months_since_signup,
    COUNT(DISTINCT m.user_id) AS active_users
FROM cohort c
JOIN monthly_orders m ON c.user_id = m.user_id
WHERE m.order_month >= c.cohort_month
GROUP BY c.cohort_month, months_since_signup
ORDER BY c.cohort_month, months_since_signup;
```

**핵심**: TIMESTAMPDIFF로 월 차이 계산

---

### D-2. User Type 분류 ★★★★

**문제**: 월별로 신규(New), 유지(Current), 복귀(Resurrected) 유저 수를 구하세요.

```sql
WITH monthly_users AS (
    SELECT DISTINCT user_id, DATE_FORMAT(order_datetime, '%Y-%m') AS ym FROM orders
),
first_order AS (
    SELECT user_id, MIN(ym) AS first_month FROM monthly_users GROUP BY user_id
),
with_prev AS (
    SELECT m.user_id, m.ym, f.first_month,
           LAG(m.ym) OVER (PARTITION BY m.user_id ORDER BY m.ym) AS prev_month
    FROM monthly_users m JOIN first_order f ON m.user_id = f.user_id
)
SELECT
    ym,
    SUM(CASE WHEN ym = first_month THEN 1 ELSE 0 END) AS new_users,
    SUM(CASE WHEN ym != first_month AND prev_month = DATE_FORMAT(DATE_SUB(STR_TO_DATE(CONCAT(ym, '-01'), '%Y-%m-%d'), INTERVAL 1 MONTH), '%Y-%m') THEN 1 ELSE 0 END) AS current_users,
    SUM(CASE WHEN ym != first_month AND (prev_month IS NULL OR prev_month < DATE_FORMAT(DATE_SUB(STR_TO_DATE(CONCAT(ym, '-01'), '%Y-%m-%d'), INTERVAL 1 MONTH), '%Y-%m')) THEN 1 ELSE 0 END) AS resurrected_users
FROM with_prev GROUP BY ym ORDER BY ym;
```

**핵심**: New/Current/Resurrected 정의 이해

---

### D-3. 주간 리텐션 ★★★

**문제**: 가입 주차별 Day 7 리텐션(가입 후 7일 이내 주문 비율)을 구하세요.

```sql
WITH signup_week AS (
    SELECT id AS user_id, created_at, YEARWEEK(created_at) AS signup_week FROM users
),
first_order AS (
    SELECT user_id, MIN(order_datetime) AS first_order_date FROM orders GROUP BY user_id
)
SELECT
    s.signup_week,
    COUNT(DISTINCT s.user_id) AS total_users,
    COUNT(DISTINCT CASE WHEN DATEDIFF(f.first_order_date, s.created_at) <= 7 THEN s.user_id END) AS d7_converted,
    ROUND(COUNT(DISTINCT CASE WHEN DATEDIFF(f.first_order_date, s.created_at) <= 7 THEN s.user_id END) / COUNT(DISTINCT s.user_id) * 100, 1) AS d7_retention_pct
FROM signup_week s
LEFT JOIN first_order f ON s.user_id = f.user_id
GROUP BY s.signup_week
ORDER BY s.signup_week;
```

**핵심**: LEFT JOIN으로 미구매자 포함

---

### D-4. 이탈 위험 고객 ★★★

**문제**: 30일 이상 구매가 없는 고객을 이탈 위험으로 분류하세요.

```sql
SELECT
    u.id AS user_id,
    u.name,
    MAX(o.order_datetime) AS last_order_date,
    DATEDIFF(NOW(), MAX(o.order_datetime)) AS days_since_last_order,
    CASE WHEN DATEDIFF(NOW(), MAX(o.order_datetime)) >= 30 THEN 'At Risk' ELSE 'Active' END AS status
FROM users u
JOIN orders o ON u.id = o.user_id
GROUP BY u.id, u.name
HAVING DATEDIFF(NOW(), MAX(o.order_datetime)) >= 30
ORDER BY days_since_last_order DESC;
```

**핵심**: DATEDIFF(NOW(), date) 경과일 계산

---

### D-5. LTV 코호트별 계산 ★★★★

**문제**: 가입 월별 코호트의 평균 LTV(총 구매금액)를 구하세요.

```sql
SELECT
    DATE_FORMAT(u.created_at, '%Y-%m') AS cohort_month,
    COUNT(DISTINCT u.id) AS cohort_size,
    COALESCE(SUM(o.total_amount), 0) AS total_revenue,
    ROUND(COALESCE(SUM(o.total_amount), 0) / COUNT(DISTINCT u.id), 0) AS avg_ltv
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
GROUP BY DATE_FORMAT(u.created_at, '%Y-%m')
ORDER BY cohort_month;
```

**핵심**: LTV = 총 매출 / 코호트 고객 수

---

### D-6. 코호트 리텐션 피벗 ★★★★

**문제**: 코호트별 M+0, M+1, M+2 리텐션을 피벗 형태로 출력하세요.

```sql
WITH cohort AS (
    SELECT id AS user_id, DATE_FORMAT(created_at, '%Y-%m') AS cohort_month FROM users
),
monthly_orders AS (
    SELECT DISTINCT user_id, DATE_FORMAT(order_datetime, '%Y-%m') AS order_month FROM orders
),
cohort_data AS (
    SELECT c.cohort_month, m.user_id,
           TIMESTAMPDIFF(MONTH, STR_TO_DATE(CONCAT(c.cohort_month, '-01'), '%Y-%m-%d'),
                                STR_TO_DATE(CONCAT(m.order_month, '-01'), '%Y-%m-%d')) AS month_diff
    FROM cohort c JOIN monthly_orders m ON c.user_id = m.user_id
    WHERE m.order_month >= c.cohort_month
)
SELECT
    cohort_month,
    COUNT(DISTINCT CASE WHEN month_diff = 0 THEN user_id END) AS M0,
    COUNT(DISTINCT CASE WHEN month_diff = 1 THEN user_id END) AS M1,
    COUNT(DISTINCT CASE WHEN month_diff = 2 THEN user_id END) AS M2,
    COUNT(DISTINCT CASE WHEN month_diff = 3 THEN user_id END) AS M3
FROM cohort_data
GROUP BY cohort_month
ORDER BY cohort_month;
```

**핵심**: CASE WHEN으로 피벗 구현

---

## 유형 E: 날짜/문자열 처리 (4문제)

### E-1. 연령대별 분석 ★★

**문제**: 생년월일 기준 연령대별 회원 수와 평균 구매금액을 구하세요.

```sql
SELECT
    CONCAT(FLOOR((YEAR(CURDATE()) - YEAR(u.birth_date)) / 10) * 10, '대') AS age_group,
    COUNT(DISTINCT u.id) AS user_count,
    ROUND(AVG(o.total_amount), 0) AS avg_purchase_amount
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
WHERE u.birth_date IS NOT NULL
GROUP BY FLOOR((YEAR(CURDATE()) - YEAR(u.birth_date)) / 10)
ORDER BY age_group;
```

**핵심**: FLOOR(나이/10)*10으로 연령대 계산

---

### E-2. 요일별 매출 패턴 ★★

**문제**: 요일별 평균 매출액과 주문 건수를 구하세요.

```sql
SELECT
    DAYOFWEEK(order_datetime) AS day_num,
    CASE DAYOFWEEK(order_datetime)
        WHEN 1 THEN '일' WHEN 2 THEN '월' WHEN 3 THEN '화'
        WHEN 4 THEN '수' WHEN 5 THEN '목' WHEN 6 THEN '금' WHEN 7 THEN '토'
    END AS day_name,
    COUNT(*) AS order_count,
    ROUND(AVG(total_amount), 0) AS avg_revenue
FROM orders
GROUP BY DAYOFWEEK(order_datetime)
ORDER BY day_num;
```

**핵심**: DAYOFWEEK() 1=일요일

---

### E-3. 전화번호 포맷 변환 ★

**문제**: 이메일에서 도메인만 추출하세요.

```sql
SELECT
    name,
    email,
    SUBSTRING_INDEX(email, '@', -1) AS domain
FROM users;
```

**핵심**: SUBSTRING_INDEX(str, delim, count)

---

### E-4. 시간대별 주문 분포 ★★

**문제**: 시간대별(새벽/오전/오후/저녁) 주문 분포를 분석하세요.

```sql
SELECT
    CASE
        WHEN HOUR(order_datetime) BETWEEN 0 AND 5 THEN '새벽(00-06)'
        WHEN HOUR(order_datetime) BETWEEN 6 AND 11 THEN '오전(06-12)'
        WHEN HOUR(order_datetime) BETWEEN 12 AND 17 THEN '오후(12-18)'
        ELSE '저녁(18-24)'
    END AS time_slot,
    COUNT(*) AS order_count,
    SUM(total_amount) AS total_revenue,
    ROUND(AVG(total_amount), 0) AS avg_amount
FROM orders
GROUP BY time_slot
ORDER BY MIN(HOUR(order_datetime));
```

**핵심**: HOUR() + CASE WHEN으로 시간대 구분

---

## 유형 F: 복합 실전 문제 (5문제)

### F-1. 베스트셀러 분석 ★★★

**문제**: 월별 매출 TOP 3 매장과 전월 대비 성장률을 구하세요.

```sql
WITH monthly_store AS (
    SELECT
        DATE_FORMAT(o.order_datetime, '%Y-%m') AS ym,
        s.name AS store_name,
        SUM(o.total_amount) AS revenue
    FROM orders o JOIN stores s ON o.store_id = s.id
    GROUP BY DATE_FORMAT(o.order_datetime, '%Y-%m'), s.id, s.name
),
with_rank AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY ym ORDER BY revenue DESC) AS rn,
           LAG(revenue) OVER (PARTITION BY store_name ORDER BY ym) AS prev_revenue
    FROM monthly_store
)
SELECT ym, store_name, revenue, prev_revenue,
       CASE WHEN prev_revenue IS NULL THEN 'NEW'
            ELSE CONCAT(ROUND((revenue - prev_revenue) / prev_revenue * 100, 1), '%')
       END AS growth_rate
FROM with_rank WHERE rn <= 3
ORDER BY ym, rn;
```

**핵심**: ROW_NUMBER + LAG 복합 활용

---

### F-2. RFM 분석 ★★★★

**문제**: 고객을 RFM 점수로 분류하세요.

```sql
SELECT
    u.id AS user_id,
    u.name,
    DATEDIFF(CURDATE(), MAX(o.order_datetime)) AS recency_days,
    COUNT(o.id) AS frequency,
    SUM(o.total_amount) AS monetary,
    CASE WHEN DATEDIFF(CURDATE(), MAX(o.order_datetime)) <= 30 THEN 3
         WHEN DATEDIFF(CURDATE(), MAX(o.order_datetime)) <= 90 THEN 2 ELSE 1 END AS R_score,
    CASE WHEN COUNT(o.id) >= 10 THEN 3 WHEN COUNT(o.id) >= 5 THEN 2 ELSE 1 END AS F_score,
    CASE WHEN SUM(o.total_amount) >= 100000 THEN 3
         WHEN SUM(o.total_amount) >= 50000 THEN 2 ELSE 1 END AS M_score
FROM users u
JOIN orders o ON u.id = o.user_id
GROUP BY u.id, u.name;
```

**핵심**: R/F/M 각각 점수화

---

### F-3. 퍼널 분석 ★★★★

**문제**: 가입 → 첫 앱 오픈 → 첫 구매 퍼널 전환율을 구하세요.

```sql
SELECT
    COUNT(DISTINCT u.id) AS signups,
    COUNT(DISTINCT a.user_id) AS app_opened,
    COUNT(DISTINCT o.user_id) AS purchasers,
    ROUND(COUNT(DISTINCT a.user_id) / COUNT(DISTINCT u.id) * 100, 1) AS signup_to_open_pct,
    ROUND(COUNT(DISTINCT o.user_id) / COUNT(DISTINCT a.user_id) * 100, 1) AS open_to_purchase_pct
FROM users u
LEFT JOIN app_logs a ON u.id = a.user_id AND a.event_name = 'app_open'
LEFT JOIN orders o ON u.id = o.user_id;
```

**핵심**: LEFT JOIN으로 각 단계 포함, 전환율 계산

---

### F-4. A/B 테스트 결과 분석 ★★★

**문제**: utm_source별 전환율과 평균 구매금액을 비교하세요.

```sql
SELECT
    u.utm_source AS test_group,
    COUNT(DISTINCT u.id) AS total_users,
    COUNT(DISTINCT o.user_id) AS purchasers,
    ROUND(COUNT(DISTINCT o.user_id) / COUNT(DISTINCT u.id) * 100, 1) AS conversion_rate,
    ROUND(AVG(o.total_amount), 0) AS avg_purchase_amount,
    SUM(o.total_amount) AS total_revenue
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
GROUP BY u.utm_source
ORDER BY conversion_rate DESC;
```

**핵심**: 전환율 = 구매자 / 전체 유저 * 100

---

### F-5. 바스켓 분석 (장바구니) ★★★

**문제**: 평균 주문당 상품 수와 주문당 평균 금액을 구하세요.

```sql
SELECT
    COUNT(DISTINCT o.id) AS total_orders,
    COUNT(oi.id) AS total_items,
    ROUND(COUNT(oi.id) / COUNT(DISTINCT o.id), 2) AS avg_items_per_order,
    ROUND(AVG(o.total_amount), 0) AS avg_order_amount
FROM orders o
LEFT JOIN order_items oi ON o.id = oi.order_id;
```

**핵심**: 주문당 상품 수 = 총 아이템 / 총 주문

---

## 유형 G: 그로스해킹/CRM (12문제)

### G-1. 고객별 평균 구매 주기 ★★★

**문제**: 2회 이상 구매한 고객의 평균 구매 주기(일)를 구하세요.

```sql
WITH order_with_prev AS (
    SELECT user_id, order_datetime,
           LAG(order_datetime) OVER (PARTITION BY user_id ORDER BY order_datetime) AS prev_order
    FROM orders
),
intervals AS (
    SELECT user_id, DATEDIFF(order_datetime, prev_order) AS days_interval
    FROM order_with_prev WHERE prev_order IS NOT NULL
)
SELECT i.user_id, u.name, COUNT(*) + 1 AS order_count,
       ROUND(AVG(days_interval), 1) AS avg_interval_days
FROM intervals i JOIN users u ON i.user_id = u.id
GROUP BY i.user_id, u.name
ORDER BY avg_interval_days;
```

**핵심**: LAG로 이전 주문일 → DATEDIFF로 간격

---

### G-2. 구매 주기 기반 세그먼트 ★★★

**문제**: 평균 구매 주기로 Heavy/Regular/Light/Occasional 분류하세요.

```sql
WITH intervals AS (
    SELECT user_id,
           AVG(DATEDIFF(order_datetime, LAG(order_datetime) OVER (PARTITION BY user_id ORDER BY order_datetime))) AS avg_interval
    FROM orders GROUP BY user_id
)
SELECT
    CASE WHEN avg_interval <= 7 THEN 'Heavy'
         WHEN avg_interval <= 14 THEN 'Regular'
         WHEN avg_interval <= 30 THEN 'Light'
         ELSE 'Occasional' END AS segment,
    COUNT(*) AS customer_count
FROM intervals WHERE avg_interval IS NOT NULL
GROUP BY segment ORDER BY customer_count DESC;
```

**핵심**: 주기 기준으로 CASE WHEN 분류

---

### G-3. CAC (Customer Acquisition Cost) ★★★

**문제**: 월별 CAC를 계산하세요.

```sql
WITH monthly_new_users AS (
    SELECT DATE_FORMAT(created_at, '%Y-%m') AS ym, COUNT(*) AS new_users
    FROM users GROUP BY DATE_FORMAT(created_at, '%Y-%m')
),
monthly_costs AS (
    SELECT ym, SUM(cost) AS total_cost FROM marketing_costs GROUP BY ym
)
SELECT c.ym, c.total_cost AS marketing_cost,
       COALESCE(u.new_users, 0) AS new_users,
       CASE WHEN COALESCE(u.new_users, 0) > 0 THEN ROUND(c.total_cost / u.new_users, 0) ELSE NULL END AS cac
FROM monthly_costs c
LEFT JOIN monthly_new_users u ON c.ym = u.ym
ORDER BY c.ym;
```

**핵심**: CAC = 마케팅비용 / 신규고객수

---

### G-4. ROAS 채널별 분석 ★★★

**문제**: 채널별 ROAS를 계산하세요.

```sql
WITH channel_revenue AS (
    SELECT u.utm_source AS channel, SUM(o.total_amount) AS revenue
    FROM users u JOIN orders o ON u.id = o.user_id GROUP BY u.utm_source
),
channel_cost AS (
    SELECT channel, SUM(cost) AS ad_spend FROM marketing_costs GROUP BY channel
)
SELECT c.channel, c.ad_spend, COALESCE(r.revenue, 0) AS attributed_revenue,
       ROUND(COALESCE(r.revenue, 0) / c.ad_spend * 100, 1) AS roas_pct
FROM channel_cost c LEFT JOIN channel_revenue r ON c.channel = r.channel
ORDER BY roas_pct DESC;
```

**핵심**: ROAS = 매출 / 광고비 * 100

---

### G-5. LTV vs CAC 비율 ★★★★

**문제**: 코호트별 LTV/CAC 비율을 구하세요.

```sql
WITH cohort_ltv AS (
    SELECT DATE_FORMAT(u.created_at, '%Y-%m') AS cohort_month,
           COUNT(DISTINCT u.id) AS cohort_size,
           COALESCE(SUM(o.total_amount), 0) / COUNT(DISTINCT u.id) AS avg_ltv
    FROM users u LEFT JOIN orders o ON u.id = o.user_id
    GROUP BY DATE_FORMAT(u.created_at, '%Y-%m')
),
monthly_cac AS (
    SELECT mc.ym, mc_total.total_cost / NULLIF(u_count.new_users, 0) AS cac
    FROM (SELECT ym, SUM(cost) AS total_cost FROM marketing_costs GROUP BY ym) mc_total
    JOIN (SELECT DATE_FORMAT(created_at, '%Y-%m') AS ym, COUNT(*) AS new_users FROM users GROUP BY DATE_FORMAT(created_at, '%Y-%m')) u_count
    ON mc_total.ym = u_count.ym
)
SELECT l.cohort_month, l.cohort_size, ROUND(l.avg_ltv, 0) AS avg_ltv,
       ROUND(c.cac, 0) AS cac,
       ROUND(l.avg_ltv / NULLIF(c.cac, 0), 2) AS ltv_cac_ratio
FROM cohort_ltv l LEFT JOIN monthly_cac c ON l.cohort_month = c.ym
ORDER BY l.cohort_month;
```

**핵심**: LTV/CAC >= 3이면 건강한 비즈니스

---

### G-6. CRM 캠페인 성과 ★★★

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
GROUP BY c.id, c.name ORDER BY open_rate DESC;
```

**핵심**: 오픈율 = 오픈수 / 발송수 * 100

---

### G-7. 재주문율 분석 ★★★

**문제**: 첫 구매 월별 재주문 비율을 구하세요.

```sql
WITH first_orders AS (
    SELECT user_id, MIN(order_datetime) AS first_order_date,
           DATE_FORMAT(MIN(order_datetime), '%Y-%m') AS first_month
    FROM orders GROUP BY user_id
),
repeat_check AS (
    SELECT f.user_id, f.first_month,
           CASE WHEN COUNT(o.id) > 1 THEN 1 ELSE 0 END AS is_repeat
    FROM first_orders f JOIN orders o ON f.user_id = o.user_id
    GROUP BY f.user_id, f.first_month
)
SELECT first_month, COUNT(*) AS first_purchasers,
       SUM(is_repeat) AS repeat_purchasers,
       ROUND(SUM(is_repeat) / COUNT(*) * 100, 1) AS repeat_rate_pct
FROM repeat_check GROUP BY first_month ORDER BY first_month;
```

**핵심**: 재주문율 = 재구매자 / 전체 * 100

---

### G-8. 시간대별 주문 패턴 ★★

**문제**: 시간대별 주문 분포와 피크 타임을 분석하세요.

```sql
SELECT
    HOUR(order_datetime) AS hour,
    COUNT(*) AS order_count,
    ROUND(AVG(total_amount), 0) AS avg_amount,
    CASE WHEN COUNT(*) >= (SELECT AVG(cnt) * 1.5 FROM (SELECT COUNT(*) AS cnt FROM orders GROUP BY HOUR(order_datetime)) t)
         THEN 'PEAK' ELSE 'NORMAL' END AS time_type
FROM orders GROUP BY HOUR(order_datetime) ORDER BY hour;
```

**핵심**: 평균의 1.5배 이상이면 피크

---

### G-9. 매장별 성과 비교 ★★★

**문제**: 매장별 월간 매출, 성장률, 순위를 구하세요.

```sql
WITH monthly_store AS (
    SELECT DATE_FORMAT(o.order_datetime, '%Y-%m') AS ym, s.name AS store_name,
           SUM(o.total_amount) AS revenue,
           COUNT(DISTINCT o.user_id) AS unique_customers
    FROM orders o JOIN stores s ON o.store_id = s.id
    GROUP BY DATE_FORMAT(o.order_datetime, '%Y-%m'), s.id, s.name
)
SELECT ym, store_name, revenue, unique_customers,
       LAG(revenue) OVER (PARTITION BY store_name ORDER BY ym) AS prev_revenue,
       ROUND((revenue - LAG(revenue) OVER (PARTITION BY store_name ORDER BY ym)) /
             NULLIF(LAG(revenue) OVER (PARTITION BY store_name ORDER BY ym), 0) * 100, 1) AS growth_pct,
       RANK() OVER (PARTITION BY ym ORDER BY revenue DESC) AS monthly_rank
FROM monthly_store ORDER BY ym, monthly_rank;
```

**핵심**: LAG + RANK 복합

---

### G-10. 이탈 위험 고객 탐지 ★★★★

**문제**: 평균 구매 주기의 2배 이상 구매 없는 고객을 추출하세요.

```sql
WITH user_intervals AS (
    SELECT user_id,
           AVG(DATEDIFF(order_datetime, LAG(order_datetime) OVER (PARTITION BY user_id ORDER BY order_datetime))) AS avg_interval,
           MAX(order_datetime) AS last_order
    FROM orders GROUP BY user_id
)
SELECT u.id AS user_id, u.name,
       ROUND(ui.avg_interval, 1) AS avg_interval_days,
       DATEDIFF(NOW(), ui.last_order) AS days_since_last_order,
       CASE WHEN DATEDIFF(NOW(), ui.last_order) >= ui.avg_interval * 2 THEN 'HIGH RISK'
            WHEN DATEDIFF(NOW(), ui.last_order) >= ui.avg_interval * 1.5 THEN 'MEDIUM RISK'
            ELSE 'LOW RISK' END AS churn_risk
FROM user_intervals ui JOIN users u ON ui.user_id = u.id
WHERE ui.avg_interval IS NOT NULL
ORDER BY days_since_last_order DESC;
```

**핵심**: 개인별 평균 주기 대비 경과일 비교

---

### G-11. 메뉴별 판매 분석 ★★

**문제**: 카테고리+사이즈별 판매량과 매출을 분석하세요.

```sql
SELECT
    p.category, p.size,
    SUM(oi.quantity) AS total_qty,
    SUM(oi.quantity * oi.unit_price) AS total_revenue,
    ROUND(SUM(oi.quantity * oi.unit_price) / SUM(SUM(oi.quantity * oi.unit_price)) OVER () * 100, 1) AS revenue_share_pct
FROM products p
JOIN order_items oi ON p.id = oi.product_id
GROUP BY p.category, p.size
ORDER BY total_revenue DESC;
```

**핵심**: 전체 대비 비중 계산

---

### G-12. ROI 기반 채널 우선순위 ★★★★

**문제**: 채널별 ROI를 계산하고 우선순위를 매기세요.

```sql
WITH channel_metrics AS (
    SELECT u.utm_source AS channel,
           COUNT(DISTINCT u.id) AS users,
           COALESCE(SUM(o.total_amount), 0) AS revenue
    FROM users u LEFT JOIN orders o ON u.id = o.user_id
    GROUP BY u.utm_source
),
channel_cost AS (
    SELECT channel, SUM(cost) AS cost FROM marketing_costs GROUP BY channel
)
SELECT m.channel, m.users, m.revenue, c.cost,
       ROUND((m.revenue - c.cost) / c.cost * 100, 1) AS roi_pct,
       RANK() OVER (ORDER BY (m.revenue - c.cost) / c.cost DESC) AS priority_rank
FROM channel_metrics m JOIN channel_cost c ON m.channel = c.channel
ORDER BY priority_rank;
```

**핵심**: ROI = (매출 - 비용) / 비용 * 100

---

## 보너스 X: 난이도 최상 (3문제)

### X-1. 연속 로그인 보상 ★★★★

**문제**: 연속 구매일이 3일 이상인 기간을 찾으세요.

```sql
WITH daily_orders AS (
    SELECT DISTINCT user_id, DATE(order_datetime) AS order_date FROM orders
),
with_groups AS (
    SELECT user_id, order_date,
           DATE_SUB(order_date, INTERVAL ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY order_date) DAY) AS grp
    FROM daily_orders
)
SELECT user_id, MIN(order_date) AS streak_start, MAX(order_date) AS streak_end,
       DATEDIFF(MAX(order_date), MIN(order_date)) + 1 AS consecutive_days
FROM with_groups
GROUP BY user_id, grp
HAVING consecutive_days >= 3
ORDER BY consecutive_days DESC;
```

**핵심**: DATE - ROW_NUMBER 패턴으로 연속일 그룹화

---

### X-2. 세션 분석 ★★★★

**문제**: 30분 이상 간격이면 새 세션으로 정의하고 세션별 이벤트를 분석하세요.

```sql
WITH with_diff AS (
    SELECT user_id, event_name, event_time,
           TIMESTAMPDIFF(MINUTE, LAG(event_time) OVER (PARTITION BY user_id ORDER BY event_time), event_time) AS min_diff
    FROM app_logs
),
with_session_flag AS (
    SELECT *, CASE WHEN min_diff IS NULL OR min_diff >= 30 THEN 1 ELSE 0 END AS new_session
    FROM with_diff
),
with_session_id AS (
    SELECT *, SUM(new_session) OVER (PARTITION BY user_id ORDER BY event_time) AS session_id
    FROM with_session_flag
)
SELECT user_id, session_id, COUNT(*) AS event_count,
       MIN(event_time) AS session_start, MAX(event_time) AS session_end,
       TIMESTAMPDIFF(MINUTE, MIN(event_time), MAX(event_time)) AS session_duration_min
FROM with_session_id
GROUP BY user_id, session_id
ORDER BY user_id, session_id;
```

**핵심**: 30분 간격으로 세션 플래그 → SUM OVER로 세션 ID 부여

---

### X-3. 계층 구조 탐색 (재귀 CTE) ★★★★

**문제**: 지역 → 매장 계층으로 매출을 집계하세요.

```sql
SELECT
    s.region,
    s.name AS store_name,
    SUM(o.total_amount) AS store_revenue,
    SUM(SUM(o.total_amount)) OVER (PARTITION BY s.region) AS region_total,
    ROUND(SUM(o.total_amount) / SUM(SUM(o.total_amount)) OVER (PARTITION BY s.region) * 100, 1) AS region_share_pct
FROM stores s
JOIN orders o ON s.id = o.store_id
GROUP BY s.region, s.id, s.name
ORDER BY s.region, store_revenue DESC;
```

**핵심**: PARTITION BY region으로 지역 소계

---

## 핵심 패턴 요약

```sql
-- 1. 그룹별 TOP N
SELECT * FROM (SELECT *, ROW_NUMBER() OVER (PARTITION BY grp ORDER BY val DESC) AS rn FROM t) sub WHERE rn <= N;

-- 2. 미존재 찾기
SELECT a.* FROM a LEFT JOIN b ON a.id = b.a_id WHERE b.id IS NULL;

-- 3. 누적합
SUM(col) OVER (ORDER BY date_col)

-- 4. 전월 대비
LAG(col) OVER (ORDER BY ym)

-- 5. 연속일 그룹화
DATE_SUB(date, INTERVAL ROW_NUMBER() OVER (ORDER BY date) DAY) AS grp

-- 6. 코호트 월 차이
TIMESTAMPDIFF(MONTH, cohort_date, activity_date)
```

---

*Total: 52 problems | Last Updated: 2026-01-20*
