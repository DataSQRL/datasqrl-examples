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
- first_name: The customer's first name.
- last_name: The customer's last name.
- email: Customer's email address.
- ip_address: IP address used by the customer.
- country: Country of residence.
- changed_on: Timestamp of the last change to the customer's data.

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

For a detailed explanation of how to work with this package, please refer to our comprehensive
[Retail Customer360 Nutshop](https://github.com/DataSQRL/datasqrl-examples/blob/main/retail-customer360-nutshop/README.md) tutorial.

To apply it in your project, update the imports in the `customer360.sqrl` file:
```sql
IMPORT datasqrl.examples.retail.OrderItems AS Orders;
IMPORT datasqrl.examples.retail.Products;
IMPORT datasqrl.examples.retail.Customers;
IMPORT time.*;
IMPORT text.textSearch;
```
