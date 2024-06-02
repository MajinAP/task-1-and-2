/*TASK1
  Create a publically accesible bucket in GCP with Terraform. You must complete the following tasks.
1) Terraform script
2) Git Push the script to your Github
3) Output file must show the public link
4) Must have an index.html file within*/

terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "5.25.0"

    }
  }
}
provider "google"{
    project = "banesrevenge"
}
#######################
#### Create Bucket ####
#######################
resource "google_storage_bucket" "rorschachsbucket" {
 name          = "mementomori"
 location      = "US"
 storage_class = "STANDARD"
 force_destroy = true
 uniform_bucket_level_access = false

website {
    main_page_suffix = "index.html"
    not_found_page = "404.html"
}
}
#### Create and put HTML object in referenced bucket ####
resource "google_storage_bucket_object" "default" {
 name         = "index.html"
 source       = "C:/Code/Terraform/GCP/ArmageddonHW/hakai/t1/index.html"
 content_type = "text/html"
 bucket       = google_storage_bucket.rorschachsbucket.id
}
#### Create and put PNG object in referenced bucket
resource "google_storage_bucket_object" "object1" {
 name         = "ror.png"
 source       = "C:/Code/Terraform/GCP/ArmageddonHW/hakai/t1/ror.png"
 content_type = "image/png"
 bucket       = google_storage_bucket.rorschachsbucket.id
}
#### Give public access to bucket
resource "google_storage_bucket_access_control" "public_read" {
  bucket = google_storage_bucket.rorschachsbucket.name
  role   = "READER"
  entity = "allUsers"
}
#### Give public access to HTML
resource "google_storage_object_access_control" "public_html" {
  object = google_storage_bucket_object.default.output_name
  bucket = google_storage_bucket.rorschachsbucket.name
  role   = "READER"
  entity = "allUsers"
}
#### Give public access to IMAGE (PNG)
resource "google_storage_object_access_control" "public_image" {
  object = google_storage_bucket_object.object1.output_name
  bucket = google_storage_bucket.rorschachsbucket.name
  role   = "READER"
  entity = "allusers"
}

#####################################
#### Output file with public link ###
#####################################
output "URL_HERE--" {
  value = "https://storage.googleapis.com/${google_storage_bucket.rorschachsbucket.name}/index.html"
}



#################################################################################
#################################################################################
#################################################################################
#################################################################################



/*TASK 2
  Create a publically accessible web page with Terraform.  You must complete the following
 1) Terraform Script with a VPC
 2) Terraform script must have a VM within your VPC.
 3) The VM must have the homepage on it.
 4) The VM must have an publically accessible link to it.
 5) You must Git Push your script to your Github.
 6) Output file must show 1) Public IP, 2) VPC, 3) Subnet of the VM, 4) Internal IP of the VM.
 7) Public IP 35.213.27.66*/

terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "5.25.0"
    }
  }
}
provider "google"{
    project = "banesrevenge"
}

#############################
## VPC Network and Subnets ##
#############################

resource "google_compute_network" "task2-vpc" {
name = "task2-vpc"
}

resource "google_compute_subnetwork" "subnet1" {
name = "task2-subnet"
ip_cidr_range = "10.123.1.0/24"
region = "asia-northeast1"
network = google_compute_network.task2-vpc.id
}
########################
#### Firewall Rules ####
########################
resource "google_compute_firewall" "allow_http" {
  name        = "http"
  description = "Allow HTTP traffic"
  network     = google_compute_network.task2-vpc.id
  direction   = "INGRESS"
  priority    = 1000

  allow {
    protocol = "tcp" 
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = ["http-server"]
}

resource "google_compute_firewall" "allow_ssh" {
  name        = "ssh"
  description = "Allow SSH traffic"
  network     = google_compute_network.task2-vpc.id
  direction   = "INGRESS"
  priority    = 1000

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = ["ssh-server"]
}

resource "google_compute_firewall" "allow_egress" {
  name        = "egressing"
  description = "Allow ALL egress traffic"
  network     = google_compute_network.task2-vpc.id
  direction   = "EGRESS"
  priority    = 1000

  allow {
    protocol = "all"
  }

  destination_ranges = ["0.0.0.0/0"]

  target_tags = ["egress"]
}

###############
### Instance ##
###############

resource "google_compute_instance" "instance-task2" {
  boot_disk {
    auto_delete = true
    device_name = "instance-task2"

    initialize_params {
      image = "projects/debian-cloud/global/images/debian-12-bookworm-v20240515"
      size  = 10
      type  = "pd-balanced"
    }

    mode = "READ_WRITE"
  }

  can_ip_forward      = false
  deletion_protection = false
  enable_display      = false

  labels = {
    goog-ec-src = "vm_add-tf"
  }

  machine_type = "e2-medium"
####SCIPT####
  metadata = {
    startup-script = "#Thanks to Remo\n#!/bin/bash\n# Update and install Apache2\napt update\napt install -y apache2\n\n# Start and enable Apache2\nsystemctl start apache2\nsystemctl enable apache2\n\n# GCP Metadata server base URL and header\nMETADATA_URL=\"http://metadata.google.internal/computeMetadata/v1\"\nMETADATA_FLAVOR_HEADER=\"Metadata-Flavor: Google\"\n\n# Use curl to fetch instance metadata\nlocal_ipv4=$(curl -H \"$${METADATA_FLAVOR_HEADER}\" -s \"$${METADATA_URL}/instance/network-interfaces/0/ip\")\nzone=$(curl -H \"$${METADATA_FLAVOR_HEADER}\" -s \"$${METADATA_URL}/instance/zone\")\nproject_id=$(curl -H \"$${METADATA_FLAVOR_HEADER}\" -s \"$${METADATA_URL}/project/project-id\")\nnetwork_tags=$(curl -H \"$${METADATA_FLAVOR_HEADER}\" -s \"$${METADATA_URL}/instance/tags\")\n\n# Create a simple HTML page and include instance details\ncat <<EOF > /var/www/html/index.html\n<html><body>\n<h2>Never Compromise, Not Even In The Face Of Armageddon - T2</h2>\n<h3>Created with a direct input startup script!</h3>\n<p><b>Instance Name:</b> $(hostname -f)</p>\n<p><b>Instance Private IP Address: </b> $local_ipv4</p>\n<p><b>Zone: </b> $zone</p>\n<p><b>Project ID:</b> $project_id</p>\n<p><b>Network Tags:</b> $network_tags</p>\n</body></html>\nEOF"
  }

  name = "instance-task2"

  network_interface {
    access_config {
      network_tier = "PREMIUM"
    }

    queue_count = 0
    stack_type  = "IPV4_ONLY"
    subnetwork  = google_compute_subnetwork.subnet1.id
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = false
    provisioning_model  = "STANDARD"
  }

  service_account {
    email  = "610336172779-compute@developer.gserviceaccount.com"
    scopes = ["https://www.googleapis.com/auth/devstorage.read_only", "https://www.googleapis.com/auth/logging.write", "https://www.googleapis.com/auth/monitoring.write", "https://www.googleapis.com/auth/service.management.readonly", "https://www.googleapis.com/auth/servicecontrol", "https://www.googleapis.com/auth/trace.append"]
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = false
    enable_vtpm                 = true
  }

  tags = ["http-server"]
  zone = "asia-northeast1-b"
}

#############################################################################################
# OUPUT file must show 1) Public IP, 2) VPC, 3) Subnet of the VM, 4) Internal IP of the VM  #
#############################################################################################
output "public_ip" {
  value = {
  "TASK 2 LEAGUE OF SHADOWS" = "http://${google_compute_instance.instance-task2.network_interface[0].access_config[0].nat_ip}"
}
}
output "VPC" {
    value = google_compute_network.task2-vpc.id
}

output "subnet_of_VM" {
    value = google_compute_subnetwork.subnet1.region
}

output "internal_ip_vm" {
  description = "The internal IP of the VM instance"
  value       = google_compute_instance.instance-task2.network_interface[0].network_ip
}




