variable "name" {}

variable "owner" {}

variable "repository" {}
variable "branch" {}

variable "image" {}

variable "build_timeout" {
  type        = "string"
  description = "How long in minutes, from 5 to 480 (8 hours), for AWS CodeBuild to wait until timing out any related build that does not get marked as completed. The default is 30 minutes."
  default     = "30"
}

variable "compute_type" {
  type        = "string"
  description = "Information about the compute resources the build project will use."
  default     = "BUILD_GENERAL1_SMALL"
}

variable "artifacts_store" {}

variable "environment_variables" {
  type = "list"
}

variable "notification_arn" {
  type    = "string"
  default = ""
}

variable "artifacts_bucket_arn" {}

variable "buildspec" {
  type        = "map"
  description = "The build spec declaration path to use for this build project's terraform builds."

  default = {
    plan  = ".buildspec/plan.yml"
    apply = ".buildspec/apply.yml"
  }
}
