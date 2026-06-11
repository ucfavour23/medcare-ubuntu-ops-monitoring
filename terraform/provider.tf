provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Company     = "MedCare Health Services"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
