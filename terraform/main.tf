provider "google" {
  credentials = file("ace-computer-406008-9d517441fd06.json")
  project     = "ace-computer-406008"
  region      = "us-central1"
}


provider "kubernetes" {
  load_config_file       = false
  host                   = google_container_cluster.k8s_cluster.endpoint
  cluster_ca_certificate = base64decode(google_container_cluster.k8s_cluster.master_auth[0].cluster_ca_certificate)
  token                  = google_container_cluster.k8s_cluster.master_auth[0].token
}


resource "google_container_cluster" "k8s_cluster" {
  count    = var.create_cluster ? 1 : 0
  name     = "ghost"
  location = "us-central1"

  node_pool {
    name   = "default-pool"
    initial_node_count = 1
  }
}

resource "google_compute_disk" "ghost_pv" {
  name  = "ghost-pv"
  size  = 10
  type  = "pd-standard"
  zone  = "us-central1-a"
}

resource "null_resource" "clone_repo" {
  provisioner "local-exec" {
    command = "git clone https://github.com/mahdiswaidan/Ghost ."
  }
}

resource "null_resource" "apply_manifests" {
  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/./*.yaml"
  }

  depends_on = [null_resource.clone_repo, google_compute_disk.ghost_pv]
}

