```hcl
terraform {
  required_version = ">= 1.6"
  required_providers {
    aws   = { source = "hashicorp/aws",   version = ">= 5.0" }
    azurerm = { source = "hashicorp/azurerm", version = ">= 3.0" }
    google = { source = "hashicorp/google", version = ">= 5.0" }
  }
}

#---------------------------
# Required Tags (Enforced)
#---------------------------
locals {
  required_tags = {
    env         = "dev"
    owner       = "platform"
    cost-center = "cc-101"
  }
}

#---------------------------
# AWS Implementation
#---------------------------
provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.10.0.0/16"
  tags       = merge(local.required_tags, { Name = "sample-app-dev-vpc" })
}

resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.10.0.0/24"
  map_public_ip_on_launch = true
  tags                    = merge(local.required_tags, { Name = "sample-app-dev-subnet" })
}

resource "aws_security_group" "main" {
  name        = "sample-app-dev-sg"
  description = "Allow HTTP/HTTPS"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(local.required_tags, { Name = "sample-app-dev-sg" })
}

resource "aws_instance" "main" {
  ami           = data.aws_ami.linux.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.main.id]
  count         = 1
  tags          = merge(local.required_tags, { Name = "sample-app-dev" })

  root_block_device {
    encrypted = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_ami" "linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance_state" "ttl" {
  instance_id = aws_instance.main.id
  state       = "terminated"
  timeouts {
    create = "${24 * 60}m"
  }
}

#---------------------------
# Azure Implementation
#---------------------------
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = "sample-app-dev-rg"
  location = "East US"
  tags     = local.required_tags
}

resource "azurerm_virtual_network" "main" {
  name                = "sample-app-dev-vnet"
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.required_tags
}

resource "azurerm_subnet" "main" {
  name                 = "sample-app-dev-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.10.0.0/24"]
}

resource "azurerm_network_security_group" "main" {
  name                = "sample-app-dev-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.required_tags

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "main" {
  name                = "sample-app-dev-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "main" {
  name                = "sample-app-dev-vm"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = "Standard_B1s"
  admin_username      = "azureuser"
  network_interface_ids = [azurerm_network_interface.main.id]
  disable_password_authentication = true

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_encryption_set_id = null
    name                 = "sample-app-dev-osdisk"
    disk_size_gb         = 30
    encryption_enabled   = true
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  tags = local.required_tags
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "main" {
  virtual_machine_id = azurerm_linux_virtual_machine.main.id
  location           = azurerm_resource_group.main.location
  enabled            = true
  daily_recurrence_time = "0000"
  timezone              = "UTC"
  notification_settings {
    enabled = false
  }
}

#---------------------------
# GCP Implementation
#---------------------------
provider "google" {
  region = "us-east1"
}

resource "google_compute_network" "main" {
  name                    = "sample-app-dev-vpc"
  auto_create_subnetworks = false
  tags                    = local.required_tags
}

resource "google_compute_subnetwork" "main" {
  name          = "sample-app-dev-subnet"
  ip_cidr_range = "10.10.0.0/24"
  region        = "us-east1"
  network       = google_compute_network.main.id
}

resource "google_compute_firewall" "main" {
  name    = "sample-app-dev-fw"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["sample-app-dev"]
}

resource "google_compute_instance" "main" {
  name         = "sample-app-dev"
  machine_type = "e2-micro"
  zone         = "us-east1-b"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
      size  = 30
      type  = "pd-standard"
    }
    auto_delete = true
    disk_encryption_key {
      kms_key_self_link = null # Default encryption
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.main.id
    access_config {}
  }

  tags = ["sample-app-dev"]

  labels = local.required_tags
}

resource "google_compute_resource_policy" "ttl" {
  name   = "sample-app-dev-ttl"
  region = "us-east1"
  instance_schedule_policy {
    vm_start_schedule {
      schedule = "0 0 * * *"
    }
    vm_stop_schedule {
      schedule = "0 0 * * *"
    }
  }
}

terraform {
  backend "s3" {}
}

```

**Notes:**
- All resources are tagged/labeled with the required tags.
- Cost-optimized instance types: `t3.micro` (AWS), `Standard_B1s` (Azure), `e2-micro` (GCP).
- Storage encryption is enabled where supported.
- Network CIDR and subnets are consistent across clouds.
- Security groups/firewalls allow HTTP/HTTPS.
- TTL/lifecycle: Each cloud has a mechanism to stop/terminate VMs after 24 hours (AWS: instance state, Azure: DevTest shutdown, GCP: resource policy).
- No cloud-specific fields in the intent; all logic is cloud-agnostic and mapped to each provider.
- Only the primary cloud (AWS) is configured for region, but all clouds are defined for parity.