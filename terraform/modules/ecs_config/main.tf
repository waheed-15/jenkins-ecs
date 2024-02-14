resource "aws_ecs_cluster" "ecs_cluster" {
  count = length(terraform.workspace == "default" ? [] : aws_ecs_cluster.ecs_cluster[*]) == 0 ? 1 : 0
  name  = "my-ecs-cluster"
}


output "ecs_cluster_id" {
  value = aws_ecs_cluster.ecs_cluster[length(aws_ecs_cluster.ecs_cluster) - 1].id
}

resource "aws_launch_template" "ecs_lt" {
  count = length(terraform.workspace == "default" ? [] : aws_launch_template.ecs_lt[*]) == 0 ? 1 : 0

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
  count = length(terraform.workspace == "default" ? [] : aws_autoscaling_group.ecs_asg[*]) == 0 ? 1 : 0
  
  vpc_zone_identifier = ["subnet-0ab6ee277d0b523f8", "subnet-0c192bb582f2042c0"]
  desired_capacity    = 2
  max_size            = 2
  min_size            = 1

  launch_template {
    id      = aws_launch_template.ecs_lt[0].id
    version = "$Latest"
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }
}


resource "null_resource" "check_capacity_provider" {
  # This resource doesn't create anything, it just runs the local-exec provisioner
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<EOT
      # Check if the capacity provider already exists in the terraform.tfstate
      if grep -q '"aws_ecs_capacity_provider"."ecs_capacity_provider"' /var/lib/jenkins/workspace/test/terraform/modules/ecs_config/terraform.tfstate; then
        echo "Capacity provider already exists"
        echo "CAPACITY_PROVIDER_EXISTS = true" > /var/lib/jenkins/workspace/test/terraform/modules/ecs_config/terraform.tfvars
      else
        echo "Capacity provider does not exist"
        echo "CAPACITY_PROVIDER_EXISTS = false" > /var/lib/jenkins/workspace/test/terraform/modules/ecs_config/terraform.tfvars
      fi
    EOT
  }
}

data "aws_ecs_capacity_provider" "existing_capacity_provider" {
  name = "test1"
}

resource "aws_ecs_capacity_provider" "ecs_capacity_provider" {
  count = data.aws_ecs_capacity_provider.existing_capacity_provider ? 0 : 1
  
  name = "test1"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ecs_asg[0].arn

    managed_scaling {
      maximum_scaling_step_size = 1000
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 3
    }
  }
}

output "capacity_provider_name" {
  value = aws_ecs_capacity_provider.ecs_capacity_provider[0].name  
}

resource "aws_ecs_cluster_capacity_providers" "example" {
  count = length(terraform.workspace == "default" ? [] : aws_ecs_cluster_capacity_providers.example[*]) == 0 ? 1 : 0

  cluster_name = aws_ecs_cluster.ecs_cluster[length(aws_ecs_cluster.ecs_cluster) - 1].name

  capacity_providers = [aws_ecs_capacity_provider.ecs_capacity_provider[length(aws_ecs_capacity_provider.ecs_capacity_provider) - 1].name]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider[0].name
  }
}


resource "aws_ecs_task_definition" "ecs_task_definition" {
  count = length(terraform.workspace == "default" ? [] : aws_ecs_task_definition.ecs_task_definition[*]) == 0 ? 1 : 0

  family             = "my-ecs-task"
  network_mode       = "awsvpc"
  execution_role_arn = "arn:aws:iam::847415613895:role/adminrole"
  cpu                = 256

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name      = "dockergs"
      image     = var.ecr_image_uri
      cpu       = 256
      memory    = 512
      essential = true

      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
    }
  ])
}


resource "aws_ecs_service" "ecs_service" {
  name             = "my-ecs-service"
  cluster          = aws_ecs_cluster.ecs_cluster[length(aws_ecs_cluster.ecs_cluster) - 1].id
  task_definition  = aws_ecs_task_definition.ecs_task_definition[length(aws_ecs_task_definition.ecs_task_definition) - 1].arn
  desired_count    = 2

  network_configuration {
    subnets         = ["subnet-0ab6ee277d0b523f8", "subnet-0c192bb582f2042c0"]
    security_groups = ["sg-0498660e030d72814", "sg-067e56dd2d6651ddf"]
  }

  force_new_deployment = true

  placement_constraints {
    type = "distinctInstance"
  }

  triggers = {
    redeployment = timestamp()
  }

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider[length(aws_ecs_capacity_provider.ecs_capacity_provider) - 1].name
    weight            = 100
  }
  
  depends_on = [aws_autoscaling_group.ecs_asg]
}
