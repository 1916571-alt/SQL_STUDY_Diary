# [백문이불여일타] 데이터 분석을 위한 고급 SQL

진행 상태: 완료
마감일: 2025년 8월 8일
프로젝트: (공부) SQL (https://www.notion.so/SQL-232be5e372b080098162cd2246c78034?pvs=21)

https://leetcode.com/problemset/database/

[https://solvesql.com/problems/find-christmas-games/](https://solvesql.com/problems/find-christmas-games/)

[h](https://www.w3schools.com/mysql/trymysql.asp?filename=trysql_select_limit)https://www.hackerrank.com/domains/sql?filters%5Bsubdomains%5D%5B%5D=aggregation

---

[https://datarian.io/blog/sql-post-collection](https://datarian.io/blog/sql-post-collection)  → 

정규표현식

튜토리얼 : [https://regexone.com/lesson/letters_and_digits](https://regexone.com/lesson/letters_and_digits)?

테스트 : [https://regexr.com/](https://regexr.com/)

![image.png](image.png)

```
SELECT D.name AS departmentID, E.name AS Employee, E.Salary
FROM Employee E
INNER JOIN Department D
ON E.departmentId = D.id
group by departmentID
Having E.salary IN (SELECT max(E.Salary) from employee E
                   INNER JOIN Department D
                    ON E.departmentId = D.id
                    group by departmentID)
```

HAVING을 이렇게 하면 → 부서별로 한 명만 남기 때문에 동률의 경우 누군지 알 수 없게 됨.

```
SELECT D.name AS Department, E.name AS Employee, E.Salary
FROM Employee E
JOIN Department D ON E.departmentId = D.id
WHERE E.salary = (
    SELECT MAX(E2.salary)
    FROM Employee E2
    WHERE E2.departmentId = E.departmentId
);

이렇게 해야지 동률인 애도 나오게 됨.
조인 -> 서브쿼리 로직의 개념 차이임.
애네들은
1. 조인된 데이터에서 -> 특정 직원을 뽑음
2. 특정 직원이 속한 부서명을 조인을 통해 추출했고 -> 그 안에서, MAX 값을 찾는 로직임
3. 즉, 특정 직원이 속한 부서에서의 MAX SALARY를 찾는다.
4. 이 과정이 끝나면 다음 직원을 대상으로 찾겠지.  
문제 : https://leetcode.com/problems/department-highest-salary/description/
```

---

1. **Challenges - 해커랭**

[https://www.hackerrank.com/challenges/challenges/problem?isFullScreen=true](https://www.hackerrank.com/challenges/challenges/problem?isFullScreen=true)

단계별 생각 → 처음부터 이으려고 하지말 것. 해야되는 단계를 생각하고 차례대로 구현하여 연합시키는 방법으로 해볼자.

```
with sub AS  (
    SELECT h.hacker_id, h.name,count(*) AS cnt
    from Hackers h INNER JOIN Challenges c ON             h.hacker_id = c.hacker_id
group by h.hacker_id, h.name
),
sub2 AS(
select sub.cnt, count(*) as cnt2
from sub
GROUP BY sub.cnt
),
sub3 AS(
SELECT max(sub2.cnt) AS max_cnt, count(*)
from sub2
)
SELECT s.hacker_id,s.name,s.cnt
from sub s
INNER JOIN sub2 s2 ON s.cnt = s2.cnt
INNER JOIN sub3 s3 ON 1 = 1
WHERE s.cnt = s3.max_cnt 
    OR s2.cnt2 = 1
ORDER BY s.cnt DESC, s.hacker_id

최댓값이면 중복을 살리고
최댓값이 아니라면 중복을 모두 제거할 것.
최댓값이 아니고 독립적인 값은 출력하자.

지금 내가 한 것은 '특정 학생별로 문제 출제 수를 집계했다.'
    ->애네들의 출제 문제 수가 중복인지 아닌지 확인해야댐.
    -> 어떻게 할까? COUNT 하는 거지 - (1)
    -> 그럼 애네들의 max 출제 수는 단일값일까 중복값일까 확인해보자 (2)
    -> max의 값을 알았다. 이제 해커별 문제 출제수의 최댓값을 알 수 있고, 출제 수 별 빈도도 알 수 있다.
    -> 비교만 해보면 된다. 최댓값인지? -> 최댓값이 아니라면, 빈도가 1인지? 
    -> 최댓값이 아닌데, 빈도가 2이상이면 삭제해야 되기 때문에, 가져올 필요가 없다.

```

(2) 서브쿼리로 풀어보기

```
SELECT h.hacker_id, h.name, COUNT(*) AS cnt
FROM Hackers h
JOIN Challenges c 
  ON h.hacker_id = c.hacker_id
GROUP BY h.hacker_id, h.name
HAVING COUNT(*) = (
    SELECT MAX(cnt)
    FROM (
        SELECT hacker_id, COUNT(*) AS cnt
        FROM Challenges
        GROUP BY hacker_id
    ) t
)
OR COUNT(*) IN (
    SELECT cnt
    FROM (
        SELECT hacker_id, COUNT(*) AS cnt
        FROM Challenges
        GROUP BY hacker_id
    ) t
    GROUP BY cnt
    HAVING COUNT(*) = 1
)
ORDER BY cnt DESC, hacker_id;

로직은 동일함.
1. 특정 해커별로 문제 출제 수 집계
2. 서브쿼리 having 절을 활용하여 max 치와의 비교
3. in을 활용하여, count가 1인 애들을 모두 골라내는 거야.
근데 마지막 in 문을 보게 되면, 이건 -> 문제 출제 수만 확인할 수 있는 거 아닌가?
-> 그 바깥 서브쿼리에 그룹바이로 CNT로 묶었기 떄문에, CNT 별로 갯수가 COUNT되고, HAVING이 걸려있어서 1개만 뽑히는 구조.
```

---

0812

```
SELECT CASE
    WHEN g.grade < 8 THEN NULL ELSE s.name end as name,g.grade, s.Marks
FROM Students AS s
Inner join grades AS g ON s.Marks between Min_MARK AND Max_Mark
ORDER BY g.grade DESC, s.name, s.Marks 

사고의 메모
1. 이번에는 정확한 값의 조인이 아닌, 범위와의 조인 그럴때는, in between이 아닌 일반 between 사용하면 된다.
2. xx 일땐, y를 출력하고 뭐일땐 뭐를 출력해야하면, case when if문을 생각하자!
```

```sql
Select DISTINCT l1.num AS ConsecutiveNums
from Logs l1
inner join logs l2 ON l1.id + 1 = l2.id
inner join logs l3 ON l2.id + 1 = l3.id
WHERE l1.num = l2.num AND l2.num = l3.num

하나의 테이블로 내 다음 행과 비교해야 하면  셀프 조인할 떄, +1을 생각할 것.
근데 왜 WHERE 대신에 CASE는 안되는 거지?

답 : CASE 는 보여주는 거임, 틀리면 NULL을 반환하나, WHERE은 필터링의 역할

```

---

윈도우 함수(그룹바이랑 조금은 비슷한 느낌)

차이는 뭘까?

그룹바이는 ROW별로가 아닌, SUM해서 딱 하나의 값만 보여줌

WINDOW 는 각 ROW별로 결과를 출력해서 보여줌. 

함수(컬럼) OVER (PARTITION BY 컬럼 ORDER BY 컬럼)

- 파티션은 그룹바이와 비슷하다고 생각하면 됨.

EX) SUM(PROFIT) OVER( PARTITION BY CONTRY ORDER BY 컬럼

이것을 사용하게 되면, 전체 데이터를 보면서,  max, 값 등 특정값을 추출해서 → 비교해서 보기 쉽다.

요기서 partition 이 아니라, order by를 쓰게되면 누적합을 보여주게 된다.

*** 근데 mysql 구버전이면 누적합 기능 없음 

```jsx
SELECT e1.id,
			 e1.name,
			 e1.kg,
			 e1.Line,
			 sum(e2.kg) AS cumsum
FROM Elevatio e1
inner join elevator e2
	on e1.id = e2.id
	and e1.line >= e2.line
group by 1,2,3,4

-- 서브쿼리
select e1.id,
				xxxx
				,(select sum(e2.kg)
				from e... e2
				where e1.id= e2.id
				and e1.line >= e2.line) as cX
```

order by + partiontion by 하면 그룹별 누적합 구한다고 이해하면 쉽다./

순위를 정하는 함수 over (order by)

1. row_number() → 중복 고려 x
2. rank() - 공동 1,1,3
3. dense_rank() 1,1,2 

순서 바꾸기 lead, lag

lag(x, 2, x) over (order by) as

x는 디폴트 값

누적합은 → select 서브쿼리에 대한 이야기

---

결과값이 피벗테이블을 원할 때는, CASE 문이다.

고급반 끝난 후,

[https://datarian.io/blog/sql-camp-level-test](https://datarian.io/blog/sql-camp-level-test)

---

특정 순위를 기반으로, 출력해라 하면. rank.윈도우함수 사용. 

SELECT 절에서 집계함수 사용시, WHERE 바로 사용 못해. 서브쿼리로 감싸.

```
SELECT t.department
      ,t.employee
      ,t.salary
FROM(
    SELECT department.name AS department
        ,employee.name AS employee
        ,employee.salary
        ,DENSE_RANK() OVER (PARTITION BY departmentid ORDER BY salary DESC) AS dr
    FROM employee
        INNER JOIN department ON employee.departmentid = department.id
) t
WHERE t.dr <=3
```

---

**사용자 정의 함수**

수업에서 언급한 MySQL tutorials 링크

1. 사용자 정의 함수: https://www.mysqltutorial.org/mysql-stored-function/

2. IF statement: https://www.mysqltutorial.org/mysql-if-statement/

CREATE FUNCTUIN ‘함수 이름’ (’파라미터의 이름’,’데이터 타입’)

RETURNS ‘datatype’ (deterministic) — 출력될 결과의 데이터 타입

BEGIN

DECLARE ‘변수 명’, ‘데이터타입’;

SET ;

RETURN (쿼리) / ‘변수명’;

END

---

Create function add (x,y)

returns INT

if ㅌ > xx then

set x = ‘x’;

elseif (xx and x>) then

set x = 

---

function 인데, 리미트와 offset 을 활용하면 서브쿼리 없이도 가능함.

```
CREATE FUNCTION getNthHighestSalary(N INT)
RETURNS INT
BEGIN
  RETURN (
    SELECT CASE WHEN COUNT(sub.Salary) < N THEN NULL
                ELSE MIN(sub.Salry)
            END
    FROM(
        SELECT DISTINCT Salary
        FROM Employee
        order BY Salary DESC
        LIMIT N
        ) sub
  );
END
조건이 많으면 case
하나라면 if 가 더 좋
```

```
CREATE FUNCTION getNthHighestSalary(N INT)
RETURNS INT
BEGIN
  RETURN (
    SELECT IF(COUNT(sub.Salary) < N,NULL ,MIN(sub.Salary))
        END
    FROM(
        SELECT DISTINCT Salary
        FROM Employee
        order BY Salary DESC
        LIMIT N
        ) sub
  );
END
```

지금은 리미트 하나만 줘서 값을 뽑아왔었음.

근데 limit 는 값을 여러 개 받아올 수 있음.

SELECT * FROM table LIMIT 5, 10 #Retrieve rows 6~15\

=

SELECT * FROM table LIMIT 1 OFFSET N 

→ SET 에서 N 만큼을 없애라.

그럼 N-1 까지 들고오면 될듯?

```
---
CREATE FUNCTION getNthHighestSalary(N INT)
RETURNS INT
BEGIN
  --DECLARE A INT;
  **SET N = N-1;**
  RETURN (
    SELECT DISTINCT Salary
    FROM Employee
    ORDER BY Salary DESC
    LIMIT N, 1
  );
END

CREATE FUNCTION getNthHighestSalary(N INT)
RETURNS INT
BEGIN
  --DECLARE A INT;
  **SET N = N-1;**
  RETURN (
    SELECT DISTINCT Salary
    FROM Employee
    ORDER BY Salary DESC
    LIMIT 1 OFFSET N
  );
END

SELECT getNthHighestSalary(3)

```

ROW_NUMBER, RANK, DENSE_RANK, LEAD, LAG 등은 윈도우 함수에 해당합니다. SUM, AVG, COUNT는 일반 집계 함수로 전체 또는 그룹별로 계산합니다.

---

```sql
SELECT h.hacker_id, h.name, sum(s.score)
FROM Hackers h
JOIN Submissions s ON h.hacker_id = s.hacker_id
group by h.hacker_id, h.name
HAVING sum(s.score) <> 0 and 
order by sum(s.score) DESC, hacker_id ASC

-- 막힌 부분 : 과목별 최대값을 활용하라는 지문을 이해하지 못함
--아래 정답 쿼리 로직
-- 1. id별 과목별 맥스 점수를 구한다
-- 2. 서브쿼리를 통해 -> 정보 테이블과 조인
-- 3. 그런 다음 -> 점수 합산.
SELECT h.hacker_id
      , h.name
      , Sum(score_max)
FROM(
SELECT hacker_id
     , challenge_id
     , MAX(score) score_max
FROM Submissions s
Group by hacker_id, challenge_id
) t INNER JOIN Hackers h ON h.hacker_id = t.hacker_id
GROUP BY h.hacker_id, h.name
HAVING total_score != 0
ORDER BY total_score DESC, h.hacker_id
```

---

해커랭크 - New company

s

```
SELECT c.company_code
      ,c.founder
      , (SELECT COUNT(DISTINCT lead_manager_code)
        FROM lead_manager
        WHERE company_code = c.company_code)
      , (SELECT COUNT(DISTINCT lead_manager_code)
        FROM lead_manager
        WHERE company_code = c.company_code)
      , (SELECT COUNT(DISTINCT lead_manager_code)
        FROM lead_manager
        WHERE company_code = c.company_code)
      , (SELECT COUNT(DISTINCT lead_manager_code)
        FROM lead_manager
        WHERE company_code = c.company_code)
FROM Company c 
Order by company_code

조인을 사용하지 않고, 서브쿼리를 사용해서 풀 수 있다.
나는 다 조인해서 -> 갯수를 세려고 했는데 굳이?

단, 서브쿼리 안에 where 절을 사용함으로써 -> 특정 company_code를 select할떄,
ㅇwhere절로 들어가서 해당 회사의 리드매니저의 수, 이런식으로 셀 수 있는 로직
    
```

---

---

해커랭커 - occupations

```sql
select Min(CASE WHEN occupation = 'Doctor' THEN Name ELSE NULL END) doctor
			,Min(CASE WHEN occupation = 'Professor' THEN Name ELSE NULL END) pro
			,Min(CASE WHEN occupation = 'Singer' THEN Name ELSE NULL END) sin
			,Min(CASE WHEN occupation = 'Actor' THEN Name ELSE NULL END) act
from (
SELECT occupation
			, name
			, ROW_NUMBER () OVER (PARTITION BY occupation order by name) rn
FROM Occupations
) t
group by rn
order by rn

]왜 min을 하냐면 min을 하지 않으면, 중복 행들이 발생해서, 그걸 없애고 닥터인 애 row 인지? col 인지? 하나만 남기려고
```