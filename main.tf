data "google_compute_default_service_account" "default_sa" {}


resource "google_compute_instance" "rune_indexer" {
  name         = "rune-indexer-${var.network}"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 512
    }
    auto_delete = true
    device_name = "indexer-disk"
  }

  network_interface {
    network = "default"
    access_config {
      network_tier = "STANDARD"
    }
  }


  service_account {
    email  = data.google_compute_default_service_account.default_sa.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
  allow_stopping_for_update = true

  metadata_startup_script = local.startup_script

  metadata = {
    container-config-hash = sha256(local.startup_script)
  }

  tags = ["rune-indexer", var.network]
}


locals {
    startup_script = templatefile("${path.module}/templates/startup-script.tftpl", {
      bitcoin_rpc_user     = var.bitcoin_rpc_user
      bitcoin_rpc_password = var.bitcoin_rpc_password
      network              = var.network
      index_start_height   = var.index_start_height
    })
}