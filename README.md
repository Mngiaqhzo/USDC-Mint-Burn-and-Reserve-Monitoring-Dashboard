# USDC Mint, Burn and Reserve Monitoring Dashboard

A beginner-level stablecoin monitoring project built with **Dune SQL**.

The project analyzes USDC minting, burning, circulating supply, reserve coverage, market price, and basic risk status.

The main purpose is to understand how on-chain stablecoin data can be combined with publicly reported off-chain reserve data.

---

## 1. Project Overview

A fiat-backed stablecoin should normally maintain enough reserve assets to support its circulating supply.

The basic relationship is:

```text
Reserve Assets >= Circulating Stablecoin Supply
```

The reserve coverage ratio is calculated as:

```text
Reserve Coverage Ratio
=
Reported Reserve Assets / Circulating Supply
```

This project monitors three simple indicators:

1. Reserve coverage ratio
2. Stablecoin market price
3. Net burn amount

The results are classified as:

* `GREEN`
* `YELLOW`
* `RED`

---

## 2. Why I Built This Project

My previous experience is mainly in traditional financial operations, including:

* Daily risk monitoring
* Data reconciliation
* Limit monitoring
* Exception handling
* Regulatory data checking
* Operational control testing

This project applies similar methods to a stablecoin environment.

Instead of reconciling only internal financial records, the project compares:

```text
On-chain token supply
with
Off-chain reported reserve assets
```

---

## 3. Project Scope

This is a beginner portfolio project.

It focuses on basic monitoring logic rather than building a complete production risk system.

The project includes:

* Daily USDC mint amount
* Daily USDC burn amount
* Net burn amount
* Estimated circulating supply
* Reported reserve assets
* Reserve coverage ratio
* Stablecoin market price
* Simple risk classification

The project does not include:

* Automated regulatory reporting
* Real-time alerts
* Bank API integration
* Automated reserve report extraction
* Production incident management
* Machine learning models

---

## 4. Data Sources

### On-Chain Data

The following data is queried using Dune SQL:

* ERC-20 transfer events
* Mint transactions
* Burn transactions
* Token supply changes
* Stablecoin price data

Minting is identified when tokens are transferred from the zero address:

```text
from = 0x0000000000000000000000000000000000000000
```

Burning is identified when tokens are transferred to the zero address:

```text
to = 0x0000000000000000000000000000000000000000
```

### Off-Chain Reserve Data

Stablecoin reserve assets are normally held in:

* Bank deposits
* Short-term government securities
* Money market funds
* Custodian accounts

These assets cannot normally be observed directly on-chain.

For this reason, reserve values are manually entered into the SQL query based on public reserve or attestation reports.

```sql
VALUES
    (DATE '2026-07-10', 101500000.0),
    (DATE '2026-07-11', 101200000.0),
    (DATE '2026-07-12', 100300000.0),
    (DATE '2026-07-13',  99500000.0)
```

The reserve data used in the sample scenario is simulated.

---

## 5. Core Calculations

### Daily Mint Amount

```text
Daily Mint Amount
=
Transfers from the zero address
```

### Daily Burn Amount

```text
Daily Burn Amount
=
Transfers to the zero address
```

### Net Burn Amount

```text
Net Burn Amount
=
Burned Amount - Minted Amount
```

In this beginner project, net burn is used as a proxy for net redemption pressure.

However, an on-chain burn does not always prove that an equivalent fiat redemption has already been completed.

### Estimated Circulating Supply

```text
Estimated Circulating Supply
=
Cumulative Mint Amount - Cumulative Burn Amount
```

### Reserve Coverage Ratio

```text
Reserve Coverage Ratio
=
Reported Reserve Assets / Circulating Supply
```

---

## 6. Alert Rules

The alert thresholds are project assumptions created for learning purposes.

They are not regulatory requirements.

### Reserve Coverage

| Status | Condition                                 |
| ------ | ----------------------------------------- |
| GREEN  | Coverage ratio is at least 100.5%         |
| YELLOW | Coverage ratio is between 100% and 100.5% |
| RED    | Coverage ratio is below 100%              |

### Market Price

| Status | Condition                        |
| ------ | -------------------------------- |
| GREEN  | Price is at least 0.995          |
| YELLOW | Price is between 0.980 and 0.995 |
| RED    | Price is below 0.980             |

### Net Burn

| Status | Condition                                      |
| ------ | ---------------------------------------------- |
| GREEN  | Net burn is below $5 million                   |
| YELLOW | Net burn is between $5 million and $10 million |
| RED    | Net burn is above $10 million                  |

### Overall Status

The overall status equals the highest risk level triggered by any indicator.

For example:

```text
Coverage Status: RED
Price Status: YELLOW
Net Burn Status: RED

Overall Status: RED
```

---

## 7. Example Results

| Date       | Reserve Coverage | Market Price | Net Burn | Status |
| ---------- | ---------------: | -----------: | -------: | ------ |
| 2026-07-10 |           101.5% |        1.000 |      $1M | GREEN  |
| 2026-07-11 |           101.2% |        0.998 |      $2M | GREEN  |
| 2026-07-12 |           100.3% |        0.993 |      $6M | YELLOW |
| 2026-07-13 |            99.5% |        0.981 |     $12M | RED    |

On July 13, the overall result becomes `RED` because:

* Reserve coverage is below 100%
* Net burn is above $10 million
* Market price is below the normal range

---

## 8. Recommended Actions

When the result is `GREEN`:

* Continue normal daily monitoring

When the result is `YELLOW`:

* Verify data freshness
* Increase monitoring frequency
* Review reserve and burn data

When the result is `RED`:

* Stop new minting
* Verify reserve data
* Review redemption pressure
* Escalate the exception for further investigation

A global smart contract pause should not be automatically triggered unless there is evidence of:

* A smart contract attack
* Private key compromise
* Unauthorized minting
* Abnormal on-chain activity

Reserve risk and smart contract risk require different control actions.

---

## 9. Dashboard Design

The Dune dashboard contains four visualizations.

### Mint and Burn Amount

Bar chart showing:

* Daily minted amount
* Daily burned amount

### Net Burn Trend

Line or bar chart showing:

* Daily burn minus daily mint

### Reserve Coverage Ratio

Line chart showing:

* Daily reserve coverage
* 100% reference level

### Monitoring Results

Table showing:

* Date
* Reserve assets
* Circulating supply
* Coverage ratio
* Market price
* Net burn
* Overall status

---

## 10. Repository Structure

```text
stablecoin-monitoring/
├── README.md
├── sql/
│   ├── 01_mint_burn.sql
│   ├── 02_reserve_monitoring.sql
│   └── 03_risk_status.sql
├── docs/
│   ├── methodology.md
│   └── incident_analysis.md
└── images/
    └── dashboard_preview.png
```

### SQL Files

`01_mint_burn.sql`

Calculates daily USDC mint, burn, and net burn amounts.

`02_reserve_monitoring.sql`

Combines circulating supply with manually entered reserve data.

`03_risk_status.sql`

Calculates reserve coverage and assigns GREEN, YELLOW, or RED risk status.

---

## 11. Limitations

This project has several limitations.

### Reserve Data Is Off-Chain

Reserve amounts are manually entered and are not independently verified by the SQL query.

### Burn Is Only a Redemption Proxy

A burn transaction does not always prove that fiat funds have already been paid to a customer.

### Ethereum Only

The current project monitors USDC on Ethereum only.

USDC also exists on other supported networks, so Ethereum supply does not represent total USDC supply across all chains.

### Simplified Thresholds

The risk thresholds are learning assumptions and do not represent official regulatory or issuer thresholds.

### Data Tables May Change

Dune table names and schemas may change. Queries may need to be updated based on current Dune documentation and available datasets.

---

## 12. What I Learned

Through this project, I learned:

* How ERC-20 minting and burning appear in transfer data
* How to calculate daily mint and burn amounts
* How to use SQL window functions for cumulative supply
* How to combine on-chain and off-chain data
* How to calculate reserve coverage
* How to create simple risk thresholds
* Why reserve risk differs from smart contract risk
* How traditional reconciliation methods can be applied to stablecoins

---

## 13. Resume Description

Developed a beginner-level USDC monitoring dashboard using Dune SQL. Analyzed Ethereum mint and burn activity, estimated circulating supply, combined on-chain data with simulated reserve information, calculated reserve coverage and net burn, and created GREEN, YELLOW, and RED risk indicators for reserve adequacy, price deviation, and redemption pressure.

---

## 14. Interview Explanation

This is a beginner-level stablecoin monitoring project built with Dune SQL.

I focused on three indicators: reserve coverage, market price, and net burn.

Mint and burn activity is identified from ERC-20 transfers involving the zero address. I then calculate the net burn amount and estimated circulating supply.

Because reserve assets are held off-chain, I manually enter simulated reserve data into the SQL query and compare it with the on-chain supply.

In the example scenario, reserve coverage falls below 100%, the market price falls to 0.981, and net burn rises above $10 million.

The result is classified as RED.

My recommended response is to stop new minting, verify the reserve data, and review redemption pressure.

I would not automatically pause all transfers because there is no evidence of a smart contract attack or private key compromise.

The project helped me understand how traditional reconciliation and risk monitoring methods can be applied to stablecoin operations.

---

## Disclaimer

This project is for educational and portfolio purposes only.

All reserve values, risk thresholds, incident data, and recommended actions are simplified project assumptions. They do not represent the internal procedures of Circle, USDC, Dune, or any other organization.
