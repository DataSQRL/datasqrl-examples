# Customer Data Team

The Customer Data team owns foundational customer identity, demographics, and compliance data that serves as the authoritative source for customer information across all lines of business.

## Team Responsibilities

- Customer master data management and data quality
- KYC/AML compliance data and screening results
- Customer segmentation and household management
- Customer lifetime value calculations

## Datasets

| Dataset | Layer | Description |
|---------|-------|-------------|
| [customer_master.sqrl](customer_master.sqrl) | Bronze | Core customer identity, demographics, addresses, contacts, employment, and relationships |
| [kyc_aml.sqrl](kyc_aml.sqrl) | Bronze | KYC verification, sanctions screening, PEP screening, and customer risk ratings |
| [customer_enriched.sqrl](customer_enriched.sqrl) | Silver | Consolidated customer profiles, segmentation, households, and lifetime value |

## Key Entities

- **Customer**: Primary customer identity record
- **Customer_Profile**: Enriched 360-degree customer view
- **Customer_Risk_Rating**: AML risk assessment for compliance monitoring

## Data Governance

- **Classification**: Restricted
- **Regulatory Scope**: GLBA, GDPR, CCPA, FCRA, BSA
- **Data Steward**: Customer Data Management
- **Refresh Frequency**: Real-time for bronze, hourly for silver

## Environments

- **-test**: Local data for testing
- **-prod**: Production data (Kafka or Iceberg)