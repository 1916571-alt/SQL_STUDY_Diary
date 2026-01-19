# [LV_4] 식품분류별 가장 비싼 식품의 정보 조회하기

> **정보**
> - **날짜**: 2026년 1월 19일
> - **분류**: 프로그래머스 (LV_4)
> - **주제**: GROUP BY
> - **재풀이 여부**: X

### 🎯 문제 설명

다음은 식품의 정보를 담은 `FOOD_PRODUCT` 테이블입니다. `FOOD_PRODUCT` 테이블은 다음과 같으며 `PRODUCT_ID`, `PRODUCT_NAME`, `PRODUCT_CD`, `CATEGORY`, `PRICE`는 식품 ID, 식품 이름, 식품코드, 식품분류, 식품 가격을 의미합니다.

| Column name | Type | Nullable |
| --- | --- | --- |
| PRODUCT_ID | VARCHAR(10) | FALSE |
| PRODUCT_NAME | VARCHAR(50) | FALSE |
| PRODUCT_CD | VARCHAR(10) | TRUE |
| CATEGORY | VARCHAR(10) | TRUE |
| PRICE | NUMBER | TRUE |

---

### 문제

`FOOD_PRODUCT` 테이블에서 식품분류별로 가격이 제일 비싼 식품의 분류, 가격, 이름을 조회하는 SQL문을 작성해주세요. 이때 식품분류가 '과자', '국', '김치', '식용유'인 경우만 출력시켜 주시고 결과는 식품 가격을 기준으로 내림차순 정렬해주세요.

---

### 💡 풀이 과정
- 특정 카테고리('과자', '국', '김치', '식용유')에 대해서만 필터링.
- 각 카테고리별 최대 가격을 `WITH` 절로 구함.
- 원본 데이터와 조인하여 해당 카테고리와 최대 가격을 가진 상품명을 가져옴.

```sql
WITH BASE AS (
  SELECT
    PRODUCT_NAME,
    CATEGORY,
    PRICE
  FROM FOOD_PRODUCT
  WHERE
    CATEGORY IN ('과자', '국', '김치', '식용유')
),
MAX_PRODUCT AS (
  SELECT
    CATEGORY,
    MAX(PRICE) AS MAX_PRICE
  FROM BASE
  GROUP BY
    CATEGORY
)
SELECT
  B.CATEGORY,
  M.MAX_PRICE,
  B.PRODUCT_NAME
FROM BASE B
JOIN MAX_PRODUCT M
  ON B.CATEGORY = M.CATEGORY
  AND B.PRICE = M.MAX_PRICE
ORDER BY
  M.MAX_PRICE DESC;
```
