USE practice;

-- =====================================================
-- SQL 실전 문제 풀이 (52문제)
-- =====================================================
-- 테이블 생성: XAMPP MySQL.session.sql 먼저 실행 필요
-- =====================================================

-- =====================================================
-- 테이블 빠른 참조 (문제 풀기 전 확인!)
-- =====================================================
-- [기본]
--   users          : id, name, email, birth_date, created_at, utm_source, grade, phone, rfm_segment
--   stores         : id, name, region, opened_at
--   products       : id, name, category, category_id, size, price
--   orders         : id, user_id, store_id, order_datetime, order_date, total_amount, status
--   order_items    : id, order_id, product_id, quantity, unit_price
--
-- [도서 (A-1, A-4 전용)]
--   authors        : id, name, country
--   books          : id, title, author_id, price, category
--   book_orders    : id, book_id, user_id, quantity, order_date
--   reviews        : id, book_id, user_id, rating, review_date  ← 도서 리뷰!
--
-- [상품 리뷰 (A-6 전용)]
--   product_reviews: id, product_id, user_id, rating, content, created_at  ← 상품 리뷰!
--
-- [윈도우 함수용]
--   departments    : id, name, location
--   employees      : id, name, dept_id, salary, hire_date, manager_id
--   students       : id, name, class_id
--   scores         : id, student_id, subject, score
--   salesperson    : id, name, hire_date
--   sales          : id, salesperson_id, amount, sale_date
--   daily_sales    : id, sale_date, product_id, revenue
--
-- [시계열]
--   daily_visitors : id, visit_date, visitor_count
--   daily_orders   : id, order_date, number_of_orders
--   stock_prices   : id, price_date, price
--
-- [리텐션/로그]
--   login_logs     : id, user_id, login_date
--   app_logs       : id, user_id, event_name, event_date, event_time
--
-- [마케팅/캠페인]
--   marketing_costs: id, ym, channel, cost
--   campaigns      : id, name, target_segment, budget, sent_at
--   campaign_sends : id, campaign_id, user_id, sent_at
--   campaign_opens : id, send_id, opened_at
--   campaign_clicks: id, send_id, clicked_at
--
-- [기타]
--   cart_items     : id, user_id, product_id, added_at
--   ab_test_users  : id, user_id, test_group, assigned_at
--   categories     : id, name
-- =====================================================

-- =====================================================
-- 맞춤 학습 로드맵 (52문제 순서)
-- =====================================================
-- [1단계] 기본기 + 약점 보완 (9문제)
-- -------------------------------------------------
--  1. A-4  미구매 회원 조회        ★★    LEFT JOIN + IS NULL
--  2. A-6  상품별 리뷰 통계        ★★    기본 집계 워밍업
SELECT product_id,
       COUNT(user_id) AS review_count,
       AVG(RATING) AS avg_rating,
       MAX(RATING) as max_rating,
       MIN(RATING) as min_rating
FROM product_reviews
group by product_id
having COUNT(user_id) > 5
ORDER BY avg_rating DESC
--  3. A-3  고객 등급별 평균 구매   ★★    GROUP BY + 조건
-- 재풀이 필요
with base as(
SELECT user_id,
       SUM(total_amount) as order_amount,
       count(*) as order_count
FROM orders 
where year(order_date) = 2024
group by user_id)
select u.grade,
       avg(order_amount) as avg_order_amount,
       avg(order_count) as avg_order_count,
       count(b.user_id) as user_count
from base b
join users u
on b.user_id = u.id
group by u.grade
--  4. A-1  작가별 판매 통계        ★★★   복합 JOIN
SELECT a.name as author_name,
       sum(bo.quantity) as total_sales,
       round(avg(rating),2) as avg_rating,
       count(r.id) as rated_book_cnt
FROM book_orders bo
join books b
on bo.book_id = b.id
join authors a
on b.author_id = a.id
join reviews r
on r.book_id = bo.book_id
group by a.name
order by total_sales
--  5. A-2  카테고리별 매출 TOP 3   ★★    서브쿼리 + 순위
with base as (
SELECT 
       c.name as category_name,
       p.name as product_name,
       sum(p.price * oi.quantity) as total_revenue,
       sum(oi.quantity) as total_qty
from orders o
join order_items oi
on o.id = oi.order_id
join products p
on oi.product_id = p.id
join categories c
on c.id = p.category_id
where year(o.order_date) = 2024
group by c.name,p.name
),
ranked as(
SELECT *,
       RANK () OVER (PARTITION BY category_name order by total_revenue DESC) AS rnk
FROM base
)
SELECT category_name, product_name, total_revenue, total_qty
FROM ranked
where rnk <= 3;
--  6. A-5  재구매율 계산           ★★★   비율 계산

with base as(
SELECT user_id,
       min(order_date) as order_date2
FROM orders
group by user_id
),fisrt_half as(
  SELECT user_id
  FROM base
  where DATE_FORMAT(order_date2,'%Y-%m') BETWEEN '2024-01' and '2024-06'
), repurchase as (
  SELECT distinct(o.user_id) as repurchase
  FROM orders o
  join fisrt_half fh on o.user_id = fh.user_id
  where DATE_FORMAT(o.order_date,'%Y-%m') BETWEEN '2024-07' and '2024-12'
)
SELECT count(fh.user_id) as first_half_customers,
       count(r.repurchase) as repurchase_customers,
       count(r.repurchase)/count(fh.user_id) as repurchase_rate
FROM fisrt_half fh
left join repurchase r
on fh.user_id = r.repurchase


--  7. A-7  신규/기존 고객 매출     ★★★   CTE + 조건 분기
WITH first_purchase AS (
    SELECT user_id,
           DATE_FORMAT(MIN(order_date), '%Y-%m') AS first_month
    FROM orders
    GROUP BY user_id
),
monthly_total AS (
    SELECT DATE_FORMAT(order_date, '%Y-%m') AS year_month,
           SUM(total_amount) AS total_revenue
    FROM orders
    WHERE YEAR(order_date) = 2024
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
),
monthly_new AS (
    SELECT DATE_FORMAT(o.order_date, '%Y-%m') AS year_month,
           SUM(o.total_amount) AS new_customer_revenue
    FROM orders o
    JOIN first_purchase f ON o.user_id = f.user_id
    WHERE YEAR(o.order_date) = 2024
      AND DATE_FORMAT(o.order_date, '%Y-%m') = f.first_month
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
)
SELECT t.year_month,
       IFNULL(n.new_customer_revenue, 0) AS new_customer_revenue,
       t.total_revenue - IFNULL(n.new_customer_revenue, 0) AS existing_customer_revenue
FROM monthly_total t
LEFT JOIN monthly_new n ON t.year_month = n.year_month
ORDER BY t.year_month;
--  8. A-8  동시 구매 분석          ★★★   Self JOIN
SELECT p.name AS product_name,
       COUNT(*) AS co_purchase_count                                          
  FROM order_items oi1 
  JOIN order_items oi2 ON oi1.order_id = oi2.order_id
  JOIN products p ON oi2.product_id = p.id                              
  WHERE oi1.product_id = 1
    AND oi2.product_id != 1
  GROUP BY oi2.product_id, p.name
  ORDER BY co_purchase_count DESC
  LIMIT 10;
--  9. E-3  전화번호 포맷           ★      쉬어가기
  SELECT name,
         CONCAT(
             SUBSTRING(phone, 1, 3), '-',
             SUBSTRING(phone, 4, 4), '-',
             SUBSTRING(phone, 8, 4)
         ) AS formatted_phone
  FROM users;
-- [2단계] 윈도우 함수 마스터 (10문제)
-- -------------------------------------------------
-- 10. B-1  부서별 연봉 TOP 3       ★★    DENSE_RANK + PARTITION
with base as(
SELECT name,
       dept_id,
       salary,
       RANK() OVER (partition by dept_id order by salary desc) as rnk
from employees
)
SELECT d.name,
       b.name,
       salary,
       rnk
FROM base b
join departments d on b.dept_id = d.id 
where rnk <= 3
-- 11. B-2  카테고리별 판매량 순위  ★★    RANK vs DENSE_RANK
WITH prod_sales AS (
    SELECT
        p.category_id,
        p.name AS product_name,
        SUM(oi.quantity) AS total_qty
    FROM order_items oi
    JOIN products p ON oi.product_id = p.id
    GROUP BY p.category_id, p.name
),
ranked AS (
    SELECT
        category_id,
        product_name,
        total_qty,
        RANK() OVER (PARTITION BY category_id ORDER BY total_qty DESC) AS sales_rank
    FROM prod_sales
)
SELECT
    category_id,
    product_name,
    total_qty,
    sales_rank
FROM ranked
WHERE sales_rank <= 3;
--“순위를 매길 값이 집계 결과냐?”
--집계 결과라면 → GROUP BY 먼저
--집계가 필요 없다면 → 바로 RANK

-- 12. B-4  성적 상위 10%           ★★    PERCENT_RANK
WITH base AS (
    SELECT
        student_id,
        SUM(score) AS total_score
    FROM scores
    GROUP BY student_id
),
ranked AS (
    SELECT
        student_id,
        total_score,
        PERCENT_RANK() OVER (ORDER BY total_score DESC) AS percentile
    FROM base
)
SELECT
    student_id,
    total_score,
    percentile
FROM ranked
WHERE percentile <= 0.10;
-- 13. B-6  분기별 실적 순위        ★★    복합 ORDER BY
WITH quarterly AS (
    SELECT
        s.salesperson_id,
        CONCAT(YEAR(s.sale_date), '-Q', QUARTER(s.sale_date)) AS year_quarter,
        SUM(s.amount) AS total_sales
    FROM sales s
    GROUP BY s.salesperson_id, year_quarter
),
ranked AS (
    SELECT
        q.year_quarter,
        sp.name,
        q.total_sales,
        ROW_NUMBER() OVER (
            PARTITION BY q.year_quarter
            ORDER BY q.total_sales DESC, sp.hire_date ASC
        ) AS quarter_rank
    FROM quarterly q
    JOIN salesperson sp ON sp.id = q.salesperson_id
)
SELECT
    year_quarter,
    name,
    total_sales,
    quarter_rank
FROM ranked
ORDER BY year_quarter, quarter_rank;

-- 14. B-3  월별 매출 순위 변화     ★★★   LAG로 순위 비교 --체크 필요.
WITH monthly_sales AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m') AS year_month,
        oi.product_id,
        SUM(oi.quantity * oi.unit_price) AS monthly_revenue
    FROM order_items oi
    JOIN orders o ON o.id = oi.order_id
    GROUP BY year_month, oi.product_id
),
ranked AS (
    SELECT
        year_month,
        product_id,
        monthly_revenue,
        RANK() OVER (
            PARTITION BY year_month
            ORDER BY monthly_revenue DESC
        ) AS current_rank
    FROM monthly_sales
),
with_prev AS (
    SELECT
        year_month,
        product_id,
        monthly_revenue,
        current_rank,
        LAG(current_rank) OVER (
            PARTITION BY product_id
            ORDER BY year_month
        ) AS prev_rank
    FROM ranked
)
SELECT
    year_month,
    product_id,
    monthly_revenue,
    current_rank,
    prev_rank,
    CASE
        WHEN prev_rank IS NULL THEN 'NEW'
        WHEN current_rank < prev_rank THEN '상승'
        WHEN current_rank > prev_rank THEN '하락'
        ELSE '유지'
    END AS rank_change
FROM with_prev
ORDER BY year_month, current_rank, product_id;


-- 15. C-4  전일 대비 증감률        ★★    LAG 기본
PARTITION BY visit_date는 쓰면 안 됩니다.
→ 날짜가 파티션 기준이 되면 각 날짜가 한 파티션이 되어, 전일 비교가 불가능합니다.
→ 따라서 ORDER BY visit_date만 사용해야 합니다
- 현월-전월/전월 * 100
WITH base AS (
    SELECT
        visit_date,
        visitor_count,
        LAG(visitor_count) OVER (ORDER BY visit_date) AS prev_day_count
    FROM daily_visitors
)
SELECT
    visit_date,
    visitor_count,
    prev_day_count,
    CASE
        WHEN prev_day_count IS NULL THEN NULL
        ELSE ROUND(
            (visitor_count - prev_day_count) / NULLIF(prev_day_count, 0) * 100,
            2
        )
    END AS change_rate
FROM base
ORDER BY visit_date;

-- 16. C-2  누적 매출               ★★    SUM() OVER
WITH monthly AS (
    SELECT
        DATE_FORMAT(order_date, '%Y-%m') AS year_month,
        SUM(total_amount) AS monthly_revenue
    FROM orders
    WHERE YEAR(order_date) = 2024
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
),
cumulative AS (
    SELECT
        year_month,
        monthly_revenue,
        SUM(monthly_revenue) OVER (ORDER BY year_month) AS cumulative_revenue
    FROM monthly
)
SELECT
    year_month,
    monthly_revenue,
    cumulative_revenue,
    ROUND(cumulative_revenue / 1200000000 * 100, 2) AS achievement_rate
FROM cumulative
ORDER BY year_month;

-- 17. C-3  7일 이동평균            ★★    ROWS BETWEEN 
-- 확인필요.
WITH daily AS (
    SELECT
        sale_date,
        SUM(revenue) AS daily_revenue
    FROM daily_sales
    GROUP BY sale_date
)
SELECT
    sale_date,
    daily_revenue,
    ROUND(
        AVG(daily_revenue) OVER (
            ORDER BY sale_date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS moving_avg_7days
FROM daily
ORDER BY sale_date;

-- 18. C-7  구간별 매출 비중        ★★    파레토 분석
-- 고객별 매출을 계산하고, 상위 20% 고객이 전체 매출의 몇 %를 차지하는지 분석
WITH customer_revenue AS (
    SELECT
        user_id,
        SUM(total_amount) AS total_revenue
    FROM orders
    WHERE YEAR(order_date) = 2024
    GROUP BY user_id
),
ranked AS (
    SELECT
        user_id,
        total_revenue,
        SUM(total_revenue) OVER (ORDER BY total_revenue DESC) AS cumulative_revenue,
        SUM(total_revenue) OVER () AS grand_total,
        ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS rn,
        COUNT(*) OVER () AS total_customers
    FROM customer_revenue
)
SELECT
    CASE
        WHEN rn <= total_customers * 0.2 THEN 'Top 20%'
        WHEN rn <= total_customers * 0.5 THEN 'Middle 30%'
        ELSE 'Bottom 50%'
    END AS customer_segment,
    COUNT(*) AS customer_count,
    SUM(total_revenue) AS segment_revenue,
    ROUND(SUM(total_revenue) / MAX(grand_total) * 100, 2) AS revenue_percentage
FROM ranked
GROUP BY
    CASE
        WHEN rn <= total_customers * 0.2 THEN 'Top 20%'
        WHEN rn <= total_customers * 0.5 THEN 'Middle 30%'
        ELSE 'Bottom 50%'
    END
ORDER BY revenue_percentage DESC;

-- 19. B-7  그룹별 중앙값           ★★★   ROW_NUMBER 응용
-- 부서별 연봉 중앙값 계산
WITH ranked AS (
    SELECT
        dept_id,
        salary,
        ROW_NUMBER() OVER (PARTITION BY dept_id ORDER BY salary) AS rn,
        COUNT(*) OVER (PARTITION BY dept_id) AS cnt
    FROM employees
)
SELECT
    d.name AS department_name,
    AVG(r.salary) AS median_salary
FROM ranked r
JOIN departments d ON r.dept_id = d.id
WHERE rn IN (FLOOR((cnt + 1) / 2), CEIL((cnt + 1) / 2))
GROUP BY d.name;

-- [3단계] 비즈니스 로직 (10문제)
-- -------------------------------------------------
-- 20. E-1  연령대별 분석           ★★    날짜 함수 + CASE
-- 연령대별 고객 수와 평균 구매액 분석
SELECT
    CASE
        WHEN TIMESTAMPDIFF(YEAR, birth_date, CURDATE()) < 20 THEN '10대'
        WHEN TIMESTAMPDIFF(YEAR, birth_date, CURDATE()) < 30 THEN '20대'
        WHEN TIMESTAMPDIFF(YEAR, birth_date, CURDATE()) < 40 THEN '30대'
        WHEN TIMESTAMPDIFF(YEAR, birth_date, CURDATE()) < 50 THEN '40대'
        ELSE '50대 이상'
    END AS age_group,
    COUNT(DISTINCT u.id) AS customer_count,
    ROUND(AVG(o.total_amount), 0) AS avg_order_amount,
    SUM(o.total_amount) AS total_revenue
FROM users u
LEFT JOIN orders o ON u.id = o.user_id AND YEAR(o.order_date) = 2024
GROUP BY
    CASE
        WHEN TIMESTAMPDIFF(YEAR, birth_date, CURDATE()) < 20 THEN '10대'
        WHEN TIMESTAMPDIFF(YEAR, birth_date, CURDATE()) < 30 THEN '20대'
        WHEN TIMESTAMPDIFF(YEAR, birth_date, CURDATE()) < 40 THEN '30대'
        WHEN TIMESTAMPDIFF(YEAR, birth_date, CURDATE()) < 50 THEN '40대'
        ELSE '50대 이상'
    END
ORDER BY age_group;

-- 21. E-2  요일별 매출 패턴        ★★    DAYOFWEEK
-- 요일별 주문 건수와 평균 매출 분석
SELECT
    DAYOFWEEK(order_date) AS day_num,
    CASE DAYOFWEEK(order_date)
        WHEN 1 THEN '일요일'
        WHEN 2 THEN '월요일'
        WHEN 3 THEN '화요일'
        WHEN 4 THEN '수요일'
        WHEN 5 THEN '목요일'
        WHEN 6 THEN '금요일'
        WHEN 7 THEN '토요일'
    END AS day_name,
    COUNT(*) AS order_count,
    SUM(total_amount) AS total_revenue,
    ROUND(AVG(total_amount), 0) AS avg_order_amount
FROM orders
WHERE YEAR(order_date) = 2024
GROUP BY DAYOFWEEK(order_date)
ORDER BY day_num;

-- 22. E-4  시간대별 주문 분포      ★★    HOUR + 구간 분류
-- 시간대별 주문 분포 (피크타임 파악)
SELECT
    CASE
        WHEN HOUR(order_datetime) BETWEEN 6 AND 10 THEN '아침 (06-10)'
        WHEN HOUR(order_datetime) BETWEEN 11 AND 13 THEN '점심 (11-13)'
        WHEN HOUR(order_datetime) BETWEEN 14 AND 17 THEN '오후 (14-17)'
        WHEN HOUR(order_datetime) BETWEEN 18 AND 21 THEN '저녁 (18-21)'
        ELSE '심야 (22-05)'
    END AS time_slot,
    COUNT(*) AS order_count,
    SUM(total_amount) AS total_revenue,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM orders
WHERE YEAR(order_date) = 2024
GROUP BY
    CASE
        WHEN HOUR(order_datetime) BETWEEN 6 AND 10 THEN '아침 (06-10)'
        WHEN HOUR(order_datetime) BETWEEN 11 AND 13 THEN '점심 (11-13)'
        WHEN HOUR(order_datetime) BETWEEN 14 AND 17 THEN '오후 (14-17)'
        WHEN HOUR(order_datetime) BETWEEN 18 AND 21 THEN '저녁 (18-21)'
        ELSE '심야 (22-05)'
    END
ORDER BY order_count DESC;

-- 23. C-5  NULL 값 채우기          ★★★   Forward Fill
-- 주가 데이터에서 NULL을 직전 값으로 채우기
WITH numbered AS (
    SELECT
        price_date,
        price,
        SUM(CASE WHEN price IS NOT NULL THEN 1 ELSE 0 END)
            OVER (ORDER BY price_date) AS grp
    FROM stock_prices
)
SELECT
    price_date,
    price AS original_price,
    FIRST_VALUE(price) OVER (PARTITION BY grp ORDER BY price_date) AS filled_price
FROM numbered
ORDER BY price_date;

-- 24. C-6  연속 증가 기간          ★★★   LAG + 연속 패턴
-- 주문 건수가 연속으로 증가한 최대 기간
WITH daily AS (
    SELECT
        order_date,
        COUNT(*) AS order_count
    FROM orders
    GROUP BY order_date
),
with_prev AS (
    SELECT
        order_date,
        order_count,
        LAG(order_count) OVER (ORDER BY order_date) AS prev_count
    FROM daily
),
with_flag AS (
    SELECT
        order_date,
        order_count,
        CASE WHEN order_count > COALESCE(prev_count, 0) THEN 0 ELSE 1 END AS reset_flag
    FROM with_prev
),
with_group AS (
    SELECT
        order_date,
        order_count,
        SUM(reset_flag) OVER (ORDER BY order_date) AS grp
    FROM with_flag
)
SELECT
    grp,
    MIN(order_date) AS start_date,
    MAX(order_date) AS end_date,
    COUNT(*) AS consecutive_days
FROM with_group
GROUP BY grp
ORDER BY consecutive_days DESC
LIMIT 1;

-- 25. D-1  월별 코호트 리텐션      ★★★   코호트 기초
-- 가입 월 기준 코호트별 N개월 후 리텐션율
WITH first_order AS (
    SELECT
        user_id,
        DATE_FORMAT(MIN(order_date), '%Y-%m') AS cohort_month
    FROM orders
    GROUP BY user_id
),
monthly_activity AS (
    SELECT
        o.user_id,
        f.cohort_month,
        TIMESTAMPDIFF(MONTH,
            STR_TO_DATE(CONCAT(f.cohort_month, '-01'), '%Y-%m-%d'),
            STR_TO_DATE(CONCAT(DATE_FORMAT(o.order_date, '%Y-%m'), '-01'), '%Y-%m-%d')
        ) AS month_number
    FROM orders o
    JOIN first_order f ON o.user_id = f.user_id
),
cohort_size AS (
    SELECT cohort_month, COUNT(DISTINCT user_id) AS cohort_users
    FROM first_order
    GROUP BY cohort_month
)
SELECT
    ma.cohort_month,
    cs.cohort_users,
    ma.month_number,
    COUNT(DISTINCT ma.user_id) AS retained_users,
    ROUND(COUNT(DISTINCT ma.user_id) * 100.0 / cs.cohort_users, 2) AS retention_rate
FROM monthly_activity ma
JOIN cohort_size cs ON ma.cohort_month = cs.cohort_month
WHERE ma.month_number <= 6
GROUP BY ma.cohort_month, cs.cohort_users, ma.month_number
ORDER BY ma.cohort_month, ma.month_number;

-- 26. D-4  주간 리텐션 (D1,D3,D7)  ★★★   리텐션율 계산
-- D1, D3, D7 리텐션율 계산
WITH first_login AS (
    SELECT
        user_id,
        MIN(login_date) AS first_date
    FROM login_logs
    GROUP BY user_id
),
retention AS (
    SELECT
        f.user_id,
        f.first_date,
        MAX(CASE WHEN DATEDIFF(l.login_date, f.first_date) = 1 THEN 1 ELSE 0 END) AS d1,
        MAX(CASE WHEN DATEDIFF(l.login_date, f.first_date) = 3 THEN 1 ELSE 0 END) AS d3,
        MAX(CASE WHEN DATEDIFF(l.login_date, f.first_date) = 7 THEN 1 ELSE 0 END) AS d7
    FROM first_login f
    LEFT JOIN login_logs l ON f.user_id = l.user_id
    GROUP BY f.user_id, f.first_date
)
SELECT
    COUNT(*) AS total_users,
    SUM(d1) AS d1_retained,
    ROUND(SUM(d1) * 100.0 / COUNT(*), 2) AS d1_retention_rate,
    SUM(d3) AS d3_retained,
    ROUND(SUM(d3) * 100.0 / COUNT(*), 2) AS d3_retention_rate,
    SUM(d7) AS d7_retained,
    ROUND(SUM(d7) * 100.0 / COUNT(*), 2) AS d7_retention_rate
FROM retention;

-- 27. D-5  이탈 예측 지표          ★★★   평균 접속 주기
-- 고객별 평균 접속 주기 계산 (이탈 예측용)
WITH login_gaps AS (
    SELECT
        user_id,
        login_date,
        LAG(login_date) OVER (PARTITION BY user_id ORDER BY login_date) AS prev_login,
        DATEDIFF(login_date,
            LAG(login_date) OVER (PARTITION BY user_id ORDER BY login_date)
        ) AS days_gap
    FROM login_logs
)
SELECT
    user_id,
    COUNT(*) AS login_count,
    ROUND(AVG(days_gap), 1) AS avg_login_gap,
    MAX(days_gap) AS max_gap,
    DATEDIFF(CURDATE(), MAX(login_date)) AS days_since_last_login,
    CASE
        WHEN DATEDIFF(CURDATE(), MAX(login_date)) > AVG(days_gap) * 2 THEN '이탈 위험'
        WHEN DATEDIFF(CURDATE(), MAX(login_date)) > AVG(days_gap) THEN '주의'
        ELSE '정상'
    END AS churn_risk
FROM login_gaps
GROUP BY user_id
HAVING COUNT(*) > 1
ORDER BY days_since_last_login DESC;

-- 28. B-5  연속 1위 기간           ★★★★  연속 패턴 고급
-- 월별 매출 1위를 연속으로 유지한 최장 기간
WITH monthly_sales AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m') AS year_month,
        oi.product_id,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM orders o
    JOIN order_items oi ON o.id = oi.order_id
    GROUP BY year_month, oi.product_id
),
ranked AS (
    SELECT
        year_month,
        product_id,
        revenue,
        RANK() OVER (PARTITION BY year_month ORDER BY revenue DESC) AS rnk
    FROM monthly_sales
),
top_products AS (
    SELECT
        year_month,
        product_id,
        ROW_NUMBER() OVER (ORDER BY year_month) AS month_num,
        ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY year_month) AS product_seq
    FROM ranked
    WHERE rnk = 1
),
grouped AS (
    SELECT
        product_id,
        month_num - product_seq AS grp
    FROM top_products
)
SELECT
    p.name AS product_name,
    COUNT(*) AS consecutive_months
FROM grouped g
JOIN products p ON g.product_id = p.id
GROUP BY g.product_id, g.grp, p.name
ORDER BY consecutive_months DESC
LIMIT 5;

-- 29. C-1  고객별 구매 비율        ★★★   집계+비율+순위 통합
-- 고객별 전체 매출 대비 비율과 누적 비율 계산
WITH customer_sales AS (
    SELECT
        user_id,
        SUM(total_amount) AS total_revenue
    FROM orders
    WHERE YEAR(order_date) = 2024
    GROUP BY user_id
)
SELECT
    u.name AS customer_name,
    cs.total_revenue,
    ROUND(cs.total_revenue * 100.0 / SUM(cs.total_revenue) OVER (), 2) AS revenue_share,
    ROUND(SUM(cs.total_revenue) OVER (ORDER BY cs.total_revenue DESC) * 100.0
        / SUM(cs.total_revenue) OVER (), 2) AS cumulative_share,
    RANK() OVER (ORDER BY cs.total_revenue DESC) AS revenue_rank
FROM customer_sales cs
JOIN users u ON cs.user_id = u.id
ORDER BY cs.total_revenue DESC
LIMIT 20;

-- [4단계] 그로스해킹 실전 (14문제)
-- -------------------------------------------------
-- 30. G-1  평균 구매 주기          ★★★   LAG + DATEDIFF
-- 고객별 평균 구매 주기 계산
WITH order_gaps AS (
    SELECT
        user_id,
        order_date,
        LAG(order_date) OVER (PARTITION BY user_id ORDER BY order_date) AS prev_order_date,
        DATEDIFF(order_date,
            LAG(order_date) OVER (PARTITION BY user_id ORDER BY order_date)
        ) AS days_between
    FROM orders
)
SELECT
    user_id,
    COUNT(*) AS order_count,
    ROUND(AVG(days_between), 1) AS avg_purchase_cycle,
    MIN(days_between) AS min_cycle,
    MAX(days_between) AS max_cycle
FROM order_gaps
WHERE days_between IS NOT NULL
GROUP BY user_id
HAVING COUNT(*) >= 2
ORDER BY avg_purchase_cycle;

-- 31. G-2  구매 주기 세그먼트      ★★★   세그먼트 분류
-- 평균 구매 주기 기반 고객 세그먼트
WITH order_gaps AS (
    SELECT
        user_id,
        DATEDIFF(order_date,
            LAG(order_date) OVER (PARTITION BY user_id ORDER BY order_date)
        ) AS days_between
    FROM orders
),
avg_cycle AS (
    SELECT
        user_id,
        ROUND(AVG(days_between), 1) AS avg_purchase_cycle
    FROM order_gaps
    WHERE days_between IS NOT NULL
    GROUP BY user_id
)
SELECT
    CASE
        WHEN avg_purchase_cycle <= 7 THEN '매주 구매 (Weekly)'
        WHEN avg_purchase_cycle <= 14 THEN '2주 구매 (Bi-weekly)'
        WHEN avg_purchase_cycle <= 30 THEN '월간 구매 (Monthly)'
        WHEN avg_purchase_cycle <= 90 THEN '분기 구매 (Quarterly)'
        ELSE '비정기 구매 (Occasional)'
    END AS purchase_segment,
    COUNT(*) AS customer_count,
    ROUND(AVG(avg_purchase_cycle), 1) AS segment_avg_cycle
FROM avg_cycle
GROUP BY
    CASE
        WHEN avg_purchase_cycle <= 7 THEN '매주 구매 (Weekly)'
        WHEN avg_purchase_cycle <= 14 THEN '2주 구매 (Bi-weekly)'
        WHEN avg_purchase_cycle <= 30 THEN '월간 구매 (Monthly)'
        WHEN avg_purchase_cycle <= 90 THEN '분기 구매 (Quarterly)'
        ELSE '비정기 구매 (Occasional)'
    END
ORDER BY segment_avg_cycle;

-- 32. G-7  재주문율 분석           ★★★   재구매 전환율
-- 첫 구매 후 30일 이내 재구매 전환율
WITH first_order AS (
    SELECT
        user_id,
        MIN(order_date) AS first_order_date
    FROM orders
    GROUP BY user_id
),
repeat_within_30 AS (
    SELECT DISTINCT f.user_id
    FROM first_order f
    JOIN orders o ON f.user_id = o.user_id
    WHERE o.order_date > f.first_order_date
      AND DATEDIFF(o.order_date, f.first_order_date) <= 30
)
SELECT
    COUNT(DISTINCT f.user_id) AS total_customers,
    COUNT(DISTINCT r.user_id) AS repeat_customers,
    ROUND(COUNT(DISTINCT r.user_id) * 100.0 / COUNT(DISTINCT f.user_id), 2) AS repeat_rate_30days
FROM first_order f
LEFT JOIN repeat_within_30 r ON f.user_id = r.user_id;

-- 33. G-8  시간대별 주문 패턴      ★★    피크타임 분석
-- 시간대별 주문 패턴 및 피크타임 식별
SELECT
    HOUR(order_datetime) AS order_hour,
    COUNT(*) AS order_count,
    SUM(total_amount) AS total_revenue,
    ROUND(AVG(total_amount), 0) AS avg_order_value,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS order_share
FROM orders
WHERE YEAR(order_date) = 2024
GROUP BY HOUR(order_datetime)
ORDER BY order_hour;

-- 34. G-9  매장별 성과 비교        ★★★   순위 + 성장률
-- 매장별 월간 매출 및 전월 대비 성장률
WITH monthly_store AS (
    SELECT
        store_id,
        DATE_FORMAT(order_date, '%Y-%m') AS year_month,
        SUM(total_amount) AS monthly_revenue
    FROM orders
    WHERE YEAR(order_date) = 2024
    GROUP BY store_id, DATE_FORMAT(order_date, '%Y-%m')
),
with_growth AS (
    SELECT
        store_id,
        year_month,
        monthly_revenue,
        LAG(monthly_revenue) OVER (PARTITION BY store_id ORDER BY year_month) AS prev_month_revenue,
        ROUND(
            (monthly_revenue - LAG(monthly_revenue) OVER (PARTITION BY store_id ORDER BY year_month))
            / NULLIF(LAG(monthly_revenue) OVER (PARTITION BY store_id ORDER BY year_month), 0) * 100
        , 2) AS growth_rate
    FROM monthly_store
)
SELECT
    s.name AS store_name,
    w.year_month,
    w.monthly_revenue,
    w.prev_month_revenue,
    w.growth_rate,
    RANK() OVER (PARTITION BY w.year_month ORDER BY w.monthly_revenue DESC) AS monthly_rank
FROM with_growth w
JOIN stores s ON w.store_id = s.id
ORDER BY w.year_month, monthly_rank;

-- 35. G-11 메뉴별 판매 분석        ★★    크로스탭 분석
-- 카테고리별 월간 판매 크로스탭
SELECT
    c.name AS category_name,
    SUM(CASE WHEN DATE_FORMAT(o.order_date, '%Y-%m') = '2024-01' THEN oi.quantity ELSE 0 END) AS `2024-01`,
    SUM(CASE WHEN DATE_FORMAT(o.order_date, '%Y-%m') = '2024-02' THEN oi.quantity ELSE 0 END) AS `2024-02`,
    SUM(CASE WHEN DATE_FORMAT(o.order_date, '%Y-%m') = '2024-03' THEN oi.quantity ELSE 0 END) AS `2024-03`,
    SUM(CASE WHEN DATE_FORMAT(o.order_date, '%Y-%m') = '2024-04' THEN oi.quantity ELSE 0 END) AS `2024-04`,
    SUM(CASE WHEN DATE_FORMAT(o.order_date, '%Y-%m') = '2024-05' THEN oi.quantity ELSE 0 END) AS `2024-05`,
    SUM(CASE WHEN DATE_FORMAT(o.order_date, '%Y-%m') = '2024-06' THEN oi.quantity ELSE 0 END) AS `2024-06`,
    SUM(oi.quantity) AS total_qty
FROM order_items oi
JOIN orders o ON oi.order_id = o.id
JOIN products p ON oi.product_id = p.id
JOIN categories c ON p.category_id = c.id
WHERE YEAR(o.order_date) = 2024
GROUP BY c.name
ORDER BY total_qty DESC;

-- 36. G-3  CAC 계산                ★★★   마케팅비용/신규
-- 채널별 고객획득비용(CAC) 계산
WITH new_customers AS (
    SELECT
        u.utm_source AS channel,
        DATE_FORMAT(u.created_at, '%Y-%m') AS ym,
        COUNT(*) AS new_users
    FROM users u
    WHERE DATE_FORMAT(u.created_at, '%Y-%m') >= '2024-01'
    GROUP BY u.utm_source, DATE_FORMAT(u.created_at, '%Y-%m')
)
SELECT
    nc.channel,
    nc.ym,
    nc.new_users,
    mc.cost AS marketing_cost,
    ROUND(mc.cost / NULLIF(nc.new_users, 0), 0) AS cac
FROM new_customers nc
LEFT JOIN marketing_costs mc ON nc.channel = mc.channel AND nc.ym = mc.ym
WHERE nc.channel IS NOT NULL
ORDER BY nc.ym, nc.channel;

-- 37. G-4  ROAS 채널별 분석        ★★★   UTM + 매출 귀속
-- 채널별 ROAS(광고수익률) 계산
WITH channel_revenue AS (
    SELECT
        u.utm_source AS channel,
        DATE_FORMAT(o.order_date, '%Y-%m') AS ym,
        SUM(o.total_amount) AS revenue
    FROM orders o
    JOIN users u ON o.user_id = u.id
    WHERE YEAR(o.order_date) = 2024 AND u.utm_source IS NOT NULL
    GROUP BY u.utm_source, DATE_FORMAT(o.order_date, '%Y-%m')
)
SELECT
    cr.channel,
    cr.ym,
    cr.revenue,
    mc.cost AS ad_cost,
    ROUND(cr.revenue / NULLIF(mc.cost, 0), 2) AS roas
FROM channel_revenue cr
LEFT JOIN marketing_costs mc ON cr.channel = mc.channel AND cr.ym = mc.ym
ORDER BY cr.ym, roas DESC;

-- 38. G-6  CRM 캠페인 성과         ★★★   오픈/클릭/전환율
-- 캠페인별 오픈율, 클릭율, 전환율 계산
WITH campaign_metrics AS (
    SELECT
        c.id AS campaign_id,
        c.name AS campaign_name,
        COUNT(DISTINCT cs.id) AS total_sent,
        COUNT(DISTINCT co.id) AS total_opened,
        COUNT(DISTINCT cc.id) AS total_clicked
    FROM campaigns c
    LEFT JOIN campaign_sends cs ON c.id = cs.campaign_id
    LEFT JOIN campaign_opens co ON cs.id = co.send_id
    LEFT JOIN campaign_clicks cc ON cs.id = cc.send_id
    GROUP BY c.id, c.name
)
SELECT
    campaign_name,
    total_sent,
    total_opened,
    ROUND(total_opened * 100.0 / NULLIF(total_sent, 0), 2) AS open_rate,
    total_clicked,
    ROUND(total_clicked * 100.0 / NULLIF(total_sent, 0), 2) AS click_rate,
    ROUND(total_clicked * 100.0 / NULLIF(total_opened, 0), 2) AS click_to_open_rate
FROM campaign_metrics
ORDER BY open_rate DESC;

-- 39. D-6  LTV 코호트별 계산       ★★★★  6개월 LTV
-- 코호트별 6개월 누적 LTV 계산
WITH first_order AS (
    SELECT
        user_id,
        DATE_FORMAT(MIN(order_date), '%Y-%m') AS cohort_month
    FROM orders
    GROUP BY user_id
),
ltv_data AS (
    SELECT
        f.cohort_month,
        TIMESTAMPDIFF(MONTH,
            STR_TO_DATE(CONCAT(f.cohort_month, '-01'), '%Y-%m-%d'),
            STR_TO_DATE(CONCAT(DATE_FORMAT(o.order_date, '%Y-%m'), '-01'), '%Y-%m-%d')
        ) AS month_number,
        SUM(o.total_amount) AS revenue
    FROM orders o
    JOIN first_order f ON o.user_id = f.user_id
    GROUP BY f.cohort_month, month_number
),
cohort_size AS (
    SELECT cohort_month, COUNT(*) AS users
    FROM first_order
    GROUP BY cohort_month
)
SELECT
    l.cohort_month,
    cs.users AS cohort_users,
    l.month_number,
    l.revenue,
    SUM(l.revenue) OVER (PARTITION BY l.cohort_month ORDER BY l.month_number) AS cumulative_revenue,
    ROUND(SUM(l.revenue) OVER (PARTITION BY l.cohort_month ORDER BY l.month_number) / cs.users, 0) AS ltv_per_user
FROM ltv_data l
JOIN cohort_size cs ON l.cohort_month = cs.cohort_month
WHERE l.month_number <= 6
ORDER BY l.cohort_month, l.month_number;

-- 40. F-2  RFM 분석                ★★★★  R/F/M 점수화
-- RFM 점수 기반 고객 세분화
WITH rfm_base AS (
    SELECT
        user_id,
        DATEDIFF(CURDATE(), MAX(order_date)) AS recency,
        COUNT(*) AS frequency,
        SUM(total_amount) AS monetary
    FROM orders
    GROUP BY user_id
),
rfm_scores AS (
    SELECT
        user_id,
        recency,
        frequency,
        monetary,
        NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency) AS f_score,
        NTILE(5) OVER (ORDER BY monetary) AS m_score
    FROM rfm_base
)
SELECT
    user_id,
    recency,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    CONCAT(r_score, f_score, m_score) AS rfm_segment,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 4 AND f_score >= 3 THEN 'Loyal Customers'
        WHEN r_score >= 4 AND f_score <= 2 THEN 'New Customers'
        WHEN r_score >= 3 AND f_score >= 3 THEN 'Potential Loyalists'
        WHEN r_score <= 2 AND f_score >= 4 THEN 'At Risk'
        WHEN r_score <= 2 AND f_score <= 2 THEN 'Lost'
        ELSE 'Others'
    END AS customer_segment
FROM rfm_scores
ORDER BY r_score DESC, f_score DESC, m_score DESC;

-- 41. F-3  장바구니 이탈 분석      ★★★   이탈률
-- 장바구니에 담았지만 구매하지 않은 비율
WITH cart_users AS (
    SELECT DISTINCT user_id, product_id, DATE(added_at) AS cart_date
    FROM cart_items
),
purchased AS (
    SELECT DISTINCT o.user_id, oi.product_id, DATE(o.order_date) AS order_date
    FROM orders o
    JOIN order_items oi ON o.id = oi.order_id
),
cart_analysis AS (
    SELECT
        c.user_id,
        c.product_id,
        c.cart_date,
        CASE WHEN p.user_id IS NOT NULL THEN 1 ELSE 0 END AS converted
    FROM cart_users c
    LEFT JOIN purchased p
        ON c.user_id = p.user_id
        AND c.product_id = p.product_id
        AND p.order_date >= c.cart_date
        AND p.order_date <= DATE_ADD(c.cart_date, INTERVAL 7 DAY)
)
SELECT
    COUNT(*) AS total_cart_items,
    SUM(converted) AS converted_items,
    COUNT(*) - SUM(converted) AS abandoned_items,
    ROUND((COUNT(*) - SUM(converted)) * 100.0 / COUNT(*), 2) AS abandonment_rate,
    ROUND(SUM(converted) * 100.0 / COUNT(*), 2) AS conversion_rate
FROM cart_analysis;

-- 42. F-1  베스트셀러 분석         ★★★   전월 대비 증감
-- 베스트셀러 상품의 전월 대비 판매량 변화
WITH monthly_product_sales AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m') AS year_month,
        oi.product_id,
        SUM(oi.quantity) AS total_qty,
        SUM(oi.quantity * oi.unit_price) AS total_revenue
    FROM orders o
    JOIN order_items oi ON o.id = oi.order_id
    WHERE YEAR(o.order_date) = 2024
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m'), oi.product_id
),
with_prev AS (
    SELECT
        year_month,
        product_id,
        total_qty,
        total_revenue,
        LAG(total_qty) OVER (PARTITION BY product_id ORDER BY year_month) AS prev_qty,
        LAG(total_revenue) OVER (PARTITION BY product_id ORDER BY year_month) AS prev_revenue
    FROM monthly_product_sales
)
SELECT
    w.year_month,
    p.name AS product_name,
    w.total_qty,
    w.prev_qty,
    w.total_qty - COALESCE(w.prev_qty, 0) AS qty_change,
    ROUND((w.total_qty - COALESCE(w.prev_qty, w.total_qty)) * 100.0 / NULLIF(w.prev_qty, 0), 2) AS qty_growth_rate,
    RANK() OVER (PARTITION BY w.year_month ORDER BY w.total_revenue DESC) AS monthly_rank
FROM with_prev w
JOIN products p ON w.product_id = p.id
ORDER BY w.year_month, monthly_rank
LIMIT 30;

-- 43. G-5  LTV vs CAC 비율         ★★★★  건강한 비즈니스
-- 채널별 LTV:CAC 비율 계산 (건강한 비즈니스 지표)
WITH customer_ltv AS (
    SELECT
        u.utm_source AS channel,
        u.id AS user_id,
        SUM(o.total_amount) AS lifetime_value
    FROM users u
    LEFT JOIN orders o ON u.id = o.user_id
    WHERE u.utm_source IS NOT NULL
    GROUP BY u.utm_source, u.id
),
channel_ltv AS (
    SELECT
        channel,
        COUNT(*) AS customer_count,
        ROUND(AVG(lifetime_value), 0) AS avg_ltv
    FROM customer_ltv
    GROUP BY channel
),
channel_cac AS (
    SELECT
        channel,
        SUM(cost) AS total_cost
    FROM marketing_costs
    GROUP BY channel
),
new_customers AS (
    SELECT
        utm_source AS channel,
        COUNT(*) AS new_users
    FROM users
    WHERE utm_source IS NOT NULL
    GROUP BY utm_source
)
SELECT
    cl.channel,
    cl.customer_count,
    cl.avg_ltv,
    ROUND(cc.total_cost / NULLIF(nc.new_users, 0), 0) AS cac,
    ROUND(cl.avg_ltv / NULLIF(cc.total_cost / NULLIF(nc.new_users, 0), 0), 2) AS ltv_cac_ratio,
    CASE
        WHEN cl.avg_ltv / NULLIF(cc.total_cost / NULLIF(nc.new_users, 0), 0) >= 3 THEN '우수 (Excellent)'
        WHEN cl.avg_ltv / NULLIF(cc.total_cost / NULLIF(nc.new_users, 0), 0) >= 1 THEN '양호 (Good)'
        ELSE '개선필요 (Needs Improvement)'
    END AS health_status
FROM channel_ltv cl
JOIN channel_cac cc ON cl.channel = cc.channel
JOIN new_customers nc ON cl.channel = nc.channel
ORDER BY ltv_cac_ratio DESC;

-- [5단계] 최고난이도 도전 (9문제)
-- -------------------------------------------------
-- 44. F-4  퍼널 분석               ★★★★  전환율 단계별
-- 45. F-5  A/B 테스트 분석         ★★★   그룹별 비교
-- 46. D-2  리텐션 피벗 테이블      ★★★★  CASE WHEN 피벗
-- 47. D-3  User Type 분류          ★★★★  New/Current/Resurrected
-- 48. G-10 이탈 위험 고객 탐지     ★★★★  복합 조건
-- 49. G-12 ROI 기반 세그먼트       ★★★★  마케팅 우선순위
-- 50. X-1  연속 로그인 보상        ★★★★  연속 패턴 + 구간
-- 51. X-2  세션 분석               ★★★★  30분 기준 세션
-- 52. X-3  계층 구조 탐색          ★★★★  재귀 CTE
--
-- =================================================
-- 현재 진행: [ 1 ] / 52
-- =================================================


-- =====================================================
-- #1. A-4 미구매 회원 조회 ★★
-- =====================================================
-- 2024년 1월에 가입했지만 아직 한 번도 구매하지 않은 회원의
-- 회원ID, 이름, 가입일을 가입일 순으로 출력하세요.
-- [테이블] users, orders
-- [출력] user_id | name | created_at

SELECT u.id,
       u.name,
       u.created_at
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
WHERE DATE_FORMAT(u.created_at, '%Y-%m') = '2024-01'
  AND o.user_id IS NULL
ORDER BY u.created_at;