# Создаём машинку в гугле с именем App
resource "google_compute_instance" "app" {
  name         = "reddit-app"
  machine_type = "${var.machine_type}"
  zone         = "${var.zone}"
  tags         = ["reddit-app"]

  boot_disk {
    initialize_params {
      image = "${var.app_disk_image}"
    }
  }

  network_interface {
    network = "default"

    access_config = {
      nat_ip = "${google_compute_address.app_ip.address}"
    }
  }
 metadata {
    sshKeys = "asomirl:${file(var.public_key_path)}"
  }
 connection {
    type        = "ssh"
    user        = "asomirl"
    agent       = "false"
    private_key = "${file(var.private_key_path)}"
  }
 provisioner "file" {
 	source = "gs://storage-bucket-test-11/puma.service"
 	destination = "/tmp/puma.service"
	}

 provisioner "remote-exec" {
 	script = "gs://storage-bucket-test-11/deploy.sh"
	}
}

resource "google_compute_address" "app_ip" {
  name = "reddit-app-ip"
}

# Создание правила для firewall
resource "google_compute_firewall" "firewall_puma" {
  name    = "allow-puma-default"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["9292"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["reddit-app"]
}

