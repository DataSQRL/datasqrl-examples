# Sensor API

This is an example API for recording and analyzing metrics data.
Specifically, this API collects the temperature readings of sensors.

## 1. Run the API

To run this example, invoke the following command in this directory on Unix based systems
```bash
docker run -it -p 8888:8888 -p 8081:8081 -v $PWD:/build datasqrl/cmd:v0.5.2 compile sensors.sqrl sensors.graphqls
```

If you are on windows using Powershell, run the following:
```bash
docker run -it -p 8888:8888 -p 8081:8081 -v ${PWD}:/build datasqrl/cmd:v0.5.2 compile sensors.sqrl sensors.graphqls
```

then 

```bash
cd build/deploy; docker compose up --build
```

This command stands up the API using [DataSQRL](https://www.datasqrl.com/), a development tool
for data pipelines. To check that the GraphQL API is running properly, [open GraphiQL](http://localhost:8888/graphiql/) to access the API.

This command stands up the API using [DataSQRL](https://www.datasqrl.com/), a development tool
for data pipelines.

## 2. Add Temperature Readings

Once the API is up and running, you can access it through GraphiQL, a GraphQL IDE by opening
[http://localhost:8888//graphiql/](http://localhost:8888//graphiql/) in your browser.

Before you run the associated ChatBot, we need to record some sensor data through the API.
You can do that by copy-pasting the following GraphQL mutation query and running it in GraphiQL:
```graphql
mutation AddReading {
  AddReading(metric: {sensorid: 1, temperature: 44.1}) {
    _source_time
  }
}
```

Run the query a few times to add some data. Feel free to change the temperature and sensor id.

Once you are done, hit CTRL-C and take down the pipeline containers with docker compose down -v.


## 3. Run the AI Data Agent

To run a ChatBot interface for the sensor data, execute the following command by substituting your OpenAI API key for `{ADD_YOUR_KEY}`:

```bash
docker run -it --rm -p 8080:8080 -v $PWD:/config/ -e OPENAI_API_KEY={ADD_YOUR_KEY} datasqrl/acorn /config/agent/sensors.openai.config.json /config/sensors.graphqls
```

Open the [data agent chat](http://localhost:8080/) and enter a customer id (1-9) to "log in" as that customer.

You can add sensor data through the API as shown above or by telling the chatbot "Record 50 degrees for sensor 3". Then ask questions about the sensor data.

