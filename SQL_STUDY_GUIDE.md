# SQL Study Logging Guide (Rules)

To maintain consistency in the SQL study diary, follow these formatting and organizational rules.

## 1. Directory Structure

- **Path**: `Problems/Programmers/[SQL_TYPE]/`
- **Example**: `Problems/Programmers/SELECT/`, `Problems/Programmers/GROUP BY/`

## 2. Filename Convention

- **Re-solve required** (`재풀이 여부: O`): `[재풀이 필요] 문제명.md`
- **Normal**: `문제명.md`
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
- Keep commit messages descriptive (e.g., "Add [Problem Name] and reformat SQL").
