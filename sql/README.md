# SQL Data Preparation

This directory contains the PostgreSQL queries used to clean, standardize, and integrate the four underlying market datasets.

The SQL workflow performs the following steps:

- Converts raw date fields into PostgreSQL DATE format
- Standardizes the date column name across tables
- Verifies column data types
- Joins EMB, credit spread, crude oil, and VIX data using common trading dates
- Creates the final merged market-data table
- Checks the number of merged observations
- Checks for duplicate dates

merge_market_data.sql contains the executable SQL workflow.

Quant Trading Model SQL Documentation.pdf contains additional documentation, outputs, and explanatory notes from the database preparation process.

Return calculations and other model features are created later in Python rather than in SQL.
