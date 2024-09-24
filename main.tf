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

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo mkdir -p /opt/indexer",
      "sudo chown -R indexer:indexer /opt/indexer",
      "sudo chmod -R 700 /opt/indexer"
    ]
  }

  connection {
    type        = "ssh"
    user        = "indexer"
    private_key = tls_private_key.blockscout_key.private_key_pem
    host = self.network_interface[0].access_config[0].nat_ip
    agent = false
  }

  provisioner "file" {
    content     = local.bitcoin_conf
    destination = "/opt/indexer/bitcoin.conf"
  }

  provisioner "file" {
    content     = local.ord_config
    destination = "/opt/indexer/ord.yaml"
  }

  allow_stopping_for_update = true

  metadata_startup_script = local.startup_script

  metadata = {
    container-config-hash = sha256(local.startup_script)
    ssh-keys = "indexer:${tls_private_key.blockscout_key.public_key_openssh}"
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

    ord_config = templatefile("${path.module}/templates/ord.yaml.tftpl", {
      bitcoin_rpc_username = var.bitcoin_rpc_user
      bitcoin_rpc_password = var.bitcoin_rpc_password
      network              = var.network
      index_start_height   = var.index_start_height
    })

    bitcoin_conf = templatefile("${path.module}/templates/bitcoin.conf.tftpl", {
      bitcoin_rpc_user     = var.bitcoin_rpc_user
      bitcoin_rpc_password = var.bitcoin_rpc_password
      network              = var.network
    })
}

resource "tls_private_key" "blockscout_key" {
  algorithm = "RSA"
}