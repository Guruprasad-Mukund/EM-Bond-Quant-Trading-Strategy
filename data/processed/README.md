# Processed Data

This directory contains the merged market dataset produced after SQL data preparation.

The four source datasets were aligned using an inner join on trading dates.

The resulting dataset contains:

- date
- emb_price
- credit_spread
- oil_price
- vix

The merged dataset is then imported into Python for feature engineering, exploratory analysis, regression modeling, and strategy backtesting.

The transformations used in Python include:

- EMB daily log returns
- Oil daily log returns
- Daily changes in VIX
- Daily changes in credit spreads
- Next-day EMB returns as the prediction target
