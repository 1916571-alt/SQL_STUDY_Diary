# [백문이불여일타] 데이터 분석을 위한 기초 SQL

진행 상태: 완료
마감일: 2025년 7월 8일 → 2025년 7월 10일
프로젝트: (공부) SQL (https://www.notion.so/SQL-232be5e372b080098162cd2246c78034?pvs=21)

7-16

1. **Weather Observation Station 12**

- IN은 정확한 문자열 값에만 사용 가

```sql
SELECT DISTINCT *
FROM Station
WHERE CITY NOT IN ('a%','e%''i%''o%''u%')
AND NOT IN ('%a', '%e', '%i', '%o', '%u')
```

```sql
SELECT DISTINCT city
FROM Station
WHERE city NOT LIKE 'a%'
AND city NOT LIKE 'e%'
AND city NOT LIKE 'i%'
AND city NOT LIKE 'o%'
AND city NOT LIKE 'u%'
AND city NOT LIKE '%a'
AND city NOT LIKE '%e'
AND city NOT LIKE '%i'
AND city NOT LIKE '%o'
AND city NOT LIKE '%u'
```

1.  **Higher Than 75 Marks**
    - name에서 끝자리 3개를 기준으로 정렬해

```sql
SELECT Name
FROM STUDENTS
WHERE Marks > 75
Order BY RIGHT(Name, 3), ID

-- SQL 도 RIGHT, LEFT, SUBSTR 함수 사용가
```

1.  **Weather Observation Station 15**
    1. CEIL
    2. FLOOR
    3. ROUND 가
    
    ```
    /* SELECT ROUND(LONG_W, 4)
    FROM STATION
    WHERE LAT_N < 137.2345
    ORDER BY LAT_N DESC
    LIMIT 1
    */
    ```
    

제일 큰 거만 추출해라 → 정렬 → LIMIT

[[데이터리안]_SQL_Basic_Cheat_Sheet (1).pdf](%E1%84%83%E1%85%A6%E1%84%8B%E1%85%B5%E1%84%90%E1%85%A5%E1%84%85%E1%85%B5%E1%84%8B%E1%85%A1%E1%86%AB_SQL_Basic_Cheat_Sheet_(1).pdf)