variable "region" {
  default = "europe-west8"
}

variable "zone" {
  default = "europe-west8-b"
}
variable "vpc_cidr" {
  default = "172.20.0.0/16"
}
# Adjusting subnet ranges to fit within the VPC range (172.20.0.0/16)
variable "public_subnet_cidr" {
  default = "172.20.1.0/24"
}

variable "private_subnet_cidr" {
  default = "172.20.2.0/24"
}
#instance type
variable "instance_type" {
  default = "e2-small"
}

variable "instance_type_spark" {
  default = "e2-standard-2"
}


variable "instance_image" {
  type = map(string)
  default = {
    centos = "centos-cloud/centos-stream-9"
    ubuntu = "ubuntu-os-cloud/ubuntu-2204-lts"
  }
}

variable "project_id" {
  type    = string
  default = "api-project-269968866265" # Replace with your GCP project ID
}

variable "temp_bucket_name" {
  type    = string
  default = "stream-bucket-263968866565" # Replace with your GCP bucket name
}

