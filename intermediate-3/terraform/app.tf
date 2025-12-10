resource "kubernetes_namespace" "app" {
  metadata {
    name = "app"
  }
}

# 1. Express App Code
resource "kubernetes_config_map" "express_app_code" {
  metadata {
    name      = "express-app-code"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  data = {
    "index.js"     = file("${path.module}/../express-app/index.js")
    "package.json" = file("${path.module}/../express-app/package.json")
  }
}

# 2. Express App Deployment
resource "kubernetes_deployment" "express_app" {
  metadata {
    name      = "express-app"
    namespace = kubernetes_namespace.app.metadata[0].name
    labels = {
      app = "express-app"
    }
  }

  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "express-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "express-app"
        }
      }

      spec {
        init_container {
          name    = "setup"
          image   = "node:18-alpine"
          command = ["sh", "-c", "cp /config/* /app/ && cd /app && npm install"]
          
          volume_mount {
            name       = "code"
            mount_path = "/config"
          }
          volume_mount {
            name       = "workdir"
            mount_path = "/app"
          }
        }

        container {
          name    = "app"
          image   = "node:18-alpine"
          command = ["node", "/app/index.js"]
          working_dir = "/app"

          port {
            container_port = 8080
          }

          volume_mount {
            name       = "workdir"
            mount_path = "/app"
          }
        }

        volume {
          name = "code"
          config_map {
            name = kubernetes_config_map.express_app_code.metadata[0].name
          }
        }

        volume {
          name = "workdir"
          empty_dir {}
        }
      }
    }
  }
}

# 3. Express App Service
resource "kubernetes_service" "express_service" {
  metadata {
    name      = "express-service"
    namespace = kubernetes_namespace.app.metadata[0].name
    labels = {
      app = "express-app"
    }
  }

  spec {
    selector = {
      app = "express-app"
    }
    port {
      name        = "http"
      port        = 8080
      target_port = 8080
    }
  }
}

# 4. ServiceMonitor for Prometheus
resource "kubernetes_manifest" "express_servicemonitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "express-monitor"
      namespace = kubernetes_namespace.monitoring.metadata[0].name
      labels = {
        release = "kube-prometheus-stack" # Important for Prometheus to pick it up
      }
    }
    spec = {
      selector = {
        matchLabels = {
          app = "express-app"
        }
      }
      namespaceSelector = {
        matchNames = ["app"]
      }
      endpoints = [
        {
          port = "http"
          path = "/metrics"
        }
      ]
    }
  }
  depends_on = [helm_release.kube_prometheus_stack]
}

# 5. Traffic Generator
resource "kubernetes_deployment" "traffic_generator" {
  metadata {
    name      = "traffic-generator"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "traffic-generator"
      }
    }

    template {
      metadata {
        labels = {
          app = "traffic-generator"
        }
      }

      spec {
        container {
          name    = "generator"
          image   = "curlimages/curl"
          command = ["/bin/sh", "-c", "while true; do curl -s http://express-service.app.svc.cluster.local:8080/checkout; sleep 1; done"]
        }
      }
    }
  }
}
