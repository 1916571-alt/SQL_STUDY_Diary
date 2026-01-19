# [LV_4] 식품분류별 가장 비싼 식품의 정보 조회하기

> **정보**
> - **날짜**: 2026년 1월 1일
> - **분류**: 프로그래머스 (LV_4)
> - **주제**: GROUP BY

### 🎯 문제 핵심
**식품분류별로 가격이 제일 비싼 식품의 분류, 가격, 이름 조회하기**

1. `FOOD_PRODUCT` 테이블에서 식품분류가 '과자', '국', '김치', '식용유' 인 경우만 골라내야 함.
2. 분류별로 가장 비싼 가격을 찾아야 함.
3. 해당 가격을 가진 행을 찾아 출력해야 함.

### 💡 풀이 (WITH절 사용)

```sql
WITH
  ca_list AS (
    SELECT
      CATEGORY,
      PRICE,
      PRODUCT_NAME
    FROM
      FOOD_PRODUCT
    WHERE
      CATEGORY IN ("과자", "국", "김치", "식용유")
  ),
  MAX_LIST AS (
    SELECT
      CATEGORY,
      MAX(PRICE) AS MAX_PRICE
    FROM
      ca_list
    GROUP BY
      CATEGORY
  )
SELECT
  c.CATEGORY,
  c.PRICE AS MAX_PRICE,
  c.PRODUCT_NAME
FROM
  ca_list c
  JOIN MAX_LIST m ON c.CATEGORY = m.CATEGORY
  AND c.PRICE = m.MAX_PRICE
ORDER BY
  c.PRICE DESC
```
