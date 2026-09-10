# Raw Data

This directory contains the original market datasets collected before cleaning, database integration, and feature engineering.

The source series correspond to:

- EMB ETF historical closing prices
- Cboe VIX levels
- U.S. crude oil prices
- ICE BofA BB U.S. High Yield Option-Adjusted Spread

The files were imported into PostgreSQL as separate tables and subsequently aligned by date.

No return or change variables are calculated at this stage. Feature engineering is performed later in the Python notebook.
