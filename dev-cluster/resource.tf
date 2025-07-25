# runs command to check if docker and kind are installed
resource "null_resource" "prerequisites_check" {
  provisioner "local-exec" {
    command = <<EOT
      if ! command -v kind >/dev/null 2>&1; then
        echo "Error: kind is not installed"; exit 1
      fi
      if ! command -v docker >/dev/null 2>&1; then
        echo "Error: Docker is not installed"; exit 1
      fi
    EOT
  }
}

# kind-cluster-config-generator-resource
resource "local_file" "kind_config_generator" {

  filename = "${path.module}/terraform-generated-${var.cluster_name}-config.yaml"
  content = templatefile("${path.module}/template-kind-config.yaml", {
    cluster_name = var.cluster_name

  })
}

# kind-cluster-generator-resource
resource "null_resource" "kind_cluster_dev" {
  depends_on = [local_file.kind_config_generator, null_resource.prerequisites_check]

  triggers = {
    always_run   = timestamp()
    cluster_name = var.cluster_name
  }

  provisioner "local-exec" {
    command = "kind create cluster --config ${local_file.kind_config_generator.filename}"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kind delete cluster --name ${self.triggers.cluster_name}"
  }
}
/*
# This resource allows to install ingress-nginx generator-resource
resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.9.1" # Pinning chart version for stable deployments
  namespace  = "ingress-nginx"
  create_namespace = true # Have Helm create the namespace for us

  # The 'values' block here is like using a custom values.yaml file.
  # For kind, we don't have a real cloud LoadBalancer. This setting
  # makes the Ingress controller accessible via the kind node's IP.
  # This is a common configuration for local development with kind.
  set = [{
    name  = "controller.service.type"
    value = "NodePort"
  },
  {
    name  = "controller.service.nodePorts.http"
    value = "30080" # This port needs to be mapped in your kind cluster config
  }]
}

# This block defines the NGINX Deployment. You should already have this.
# We need it here to see the labels.
resource "kubernetes_deployment" "nginx" {
  metadata {
    name = "nginx-deployment"
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        # This label is VERY important. It's how the Service finds the Pods.
        app = "nginx" 
      }
    }
    template {
      metadata {
        labels = {
          # Ensure this label matches the selector above.
          app = "nginx"
        }
      }
      spec {
        container {
          image = "nginx:1.25"
          name  = "nginx"
          port {
            container_port = 80
          }
        }
      }
    }
  }
}

# --- ADD THIS NEW RESOURCE ---
# This creates the stable network endpoint for the NGINX pods.
resource "kubernetes_service" "nginx_service" {
  metadata {
    name = "nginx-service" # This is the internal DNS name for the service.
  }
  spec {
    selector = {
      # This MUST match the label on your Deployment's Pods.
      app = kubernetes_deployment.nginx.spec[0].template[0].metadata[0].labels.app
    }
    port {
      port        = 80 # The port the Service will listen on.
      target_port = 80 # The port on the container to send traffic to.
    }
    # ClusterIP is the default type, making it reachable only from within the cluster.
    # This is exactly what we want, as the Ingress will handle external traffic.
    type = "ClusterIP"
  }
}

# This resource now actually allows nginx_ingress to route traffic from outside
# the cluster to applications running internal services.
resource "kubernetes_ingress_v1" "nginx_ingress" {
  metadata {
    name = "nginx-ingress"
    # Important: The Ingress resource must be in the same namespace as the service it is routing to.
    # We reference the service's namespace directly to ensure they match.
    namespace = kubernetes_service.nginx_service.metadata[0].namespace
    annotations = {
      # This annotation tells the ingress-nginx controller that it should handle this Ingress resource.
      # While ingress_class_name is the modern way, this annotation is still very common and provides compatibility.
      "kubernetes.io/ingress.class" = "nginx"
    }
  }

  spec {
    # This is the modern field for specifying the IngressClass. The Helm chart
    # we installed automatically created an IngressClass object named "nginx" for us.
    ingress_class_name = "nginx"

    rule {
      host = "nginx.local"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              # These lines dynamically look up the name and port of your NGINX service.
              # This is better than hardcoding because it prevents typos and updates automatically.
              name = kubernetes_service.nginx_service.metadata[0].name
              port {
                number = kubernetes_service.nginx_service.spec[0].port[0].port
              }
            }
          }
        }
      }
    }
  }
  
  # This ensures the Ingress is created only after the Ingress Controller is ready.
  depends_on = [helm_release.ingress_nginx]
}
*/