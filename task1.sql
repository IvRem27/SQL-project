-- create database and connect to it
CREATE DATABASE orders;
\c orders;

-- create tables
CREATE TABLE customer
(
    id   SERIAL PRIMARY KEY NOT NULL,
    name TEXT               NOT NULL
);

CREATE TABLE "order"
(
    id          SERIAL PRIMARY KEY NOT NULL,
    customer_id INT                NOT NULL,
    sub_total   NUMERIC(7, 2)      NOT NULL,
    discount    NUMERIC(7, 2),
    tax_amount  NUMERIC(7, 2)      NOT NULL,
    total       NUMERIC(7, 2)      NOT NULL,
    CONSTRAINT FK_order_customer FOREIGN KEY (customer_id)
        REFERENCES customer (id)
);

CREATE TABLE order_item
(
    id            SERIAL PRIMARY KEY NOT NULL,
    order_id      INT                NOT NULL,
    product       TEXT               NOT NULL,
    unit_price    NUMERIC(7, 2)      NOT NULL,
    unit_discount NUMERIC(7, 2),
    CONSTRAINT FK_order_item_order FOREIGN KEY (order_id)
        REFERENCES "order" (id)
);



-- trigger function which will recalculate sub_total and total in orders table whenever order_item(s) change
CREATE OR REPLACE FUNCTION public.recalculate_totals() RETURNS trigger AS
$$
DECLARE
    SubTotal      float;
    FinalTotal    float;
    OrderDiscount float;
    TaxAmount     float;
BEGIN

    -- for INSERT/UPDATE we will have NEW.order_id filled, for DELETE we will have OLD.order_id filled
    -- Calculate subtotal based on all order_items for this order and save it into the SubTotal variable
    SELECT sb.sub_total
    INTO SubTotal
    FROM (SELECT SUM(oi.unit_price - (oi.unit_price * COALESCE(oi.unit_discount, 0) / 100)) AS sub_total
          FROM order_item oi
          WHERE oi.order_id = COALESCE(NEW.order_id, OLD.order_id)
         ) as sb;

    -- Get the discount and tax_amount for the order
    SELECT o.discount, o.tax_amount
    INTO OrderDiscount, TaxAmount
    FROM (SELECT COALESCE(discount, 0) AS discount, tax_amount FROM "order" WHERE id = COALESCE(NEW.order_id, OLD.order_id)) AS o;

    -- if SubTotal is null, then set it to 0
    IF SubTotal IS NULL THEN
        SubTotal := 0;
    END IF;

    -- calculate the appropriate total for the order after changes in order_item based on order discount and tax amount
    FinalTotal := SubTotal - (SubTotal * OrderDiscount / 100);
    FinalTotal := FinalTotal + (FinalTotal * TaxAmount / 100);

    -- update order with the newly recalculated sub total and total
    UPDATE "order"
    SET sub_total = SubTotal,
        total     = FinalTotal
    WHERE id = COALESCE(NEW.order_id, OLD.order_id);

    RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

-- add the previously defined trigger to the order_item table
CREATE TRIGGER order_item_recalculate_totals
    AFTER INSERT
        OR UPDATE
        OR DELETE
    ON public.order_item
    FOR EACH ROW
EXECUTE PROCEDURE public.recalculate_totals();

-- insert statements to add customers
INSERT INTO public.customer (id, name)
VALUES (1, 'John');

INSERT INTO public.customer (id, name)
VALUES (2, 'Anne');

INSERT INTO public.customer (id, name)
VALUES (3, 'Messi');

INSERT INTO public.customer (id, name)
VALUES (4, 'Ronaldo');

INSERT INTO public.customer (id, name)
VALUES (5, 'Neymar');

-- insert statements to add orders
INSERT INTO public."order" (id, customer_id, sub_total, discount, tax_amount, total)
VALUES (1, 1, 17.31, null, 25.00, 21.64);

INSERT INTO public."order" (id, customer_id, sub_total, discount, tax_amount, total)
VALUES (2, 2, 16.78, 12.00, 25.00, 18.46);

INSERT INTO public."order" (id, customer_id, sub_total, discount, tax_amount, total)
VALUES (3, 3, 179.16, 15.00, 25.00, 197.07);

-- insert statements to add order items
-- order items for order with id 1
INSERT INTO public.order_item (id, order_id, product, unit_price, unit_discount)
VALUES (6, 1, 'Shirt', 12.56, null);

INSERT INTO public.order_item (id, order_id, product, unit_price, unit_discount)
VALUES (7, 1, 'Glove', 5.40, 12.00);

-- order items for order with id 2
INSERT INTO public.order_item (id, order_id, product, unit_price, unit_discount)
VALUES (8, 2, 'Hats', 16.78, null);

-- order items for order with id 3
INSERT INTO public.order_item (id, order_id, product, unit_price, unit_discount)
VALUES (9, 3, 'Pants', 56.78, 15.00);

INSERT INTO public.order_item (id, order_id, product, unit_price, unit_discount)
VALUES (10, 3, 'Scarf', 14.35, 45.00);

INSERT INTO public.order_item (id, order_id, product, unit_price, unit_discount)
VALUES (11, 3, 'Boots', 123.00, null);


-- DROP statements to delete everything we created
-- drop the trigger
DROP TRIGGER order_item_recalculate_totals ON public.order_item;

-- drop all tables
DROP TABLE IF EXISTS "order_item";
DROP TABLE IF EXISTS "order";
DROP TABLE IF EXISTS "customer";

DROP DATABASE orders;