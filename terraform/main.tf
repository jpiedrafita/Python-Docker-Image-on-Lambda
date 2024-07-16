terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

}

provider "aws" {
  profile = var.profile
  region  = "eu-south-2"
}

resource "aws_ecr_repository" "lambda_repo" {
  name = "docker-lambda-repo-${var.env_name}"
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda-${var.env_name}"
  assume_role_policy = jsonencode({
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}


resource "aws_lambda_function" "docker_lambda" {
  function_name = "docker_lambda_function-${var.env_name}"
  timeout       = 10
  role          = aws_iam_role.iam_for_lambda.arn
  image_uri     = "${aws_ecr_repository.lambda_repo.repository_url}:${var.env_name}"
  package_type  = "Image"
  environment {
    variables = {
      ENVIRONMENT = var.env_name
    }
  }
}