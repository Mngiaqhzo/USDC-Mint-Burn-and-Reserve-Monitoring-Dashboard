# Methodology

## 1. Objective

The purpose of this project is to build a simple monitoring model for a fiat-backed stablecoin.

The model combines:

* On-chain mint and burn data
* Estimated circulating supply
* Off-chain reserve information
* Stablecoin market price
* Basic risk thresholds

The project uses Dune SQL for data processing and visualization.

---

## 2. Mint and Burn Identification

ERC-20 minting and burning can normally be identified through transfer events involving the zero address.

### Mint

A mint occurs when the transfer sender is the zero address.

```sql
CASE
    WHEN "from" =
        0x0000000000000000000000000000000000000000
    THEN amount
    ELSE 0
END
```

### Burn

A burn occurs when the transfer recipient is the zero address.

```sql
CASE
    WHEN "to" =
        0x0000000000000000000000000000000000000000
    THEN amount
    ELSE 0
END
```

---

## 3. Net Burn Calculation

Net burn is calculated as:

```text
Net Burn = Burned Amount - Minted Amount
```

A positive result means more tokens were burned than minted during the period.

A negative result means more tokens were minted than burned.

In this project, net burn is treated as an approximate indicator of redemption pressure.

This is a simplification because a token burn does not necessarily confirm that fiat redemption has already been completed.

---

## 4. Circulating Supply

Estimated circulating supply is calculated using cumulative net issuance.

```sql
SUM(minted_amount - burned_amount)
OVER (
    ORDER BY day
    ROWS BETWEEN UNBOUNDED PRECEDING
    AND CURRENT ROW
)
```

This method calculates:

```text
Total Minted Amount - Total Burned Amount
```

For a production analysis, the result should be checked against an official token supply source.

---

## 5. Reserve Data

Reserve assets are held off-chain and cannot normally be observed directly from Ethereum.

Reserve information must therefore come from an external source, such as:

* Issuer reserve reports
* Attestation reports
* Audit reports
* Transparency reports

For the beginner version of this project, reserve values are entered manually through a SQL `VALUES` table.

```sql
WITH reserve_data AS (
    SELECT *
    FROM (
        VALUES
            (DATE '2026-07-10', 101500000.0),
            (DATE '2026-07-11', 101200000.0),
            (DATE '2026-07-12', 100300000.0),
            (DATE '2026-07-13',  99500000.0)
    ) AS t(day, reserve_assets_usd)
)
```

These values are simulated and are not real USDC reserve figures.

---

## 6. Reserve Coverage

Reserve coverage is calculated as:

```text
Reserve Coverage
=
Reported Reserve Assets / Circulating Supply
```

Example:

```text
Reserve Assets: $101.5 million
Circulating Supply: $100 million

Reserve Coverage: 101.5%
```

A ratio below 100% is classified as RED in this simplified model.

---

## 7. Risk Classification

Each indicator receives an individual status.

### Reserve Coverage Status

```sql
CASE
    WHEN coverage_ratio < 1
        THEN 'RED'
    WHEN coverage_ratio < 1.005
        THEN 'YELLOW'
    ELSE 'GREEN'
END
```

### Price Status

```sql
CASE
    WHEN market_price < 0.980
        THEN 'RED'
    WHEN market_price < 0.995
        THEN 'YELLOW'
    ELSE 'GREEN'
END
```

### Net Burn Status

```sql
CASE
    WHEN net_burn_amount > 10000000
        THEN 'RED'
    WHEN net_burn_amount >= 5000000
        THEN 'YELLOW'
    ELSE 'GREEN'
END
```

### Overall Status

The overall result equals the highest risk status triggered by any individual indicator.

```text
RED takes priority over YELLOW.
YELLOW takes priority over GREEN.
```

---

## 8. Interpretation

A RED reserve result does not automatically mean the smart contract should be globally paused.

The first recommended actions are:

* Stop new minting
* Verify reserve information
* Review burn activity
* Increase monitoring frequency

A global pause is more appropriate when there is evidence of:

* Contract exploitation
* Unauthorized minting
* Private key compromise
* Abnormal token transfers

This distinction is one of the main conclusions of the project.

---

## 9. Limitations

The model is simplified.

It does not fully measure:

* Cross-chain supply
* Actual completed fiat redemptions
* Reserve asset liquidity
* Custodian concentration
* Banking settlement delays
* Market depth
* Customer-level redemption requests
* AML or sanctions risk

The project should therefore be viewed as a learning model rather than a production risk system.
