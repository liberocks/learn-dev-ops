output "kubeconfig" {
  value     = digitalocean_kubernetes_cluster.k8s_cluster.kube_config[0].raw_config
  sensitive = true
}

output "grafana_password" {
  value = "admin"
  description = "Grafana admin password (set in observability.tf)"
}

output "grafana_port_forward_cmd" {
  value = "kubectl port-forward svc/kube-prometheus-stack-grafana -n monitoring 3000:80"
}
