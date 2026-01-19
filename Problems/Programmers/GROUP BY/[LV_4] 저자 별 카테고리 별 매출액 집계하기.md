# [LV_4] 저자 별 카테고리 별 매출액 집계하기

> **정보**
> - **날짜**: 2025년 12월 30일
> - **분류**: 프로그래머스 (LV_4)
> - **주제**: GROUP BY

### 🎯 문제 핵심
**2022년 1월 판매 데이터 기준, 저자별/카테고리별 매출액 집계**

1. **테이블 조인**: `BOOK_SALES` (매출), `BOOK` (책 정보), `AUTHOR` (저자 정보) 연결 필요.
2. **필터링**: 2022년 1월 데이터 (`2022-01`)만 대상.
3. **계산**: `매출액 = 판매량 * 판매가`.
4. **집계**: 저자 ID와 카테고리별로 매출액 합계(`SUM`).
5. **정렬**: 저자 ID 오름차순, 카테고리 내림차순.

### 💡 풀이

```sql
WITH
  BASE AS (
    SELECT
      B.BOOK_ID,
      B.CATEGORY,
      B.AUTHOR_ID,
      B.PRICE,
      BS.SALES,
      B.PRICE * BS.SALES AS TOTAL_SALES
    FROM
      BOOK_SALES AS BS
      JOIN BOOK AS B ON BS.BOOK_ID = B.BOOK_ID
    WHERE
      DATE_FORMAT(BS.SALES_DATE, "%Y-%m") = '2022-01'
  )
SELECT
  B.AUTHOR_ID,
  A.AUTHOR_NAME,
  B.category,
  SUM(B.TOTAL_SALES) AS TOTAL_SALES
FROM
  BASE B
  JOIN AUTHOR A ON B.AUTHOR_ID = A.AUTHOR_ID
GROUP BY
  B.AUTHOR_ID,
  B.category
ORDER BY
  B.AUTHOR_ID,
  B.CATEGORY DESC
```
