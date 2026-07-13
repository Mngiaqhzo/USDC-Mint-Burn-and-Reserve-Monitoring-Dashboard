```sql
-- ============================================================
-- File: 03_risk_status.sql
-- Project: USDC Mint, Burn and Reserve Monitoring
--
-- Purpose:
--   Assign GREEN, YELLOW, and RED statuses to:
--   1. Reserve coverage
--   2. Market price
--   3. Net burn activity
--
-- Setup:
--   Replace query_XXXXXXX with the Dune query ID of
--   02_supply_price_reserve.sql.
--
-- Example:
--   FROM query_1234567
--
-- The thresholds below are project assumptions.
-- They are not regulatory or issuer thresholds.
-- ============================================================

WITH monitoring_data AS (
    SELECT
        day,

        minted_amount,

        burned_amount,

        net_issuance,

        net_burn_amount,

        estimated_ethereum_supply,

        market_price_usd,

        report_date,

        reserve_assets_usd,

        reserve_source,

        reserve_coverage_ratio

    FROM query_XXXXXXX
),

individual_status AS (
    SELECT
        *,

        -- ----------------------------------------------------
        -- Reserve coverage status
        -- ----------------------------------------------------

        CASE
            WHEN reserve_coverage_ratio IS NULL
                THEN 'NO DATA'

            WHEN reserve_coverage_ratio < 1.000
                THEN 'RED'

            WHEN reserve_coverage_ratio < 1.005
                THEN 'YELLOW'

            ELSE 'GREEN'
        END AS coverage_status,

        -- ----------------------------------------------------
        -- Stablecoin price status
        -- ----------------------------------------------------

        CASE
            WHEN market_price_usd IS NULL
                THEN 'NO DATA'

            WHEN market_price_usd < 0.980
                THEN 'RED'

            WHEN market_price_usd < 0.995
                THEN 'YELLOW'

            ELSE 'GREEN'
        END AS price_status,

        -- ----------------------------------------------------
        -- Net burn status
        --
        -- Positive net burn means burns exceeded mints.
        -- It is used as a simplified redemption-pressure proxy.
        -- ----------------------------------------------------

        CASE
            WHEN net_burn_amount > 10000000
                THEN 'RED'

            WHEN net_burn_amount >= 5000000
                THEN 'YELLOW'

            ELSE 'GREEN'
        END AS net_burn_status

    FROM monitoring_data
),

overall_status AS (
    SELECT
        *,

        CASE
            WHEN coverage_status = 'RED'
              OR price_status = 'RED'
              OR net_burn_status = 'RED'
                THEN 'RED'

            WHEN coverage_status = 'YELLOW'
              OR price_status = 'YELLOW'
              OR net_burn_status = 'YELLOW'
                THEN 'YELLOW'

            WHEN coverage_status = 'NO DATA'
              OR price_status = 'NO DATA'
                THEN 'NO DATA'

            ELSE 'GREEN'
        END AS overall_risk_status

    FROM individual_status
)

SELECT
    day,

    reserve_assets_usd,

    estimated_ethereum_supply,

    reserve_coverage_ratio,

    market_price_usd,

    minted_amount,

    burned_amount,

    net_burn_amount,

    coverage_status,

    price_status,

    net_burn_status,

    overall_risk_status,

    CASE
        WHEN overall_risk_status = 'RED'
            THEN
                'Stop new minting, verify reserve data, '
                || 'review net burn activity, and escalate.'

        WHEN overall_risk_status = 'YELLOW'
            THEN
                'Verify data freshness and increase monitoring.'

        WHEN overall_risk_status = 'NO DATA'
            THEN
                'Complete missing reserve or price data before assessment.'

        ELSE
            'Continue normal daily monitoring.'
    END AS recommended_action

FROM overall_status

ORDER BY day DESC;
```

## Risk thresholds

| Indicator        | GREEN   | YELLOW      | RED    |
| ---------------- | ------- | ----------- | ------ |
| Reserve coverage | ≥100.5% | 100%–100.5% | <100%  |
| Market price     | ≥0.995  | 0.980–0.995 | <0.980 |
| Net burn         | <$5M    | $5M–$10M    | >$10M  |

## Overall-status logic

```text
Any RED indicator
→ Overall status is RED

No RED, but at least one YELLOW
→ Overall status is YELLOW

All indicators GREEN
→ Overall status is GREEN
```

## Suggested Dune table

Create a table visualization with:

```text
day
reserve_coverage_ratio
market_price_usd
net_burn_amount
coverage_status
price_status
net_burn_status
overall_risk_status
recommended_action
```

## Suggested dashboard layout

```text
---------------------------------------------------------
| USDC Stablecoin Monitoring Dashboard                  |
---------------------------------------------------------
| Daily Mint vs Burn       | Net Burn Trend             |
---------------------------------------------------------
| Reserve Coverage Ratio   | USDC Market Price          |
---------------------------------------------------------
| Daily Risk Monitoring Results                         |
---------------------------------------------------------
```
