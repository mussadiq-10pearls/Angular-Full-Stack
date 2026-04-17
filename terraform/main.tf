provider "aws" {
  region = "us-east-1"
}

#####################################
# Random suffix
#####################################
resource "random_id" "suffix" {
  byte_length = 4
}

#####################################
# S3 Bucket (for artifacts)
#####################################
resource "aws_s3_bucket" "eb_bucket" {
  bucket        = "angular-full-stack-${random_id.suffix.hex}"
  force_destroy = true
}

#####################################
# IAM Role (EC2 for EB)
#####################################
resource "aws_iam_role" "ec2_role" {
  name = "eb-ec2-role-${random_id.suffix.hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_web" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "eb-ec2-profile-${random_id.suffix.hex}"
  role = aws_iam_role.ec2_role.name
}

#####################################
# Elastic Beanstalk Application
#####################################
resource "aws_elastic_beanstalk_application" "app" {
  name = "angular-full-stack-${random_id.suffix.hex}"
}

#####################################
# VPC + Subnets (TOP LEVEL - FIXED)
#####################################
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "map-public-ip-on-launch"
    values = ["true"]
  }
}

locals {
  selected_subnets = slice(data.aws_subnets.public.ids, 0, 2)
}

#####################################
# Elastic Beanstalk Environment
#####################################
resource "aws_elastic_beanstalk_environment" "env" {
  name                = "angular-env-${random_id.suffix.hex}"
  application         = aws_elastic_beanstalk_application.app.name
  solution_stack_name = "64bit Amazon Linux 2023 v6.10.1 running Node.js 20"

  #####################################
  # ENV VARIABLES
  #####################################
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "MONGODB_URI"
    value     = var.mongodb_uri
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "SECRET_TOKEN"
    value     = var.secret_token
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "NODE_ENV"
    value     = "production"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "PORT"
    value     = "8080"
  }

  #####################################
  # INSTANCE CONFIG
  #####################################
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "t3.micro"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.ec2_profile.name
  }

  #####################################
  # SCALING
  #####################################
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = "1"
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = "1"
  }

  #####################################
  # VPC CONFIG
  #####################################
  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = data.aws_vpc.default.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = join(",", local.selected_subnets)
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "AssociatePublicIpAddress"
    value     = "true"
  }

  depends_on = [
    aws_iam_instance_profile.ec2_profile
  ]
}

#####################################
# OUTPUTS (for CI/CD)
#####################################

output "url" {
  value = aws_elastic_beanstalk_environment.env.endpoint_url
}