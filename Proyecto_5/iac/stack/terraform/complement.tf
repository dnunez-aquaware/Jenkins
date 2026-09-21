resource "aws_ecr_repository" "cloud_dashboard" {
  name                 = "cloud-dashboard"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}