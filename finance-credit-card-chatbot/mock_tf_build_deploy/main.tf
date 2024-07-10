locals {
  namespace  = "datasqrl"
  aws_region = "us-east-1"



  local_data_locations = toset([
    "/home/runner/work/datasqrl-examples/datasqrl-examples/finance-credit-card-chatbot/creditcard-local/cardAssignment.jsonl",
    "/home/runner/work/datasqrl-examples/datasqrl-examples/finance-credit-card-chatbot/creditcard-local/merchant.jsonl",
    "/home/runner/work/datasqrl-examples/datasqrl-examples/finance-credit-card-chatbot/creditcard-local/merchantReward.jsonl",
    "/home/runner/work/datasqrl-examples/datasqrl-examples/finance-credit-card-chatbot/creditcard-local/transaction.jsonl",
  ])

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
  source = "../../modules/component-aws-managed-full-stack-local"

  engine_server_image = "286928876767.dkr.ecr.us-east-1.amazonaws.com/datasqrl-examples/finance-credit-card-chatbot/package-analytics-no-chat/deploy-server:latest"

  engine_db_username                        = "postgres"
  engine_db_dbname                          = "datasqrl"
  engine_db_database_schema_script_location = "/home/runner/work/datasqrl-examples/datasqrl-examples/finance-credit-card-chatbot/build/deploy/postgres/database-schema.sql"

  engine_flink_jar_file_path               = "/home/runner/work/datasqrl-examples/datasqrl-examples/FlinkJob.jar"
  engine_flink_aws_managed_property_groups = local.engine_flink_aws_managed_property_groups
  local_data_locations                     = local.local_data_locations
  engine_server_environment_variables      = local.engine_server_environment_variables
}