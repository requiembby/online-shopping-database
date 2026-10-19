# Online Shopping Database Management System

**University project | Webster University in Tashkent | COSC 4110 Database Concepts | July 2026**

**Author:** Charoskhon Farkhadova  
**Focus:** SQL • MySQL • Relational Database Design • Data Modeling • Data Integrity

## Overview

A database-layer implementation for a fictional online retailer. This academic project connects customers, product catalogs, suppliers, inventory, orders, discounts, payments, shipments, and product reviews in a consistent relational schema.

The project emphasizes translating business requirements into database structures and enforcing business rules with constraints, stored procedures, and triggers. **This is a database project, not a web application:** it does not include a frontend, production payment integration, or delivery APIs.

## Technical highlights

| Component | Implementation |
| --- | --- |
| Database | MySQL 8.0+ with InnoDB |
| Relational model | 13 tables and 16 foreign-key relationships |
| Normalization | Third Normal Form (3NF), with deliberate preservation of historical transaction values |
| Reusable logic | 5 stored procedures and 3 views |
| Automated integrity | 9 triggers |
| Demonstration data | 116 fictional sample rows |
| Reporting | 8 analytical queries |
| Operations | INSERT, UPDATE, DELETE and transaction examples |

## Database design

The schema models the relationships between customers and addresses, products and inventory, orders and order items, and payments and shipments. Primary keys, foreign keys, unique constraints, and check constraints help prevent inconsistent records.

**Business rules:** stock is reserved when order items are created, released on cancellation, and updated on fulfillment; order totals are kept consistent with line items, coupons, and tax logic.

## Repository files

- [`online_shopping_database.sql`](./online_shopping_database.sql) – complete SQL implementation, fictional sample dataset, views, procedures, triggers, and reporting queries.

## Running the project

**Requirements:** MySQL 8.0+ (MySQL Workbench recommended).

1. Use a **local or disposable development** MySQL instance. Never run this script against a production database.
2. Open `online_shopping_database.sql` in MySQL Workbench.
3. Execute the script from the beginning to create the database and populate the sample data.
4. Inspect the `online_shopping_db` schema and run the included analytical queries to explore reports and operational metrics.

> **Important:** The script begins with `DROP DATABASE IF EXISTS online_shopping_db;`, so it deletes and recreates a database with that exact name. Make sure it contains no data you need before executing the script.

## Security and scope notes

- All dataset records are **fictional examples** prepared for demonstration. Email and phone values have been sanitized for public sharing.
- The sample `password_hash` values are illustrative placeholders, **not secure production password hashes**.
- This project demonstrates relational integrity and database programming; it is not a production-ready ecommerce system and has not been independently security audited.

## Skills demonstrated

**SQL, MySQL, Database Design, ER Modeling, 3NF Normalization, Joins, Aggregation, Views, Stored Procedures, Triggers, Transactions, Data Integrity, Analytical Reporting, and Business Requirements Translation.**

---

**Related interests:** Database Engineering • Data Analytics • Business Analysis • Enterprise Information Systems

[GitHub profile](https://github.com/requiembby) · [LinkedIn](https://www.linkedin.com/in/charoskhon-farkhadova-2148a9307/)
