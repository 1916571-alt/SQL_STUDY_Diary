# A/B 테스트 분석

> **정보**
> - **날짜**: 2026년 01월 23일
> - **분류**: Self-Made (F-5)
> - **주제**: 그룹별 비교 분석
> - **난이도**: ★★★
> - **재풀이 여부**: X

---

### 문제 설명

A/B 테스트 결과를 분석하여 Control 그룹과 Treatment 그룹의 전환율, 평균 구매액을 비교하세요.

**테이블**: ab_test_users
| 컬럼명 | 타입 | 설명 |
|--------|------|------|
| id | INT | ID |
| user_id | INT | 사용자 ID |
| test_group | VARCHAR | 테스트 그룹 ('control', 'treatment') |
| assigned_at | DATETIME | 배정 시간 |

**테이블**: orders (기존)

**출력**: test_group | users | purchasers | conversion_rate | total_revenue | avg_revenue_per_user | avg_order_value

---

### 정답 풀이

```sql
WITH test_metrics AS (
    SELECT
        ab.test_group,
        COUNT(DISTINCT ab.user_id) AS users,
        COUNT(DISTINCT o.user_id) AS purchasers,
        SUM(o.total_amount) AS total_revenue,
        COUNT(o.id) AS order_count
    FROM ab_test_users ab
    LEFT JOIN orders o
        ON ab.user_id = o.user_id
        AND o.order_date >= DATE(ab.assigned_at)
    GROUP BY ab.test_group
)
SELECT
    test_group,
    users,
    purchasers,
    ROUND(purchasers * 100.0 / users, 2) AS conversion_rate,
    COALESCE(total_revenue, 0) AS total_revenue,
    ROUND(COALESCE(total_revenue, 0) / users, 0) AS avg_revenue_per_user,
    ROUND(COALESCE(total_revenue, 0) / NULLIF(order_count, 0), 0) AS avg_order_value
FROM test_metrics
ORDER BY test_group;
```

---

### 확장: 통계적 유의성 검정 준비 데이터

```sql
WITH daily_metrics AS (
    SELECT
        DATE(ab.assigned_at) AS test_date,
        ab.test_group,
        COUNT(DISTINCT ab.user_id) AS daily_users,
        COUNT(DISTINCT CASE WHEN o.id IS NOT NULL THEN ab.user_id END) AS daily_purchasers,
        COALESCE(SUM(o.total_amount), 0) AS daily_revenue
    FROM ab_test_users ab
    LEFT JOIN orders o
        ON ab.user_id = o.user_id
        AND o.order_date >= DATE(ab.assigned_at)
        AND o.order_date <= DATE_ADD(DATE(ab.assigned_at), INTERVAL 7 DAY)
    GROUP BY DATE(ab.assigned_at), ab.test_group
)
SELECT
    test_group,
    COUNT(*) AS days,
    SUM(daily_users) AS total_users,
    SUM(daily_purchasers) AS total_purchasers,
    ROUND(SUM(daily_purchasers) * 100.0 / SUM(daily_users), 2) AS overall_cvr,
    ROUND(AVG(daily_purchasers * 100.0 / daily_users), 2) AS avg_daily_cvr,
    ROUND(STDDEV(daily_purchasers * 100.0 / daily_users), 2) AS stddev_cvr,
    SUM(daily_revenue) AS total_revenue,
    ROUND(AVG(daily_revenue / NULLIF(daily_users, 0)), 0) AS avg_daily_arpu
FROM daily_metrics
GROUP BY test_group;
```

---

### 그룹별 세그먼트 상세 분석

```sql
WITH user_segment AS (
    SELECT
        ab.user_id,
        ab.test_group,
        u.grade,
        CASE
            WHEN TIMESTAMPDIFF(YEAR, u.birth_date, CURDATE()) < 30 THEN '20대'
            WHEN TIMESTAMPDIFF(YEAR, u.birth_date, CURDATE()) < 40 THEN '30대'
            ELSE '40대 이상'
        END AS age_group
    FROM ab_test_users ab
    JOIN users u ON ab.user_id = u.id
),
segment_metrics AS (
    SELECT
        us.test_group,
        us.age_group,
        COUNT(DISTINCT us.user_id) AS users,
        COUNT(DISTINCT o.user_id) AS purchasers,
        COALESCE(SUM(o.total_amount), 0) AS revenue
    FROM user_segment us
    LEFT JOIN orders o ON us.user_id = o.user_id
    GROUP BY us.test_group, us.age_group
)
SELECT
    test_group,
    age_group,
    users,
    purchasers,
    ROUND(purchasers * 100.0 / users, 2) AS conversion_rate,
    revenue,
    ROUND(revenue / users, 0) AS arpu
FROM segment_metrics
ORDER BY test_group, age_group;
```

---

### 핵심 포인트

1. **배정 이후 행동만 카운트**: `o.order_date >= DATE(ab.assigned_at)`
2. **LEFT JOIN**: 구매하지 않은 유저도 포함
3. **전환율**: 구매자 수 / 전체 배정 유저 수
4. **ARPU**: 유저당 평균 매출 (Average Revenue Per User)
5. **세그먼트별 분석**: 어떤 세그먼트에서 효과가 큰지 확인

---

### 실무 활용

- Treatment 그룹의 전환율이 Control 대비 높은지 비교
- 통계적 유의성 검정을 위한 표본 크기, 표준편차 확인
- 특정 세그먼트에서만 효과가 있는지 분석
