# Intermediate Kubernetes on DigitalOcean: Production-Ready Infrastructure

This guide builds upon the [Basic Kubernetes Curriculum](./basic.md) to take your skills from "running containers" to "managing production infrastructure". We will focus on Infrastructure as Code (IaC), GitOps, Advanced Observability, and Security.

---

## 📑 Table of Contents

### **Part 1: Infrastructure as Code (IaC)**
- [Introduction to Terraform](#introduction-to-terraform)
- [Setting up DigitalOcean Provider](#setting-up-digitalocean-provider)
- [Provisioning DOKS with Terraform](#provisioning-doks-with-terraform)
- [Managing State & Modules](#managing-state--modules)

### **Part 2: GitOps with ArgoCD**
- [GitOps Principles](#gitops-principles)
- [Installing ArgoCD](#installing-argocd)
- [Deploying Applications via Git](#deploying-applications-via-git)
- [Sync Strategies & Self-Healing](#sync-strategies--self-healing)
- [Managing Secrets in GitOps](#managing-secrets-in-gitops)

### **Part 3: Advanced Observability (Grafana Stack)**
- [The LGTM Stack (Loki, Grafana, Tempo, Mimir)](#the-lgtm-stack)
- [Prometheus Deep Dive](#prometheus-deep-dive)
- [Grafana Dashboards as Code](#grafana-dashboards-as-code)
- [Log Aggregation with Loki](#log-aggregation-with-loki)
- [Alerting & Notification Channels](#alerting--notification-channels)
- [Hands-on Practice: Observability with Datadog (via Terraform)](#hands-on-practice-observability-with-datadog-via-terraform)

### **Part 4: Advanced Networking & Service Mesh**
- [Advanced Ingress with Traefik](#advanced-ingress-with-traefik)
- [Introduction to Service Mesh](#introduction-to-service-mesh)
- [Istio Basics](#istio-basics)
- [Traffic Management (Canary/Blue-Green)](#traffic-management)
- [mTLS & Security](#mtls--security)

### Part 5: Security & Policy
- [Policy as Code (OPA/Kyverno)](#policy-as-code)
- [Network Policies Deep Dive](#network-policies-deep-dive)
- [Runtime Security](#runtime-security)
- [Advanced Secret Management (External Secrets Operator)](#advanced-secret-management-external-secrets-operator)

### **Part 6: Advanced Helm**
- [Chart Development](#chart-development)
- [Helmfile for Multi-Chart Management](#helmfile-for-multi-chart-management)

### **Part 7: Kustomize (Native Configuration Management)**
- [Core Concepts: Base & Overlays](#core-concepts-base--overlays)
- [The kustomization.yaml File](#the-kustomizationyaml-file)
- [Common Transformers](#common-transformers)
- [ConfigMap & Secret Generators](#configmap--secret-generators)
- [Kustomize vs. Helm](#kustomize-vs-helm)

### **Part 8: Production-Ready Stateful Workloads (PostgreSQL)**
- [Running Databases on Kubernetes](#running-databases-on-kubernetes)
- [CloudNativePG Operator](#cloudnativepg-operator)
- [High Availability (Replicas)](#high-availability-replicas)
- [Backups & PITR](#backups--pitr)
- [Connection Pooling (PgBouncer)](#connection-pooling-pgbouncer)

### **Part 9: Multi-Region & Multi-Cluster Strategy**
- [Why Multi-Region?](#why-multi-region)
- [Architecture Patterns](#architecture-patterns)
- [Global Load Balancing (GSLB)](#global-load-balancing-gslb)
- [Multi-Cluster Connectivity (Cilium Mesh)](#multi-cluster-connectivity-cilium-mesh)
- [GitOps for Multi-Cluster (ArgoCD ApplicationSets)](#gitops-for-multi-cluster-argocd-applicationsets)

### **Capstone Project**
- [End-to-End Production Platform](#capstone-project-end-to-end-production-platform)

### **Cleanup & Cost Management**
- [Destroying Infrastructure](#destroying-infrastructure)

---

## Prerequisites

Before starting this intermediate course, you should be comfortable with:
- Basic Kubernetes resources (Pods, Deployments, Services, PVCs)
- `kubectl` command line usage
- Basic Docker concepts
- Have a DigitalOcean account and API token ready

> **Note**: This course involves creating real cloud resources. Be mindful of costs. We will use Terraform to easily spin up and tear down environments to save money.

---

## Part 1: Infrastructure as Code (IaC)

Infrastructure as Code (IaC) allows you to manage and provision your infrastructure through code instead of manual processes. We will use **Terraform**, the industry standard for cloud-agnostic IaC.

### Introduction to Terraform

Terraform uses a declarative language (HCL - HashiCorp Configuration Language) to define the "desired state" of your infrastructure.
- **Provider**: Plugin that interacts with cloud APIs (e.g., DigitalOcean, AWS).
- **Resource**: A specific piece of infrastructure (e.g., a Kubernetes cluster, a Droplet).
- **State**: Terraform keeps track of what it has created in a `terraform.tfstate` file.

**Prerequisites:**
```bash
# macOS
brew install terraform

# Linux (Ubuntu/Debian)
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Verify installation
terraform version
```

### Setting up DigitalOcean Provider

Create a new directory for your infrastructure code:
```bash
mkdir terraform-doks
cd terraform-doks
```

Create a file named `main.tf`. This is where we define our provider and resources.

```hcl
# main.tf
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
```

We need to define the `do_token` variable. Create `variables.tf`:

```hcl
# variables.tf
variable "do_token" {
  description = "DigitalOcean API Token"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "DigitalOcean region"
  type        = string
  default     = "nyc1"
}
```

**Security Tip**: Never commit your API token to Git! We will pass it via environment variables or a `terraform.tfvars` file that is git-ignored.

Create a `terraform.tfvars` file (and add it to `.gitignore`):
```hcl
# terraform.tfvars
do_token = "dop_v1_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

### Provisioning DOKS with Terraform

Now, let's define the Kubernetes cluster resource in `main.tf`. Append this to the file:

```hcl
# ... existing provider config ...

resource "digitalocean_kubernetes_cluster" "k8s_cluster" {
  name    = "doks-intermediate"
  region  = var.region
  version = "1.28.2-do.0" # Use 'doctl kubernetes options versions' to find latest

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
```

### Managing State & Modules

**Initialize and Apply:**

1.  **Initialize**: Downloads the provider plugins.
    ```bash
    terraform init
    ```

2.  **Plan**: Shows what Terraform will do. Always review this!
    ```bash
    terraform plan
    ```

3.  **Apply**: Creates the resources.
    ```bash
    terraform apply
    # Type 'yes' to confirm
    ```

**Accessing the Cluster:**

Once finished, Terraform has the kubeconfig in its state. You can save it to a file:

```bash
terraform output -raw kubeconfig > kubeconfig.yaml
export KUBECONFIG=$(pwd)/kubeconfig.yaml

# Verify access
kubectl get nodes
```

**🏭 Industry Best Practice - State Management:**
- **Local State**: The `terraform.tfstate` file is stored on your machine. Good for learning/solo.
- **Remote State**: In production, store state in a remote backend (S3, Terraform Cloud) to allow team collaboration and locking.
- **Locking**: Prevents two people from running `apply` at the same time.

---

## Part 2: GitOps with ArgoCD

GitOps is a set of practices to manage infrastructure and application configurations using Git. Git becomes the "single source of truth" for your declarative infrastructure and applications.

### GitOps Principles
1.  **Declarative**: The entire system is described declaratively (YAML).
2.  **Versioned**: The desired state is stored in Git.
3.  **Automated**: Changes to Git are automatically applied to the system.
4.  **Self-Healing**: The system ensures the actual state matches the desired state.

### Installing ArgoCD

We will install ArgoCD into our cluster.

```bash
# Create namespace
kubectl create namespace argocd

# Install ArgoCD (stable version)
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

**Accessing the UI:**

By default, the ArgoCD API server is not exposed with an external IP. We can use port-forwarding to access it.

```bash
# Port forward to localhost:8080
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Open `https://localhost:8080` in your browser. Accept the self-signed certificate warning.

**Login Credentials:**
-   **Username**: `admin`
-   **Password**: The initial password is the name of the ArgoCD server pod.
    ```bash
    kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
    ```

### Deploying Applications via Git

We will deploy a sample "Guestbook" application from a public Git repository.

**Declarative Setup (The GitOps Way):**

Create a file named `application.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: guestbook
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/argoproj/argocd-example-apps.git
    targetRevision: HEAD
    path: guestbook
  destination:
    server: https://kubernetes.default.svc
    namespace: guestbook
  syncPolicy:
    automated:
      prune: true      # Delete resources that are no longer in Git
      selfHeal: true   # Fix resources that drift from Git state
    syncOptions:
    - CreateNamespace=true
```

Apply this manifest:
```bash
kubectl apply -f application.yaml
```

Check the ArgoCD UI. You should see the "guestbook" application syncing and turning green (Healthy).

### Sync Strategies & Self-Healing

In the `syncPolicy` above, we enabled:
-   **Automated Sync**: ArgoCD watches Git and applies changes automatically (usually polls every 3 mins).
-   **Prune**: If you remove a file from Git, ArgoCD deletes the resource from the cluster.
-   **Self-Healing**: If you manually delete a deployment (`kubectl delete deploy ...`), ArgoCD detects the drift and immediately recreates it to match Git.

**Exercise:**
1.  Manually scale the guestbook deployment: `kubectl scale deploy guestbook-ui --replicas=5 -n guestbook`
2.  Watch ArgoCD immediately revert it back to the number defined in Git (1 replica).
3.  This proves Git is the source of truth!

### Managing Secrets in GitOps

**Problem**: You cannot store raw secrets (passwords, API keys) in public Git repositories.
**Solution**: **Sealed Secrets** by Bitnami.

1.  **Install Sealed Secrets Controller**:
    ```bash
    helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
    helm install sealed-secrets -n kube-system --create-namespace sealed-secrets/sealed-secrets
    ```

2.  **Install kubeseal CLI**:
    ```bash
    # macOS
    brew install kubeseal

    # Linux
    # Fetch latest version tag
    KUBESEAL_VERSION=$(curl -s https://api.github.com/repos/bitnami-labs/sealed-secrets/releases/latest | grep tag_name | cut -d '"' -f 4 | cut -c 2-)
    wget "https://github.com/bitnami-labs/sealed-secrets/releases/download/v${KUBESEAL_VERSION}/kubeseal-${KUBESEAL_VERSION}-linux-amd64.tar.gz"
    tar -xvzf kubeseal-${KUBESEAL_VERSION}-linux-amd64.tar.gz kubeseal
    sudo install -m 755 kubeseal /usr/local/bin/kubeseal
    ```

3.  **Workflow**:
    -   Create a regular Secret locally (do not commit!).
    -   Encrypt it with `kubeseal`.
    -   Commit the `SealedSecret` CRD to Git.
    -   Controller decrypts it inside the cluster.

```bash
# Create secret locally (dry-run)
kubectl create secret generic db-pass --from-literal=password=supersecret --dry-run=client -o yaml > secret.yaml

# Seal it
kubeseal < secret.yaml > sealed-secret.yaml

# Apply (or commit to Git for ArgoCD to pick up)
kubectl apply -f sealed-secret.yaml
```

---

## Part 3: Advanced Observability (Grafana Stack)

Observability goes beyond simple monitoring ("is it up?") to understanding "why is it broken?". We will use the **LGTM** stack: **L**oki (logs), **G**rafana (visualization), **T**empo (traces), and **M**imir (metrics - often replaced by Prometheus for smaller setups).

### The LGTM Stack

-   **Prometheus**: Collects metrics (CPU, Memory, Request Rate).
-   **Grafana**: Visualizes data from Prometheus, Loki, etc.
-   **Loki**: Aggregates logs (like Splunk/ELK but cheaper).
-   **Promtail**: Agent that ships logs from nodes to Loki.

### Installing kube-prometheus-stack

The community standard is the `kube-prometheus-stack` Helm chart, which includes Prometheus, Grafana, AlertManager, and node-exporters.

```bash
# Add repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Create namespace
kubectl create namespace monitoring

# Install
helm install monitoring prometheus-community/kube-prometheus-stack -n monitoring
```

**Accessing Grafana:**

```bash
# Get admin password
kubectl get secret --namespace monitoring monitoring-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

# Port forward
kubectl port-forward svc/monitoring-grafana 3000:80 -n monitoring
```
Visit `http://localhost:3000` (User: `admin`, Password: from command above).

### Prometheus Deep Dive

**ServiceMonitors:**
How does Prometheus know what to scrape? In Kubernetes, we use the `ServiceMonitor` CRD. It tells Prometheus: "Look for Services with label X, and scrape port Y".

Example `ServiceMonitor` for a NodeJS app:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: myapp-monitor
  namespace: monitoring
  labels:
    release: monitoring # Must match the Prometheus release label
spec:
  selector:
    matchLabels:
      app: myapp # Target Service label
  endpoints:
  - port: http
    path: /metrics
```

### Log Aggregation with Loki

To add logging, we need to install Loki and Promtail.

```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install Loki Stack (Loki + Promtail)
helm install loki grafana/loki-stack \
    --namespace monitoring \
    --set grafana.enabled=false \
    --set prometheus.enabled=false \
    --set promtail.enabled=true
```

**Visualizing Logs in Grafana:**
1.  Go to Grafana > Configuration > Data Sources.
2.  Add Data Source > Loki.
3.  URL: `http://loki.monitoring.svc:3100`.
4.  Save & Test.
5.  Go to "Explore" tab, select "Loki", and query `{namespace="default"}` to see logs from the default namespace.

### Alerting & Notification Channels

AlertManager handles alerts sent by Prometheus.

**Configuring Alerts (PrometheusRule):**

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: high-cpu-alert
  namespace: monitoring
  labels:
    release: monitoring
spec:
  groups:
  - name: node.rules
    rules:
    - alert: HighNodeCPU
      expr: instance:node_cpu:rate:sum > 0.8
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High CPU usage on {{ $labels.instance }}"
```

This rule triggers if CPU usage is > 80% for 5 minutes.

### Hands-on Practice: Observability with Datadog (via Terraform)

In this real-world scenario, we will use Terraform to:
1.  Provision the Datadog Agent.
2.  Deploy a custom "Metric Generator" service that emits business metrics (checkout latency).
3.  Create advanced monitors (Anomaly Detection & Composite Alerts) to watch those metrics.

**Prerequisites:**
1.  Datadog Account (API Key & App Key).
2.  Terraform installed.

**1. Setup Providers**
We need `datadog` (for monitors), `helm` (for the agent), and `kubernetes` (for the app).

```hcl
terraform {
  required_providers {
    datadog = { source = "DataDog/datadog" }
    helm    = { source = "hashicorp/helm" }
    kubernetes = { source = "hashicorp/kubernetes" }
  }
}

provider "datadog" {
  api_key = var.datadog_api_key
  app_key = var.datadog_app_key
}

provider "helm" {
  kubernetes { config_path = "~/.kube/config" }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}
```

**2. Install Datadog Agent**
Deploy the agent to all nodes to collect metrics and logs.

```hcl
resource "helm_release" "datadog_agent" {
  name       = "datadog"
  repository = "https://helm.datadoghq.com"
  chart      = "datadog"
  namespace  = "datadog"
  create_namespace = true

  set_sensitive {
    name  = "datadog.apiKey"
    value = var.datadog_api_key
  }
  # Enable DogStatsD for custom metrics
  set {
    name  = "datadog.dogstatsd.useHostPort"
    value = "true"
  }
}
```

**3. Deploy Express App & Traffic Generator**
We will deploy a simple Express.js app that emits a custom metric `custom.checkout.latency` via DogStatsD. We also deploy a traffic generator to hit the endpoint.

*Note: The source code for these apps is in the `intermediate-3/` folder.*

```hcl
# 1. Express App Code (Mounted via ConfigMap for simplicity)
resource "kubernetes_config_map" "express_code" {
  metadata { name = "express-code" }
  data = {
    "index.js" = file("${path.module}/../intermediate-3/express-app/index.js")
    "package.json" = file("${path.module}/../intermediate-3/express-app/package.json")
  }
}

# 2. Express App Deployment
resource "kubernetes_deployment" "express_app" {
  metadata { name = "express-app" }
  spec {
    replicas = 1
    selector { match_labels = { app = "express-app" } }
    template {
      metadata { labels = { app = "express-app" } }
      spec {
        container {
          image = "node:18-alpine"
          name  = "express"
          command = ["/bin/sh", "-c"]
          # Install deps and run
          args = ["cd /app && npm install && node index.js"]
          
          # Inject Node IP to reach the Datadog Agent
          env {
            name = "DD_AGENT_HOST"
            value_from {
              field_ref { field_path = "status.hostIP" }
            }
          }
          volume_mount {
            name       = "code-vol"
            mount_path = "/app"
          }
        }
        volume {
          name = "code-vol"
          config_map { name = "express-code" }
        }
      }
    }
  }
}

# 3. Service for Express App
resource "kubernetes_service" "express_service" {
  metadata { name = "express-service" }
  spec {
    selector = { app = "express-app" }
    port {
      port        = 8080
      target_port = 8080
    }
  }
}

# 4. Traffic Generator
resource "kubernetes_deployment" "traffic_generator" {
  metadata { name = "traffic-generator" }
  spec {
    replicas = 1
    selector { match_labels = { app = "traffic-generator" } }
    template {
      metadata { labels = { app = "traffic-generator" } }
      spec {
        container {
          image = "curlimages/curl"
          name  = "traffic"
          command = ["/bin/sh", "-c"]
          args = ["while true; do curl -s http://express-service:8080/checkout; echo ''; sleep 1; done"]
        }
      }
    }
  }
}
```

**4. Create Advanced Monitors**
Now that data is flowing, let's create monitors that are impossible to manage manually at scale.

**Monitor A: Anomaly Detection**
Alert if latency behaves differently than usual (e.g., sudden spike compared to last week).

```hcl
resource "datadog_monitor" "latency_anomaly" {
  name    = "[Anomaly] Checkout Latency Deviation"
  type    = "query alert"
  message = "Latency is abnormal! @slack-channel"
  
  # Query: Average latency over last 1h, using 'basic' algorithm, 2 deviations
  query = "avg(last_1h):anomalies(avg:custom.checkout.latency{service:checkout-api}, 'basic', 2) > 1"

  monitor_thresholds {
    critical = 1.0
  }
}
```

**Monitor B: Composite Monitor**
Reduce noise by alerting ONLY if Latency is high AND CPU is high.

```hcl
# 1. High Latency Monitor (Hidden)
resource "datadog_monitor" "latency_high" {
  name    = "High Latency"
  type    = "metric alert"
  query   = "avg(last_5m):avg:custom.checkout.latency{service:checkout-api} > 400"
  message = "Latency > 400ms"
}

# 2. High CPU Monitor (Hidden)
resource "datadog_monitor" "cpu_high" {
  name    = "High CPU"
  type    = "metric alert"
  query   = "avg(last_5m):avg:system.cpu.idle{*} by {host} < 10"
  message = "CPU Idle < 10%"
}

# 3. Composite Monitor (The real alert)
resource "datadog_monitor" "composite_alert" {
  name    = "[Critical] High Latency AND High CPU"
  type    = "composite"
  message = "System is overloaded and slow! @pagerduty"
  
  # Logic: Trigger if BOTH monitors are in Alert state
  query   = "${datadog_monitor.latency_high.id} && ${datadog_monitor.cpu_high.id}"
}
```

**5. Apply & Verify**
```bash
export TF_VAR_datadog_api_key="your-key"
export TF_VAR_datadog_app_key="your-app-key"
terraform apply
```
Go to Datadog > Metrics > Explorer and search for `custom.checkout.latency` to see your data!

---

## Part 4: Advanced Networking & Service Mesh

We will explore advanced networking concepts, starting with modern Ingress Controllers and moving to Service Meshes.

### Advanced Ingress with Traefik

**Traefik** is a modern HTTP reverse proxy and load balancer that makes deploying microservices easy. It supports dynamic configuration and integrates natively with Kubernetes.

**Core Concepts:**
-   **EntryPoints**: The network entry points into Traefik (e.g., port 80 for HTTP, 443 for HTTPS).
-   **Routers**: Analyze the incoming requests (Host, Path, Headers) and connect them to the appropriate services.
-   **Middlewares**: Chainable components that tweak the requests before they reach the service (e.g., Auth, Rate Limiting, Compress).
-   **Services**: The actual backend services (Kubernetes Services) that process the requests.
-   **Providers**: The source of configuration (e.g., Kubernetes CRDs, Docker, File).

**Installation via Helm:**

```bash
helm repo add traefik https://traefik.github.io/charts
helm repo update
helm install traefik traefik/traefik -n traefik --create-namespace
```

**Exposing the Dashboard:**
Traefik comes with a dashboard. You can expose it securely, but for learning, we can port-forward:

```bash
kubectl port-forward $(kubectl get pods --selector "app.kubernetes.io/name=traefik" --output=jsonpath={.items..metadata.name} -n traefik) -n traefik 9000:9000
```
Visit `http://localhost:9000/dashboard/`.

**Using IngressRoute:**
Instead of the standard `Ingress`, Traefik uses `IngressRoute` CRD for more advanced configuration.

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: myapp-route
  namespace: default
spec:
  entryPoints:
    - web
  routes:
  - match: Host(`myapp.example.com`)
    kind: Rule
    services:
    - name: myapp
      port: 80
```

### Production Use Cases

#### 1. Automatic SSL/TLS with Let's Encrypt
Traefik can automatically generate and renew certificates.

First, configure the `CertResolver` in your Helm values or static config (usually done at install time):
```yaml
# values.yaml for Helm chart
additionalArguments:
  - "--certificatesresolvers.myresolver.acme.email=your-email@example.com"
  - "--certificatesresolvers.myresolver.acme.storage=/data/acme.json"
  - "--certificatesresolvers.myresolver.acme.httpchallenge.entrypoint=web"
```

Then, reference it in your `IngressRoute`:
```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: myapp-secure
spec:
  entryPoints:
    - websecure # Port 443
  routes:
  - match: Host(`secure.example.com`)
    kind: Rule
    services:
    - name: myapp
      port: 80
  tls:
    certResolver: myresolver
```

#### 2. Path-Based Routing (API Gateway Pattern)
Route traffic to different microservices based on the URL path.

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: api-gateway
spec:
  entryPoints:
    - web
  routes:
  - match: Host(`api.example.com`) && PathPrefix(`/users`)
    kind: Rule
    services:
    - name: user-service
      port: 8080
  - match: Host(`api.example.com`) && PathPrefix(`/orders`)
    kind: Rule
    services:
    - name: order-service
      port: 8080
```

#### 3. Rate Limiting (DDoS Protection)
Protect your API from abuse by limiting the number of requests.

1.  **Define the Middleware**:
    ```yaml
    apiVersion: traefik.containo.us/v1alpha1
    kind: Middleware
    metadata:
      name: api-rate-limit
    spec:
      rateLimit:
        average: 100  # 100 requests per second
        burst: 50     # Allow bursts of 50
    ```

2.  **Apply to IngressRoute**:
    ```yaml
    # ... inside IngressRoute ...
    routes:
    - match: Host(`api.example.com`)
      kind: Rule
      middlewares:
      - name: api-rate-limit
      services:
      - name: my-api
        port: 80
    ```

#### 4. Canary Deployments (Weighted Round Robin)
Gradually roll out a new version by splitting traffic.

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: TraefikService
metadata:
  name: myapp-canary
spec:
  weighted:
    services:
    - name: myapp-v1
      port: 80
      weight: 90  # 90% traffic
    - name: myapp-v2
      port: 80
      weight: 10  # 10% traffic
---
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: myapp-route
spec:
  entryPoints:
    - web
  routes:
  - match: Host(`myapp.example.com`)
    kind: Rule
    services:
    - name: myapp-canary # Point to the TraefikService, not the K8s Service
      kind: TraefikService
```

### Introduction to Service Mesh

A Service Mesh is a dedicated infrastructure layer for handling service-to-service communication. It provides features like traffic management, security (mTLS), and observability without changing application code. We will use **Istio**.

-   **Data Plane**: Sidecar proxies (Envoy) deployed alongside every app container. Intercepts all network traffic.
-   **Control Plane**: Manages and configures the proxies (Istiod).

### Istio Basics

**Installation:**

```bash
# Download istioctl
curl -L https://istio.io/downloadIstio | sh -
cd istio-*
export PATH=$PWD/bin:$PATH

# Install Istio (demo profile is good for learning)
istioctl install --set profile=demo -y
```

**Enable Sidecar Injection:**
Label the namespace so Istio automatically injects the Envoy sidecar.

```bash
kubectl label namespace default istio-injection=enabled
```

Now, any new pod created in `default` will have 2 containers: your app + `istio-proxy`.

### Traffic Management

Istio uses `VirtualService` and `DestinationRule` to control traffic.

**Canary Deployment (Blue/Green):**
Imagine you have `v1` and `v2` of your app. You want to send 90% traffic to `v1` and 10% to `v2`.

1.  **DestinationRule**: Defines the subsets (versions).
    ```yaml
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: myapp
    spec:
      host: myapp
      subsets:
      - name: v1
        labels:
          version: v1
      - name: v2
        labels:
          version: v2
    ```

2.  **VirtualService**: Defines the routing logic.
    ```yaml
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: myapp
    spec:
      hosts:
      - myapp
      http:
      - route:
        - destination:
            host: myapp
            subset: v1
          weight: 90
        - destination:
            host: myapp
            subset: v2
          weight: 10
    ```

### mTLS & Security

Mutual TLS (mTLS) ensures that traffic between services is encrypted and authenticated. Istio enables this by default in "Permissive" mode (allows both plain text and mTLS).

**Enforce Strict mTLS:**

```yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: default
spec:
  mtls:
    mode: STRICT
```

Now, only services with valid Istio certificates can communicate within the `default` namespace. Legacy non-mesh clients will be rejected.

---

## Part 5: Security & Policy

Security in Kubernetes is layered: Cluster, Network, and Runtime.

### Policy as Code (OPA/Kyverno)

We want to enforce rules like "No pods running as root" or "All images must come from our private registry". We can use **Kyverno** (Kubernetes Native Policy Management).

**Install Kyverno:**
```bash
helm repo add kyverno https://kyverno.github.io/kyverno/
helm install kyverno kyverno/kyverno -n kyverno --create-namespace
```

**Example Policy: Disallow Root User**
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: disallow-root-user
spec:
  validationFailureAction: Enforce
  rules:
  - name: check-runasnonroot
    match:
      resources:
        kinds:
        - Pod
    validate:
      message: "Running as root is not allowed. Set runAsNonRoot to true."
      pattern:
        spec:
          securityContext:
            runAsNonRoot: true
```

### Network Policies Deep Dive

By default, all pods can talk to all other pods. **NetworkPolicies** act as a firewall inside the cluster.

**Best Practice: Default Deny All**
Start by blocking all traffic, then whitelist what is needed.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: default
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

**Allow Traffic to Frontend:**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: frontend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: ingress-gateway # Allow traffic from Ingress Controller
    ports:
    - protocol: TCP
      port: 80
```

### Runtime Security

Tools like **Falco** monitor kernel system calls to detect suspicious activity (e.g., a shell spawning in a container, sensitive file access).

**Install Falco:**
```bash
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm install falco falcosecurity/falco -n falco --create-namespace
```

Falco logs alerts to stdout or sends them to Slack/AlertManager when it detects anomalies.

### Advanced Secret Management (External Secrets Operator)

While Sealed Secrets (covered in Part 2) is excellent for GitOps, managing secrets across multiple environments or rotating them can be challenging. **External Secrets Operator (ESO)** is the industry standard for syncing secrets from external secret managers (like AWS Secrets Manager, HashiCorp Vault, or Azure Key Vault) into Kubernetes.

**Why use ESO?**
- **Centralization**: Manage all secrets in a secure, external vault.
- **Rotation**: Rotate secrets in the provider, and ESO automatically updates them in the cluster.
- **Security**: Secrets are never stored in Git.

**Installation:**
```bash
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets -n external-secrets --create-namespace
```

**How it works:**
1.  **SecretStore**: Defines how to connect to your external provider (e.g., Vault).
2.  **ExternalSecret**: Defines which secret to fetch and how to map it to a Kubernetes Secret.

**Example (Conceptual):**
Instead of committing a `SealedSecret`, you commit an `ExternalSecret` manifest.

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: database-credentials
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: my-secret-store
    kind: SecretStore
  target:
    name: db-secret # The K8s Secret to create
  data:
  - secretKey: username
    remoteRef:
      key: prod/db
      property: username
  - secretKey: password
    remoteRef:
      key: prod/db
      property: password
```

---

## Part 6: Advanced Helm

While using public charts is easy, creating your own allows you to package your applications for distribution.

### Chart Development

Create a new chart:
```bash
helm create mychart
```

This creates a directory structure:
-   `Chart.yaml`: Metadata (name, version).
-   `values.yaml`: Default configuration values.
-   `templates/`: The YAML templates that get rendered.

**Templating Basics:**
In `templates/deployment.yaml`, you'll see:
```yaml
replicas: {{ .Values.replicaCount }}
```
This replaces the value from `values.yaml`.

**Flow Control (If/Else):**
```yaml
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
...
{{- end }}
```

### Helmfile for Multi-Chart Management

Managing 10 different `helm install` commands is tedious. **Helmfile** allows you to define all your releases in one YAML file.

**Install Helmfile:**
```bash
# macOS
brew install helmfile

# Linux
# Fetch latest version tag
HELMFILE_VERSION=$(curl -s https://api.github.com/repos/helmfile/helmfile/releases/latest | grep tag_name | cut -d '"' -f 4 | cut -c 2-)
wget "https://github.com/helmfile/helmfile/releases/download/v${HELMFILE_VERSION}/helmfile_${HELMFILE_VERSION}_linux_amd64.tar.gz"
tar -zxvf helmfile_${HELMFILE_VERSION}_linux_amd64.tar.gz helmfile
sudo mv helmfile /usr/local/bin/
```

**Example `helmfile.yaml`:**
```yaml
repositories:
  - name: prometheus-community
    url: https://prometheus-community.github.io/helm-charts

releases:
  - name: monitoring
    namespace: monitoring
    chart: prometheus-community/kube-prometheus-stack
    version: 45.0.0
    values:
      - grafana:
          enabled: true
  
  - name: myapp
    chart: ./charts/mychart
    values:
      - values-prod.yaml
```

**Apply all charts:**
```bash
helmfile sync
```

---

## Part 7: Kustomize (Native Configuration Management)

While Helm is a package manager that uses templates, **Kustomize** is a configuration management tool that uses a template-free approach based on **overlays**. It is built into `kubectl` (since v1.14), making it a "native" choice for many.

### Core Concepts: Base & Overlays

Kustomize allows you to define a **Base** (common configuration) and **Overlays** (environment-specific patches).

**Directory Structure:**
```text
├── base/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── kustomization.yaml
└── overlays/
    ├── dev/
    │   ├── kustomization.yaml
    │   └── replica_count.yaml
    └── prod/
        ├── kustomization.yaml
        └── resource_limits.yaml
```

### The `kustomization.yaml` File

This file tells Kustomize what to do.

**Base (`base/kustomization.yaml`):**
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- deployment.yaml
- service.yaml

commonLabels:
  app: myapp
```

**Overlay (`overlays/prod/kustomization.yaml`):**
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- ../../base

namePrefix: prod-
namespace: production

patches:
- path: resource_limits.yaml
```

### Common Transformers

Kustomize can automatically modify resources without touching the original YAML.

1.  **`commonLabels`**: Adds a label to *every* resource and selector.
2.  **`namePrefix` / `nameSuffix`**: Renames resources (e.g., `myapp` -> `prod-myapp`).
3.  **`namespace`**: Sets the namespace for all resources.
4.  **`images`**: Overrides container images and tags.

**Example: Changing Image Tag in Prod**
```yaml
images:
- name: my-app-image
  newName: registry.example.com/my-app
  newTag: v2.0.0
```

### ConfigMap & Secret Generators

Instead of writing `ConfigMap` YAMLs manually, generate them from files or literals. This appends a hash to the name (e.g., `my-config-v5d89f`), forcing a Pod rollout when content changes.

```yaml
configMapGenerator:
- name: app-config
  files:
  - config.properties
  literals:
  - ENVIRONMENT=production
```

### Usage

Since Kustomize is built into `kubectl`, you can apply it directly:

```bash
# Apply the Dev overlay
kubectl apply -k overlays/dev/

# View the generated YAML (dry-run)
kubectl kustomize overlays/prod/
```

### Kustomize vs. Helm

| Feature | Helm | Kustomize |
| :--- | :--- | :--- |
| **Approach** | Templating (Go templates) | Overlays (Patching) |
| **Complexity** | High (learning curve) | Low (pure YAML) |
| **Packaging** | Charts (tarballs) | Git directories |
| **Use Case** | Distributing apps to others | Managing own config across envs |

Many teams use **both**: Helm to install 3rd party apps (Prometheus, Cert-Manager) and Kustomize for their own internal microservices.

---

## Part 8: Production-Ready Stateful Workloads (PostgreSQL)

Running stateful workloads like databases on Kubernetes has historically been challenging. However, with the maturity of **Operators**, it is now a viable and powerful option for production.

### Running Databases on Kubernetes

**Managed Service (DbaaS) vs. Kubernetes Operator:**
-   **Managed Service (e.g., DigitalOcean Managed Databases, AWS RDS)**: Easiest to set up, handled backups/updates, but higher cost and vendor lock-in.
-   **Kubernetes Operator**: Runs inside your cluster, lower cost, full control, no lock-in, but requires more knowledge to manage.

For this guide, we will use the **CloudNativePG (CNPG)** operator, which is widely considered the gold standard for running PostgreSQL on Kubernetes.

### CloudNativePG Operator

CNPG provides:
-   **High Availability**: Automatic failover.
-   **Self-Healing**: Automatically recovers from node failures.
-   **Backups & PITR**: Continuous WAL archiving to S3/MinIO.
-   **Connection Pooling**: Integrated PgBouncer.

**Installation:**

```bash
helm repo add cnpg https://cloudnative-pg.io/charts
helm repo update
helm install cnpg cnpg/cloudnative-pg -n cnpg-system --create-namespace
```

### High Availability (Replicas)

To ensure your database survives a node failure, you should run at least 3 instances (1 Primary, 2 Replicas).

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: production-db
  namespace: database
spec:
  instances: 3 # 1 Primary + 2 Replicas
  
  # Storage Configuration
  storage:
    size: 10Gi
    storageClass: do-block-storage
  
  # PostgreSQL Configuration
  postgresql:
    parameters:
      max_connections: "1000"
      shared_buffers: "256MB"
```

### Backups & PITR

Production databases need **Point-in-Time Recovery (PITR)**. This allows you to restore the database to *any* second in the past (e.g., right before a bad `DROP TABLE` command).

CNPG achieves this by archiving Write-Ahead Logs (WAL) to object storage (like AWS S3 or DigitalOcean Spaces).

**1. Create a Secret with S3 Credentials (Securely):**
Instead of creating a raw Kubernetes Secret (which is insecure in GitOps), we will use the **External Secrets Operator** (covered in Part 5) to fetch credentials from your cloud provider (e.g., AWS Secrets Manager or DigitalOcean Vault).

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: backup-s3-creds
  namespace: database
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: do-vault-backend
    kind: ClusterSecretStore
  target:
    name: backup-s3-creds # The K8s Secret to be created
  data:
  - secretKey: ACCESS_KEY_ID
    remoteRef:
      key: production/postgres-backup
      property: access-key
  - secretKey: SECRET_ACCESS_KEY
    remoteRef:
      key: production/postgres-backup
      property: secret-key
```

**2. Configure the Cluster for Archiving:**
```yaml
spec:
  backup:
    barmanObjectStore:
      destinationPath: s3://my-backup-bucket/postgres/
      endpointURL: https://nyc3.digitaloceanspaces.com
      s3Credentials:
        accessKeyId:
          name: backup-s3-creds
          key: ACCESS_KEY_ID
        secretAccessKey:
          name: backup-s3-creds
          key: SECRET_ACCESS_KEY
      wal:
        compression: gzip
      data:
        compression: gzip
```

**Restoring:**
To restore, you create a *new* Cluster resource that bootstraps from the backup.

```yaml
spec:
  bootstrap:
    recovery:
      source: production-db
      recoveryTarget:
        targetTime: "2023-11-28 14:00:00.000000+00" # Restore to this exact time
```

### Connection Pooling (PgBouncer)

PostgreSQL has a high per-connection overhead. In a microservices environment (like Kubernetes), you might have hundreds of pods trying to connect, which can overwhelm the database.

**PgBouncer** is a lightweight connection pooler that sits in front of Postgres. It maintains a small pool of connections to the DB and reuses them for thousands of client clients.

CNPG has native support for PgBouncer.

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Pooler
metadata:
  name: pooler-rw
  namespace: database
spec:
  cluster:
    name: production-db
  instances: 2
  type: rw
  pgbouncer:
    poolMode: transaction
    parameters:
      max_client_conn: "1000"
      default_pool_size: "20"
```

**Application Connection:**
Instead of connecting to the database service directly, your apps connect to the **Pooler** service (`pooler-rw-rw`).

```yaml
# App Environment Variables
env:
  - name: DB_HOST
    value: pooler-rw-rw # Connects via PgBouncer
  - name: DB_PORT
    value: "5432"
```

---

## Part 9: Multi-Region & Multi-Cluster Strategy

As your application grows, running on a single cluster in a single region becomes a risk. A region outage (e.g., `nyc1` goes down) could take your entire business offline.

### Why Multi-Region?
1.  **High Availability (HA)**: Survive a complete region failure.
2.  **Latency**: Serve users from the region closest to them (e.g., EU users hit `fra1`, US users hit `nyc1`).
3.  **Compliance**: Keep data within specific borders (GDPR).

### Architecture Patterns

**1. Active-Passive (Disaster Recovery):**
-   **Primary Cluster (Active)**: Handles 100% of traffic.
-   **Secondary Cluster (Passive)**: Scaled down, waiting for failover.
-   **Data Sync**: Async replication of databases and object storage.
-   **Pros**: Simpler to manage.
-   **Cons**: Higher RTO (Recovery Time Objective) during failover.

**2. Active-Active:**
-   **Both Clusters**: Handle traffic simultaneously.
-   **Global Load Balancer**: Routes traffic based on geography or health.
-   **Data Sync**: Requires complex bi-directional replication (e.g., CockroachDB, Cassandra) or sharding.
-   **Pros**: Zero downtime, low latency.
-   **Cons**: Very complex data consistency challenges.

### Global Load Balancing (GSLB)

Standard Kubernetes LoadBalancers are regional. To route traffic across regions, you need a **Global Server Load Balancer (GSLB)**. This is usually DNS-based.

**Tools:**
-   **ExternalDNS**: Can sync Kubernetes Services/Ingresses to DNS providers (Route53, Cloudflare, DigitalOcean DNS).
-   **K8GB**: A cloud native GSLB solution that runs inside your cluster.

**Example with ExternalDNS (Weighted Routing):**
You can configure ExternalDNS to update your DNS provider with the IPs of your Ingress Controllers in both regions.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    external-dns.alpha.kubernetes.io/target: myapp.example.com
    external-dns.alpha.kubernetes.io/set-identifier: "nyc1-cluster"
    external-dns.alpha.kubernetes.io/aws-weight: "100" # Route53 specific
```

### Multi-Cluster Connectivity (Cilium Mesh)

If Service A in `nyc1` needs to talk to Service B in `fra1`, you need a multi-cluster service mesh. **Cilium Cluster Mesh** is a high-performance option that connects clusters at the networking layer (eBPF).

**How it works:**
-   Cilium agents in both clusters peer with each other.
-   Pod IPs are routable across the mesh (via VPN or VPC peering).
-   Service discovery works globally (`service-b.default.svc.cluster.local` resolves to IPs in both clusters).

**Enable Cluster Mesh:**
```bash
# On Cluster 1
cilium clustermesh enable --context $CTX1

# On Cluster 2
cilium clustermesh enable --context $CTX2

# Connect them
cilium clustermesh connect --context $CTX1 --destination-context $CTX2
```

### GitOps for Multi-Cluster (ArgoCD ApplicationSets)

Managing 10 clusters with 10 different `Application` manifests is unscalable. **ArgoCD ApplicationSets** allow you to generate Applications automatically based on a list of clusters.

**Generator Example:**
This deploys the `guestbook` app to *all* clusters labeled `env: production`.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: guestbook-global
spec:
  generators:
  - clusters:
      selector:
        matchLabels:
          env: production
  template:
    metadata:
      name: 'guestbook-{{name}}'
    spec:
      project: default
      source:
        repoURL: https://github.com/argoproj/argocd-example-apps.git
        targetRevision: HEAD
        path: guestbook
      destination:
        server: '{{server}}'
        namespace: guestbook
```

---

## Capstone Project: End-to-End Production Platform

In this final project, you will build a complete production-grade platform using everything you've learned.

### Architecture
1.  **Infrastructure**: DOKS cluster provisioned via **Terraform**.
2.  **GitOps**: **ArgoCD** managing all applications.
3.  **Observability**: **Prometheus/Grafana/Loki** stack.
4.  **Networking**: **Istio** Service Mesh for traffic management.
5.  **Security**: **Kyverno** policies and **NetworkPolicies**.
6.  **Application**: A microservices e-commerce app (e.g., Google's Online Boutique).

### Steps

1.  **Infrastructure**:
    -   Use Terraform to spin up a 3-node cluster (s-4vcpu-8gb nodes recommended for this stack).

2.  **Bootstrap**:
    -   Install ArgoCD manually (or via Terraform Helm provider).
    -   Connect ArgoCD to your Git repository.

3.  **App of Apps Pattern**:
    -   Create a "Root Application" in ArgoCD that points to a folder containing other Applications.
    -   This allows you to deploy the entire stack (Monitoring, Istio, App) with one sync.

4.  **Deploy**:
    -   Commit the manifests for Prometheus, Loki, Istio, and the Online Boutique app to Git.
    -   Sync ArgoCD.

5.  **Verify**:
    -   Access Grafana and view cluster metrics.
    -   Access Kiali (Istio dashboard) to see the service mesh graph.
    -   Trigger a canary deployment for the frontend service.

---

## Cleanup & Cost Management

**Important**: Cloud resources cost money. Always clean up when you are done.

### Destroying Infrastructure

Since we used Terraform, cleanup is easy:

```bash
cd terraform-doks
terraform destroy
# Type 'yes' to confirm
```

**Check for Leftovers:**
Sometimes Kubernetes creates resources that Terraform doesn't know about (e.g., LoadBalancers created by Services, PVCs).

```bash
# Check for Load Balancers
doctl compute load-balancer list

# Check for Volumes
doctl compute volume list
```

If you find any, delete them manually via `doctl` or the DigitalOcean dashboard to avoid unexpected charges.

### Cost Optimization Tips
-   **Spot Instances**: Use spot instances for worker nodes (not yet fully supported in DOKS, but keep an eye out).
-   **Auto-Scaling**: Configure cluster autoscaler to scale down to 1 node when idle.
-   **Sleep Mode**: Use tools like `kube-downscaler` to scale deployments to 0 at night.

---
[Back to Basic Curriculum](./basic.md)

