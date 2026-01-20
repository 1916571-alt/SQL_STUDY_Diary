# SQL 실습 문제 정답 및 핵심 포인트

> **XAMPP MySQL `practice` 데이터베이스 기준**
> 총 52문제 정답 수록
> **Curriculum 문제와 1:1 매칭**

---

## 테이블 매핑 가이드

| 문제 | Curriculum 표기 | 실제 테이블 |
|------|-----------------|-------------|
| A-1 | orders (도서) | `book_orders` |
| A-1 | reviews (도서) | `reviews` |
| A-6 | reviews (상품) | `product_reviews` |
| 기타 | orders | `orders` (카페) |

---

## 사용 가능한 테이블

### 기본 테이블
| 테이블 | 컬럼 |
|--------|------|
| `users` | id, name, email, birth_date, created_at, utm_source, grade, phone, rfm_segment |
| `stores` | id, name, region, opened_at |
| `products` | id, name, category, category_id, size, price |
| `orders` | id, user_id, store_id, order_datetime, order_date, total_amount, status |
| `order_items` | id, order_id, product_id, quantity, unit_price |

### A유형 (도서/리뷰)
| 테이블 | 컬럼 |
|--------|------|
| `authors` | id, name, country |
| `books` | id, title, author_id, price, category |
| `book_orders` | id, book_id, user_id, quantity, order_date |
| `reviews` | id, book_id, user_id, rating, review_date |
| `product_reviews` | id, product_id, user_id, rating, content, created_at |
| `categories` | id, name |

### B유형 (윈도우함수)
| 테이블 | 컬럼 |
|--------|------|
| `departments` | id, name, location |
| `employees` | id, name, dept_id, salary, hire_date, manager_id |
| `students` | id, name, class_id |
| `scores` | id, student_id, subject, score |
| `salesperson` | id, name, hire_date |
| `sales` | id, salesperson_id, amount, sale_date |
| `daily_sales` | id, sale_date, product_id, revenue |

### C유형 (시계열)
| 테이블 | 컬럼 |
|--------|------|
| `daily_visitors` | id, visit_date, visitor_count |
| `daily_orders` | id, order_date, number_of_orders |
| `stock_prices` | id, price_date, price |

### D유형 (리텐션)
| 테이블 | 컬럼 |
|--------|------|
| `login_logs` | id, user_id, login_date |
| `app_logs` | id, user_id, event_name, event_date, event_time |

### F유형 (퍼널/AB테스트)
| 테이블 | 컬럼 |
|--------|------|
| `cart_items` | id, user_id, product_id, added_at |
| `ab_test_users` | id, user_id, test_group, assigned_at |

### G유형 (캠페인)
| 테이블 | 컬럼 |
|--------|------|
| `marketing_costs` | id, ym, channel, cost |
| `campaigns` | id, name, target_segment, budget, sent_at |
| `campaign_sends` | id, campaign_id, user_id, sent_at |
| `campaign_opens` | id, send_id, opened_at |
| `campaign_clicks` | id, send_id, clicked_at |

---

## 유형 A: JOIN + 집계 복합 (8문제)

### A-1. 작가별 판매 통계 ★★★

**문제**: 2024년에 가장 많이 팔린 상위 5명의 작가들에 대해, 작가 이름, 총 판매 권수, 평균 평점(소수점 둘째자리), 평점을 받은 책의 개수를 판매량이 많은 순으로 출력

**테이블**: `authors`, `books`, `book_orders`, `reviews`

```sql
SELECT
    a.name AS author_name,
    SUM(bo.quantity) AS total_sales,
    ROUND(AVG(r.rating), 2) AS avg_rating,
    COUNT(DISTINCT r.book_id) AS rated_book_cnt
FROM authors a
JOIN books b ON a.id = b.author_id
JOIN book_orders bo ON b.id = bo.book_id
LEFT JOIN reviews r ON b.id = r.book_id
WHERE YEAR(bo.order_date) = 2024
GROUP BY a.id, a.name
ORDER BY total_sales DESC
LIMIT 5;
```

**핵심**: 4개 테이블 JOIN, LEFT JOIN (리뷰 없는 책 포함), GROUP BY + 집계

---

### A-2. 카테고리별 매출 TOP 3 상품 ★★

**문제**: 각 카테고리별로 2024년 매출액 상위 3개 상품의 상품명, 카테고리명, 총 매출액, 판매 수량을 출력

**테이블**: `products`, `categories`, `order_items`, `orders`

```sql
WITH product_sales AS (
    SELECT
        p.id AS product_id,
        p.name AS product_name,
        c.name AS category_name,
        p.category_id,
        SUM(oi.quantity * oi.unit_price) AS total_revenue,
        SUM(oi.quantity) AS total_qty,
        RANK() OVER (PARTITION BY p.category_id ORDER BY SUM(oi.quantity * oi.unit_price) DESC) AS rnk
    FROM products p
    JOIN categories c ON p.category_id = c.id
    JOIN order_items oi ON p.id = oi.product_id
    JOIN orders o ON oi.order_id = o.id
    WHERE YEAR(o.order_date) = 2024
    GROUP BY p.id, p.name, c.name, p.category_id
)
SELECT category_name, product_name, total_revenue, total_qty
FROM product_sales
WHERE rnk <= 3
ORDER BY category_id, rnk;
```

**핵심**: RANK() OVER (PARTITION BY), CTE 활용

---

### A-3. 고객 등급별 평균 구매 금액 ★★

**문제**: 고객 등급(Gold, Silver, Bronze)별로 평균 주문 금액, 평균 주문 건수, 총 고객 수를 구하세요. 2024년 주문 고객만 대상.

**테이블**: `users`, `orders`

```sql
SELECT
    u.grade,
    ROUND(AVG(o.total_amount), 0) AS avg_order_amount,
    ROUND(COUNT(o.id) / COUNT(DISTINCT u.id), 1) AS avg_order_count,
    COUNT(DISTINCT u.id) AS user_count
FROM users u
JOIN orders o ON u.id = o.user_id
WHERE YEAR(o.order_date) = 2024
GROUP BY u.grade
ORDER BY avg_order_amount DESC;
```

**핵심**: 등급별 GROUP BY, 평균 주문 건수 = 총 주문 / 고객 수

---

### A-4. 미구매 회원 조회 ★★

**문제**: 2024년 1월에 가입했지만 한 번도 구매하지 않은 회원의 회원ID, 이름, 가입일을 출력

**테이블**: `users`, `orders`

```sql
SELECT
    u.id AS user_id,
    u.name,
    u.created_at
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
WHERE DATE_FORMAT(u.created_at, '%Y-%m') = '2024-01'
  AND o.id IS NULL
ORDER BY u.created_at;
```

**핵심**: LEFT JOIN + IS NULL 패턴

---

### A-5. 재구매율 계산 ★★★

**문제**: 2024년 상반기(1-6월)에 첫 구매한 고객 중 하반기(7-12월)에 재구매한 고객의 비율

**테이블**: `orders`

```sql
WITH first_purchase AS (
    SELECT user_id, MIN(order_date) AS first_order_date
    FROM orders
    WHERE YEAR(order_date) = 2024
    GROUP BY user_id
    HAVING MIN(order_date) BETWEEN '2024-01-01' AND '2024-06-30'
),
repurchase AS (
    SELECT DISTINCT fp.user_id
    FROM first_purchase fp
    JOIN orders o ON fp.user_id = o.user_id
    WHERE o.order_date BETWEEN '2024-07-01' AND '2024-12-31'
)
SELECT
    COUNT(DISTINCT fp.user_id) AS first_half_customers,
    COUNT(DISTINCT r.user_id) AS repurchase_customers,
    ROUND(COUNT(DISTINCT r.user_id) / COUNT(DISTINCT fp.user_id) * 100, 2) AS repurchase_rate
FROM first_purchase fp
LEFT JOIN repurchase r ON fp.user_id = r.user_id;
```

**핵심**: CTE로 단계별 분리, 코호트 분석 기초

---

### A-6. 상품별 리뷰 통계 ★★

**문제**: 상품별로 리뷰 개수, 평균 평점, 최고 평점, 최저 평점을 구하되, 리뷰가 5개 이상인 상품만 평균 평점 내림차순으로 출력

**테이블**: `products`, `product_reviews`

```sql
SELECT
    p.name AS product_name,
    COUNT(*) AS review_count,
    ROUND(AVG(pr.rating), 2) AS avg_rating,
    MAX(pr.rating) AS max_rating,
    MIN(pr.rating) AS min_rating
FROM products p
JOIN product_reviews pr ON p.id = pr.product_id
GROUP BY p.id, p.name
HAVING COUNT(*) >= 5
ORDER BY avg_rating DESC;
```

**핵심**: HAVING으로 집계 결과 필터링

---

### A-7. 월별 신규/기존 고객 매출 비교 ★★★

**문제**: 2024년 각 월별로 신규 고객(해당 월 첫 구매)과 기존 고객의 매출액을 각각 구하세요

**테이블**: `orders`

```sql
WITH first_order AS (
    SELECT user_id, MIN(order_date) AS first_order_date
    FROM orders
    GROUP BY user_id
)
SELECT
    DATE_FORMAT(o.order_date, '%Y-%m') AS year_month,
    SUM(CASE WHEN DATE_FORMAT(o.order_date, '%Y-%m') = DATE_FORMAT(fo.first_order_date, '%Y-%m')
             THEN o.total_amount ELSE 0 END) AS new_customer_revenue,
    SUM(CASE WHEN DATE_FORMAT(o.order_date, '%Y-%m') > DATE_FORMAT(fo.first_order_date, '%Y-%m')
             THEN o.total_amount ELSE 0 END) AS existing_customer_revenue
FROM orders o
JOIN first_order fo ON o.user_id = fo.user_id
WHERE YEAR(o.order_date) = 2024
GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
ORDER BY year_month;
```

**핵심**: 첫 구매 월과 현재 주문 월 비교, CASE WHEN 분기

---

### A-8. 동시 구매 상품 분석 ★★★

**문제**: 상품 A(id=1)와 같은 주문에서 함께 구매된 상품들을 동시 구매 횟수가 많은 순으로 상위 10개 출력

**테이블**: `order_items`, `products`

```sql
SELECT
    p.name AS product_name,
    COUNT(*) AS co_purchase_count
FROM order_items oi1
JOIN order_items oi2 ON oi1.order_id = oi2.order_id
JOIN products p ON oi2.product_id = p.id
WHERE oi1.product_id = 1
  AND oi2.product_id != 1
GROUP BY oi2.product_id, p.name
ORDER BY co_purchase_count DESC
LIMIT 10;
```

**핵심**: Self JOIN으로 같은 주문 내 다른 상품 찾기

---

## 유형 B: 윈도우 함수 - 순위 (7문제)

### B-1. 부서별 연봉 TOP 3 ★★

**문제**: 각 부서별로 연봉 상위 3명의 직원 정보를 출력. 동일 연봉자는 모두 표시.

**테이블**: `employees`, `departments`

```sql
SELECT dept_name, emp_name, salary, rank_in_dept
FROM (
    SELECT
        d.name AS dept_name,
        e.name AS emp_name,
        e.salary,
        DENSE_RANK() OVER (PARTITION BY e.dept_id ORDER BY e.salary DESC) AS rank_in_dept
    FROM employees e
    JOIN departments d ON e.dept_id = d.id
) ranked
WHERE rank_in_dept <= 3
ORDER BY dept_name, rank_in_dept;
```

**핵심**: DENSE_RANK (동점자 모두 포함), PARTITION BY

---

### B-2. 카테고리별 판매량 순위 ★★

**문제**: 각 카테고리 내에서 상품별 판매량 순위 1~3위만 출력

**테이블**: `products`, `order_items`

```sql
SELECT category_id, product_name, total_qty, sales_rank
FROM (
    SELECT
        p.category_id,
        p.name AS product_name,
        SUM(oi.quantity) AS total_qty,
        RANK() OVER (PARTITION BY p.category_id ORDER BY SUM(oi.quantity) DESC) AS sales_rank
    FROM products p
    JOIN order_items oi ON p.id = oi.product_id
    GROUP BY p.category_id, p.id, p.name
) ranked
WHERE sales_rank <= 3
ORDER BY category_id, sales_rank;
```

**핵심**: RANK (동점 시 다음 순위 건너뜀)

---

### B-3. 월별 매출 순위 변화 ★★★

**문제**: 각 상품의 월별 매출 순위와 전월 대비 순위 변화(상승/하락/유지)를 표시

**테이블**: `order_items`, `orders`

```sql
WITH monthly_rank AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m') AS year_month,
        oi.product_id,
        SUM(oi.quantity * oi.unit_price) AS monthly_revenue,
        RANK() OVER (PARTITION BY DATE_FORMAT(o.order_date, '%Y-%m')
                     ORDER BY SUM(oi.quantity * oi.unit_price) DESC) AS current_rank
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.id
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m'), oi.product_id
)
SELECT
    year_month,
    product_id,
    monthly_revenue,
    current_rank,
    LAG(current_rank) OVER (PARTITION BY product_id ORDER BY year_month) AS prev_rank,
    CASE
        WHEN LAG(current_rank) OVER (PARTITION BY product_id ORDER BY year_month) IS NULL THEN 'NEW'
        WHEN current_rank < LAG(current_rank) OVER (PARTITION BY product_id ORDER BY year_month) THEN '상승'
        WHEN current_rank > LAG(current_rank) OVER (PARTITION BY product_id ORDER BY year_month) THEN '하락'
        ELSE '유지'
    END AS rank_change
FROM monthly_rank
ORDER BY year_month, current_rank;
```

**핵심**: LAG로 이전 행 비교, CASE WHEN으로 변화 표시

---

### B-4. 성적 상위 10% 학생 ★★

**문제**: 전체 학생 중 총점 기준 상위 10%에 해당하는 학생들의 이름, 총점, 백분위를 출력

**테이블**: `students`, `scores`

```sql
SELECT name, total_score, percentile
FROM (
    SELECT
        s.name,
        SUM(sc.score) AS total_score,
        PERCENT_RANK() OVER (ORDER BY SUM(sc.score) DESC) AS percentile
    FROM students s
    JOIN scores sc ON s.id = sc.student_id
    GROUP BY s.id, s.name
) ranked
WHERE percentile <= 0.1
ORDER BY total_score DESC;
```

**핵심**: PERCENT_RANK (0~1 범위 백분위)

---

### B-5. 연속 1위 기간 ★★★★

**문제**: 일별 매출 데이터에서 상품별로 연속으로 1위를 유지한 최대 기간(일수)을 구하세요

**테이블**: `daily_sales`

```sql
WITH daily_rank AS (
    SELECT
        sale_date,
        product_id,
        RANK() OVER (PARTITION BY sale_date ORDER BY revenue DESC) AS rnk
    FROM daily_sales
),
first_place AS (
    SELECT
        sale_date,
        product_id,
        ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY sale_date) AS rn,
        DATEDIFF(sale_date, '2024-01-01') AS day_num
    FROM daily_rank
    WHERE rnk = 1
),
grouped AS (
    SELECT
        product_id,
        sale_date,
        day_num - rn AS grp
    FROM first_place
)
SELECT
    product_id,
    MAX(consecutive_days) AS max_consecutive_first_days
FROM (
    SELECT product_id, grp, COUNT(*) AS consecutive_days
    FROM grouped
    GROUP BY product_id, grp
) t
GROUP BY product_id
ORDER BY max_consecutive_first_days DESC;
```

**핵심**: 연속 구간 찾기 (날짜 - ROW_NUMBER = 그룹)

---

### B-6. 분기별 실적 순위 ★★

**문제**: 영업사원별 분기별 실적과 해당 분기 내 순위를 구하세요. 실적이 같으면 입사일이 빠른 사람이 높은 순위.

**테이블**: `salesperson`, `sales`

```sql
SELECT
    CONCAT(YEAR(s.sale_date), '-Q', QUARTER(s.sale_date)) AS year_quarter,
    sp.name,
    SUM(s.amount) AS total_sales,
    RANK() OVER (
        PARTITION BY YEAR(s.sale_date), QUARTER(s.sale_date)
        ORDER BY SUM(s.amount) DESC, sp.hire_date ASC
    ) AS quarter_rank
FROM salesperson sp
JOIN sales s ON sp.id = s.salesperson_id
GROUP BY YEAR(s.sale_date), QUARTER(s.sale_date), sp.id, sp.name, sp.hire_date
ORDER BY year_quarter, quarter_rank;
```

**핵심**: 복합 ORDER BY (매출 DESC, 입사일 ASC)

---

### B-7. 그룹별 중앙값 구하기 ★★★

**문제**: 각 부서별 연봉의 중앙값(MEDIAN)을 구하세요

**테이블**: `employees`

```sql
WITH ranked AS (
    SELECT
        dept_id,
        salary,
        ROW_NUMBER() OVER (PARTITION BY dept_id ORDER BY salary) AS rn,
        COUNT(*) OVER (PARTITION BY dept_id) AS cnt
    FROM employees
)
SELECT
    dept_id,
    AVG(salary) AS median_salary
FROM ranked
WHERE rn IN (FLOOR((cnt + 1) / 2), CEIL((cnt + 1) / 2))
GROUP BY dept_id
ORDER BY dept_id;
```

**핵심**: MySQL MEDIAN 없음 → ROW_NUMBER로 중간값 찾기

---

## 유형 C: 윈도우 함수 - 집계/LAG/LEAD (7문제)

### C-1. 고객별 구매 비율 ★★★

**문제**: 각 고객별로 총 구매 횟수, 커피 구매 횟수, 커피 구매 비율, 전체 고객 중 구매액 순위를 표시

**테이블**: `orders`, `order_items`, `products`

```sql
SELECT
    o.user_id,
    COUNT(DISTINCT o.id) AS total_order_cnt,
    COUNT(DISTINCT CASE WHEN p.category = '커피' THEN o.id END) AS coffee_order_cnt,
    SUM(o.total_amount) AS total_amount,
    ROUND(
        SUM(CASE WHEN p.category = '커피' THEN oi.quantity * oi.unit_price ELSE 0 END)
        / SUM(oi.quantity * oi.unit_price) * 100, 1
    ) AS coffee_ratio,
    RANK() OVER (ORDER BY SUM(o.total_amount) DESC) AS amount_rank
FROM orders o
JOIN order_items oi ON o.id = oi.order_id
JOIN products p ON oi.product_id = p.id
GROUP BY o.user_id
ORDER BY amount_rank;
```

**핵심**: CASE WHEN + SUM으로 조건부 집계, RANK OVER로 순위

---

### C-2. 누적 매출 및 목표 달성률 ★★

**문제**: 2024년 각 월별 매출과 연초부터의 누적 매출, 연간 목표(12억) 대비 누적 달성률

**테이블**: `orders`

```sql
SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS year_month,
    SUM(total_amount) AS monthly_revenue,
    SUM(SUM(total_amount)) OVER (ORDER BY DATE_FORMAT(order_date, '%Y-%m')) AS cumulative_revenue,
    ROUND(
        SUM(SUM(total_amount)) OVER (ORDER BY DATE_FORMAT(order_date, '%Y-%m'))
        / 1200000000 * 100, 2
    ) AS achievement_rate
FROM orders
WHERE YEAR(order_date) = 2024
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY year_month;
```

**핵심**: SUM() OVER (ORDER BY)로 누적합

---

### C-3. 이동 평균 (7일) ★★

**문제**: 일별 매출의 7일 이동평균을 구하세요

**테이블**: `daily_sales`

```sql
SELECT
    sale_date AS date,
    SUM(revenue) AS daily_revenue,
    ROUND(
        AVG(SUM(revenue)) OVER (
            ORDER BY sale_date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ), 0
    ) AS moving_avg_7days
FROM daily_sales
GROUP BY sale_date
ORDER BY sale_date;
```

**핵심**: ROWS BETWEEN N PRECEDING AND CURRENT ROW

---

### C-4. 전일 대비 증감률 ★★

**문제**: 일별 방문자 수와 전일 대비 증감률(%)

**테이블**: `daily_visitors`

```sql
SELECT
    visit_date AS date,
    visitor_count,
    LAG(visitor_count) OVER (ORDER BY visit_date) AS prev_day_count,
    ROUND(
        (visitor_count - LAG(visitor_count) OVER (ORDER BY visit_date))
        / LAG(visitor_count) OVER (ORDER BY visit_date) * 100, 1
    ) AS change_rate
FROM daily_visitors
ORDER BY visit_date;
```

**핵심**: LAG로 이전 행 값 가져오기

---

### C-5. NULL 값 채우기 (Forward Fill) ★★★

**문제**: NULL 값을 바로 이전 날짜의 값으로 채우기

**테이블**: `daily_orders`

```sql
SELECT
    order_date AS date,
    COALESCE(
        number_of_orders,
        (SELECT number_of_orders
         FROM daily_orders d2
         WHERE d2.order_date < d1.order_date
           AND d2.number_of_orders IS NOT NULL
         ORDER BY d2.order_date DESC
         LIMIT 1)
    ) AS filled_orders
FROM daily_orders d1
ORDER BY order_date;
```

**핵심**: MySQL은 IGNORE NULLS 미지원 → 서브쿼리로 해결

---

### C-6. 연속 증가 기간 ★★★

**문제**: 주가 데이터에서 연속으로 상승한 최대 일수

**테이블**: `stock_prices`

```sql
WITH price_change AS (
    SELECT
        price_date,
        price,
        CASE WHEN price > LAG(price) OVER (ORDER BY price_date) THEN 1 ELSE 0 END AS is_up
    FROM stock_prices
),
grouped AS (
    SELECT
        price_date,
        is_up,
        SUM(CASE WHEN is_up = 0 THEN 1 ELSE 0 END) OVER (ORDER BY price_date) AS grp
    FROM price_change
)
SELECT MAX(up_days) AS max_consecutive_up_days
FROM (
    SELECT grp, COUNT(*) AS up_days
    FROM grouped
    WHERE is_up = 1
    GROUP BY grp
) t;
```

**핵심**: 연속 구간 = 그룹핑 기법

---

### C-7. 구간별 매출 비중 (파레토) ★★

**문제**: 전체 매출 대비 각 상품 비중과 누적 비중

**테이블**: `order_items`, `products`

```sql
SELECT
    p.name AS product_name,
    SUM(oi.quantity * oi.unit_price) AS revenue,
    ROUND(
        SUM(oi.quantity * oi.unit_price) / SUM(SUM(oi.quantity * oi.unit_price)) OVER () * 100, 1
    ) AS revenue_ratio,
    ROUND(
        SUM(SUM(oi.quantity * oi.unit_price)) OVER (ORDER BY SUM(oi.quantity * oi.unit_price) DESC)
        / SUM(SUM(oi.quantity * oi.unit_price)) OVER () * 100, 1
    ) AS cumulative_ratio
FROM order_items oi
JOIN products p ON oi.product_id = p.id
GROUP BY p.id, p.name
ORDER BY revenue DESC;
```

**핵심**: SUM() OVER ()로 전체 합계, 누적 비중

---

## 유형 D: 코호트/리텐션 (6문제)

### D-1. 월별 코호트 리텐션 ★★★

**문제**: 코호트 월별 유저 수 계산 (첫 접속 기준)

**테이블**: `app_logs`

```sql
WITH first_visit AS (
    SELECT user_id, DATE_FORMAT(MIN(event_date), '%Y-%m') AS cohort_month
    FROM app_logs
    GROUP BY user_id
),
monthly_activity AS (
    SELECT DISTINCT user_id, DATE_FORMAT(event_date, '%Y-%m') AS activity_month
    FROM app_logs
)
SELECT
    f.cohort_month,
    TIMESTAMPDIFF(MONTH,
        STR_TO_DATE(CONCAT(f.cohort_month, '-01'), '%Y-%m-%d'),
        STR_TO_DATE(CONCAT(m.activity_month, '-01'), '%Y-%m-%d')
    ) AS diff_month,
    COUNT(DISTINCT m.user_id) AS user_cnts
FROM first_visit f
JOIN monthly_activity m ON f.user_id = m.user_id
GROUP BY f.cohort_month, diff_month
ORDER BY f.cohort_month, diff_month;
```

**핵심**: 첫 방문 월(코호트) 기준 월별 활성 유저 집계

---

### D-2. 리텐션율 피벗 테이블 ★★★★

**문제**: 코호트별 리텐션율을 피벗 형태로 출력 (M+0, M+1, M+2, M+3)

**테이블**: `app_logs`

```sql
WITH first_visit AS (
    SELECT user_id, DATE_FORMAT(MIN(event_date), '%Y-%m') AS cohort_month
    FROM app_logs
    GROUP BY user_id
),
monthly_activity AS (
    SELECT DISTINCT user_id, DATE_FORMAT(event_date, '%Y-%m') AS activity_month
    FROM app_logs
),
cohort_data AS (
    SELECT
        f.cohort_month,
        TIMESTAMPDIFF(MONTH,
            STR_TO_DATE(CONCAT(f.cohort_month, '-01'), '%Y-%m-%d'),
            STR_TO_DATE(CONCAT(m.activity_month, '-01'), '%Y-%m-%d')
        ) AS diff_month,
        COUNT(DISTINCT m.user_id) AS user_cnt
    FROM first_visit f
    JOIN monthly_activity m ON f.user_id = m.user_id
    GROUP BY f.cohort_month, diff_month
)
SELECT
    cohort_month,
    MAX(CASE WHEN diff_month = 0 THEN user_cnt END) AS M0_users,
    CONCAT(ROUND(MAX(CASE WHEN diff_month = 1 THEN user_cnt END) / MAX(CASE WHEN diff_month = 0 THEN user_cnt END) * 100, 1), '%') AS M1_retention,
    CONCAT(ROUND(MAX(CASE WHEN diff_month = 2 THEN user_cnt END) / MAX(CASE WHEN diff_month = 0 THEN user_cnt END) * 100, 1), '%') AS M2_retention,
    CONCAT(ROUND(MAX(CASE WHEN diff_month = 3 THEN user_cnt END) / MAX(CASE WHEN diff_month = 0 THEN user_cnt END) * 100, 1), '%') AS M3_retention
FROM cohort_data
GROUP BY cohort_month
ORDER BY cohort_month;
```

**핵심**: CASE WHEN으로 피벗, 리텐션율 = 해당월 유저 / M0 유저

---

### D-3. User Type 분류 ★★★★

**문제**: MAU 유저를 New, Current, Resurrected, Dormant로 분류

**테이블**: `app_logs`

```sql
WITH monthly_users AS (
    SELECT DISTINCT user_id, DATE_FORMAT(event_date, '%Y-%m') AS year_month
    FROM app_logs
),
first_activity AS (
    SELECT user_id, MIN(year_month) AS first_month
    FROM monthly_users
    GROUP BY user_id
),
user_status AS (
    SELECT
        m.year_month,
        m.user_id,
        f.first_month,
        LAG(m.year_month) OVER (PARTITION BY m.user_id ORDER BY m.year_month) AS prev_month
    FROM monthly_users m
    JOIN first_activity f ON m.user_id = f.user_id
)
SELECT
    year_month,
    CASE
        WHEN year_month = first_month THEN 'New'
        WHEN prev_month = DATE_FORMAT(DATE_SUB(STR_TO_DATE(CONCAT(year_month, '-01'), '%Y-%m-%d'), INTERVAL 1 MONTH), '%Y-%m') THEN 'Current'
        ELSE 'Resurrected'
    END AS user_type,
    COUNT(*) AS user_cnts
FROM user_status
GROUP BY year_month, user_type
ORDER BY year_month, user_type;
```

**핵심**: LAG로 이전 활동 월 비교, CASE WHEN으로 유저 타입 분류

---

### D-4. 주간 리텐션 (Day 1, 3, 7) ★★★

**문제**: 가입일 기준 Day 1, Day 3, Day 7 리텐션율

**테이블**: `users`, `login_logs`

```sql
SELECT
    DATE_FORMAT(u.created_at, '%Y-%W') AS signup_week,
    COUNT(DISTINCT u.id) AS total_users,
    ROUND(COUNT(DISTINCT CASE WHEN DATEDIFF(l.login_date, DATE(u.created_at)) = 1 THEN u.id END) / COUNT(DISTINCT u.id) * 100, 1) AS d1_retention,
    ROUND(COUNT(DISTINCT CASE WHEN DATEDIFF(l.login_date, DATE(u.created_at)) = 3 THEN u.id END) / COUNT(DISTINCT u.id) * 100, 1) AS d3_retention,
    ROUND(COUNT(DISTINCT CASE WHEN DATEDIFF(l.login_date, DATE(u.created_at)) = 7 THEN u.id END) / COUNT(DISTINCT u.id) * 100, 1) AS d7_retention
FROM users u
LEFT JOIN login_logs l ON u.id = l.user_id
GROUP BY DATE_FORMAT(u.created_at, '%Y-%W')
ORDER BY signup_week;
```

**핵심**: DATEDIFF로 가입일과 로그인일 차이 계산

---

### D-5. 이탈 예측 지표 ★★★

**문제**: 최근 30일간 활동 없고, 과거 평균 접속 주기가 7일 이하인 유저를 "이탈 위험"으로 분류

**테이블**: `app_logs`

```sql
WITH user_activity AS (
    SELECT
        user_id,
        MAX(event_date) AS last_activity_date,
        DATEDIFF(CURDATE(), MAX(event_date)) AS days_since_last_visit,
        AVG(DATEDIFF(event_date, LAG(event_date) OVER (PARTITION BY user_id ORDER BY event_date))) AS avg_visit_interval
    FROM app_logs
    GROUP BY user_id
)
SELECT
    user_id,
    last_activity_date,
    ROUND(avg_visit_interval, 1) AS avg_visit_interval,
    days_since_last_visit
FROM user_activity
WHERE days_since_last_visit >= 30
  AND avg_visit_interval <= 7
ORDER BY days_since_last_visit DESC;
```

**핵심**: LAG로 방문 간격 계산, 조건 필터링

---

### D-6. LTV 코호트별 계산 ★★★★

**문제**: 가입 월 기준 코호트별로 가입 후 6개월간의 평균 LTV

**테이블**: `users`, `orders`

```sql
SELECT
    DATE_FORMAT(u.created_at, '%Y-%m') AS cohort_month,
    COUNT(DISTINCT u.id) AS cohort_size,
    ROUND(
        COALESCE(SUM(CASE
            WHEN o.order_date BETWEEN DATE(u.created_at) AND DATE_ADD(DATE(u.created_at), INTERVAL 6 MONTH)
            THEN o.total_amount ELSE 0 END
        ), 0) / COUNT(DISTINCT u.id), 0
    ) AS avg_ltv_6months
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
GROUP BY DATE_FORMAT(u.created_at, '%Y-%m')
ORDER BY cohort_month;
```

**핵심**: 가입 후 6개월 내 주문만 필터링, 코호트별 평균

---

## 유형 E: 날짜/문자열 처리 (4문제)

### E-1. 연령대별 분석 ★★

**문제**: 생년월일 기준 연령대(10대, 20대...)별 회원 수와 평균 구매금액

**테이블**: `users`, `orders`

```sql
SELECT
    CONCAT(FLOOR((YEAR(CURDATE()) - YEAR(u.birth_date)) / 10) * 10, '대') AS age_group,
    COUNT(DISTINCT u.id) AS user_count,
    ROUND(AVG(o.total_amount), 0) AS avg_purchase_amount
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
GROUP BY FLOOR((YEAR(CURDATE()) - YEAR(u.birth_date)) / 10)
ORDER BY age_group;
```

**핵심**: FLOOR로 연령대 계산

---

### E-2. 요일별 매출 패턴 ★★

**문제**: 요일별(월~일) 평균 매출액과 주문 건수

**테이블**: `orders`

```sql
SELECT
    DAYOFWEEK(order_date) AS day_of_week,
    CASE DAYOFWEEK(order_date)
        WHEN 1 THEN '일요일'
        WHEN 2 THEN '월요일'
        WHEN 3 THEN '화요일'
        WHEN 4 THEN '수요일'
        WHEN 5 THEN '목요일'
        WHEN 6 THEN '금요일'
        WHEN 7 THEN '토요일'
    END AS day_name,
    ROUND(AVG(total_amount), 0) AS avg_revenue,
    COUNT(*) AS order_count
FROM orders
GROUP BY DAYOFWEEK(order_date)
ORDER BY CASE WHEN DAYOFWEEK(order_date) = 1 THEN 8 ELSE DAYOFWEEK(order_date) END;
```

**핵심**: DAYOFWEEK (1=일, 2=월...), 월요일부터 정렬

---

### E-3. 전화번호 포맷 변환 ★

**문제**: 전화번호를 XXX-XXXX-XXXX 형식으로 변환

**테이블**: `users`

```sql
SELECT
    name,
    CONCAT(
        LEFT(phone, 3), '-',
        SUBSTRING(phone, 4, 4), '-',
        RIGHT(phone, 4)
    ) AS formatted_phone
FROM users;
```

**핵심**: LEFT, SUBSTRING, RIGHT, CONCAT

---

### E-4. 시간대별 주문 분포 ★★

**문제**: 주문 시간을 4개 시간대로 구분하여 분석 (새벽/오전/오후/저녁)

**테이블**: `orders`

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
    ROUND(AVG(total_amount), 0) AS avg_order_amount
FROM orders
GROUP BY time_slot
ORDER BY FIELD(time_slot, '새벽(00-06)', '오전(06-12)', '오후(12-18)', '저녁(18-24)');
```

**핵심**: HOUR로 시간 추출, FIELD로 커스텀 정렬

---

## 유형 F: 복합 실전 문제 (5문제)

### F-1. 베스트셀러 분석 ★★★

**문제**: 월별 가장 많이 팔린 상품 TOP 3와 전월 대비 판매량 증감률

**테이블**: `products`, `order_items`, `orders`

```sql
WITH monthly_sales AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m') AS year_month,
        p.id AS product_id,
        p.name AS product_name,
        SUM(oi.quantity) AS quantity,
        RANK() OVER (PARTITION BY DATE_FORMAT(o.order_date, '%Y-%m') ORDER BY SUM(oi.quantity) DESC) AS rnk
    FROM products p
    JOIN order_items oi ON p.id = oi.product_id
    JOIN orders o ON oi.order_id = o.id
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m'), p.id, p.name
)
SELECT
    year_month,
    rnk AS rank_num,
    product_name,
    quantity,
    LAG(quantity) OVER (PARTITION BY product_id ORDER BY year_month) AS prev_quantity,
    CASE
        WHEN LAG(quantity) OVER (PARTITION BY product_id ORDER BY year_month) IS NULL THEN 'NEW'
        ELSE CONCAT(ROUND((quantity - LAG(quantity) OVER (PARTITION BY product_id ORDER BY year_month))
                          / LAG(quantity) OVER (PARTITION BY product_id ORDER BY year_month) * 100, 1), '%')
    END AS change_rate
FROM monthly_sales
WHERE rnk <= 3
ORDER BY year_month, rnk;
```

**핵심**: RANK + LAG 조합, 증감률 계산

---

### F-2. RFM 분석 ★★★★

**문제**: 고객을 RFM 점수로 분류

**테이블**: `users`, `orders`

```sql
WITH rfm_raw AS (
    SELECT
        u.id AS user_id,
        u.name,
        DATEDIFF(CURDATE(), MAX(o.order_date)) AS recency,
        COUNT(o.id) AS frequency,
        COALESCE(SUM(o.total_amount), 0) AS monetary
    FROM users u
    LEFT JOIN orders o ON u.id = o.user_id
    GROUP BY u.id, u.name
)
SELECT
    user_id,
    name,
    CASE WHEN recency <= 30 THEN 3 WHEN recency <= 90 THEN 2 ELSE 1 END AS recency_score,
    CASE WHEN frequency >= 10 THEN 3 WHEN frequency >= 5 THEN 2 ELSE 1 END AS frequency_score,
    CASE WHEN monetary >= 1000000 THEN 3 WHEN monetary >= 500000 THEN 2 ELSE 1 END AS monetary_score,
    CONCAT(
        CASE WHEN recency <= 30 THEN 3 WHEN recency <= 90 THEN 2 ELSE 1 END,
        CASE WHEN frequency >= 10 THEN 3 WHEN frequency >= 5 THEN 2 ELSE 1 END,
        CASE WHEN monetary >= 1000000 THEN 3 WHEN monetary >= 500000 THEN 2 ELSE 1 END
    ) AS rfm_segment
FROM rfm_raw
ORDER BY rfm_segment DESC;
```

**핵심**: RFM 각 지표별 점수화, 세그먼트 생성

---

### F-3. 장바구니 이탈 분석 ★★★

**문제**: 장바구니에 담았지만 24시간 내 구매하지 않은 상품의 이탈률

**테이블**: `cart_items`, `order_items`, `orders`, `products`

```sql
WITH cart_with_purchase AS (
    SELECT
        c.product_id,
        c.user_id,
        c.added_at,
        CASE
            WHEN EXISTS (
                SELECT 1 FROM orders o
                JOIN order_items oi ON o.id = oi.order_id
                WHERE o.user_id = c.user_id
                  AND oi.product_id = c.product_id
                  AND o.order_datetime BETWEEN c.added_at AND DATE_ADD(c.added_at, INTERVAL 24 HOUR)
            ) THEN 1 ELSE 0
        END AS purchased
    FROM cart_items c
)
SELECT
    p.name AS product_name,
    COUNT(*) AS cart_add_count,
    SUM(purchased) AS purchase_count,
    ROUND((1 - SUM(purchased) / COUNT(*)) * 100, 1) AS abandon_rate
FROM cart_with_purchase cwp
JOIN products p ON cwp.product_id = p.id
GROUP BY cwp.product_id, p.name
ORDER BY abandon_rate DESC;
```

**핵심**: EXISTS로 24시간 내 구매 여부 확인

---

### F-4. 퍼널 분석 ★★★★

**문제**: 회원가입 → 첫 장바구니 → 첫 구매 퍼널의 단계별 전환율

**테이블**: `users`, `cart_items`, `orders`

```sql
SELECT
    DATE(u.created_at) AS signup_date,
    COUNT(DISTINCT u.id) AS signups,
    COUNT(DISTINCT c.user_id) AS cart_users,
    COUNT(DISTINCT o.user_id) AS purchasers,
    ROUND(COUNT(DISTINCT c.user_id) / COUNT(DISTINCT u.id) * 100, 1) AS signup_to_cart_rate,
    ROUND(COUNT(DISTINCT o.user_id) / NULLIF(COUNT(DISTINCT c.user_id), 0) * 100, 1) AS cart_to_purchase_rate
FROM users u
LEFT JOIN cart_items c ON u.id = c.user_id
LEFT JOIN orders o ON u.id = o.user_id
GROUP BY DATE(u.created_at)
ORDER BY signup_date;
```

**핵심**: LEFT JOIN으로 각 단계 유저 수 집계, NULLIF로 0 나눗셈 방지

---

### F-5. A/B 테스트 결과 분석 ★★★

**문제**: A/B 테스트 그룹별 전환율, 평균 구매금액, 구매자 수 비교

**테이블**: `ab_test_users`, `orders`

```sql
SELECT
    ab.test_group,
    COUNT(DISTINCT ab.user_id) AS total_users,
    COUNT(DISTINCT o.user_id) AS purchasers,
    ROUND(COUNT(DISTINCT o.user_id) / COUNT(DISTINCT ab.user_id) * 100, 1) AS conversion_rate,
    ROUND(AVG(o.total_amount), 0) AS avg_purchase_amount,
    COALESCE(SUM(o.total_amount), 0) AS total_revenue
FROM ab_test_users ab
LEFT JOIN orders o ON ab.user_id = o.user_id
    AND o.order_datetime >= ab.assigned_at
GROUP BY ab.test_group
ORDER BY test_group;
```

**핵심**: 테스트 배정 이후 주문만 집계 (order_datetime >= assigned_at)

---

## 유형 G: 그로스해킹/CRM (12문제)

### G-1. 고객별 평균 구매 주기 분석 ★★★

**문제**: 각 고객의 평균 구매 주기(일) 계산. 2회 이상 구매 고객만, 주기가 짧은 순.

**테이블**: `users`, `orders`

```sql
WITH order_intervals AS (
    SELECT
        user_id,
        order_date,
        LAG(order_date) OVER (PARTITION BY user_id ORDER BY order_date) AS prev_order_date
    FROM orders
)
SELECT
    u.id AS user_id,
    u.name,
    COUNT(DISTINCT o.id) AS order_count,
    ROUND(AVG(DATEDIFF(oi.order_date, oi.prev_order_date)), 1) AS avg_purchase_interval_days,
    MAX(o.order_date) AS last_order_date
FROM users u
JOIN orders o ON u.id = o.user_id
JOIN order_intervals oi ON u.id = oi.user_id AND oi.prev_order_date IS NOT NULL
GROUP BY u.id, u.name
HAVING COUNT(DISTINCT o.id) >= 2
ORDER BY avg_purchase_interval_days;
```

**핵심**: LAG로 이전 주문일 가져와 간격 계산

---

### G-2. 구매 주기 기반 세그먼트 분류 ★★★

**문제**: 고객을 구매 주기에 따라 Heavy/Regular/Light/Occasional로 분류

**테이블**: `orders`

```sql
WITH purchase_intervals AS (
    SELECT
        user_id,
        AVG(DATEDIFF(order_date, LAG(order_date) OVER (PARTITION BY user_id ORDER BY order_date))) AS avg_interval
    FROM orders
    GROUP BY user_id
),
user_segment AS (
    SELECT
        o.user_id,
        pi.avg_interval,
        CASE
            WHEN pi.avg_interval <= 7 THEN 'Heavy'
            WHEN pi.avg_interval <= 14 THEN 'Regular'
            WHEN pi.avg_interval <= 30 THEN 'Light'
            ELSE 'Occasional'
        END AS segment,
        SUM(o.total_amount) AS total_revenue
    FROM orders o
    LEFT JOIN purchase_intervals pi ON o.user_id = pi.user_id
    GROUP BY o.user_id, pi.avg_interval
)
SELECT
    segment,
    COUNT(*) AS customer_count,
    ROUND(AVG(total_revenue), 0) AS avg_order_amount,
    SUM(total_revenue) AS total_revenue,
    ROUND(SUM(total_revenue) / (SELECT SUM(total_amount) FROM orders) * 100, 1) AS revenue_share_pct
FROM user_segment
GROUP BY segment
ORDER BY FIELD(segment, 'Heavy', 'Regular', 'Light', 'Occasional');
```

**핵심**: 구매 주기 기반 세그먼트 분류, 매출 비중 계산

---

### G-3. CAC 계산 ★★★

**문제**: 월별 CAC(신규 고객 획득 비용)와 첫 구매 전환율

**테이블**: `users`, `orders`, `marketing_costs`

```sql
WITH monthly_new_users AS (
    SELECT
        DATE_FORMAT(created_at, '%Y-%m') AS year_month,
        COUNT(*) AS new_users
    FROM users
    GROUP BY DATE_FORMAT(created_at, '%Y-%m')
),
first_purchasers AS (
    SELECT
        DATE_FORMAT(u.created_at, '%Y-%m') AS year_month,
        COUNT(DISTINCT o.user_id) AS first_purchasers
    FROM users u
    JOIN orders o ON u.id = o.user_id
    WHERE DATE_FORMAT(o.order_date, '%Y-%m') = DATE_FORMAT(u.created_at, '%Y-%m')
    GROUP BY DATE_FORMAT(u.created_at, '%Y-%m')
),
monthly_cost AS (
    SELECT ym AS year_month, SUM(cost) AS marketing_cost
    FROM marketing_costs
    GROUP BY ym
)
SELECT
    mnu.year_month,
    mc.marketing_cost,
    mnu.new_users,
    COALESCE(fp.first_purchasers, 0) AS first_purchasers,
    ROUND(mc.marketing_cost / mnu.new_users, 0) AS cac,
    ROUND(COALESCE(fp.first_purchasers, 0) / mnu.new_users * 100, 1) AS first_purchase_rate
FROM monthly_new_users mnu
LEFT JOIN monthly_cost mc ON mnu.year_month = mc.year_month
LEFT JOIN first_purchasers fp ON mnu.year_month = fp.year_month
ORDER BY mnu.year_month;
```

**핵심**: CAC = 마케팅비용 / 신규고객수

---

### G-4. ROAS 채널별 분석 ★★★

**문제**: 마케팅 채널별 ROAS 계산

**테이블**: `users`, `orders`, `marketing_costs`

```sql
WITH channel_revenue AS (
    SELECT
        u.utm_source AS channel,
        COUNT(DISTINCT u.id) AS attributed_users,
        COALESCE(SUM(o.total_amount), 0) AS attributed_revenue
    FROM users u
    LEFT JOIN orders o ON u.id = o.user_id
    WHERE u.utm_source != 'organic'
    GROUP BY u.utm_source
),
channel_cost AS (
    SELECT channel, SUM(cost) AS ad_spend
    FROM marketing_costs
    GROUP BY channel
)
SELECT
    cr.channel,
    COALESCE(cc.ad_spend, 0) AS ad_spend,
    cr.attributed_users,
    cr.attributed_revenue,
    CASE
        WHEN cc.ad_spend > 0 THEN ROUND(cr.attributed_revenue / cc.ad_spend * 100, 1)
        ELSE NULL
    END AS roas_pct
FROM channel_revenue cr
LEFT JOIN channel_cost cc ON cr.channel = cc.channel
ORDER BY roas_pct DESC;
```

**핵심**: ROAS = 매출 / 광고비 × 100

---

### G-5. LTV vs CAC 비율 분석 ★★★★

**문제**: 코호트별 12개월 LTV와 CAC 비교

**테이블**: `users`, `orders`, `marketing_costs`

```sql
WITH cohort_ltv AS (
    SELECT
        DATE_FORMAT(u.created_at, '%Y-%m') AS cohort_month,
        COUNT(DISTINCT u.id) AS cohort_size,
        ROUND(COALESCE(SUM(o.total_amount), 0) / COUNT(DISTINCT u.id), 0) AS ltv_12months
    FROM users u
    LEFT JOIN orders o ON u.id = o.user_id
        AND o.order_date <= DATE_ADD(DATE(u.created_at), INTERVAL 12 MONTH)
    GROUP BY DATE_FORMAT(u.created_at, '%Y-%m')
),
cohort_cac AS (
    SELECT
        DATE_FORMAT(u.created_at, '%Y-%m') AS cohort_month,
        ROUND(SUM(mc.cost) / COUNT(DISTINCT u.id), 0) AS cac
    FROM users u
    JOIN marketing_costs mc ON DATE_FORMAT(u.created_at, '%Y-%m') = mc.ym
    GROUP BY DATE_FORMAT(u.created_at, '%Y-%m')
)
SELECT
    cl.cohort_month,
    cl.cohort_size,
    COALESCE(cc.cac, 0) AS cac,
    cl.ltv_12months,
    CASE
        WHEN cc.cac > 0 THEN ROUND(cl.ltv_12months / cc.cac, 2)
        ELSE NULL
    END AS ltv_cac_ratio,
    CASE
        WHEN cc.cac > 0 AND cl.ltv_12months / cc.cac >= 3 THEN 'Healthy'
        ELSE 'At Risk'
    END AS health_status
FROM cohort_ltv cl
LEFT JOIN cohort_cac cc ON cl.cohort_month = cc.cohort_month
ORDER BY cl.cohort_month;
```

**핵심**: LTV/CAC >= 3 이면 건강한 비즈니스

---

### G-6. CRM 캠페인 성과 분석 ★★★

**문제**: 캠페인별 발송수, 오픈율, 클릭율, 전환율, 매출

**테이블**: `campaigns`, `campaign_sends`, `campaign_opens`, `campaign_clicks`, `orders`

```sql
SELECT
    c.name AS campaign_name,
    COUNT(DISTINCT cs.id) AS sent_count,
    ROUND(COUNT(DISTINCT co.send_id) / COUNT(DISTINCT cs.id) * 100, 1) AS open_rate,
    ROUND(COUNT(DISTINCT cc.send_id) / COUNT(DISTINCT cs.id) * 100, 1) AS click_rate,
    ROUND(COUNT(DISTINCT CASE
        WHEN o.order_datetime BETWEEN cs.sent_at AND DATE_ADD(cs.sent_at, INTERVAL 24 HOUR)
        THEN o.user_id END) / COUNT(DISTINCT cs.user_id) * 100, 1) AS conversion_rate,
    COALESCE(SUM(CASE
        WHEN o.order_datetime BETWEEN cs.sent_at AND DATE_ADD(cs.sent_at, INTERVAL 24 HOUR)
        THEN o.total_amount END), 0) AS campaign_revenue
FROM campaigns c
JOIN campaign_sends cs ON c.id = cs.campaign_id
LEFT JOIN campaign_opens co ON cs.id = co.send_id
LEFT JOIN campaign_clicks cc ON cs.id = cc.send_id
LEFT JOIN orders o ON cs.user_id = o.user_id
GROUP BY c.id, c.name
ORDER BY campaign_revenue DESC;
```

**핵심**: 24시간 내 전환, 단계별 전환율 계산

---

### G-7. 재주문율 및 재주문 주기 분석 ★★★

**문제**: 첫 구매 후 재주문 비율과 평균 일수

**테이블**: `orders`

```sql
WITH first_orders AS (
    SELECT user_id, MIN(order_date) AS first_order_date
    FROM orders
    GROUP BY user_id
),
repeat_orders AS (
    SELECT
        fo.user_id,
        MIN(o.order_date) AS second_order_date,
        DATEDIFF(MIN(o.order_date), fo.first_order_date) AS days_to_repeat
    FROM first_orders fo
    JOIN orders o ON fo.user_id = o.user_id AND o.order_date > fo.first_order_date
    GROUP BY fo.user_id, fo.first_order_date
)
SELECT
    DATE_FORMAT(fo.first_order_date, '%Y-%m') AS first_order_month,
    COUNT(DISTINCT fo.user_id) AS first_purchasers,
    COUNT(DISTINCT ro.user_id) AS repeat_purchasers,
    ROUND(COUNT(DISTINCT ro.user_id) / COUNT(DISTINCT fo.user_id) * 100, 1) AS repeat_rate,
    ROUND(AVG(ro.days_to_repeat), 1) AS avg_days_to_repeat
FROM first_orders fo
LEFT JOIN repeat_orders ro ON fo.user_id = ro.user_id
GROUP BY DATE_FORMAT(fo.first_order_date, '%Y-%m')
ORDER BY first_order_month;
```

**핵심**: 첫 구매일과 재구매일 비교

---

### G-8. 시간대별 주문 패턴 ★★

**문제**: 시간대별 주문 건수와 평균 금액, 피크 타임 구분

**테이블**: `orders`

```sql
WITH hourly_stats AS (
    SELECT
        HOUR(order_datetime) AS hour,
        SUM(CASE WHEN DAYOFWEEK(order_datetime) BETWEEN 2 AND 6 THEN 1 ELSE 0 END) AS weekday_orders,
        SUM(CASE WHEN DAYOFWEEK(order_datetime) IN (1, 7) THEN 1 ELSE 0 END) AS weekend_orders,
        AVG(total_amount) AS avg_amount
    FROM orders
    GROUP BY HOUR(order_datetime)
),
ranked AS (
    SELECT *, RANK() OVER (ORDER BY weekday_orders + weekend_orders DESC) AS order_rank
    FROM hourly_stats
)
SELECT
    hour,
    weekday_orders,
    weekend_orders,
    ROUND(avg_amount, 0) AS avg_amount,
    CASE WHEN order_rank <= 3 THEN 'Y' ELSE 'N' END AS is_peak_time
FROM ranked
ORDER BY hour;
```

**핵심**: 요일 구분, RANK로 피크 타임 식별

---

### G-9. 매장별 성과 비교 및 순위 ★★★

**문제**: 매장별 월간 매출, 주문 건수, 객단가, 재방문율, 성장률, 순위

**테이블**: `stores`, `orders`

```sql
WITH monthly_store AS (
    SELECT
        s.name AS store_name,
        s.region,
        DATE_FORMAT(o.order_date, '%Y-%m') AS year_month,
        SUM(o.total_amount) AS monthly_revenue,
        COUNT(*) AS order_count,
        COUNT(DISTINCT o.user_id) AS unique_customers
    FROM stores s
    JOIN orders o ON s.id = o.store_id
    GROUP BY s.id, s.name, s.region, DATE_FORMAT(o.order_date, '%Y-%m')
)
SELECT
    store_name,
    region,
    monthly_revenue,
    order_count,
    ROUND(monthly_revenue / order_count, 0) AS avg_ticket,
    LAG(monthly_revenue) OVER (PARTITION BY store_name ORDER BY year_month) AS prev_revenue,
    ROUND((monthly_revenue - LAG(monthly_revenue) OVER (PARTITION BY store_name ORDER BY year_month))
          / LAG(monthly_revenue) OVER (PARTITION BY store_name ORDER BY year_month) * 100, 1) AS growth_rate,
    RANK() OVER (PARTITION BY year_month ORDER BY monthly_revenue DESC) AS revenue_rank
FROM monthly_store
ORDER BY year_month DESC, revenue_rank;
```

**핵심**: LAG로 전월 비교, RANK로 매장 순위

---

### G-10. 이탈 위험 고객 조기 탐지 ★★★★

**문제**: 이탈 위험 고객 추출 (평균 주기 2배 이상 미구매, 매출 50% 감소, 30일 미접속)

**테이블**: `users`, `orders`, `app_logs`

```sql
WITH user_metrics AS (
    SELECT
        u.id AS user_id,
        u.name,
        AVG(DATEDIFF(o2.order_date, o1.order_date)) AS avg_interval,
        DATEDIFF(CURDATE(), MAX(o1.order_date)) AS days_since_last_order,
        SUM(CASE WHEN o1.order_date >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH) THEN o1.total_amount ELSE 0 END) AS recent_revenue,
        SUM(CASE WHEN o1.order_date BETWEEN DATE_SUB(CURDATE(), INTERVAL 6 MONTH) AND DATE_SUB(CURDATE(), INTERVAL 3 MONTH) THEN o1.total_amount ELSE 0 END) AS prev_revenue
    FROM users u
    JOIN orders o1 ON u.id = o1.user_id
    LEFT JOIN orders o2 ON u.id = o2.user_id AND o2.order_date < o1.order_date
    GROUP BY u.id, u.name
),
app_activity AS (
    SELECT user_id, MAX(event_date) AS last_app_date
    FROM app_logs
    GROUP BY user_id
)
SELECT
    um.user_id,
    um.name,
    ROUND(um.avg_interval, 1) AS avg_interval,
    um.days_since_last_order,
    ROUND((um.prev_revenue - um.recent_revenue) / NULLIF(um.prev_revenue, 0) * 100, 1) AS recent_revenue_drop,
    CASE
        WHEN um.days_since_last_order >= um.avg_interval * 2 THEN 1 ELSE 0
    END + CASE
        WHEN (um.prev_revenue - um.recent_revenue) / NULLIF(um.prev_revenue, 0) >= 0.5 THEN 1 ELSE 0
    END + CASE
        WHEN DATEDIFF(CURDATE(), aa.last_app_date) >= 30 OR aa.last_app_date IS NULL THEN 1 ELSE 0
    END AS churn_risk_score
FROM user_metrics um
LEFT JOIN app_activity aa ON um.user_id = aa.user_id
HAVING churn_risk_score >= 2
ORDER BY churn_risk_score DESC;
```

**핵심**: 다중 조건 이탈 위험 점수화

---

### G-11. 메뉴별 판매 분석 ★★

**문제**: 카테고리별, 사이즈별 판매량과 시간대별 선호 변화

**테이블**: `products`, `order_items`, `orders`

```sql
SELECT
    p.category,
    p.size,
    COUNT(*) AS order_count,
    SUM(oi.quantity * oi.unit_price) AS revenue,
    ROUND(SUM(CASE WHEN HOUR(o.order_datetime) BETWEEN 6 AND 11 THEN oi.quantity ELSE 0 END) / SUM(oi.quantity) * 100, 1) AS morning_share,
    ROUND(SUM(CASE WHEN HOUR(o.order_datetime) BETWEEN 12 AND 17 THEN oi.quantity ELSE 0 END) / SUM(oi.quantity) * 100, 1) AS afternoon_share,
    ROUND(SUM(CASE WHEN HOUR(o.order_datetime) >= 18 OR HOUR(o.order_datetime) < 6 THEN oi.quantity ELSE 0 END) / SUM(oi.quantity) * 100, 1) AS evening_share
FROM products p
JOIN order_items oi ON p.id = oi.product_id
JOIN orders o ON oi.order_id = o.id
GROUP BY p.category, p.size
ORDER BY order_count DESC;
```

**핵심**: 시간대별 CASE WHEN으로 비중 계산

---

### G-12. ROI 기반 세그먼트 우선순위 ★★★★

**문제**: RFM 세그먼트별 마케팅 ROI 분석

**테이블**: `users`, `orders`, `campaign_sends`, `campaigns`

```sql
WITH segment_revenue AS (
    SELECT
        u.rfm_segment,
        COUNT(DISTINCT u.id) AS user_count,
        SUM(CASE WHEN o.order_date < '2024-04-01' THEN o.total_amount ELSE 0 END) AS pre_campaign_revenue,
        SUM(CASE WHEN o.order_date >= '2024-04-01' THEN o.total_amount ELSE 0 END) AS post_campaign_revenue
    FROM users u
    LEFT JOIN orders o ON u.id = o.user_id
    GROUP BY u.rfm_segment
),
segment_cost AS (
    SELECT
        u.rfm_segment,
        SUM(c.budget) / COUNT(DISTINCT cs.user_id) * COUNT(DISTINCT CASE WHEN u.rfm_segment = u.rfm_segment THEN cs.user_id END) AS campaign_cost
    FROM users u
    JOIN campaign_sends cs ON u.id = cs.user_id
    JOIN campaigns c ON cs.campaign_id = c.id
    GROUP BY u.rfm_segment
)
SELECT
    sr.rfm_segment,
    sr.user_count,
    sr.pre_campaign_revenue,
    sr.post_campaign_revenue,
    COALESCE(sc.campaign_cost, 0) AS campaign_cost,
    sr.post_campaign_revenue - sr.pre_campaign_revenue AS incremental_revenue,
    CASE
        WHEN sc.campaign_cost > 0
        THEN ROUND((sr.post_campaign_revenue - sr.pre_campaign_revenue) / sc.campaign_cost * 100, 1)
        ELSE NULL
    END AS roi_pct,
    RANK() OVER (ORDER BY (sr.post_campaign_revenue - sr.pre_campaign_revenue) / NULLIF(sc.campaign_cost, 0) DESC) AS priority_rank
FROM segment_revenue sr
LEFT JOIN segment_cost sc ON sr.rfm_segment = sc.rfm_segment
ORDER BY priority_rank;
```

**핵심**: 캠페인 전후 매출 비교, ROI = 증분매출 / 비용

---

## 유형 X: 고급 문제 (3문제)

### X-1. 연속 로그인 보상 ★★★★

**문제**: 7일 연속 로그인한 유저의 연속 기간 정보

**테이블**: `login_logs`

```sql
WITH login_groups AS (
    SELECT
        user_id,
        login_date,
        DATE_SUB(login_date, INTERVAL ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY login_date) DAY) AS grp
    FROM (SELECT DISTINCT user_id, login_date FROM login_logs) t
)
SELECT
    user_id,
    MIN(login_date) AS streak_start,
    MAX(login_date) AS streak_end,
    COUNT(*) AS consecutive_days
FROM login_groups
GROUP BY user_id, grp
HAVING COUNT(*) >= 7
ORDER BY user_id, streak_start;
```

**핵심**: 날짜 - ROW_NUMBER = 연속 그룹

---

### X-2. 세션 분석 ★★★★

**문제**: 30분 이상 간격이면 새 세션, 세션별 통계

**테이블**: `app_logs`

```sql
WITH time_diff AS (
    SELECT
        user_id,
        event_name,
        event_time,
        TIMESTAMPDIFF(MINUTE,
            LAG(event_time) OVER (PARTITION BY user_id ORDER BY event_time),
            event_time
        ) AS min_diff
    FROM app_logs
),
session_flag AS (
    SELECT
        *,
        CASE WHEN min_diff IS NULL OR min_diff >= 30 THEN 1 ELSE 0 END AS new_session
    FROM time_diff
),
session_assigned AS (
    SELECT
        *,
        SUM(new_session) OVER (PARTITION BY user_id ORDER BY event_time) AS session_id
    FROM session_flag
)
SELECT
    user_id,
    session_id,
    COUNT(*) AS event_count,
    TIMESTAMPDIFF(MINUTE, MIN(event_time), MAX(event_time)) AS session_duration_min,
    MIN(event_name) AS first_event,
    MAX(event_name) AS last_event
FROM session_assigned
GROUP BY user_id, session_id
ORDER BY user_id, session_id;
```

**핵심**: LAG로 간격 계산, SUM() OVER로 세션 ID 부여

---

### X-3. 계층 구조 탐색 (재귀 CTE) ★★★★

**문제**: 조직도에서 특정 매니저 아래 모든 직원을 계층 레벨과 함께 출력

**테이블**: `employees`

```sql
WITH RECURSIVE org_tree AS (
    -- Base case: CEO (manager_id IS NULL)
    SELECT
        id,
        name,
        manager_id,
        0 AS level,
        CAST(name AS CHAR(500)) AS path
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    -- Recursive case
    SELECT
        e.id,
        e.name,
        e.manager_id,
        ot.level + 1,
        CONCAT(ot.path, ' > ', e.name)
    FROM employees e
    JOIN org_tree ot ON e.manager_id = ot.id
)
SELECT id, name, level, path
FROM org_tree
ORDER BY path;
```

**핵심**: WITH RECURSIVE로 계층 탐색, CONCAT으로 경로 생성

---

## 학습 팁

### 문제 접근법
```
1) Expected Output 형태 파악
2) 필요한 테이블/컬럼 확인
3) 중간 Output 설계 (CTE)
4) 단계별 쿼리 작성
5) 최종 쿼리 조합
```

### 자주 쓰는 패턴
- **LEFT JOIN + IS NULL**: 없는 데이터 찾기
- **RANK/DENSE_RANK + 서브쿼리**: TOP N
- **LAG/LEAD**: 이전/다음 행 비교
- **SUM() OVER (ORDER BY)**: 누적합
- **날짜 - ROW_NUMBER**: 연속 구간 찾기

---

*Last Updated: 2026-01-20*
