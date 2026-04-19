resource "aws_ecr_repository" "app" {
  name                 = "url-shortener"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = { Project = "url-shortener", Env = "dev" }
}

output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

