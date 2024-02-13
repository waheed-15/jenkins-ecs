data "aws_ecs_cluster" "existing_cluster" {
  cluster_name = "my-ecs-cluster"  # Replace this with the name of your ECS cluster
}

module "task_definition" {
  source         = "./modules/task_definition"
  ecs_cluster_id = data.aws_ecs_cluster.existing_cluster.id
  ecr_image_uri = var.ecr_image_uri
}
