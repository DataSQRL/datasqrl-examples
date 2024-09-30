# Data Package for the Customer 360 (Retail) Example

This data package is used by the Customer 360 (Retail) Example which demonstrates how to integrate data from multiple
sources to create a comprehensive Customer 360 view. By combining customer data with orders and product information,
we can offer customers a detailed look at their purchase history and enable analytics and search functionalities
through a GraphQL API.

We will use the SQRL Nut Shop, an e-commerce store that sells a variety of nuts and seeds, as the example.
The goal is to provide a customer with insights into their purchase behavior, order details, and product searches.

## Data Overview

The Customer 360 pipeline aggregates four core data sources:
Customers: Basic customer profile information (e.g., name, email, and country).
Orders: Details about orders, including products purchased, time of order, and any discounts applied.
Order Items: Specific details of products in each order.
- Products: Information about each product sold (e.g., name, weight, and category).

#### Customers Data

This dataset contains the customer profile data, which is used to identify customers and connect them with their orders.

Fields:
- id: Unique customer identifier.
- first_name: The customer’s first name.
- last_name: The customer’s last name.
- email: Customer’s email address.
- ip_address: IP address used by the customer.
- country: Country of residence.
- changed_on: Timestamp of the last change to the customer’s data.

Sample Data:
```json
{"id":17,"first_name":"Petrina","last_name":"Donahue","email":"pdonahueg@tmall.com","ip_address":"113.165.34.115","country":"US","changed_on":1672448170042}
{"id":18,"first_name":"Luelle","last_name":"Sproul","email":"lsproulh@friendfeed.com","ip_address":"186.204.27.207","country":"BR","changed_on":1672227942481}
{"id":19,"first_name":"Debbie","last_name":"Forsdike","email":"dforsdikei@cnn.com","ip_address":null,"country":"BR","changed_on":1672093739202}
```

#### Order Items Data

The order items data includes detailed records of the products purchased in each order. Each order can have multiple items.

Fields:
- id: Unique order identifier.
- customerid: The ID of the customer who placed the order.
- time: Timestamp of when the order was placed.
- items: An array of items purchased in the order, each item containing:
- productid: The ID of the purchased product.
- quantity: The number of units of the product purchased.
- unit_price: The price per unit.
- discount: Any discount applied to the unit price (optional).

Sample Data:
```json
{
  "id": 150000001,
  "customerid": 13,
  "time": "2023-01-03T13:08:50.269Z",
  "items": [
    {"productid": 140, "quantity": 2, "unit_price": 25.83, "discount": 15.32},
    {"productid": 184, "quantity": 1, "unit_price": 8.47}
  ]
}
```

#### Orders Data

The Orders dataset gives a summary of customer orders, focusing on which products were purchased, when, and at what price.

Fields:
- id: Unique order identifier.
- customerid: The customer ID associated with the order.
- time: Timestamp of the order.
- productid: The ID of the product purchased.
- quantity: The number of units purchased.
- unit_price: Price of the product per unit.
- discount: Any discount applied to the product.

Sample Data:
```json
{"id": 150000001, "customerid": 13, "time": "2023-01-03T13:08:50.269Z", "productid": 140, "quantity": 2, "unit_price": 25.83, "discount": 15.32}
```

#### Products Data

The product dataset contains information about the products sold in the e-commerce shop, which is essential for matching order items with product descriptions, weights, and categories.

Fields:
- id: Unique identifier for the product.
- name: The name of the product.
- sizing: The size or package description.
- weight_in_gram: The weight of the product in grams.
- type: The type of product (e.g., “Nuts”, “Seeds”).
- category: The category to which the product belongs (e.g., “almonds”, “mixed nuts”).
- usda_id: A reference to USDA product information.
- updated: The last update timestamp for the product information.

Sample Data:
```json
{
  "id": 21,
  "name": "mixed nuts, oil roasted, with peanuts, with salt added",
  "sizing": "2 lbs",
  "weight_in_gram": 907,
  "type": "Nuts",
  "category": "mixed nuts",
  "usda_id": 168600,
  "updated": "2023-01-01T22:14:30.525Z"
}
```

## How to use the data package with an example

We are going to build a data pipeline that aggregates customer data.
With DataSQRL, you can implement the entire data pipeline in a single SQL script.

1. Create a new folder for the data pipeline:
```bash
mkdir nutshop; cd nutshop
```

2. Then create a new file called nutshop.sqrl and copy-paste the following SQL code:
```sql
IMPORT datasqrl.examples.retail.OrderItems AS Orders;
IMPORT datasqrl.examples.retail.Products;
IMPORT datasqrl.examples.retail.Customers;
IMPORT time.*;
IMPORT text.textSearch;

Orders.totals := SELECT sum(quantity * unit_price - coalesce(discount, 0.0)) as price,
                  sum(coalesce(discount, 0.0)) as saving FROM @.items;

Customers := DISTINCT Customers ON id ORDER BY timestamp DESC;
Customers.purchases := JOIN Orders ON Orders.customerid = @.id;
Customers.country0 := coalesce(country, 'none');
Orders.customer := JOIN Customers ON @.customerid = Customers.id;

Customers.spending := SELECT endOfWeek(p.time) AS week,
         sum(t.price) AS spend, sum(t.saving) AS saved
      FROM @.purchases p JOIN p.totals t
      GROUP BY week ORDER BY week DESC;

Customers.order_stats := SELECT min(p.time) as first_order,
                             sum(t.price) as total_spend, sum(t.saving) as total_saved,
                               count(1) as num_orders
                        FROM @.purchases p JOIN p.totals t;


Customers.past_purchases := SELECT i.productid, count(1) as num_orders,
         sum(i.quantity) as total_quantity
      FROM @ JOIN Orders o ON o.customerid = @.id JOIN o.items i
      GROUP BY i.productid
      ORDER BY num_orders DESC, total_quantity DESC;

/*+test */
CustomerPurchaseTest := SELECT c.id, p.productid, count(*) as num
                        FROM Customers c JOIN c.past_purchases p
                        GROUP BY id, productid
                        ORDER BY id ASC, productid ASC;

Products := DISTINCT Products ON id ORDER BY updated DESC;

_OrderItems := SELECT o.id, o.time, o.customerid, i.* FROM Orders o JOIN o.items i;

_OrderItemsProduct := SELECT o.*, p.name as productName, p.category as productCategory, p.type as productType
    FROM _OrderItems o JOIN Products p ON o.productid = p.id;


ProductSearch(@customerId: BIGINT, @query: String) := SELECT id, time, productid, productName, quantity,
                                                             textSearch(@query, productName, productCategory) as score
                                 FROM _OrderItemsProduct
                                 WHERE textSearch(@query, productName, productCategory) > 0
                                        AND customerid = @customerId
                                 ORDER BY score DESC;
```

3. Compile the SQL script to an integrated data pipeline:
```bash
docker run -it --rm -v $PWD:/build datasqrl/cmd:v0.5.5 compile nutshop.sqrl
```

4. By default, DataSQRL uses docker to run data pipelines locally. Start the pipeline with docker compose:
```bash
(cd build/deploy; docker compose up --build)
```

5. Once you are done, hit CTRL-C and take down the pipeline containers with:
```bash
docker compose down -v 
```

## Querying the API

Once the data pipeline is running, you can query the API using GraphiQL.

#### Retrieve Recent Purchases

To get recent purchases for a specific customer, use the following query:
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

#### Spending History

To get a breakdown of customer spending and savings over previous weeks:
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

#### Repeat Purchases

To identify which products the customer has purchased multiple times:

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

#### Product Search

To search customer orders for a specific product (e.g., “macadamia”):
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

## Additional Resources

For further details on how this package works check out our detailed [Retail Customer360 Nutshop](https://github.com/DataSQRL/datasqrl-examples/blob/main/retail-customer360-nutshop/README.md) tutorial.