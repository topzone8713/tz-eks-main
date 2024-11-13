resource "awscc_ecr_repository" "tz-devops-admin" {
  repository_name      = "tz-devops-admin"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration = {
    scan_on_push = true
  }
}

resource "awscc_ecr_repository" "tz-demo-app" {
  repository_name      = "tz-demo-app"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration = {
    scan_on_push = true
  }
}
