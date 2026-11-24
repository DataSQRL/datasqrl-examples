# Iceberg batch test job

Staging E2E job on L3: a batch Flink run writes `AddressByCity` to Iceberg under data group `dogbsmi4nm1iqq0ue`'s S3 prefix.
The package sets only the warehouse; the platform picks the Glue database and table names.
