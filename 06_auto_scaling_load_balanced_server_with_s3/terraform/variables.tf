variable "environment" {
  description = "Name of environment (debug/production)"
  type        = string
  default     = "debug"
  # default     = "production"
}
variable "owner" {
  description = "Project owner/runner"
  type        = string
  # Change this to your identifier
  default = "fbunt"
}

variable "min_size" {
  type    = number
  default = 1
}
variable "max_size" {
  type    = number
  default = 10
}
variable "desired_size" {
  type    = number
  default = 1
}

variable "docker_img_tar_file" {
  description = "docker image tar file"
  type        = string
  default     = "app-img.tar"
}
variable "docker_img_tag" {
  description = "Tag used for the docker image"
  type        = string
  default     = "my-site"
}
variable "ami_al2_ecs" {
  description = "Amazon Linux 2 with ECS. Latest as of 2022-02-11"
  type        = string
  default     = "ami-02b05e04df16de7a9"
}
