resource "aws_ecs_cluster" "ecs_cluster" {
 name = "my-ecs-cluster"
}

output "ecs_cluster_id" {
  value = aws_ecs_cluster.ecs_cluster.id
}

resource "aws_launch_template" "ecs_lt" {
 name_prefix   = "ecs-template"
 image_id      = var.ami_id
 instance_type = var.instance_type

 key_name               = var.key_name
 vpc_security_group_ids = ["sg-0498660e030d72814", "sg-067e56dd2d6651ddf"]
 iam_instance_profile {
   name = "adminrole"
 }

 block_device_mappings {
   device_name = "/dev/xvda"
   ebs {
     volume_size = 30
     volume_type = "gp2"
   }
 }

 tag_specifications {
   resource_type = "instance"
   tags = {
     Name = "ecs-instance"
   }
 }

 user_data = filebase64("./ecs.sh")
}

resource "aws_autoscaling_group" "ecs_asg" {
 vpc_zone_identifier = ["subnet-0ab6ee277d0b523f8", "subnet-0c192bb582f2042c0"]
 desired_capacity    = 2
 max_size            = 2
 min_size            = 1

 launch_template {
   id      = aws_launch_template.ecs_lt.id
   version = "$Latest"
 }

 tag {
   key                 = "AmazonECSManaged"
   value               = true
   propagate_at_launch = true
 }
}

resource "aws_ecs_capacity_provider" "ecs_capacity_provider" {
 name = "test1"

 auto_scaling_group_provider {
   auto_scaling_group_arn = aws_autoscaling_group.ecs_asg.arn

   managed_scaling {
     maximum_scaling_step_size = 1000
     minimum_scaling_step_size = 1
     status                    = "ENABLED"
     target_capacity           = 3
   }
 }
}

resource "aws_ecs_cluster_capacity_providers" "example" {
 cluster_name = aws_ecs_cluster.ecs_cluster.name

 capacity_providers = [aws_ecs_capacity_provider.ecs_capacity_provider.name]

 default_capacity_provider_strategy {
   base              = 1
   weight            = 100
   capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider.name
 }
}

# resource "aws_ecs_task_definition" "ecs_task_definition" {
#  family             = "my-ecs-task"
#  network_mode       = "awsvpc"
#  execution_role_arn = module.ecr.aws_ecr_repository.app_repo.repository_url
#  cpu                = 256
#  runtime_platform {
#    operating_system_family = "LINUX"
#    cpu_architecture        = "X86_64"
#  }
#  container_definitions = jsonencode([
#    {
#      name      = "dockergs"
#      image     = var.ecr_image_uri
#      cpu       = 256
#      memory    = 512
#      essential = true
#      portMappings = [
#        {
#          containerPort = 80
#          hostPort      = 80
#          protocol      = "tcp"
#        }
#      ]
#    }
#  ])
# }


# resource "aws_ecs_service" "ecs_service" {
#  name            = "my-ecs-service"
#  cluster         = aws_ecs_cluster.ecs_cluster.id
#  task_definition = aws_ecs_task_definition.ecs_task_definition.arn
#  desired_count   = 2

#  network_configuration {
#    subnets         = ["subnet-0ab6ee277d0b523f8", "subnet-0c192bb582f2042c0"]
#    security_groups = ["sg-0498660e030d72814", "sg-067e56dd2d6651ddf"]
#  }

#  force_new_deployment = true
#  placement_constraints {
#    type = "distinctInstance"
#  }

#  triggers = {
#    redeployment = timestamp()
#  }

#  capacity_provider_strategy {
#    capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider.name
#    weight            = 100
#  }

#  load_balancer {
#    target_group_arn = aws_lb_target_group.ecs_tg.arn
#    container_name   = "dockergs"
#    container_port   = 80
#  }

#  depends_on = [aws_autoscaling_group.ecs_asg]
# }
