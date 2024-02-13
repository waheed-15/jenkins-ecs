provider "aws" {
  region = var.region
}
resource "aws_ecr_repository" "app_repo" {
  name = var.ecr_name
}
output "ecr_repo_url" {
  value = aws_ecr_repository.app_repo.repository_url
}
