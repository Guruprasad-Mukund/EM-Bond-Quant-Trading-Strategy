ALTER TABLE emb_etf
ALTER COLUMN "Date" TYPE date
USING to_date("Date", 'MM/DD/YYYY');

ALTER TABLE credit_spreads
ALTER COLUMN "Date" TYPE date
USING to_date("Date", 'MM/DD/YYYY');

ALTER TABLE uso_crude
ALTER COLUMN "Date" TYPE date
USING to_date("Date", 'MM/DD/YYYY');

ALTER TABLE "VIX"
ALTER COLUMN "Date" TYPE date
USING to_date("Date", 'MM/DD/YYYY');

ALTER TABLE emb_etf RENAME COLUMN "Date" TO date;
ALTER TABLE credit_spreads RENAME COLUMN "Date" TO date;
ALTER TABLE uso_crude RENAME COLUMN "Date" TO date;
ALTER TABLE "VIX" RENAME COLUMN "Date" TO date;

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'emb_etf';

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'credit_spreads';

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'uso_crude';

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'VIX';

CREATE TABLE merged_data AS
SELECT
    e.date,
    e.emb_price,
    c.credit_spread,
    o.oil_price,
    v.vix
FROM emb_etf e
INNER JOIN credit_spreads c
    ON e.date = c.date
INNER JOIN uso_crude o
    ON e.date = o.date
INNER JOIN "VIX" v
    ON e.date = v.date
ORDER BY e.date;

SELECT *
FROM merged_data
LIMIT 20;

SELECT COUNT(*)
FROM merged_data;

SELECT date, COUNT(*)
FROM merged_data
GROUP BY date
HAVING COUNT(*) > 1;
