resource "aws_ecr_repository" "cloud_dashboard" {
  name                 = "cloud-dashboard"
  # Con versionado semantico un tag publicado no debe poder sobrescribirse:
  # v1.0.1 siempre apunta a la misma imagen.
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}