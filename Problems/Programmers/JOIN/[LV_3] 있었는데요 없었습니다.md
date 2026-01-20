# [LV_3] 있었는데요 없었습니다

> **정보**
> - **날짜**: 2026년 1월 20일
> - **분류**: 프로그래머스 (LV_3)
> - **주제**: JOIN

### 문제 핵심
**보호 시작일보다 입양일이 더 빠른 동물 찾기 (데이터 오류)**

1. ANIMAL_INS와 ANIMAL_OUTS를 INNER JOIN
2. 보호 시작일(INS.DATETIME) > 입양일(OUTS.DATETIME)인 경우 필터링
3. 보호 시작일 기준 오름차순 정렬

### 풀이

```sql
SELECT ai.ANIMAL_ID,
       ai.NAME
FROM ANIMAL_INS ai
JOIN ANIMAL_OUTS ao
    ON ai.ANIMAL_ID = ao.ANIMAL_ID
WHERE ai.DATETIME > ao.DATETIME
ORDER BY ai.DATETIME
```

### 핵심 패턴
- JOIN 후 날짜 비교로 데이터 오류 검출
