

## Queries

```graphql
{
  BoloDetails(make: "Honda", model: "CR-V") {
   	bolo_id
    issue_date
    model
    year
    registration_state
    registration_number
    driver {
      first_name
      last_name
      date_of_birth
      warrants {
        issue_date
        warrant_status
      }
    }
  }
}
```

```graphql
{
  Vehicle(registration_number: "gwd-8241") {
    driver {
      first_name
      last_name
    }
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


```graphql
mutation {
  Tracking(encounter:  {
    plate: "gwd-8241",
    latitude: 55.2,
    longitude:109.3
  }) {
		plate
  }
}
```