variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "name_prefix" {
  type    = string
  default = "asterra-demo"
}

variable "my_ip_cidr" {
  type    = string
  default = "0.0.0.0/0"
}
