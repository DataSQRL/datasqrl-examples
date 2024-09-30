# Data Package for the Finance Creditcard Chatbot Example

This data package is used by the Finance Creditcard Chatbot example which demonstrates how DataSQRL enables real-time
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
and a card type (e.g., “family”, “travel”). The timestamp indicates when the card assignment was made.

Fields:
- customerId: Unique identifier for the customer.
- cardNo: Credit card number (in string format).
- timestamp: Time of card assignment in ISO 8601 format (UTC).
- cardType: The category of the card (e.g., “family”, “travel”). This may be blank if unspecified.

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
- category: The type of goods or services provided by the merchant (e.g., “Clothing & Apparel”, “Housing & Utilities”).
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
- cardType: The type of card eligible for the reward (e.g., “travel”, “sports”).
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

## How to use the data package with an example

We are going to build a data pipeline that aggregates rewards data.
With DataSQRL, you can implement the entire data pipeline in a single SQL script.

1. Create a new folder for the data pipeline:
```bash
mkdir finance; cd finance
```

2. Then create a new file called rewards.sqrl and copy-paste the following SQL code:
```sql
IMPORT datasqrl.examples.finance.Merchant;
IMPORT datasqrl.examples.finance.CardAssignment;
IMPORT datasqrl.examples.finance.Transaction;
IMPORT datasqrl.examples.finance.MerchantReward;
IMPORT time.*;

Merchant :=       DISTINCT Merchant ON merchantId ORDER BY updatedTime DESC;
MerchantReward := DISTINCT MerchantReward ON merchantId ORDER BY updatedTime DESC;
CardAssignment := DISTINCT CardAssignment ON cardNo ORDER BY timestamp DESC;

/* Part 1: Compute customer rewards */
_CustomerTransaction := SELECT t.transactionId, t.cardNo, t.time, t.amount, m.name AS merchantName,
                              m.merchantId, m.category, c.customerid, c.cardType
                       FROM Transaction t
                       TEMPORAL JOIN CardAssignment c ON t.cardNo = c.cardNo
                       TEMPORAL JOIN Merchant m ON t.merchantId = m.merchantid ORDER BY t.time DESC;

_CustomerTransactionRewards := SELECT t.*, r.rewardsByCard AS rewards FROM _CustomerTransaction t
                              TEMPORAL JOIN MerchantReward r ON r.merchantId = t.merchantId;

_CustomerTransactionRewardsByCard := SELECT t.*, t.amount * (r.rewardPercentage / 100.0) as reward, r.cardType AS rewardCardType
                                    FROM _CustomerTransactionRewards t JOIN t.rewards r
                                    WHERE timestampToEpoch(t.time) <= r.expirationTimestamp AND timestampToEpoch(t.time) >= r.startTimestamp;

CustomerRewards := SELECT transactionId, customerId, cardNo, cardType, time, amount, reward, merchantName
                  FROM _CustomerTransactionRewardsByCard
                  WHERE cardType = rewardCardType;


/* Part 2a: Query and Analyze Rewards */
Rewards(@customerid: BIGINT, @fromTime: TIMESTAMP, @toTime: TIMESTAMP) :=
SELECT * FROM CustomerRewards WHERE customerid = @customerid AND @fromTime <= time AND @toTime > time
ORDER BY time DESC;

TotalReward := SELECT customerId, SUM(reward) AS total_reward,
                              MIN(time) as since_time
                       FROM CustomerRewards GROUP BY customerId;

RewardsByWeek := SELECT customerId, endOfWeek(time) as timeWeek, SUM(reward) as total_reward
                FROM CustomerRewards GROUP BY customerId, timeWeek ORDER BY timeWeek DESC;



/* Part 2b: Compute potential rewards for personalized sales */
_CustomerPotentialRewards := SELECT transactionId, customerId, rewardCardType, time, amount, reward, merchantName
                            FROM _CustomerTransactionRewardsByCard
                            WHERE cardType != rewardCardType;

PotentialRewards(@customerid: BIGINT, @cardType: STRING, @fromTime: TIMESTAMP, @toTime: TIMESTAMP) :=
SELECT * FROM _CustomerPotentialRewards WHERE customerid = @customerid AND @fromTime <= time AND @toTime > time
AND rewardCardType = @cardType ORDER BY time DESC;

TotalPotentialReward := SELECT customerId, rewardCardType AS cardType, SUM(reward) AS total_reward,
                                       MIN(time) as since_time
                                FROM _CustomerPotentialRewards
                                GROUP BY customerId, cardType ORDER BY cardType DESC;

PotentialRewardsByWeek := SELECT customerId, rewardCardType AS cardType, endOfWeek(time) as timeWeek, SUM(reward) as total_reward
                 FROM _CustomerPotentialRewards GROUP BY customerId, cardType, timeWeek ORDER BY timeWeek DESC;
```

3. Then create a new file called rewards.graphql and copy-paste the following graphql code:
```graphql
"An RFC-3339 compliant DateTime Scalar"
scalar DateTime

type Query {
    """Returns all the rewards that a customer has earned in the given time period"""
    Rewards(
        """customerid: Customer identifier"""
        customerid: Int!,
        """fromTime: RFC-3339 compliant date time scalar. Returns rewards after this time. Use the start of the day only, e.g. 2024-01-19T00:00:00-00:00."""
        fromTime: DateTime!,
        """toTime: RFC-3339 compliant date time scalar. Returns rewards up to this time. Use the start of the day only, e.g. 2024-01-19T00:00:00-00:00."""
        toTime: DateTime!
    ): [CustomerRewards!]

    """Returns the total awards a customer earned by week starting from the most recent week."""
    RewardsByWeek(
        """customerid: Customer identifier"""
        customerid: Int!,
        """limit: The number of weeks to return starting from most recent to less recent weeks. For example, if limit is 12 it will return the last 12 weeks of total rewards earned."""
        limit: Int = 12,
        """offset: The number of weeks to offset. For example, if offset is 4, it will skip the last 4 weeks of rewards earned and return the weeks before that."""
        offset: Int = 0
    ): [RewardsByWeek!]

    """Returns the total amount of rewards the customer has earned to date and the time since when they eared rewards"""
    TotalReward(
        """customerid: Customer identifier"""
        customerid: Int!
    ): TotalReward

    """Returns all the potential rewards a customer could have earned in the given time period for the given card type. Use this function to show customers the rewards they would have earned if they had the given card."""
    PotentialRewards(
        """customerid: Customer identifier"""
        customerid: Int!,
        """cardType: The type of card to calculate potential rewards for (i.e. travel, sports, business, or family)"""
        cardType: String!,
        """fromTime: RFC-3339 compliant date time scalar. Returns rewards after this time. Use the start of the day only, e.g. 2024-01-19T00:00:00-00:00."""
        fromTime: DateTime!,
        """toTime: RFC-3339 compliant date time scalar. Returns rewards up to this time. Use the start of the day only, e.g. 2024-01-19T00:00:00-00:00."""
        toTime: DateTime!
    ): [PotentialRewards!]

    """Returns the total awards a customer could have earned for a given card type by week starting from the most recent week. Use this function to show the customer what their reward earnings would have looked like, if they had a given card."""
    PotentialRewardsByWeek(
        """customerid: Customer identifier"""
        customerid: Int!,
        """cardType: The type of card to calculate potential rewards for (e.g., travel, sports, business, family)"""
        cardType: String!,
        """limit: The number of weeks to return starting from most recent to less recent weeks. For example, if limit is 12 it will return the last 12 weeks of total rewards earned."""
        limit: Int = 12,
        """offset: The number of weeks to offset. For example, if offset is 4, it will skip the last 4 weeks of rewards earned and return the weeks before that."""
        offset: Int = 0
    ): [PotentialRewardsByWeek!]

    """Returns the total amount of rewards the customer could have earned for each type of credit card the customer does not yet have. Use this function to determine which credit card type to recommend to a customer."""
    TotalPotentialReward(
        """customerid: Customer identifier"""
        customerid: Int!
    ): [TotalPotentialReward!]
}

type Subscription {
    """Returns the rewards for a given customer immediately"""
    CustomerRewards(customerid: Int!): CustomerRewards
}

type CustomerRewards {
    transactionId: Float!
    customerid: Int!
    cardNo: Float!
    cardType: String!
    time: DateTime!
    amount: Float!
    reward: Float!
    merchantName: String!
}

type RewardsByWeek {
    customerid: Int!
    timeWeek: DateTime!
    total_reward: Float!
}

type TotalReward {
    customerid: Int!
    total_reward: Float!
    since_time: DateTime!
}

type PotentialRewards {
    transactionId: Float!
    customerid: Int!
    rewardCardType: String!
    time: DateTime!
    amount: Float!
    reward: Float!
    merchantName: String!
}

type PotentialRewardsByWeek {
    customerid: Int!
    cardType: String!
    timeWeek: DateTime!
    total_reward: Float!
}

type TotalPotentialReward {
    customerid: Int!
    cardType: String!
    total_reward: Float!
    since_time: DateTime!
}

type CustomerChatMessage {
    role: String!
    content: String!
    name: String
    functionCall: String
    customerid: Int!
    timestamp: String!
    uuid: String!
}

type Mutation {
    """Adds a customer chat message"""
    InternalSaveChatMessage(message: ChatMessageInput!): CreatedChatMessage
}

input ChatMessageInput {
    role: String!
    content: String!
    name: String
    functionCall: String
    customerid: Int
}

type CreatedChatMessage {
    event_time: String!
}
```

4. Compile the SQL script to an integrated data pipeline:
```bash
docker run -it --rm -v $PWD:/build datasqrl/cmd:v0.5.5 compile rewards.sqrl rewards.graphqls
```

5. By default, DataSQRL uses docker to run data pipelines locally. Start the pipeline with docker compose:
```bash
(cd build/deploy; docker compose up --build)
```

6. Once you are done, hit CTRL-C and take down the pipeline containers with:
```bash
docker compose down -v 
```

## Additional Resources

For further details on how this package works check out our detailed [Finance Credit Card Chatbot](https://github.com/DataSQRL/datasqrl-examples/blob/main/finance-credit-card-chatbot/README.md) tutorial.
