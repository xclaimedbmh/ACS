

#----------------------------------------------------------
# ACS730 - Week 3 - Terraform Introduction
#
# Build EC2 Instances
#
#----------------------------------------------------------

# Step 1 - Define the provider
provider "aws" {
  region = "us-east-1"
}

# Step 12 - Data source for AMI id
data "aws_ami" "latest_amazon_linux" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Step 12 - Use remote state to retrieve the data
data "terraform_remote_state" "public_subnet" { // This is to use Outputs from Remote State
  backend = "s3"
  config = {
    bucket = "acs730-week4-igeiman"               // Bucket from where to GET Terraform State
    key    = "01-networking/terraform.tfstate" // Object name in the bucket to GET Terraform State
    region = "us-east-1"                          // Region where bucket created
  }
}

# Step 12 - Data source for availability zones in us-east-1
data "aws_availability_zones" "available" {
  state = "available"
}

# Step 12 - Reference subnet provisioned by 01-Networking 
resource "aws_instance" "my_amazon" {
  ami                         = data.aws_ami.latest_amazon_linux.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.web_key.key_name
  subnet_id                   = data.terraform_remote_state.public_subnet.outputs.subnet_id
  associate_public_ip_address = true

  tags = merge(var.default_tags,
    {
      "Name" = "${var.prefix}-Amazon-Linux"
    }
  )
}

# Step 4 -  Attach EBS volume
resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.web_ebs.id
  instance_id = aws_instance.my_amazon.id
}



# Step 5 - Adding SSH key to Amazon EC2
resource "aws_key_pair" "web_key" {
  key_name   = var.prefix
  public_key = file("${var.prefix}.pub")
}

# Step 9 - Create another EBS volume
resource "aws_ebs_volume" "web_ebs" {
  availability_zone = data.aws_availability_zones.available.names[1]
  size              = 40

  tags = merge(var.default_tags,
    {
      "Name" = "${var.prefix}-EBS"
    }
  )
}