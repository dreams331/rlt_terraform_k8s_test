# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# These variables are expected to be passed in by the operator.
# ---------------------------------------------------------------------------------------------------------------------

variable "region" {
  default = "us-west1"
}

variable "location" {
  default = "us-west1-b"
}

variable "network_name" {
  default = "tf-gke-k8s"
}

provider "google" {
  region = var.region
}
#-----------------------------------------------------------------------------------------------------------------------------------
# SETTING MY DOCKER PROVIDER BLOCK AND AUTOMATING MY IMAGE BUILD
# i am automate the build of my docker image from the set part within my folder

provider "docker" {
  # Configuration options
}

resource "docker_image" "waltapp" {
  name = "waltapp"
  
  build {
    path = "../apllication/rlt-test"
    dockerfile = "waltapp.Dockerfile"
  }
}  
  

#--------------------------------------------------------------------------------------------------------------------------------------------------------------
# USING DEFAULT NETWORK SETTINGS
# I am using a default network settings due to time, but could also 
# provision custom VPC and Subnets
    
resource "google_compute_network" "default" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "default" {
  name                     = var.network_name
  ip_cidr_range            = "10.127.0.0/20"
  network                  = google_compute_network.default.self_link
  region                   = var.region
  private_ip_google_access = true
}

data "google_client_config" "current" {
}

data "google_container_engine_versions" "default" {
  location = var.location
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A GKE PUBLIC CLUSTER IN GOOGLE CLOUD PLATFORM
# i am deploying a google cloud cluster 
# ---------------------------------------------------------------------------------------------------------------------    
    
resource "google_container_cluster" "default" {
  name               = var.network_name
  location           = var.location
  initial_node_count = 3
  min_master_version = data.google_container_engine_versions.default.latest_master_version
  network            = google_compute_subnetwork.default.name
  subnetwork         = google_compute_subnetwork.default.name
  enable_legacy_abac = true
  provisioner "local-exec" {
    when    = destroy
    command = "sleep 90"
  }
}

output "network" {
  value = google_compute_subnetwork.default.network
}

output "subnetwork_name" {
  value = google_compute_subnetwork.default.name
}

output "cluster_name" {
  value = google_container_cluster.default.name
}

output "cluster_region" {
  value = var.region
}

output "cluster_location" {
  value = google_container_cluster.default.location
}
