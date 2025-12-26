# 🐣 기초 SQL 스터디 로그 (Basic SQL)

> **프로젝트**: [백문이불여일타] 데이터 분석을 위한 기초 SQL
> **기간**: 2025.07.08 ~ 2025.07.10
> **상태**: 완료 ✅

---

## 📅 7월 16일 학습 내용

### 1. Weather Observation Station 12 (HackerRank)
**핵심 개념**: `NOT IN`과 `NOT LIKE`의 활용

- **포인트**: `IN`은 정확한 문자열 값에만 사용 가능하다. 패턴 매칭을 하려면 `LIKE`를 써야 한다.

#### ❌ 오답 (잘못된 사용)
```sql
SELECT DISTINCT *
FROM Station
WHERE CITY NOT IN ('a%','e%','i%','o%','u%') -- IN은 와일드카드(%)를 인식하지 못함
```

#### ✅ 정답 (올바른 사용)
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

---

### 2. Higher Than 75 Marks
**핵심 개념**: 문자열 함수와 정렬

- **문제**: 점수가 75점보다 높은 학생을 이름의 **끝 3글자** 기준으로 정렬하라.
- **해결**: `RIGHT()` 함수 사용.

```sql
SELECT Name
FROM STUDENTS
WHERE Marks > 75
ORDER BY RIGHT(Name, 3), ID;
```
> 💡 **Tip**: SQL에서도 `RIGHT`, `LEFT`, `SUBSTR` 같은 문자열 함수를 자유롭게 사용할 수 있다.

---

### 3. Weather Observation Station 15
**핵심 개념**: 집계 함수와 반올림

- **함수 정리**:
  - `CEIL()`: 올림
  - `FLOOR()`: 내림
  - `ROUND()`: 반올림

#### 문제 풀이
가장 큰 값을 찾기 위해 정렬 후 `LIMIT` 사용.

```sql
SELECT ROUND(LONG_W, 4)
FROM STATION
WHERE LAT_N < 137.2345
ORDER BY LAT_N DESC
LIMIT 1;
```

---

## 🔗 참고 자료
- [데이터리안 SQL Basic Cheat Sheet](https://datarian.io/)