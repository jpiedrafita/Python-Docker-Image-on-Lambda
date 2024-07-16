variable "profile" {
  description = "The AWS profile to use"
  type        = string
  default     = "sbot"
}

variable "region" {
  description = "The AWS region to deploy to"
  type        = string
  default     = "eu-south-2"
}

variable "env_name" {
  description = "The environment name"
  type        = string
  default     = "dev"
}
