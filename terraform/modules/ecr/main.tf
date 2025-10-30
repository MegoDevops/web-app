resource "aws_ecr_repository" "web" {
  name = "${var.project_name}-web"
  force_delete         = true 
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-web"
  }
}

resource "aws_ecr_repository" "api" {
  name = "${var.project_name}-api"
  force_delete         = true 
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-api"
  }
}