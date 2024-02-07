variable "apps" {
  description = "Map of all apps with their config"
  type        = any
  default     = {}
}

variable "aws_conf" {
  description = "Map of aws configs"

  type = object({
    region     = string
    account_id = string
  })
}

variable "common_tags" {
  description = "Tags per brands"
  type        = map(string)
}

variable "dynamodb_kms_key_arn" {
  description = "DynamoDB KMS key arn"
  type        = string
  default     = ""
}

variable "env" {
  description = "The project environment name"
  type        = string
}

variable "microservices" {
  description = "Map of all microservices projects with config"
  type        = any
  default     = {}
}

variable "project" {
  description = "The project name"
  type        = string
}

variable "sqs_enabled" {
  description = "Enable SQS"
  type        = bool
  default     = false
}

variable "suffix" {
  description = "Add unique suffix"
  type        = string
  default     = ""
}
