
variable "project_id" {
  description = "Google Cloud Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "us-central1-a"
}


variable "machine_type" {
  description = "GCP machine type"
  type        = string
  default     = "e2-standard-4"
}


variable "bitcoin_rpc_user" {
  description = "Bitcoin RPC username"
  type        = string
  default     = "bitcoin"
}

variable "bitcoin_rpc_password" {
  description = "Bitcoin RPC password"
  type        = string
  default     = "QsZjx3FX"
  sensitive   = true
}

variable "index_start_height" {
  description = "Block height to start indexing from"
  type        = number
  default     = 0
}

variable "network" {
  description = "Bitcoin network (mainnet or testnet or regtest)"
  type        = string
  default     = "testnet"
  validation {
    condition     = contains(["mainnet", "testnet", "regtest"], var.network)
    error_message = "The network must be mainnet, testnet, or regtest."
  }
}
