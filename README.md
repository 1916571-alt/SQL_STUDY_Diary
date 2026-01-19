# SQL Study Diary

데이터 분석 및 SQL 코딩테스트 준비를 위한 학습 기록 저장소입니다.

## Core Skills

| 영역 | 상세 |
|------|------|
| **기본 문법** | JOIN (INNER/LEFT/RIGHT/SELF), GROUP BY, HAVING, Subquery |
| **윈도우 함수** | ROW_NUMBER, RANK, DENSE_RANK, LAG, LEAD, SUM OVER |
| **비즈니스 지표** | 코호트 리텐션, User Type 분류, LTV, CAC, ROAS, RFM 분석 |
| **데이터 처리** | 날짜 함수, 문자열 처리, NULL 핸들링, 피벗 테이블 |

---

## Repository Structure

```
├── Problems/           # 플랫폼별 문제 풀이
│   ├── Programmers/    # 프로그래머스 SQL (LV1~LV5)
│   ├── LeetCode/       # LeetCode Database
│   ├── HackerRank/     # HackerRank SQL
│   └── Solve_SQL_2025/ # SolveSQL
│
├── Concepts/           # SQL 개념 정리
│   └── Subquery_vs_CTE.md
│
└── Curriculum/         # 코딩테스트 심화 커리큘럼
    ├── SQL_CodingTest_Advanced_Curriculum.md  # 학습 커리큘럼
    └── SQL_Practice_Solutions.md              # 52문제 정답 및 해설
```

---

## Practice Problems (52 Problems)

실무에서 자주 사용되는 SQL 패턴을 유형별로 정리했습니다.

| 유형 | 문제 수 | 주요 내용 |
|------|---------|----------|
| **A. JOIN + 집계** | 8 | 다중 테이블 조인, 채널별 분석, 재구매율 |
| **B. 윈도우 함수 (순위)** | 7 | TOP N 추출, 그룹별 순위, 중앙값 |
| **C. 윈도우 함수 (집계)** | 7 | 누적합, 전월 대비, 이동평균 |
| **D. 코호트/리텐션** | 6 | 월별 코호트, User Type, LTV |
| **E. 날짜/문자열** | 4 | 연령대 분석, 요일별 패턴 |
| **F. 복합 실전** | 5 | RFM 분석, 퍼널 분석, A/B 테스트 |
| **G. 그로스해킹** | 12 | CAC, ROAS, 구매주기, CRM 캠페인 |
| **X. 고급** | 3 | 연속일 분석, 세션 분석, 계층 구조 |

> 모든 문제는 MySQL 8.0 기준이며, 로컬 환경에서 테스트 완료되었습니다.

---

## Key Highlights

### 1. 비즈니스 지표 SQL 구현

```sql
-- 코호트 리텐션: 가입 월 기준 월별 잔존율
WITH cohort AS (
    SELECT user_id, DATE_FORMAT(created_at, '%Y-%m') AS cohort_month FROM users
),
monthly_orders AS (
    SELECT DISTINCT user_id, DATE_FORMAT(order_datetime, '%Y-%m') AS order_month FROM orders
)
SELECT cohort_month, months_since_signup, COUNT(DISTINCT user_id) AS active_users
FROM cohort c JOIN monthly_orders m ON c.user_id = m.user_id
GROUP BY cohort_month, months_since_signup;
```

### 2. 윈도우 함수 활용

```sql
-- 고객별 구매 주기 분석
SELECT user_id,
       AVG(DATEDIFF(order_datetime,
           LAG(order_datetime) OVER (PARTITION BY user_id ORDER BY order_datetime)
       )) AS avg_purchase_interval
FROM orders GROUP BY user_id;
```

### 3. User Type 분류 (New / Current / Resurrected)

```sql
-- MAU를 유저 타입별로 분류
SELECT ym,
    SUM(CASE WHEN ym = first_month THEN 1 ELSE 0 END) AS new_users,
    SUM(CASE WHEN prev_month = last_month THEN 1 ELSE 0 END) AS current_users,
    SUM(CASE WHEN prev_month < last_month THEN 1 ELSE 0 END) AS resurrected_users
FROM user_activity GROUP BY ym;
```

---

## Problem Solving Log

### Programmers SQL

> 상세 풀이는 [Problems/Programmers](./Problems/Programmers) 참조

---

## Review Queue (재풀이 필요)

다시 복습이 필요한 문제들입니다.

| 난이도 | 유형 | 문제명 | 핵심 포인트 |
|--------|------|--------|-------------|
| **LV5** | JOIN | [상품을 구매한 회원 비율 구하기](./Problems/Programmers/JOIN/%5BLV_5%5D%20%5B%EC%9E%AC%ED%92%80%EC%9D%B4%20%ED%95%84%EC%9A%94%5D%20%EC%83%81%ED%92%88%EC%9D%84%20%EA%B5%AC%EB%A7%A4%ED%95%9C%20%ED%9A%8C%EC%9B%90%20%EB%B9%84%EC%9C%A8%20%EA%B5%AC%ED%95%98%EA%B8%B0.md) | 복합 JOIN + 비율 계산 |
| **LV4** | GROUP BY | [입양 시각 구하기(2)](./Problems/Programmers/GROUP%20BY/%5BLV_4%5D%20%5B%EC%9E%AC%ED%92%80%EC%9D%B4%20%ED%95%84%EC%9A%94%5D%20%EC%9E%85%EC%96%91%20%EC%8B%9C%EA%B0%81%20%EA%B5%AC%ED%95%98%EA%B8%B0%282%29.md) | 연속 숫자 생성 + LEFT JOIN |
| **LV4** | SELECT | [오프라인-온라인 판매 데이터 통합하기](./Problems/Programmers/SELECT/%5BLV_4%5D%20%5B%EC%9E%AC%ED%92%80%EC%9D%B4%20%ED%95%84%EC%9A%94%5D%20%EC%98%A4%ED%94%84%EB%9D%BC%EC%9D%B8-%EC%98%A8%EB%9D%BC%EC%9D%B8%20%ED%8C%90%EB%A7%A4%20%EB%8D%B0%EC%9D%B4%ED%84%B0%20%ED%86%B5%ED%95%A9%ED%95%98%EA%B8%B0.md) | UNION ALL + 날짜 처리 |
| **LV3** | IS NULL | [업그레이드 할 수 없는 아이템 구하기](./Problems/Programmers/IS%20NULL/%5BLV_3%5D%20%5B%EC%9E%AC%ED%92%80%EC%9D%B4%20%ED%95%84%EC%9A%94%5D%20%EC%97%85%EA%B7%B8%EB%A0%88%EC%9D%B4%EB%93%9C%20%ED%95%A0%20%EC%88%98%20%EC%97%86%EB%8A%94%20%EC%95%84%EC%9D%B4%ED%85%9C%20%EA%B5%AC%ED%95%98%EA%B8%B0.md) | NOT IN / NOT EXISTS |

---

## Tech Stack

- **Database**: MySQL 8.0, MariaDB
- **Tools**: VSCode + SQLTools, XAMPP, DB Fiddle
- **Concepts**: Window Functions, CTEs, Subqueries, Date Functions

---

## References

- [Programmers SQL 고득점 Kit](https://school.programmers.co.kr/learn/challenges?tab=sql_practice_kit)
- [LeetCode SQL Study Plan](https://leetcode.com/study-plan/sql/)
- [SolveSQL](https://solvesql.com/)

---

<details>
<summary><b>Local Development Setup</b></summary>

### XAMPP MySQL 환경 설정

1. XAMPP Control Panel → MySQL Start
2. VSCode SQLTools로 연결
3. `XAMPP MySQL.session.sql` 실행하여 샘플 데이터 로드

**테이블 구성**: users, stores, products, orders, order_items, app_logs, marketing_costs, campaigns 등 11개 테이블

</details>
