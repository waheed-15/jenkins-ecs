module "ecs_config" {
  source = "./modules/ecs_config"
}

module "task_definition" {
  source         = "./modules/task_definition"
  capacity_provider_name = module.ecs_config.capacity_provider_name
  ecr_image_uri = var.ecr_image_uri
}
