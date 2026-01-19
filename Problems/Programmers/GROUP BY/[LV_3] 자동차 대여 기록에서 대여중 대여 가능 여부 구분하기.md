# [LV_3] 자동차 대여 기록에서 대여중 대여 가능 여부 구분하기

> **정보**
> - **날짜**: 2025년 12월 29일
> - **분류**: 프로그래머스 (LV_3)
> - **주제**: GROUP BY

### 🎯 문제 핵심
**2022년 10월 16일에 대여중인 자동차 OR 아닌 자동차 찾기**

1. 렌트 시작일이 2022년 10월 16일 보다 같거나 앞이고, 렌트 종료일이 2022년 10월 16일 보다 뒤이면 **대여중**
2. `HAVING`은 “이 그룹을 결과에 남길지 말지”만 판단할 뿐, 그 조건(MAX·COUNT 등)에 해당하는 ‘행’을 골라주지는 않는다.
3. 중복 `car_id`가 존재하므로, 조건에 해당하는 것이 1개라도 있는지 찾는 쿼리 필요.
    - 집계하여 대여가능이면 0, 대여중이면 1
    - `GROUP BY` 별로 값에 따라 '대여중' vs '대여 가능' 구분

### 💡 풀이 (CASE 문 중첩)

```sql
SELECT
    car_id,
    CASE
        WHEN SUM(
            CASE
                WHEN START_DATE <= '2022-10-16' AND END_DATE >= '2022-10-16' THEN 1 
                ELSE 0
            END
        ) > 0
        THEN "대여중"
        ELSE "대여 가능"
    END AS AVAILABILITY
FROM
    CAR_RENTAL_COMPANY_RENTAL_HISTORY
GROUP BY
    CAR_ID
ORDER BY
    CAR_ID DESC
```