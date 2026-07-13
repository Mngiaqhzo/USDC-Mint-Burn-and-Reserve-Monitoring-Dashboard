```sql
-- ============================================================
-- File: 01_mint_burn.sql
-- Project: USDC Mint, Burn and Reserve Monitoring
--
-- Purpose:
--   Calculate daily USDC mint, burn, net issuance,
--   and net burn activity on Ethereum.
--
-- Notes:
--   1. A transfer from the zero address is treated as a mint.
--   2. A transfer to the zero address is treated as a burn.
--   3. Net burn is used only as a proxy for redemption pressure.
--   4. A burn does not prove that fiat redemption was completed.
-- ============================================================

WITH parameters AS (
    SELECT
        0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48
            AS token_address,

        0x0000000000000000000000000000000000000000
            AS zero_address,

        CURRENT_DATE - INTERVAL '90' DAY
            AS start_date
),

daily_mint_burn AS (
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

      AND t.block_date >= p.start_date

      AND (
          t."from" = p.zero_address
          OR t."to" = p.zero_address
      )

    GROUP BY 1
)

SELECT
    day,

    minted_amount,

    burned_amount,

    minted_amount - burned_amount
        AS net_issuance,

    burned_amount - minted_amount
        AS net_burn_amount,

    CASE
        WHEN burned_amount > minted_amount
            THEN 'NET BURN'

        WHEN minted_amount > burned_amount
            THEN 'NET MINT'

        ELSE 'NO CHANGE'
    END AS daily_activity

FROM daily_mint_burn

ORDER BY day DESC;
```

