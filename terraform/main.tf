provider "google" {
  credentials = file("ace-computer-406008-9d517441fd06.json")
  project     = "ace-computer-406008"
  region      = "us-central1"
}

locals {
  kubeconfig_content = google_container_cluster.ghost[0].master_auth[0].cluster_ca_certificate != null ? templatefile("${path.module}/kubeconfig_template.tpl", {
    cluster_ca_certificate = google_container_cluster.ghost[0].master_auth[0].cluster_ca_certificate
    endpoint               = google_container_cluster.ghost[0].endpoint
    name                   = google_container_cluster.ghost[0].name
  }) : ""
}

resource "google_container_cluster" "ghost" {
  count                = 1
  name                 = "ghost"
  location             = "us-central1"
  deletion_protection = false
  initial_node_count   = 1
  enable_autopilot     = true
  lifecycle {
    ignore_changes = [name]
  }
}

resource "google_compute_disk" "ghost_pv" {
  name  = "ghost-pv"
  size  = 10
  type  = "pd-standard"
  zone  = "us-central1-a"
}

provider "kubernetes" {
  kubectl_version = "1.27.0"
  load_config_file = false
  host             = google_container_cluster.ghost[0].endpoint
  token            = google_container_cluster.ghost[0].master_auth[0].token
  cluster_ca_certificate = base64decode(
    google_container_cluster.ghost[0].master_auth[0].cluster_ca_certificate
  )
}

data "google_client_config" "default" {}

# Get the list of YAML files in the manifests directory
data "kubectl_filename_list" "manifests" {
  pattern = "${path.module}/../yaml/*.yaml"
}

# Apply each YAML file to the cluster
resource "kubectl_manifest" "test" {
 
  count     = length(data.kubectl_filename_list.manifests.matches)
  yaml_body = file(element(data.kubectl_filename_list.manifests.matches, count.index))
}

output "kubeconfig" {
  value = local.kubeconfig_content
}

terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.0.0"
    }
  }
}
output "yaml_content" {
  value = data.kubectl_filename_list.manifests.matches
}

output "manifest_count" {
  value = length(data.kubectl_filename_list.manifests.matches)
}
