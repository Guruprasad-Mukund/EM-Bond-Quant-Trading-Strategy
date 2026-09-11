# Emerging Market Bond Quantitative Trading Strategy

## Overview

This project develops and evaluates a quantitative trading strategy for the **iShares J.P. Morgan USD Emerging Markets Bond ETF (EMB)**.

The goal is to test whether changes in global risk sentiment, credit conditions, and commodity markets can help predict **next-day EMB returns**.

The analysis uses three macro-financial predictors:

- **ΔVIX** — daily change in the Cboe Volatility Index
- **ΔCredit Spread** — daily change in the ICE BofA BB U.S. High Yield Option-Adjusted Spread
- **Oil Return** — daily log return of the crude oil price series used in the project

Three models are compared:

1. **VIX-Only OLS Regression**
2. **Three-Factor OLS Regression**
3. **Three-Factor Ridge Regression**

Each model is tested on both **prediction accuracy and trading performance**.

---

## Research Question

**Can changes in VIX, U.S. high-yield credit spreads, and crude oil prices predict next-day emerging-market bond returns and generate a profitable out-of-sample trading strategy?**

---

## Data

The analysis uses approximately **10 years of daily market data from 2016 through 2026**.

| Variable | Description | Transformation |
| --- | --- | --- |
| EMB Price | Historical EMB closing price | Daily log return |
| VIX | Cboe Volatility Index | Daily change |
| Credit Spread | ICE BofA BB U.S. High Yield Option-Adjusted Spread | Daily change |
| Oil Price | Crude oil price series | Daily log return |

The original datasets were imported into **PostgreSQL** and joined by trading date using SQL.

The final merged dataset contains:

date, emb_price, credit_spread, oil_price, vix


Feature engineering and statistical modeling were then completed in Python.

---

## Methodology

The project uses today's market information to predict the **next trading day's EMB return**.

The main features are:

em_return = log(EMB_t / EMB_t-1)
oil_return = log(Oil_t / Oil_t-1)
delta_vix = VIX_t - VIX_t-1
delta_spread = Spread_t - Spread_t-1


The prediction target is:

target_t = em_return_t+1


The dataset is divided chronologically into:

- **70% training data**
- **30% testing data**

The observations are not randomly shuffled because the project uses time-series data.

The out-of-sample testing period covers approximately **April 2023 through April 2026**.

---

## Exploratory Analysis

The exploratory analysis includes:

- Descriptive statistics
- Correlation analysis
- Scatterplots and fitted relationships
- Skewness and kurtosis
- Regression diagnostics

Approximate same-day correlations include:

| Relationship | Correlation |
| --- | ---: |
| ΔVIX vs. EMB Return | **-0.47** |
| ΔCredit Spread vs. EMB Return | **-0.35** |
| Oil Return vs. EMB Return | **+0.24** |
| ΔVIX vs. ΔCredit Spread | **+0.46** |

VIX and credit-spread increases tend to occur alongside lower EMB returns, while oil returns have a weaker positive relationship with EMB returns.

The financial variables also exhibit substantial **heavy tails**, reflecting the presence of unusually large market movements during periods of stress.

---

## Model 1 — VIX-Only OLS

The first model uses only today's change in VIX to predict tomorrow's EMB return.

The same-day relationship between ΔVIX and EMB returns is negative, while the estimated next-day coefficient is positive. This is consistent with a possible **short-term reversal** following volatility shocks.

However, using HC3 heteroskedasticity-robust standard errors, the ΔVIX coefficient is not statistically significant at the 5% level.

### Results

- **Test R²:** -1.01%
- **Annualized Sharpe Ratio:** 0.21
- **Test-Period Return:** 2.7%

The VIX-only model had limited ability to predict next-day EMB returns and produced relatively weak trading performance.

---

## Model 2 — Three-Factor OLS

The second model combines:

- Oil Return
- ΔVIX
- ΔCredit Spread

HC3 heteroskedasticity-robust standard errors are used for statistical inference.

The individual predictors are not statistically significant at the 5% level when combined in the multivariate model.

ΔVIX and ΔCredit Spread are moderately correlated, suggesting that they contain some overlapping information about financial-market stress.

### Results

- **Test R²:** -1.62%
- **Annualized Sharpe Ratio:** 0.84
- **Test-Period Return:** 12.9%

Although the model did not improve prediction of the exact size of next-day returns, it produced a much stronger trading signal than the VIX-only model.

---

## Model 3 — Ridge Regression

The third model applies **Ridge regression** to the same three predictors.

Before fitting Ridge, the predictors are standardized using StandardScaler so that variables measured on different scales are treated consistently.

Ridge adds a penalty that shrinks coefficients toward zero and can reduce model sensitivity when predictors contain overlapping information.

An alpha of **100** was selected using a rule-based tradeoff between model fit and regularization.

### Results

- **Test R²:** -1.49%
- **Annualized Sharpe Ratio:** 0.89
- **Test-Period Return:** 13.8%

Ridge produced a modest improvement over the three-factor OLS model in both test R² and trading performance.

---

## Trading Strategy

Each model predicts the next-day EMB return.

The trading rule is:

Predicted return > 0  → Invest in EMB
Predicted return ≤ 0  → Stay in cash


The strategy is **long-only** and does not short EMB.

Cash is assumed to earn a **0% return**.

Because the project uses log returns, cumulative portfolio values are calculated using:

np.exp(strategy_return.cumsum())

---

## Results

| Strategy | Test R² | Annualized Sharpe | Test-Period Return |
| --- | ---: | ---: | ---: |
| VIX-Only OLS | -1.01% | 0.21 | 2.7% |
| Three-Factor OLS | -1.62% | 0.84 | 12.9% |
| Three-Factor Ridge | -1.49% | 0.89 | 13.8% |
| Buy-and-Hold EMB | — | — | 9.0% |

All three models produced negative test R² values, meaning they were not very accurate at predicting the **exact size** of next-day EMB returns compared with a simple average-return benchmark.

However, the trading strategy mainly uses the **direction** of the prediction — positive or negative — to decide whether to invest in EMB or remain in cash.

The three-factor models therefore generated stronger trading performance despite weak return-magnitude forecasts.

---

## Key Findings

- Exact next-day EMB returns are difficult to predict.
- Combining VIX, credit spreads, and oil produced a stronger trading signal than using VIX alone.
- Ridge modestly improved the three-factor model's out-of-sample performance.
- Prediction accuracy and trading performance do not necessarily move together.
- A model can have weak return-magnitude predictions while still provide useful information for investment decisions.

---

## Limitations

The backtest is a simplified academic model rather than a directly deployable trading strategy.

Important limitations include:

- EMB returns are calculated using closing prices rather than dividend-adjusted prices.
- Because EMB pays cash distributions, some price declines may reflect distributions rather than actual investment losses.
- Transaction costs, bid-ask spreads, and slippage are excluded.
- Because the strategy trades more often than buy-and-hold, real-world trading costs could reduce some of its higher returns.
- Cash is assumed to earn 0%.
- The model does not directly include changes in the U.S. dollar or emerging-market currencies.
- EMB combines many countries with different economic, commodity, currency, and geopolitical exposures.
- Relationships between VIX, oil, credit spreads, and EMB may change over time.
---

## Potential Extensions

Future work could:

- Periodically retrain the model as new data become available
- Add a U.S. dollar or emerging-market currency factor
- Add a geopolitical risk indicator
- Analyze country-level emerging-market sovereign bonds
- Include transaction costs and a realistic cash yield
- Use dividend-adjusted EMB returns
- Test different trading thresholds rather than only using zero
- Select Ridge alpha more systematically using multiple training and validation periods

---

## Technologies Used

### Programming and Analysis

- Python
- pandas
- NumPy
- Matplotlib
- statsmodels
- scikit-learn
- Jupyter Notebook

### Database and Data Engineering

- PostgreSQL
- pgAdmin
- SQL

### Modeling

- Ordinary Least Squares Regression
- HC3 Heteroskedasticity-Robust Standard Errors
- Ridge Regression
- Predictor Standardization
- Chronological Train/Test Splitting
- Out-of-Sample Backtesting
- Sharpe Ratio Analysis

---

## Repository Structure

EM-Bond-Quant-Trading-Strategy/
│
├── README.md
├── requirements.txt
├── .gitignore
│
├── data/
│   ├── README.md
│   ├── raw/
│   │   ├── README.md
│   │   └── Original market datasets
│   └── processed/
│       ├── README.md
│       └── Merged market dataset
│
├── notebooks/
│   ├── README.md
│   └── EM_Bond_Quant_Trading_Strategy.ipynb
│
├── sql/
│   ├── README.md
│   ├── merge_market_data.sql
│   └── Quant Trading Model SQL Documentation.pdf
│
└── presentation/
    ├── README.md
    └── Final project presentation


---

## Installation

Install the required Python packages with:

bash
pip install -r requirements.txt


The project requires:

text
numpy
pandas
matplotlib
statsmodels
scikit-learn


---

## Conclusion

Predicting the exact magnitude of next-day EMB returns proved difficult, but combining economically motivated market factors produced a more useful trading signal.

The three-factor OLS strategy generated an annualized Sharpe ratio of approximately **0.84**, while Ridge increased it to approximately **0.89**.

The Ridge strategy returned approximately **13.8%** during the out-of-sample testing period, compared with approximately **9.0%** for buy-and-hold EMB.

Overall, the project demonstrates the importance of evaluating quantitative models using both **statistical prediction accuracy and economic trading performance**.

---

## Disclaimer

This project was developed for **academic and educational purposes only**.

Backtested results do not represent actual investment performance and should not be interpreted as investment advice.
