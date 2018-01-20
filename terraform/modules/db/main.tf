# Создаём инстанс Монги-Дури-Бонги
resource "google_compute_instance" "db" {
  name         = "reddit-db"
  machine_type = "g1-small"
  zone         = "${var.zone}"
  tags         = ["reddit-db"]

  boot_disk {
    initialize_params {
      image = "${var.db_disk_image}"
    }
  }
  # Инициализируем сеточку
  network_interface {
    network       = "default"
    access_config = {}
  }

  # Прихерачиваем SSH, чтобы копировать файлики и выполнять скриптики
  metadata {
    sshKeys = "asomirl:${file(var.public_key_path)}"
  }
 connection {
    type        = "ssh"
    user        = "asomirl"
    agent       = "false"
    private_key = "${file(var.private_key_path)}"
  }
   #Копируем конфиг Монги в ТМП на ДБ сервере
 provisioner "file" {
 	source     = "${path.module}/files/mongod.conf"
 	destination = "/tmp/mongod.conf"
	}
 # Выполняем наш скрыпт деплоя
 provisioner "remote-exec" {
 	script = "${path.module}/files/deploy.sh"
	}

  #metadata {
  #sshKeys = "asomirl:${file(var.public_key_path)}"
  #}
}

# Создаём правило firewall_mongo для 27017 порта Монги-Дури-Бонги
resource "google_compute_firewall" "firewall_mongo" {
  name    = "allow-mongo-default"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["27017"]
  }

  # правило применимо к инстансам с тегом ...
  target_tags = ["reddit-db"]

  # порт будет доступен только для инстансов с тегом ...
  source_tags = ["reddit-app"]
}
