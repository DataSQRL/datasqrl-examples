# Data Package for the Finance Credit Card Chatbot Example

This data package is used by the Finance Credit Card Chatbot example which demonstrates how DataSQRL enables real-time
analytics and a rewards program based on credit card transactions. It showcases how to aggregate, enrich, and process
streaming data to provide insights into customer spending and credit card rewards, all within a compact data pipeline.

The data pipeline processes transactions to deliver insights such as customer spending per category, rewards earned,
and potential rewards based on different card types. With DataSQRL, this complex pipeline is created with minimal code.

## Data Overview

The following are the four main datasets involved in the data processing pipeline, each represented in JSON format. These datasets are:
- Card Assignment Data
- Merchant Data
- Merchant Reward Data
- Transaction Data

Each dataset has a unique structure, and its elements are described below with sample records.

#### Card Assignment Data

This dataset represents the assignment of credit cards to customers. Each card has an associated customer, a card number,
and a card type (e.g., "family", "travel"). The timestamp indicates when the card assignment was made.

Fields:
- customerId: Unique identifier for the customer.
- cardNo: Credit card number (in string format).
- timestamp: Time of card assignment in ISO 8601 format (UTC).
- cardType: The category of the card (e.g., "family", "travel"). This may be blank if unspecified.

Sample Record:
```json
{"customerId": 1, "cardNo": "379261260820130", "timestamp": "2024-02-25T00:00:00Z", "cardType": "family"}
```

####  Merchant Data

This dataset holds information about merchants where transactions occur. Each merchant has a unique ID, a name,
a category of goods or services they provide, and an updated timestamp.

Fields:
- merchantId: Unique identifier for the merchant.
- name: The name of the merchant.
- category: The type of goods or services provided by the merchant (e.g., "Clothing & Apparel", "Housing & Utilities").
- updatedTime: The time when this merchant information was last updated, in ISO 8601 format.

Sample Record:
```json
{"merchantId": 57, "name": "Blanda-Weissnat", "category": "Housing & Utilities", "updatedTime": "2024-02-25T00:00:00Z"}
```

#### Merchant Reward Data

This dataset provides information on rewards offered by specific merchants for different card types. Each merchant may offer different reward percentages depending on the card type, with each reward having a start and expiration date.

Fields:
- merchantId: Unique identifier for the merchant.
- rewardsByCard: An array of reward structures associated with specific card types. Each entry in the array includes:
- cardType: The type of card eligible for the reward (e.g., "travel", "sports").
- rewardPercentage: The percentage of reward offered on purchases with this card type.
- startTimestamp: Start of the reward period in Unix epoch time.
- expirationTimestamp: End of the reward period in Unix epoch time.
- updatedTime: The time when this reward information was last updated, in ISO 8601 format.

Sample Record:
```json
{
  "merchantId": 61,
  "rewardsByCard": [
    {"cardType": "travel", "rewardPercentage": 10, "startTimestamp": 1709164800, "expirationTimestamp": 1710979200}
  ],
  "updatedTime": "2024-02-25T00:00:00Z"
}
```

#### Transaction Data

This dataset logs each transaction made by customers using their credit cards. Each transaction includes details such as the card number, time of the transaction, the amount, and the associated merchant.

Fields:
- transactionId: Unique identifier for the transaction.
- cardNo: The credit card number used for the transaction (in string format).
- time: The timestamp of the transaction in ISO 8601 format (UTC).
- amount: The transaction amount in the respective currency.
- merchantId: Unique identifier of the merchant involved in the transaction.

Sample Record:
```json
{"transactionId": 8566250, "cardNo": "4120726898131609", "time": "2024-02-26T08:33:11.871Z", "amount": 443.45, "merchantId": 51}
```
