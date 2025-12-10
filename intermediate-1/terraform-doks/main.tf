terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_kubernetes_cluster" "k8s_cluster" {
  name    = "doks-intermediate"
  region  = var.region
  version = "1.34.1-do.1" # Use 'doctl kubernetes options versions' to find latest

  node_pool {
    name       = "worker-pool"
    size       = "s-2vcpu-4gb" # Minimum recommended for ArgoCD + Monitoring
    node_count = 3
  }
}

# Output the kubeconfig
output "kubeconfig" {
  value     = digitalocean_kubernetes_cluster.k8s_cluster.kube_config[0].raw_config
  sensitive = true
}