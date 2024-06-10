# Logistics

This example demonstrates DataSQRL's capabilities by replicating shipment delivery in Manhattan. It
serves as an ideal use-case for streaming, showcasing real-time shipment tracking. Monitor and
manage shipments as they move through the city and answer queries like the number of shipments per
customer and their current locations. Amazingly, all of this is achieved in just 22 lines of code,
imports included. How cool is that?

## How to compile and run the project

- To compile the project, use the following
  command: `sqrl compile logistics.sqrl logistics.graphqls`
- To run the project, execute: `docker compose up --build`

## Exploring the Pipeline

Now that you've successfully compiled and started the pipeline, let’s explore its capabilities.

### Understanding the Input Data

First, let's examine the input data you will be working with, located in the `local-package` folder:

#### Customers

Typically, customer data might reside in a relational database management system (RDBMS) in a
real-world scenario. In a streaming context, we simulate changes via Change Data Capture (CDC),
where each record represents a data modification. While the initial data does not include changes,
feel free to experiment by adding a new record to `local-package/customer.jsonl` to see how the
system reacts.

```json
...
{"id": 2, "lastUpdated": "2024-04-17T09:00:50.838300", "email": "ljohnson@example.org", "phone": "001-291-828-3417x6473"}
{"id": 3, "lastUpdated": "2024-04-16T23:25:53.025920", "email": "kevinmitchell@example.net", "phone": "825.323.1139"}
{"id": 4, "lastUpdated": "2024-04-16T22:23:29.183022", "email": "griffinjessica@example.net", "phone": "+1-291-441-8408x37087"}
...
```

#### Shipments

Here, each shipment's estimatedDelivery time, along with its delivery coordinates (`lat` and `lon`),
has been pre-calculated:

```json
...
{"id": 24, "lastUpdated": "2024-04-17T22:57:26.347579", "origin": "Myanmar", "lat": 40.8701354, "lon": -73.9170165, "weight": 2.1, "estimatedDelivery": "2024-04-23T22:21:00.203370", "customerId": 7}
{"id": 25, "lastUpdated": "2024-04-17T16:16:59.714234", "origin": "Vanuatu", "lat": 40.7143955, "lon": -74.0005026, "weight": 3.9, "estimatedDelivery": "2024-04-23T22:54:33.043504", "customerId": 14}
{"id": 26, "lastUpdated": "2024-04-18T08:25:50.095937", "origin": "Martinique", "lat": 40.8115152, "lon": -73.9349267, "weight": 6.0, "estimatedDelivery": "2024-04-23T22:32:36.206061", "customerId": 4}
{"id": 27, "lastUpdated": "2024-04-17T22:34:32.917568", "origin": "Armenia", "lat": 40.7140166, "lon": -74.0044302, "weight": 8.3, "estimatedDelivery": "2024-04-23T23:12:46.687424", "customerId": 6}
{"id": 28, "lastUpdated": "2024-04-17T20:59:47.006159", "origin": "Cook Islands", "lat": 40.7219848, "lon": -74.0082309, "weight": 0.8, "estimatedDelivery": "2024-04-23T23:32:49.375996", "customerId": 10}
...
```

#### Vehicle

This model covers the details of 4 vehicles involved in delivery. A heavy truck acts as a regional
transporter, delivering shipments to a distribution center in Manhattan, where they are subsequently
picked up by three different trucks aimed at distinct parts of Manhattan (north, center, south).

```json
{"id": 0, "lastUpdated": "2024-04-17T12:27:07.832982", "type": "HEAVY_TRUCK", "capacity": 289}
{"id": 1, "lastUpdated": "2024-04-17T12:27:07.832983", "type": "BOX_TRUCK", "capacity": 288}
{"id": 2, "lastUpdated": "2024-04-17T12:27:07.832984", "type": "BOX_TRUCK", "capacity": 183}
{"id": 3, "lastUpdated": "2024-04-17T12:27:07.832985", "type": "CARGO_VAN", "capacity": 173}
```

#### Shipment location

This stream tracks the current vehicle holding a specific shipment. Once a shipment is loaded to a
vehicle a shipment location event is emitted.

```json
...
{"timestamp": "2024-04-23T18:26:11.220515", "shipmentId": 25, "vehicleId": 1}
{"timestamp": "2024-04-23T18:26:11.220515", "shipmentId": 26, "vehicleId": 2}
{"timestamp": "2024-04-23T18:26:11.220515", "shipmentId": 27, "vehicleId": 1}
...
```

#### Vehicle status

This data stream provides real-time location updates for each vehicle.

```json
...
{"timestamp": "2024-04-23T22:28:21.095515", "lat": 40.8024528, "lon": -73.9388372, "vehicleId": 2}
{"timestamp": "2024-04-23T22:39:18.690515", "lat": 40.7194555, "lon": -73.994384, "vehicleId": 1}
{"timestamp": "2024-04-23T22:40:26.138515", "lat": 40.8701354, "lon": -73.9170165, "vehicleId": 3}
{"timestamp": "2024-04-23T22:55:11.794515", "lat": 40.7143955, "lon": -74.0005026, "vehicleId": 1}
{"timestamp": "2024-04-23T22:55:17.755515", "lat": 40.8115152, "lon": -73.9349267, "vehicleId": 2}
{"timestamp": "2024-04-23T23:04:21.859515", "lat": 40.7140166, "lon": -74.0044302, "vehicleId": 1}
...
```

### Performing Queries with GraphQL

Navigate to http://localhost:8888/graphiql/ and execute the following GraphQL queries to interact
with our simulation.

#### How many shipments does a customer have?

The following GraphQL query provides insight into the total number of shipments associated with a
specific customer, in this case, customer with `id: 4`. Additionally, the query returns the email
address of the customer, enhancing the ease of identification. Refer to the `logistics.graphqls`
file for details on all available fields you can query.

```graphql
{
    Customer(id: 4) {
        email,
        statistics {
            shipment_count
        }
    }
}
```

#### Expected Response

Below is a sample response which shows that the customer identified by the
email `griffinjessica@example.net` has two ongoing shipments.

```json
{
  "data": {
    "Customer": [
      {
        "email": "griffinjessica@example.net",
        "statistics": [
          {
            "shipment_count": 2
          }
        ]
      }
    ]
  }
}
```

#### What are the customer's shipments, and what is their latest location?

For more detailed tracking, this GraphQL query extends the information returned about each shipment
for a specified customer (ID 4 in this example). This query not only provides details such as the
shipment weight and estimated delivery time but also includes the latest known location (`lat` and
`lon`) of the vehicle carrying each shipment, which can be particularly useful for plotting these
locations on a map.

```graphql
{
    Customer(id: 4) {
        email,
        shipments {
            weight,
            estimatedDelivery,
            locations(limit: 1) {
                vehicleId,
                vehicle_statuses(limit: 1) {
                    timestamp
                    lat,
                    lon
                }
            }
        }
    }
}
```

#### Response Example

Below is what the response might look like, showing detailed tracking information for each shipment.
Note the precise coordinates and timestamps indicating the most recent status update for each
vehicle.

```json
{
  "data": {
    "Customer": [
      {
        "email": "griffinjessica@example.net",
        "shipments": [
          {
            "weight": 9.9,
            "estimatedDelivery": "2024-04-23T22:43:29.035Z",
            "locations": [
              {
                "vehicleId": 1,
                "vehicle_statuses": [
                  {
                    "timestamp": "2024-04-24T01:16:29.794Z",
                    "lat": 40.7124667,
                    "lon": -73.9777769
                  }
                ]
              }
            ]
          },
          {
            "weight": 6,
            "estimatedDelivery": "2024-04-23T22:32:36.206Z",
            "locations": [
              {
                "vehicleId": 2,
                "vehicle_statuses": [
                  {
                    "timestamp": "2024-04-24T03:58:00.498Z",
                    "lat": 40.7583508,
                    "lon": -74.0038049
                  }
                ]
              }
            ]
          }
        ]
      }
    ]
  }
}
```

## Regenerate test data

Normally, there is no need to regenerate the test data if you are using pre-configured sets.
However, if you wish to modify or experiment with the data, here's how you can regenerate it.

- Remove the `generated` folder.
- Activate the virtual environment as described in
  the [Using Python in examples section](../README.md#using-python-in-examples).
- Then navigate to the logistics root directory and run the following commands:
    - `python datagen/src/generate_test_data.py` to generate fresh test data. This command generates
      three folders under the `generated` folder:
        - `assets`: In this folder, you can find the plotted route for each event when a vehicle
          status was emitted. Alongside them, there is a `logistics.gif` which is an animation
          created from the plots. We only commit the last `png` file to show the full route; any
          other file is irrelevant, as they are needed for the gif creation. We didn't add
          automation to delete them because this way you can use them for your experiments.
        - `db`: In this folder, you can find the entities which could live in an RDBMS.
        - `stream`: In this folder, you can find the events which would be emitted by a sensor on
          the vehicle or by a scanner in the distribution center.
