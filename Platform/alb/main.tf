data "aws_availability_zones" "available" {}

locals {
  region = "us-east-1"
  name   = "demo"

  container_name = "ngnix"
  container_port = 8080


}





################################################################################
# Supporting Resources
################################################################################

data "aws_ssm_parameter" "ecs_optimized_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended"
}

module "alb_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "${local.name}-service"
  description = "Service security group"
  vpc_id      = "vpc-0803d89825ac7428d" #module.vpc.vpc_id

  ingress_rules       = ["http-80-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]

  egress_rules       = ["all-all"]
  egress_cidr_blocks = ["0.0.0.0/0"] #module.vpc.private_subnets_cidr_blocks

  tags = local.tags
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 8.0"

  name = local.name

  load_balancer_type = "application"

  vpc_id          = "vpc-0803d89825ac7428d" #module.vpc.vpc_id
  subnets         = ["subnet-0377a9b6b8da787d5", "subnet-05b5c288fbbb4cfab"] #module.vpc.public_subnets
  security_groups = ["sg-0383da77192b3ca33"]

  http_tcp_listeners = [
    {
      port               =  80
      protocol           = "HTTP"
      target_group_index = 0
    },
  ]

  target_groups = [
    {
      name             = "${local.name}-${local.container_name}"
      backend_protocol = "HTTP"
      backend_port     = local.container_port
      target_type      = "instance"
      tags = {
        Project = "TTN-Infra" 
      }
    },
  ]

  # tags = {
  #   Project = "TTN-Infra" 
  # }
}

# module "autoscaling" {
#   source  = "terraform-aws-modules/autoscaling/aws"
#   version = "~> 6.5"

#   for_each = {
#     # On-demand instances
#     ex-1 = {
#       name= "myasg"
#       instance_type              = "t3.large"
#       use_mixed_instances_policy = false
#       mixed_instances_policy     = {}
#       user_data                  = <<-EOT
#         #!/bin/bash
#         cat <<'EOF' >> /etc/ecs/ecs.config
#         ECS_CLUSTER=${local.name}
#         ECS_LOGLEVEL=debug
#         ECS_CONTAINER_INSTANCE_TAGS=${jsonencode(local.tags)}
#         ECS_ENABLE_TASK_IAM_ROLE=true
#         EOF
#       EOT
#     }
#     # Spot instances
#     ex-2 = {
#       instance_type              = "t3.medium"
#       use_mixed_instances_policy = true
#       mixed_instances_policy = {
#         instances_distribution = {
#           on_demand_base_capacity                  = 0
#           on_demand_percentage_above_base_capacity = 0
#           spot_allocation_strategy                 = "price-capacity-optimized"
#         }

#         override = [
#           {
#             instance_type     = "m4.large"
#             weighted_capacity = "2"
#           },
#           {
#             instance_type     = "t3.large"
#             weighted_capacity = "1"
#           },
#         ]
#       }
#       user_data = <<-EOT
#         #!/bin/bash
#         cat <<'EOF' >> /etc/ecs/ecs.config
#         ECS_CLUSTER=${local.name}
#         ECS_LOGLEVEL=debug
#         ECS_CONTAINER_INSTANCE_TAGS=${jsonencode(local.tags)}
#         ECS_ENABLE_TASK_IAM_ROLE=true
#         ECS_ENABLE_SPOT_INSTANCE_DRAINING=true
#         EOF
#       EOT
#     }
#   }

#   name = "${local.name}-${each.key}"

#   image_id      = jsondecode(data.aws_ssm_parameter.ecs_optimized_ami.value)["image_id"]
#   instance_type = each.value.instance_type

#   security_groups                 = [module.autoscaling_sg.security_group_id]
#   user_data                       = base64encode(each.value.user_data)
#   ignore_desired_capacity_changes = true

#   create_iam_instance_profile = true
#   iam_role_name               = local.name
#   iam_role_description        = "ECS role for ${local.name}"
#   iam_role_policies = {
#     AmazonEC2ContainerServiceforEC2Role = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
#     AmazonSSMManagedInstanceCore        = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
#   }

#   vpc_zone_identifier = module.vpc.private_subnets
#   health_check_type   = "EC2"
#   min_size            = 1
#   max_size            = 5
#   desired_capacity    = 2

#   # https://github.com/hashicorp/terraform-provider-aws/issues/12582
#   autoscaling_group_tags = {
#     AmazonECSManaged = true
#   }

#   # Required for  managed_termination_protection = "ENABLED"
#   protect_from_scale_in = true

#   # Spot instances
#   use_mixed_instances_policy = each.value.use_mixed_instances_policy
#   mixed_instances_policy     = each.value.mixed_instances_policy

#   tags = local.tags
# }

# module "autoscaling_sg" {
#   source  = "terraform-aws-modules/security-group/aws"
#   version = "~> 4.0"

#   name        = local.name
#   description = "Autoscaling group security group"
#   vpc_id      = module.vpc.vpc_id

#   computed_ingress_with_source_security_group_id = [
#     {
#       rule                     = "http-80-tcp"
#       source_security_group_id = module.alb_sg.security_group_id
#     }
#   ]
#   number_of_computed_ingress_with_source_security_group_id = 1

#   egress_rules = ["all-all"]

#   tags = local.tags
# }

# module "vpc" {
#   source  = "terraform-aws-modules/vpc/aws"
#   version = "~> 4.0"

#   name = local.name
#   cidr = local.vpc_cidr

#   azs             = local.azs
#   private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
#   public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]

#   enable_nat_gateway = true
#   single_nat_gateway = true

#   tags = local.tags
# }