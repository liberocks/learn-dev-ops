resource "digitalocean_kubernetes_cluster" "k8s_cluster" {
  name    = var.cluster_name
  region  = var.region
  version = var.k8s_version

  node_pool {
    name       = "worker-pool"
    size       = "s-4vcpu-8gb" # Need enough resources for LGTM stack
    node_count = var.node_count
  }
}
