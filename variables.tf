variable "region" {
  description = "AWS region"
  default     = "us-west-2"
}

# Consul cluster
variable "consult_ami_id" {
  default = "ami-0ac73f33a1888c64a"
}

variable "consul_cluster_min_size" {
  default = 3
}

variable "consul_cluster_max_size" {
  default = 5
}

variable "consul_desired_capacity" {
  default = 3
}

variable "consul_instance_type" {
  default = "t2.micro"
}

variable "consul_cluster_name" {
  type    = string
  default = "cunsul-example-dev"
}


# Vault cluster
variable "vault_ami_id" {
  default = "ami-0ac73f33a1888c64a"
}

variable "vault_cluster_name" {
  default = "vault_example-dev"
}

variable "vault_cluster_min_size" {
  default = 1
}

variable "vault_cluster_max_size" {
  default = 2
}

variable "vault_instance_type" {
  default = "t2.micro"
}

variable "vault_desired_capacity" {
  default = 1
}
