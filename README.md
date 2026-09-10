# Emerging Market Bond Quantitative Trading Strategy

## Overview

This project develops and evaluates a quantitative trading strategy for the **iShares J.P. Morgan USD Emerging Markets Bond ETF (EMB)**.

The objective is to test whether changes in global risk sentiment, credit conditions, and commodity markets contain useful information for predicting **next-day EMB price returns**.

The analysis focuses on three macro-financial predictors:

- **ΔVIX** — daily change in the Cboe Volatility Index
- **ΔCredit Spread** — daily change in the ICE BofA BB U.S. High Yield Option-Adjusted Spread
- **Oil Return** — daily log return of the U.S. crude oil price series used in the project

The project progresses through three models:

1. **VIX-Only OLS Regression**
2. **Three-Factor OLS Regression**
3. **Three-Factor Ridge Regression**

Each model is evaluated using both statistical forecasting metrics and the performance of an out-of-sample **long-or-cash trading strategy**.

---

## Research Question

**Can changes in VIX, U.S. high-yield credit spreads, and crude oil prices predict next-day emerging-market bond returns and generate a profitable out-of-sample trading strategy?**

---

## Economic Motivation

Emerging-market sovereign bonds can be sensitive to changes in global financial conditions.

A rise in the **VIX** can indicate a shift toward risk aversion and a flight to safer assets.

A widening **high-yield credit spread** can signal deteriorating credit conditions and greater compensation demanded by investors for bearing risk.

Changes in **oil prices** can also affect emerging markets because many countries represented in emerging-market bond indices are commodity exporters or importers.

These variables therefore provide different, although partially overlapping, measures of global macroeconomic and financial-market conditions.

The purpose of the project is not only to determine whether these variables explain EMB returns statistically, but also whether their combined signals can produce economically useful trading decisions.

---

# Data

## Time Period

The dataset contains approximately **10 years of daily observations from 2016 through 2026**, resulting in more than 2,500 observations before feature engineering and missing-value removal.

## Variables

| Variable | Description | Transformation |
| --- | --- | --- |
| emb_price | Historical EMB closing price | Daily log return |
| vix | Cboe Volatility Index level | Daily first difference |
| credit_spread | ICE BofA BB U.S. High Yield Option-Adjusted Spread | Daily first difference |
| oil_price | U.S. crude oil price series | Daily log return |

The final merged dataset contains:

date, emb_price, credit_spread, oil_price, vix


---

# Data Engineering

The original market datasets were first loaded into **PostgreSQL** as separate tables.

SQL was then used to clean and integrate the data.

The workflow included:

- Converting date fields into PostgreSQL DATE format
- Standardizing date column names
- Verifying column data types
- Joining the EMB, VIX, credit-spread, and oil datasets on common trading dates
- Creating a final merged market-data table
- Checking the number of merged observations
- Checking for duplicate dates
- Exporting the merged dataset for analysis in Python

The SQL workflow is available in the [sql/](sql/) directory.

---

# Feature Engineering

The merged market dataset was imported into Python using pandas.

The following variables were constructed.

## EMB Return

EMB price returns are calculated as daily log returns:

python
df["em_return"] = np.log(
    df["emb_price"] / df["emb_price"].shift(1)
)


Mathematically:

$$
r^{EMB}_t =
\ln\left(
\frac{P^{EMB}_t}
{P^{EMB}_{t-1}}
\right)
$$

---

## Oil Return

Oil is also transformed into a daily log return:

python
df["oil_return"] = np.log(
    df["oil_price"] / df["oil_price"].shift(1)
)


$$
r^{Oil}_t =
\ln\left(
\frac{P^{Oil}_t}
{P^{Oil}_{t-1}}
\right)
$$

---

## Change in VIX

Because VIX is an index level rather than a directly traded asset price, the model uses the daily change in VIX rather than a return:

python
df["delta_vix"] = df["vix"].diff()


$$
\Delta VIX_t = VIX_t - VIX_{t-1}
$$

This variable captures changes in the level of market-implied volatility and risk sentiment.

---

## Change in Credit Spread

The high-yield credit spread is already expressed as a spread, so the analysis uses its daily change:

python
df["delta_spread"] = df["credit_spread"].diff()


$$
\Delta Spread_t =
Spread_t - Spread_{t-1}
$$

A positive value represents spread widening, while a negative value represents spread tightening.

---

## Next-Day Prediction Target

The models use information observed at time t to predict the EMB return at time t+1.

python
df["target"] = df["em_return"].shift(-1)


Therefore:

$$
Target_t = r^{EMB}_{t+1}
$$

This aligns today's predictor values with tomorrow's EMB return.

---

# Exploratory Data Analysis

Before developing the trading models, exploratory analysis was performed to understand the statistical characteristics of the variables and their relationships with EMB returns.

The analysis included:

- Descriptive statistics
- Correlation analysis
- Scatterplots
- Linear trend lines
- Skewness
- Excess kurtosis
- Regression diagnostics

---

## Same-Day Correlations

The correlation matrix showed the following approximate contemporaneous relationships:

| Relationship | Correlation |
| --- | ---: |
| ΔVIX vs. EMB Return | **-0.47** |
| ΔCredit Spread vs. EMB Return | **-0.35** |
| Oil Return vs. EMB Return | **+0.24** |
| ΔVIX vs. ΔCredit Spread | **+0.46** |

### ΔVIX and EMB

The strongest same-day relationship was between ΔVIX and EMB returns.

A correlation of approximately **-0.47** indicates that increases in market-implied volatility tend to coincide with declines in EMB prices.

This relationship is contemporaneous rather than predictive: the VIX movement and EMB return are measured on the same day.

---

## Credit Spreads and EMB

ΔCredit Spread had a same-day correlation of approximately **-0.35** with EMB returns.

When high-yield credit spreads widen, financial conditions generally become more risk-averse and investors demand greater compensation for holding risky debt.

EMB prices therefore also tend to decline during periods of spread widening.

---

## Oil Returns and EMB

Oil returns had a weaker positive same-day correlation of approximately **+0.24** with EMB returns.

Higher oil prices can benefit commodity-exporting emerging markets, but the relationship is not uniform because EMB contains countries with very different commodity exposures.

Oil-price increases can also occur because of geopolitical disruptions rather than stronger economic conditions.

---

## Relationship Between VIX and Credit Spreads

ΔVIX and ΔCredit Spread had a correlation of approximately **+0.46**.

This suggests that the two variables contain some overlapping information about global financial stress.

The correlation is meaningful but not sufficiently high to conclude that they contain identical information.

This overlap provides one motivation for later testing Ridge regression.

---

# Distributional Characteristics

The financial variables exhibited substantial skewness and heavy tails.

Using pandas:

python
df[
    ["em_return", "oil_return", "delta_vix", "delta_spread"]
].kurtosis()


produced large positive **excess kurtosis** values.

Because pandas reports excess kurtosis, a normal distribution has a value of **0**.

Large positive values indicate that extreme observations occur more frequently than they would under a normal distribution.

This is consistent with financial markets experiencing periods of unusually large price movements during crises and other market shocks.

---

# Train/Test Methodology

The dataset was divided chronologically into:

- **70% training data**
- **30% testing data**

The data were **not randomly shuffled** because the analysis is based on time-series observations.

python
split = int(len(df) * 0.7)

train = df.iloc[:split].copy()
test = df.iloc[split:].copy()


The training period is used to estimate model parameters.

The testing period is then used to evaluate the models on observations that were not used to estimate their coefficients.

The out-of-sample test period covers approximately **April 2023 through April 2026**.

---

# Model 1 — VIX-Only OLS Regression

The first model examines whether today's change in VIX can predict tomorrow's EMB return.

The model is:

$$
r^{EMB}_{t+1}
=
\alpha
+
\beta_1 \Delta VIX_t
+
\epsilon_t
$$

The estimated ΔVIX coefficient is approximately:

text
+0.0003


This produces an interesting difference between the same-day and next-day relationships.

The **same-day correlation is negative**, meaning a VIX spike generally coincides with an EMB decline.

However, the **next-day regression coefficient is positive**.

This sign reversal is consistent with a possible short-term rebound following volatility shocks: EMB prices may decline during the initial increase in market fear and partially recover afterward.

However, this interpretation should be considered suggestive rather than conclusive.

Using **HC3 heteroskedasticity-robust standard errors**, the ΔVIX coefficient has a p-value of approximately:

text
0.181


Therefore, the coefficient is **not statistically significant at the 5% level** under the robust specification.

---

## Model 1 Results

| Metric | Result |
| --- | ---: |
| Test R² | **-1.01%** |
| Annualized Sharpe Ratio | **0.21** |
| Ending Portfolio Value | **1.027** |
| Test-Period Return | **2.7%** |

The negative test R² indicates that the model has limited ability to predict the exact magnitude of next-day EMB returns.

The VIX-only strategy also underperformed the buy-and-hold EMB benchmark over the testing period.

---

# Model 2 — Three-Factor OLS Regression

The second model combines all three macro-financial signals:

- Oil Return
- ΔVIX
- ΔCredit Spread

The model is:

$$
r^{EMB}_{t+1}
=
\alpha
+
\beta_1 r^{Oil}_t
+
\beta_2 \Delta VIX_t
+
\beta_3 \Delta Spread_t
+
\epsilon_t
$$

The estimated OLS equation is approximately:

$$
\widehat{r}^{EMB}_{t+1}
=
-0.0001
+
0.0104(OilReturn_t)
+
0.0003(\Delta VIX_t)
+
0.0016(\Delta Spread_t)
$$

HC3 heteroskedasticity-robust standard errors were used for statistical inference.

The individual predictors were not statistically significant at the 5% level in the multivariate specification.

Approximate HC3 p-values were:

| Predictor | HC3 p-value |
| --- | ---: |
| Oil Return | 0.452 |
| ΔVIX | 0.268 |
| ΔCredit Spread | 0.742 |

One possible contributor is overlapping information among the predictors.

In particular, ΔVIX and ΔCredit Spread have a correlation of approximately **0.46**, which can increase coefficient uncertainty.

However, this should not be interpreted as evidence of extreme multicollinearity.

The model nevertheless performed substantially better as a **trading signal** than the single-factor VIX model.

---

## Model 2 Results

| Metric | Result |
| --- | ---: |
| Test R² | **-1.62%** |
| Annualized Sharpe Ratio | **0.84** |
| Ending Portfolio Value | **1.129** |
| Test-Period Return | **12.9%** |

Although the model's return-magnitude forecasting accuracy deteriorated relative to Model 1 based on test R², its trading performance improved substantially.

This demonstrates that **forecasting accuracy and trading usefulness are not necessarily the same thing**.

---

# Model 3 — Three-Factor Ridge Regression

The third model applies **Ridge regression** to the same three predictors.

Ridge regression adds an L2 penalty to the regression objective:

$$
\text{SSE}
+
\alpha
\sum_{j=1}^{p}\beta_j^2
$$

The penalty shrinks coefficients toward zero.

This can reduce model sensitivity when predictors contain overlapping information and can improve out-of-sample stability.

---

## Predictor Standardization

Before estimating the Ridge model, each predictor is standardized using:

python
StandardScaler()


Standardization transforms a variable approximately as:

$$
z =
\frac{x-\bar{x}}{s_x}
$$

This gives each predictor a mean near zero and a standard deviation near one.

Standardization is particularly important for Ridge regression because the penalty is applied to coefficient magnitudes.

Without standardization, variables measured on larger or smaller numerical scales could be penalized differently simply because of their measurement units.

---

## Standardized Ridge Coefficients

The standardized coefficients are approximately:

| Predictor | Standardized Coefficient |
| --- | ---: |
| Oil Return | 0.000245 |
| ΔVIX | 0.000512 |
| ΔCredit Spread | 0.000160 |

Standardized coefficients describe the effect associated with a **one-standard-deviation change** in each predictor.

Because all predictors are measured on a common scale, these coefficients are useful for comparing their relative weights within the Ridge model.

---

## Original-Unit Ridge Coefficients

The standardized Ridge coefficients can also be converted back into the variables' original measurement units.

These original units include:

- Oil daily log returns
- VIX index-point changes
- Credit-spread percentage-point changes

The corresponding coefficients are approximately:

| Predictor | Original-Unit Coefficient |
| --- | ---: |
| Oil Return | 0.009374 |
| ΔVIX | 0.000251 |
| ΔCredit Spread | 0.001609 |

The original-unit Ridge equation is approximately:

$$
\widehat{r}^{EMB}_{t+1}
=
-0.000139
+
0.009374(OilReturn_t)
+
0.000251(\Delta VIX_t)
+
0.001609(\Delta Spread_t)
$$

The standardized and original-unit coefficients represent the **same Ridge model**.

The standardized coefficients express predictor effects on a common standard-deviation scale, while the original-unit coefficients express the model using the variables' actual measurement units.

---

# Ridge Regularization Parameter

A range of Ridge penalty values was tested.

The project used a **fit-regularization trade-off heuristic** rather than selecting the penalty based on the testing sample.

The procedure was:

1. Calculate training R² for a range of alpha values.
2. Find the maximum training R².
3. Retain alpha values producing at least **99% of the maximum training R²**.
4. Select the largest eligible alpha to obtain stronger regularization while preserving nearly all of the model's training fit.

This resulted in:

text
alpha = 100


The selected model retained almost all of the maximum training R² while applying substantially more coefficient shrinkage.

This should be viewed as a modeling heuristic rather than a statistically unique or globally optimal value of alpha.

A future extension would use **time-series cross-validation** within the training sample to select the Ridge penalty.

---

## Model 3 Results

| Metric | Result |
| --- | ---: |
| Test R² | **-1.49%** |
| Annualized Sharpe Ratio | **0.89** |
| Ending Portfolio Value | **1.138** |
| Test-Period Return | **13.8%** |

Relative to the unregularized three-factor OLS model, Ridge produced:

- A slightly less-negative test R²
- A slightly higher Sharpe ratio
- A slightly higher cumulative return

The improvement is modest but suggests some benefit from coefficient shrinkage.

---

# Trading Strategy

Each model generates a predicted EMB return for the next trading day.

The trading rule is:

text
Predicted next-day EMB return > 0
→ Invest in EMB

Predicted next-day EMB return ≤ 0
→ Stay in cash


In Python:

python
signal = (predicted_return > 0).astype(int)


The realized strategy return is:

python
strategy_return = signal * actual_next_day_emb_return


Therefore:

$$
StrategyReturn_{t+1}
=
Signal_t
\times
r^{EMB}_{t+1}
$$

where:

text
Signal = 1 → Hold EMB
Signal = 0 → Hold cash


The strategy is **long-only** and never takes a short position in EMB.

---

# Cumulative Portfolio Returns

Because the strategy uses log returns, cumulative portfolio wealth is calculated using:

python
np.exp(strategy_return.cumsum())


rather than:

python
(1 + strategy_return).cumprod()


All strategies begin with a hypothetical portfolio value of:

text
$1.00


The ending portfolio values therefore represent how much one dollar would have grown to during the approximately three-year out-of-sample testing period.

---

# Sharpe Ratio

Daily Sharpe ratios are calculated as:

$$
Sharpe_{daily}
=
\frac{\overline{r}}
{\sigma_r}
$$

The project assumes a **0% risk-free/cash return**.

Daily Sharpe ratios are annualized using approximately 252 trading days:

$$
Sharpe_{annual}
=
Sharpe_{daily}
\sqrt{252}
$$

The resulting annualized Sharpe ratios are approximately:

| Model | Annualized Sharpe |
| --- | ---: |
| VIX-Only OLS | **0.21** |
| Three-Factor OLS | **0.84** |
| Three-Factor Ridge | **0.89** |

---

# Out-of-Sample Model Comparison

| Strategy | Test R² | Annualized Sharpe | Ending Value | Return |
| --- | ---: | ---: | ---: | ---: |
| VIX-Only OLS | -1.01% | 0.21 | 1.027 | 2.7% |
| Three-Factor OLS | -1.62% | 0.84 | 1.129 | 12.9% |
| Three-Factor Ridge | -1.49% | 0.89 | 1.138 | 13.8% |
| Buy-and-Hold EMB | — | — | 1.090 | 9.0% |

The Ridge strategy generated the strongest overall trading performance during the testing period.

---

# Statistical Fit vs. Trading Performance

One of the main findings of the project is that **statistical forecasting accuracy and economic trading performance can differ substantially**.

All three models produced negative test R² values.

A negative out-of-sample R² means the model performed worse at predicting the exact magnitude of next-day returns than a simple constant-mean prediction benchmark under squared-error loss.

However, the trading strategy does not directly use the magnitude of the prediction.

Instead, it converts each prediction into a binary decision:

text
Positive prediction → Invest
Negative prediction → Stay in cash


A model can therefore have weak return-magnitude predictions while still producing useful investment signals if the signs of its predictions systematically help the strategy participate in favorable periods or avoid unfavorable ones.

This helps explain why the three-factor models achieved substantially stronger Sharpe ratios despite having negative test R² values.

---

# Model Diagnostics

## Heteroskedasticity

Financial-market volatility is not necessarily constant over time.

Quiet markets can exhibit relatively small return fluctuations, while crises can produce much larger movements.

The OLS models therefore use **HC3 heteroskedasticity-robust standard errors**.

HC3 changes:

- Standard errors
- Confidence intervals
- Test statistics
- p-values

It does **not** change the estimated OLS coefficients themselves.

---

## Heavy Tails and Non-Normality

The data and regression residuals exhibit high kurtosis and substantial tail risk.

This suggests that large market movements occur more frequently than would be expected under a normal distribution.

---

## Serial Dependence

Durbin-Watson statistics for the regressions are slightly below 2.

Values near 2 generally indicate limited first-order residual autocorrelation.

Values slightly below 2 suggest **mild positive first-order autocorrelation**, meaning consecutive regression errors may be slightly positively related.

However, the statistics remain close to 2 and do not indicate strong first-order serial dependence.

---

## Predictor Overlap

ΔVIX and ΔCredit Spread have a correlation of approximately **0.46**.

The variables therefore contain some overlapping information about periods of financial stress.

This overlap can increase coefficient uncertainty in the multivariate OLS model.

Ridge regression is used to reduce coefficient sensitivity by shrinking the predictors rather than eliminating them from the model.

---

# Key Findings

## 1. Exact Next-Day Returns Are Difficult to Predict

All models produced negative out-of-sample R² values.

This highlights the high level of noise involved in forecasting daily financial-market returns.

---

## 2. Statistical Significance Did Not Guarantee Trading Performance

ΔVIX showed the strongest individual relationship among the predictors, but the VIX-only strategy produced an annualized Sharpe ratio of only approximately **0.21** and a cumulative return of approximately **2.7%**.

The multifactor models produced substantially stronger trading performance.

---

## 3. Combining Factors Improved the Trading Signal

Adding credit spreads and oil to VIX increased the amount of macro-financial information incorporated into the trading decision.

Although the three-factor model did not improve return-magnitude forecasting based on test R², it generated much stronger risk-adjusted trading performance.

---

## 4. Ridge Produced a Modest Improvement

Ridge improved the three-factor model's:

- Test R² from approximately **-1.62% to -1.49%**
- Annualized Sharpe ratio from approximately **0.84 to 0.89**
- Test-period return from approximately **12.9% to 13.8%**

The improvement suggests that coefficient shrinkage may provide some benefit when the predictors contain overlapping information.

---

## 5. Forecasting Accuracy and Economic Usefulness Are Different

Model 1 actually produced the least-negative test R², meaning it performed best among the three models at predicting return magnitudes according to that metric.

However, Models 2 and 3 generated much stronger trading results.

This demonstrates why quantitative strategies should be evaluated using both statistical forecasting metrics and economic performance measures.

---

# Risks and Limitations

## Closing Prices Rather Than Total Returns

EMB returns are calculated using historical closing prices rather than dividend-adjusted prices.

Because EMB makes regular cash distributions, the analysis measures **price returns rather than total investor returns**.

An ex-dividend decline in the ETF price may therefore appear as a negative return even though an investor received a cash distribution.

As a result, both the trading strategy and the buy-and-hold benchmark may understate total investor returns.

---

## Transaction Costs

The backtest assumes costless trading.

It does not include:

- Bid-ask spreads
- Brokerage costs
- Slippage
- Market impact
- Taxes

Because the strategy can move between EMB and cash repeatedly, transaction costs could reduce or potentially eliminate part of its apparent advantage over buy-and-hold.

---

## Zero Cash Return

When the strategy does not invest in EMB, cash is assumed to earn:

text
0%


In reality, cash could earn a positive short-term interest rate such as a Treasury-bill or money-market yield.

A more realistic backtest would include a daily risk-free return for periods when the model remains in cash.

---

## VIX Information May Be Incorporated Quickly

VIX is one of the most widely observed measures of market risk.

Changes in VIX can be incorporated into asset prices quickly.

This may help explain why VIX has a strong contemporaneous relationship with EMB returns but relatively limited standalone next-day forecasting ability.

---

## U.S. Dollar and FX Risk Are Omitted

Many emerging-market sovereign borrowers issue debt denominated in U.S. dollars.

A stronger U.S. dollar can increase the local-currency burden of servicing dollar-denominated debt.

Dollar strength can also be associated with:

- Capital outflows from emerging markets
- Tighter financial conditions
- Currency depreciation
- Increased sovereign credit stress

The current model does not directly incorporate a broad U.S. dollar or emerging-market FX factor.

---

## EMB Aggregates Many Countries

EMB represents a diversified portfolio of emerging-market sovereign debt.

Countries in the index have very different exposures to:

- Commodities
- Geopolitical events
- Exchange rates
- Inflation
- Monetary policy
- Fiscal conditions
- Capital flows

Aggregating these countries into a single ETF can dilute country-specific relationships between macroeconomic shocks and sovereign bond returns.

---

## Changing Market Regimes

The 70/30 train/test framework estimates each model using a fixed historical training sample.

However, relationships among VIX, oil, credit spreads, and emerging-market bonds may change across:

- Monetary-policy regimes
- Recessions
- Financial crises
- Inflation regimes
- Geopolitical shocks

The model therefore assumes more stability in factor relationships than may exist in practice.

---

## Execution Timing

The predictors use daily market information at time t to predict the return at time t+1.

A fully implementable strategy would also need to specify exactly when each predictor becomes observable and at what price the EMB trade can be executed.

The current backtest does not explicitly model intraday execution timing.

---

## Ridge Alpha Selection

The Ridge penalty was selected using a training-R²-based fit-regularization heuristic.

Although the testing data were not used as the formal selection criterion, a more rigorous approach would use time-series cross-validation entirely within the training sample.

---

# Potential Extensions

## Rolling or Expanding Model Estimation

Rather than estimating coefficients once using the entire training sample, the model could be periodically re-estimated.

Possible approaches include:

- Rolling-window estimation
- Expanding-window estimation
- Walk-forward backtesting

This would allow factor relationships to evolve as financial-market regimes change.

---

## Add a U.S. Dollar or EM-FX Factor

A future model could incorporate:

- A broad U.S. dollar index
- Emerging-market currency returns
- Country-specific exchange-rate movements

This could capture financial pressures associated with dollar appreciation and EM currency depreciation that are not fully reflected in VIX, credit spreads, or oil.

---

## Add a Geopolitical Risk Factor

The **Caldara-Iacoviello Geopolitical Risk Index** could be incorporated as an additional predictor.

The objective would be to test whether changes in geopolitical risk provide incremental out-of-sample predictive information beyond the existing factors.

---

## Country-Level Emerging-Market Bonds

Rather than trading one diversified EMB ETF, future work could analyze individual countries or country-specific sovereign bond indices.

A country-level model could incorporate exposures such as:

- Oil dependence
- Currency depreciation
- Sovereign credit quality
- Inflation
- Political risk
- Fiscal conditions

Predicted returns could then be used to construct a portfolio across emerging markets.

---

## Transaction Costs and Cash Yield

A more realistic strategy could explicitly incorporate:

- Bid-ask spreads
- Trading costs
- Slippage
- Turnover
- Short-term Treasury or cash returns

This would provide a more realistic estimate of implementable strategy performance.

---

## Dividend-Adjusted EMB Returns

Future analysis could replace raw historical closing prices with a dividend-adjusted or total-return EMB series.

This would provide a more accurate comparison between the active strategy and long-term buy-and-hold investing.

---

## Time-Series Cross-Validation for Ridge

Instead of the current 99%-of-training-R² heuristic, the Ridge penalty could be selected using:

python
TimeSeriesSplit


Alpha would be selected using validation periods inside the training sample.

The final model could then be re-estimated on the complete training set and evaluated once on the untouched testing period.

---

# Technologies Used

## Programming and Analysis

- **Python**
- **pandas**
- **NumPy**
- **Matplotlib**
- **statsmodels**
- **scikit-learn**
- **Jupyter Notebook**

## Database and Data Engineering

- **PostgreSQL**
- **pgAdmin**
- **SQL**

## Modeling Techniques

- Ordinary Least Squares Regression
- HC3 Heteroskedasticity-Robust Standard Errors
- Ridge Regression
- Predictor Standardization
- Chronological Train/Test Splitting
- Out-of-Sample Backtesting
- Sharpe Ratio Analysis
- Cumulative Portfolio Return Analysis

---

# Repository Structure

text
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
│   │
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

# Python Requirements

The project uses the following Python packages:

text
numpy
pandas
matplotlib
statsmodels
scikit-learn


Install them using:

bash
pip install -r requirements.txt


---

# Reproducing the Analysis

The general workflow is:

1. Obtain the four underlying market datasets.
2. Import the datasets into PostgreSQL.
3. Run the SQL workflow in [sql/merge_market_data.sql](sql/merge_market_data.sql).
4. Export the merged dataset.
5. Place the processed dataset in the data/processed/ directory.
6. Open the Jupyter Notebook in the [notebooks/](notebooks/) directory.
7. Run the notebook cells sequentially to reproduce the exploratory analysis, models, and backtests.

The Python notebook expects the processed dataset to contain:

text
date
emb_price
credit_spread
oil_price
vix


---

# Conclusion

The project finds that predicting the **exact magnitude** of next-day EMB returns is difficult.

All three models produced negative out-of-sample R² values.

However, combining VIX, credit spreads, and oil produced a substantially stronger trading signal than using VIX alone.

The three-factor OLS strategy generated an annualized Sharpe ratio of approximately **0.84**, while Ridge increased the Sharpe ratio to approximately **0.89**.

The Ridge strategy also ended the approximately three-year testing period with a portfolio value of approximately **1.138**, compared with approximately **1.090** for buy-and-hold EMB.

The results therefore illustrate an important distinction:

> **A model can have weak return-magnitude forecasting accuracy while still contain economically useful information for trading decisions.**

At the same time, the results should not be interpreted as evidence of a deployable trading strategy without further testing.

Transaction costs, dividend-adjusted returns, cash yields, execution timing, changing market regimes, and additional macro-financial factors would need to be incorporated before drawing stronger conclusions about real-world profitability.

---

# Disclaimer

This project was developed for **academic and educational purposes only**.

The results are based on historical data and a simplified backtesting framework.

They do not represent actual investment performance and should not be interpreted as investment advice.
