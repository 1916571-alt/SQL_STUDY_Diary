# User Type 분류

> **정보**
> - **날짜**: 2026년 01월 23일
> - **분류**: Self-Made (D-3)
> - **주제**: New/Current/Resurrected/Churned 사용자 분류
> - **난이도**: ★★★★
> - **재풀이 여부**: X

---

### 문제 설명

각 월별로 사용자를 다음 4가지 타입으로 분류하세요:
- **New**: 해당 월에 첫 구매
- **Current**: 전월에도 구매, 이번 달에도 구매
- **Resurrected**: 전월 미구매, 이전에 구매 이력 있음, 이번 달 구매
- **Churned**: 전월 구매, 이번 달 미구매

**테이블**: orders

**출력**: year_month | new_users | current_users | resurrected_users | churned_users

---

### 정답 풀이

```sql
WITH monthly_users AS (
    SELECT DISTINCT
        user_id,
        DATE_FORMAT(order_date, '%Y-%m') AS year_month
    FROM orders
),
user_first_month AS (
    SELECT
        user_id,
        MIN(year_month) AS first_month
    FROM monthly_users
    GROUP BY user_id
),
all_months AS (
    SELECT DISTINCT year_month
    FROM monthly_users
),
user_status AS (
    SELECT
        am.year_month,
        mu.user_id,
        CASE
            WHEN ufm.first_month = am.year_month THEN 'New'
            WHEN prev.user_id IS NOT NULL AND mu.user_id IS NOT NULL THEN 'Current'
            WHEN prev.user_id IS NULL AND mu.user_id IS NOT NULL AND ufm.first_month < am.year_month THEN 'Resurrected'
            WHEN prev.user_id IS NOT NULL AND mu.user_id IS NULL THEN 'Churned'
            ELSE NULL
        END AS user_type
    FROM all_months am
    CROSS JOIN (SELECT DISTINCT user_id FROM monthly_users) all_users
    LEFT JOIN monthly_users mu
        ON all_users.user_id = mu.user_id AND am.year_month = mu.year_month
    LEFT JOIN monthly_users prev
        ON all_users.user_id = prev.user_id
        AND prev.year_month = DATE_FORMAT(DATE_SUB(STR_TO_DATE(CONCAT(am.year_month, '-01'), '%Y-%m-%d'), INTERVAL 1 MONTH), '%Y-%m')
    LEFT JOIN user_first_month ufm
        ON all_users.user_id = ufm.user_id
)
SELECT
    year_month,
    SUM(CASE WHEN user_type = 'New' THEN 1 ELSE 0 END) AS new_users,
    SUM(CASE WHEN user_type = 'Current' THEN 1 ELSE 0 END) AS current_users,
    SUM(CASE WHEN user_type = 'Resurrected' THEN 1 ELSE 0 END) AS resurrected_users,
    SUM(CASE WHEN user_type = 'Churned' THEN 1 ELSE 0 END) AS churned_users
FROM user_status
WHERE user_type IS NOT NULL
GROUP BY year_month
ORDER BY year_month;
```

---

### 간소화 버전

```sql
WITH monthly AS (
    SELECT DISTINCT
        user_id,
        DATE_FORMAT(order_date, '%Y-%m') AS ym
    FROM orders
),
first_month AS (
    SELECT user_id, MIN(ym) AS first_ym
    FROM monthly
    GROUP BY user_id
),
with_prev AS (
    SELECT
        m.user_id,
        m.ym,
        f.first_ym,
        LAG(m.ym) OVER (PARTITION BY m.user_id ORDER BY m.ym) AS prev_ym
    FROM monthly m
    JOIN first_month f ON m.user_id = f.user_id
),
classified AS (
    SELECT
        ym,
        user_id,
        CASE
            WHEN ym = first_ym THEN 'New'
            WHEN prev_ym = DATE_FORMAT(
                DATE_SUB(STR_TO_DATE(CONCAT(ym, '-01'), '%Y-%m-%d'), INTERVAL 1 MONTH),
                '%Y-%m'
            ) THEN 'Current'
            ELSE 'Resurrected'
        END AS user_type
    FROM with_prev
)
SELECT
    ym AS year_month,
    SUM(CASE WHEN user_type = 'New' THEN 1 ELSE 0 END) AS new_users,
    SUM(CASE WHEN user_type = 'Current' THEN 1 ELSE 0 END) AS current_users,
    SUM(CASE WHEN user_type = 'Resurrected' THEN 1 ELSE 0 END) AS resurrected_users
FROM classified
GROUP BY ym
ORDER BY ym;
```

---

### Churned 사용자 별도 계산

```sql
WITH monthly AS (
    SELECT DISTINCT user_id, DATE_FORMAT(order_date, '%Y-%m') AS ym
    FROM orders
),
with_next AS (
    SELECT
        user_id,
        ym,
        LEAD(ym) OVER (PARTITION BY user_id ORDER BY ym) AS next_ym
    FROM monthly
)
SELECT
    ym AS year_month,
    COUNT(CASE
        WHEN next_ym IS NULL OR next_ym != DATE_FORMAT(
            DATE_ADD(STR_TO_DATE(CONCAT(ym, '-01'), '%Y-%m-%d'), INTERVAL 1 MONTH),
            '%Y-%m'
        ) THEN 1
    END) AS churned_users
FROM with_next
GROUP BY ym
ORDER BY ym;
```

---

### 핵심 포인트

1. **LAG/LEAD**: 전월/다음월 활동 여부 확인
2. **첫 구매월 비교**: New vs 기존 사용자 구분
3. **연속 여부 판단**: 전월과 현재월이 1개월 차이인지 확인
4. **Churned 정의**: 전월 활성 → 당월 비활성 (미래 시점에서 판단)
5. **CROSS JOIN**: 모든 월 × 모든 사용자 조합 생성

---

### 실무 활용

- 사용자 성장 분해: 신규 유입 vs 이탈 vs 복귀
- 월간 활성 사용자(MAU) 구성 분석
- 리텐션 전략 수립 (Resurrected 증가 = 재활성화 캠페인 효과)
