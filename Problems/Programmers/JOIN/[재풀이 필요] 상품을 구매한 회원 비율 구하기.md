# [LV_5] [재풀이 필요] 상품을 구매한 회원 비율 구하기

> **정보**
> - **날짜**: 2026년 1월 19일
> - **분류**: 프로그래머스 (LV_5)
> - **주제**: JOIN
> - **재풀이 여부**: O

### ✨ 핵심 포인트
- **CROSS JOIN**은 조인 조건 없이 모든 행을 곱해서, ‘고정 값이나 모든 경우의 수’를 만들 때 쓰는 JOIN이다.

### 🎯 문제 설명

다음은 어느 의류 쇼핑몰에 가입한 회원 정보를 담은 `USER_INFO` 테이블과 온라인 상품 판매 정보를 담은 `ONLINE_SALE` 테이블 입니다. `USER_INFO` 테이블은 아래와 같은 구조로 되어있으며 `USER_ID`, `GENDER`, `AGE`, `JOINED`는 각각 회원 ID, 성별, 나이, 가입일을 나타냅니다.

| Column name | Type | Nullable |
| --- | --- | --- |
| USER_ID | INTEGER | FALSE |
| GENDER | TINYINT(1) | TRUE |
| AGE | INTEGER | TRUE |
| JOINED | DATE | FALSE |

`GENDER` 컬럼은 비어있거나 0 또는 1의 값을 가지며 0인 경우 남자를, 1인 경우는 여자를 나타냅니다.

`ONLINE_SALE` 테이블은 아래와 같은 구조로 되어있으며 `ONLINE_SALE_ID`, `USER_ID`, `PRODUCT_ID`, `SALES_AMOUNT`, `SALES_DATE`는 각각 온라인 상품 판매 ID, 회원 ID, 상품 ID, 판매량, 판매일을 나타냅니다.

| Column name | Type | Nullable |
| --- | --- | --- |
| ONLINE_SALE_ID | INTEGER | FALSE |
| USER_ID | INTEGER | FALSE |
| PRODUCT_ID | INTEGER | FALSE |
| SALES_AMOUNT | INTEGER | FALSE |
| SALES_DATE | DATE | FALSE |

동일한 날짜, 회원 ID, 상품 ID 조합에 대해서는 하나의 판매 데이터만 존재합니다.

---

### 문제

`USER_INFO` 테이블과 `ONLINE_SALE` 테이블에서 2021년에 가입한 전체 회원들 중 상품을 구매한 회원수와 상품을 구매한 회원의 비율(=2021년에 가입한 회원 중 상품을 구매한 회원수 / 2021년에 가입한 전체 회원 수)을 년, 월 별로 출력하는 SQL문을 작성해주세요. 상품을 구매한 회원의 비율은 소수점 두번째자리에서 반올림하고, 전체 결과는 년을 기준으로 오름차순 정렬해주시고 년이 같다면 월을 기준으로 오름차순 정렬해주세요.

---

### 💡 풀이 과정
- **2021년에 가입한 전체 회원 수**를 먼저 구해야 함 (분모).
- 이를 위해 `WITH` 절을 사용하여 2021년 가입 회원과 그 총 수를 정의.
- `ONLINE_SALE`과 조인하여 구매한 회원 수를 집계.
- 전체 회원 수(`total_users`)는 모든 행에 동일하게 적용되어야 하므로 `CROSS JOIN`을 사용.

```sql
WITH JOIN_USER AS (
  SELECT
    USER_ID
  FROM USER_INFO
  WHERE
    YEAR(JOINED) = 2021
),
TOTAL AS (
  SELECT
    COUNT(*) AS TOTAL_USERS
  FROM JOIN_USER
)
SELECT
  YEAR(OS.SALES_DATE) AS YEAR,
  MONTH(OS.SALES_DATE) AS MONTH,
  COUNT(DISTINCT OS.USER_ID) AS PURCHASED_USERS,
  ROUND(COUNT(DISTINCT OS.USER_ID) / TOTAL.TOTAL_USERS, 1) AS PURCHASED_RATIO
FROM ONLINE_SALE OS
JOIN JOIN_USER JU
  ON OS.USER_ID = JU.USER_ID
CROSS JOIN TOTAL
GROUP BY
  YEAR(OS.SALES_DATE),
  MONTH(OS.SALES_DATE)
ORDER BY
  YEAR,
  MONTH;
```
