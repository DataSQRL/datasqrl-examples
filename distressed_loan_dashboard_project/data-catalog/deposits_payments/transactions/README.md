# Transactions Team

The Transactions team owns transaction data across all payment channels including core ledger transactions, card payments, ACH, and wire transfers, along with enriched transaction analytics.

## Team Responsibilities

- Core transaction ledger and posting
- Card authorization and settlement processing
- ACH and wire transfer processing
- Transaction enrichment and categorization
- Recurring payment detection

## Datasets

| Dataset | Layer | Description |
|---------|-------|-------------|
| [core_transactions.sqrl](core_transactions.sqrl) | Bronze | Primary transaction ledger, transaction types, and reversals |
| [card_transactions.sqrl](card_transactions.sqrl) | Bronze | Card authorizations, settlements, chargebacks, and MCC reference |
| [wire_ach_transactions.sqrl](wire_ach_transactions.sqrl) | Bronze | ACH transactions, wire transfers, and payment returns |
| [enriched_transactions.sqrl](enriched_transactions.sqrl) | Silver | Unified transactions, merchant enrichment, categories, and recurring payments |

## Key Entities

- **Transaction**: Primary ledger record for all account movements
- **Unified_Transaction**: Consolidated view across all transaction types
- **Recurring_Payment**: Detected recurring payment patterns

## Data Governance

- **Classification**: Restricted
- **Regulatory Scope**: GLBA, GDPR, CCPA, Regulation E, BSA, OFAC, PCI-DSS
- **Data Steward**: Payment Operations
- **Refresh Frequency**: Real-time for bronze, hourly for silver
