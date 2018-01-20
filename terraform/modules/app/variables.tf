variable region {
  description = "Region"
  default     = "europe-west1"
}

variable zone {
  description = "Zone"
  default     = "europe-west1-b"
}

variable app_disk_image {
  description = "Disk image for reddit app"
  default     = "reddit-app-base"
}

variable public_key_path {
  description = "Path to the public key used for ssh access"
}

variable private_key_path { 
 description = "Path to the private key used for ssh access"
 default = "~/.ssh/id_rsa"
}

variable machine_type {
  description = "Machine type in GCP"
  default     = "g1-small"
}

variable db_address {
  description = "MongoDB IP"
  default     = "127.0.0.1"
}
