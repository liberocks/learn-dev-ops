resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

# 1. Prometheus & Grafana (Metrics & Visualization)
resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  set {
    name  = "grafana.adminPassword"
    value = "admin" # Change in production!
  }
  
  # Enable ServiceMonitor discovery
  set {
    name  = "prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues"
    value = "false"
  }
}

# 2. Loki & Promtail (Logs)
resource "helm_release" "loki_stack" {
  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  set {
    name  = "promtail.enabled"
    value = "true"
  }
  
  # Configure Loki to work with Grafana
  set {
    name  = "grafana.enabled"
    value = "false" # We use the Grafana from kube-prometheus-stack
  }
}

# 3. Tempo (Traces)
resource "helm_release" "tempo" {
  name       = "tempo"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "tempo"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
}

# Configure Grafana Data Sources for Loki and Tempo
# We need to add this to the kube-prometheus-stack values or via a separate ConfigMap/Secret
# that the Grafana sidecar picks up.
resource "kubernetes_config_map" "grafana_datasources" {
  metadata {
    name      = "grafana-datasource-lgtm"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels = {
      grafana_datasource = "1"
    }
  }

  data = {
    "loki-datasource.yaml" = <<EOF
apiVersion: 1
datasources:
  - name: Loki
    type: loki
    url: http://loki:3100
    access: proxy
    isDefault: false
EOF
    "tempo-datasource.yaml" = <<EOF
apiVersion: 1
datasources:
  - name: Tempo
    type: tempo
    url: http://tempo:3100
    access: proxy
    isDefault: false
EOF
  }
  
  depends_on = [helm_release.kube_prometheus_stack]
}
