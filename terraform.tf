terraform {
    required_version = ">= 1.7"

    required_providers {
        google = {
            source  = "hashicorp/google"
            version = ">= 5.18"
        }

        random = {
            source  = "hashicorp/random"
            version = ">= 3.4"
        }

        tls = {
            source  = "hashicorp/tls"
            version = ">= 3.0"
        }
    }

    # Configure where the state is stored, you can also use a local state file, aws s3 bucket, etc.
    backend "gcs" {
        bucket = "ord-indexer-state"
        prefix = "indexer"
    }
}