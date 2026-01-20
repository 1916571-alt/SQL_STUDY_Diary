# [LV_3] 즐겨찾기가 가장 많은 식당 정보 출력하기

> **정보**
> - **날짜**: 2026년 1월 20일
> - **분류**: 프로그래머스 (LV_3)
> - **주제**: GROUP BY

### 문제 핵심
**음식종류별로 즐겨찾기수가 가장 많은 식당 조회**

1. PARTITION BY FOOD_TYPE으로 음식종류별 그룹화
2. RANK()로 즐겨찾기 수 기준 순위 매기기
3. 순위가 1인 행만 필터링
4. 음식 종류 기준 내림차순 정렬

### 풀이

```sql
WITH base AS(
SELECT FOOD_TYPE,
       REST_ID,
       REST_NAME,
       FAVORITES,
       RANK() OVER (PARTITION BY FOOD_TYPE ORDER BY FAVORITES DESC) AS rnk
FROM REST_INFO
)
SELECT FOOD_TYPE, REST_ID, REST_NAME, FAVORITES
FROM base
WHERE rnk = 1
ORDER BY FOOD_TYPE DESC
```

### 핵심 패턴
- RANK() + PARTITION BY로 그룹별 TOP 1 추출
