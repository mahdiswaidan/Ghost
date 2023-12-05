provider "kubernetes" {
  config_path = "~/.kube/config"  # Update this to the path of your kubeconfig file
}

data "kubectl_filename_list" "manifests" {
  pattern = "${path.module}/yaml/*.yaml"
}

resource "kubectl_manifest" "deployments" {
  count     = length(data.kubectl_filename_list.manifests.matches)
  yaml_body = file(element(data.kubectl_filename_list.manifests.matches, count.index))
}
terraform {
  required_providers {
    kubectl = {
      source  = "hashicorp/kubectl"
      version = "2.1.0"  # Replace with the version you want
    }
  }
}
