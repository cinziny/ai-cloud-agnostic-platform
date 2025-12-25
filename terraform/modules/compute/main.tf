variable "cloud" {}
variable "size" {}
variable "tags" {}

resource "aws_instance" "vm" {
  count         = var.cloud == "aws" ? 1 : 0
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t3.micro"
  tags          = var.tags
}

resource "google_compute_instance" "vm" {
  count        = var.cloud == "gcp" ? 1 : 0
  name         = "vm"
  machine_type = "e2-micro"
  zone         = "us-central1-a"
  labels       = var.tags
}
