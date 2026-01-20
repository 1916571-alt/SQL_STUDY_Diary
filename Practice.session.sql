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
SELECT 
--  6. A-5  재구매율 계산           ★★★   비율 계산
--  7. A-7  신규/기존 고객 매출     ★★★   CTE + 조건 분기
--  8. A-8  동시 구매 분석          ★★★   Self JOIN
--  9. E-3  전화번호 포맷           ★      쉬어가기
--
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


-- =====================================================
-- #2. A-6 상품별 리뷰 통계 ★★
-- =====================================================
-- 상품별로 리뷰 개수, 평균 평점, 최고 평점, 최저 평점을 구하되,
-- 리뷰가 5개 이상인 상품만 평균 평점 내림차순으로 출력하세요.
-- [테이블] products, product_reviews
-- [출력] product_name | review_count | avg_rating | max_rating | min_rating



-- =====================================================
-- #3. A-3 고객 등급별 평균 구매 금액 ★★
-- =====================================================
-- 고객 등급(Gold, Silver, Bronze)별로
-- 평균 주문 금액, 평균 주문 건수, 총 고객 수를 구하세요.
-- 단, 2024년에 주문한 고객만 대상입니다.
-- [테이블] users, orders
-- [출력] grade | avg_order_amount | avg_order_count | user_count



-- =====================================================
-- #4. A-1 작가별 판매 통계 ★★★
-- =====================================================
-- 2024년에 가장 많이 팔린 상위 5명의 작가들에 대해,
-- 작가 이름, 총 판매 권수, 평균 평점(소수점 둘째자리),
-- 평점을 받은 책의 개수를 판매량이 많은 순으로 출력하세요.
-- [테이블] authors, books, book_orders, reviews
-- [출력] author_name | total_sales | avg_rating | rated_book_cnt



-- =====================================================
-- #5. A-2 카테고리별 매출 TOP 3 상품 ★★
-- =====================================================
-- 각 카테고리별로 2024년 매출액 상위 3개 상품의
-- 상품명, 카테고리명, 총 매출액, 판매 수량을 출력하세요.
-- [테이블] products, categories, order_items, orders
-- [출력] category_name | product_name | total_revenue | total_qty



-- =====================================================
-- #6. A-5 재구매율 계산 ★★★
-- =====================================================
-- 2024년 상반기(1-6월)에 첫 구매한 고객 중
-- 하반기(7-12월)에 재구매한 고객의 비율을 구하세요.
-- 소수점 둘째자리까지 표시합니다.
-- [테이블] orders
-- [출력] first_half_customers | repurchase_customers | repurchase_rate



-- =====================================================
-- #7. A-7 월별 신규/기존 고객 매출 비교 ★★★
-- =====================================================
-- 2024년 각 월별로 신규 고객(해당 월 첫 구매)과
-- 기존 고객(이전 구매 이력 있음)의 매출액을 각각 구하세요.
-- [테이블] orders
-- [출력] year_month | new_customer_revenue | existing_customer_revenue



-- =====================================================
-- #8. A-8 동시 구매 상품 분석 ★★★
-- =====================================================
-- 상품 A(id=1)와 같은 주문에서 함께 구매된 상품들을
-- 동시 구매 횟수가 많은 순으로 상위 10개 출력하세요.
-- [테이블] order_items, products
-- [출력] product_name | co_purchase_count



-- =====================================================
-- #9. E-3 전화번호 포맷 변환 ★
-- =====================================================
-- 전화번호를 XXX-XXXX-XXXX 형식으로 변환하세요.
-- 원본 데이터는 01012345678 형태입니다.
-- [테이블] users
-- [출력] name | formatted_phone



-- =====================================================
-- #10. B-1 부서별 연봉 TOP 3 ★★
-- =====================================================
-- 각 부서별로 연봉 상위 3명의 직원 정보를 출력하되,
-- 동일 연봉자가 있는 경우 모두 표시해주세요.
-- [테이블] employees, departments
-- [출력] dept_name | emp_name | salary | rank_in_dept



-- =====================================================
-- #11. B-2 카테고리별 판매량 순위 ★★
-- =====================================================
-- 각 카테고리 내에서 상품별 판매량 순위를 매기고,
-- 순위가 1~3위인 상품만 출력하세요.
-- 동일 판매량일 경우 같은 순위, 다음 순위는 건너뜁니다.
-- [테이블] products, order_items
-- [출력] category_id | product_name | total_qty | sales_rank



-- =====================================================
-- #12. B-4 성적 상위 10% 학생 ★★
-- =====================================================
-- 전체 학생 중 총점 기준 상위 10%에 해당하는 학생들의
-- 이름, 총점, 백분위를 출력하세요.
-- [테이블] students, scores
-- [출력] name | total_score | percentile



-- =====================================================
-- #13. B-6 분기별 실적 순위 ★★
-- =====================================================
-- 영업사원별 분기별 실적과 해당 분기 내 순위를 구하세요.
-- 실적이 같으면 입사일이 빠른 사람이 높은 순위입니다.
-- [테이블] salesperson, sales
-- [출력] year_quarter | name | total_sales | quarter_rank



-- =====================================================
-- #14. B-3 월별 매출 순위 변화 ★★★
-- =====================================================
-- 각 상품의 월별 매출 순위를 구하고,
-- 전월 대비 순위 변화(상승/하락/유지)를 표시하세요.
-- [테이블] order_items, orders
-- [출력] year_month | product_id | monthly_revenue | current_rank | prev_rank | rank_change



-- =====================================================
-- #15. C-4 전일 대비 증감률 ★★
-- =====================================================
-- 일별 방문자 수와 전일 대비 증감률(%)을 구하세요.
-- 첫날은 증감률을 NULL로 표시합니다.
-- [테이블] daily_visitors
-- [출력] date | visitor_count | prev_day_count | change_rate



-- =====================================================
-- #16. C-2 누적 매출 및 목표 달성률 ★★
-- =====================================================
-- 2024년 각 월별 매출과 연초부터의 누적 매출,
-- 연간 목표(12억) 대비 누적 달성률을 구하세요.
-- [테이블] orders
-- [출력] year_month | monthly_revenue | cumulative_revenue | achievement_rate



-- =====================================================
-- #17. C-3 이동 평균 (7일) ★★
-- =====================================================
-- 일별 매출의 7일 이동평균을 구하세요.
-- 데이터가 7일 미만인 초기에는 있는 데이터만으로 평균을 계산합니다.
-- [테이블] daily_sales
-- [출력] date | daily_revenue | moving_avg_7days



-- =====================================================
-- #18. C-7 구간별 매출 비중 ★★
-- =====================================================
-- 전체 매출을 100%로 했을 때, 각 상품이 차지하는 비중과
-- 상위부터의 누적 비중을 구하세요. (파레토 분석)
-- [테이블] order_items, products
-- [출력] product_name | revenue | revenue_ratio | cumulative_ratio



-- =====================================================
-- #19. B-7 그룹별 중앙값 구하기 ★★★
-- =====================================================
-- 각 부서별 연봉의 중앙값(MEDIAN)을 구하세요.
-- (MySQL은 MEDIAN 함수가 없으므로 ROW_NUMBER로 구현)
-- [테이블] employees
-- [출력] dept_id | median_salary



-- =====================================================
-- #20. E-1 연령대별 분석 ★★
-- =====================================================
-- 생년월일을 기준으로 연령대(10대, 20대, 30대...)를 구하고,
-- 연령대별 회원 수와 평균 구매금액을 출력하세요.
-- [테이블] users, orders
-- [출력] age_group | user_count | avg_purchase_amount



-- =====================================================
-- #21. E-2 요일별 매출 패턴 ★★
-- =====================================================
-- 요일별(월~일) 평균 매출액과 주문 건수를 구하세요.
-- 요일은 월요일부터 정렬합니다.
-- [테이블] orders
-- [출력] day_of_week | day_name | avg_revenue | order_count



-- =====================================================
-- #22. E-4 시간대별 주문 분포 ★★
-- =====================================================
-- 주문 시간을 4개 시간대로 구분하여 주문 분포를 분석하세요.
-- 새벽(00-06), 오전(06-12), 오후(12-18), 저녁(18-24)
-- [테이블] orders
-- [출력] time_slot | order_count | total_revenue | avg_order_amount



-- =====================================================
-- #23. C-5 NULL 값 채우기 (Forward Fill) ★★★
-- =====================================================
-- NULL 값을 바로 이전 날짜의 값으로 채워주는 쿼리를 작성하세요.
-- (MySQL은 IGNORE NULLS 미지원 → 서브쿼리 활용)
-- [테이블] daily_orders
-- [출력] date | filled_orders



-- =====================================================
-- #24. C-6 연속 증가 기간 ★★★
-- =====================================================
-- 주가 데이터에서 연속으로 상승한 최대 일수를 구하세요.
-- [테이블] stock_prices
-- [출력] max_consecutive_up_days



-- =====================================================
-- #25. D-1 월별 코호트 리텐션 ★★★
-- =====================================================
-- 코호트 월별 유저 수를 계산해주세요.
-- 코호트: 첫 접속을 기준으로 나눔
-- [테이블] app_logs (user_id, event_name, event_date)
-- [출력] cohort_month | diff_month | user_cnts



-- =====================================================
-- #26. D-4 주간 리텐션 (Day 1, 3, 7) ★★★
-- =====================================================
-- 가입일 기준으로 Day 1, Day 3, Day 7 리텐션율을 구하세요.
-- [테이블] users, login_logs
-- [출력] signup_week | total_users | d1_retention | d3_retention | d7_retention



-- =====================================================
-- #27. D-5 이탈 예측 지표 ★★★
-- =====================================================
-- 최근 30일간 활동이 없는 유저 중,
-- 과거 평균 접속 주기가 7일 이하였던 유저를 "이탈 위험"으로 분류
-- [테이블] app_logs
-- [출력] user_id | last_activity_date | avg_visit_interval | days_since_last_visit



-- =====================================================
-- #28. B-5 연속 1위 기간 ★★★★
-- =====================================================
-- 일별 매출 데이터에서 상품별로 연속으로 1위를 유지한
-- 최대 기간(일수)을 구하세요.
-- [테이블] daily_sales
-- [출력] product_id | max_consecutive_first_days



-- =====================================================
-- #29. C-1 고객별 구매 비율 ★★★
-- =====================================================
-- 각 고객별로 총 구매 횟수, 커피 구매 횟수,
-- 전체 구매 금액 대비 커피 구매 비율, 구매액 순위를 표시
-- (원문: 전자제품 → 카페DB이므로 '커피' 카테고리로 대체)
-- [테이블] orders, order_items, products
-- [출력] user_id | total_order_cnt | coffee_order_cnt | total_amount | coffee_ratio | rank



-- =====================================================
-- #30. G-1 고객별 평균 구매 주기 분석 ★★★
-- =====================================================
-- 각 고객의 평균 구매 주기(일)를 계산하세요.
-- 2회 이상 구매한 고객만 대상, 주기가 짧은 순으로 정렬
-- [테이블] users, orders
-- [출력] user_id | name | order_count | avg_purchase_interval_days | last_order_date



-- =====================================================
-- #31. G-2 구매 주기 기반 세그먼트 분류 ★★★
-- =====================================================
-- Heavy(7일이하), Regular(8-14일), Light(15-30일), Occasional(31일+)
-- 각 세그먼트별 고객 수, 평균 주문금액, 총 매출을 구하세요.
-- [테이블] orders
-- [출력] segment | customer_count | avg_order_amount | total_revenue | revenue_share_pct



-- =====================================================
-- #32. G-7 재주문율 및 재주문 주기 분석 ★★★
-- =====================================================
-- 첫 구매 후 재주문한 고객 비율과
-- 첫 구매 → 재주문까지의 평균 일수를 월별로 분석
-- [테이블] orders
-- [출력] first_order_month | first_purchasers | repeat_purchasers | repeat_rate | avg_days_to_repeat



-- =====================================================
-- #33. G-8 시간대별 주문 패턴 (카페 특화) ★★
-- =====================================================
-- 시간대별(1시간 단위) 주문 건수와 평균 주문금액을 분석
-- 피크 타임(상위 3개 시간대)과 오프 피크 구분
-- [테이블] orders
-- [출력] hour | weekday_orders | weekend_orders | avg_amount | is_peak_time



-- =====================================================
-- #34. G-9 매장별 성과 비교 및 순위 ★★★
-- =====================================================
-- 매장별 월간 매출, 주문 건수, 객단가, 재방문 고객 비율,
-- 전월 대비 성장률과 전체 매장 내 순위를 계산
-- [테이블] stores, orders
-- [출력] store_name | region | monthly_revenue | order_count | avg_ticket | revisit_rate | growth_rate | revenue_rank



-- =====================================================
-- #35. G-11 메뉴별 판매 분석 (음료 카테고리) ★★
-- =====================================================
-- 카테고리별, 사이즈별 판매량과 매출 분석
-- 인기 조합 TOP 10, 시간대별 선호 카테고리 변화
-- [테이블] products, order_items, orders
-- [출력] category | size | order_count | revenue | morning_share | afternoon_share | evening_share



-- =====================================================
-- #36. G-3 CAC (Customer Acquisition Cost) 계산 ★★★
-- =====================================================
-- 월별 마케팅 비용과 신규 고객 수를 기반으로 CAC 계산
-- 해당 월 신규 고객의 첫 구매 전환율도 함께 구하세요.
-- [테이블] users, orders, marketing_costs
-- [출력] year_month | marketing_cost | new_users | first_purchasers | cac | first_purchase_rate



-- =====================================================
-- #37. G-4 ROAS (Return on Ad Spend) 채널별 분석 ★★★
-- =====================================================
-- 마케팅 채널별 ROAS = (채널 유입 고객의 매출) / (채널 광고비) × 100
-- [테이블] users, orders, marketing_costs
-- [출력] channel | ad_spend | attributed_users | attributed_revenue | roas_pct



-- =====================================================
-- #38. G-6 CRM 캠페인 성과 분석 ★★★
-- =====================================================
-- 캠페인별 발송 수, 오픈율, 클릭율, 전환율(구매), 캠페인 매출
-- 캠페인 발송 후 24시간 내 구매를 전환으로 봄
-- [테이블] campaigns, campaign_sends, campaign_opens, campaign_clicks, orders
-- [출력] campaign_name | sent_count | open_rate | click_rate | conversion_rate | campaign_revenue



-- =====================================================
-- #39. D-6 LTV(Life Time Value) 코호트별 계산 ★★★★
-- =====================================================
-- 가입 월 기준 코호트별로 가입 후 6개월간의 평균 LTV 계산
-- [테이블] users, orders
-- [출력] cohort_month | cohort_size | avg_ltv_6months



-- =====================================================
-- #40. F-2 RFM 분석 ★★★★
-- =====================================================
-- Recency: 최근 구매일 (30일 이내=3, 90일 이내=2, 그 외=1)
-- Frequency: 구매 횟수 (10회 이상=3, 5회 이상=2, 그 외=1)
-- Monetary: 총 구매금액 (100만원 이상=3, 50만원 이상=2, 그 외=1)
-- [테이블] users, orders
-- [출력] user_id | name | recency_score | frequency_score | monetary_score | rfm_segment



-- =====================================================
-- #41. F-3 장바구니 이탈 분석 ★★★
-- =====================================================
-- 장바구니에 담았지만 24시간 내 구매하지 않은 상품과 이탈률
-- [테이블] cart_items, order_items, orders, products
-- [출력] product_name | cart_add_count | purchase_count | abandon_rate



-- =====================================================
-- #42. F-1 베스트셀러 분석 ★★★
-- =====================================================
-- 월별로 가장 많이 팔린 상품 TOP 3와
-- 해당 상품의 전월 대비 판매량 증감률 (신규는 'NEW')
-- [테이블] products, order_items, orders
-- [출력] year_month | rank | product_name | quantity | prev_quantity | change_rate



-- =====================================================
-- #43. G-5 LTV vs CAC 비율 분석 ★★★★
-- =====================================================
-- 코호트별로 12개월 LTV와 CAC를 계산하고 LTV/CAC 비율
-- (3 이상이면 건강한 비즈니스)
-- [테이블] users, orders, marketing_costs
-- [출력] cohort_month | cohort_size | cac | ltv_12months | ltv_cac_ratio | health_status



-- =====================================================
-- #44. F-4 퍼널 분석 ★★★★
-- =====================================================
-- 회원가입 → 첫 장바구니 담기 → 첫 구매 퍼널의 단계별 전환율
-- [테이블] users, cart_items, orders
-- [출력] signup_date | signups | cart_users | purchasers | signup_to_cart_rate | cart_to_purchase_rate



-- =====================================================
-- #45. F-5 A/B 테스트 결과 분석 ★★★
-- =====================================================
-- A/B 테스트 그룹별 전환율, 평균 구매금액, 구매자 수 비교
-- [테이블] ab_test_users, orders
-- [출력] test_group | total_users | purchasers | conversion_rate | avg_purchase_amount | total_revenue



-- =====================================================
-- #46. D-2 리텐션율 피벗 테이블 ★★★★
-- =====================================================
-- 코호트별 리텐션율을 피벗 형태로 출력 (M+0, M+1, M+2, M+3)
-- [테이블] app_logs
-- [출력] cohort_month | M0_users | M1_retention | M2_retention | M3_retention



-- =====================================================
-- #47. D-3 User Type 분류 ★★★★
-- =====================================================
-- New: 해당 월에 처음 활동
-- Current: 지난달+이번달 활동
-- Resurrected: 2개월+ 미활동 후 복귀
-- Dormant: 지난달 활동, 이번달 미활동
-- [테이블] app_logs
-- [출력] year_month | user_type | user_cnts



-- =====================================================
-- #48. G-10 이탈 위험 고객 조기 탐지 ★★★★
-- =====================================================
-- 조건: 평균 구매 주기의 2배 이상 미구매 + 최근 3개월 매출 50%↓ + 30일간 앱 접속 0회
-- [테이블] users, orders, app_logs
-- [출력] user_id | name | avg_interval | days_since_last_order | recent_revenue_drop | churn_risk_score



-- =====================================================
-- #49. G-12 ROI 기반 세그먼트 우선순위 ★★★★
-- =====================================================
-- RFM 세그먼트별 마케팅 ROI 분석, 우선순위 세그먼트 도출
-- [테이블] users, orders, campaign_sends, campaigns
-- [출력] rfm_segment | user_count | pre_campaign_revenue | post_campaign_revenue | campaign_cost | incremental_revenue | roi_pct | priority_rank



-- =====================================================
-- #50. X-1 연속 로그인 보상 ★★★★
-- =====================================================
-- 7일 연속 로그인한 유저의 연속 로그인 시작일, 종료일, 연속 일수
-- [테이블] login_logs
-- [출력] user_id | streak_start | streak_end | consecutive_days



-- =====================================================
-- #51. X-2 세션 분석 ★★★★
-- =====================================================
-- 30분 이상 간격이면 새 세션으로 정의
-- 세션별 이벤트 수, 세션 시간(분), 첫/마지막 이벤트
-- [테이블] app_logs
-- [출력] user_id | session_id | event_count | session_duration_min | first_event | last_event



-- =====================================================
-- #52. X-3 계층 구조 탐색 (재귀 CTE) ★★★★
-- =====================================================
-- 조직도에서 특정 매니저(id=1) 아래의 모든 직원을 계층 레벨과 함께 출력
-- [테이블] employees
-- [출력] id | name | level | path


