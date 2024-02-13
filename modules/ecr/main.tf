resource "aws_ecr_repository" "app_repo" {
  name = "my-app-repo"
}

output "ecr_repo_url" {
  value = aws_ecr_repository.app_repo.repository_url
}
