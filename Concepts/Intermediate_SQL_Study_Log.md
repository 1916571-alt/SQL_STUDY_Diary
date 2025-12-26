# [백문이불여일타] 데이터 분석을 위한 중급 SQL

진행 상태: 완료
마감일: 2025년 7월 17일 → 2025년 8월 7일
프로젝트: (공부) SQL (https://www.notion.so/SQL-232be5e372b080098162cd2246c78034?pvs=21)

---

0717

https://leetcode.com/problemset/database/

[https://solvesql.com/problems/find-christmas-games/](https://solvesql.com/problems/find-christmas-games/)

[h](https://www.w3schools.com/mysql/trymysql.asp?filename=trysql_select_limit)https://www.hackerrank.com/domains/sql?filters%5Bsubdomains%5D%5B%5D=aggregation

[https://www.w3schools.com/mysql/trymysql.asp?filename=trysql_select_limit](https://www.w3schools.com/mysql/trymysql.asp?filename=trysql_select_limit)

[https://www.inflearn.com/my/courses](https://www.inflearn.com/my/courses)

[[데이터리안]_SQL_Basic_Cheat_Sheet (1).pdf](%E1%84%83%E1%85%A6%E1%84%8B%E1%85%B5%E1%84%90%E1%85%A5%E1%84%85%E1%85%B5%E1%84%8B%E1%85%A1%E1%86%AB_SQL_Basic_Cheat_Sheet_(1).pdf)

**Pandas cheet sheet** 참고 추천

NULL 을 VALUE로 취급하냐 안하냐에 따라서

다 더해서 /COUNT 로 나누냐 아니면 AVG 로 하냐 차이

---

```sql
SELECT COUNT(CITY) - DISTINCT(COUNT(CITY))
FROM STATION

카운트를 밖에서 감싸줘야
```

```sql
SELECT (salary * months) AS earnings, COUNT(name)
from Employee
GROUP BY earnings 
ORDER BY earnings DESC
LIMIT 1

문제 : xx 의 값을 구하고, 가장 높은 값은 무엇인가? -> 그 수는 몇명인 것인
```

---

0729

세로 데이터 → 가로로 펼치는 방법

---

30 join

“[https://sql-joins.leopard.in.ua/](https://sql-joins.leopard.in.ua/)”

SQL 시각화

---

```sql
Select city.name
from city
    INNER JOIN country ON City.Countrycode = Country.Code 
WHERE COUNTRY.CONTINENT = "Africa"
```

---

```sql
SELECT C.name AS Customers
FROM Customers AS c
    LEFT JOIN Orders AS o ON C.id = O.customerID
WHERE o.id IS NULL
```

---

```
SELECT e.name AS Employee
FROM Employee as e 
    INNER JOIN Employee as m ON e.managerID = m.id
WHERE e.salary > m.salary;

where을 걸때는 as 말고 참조 테이블과 그거
```

```
SELECT today.id
FROM Weather AS today
    INNER JOIN Weather AS yesterday ON DATE_ADD(yesterday.recordDate, INTERVAL 1 DAY) = today.recordDate
WHERE today.temperature > yesterday.temperature

-- 오늘, 어제와의 비교 1. 오늘을 만든다. 2. 어제를 만들어 조인 값으로 활용한다.
-- 왜 결과값에 ID가 안나왔을까? ID를 사용했기 떄문 날짜를 사용해야 한당

DATE_ADD(날짜, 인터벌 X 단위)
DATE_SUB
```

---

UNION 에선

EXCEPT OR MINUS (오라클에서 씀) 교집합은 INTERSECT 도 쓴다 - 오라클만

---

MYSQL 은 FULL OUTER JOIN이 안돼서 레프트 + 라이트 해서 유니온 해야댐

---

```sql
SELECT f1.X, f1.Y, f2.X, f2.Y
FROM functions AS f1
    INNER JOIN functions AS f2 ON f1.X = f2.Y AND f1.Y = f2.X 
WHERE f1.X < f1.Y
```

홀짝 판별하는법

```
SELECT *
FROM Cinema
WHERE 
    MOD(id, 2) = 1 
    AND description != 'boring'
ORDER BY rating DESC;
```

```sql
SELECT truncate(SUM(LAT_N),4)
FROM STATION
WHERE LAT_N > 38.7880 AND LAT_N < 137.2345

/* between은 다 포함 */ 
```

---

```sql
SELECT s.name
FROM Packages p1
INNER JOIN Friends f ON p1.id = f.id
INNER JOIN Packages p2 ON p2.id = f.friend_ID
INNER JOIN Students s ON p1.id = s.id
WHERE p1.salary < p2.salary
ORDER BY p2.salary

맞췄다 ㅎ
```

```sql
SELECT DISTINCT b1.N,
    CASE
    WHEN b1.P IS NULL THEN 'Root'
    WHEN b2.N IS NOT NULL THEN 'Inner'
    ELSE 'Leaf'
    END AS 'Binary'
FROM BST b1
LEFT join BST b2 ON b1.N = b2.P
ORDER BY b1.N

JOIN 의 결과값을 생각하면 서 풀기.
CASE 문에서도, JOIN의 영향을 생각하면서 풀기.
```

끝났따!