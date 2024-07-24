# module "sqrl-aws-managed-flink-example" {
#   source = "git@github.com:DataSQRL/sqrl-cloud.git//cdktf.out/stacks/sqrlpipeline?ref=33-refactor-top-level-maintf-with-cdktf"
#   namespace  = "sqrl"
#   aws_region = "us-east-1"
#   engine_server_image = "286928876767.dkr.ecr.us-east-1.amazonaws.com/datasqrl-examples/finance-credit-card-chatbot/package-analytics-no-chat/deploy-server:latest"

#   engine_db_username                        = "postgres"
#   engine_db_dbname                          = "datasqrl"
#   engine_db_database_schema_script_location = "database-schema.sql"

#   engine_flink_jar_file_path               = "FlinkJob.jar"
#   engine_flink_s3_data_bucket              = "sqrl-examples-data-bucket"
#   create_customer_dns_record               = "true"
#   customer_dns_domain_name                 = "customer1-pipeline.sqrl-dev.live"
# }

terraform {
  required_version = ">= 1.2"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }

    aws = {
      version = "~> 5.42.0"
      source  = "registry.terraform.io/hashicorp/aws"
    }
    random = {
      version = ">= 3.6.0"
      source  = "registry.terraform.io/hashicorp/random"
    }
  }
}


provider "aws" {
  region = var.aws_region
}