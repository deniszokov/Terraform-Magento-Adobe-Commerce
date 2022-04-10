

//////////////////////////////////////////////////////[ LAUNCH TEMPLATE ]/////////////////////////////////////////////////

# # ---------------------------------------------------------------------------------------------------------------------#
# Create Launch Template for Autoscaling Groups - user_data converted
# # ---------------------------------------------------------------------------------------------------------------------#
resource "aws_launch_template" "this" {
  for_each = var.ec2
  name = "${local.project}-${each.key}-ltpl"
  iam_instance_profile { name = aws_iam_instance_profile.ec2[each.key].name }
  image_id = element(aws_imagebuilder_image.this[each.key].output_resources[*].amis[*].image, 0)[0]
  instance_type = each.value
  monitoring { enabled = var.asg["monitoring"] }
  network_interfaces { 
    associate_public_ip_address = true
    security_groups = [aws_security_group.ec2.id]
  }
  dynamic "tag_specifications" {
    for_each = toset(["instance","volume"])
    content {
       resource_type = tag_specifications.key
       tags = merge(data.aws_default_tags.this.tags,{Name = "${local.project}-${each.key}-ec2", Project = "${local.project}"})
    }
  }
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }
  user_data = filebase64("${abspath(path.root)}/user_data/${each.key}")
  update_default_version = true
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    Name = "${local.project}-${each.key}-ltpl"
  }
}
