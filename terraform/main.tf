provider "kubernetes" {
  config_path    = var.kubeconfig_path
  config_context = var.kubeconfig_context
}

provider "kubectl" {
  config_path    = var.kubeconfig_path
  config_context = var.kubeconfig_context
}

# -------------------------------------------------------------------
# Namespace
# -------------------------------------------------------------------
resource "kubernetes_namespace" "mkjs" {
  metadata {
    name = var.namespace

    labels = {
      "app.kubernetes.io/part-of"    = "mkjs"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

# -------------------------------------------------------------------
# Secret - Credenciais do PostgreSQL
# -------------------------------------------------------------------
# TODO(security): Para produção, utilize um gerenciador de segredos externo
# (Vault, Sealed Secrets, AWS Secrets Manager, etc.)
resource "kubernetes_secret" "postgres_credentials" {
  metadata {
    name      = "postgres-credentials"
    namespace = kubernetes_namespace.mkjs.metadata[0].name

    labels = {
      "app.kubernetes.io/part-of"   = "mkjs"
      "app.kubernetes.io/component" = "database"
    }
  }

  type = "Opaque"

  data = {
    POSTGRES_USER     = "postgres"
    POSTGRES_PASSWORD = "postgres"
    POSTGRES_DB       = "mkjs_db"
  }
}

# -------------------------------------------------------------------
# PersistentVolumeClaim - Dados do PostgreSQL
# -------------------------------------------------------------------
resource "kubernetes_persistent_volume_claim" "postgres_data" {
  metadata {
    name      = "postgres-data"
    namespace = kubernetes_namespace.mkjs.metadata[0].name

    labels = {
      "app.kubernetes.io/part-of"   = "mkjs"
      "app.kubernetes.io/component" = "database"
    }
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = "1Gi"
      }
    }
  }
}

# -------------------------------------------------------------------
# PostgreSQL - Deployment
# -------------------------------------------------------------------
resource "kubernetes_deployment" "postgres" {
  metadata {
    name      = "postgres"
    namespace = kubernetes_namespace.mkjs.metadata[0].name

    labels = {
      "app.kubernetes.io/name"      = "postgres"
      "app.kubernetes.io/part-of"   = "mkjs"
      "app.kubernetes.io/component" = "database"
    }
  }

  spec {
    replicas = 1

    strategy {
      type = "Recreate"
    }

    selector {
      match_labels = {
        "app.kubernetes.io/name" = "postgres"
      }
    }

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name"      = "postgres"
          "app.kubernetes.io/part-of"   = "mkjs"
          "app.kubernetes.io/component" = "database"
        }
      }

      spec {
        security_context {
          run_as_non_root = true
          run_as_user     = 70
          fs_group        = 70
        }

        container {
          name  = "postgres"
          image = var.postgres_image

          port {
            container_port = 5432
            protocol       = "TCP"
          }

          env {
            name = "POSTGRES_USER"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.postgres_credentials.metadata[0].name
                key  = "POSTGRES_USER"
              }
            }
          }

          env {
            name = "POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.postgres_credentials.metadata[0].name
                key  = "POSTGRES_PASSWORD"
              }
            }
          }

          env {
            name = "POSTGRES_DB"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.postgres_credentials.metadata[0].name
                key  = "POSTGRES_DB"
              }
            }
          }

          env {
            name  = "PGDATA"
            value = "/var/lib/postgresql/data/pgdata"
          }

          volume_mount {
            name       = "postgres-data"
            mount_path = "/var/lib/postgresql/data"
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "250m"
              memory = "256Mi"
            }
          }

          liveness_probe {
            exec {
              command = ["pg_isready", "-U", "postgres"]
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            exec {
              command = ["pg_isready", "-U", "postgres"]
            }
            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 3
          }
        }

        volume {
          name = "postgres-data"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.postgres_data.metadata[0].name
          }
        }
      }
    }
  }
}

# -------------------------------------------------------------------
# PostgreSQL - Service
# -------------------------------------------------------------------
resource "kubernetes_service" "postgres" {
  metadata {
    name      = "postgres"
    namespace = kubernetes_namespace.mkjs.metadata[0].name

    labels = {
      "app.kubernetes.io/name"      = "postgres"
      "app.kubernetes.io/part-of"   = "mkjs"
      "app.kubernetes.io/component" = "database"
    }
  }

  spec {
    type = "ClusterIP"

    selector = {
      "app.kubernetes.io/name" = "postgres"
    }

    port {
      port        = 5432
      target_port = 5432
      protocol    = "TCP"
      name        = "postgresql"
    }
  }
}

# -------------------------------------------------------------------
# Backend - Deployment
# -------------------------------------------------------------------
resource "kubernetes_deployment" "backend" {
  metadata {
    name      = "backend"
    namespace = kubernetes_namespace.mkjs.metadata[0].name

    labels = {
      "app.kubernetes.io/name"      = "backend"
      "app.kubernetes.io/part-of"   = "mkjs"
      "app.kubernetes.io/component" = "server"
    }
  }

  spec {
    replicas = var.backend_replicas

    selector {
      match_labels = {
        "app.kubernetes.io/name" = "backend"
      }
    }

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name"      = "backend"
          "app.kubernetes.io/part-of"   = "mkjs"
          "app.kubernetes.io/component" = "server"
        }
      }

      spec {
        security_context {
          run_as_non_root = true
          run_as_user     = 1000
          run_as_group    = 1000
        }

        container {
          name              = "backend"
          image             = var.backend_image
          image_pull_policy = "IfNotPresent"

          port {
            container_port = 55555
            protocol       = "TCP"
          }

          env {
            name = "POSTGRES_USER"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.postgres_credentials.metadata[0].name
                key  = "POSTGRES_USER"
              }
            }
          }

          env {
            name = "POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.postgres_credentials.metadata[0].name
                key  = "POSTGRES_PASSWORD"
              }
            }
          }

          env {
            name = "POSTGRES_DB"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.postgres_credentials.metadata[0].name
                key  = "POSTGRES_DB"
              }
            }
          }

          env {
            name  = "DATABASE_URL"
            value = "postgres://$(POSTGRES_USER):$(POSTGRES_PASSWORD)@postgres:5432/$(POSTGRES_DB)"
          }

          env {
            name  = "NODE_ENV"
            value = "production"
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "250m"
              memory = "256Mi"
            }
          }

          liveness_probe {
            tcp_socket {
              port = 55555
            }
            initial_delay_seconds = 15
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            tcp_socket {
              port = 55555
            }
            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 3
          }
        }
      }
    }
  }
}

# -------------------------------------------------------------------
# Backend - Service
# -------------------------------------------------------------------
resource "kubernetes_service" "backend" {
  metadata {
    name      = "backend"
    namespace = kubernetes_namespace.mkjs.metadata[0].name

    labels = {
      "app.kubernetes.io/name"      = "backend"
      "app.kubernetes.io/part-of"   = "mkjs"
      "app.kubernetes.io/component" = "server"
    }
  }

  spec {
    type = "ClusterIP"

    selector = {
      "app.kubernetes.io/name" = "backend"
    }

    port {
      port        = 55555
      target_port = 55555
      protocol    = "TCP"
      name        = "http"
    }
  }
}

# -------------------------------------------------------------------
# Frontend - Deployment
# -------------------------------------------------------------------
resource "kubernetes_deployment" "frontend" {
  metadata {
    name      = "frontend"
    namespace = kubernetes_namespace.mkjs.metadata[0].name

    labels = {
      "app.kubernetes.io/name"      = "frontend"
      "app.kubernetes.io/part-of"   = "mkjs"
      "app.kubernetes.io/component" = "web"
    }
  }

  spec {
    replicas = var.frontend_replicas

    selector {
      match_labels = {
        "app.kubernetes.io/name" = "frontend"
      }
    }

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name"      = "frontend"
          "app.kubernetes.io/part-of"   = "mkjs"
          "app.kubernetes.io/component" = "web"
        }
      }

      spec {
        security_context {
          run_as_non_root = true
        }

        container {
          name              = "frontend"
          image             = var.frontend_image
          image_pull_policy = "IfNotPresent"

          port {
            container_port = 8080
            protocol       = "TCP"
          }

          resources {
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "100m"
              memory = "128Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 8080
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 8080
            }
            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 3
          }
        }
      }
    }
  }
}

# -------------------------------------------------------------------
# Frontend - Service
# -------------------------------------------------------------------
resource "kubernetes_service" "frontend" {
  metadata {
    name      = "frontend"
    namespace = kubernetes_namespace.mkjs.metadata[0].name

    labels = {
      "app.kubernetes.io/name"      = "frontend"
      "app.kubernetes.io/part-of"   = "mkjs"
      "app.kubernetes.io/component" = "web"
    }
  }

  spec {
    type = "ClusterIP"

    selector = {
      "app.kubernetes.io/name" = "frontend"
    }

    port {
      port        = 8080
      target_port = 8080
      protocol    = "TCP"
      name        = "http"
    }
  }
}

# -------------------------------------------------------------------
# Ingress
# -------------------------------------------------------------------
resource "kubernetes_ingress_v1" "mkjs" {
  metadata {
    name      = "mkjs-ingress"
    namespace = kubernetes_namespace.mkjs.metadata[0].name

    labels = {
      "app.kubernetes.io/part-of"   = "mkjs"
      "app.kubernetes.io/component" = "ingress"
    }

    annotations = {
      "cert-manager.io/cluster-issuer"                       = "letsencrypt-prod"
      "nginx.ingress.kubernetes.io/ssl-redirect"             = "true"
      "nginx.ingress.kubernetes.io/force-ssl-redirect"       = "true"
      "nginx.ingress.kubernetes.io/proxy-read-timeout"       = "3600"
      "nginx.ingress.kubernetes.io/proxy-send-timeout"       = "3600"
      "nginx.ingress.kubernetes.io/proxy-http-version"       = "1.1"
      "nginx.ingress.kubernetes.io/configuration-snippet"    = <<-EOT
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
      EOT
    }
  }

  spec {
    ingress_class_name = "nginx"

    tls {
      hosts       = [var.ingress_host]
      secret_name = "mkjs-tls"
    }

    rule {
      host = var.ingress_host

      http {
        path {
          path      = "/socket.io"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.backend.metadata[0].name
              port {
                number = 55555
              }
            }
          }
        }

        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.frontend.metadata[0].name
              port {
                number = 8080
              }
            }
          }
        }
      }
    }
  }
}
