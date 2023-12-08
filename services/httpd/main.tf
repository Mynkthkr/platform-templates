module "ecs_service" {
  source = "terraform-aws-modules/ecs/aws//modules/service"

  name        = local.workspace.ecs_service.name
  cluster_arn = local.workspace.container_definitions.cluster_arn 
  requires_compatibilities = ["EC2"]
  network_mode = "bridge"
  launch_type = "EC2"
  runtime_platform = "null"
  cpu    = 256
  memory = 128

  # Container definition(s)
  container_definitions = {

    (local.workspace.container_definitions.conatiner_name) = {
    #   environment = {
    #   name  = "hello"
    #   value = "world"
    # }
      cpu       = 256
      memory    = 128
      essential = true
      image     = local.workspace.container_definitions.image 
      port_mappings = [
        {
          name          = local.workspace.container_definitions.name     #local.workspace.ecs_service.name
          containerPort = local.workspace.container_definitions.containerPort
          protocol      = local.workspace.container_definitions.protocol
        }
      ]

      # Example image used requires access to write to root filesystem
      readonly_root_filesystem = false

  

      #enable_cloudwatch_logging = false

      #memory_reservation = 100
    }
  }



  load_balancer = {
    service = {
      target_group_arn = "${data.aws_lb_target_group.test.id}"      #local.workspace.container_definitions.target_group_arn
      container_name   = local.workspace.load_balancer.container_name
      container_port   = local.workspace.load_balancer.container_port
    }
  }

  subnet_ids =  local.workspace.load_balancer.subnet_ids
  security_group_rules = {
    alb_ingress_3000 = {
      type                     = "ingress"
      from_port                = 80
      to_port                  = 80
      protocol                 = "tcp"
      description              = "Service port"
      source_security_group_id = "sg-0065ec72bb70f24bf"
    }
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}