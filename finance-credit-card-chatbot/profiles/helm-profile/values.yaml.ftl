namespace: ${config["values"]["deployment"]["namespace"]}
group_label: datasqrl-pipeline
eks_role_arn: arn:aws:iam::286928876767:role/eksctl-datasqrl-cloud-nodegroup-my-NodeInstanceRole-dNZzJBfWsGTC
hosted_zone_name: sqrl.site
project_name: ${config["values"]["deployment"]["project_name"]}
deployment_id: ${config["values"]["deployment"]["id"]}

engine:
  flink:
    logging:
      format: txt
    image:
      name: public.ecr.aws/j5u7a3j2/test/sqrl-flink
      tag: latest
    version: "v1_18"
    main_container:
      env_vars:
        - name: JDBC_URL
          value: "jdbc:postgresql://database-${config["values"]["deployment"]["shorten_id"]}-rw:5432/datasqrl"
        - name:  JDBC_USERNAME
          value: "postgres"
        - name: JDBC_PASSWORD
          value: "postgres"
        - name: S3_DATA_BUCKET
          value: sqrl-examples-data-bucket
    vector:
      type: "aws_s3"
      bucket_name: "sqrl-test-artifacts"
      region: "us-east-1"
      assume_role: "arn:aws:iam::286928876767:role/vector-s3-role"
      key_prefix: "flink_metrics_raw/date=%Y-%m-%d/"
  database:
    image:
      name: ghcr.io/cloudnative-pg/postgresql
      tag: 16
  server:
    image:
      name: datasqrl/sqrl-server
      tag: ${config["values"]["deployment"]["sqrl_version"]}
    env_vars:
      - name: PGHOST
        value: "database-${config["values"]["deployment"]["shorten_id"]}-rw"
      - name: PGPORT
        value: "5432"
      - name: PGDATABASE
        value: "datasqrl"
      - name: PGUSER
        value: "postgres"
      - name: PGPASSWORD
        value: "postgres"