module "sqrl-aws-managed-flink-example" {
  source = "../../modules/component-aws-managed-full-stack-local"

  engine_server_image = local.engine_server_image

  engine_db_username                        = "postgres"
  engine_db_dbname                          = "datasqrl"
  engine_db_database_schema_script_location = ""

  engine_flink_jar_file_path               = ""
  engine_flink_aws_managed_property_groups = local.engine_flink_aws_managed_property_groups
  local_data_locations                     = local.local_data_locations
  engine_server_environment_variables      = local.engine_server_environment_variables
}