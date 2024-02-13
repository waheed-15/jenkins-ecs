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
variable "ecr_image_uri" {
  type = string
}
variable "security_group" {
  type = string
}
