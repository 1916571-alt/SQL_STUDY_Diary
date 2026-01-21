# ROAS 채널별 분석

> **정보**
> - **날짜**: 2026년 01월 21일
> - **분류**: Self-Made (G-4)
> - **주제**: UTM + 매출 귀속
> - **난이도**: ★★★
> - **재풀이 여부**: X

---

### 문제 설명

채널별 ROAS(Return on Ad Spend, 광고수익률)를 계산하세요.

**테이블**: orders, users, marketing_costs

**출력**: channel | ym | revenue | ad_cost | roas

---

### 정답 풀이

```sql
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
```

---

### 핵심 포인트

1. **ROAS 공식**: 매출 / 광고비 (1 이상이면 수익)
2. **매출 귀속**: 유저의 utm_source로 매출을 해당 채널에 귀속
3. **채널 성과 비교**: ROAS가 높은 채널에 예산 집중
