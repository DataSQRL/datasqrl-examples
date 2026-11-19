# Law Enforcement

- **Builds:** a real-time pipeline and data API that integrate several source systems into one view of drivers, vehicles, warrants, and BOLOs.
- **Shows:** multiple source systems · data API
- **Built with:** SQRL compiled to Flink, Kafka, Postgres, and the DataSQRL API server.

This example demonstrates how to consume law enforcement data from multiple source systems:

* **Databases** for driver and vehicle information (`Driver`, `Vehicle`). Changes in these databases are captured
  as change streams (CDC), keyed by id and versioned by `last_updated`.
* **Data streams** for issued warrants and bolos ("be on the lookout") (`Warrant`, `Bolo`).

The test configuration reads all four from sample files in `connectors/testdata`.

The SQRL script consumes and integrates that information to produce a comprehensive overview of all relevant information
that an officer might need for a traffic stop or to look up a person of interest.

The SQRL script also produces relevant analytics on the issued warrants and bolos.

Furthermore, it provides a mutation for capturing traffic stop and producing alerts based on issued bolos.

## Run

Invoke the following command to run this example.

```bash
docker run -it --rm -p 8081:8081 -p 8888:8888 -p 9092:9092 -v $PWD:/workspace datasqrl/cmd:latest run baseball_card_test_package.json
```

## Queries

To issue queries, open [http://localhost:8888/v1/graphiql/](http://localhost:8888/v1/graphiql/) in your browser. You can then run the following queries.

"Baseball card" for Drivers that provides a comprehensive overview of all relevant information:

```graphql
{
    Driver(license_number: "VV770432") {
        first_name
        last_name
        date_of_birth
        license_state
        license_number
        license_expiry_date
        warrants {
            warrant_id
            warrant_status
            crime_description
            issue_date
            state_of_issuance
        }
        vehicles {
            registration_state
            registration_number
            registration_expiry
            bolos {
                issue_date
                status
            }
        }
    }
}
```

Look up a vehicle by license plate to get complete information:

```graphql
{
    Vehicle(registration_number: "gwv-9659") {
        vehicle_id
        registration_state
        registration_number
        registration_expiry
        make
        model
        year
        owner_driver_id
        bolos {
            bolo_id
            status
            issue_date
        }
    }
}
```

What Bolo's are there for similar makes and models?

```graphql
{
    BoloDetails(make: "Honda", model: "CR-V") {
        bolo_id
        issue_date
        model
        year
        registration_state
        registration_number
        license_state
        driver_id
    }
}
```

## Analytics

```graphql
{
  WarrantsByCrime(limit: 20) {
    crime
    num_warrants
  }
}
```

```graphql
{
  WarrantsByState(status: "active") {
    state
    num_warrants
  }
}
```

## Tracking

Subscription to Tracking alerts:

```graphql
subscription {
  TrackingAlert {
    bolo_id
    latitude
    longitude
    registration_number
    registration_state
  }
}
```

Mutation that records an encounter:

```graphql
mutation {
    Tracking(encounter:  {
        plate: "dkx-1292",
        latitude: 55.2,
        longitude:109.3
    }) {
        plate
    }
}
```

Query to retrieve tracking information:

```graphql
{
  Vehicle(registration_number: "dkx-1292") {
    bolos {
      bolo_id
      status
    }
    tracking {
      latitude
      longitude
    }
  }
}
```


## Build this with the DataSQRL plugin

Install the [DataSQRL plugin](https://github.com/DataSQRL/datasqrl-plugin) in Claude Code, Codex, Cursor, or Copilot, then paste this prompt:

```text
Build a DataSQRL data API for traffic stops. Capture changes from the driver and vehicle
databases, read warrants and BOLOs from event streams, and serve a driver lookup by license
number and a vehicle lookup by plate that include open warrants and BOLOs. Add a mutation that
records an encounter and a subscription that alerts when an encountered vehicle has an active BOLO.
```
