## Plan: Learn Kubernetes on DigitalOcean DOKS

A progressive curriculum covering Kubernetes fundamentals through advanced topics, using DigitalOcean's managed Kubernetes service. The plan balances theory with hands-on practice, leveraging DOKS's simplified setup to focus on learning Kubernetes concepts rather than cluster management.

---

## 📑 Table of Contents

### **Getting Started**
- [Overview](#overview)
- [Steps](#steps)
- [Further Considerations](#further-considerations)

### **Part 1: Environment Setup & Introduction**
- [Prerequisites & Tools Installation](#prerequisites--tools-installation)
- [Create Your First DOKS Cluster](#create-your-first-doks-cluster)
- [First kubectl Commands](#first-kubectl-commands)
- [Exercise 1: Deploy Your First Pod](#exercise-1-deploy-your-first-pod)

### **Part 2: Kubernetes Fundamentals**
- [Understanding Pods](#understanding-pods)
  - Multi-container Pod Pattern
- [Deployments](#deployments)
  - Scaling & Rolling Updates
- [Services](#services)
  - ClusterIP vs LoadBalancer
- [Exercise: Deploy a Sample Application](#exercise-deploy-a-sample-application)

### **Part 3: Configuration & Secrets Management**
- [ConfigMaps](#configmaps)
  - Creating & Using ConfigMaps
- [Secrets](#secrets)
  - Creating & Using Secrets
  - Production Secrets Management

### **Part 4: Storage & StatefulSets**
- [PersistentVolumes with DigitalOcean Volumes](#persistentvolumes-with-digitalocean-volumes)
  - Understanding Storage Classes
  - PersistentVolumeClaims
- [StatefulSets - Deploy MongoDB](#statefulsets---deploy-mongodb)
  - StatefulSet vs Deployment

### **Part 5: Networking & Ingress**
- [Install Nginx Ingress Controller](#install-nginx-ingress-controller)
- [Deploy Multiple Services with Ingress](#deploy-multiple-services-with-ingress)
  - Path-based Routing
- [TLS/SSL with cert-manager](#tlsssl-with-cert-manager)
  - Let's Encrypt Integration

### **Part 6: Helm Package Manager**
- [Introduction to Helm](#introduction-to-helm)
- [Helm Architecture](#helm-architecture)
- [Using Existing Charts](#using-existing-charts)
- [Creating Your Own Charts](#creating-your-own-charts)
- [Helm Best Practices](#helm-best-practices)

### **Part 7: Observability & Monitoring**
- [Install Prometheus & Grafana Stack](#install-prometheus--grafana-stack)
- [Custom Application Metrics](#custom-application-metrics)
  - ServiceMonitors
- [Logging with Loki](#logging-with-efk-stack-elasticsearch-fluentd-kibana)

### **Part 8: Advanced Kubernetes Concepts**
- [Namespaces & Resource Quotas](#namespaces--resource-quotas)
  - ResourceQuota & LimitRange
- [RBAC (Role-Based Access Control)](#rbac-role-based-access-control)
  - Roles, RoleBindings, ServiceAccounts
- [Horizontal Pod Autoscaler (HPA)](#horizontal-pod-autoscaler-hpa)
  - Custom Metrics Autoscaling
- [Cluster Autoscaler](#cluster-autoscaler)

### **Part 9: CI/CD & Production Best Practices**
- [GitOps with GitHub Actions](#gitops-with-github-actions)
  - CI/CD Pipeline Setup
- [Security Best Practices](#security-best-practices)
  - Pod Security Standards
  - NetworkPolicy
- [Backup & Disaster Recovery](#backup--disaster-recovery)
  - Velero Setup

### **Capstone Project**
- [Deploy a Complete Microservices Application](#capstone-project-deploy-a-complete-microservices-application)
  - E-commerce Multi-tier Stack

### **Resource Management & Cleanup**
- [Cleaning Up DigitalOcean Resources](#cleaning-up-digitalocean-resources)
  - Step-by-Step Cleanup Guide
  - Automated Cleanup Script
  - Cost Prevention Best Practices
  - Verification Checklist

### **Reference**
- [Useful Commands Reference](#useful-commands-reference)
- [Cost Optimization Tips](#cost-optimization-tips)
- [Additional Resources](#additional-resources)

---

### Steps

1. **Set up prerequisites and DOKS environment** — Create DigitalOcean account, install `kubectl` and `doctl`, provision first DOKS cluster, configure local access
2. **Master Kubernetes fundamentals** — Learn Pods, Deployments, Services, ConfigMaps, Secrets through hands-on exercises deploying sample applications
3. **Explore storage and stateful workloads** — Work with DigitalOcean Volumes, PersistentVolumes, StatefulSets, deploy databases and stateful applications
4. **Implement networking and ingress** — Configure DigitalOcean Load Balancers, set up Ingress controllers, manage DNS, implement network policies
5. **Practice observability and operations** — Set up monitoring with Prometheus/Grafana, implement logging, practice scaling, rolling updates, and troubleshooting
6. **Build production-ready workflows** — Implement CI/CD pipelines, Helm charts, security best practices, cost optimization, backup/disaster recovery strategies

## **Part 1: Environment Setup & Introduction**

### What You'll Learn
In this module, you'll set up your local development environment and create your first Kubernetes cluster on DigitalOcean. You'll understand what Kubernetes is, why it's useful, and get hands-on experience with the fundamental tools.

**Key Concepts:**
- **Kubernetes (k8s)**: An open-source container orchestration platform that automates deployment, scaling, and management of containerized applications
- **DOKS (DigitalOcean Kubernetes Service)**: A managed Kubernetes service that handles cluster infrastructure, upgrades, and maintenance for you
- **kubectl**: The command-line tool for interacting with Kubernetes clusters
- **doctl**: DigitalOcean's CLI for managing all DigitalOcean resources including Kubernetes clusters

### Prerequisites & Tools Installation

**Step 1: Install kubectl**

`kubectl` (pronounced "kube-control" or "kube-cuttle") is the primary tool you'll use to deploy applications, inspect cluster resources, view logs, and execute commands. It communicates with the Kubernetes API server to manage your cluster.

```bash
# macOS installation
brew install kubectl

# Linux (Ubuntu/Debian)
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl

# Verify installation
kubectl version --client
```

**What this does:** Downloads and installs the kubectl binary, which you'll use for all Kubernetes operations.

**Step 2: Install doctl (DigitalOcean CLI)**

`doctl` is DigitalOcean's command-line interface that lets you create, manage, and delete cloud resources. You'll use it to provision your Kubernetes cluster and manage related infrastructure like load balancers and volumes.

```bash
# macOS installation
brew install doctl

# Linux (Ubuntu/Debian)
# Fetch latest version tag
DOCTL_VERSION=$(curl -s https://api.github.com/repos/digitalocean/doctl/releases/latest | grep tag_name | cut -d '"' -f 4 | cut -c 2-)
wget "https://github.com/digitalocean/doctl/releases/download/v${DOCTL_VERSION}/doctl-${DOCTL_VERSION}-linux-amd64.tar.gz"
tar xf doctl-${DOCTL_VERSION}-linux-amd64.tar.gz
sudo mv doctl /usr/local/bin

# Authenticate
doctl auth init
# Enter your DigitalOcean API token when prompted
```

**What this does:** 
- Installs the doctl CLI tool
- The `auth init` command stores your API token (create one at https://cloud.digitalocean.com/account/api/tokens) so doctl can manage your resources
- This is like logging into DigitalOcean from the command line

**Step 3: Install additional tools**

These optional but highly recommended tools will make your Kubernetes experience much more pleasant:

```bash
# Helm (package manager)
# macOS
brew install helm

# Linux
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm

# k9s (terminal UI for k8s)
# macOS
brew install derailed/k9s/k9s

# Linux
# Fetch latest version tag
K9S_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep tag_name | cut -d '"' -f 4)
wget "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_amd64.tar.gz"
tar -zxvf k9s_Linux_amd64.tar.gz k9s
sudo mv k9s /usr/local/bin/

# kubectx/kubens (context switching)
# macOS
brew install kubectx

# Linux
sudo apt install kubectx
```

**What each tool does:**
- **Helm**: A package manager for Kubernetes (like apt/yum for Linux). It uses "charts" to define, install, and upgrade complex Kubernetes applications
- **k9s**: A terminal-based UI that provides a visual way to navigate and manage your cluster resources - great for learning and troubleshooting
- **kubectx/kubens**: Utilities to quickly switch between different clusters (contexts) and namespaces - saves lots of typing

### Create Your First DOKS Cluster

**Understanding Kubernetes Clusters:**
A Kubernetes cluster consists of:
- **Control Plane**: Managed by DigitalOcean (free) - makes global decisions about the cluster
- **Worker Nodes**: Virtual machines (droplets) that run your applications - these are what you pay for
- **Node Pool**: A group of nodes with the same configuration

**Command to create cluster:**
```bash
# List available regions
doctl kubernetes options regions

# List available node sizes
doctl kubernetes options sizes

# Create a cluster (smallest configuration)
doctl kubernetes cluster create learn-k8s \
  --region sgp1 \
  --node-pool "name=worker-pool;size=s-2vcpu-2gb;count=3"

# This takes 3-5 minutes
```

**What this does:**
- Creates a Kubernetes cluster named "learn-k8s" in the SGP1 datacenter (Singapore)
- Creates 3 worker nodes, each with 2 CPU cores and 2GB RAM
- The 3-node setup provides high availability and allows you to see pod distribution

**Connect to your cluster:**
```bash
# Download kubeconfig
doctl kubernetes cluster kubeconfig save learn-k8s

# Verify connection
kubectl cluster-info
kubectl get nodes
```

**What this does:**
- Downloads the cluster configuration (kubeconfig) to `~/.kube/config`
- Kubeconfig contains cluster address, authentication credentials, and context info
- kubectl uses this config to communicate securely with your cluster's API server

**Expected output:**
```
NAME                   STATUS   ROLES    AGE   VERSION
worker-pool-xxxxx      Ready    <none>   2m    v1.28.2
worker-pool-yyyyy      Ready    <none>   2m    v1.28.2
worker-pool-zzzzz      Ready    <none>   2m    v1.28.2
```

**Understanding the output:**
- Each line is a worker node (a virtual machine running in DigitalOcean)
- `STATUS: Ready` means the node is healthy and ready to run workloads
- `ROLES: <none>` indicates these are worker nodes (not control plane nodes)
- You have 3 nodes for redundancy and load distribution

### First kubectl Commands

**Understanding kubectl syntax:**
The basic pattern is: `kubectl <verb> <resource-type> <resource-name> [flags]`
- **Verbs**: get, describe, create, delete, apply, logs, exec
- **Resources**: pods, services, deployments, nodes, namespaces
- **Flags**: -o (output format), -n (namespace), --all-namespaces, -w (watch)

**Explore your cluster:**
```bash
# View cluster information
kubectl cluster-info

# View all nodes with detailed info
kubectl get nodes -o wide

# List all namespaces (logical partitions within cluster)
kubectl get namespaces

# View all pods across all namespaces
kubectl get pods --all-namespaces

# Describe a node (detailed info including resources, conditions, events)
kubectl describe node <node-name>

# View cluster events (useful for troubleshooting)
kubectl get events --all-namespaces
```

**What each command shows:**
- `cluster-info`: Shows where the control plane is running
- `get nodes -o wide`: Shows node IPs, OS, container runtime, kernel version
- `get namespaces`: Shows logical partitions (default, kube-system, kube-public, etc.)
- `describe node`: Shows capacity, allocatable resources, running pods, and recent events
- `get events`: Shows a timeline of what's happening in the cluster

**Exercise 1: Deploy your first pod**

**What is a Pod?**
- A Pod is the smallest deployable unit in Kubernetes
- It wraps one or more containers that share storage, network, and configuration
- Think of it as a "logical host" - containers in a Pod are always scheduled together on the same node
- Pods are ephemeral - they can be created, destroyed, and recreated

```yaml
# save as: first-pod.yaml
apiVersion: v1           # API version for this resource type
kind: Pod                # Type of Kubernetes object
metadata:
  name: nginx-pod        # Unique name within namespace
  labels:
    app: nginx           # Key-value pairs for organizing/selecting resources
spec:                    # Desired state specification
  containers:
  - name: nginx          # Container name within the pod
    image: nginx:1.25    # Docker image from Docker Hub
    ports:
    - containerPort: 80  # Port the container exposes (documentation only)
```

**Understanding YAML structure:**
- `apiVersion`: Which version of the Kubernetes API to use
- `kind`: What type of object (Pod, Service, Deployment, etc.)
- `metadata`: Data that helps identify the object
- `spec`: The desired state - what you want to happen

```bash
# Deploy the pod
kubectl apply -f first-pod.yaml

# Check status (may show ContainerCreating initially)
kubectl get pods

# Describe the pod for detailed information
kubectl describe pod nginx-pod

# View logs from the nginx container
kubectl logs nginx-pod

# Execute a command inside the running container
kubectl exec -it nginx-pod -- /bin/bash

# Delete the pod
kubectl delete pod nginx-pod
```

**What each command does:**
- `apply`: Creates or updates resources declaratively from YAML
- `get pods`: Shows pod status (Pending, ContainerCreating, Running, Failed)
- `describe`: Shows detailed info including events (image pull, container start, errors)
- `logs`: Streams stdout/stderr from the container - essential for debugging
- `exec -it`: Opens an interactive terminal inside the container (like SSH)
  - `-i`: Keep stdin open
  - `-t`: Allocate a pseudo-TTY (terminal)
  - `--`: Separates kubectl flags from container command
- `delete`: Removes the pod (container stops and pod is deleted)

**Note:** Direct pod creation is uncommon in production - you'll typically use Deployments which manage pods for you.

**🏭 Industry Best Practice:**
- **Learning**: Create standalone Pods to understand the basics
- **Production**: NEVER create standalone Pods - always use Deployments, StatefulSets, or DaemonSets
- **Why**: Standalone Pods don't self-heal, can't be scaled, and are lost if the node fails
- **Exception**: One-off jobs (use Jobs or CronJobs instead)

---

## **Part 2: Kubernetes Fundamentals**

### Understanding Pods

**Pod Patterns:**
Pods typically contain one container, but multi-container pods are used for specific patterns:
- **Sidecar**: Helper container that enhances the main container (logging, monitoring, proxy)
- **Ambassador**: Proxy container that simplifies network connections
- **Adapter**: Transforms the main container's output to match a standard interface

**Multi-container Pod example:**
```yaml
# save as: multi-container-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: web-app
spec:
  containers:
  - name: app
    image: nginx:1.25
    ports:
    - containerPort: 80
    volumeMounts:
    - name: shared-data
      mountPath: /usr/share/nginx/html  # Where nginx serves files from
  
  - name: sidecar
    image: busybox
    command: ['sh', '-c', 'while true; do echo "$(date) - Hello from sidecar" > /data/index.html; sleep 10; done']
    volumeMounts:
    - name: shared-data
      mountPath: /data                  # Same volume, different path
  
  volumes:
  - name: shared-data
    emptyDir: {}                        # Temporary volume shared between containers
```

**What this demonstrates:**
- **Shared storage**: Both containers mount the same volume (`shared-data`)
- **Sidecar pattern**: The busybox container continuously writes a file that nginx serves
- **emptyDir**: A temporary directory that exists as long as the Pod exists
- **Container lifecycle**: Both containers start together, share the same network (both use localhost), and are scheduled on the same node

**Why multi-container pods?**
- Containers need to share data or resources
- Tight coupling required (always deployed together)
- Containers need to communicate via localhost
- Example: Web server + log shipper, app + monitoring agent

**🏭 Industry Best Practice:**
- **When to use**: Only when containers are truly inseparable (sidecar pattern)
- **Common production use cases**:
  - Service mesh sidecar (Istio, Linkerd)
  - Log forwarding (Fluentd, Filebeat)
  - Secret injection (Vault agent)
  - TLS termination proxy
- **Anti-pattern**: Putting your entire application stack (web + API + DB) in one Pod
- **Keep it simple**: Most Pods should have just one container

```bash
kubectl apply -f multi-container-pod.yaml

# View logs from specific containers
kubectl logs web-app -c app        # nginx logs
kubectl logs web-app -c sidecar    # sidecar logs

# Forward local port 8080 to pod's port 80
kubectl port-forward web-app 8080:80
# Visit http://localhost:8080
```

**What port-forward does:**
- Creates a tunnel from your local machine to the pod
- Useful for testing before creating a Service
- Only works while the command is running

**🏭 Industry Best Practice - Port Forwarding:**
- **Learning/Debug**: Perfect for quick testing and troubleshooting
- **Production**: NEVER use port-forward for production traffic
- **Why not production**:
  - Requires kubectl access (security risk)
  - Single point of failure (your laptop)
  - No load balancing
  - Terminates when connection drops
- **Production alternatives**:
  - Internal services: Use ClusterIP Service + DNS
  - External access: Use Ingress with proper domain/TLS
  - Developer access: VPN + Internal Services
  - Debugging: Use it! But not for regular traffic

### Deployments

**What is a Deployment?**
- A higher-level abstraction that manages Pods
- Provides declarative updates, rollbacks, and scaling
- Creates and manages ReplicaSets (which manage Pods)
- **Production standard**: You rarely create Pods directly - always use Deployments

**Key benefits:**
- **Self-healing**: Replaces failed pods automatically
- **Scaling**: Easily adjust number of replicas
- **Rolling updates**: Zero-downtime deployments
- **Rollback**: Revert to previous versions easily
- **Declarative**: Describe desired state, Kubernetes makes it happen

**Basic Deployment:**
```yaml
# save as: nginx-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3                    # How many pod copies to run
  selector:
    matchLabels:
      app: nginx                 # Which pods this Deployment manages
  template:                      # Pod template (same as Pod spec)
    metadata:
      labels:
        app: nginx               # Labels applied to created pods
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports:
        - containerPort: 80
        resources:               # Resource requests and limits
          requests:              # Minimum resources needed
            memory: "64Mi"       # Kubernetes won't schedule without this
            cpu: "100m"          # 100 millicores = 0.1 CPU
          limits:                # Maximum resources allowed
            memory: "128Mi"      # Pod killed if it exceeds this
            cpu: "200m"          # Throttled if it exceeds this
```

**Understanding resource management:**
- **requests**: Guaranteed resources - used for scheduling decisions
- **limits**: Maximum allowed - protects cluster from resource exhaustion
- **CPU**: Measured in cores (1000m = 1 core)
- **Memory**: Measured in bytes (Mi = Mebibytes, Gi = Gibibytes)

**🏭 Industry Best Practice - Resource Settings:**

**ALWAYS set in production:**
```yaml
resources:
  requests:     # For scheduling - set based on actual usage
    memory: "128Mi"
    cpu: "100m"
  limits:       # For protection - set 1.5-2x requests
    memory: "256Mi"
    cpu: "200m"
```

**Production guidelines:**
- **CPU requests**: Start with 100m-500m, monitor and adjust
- **CPU limits**: 2x requests (allows bursting, prevents noisy neighbors)
- **Memory requests**: Match actual usage (use metrics from monitoring)
- **Memory limits**: 1.5x requests (memory can't be throttled like CPU)
- **Never**: Omit resources (pods can't be scheduled properly)
- **Never**: Set limits too low (causes OOMKills and CPU throttling)
- **Monitor**: Use Prometheus + Grafana to find right-sized values

**Learning environment**: Lower values are fine (64Mi/100m) to save costs

```bash
# Deploy
kubectl apply -f nginx-deployment.yaml

# Watch rollout progress
kubectl rollout status deployment/nginx-deployment

# View deployment details
kubectl get deployments
kubectl describe deployment nginx-deployment
kubectl get pods -l app=nginx        # -l filters by label

# Scale deployment (change replica count)
kubectl scale deployment nginx-deployment --replicas=5
kubectl get pods -w                  # -w watches for changes

# Update image (triggers rolling update)
kubectl set image deployment/nginx-deployment nginx=nginx:1.26
kubectl rollout status deployment/nginx-deployment

# View rollout history
kubectl rollout history deployment/nginx-deployment

# Rollback to previous version
kubectl rollout undo deployment/nginx-deployment
```

**Understanding rollouts:**
- **Rolling update**: Default strategy - gradually replaces old pods with new ones
- **Process**: Creates new pod → waits for readiness → terminates old pod → repeat
- **Zero downtime**: Old pods keep running until new ones are ready
- **Rollback**: Reverts to previous ReplicaSet instantly
- **History**: Kubernetes stores previous ReplicaSet configurations (limited by `revisionHistoryLimit`)

### Services

**What is a Service?**
- Provides stable networking for ephemeral Pods
- Pods get random IPs and are replaced frequently - Services provide consistency
- Acts as a load balancer across pod replicas
- Uses label selectors to find pods dynamically

**Service Types:**
1. **ClusterIP** (default): Internal-only, accessible within cluster
2. **NodePort**: Exposes on each node's IP at a static port (30000-32767)
3. **LoadBalancer**: Provisions external load balancer (cloud-specific)
4. **ExternalName**: Maps to external DNS name

**🏭 Industry Best Practice - Service Types:**

| Type | Production Use | When to Use |
|------|----------------|-------------|
| **ClusterIP** | ✅ Primary choice | Internal microservices communication |
| **LoadBalancer** | ⚠️ Expensive | Legacy apps, quick demos (each = $12/month) |
| **NodePort** | ❌ Avoid | Development only, security concerns |
| **ExternalName** | ✅ Rare but valid | Migrating external services to cluster |

**Production recommendation:**
- **Internal services**: Always use ClusterIP
- **External traffic**: Use **Ingress** with one LoadBalancer
  - Cost: 1 LB ($12) vs 10 services × $12 = $120/month savings
  - Better: TLS termination, path routing, host-based routing
- **Exception**: Legacy apps that need dedicated IPs (use LoadBalancer)

**Learning exercise**: We use LoadBalancer for simplicity, but know it's expensive!

**ClusterIP Service (internal):**
```yaml
# save as: nginx-service-clusterip.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: ClusterIP              # Internal only (default type)
  selector:
    app: nginx                 # Routes traffic to pods with this label
  ports:
  - protocol: TCP
    port: 80                   # Service port (how others access it)
    targetPort: 80             # Container port (where traffic is sent)
```

**How it works:**
- Service gets a stable ClusterIP (e.g., 10.245.1.15)
- DNS name created automatically: `nginx-service.default.svc.cluster.local`
- Other pods can access it by name: `http://nginx-service`
- Service load-balances traffic across all matching pods
- If pods are added/removed, Service automatically updates endpoints

**LoadBalancer Service (external - uses DigitalOcean LB):**
```yaml
# save as: nginx-service-lb.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-loadbalancer
  annotations:
    service.beta.kubernetes.io/do-loadbalancer-name: "nginx-lb"
spec:
  type: LoadBalancer         # Triggers cloud load balancer creation
  selector:
    app: nginx
  ports:
  - protocol: TCP
    port: 80                 # External port
    targetPort: 80           # Container port
```

**What happens when you apply this:**
1. Kubernetes asks DigitalOcean to create a load balancer
2. DigitalOcean provisions an external load balancer (~$12/month)
3. Load balancer gets a public IP address
4. Traffic flow: Internet → Load Balancer → Service → Pods
5. Load balancer health checks pods automatically
6. **Important**: Each LoadBalancer Service = separate DigitalOcean load balancer = additional cost

```bash
# Apply services
kubectl apply -f nginx-service-clusterip.yaml
kubectl apply -f nginx-service-lb.yaml

# Get service details
kubectl get services                     # Shows CLUSTER-IP and EXTERNAL-IP
kubectl describe service nginx-loadbalancer

# Wait for external IP (takes 1-2 minutes for DigitalOcean to provision)
kubectl get service nginx-loadbalancer -w

# Test the service
curl http://<EXTERNAL-IP>
```

**Understanding service output:**
```
NAME                 TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)
nginx-service        ClusterIP      10.245.1.15     <none>          80/TCP
nginx-loadbalancer   LoadBalancer   10.245.2.20     165.227.x.x     80:31234/TCP
```
- **CLUSTER-IP**: Internal IP, only accessible from within cluster
- **EXTERNAL-IP**: Public IP address (only for LoadBalancer type)
- **PORT(S)**: 80:31234 means external port 80 maps to NodePort 31234
- `<pending>`: Load balancer is being created

### Exercise: Deploy a Sample Application

**Complete app with deployment and service:**
```yaml
# save as: hello-app.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: hello
  template:
    metadata:
      labels:
        app: hello
    spec:
      containers:
      - name: hello
        image: gcr.io/google-samples/hello-app:1.0
        ports:
        - containerPort: 8080
        env:
        - name: PORT
          value: "8080"
---
apiVersion: v1
kind: Service
metadata:
  name: hello-service
spec:
  type: LoadBalancer
  selector:
    app: hello
  ports:
  - port: 80              # External port users connect to
    targetPort: 8080      # Container port app listens on
```

**Understanding the `---` separator:**
- YAML documents separated by `---` in one file
- kubectl processes them in order
- Convenient way to group related resources
- Deployment creates pods, Service exposes them

**🏭 Industry Best Practice - File Organization:**

**Learning**: One file with `---` separators (simple, easy to understand)
```yaml
# app.yaml
apiVersion: apps/v1
kind: Deployment
---
apiVersion: v1
kind: Service
```

**Production**: Organized directory structure
```
manifests/
├── base/                    # Common resources
│   ├── deployment.yaml
│   ├── service.yaml
│   └── configmap.yaml
├── overlays/
│   ├── dev/                 # Dev-specific
│   ├── staging/             # Staging-specific
│   └── production/          # Prod-specific
└── kustomization.yaml       # Kustomize config
```

**Production tools:**
- **Kustomize** (built into kubectl): Manage variations across environments
- **Helm**: Package and version entire applications
- **ArgoCD/Flux**: GitOps - automatically sync Git → Cluster

**Why separate files in production:**
- Different teams own different resources
- RBAC controls (dev can edit ConfigMap, not Service)
- Easier code review
- Reusable across environments

**What this application does:**
- Runs 3 replicas of a simple "Hello World" web server
- Each pod listens on port 8080
- Service exposes it externally on port 80
- Load balancer distributes traffic across 3 pods

```bash
kubectl apply -f hello-app.yaml

# View all related resources with label selector
kubectl get all -l app=hello
```

**What `-l app=hello` does:**
- `-l` is short for `--selector`
- Filters resources by label
- Shows Deployment, ReplicaSet, Pods, and Service all at once
- Useful for viewing everything related to an application

---

## **Part 3: Configuration & Secrets Management**

### ConfigMaps

**What is a ConfigMap?**
- Stores non-sensitive configuration data as key-value pairs
- Decouples configuration from container images (same image, different configs)
- Can be consumed as environment variables, command-line arguments, or files
- Makes applications portable across environments (dev, staging, prod)

**When to use ConfigMaps:**
- Application settings (API URLs, feature flags, timeouts)
- Configuration files (nginx.conf, app.properties)
- Environment-specific values
- **NOT for sensitive data** (use Secrets instead)

**🏭 Industry Best Practice - Configuration Management:**

**Production approach:**
```yaml
# ❌ Bad: Hardcoded in Deployment
env:
- name: DATABASE_URL
  value: "postgres://prod-db:5432"  # Hard to change, not versioned separately

# ✅ Good: ConfigMap reference
env:
- name: DATABASE_URL
  valueFrom:
    configMapKeyRef:
      name: app-config
      key: database_url
```

**Benefits:**
- Change config without rebuilding images
- Different configs per environment (dev/staging/prod)
- Config versioned in Git separately from code
- Rolling restart only when config changes

**Production workflow:**
1. Store ConfigMaps in Git (GitOps)
2. Use Kustomize/Helm for environment variations
3. CI/CD updates ConfigMap → triggers rolling restart
4. Monitor config changes (audit trail)

**Anti-patterns to avoid:**
- ❌ Secrets in ConfigMaps (use Secrets + encryption)
- ❌ Huge ConfigMaps (>1MB limit, split into multiple)
- ❌ Mutable ConfigMaps (treat as immutable, version them)
- ❌ Direct kubectl create (no Git history, not reproducible)

**Create ConfigMap from literal values:**
```bash
kubectl create configmap app-config \
  --from-literal=database_url=postgres://db:5432 \
  --from-literal=api_key=dev-key-12345
```

**What this does:**
- Creates a ConfigMap imperatively (without YAML)
- `--from-literal` creates key-value pairs
- Useful for quick testing, but YAML is preferred for version control

**ConfigMap YAML:**
```yaml
# save as: app-configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  database_url: "postgres://db:5432/myapp"
  api_key: "dev-key-12345"
  app.properties: |              # Multi-line string using YAML pipe
    color=blue
    mode=development
    cache.enabled=true
```

**Understanding data formats:**
- Simple key-value: `database_url: "value"`
- Multi-line with `|`: Preserves newlines (useful for config files)
- Multi-line with `>`: Folds newlines into spaces

**Using ConfigMap in Pod:**
```yaml
# save as: pod-with-configmap.yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
spec:
  containers:
  - name: app
    image: nginx:1.25
    envFrom:
    - configMapRef:
        name: app-config          # Loads ALL keys as environment variables
    env:
    - name: SPECIFIC_KEY          # Load specific key with custom name
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: database_url
    volumeMounts:
    - name: config-volume
      mountPath: /etc/config      # Mount config file here
  volumes:
  - name: config-volume
    configMap:
      name: app-config
      items:
      - key: app.properties       # Which key from ConfigMap
        path: application.properties  # Filename in the mount
```

**Three ways to use ConfigMaps:**
1. **envFrom**: All keys become environment variables (DATABASE_URL, API_KEY)
2. **env with valueFrom**: Select specific keys, rename them
3. **volumeMounts**: Mount as files in a directory

**Why mount as files?**
- Some apps expect config files (nginx.conf, application.yml)
- Enables hot-reload without pod restart (some apps watch file changes)
- Better for large configurations

```bash
kubectl apply -f app-configmap.yaml
kubectl apply -f pod-with-configmap.yaml

# Verify environment variables are set
kubectl exec app-pod -- env | grep -E "database_url|api_key"

# Verify file was mounted
kubectl exec app-pod -- cat /etc/config/application.properties
```

**What you'll see:**
- Environment variables: `database_url=postgres://db:5432/myapp`
- File content: The exact content of `app.properties` from ConfigMap
- Changes to ConfigMap require pod restart (except for volume mounts with apps that watch files)

### Secrets

**What is a Secret?**
- Similar to ConfigMap but designed for sensitive data
- Values are base64-encoded (NOT encrypted by default)
- Can be encrypted at rest with additional configuration
- Access can be restricted using RBAC
- Best practice: Use external secret management (Sealed Secrets, External Secrets Operator, Vault)

**Secret vs ConfigMap:**
| Feature | ConfigMap | Secret |
|---------|-----------|--------|
| Purpose | Non-sensitive config | Passwords, tokens, keys |
| Encoding | Plain text | Base64 |
| Encryption | No | Optional (at rest) |
| Size limit | 1MB | 1MB |
| etcd storage | Plain text | Base64 (can enable encryption) |

**🏭 Industry Best Practice - Secrets Management:**

**⚠️ WARNING: Kubernetes Secrets are NOT secure by default!**
- Base64 is **encoding**, not **encryption** (anyone can decode)
- Stored in etcd (often unencrypted)
- Visible to anyone with kubectl access
- Shows up in YAML files in Git

**Production secrets management (choose one):**

**1. Sealed Secrets (Bitnami)**
```bash
# Encrypt secrets client-side, commit encrypted YAML to Git
kubeseal < secret.yaml > sealed-secret.yaml
```
- ✅ Safe to commit to Git
- ✅ Only cluster can decrypt
- ✅ GitOps friendly

**2. External Secrets Operator**
```yaml
# Reference secrets from AWS Secrets Manager, Vault, etc.
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: db-credentials
spec:
  secretStoreRef:
    name: aws-secret-store
  target:
    name: db-credentials
  data:
  - secretKey: password
    remoteRef:
      key: prod/database/password
```
- ✅ Secrets never in Git
- ✅ Centralized management
- ✅ Rotation support
- ✅ Works with AWS, Azure, GCP, Vault

**3. HashiCorp Vault**
- ✅ Industry standard
- ✅ Dynamic secrets (auto-rotating)
- ✅ Audit logging
- ⚠️ More complex to setup

**Learning vs Production:**
- **Learning**: Native Secrets with `stringData` are fine
- **Production**: MUST use External Secrets Operator or Sealed Secrets
- **Never**: Commit base64 secrets to Git (security teams will catch you!)

**RBAC for Secrets:**
```yaml
# Restrict who can view secrets
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list"]  # Only specific teams
```

**Create Secret:**
```bash
# From literal (imperative - not recommended for production)
kubectl create secret generic db-credentials \
  --from-literal=username=admin \
  --from-literal=password='SuperSecret123!'

# From file (better for security - files not in command history)
echo -n 'admin' > ./username.txt
echo -n 'SuperSecret123!' > ./password.txt
kubectl create secret generic db-creds-file \
  --from-file=./username.txt \
  --from-file=./password.txt
rm ./username.txt ./password.txt  # Clean up sensitive files
```

**Why `echo -n`?**
- `-n` prevents adding newline character
- Without it, password would be `SuperSecret123!\n` (includes newline)
- Common source of authentication errors

**Secret YAML (base64 encoded):**
```yaml
# save as: db-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
type: Opaque                    # Generic secret (other types: kubernetes.io/tls, kubernetes.io/dockerconfigjson)
data:
  username: YWRtaW4=            # base64 encoded 'admin'
  password: U3VwZXJTZWNyZXQxMjMh  # base64 encoded 'SuperSecret123!'
```

**Alternative - stringData (no encoding needed):**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
type: Opaque
stringData:                     # Kubernetes encodes this automatically
  username: admin
  password: SuperSecret123!
```

**Which to use?**
- `stringData`: Easier, Kubernetes base64-encodes automatically
- `data`: When you need exact control over encoding
- **Important**: Both are visible in version control - use SealedSecrets or external secret managers for production

```bash
# Encode values
echo -n 'admin' | base64
echo -n 'SuperSecret123!' | base64

kubectl apply -f db-secret.yaml
```

**Using Secrets in Deployment:**
```yaml
# save as: app-with-secrets.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
spec:
  replicas: 2
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
      - name: app
        image: nginx:1.25
        env:
        - name: DB_USERNAME
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: username
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: password
        volumeMounts:
        - name: secret-volume
          mountPath: /etc/secrets
          readOnly: true
      volumes:
      - name: secret-volume
        secret:
          secretName: db-credentials
```

```bash
kubectl apply -f app-with-secrets.yaml
kubectl exec -it deployment/webapp -- env | grep DB_
kubectl exec -it deployment/webapp -- ls -la /etc/secrets/
```

---

## **Part 4: Storage & StatefulSets**

### PersistentVolumes with DigitalOcean Volumes

**Understanding Kubernetes Storage:**
- **Volume**: Directory accessible to containers in a Pod (ephemeral with emptyDir, persistent with PV)
- **PersistentVolume (PV)**: Cluster resource representing storage (provisioned by admin or dynamically)
- **PersistentVolumeClaim (PVC)**: User request for storage (like a pod requesting CPU/memory)
- **StorageClass**: Defines how to dynamically provision PVs (DigitalOcean Block Storage, AWS EBS, etc.)

**Why separate PV and PVC?**
- **Abstraction**: Developers request storage via PVC without knowing infrastructure details
- **Flexibility**: Same PVC works across cloud providers (different StorageClasses handle provisioning)
- **Lifecycle management**: PVs can outlive pods, PVCs can be reused

**StorageClass (automatically created in DOKS):**
```bash
kubectl get storageclass
# NAME                         PROVISIONER                 RECLAIMPOLICY
# do-block-storage (default)   dobs.csi.digitalocean.com   Delete
```

**Understanding StorageClass fields:**
- **NAME**: Reference this when creating PVCs
- **PROVISIONER**: DigitalOcean CSI driver that creates Block Storage volumes
- **RECLAIMPOLICY**: What happens to PV when PVC is deleted
  - `Delete`: PV and underlying storage are deleted (default)
  - `Retain`: PV remains for manual cleanup (data preserved)
- **(default)**: Used when PVC doesn't specify storageClassName

**PersistentVolumeClaim:**
```yaml
# save as: pvc-example.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-data-pvc
spec:
  accessModes:
  - ReadWriteOnce              # RWO: One node can mount as read-write
  resources:
    requests:
      storage: 5Gi             # Request 5 GB
  storageClassName: do-block-storage
```

**Access Modes explained:**
- **ReadWriteOnce (RWO)**: Volume mounted read-write by single node (most common, DigitalOcean supports this)
- **ReadOnlyMany (ROX)**: Volume mounted read-only by many nodes
- **ReadWriteMany (RWX)**: Volume mounted read-write by many nodes (requires NFS, not supported by DO Block Storage)

**What happens when you create this PVC:**
1. Kubernetes sees the PVC request
2. Finds matching StorageClass (`do-block-storage`)
3. Calls DigitalOcean API to create a 5GB Block Storage volume
4. Creates a PV representing that volume
5. Binds PVC to PV (PVC status changes to `Bound`)
6. **Cost**: ~$0.50/month for 5GB ($0.10/GB/month)

**🏭 Industry Best Practice - Storage:**

**Production storage guidelines:**

**1. Storage Classes**
```yaml
# Define multiple storage classes for different needs
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd        # For databases
provisioner: dobs.csi.digitalocean.com
parameters:
  type: pd-ssd
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: slow-hdd        # For logs, backups
provisioner: dobs.csi.digitalocean.com
parameters:
  type: pd-standard
```

**2. Reclaim Policies**
```yaml
# Production: Retain data for manual recovery
reclaimPolicy: Retain  # Default: Delete

# When PVC deleted:
# - Delete: PV and data deleted (DANGEROUS)
# - Retain: PV released, data preserved, manual cleanup
```

**3. Backup Strategy (CRITICAL)**
```bash
# Use Velero for production backups
velero backup create daily-backup --schedule="0 2 * * *"
```
- ✅ Automated daily backups
- ✅ Disaster recovery
- ✅ Cluster migration
- ✅ Test restores regularly!

**4. Volume Snapshots**
```yaml
# Point-in-time snapshots (faster than Velero)
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: db-snapshot-20241125
spec:
  source:
    persistentVolumeClaimName: postgres-data
```

**Production checklist:**
- ✅ Set `reclaimPolicy: Retain` for critical data
- ✅ Automated backups (Velero)
- ✅ Test disaster recovery quarterly
- ✅ Monitor volume usage (alerts at 80%)
- ✅ Document restore procedures
- ❌ Never rely on single PVC without backups
- ❌ Don't use emptyDir for anything important (lost when pod deleted)

**Pod using PVC:**
```yaml
# save as: pod-with-pvc.yaml
apiVersion: v1
kind: Pod
metadata:
  name: data-pod
spec:
  containers:
  - name: app
    image: nginx:1.25
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: app-data-pvc
```

```bash
kubectl apply -f pvc-example.yaml

# Watch PVC get bound
kubectl get pvc
# NAME           STATUS   VOLUME                 CAPACITY   ACCESS MODES   STORAGECLASS
# app-data-pvc   Bound    pvc-abc123-xyz456...   5Gi        RWO            do-block-storage

kubectl apply -f pod-with-pvc.yaml

# Write data to persistent volume
kubectl exec data-pod -- sh -c 'echo "persistent data" > /data/test.txt'

# Delete and recreate pod to prove data persists
kubectl delete pod data-pod
kubectl apply -f pod-with-pvc.yaml

# Verify data survived pod deletion
kubectl exec data-pod -- cat /data/test.txt
# Output: persistent data
```

**Key insight:**
- Pod deleted → Container and emptyDir volumes are gone
- PVC and PV remain → Data persists
- New pod using same PVC → Gets same data
- This is how databases maintain data across pod restarts

### StatefulSets - Deploy MongoDB

**Deployment vs StatefulSet:**
| Feature | Deployment | StatefulSet |
|---------|-----------|-------------|
| Pod names | Random (nginx-abc123) | Ordered (mongodb-0, mongodb-1) |
| Scaling order | Parallel | Sequential (0→1→2) |
| Network identity | Unstable | Stable (mongodb-0.mongodb) |
| Storage | Shared PVC or ephemeral | Per-pod PVC (volumeClaimTemplates) |
| Use cases | Stateless apps (web servers) | Stateful apps (databases, queues) |

**When to use StatefulSets:**
- Databases (MongoDB, PostgreSQL, MySQL)
- Distributed systems (Kafka, ZooKeeper, etcd)
- Apps requiring stable network identity
- Apps needing ordered deployment/scaling
- Each replica needs its own persistent storage

**🏭 Industry Best Practice - StatefulSets vs Managed Services:**

**Production decision tree:**

```
Do you need a database?
├─ YES → Use managed service (RDS, Cloud SQL, DigitalOcean Managed DB)
│        ✅ Automatic backups
│        ✅ Automatic updates
│        ✅ High availability
│        ✅ Expert support
│        ⚠️ More expensive
│
└─ Need self-hosted? → Use StatefulSet
         ⚠️ You manage backups
         ⚠️ You manage HA
         ⚠️ You manage upgrades
         ✅ Full control
         ✅ Cost savings (if team is experienced)
```

**When to run databases in Kubernetes:**
- ✅ You have dedicated DB/DevOps team
- ✅ Cost savings are critical
- ✅ Need specific version/configuration
- ✅ Multi-cloud portability required
- ❌ Small team without DB expertise (use managed!)
- ❌ Critical production database (use managed!)
- ❌ Compliance requirements (easier with managed)

**If using StatefulSets for databases:**
```yaml
# Production requirements:
spec:
  replicas: 3              # Always odd numbers (quorum)
  podManagementPolicy: OrderedReady
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      partition: 0
  
  # Anti-affinity (spread across nodes/zones)
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
          - key: app
            operator: In
            values:
            - mongodb
        topologyKey: topology.kubernetes.io/zone
```

**Production StatefulSet checklist:**
- ✅ 3+ replicas for HA
- ✅ Pod anti-affinity (spread across zones)
- ✅ Resource limits set
- ✅ Persistent volumes with Retain policy
- ✅ Automated backups (Velero + native DB backups)
- ✅ Monitoring (Prometheus + DB-specific exporters)
- ✅ Disaster recovery tested
- ✅ Upgrade runbook documented

**Learning**: Running MongoDB in Kubernetes is great for learning!
**Production**: Consider DigitalOcean Managed MongoDB ($15/month with backups, HA, support)

**Complete MongoDB StatefulSet:**
```yaml
# save as: mongodb-statefulset.yaml
apiVersion: v1
kind: Service
metadata:
  name: mongodb
  labels:
    app: mongodb
spec:
  ports:
  - port: 27017
    name: mongo
  clusterIP: None
  selector:
    app: mongodb
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mongodb
spec:
  serviceName: mongodb
  replicas: 3
  selector:
    matchLabels:
      app: mongodb
  template:
    metadata:
      labels:
        app: mongodb
    spec:
      containers:
      - name: mongodb
        image: mongo:7.0
        ports:
        - containerPort: 27017
          name: mongo
        env:
        - name: MONGO_INITDB_ROOT_USERNAME
          value: admin
        - name: MONGO_INITDB_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mongodb-secret
              key: password
        volumeMounts:
        - name: mongo-data
          mountPath: /data/db
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
  volumeClaimTemplates:
  - metadata:
      name: mongo-data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: do-block-storage
      resources:
        requests:
          storage: 10Gi
---
apiVersion: v1
kind: Secret
metadata:
  name: mongodb-secret
type: Opaque
stringData:
  password: "SecureMongoPass123!"
```

```bash
kubectl apply -f mongodb-statefulset.yaml

# Watch pods come up in order (mongodb-0, then mongodb-1, then mongodb-2)
kubectl get pods -l app=mongodb -w

# Verify stable network identities
kubectl get pods -l app=mongodb -o wide

# Connect to specific pod (stable DNS name)
kubectl exec -it mongodb-0 -- mongosh -u admin -p SecureMongoPass123!

# Inside mongosh:
# show dbs
# exit

# Check PVCs created automatically (one per pod)
kubectl get pvc -l app=mongodb
# NAME                    STATUS   VOLUME      CAPACITY
# mongo-data-mongodb-0    Bound    pvc-xxx     10Gi
# mongo-data-mongodb-1    Bound    pvc-yyy     10Gi
# mongo-data-mongodb-2    Bound    pvc-zzz     10Gi
```

**StatefulSet behavior:**
- **Ordered creation**: mongodb-0 must be Running before mongodb-1 starts
- **Stable DNS**: `mongodb-0.mongodb.default.svc.cluster.local` (never changes)
- **Persistent storage**: Each pod gets its own PVC (survives pod deletion)
- **Ordered deletion**: Deleted in reverse (2→1→0)
- **Scaling**: `kubectl scale statefulset mongodb --replicas=5` adds mongodb-3, mongodb-4 in order

**volumeClaimTemplates:**
- Creates PVC automatically for each pod
- PVC named: `<volumeClaimTemplate-name>-<statefulset-name>-<ordinal>`
- PVCs persist when pods are deleted (data survives restarts)
- Deleting StatefulSet doesn't delete PVCs (manual cleanup required)

---

## **Part 5: Networking & Ingress**

### Install Nginx Ingress Controller

**What is Ingress?**
- **Problem**: Each LoadBalancer Service = one DigitalOcean LB = $12/month
- **Solution**: One LoadBalancer (Ingress Controller) + Ingress rules to route to multiple services
- **Ingress Controller**: Actual load balancer (nginx, Traefik, HAProxy)
- **Ingress**: Rules defining how traffic is routed (path-based, host-based)

**Traffic flow:**
```
Internet → DigitalOcean LB → Ingress Controller Pod → Services → Pods
         ($12/month)       (nginx reverse proxy)   (ClusterIP)
```

**Cost savings:**
- Without Ingress: 5 services = 5 LBs = $60/month
- With Ingress: 1 Ingress Controller LB = $12/month (routes to all 5 services)

**🏭 Industry Best Practice - Ingress:**

**Production Ingress setup:**

**1. Always use Ingress for HTTP/HTTPS** (not LoadBalancer Services)
```yaml
# ❌ Bad: Multiple LoadBalancers
apiVersion: v1
kind: Service
metadata:
  name: app1-lb
spec:
  type: LoadBalancer  # $12/month
---
apiVersion: v1
kind: Service
metadata:
  name: app2-lb
spec:
  type: LoadBalancer  # Another $12/month
# Total: $24/month for 2 apps

# ✅ Good: One Ingress
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: apps-ingress
spec:
  rules:
  - host: app1.example.com
    http:
      paths:
      - path: /
        backend:
          service:
            name: app1-service
            port:
              number: 80
  - host: app2.example.com
    http:
      paths:
      - path: /
        backend:
          service:
            name: app2-service
            port:
              number: 80
# Total: $12/month for unlimited apps
```

**2. Popular Ingress Controllers:**
| Controller | Best For | Pros | Cons |
|------------|----------|------|------|
| **nginx-ingress** | General use | Simple, widely used | Basic features |
| **Traefik** | Modern apps | Auto-discovery, dashboard | Learning curve |
| **HAProxy** | High performance | Very fast, stable | Complex config |
| **AWS ALB** | AWS only | Native AWS integration | Vendor lock-in |

**3. Production features to enable:**
```yaml
metadata:
  annotations:
    # Rate limiting
    nginx.ingress.kubernetes.io/limit-rps: "100"
    
    # CORS
    nginx.ingress.kubernetes.io/enable-cors: "true"
    
    # Timeouts
    nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"
    
    # WebSocket support
    nginx.ingress.kubernetes.io/websocket-services: "chat-service"
    
    # Client body size (file uploads)
    nginx.ingress.kubernetes.io/proxy-body-size: "10m"
```

**4. Always use TLS in production:**
```yaml
spec:
  tls:
  - hosts:
    - app.example.com
    secretName: app-tls-cert  # cert-manager auto-generates
```

**Production checklist:**
- ✅ TLS for all public endpoints
- ✅ Rate limiting enabled
- ✅ CORS configured properly
- ✅ Monitoring ingress metrics
- ✅ WAF rules (if needed)
- ❌ Don't expose admin panels publicly

```bash
# Install via Helm
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/do-loadbalancer-name"="nginx-ingress-lb"

# Verify installation
kubectl get pods -n ingress-nginx
# Should see ingress-nginx-controller pod Running

kubectl get svc -n ingress-nginx
# Should see LoadBalancer service with EXTERNAL-IP

# Get LoadBalancer IP (use this for DNS A records)
kubectl get svc nginx-ingress-ingress-nginx-controller -n ingress-nginx
```

**What Helm does:**
- Installs nginx Ingress Controller as a Deployment
- Creates a LoadBalancer Service (gets DigitalOcean LB)
- Sets up RBAC permissions
- Configures default settings
- **Alternative**: Can use kubectl apply with YAML, but Helm is easier for complex apps

### Deploy Multiple Services with Ingress

**Backend applications:**
```yaml
# save as: multi-app-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-v1
spec:
  replicas: 2
  selector:
    matchLabels:
      app: myapp
      version: v1
  template:
    metadata:
      labels:
        app: myapp
        version: v1
    spec:
      containers:
      - name: app
        image: hashicorp/http-echo
        args:
        - "-text=Hello from App V1"
        - "-listen=:8080"
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: app-v1-service
spec:
  selector:
    app: myapp
    version: v1
  ports:
  - port: 80
    targetPort: 8080
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-v2
spec:
  replicas: 2
  selector:
    matchLabels:
      app: myapp
      version: v2
  template:
    metadata:
      labels:
        app: myapp
        version: v2
    spec:
      containers:
      - name: app
        image: hashicorp/http-echo
        args:
        - "-text=Hello from App V2"
        - "-listen=:8080"
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: app-v2-service
spec:
  selector:
    app: myapp
    version: v2
  ports:
  - port: 80
    targetPort: 8080
```

**Ingress with path-based routing:**
```yaml
# save as: ingress-rules.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /  # Rewrite /v1/foo to /foo
spec:
  ingressClassName: nginx                          # Which Ingress Controller handles this
  rules:
  - host: myapp.example.com                        # Domain name (optional)
    http:
      paths:
      - path: /v1                                  # Route /v1/* to app-v1-service
        pathType: Prefix                           # Prefix match (/v1, /v1/anything)
        backend:
          service:
            name: app-v1-service
            port:
              number: 80
      - path: /v2                                  # Route /v2/* to app-v2-service
        pathType: Prefix
        backend:
          service:
            name: app-v2-service
            port:
              number: 80
```

**pathType options:**
- **Prefix**: Matches path prefix (`/v1` matches `/v1`, `/v1/foo`, `/v1/foo/bar`)
- **Exact**: Exact match only (`/v1` matches `/v1` but not `/v1/foo`)
- **ImplementationSpecific**: Controller-specific matching

**How routing works:**
1. Request hits DigitalOcean LoadBalancer IP
2. LB forwards to Ingress Controller pod
3. Ingress Controller reads Ingress rules
4. Routes based on host + path to correct Service
5. Service routes to Pod

**Example requests:**
- `http://LB-IP/v1` (with Host: myapp.example.com) → app-v1-service
- `http://LB-IP/v2` (with Host: myapp.example.com) → app-v2-service

```bash
kubectl apply -f multi-app-deployment.yaml
kubectl apply -f ingress-rules.yaml

# Get Ingress details
kubectl get ingress
kubectl describe ingress app-ingress

# Test (replace with your LB IP)
INGRESS_IP=$(kubectl get svc nginx-ingress-ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

curl -H "Host: myapp.example.com" http://$INGRESS_IP/v1
curl -H "Host: myapp.example.com" http://$INGRESS_IP/v2
```

### TLS/SSL with cert-manager

**Install cert-manager:**
```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.yaml

# Verify
kubectl get pods -n cert-manager
```

**ClusterIssuer for Let's Encrypt:**
```yaml
# save as: letsencrypt-issuer.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
```

**Ingress with TLS:**
```yaml
# save as: ingress-tls.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress-tls
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - myapp.yourdomain.com
    secretName: myapp-tls-cert
  rules:
  - host: myapp.yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-v1-service
            port:
              number: 80
```

**🏭 Industry Best Practice - TLS/HTTPS:**

**Production TLS setup:**

**1. Always use HTTPS** (never plain HTTP in production)
```yaml
# Force HTTPS redirect
annotations:
  nginx.ingress.kubernetes.io/ssl-redirect: "true"
  nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
```

**2. Use Let's Encrypt with cert-manager** (free, auto-renewing)
```yaml
# Production issuer
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: ops@yourcompany.com  # For expiry notifications
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
    # OR DNS challenge (better for wildcards)
    - dns01:
        cloudflare:
          email: ops@yourcompany.com
          apiTokenSecretRef:
            name: cloudflare-api-token
            key: api-token
```

**3. Staging vs Production:**
```bash
# Test with staging first (no rate limits)
# Let's Encrypt prod: 50 certs/week limit
# Let's Encrypt staging: Unlimited, but not trusted

# Staging for testing
cluster-issuer: "letsencrypt-staging"

# Production after verified
cluster-issuer: "letsencrypt-prod"
```

**4. Wildcard certificates:**
```yaml
# For *.example.com (requires DNS challenge)
tls:
- hosts:
  - "*.example.com"
  - "example.com"
  secretName: wildcard-tls
```

**5. Monitor certificate expiry:**
```yaml
# cert-manager auto-renews at 30 days
# But monitor anyway
- alert: CertificateExpiringSoon
  expr: certmanager_certificate_expiration_timestamp_seconds - time() < 7 * 24 * 3600
```

**Security best practices:**
- ✅ Use TLS 1.2+ only (disable TLS 1.0, 1.1)
- ✅ Strong cipher suites
- ✅ HSTS headers
- ✅ Monitor certificate expiry
- ❌ Never commit TLS private keys to Git
- ❌ Don't use self-signed certs in production

---

## **Part 6: Helm Package Manager**

### Introduction to Helm

**What is Helm?**
Helm is the package manager for Kubernetes. Just as you use `apt` or `yum` for Linux, or `npm` for Node.js, you use `helm` for Kubernetes.

- **Chart**: A package of pre-configured Kubernetes resources (YAML files).
- **Release**: A specific instance of a chart deployed to the cluster.
- **Repository**: A place where charts can be collected and shared.

**Why use Helm?**
1.  **Complexity Management**: Kubernetes apps often require Deployment, Service, Ingress, ConfigMap, Secret, etc. Helm bundles them all.
2.  **Templating**: Instead of hardcoding values, Helm uses templates. You can deploy the same chart to Dev, Staging, and Prod with different configuration values.
3.  **Easy Updates & Rollbacks**: `helm upgrade` updates your app, and `helm rollback` reverts it instantly if something goes wrong.
4.  **Community**: Thousands of ready-to-use charts (Prometheus, MySQL, Redis, etc.) are available on Artifact Hub.

### Helm Architecture

Helm 3 (current version) is client-only (no Tiller server needed).

1.  **Helm Client**: CLI tool that renders templates and communicates with the Kubernetes API.
2.  **Chart**: Directory containing `Chart.yaml`, `values.yaml`, and `templates/`.
3.  **Kubernetes API**: Helm sends the rendered YAMLs to the API server to create resources.

### Using Existing Charts

**1. Add a Repository**
Repositories are where charts are stored. The most popular is Bitnami.

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

**2. Search for a Chart**
```bash
helm search repo bitnami/nginx
```

**3. Install a Chart**
```bash
# Basic install
helm install my-nginx bitnami/nginx

# Install into specific namespace
helm install my-nginx bitnami/nginx --namespace web-server --create-namespace
```

**4. Customize Installation (The `values.yaml` file)**
Every chart comes with default configuration in `values.yaml`. You can override these values.

**Method A: Command line flags (good for simple changes)**
```bash
helm install my-nginx bitnami/nginx --set replicaCount=3 --set service.type=LoadBalancer
```

**Method B: Custom values file (Best Practice)**
First, inspect the default values:
```bash
helm show values bitnami/nginx > default-values.yaml
```

Create your own `my-values.yaml`:
```yaml
replicaCount: 3
service:
  type: LoadBalancer
resources:
  limits:
    cpu: 500m
    memory: 512Mi
```

Install using your file:
```bash
helm install my-nginx bitnami/nginx -f my-values.yaml
```

**5. Manage Releases**
```bash
# List releases
helm list -A

# Upgrade a release (change config or version)
helm upgrade my-nginx bitnami/nginx -f new-values.yaml

# View revision history
helm history my-nginx

# Rollback to previous version
helm rollback my-nginx 1  # Rollback to revision 1
```

### Creating Your Own Charts

Creating a Helm chart allows you to package your application for easy distribution and deployment.

**1. Initialize a New Chart**
Run the following command to generate the standard directory structure:
```bash
helm create my-app
```

**2. Anatomy of a Chart**
Let's explore what was created in the `my-app/` directory:

*   **`Chart.yaml`**: The metadata file. Contains the chart name, version, description, and app version.
    ```yaml
    apiVersion: v2
    name: my-app
    description: A Helm chart for Kubernetes
    type: application
    version: 0.1.0       # The version of the chart itself
    appVersion: "1.16.0" # The version of the application (e.g., nginx version)
    ```

*   **`values.yaml`**: The default configuration values. This is the interface for your users.
    ```yaml
    replicaCount: 1
    image:
      repository: nginx
      pullPolicy: IfNotPresent
      tag: ""
    service:
      type: ClusterIP
      port: 80
    ```

*   **`templates/`**: This directory contains your Kubernetes manifest templates combined with Go template logic.
    *   `deployment.yaml`: Template for the Deployment resource.
    *   `service.yaml`: Template for the Service resource.
    *   `_helpers.tpl`: A place to define reusable template snippets (partials).
    *   `NOTES.txt`: Text displayed to the user after a successful install.

*   **`charts/`**: A directory for managing dependencies (other charts your chart depends on).

**3. Writing Templates (The "Code")**
Helm uses the Go templating language. You inject values from `values.yaml` into your templates using `{{ .Values.path.to.key }}`.

*Example: `templates/deployment.yaml` snippet*
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "my-app.fullname" . }}
  labels:
    {{- include "my-app.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }} # Injected from values.yaml
  selector:
    matchLabels:
      {{- include "my-app.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "my-app.selectorLabels" . | nindent 8 }}
    spec:
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          ports:
            - name: http
              containerPort: {{ .Values.service.port }}
              protocol: TCP
```

**4. Advanced Templating Features**

*   **Pipelines & Functions**: Transform data.
    ```yaml
    # Quote a value to ensure it's treated as a string
    key: {{ .Values.someValue | quote }}

    # Set a default if the value is missing
    tag: {{ .Values.image.tag | default "latest" }}

    # Indent a block of text (useful for embedding YAML chunks)
    {{- toYaml .Values.resources | nindent 12 }}
    ```

*   **Flow Control (If/Else)**: Conditionally create resources or fields.
    ```yaml
    {{- if .Values.ingress.enabled }}
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: {{ include "my-app.fullname" . }}
    spec:
      # ... ingress spec ...
    {{- end }}
    ```

*   **Loops (Range)**: Iterate over lists or maps.
    ```yaml
    env:
      {{- range $key, $val := .Values.env }}
      - name: {{ $key }}
        value: {{ $val | quote }}
      {{- end }}
    ```
    *Corresponding `values.yaml`:*
    ```yaml
    env:
      DB_HOST: "localhost"
      DB_PORT: "5432"
    ```

**5. The `_helpers.tpl` File**
This file defines "named templates" to keep your code DRY (Don't Repeat Yourself).
For example, `{{ include "my-app.fullname" . }}` generates a consistent name for resources (e.g., `release-name-chart-name`).

**6. Debugging & Linting**
Before installing, always verify your chart.

*   **Linting**: Checks for syntax errors and best practices.
    ```bash
    helm lint ./my-app
    ```

*   **Dry Run / Template**: Renders the templates to stdout without installing. This lets you see the final YAML.
    ```bash
    helm template my-release ./my-app --debug
    ```

*   **Dry Run Install**: Simulates an install against the cluster.
    ```bash
    helm install my-release ./my-app --dry-run
    ```

**7. Packaging & Sharing**
Once your chart is ready, you can package it into a `.tgz` file.
```bash
helm package ./my-app
# Output: my-app-0.1.0.tgz
```
You can then upload this file to a Helm repository or share it directly.

### Helm Best Practices

1.  **Keep `values.yaml` simple**: Only expose what needs to be configured.
2.  **Use `_helpers.tpl`**: Put reusable logic (like label generation) in helper templates.
3.  **Document your chart**: Use `README.md` and comments in `values.yaml`.
4.  **Lint your chart**: Run `helm lint ./mychart` to catch errors.
5.  **Dry Run**: Before installing, check what will be generated:
    ```bash
    helm install my-release ./mychart --dry-run --debug
    ```
6.  **Version Control**: Commit your chart source code to Git. Use a Chart Repository (like Harbor or GitHub Pages) for packaged charts.

### Use Case: Express.js API with PostgreSQL

In this real-world example, we will create a Helm chart for a basic Express.js API that connects to a PostgreSQL database. We will then configure it for three environments: **Dev**, **Staging**, and **Production**.

**1. The Application**
We have a simple Express.js app in `basic-6/express-api/app/` that connects to a database using environment variables.

*   `index.js`: The API server.
*   `Dockerfile`: To containerize the app.

**2. The Helm Chart**
The chart is located in `basic-6/express-api/chart/`.

*   **`templates/deployment.yaml`**: Defines the Deployment. It uses a ConfigMap and Secret to inject environment variables.
*   **`templates/service.yaml`**: Exposes the application.
*   **`templates/configmap.yaml`**: Stores non-sensitive config (DB host, port, name).
*   **`templates/secret.yaml`**: Stores sensitive config (DB password).

**3. Environment Configuration**
We use different values files for each environment to override the defaults in `values.yaml`.

*   **`values-dev.yaml`**:
    ```yaml
    replicaCount: 1
    env:
      ENVIRONMENT: "development"
      DB_NAME: "dev_db"
    ```

*   **`values-staging.yaml`**:
    ```yaml
    replicaCount: 2
    env:
      ENVIRONMENT: "staging"
      DB_NAME: "staging_db"
    resources:
      limits:
        cpu: 200m
        memory: 256Mi
    ```

*   **`values-prod.yaml`**:
    ```yaml
    replicaCount: 3
    env:
      ENVIRONMENT: "production"
      DB_NAME: "prod_db"
    resources:
      limits:
        cpu: 500m
        memory: 512Mi
    ```

**4. Deployment Instructions**

First, navigate to the directory:
```bash
cd basic-6/express-api
```

**Prerequisite: Database Setup**
Since our application requires a database, we will install a PostgreSQL instance in each environment using the Bitnami Helm chart.

```bash
# Add the Bitnami repo if you haven't already
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

**Deploy to Development:**
1.  Install PostgreSQL in the `dev` namespace:
    ```bash
    helm install postgres bitnami/postgresql \
      --set auth.postgresPassword="dev_secret_password" \
      --set auth.database="dev_db" \
      --namespace dev --create-namespace
    ```
    *Note: This creates a service named `postgres-postgresql`.*

2.  Deploy the Express API:
    ```bash
    helm upgrade --install express-api-dev ./chart \
      -f ./chart/values-dev.yaml \
      --set env.DB_PASSWORD="dev_secret_password" \
      --set env.DB_HOST="postgres-postgresql" \
      --namespace dev --create-namespace
    ```

**Deploy to Staging:**
1.  Install PostgreSQL in the `staging` namespace:
    ```bash
    helm install postgres bitnami/postgresql \
      --set auth.postgresPassword="staging_secret_password" \
      --set auth.database="staging_db" \
      --namespace staging --create-namespace
    ```

2.  Deploy the Express API:
    ```bash
    helm upgrade --install express-api-staging ./chart \
      -f ./chart/values-staging.yaml \
      --set env.DB_PASSWORD="staging_secret_password" \
      --set env.DB_HOST="postgres-postgresql" \
      --namespace staging --create-namespace
    ```

**Deploy to Production:**
1.  Install PostgreSQL in the `prod` namespace:
    ```bash
    helm install postgres bitnami/postgresql \
      --set auth.postgresPassword="prod_strong_password" \
      --set auth.database="prod_db" \
      --namespace prod --create-namespace
    ```

2.  Deploy the Express API:
    ```bash
    helm upgrade --install express-api-prod ./chart \
      -f ./chart/values-prod.yaml \
      --set env.DB_PASSWORD="prod_strong_password" \
      --set env.DB_HOST="postgres-postgresql" \
      --namespace prod --create-namespace
    ```

**5. Verification**
Check the pods in the production namespace:
```bash
kubectl get pods -n prod
```
You should see 3 replicas running with higher resource limits than dev.

## **Part 7: Observability & Monitoring**

### Install Prometheus & Grafana Stack

**Why Observability Matters:**
- **Monitoring**: Know when things break (alerts)
- **Troubleshooting**: Understand why things broke (metrics + logs)
- **Capacity planning**: Know when to scale
- **Performance optimization**: Identify bottlenecks

**The Observability Trio:**
1. **Metrics**: Time-series data (CPU usage, request rate, latency)
2. **Logs**: Event records (application logs, errors)
3. **Traces**: Request flow through distributed systems

**Prometheus + Grafana:**
- **Prometheus**: Metrics collection and alerting
- **Grafana**: Visualization dashboards
- **kube-prometheus-stack**: Pre-configured bundle with both + exporters

```bash
# Add Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install kube-prometheus-stack
helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set prometheus.prometheusSpec.retention=7d \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=20Gi \
  --set grafana.adminPassword='AdminPass123!'

# Verify installation
kubectl get pods -n monitoring
kubectl get svc -n monitoring
```

**What gets installed:**
- **Prometheus**: Metrics database and scraper
- **Grafana**: Dashboard UI
- **Alertmanager**: Alert routing and notifications
- **Node Exporter**: Hardware/OS metrics (CPU, memory, disk)
- **Kube-state-metrics**: Kubernetes object metrics (deployments, pods, services)
- **Pre-configured dashboards**: Cluster overview, pod metrics, node metrics
- **ServiceMonitors**: Automatic discovery of metric endpoints

**Resource usage:**
- ~1-2GB memory for Prometheus
- ~500MB for Grafana
- 20GB storage for metrics (7 days retention)

**🏭 Industry Best Practice - Observability:**

**Production monitoring stack:**

**1. The Four Golden Signals** (Google SRE)
```yaml
# What to monitor:
1. Latency    # How long requests take
2. Traffic    # Request volume
3. Errors     # Error rate
4. Saturation # Resource utilization
```

**2. Metrics retention strategy:**
```yaml
# Multi-tier retention
prometheus:
  prometheusSpec:
    retention: 15d              # Recent detailed metrics
    
# Long-term storage (Thanos/Cortex)
thanos:
  objstore:
    retention: 1y               # Aggregated metrics
```

**3. Alert pyramid:**
```
          Critical (Page on-call)
          │  - Service down
          │  - Data loss risk
     _____|_____
    |           |
    |  Warning  |  (Ticket next day)
    |  - High CPU
    |  - Disk 80% full
    |___________|____
   |                 |
   |   Information   |  (Dashboard only)
   |   - Deployment  |
   |   - Scale event |
   |_________________|
```

**4. Production alerting rules:**
```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: production-alerts
spec:
  groups:
  - name: availability
    interval: 30s
    rules:
    # Critical: Service down
    - alert: ServiceDown
      expr: up{job="my-service"} == 0
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "Service {{ $labels.instance }} is down"
    
    # Warning: High error rate
    - alert: HighErrorRate
      expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
      for: 10m
      labels:
        severity: warning
      annotations:
        summary: "Error rate above 5%"
```

**5. SLO/SLA monitoring:**
```yaml
# Define SLOs (Service Level Objectives)
- SLO: 99.9% uptime (43 minutes/month downtime budget)
- SLO: 95% requests < 200ms
- SLO: <1% error rate

# Track error budget
error_budget_remaining = 1 - (actual_uptime / target_uptime)
```

**6. Distributed tracing** (for microservices):
```bash
# Add Jaeger or Tempo for request tracing
helm install jaeger jaegertracing/jaeger

# See request flow: API → Auth → DB → Cache
# Identify bottlenecks
```

**7. Log aggregation:**
```yaml
# Options:
1. ELK Stack (Elasticsearch, Logstash, Kibana) - Heavy but powerful
2. Loki + Promtail - Lightweight, Prometheus-like
3. Cloud solutions - CloudWatch, Stackdriver

# Production: Use Loki (cost-effective)
helm install loki grafana/loki-stack \
  --set promtail.enabled=true \
  --set loki.persistence.enabled=true \
  --set loki.persistence.size=100Gi
```

**Production observability checklist:**
- ✅ Metrics: Prometheus + Grafana
- ✅ Logs: Loki or ELK
- ✅ Traces: Jaeger (if microservices)
- ✅ Alerting: PagerDuty/Opsgenie integration
- ✅ Dashboards: Per-service + cluster overview
- ✅ On-call runbooks linked to alerts
- ✅ SLO tracking dashboards
- ❌ Don't alert on everything (alert fatigue)
- ❌ Don't ignore warning alerts (they become critical)

**Access Grafana:**
```bash
# Port forward to local machine
kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80

# Visit http://localhost:3000
# Username: admin
# Password: AdminPass123!
```

**Exploring Grafana:**
- Navigate to Dashboards → Browse
- Pre-installed dashboards:
  - **Kubernetes / Compute Resources / Cluster**: Overall cluster health
  - **Kubernetes / Compute Resources / Namespace (Pods)**: Pod-level metrics
  - **Kubernetes / Compute Resources / Node (Pods)**: Node-level metrics
- Key metrics to watch:
  - CPU/Memory usage vs requests/limits
  - Pod restart counts
  - Network I/O
  - Disk usage

**port-forward limitations:**
- Only works while command is running
- Only accessible from your machine
- For production: Use Ingress with TLS, or DigitalOcean VPN

### Custom Application Metrics

**Sample app with Prometheus metrics:**
```yaml
# save as: metrics-app.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: metrics-demo
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: metrics-demo
  template:
    metadata:
      labels:
        app: metrics-demo
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/metrics"
    spec:
      containers:
      - name: app
        image: quay.io/brancz/prometheus-example-app:v0.3.0
        ports:
        - containerPort: 8080
          name: metrics
---
apiVersion: v1
kind: Service
metadata:
  name: metrics-demo
  labels:
    app: metrics-demo
spec:
  ports:
  - port: 8080
    name: metrics
  selector:
    app: metrics-demo
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: metrics-demo
  labels:
    app: metrics-demo
spec:
  selector:
    matchLabels:
      app: metrics-demo
  endpoints:
  - port: metrics
    interval: 30s
```

```bash
kubectl apply -f metrics-app.yaml

# Verify ServiceMonitor
kubectl get servicemonitor

# Access Prometheus UI
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090

# Query: rate(http_requests_total[5m])
```

### Logging with EFK Stack (Elasticsearch, Fluentd, Kibana)

**Simplified logging with Loki (lighter alternative):**
```bash
# Install Loki stack
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

helm install loki grafana/loki-stack \
  --namespace monitoring \
  --set grafana.enabled=false \
  --set promtail.enabled=true

# Loki is already integrated with Grafana from kube-prometheus-stack
```

**View logs in Grafana:**
- Navigate to Grafana → Explore
- Select Loki as data source
- Query: `{namespace="default"}`

---

## **Part 8: Advanced Kubernetes Concepts**

### Namespaces & Resource Quotas

**What are Namespaces?**
- Virtual clusters within a physical cluster
- Logical separation for multi-tenancy (dev, staging, prod teams)
- Scope for names (same resource name can exist in different namespaces)
- Can apply policies (RBAC, Network Policies, Resource Quotas) per namespace

**Default namespaces:**
- **default**: Where resources go if you don't specify a namespace
- **kube-system**: Kubernetes system components (DNS, dashboard, etc.)
- **kube-public**: Publicly readable (rare usage)
- **kube-node-lease**: Node heartbeats for performance

**Create namespaces:**
```bash
kubectl create namespace development
kubectl create namespace staging
kubectl create namespace production
```

**ResourceQuota:**
```yaml
# save as: dev-quota.yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: dev-quota
  namespace: development
spec:
  hard:
    requests.cpu: "4"           # Max 4 CPU cores requested across all pods
    requests.memory: 8Gi        # Max 8GB memory requested
    limits.cpu: "8"             # Max 8 CPU cores limit
    limits.memory: 16Gi         # Max 16GB memory limit
    pods: "10"                  # Max 10 pods in namespace
    services.loadbalancers: "2" # Max 2 LoadBalancer services
---
apiVersion: v1
kind: LimitRange
metadata:
  name: dev-limits
  namespace: development
spec:
  limits:
  - max:                        # Maximum per container
      cpu: "2"
      memory: 2Gi
    min:                        # Minimum per container
      cpu: 100m
      memory: 128Mi
    default:                    # Default limits if not specified
      cpu: 500m
      memory: 512Mi
    defaultRequest:             # Default requests if not specified
      cpu: 200m
      memory: 256Mi
    type: Container
```

**ResourceQuota vs LimitRange:**
- **ResourceQuota**: Limits total resources for entire namespace
- **LimitRange**: Sets default and max/min per pod/container
- Both prevent resource exhaustion and runaway costs

**Why use these?**
- Prevent one team from consuming all cluster resources
- Enforce fair resource distribution
- Set guardrails for developers (can't create 100 pods accidentally)
- Budget control in multi-tenant environments

```bash
kubectl apply -f dev-quota.yaml
kubectl describe quota -n development
kubectl describe limits -n development
```

### RBAC (Role-Based Access Control)

**What is RBAC?**
- Authorization system controlling what users/apps can do in Kubernetes
- Follows principle of least privilege (grant minimum permissions needed)
- Uses: Multi-user clusters, service accounts, CI/CD pipelines

**RBAC Components:**
1. **Subject**: Who (User, Group, ServiceAccount)
2. **Verb**: What action (get, list, create, delete, update)
3. **Resource**: What object (pods, services, deployments)
4. **Role/ClusterRole**: Set of permissions
5. **RoleBinding/ClusterRoleBinding**: Binds subject to role

**Role vs ClusterRole:**
- **Role**: Namespace-scoped (permissions in one namespace)
- **ClusterRole**: Cluster-wide (all namespaces, or cluster resources like nodes)

**Create service account and role:**
```yaml
# save as: rbac-example.yaml
apiVersion: v1
kind: ServiceAccount                # Identity for pods to use
metadata:
  name: app-reader
  namespace: development
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: development
rules:
- apiGroups: [""]                   # "" = core API group
  resources: ["pods", "pods/log"]   # What resources
  verbs: ["get", "list", "watch"]   # What actions (read-only)
- apiGroups: [""]
  resources: ["services"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding                   # Connects subject to role
metadata:
  name: read-pods
  namespace: development
subjects:
- kind: ServiceAccount              # Who gets permissions
  name: app-reader
  namespace: development
roleRef:
  kind: Role                        # Which role to grant
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

**Common verbs:**
- **Read**: get, list, watch
- **Write**: create, update, patch
- **Delete**: delete, deletecollection
- **Special**: * (all), exec (kubectl exec), port-forward

**Use cases:**
- **CI/CD**: Service account with deploy permissions only
- **Monitoring**: Read-only access to metrics
- **Developers**: Create pods but not delete PVCs
- **Auditing**: List/watch everything but not modify

```bash
kubectl apply -f rbac-example.yaml

# Test permissions
kubectl auth can-i get pods --as=system:serviceaccount:development:app-reader -n development
# yes

kubectl auth can-i delete pods --as=system:serviceaccount:development:app-reader -n development
# no
```

### Horizontal Pod Autoscaler (HPA)

**What is HPA?**
- Automatically scales Deployment/ReplicaSet based on metrics
- Adjusts replica count to meet target metric (CPU, memory, custom metrics)
- Prevents over/under-provisioning
- Responds to traffic spikes automatically

**How it works:**
1. HPA checks metrics every 15 seconds (default)
2. Compares current metric to target
3. Calculates desired replicas: `ceil[currentReplicas * (currentMetric / targetMetric)]`
4. Scales up/down gradually (respects cooldown periods)

**Requirements:**
- Metrics Server must be installed (DOKS has it by default)
- Pods must have resource requests defined
- Target resource must be scalable (Deployment, ReplicaSet, StatefulSet)

**Deploy app with HPA:**
```yaml
# save as: hpa-demo.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: php-apache
spec:
  replicas: 1
  selector:
    matchLabels:
      app: php-apache
  template:
    metadata:
      labels:
        app: php-apache
    spec:
      containers:
      - name: php-apache
        image: registry.k8s.io/hpa-example
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 200m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 256Mi
---
apiVersion: v1
kind: Service
metadata:
  name: php-apache
spec:
  ports:
  - port: 80
  selector:
    app: php-apache
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: php-apache
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: php-apache
  minReplicas: 1
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 70
```

```bash
kubectl apply -f hpa-demo.yaml

# Watch HPA make decisions
kubectl get hpa -w

# Generate load in one terminal
kubectl run -it load-generator --rm --image=busybox --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://php-apache; done"

# In another terminal, watch scaling happen
kubectl get hpa php-apache -w
kubectl get pods -l app=php-apache -w
```

**What you'll observe:**
1. Initial: 1 pod, CPU ~0%
2. Load starts: CPU climbs to 100%+
3. HPA scales up: 2 pods → 4 pods → eventually 10 pods
4. CPU per pod drops: Distributed across more pods
5. Stop load: CPU drops below target
6. HPA scales down: Gradually reduces to minimum replicas (5 min cooldown)

**Scaling calculation example:**
- Current: 3 pods at 80% CPU
- Target: 50% CPU
- Desired replicas: `ceil[3 * (80 / 50)]` = `ceil[4.8]` = 5 pods

**Best practices:**
- Set reasonable min/max replicas
- Don't autoscale based on memory (risky - can cause OOMKills)
- Use custom metrics for better scaling (request rate, queue depth)
- Combine with Cluster Autoscaler for node scaling

**🏭 Industry Best Practice - Autoscaling:**

**Production autoscaling strategy:**

**1. HPA Configuration:**
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: production-app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: production-app
  minReplicas: 3              # Never go below 3 (HA)
  maxReplicas: 100            # Cap to control costs
  behavior:                   # Control scale-up/down speed
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
      - type: Percent
        value: 100            # Double pods every 60s max
        periodSeconds: 60
      - type: Pods
        value: 4              # Or add 4 pods every 60s
        periodSeconds: 60
      selectPolicy: Max
    scaleDown:
      stabilizationWindowSeconds: 300  # Wait 5min before scaling down
      policies:
      - type: Percent
        value: 50             # Remove 50% every 5min max
        periodSeconds: 60
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70  # Scale when avg CPU > 70%
  - type: Pods
    pods:
      metric:
        name: http_requests_per_second
      target:
        type: AverageValue
        averageValue: "1000"  # Custom metric
```

**2. Custom Metrics (Better than CPU/Memory):**
```yaml
# Scale based on application metrics
metrics:
- type: Pods
  pods:
    metric:
      name: http_requests_per_second
    target:
      type: AverageValue
      averageValue: "1000"     # Scale when > 1000 req/s per pod

# Or queue depth
- type: Object
  object:
    metric:
      name: queue_depth
    target:
      type: Value
      value: "100"             # Scale when queue > 100
```

**3. Vertical Pod Autoscaler (VPA):**
```yaml
# Automatically adjusts resource requests/limits
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: app-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: app
  updatePolicy:
    updateMode: "Auto"         # Auto-adjust resources
  resourcePolicy:
    containerPolicies:
    - containerName: app
      minAllowed:
        cpu: 100m
        memory: 128Mi
      maxAllowed:
        cpu: 2
        memory: 2Gi
```

**⚠️ WARNING: Don't use HPA + VPA on same metric!**
- HPA: Scales replicas based on CPU
- VPA: Changes CPU requests
- Together: Conflict! (HPA scales up, VPA increases CPU, HPA scales down...)
- Solution: Use HPA for CPU, VPA for memory OR use custom metrics

**4. Cluster Autoscaler configuration:**
```yaml
# DigitalOcean node pool autoscaling
doctl kubernetes cluster node-pool update learn-k8s worker-pool \
  --auto-scale \
  --min-nodes 3 \
  --max-nodes 20

# Autoscaler behavior:
# - Scale up: When pods can't be scheduled (Pending)
# - Scale down: When nodes are < 50% utilized for 10+ minutes
# - Never scales below min-nodes
```

**5. Production autoscaling checklist:**
- ✅ Min replicas ≥ 3 for HA
- ✅ Max replicas set (cost control)
- ✅ PodDisruptionBudget configured
- ✅ Resource requests set accurately
- ✅ Slow scale-down (avoid thrashing)
- ✅ Fast scale-up (handle traffic spikes)
- ✅ Custom metrics when possible
- ✅ Load testing to verify behavior
- ❌ Don't autoscale stateful apps without careful planning
- ❌ Don't set min-replicas=1 (no HA)

**6. PodDisruptionBudget (Critical for autoscaling):**
```yaml
# Ensure availability during scaling
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: app-pdb
spec:
  minAvailable: 2            # Always keep 2 pods running
  selector:
    matchLabels:
      app: production-app
```

**Real-world example:**
```yaml
# E-commerce site scaling strategy:
# - Min 5 replicas (handle normal traffic)
# - Max 50 replicas (Black Friday spike)
# - Scale on: requests/second (not CPU)
# - PDB: Keep 3 pods minimum (rolling updates)
# - Cluster autoscaler: 3-20 nodes
# - Cost: $12-80/month (scales with traffic)
```

### Cluster Autoscaler

**What is Cluster Autoscaler?**
- Automatically adds/removes nodes based on resource needs
- Monitors pods that can't be scheduled (Pending due to insufficient resources)
- **HPA** scales pods, **Cluster Autoscaler** scales nodes
- Typically used together for complete autoscaling

**Enable DOKS cluster autoscaler:**
```bash
# Update node pool to enable autoscaling
doctl kubernetes cluster node-pool update learn-k8s worker-pool \
  --auto-scale \
  --min-nodes 3 \
  --max-nodes 10

# Verify autoscaler is running
kubectl get pods -n kube-system | grep autoscaler
```

**How it works together:**
1. **HPA** creates more pods due to high CPU
2. Pods go to **Pending** state (not enough node resources)
3. **Cluster Autoscaler** sees pending pods
4. Adds new nodes (within min-max range)
5. Pending pods get scheduled to new nodes
6. When load decreases: HPA scales down pods → Nodes become underutilized → Cluster Autoscaler removes nodes

**Cost implications:**
- More nodes = higher cost
- Set reasonable max-nodes to control budget
- DigitalOcean bills hourly, partial hours rounded up
- Scale-down delay: 10 minutes (prevents thrashing)

---

## **Part 9: CI/CD & Production Best Practices**

### GitOps with GitHub Actions

**What is GitOps?**
- Git as single source of truth for infrastructure and applications
- Changes made via Git commits (pull requests, reviews, approvals)
- Automated pipelines deploy from Git automatically
- Declarative configuration (describe desired state, not steps)

**Benefits:**
- Version control for infrastructure
- Audit trail (who changed what, when)
- Easy rollbacks (git revert)
- Collaboration via pull requests
- Eliminates manual kubectl commands in production

**GitHub Actions workflow:**
```yaml
# save as: .github/workflows/deploy.yml
name: Deploy to DOKS

on:
  push:
    branches: [ main ]

env:
  CLUSTER_NAME: learn-k8s
  IMAGE_NAME: myapp

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    - name: Log in to DigitalOcean Container Registry
      uses: docker/login-action@v3
      with:
        registry: registry.digitalocean.com
        username: ${{ secrets.DIGITALOCEAN_TOKEN }}
        password: ${{ secrets.DIGITALOCEAN_TOKEN }}
    
    - name: Build and push Docker image
      uses: docker/build-push-action@v5
      with:
        context: .
        push: true
        tags: |
          registry.digitalocean.com/${{ secrets.REGISTRY_NAME }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
          registry.digitalocean.com/${{ secrets.REGISTRY_NAME }}/${{ env.IMAGE_NAME }}:latest
    
    - name: Install doctl
      uses: digitalocean/action-doctl@v2
      with:
        token: ${{ secrets.DIGITALOCEAN_TOKEN }}
    
    - name: Configure kubectl
      run: |
        doctl kubernetes cluster kubeconfig save ${{ env.CLUSTER_NAME }}
    
    - name: Deploy to Kubernetes
      run: |
        kubectl set image deployment/myapp \
          myapp=registry.digitalocean.com/${{ secrets.REGISTRY_NAME }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
        kubectl rollout status deployment/myapp
```

### Security Best Practices

**Pod Security Standards:**
```yaml
# save as: secure-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-app
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 2000
    seccompProfile:
      type: RuntimeDefault
  
  containers:
  - name: app
    image: nginx:1.25
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop:
        - ALL
        add:
        - NET_BIND_SERVICE
    volumeMounts:
    - name: cache
      mountPath: /var/cache/nginx
    - name: run
      mountPath: /var/run
  
  volumes:
  - name: cache
    emptyDir: {}
  - name: run
    emptyDir: {}
```

**NetworkPolicy:**
```yaml
# save as: network-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-network-policy
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: database
    ports:
    - protocol: TCP
      port: 5432
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53
```

### Backup & Disaster Recovery

**Install Velero for backups:**
```bash
# Create DigitalOcean Spaces (S3-compatible storage)
# Note: Create via DigitalOcean console first

# Create credentials file
cat > credentials-velero <<EOF
[default]
aws_access_key_id=YOUR_SPACES_ACCESS_KEY
aws_secret_access_key=YOUR_SPACES_SECRET_KEY
EOF

# Install Velero CLI
# macOS
brew install velero

# Linux
# Fetch latest version
VELERO_VERSION=$(curl -s https://api.github.com/repos/vmware-tanzu/velero/releases/latest | grep tag_name | cut -d '"' -f 4)
wget "https://github.com/vmware-tanzu/velero/releases/download/${VELERO_VERSION}/velero-${VELERO_VERSION}-linux-amd64.tar.gz"
tar -zxvf velero-${VELERO_VERSION}-linux-amd64.tar.gz
sudo mv velero-${VELERO_VERSION}-linux-amd64/velero /usr/local/bin/

# Install Velero in cluster
velero install \
  --provider aws \
  --plugins velero/velero-plugin-for-aws:v1.8.0 \
  --bucket k8s-backups \
  --secret-file ./credentials-velero \
  --backup-location-config region=nyc3,s3ForcePathStyle="true",s3Url=https://nyc3.digitaloceanspaces.com \
  --snapshot-location-config region=nyc3

# Create backup
velero backup create full-backup-$(date +%Y%m%d)

# Schedule daily backups
velero schedule create daily-backup --schedule="0 2 * * *"

# List backups
velero backup get

# Restore from backup
velero restore create --from-backup full-backup-20241125
```

---

## **Capstone Project: Deploy a Complete Microservices Application**

### Project Overview
Deploy a multi-tier e-commerce application with:
- Frontend (React)
- Backend API (Node.js)
- Database (PostgreSQL)
- Cache (Redis)
- Message Queue (RabbitMQ)

**Complete deployment:**
```yaml
# save as: ecommerce-app.yaml
---
# PostgreSQL StatefulSet
apiVersion: v1
kind: Secret
metadata:
  name: postgres-secret
stringData:
  password: "SecureDbPass123!"
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: postgres
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:16
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_DB
          value: ecommerce
        - name: POSTGRES_USER
          value: admin
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: password
        volumeMounts:
        - name: postgres-data
          mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
  - metadata:
      name: postgres-data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: do-block-storage
      resources:
        requests:
          storage: 10Gi
---
apiVersion: v1
kind: Service
metadata:
  name: postgres
spec:
  clusterIP: None
  selector:
    app: postgres
  ports:
  - port: 5432
---
# Redis Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        ports:
        - containerPort: 6379
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
---
apiVersion: v1
kind: Service
metadata:
  name: redis
spec:
  selector:
    app: redis
  ports:
  - port: 6379
---
# Backend API
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: api
        image: your-registry/backend-api:latest
        ports:
        - containerPort: 3000
        env:
        - name: DATABASE_URL
          value: "postgresql://admin:$(POSTGRES_PASSWORD)@postgres:5432/ecommerce"
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: password
        - name: REDIS_URL
          value: "redis://redis:6379"
        - name: NODE_ENV
          value: "production"
        resources:
          requests:
            memory: "256Mi"
            cpu: "200m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 10
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: backend
spec:
  selector:
    app: backend
  ports:
  - port: 80
    targetPort: 3000
---
# Frontend
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: your-registry/frontend:latest
        ports:
        - containerPort: 80
        env:
        - name: API_URL
          value: "http://backend"
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
---
apiVersion: v1
kind: Service
metadata:
  name: frontend
spec:
  selector:
    app: frontend
  ports:
  - port: 80
---
# Ingress
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ecommerce-ingress
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - ecommerce.yourdomain.com
    secretName: ecommerce-tls
  rules:
  - host: ecommerce.yourdomain.com
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: backend
            port:
              number: 80
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend
            port:
              number: 80
---
# HPA for backend
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: backend-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: backend
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

---

## **Useful Commands Reference**

```bash
# Cluster management
doctl kubernetes cluster list
doctl kubernetes cluster get learn-k8s
doctl kubernetes cluster delete learn-k8s

# Context switching
kubectl config get-contexts
kubectl config use-context do-nyc1-learn-k8s

# Resource management
kubectl get all -A
kubectl top nodes
kubectl top pods
kubectl describe <resource> <name>

# Debugging
kubectl logs <pod> -f
kubectl logs <pod> -c <container>
kubectl exec -it <pod> -- /bin/bash
kubectl port-forward <pod> 8080:80
kubectl debug <pod> -it --image=busybox

# Cleanup
kubectl delete -f <file>.yaml
kubectl delete deployment,service,ingress <name>
helm uninstall <release>
```

---

## **Cost Optimization Tips**

1. **Destroy cluster when not learning:**
   ```bash
   doctl kubernetes cluster delete learn-k8s
   ```

2. **Use smaller node sizes for learning:**
   - `s-2vcpu-2gb` for basic workloads
   - Scale up only when testing autoscaling

3. **Monitor LoadBalancer usage:**
   - Each LoadBalancer = $12/month
   - Use single Ingress controller instead of multiple LoadBalancers

4. **Clean up unused volumes:**
   ```bash
   kubectl get pv
   doctl compute volume list
   ```

---

## **Additional Resources**

- **DigitalOcean Kubernetes Docs:** https://docs.digitalocean.com/products/kubernetes/
- **Kubernetes Official Docs:** https://kubernetes.io/docs/
- **kubectl Cheat Sheet:** https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- **Helm Documentation:** https://helm.sh/docs/
- **CNCF Landscape:** https://landscape.cncf.io/

---

## **Cleaning Up DigitalOcean Resources**

### Understanding What Gets Deleted (and What Doesn't)

**When you delete a DOKS cluster, Kubernetes automatically deletes:**
- ✅ Worker node droplets (the virtual machines running your workloads)
- ✅ Node pool configurations
- ✅ Cluster control plane (managed by DigitalOcean, always free)
- ✅ Default cluster networking (VPC if auto-created)

**What does NOT get deleted automatically (and will continue costing money):**
- ❌ **LoadBalancers** created by Services with `type: LoadBalancer` ($12/month each)
- ❌ **Block Storage Volumes** created by PersistentVolumeClaims ($0.10/GB/month)
- ❌ **Container Registry** and stored images (if you created one)
- ❌ **Spaces** (object storage) used for backups like Velero
- ❌ **Snapshots** if you created any for backup purposes
- ❌ **Floating IPs** if assigned (though rare in DOKS setups)

**Why this matters:**
- Forgetting to delete these resources can result in unexpected charges
- A single LoadBalancer left running = $12/month = $144/year
- Multiple PVCs with large volumes can add up quickly

### Step 1: Clean Up Kubernetes Resources First

**Before deleting the cluster, clean up resources that create DigitalOcean infrastructure:**

```bash
# Delete all LoadBalancer services (prevents orphaned load balancers)
kubectl delete svc --all --all-namespaces --field-selector spec.type=LoadBalancer

# Or delete specific LoadBalancer services you know about
kubectl delete svc nginx-loadbalancer
kubectl delete svc hello-service
kubectl delete svc -n ingress-nginx nginx-ingress-ingress-nginx-controller

# View what will be deleted
kubectl get svc --all-namespaces --field-selector spec.type=LoadBalancer
```

**What this does:**
- Tells Kubernetes to delete LoadBalancer Services
- Kubernetes tells DigitalOcean to delete the associated load balancers
- Prevents "orphaned" load balancers that cost money but aren't connected to anything

**For PersistentVolumeClaims (optional - if you want to preserve data):**

```bash
# List all PVCs to see what you have
kubectl get pvc --all-namespaces

# Delete specific PVCs (deletes underlying DigitalOcean volumes)
kubectl delete pvc app-data-pvc

# Delete all PVCs in a namespace
kubectl delete pvc --all -n default

# If using StatefulSets, PVCs may not auto-delete:
kubectl get pvc -l app=mongodb
kubectl delete pvc mongo-data-mongodb-0 mongo-data-mongodb-1 mongo-data-mongodb-2
```

**Understanding PVC deletion:**
- Default behavior: PVC deleted → PV deleted → DigitalOcean volume deleted
- With `persistentVolumeReclaimPolicy: Retain`: Volume kept for manual recovery
- **Important**: Data is permanently lost when volumes are deleted
- **Backup first** if data is important (use Velero or manual backups)

### Step 2: Delete the Kubernetes Cluster

**Delete the entire cluster:**

```bash
# List your clusters to confirm the name
doctl kubernetes cluster list

# Delete the cluster (will prompt for confirmation)
doctl kubernetes cluster delete learn-k8s

# Force delete without confirmation (use with caution)
doctl kubernetes cluster delete learn-k8s --force
```

**What happens during cluster deletion:**
1. All pods are terminated immediately
2. Worker node droplets are destroyed
3. Cluster control plane is removed
4. Associated VPC networking is cleaned up (if auto-created)
5. **Takes 2-5 minutes** to complete

**Note:** This does NOT delete LoadBalancers or Block Storage volumes you created!

### Step 3: Verify and Delete Orphaned Load Balancers

**Check for remaining load balancers:**

```bash
# List all load balancers
doctl compute load-balancer list

# You'll see output like:
# ID          IP              Name              Status    Created At
# 123456789   165.227.x.x     nginx-lb          active    2024-11-20T10:30:00Z
# 987654321   164.90.x.x      ingress-nginx-lb  active    2024-11-22T14:15:00Z
```

**Delete specific load balancers:**

```bash
# Delete by ID
doctl compute load-balancer delete 123456789

# Or delete by name (if you know it)
doctl compute load-balancer list --format ID,Name
doctl compute load-balancer delete <id>

# Force delete without confirmation
doctl compute load-balancer delete 123456789 --force
```

**Why orphaned load balancers exist:**
- You deleted the cluster before deleting LoadBalancer Services
- Kubernetes couldn't clean up because cluster was already gone
- DigitalOcean doesn't automatically delete them (safety feature)

### Step 4: Delete Orphaned Block Storage Volumes

**Check for remaining volumes:**

```bash
# List all volumes
doctl compute volume list

# You'll see output like:
# ID                                      Name                    Size    Region  Attached To
# abc123-def456-ghi789                    pvc-abc123-xyz456       10 GiB  nyc1    
# xyz789-uvw456-rst123                    pvc-mongo-data-0        20 GiB  nyc1    
```

**Understanding the output:**
- **Attached To** is empty → Volume is orphaned (not attached to any droplet)
- These continue costing money even though they're not being used

**Delete specific volumes:**

```bash
# Delete by ID
doctl compute volume delete abc123-def456-ghi789

# Force delete without confirmation
doctl compute volume delete abc123-def456-ghi789 --force
```

**Delete all orphaned volumes (advanced):**

```bash
# List volumes with no attachments and delete them
doctl compute volume list --format ID,Name,DropletIDs | grep -v "DROPLET IDS" | awk '$3 == "" {print $1}' | xargs -I {} doctl compute volume delete {} --force
```

**What this command does:**
1. Lists all volumes with their droplet attachments
2. Filters for volumes with empty "DropletIDs" (orphaned)
3. Extracts the volume IDs
4. Deletes each orphaned volume
⚠️ **Warning**: This deletes ALL orphaned volumes - make sure you have backups!

### Step 5: Delete Container Registry (if created)

**Check if you have a registry:**

```bash
# List container registries
doctl registry list

# List repositories in your registry
doctl registry repository list

# List tags for a specific repository
doctl registry repository list-tags <repository-name>
```

**Delete registry images:**

```bash
# Delete specific tag
doctl registry repository delete-tag <repository-name> <tag>

# Delete entire repository
doctl registry repository delete <repository-name>

# Delete the entire registry
doctl registry delete <registry-name>
```

**Understanding registry costs:**
- Basic plan: $5/month (500MB storage)
- Professional: $20/month (100GB storage)
- If you're not using it, delete it to avoid monthly charges

### Step 6: Delete Spaces/Object Storage (if used)

**If you set up Velero or used Spaces for backups:**

```bash
# List Spaces (requires s3cmd or DigitalOcean web console)
# Via web console:
# 1. Navigate to https://cloud.digitalocean.com/spaces
# 2. Select your Space
# 3. Click Settings → Destroy
```

**Spaces pricing:**
- $5/month for 250GB storage + 1TB outbound transfer
- Additional storage: $0.02/GB/month
- If you created a Space for learning, delete it

### Step 7: Clean Up Local Kubeconfig

**Remove cluster configuration from local kubectl config:**

```bash
# Option 1: Use doctl (easiest)
doctl kubernetes cluster kubeconfig remove learn-k8s

# Option 2: Manual kubectl commands
kubectl config get-contexts
kubectl config delete-context do-sgp1-learn-k8s
kubectl config delete-cluster do-sgp1-learn-k8s
kubectl config delete-user do-sgp1-learn-k8s-admin
```

**Verify cleanup:**

```bash
# Check remaining contexts
kubectl config get-contexts

# If you have other clusters, switch to them
kubectl config use-context <other-context-name>

# If no other clusters, kubectl commands will fail (expected)
```

### Automated Cleanup Script

**Save this as `cleanup-doks.sh` for future use:**

```bash
#!/bin/bash
# Comprehensive DOKS cleanup script
# Usage: ./cleanup-doks.sh learn-k8s

set -e  # Exit on error

CLUSTER_NAME=${1:-learn-k8s}

echo "🧹 Starting cleanup for cluster: $CLUSTER_NAME"
echo ""

# Step 1: Delete LoadBalancer services
echo "📋 Step 1: Cleaning up LoadBalancer services..."
if kubectl config get-contexts | grep -q $CLUSTER_NAME; then
  echo "  Deleting LoadBalancer services..."
  kubectl delete svc --all --all-namespaces --field-selector spec.type=LoadBalancer --ignore-not-found
  sleep 10  # Give time for load balancers to be removed
else
  echo "  ⚠️  Cluster context not found, skipping Kubernetes cleanup"
fi

# Step 2: Delete the cluster
echo ""
echo "📋 Step 2: Deleting cluster..."
doctl kubernetes cluster delete $CLUSTER_NAME --force
echo "  ⏳ Waiting for cluster deletion to complete..."
sleep 30

# Step 3: Delete orphaned load balancers
echo ""
echo "📋 Step 3: Checking for orphaned load balancers..."
LB_COUNT=$(doctl compute load-balancer list --format ID --no-header | wc -l)
if [ $LB_COUNT -gt 0 ]; then
  echo "  Found $LB_COUNT load balancer(s)"
  doctl compute load-balancer list --format ID --no-header | while read lb_id; do
    echo "  Deleting load balancer: $lb_id"
    doctl compute load-balancer delete $lb_id --force
  done
else
  echo "  ✅ No orphaned load balancers found"
fi

# Step 4: Delete orphaned volumes
echo ""
echo "📋 Step 4: Checking for orphaned volumes..."
ORPHANED_VOLUMES=$(doctl compute volume list --format ID,DropletIDs --no-header | awk '$2 == "" {print $1}')
if [ -n "$ORPHANED_VOLUMES" ]; then
  VOLUME_COUNT=$(echo "$ORPHANED_VOLUMES" | wc -l)
  echo "  Found $VOLUME_COUNT orphaned volume(s)"
  echo "$ORPHANED_VOLUMES" | while read vol_id; do
    echo "  Deleting volume: $vol_id"
    doctl compute volume delete $vol_id --force
  done
else
  echo "  ✅ No orphaned volumes found"
fi

# Step 5: Clean up kubeconfig
echo ""
echo "📋 Step 5: Cleaning up local kubeconfig..."
doctl kubernetes cluster kubeconfig remove $CLUSTER_NAME 2>/dev/null || echo "  Already removed"

# Final verification
echo ""
echo "📋 Final Verification:"
echo ""
echo "Remaining load balancers:"
doctl compute load-balancer list
echo ""
echo "Remaining volumes:"
doctl compute volume list
echo ""
echo "✅ Cleanup complete!"
echo ""
echo "⚠️  Manual checks recommended:"
echo "  - Container Registry: doctl registry list"
echo "  - Spaces: https://cloud.digitalocean.com/spaces"
echo "  - Snapshots: doctl compute snapshot list"
```

**Make it executable and run:**

```bash
chmod +x cleanup-doks.sh
./cleanup-doks.sh learn-k8s
```

### Cost Prevention Best Practices

**During active learning sessions:**

```bash
# Before ending a session, delete LoadBalancers but keep the cluster
kubectl delete svc --all --all-namespaces --field-selector spec.type=LoadBalancer

# This keeps your cluster running but removes expensive load balancers
# Recreate them next session when needed
```

**Between learning sessions (longer breaks):**

```bash
# Delete entire cluster to stop all costs
doctl kubernetes cluster delete learn-k8s --force

# Recreate when you're ready to learn again
doctl kubernetes cluster create learn-k8s \
  --region nyc1 \
  --version 1.28.2-do.0 \
  --node-pool "name=worker-pool;size=s-2vcpu-2gb;count=3"
```

**Monthly cost breakdown for awareness:**
- **3 worker nodes** (s-2vcpu-2gb): $12/month ($4 × 3)
- **1 LoadBalancer**: $12/month
- **Ingress Controller LB**: $12/month
- **10GB Block Storage**: $1/month ($0.10/GB)
- **Container Registry** (if used): $5-20/month
- **Total**: ~$40-50/month if everything is running

**Zero-cost strategy:**
- Delete cluster when not actively learning
- Recreate when needed (takes 3-5 minutes)
- Only charged for the hours/days you use it
- DigitalOcean bills hourly, partial hours rounded up

### Final Verification Checklist

**After running cleanup, verify everything is deleted:**

```bash
# ✅ No Kubernetes clusters
doctl kubernetes cluster list
# Expected: Empty list

# ✅ No load balancers
doctl compute load-balancer list
# Expected: Empty list

# ✅ No orphaned volumes
doctl compute volume list
# Expected: Empty list or only volumes attached to other droplets

# ✅ No droplets (unless you have non-DOKS droplets)
doctl compute droplet list
# Expected: Empty list or only your other VMs

# ✅ No container registry (if you created one)
doctl registry list
# Expected: Empty list

# ✅ Check DigitalOcean billing page
# Visit: https://cloud.digitalocean.com/account/billing
# Look for any unexpected resources
```

**If you see unexpected charges:**
1. Check the billing page for active resources
2. Look for resources in different regions (NYC1, SGP1, etc.)
3. Check for Floating IPs: `doctl compute floating-ip list`
4. Check for Snapshots: `doctl compute snapshot list`
5. Review Spaces in the web console

### Emergency "Delete Everything" Command

**If you want to ensure absolutely nothing is left (nuclear option):**

```bash
# ⚠️ WARNING: This deletes ALL DigitalOcean resources (not just DOKS)
# Only use if this is a dedicated learning account!

# Delete all load balancers
doctl compute load-balancer list --format ID --no-header | xargs -I {} doctl compute load-balancer delete {} --force

# Delete all volumes
doctl compute volume list --format ID --no-header | xargs -I {} doctl compute volume delete {} --force

# Delete all Kubernetes clusters
doctl kubernetes cluster list --format ID --no-header | xargs -I {} doctl kubernetes cluster delete {} --force

# Delete all droplets
doctl compute droplet list --format ID --no-header | xargs -I {} doctl compute droplet delete {} --force
```

**⚠️ Use with extreme caution!** This will delete resources for production workloads too!

---

## Summary: Learning Workflow with Cost Control

**Start of learning session:**
```bash
doctl kubernetes cluster create learn-k8s --region nyc1 --version 1.28.2-do.0 --node-pool "name=worker-pool;size=s-2vcpu-2gb;count=3"
doctl kubernetes cluster kubeconfig save learn-k8s
```

**End of learning session:**
```bash
kubectl delete svc --all --all-namespaces --field-selector spec.type=LoadBalancer
```

**End of session/extended break:**
```bash
./cleanup-doks.sh learn-k8s
```

This ensures you only pay for resources while actively learning, making the curriculum affordable!

## **Cleanup Commands**

### 1. Delete the Kubernetes Cluster
```bash
# This removes the cluster and its worker nodes
doctl kubernetes cluster delete learn-k8s

# Confirm when prompted, or force delete without confirmation
doctl kubernetes cluster delete learn-k8s --force
```

### 2. Delete Load Balancers
```bash
# List all load balancers
doctl compute load-balancer list

# Delete specific load balancers (created by Services/Ingress)
doctl compute load-balancer delete <load-balancer-id>

# Or delete by name if you set one
doctl compute load-balancer list --format ID,Name
doctl compute load-balancer delete <id>
```

### 3. Delete Block Storage Volumes
```bash
# List all volumes (created by PersistentVolumeClaims)
doctl compute volume list

# Delete volumes individually
doctl compute volume delete <volume-id>

# Or delete all unused volumes
doctl compute volume list --format ID,Name,DropletIDs | grep -v "DROPLET IDS" | awk '$3 == "" {print $1}' | xargs -I {} doctl compute volume delete {}
```

### 4. Delete Container Registry Images (if used)
```bash
# List registries
doctl registry list

# Delete specific registry
doctl registry delete <registry-name>

# Or just delete specific repositories
doctl registry repository list-tags <repository-name>
doctl registry repository delete-tag <repository-name> <tag>
```

### 5. Delete Spaces/Object Storage (if used for Velero backups)
```bash
# Via DigitalOcean web console:
# Navigate to Spaces → Select bucket → Settings → Destroy
```

### 6. Verify Everything is Deleted
```bash
# Check for remaining resources
doctl kubernetes cluster list
doctl compute load-balancer list
doctl compute volume list
doctl compute droplet list
doctl registry list
```

## **Important Notes**

⚠️ **What gets auto-deleted with cluster:**
- Worker node droplets
- Node pool configurations
- Cluster networking (VPC if created)

⚠️ **What does NOT auto-delete:**
- **Load Balancers** created by Services type=LoadBalancer
- **Block Storage Volumes** created by PersistentVolumeClaims
- **Container Registry** and images
- **Spaces** buckets used for backups
- **Snapshots** if you created any

## **Quick Cleanup Script**

```bash
#!/bin/bash
# save as: cleanup-doks.sh

echo "Cleaning up DigitalOcean resources..."

# Delete cluster
echo "Deleting cluster..."
doctl kubernetes cluster delete learn-k8s --force

# Wait a bit for cluster deletion
sleep 30

# Delete orphaned load balancers
echo "Checking for load balancers..."
doctl compute load-balancer list --format ID --no-header | while read lb_id; do
  echo "Deleting load balancer $lb_id"
  doctl compute load-balancer delete $lb_id --force
done

# Delete orphaned volumes
echo "Checking for volumes..."
doctl compute volume list --format ID --no-header | while read vol_id; do
  echo "Deleting volume $vol_id"
  doctl compute volume delete $vol_id --force
done

echo "Cleanup complete! Verify with:"
echo "  doctl compute load-balancer list"
echo "  doctl compute volume list"
```

```bash
chmod +x cleanup-doks.sh
./cleanup-doks.sh
```

## **Cost Prevention Tips**

**Before you finish each learning session:**
```bash
# Delete unnecessary LoadBalancers
kubectl delete svc --all -A --field-selector spec.type=LoadBalancer

# Or delete specific services
kubectl delete svc nginx-loadbalancer
kubectl delete svc -n ingress-nginx nginx-ingress-ingress-nginx-controller
```

**When taking breaks from learning:**
```bash
# Delete the entire cluster and recreate when needed
doctl kubernetes cluster delete learn-k8s --force

# Recreate later with same command
doctl kubernetes cluster create learn-k8s \
  --region sgp1 \
  --version 1.28.2-do.0 \
  --node-pool "name=worker-pool;size=s-2vcpu-2gb;count=3"
```

This ensures you're only charged when actively learning!

## **Remove DOKS Cluster from kubeconfig**

### Option 1: Remove specific context
```bash
# List all contexts
kubectl config get-contexts

# Delete the DOKS context
kubectl config delete-context do-sgp1-learn-k8s

# Delete the cluster entry
kubectl config delete-cluster do-sgp1-learn-k8s

# Delete the user entry
kubectl config delete-user do-sgp1-learn-k8s-admin
```

### Option 2: Use doctl to clean up
```bash
# Remove the cluster's kubeconfig entry
doctl kubernetes cluster kubeconfig remove learn-k8s
```

### Option 3: Manual cleanup
```bash
# Edit kubeconfig directly
nano ~/.kube/config

# Or use your preferred editor
code ~/.kube/config
```

Remove the sections for your deleted cluster under:
- `clusters:`
- `contexts:`
- `users:`

### Option 4: Complete reset (nuclear option)
```bash
# Backup current config
cp ~/.kube/config ~/.kube/config.backup

# Remove all contexts
rm ~/.kube/config

# If you have other clusters, restore and manually edit
# mv ~/.kube/config.backup ~/.kube/config
```

## **Verify Cleanup**

```bash
# Check remaining contexts
kubectl config get-contexts

# Check current context
kubectl config current-context

# If you have other clusters, switch to them
kubectl config use-context <other-context-name>
```

## **Quick Command**
The simplest approach after deleting a DOKS cluster:

```bash
doctl kubernetes cluster kubeconfig remove learn-k8s
```

This removes all associated entries (context, cluster, and user) from your kubeconfig automatically!