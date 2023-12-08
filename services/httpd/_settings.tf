provider "aws" {
  region     = "us-east-1"
  access_key = "AKIAW54MKN5E24ZQCQEN"
  secret_key = "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"
}


locals {
  #env       = yamldecode(file("${path.module}/config.yml"))
 # common    = local.env["common"]
  env_space = yamldecode(file("config.yml"))
  workspace = local.env_space["workspace"][terraform.workspace]

  project_name_prefix = "${local.workspace.environment_name}"

  tags = {
    Project     = local.workspace.environment_name
    Environment = local.workspace.environment_name
  }
}


