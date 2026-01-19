# [LV_4] 연간 평가점수에 해당하는 평가 등급 및 성과금 조회하기

> **정보**
> - **날짜**: 2026년 1월 19일
> - **분류**: 프로그래머스 (LV_4)
> - **주제**: GROUP BY
> - **재풀이 여부**: X

### 🎯 문제 설명

`HR_DEPARTMENT` 테이블은 회사의 부서 정보를 담은 테이블입니다. `HR_DEPARTMENT` 테이블의 구조는 다음과 같으며 `DEPT_ID`, `DEPT_NAME_KR`, `DEPT_NAME_EN`, `LOCATION`은 각각 부서 ID, 국문 부서명, 영문 부서명, 부서 위치를 의미합니다.

| Column name | Type | Nullable |
| --- | --- | --- |
| DEPT_ID | VARCHAR | FALSE |
| DEPT_NAME_KR | VARCHAR | FALSE |
| DEPT_NAME_EN | VARCHAR | FALSE |
| LOCATION | VARCHAR | FLASE |

`HR_EMPLOYEES` 테이블은 회사의 사원 정보를 담은 테이블입니다. `HR_EMPLOYEES` 테이블의 구조는 다음과 같으며 `EMP_NO`, `EMP_NAME`, `DEPT_ID`, `POSITION`, `EMAIL`, `COMP_TEL`, `HIRE_DATE`, `SAL`은 각각 사번, 성명, 부서 ID, 직책, 이메일, 전화번호, 입사일, 연봉을 의미합니다.

| Column name | Type | Nullable |
| --- | --- | --- |
| EMP_NO | VARCHAR | FALSE |
| EMP_NAME | VARCHAR | FALSE |
| DEPT_ID | VARCHAR | FALSE |
| POSITION | VARCHAR | FALSE |
| EMAIL | VARCHAR | FALSE |
| COMP_TEL | VARCHAR | FALSE |
| HIRE_DATE | DATE | FALSE |
| SAL | NUMBER | FALSE |

`HR_GRADE` 테이블은 2022년 사원의 평가 정보를 담은 테이블입니다. `HR_GRADE`의 구조는 다음과 같으며 `EMP_NO`, `YEAR`, `HALF_YEAR`, `SCORE`는 각각 사번, 연도, 반기, 평가 점수를 의미합니다.

| Column name | Type | Nullable |
| --- | --- | --- |
| EMP_NO | VARCHAR | FALSE |
| YEAR | NUMBER | FALSE |
| HALF_YEAR | NUMBER | FALSE |
| SCORE | NUMBER | FALSE |

---

### 문제

`HR_DEPARTMENT`, `HR_EMPLOYEES`, `HR_GRADE` 테이블을 이용해 사원별 성과금 정보를 조회하려합니다. 평가 점수별 등급과 등급에 따른 성과금 정보가 아래와 같을 때, 사번, 성명, 평가 등급, 성과금을 조회하는 SQL문을 작성해주세요.

평가등급의 컬럼명은 `GRADE`로, 성과금의 컬럼명은 `BONUS`로 해주세요.

결과는 사번 기준으로 오름차순 정렬해주세요.

| 기준 점수 | 평가 등급 | 성과금(연봉 기준) |
| --- | --- | --- |
| 96 이상 | S | 20% |
| 90 이상 | A | 15% |
| 80 이상 | B | 10% |
| 이외 | C | 0% |

---

### 💡 풀이 과정
- 사원별 평균 평가 점수를 구하기 위해 `GROUP BY EMP_NO`.
- `CASE` 문을 사용하여 점수에 따른 등급(`GRADE`)과 성과금(`BONUS`)을 계산.
- 연봉(`SAL`)에 따른 비율을 곱하여 최종 성과금을 산출.

```sql
WITH BASE AS (
  SELECT
    HE.EMP_NO,
    HE.EMP_NAME,
    AVG(HE.SAL) AS AVG_SAL,
    AVG(HG.SCORE) AS AVG_SCORE
  FROM HR_EMPLOYEES HE
  JOIN HR_GRADE HG
    ON HE.EMP_NO = HG.EMP_NO
  GROUP BY
    HE.EMP_NO
)
SELECT
  EMP_NO,
  EMP_NAME,
  CASE
    WHEN AVG_SCORE >= 96 THEN 'S'
    WHEN AVG_SCORE >= 90 THEN 'A'
    WHEN AVG_SCORE >= 80 THEN 'B'
    ELSE 'C'
  END AS GRADE,
  CASE
    WHEN AVG_SCORE >= 96 THEN AVG_SAL * 0.2
    WHEN AVG_SCORE >= 90 THEN AVG_SAL * 0.15
    WHEN AVG_SCORE >= 80 THEN AVG_SAL * 0.1
    ELSE 0
  END AS BONUS
FROM BASE
ORDER BY
  EMP_NO;
```
