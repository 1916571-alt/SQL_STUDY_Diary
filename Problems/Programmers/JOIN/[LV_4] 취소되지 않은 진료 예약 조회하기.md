# [LV_4] 취소되지 않은 진료 예약 조회하기

> **정보**
> - **날짜**: 2026년 1월 20일
> - **분류**: 프로그래머스 (LV_4)
> - **주제**: JOIN

### 문제 핵심
**2022년 4월 13일 취소되지 않은 흉부외과(CS) 진료 예약 내역 조회**

1. APPOINTMENT, PATIENT, DOCTOR 3개 테이블 JOIN
2. 조건: 진료과코드 = 'CS', 취소여부 = 'N', 날짜 = '2022-04-13'
3. 진료예약일시 기준 오름차순 정렬

### 풀이

```sql
SELECT A.APNT_NO,
       P.PT_NAME,
       A.PT_NO,
       A.MCDP_CD,
       D.DR_NAME,
       A.APNT_YMD
FROM APPOINTMENT A
JOIN PATIENT P
    ON A.PT_NO = P.PT_NO
JOIN DOCTOR D
    ON A.MDDR_ID = D.DR_ID
WHERE A.MCDP_CD = 'CS'
  AND APNT_CNCL_YN = 'N'
  AND DATE_FORMAT(A.APNT_YMD, '%Y-%m-%d') = '2022-04-13'
ORDER BY A.APNT_YMD
```

### 핵심 패턴
- 다중 테이블 JOIN (3개 테이블)
- 복합 WHERE 조건
