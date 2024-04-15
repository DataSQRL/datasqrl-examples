# Logistics

TODO Description

## Regenerate test data

- Delete the data-db and data-stream folders if exists.
- Activate venv based on this guide: [Using Python in examples section](../README.md#using-python-in-examples)
- From logistics root:
  - Run `python datagen/src/generate_test_data.py`
  - Generate data packages:
    - `sqrl discover datagen/generated/db -o data-db`
    - `sqrl discover datagen/generated/stream -o data-stream`

## How to compile and run the project
  - Compile the project: `sqrl compile --mnt datagen/generated logistics.sqrl logistics.graphqls`
  - Fix mnt in the generated compose-file because as of 0.5 there is a bug and it doesn't respect relative paths
    - Swap `datagen/generated` to `../../datagen/generated:/build/datagen/generated` in `build/deploy/docker-compose.yml`
  - Run the project: `docker compose up --build`

## GraphQL examples

# How many shipments does the customer have?
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


# What are the customer's shipments, and what is their latest location?
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
