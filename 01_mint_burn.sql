WITH daily_mint_burn AS (
    SELECT
        block_date AS day,

        SUM(
            CASE
                WHEN "from" =
                    0x0000000000000000000000000000000000000000
                THEN amount
                ELSE 0
            END
        ) AS minted_amount,

        SUM(
            CASE
                WHEN "to" =
                    0x0000000000000000000000000000000000000000
                THEN amount
                ELSE 0
            END
        ) AS burned_amount

    FROM tokens.transfers

    WHERE blockchain = 'ethereum'

      AND contract_address =
          0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48

      AND block_date >= DATE '2026-07-01'

    GROUP BY 1
)

SELECT
    day,
    minted_amount,
    burned_amount,
    burned_amount - minted_amount AS net_burn_amount

FROM daily_mint_burn

ORDER BY day;
