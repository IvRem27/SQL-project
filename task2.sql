-- Write a query to retrieve all customers that have orders.
SELECT c.*
FROM customer c
         INNER JOIN "order" o on c.id = o.customer_id;

-- Write a query to retrieve orders and order_items. Instead of customer_id you need to have a customer name.
SELECT c.name,
       oi.product,
       oi.unit_price,
       oi.unit_discount,
       o.sub_total,
       o.discount,
       o.tax_amount,
       o.total
FROM customer c
         INNER JOIN "order" o on c.id = o.customer_id
         INNER JOIN order_item oi on o.id = oi.order_id;

-- Write a query to retrieve the total sum of all orders.
SELECT SUM(total) AS sum_of_all_orders
FROM "order";

-- Write a query to retrieve the total sum of all orders grouped by customer
SELECT c.name, SUM(total) AS orders_sum
FROM "order" o
         INNER JOIN customer c on c.id = o.customer_id
GROUP BY o.customer_id, c.name;