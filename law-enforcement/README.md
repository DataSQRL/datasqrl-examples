# Law Enforcement

This example demonstrates how to consume law enforcement data from multiple sources, such as:

* Databases for Driver and Vehicle information
* Data streams for issued warrants and bolos ("be on the lookout")

The SQRL script consumes and integrates that information to produce a comprehensive overview of all relevant information
that an officer might need for a traffic stop or to look up a person of interest.

The SQRL script also produces relevant analytics on the issued warrants and bolos.

Furthermore, it provides a mutation for capturing traffic stops and producing alerts based on issued bolos.

The project keeps its configuration in a base manifest plus thin per-environment overlays, selected through `script.config.environment`:

| Environment | Driver/Vehicle/Warrant/Bolo data comes from | Overlay |
|-------------|---------------------------------------------|---------|
| `test` | the sample files in `connectors/testdata/` (`connectors/police_test.sqrl`) | `baseball_card-test-package.json` |
| `dev` | one Kafka topic per dataset (`connectors/police_dev.sqrl`, columns declared in `connectors/police.sqrl`) | `baseball_card-dev-package.json` |

DataSQRL merges the manifests in the order they are given (later files override earlier ones), so every command passes the base first and the overlay second.

## Run

Invoke the following command to run this example with the sample data:

```bash
docker run -it -p 8888:8888 -p 8081:8081 --rm -v $PWD:/workspace datasqrl/cmd:latest run \
  baseball_card-shared-package.json \
  baseball_card-test-package.json
```

The `dev` overlay runs the same pipeline against Kafka topics instead of files, for wiring the example up to live data streams.

## Run the Tests

`run-tests.sh` is the single entry point for the test suites:

```bash
./run-tests.sh                       # test environment: file data, snapshot tests
./run-tests.sh --compile --env dev   # compile-verify the Kafka-sourced dev environment
./run-tests.sh --list-invocations    # print what would run without running it
```

The snapshot tests (`snapshots/baseball_card/`) cover the bolo and warrant analytics.

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

An alert fires when a recorded encounter's plate matches an active bolo issued within the 60 days before the encounter.

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
    Tracking(event:  {
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
