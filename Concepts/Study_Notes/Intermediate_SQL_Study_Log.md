# 🏃 중급 SQL 스터디 로그 (Intermediate SQL)

> **프로젝트**: [백문이불여일타] 데이터 분석을 위한 중급 SQL
> **기간**: 2025.07.17 ~ 2025.08.07
> **상태**: 완료 ✅

---

## 📅 7월 17일 학습 내용

### 📝 주요 메모
- **NULL 처리**: `NULL`을 값으로 취급하느냐 안 하느냐에 따라 `COUNT`, `AVG` 결과가 달라진다.
- **Pandas Cheat Sheet**: SQL과 비교하며 공부하면 좋다.

---

### 1. HackerRank: Aggregation
`COUNT`를 밖에서 감싸서 전체 개수 차이를 구하는 패턴.

```sql
SELECT COUNT(CITY) - COUNT(DISTINCT CITY)
FROM STATION;
```

### 2. Top Earners
**문제**: 가장 높은 수입(`salary * months`)과 그 수입을 가진 사람 수 구하기.

```sql
SELECT (salary * months) AS earnings, COUNT(name)
FROM Employee
GROUP BY earnings 
ORDER BY earnings DESC
LIMIT 1;
```

---

## 📅 7월 29일 학습 내용 (JOIN & Set Operations)

> **참고**: [SQL Joins Visualizer](https://sql-joins.leopard.in.ua/)

### 1. INNER JOIN (기본)
아프리카 대륙에 있는 도시 찾기.
```sql
SELECT city.name
FROM city
INNER JOIN country ON City.Countrycode = Country.Code 
WHERE COUNTRY.CONTINENT = "Africa";
```

### 2. LEFT JOIN (NULL 찾기)
주문하지 않은 고객 찾기 (`IS NULL` 패턴).
```sql
SELECT C.name AS Customers
FROM Customers AS c
LEFT JOIN Orders AS o ON C.id = O.customerID
WHERE o.id IS NULL;
```

### 3. SELF JOIN (자기 참조)
매니저보다 연봉이 높은 사원 찾기.
```sql
SELECT e.name AS Employee
FROM Employee as e 
INNER JOIN Employee as m ON e.managerID = m.id
WHERE e.salary > m.salary;
```

### 4. 날짜 비교 (DATE_ADD)
어제보다 온도가 높은 날 찾기.
```sql
SELECT today.id
FROM Weather AS today
INNER JOIN Weather AS yesterday 
    ON DATE_ADD(yesterday.recordDate, INTERVAL 1 DAY) = today.recordDate
WHERE today.temperature > yesterday.temperature;
```
> 💡 **Tip**: `DATE_ADD(날짜, INTERVAL 1 DAY)`를 사용하여 "어제"를 "오늘" 날짜로 변환해 조인 조건으로 사용한다.

---

### 5. Advanced Join Logic
친구의 연봉이 더 높은 경우 찾기 (3중 조인).
```sql
SELECT s.name
FROM Packages p1
INNER JOIN Friends f ON p1.id = f.id
INNER JOIN Packages p2 ON p2.id = f.friend_ID
INNER JOIN Students s ON p1.id = s.id
WHERE p1.salary < p2.salary
ORDER BY p2.salary;
```

### 6. Binary Tree Nodes (CASE + JOIN)
트리 노드가 Root, Inner, Leaf인지 판별하기.
```sql
SELECT DISTINCT b1.N,
    CASE
        WHEN b1.P IS NULL THEN 'Root'
        WHEN b2.N IS NOT NULL THEN 'Inner'
        ELSE 'Leaf'
    END AS NodeType
FROM BST b1
LEFT JOIN BST b2 ON b1.N = b2.P
ORDER BY b1.N;
```

---

## 🧠 개념 정리: JOIN과 UNION

- **UNION**: 두 쿼리 결과를 위아래로 합침 (중복 제거).
- **UNION ALL**: 중복 포함하여 합침.
- **EXCEPT / MINUS**: 차집합 (Oracle 등).
- **INTERSECT**: 교집합.
- **MySQL 특이사항**: `FULL OUTER JOIN`을 지원하지 않으므로, `LEFT JOIN`과 `RIGHT JOIN`을 `UNION`하여 구현해야 한다.