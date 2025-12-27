# 1227_A/B테스트를 위한 버킷 나누기 2

## SQL Solution

```sql
with
  base AS (
    SELECT
      customer_id,
      CASE
        WHEN customer_id % 10 = 0 then 'A'
        ELSE 'B'
      END bucket,
      COUNT(*) as order_1,
      SUM(total_price) as order_2
    FROM
      transactions
    WHERE
      is_returned = 0
    GROUP BY
      customer_id,bucket
  )
SELECT
  bucket,
  count(*) AS user_count,
  ROUND(AVG(order_1), 2) AS avg_orders,
  ROUND(avg(order_2), 2) AS avg_revenue
FROM
  base
group by
  bucket
```
