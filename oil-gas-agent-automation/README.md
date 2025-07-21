# Automated Monitoring - Oil & Gas Use Case

Run the data backend with the following command:

`docker run -it -p 8888:8888 -p 8081:8081 -p 9092:9092 --rm -v $PWD:/build datasqrl/cmd:latest run  -c package-local.json `

To publish flowrate metrics, open [GraphiQL in the browser](http://localhost:8888/graphiql/) and run the following mutation:

```graphql
mutation {
  AddFlowRate(event: {assetId: 12221, flowrate: 220.5 }) {
    assetId
    flowrate
  }
}
```

This sample dataset has 5 pre-defined wells (i.e. assets) with the following ids:
`12221, 21112, 34443, 45555, 59995`

Open GraphiQL again in another window and listen to this subscription:
```graphql
subscription {
  LowFlowRate {
    assetId
    flowrate
  }
}
```

Add another flowrate metric with a value below `200` and observe it through the subscription.
To retrieve recent pressure and temperature readings for a well, run this query:
```graphql
{
  RecentPressure(assetId: 12221) {
    pressure_psi
    temperature_f
    timestamp_normalized
  }
}
```
