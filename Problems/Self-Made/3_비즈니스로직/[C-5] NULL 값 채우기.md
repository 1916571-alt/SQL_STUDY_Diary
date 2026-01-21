# NULL 값 채우기

> **정보**
> - **날짜**: 2026년 01월 21일
> - **분류**: Self-Made (C-5)
> - **주제**: 윈도우 함수 - Forward Fill
> - **난이도**: ★★★
> - **재풀이 여부**: X

---

### 문제 설명

주가 데이터에서 NULL 값을 직전 유효 값으로 채우세요 (Forward Fill).

**테이블**: stock_prices (price_date, price)

**출력**: price_date | original_price | filled_price

---

### 정답 풀이

```sql
WITH numbered AS (
    SELECT
        price_date,
        price,
        SUM(CASE WHEN price IS NOT NULL THEN 1 ELSE 0 END)
            OVER (ORDER BY price_date) AS grp
    FROM stock_prices
)
SELECT
    price_date,
    price AS original_price,
    FIRST_VALUE(price) OVER (PARTITION BY grp ORDER BY price_date) AS filled_price
FROM numbered
ORDER BY price_date;
```

---

### 핵심 포인트

1. **그룹 번호 부여**: NULL이 아닌 값이 나올 때마다 그룹 번호 증가
2. **FIRST_VALUE**: 각 그룹의 첫 번째 값(NULL이 아닌 값)을 모든 행에 적용
3. **Forward Fill 패턴**: 시계열 데이터에서 결측값 처리의 표준 방법
