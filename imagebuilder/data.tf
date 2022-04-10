# # ---------------------------------------------------------------------------------------------------------------------#
# Get the name of the region where the Terraform deployment is running
# # ---------------------------------------------------------------------------------------------------------------------#
data "aws_region" "current" {}

# # ---------------------------------------------------------------------------------------------------------------------#
# Get the effective Account ID, User ID, and ARN in which Terraform is authorized.
# # ---------------------------------------------------------------------------------------------------------------------#
data "aws_caller_identity" "current" {}

# # ---------------------------------------------------------------------------------------------------------------------#
# Get get SSM Parameter Store variables
# # ---------------------------------------------------------------------------------------------------------------------#
data "aws_ssm_parameters_by_path" "env" {
  path      = "/env"
  recursive = true
}
locals {
  var = "${jsondecode(nonsensitive(element(data.aws_ssm_parameters_by_path.env.values, 0)))}"
}
# # ---------------------------------------------------------------------------------------------------------------------#
# Get get the latest ID of a registered AMI linux distro by owner and version
# # ---------------------------------------------------------------------------------------------------------------------#
data "aws_ami" "distro" {
  most_recent = true
  owners      = ["136693071363"] # debian

  filter {
    name   = "name"
    values = ["debian-11-arm64*"] # debian
  }
}
# # ---------------------------------------------------------------------------------------------------------------------#
# Get EventBridge role name
# # ---------------------------------------------------------------------------------------------------------------------#
data "aws_iam_role" "eventbridge_service_role" {
  name = "${local.var["PROJECT"]}-EventBridgeServiceRole"
}
# # ---------------------------------------------------------------------------------------------------------------------#
# Get get instance profiles from IAM
# # ---------------------------------------------------------------------------------------------------------------------#
data "aws_iam_instance_profile" "ec2" {
  for_each = toset(local.var["INSTANCE_NAMES"])
  name     = "${local.var["PROJECT"]}-EC2InstanceProfile-${each.key}"
}
# # ---------------------------------------------------------------------------------------------------------------------#
# Get get launch template id
# # ---------------------------------------------------------------------------------------------------------------------#
#data "aws_launch_template" "this" {
#  for_each = toset(local.var["INSTANCE_NAMES"])
#  filter {
#    name   = "launch-template-name"
#    values = ["${local.var["PROJECT"]}-${each.key}-ltpl"]
#  }
#}
# # ---------------------------------------------------------------------------------------------------------------------#
# Get get CodeCommit services repo name
# # ---------------------------------------------------------------------------------------------------------------------#
data "aws_codecommit_repository" "services" {
  repository_name = regex("//(.*)",local.var["CODECOMMIT_SERVICES_REPO"])[0]
}


