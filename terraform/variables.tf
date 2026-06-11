variable "kubeconfig_path" {
  description = "Caminho para o arquivo kubeconfig"
  type        = string
  default     = "~/.kube/config"
}

variable "kubeconfig_context" {
  description = "Contexto do kubeconfig a ser utilizado"
  type        = string
  default     = "minikube"
}

variable "namespace" {
  description = "Namespace do Kubernetes para a aplicação"
  type        = string
  default     = "mkjs"
}

variable "frontend_image" {
  description = "Imagem Docker do frontend"
  type        = string
  default     = "mkjs-frontend:latest"
}

variable "backend_image" {
  description = "Imagem Docker do backend"
  type        = string
  default     = "mkjs-backend:latest"
}

variable "postgres_image" {
  description = "Imagem Docker do PostgreSQL"
  type        = string
  default     = "postgres:15-alpine"
}

variable "frontend_replicas" {
  description = "Número de réplicas do frontend"
  type        = number
  default     = 2
}

variable "backend_replicas" {
  description = "Número de réplicas do backend"
  type        = number
  default     = 2
}

variable "ingress_host" {
  description = "Hostname para o Ingress"
  type        = string
  default     = "mkjs.local"
}
