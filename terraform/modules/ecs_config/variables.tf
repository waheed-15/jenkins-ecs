variable "ami_id" {
  type = string
  default = "ami-0e731c8a588258d0d"
}
variable "instance_type" {
  type = string
  default = "t3.micro"
}
variable "key_name" {
  type = string
  default = "waheed-test"
}
variable "ecs_cluster" {
  type = string
  default = "my-ecs-cluster"
}
variable "ecr_image_uri" {
  type = string
}
variable "CAPACITY_PROVIDER_EXISTS" {
  type = bool
}