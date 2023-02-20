variable "do_token" {}
variable "region" {}
variable "project_name" {}
variable "ssh_pub_path" {}
variable "node_count" {}
variable "machine_size" {}
provider "digitalocean" {
  token = var.do_token
}

data "digitalocean_kubernetes_versions" "versions" {}

resource "digitalocean_ssh_key" "web-ssh" {
  name       = "web-ssh"
  public_key = try(file(var.ssh_pub_path), null)
}

resource "digitalocean_kubernetes_cluster" "cluster" {
  name    = "${var.project_name}-cluster"
  region  = var.region
  version = data.digitalocean_kubernetes_versions.versions.latest_version
  tags    = ["testing"]

  node_pool {
    name       = "worker-pool"
    size       = "s-1vcpu-2gb"
    node_count = 2
    tags       = ["worker"]
  }
}

provider "kubernetes" {
  load_config = false
  host        = digitalocean_kubernetes_cluster.cluster.endpoint
  token       = digitalocean_kubernetes_cluster.cluster.kube_config[0].token
  cluster_ca_certificate = base64decode(
    digitalocean_kubernetes_cluster.cluster.kube_config[0].cluster_ca_certificate
  )
}

output "cluster-id" {
  value = digitalocean_kubernetes_cluster.cluster.id
}

output "endpoint" {
  value = digitalocean_kubernetes_cluster.cluster.endpoint
}

output "token" {
  value     = digitalocean_kubernetes_cluster.cluster.kube_config[0].token
  sensitive = true
}

output "cert" {
  value     = digitalocean_kubernetes_cluster.cluster.kube_config[0].cluster_ca_certificate
  sensitive = true
}

output "k8s_version" {
  value     = data.digitalocean_kubernetes_versions.versions.latest_version
  sensitive = true
}

output "kube_config" {
  value     = digitalocean_kubernetes_cluster.cluster.kube_config[0].raw_config
  sensitive = true
}
