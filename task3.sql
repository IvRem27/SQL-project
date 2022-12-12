-- Write a query to update the customer name with ID 3 to be John Doe.
UPDATE customer
SET name = 'John Doe'
WHERE id = 3;

-- Write a query to update the order for customer John Doe. Add a discount of 10 % to all orders for John Doe and recalculate order totals. If you don’t have orders for this customer please add orders to be able to complete this task.
UPDATE "order" o
SET discount=o.discount + 10,
    total=(o.sub_total - (o.sub_total * ((o.discount + 10) / 100))) + (o.sub_total * (o.tax_amount / 100))
WHERE o.customer_id = 3;