# # ---------------------------------------------------------------------------------------------------------------------#
# Get the name of the region where the Terraform deployment is running
# # ---------------------------------------------------------------------------------------------------------------------#
data "aws_region" "current" {}

# # ---------------------------------------------------------------------------------------------------------------------#
# Get the effective Account ID, User ID, and ARN in which Terraform is authorized.
# # ---------------------------------------------------------------------------------------------------------------------#
data "aws_caller_identity" "current" {}

# # ---------------------------------------------------------------------------------------------------------------------#
# Get the Account ID of the AWS ELB Service Account for the purpose of permitting in S3 bucket policy.
# # ---------------------------------------------------------------------------------------------------------------------#
data "aws_elb_service_account" "current" {}

# # ---------------------------------------------------------------------------------------------------------------------#
# Get AWS Inspector rules available in this region
# # ---------------------------------------------------------------------------------------------------------------------#
data "aws_inspector_rules_packages" "available" {}

# # ---------------------------------------------------------------------------------------------------------------------#
# Get the list of AWS Availability Zones available in this region
# # ---------------------------------------------------------------------------------------------------------------------#
data "aws_availability_zones" "available" {
  state            = "available"
  exclude_zone_ids = ["use1-az3"]
}

data "aws_availability_zone" "all" {
  for_each = toset(data.aws_availability_zones.available.names)
  name = each.key
}
# # ---------------------------------------------------------------------------------------------------------------------#
# Get the ID of default VPC
# # ---------------------------------------------------------------------------------------------------------------------#
data "aws_vpc" "default" {
  default = true
}
# # ---------------------------------------------------------------------------------------------------------------------#
# Get default subnets from AZ in this region/vpc
# # ---------------------------------------------------------------------------------------------------------------------#
data "aws_subnets" "default" {
   filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
   }

  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}
# # ---------------------------------------------------------------------------------------------------------------------#
# Get all available VPC in this region
# # ---------------------------------------------------------------------------------------------------------------------#
data "aws_vpcs" "available" {}

data "aws_vpc" "all" {
  for_each = toset(data.aws_vpcs.available.ids)
  id = each.key
}
# # ---------------------------------------------------------------------------------------------------------------------#
# Get the ID of default Security Group
# # ---------------------------------------------------------------------------------------------------------------------#
data "aws_security_group" "default" {
  vpc_id = data.aws_vpc.default.id

  filter {
    name   = "group-name"
    values = ["default"]
  }
}
# # ---------------------------------------------------------------------------------------------------------------------#
# Get the ID of CloudFront origin request policy
# # ---------------------------------------------------------------------------------------------------------------------#
data "aws_cloudfront_origin_request_policy" "s3" {
  name = "Managed-CORS-S3Origin"
}
data "aws_cloudfront_origin_request_policy" "custom" {
  name = "Managed-CORS-CustomOrigin"
}
# # ---------------------------------------------------------------------------------------------------------------------#
# Get the ID of CloudFront cache policy.
# # ---------------------------------------------------------------------------------------------------------------------#
data "aws_cloudfront_cache_policy" "s3" {
  name = "Managed-CachingOptimizedForUncompressedObjects"
}
data "aws_cloudfront_cache_policy" "custom" {
  name = "Managed-CachingOptimized"
}
