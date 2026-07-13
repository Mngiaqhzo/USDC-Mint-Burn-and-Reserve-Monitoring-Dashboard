```sql
-- ============================================================
-- File: 02_supply_price_reserve.sql
-- Project: USDC Mint, Burn and Reserve Monitoring
--
-- Purpose:
--   1. Calculate estimated USDC supply on Ethereum.
--   2. Add the daily USDC market price.
--   3. Add manually entered reserve-report data.
--   4. Calculate the reserve coverage ratio.
--
-- Important limitations:
--   1. Supply calculated here covers Ethereum USDC only.
--   2. Reserve reports may cover USDC across multiple networks.
--   3. Do not compare Ethereum-only supply with global reserves
--      unless both figures use the same scope.
--   4. The reserve values below are placeholders.
-- ============================================================

WITH parameters AS (
    SELECT
        0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48
            AS token_address,

        0x0000000000000000000000000000000000000000
            AS zero_address,

        CURRENT_DATE - INTERVAL '90' DAY
            AS display_start_date
),

-- ------------------------------------------------------------
-- Manually entered reserve-report data
--
-- Replace these rows with figures taken from public reports.
-- Each reserve value will be carried forward until the next
-- report date.
-- ------------------------------------------------------------

reserve_reports AS (
    SELECT *
    FROM (
        VALUES
            (
                DATE '2026-04-30',
                CAST(101500000.00 AS DOUBLE),
                'SIMULATED'
            ),
            (
                DATE '2026-05-31',
                CAST(101200000.00 AS DOUBLE),
                'SIMULATED'
            ),
            (
                DATE '2026-06-30',
                CAST(100300000.00 AS DOUBLE),
                'SIMULATED'
            ),
            (
                DATE '2026-07-13',
                CAST(99500000.00 AS DOUBLE),
                'SIMULATED'
            )
    ) AS r(
        report_date,
        reserve_assets_usd,
        reserve_source
    )
),

-- Convert each reserve report into an effective date range.

reserve_periods AS (
    SELECT
        report_date,

        reserve_assets_usd,

        reserve_source,

        LEAD(
            report_date,
            1,
            DATE '9999-12-31'
        ) OVER (
            ORDER BY report_date
        ) AS next_report_date

    FROM reserve_reports
),

-- ------------------------------------------------------------
-- Calculate daily mint and burn amounts from all available
-- transfer history.
--
-- We calculate from the full history because starting from only
-- the last 90 days would not produce the total token supply.
-- ------------------------------------------------------------

daily_issuance AS (
    SELECT
        t.block_date AS day,

        SUM(
            CASE
                WHEN t."from" = p.zero_address
                    THEN t.amount
                ELSE 0
            END
        ) AS minted_amount,

        SUM(
            CASE
                WHEN t."to" = p.zero_address
                    THEN t.amount
                ELSE 0
            END
        ) AS burned_amount

    FROM tokens.transfers t

    CROSS JOIN parameters p

    WHERE t.blockchain = 'ethereum'

      AND t.contract_address = p.token_address

      AND (
          t."from" = p.zero_address
          OR t."to" = p.zero_address
      )

    GROUP BY 1
),

-- Calculate cumulative net issuance.

supply_history AS (
    SELECT
        day,

        minted_amount,

        burned_amount,

        minted_amount - burned_amount
            AS net_issuance,

        burned_amount - minted_amount
            AS net_burn_amount,

        SUM(
            minted_amount - burned_amount
        ) OVER (
            ORDER BY day
            ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
        ) AS estimated_ethereum_supply

    FROM daily_issuance
),

-- Retrieve USDC daily price from Dune's curated price table.

daily_price AS (
    SELECT
        CAST(pr.timestamp AS DATE) AS day,

        pr.price AS market_price_usd

    FROM prices.day pr

    CROSS JOIN parameters p

    WHERE pr.blockchain = 'ethereum'

      AND pr.contract_address = p.token_address
),

-- Join supply, price, and the reserve-report period.

combined_data AS (
    SELECT
        s.day,

        s.minted_amount,

        s.burned_amount,

        s.net_issuance,

        s.net_burn_amount,

        s.estimated_ethereum_supply,

        dp.market_price_usd,

        rp.report_date,

        rp.reserve_assets_usd,

        rp.reserve_source

    FROM supply_history s

    LEFT JOIN daily_price dp
        ON s.day = dp.day

    LEFT JOIN reserve_periods rp
        ON s.day >= rp.report_date
       AND s.day < rp.next_report_date
)

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

    reserve_assets_usd
        / NULLIF(estimated_ethereum_supply, 0)
        AS reserve_coverage_ratio

FROM combined_data

CROSS JOIN parameters p

WHERE day >= p.display_start_date

ORDER BY day DESC;
```

