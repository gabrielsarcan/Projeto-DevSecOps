output "namespace" {
  description = "Namespace onde a aplicação foi implantada"
  value       = kubernetes_namespace.mkjs.metadata[0].name
}

output "frontend_service" {
  description = "Nome do serviço do frontend"
  value       = kubernetes_service.frontend.metadata[0].name
}

output "backend_service" {
  description = "Nome do serviço do backend"
  value       = kubernetes_service.backend.metadata[0].name
}

output "postgres_service" {
  description = "Nome do serviço do PostgreSQL"
  value       = kubernetes_service.postgres.metadata[0].name
}

output "ingress_host" {
  description = "Hostname configurado no Ingress"
  value       = var.ingress_host
}

output "access_instructions" {
  description = "Instruções de acesso à aplicação"
  value       = <<-EOT
    
    ============================================
    Aplicação implantada com sucesso!
    ============================================
    
    1. Adicione a entrada no /etc/hosts:
       $(minikube ip) ${var.ingress_host}
    
    2. Acesse: http://${var.ingress_host}
    
    3. Para verificar os pods:
       kubectl get pods -n ${var.namespace}
    
  EOT
}
