# Customer 360 (Retail) Example

This example shows how to combine data from multiple sources to create a comprehensive view of the customer (called a *"Customer 360"*) and expose that view through an API.

We are building a Customer 360 for an e-commerce site - our SQRL Nut Shop. It combines information on the customer, with the customer's orders and products. The goal is to give the customer a complete picture of their purchase history with analytics and search.

## 1. Compile & Launch Data Pipeline

To run this example, invoke the following command in this directory to compile the data pipeline
```bash
 docker run -it --rm -v $PWD:/build datasqrl/cmd:v0.5.0 compile customer360.sqrl
```

Next, run the following to start the pipeline with Docker:
`(cd build/deploy; docker compose up --build)`.

Once everything is started pu, check that the GraphQL API is running properly by [opening GraphiQL](http://localhost:8888/graphiql/) to access it.

## 2. Query the API

In GraphiQL, you can run the following queries to access the data:

### Retrieve Recent Purchases

```graphql
{
  Customers(id: 5) {
    country
    purchases {
      id
      time
      items {
        productid
        unit_price
      }
    }
  }
}
```

Returns the purchases for customer with `id=5` and the items in those orders.

### Spending History

```graphql
{
  Customers(id: 5) {
    spending {
      week
      spend
      saved
    }
  }
}
```

Shows how much money the customer spent and saved in each of the previous weeks.

### Repeat Purchases

```graphql
{
  Customers(id: 5) {
    past_purchases {
      productid
      num_orders
      total_quantity
    }
  }
}
```

Shows which products the customers has purchased repeatedly.


### Product Search

```graphql
{
  ProductSearch(customerId: 5, query: "macadamia") {
    id
    time
    productid
    productName
    quantity
  }
}
```

Searches for all customer orders with products that match the query `macadamia`.

## 3. Shut Down Data Pipeline

To stop the data pipeline and release the resources allocated to it, run
`(cd build/deploy; docker compose down -v)`.
