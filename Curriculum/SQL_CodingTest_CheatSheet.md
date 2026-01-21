# SQL 코딩테스트 CHEAT SHEET

> **시험장 빠른 참조용** - 헷갈리는 함수/문법 바로 찾기

---

## 0. 헷갈리기 쉬운 함수 모음 (시험 전 필독!)

### 연령/나이 계산
```sql
-- 생년월일 → 나이 (정확한 방법)
TIMESTAMPDIFF(YEAR, birth_date, CURDATE()) AS age

-- 연령대 분류
CASE
    WHEN TIMESTAMPDIFF(YEAR, birth_date, CURDATE()) < 20 THEN '10대'
    WHEN TIMESTAMPDIFF(YEAR, birth_date, CURDATE()) < 30 THEN '20대'
    WHEN TIMESTAMPDIFF(YEAR, birth_date, CURDATE()) < 40 THEN '30대'
    WHEN TIMESTAMPDIFF(YEAR, birth_date, CURDATE()) < 50 THEN '40대'
    ELSE '50대 이상'
END AS age_group
```

### TIMESTAMPDIFF 완전 정복
```sql
-- 문법: TIMESTAMPDIFF(단위, 시작일, 종료일)
-- ⚠️ 순서 주의: 작은 날짜가 먼저! (종료일 - 시작일)

TIMESTAMPDIFF(YEAR, birth_date, CURDATE())    -- 년수 차이 (나이)
TIMESTAMPDIFF(MONTH, date1, date2)            -- 월수 차이 (코호트)
TIMESTAMPDIFF(DAY, date1, date2)              -- 일수 차이
TIMESTAMPDIFF(HOUR, time1, time2)             -- 시간 차이
TIMESTAMPDIFF(MINUTE, time1, time2)           -- 분 차이 (세션 분석)

-- 예: 코호트 월 차이 계산
TIMESTAMPDIFF(MONTH,
    STR_TO_DATE(CONCAT(cohort_month, '-01'), '%Y-%m-%d'),
    STR_TO_DATE(CONCAT(activity_month, '-01'), '%Y-%m-%d')
) AS month_number
```

### DATEDIFF vs TIMESTAMPDIFF
```sql
-- DATEDIFF: 일수만 계산 (간단)
DATEDIFF(date1, date2)                -- date1 - date2 (일수)
DATEDIFF(CURDATE(), last_login)       -- 마지막 접속 후 경과일

-- TIMESTAMPDIFF: 다양한 단위 (정확)
TIMESTAMPDIFF(DAY, date1, date2)      -- 일수
TIMESTAMPDIFF(MONTH, date1, date2)    -- 월수 (정확한 월 차이)
```

### DATE_ADD / DATE_SUB
```sql
-- 날짜 더하기/빼기
DATE_ADD(date, INTERVAL 1 DAY)        -- 1일 후
DATE_ADD(date, INTERVAL 7 DAY)        -- 7일 후
DATE_SUB(date, INTERVAL 1 MONTH)      -- 1달 전
DATE_SUB(date, INTERVAL 30 DAY)       -- 30일 전

-- 실전: 전일 데이터 JOIN
LEFT JOIN base b2 ON b1.order_date = DATE_ADD(b2.order_date, INTERVAL 1 DAY)
```

### DAYOFWEEK vs WEEKDAY
```sql
-- DAYOFWEEK: 1=일요일, 2=월요일, ..., 7=토요일
DAYOFWEEK(order_date)
CASE DAYOFWEEK(order_date)
    WHEN 1 THEN '일요일'
    WHEN 2 THEN '월요일'
    -- ...
    WHEN 7 THEN '토요일'
END

-- WEEKDAY: 0=월요일, 1=화요일, ..., 6=일요일
WEEKDAY(purchased_at)
CASE WEEKDAY(purchased_at)
    WHEN 0 THEN 'Monday'
    WHEN 1 THEN 'Tuesday'
    -- ...
    WHEN 6 THEN 'Sunday'
END
```

### 분기(Quarter) 추출
```sql
-- 분기 추출
QUARTER(date)                         -- 1, 2, 3, 4

-- 연도-분기 형식
CONCAT(YEAR(sale_date), '-Q', QUARTER(sale_date)) AS year_quarter
-- 결과: '2024-Q1', '2024-Q2' 등
```

### 시간 추출
```sql
HOUR(order_datetime)      -- 시간 (0-23)
MINUTE(datetime)          -- 분 (0-59)
SECOND(datetime)          -- 초 (0-59)

-- 시간대 분류
CASE
    WHEN HOUR(order_datetime) BETWEEN 6 AND 10 THEN '아침'
    WHEN HOUR(order_datetime) BETWEEN 11 AND 13 THEN '점심'
    WHEN HOUR(order_datetime) BETWEEN 14 AND 17 THEN '오후'
    WHEN HOUR(order_datetime) BETWEEN 18 AND 21 THEN '저녁'
    ELSE '심야'
END AS time_slot
```

---

## 1. 상황별 빠른 참조표

| 문제 요구사항 | 사용할 함수/패턴 | 예시 |
|-------------|-----------------|------|
| "~별 TOP N개" | `DENSE_RANK() OVER (PARTITION BY ... ORDER BY ...)` | 부서별 연봉 TOP 3 |
| "순위 매기기" | `ROW_NUMBER()` / `RANK()` / `DENSE_RANK()` | 판매량 순위 |
| "상위 10%" | `PERCENT_RANK() <= 0.10` | 성적 상위 10% |
| "N등분" | `NTILE(N)` | RFM 점수 (5등분) |
| "전일/전월 대비" | `LAG(col) OVER (ORDER BY date)` | 전일 대비 증감률 |
| "누적합" | `SUM() OVER (ORDER BY date)` | 월별 누적 매출 |
| "이동평균 (N일)" | `AVG() OVER (ROWS BETWEEN N-1 PRECEDING AND CURRENT ROW)` | 7일 이동평균 |
| "비율/퍼센트" | `값 / SUM(값) OVER () * 100` | 전체 대비 비중 |
| "~한 적 없는" | `LEFT JOIN + IS NULL` 또는 `NOT EXISTS` | 미구매 회원 |
| "~가 존재하는" | `EXISTS` | 특정 조건 주문 있는 회원 |
| "없는 구간 채우기" | 재귀 CTE로 시리즈 생성 + `LEFT JOIN` | 모든 시간대 출력 |
| "데이터 합치기" | `UNION ALL` (중복 허용) / `UNION` (중복 제거) | 온오프라인 통합 |
| "~와 함께 구매" | `Self JOIN (같은 order_id)` | 동시 구매 상품 |
| "첫 구매/첫 접속" | `MIN(date) GROUP BY user_id` | 코호트 분석 |
| "연속 N일" | `날짜 - ROW_NUMBER() = 동일그룹` | 연속 로그인 |
| "NULL 채우기" | `FIRST_VALUE() + 그룹핑` 또는 서브쿼리 | Forward Fill |
| "연령대별" | `TIMESTAMPDIFF(YEAR, birth_date, CURDATE())` | 10대, 20대... |
| "시간대별" | `HOUR(datetime) + CASE WHEN` | 새벽/오전/오후/저녁 |
| "요일별" | `DAYOFWEEK()` 또는 `WEEKDAY()` | 월~일 패턴 |
| "분기별" | `QUARTER(date)` | 분기별 실적 |
| "월별 집계" | `DATE_FORMAT(date, '%Y-%m')` | 월별 매출 |
| "그룹별 MAX만" | `기준 테이블 + MAX 테이블 JOIN` | 도시별 VIP |
| "중앙값" | `ROW_NUMBER() + FLOOR/CEIL` | 부서별 중앙값 |

---

## 2. 핵심 함수 모음

### 2-1. 날짜 함수 (가장 자주 출제!)

```sql
-- 날짜 포맷 변환 (필수!)
DATE_FORMAT(date, '%Y-%m-%d')   -- 2024-01-15
DATE_FORMAT(date, '%Y-%m')      -- 2024-01 (월별 집계용)
DATE_FORMAT(date, '%Y')         -- 2024 (연도만)

-- 날짜 추출
YEAR(date), MONTH(date), DAY(date)
HOUR(datetime), MINUTE(datetime)
DAYOFWEEK(date)   -- 1=일, 7=토
WEEKDAY(date)     -- 0=월, 6=일
QUARTER(date)     -- 1~4 분기

-- 날짜 연산
DATE_ADD(date, INTERVAL 1 DAY)
DATE_SUB(date, INTERVAL 1 MONTH)
DATEDIFF(date1, date2)              -- 일수 차이
TIMESTAMPDIFF(MONTH, date1, date2)  -- 월수 차이

-- 문자열 → 날짜
STR_TO_DATE('2024-01-15', '%Y-%m-%d')
STR_TO_DATE(CONCAT(ym, '-01'), '%Y-%m-%d')
```

### 2-2. 집계 함수

```sql
COUNT(*)                    -- 전체 행 수 (NULL 포함)
COUNT(column)               -- NULL 제외 행 수
COUNT(DISTINCT column)      -- 중복 제거 후 개수

SUM(column), AVG(column), MAX(column), MIN(column)
```

### 2-3. 조건 함수 (CASE WHEN)

```sql
-- 기본 형태
CASE
    WHEN 조건1 THEN 결과1
    WHEN 조건2 THEN 결과2
    ELSE 기본값
END

-- 조건부 집계 (피벗)
SUM(CASE WHEN category = '커피' THEN amount ELSE 0 END) AS coffee_amount
COUNT(CASE WHEN status = 'completed' THEN 1 END) AS completed_count

-- ⭐ 조건부 DISTINCT (매우 자주 출제!)
COUNT(DISTINCT CASE WHEN category = '전자제품' THEN user_id END) AS elec_buyers
COUNT(DISTINCT CASE WHEN order_count >= 2 THEN user_id END) AS repeat_buyers

-- 크로스탭 (월별 피벗)
SUM(CASE WHEN DATE_FORMAT(order_date, '%Y-%m') = '2024-01' THEN qty ELSE 0 END) AS `2024-01`
```

### 2-4. NULL 처리

```sql
IFNULL(column, 대체값)          -- NULL이면 대체값
COALESCE(a, b, c)               -- 첫 번째 NOT NULL 값
NULLIF(a, b)                    -- a=b면 NULL

-- NULL 비교 (= 사용 금지!)
WHERE column IS NULL
WHERE column IS NOT NULL

-- 0으로 나누기 방지
column / NULLIF(divisor, 0)
```

### 2-5. 문자열 함수

```sql
CONCAT(str1, '-', str2)             -- 문자열 연결
SUBSTRING(str, start, length)       -- 부분 문자열
LEFT(str, n), RIGHT(str, n)
REPLACE(str, from, to)              -- 문자열 치환
TRIM(str)                           -- 양쪽 공백 제거

-- 전화번호 포맷: 01012345678 → 010-1234-5678
CONCAT(
    SUBSTRING(phone, 1, 3), '-',
    SUBSTRING(phone, 4, 4), '-',
    SUBSTRING(phone, 8, 4)
) AS formatted_phone

-- 패턴 매칭
LIKE '%키워드%'                     -- 포함
LIKE '김%'                          -- ~로 시작
NOT LIKE '%test%'                   -- 미포함

-- 콤마 구분 옵션에서 특정 값 찾기 (MySQL)
FIND_IN_SET('네비게이션', options)  -- options = '선루프,네비게이션,후방카메라'
-- 결과: 2 (위치 반환, 없으면 0)

-- 정규식 (REGEXP)
WHERE name REGEXP '^[가-힣]+$'      -- 한글만
WHERE phone REGEXP '^010'           -- 010으로 시작
```

### 2-6. 숫자 함수

```sql
ROUND(num, 2)       -- 소수점 2자리 반올림
CEIL(num)           -- 올림
FLOOR(num)          -- 내림
ABS(num)            -- 절댓값
MOD(a, b)           -- 나머지 (A/B테스트: customer_id % 10)
```

---

## 3. 윈도우 함수 완전 정복

### 3-1. 순위 함수 비교

```sql
-- 데이터: 100, 100, 90, 80
ROW_NUMBER()    -- 1, 2, 3, 4 (무조건 순차, 고유번호)
RANK()          -- 1, 1, 3, 4 (동점 후 건너뜀)
DENSE_RANK()    -- 1, 1, 2, 3 (동점 후 연속) ← TOP N 추출시 추천!

-- 사용 기준
ROW_NUMBER()  → 고유 번호, 정확히 1개만 뽑을 때
DENSE_RANK()  → "TOP 3" 요구 시 동점자 모두 포함
RANK()        → 일반적인 순위
```

### 3-2. 그룹별 TOP N (핵심 패턴!)

```sql
-- 카테고리별 매출 TOP 3 (동점자 모두 포함)
WITH ranked AS (
    SELECT
        category_name,
        product_name,
        total_revenue,
        DENSE_RANK() OVER (
            PARTITION BY category_name
            ORDER BY total_revenue DESC
        ) AS rnk
    FROM sales_summary
)
SELECT * FROM ranked WHERE rnk <= 3;
```

### 3-3. 백분위 & N등분

```sql
-- 상위 10% (PERCENT_RANK: 0~1 범위)
PERCENT_RANK() OVER (ORDER BY score DESC) AS percentile
WHERE percentile <= 0.10

-- 5등분 (RFM 분석용)
NTILE(5) OVER (ORDER BY recency DESC) AS r_score
NTILE(5) OVER (ORDER BY frequency) AS f_score
NTILE(5) OVER (ORDER BY monetary) AS m_score
```

### 3-4. LAG / LEAD

```sql
-- LAG: 이전 행 값
LAG(column, 1) OVER (ORDER BY date)         -- 1행 이전
LAG(column, 1, 0) OVER (ORDER BY date)      -- 기본값 0

-- 전일 대비 증감률
SELECT
    date, sales,
    LAG(sales, 1) OVER (ORDER BY date) AS prev_sales,
    ROUND((sales - LAG(sales, 1) OVER (ORDER BY date))
          / NULLIF(LAG(sales, 1) OVER (ORDER BY date), 0) * 100, 2) AS change_rate
FROM daily_sales;

-- 구매 주기 계산
DATEDIFF(order_date, LAG(order_date) OVER (PARTITION BY user_id ORDER BY order_date)) AS days_between
```

### 3-5. 누적합 & 이동평균

```sql
-- 누적합
SUM(amount) OVER (ORDER BY date) AS cumulative

-- 7일 이동평균
AVG(revenue) OVER (
    ORDER BY date
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
) AS moving_avg_7days

-- 전체 대비 비율
amount / SUM(amount) OVER () * 100 AS ratio
```

### 3-6. FIRST_VALUE / LAST_VALUE

```sql
-- NULL Forward Fill (빈 값을 직전 값으로 채우기)
WITH numbered AS (
    SELECT
        date, price,
        SUM(CASE WHEN price IS NOT NULL THEN 1 ELSE 0 END)
            OVER (ORDER BY date) AS grp
    FROM stock_prices
)
SELECT
    date,
    FIRST_VALUE(price) OVER (PARTITION BY grp ORDER BY date) AS filled_price
FROM numbered;
```

---

## 4. JOIN 패턴

### 4-1. 미구매 회원 - 2가지 방법

```sql
-- 방법1: LEFT JOIN + IS NULL (익숙한 방식)
SELECT u.id, u.name
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
WHERE o.user_id IS NULL;

-- 방법2: NOT EXISTS (더 안전! 중복 문제 없음)
SELECT u.id, u.name
FROM users u
WHERE NOT EXISTS (
    SELECT 1 FROM orders o WHERE o.user_id = u.id
);

-- EXISTS: "조건 만족하는 주문이 있는 회원"
SELECT u.id, u.name
FROM users u
WHERE EXISTS (
    SELECT 1 FROM orders o
    WHERE o.user_id = u.id
      AND o.total_amount >= 100000
);
```

**언제 NOT EXISTS가 더 좋은가?**
- JOIN 시 1:N 관계에서 중복 뻥튀기 방지
- 복잡한 조건 (여러 테이블 조건 조합)
- "존재 여부"만 확인할 때

### 4-2. 동시 구매 분석 (Self JOIN)
```sql
SELECT p.name, COUNT(*) AS co_purchase_count
FROM order_items oi1
JOIN order_items oi2 ON oi1.order_id = oi2.order_id
JOIN products p ON oi2.product_id = p.id
WHERE oi1.product_id = 1
  AND oi2.product_id != 1
GROUP BY oi2.product_id, p.name
ORDER BY co_purchase_count DESC;
```

### 4-3. 그룹별 MAX만 추출 (기준+MAX 테이블 JOIN)
```sql
-- 도시별 VIP (최고 소비 고객)
WITH city_customer AS (
    SELECT city_id, customer_id, SUM(total_price) AS total_spent
    FROM transactions
    GROUP BY city_id, customer_id
),
city_max AS (
    SELECT city_id, MAX(total_spent) AS max_spent
    FROM city_customer
    GROUP BY city_id
)
SELECT cc.city_id, cc.customer_id, cc.total_spent
FROM city_customer cc
JOIN city_max cm ON cc.city_id = cm.city_id
  AND cc.total_spent = cm.max_spent;
```

---

## 5. 비즈니스 로직 템플릿

### 5-1. 코호트 리텐션
```sql
WITH first_order AS (
    SELECT user_id,
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
)
SELECT cohort_month, month_number,
       COUNT(DISTINCT user_id) AS retained_users
FROM monthly_activity
GROUP BY cohort_month, month_number
ORDER BY cohort_month, month_number;
```

### 5-2. D1/D3/D7 리텐션
```sql
WITH first_login AS (
    SELECT user_id, MIN(login_date) AS first_date
    FROM login_logs
    GROUP BY user_id
),
retention AS (
    SELECT
        f.user_id,
        MAX(CASE WHEN DATEDIFF(l.login_date, f.first_date) = 1 THEN 1 ELSE 0 END) AS d1,
        MAX(CASE WHEN DATEDIFF(l.login_date, f.first_date) = 3 THEN 1 ELSE 0 END) AS d3,
        MAX(CASE WHEN DATEDIFF(l.login_date, f.first_date) = 7 THEN 1 ELSE 0 END) AS d7
    FROM first_login f
    LEFT JOIN login_logs l ON f.user_id = l.user_id
    GROUP BY f.user_id
)
SELECT
    COUNT(*) AS total_users,
    ROUND(SUM(d1) * 100.0 / COUNT(*), 2) AS d1_rate,
    ROUND(SUM(d3) * 100.0 / COUNT(*), 2) AS d3_rate,
    ROUND(SUM(d7) * 100.0 / COUNT(*), 2) AS d7_rate
FROM retention;
```

### 5-3. 연속 패턴 (연속 로그인, 연속 1위)
```sql
-- 핵심: 날짜 - ROW_NUMBER() = 동일 그룹
WITH numbered AS (
    SELECT
        user_id,
        login_date,
        DATE_SUB(login_date, INTERVAL ROW_NUMBER() OVER (
            PARTITION BY user_id ORDER BY login_date
        ) DAY) AS grp
    FROM login_logs
)
SELECT
    user_id,
    MIN(login_date) AS streak_start,
    MAX(login_date) AS streak_end,
    COUNT(*) AS consecutive_days
FROM numbered
GROUP BY user_id, grp
HAVING COUNT(*) >= 7;
```

### 5-4. RFM 분석
```sql
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
    SELECT *,
        NTILE(5) OVER (ORDER BY recency DESC) AS r_score,  -- 최근일수록 높은 점수
        NTILE(5) OVER (ORDER BY frequency) AS f_score,
        NTILE(5) OVER (ORDER BY monetary) AS m_score
    FROM rfm_base
)
SELECT *,
    CONCAT(r_score, f_score, m_score) AS rfm_segment,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 THEN 'Champions'
        WHEN r_score >= 4 AND f_score <= 2 THEN 'New Customers'
        WHEN r_score <= 2 AND f_score >= 4 THEN 'At Risk'
        ELSE 'Others'
    END AS customer_segment
FROM rfm_scores;
```

### 5-5. 중앙값 계산
```sql
-- MySQL은 MEDIAN 함수 없음 → ROW_NUMBER로 구현
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
GROUP BY dept_id;
```

### 5-6. A/B 테스트 버킷
```sql
-- customer_id % 10 으로 버킷 분류
SELECT
    CASE WHEN customer_id % 10 = 0 THEN 'A' ELSE 'B' END AS bucket,
    COUNT(*) AS user_count,
    ROUND(AVG(order_count), 2) AS avg_orders,
    ROUND(AVG(revenue), 2) AS avg_revenue
FROM user_summary
GROUP BY bucket;
```

### 5-7. 날짜 시리즈 생성 (없는 행 만들기)
```sql
-- "모든 시간대 출력하되, 주문 없으면 0" (입양 시각 구하기 2)
-- 재귀 CTE로 0~23시 생성
WITH RECURSIVE hours AS (
    SELECT 0 AS hour
    UNION ALL
    SELECT hour + 1 FROM hours WHERE hour < 23
)
SELECT
    h.hour,
    COUNT(o.id) AS order_count
FROM hours h
LEFT JOIN orders o ON HOUR(o.order_datetime) = h.hour
GROUP BY h.hour
ORDER BY h.hour;

-- 날짜 시리즈 생성 (2024-01-01 ~ 2024-01-31)
WITH RECURSIVE dates AS (
    SELECT DATE('2024-01-01') AS date
    UNION ALL
    SELECT DATE_ADD(date, INTERVAL 1 DAY)
    FROM dates
    WHERE date < '2024-01-31'
)
SELECT
    d.date,
    COALESCE(SUM(o.total_amount), 0) AS daily_revenue
FROM dates d
LEFT JOIN orders o ON DATE(o.order_date) = d.date
GROUP BY d.date;
```

### 5-8. Top N - 서브쿼리 풀이 (윈도우 없이)
```sql
-- 윈도우 함수 없이 그룹별 MAX만 뽑기
-- 카테고리별 최고 매출 상품
SELECT p.category, p.name, p.revenue
FROM products p
WHERE p.revenue = (
    SELECT MAX(p2.revenue)
    FROM products p2
    WHERE p2.category = p.category
);

-- Top 3 (동점자 포함)
SELECT p.category, p.name, p.revenue
FROM products p
WHERE (
    SELECT COUNT(DISTINCT p2.revenue)
    FROM products p2
    WHERE p2.category = p.category
      AND p2.revenue >= p.revenue
) <= 3;
```

---

## 6. UNION / UNION ALL

```sql
-- UNION: 중복 제거 (DISTINCT)
SELECT name, 'orders' AS source FROM orders
UNION
SELECT name, 'returns' AS source FROM returns;

-- UNION ALL: 그대로 붙임 (빠름, 중복 허용)
SELECT product_id, quantity, 'online' AS channel FROM online_sales
UNION ALL
SELECT product_id, quantity, 'offline' AS channel FROM offline_sales;
```

**필수 규칙:**
- 컬럼 개수 동일해야 함
- 컬럼 타입 호환되어야 함
- 컬럼명은 첫 번째 SELECT 기준
- `ORDER BY`는 맨 마지막에만 (전체 결과 정렬)

```sql
-- 올바른 예
SELECT id, name FROM a
UNION ALL
SELECT id, name FROM b
ORDER BY id;  -- 맨 마지막에만!
```

---

## 7. 날짜 경계 함정 (BETWEEN 주의!)

### BETWEEN은 양끝 포함!
```sql
-- BETWEEN은 이상/이하 (>=, <=)
WHERE date BETWEEN '2024-01-01' AND '2024-01-31'
-- = WHERE date >= '2024-01-01' AND date <= '2024-01-31'

-- ⚠️ DATETIME에서 함정!
WHERE order_datetime BETWEEN '2024-01-01' AND '2024-01-31'
-- 2024-01-31 00:00:00 까지만 포함! (23:59:59 제외)

-- 안전한 방법
WHERE order_datetime >= '2024-01-01'
  AND order_datetime < '2024-02-01'  -- 다음날 미만
```

### 기간 계산: +1 해야 할 때
```sql
-- 대여 기간, 숙박 일수, 근무일 등은 +1
-- 1월 1일 ~ 1월 3일 = 3일 (1,2,3일)
DATEDIFF(end_date, start_date) + 1 AS rental_days

-- 단순 경과 일수는 그대로
-- 1월 1일 가입 → 1월 3일 현재 = 2일 경과
DATEDIFF(CURDATE(), signup_date) AS days_since_signup
```

---

## 8. 윈도우 프레임 함정

### ROWS vs RANGE
```sql
-- ROWS: 물리적 행 기준 (정확히 N행)
AVG(val) OVER (ORDER BY date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)
-- → 정확히 현재 포함 3행 평균

-- RANGE: 논리적 값 기준 (같은 값이면 모두 포함)
AVG(val) OVER (ORDER BY date RANGE BETWEEN 2 PRECEDING AND CURRENT ROW)
-- → 같은 날짜가 여러 개면 모두 포함!

-- ⚠️ 기본값이 RANGE인 경우가 있어서, 명시적으로 ROWS 쓰는 게 안전
```

### LAST_VALUE 함정
```sql
-- ❌ 기대와 다른 결과 (기본 프레임 문제)
LAST_VALUE(name) OVER (PARTITION BY dept ORDER BY salary)

-- ✅ 올바른 방법: 프레임 명시
LAST_VALUE(name) OVER (
    PARTITION BY dept ORDER BY salary
    ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
)
```

---

## 9. 자주 틀리는 실수 체크리스트

| 실수 | 올바른 방법 |
|-----|-----------|
| `WHERE col = NULL` | `WHERE col IS NULL` |
| `LAG()` 에 `PARTITION BY` 잘못 사용 | 시계열은 `ORDER BY`만! |
| 0으로 나누기 | `/ NULLIF(divisor, 0)` |
| `COUNT(*)`가 NULL 제외라고 착각 | `COUNT(*)` = NULL 포함, `COUNT(col)` = NULL 제외 |
| `GROUP BY`에 없는 컬럼 SELECT | 집계 아닌 컬럼은 모두 `GROUP BY`에 |
| `DAYOFWEEK` 시작일 혼동 | 1=일요일 (vs `WEEKDAY` 0=월요일) |
| `TIMESTAMPDIFF` 순서 | `(단위, 시작일, 종료일)` - 작은 날짜 먼저! |
| `BETWEEN` datetime 함정 | `>= start AND < next_day` 가 안전 |
| `UNION` 컬럼 불일치 | 컬럼 개수/타입/순서 일치 필수 |
| 기간 계산 +1 누락 | 대여일수 = `DATEDIFF() + 1` |
| `LAST_VALUE` 기본 프레임 | `ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING` 명시 |

---

## 10. Quick Reference (복붙용)

```sql
-- 월별 집계
DATE_FORMAT(date, '%Y-%m')

-- 연령 계산
TIMESTAMPDIFF(YEAR, birth_date, CURDATE())

-- 분기 추출
CONCAT(YEAR(date), '-Q', QUARTER(date))

-- 그룹별 TOP N
DENSE_RANK() OVER (PARTITION BY grp ORDER BY val DESC) AS rnk
WHERE rnk <= N

-- 전일 대비
LAG(val, 1) OVER (ORDER BY date) AS prev_val

-- 증감률
ROUND((현재 - 이전) / NULLIF(이전, 0) * 100, 2)

-- 누적합
SUM(val) OVER (ORDER BY date)

-- 7일 이동평균 (ROWS 명시!)
AVG(val) OVER (ORDER BY date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)

-- 미구매 회원
NOT EXISTS (SELECT 1 FROM orders o WHERE o.user_id = u.id)

-- 조건부 DISTINCT
COUNT(DISTINCT CASE WHEN 조건 THEN user_id END)

-- NULL 대체
COALESCE(a, b, 0)

-- 조건부 집계
SUM(CASE WHEN 조건 THEN 값 ELSE 0 END)

-- 날짜 시리즈 생성 (재귀)
WITH RECURSIVE nums AS (SELECT 0 AS n UNION ALL SELECT n+1 FROM nums WHERE n<23)

-- 대여/숙박 기간
DATEDIFF(end_date, start_date) + 1

-- 안전한 날짜 범위
WHERE date >= '2024-01-01' AND date < '2024-02-01'

-- 연속 패턴
DATE_SUB(date, INTERVAL ROW_NUMBER() OVER (...) DAY) AS grp

-- 콤마 구분 옵션 검색
FIND_IN_SET('네비게이션', options) > 0
```

---

## 11. 문제 접근 순서

```
1. 최종 Output 형태 파악 (어떤 컬럼?)
2. 필요한 테이블/컬럼 확인
3. "없는 행"이 필요한지 체크 (시리즈 생성?)
4. 중간 Output 설계 (CTE로 단계 분리)
5. 단계별 쿼리 작성 & 검증
6. 최종 쿼리 조합

💡 디버깅: CTE 중간에서 SELECT * FROM step1; 로 확인
💡 날짜 범위: BETWEEN 대신 >= AND < 고려
💡 중복 체크: JOIN 결과가 뻥튀기되는지 확인
```

---

*Updated: 2026-01-21 | Based on 43 Practice Problems + Programmers + Solve_SQL_2025 + GPT Review*
