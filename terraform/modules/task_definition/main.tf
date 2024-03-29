resource "aws_ecs_task_definition" "ecs_task_definition" {
 family             = "my-ecs-task"
 network_mode       = "awsvpc"
 execution_role_arn = "arn:aws:iam::532199187081:role/ecsTaskExecutionRole"
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

data "aws_ecs_clusters" "existing_clusters" {
  names = "my-ecs-cluster"
}

data "aws_ecs_capacity_providers" "existing_providers" {
  names = "test1"
}

resource "aws_ecs_service" "ecs_service" {
 name            = "my-ecs-service"
 cluster         = data.aws_ecs_clusters.existing_clusters.id
 task_definition = aws_ecs_task_definition.ecs_task_definition.arn
 desired_count   = 2

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
   capacity_provider = data.aws_ecs_capacity_providers.existing_providers.name
   weight            = 100
 }

#  load_balancer {
#    target_group_arn = aws_lb_target_group.ecs_tg.arn
#    container_name   = "dockergs"
#    container_port   = 80
#  }

#  depends_on = module.ecs_config.aws_autoscaling_group.ecs_asg
 }