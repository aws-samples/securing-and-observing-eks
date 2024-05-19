resource "kubernetes_deployment_v1" "collector" {
  metadata {
    name      = "collector"
    namespace = "default"
    labels = {
      app = "collector"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "collector"
      }
    }

    template {
      metadata {
        labels = {
          app = "collector"
        }
      }

      spec {
        container {
          image   = "public.ecr.aws/aws-cli/aws-cli:2.15.53"
          name    = "collector"
          command = ["sleep"]
          args    = ["infinity"]

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
        }
        service_account_name = "collector-sa"
      }
    }
  }
  depends_on = [module.eks]
}

resource "kubernetes_service_account_v1" "collector" {
  metadata {
    name      = "collector-sa"
    namespace = "default"
  }
  depends_on = [module.eks]
}

resource "kubernetes_deployment_v1" "threat" {
  metadata {
    name      = "threat"
    namespace = "kube-system"
    labels = {
      app = "threat"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "threat"
      }
    }

    template {
      metadata {
        labels = {
          app = "threat"
        }
      }

      spec {
        container {
          image   = "public.ecr.aws/lts/ubuntu:latest"
          name    = "threat"
          command = ["sleep"]
          args    = ["infinity"]

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
          port {
            container_port = 22
          }
          security_context {
            privileged = true
          }
          volume_mount {
            name       = "host-etc"
            mount_path = "/host-etc"
          }
        }
        volume {
          name = "host-etc"
          host_path {
            path = "/etc"
          }
        }
        service_account_name = "default"
      }
    }
  }
  depends_on = [module.eks]
}

resource "kubernetes_role_binding_v1" "threat" {
  metadata {
    name      = "threat"
    namespace = "kube-system"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = "kube-system"
  }
  depends_on = [module.eks]
}