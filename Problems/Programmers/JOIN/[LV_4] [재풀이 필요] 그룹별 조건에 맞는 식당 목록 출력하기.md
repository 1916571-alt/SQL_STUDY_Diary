# [LV_4] 그룹별 조건에 맞는 식당 목록 출력하기

> **정보**
> - **날짜**: 2026년 1월 20일
> - **분류**: 프로그래머스 (LV_4)
> - **주제**: JOIN
> - **재풀이**: 필요

### 문제 핵심
**리뷰를 가장 많이 작성한 회원의 모든 리뷰 조회**

1. 먼저 회원별 리뷰 수를 집계하고 RANK()로 순위 매기기
2. 1위 회원의 MEMBER_ID를 찾은 후
3. 해당 회원의 모든 리뷰를 JOIN으로 가져오기
4. 리뷰 작성일, 리뷰 텍스트 순으로 정렬

### 풀이

```sql
WITH rank_base AS(
SELECT MEMBER_ID,
       COUNT(*) AS review_num,
       RANK() OVER (ORDER BY COUNT(*) DESC) AS rnk
FROM REST_REVIEW
GROUP BY MEMBER_ID
)
SELECT mp.MEMBER_NAME,
       REVIEW_TEXT,
       DATE_FORMAT(REVIEW_DATE,"%Y-%m-%d") AS REVIEW_DATE
FROM rank_base rb
JOIN MEMBER_PROFILE mp
    ON rb.MEMBER_ID = mp.member_id
JOIN REST_REVIEW rr
    ON mp.MEMBER_ID = rr.MEMBER_ID
WHERE rnk = 1
ORDER BY REVIEW_DATE, REVIEW_TEXT
```

### 복습 포인트
- RANK() 윈도우 함수 활용
- CTE로 먼저 순위를 구한 뒤 다시 JOIN하는 패턴
