# Jupyter Notebook

This directory contains the primary Python analysis for the project.

EM_Bond_Quant_Trading_Strategy.ipynb includes the complete quantitative workflow:

- Loading and validating the merged market dataset
- Feature engineering
- Descriptive statistics
- Correlation analysis
- Data visualization
- Bivariate OLS regressions
- VIX-only trading strategy
- Three-factor OLS regression
- HC3 heteroskedasticity-robust inference
- Ridge regression with standardized predictors
- Chronological train/test evaluation
- Sharpe ratio calculation
- Cumulative return backtesting
- Comparison with a buy-and-hold EMB benchmark

The notebook uses predictor information from time t to forecast EMB returns at time t+1.

The dataset is split chronologically into 70% training observations and 30% testing observations without random shuffling.
