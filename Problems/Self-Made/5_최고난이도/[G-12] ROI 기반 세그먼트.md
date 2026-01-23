# ROI 기반 세그먼트

> **정보**
> - **날짜**: 2026년 01월 23일
> - **분류**: Self-Made (G-12)
> - **주제**: 마케팅 우선순위 결정을 위한 ROI 세그먼트
> - **난이도**: ★★★★
> - **재풀이 여부**: X

---

### 문제 설명

채널별/세그먼트별 마케팅 ROI를 계산하여 투자 우선순위를 결정하세요.
각 세그먼트의 획득 비용, 매출, LTV, ROI를 분석합니다.

**테이블**: users, orders, marketing_costs

**출력**: segment | customers | total_revenue | acquisition_cost | roi | priority_rank

---

### 정답 풀이

```sql
WITH customer_value AS (
    SELECT
        u.id AS user_id,
        u.utm_source AS channel,
        u.grade,
        u.rfm_segment,
        DATE_FORMAT(u.created_at, '%Y-%m') AS acquisition_month,
        COUNT(o.id) AS order_count,
        COALESCE(SUM(o.total_amount), 0) AS lifetime_value
    FROM users u
    LEFT JOIN orders o ON u.id = o.user_id
    GROUP BY u.id, u.utm_source, u.grade, u.rfm_segment, DATE_FORMAT(u.created_at, '%Y-%m')
),
channel_costs AS (
    SELECT
        channel,
        SUM(cost) AS total_cost,
        COUNT(DISTINCT ym) AS months
    FROM marketing_costs
    GROUP BY channel
),
channel_customers AS (
    SELECT
        channel,
        COUNT(*) AS customer_count
    FROM customer_value
    WHERE channel IS NOT NULL
    GROUP BY channel
),
channel_metrics AS (
    SELECT
        cv.channel,
        COUNT(DISTINCT cv.user_id) AS customers,
        SUM(cv.lifetime_value) AS total_revenue,
        ROUND(AVG(cv.lifetime_value), 0) AS avg_ltv,
        cc.total_cost AS acquisition_cost,
        ROUND(cc.total_cost / NULLIF(cust.customer_count, 0), 0) AS cac
    FROM customer_value cv
    JOIN channel_costs cc ON cv.channel = cc.channel
    JOIN channel_customers cust ON cv.channel = cust.channel
    WHERE cv.channel IS NOT NULL
    GROUP BY cv.channel, cc.total_cost, cust.customer_count
)
SELECT
    channel AS segment,
    customers,
    total_revenue,
    acquisition_cost,
    ROUND((total_revenue - acquisition_cost) * 100.0 / NULLIF(acquisition_cost, 0), 2) AS roi_pct,
    ROUND(avg_ltv / NULLIF(cac, 0), 2) AS ltv_cac_ratio,
    RANK() OVER (ORDER BY (total_revenue - acquisition_cost) * 100.0 / NULLIF(acquisition_cost, 0) DESC) AS priority_rank,
    CASE
        WHEN (total_revenue - acquisition_cost) * 100.0 / NULLIF(acquisition_cost, 0) >= 200 THEN 'Scale Up'
        WHEN (total_revenue - acquisition_cost) * 100.0 / NULLIF(acquisition_cost, 0) >= 100 THEN 'Maintain'
        WHEN (total_revenue - acquisition_cost) * 100.0 / NULLIF(acquisition_cost, 0) >= 0 THEN 'Optimize'
        ELSE 'Reduce/Stop'
    END AS recommendation
FROM channel_metrics
ORDER BY priority_rank;
```

---

### RFM 세그먼트별 ROI 분석

```sql
WITH segment_value AS (
    SELECT
        u.rfm_segment,
        COUNT(DISTINCT u.id) AS customers,
        SUM(o.total_amount) AS total_revenue,
        COUNT(o.id) AS total_orders
    FROM users u
    LEFT JOIN orders o ON u.id = o.user_id
    WHERE u.rfm_segment IS NOT NULL
    GROUP BY u.rfm_segment
),
segment_cost AS (
    -- 가정: 세그먼트별 마케팅 비용 배분 (실제로는 별도 테이블 필요)
    SELECT
        sv.rfm_segment,
        sv.customers,
        sv.total_revenue,
        sv.total_orders,
        -- 간단히 고객 수 비례로 비용 배분
        ROUND(sv.customers * 1.0 / SUM(sv.customers) OVER () *
            (SELECT SUM(cost) FROM marketing_costs), 0) AS allocated_cost
    FROM segment_value sv
)
SELECT
    rfm_segment AS segment,
    customers,
    total_revenue,
    allocated_cost,
    ROUND((total_revenue - allocated_cost) * 100.0 / NULLIF(allocated_cost, 0), 2) AS roi_pct,
    ROUND(total_revenue / NULLIF(customers, 0), 0) AS revenue_per_customer,
    ROUND(total_orders * 1.0 / NULLIF(customers, 0), 2) AS orders_per_customer,
    RANK() OVER (ORDER BY total_revenue / NULLIF(allocated_cost, 0) DESC) AS efficiency_rank
FROM segment_cost
ORDER BY efficiency_rank;
```

---

### 등급(Grade) + 채널 교차 분석

```sql
WITH cross_segment AS (
    SELECT
        u.grade,
        u.utm_source AS channel,
        COUNT(DISTINCT u.id) AS customers,
        SUM(o.total_amount) AS revenue
    FROM users u
    LEFT JOIN orders o ON u.id = o.user_id
    WHERE u.grade IS NOT NULL AND u.utm_source IS NOT NULL
    GROUP BY u.grade, u.utm_source
)
SELECT
    grade,
    channel,
    customers,
    revenue,
    ROUND(revenue / NULLIF(customers, 0), 0) AS arpu,
    ROUND(customers * 100.0 / SUM(customers) OVER (PARTITION BY channel), 2) AS pct_of_channel,
    ROUND(revenue * 100.0 / SUM(revenue) OVER (PARTITION BY channel), 2) AS revenue_share
FROM cross_segment
ORDER BY channel, revenue DESC;
```

---

### 핵심 포인트

1. **ROI 계산**: (매출 - 비용) / 비용 × 100
2. **LTV:CAC 비율**: 3 이상이면 건강한 비즈니스
3. **채널 귀속**: utm_source로 고객 획득 채널 추적
4. **비용 배분**: 세그먼트별 비용 배분 로직 필요
5. **우선순위화**: ROI 기반 투자 의사결정

---

### 실무 활용

- 마케팅 예산 재배분 의사결정
- 저효율 채널 최적화 또는 중단
- 고효율 세그먼트 타겟팅 강화
- 경영진 리포팅용 ROI 대시보드
