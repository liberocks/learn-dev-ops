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

### **Part 4: Advanced Networking & Service Mesh**
- [Introduction to Service Mesh](#introduction-to-service-mesh)
- [Istio Basics](#istio-basics)
- [Traffic Management (Canary/Blue-Green)](#traffic-management)
- [mTLS & Security](#mtls--security)

### **Part 5: Security & Policy**
- [Policy as Code (OPA/Kyverno)](#policy-as-code)
- [Network Policies Deep Dive](#network-policies-deep-dive)
- [Runtime Security](#runtime-security)

### **Part 6: Advanced Helm**
- [Chart Development](#chart-development)
- [Helmfile for Multi-Chart Management](#helmfile-for-multi-chart-management)

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

---

## Part 4: Advanced Networking & Service Mesh

A Service Mesh is a dedicated infrastructure layer for handling service-to-service communication. It provides features like traffic management, security (mTLS), and observability without changing application code. We will use **Istio**.

### Introduction to Service Mesh

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

