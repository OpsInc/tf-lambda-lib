variable "apps" {
  description = "Map of all apps with their config"
  type        = any
  default     = {}
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

variable "lambdas" {
  description = "Map of all lambda projects with config"
  type        = any
  default     = {}
}

variable "project" {
  description = "The project name"
  type        = string
}

variable "suffix" {
  description = "Add uniq suffix, can also include the environment name"
  type        = string
}
