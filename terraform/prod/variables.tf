variable project {
  description = "Project ID"
}

variable region {
  description = "Region"
  default     = "europe-west1"
}

variable zone {
  description = "Zone"
  default     = "europe-west1-b"
}

variable public_key_path {
  description = "Path to the public key used for ssh access"
}

variable private_key_path {
  description = "Path to the private key used for ssh access"
}

variable disk_image {
  description = "Disk image"
  default     = "reddit-base-1515001795"
}

variable app_disk_image {
  description = "Disk image for reddit app"
  default     = "reddit-app-base-20180104-125540"
}

variable db_disk_image {
  description = "Disk image for reddit db"
  default     = "reddit-db-base-20180104-125940"
}
