provider "aws" {
  region = "eu-north-1"

  default_tags {
    tags = {
      "Name"    = var.project_name
      "Project" = var.project_name
    }
  }
}

}