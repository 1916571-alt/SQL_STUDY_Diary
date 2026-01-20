# [LV_4] 보호소에서 중성화한 동물

> **정보**
> - **날짜**: 2026년 1월 20일
> - **분류**: 프로그래머스 (LV_4)
> - **주제**: JOIN

### 문제 핵심
**보호소에 들어올 때는 중성화X, 나갈 때는 중성화O인 동물 찾기**

1. ANIMAL_INS와 ANIMAL_OUTS를 INNER JOIN
2. 들어올 때와 나갈 때의 SEX_UPON 값이 다르면 중성화 수술을 받은 것
   - Intact: 중성화 안 됨
   - Spayed/Neutered: 중성화 됨
3. 아이디 순으로 정렬

### 풀이

```sql
SELECT I.ANIMAL_ID,
       I.ANIMAL_TYPE,
       I.NAME
FROM ANIMAL_INS I
JOIN ANIMAL_OUTS O
    ON I.ANIMAL_ID = O.ANIMAL_ID
WHERE I.SEX_UPON_INTAKE != O.SEX_UPON_OUTCOME
ORDER BY I.ANIMAL_ID
```
