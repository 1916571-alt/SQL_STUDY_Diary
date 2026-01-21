# CRM 캠페인 성과

> **정보**
> - **날짜**: 2026년 01월 21일
> - **분류**: Self-Made (G-6)
> - **주제**: 오픈/클릭/전환율
> - **난이도**: ★★★
> - **재풀이 여부**: X

---

### 문제 설명

캠페인별 오픈율, 클릭율, 전환율을 계산하세요.

**테이블**: campaigns, campaign_sends, campaign_opens, campaign_clicks

**출력**: campaign_name | total_sent | total_opened | open_rate | total_clicked | click_rate | click_to_open_rate

---

### 정답 풀이

```sql
WITH campaign_metrics AS (
    SELECT
        c.id AS campaign_id,
        c.name AS campaign_name,
        COUNT(DISTINCT cs.id) AS total_sent,
        COUNT(DISTINCT co.id) AS total_opened,
        COUNT(DISTINCT cc.id) AS total_clicked
    FROM campaigns c
    LEFT JOIN campaign_sends cs ON c.id = cs.campaign_id
    LEFT JOIN campaign_opens co ON cs.id = co.send_id
    LEFT JOIN campaign_clicks cc ON cs.id = cc.send_id
    GROUP BY c.id, c.name
)
SELECT
    campaign_name,
    total_sent,
    total_opened,
    ROUND(total_opened * 100.0 / NULLIF(total_sent, 0), 2) AS open_rate,
    total_clicked,
    ROUND(total_clicked * 100.0 / NULLIF(total_sent, 0), 2) AS click_rate,
    ROUND(total_clicked * 100.0 / NULLIF(total_opened, 0), 2) AS click_to_open_rate
FROM campaign_metrics
ORDER BY open_rate DESC;
```

---

### 핵심 포인트

1. **오픈율**: 오픈 수 / 발송 수 × 100
2. **클릭율 (CTR)**: 클릭 수 / 발송 수 × 100
3. **CTOR**: 클릭 수 / 오픈 수 × 100 (컨텐츠 품질 지표)
