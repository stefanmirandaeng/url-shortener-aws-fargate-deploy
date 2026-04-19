provider "aws" {
  region = local.region
}

data "aws_availability_zones" "available" {
  # Exclude local zones
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

################################################################################
# Cluster
################################################################################

module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 6.0"

  cluster_name = local.name

  default_capacity_provider_strategy = {
    FARGATE = {
      weight = 100
      base   = 1
    }
  }

  tags = local.tags
}

################################################################################
# Service
################################################################################
module "ecs_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "~> 6.0"

  name        = "url-shortener"
  cluster_arn = module.ecs_cluster.cluster_arn

  cpu    = 256
  memory = 512

  container_definitions = {
    url-shortener = {
      cpu       = 256
      memory    = 512
      essential = true
      image     = "447170313597.dkr.ecr.ap-southeast-2.amazonaws.com/url-shortener:latest"

      portMappings = [
        {
          name          = "url-shortener"
          containerPort = 5000
          hostPort      = 5000
          protocol      = "tcp"
        }
      ]

      enable_cloudwatch_logging = true

      readonly_root_filesystem = false
    }
  }

  load_balancer = {
    service = {
      target_group_arn = module.alb.target_groups["ex-ecs"].arn
      container_name   = "url-shortener"
      container_port   = 5000
    }
  }

  subnet_ids = module.vpc.private_subnets

  security_group_ingress_rules = {
    alb_5000 = {
      description                  = "Allow traffic from ALB"
      from_port                    = 5000
      ip_protocol                  = "tcp"
      referenced_security_group_id = module.alb.security_group_id
    }
  }

  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  tags = local.tags
}

################################################################################
# Supporting Resources
################################################################################

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 10.0"

  name = "url-shortener"

  load_balancer_type = "application"

  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets

  enable_deletion_protection = false

  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = module.vpc.vpc_cidr_block
    }
  }

  listeners = {
    ex-http = {
      port     = 80
      protocol = "HTTP"

      forward = {
        target_group_key = "ex-ecs"
      }
    }
  }

  target_groups = {
    ex-ecs = {
      backend_protocol                  = "HTTP"
      backend_port                      = 5000
      target_type                       = "ip"
      deregistration_delay              = 5
      load_balancing_cross_zone_enabled = true

      health_check = {
        enabled             = true
        healthy_threshold   = 5
        interval            = 30
        matcher             = "200"
        path                = "/health"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        unhealthy_threshold = 2
      }

      create_attachment = false
    }
  }

  tags = local.tags
}