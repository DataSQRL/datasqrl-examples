# Retail Bank Data Catalog

A data catalog covering the **bronze** (source) and **silver** (enriched/conformed) layers of a retail bank's data mesh. Tables are documented as SQRL `CREATE TABLE` definitions using Flink SQL syntax, organized by line of business and team.

## Catalog Index

| Line of Business | Team | Folder | Key Datasets |
|---|---|---|---|
| Customer | Customer Data | [customer/customer_data/](customer/customer_data/) | Customer master, KYC/AML, Customer profiles |
| Deposits & Payments | Accounts | [deposits_payments/accounts/](deposits_payments/accounts/) | Deposit accounts, Balances, Account analytics |
| Deposits & Payments | Transactions | [deposits_payments/transactions/](deposits_payments/transactions/) | Core transactions, Card/Wire/ACH, Enriched transactions |
| Lending | Mortgages | [lending/mortgages/](lending/mortgages/) | Originations, Servicing, Performance analytics |
| Lending | Cards & Consumer Credit | [lending/cards_consumer_credit/](lending/cards_consumer_credit/) | Credit cards, Consumer loans, Credit risk signals |

## Classification Levels

| Level | Description |
|---|---|
| **Public** | Disclosed publicly or intended for public use |
| **Internal** | Internal-by-default, low harm if disclosed |
| **Confidential** | Disclosure causes material harm or competitive damage |
| **Restricted** | Disclosure causes regulatory, legal, or significant customer harm (PII, NPI, PCI) |

## Sensitivity Tags

| Tag | Category |
|---|---|
| `@pii` | Personally Identifiable Information (name, address, phone, email, DOB) |
| `@spii` | Sensitive PII (SSN, passport, driver's license, biometrics) |
| `@npi` | GLBA Non-public Personal Information (account numbers, balances, transactions) |
| `@pci` | Payment Card Industry data (PAN, expiration, cardholder name) |
| `@confidential` | Internal sensitive but not personal (risk scores, pricing models) |

## Regulatory Scope Tags

`@glba` (Gramm-Leach-Bliley) | `@gdpr` (EU GDPR) | `@ccpa` (California CCPA/CPRA) | `@pci-dss` (PCI DSS) | `@bsa` (Bank Secrecy Act) | `@sox` (Sarbanes-Oxley)

## Handling Tags

| Tag | Required Handling |
|---|---|
| `@encrypt` | Encrypted at rest using platform key management |
| `@tokenize` | Original value replaced by token; raw value in vault only |
| `@mask` | Display masked outside production and to non-privileged consumers |
| `@erasable` | Subject to right-to-erasure (GDPR Art. 17, CCPA delete) |

## File Structure

Each `.sqrl` file contains:
- Header comment with layer, classification, and regulatory scope
- `CREATE TABLE` statements with JavaDoc-style comments
- Column-level sensitivity tags for all PII/NPI/PCI fields

Bronze tables include audit columns: `source_system`, `ingested_at`, `source_updated_at`
