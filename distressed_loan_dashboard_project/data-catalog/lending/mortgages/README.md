# Mortgages Team

The Mortgages team owns mortgage loan data from origination through servicing, including loan applications, funded loans, payment history, and portfolio performance analytics.

## Team Responsibilities

- Mortgage application and origination data
- Loan servicing and payment processing
- Escrow account management
- Delinquency and loss mitigation tracking
- Portfolio performance monitoring and investor reporting

## Datasets

| Dataset | Layer | Description |
|---------|-------|-------------|
| [mortgage_originations.sqrl](mortgage_originations.sqrl) | Bronze | Applications, funded loans, property collateral, and borrower information |
| [mortgage_servicing.sqrl](mortgage_servicing.sqrl) | Bronze | Payments, escrow accounts, delinquency events, modifications, and valuations |
| [mortgage_performance.sqrl](mortgage_performance.sqrl) | Silver | Monthly performance snapshots, prepayment signals, and vintage analysis |

## Key Entities

- **Mortgage_Loan**: Primary funded loan record
- **Loan_Performance_Monthly**: Point-in-time portfolio snapshots
- **Vintage_Performance**: Cohort-level performance trends

## Data Governance

- **Classification**: Restricted
- **Regulatory Scope**: GLBA, GDPR, CCPA, HMDA, RESPA, TILA, ECOA, CFPB Servicing Rules
- **Data Steward**: Mortgage Operations
- **Refresh Frequency**: Realtime for bronze, monthly for silver

## Environments

- **-test**: Local data for testing
- **-prod**: Production data (Kafka or Iceberg)