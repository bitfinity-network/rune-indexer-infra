output "instance_ip" {
  value       = google_compute_instance.rune_indexer.network_interface[0].access_config[0].nat_ip
  description = "The public IP address of the rune indexer instance"
}

output "bitcoin_network" {
  value       = var.network
  description = "The Bitcoin network being indexed (mainnet or testnet)"
}
