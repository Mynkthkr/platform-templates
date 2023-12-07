provider "aws" {

}


locals {
  #env       = yamldecode(file("${path.module}/config.yml"))
 # common    = local.env["common"]
  # env_space = yamldecode(file("config.yml"))
 # env_space = yamldecode(file("../../../platform-config/platform/cluster/config.yml"))
  # env_space = yamldecode(file("${path.module}/../../platform-config/platform/cluster/config.yml"))
  config_content = file("${path.module}/../../../platform-config/platform/cluster/config.yml")
  env_space      = jsondecode(replace(local.config_content, "/\\n/", ""))
  workspace = local.env_space["workspace"][terraform.workspace]

  project_name_prefix = "${local.workspace.environment_name}"

  tags = {
    Project     = local.workspace.environment_name
    Environment = local.workspace.environment_name
  }
}


