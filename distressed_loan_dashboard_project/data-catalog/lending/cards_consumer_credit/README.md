# Cards & Consumer Credit Team

The Cards & Consumer Credit team owns credit card, personal loan, and auto loan data including account management, payments, and credit risk analytics.

## Team Responsibilities

- Credit card account and card management
- Personal and auto loan origination and servicing
- Payment processing and collections
- Credit risk signal generation and monitoring
- Portfolio credit quality analytics

## Datasets

| Dataset | Layer | Description |
|---------|-------|-------------|
| [credit_cards.sqrl](credit_cards.sqrl) | Bronze | Credit card accounts, cards, statements, payments, limit history, and delinquency |
| [consumer_loans.sqrl](consumer_loans.sqrl) | Bronze | Personal loans, auto loans, applications, payments, and delinquency events |
| [credit_risk_signals.sqrl](credit_risk_signals.sqrl) | Silver | Credit exposure, payment behavior, delinquency rollforward, and utilization |

## Key Entities

- **Credit_Card_Account**: Primary credit card account record
- **Personal_Loan / Auto_Loan**: Consumer installment loan records
- **Customer_Credit_Exposure**: Aggregated credit view per customer
- **Payment_Behavior**: Customer payment pattern analytics

## Data Governance

- **Classification**: Restricted
- **Regulatory Scope**: GLBA, GDPR, CCPA, FCRA, TILA, CARD Act, ECOA, PCI-DSS
- **Data Steward**: Consumer Credit Operations
- **Refresh Frequency**: Realtime for bronze, daily for silver

## Environments

- **-test**: Local data for testing
- **-prod**: Production data (Kafka or Iceberg)