# Finance Credit Card ChatBot Examples

This project contains two example use cases that process credit card transaction, customer, and merchant data:

* [**Transaction Analytics**](finance-credit-card-analytics-example): A data pipeline which enriches the credit card
  transactions with customer and merchant information to give customers an overview of their transactions as well as
  some analytics on their spending.
  * To run this data pipeline with file data, use the `creditcard_analytics_package_test.json` manifest file.
  * To run this data pipeline with Kafka as the data source, use the `creditcard_analytics_package_kafka.json` manifest file.
* [**Credit Card Rewards**](finance-credit-card-rewards-example): A data pipeline that implements a credit card rewards program.
  Merchants sign up for cash-back rewards on certain credit card types during certain periods and customer get a cash
  reward when they make a purchase at the merchant during that time. The data pipeline processes the rewards and give
  the customer insight into the reward they earned.
  * To run this data pipeline with file data, use the `creditcard_rewards_package_test.json` manifest file.
  * To run this data pipeline with Kafka as the data source, use the `creditcard_rewards_package_kafka.json` manifest file.

See below for detailed instructions on how to run each data pipeline.
Note, that the instructions are for the *Transaction Analytics* use case.
Replace the manifest files to run the *Credit Card Rewards* use case (i.e. `rewards` instead of `analytics` in the
package JSON filename) - the instructions are otherwise identical.

## 1. Run the API with File data source

To run this example, invoke the following command in this directory on Unix based systems to compile the project
```bash
docker run -it -p 8081:8081 -p 8888:8888 --rm -v $PWD:/build datasqrl/cmd:latest run -c creditcard_analytics_package_test.json
```

This command stands up the API using [DataSQRL](https://www.datasqrl.com/), a development tool
for data pipelines. To check that the GraphQL API is running properly, [open GraphiQL](http://localhost:8888/graphiql/) to access the API.

When you are done, you can stop the pipeline by hitting CTRL-C.

## 2. Run the API with Kafka data source

The instructions above run the data pipeline with data ingested from local files. While this is great for testing and local development,
most production use cases need to ingest data from an external data source like Kafka.

To use Kafka as the data source, follow these steps:

Invoke the following command in this directory:
```bash
docker run -it -p 8081:8081 -p 8888:8888 -p 9092:9092 --rm -v $PWD:/build datasqrl/cmd:latest run -c creditcard_analytics_package_kafka.json
```

This command stands up the entire data pipeline and all data services, including Kafka.

Now, we need to write the data to Kafka, so it can be consumed by the pipeline.

The easiest way to do so is to use a little helper python script
that reads the data from a file and writes it to the kafka topic. This requires you have Python3 installed on your machine.

In this directory, invoke the script twice in the following order to populate Kafka:
1. `python3 ../util/load_data.py creditcard-testdata/merchant.jsonl localhost:9092 merchant --msg 500`
2. `python3 ../util/load_data.py creditcard-testdata/merchantReward.jsonl localhost:9092 merchantreward --msg 500`
3. `python3 ../util/load_data.py creditcard-testdata/cardAssignment.jsonl localhost:9092 cardassignment --msg 500`
4. `python3 ../util/load_data.py creditcard-testdata/transaction.jsonl localhost:9092 transaction --msg 50`

The first load should be pretty quick. The transactions are then loaded at a rate of 50 per second (You can adjust the rate via the `--msg` option).

To see how the data enters the topics and the [Flink UI](http://localhost:8081/) to see the processing status.

As above, you can [open GraphiQL](http://localhost:8888/graphiql/) to access the API and query for data. Note, that the time windows are very long,
so you won't be seeing any output there for the short period of time we are inserting data.
You can adjust the time windows or keep loading data for a long time ;-).

When you are done, you can stop the pipeline by hitting CTRL-C.

## 3. Run the AI Data Agent

Both use cases can be extended with a Generative AI data agent:
1. **Transaction Analytics**: The data agent can answer customers' questions about their credit card transaction history
   and spending habits. The agent is defined in the folder `analytics-agent`.
2. **Credit Card Rewards**: The data agent can show customers the rewards they earned and sell customers on different types
   of credit cards to maximize their rewards. The agent is defined in the folder `rewards-agent`.

To run the data agent as a chatbot, you follow these steps:

1. Run the agent in docker:
   ```bash
   docker run -it --rm -p 8080:8080 -v $PWD:/config/ -e OPENAI_API_KEY={ADD_YOUR_KEY} datasqrl/acorn /config/analytics-agent/creditcard.openai.config.json /config/creditcard_analytics.graphqls
   ```
   1. Replace `{ADD_YOUR_KEY}` with your OpenAI API key.
   2. To run the agent for the credit card rewards use case, replace the folder `analytics-agent` with `rewards-agent`
      and the GraphQL file `creditcard_analytics.graphqls` with `creditcard_rewards.graphqls`.
2. Open the [data agent chat](http://localhost:8080/) and enter a customer id (1-9) to "log in" as that customer.
   Then ask away. Questions like "what credit card would you recommend for me?" or "How many rewards did I earn?"
   or "How many rewards could I have earned?"

The example above uses OpenAI as the LLM model provider.
To use a different LLM model provider, you can change the configuration file (i.e. the first argument that ends with `config.json`):
* `creditcard.bedrock-llama.config.json`: Uses Llama3 on AWS Bedrock.
* `creditcard.groq-llama.config.json`: Uses Llama3 on Groq.

You may have to update the model provider configuration to match your cloud configuration for Bedrock or Google Vertex.
