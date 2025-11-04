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

resource "kubernetes_config_map_v1" "critical_application_script" {
  metadata {
    name      = "critical-application-script"
    namespace = "default"
  }

  data = {
    "log_generator.py" = <<-EOT
      import time
      import random
      import datetime
      import traceback

      log_levels = ["INFO", "WARN", "ERROR", "DEBUG"]
      endpoints = ["/api/v1/products", "/api/v1/orders", "/api/v1/users", "/healthcheck"]
      users = ["alice", "bob", "carol", "dave", "eve"]

      error_stack_trace = """Traceback (most recent call last):
        File "log_generator.py", line 45, in <module>
          simulate_error()
        File "log_generator.py", line 44, in simulate_error
          1 / 0
      ZeroDivisionError: division by zero"""

      def generate_log_line():
          timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
          level = random.choice(log_levels)
          user = random.choice(users)
          
          if level == "ERROR":
              message = (
                  "Exception occurred while processing request\n"
                  "Request: POST /api/v1/orders\n"
                  "Payload: {'order_id': 1234, 'items': ['book', 'pen'], 'user': '%s'}\n"
                  "Stack trace:\n%s" % (user, error_stack_trace)
              )
          elif level == "WARN":
              message = (
                  "Warning: High response latency detected for endpoint %s\n"
                  "Latency: %.2f seconds\n"
                  "User: %s" % (random.choice(endpoints), random.uniform(0.5, 3.0), user)
              )
          elif level == "DEBUG":
              message = (
                  "Request received\n"
                  "Method: GET\n"
                  "Endpoint: %s\n"
                  "User: %s\n"
                  "Headers: { 'Authorization': 'Bearer token123', 'Content-Type': 'application/json' }\n"
                  "Body: { 'example': 'data' }" % (random.choice(endpoints), user)
              )
          else:
              message = (
                  "User %s successfully accessed endpoint %s\n"
                  "Request ID: %s\n"
                  "Response Time: %.2f ms\n"
                  "Status: 200 OK" % (user, random.choice(endpoints), random.randint(1000,9999), random.uniform(100, 500))
              )
          
          return f"{timestamp} {level} {message}"

      while True:
          print(generate_log_line())
          time.sleep(1)
    EOT
  }

  depends_on = [module.eks]
}

resource "kubernetes_deployment_v1" "critical_application" {
  metadata {
    name      = "critical-application"
    namespace = "default"
    labels = {
      app = "critical-application"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "critical-application"
      }
    }

    template {
      metadata {
        labels = {
          app = "critical-application"
        }
      }

      spec {
        container {
          image   = "python:3.11-alpine"
          name    = "critical-application"
          command = ["python", "-u", "/app/log_generator.py"]

          volume_mount {
            name       = "script-volume"
            mount_path = "/app"
          }
        }

        volume {
          name = "script-volume"
          config_map {
            name = kubernetes_config_map_v1.critical_application_script.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [
    module.eks,
    kubernetes_config_map_v1.critical_application_script
  ]
}
