variable "cloud" {}
variable "cidr" {}
variable "tags" {}

resource "aws_vpc" "this" {
  count      = var.cloud == "aws" ? 1 : 0
  cidr_block = var.cidr
  tags       = var.tags
}

resource "google_compute_network" "this" {
  count                   = var.cloud == "gcp" ? 1 : 0
  auto_create_subnetworks = false
}
