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

variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
  default     = "lgtm-stack-cluster"
}

variable "k8s_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.34.1-do.1" # Use 'doctl kubernetes options versions' to find latest
}

variable "node_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 3
}
