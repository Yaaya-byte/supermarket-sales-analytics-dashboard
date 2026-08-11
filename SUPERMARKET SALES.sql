use supermarket;
select * from bprice;
select * from sales;
select * from price_difference;
select * from inventory;

            -- 1. TOP SALESPERSON WHO SOLD THE MOST, PER MONTH (with rank)

SELECT month_year, sales_person, total_revenue, `rank`
FROM (SELECT DATE_FORMAT(`ORDER_DATE`, '%Y-%m') AS month_year,`SALES_PERSON` AS sales_person,SUM(TOTAL) AS total_revenue,
RANK() OVER (PARTITION BY DATE_FORMAT(`ORDER_DATE`, '%Y-%m') ORDER BY SUM(TOTAL) DESC) AS `rank`
FROM sales GROUP BY month_year, sales_person) ranked WHERE `rank` = 1 ORDER BY month_year;

           -- Simple version (no rank, just sorted)
SELECT DATE_FORMAT(`ORDER_DATE`, '%Y-%m') AS month, `SALES_PERSON` AS salesperson, SUM(TOTAL) AS revenue
FROM sales GROUP BY month, salesperson ORDER BY month, revenue DESC;


           -- Top 2 in first month, with rank column
SELECT month, SALES_PERSON, revenue, RANK() OVER (ORDER BY revenue DESC) AS rank_position
FROM (SELECT DATE_FORMAT(`ORDER_DATE`, '%Y-%m') AS month,  `SALES_PERSON`, SUM(TOTAL) AS revenue 
FROM sales WHERE DATE_FORMAT(`ORDER_DATE`, '%Y-%m') = (SELECT MIN(DATE_FORMAT(`ORDER_DATE`, '%Y-%m')) FROM sales)
GROUP BY month, `SALES_PERSON`) sub ORDER BY revenue DESC LIMIT 2;


         -- 2. TOP 2 PRODUCTS SOLD, PER MONTH (with category + total sales)

SELECT month, category, product, total_qty, total_sales, rank_position FROM (SELECT DATE_FORMAT(`ORDER_DATE`, '%Y-%m') AS month,
CATEGORY AS category, PRODUCT AS product, SUM(QUANTITY) AS total_qty, SUM(TOTAL) AS total_sales,
RANK() OVER (PARTITION BY DATE_FORMAT(`ORDER_DATE`, '%Y-%m') ORDER BY SUM(QUANTITY) DESC) AS rank_position
FROM sales GROUP BY month, category, product) ranked WHERE rank_position <= 2 ORDER BY month, rank_position;


           -- 3. DATA QUARTER (which quarters exist in your data)
SELECT DISTINCT YEAR(ORDER_DATE) AS year, QUARTER(ORDER_DATE) AS quarter FROM sales ORDER BY year, quarter;


				
			-- 4. PROFIT — MONTHLY / WEEKLY / QUARTERLY
            
	    -- Weekly profit (4-5 rows per month, "week of month" style)
            
SELECT DATE_FORMAT(sales.ORDER_DATE, '%Y-%m') AS month, CEIL(DAY(sales.ORDER_DATE) / 7) AS week_of_month,
SUM(sales.TOTAL) AS revenue, SUM(sales.QUANTITY * bprice.BUYING_PRICE_PER_PCS) AS cost,
SUM(sales.TOTAL) - SUM(sales.QUANTITY * bprice.BUYING_PRICE_PER_PCS) AS profit
FROM sales JOIN bprice ON sales.PRODUCT = bprice.PRODUCT GROUP BY month, week_of_month ORDER BY month, week_of_month;
             
             
              -- Monthly profit
             
SELECT DATE_FORMAT(sales.ORDER_DATE, '%Y-%m') AS month, SUM(sales.TOTAL) AS revenue,
SUM(sales.QUANTITY * bprice.BUYING_PRICE_PER_PCS) AS cost, SUM(sales.TOTAL) - SUM(sales.QUANTITY * bprice.BUYING_PRICE_PER_PCS) AS profit
FROM sales JOIN bprice ON sales.PRODUCT = bprice.PRODUCT GROUP BY month ORDER BY month;


	
                  -- Quarterly profit
                  
SELECT YEAR(sales.ORDER_DATE) AS year, QUARTER(sales.ORDER_DATE) AS quarter, SUM(sales.TOTAL) AS revenue,
SUM(sales.QUANTITY * bprice.BUYING_PRICE_PER_PCS) AS cost,
SUM(sales.TOTAL) - SUM(sales.QUANTITY * bprice.BUYING_PRICE_PER_PCS) AS profit FROM sales
JOIN bprice ON sales.PRODUCT = bprice.PRODUCT GROUP BY year, quarter ORDER BY year, quarter;

Select * from SaleS;

               -- 5. ORDERS SOLD BELOW BUYING PRICE

SELECT sales.ORDER_DATE, sales.SALES_PERSON, sales.PRODUCT, sales.QUANTITY, sales.`Selling_price_per_pcS` AS selling_price,
bprice.BUYING_PRICE_PER_PCS AS buying_price, sales.STATUS, sales.TOTAL
FROM sales JOIN bprice ON sales.PRODUCT = bprice.PRODUCT WHERE sales.STATUS = 'Below Buying Price'
ORDER BY sales.ORDER_DATE;


             -- 6. TOTAL PCS IN INVENTORY BEFORE SELLING

SELECT SUM(PCS_IN_INVENTORY) AS total_pcs_before_selling FROM inventory;


           -- 7. SALESPERSON COMPARISON — PROFIT

SELECT sales.SALES_PERSON, SUM(sales.TOTAL) AS revenue, SUM(sales.QUANTITY * bprice.BUYING_PRICE_PER_PCS) AS cost,
SUM(sales.TOTAL) - SUM(sales.QUANTITY * bprice.BUYING_PRICE_PER_PCS) AS profit FROM sales JOIN bprice ON sales.PRODUCT = bprice.PRODUCT
GROUP BY sales.SALES_PERSON ORDER BY profit DESC;


          -- 8. JOINING BPRICE AND SALES TABLE
-- ---------------------------------------------------------
SELECT * FROM sales JOIN bprice ON sales.PRODUCT = bprice.PRODUCT;


			-- 9. FORMAL LINKS (FOREIGN KEYS) BETWEEN TABLES

            -- Make PRODUCT unique in BPRICE first (required to be referenced)
            
ALTER TABLE bprice ADD CONSTRAINT unique_product UNIQUE (PRODUCT);


           -- SALES -> BPRICE
ALTER TABLE sales  ADD CONSTRAINT fk_sales_product FOREIGN KEY (PRODUCT) REFERENCES bprice(PRODUCT);


           -- INVENTORY -> BPRICE (needs an index first)
ALTER TABLE inventory ADD INDEX idx_product (PRODUCT);
ALTER TABLE inventory ADD CONSTRAINT fk_inventory_product FOREIGN KEY (PRODUCT) REFERENCES bprice(PRODUCT);


         -- PRICE_DIFFERENCE -> BPRICE (needs an index first)
ALTER TABLE price_difference ADD INDEX idx_product (PRODUCT);
ALTER TABLE price_difference ADD CONSTRAINT fk_pricediff_product FOREIGN KEY (PRODUCT) REFERENCES bprice(PRODUCT);


             -- 10. AUTO-DEDUCT STOCK TRIGGER (when a sale is inserted)
/*
DELIMITER //

CREATE TRIGGER auto_deduct_stock
AFTER INSERT ON sales
FOR EACH ROW
BEGIN
    UPDATE inventory
    SET PCS_SOLD = PCS_SOLD + NEW.QUANTITY
    WHERE PRODUCT = NEW.PRODUCT;
END;
//

DELIMITER ;

-- CURRENT_PCS as auto-calculating generated column (no manual updates needed)
ALTER TABLE inventory DROP COLUMN CURRENT_PCS;
ALTER TABLE inventory ADD COLUMN CURRENT_PCS INT 
GENERATED ALWAYS AS (PCS_IN_INVENTORY - PCS_SOLD) STORED;
/*
