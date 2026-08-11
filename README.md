# Supermarket Sales & Inventory Analytics System

**End-to-end data project:** relational database design → SQL analysis → Power BI dashboard, built from scratch to answer real business questions for a supermarket's pricing, sales, and inventory operations.

---

## Project Overview

A supermarket needed a way to track **what it buys, what it sells, and what's left in stock** — and to answer questions like *"who's my best salesperson this month?"* or *"which orders are losing us money?"* without digging through spreadsheets by hand.

This project builds that system from the ground up, starting from raw spreadsheet data:

1. **Data structuring in Excel** — 4 related tables (purchasing, sales, inventory, pricing) built with formulas, VLOOKUP/SUMIF linking, and conditional formatting for stock alerts
2. **Migrated into a relational database** in MySQL with enforced relationships and an automated stock-deduction trigger
3. **An interactive Power BI dashboard** answering 9+ specific business questions with live, filterable visuals

---

## Tools Used

- **Microsoft Excel** — initial data structuring, VLOOKUP/SUMIF for cross-table linking, conditional formatting for stock alerts, formula-driven inventory tracking
- **MySQL / MySQL Workbench** — database schema, foreign keys, triggers, generated columns, analytical SQL queries
- **Power BI Desktop** — data modeling, DAX measures, interactive dashboard

---

## Data Model

Four tables, connected through a shared `PRODUCT` field:

| Table | Purpose | Rows |
|---|---|---|
| **BPRICE** | What was purchased — store, category, product, cost, transport | 109 products |
| **SALES** | Every individual sale — date, salesperson, product, quantity, selling price | 373 transactions |
| **INVENTORY** | Stock tracking — units purchased, sold, and remaining | 109 products |
| **PRICE_DIFFERENCE** | Buying price vs. selling price comparison per product | 109 products |

**Relationships:** BPRICE acts as the central hub, linked to SALES (one-to-many, since one product can be sold repeatedly) and to INVENTORY / PRICE_DIFFERENCE (one-to-one, since each product appears once in those tables).

---

## Key SQL Features Implemented

- **Foreign key constraints** across all 4 tables, enforced at the database level — prevents any sale from referencing a product that was never purchased
- **A trigger** that automatically deducts sold quantity from inventory the moment a sale is inserted — no manual stock updates required:
  ```sql
  CREATE TRIGGER auto_deduct_stock
  AFTER INSERT ON sales
  FOR EACH ROW
  BEGIN
      UPDATE inventory
      SET PCS_SOLD = PCS_SOLD + NEW.QUANTITY
      WHERE PRODUCT = NEW.PRODUCT;
  END;
  ```
- **A generated column** for `CURRENT_PCS` that always self-calculates (`PCS_IN_INVENTORY - PCS_SOLD`) — impossible for it to go out of sync
- **Window functions** (`RANK() OVER (PARTITION BY ...)`) for month-by-month ranking of top performers and top products

---

## Business Questions Answered

Every question below was solved with a dedicated SQL query and/or a live Power BI visual:

1. **Who are the top 2 salespeople by revenue, in every month?**
2. **How does each salesperson's performance trend across the full period?**
3. **What are the top 2 best-selling products, every month?**
4. **What quarters does the dataset actually cover?**
5. **What's the profit, broken down by week / month / quarter?**
6. **Which orders were sold below buying price (i.e., at a loss), and by how much?**
7. **How many total units were sitting in inventory before any sales happened?**
8. **How does total profit compare across salespeople?**
9. **How are the core tables (purchasing and sales) formally linked for analysis?**

---

## Power BI Dashboard

A single-page interactive dashboard combining:
- Monthly profit trend (column chart)
- Salesperson performance over time (line/column, one series per person)
- Top 2 salespeople per month (ranked, dynamically filtered)
- Top 2 products per month
- Profit by quarter
- A live table of every below-cost sale (loss tracking)
- Salesperson profit comparison (ranked bar chart)
- Total starting stock (KPI card)

All visuals are cross-filterable — clicking any bar filters the rest of the dashboard.

---

## What I'd Do Next

- Add a proper Date table with `CALENDAR()` for cleaner time-intelligence (YoY comparisons, running totals)
- Build a second dashboard page covering inventory health and profit margin % by product
- Publish to Power BI Service for live sharing instead of static exports

---

## About This Project

Built as a hands-on learning + portfolio project — covering the full pipeline from raw spreadsheet data to a database-backed, business-ready dashboard. Available for similar data analysis, SQL database design, or Power BI dashboard work.
