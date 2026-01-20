# 카테고리별 매출 TOP 3 상품

> **정보**
> - **날짜**: 2025년 01월 20일
> - **분류**: Self-Made (A-2)
> - **주제**: 서브쿼리 + 순위 (RANK)
> - **난이도**: ★★
> - **재풀이 여부**: O

---

### 문제 설명
각 카테고리별로 2024년 매출액 상위 3개 상품의
상품명, 카테고리명, 총 매출액, 판매 수량을 출력하세요.

**테이블**: products, categories, order_items, orders
**출력**: category_name | product_name | total_revenue | total_qty

---

### 오답 풀이

```sql
WITH base AS (
    SELECT p.name AS product_name,
           c.name AS category_name,
           p.price * oi.quantity AS total_revenue1,
           oi.quantity AS total_qty1,
           RANK() OVER (PARTITION BY c.name ORDER BY p.price * oi.quantity) AS rnk
    FROM orders o
    JOIN order_items oi ON o.id = oi.id          -- 오류 1
    JOIN products p ON oi.product_id = p.id
    JOIN categories c ON c.id = p.category_id
    WHERE YEAR(o.order_date) = 2024
)
SELECT category_name,
       product_name,
       SUM(total_revenue1) AS total_revenue,
       SUM(total_qty1) AS total_qty
FROM base
WHERE rnk <= 3
GROUP BY category_name;                          -- 오류 4
```

**문제점 4가지**:

| # | 오류 | 설명 |
|---|------|------|
| 1 | `o.id = oi.id` | orders.id와 order_items.id를 조인함. **`o.id = oi.order_id`** 여야 함 |
| 2 | RANK 적용 시점 | 행 단위로 순위 매김. **집계 후** 순위를 매겨야 함 |
| 3 | 정렬 방향 | 오름차순으로 정렬됨. **DESC 필요** (매출 높은 순) |
| 4 | GROUP BY 불완전 | `product_name`이 GROUP BY에 없음 |

---

### 왜 집계 후에 RANK를 매겨야 하는가?

**집계 전 RANK (잘못된 방식)**:
| product_name | 주문건 매출 | rnk |
|--------------|-------------|-----|
| 아메리카노   | 4,500       | 1   |
| 아메리카노   | 4,500       | 1   |
| 라떼         | 5,500       | 3   |

→ 라떼가 1건인데 순위 3위

**집계 후 RANK (올바른 방식)**:
| product_name | 총 매출 | rnk |
|--------------|---------|-----|
| 아메리카노   | 9,000   | 1   |
| 라떼         | 5,500   | 2   |

→ 총 매출 기준 순위

---

### 정답 풀이

```sql
WITH product_sales AS (
    -- Step 1: 상품별 총 매출 집계
    SELECT p.name AS product_name,
           c.name AS category_name,
           SUM(p.price * oi.quantity) AS total_revenue,
           SUM(oi.quantity) AS total_qty
    FROM orders o
    JOIN order_items oi ON o.id = oi.order_id   -- 수정
    JOIN products p ON oi.product_id = p.id
    JOIN categories c ON c.id = p.category_id
    WHERE YEAR(o.order_date) = 2024
    GROUP BY c.name, p.name
),
ranked AS (
    -- Step 2: 집계된 결과에 순위 부여
    SELECT *,
           RANK() OVER (PARTITION BY category_name ORDER BY total_revenue DESC) AS rnk
    FROM product_sales
)
SELECT category_name,
       product_name,
       total_revenue,
       total_qty
FROM ranked
WHERE rnk <= 3;
```

---

### 배운 점

1. **JOIN 조건 확인**: `order_items`와 `orders` 조인 시 `order_id` 사용
2. **순위 함수 적용 시점**:
   - 개별 행이 아닌 **집계된 결과**에 순위를 매겨야 함
   - "상품별 총 매출 TOP N" = 먼저 상품별 집계 → 그 다음 순위
3. **정렬 방향**: TOP N은 대부분 **DESC** (내림차순)
