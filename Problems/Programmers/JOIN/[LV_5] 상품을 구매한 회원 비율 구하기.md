# [LV_5] 상품을 구매한 회원 비율 구하기

> **정보**
> - **날짜**: 2026년 1월 20일
> - **분류**: 프로그래머스 (LV_5)
> - **주제**: JOIN

### 문제 핵심
**2021년 가입 회원 중 상품 구매 회원수와 비율을 년/월별로 출력**

1. 2021년 가입한 전체 회원 수를 CTE로 먼저 계산
2. ONLINE_SALE과 USER_INFO를 JOIN
3. 2021년 가입 회원만 필터링
4. 년/월별 구매 회원 수(DISTINCT)와 비율 계산
5. CROSS JOIN으로 전체 회원 수를 각 행에 붙이기

### 풀이

```sql
WITH JOIN_member AS
(
SELECT COUNT(*) as joinmem
FROM USER_INFO
WHERE YEAR(joined) = 2021
)
SELECT YEAR(SALES_DATE) AS YEAR,
       MONTH(SALES_DATE) AS MONTH,
       COUNT(DISTINCT(os.USER_ID)) AS PURCHASED_USERS,
       ROUND(COUNT(DISTINCT(os.USER_ID))/jm.joinmem,1) AS PUCHASED_RATIO
FROM ONLINE_SALE os
JOIN USER_INFO ui
    ON os.user_id = ui.user_id
CROSS JOIN JOIN_member jm
WHERE YEAR(ui.joined) = 2021
GROUP BY YEAR(SALES_DATE), MONTH(SALES_DATE)
ORDER BY YEAR, MONTH
```

### 핵심 패턴
- CTE + CROSS JOIN으로 전체 대비 비율 계산
- COUNT(DISTINCT)로 중복 제거
