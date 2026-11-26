# Iceberg batch test job

Staging E2E job on L3: a batch Flink run writes one Iceberg table, `addressbycity`.
The package sets the warehouse and `catalog-impl`; the platform picks the Glue database and table names.

`dogbsmi4nm1iqq0ue` in the warehouse path is the data group key of the staging E2E org `frontend-test-datasqrl`
(the `cc-<key>` part of its Kubernetes namespaces). Update it if that data group is recreated.
