# SQL Study Logging Guide (Rules)

To maintain consistency in the SQL study diary, follow these formatting and organizational rules.

## 1. Directory Structure

- **Path**: `Problems/Programmers/[SQL_TYPE]/`
- **Example**: `Problems/Programmers/SELECT/`, `Problems/Programmers/GROUP BY/`

## 2. Filename Convention

- **General Format**: `[LV_N] [재풀이 필요] 문제명.md`
- **Re-solve required** (`재풀이 여부: O`): `[LV_N] [재풀이 필요] 문제명.md`
- **Normal**: `[LV_N] 문제명.md`
- **Note**: Replace slashes (`/`) in problem names with hyphens (`-`) to avoid directory issues.

## 3. Markdown Content structure

Each problem file must follow this template:

### Title
`# Problem Name`

### Information Block
```markdown
> **정보**
> - **날짜**: YYYY년 MM월 DD일
> - **분류**: 프로그래머스 (LV_N)
> - **주제**: [SQL_TYPE]
> - **재풀이 여부**: O/X
```

### Problem Description
`### 🎯 문제 설명`
Full description of the problem.

### Wrong Answer Analysis (Optional)
`### 📝 오답 풀이`
- **Required** if `재풀이 여부: O`.
- Explain why the previous attempt failed and what was missing.

---

### Solution / Process
`### 💡 풀이 과정`
- Key takeaways or step-by-step logic.
- SQL code blocks:
  - Keywords in **UPPERCASE**.
  - Proper indentation and semi-colons.
  - Use single quotes (`'`) for string literals.

---

## 4. Git Workflow
- Always `git pull` before working.
- **README Update**: If a problem is added or updated to `재풀이 여부: O`, add its link to the `## 🔁 재풀이 필요 문제` section in the root `README.md`.
- Keep commit messages descriptive (e.g., "Add [Problem Name] and reformat SQL").

---

## 5. Self-Made 문제 (Practice.session.sql 오답노트)

### 5.1 Directory Structure
- **Path**: `Problems/Self-Made/[단계]/`
- Practice.session.sql에서 푼 문제들의 오답노트 저장소

```
Problems/Self-Made/
├── 1_기본기/        ← A-4, A-6, A-3, A-1, A-2, A-5, A-7, A-8, E-3
├── 2_윈도우함수/    ← B-1~B-7, C-2~C-4, C-7
├── 3_비즈니스로직/  ← E-1, E-2, E-4, C-5, C-6, D-1, D-4, D-5, B-5, C-1
├── 4_그로스해킹/    ← G-1~G-11, D-6, F-1~F-3
└── 5_최고난이도/    ← F-4, F-5, D-2, D-3, G-10, G-12, X-1~X-3
```

### 5.2 Filename Convention
- **General Format**: `[A-N] 문제명.md`
- **Re-solve required**: `[A-N] [재풀이 필요] 문제명.md`
- 문제 번호(A-1, B-2, C-3 등)를 기준으로 해당 단계 폴더에 저장

### 5.3 Self-Made Content Structure

```markdown
# 문제명

> **정보**
> - **날짜**: YYYY년 MM월 DD일
> - **분류**: Self-Made (A-N)
> - **주제**: [SQL 주제]
> - **난이도**: ★~★★★★
> - **재풀이 여부**: O/X

---

### 문제 설명
문제 내용

**테이블**: 사용 테이블
**출력**: 출력 컬럼

---

### 오답 풀이 (틀렸을 경우)
- 잘못된 코드와 문제점 설명

---

### 정답 풀이
- 올바른 코드

---

### 배운 점
- 핵심 포인트 정리
```

### 5.4 Self-Made 문제 정리 요청 방법

Practice.session.sql에서 문제를 풀고 오답노트를 정리하려면:

```
"A-N 문제 풀었는데 어디가 틀린 거 같아?" → 오답 분석
"지금까지 푼 문제들 Self-Made 폴더에 정리해줘" → 오답노트 생성
```

Claude가 자동으로:
1. Practice.session.sql에서 풀이 코드 확인
2. 오답 분석 및 정답 제시
3. `Problems/Self-Made/` 폴더에 md 파일 생성
