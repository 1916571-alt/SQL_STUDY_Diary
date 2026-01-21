# RFM 분석

> **정보**
> - **날짜**: 2026년 01월 21일
> - **분류**: Self-Made (F-2)
> - **주제**: R/F/M 점수화
> - **난이도**: ★★★★
> - **재풀이 여부**: X

---

### 문제 설명

RFM 점수 기반으로 고객을 세분화하세요.
- R (Recency): 최근 구매일
- F (Frequency): 구매 빈도
- M (Monetary): 구매 금액

**테이블**: orders

**출력**: user_id | recency | frequency | monetary | r_score | f_score | m_score | rfm_segment | customer_segment

---

### 정답 풀이

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
    SELECT
        user_id,
        recency,
        frequency,
        monetary,
        NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency) AS f_score,
        NTILE(5) OVER (ORDER BY monetary) AS m_score
    FROM rfm_base
)
SELECT
    user_id,
    recency,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    CONCAT(r_score, f_score, m_score) AS rfm_segment,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 4 AND f_score >= 3 THEN 'Loyal Customers'
        WHEN r_score >= 4 AND f_score <= 2 THEN 'New Customers'
        WHEN r_score >= 3 AND f_score >= 3 THEN 'Potential Loyalists'
        WHEN r_score <= 2 AND f_score >= 4 THEN 'At Risk'
        WHEN r_score <= 2 AND f_score <= 2 THEN 'Lost'
        ELSE 'Others'
    END AS customer_segment
FROM rfm_scores
ORDER BY r_score DESC, f_score DESC, m_score DESC;
```

---

### 핵심 포인트

1. **NTILE(5)**: 5분위로 나누어 1~5점 부여
2. **R 점수 정렬**: recency는 낮을수록(최근) 좋으므로 DESC 정렬
3. **세그먼트 분류**: RFM 조합으로 고객 유형 정의 (Champions, At Risk 등)
