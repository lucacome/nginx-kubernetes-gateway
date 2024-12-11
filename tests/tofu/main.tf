provider "google" {
  project = var.gke_project
  region  = var.gke_cluster_region
}

data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}

data "google_client_config" "current" {}

data "google_compute_zones" "available" {}

locals {
  google_zone = data.google_compute_zones.available.names[0]
}

resource "google_container_cluster" "primary" {
  name    = var.gke_cluster_name
  project = data.google_client_config.current.project

  location                 = local.google_zone
  initial_node_count       = 1
  remove_default_node_pool = true

  network    = google_compute_network.vpc.self_link
  subnetwork = google_compute_subnetwork.subnet.self_link

  deletion_protection = false
  resource_labels = {
    env = "ngf-tests"
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "${chomp(data.http.myip.response_body)}/32"
      display_name = "local-ip"
    }
  }

  private_cluster_config {
    enable_private_nodes        = true
    private_endpoint_subnetwork = google_compute_subnetwork.subnet.self_link
  }
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.gke_cluster_name}-nodes"
  cluster    = google_container_cluster.primary.id
  node_count = var.gke_num_nodes

  node_config {
    machine_type    = var.gke_machine_type
    service_account = var.gke_nodes_service_account
    metadata = {
      block-project-ssh-keys   = "TRUE"
      disable-legacy-endpoints = "true"
    }
    shielded_instance_config {
      enable_secure_boot = true
    }
  }

  lifecycle {
    ignore_changes = [
      initial_node_count
    ]
  }

}

resource "google_compute_instance" "vm" {
  name                      = "${var.gke_cluster_name}-vm"
  machine_type              = "n2-standard-2"
  zone                      = local.google_zone
  allow_stopping_for_update = true
  boot_disk {
    initialize_params {
      image = "ngf-debian"
    }
  }
  shielded_instance_config {
    enable_secure_boot = true
  }
  network_interface {
    network    = google_compute_network.vpc.self_link
    subnetwork = google_compute_subnetwork.subnet.self_link

    access_config {
      nat_ip = google_compute_address.vpc-ip.address
    }
  }

  service_account {
    email  = var.vm_service_account
    scopes = ["cloud-platform"]
  }
  metadata = {
    user-data              = data.cloudinit_config.kubeconfig_setup.rendered
    block-project-ssh-keys = "TRUE"
  }
}
