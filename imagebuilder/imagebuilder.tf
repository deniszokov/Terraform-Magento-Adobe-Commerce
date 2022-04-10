


////////////////////////////////////////////////////[ AWS IMAGE BUILDER ]/////////////////////////////////////////////////

# # ---------------------------------------------------------------------------------------------------------------------#
# Create ImageBuilder image
# # ---------------------------------------------------------------------------------------------------------------------#
resource "aws_imagebuilder_image" "this" {
  for_each                         = toset(local.var["INSTANCE_NAMES"])
  image_recipe_arn                 = aws_imagebuilder_image_recipe.this[each.key].arn
  infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.this[each.key].arn
  
  tags = {
    Name = "${local.var["PROJECT"]}-${each.key}-image"
  }
}
# # ---------------------------------------------------------------------------------------------------------------------#
# Create ImageBuilder image component
# # ---------------------------------------------------------------------------------------------------------------------#
resource "aws_imagebuilder_component" "build" {
  name         = "${local.var["PROJECT"]}-imagebuilder-component"
  description  = "ImageBuilder component for ${local.var["PROJECT"]}"
  data = file("${abspath(path.root)}/scripts/build.yml")
  platform = "Linux"
  version  = "1.0.0"
  
  tags = {
    Name = "${local.var["PROJECT"]}-imagebuilder-recipe"
  }
}
# # ---------------------------------------------------------------------------------------------------------------------#
# Create ImageBuilder image recipe
# # ---------------------------------------------------------------------------------------------------------------------#
resource "aws_imagebuilder_image_recipe" "this" {
  for_each     = toset(local.var["INSTANCE_NAMES"])
  name         = "${local.var["PROJECT"]}-${each.key}-imagebuilder-recipe"
  description  = "ImageBuilder recipe for ${each.key} in ${local.var["PROJECT"]} using debian-11-arm64"
  parent_image = data.aws_ami.distro.id
  version      = "1.0.0"
  
  block_device_mapping {
    device_name = "/dev/xvda"

    ebs {
      delete_on_termination = true
      encrypted             = true
      kms_key_id            = "alias/aws/ebs"
      volume_size           = local.var["VOLUME_SIZE"]
      volume_type           = "gp3"
    }
  }
  
  component {
    component_arn = aws_imagebuilder_component.build.arn
    parameter {
      name        = "PARAMETERSTORE_NAME"
      value       = "${element(data.aws_ssm_parameters_by_path.env.names, 0)}"
    }

    parameter {
      name        = "INSTANCE_NAME"
      value       = "${each.key}"
    }
    
    parameter {
      name        = "S3_SYSTEM_BUCKET"
      value       = "${local.var["S3_SYSTEM_BUCKET"]}"
    }
  }
  
  user_data_base64        = filebase64("${abspath(path.root)}/scripts/ssm.sh")

  lifecycle {
    create_before_destroy = true
  }
  
  tags = {
    Name = "${local.var["PROJECT"]}-${each.key}-imagebuilder-recipe"
  }
}
# # ---------------------------------------------------------------------------------------------------------------------#
# Create ImageBuilder infrastructure configuration
# # ---------------------------------------------------------------------------------------------------------------------#
resource "aws_imagebuilder_infrastructure_configuration" "this" {
  for_each              = toset(local.var["INSTANCE_NAMES"])
  name                  = "${local.var["PROJECT"]}-${each.key}-imagebuilder-infrastructure"
  description           = "ImageBuilder infrastructure for ${each.key} in ${local.var["PROJECT"]}"
  instance_profile_name = data.aws_iam_instance_profile.ec2[each.key].name
  instance_types        = ["c6g.xlarge"]
  security_group_ids    = [local.var["EC2_SECURITY_GROUP_ID"]]
  sns_topic_arn         = local.var["SNS_TOPIC_ARN"]
  subnet_id             = local.var["SUBNET_ID"]
  
  terminate_instance_on_failure = true

  logging {
    s3_logs {
      s3_bucket_name = local.var["S3_SYSTEM_BUCKET"]
      s3_key_prefix  = "imagebuilder"
    }
  }

  resource_tags = {
    Resource = "${local.var["PROJECT"]}-${each.key}-image"
  }
  
  tags = {
    Name = "${local.var["PROJECT"]}-${each.key}-imagebuilder-infrastructure"
  }
}
# # ---------------------------------------------------------------------------------------------------------------------#
# Create ImageBuilder image pipeline
# # ---------------------------------------------------------------------------------------------------------------------#
resource "aws_imagebuilder_image_pipeline" "this" {
  for_each                         = toset(local.var["INSTANCE_NAMES"])
  name                             = "${local.var["PROJECT"]}-${each.key}-imagebuilder-pipeline"
  description                      = "ImageBuilder pipeline for ${each.key} in ${local.var["PROJECT"]}"
  image_recipe_arn                 = aws_imagebuilder_image_recipe.this[each.key].arn
  infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.this[each.key].arn
  
  tags = {
    Name = "${local.var["PROJECT"]}-${each.key}-imagebuilder-pipeline"
  }
}
# # ---------------------------------------------------------------------------------------------------------------------#
# Create ImageBuilder image distribution configuration
# # ---------------------------------------------------------------------------------------------------------------------#
resource "aws_imagebuilder_distribution_configuration" "this" {
  for_each     = toset(local.var["INSTANCE_NAMES"])
  name         = "${local.var["PROJECT"]}-${each.key}-imagebuilder-distribution-configuration"
  description  = "ImageBuilder distribution configuration for ${each.key} in ${local.var["PROJECT"]}"
  distribution {
    ami_distribution_configuration {
      name         = "${local.var["PROJECT"]}-${each.key}-{{ imagebuilder:buildDate }}"
      description  = "AMI for ${each.key} in ${local.var["PROJECT"]} - {{ imagebuilder:buildDate }}"
      ami_tags = {
        Name = "${local.var["PROJECT"]}-${each.key}-{{ imagebuilder:buildDate }}"
      }
      launch_permission {
        user_ids = [data.aws_caller_identity.current.account_id]
      }
    }
    
    #launch_template_configuration {
    #  launch_template_id = data.aws_launch_template.this[each.key].id
    #}

    region = data.aws_region.current.name
  }
  
  tags = {
    Name = "${local.var["PROJECT"]}-${each.key}-imagebuilder-distribution-configuration"
  }
}
