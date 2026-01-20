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
-- 11. B-2  카테고리별 판매량 순위  ★★    RANK vs DENSE_RANK
-- 12. B-4  성적 상위 10%           ★★    PERCENT_RANK
-- 13. B-6  분기별 실적 순위        ★★    복합 ORDER BY
-- 14. B-3  월별 매출 순위 변화     ★★★   LAG로 순위 비교
-- 15. C-4  전일 대비 증감률        ★★    LAG 기본
-- 16. C-2  누적 매출               ★★    SUM() OVER
-- 17. C-3  7일 이동평균            ★★    ROWS BETWEEN
-- 18. C-7  구간별 매출 비중        ★★    파레토 분석
-- 19. B-7  그룹별 중앙값           ★★★   ROW_NUMBER 응용
--
-- [3단계] 비즈니스 로직 (10문제)
-- -------------------------------------------------
-- 20. E-1  연령대별 분석           ★★    날짜 함수 + CASE
-- 21. E-2  요일별 매출 패턴        ★★    DAYOFWEEK
-- 22. E-4  시간대별 주문 분포      ★★    HOUR + 구간 분류
-- 23. C-5  NULL 값 채우기          ★★★   Forward Fill
-- 24. C-6  연속 증가 기간          ★★★   LAG + 연속 패턴
-- 25. D-1  월별 코호트 리텐션      ★★★   코호트 기초
-- 26. D-4  주간 리텐션 (D1,D3,D7)  ★★★   리텐션율 계산
-- 27. D-5  이탈 예측 지표          ★★★   평균 접속 주기
-- 28. B-5  연속 1위 기간           ★★★★  연속 패턴 고급
-- 29. C-1  고객별 구매 비율        ★★★   집계+비율+순위 통합
--
-- [4단계] 그로스해킹 실전 (14문제)
-- -------------------------------------------------
-- 30. G-1  평균 구매 주기          ★★★   LAG + DATEDIFF
-- 31. G-2  구매 주기 세그먼트      ★★★   세그먼트 분류
-- 32. G-7  재주문율 분석           ★★★   재구매 전환율
-- 33. G-8  시간대별 주문 패턴      ★★    피크타임 분석
-- 34. G-9  매장별 성과 비교        ★★★   순위 + 성장률
-- 35. G-11 메뉴별 판매 분석        ★★    크로스탭 분석
-- 36. G-3  CAC 계산                ★★★   마케팅비용/신규
-- 37. G-4  ROAS 채널별 분석        ★★★   UTM + 매출 귀속
-- 38. G-6  CRM 캠페인 성과         ★★★   오픈/클릭/전환율
-- 39. D-6  LTV 코호트별 계산       ★★★★  6개월 LTV
-- 40. F-2  RFM 분석                ★★★★  R/F/M 점수화
-- 41. F-3  장바구니 이탈 분석      ★★★   이탈률
-- 42. F-1  베스트셀러 분석         ★★★   전월 대비 증감
-- 43. G-5  LTV vs CAC 비율         ★★★★  건강한 비즈니스
--
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