/*
variable "codestar_connection_arn" {
  // arn:aws:codestar-connections:...:...:connection/.....
  type = string
}
*/
variable "codebuild_project_name" {
  type = string
}
variable "codepipeline_bucket_name" {
  type = string
}

variable "actions" {}

variable "env" {}

variable "codepipeline_name" {
  type = string
}
