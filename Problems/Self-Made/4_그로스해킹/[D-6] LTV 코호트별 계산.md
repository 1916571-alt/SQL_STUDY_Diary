# LTV 코호트별 계산

> **정보**
> - **날짜**: 2026년 01월 21일
> - **분류**: Self-Made (D-6)
> - **주제**: 6개월 누적 LTV
> - **난이도**: ★★★★
> - **재풀이 여부**: X

---

### 문제 설명

코호트별 6개월 누적 LTV(고객생애가치)를 계산하세요.

**테이블**: orders

**출력**: cohort_month | cohort_users | month_number | revenue | cumulative_revenue | ltv_per_user

---

### 정답 풀이

```sql
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
```

---

### 핵심 포인트

1. **LTV 정의**: 고객이 평생 창출하는 가치 (여기선 6개월 기준)
2. **누적합 계산**: `SUM() OVER (ORDER BY month_number)` 로 월별 누적
3. **코호트별 비교**: 어느 시기에 획득한 고객이 가치가 높은지 분석
