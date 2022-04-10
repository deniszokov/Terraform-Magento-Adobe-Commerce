data "aws_ami" "imagebuilder" {
  for_each    = var.ec2
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["${local.project}-${each.key}-imagebuilder*"]
  }
  
  filter {
    name   = "architecture"
    values = ["arm64"]
  }
  
  filter {
    name   = "state"
    values = ["available"]
  }
}
