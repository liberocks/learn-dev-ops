resource "digitalocean_kubernetes_cluster" "k8s_cluster" {
  name    = "doks-gitops"
  region  = var.region
  version = "1.34.1-do.1" # Use 'doctl kubernetes options versions' to find latest

  node_pool {
    name       = "worker-pool"
    size       = "s-4vcpu-8gb" # Recommended for ArgoCD + Apps
    node_count = 2
  }
}