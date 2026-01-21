# CAC 계산

> **정보**
> - **날짜**: 2026년 01월 21일
> - **분류**: Self-Made (G-3)
> - **주제**: 마케팅비용/신규고객
> - **난이도**: ★★★
> - **재풀이 여부**: X

---

### 문제 설명

채널별 고객획득비용(CAC: Customer Acquisition Cost)을 계산하세요.

**테이블**: users, marketing_costs

**출력**: channel | ym | new_users | marketing_cost | cac

---

### 정답 풀이

```sql
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
```

---

### 핵심 포인트

1. **CAC 공식**: 마케팅 비용 / 신규 고객 수
2. **UTM Source**: 유입 채널 추적의 핵심
3. **NULLIF**: 0으로 나누기 방지
