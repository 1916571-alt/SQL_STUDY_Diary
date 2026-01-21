# LTV vs CAC 비율

> **정보**
> - **날짜**: 2026년 01월 21일
> - **분류**: Self-Made (G-5)
> - **주제**: 건강한 비즈니스 지표
> - **난이도**: ★★★★
> - **재풀이 여부**: X

---

### 문제 설명

채널별 LTV:CAC 비율을 계산하여 비즈니스 건강도를 분석하세요.

**테이블**: users, orders, marketing_costs

**출력**: channel | customer_count | avg_ltv | cac | ltv_cac_ratio | health_status

---

### 정답 풀이

```sql
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
```

---

### 핵심 포인트

1. **LTV:CAC 비율**: 3:1 이상이면 건강한 비즈니스
2. **의미 해석**: LTV가 CAC의 3배 → 고객 1명당 투자비의 3배 회수
3. **채널별 의사결정**: 비율이 낮은 채널은 개선 또는 예산 축소
