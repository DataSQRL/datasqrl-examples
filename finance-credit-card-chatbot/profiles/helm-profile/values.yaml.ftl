namespace: default
group_label: datasqrl-pipeline
eks_role_arn: arn:aws:iam::286928876767:role/eksctl-datasqrl-cloud-nodegroup-my-NodeInstanceRole-dNZzJBfWsGTC

engine:
  flink:
    image:
      name: public.ecr.aws/j5u7a3j2/test/sqrl-flink
      tag: latest
    version: "v1_18"
    main_container:
      env_vars:
        - name: PROPERTIES_BOOTSTRAP_SERVERS
          value: wb-1.cloudmvpcluster.ie4ci8.c1.kafka.us-east-1.amazonaws.com:9092
        - name: BOOTSTRAP_SERVERS
          value: wb-1.cloudmvpcluster.ie4ci8.c1.kafka.us-east-1.amazonaws.com:9092
        - name: JDBC_URL
          value: "jdbc:postgresql://database-rw:5432/datasqrl"
        - name:  JDBC_USERNAME
          value: "postgres"
        - name: JDBC_PASSWORD
          value: "postgres"
        - name: S3_DATA_BUCKET
          value: sqrl-examples-data-bucket
  database:
    image:
      name: ghcr.io/cloudnative-pg/postgresql
      tag: 16
  server:
    image:
      name: datasqrl/sqrl-server
      tag: v0.5.3
    env_vars:
      - name: PGHOST
        value: "database-rw"
      - name: PGPORT
        value: "5432"
      - name: PGDATABASE
        value: "datasqrl"
      - name: PGUSER
        value: "postgres"
      - name: PGPASSWORD
        value: "postgres"
      - name: PROPERTIES_BOOTSTRAP_SERVERS
        value: wb-1.cloudmvpcluster.ie4ci8.c1.kafka.us-east-1.amazonaws.com:9092
  kafka:
    endpoint: wb-1.cloudmvpcluster.ie4ci8.c1.kafka.us-east-1.amazonaws.com:9092