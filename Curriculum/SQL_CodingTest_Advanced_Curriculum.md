# SQL 코딩테스트 심화 커리큘럼 (MySQL 기준)

> **목표**: 프로그래머스 SQL 코딩테스트 완벽 대비
> **기준 DB**: MySQL 8.0
> **핵심 전략**: Input → 중간 Output → 최종 Output 사고법

---

## 최신 출제 트렌드 요약

```
❌ 과거: 단순 WHERE, HAVING, CASE WHEN 단독 문제
✅ 현재: 특정 로직을 주고 지표를 작성하는 복합 문제
```

### 자주 나오는 4대 유형
| 유형 | 핵심 스킬 | 출제 빈도 |
|------|----------|----------|
| 1. JOIN + 집계 | 다중 테이블 조인 + GROUP BY + 집계함수 | ⭐⭐⭐⭐⭐ |
| 2. 윈도우 함수 (순위) | ROW_NUMBER, RANK, DENSE_RANK | ⭐⭐⭐⭐⭐ |
| 3. 윈도우 함수 (집계) | SUM/COUNT OVER, LAG/LEAD | ⭐⭐⭐⭐ |
| 4. 비즈니스 로직 지표 | 코호트 리텐션, User Type, 세션 분석 | ⭐⭐⭐⭐ |

---

## Phase 1: 기초 체력 다지기

### 1-1. JOIN 완벽 정복
```sql
-- 반드시 알아야 할 JOIN 유형
INNER JOIN    -- 교집합
LEFT JOIN     -- 왼쪽 테이블 기준 전체 + 매칭
RIGHT JOIN    -- 오른쪽 테이블 기준 전체 + 매칭
CROSS JOIN    -- 모든 조합 (카테시안 곱)
SELF JOIN     -- 자기 자신과 조인 (계층, 비교)
```

#### 프로그래머스 필수 문제
| 레벨 | 문제명 | 핵심 포인트 |
|-----|-------|------------|
| LV2 | 조건에 맞는 도서와 저자 리스트 출력하기 | 기본 INNER JOIN |
| LV3 | 오랜 기간 보호한 동물(1) | LEFT JOIN + IS NULL |
| LV4 | 보호소에서 중성화한 동물 | INNER JOIN + 조건 비교 |
| LV4 | 그룹별 조건에 맞는 식당 목록 출력하기 | JOIN + 서브쿼리 조합 |
| **LV5** | **상품을 구매한 회원 비율 구하기** | **복합 JOIN + 비율 계산** |

---

### 1-2. GROUP BY + 집계 함수 심화
```sql
-- 필수 집계 함수
COUNT(*), COUNT(DISTINCT col)
SUM(), AVG(), MAX(), MIN()
GROUP_CONCAT()  -- MySQL 특화

-- HAVING vs WHERE 구분
WHERE   -- 그룹화 전 필터링
HAVING  -- 그룹화 후 필터링
```

#### 프로그래머스 필수 문제
| 레벨 | 문제명 | 핵심 포인트 |
|-----|-------|------------|
| LV2 | 성분으로 구분한 아이스크림 총 주문량 | 기본 GROUP BY |
| LV3 | 즐겨찾기가 가장 많은 식당 정보 출력하기 | GROUP BY + 서브쿼리 |
| LV4 | 식품분류별 가장 비싼 식품의 정보 조회하기 | GROUP BY + MAX 서브쿼리 |
| **LV4** | **입양 시각 구하기(2)** | **연속 숫자 생성 + LEFT JOIN** |
| LV4 | 저자 별 카테고리 별 매출액 집계하기 | 다중 GROUP BY |

---

### 1-3. 서브쿼리 패턴
```sql
-- 1. 스칼라 서브쿼리 (SELECT 절)
SELECT name,
       (SELECT AVG(salary) FROM employees) AS avg_salary
FROM employees;

-- 2. 인라인 뷰 (FROM 절)
SELECT * FROM (
    SELECT user_id, COUNT(*) AS order_cnt
    FROM orders
    GROUP BY user_id
) AS sub;

-- 3. 조건 서브쿼리 (WHERE 절)
SELECT * FROM products
WHERE price > (SELECT AVG(price) FROM products);

-- 4. EXISTS / NOT EXISTS
SELECT * FROM users u
WHERE EXISTS (SELECT 1 FROM orders o WHERE o.user_id = u.id);
```

#### 프로그래머스 필수 문제
| 레벨 | 문제명 | 핵심 포인트 |
|-----|-------|------------|
| LV3 | 있었는데요 없었습니다 | 서브쿼리 조건 |
| LV3 | 업그레이드 할 수 없는 아이템 구하기 | NOT IN / NOT EXISTS |
| LV4 | 5월 식품들의 총매출 조회하기 | 인라인 뷰 활용 |

---

## Phase 2: 윈도우 함수 마스터 (핵심!)

### 2-1. 순위 함수
```sql
-- ROW_NUMBER: 무조건 순차 번호 (1,2,3,4,5)
-- RANK: 동점자 동일 순위, 다음 건너뜀 (1,2,2,4,5)
-- DENSE_RANK: 동점자 동일 순위, 다음 연속 (1,2,2,3,4)

SELECT
    dept_id,
    emp_name,
    salary,
    ROW_NUMBER() OVER (PARTITION BY dept_id ORDER BY salary DESC) AS rn,
    RANK() OVER (PARTITION BY dept_id ORDER BY salary DESC) AS rnk,
    DENSE_RANK() OVER (PARTITION BY dept_id ORDER BY salary DESC) AS dense_rnk
FROM employees;
```

#### 핵심 패턴: 그룹별 TOP N 추출
```sql
-- 부서별 연봉 TOP 3 (동점자 모두 포함)
SELECT *
FROM (
    SELECT
        dept_name,
        emp_name,
        salary,
        DENSE_RANK() OVER (PARTITION BY dept_id ORDER BY salary DESC) AS rnk
    FROM employees e
    JOIN departments d ON e.dept_id = d.id
) ranked
WHERE rnk <= 3;
```

#### 프로그래머스 필수 문제
| 레벨 | 문제명 | 핵심 포인트 |
|-----|-------|------------|
| LV3 | 대장균의 크기에 따라 분류하기 2 | NTILE 또는 PERCENT_RANK |
| LV4 | 그룹별 조건에 맞는 식당 목록 출력하기 | ROW_NUMBER + PARTITION |
| LV4 | 년, 월, 성별 별 상품 구매 회원 수 구하기 | DISTINCT + 윈도우 조합 |

---

### 2-2. 집계 윈도우 함수
```sql
-- 누적합
SUM(amount) OVER (ORDER BY date)

-- 이동 평균 (최근 3일)
AVG(amount) OVER (ORDER BY date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)

-- 전체 대비 비율
amount / SUM(amount) OVER () * 100 AS ratio

-- 그룹 내 비율
amount / SUM(amount) OVER (PARTITION BY category) * 100 AS category_ratio
```

#### 핵심 패턴: 고객별 구매 비율 계산
```sql
-- 고객별 총 구매 횟수, 전자제품 구매 횟수, 비율, 순위
SELECT
    user_id,
    COUNT(*) AS total_order_cnt,
    SUM(CASE WHEN category = '전자제품' THEN 1 ELSE 0 END) AS elec_order_cnt,
    SUM(amount) AS total_amount,
    ROUND(
        SUM(CASE WHEN category = '전자제품' THEN amount ELSE 0 END)
        / SUM(amount) * 100
    ) AS elec_ratio,
    RANK() OVER (ORDER BY SUM(amount) DESC) AS amount_rank
FROM orders o
JOIN products p ON o.product_id = p.id
GROUP BY user_id;
```

---

### 2-3. LAG / LEAD 함수
```sql
-- LAG: 이전 행 값
-- LEAD: 다음 행 값

SELECT
    date,
    sales,
    LAG(sales, 1) OVER (ORDER BY date) AS prev_sales,
    sales - LAG(sales, 1) OVER (ORDER BY date) AS diff
FROM daily_sales;
```

#### 핵심 패턴: NULL 값을 이전 값으로 채우기
```sql
-- MySQL 8.0에서 IGNORE NULLS 미지원 → 서브쿼리로 해결
SELECT
    date,
    COALESCE(
        number_of_orders,
        (SELECT number_of_orders
         FROM daily_orders d2
         WHERE d2.date < d1.date AND d2.number_of_orders IS NOT NULL
         ORDER BY d2.date DESC
         LIMIT 1)
    ) AS filled_orders
FROM daily_orders d1;

-- 또는 변수 활용 (MySQL 특화)
SET @prev := NULL;
SELECT
    date,
    @prev := COALESCE(number_of_orders, @prev) AS filled_orders
FROM daily_orders
ORDER BY date;
```

---

## Phase 3: 비즈니스 로직 지표 (고급)

### 3-1. 코호트 리텐션 분석
```sql
-- 목표: 사용자의 첫 접속 월(코호트) 기준 월별 잔존율

-- Step 1: 유저별 첫 접속 월 구하기
WITH first_visit AS (
    SELECT
        user_id,
        DATE_FORMAT(MIN(event_date), '%Y-%m') AS cohort_month
    FROM user_logs
    GROUP BY user_id
),

-- Step 2: 유저별 활동 월 구하기
monthly_activity AS (
    SELECT DISTINCT
        user_id,
        DATE_FORMAT(event_date, '%Y-%m') AS activity_month
    FROM user_logs
),

-- Step 3: 코호트와 활동 월 조인 + diff 계산
cohort_data AS (
    SELECT
        f.cohort_month,
        m.activity_month,
        TIMESTAMPDIFF(MONTH,
            STR_TO_DATE(CONCAT(f.cohort_month, '-01'), '%Y-%m-%d'),
            STR_TO_DATE(CONCAT(m.activity_month, '-01'), '%Y-%m-%d')
        ) AS diff_month,
        COUNT(DISTINCT m.user_id) AS user_cnt
    FROM first_visit f
    JOIN monthly_activity m ON f.user_id = m.user_id
    GROUP BY f.cohort_month, m.activity_month
)

-- Step 4: 최종 출력
SELECT
    cohort_month,
    diff_month,
    user_cnt
FROM cohort_data
ORDER BY cohort_month, diff_month;
```

---

### 3-2. User Type 분류 (New, Current, Resurrected, Dormant)
```sql
-- 정의
-- New: 해당 월에 처음 활동한 사용자
-- Current: 지난달에도 활동했고 이번달에도 활동한 사용자
-- Resurrected: 2개월 이상 활동하지 않다가 이번달에 다시 활동한 사용자
-- Dormant: 지난달에는 활동했지만 이번달에는 활동하지 않은 사용자

WITH monthly_users AS (
    SELECT DISTINCT
        user_id,
        DATE_FORMAT(event_date, '%Y-%m') AS year_month
    FROM user_logs
),

first_activity AS (
    SELECT
        user_id,
        MIN(year_month) AS first_month
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
        WHEN prev_month = DATE_FORMAT(
            DATE_SUB(STR_TO_DATE(CONCAT(year_month, '-01'), '%Y-%m-%d'), INTERVAL 1 MONTH),
            '%Y-%m'
        ) THEN 'Current'
        ELSE 'Resurrected'
    END AS user_type,
    COUNT(*) AS user_cnt
FROM user_status
GROUP BY year_month, user_type
ORDER BY year_month, user_type;
```

---

### 3-3. 세션 분석 (커스텀 세션)
```sql
-- 30분 이상 간격이면 새 세션으로 정의

WITH time_diff AS (
    SELECT
        user_id,
        event_time,
        TIMESTAMPDIFF(MINUTE,
            LAG(event_time) OVER (PARTITION BY user_id ORDER BY event_time),
            event_time
        ) AS min_diff
    FROM user_events
),

session_flag AS (
    SELECT
        *,
        CASE WHEN min_diff IS NULL OR min_diff >= 30 THEN 1 ELSE 0 END AS new_session
    FROM time_diff
)

SELECT
    user_id,
    event_time,
    SUM(new_session) OVER (PARTITION BY user_id ORDER BY event_time) AS session_id
FROM session_flag;
```

---

## Phase 4: MySQL 필수 함수 정리

### 4-1. 날짜 함수 (가장 중요!)
```sql
-- 현재 날짜/시간
NOW(), CURDATE(), CURTIME()

-- 날짜 포맷 변환
DATE_FORMAT(date, '%Y-%m-%d')   -- 2024-01-15
DATE_FORMAT(date, '%Y-%m')      -- 2024-01

-- 날짜 추출
YEAR(date), MONTH(date), DAY(date)
HOUR(time), MINUTE(time), SECOND(time)
DAYOFWEEK(date)  -- 1=일요일, 7=토요일

-- 날짜 연산
DATE_ADD(date, INTERVAL 1 DAY)
DATE_SUB(date, INTERVAL 1 MONTH)
DATEDIFF(date1, date2)           -- 일수 차이
TIMESTAMPDIFF(MONTH, date1, date2)  -- 월수 차이

-- 문자열 → 날짜
STR_TO_DATE('2024-01-15', '%Y-%m-%d')
```

### 4-2. 문자열 함수
```sql
-- 기본
CONCAT(str1, str2)
SUBSTRING(str, start, length)
LEFT(str, n), RIGHT(str, n)
LENGTH(str), CHAR_LENGTH(str)

-- 변환
UPPER(str), LOWER(str)
TRIM(str), LTRIM(str), RTRIM(str)
REPLACE(str, from, to)

-- 패턴 매칭
LIKE '%pattern%'
REGEXP '^[0-9]+'
```

### 4-3. 조건 함수
```sql
-- CASE WHEN (필수!)
CASE
    WHEN condition1 THEN result1
    WHEN condition2 THEN result2
    ELSE default_result
END

-- IF (MySQL 특화)
IF(condition, true_value, false_value)

-- NULL 처리
IFNULL(expr, default)      -- NULL이면 default
COALESCE(a, b, c)          -- 첫 번째 NOT NULL 값
NULLIF(a, b)               -- a=b면 NULL 반환
```

### 4-4. 숫자 함수
```sql
ROUND(num, decimals)    -- 반올림
CEIL(num), FLOOR(num)   -- 올림, 내림
TRUNCATE(num, decimals) -- 버림
ABS(num)                -- 절댓값
MOD(a, b)               -- 나머지 (a % b)
```

---

## Phase 5: 프로그래머스 레벨별 필수 문제 리스트

### LV4 필수 (중상급)
| 문제명 | 카테고리 | 핵심 스킬 |
|-------|---------|----------|
| 입양 시각 구하기(2) | GROUP BY | 연속 숫자 생성 + LEFT JOIN |
| 보호소에서 중성화한 동물 | JOIN | INNER JOIN + 조건 비교 |
| 그룹별 조건에 맞는 식당 목록 출력하기 | JOIN | 윈도우 함수 또는 서브쿼리 |
| 식품분류별 가장 비싼 식품의 정보 조회하기 | GROUP BY | GROUP BY + MAX 서브쿼리 |
| 5월 식품들의 총매출 조회하기 | JOIN | 다중 JOIN + 날짜 필터 |
| 저자 별 카테고리 별 매출액 집계하기 | JOIN | 다중 GROUP BY + 계산 |
| 오프라인/온라인 판매 데이터 통합하기 | SELECT | UNION ALL + 날짜 처리 |
| 년, 월, 성별 별 상품 구매 회원 수 구하기 | GROUP BY | 다중 GROUP BY + DISTINCT |
| 서울에 위치한 식당 목록 출력하기 | JOIN | JOIN + 소수점 처리 |
| 취소되지 않은 진료 예약 조회하기 | JOIN | 다중 JOIN + 조건 필터 |

### LV5 필수 (고급)
| 문제명 | 카테고리 | 핵심 스킬 |
|-------|---------|----------|
| **상품을 구매한 회원 비율 구하기** | JOIN | 복합 JOIN + 비율 계산 + 날짜 |

---

## 실전 연습 문제 (총 35문제)

> 유형별로 충분한 연습을 통해 패턴을 익히세요.
> 난이도: ★ 쉬움 / ★★ 보통 / ★★★ 어려움 / ★★★★ 매우 어려움

---

### 유형 A: JOIN + 집계 복합 (8문제)

#### A-1. 작가별 판매 통계 ★★★
```
2024년에 가장 많이 팔린 상위 5명의 작가들에 대해,
각 작가별로 작가 이름, 총 판매 권수, 작가의 모든 책들의 평균 평점
(소수점 둘째자리), 평점을 받은 책의 개수를
판매량이 많은 순으로 출력해주세요.

[테이블]
- authors (id, name, country)
- books (id, title, author_id, price, category)
- orders (id, book_id, user_id, quantity, order_date)
- reviews (id, book_id, user_id, rating, review_date)

[Expected Output]
author_name | total_sales | avg_rating | rated_book_cnt
```

#### A-2. 카테고리별 매출 TOP 3 상품 ★★
```
각 카테고리별로 2024년 매출액 상위 3개 상품의
상품명, 카테고리명, 총 매출액, 판매 수량을 출력하세요.

[테이블]
- products (id, name, category_id, price)
- categories (id, name)
- order_items (id, order_id, product_id, quantity)
- orders (id, user_id, order_date, status)

[Expected Output]
category_name | product_name | total_revenue | total_qty
```

#### A-3. 고객 등급별 평균 구매 금액 ★★
```
고객 등급(Gold, Silver, Bronze)별로
평균 주문 금액, 평균 주문 건수, 총 고객 수를 구하세요.
단, 2024년에 주문한 고객만 대상입니다.

[테이블]
- users (id, name, grade, created_at)
- orders (id, user_id, total_amount, order_date)

[Expected Output]
grade | avg_order_amount | avg_order_count | user_count
```

#### A-4. 미구매 회원 조회 ★★
```
2024년 1월에 가입했지만 아직 한 번도 구매하지 않은 회원의
회원ID, 이름, 가입일을 가입일 순으로 출력하세요.

[테이블]
- users (id, name, email, created_at)
- orders (id, user_id, order_date)

[Expected Output]
user_id | name | created_at
```

#### A-5. 재구매율 계산 ★★★
```
2024년 상반기(1-6월)에 첫 구매한 고객 중
하반기(7-12월)에 재구매한 고객의 비율을 구하세요.
소수점 둘째자리까지 표시합니다.

[테이블]
- orders (id, user_id, order_date)

[Expected Output]
first_half_customers | repurchase_customers | repurchase_rate
```

#### A-6. 상품별 리뷰 통계 ★★
```
상품별로 리뷰 개수, 평균 평점, 최고 평점, 최저 평점을 구하되,
리뷰가 5개 이상인 상품만 평균 평점 내림차순으로 출력하세요.

[테이블]
- products (id, name, category)
- reviews (id, product_id, user_id, rating, content, created_at)

[Expected Output]
product_name | review_count | avg_rating | max_rating | min_rating
```

#### A-7. 월별 신규/기존 고객 매출 비교 ★★★
```
2024년 각 월별로 신규 고객(해당 월 첫 구매)과
기존 고객(이전 구매 이력 있음)의 매출액을 각각 구하세요.

[테이블]
- orders (id, user_id, total_amount, order_date)

[Expected Output]
year_month | new_customer_revenue | existing_customer_revenue
```

#### A-8. 동시 구매 상품 분석 ★★★
```
상품 A(id=101)와 같은 주문에서 함께 구매된 상품들을
동시 구매 횟수가 많은 순으로 상위 10개 출력하세요.

[테이블]
- order_items (id, order_id, product_id, quantity)
- products (id, name)

[Expected Output]
product_name | co_purchase_count
```

---

### 유형 B: 윈도우 함수 - 순위 (7문제)

#### B-1. 부서별 연봉 TOP 3 ★★
```
각 부서별로 연봉 상위 3명의 직원 정보를 출력하되,
동일 연봉자가 있는 경우 모두 표시해주세요.
(부서명, 직원명, 연봉, 부서 내 순위)

[테이블]
- employees (id, name, dept_id, salary, hire_date)
- departments (id, name, location)

[Expected Output]
dept_name | emp_name | salary | rank_in_dept
```

#### B-2. 카테고리별 판매량 순위 ★★
```
각 카테고리 내에서 상품별 판매량 순위를 매기고,
순위가 1~3위인 상품만 출력하세요.
동일 판매량일 경우 같은 순위를 부여하고 다음 순위는 건너뜁니다.

[테이블]
- products (id, name, category_id)
- order_items (order_id, product_id, quantity)

[Expected Output]
category_id | product_name | total_qty | sales_rank
```

#### B-3. 월별 매출 순위 변화 ★★★
```
각 상품의 월별 매출 순위를 구하고,
전월 대비 순위 변화(상승/하락/유지)를 표시하세요.

[테이블]
- order_items (order_id, product_id, quantity, unit_price)
- orders (id, order_date)

[Expected Output]
year_month | product_id | monthly_revenue | current_rank | prev_rank | rank_change
```

#### B-4. 성적 상위 10% 학생 ★★
```
전체 학생 중 총점 기준 상위 10%에 해당하는 학생들의
이름, 총점, 백분위를 출력하세요.

[테이블]
- students (id, name, class_id)
- scores (student_id, subject, score)

[Expected Output]
name | total_score | percentile
```

#### B-5. 연속 1위 기간 ★★★★
```
일별 매출 데이터에서 상품별로 연속으로 1위를 유지한
최대 기간(일수)을 구하세요.

[테이블]
- daily_sales (date, product_id, revenue)

[Expected Output]
product_id | max_consecutive_first_days
```

#### B-6. 분기별 실적 순위 ★★
```
영업사원별 분기별 실적과 해당 분기 내 순위를 구하세요.
실적이 같으면 입사일이 빠른 사람이 높은 순위입니다.

[테이블]
- salesperson (id, name, hire_date)
- sales (id, salesperson_id, amount, sale_date)

[Expected Output]
year_quarter | name | total_sales | quarter_rank
```

#### B-7. 그룹별 중앙값 구하기 ★★★
```
각 부서별 연봉의 중앙값(MEDIAN)을 구하세요.
(MySQL은 MEDIAN 함수가 없으므로 ROW_NUMBER로 구현)

[테이블]
- employees (id, name, dept_id, salary)

[Expected Output]
dept_id | median_salary
```

---

### 유형 C: 윈도우 함수 - 집계/LAG/LEAD (7문제)

#### C-1. 고객별 구매 비율 ★★★
```
각 고객별로 총 구매 횟수, 전자제품 구매 횟수,
전체 구매 금액 대비 전자제품 구매 비율을 구하고,
추가로 전체 고객 중 구매액 순위를 표시해주세요.

[테이블]
- orders (id, user_id, product_id, amount, order_date)
- products (id, name, category, price)

[Expected Output]
user_id | total_order_cnt | elec_order_cnt | total_amount | elec_ratio | rank
```

#### C-2. 누적 매출 및 목표 달성률 ★★
```
2024년 각 월별 매출과 연초부터의 누적 매출,
연간 목표(12억) 대비 누적 달성률을 구하세요.

[테이블]
- orders (id, total_amount, order_date)

[Expected Output]
year_month | monthly_revenue | cumulative_revenue | achievement_rate
```

#### C-3. 이동 평균 (7일) ★★
```
일별 매출의 7일 이동평균을 구하세요.
데이터가 7일 미만인 초기에는 있는 데이터만으로 평균을 계산합니다.

[테이블]
- daily_sales (date, revenue)

[Expected Output]
date | daily_revenue | moving_avg_7days
```

#### C-4. 전일 대비 증감률 ★★
```
일별 방문자 수와 전일 대비 증감률(%)을 구하세요.
첫날은 증감률을 NULL로 표시합니다.

[테이블]
- daily_visitors (date, visitor_count)

[Expected Output]
date | visitor_count | prev_day_count | change_rate
```

#### C-5. NULL 값 채우기 (Forward Fill) ★★★
```
아래 데이터에서 NULL 값이라고 되어 있는 부분을
바로 이전 날짜의 값으로 채워주는 쿼리를 작성해주세요.
(참고: 5월 11일, 12일 연속 NULL입니다)

[테이블]
- daily_orders (date, number_of_orders)

힌트: 단순히 LAG 함수가 아닌 특정 옵션을 줘야 실행됩니다
(MySQL은 IGNORE NULLS 미지원 → 서브쿼리 활용)

[Expected Output]
date | filled_orders
```

#### C-6. 연속 증가 기간 ★★★
```
주가 데이터에서 연속으로 상승한 최대 일수를 구하세요.

[테이블]
- stock_prices (date, price)

[Expected Output]
max_consecutive_up_days
```

#### C-7. 구간별 매출 비중 ★★
```
전체 매출을 100%로 했을 때, 각 상품이 차지하는 비중과
상위부터의 누적 비중을 구하세요. (파레토 분석)

[테이블]
- order_items (product_id, quantity, unit_price)
- products (id, name)

[Expected Output]
product_name | revenue | revenue_ratio | cumulative_ratio
```

---

### 유형 D: 비즈니스 로직 - 코호트/리텐션 (6문제)

#### D-1. 월별 코호트 리텐션 ★★★
```
사용자들의 월별 코호트를 집계하기 위해
코호트 월별 유저 수를 계산해주세요.

코호트: 첫 접속을 기준으로 나눔
하루에 여러번 접속해도 1번으로 집계함

[테이블]
- user_logs (user_id, event_name, event_date)

[Expected Output]
cohort_month | diff_month | user_cnts
2024-01      | 0          | 1030
2024-01      | 1          | 400
```

#### D-2. 리텐션율 피벗 테이블 ★★★★
```
코호트별 리텐션율을 피벗 형태로 출력하세요.
(M+0, M+1, M+2, M+3 컬럼으로)

[테이블]
- user_logs (user_id, event_date)

[Expected Output]
cohort_month | M0_users | M1_retention | M2_retention | M3_retention
2024-01      | 1000     | 45.2%        | 32.1%        | 28.5%
```

#### D-3. User Type 분류 ★★★★
```
MAU의 유저를 4가지 타입으로 구분해서 집계해주세요.
앱에서 어떤 이벤트라도 발생시켰으면 Active라고 정의함

- New: 해당 월에 처음 활동한 사용자
- Current: 지난달에도 활동했고 이번달에도 활동한 사용자
- Resurrected: 2개월 이상 활동하지 않다가 이번달에 다시 활동한 사용자
- Dormant: 지난달에는 활동했지만 이번달에는 활동하지 않은 사용자

[Expected Output]
year_month | user_type | user_cnts
```

#### D-4. 주간 리텐션 (Day 1, 3, 7) ★★★
```
가입일 기준으로 Day 1, Day 3, Day 7 리텐션율을 구하세요.
(해당 일에 로그인한 유저 비율)

[테이블]
- users (id, created_at)
- login_logs (user_id, login_date)

[Expected Output]
signup_week | total_users | d1_retention | d3_retention | d7_retention
```

#### D-5. 이탈 예측 지표 ★★★
```
최근 30일간 활동이 없는 유저 중,
과거 평균 접속 주기가 7일 이하였던 유저를
"이탈 위험" 유저로 분류하여 출력하세요.

[테이블]
- user_logs (user_id, event_date)

[Expected Output]
user_id | last_activity_date | avg_visit_interval | days_since_last_visit
```

#### D-6. LTV(Life Time Value) 코호트별 계산 ★★★★
```
가입 월 기준 코호트별로 가입 후 6개월간의
평균 LTV(총 구매금액)를 계산하세요.

[테이블]
- users (id, created_at)
- orders (id, user_id, total_amount, order_date)

[Expected Output]
cohort_month | cohort_size | avg_ltv_6months
```

---

### 유형 E: 날짜/문자열 처리 (4문제)

#### E-1. 연령대별 분석 ★★
```
생년월일을 기준으로 연령대(10대, 20대, 30대...)를 구하고,
연령대별 회원 수와 평균 구매금액을 출력하세요.

[테이블]
- users (id, name, birth_date)
- orders (id, user_id, total_amount)

[Expected Output]
age_group | user_count | avg_purchase_amount
```

#### E-2. 요일별 매출 패턴 ★★
```
요일별(월~일) 평균 매출액과 주문 건수를 구하세요.
요일은 월요일부터 정렬합니다.

[테이블]
- orders (id, total_amount, order_date)

[Expected Output]
day_of_week | day_name | avg_revenue | order_count
```

#### E-3. 전화번호 포맷 변환 ★
```
전화번호를 XXX-XXXX-XXXX 형식으로 변환하세요.
원본 데이터는 01012345678 형태입니다.

[테이블]
- users (id, name, phone)

[Expected Output]
name | formatted_phone
```

#### E-4. 시간대별 주문 분포 ★★
```
주문 시간을 4개 시간대로 구분하여 주문 분포를 분석하세요.
- 새벽(00-06), 오전(06-12), 오후(12-18), 저녁(18-24)

[테이블]
- orders (id, total_amount, order_datetime)

[Expected Output]
time_slot | order_count | total_revenue | avg_order_amount
```

---

### 유형 F: 복합 실전 문제 (5문제)

#### F-1. 베스트셀러 분석 ★★★
```
월별로 가장 많이 팔린 상품 TOP 3와
해당 상품의 전월 대비 판매량 증감률을 구하세요.
신규 상품(전월 판매 없음)은 'NEW'로 표시합니다.

[테이블]
- products (id, name, category)
- order_items (order_id, product_id, quantity)
- orders (id, order_date)

[Expected Output]
year_month | rank | product_name | quantity | prev_quantity | change_rate
```

#### F-2. RFM 분석 ★★★★
```
고객을 RFM 점수로 분류하세요.
- Recency: 최근 구매일 (30일 이내=3, 90일 이내=2, 그 외=1)
- Frequency: 구매 횟수 (10회 이상=3, 5회 이상=2, 그 외=1)
- Monetary: 총 구매금액 (100만원 이상=3, 50만원 이상=2, 그 외=1)

[테이블]
- users (id, name)
- orders (id, user_id, total_amount, order_date)

[Expected Output]
user_id | name | recency_score | frequency_score | monetary_score | rfm_segment
```

#### F-3. 장바구니 이탈 분석 ★★★
```
장바구니에 담았지만 24시간 내 구매하지 않은 상품과
해당 상품의 이탈률을 구하세요.

[테이블]
- cart_items (id, user_id, product_id, added_at)
- order_items (order_id, product_id, user_id)
- orders (id, user_id, order_date)

[Expected Output]
product_name | cart_add_count | purchase_count | abandon_rate
```

#### F-4. 퍼널 분석 ★★★★
```
회원가입 → 첫 장바구니 담기 → 첫 구매 퍼널의
단계별 전환율을 일별로 분석하세요.

[테이블]
- users (id, created_at)
- cart_items (id, user_id, added_at)
- orders (id, user_id, order_date)

[Expected Output]
signup_date | signups | cart_users | purchasers | signup_to_cart_rate | cart_to_purchase_rate
```

#### F-5. A/B 테스트 결과 분석 ★★★
```
A/B 테스트 그룹별로 전환율, 평균 구매금액,
구매자 수를 비교하고 통계적 유의미성 판단을 위한
기초 데이터를 추출하세요.

[테이블]
- ab_test_users (user_id, test_group, assigned_at)
- orders (id, user_id, total_amount, order_date)

[Expected Output]
test_group | total_users | purchasers | conversion_rate | avg_purchase_amount | total_revenue
```

---

### 보너스: 난이도 최상 도전 문제 (3문제)

#### X-1. 연속 로그인 보상 ★★★★
```
7일 연속 로그인한 유저에게 보상을 지급하려 합니다.
각 유저의 연속 로그인 시작일, 종료일, 연속 일수를 구하세요.
(한 유저가 여러 번의 7일 연속 로그인 가능)

[테이블]
- login_logs (user_id, login_date)

[Expected Output]
user_id | streak_start | streak_end | consecutive_days
```

#### X-2. 세션 분석 ★★★★
```
유저 이벤트 로그에서 30분 이상 간격이 있으면
새로운 세션으로 정의하고, 세션별 이벤트 수,
세션 시간(분), 첫 이벤트, 마지막 이벤트를 구하세요.

[테이블]
- event_logs (user_id, event_name, event_time)

[Expected Output]
user_id | session_id | event_count | session_duration_min | first_event | last_event
```

#### X-3. 계층 구조 탐색 (재귀 CTE) ★★★★
```
조직도에서 특정 매니저(id=1) 아래의 모든 직원을
계층 레벨과 함께 출력하세요.

[테이블]
- employees (id, name, manager_id)

[Expected Output]
id | name | level | path
1  | CEO  | 0     | CEO
2  | CTO  | 1     | CEO > CTO
3  | Dev1 | 2     | CEO > CTO > Dev1
```

---

### 유형 G: xx기업 맞춤 - 그로스해킹/CRM (12문제)

> **xx기업 채용 요건에 맞춘 실전 문제**
> 핵심 키워드: LTV, CAC, ROAS, ROI, 구매주기, 세그먼트, CRM 성과, 리텐션

---

#### G-1. 고객별 평균 구매 주기 분석 ★★★
```
각 고객의 평균 구매 주기(일)를 계산하세요.
구매 주기 = 연속된 두 주문 사이의 일수 평균
2회 이상 구매한 고객만 대상이며, 주기가 짧은 순으로 정렬하세요.

[테이블]
- users (id, name, created_at)
- orders (id, user_id, order_date, total_amount)

[Expected Output]
user_id | name | order_count | avg_purchase_interval_days | last_order_date
```

#### G-2. 구매 주기 기반 세그먼트 분류 ★★★
```
고객을 구매 주기에 따라 4개 세그먼트로 분류하세요.
- Heavy: 평균 주기 7일 이하
- Regular: 평균 주기 8~14일
- Light: 평균 주기 15~30일
- Occasional: 평균 주기 31일 이상

각 세그먼트별 고객 수, 평균 주문금액, 총 매출을 구하세요.

[테이블]
- orders (id, user_id, order_date, total_amount)

[Expected Output]
segment | customer_count | avg_order_amount | total_revenue | revenue_share_pct
```

#### G-3. CAC (Customer Acquisition Cost) 계산 ★★★
```
월별 마케팅 비용과 신규 고객 수를 기반으로
CAC(신규 고객 1명 획득 비용)를 계산하세요.
또한 해당 월 신규 고객의 첫 구매 전환율도 함께 구하세요.

[테이블]
- users (id, created_at)
- orders (id, user_id, order_date)
- marketing_costs (month, channel, cost)

[Expected Output]
year_month | marketing_cost | new_users | first_purchasers | cac | first_purchase_rate
```

#### G-4. ROAS (Return on Ad Spend) 채널별 분석 ★★★
```
마케팅 채널별 ROAS를 계산하세요.
ROAS = (채널 유입 고객의 매출) / (채널 광고비) × 100

UTM 파라미터로 유입 채널이 기록되어 있습니다.

[테이블]
- users (id, created_at, utm_source)
- orders (id, user_id, total_amount, order_date)
- marketing_costs (month, channel, cost)

[Expected Output]
channel | ad_spend | attributed_users | attributed_revenue | roas_pct
```

#### G-5. LTV vs CAC 비율 분석 ★★★★
```
코호트별로 12개월 LTV와 CAC를 계산하고,
LTV/CAC 비율을 구하세요. (3 이상이면 건강한 비즈니스)

[테이블]
- users (id, created_at, utm_source)
- orders (id, user_id, total_amount, order_date)
- marketing_costs (month, channel, cost)

[Expected Output]
cohort_month | cohort_size | cac | ltv_12months | ltv_cac_ratio | health_status
```

#### G-6. CRM 캠페인 성과 분석 ★★★
```
푸시 알림 캠페인별 성과를 분석하세요.
- 발송 수, 오픈율, 클릭율, 전환율(구매), 캠페인 매출
캠페인 발송 후 24시간 내 구매를 전환으로 봅니다.

[테이블]
- campaigns (id, name, sent_at, target_segment)
- campaign_sends (id, campaign_id, user_id, sent_at)
- campaign_opens (id, send_id, opened_at)
- campaign_clicks (id, send_id, clicked_at)
- orders (id, user_id, order_date, total_amount)

[Expected Output]
campaign_name | sent_count | open_rate | click_rate | conversion_rate | campaign_revenue
```

#### G-7. 재주문율 및 재주문 주기 분석 ★★★
```
첫 구매 후 재주문한 고객 비율과
첫 구매 → 재주문까지의 평균 일수를 월별로 분석하세요.
(재주문율 80% 목표)

[테이블]
- orders (id, user_id, order_date, total_amount)

[Expected Output]
first_order_month | first_purchasers | repeat_purchasers | repeat_rate | avg_days_to_repeat
```

#### G-8. 시간대별 주문 패턴 (카페 특화) ★★
```
시간대별(1시간 단위) 주문 건수와 평균 주문금액을 분석하세요.
피크 타임(상위 3개 시간대)과 오프 피크를 구분하고,
요일별 차이도 함께 분석하세요.

[테이블]
- orders (id, user_id, order_datetime, total_amount, store_id)

[Expected Output]
hour | weekday_orders | weekend_orders | avg_amount | is_peak_time
```

#### G-9. 매장별 성과 비교 및 순위 ★★★
```
매장별 월간 매출, 주문 건수, 객단가, 재방문 고객 비율을 구하고
전월 대비 성장률과 전체 매장 내 순위를 계산하세요.

[테이블]
- stores (id, name, region, opened_at)
- orders (id, user_id, store_id, order_date, total_amount)

[Expected Output]
store_name | region | monthly_revenue | order_count | avg_ticket | revisit_rate | growth_rate | revenue_rank
```

#### G-10. 이탈 위험 고객 조기 탐지 ★★★★
```
다음 조건을 모두 만족하는 "이탈 위험" 고객을 추출하세요:
1. 과거 평균 구매 주기의 2배 이상 구매 없음
2. 최근 3개월 내 구매 금액이 이전 3개월 대비 50% 이상 감소
3. 최근 30일간 앱 접속 0회

[테이블]
- users (id, name, created_at)
- orders (id, user_id, order_date, total_amount)
- app_logs (user_id, event_date, event_name)

[Expected Output]
user_id | name | avg_interval | days_since_last_order | recent_revenue_drop | churn_risk_score
```

#### G-11. 메뉴별 판매 분석 (음료 카테고리) ★★
```
음료 카테고리별, 사이즈별 판매량과 매출을 분석하세요.
인기 조합(카테고리+사이즈) TOP 10과
시간대별 선호 카테고리 변화도 분석하세요.

[테이블]
- products (id, name, category, size, price)
- order_items (order_id, product_id, quantity)
- orders (id, order_datetime)

[Expected Output]
category | size | order_count | revenue | morning_share | afternoon_share | evening_share
```

#### G-12. ROI 기반 세그먼트 우선순위 ★★★★
```
RFM 세그먼트별로 마케팅 ROI를 분석하세요.
각 세그먼트에 투입된 마케팅 비용 대비
해당 세그먼트의 매출 증가분을 계산하여
마케팅 우선순위 세그먼트를 도출하세요.

[테이블]
- users (id, rfm_segment, created_at)
- orders (id, user_id, order_date, total_amount)
- campaign_sends (campaign_id, user_id, sent_at)
- campaigns (id, name, target_segment, budget)

[Expected Output]
rfm_segment | user_count | pre_campaign_revenue | post_campaign_revenue | campaign_cost | incremental_revenue | roi_pct | priority_rank
```

---

## 학습 체크리스트

### 기본기
- [ ] SELECT, FROM, WHERE, ORDER BY 자유자재
- [ ] GROUP BY + HAVING 완벽 이해
- [ ] 모든 JOIN 유형 사용 가능
- [ ] 서브쿼리 3가지 위치 (SELECT, FROM, WHERE) 활용

### 윈도우 함수
- [ ] ROW_NUMBER, RANK, DENSE_RANK 차이점 설명 가능
- [ ] PARTITION BY + ORDER BY 조합 자유자재
- [ ] SUM/COUNT/AVG OVER 활용
- [ ] LAG/LEAD로 이전/다음 행 비교
- [ ] 누적합, 이동평균 계산 가능

### 비즈니스 로직
- [ ] 코호트 리텐션 쿼리 작성 가능
- [ ] User Type (New/Current/Resurrected/Dormant) 분류 가능
- [ ] 세션 분석 쿼리 작성 가능
- [ ] DAU, WAU, MAU 계산 가능

### MySQL 문법
- [ ] DATE_FORMAT, DATEDIFF, TIMESTAMPDIFF 활용
- [ ] CASE WHEN 복잡한 조건 처리
- [ ] COALESCE, IFNULL로 NULL 처리
- [ ] WITH (CTE) 사용하여 가독성 높은 쿼리 작성

### xx기업 핵심 역량 (그로스해킹)
- [ ] **구매 주기 분석**: 고객별 평균 구매 간격 계산
- [ ] **세그먼트 분류**: 구매 주기/RFM 기반 고객 분류
- [ ] **LTV 계산**: 코호트별 Life Time Value
- [ ] **CAC 계산**: 마케팅 비용 / 신규 고객 수
- [ ] **ROAS 계산**: 채널별 광고 수익률
- [ ] **ROI 분석**: 캠페인별 투자 대비 수익률
- [ ] **재주문율**: 첫 구매 → 재구매 전환율
- [ ] **이탈 예측**: 이탈 위험 고객 조기 탐지
- [ ] **CRM 성과 분석**: 캠페인 오픈율/클릭율/전환율

---

## 학습 팁

### 1. 문제 접근법 (Input → Output 사고)
```
1) 최종 Output 형태 파악
2) 필요한 테이블/컬럼 확인
3) 중간 Output 설계 (CTE 또는 서브쿼리)
4) 단계별 쿼리 작성
5) 최종 쿼리 조합
```

### 2. 디버깅 팁
```sql
-- 중간 결과 확인하면서 작성
WITH step1 AS (...),
     step2 AS (...)
-- SELECT * FROM step1;  -- 중간 확인
-- SELECT * FROM step2;  -- 중간 확인
SELECT * FROM step2;     -- 최종 결과
```

### 3. 실수 방지
- COUNT(*) vs COUNT(column) 차이 주의
- GROUP BY에 없는 컬럼 SELECT 주의
- NULL 비교는 = 대신 IS NULL 사용
- 날짜 포맷 일치 확인

---

> **"어려운 로직을 직접 생각하는 과정이 필요합니다.
> 처음에 어려운 느낌이 드는 건 당연합니다.
> 그러나 잘 수강하시면 SQL 역량이 많이 올라갈 것입니다."**

---

*Last Updated: 2026-01-20*
