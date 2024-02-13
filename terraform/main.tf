module "ecs_config" {
  source = "./modules/ecs_config"
  # Other configuration for ecs_config module
}

module "task_definition" {
  source = "./modules/task_definition"
  ecs_cluster_id = module.ecs_config.ecs_cluster_id
  ecr_image_uri = var.ecr_image_uri
}
