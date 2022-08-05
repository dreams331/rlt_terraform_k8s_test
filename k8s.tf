provider "kubernetes" {
  version = "~> 1.10.0"
  host    = google_container_cluster.default.endpoint
  token   = data.google_client_config.current.access_token
  client_certificate = base64decode(
    google_container_cluster.default.master_auth[0].client_certificate,
  )
  client_key = base64decode(google_container_cluster.default.master_auth[0].client_key)
  cluster_ca_certificate = base64decode(
    google_container_cluster.default.master_auth[0].cluster_ca_certificate,
  )
}

provider "helm" {

  kubernetes {
    host                   = data.template_file.gke_host_endpoint.rendered
    token                  = data.template_file.access_token.rendered
    cluster_ca_certificate = data.template_file.cluster_ca_certificate.rendered
    load_config_file       = false
  }
}

resource "helm_release" "apache" {
  depends_on = [google_container_node_pool.node_pool]

  repository = "https://charts.bitnami.com/bitnami"
  name       = "apache"
  chart      = "apache"
}




resource "kubernetes_namespace" "staging" {
  metadata {
    name = "staging"
  }
}

resource "google_compute_address" "default" {
  name   = var.network_name
  region = var.region
}

resource "kubernetes_service" "apache" {
  metadata {
    namespace = kubernetes_namespace.staging.metadata[0].name
    name      = "apache"
  }

  spec {
    selector = {
      run = "apache"
    }

    session_affinity = "ClientIP"

    port {
      protocol    = "TCP"
      port        = 80
      target_port = 80
    }

    type             = "LoadBalancer"
    load_balancer_ip = google_compute_address.default.address
  }
}

resource "kubernetes_replication_controller" "apache" {
  metadata {
    name      = "apache"
    namespace = kubernetes_namespace.staging.metadata[0].name

    labels = {
      run = "apache"
    }
  }

  spec {
    selector = {
      run = "apache"
    }

    template {
      metadata {
          name = "apache"
          labels = {
              run = "apache"
          }
      }

      spec {
        container {
            image = "apache:latest"
            name  = "apache"

            resources {
                limits {
                    cpu    = "0.5"
                    memory = "512Mi"
                }

                requests {
                    cpu    = "250m"
                    memory = "50Mi"
                }
            }
        }       
      }
    }
  }
}

output "load-balancer-ip" {
  value = google_compute_address.default.address
}
