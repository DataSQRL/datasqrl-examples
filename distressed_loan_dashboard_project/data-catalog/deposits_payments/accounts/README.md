# Accounts Team

The Accounts team owns deposit account data including account lifecycle management, balance tracking, and account-level analytics for the bank's deposit product portfolio.

## Team Responsibilities

- Deposit account master data (checking, savings, money market, CDs)
- Account ownership and holder management
- Daily balance snapshots and interest accruals
- Account dormancy monitoring and escheatment compliance

## Datasets

| Dataset | Layer | Description |
|---------|-------|-------------|
| [deposit_accounts.sqrl](deposit_accounts.sqrl) | Bronze | Account records, holders, status history, and product configuration |
| [account_balances.sqrl](account_balances.sqrl) | Bronze | Daily balance snapshots, interest accruals, and account holds |
| [account_analytics.sqrl](account_analytics.sqrl) | Silver | Activity summaries, balance trends, and dormancy signals |

## Key Entities

- **Account**: Primary deposit account record
- **Account_Balance_Daily**: Point-in-time balance snapshots
- **Dormancy_Signal**: Regulatory compliance for dormant account monitoring

## Data Governance

- **Classification**: Restricted
- **Regulatory Scope**: GLBA, GDPR, CCPA, Regulation E, Regulation DD
- **Data Steward**: Deposit Operations
- **Refresh Frequency**: Daily for bronze, daily for silver
