resource "aws_ecr_repository" "backend" {
  name                 = "shopnow-backend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name    = "shopnow-backend"
    Project = var.project_name
  }
}

resource "aws_ecr_repository" "frontend" {
  name                 = "shopnow-frontend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name    = "shopnow-frontend"
    Project = var.project_name
  }
}

resource "aws_ecr_repository" "admin" {
  name                 = "shopnow-admin"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name    = "shopnow-admin"
    Project = var.project_name
  }
}

# Lifecycle policy — keep the last 10 images, purge untagged after 1 day
resource "aws_ecr_lifecycle_policy" "backend" {
  repository = aws_ecr_repository.backend.name
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 tagged images"
        selection = {
          tagStatus   = "tagged"
          tagPrefixList = ["v", "latest", "build-"]
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Expire untagged images after 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = { type = "expire" }
      }
    ]
  })
}

resource "aws_ecr_lifecycle_policy" "frontend" {
  repository = aws_ecr_repository.frontend.name
  policy     = aws_ecr_lifecycle_policy.backend.policy
}

resource "aws_ecr_lifecycle_policy" "admin" {
  repository = aws_ecr_repository.admin.name
  policy     = aws_ecr_lifecycle_policy.backend.policy
}
