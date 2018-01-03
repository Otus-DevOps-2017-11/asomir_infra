provider "google" {
 version = "1.4.0"
 project = "${var.project}"
 region = "${var.region}"
}

resource "google_compute_instance" "app" {
 name = "reddit-app"
 machine_type = "g1-small"
 zone = "${var.zone}"
 tags = ["reddit-app"] 
 
 # добавление SSH ключей для моего пользователя
 metadata {
 sshKeys = "asomirl:${file(var.public_key_path)}"
 }
 
 # определение загрузочного диска
 boot_disk {
 initialize_params {
 image = "${var.disk_image}"
 }
 }
 
 # определение сетевого интерфейса
 network_interface {
 # сеть, к которой присоединить данный интерфейс
 network = "default"
 # использовать ephemeral IP для доступа из Интернет
 access_config {} 
 }
 # включаем подключение по ssh с путём к приватному ключу 
 connection {
 	type = "ssh"
 	user = "asomirl"
 	agent = false
 	private_key = "${file("var.private_key_path")}"
 }
# копируем puma-service 
 provisioner "file" { 
 	source = "files/puma.service"
 	destination = "/tmp/puma.service"
 }

# запуск скрипта деплоя
 provisioner "remote-exec" {
 	script = "files/deploy.sh"
 }
}

# Создание правила для firewall
resource "google_compute_firewall" "firewall_puma" {
 name = "allow-puma-default"
# Название сети, в которой действует правило
 network = "default"
# Какой доступ разрешить
 allow {
 protocol = "tcp"
 ports = ["9292"]
 }
# Каким адресам разрешаем доступ
 source_ranges = ["0.0.0.0/0"]
# Правило применимо для инстансов с тегом …
 target_tags = ["reddit-app"]
}

