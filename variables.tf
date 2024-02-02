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

variable "project_identifier" {
  description = "The project name with environment"
  type        = string
}
