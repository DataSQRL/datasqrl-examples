locals {
  namespace  = "datasqrl"
  aws_region = "us-east-1"

  engine_server_environment_variables = {
    "PROPERTIES_BOOTSTRAP_SERVERS" : "kafka:9092"
  }

  engine_flink_aws_managed_property_groups = [
    {
      "property_group_id" : "ProducerConfigProperties",
      "property_map" : {
        "flink.stream.initpos"            = "LATEST"
        "AggregationEnabled"              = "false"
        "log4j.appender.file.MaxFileSize" = "10MB"
      }
    }
  ]
}


module "sqrl-aws-managed-flink-example" {
  source = "git@github.com:DataSQRL/sqrl-cloud.git//modules/component-aws-managed-full-stack-local"

  engine_server_image = "286928876767.dkr.ecr.us-east-1.amazonaws.com/datasqrl-examples/finance-credit-card-chatbot/package-analytics-no-chat/deploy-server:latest"

  engine_db_username                        = "postgres"
  engine_db_dbname                          = "datasqrl"
  engine_db_database_schema_script_location = "database-schema.sql"

  engine_flink_jar_file_path               = "FlinkJob.jar"
  engine_flink_aws_managed_property_groups = local.engine_flink_aws_managed_property_groups
  engine_server_environment_variables      = local.engine_server_environment_variables
  engine_flink_s3_data_bucket              = "sqrl-examples-data-bucket"
  create_customer_dns_record               = true
  customer_dns_domain_name                 = "customer1-pipeline.sqrl-dev.live"
}


module "cluster" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "9.3.0"

  name           = "test-aurora-db-postgres96"
  engine         = "aurora-postgresql"
  engine_version = "14.5"
  instance_class = "db.r6g.large"
  instances = {
    one = {}
    2 = {
      instance_class = "db.r6g.2xlarge"
    }
  }

  vpc_id               = "vpc-0812002a4607076a4"
  db_subnet_group_name = "db-subnet-group"

  storage_encrypted   = true
  apply_immediately   = true
  monitoring_interval = 10

  enabled_cloudwatch_logs_exports = ["postgresql"]

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}