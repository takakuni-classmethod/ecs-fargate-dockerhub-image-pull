variable "prefix" {
  type = string
  default = "fargate-dockerhub"
}
variable "dockerhub_username" {
  type = string
  default = "dummy_user"
  sensitive = true
}

variable "dockerhub_password" {
  type = string
  default = "dummy_password"
  sensitive = true
}