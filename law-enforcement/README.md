
This example demonstrates how to consume law enforcement data from multiple sources, such as:

* Databases for Driver and Vehicle information
* Data streams for issued warrants and bolos ("be on the lookout")

The SQRL script consumes and integrates that information to produce a comprehensive overview of all relevant information that an officer might need for a traffic stop or to look up a person of interest.

The SQRL script also produces relevant analytics on the issued warrants and bolos.

Furthermore, it provides a mutation for capturing traffic stop and producing alerts based on issued bolos.

## Run

Invoke the following command to run this example.

```bash
docker run -it -p 8888:8888 -p 8081:8081 --rm -v $PWD:/build datasqrl/cmd:latest run -c baseball-card-local.json
```

## Queries

To issue queries, open [http://localhost:8888/graphiql/](http://localhost:8888/graphiql/) in your browser. You can then run the following queries.

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

## AI Agent

To access the information with the help of an AI assistant, run the following command to launch the agent:

```bash
docker run -it --rm -p 8080:8080 -v $PWD:/config/ -e OPENAI_API_KEY={YOUR-OPEN-AI-API-KEY} datasqrl/acorn /config/agent/openai.config.json /config/baseball_card.graphqls
```

Then open the agent in the [browser](http://localhost:8080/?login=false) and ask questions such as:

* "Pull up information on driver's license ZK035266"
* "Show me bolo statistics for the state of washington over the last 11 weeks"