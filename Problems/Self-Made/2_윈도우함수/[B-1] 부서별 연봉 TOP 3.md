# 부서별 연봉 TOP 3

> **정보**
> - **날짜**: 2026년 01월 21일
> - **분류**: Self-Made (B-1)
> - **주제**: 윈도우 함수 - DENSE_RANK + PARTITION
> - **난이도**: ★★
> - **재풀이 여부**: X

---

### 문제 설명

부서별로 연봉이 높은 상위 3명을 출력하세요.

**테이블**: employees, departments

**출력**: department_name | employee_name | salary | rank

---

### 정답 풀이

```sql
WITH base AS (
    SELECT
        name,
        dept_id,
        salary,
        RANK() OVER (PARTITION BY dept_id ORDER BY salary DESC) AS rnk
    FROM employees
)
SELECT
    d.name AS department_name,
    b.name AS employee_name,
    salary,
    rnk
FROM base b
JOIN departments d ON b.dept_id = d.id
WHERE rnk <= 3;
```

---

### 핵심 포인트

1. **PARTITION BY**: 부서별로 그룹을 나눠서 순위 부여
2. **RANK vs DENSE_RANK**: 동점자 처리 방식 차이
3. **WHERE rnk <= 3**: CTE에서 순위 계산 후 메인에서 필터링
