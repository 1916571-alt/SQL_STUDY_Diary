# [LV_2] 조건에 맞는 도서와 저자 리스트 출력하기

> **정보**
> - **날짜**: 2026년 1월 20일
> - **분류**: 프로그래머스 (LV_2)
> - **주제**: JOIN

### 문제 핵심
**경제 카테고리 도서의 도서ID, 저자명, 출판일을 출판일 기준 오름차순으로 조회**

1. BOOK 테이블과 AUTHOR 테이블을 AUTHOR_ID로 JOIN
2. 경제 카테고리 필터링
3. DATE_FORMAT으로 출판일 포맷 변환

### 풀이

```sql
SELECT B.BOOK_ID,
       A.AUTHOR_NAME,
       DATE_FORMAT(B.PUBLISHED_DATE,"%Y-%m-%d") AS PUBLISHED_DATE
FROM BOOK B
JOIN AUTHOR A
    ON B.AUTHOR_ID = A.AUTHOR_ID
WHERE CATEGORY = "경제"
ORDER BY PUBLISHED_DATE
```
