provider "google" {
 version = "1.4.0"
 project = "${var.project}"
 region = "${var.region}"
}

# Подключение SSH ключей для пользователя asomirl И appuser
resource "google_compute_project_metadata" "ssh-asomirl" {
 metadata  {
 	ssh-keys  = "asomirl:${file(var.public_key_path)}\n appuser:${file(var.public_key_path)}"
  }
}

resource "google_compute_instance" "app" {
 name = "reddit-app"
 machine_type = "g1-small"
 zone = "${var.zone}"
 tags = ["reddit-app"] 
 
 # добавление SSH ключей для моего пользователя
 #metadata {
 #sshKeys = "asomirl:${file(var.public_key_path)}"
 #}
 
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
 	private_key = "${file(var.private_key_path)}"
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

# Задаём IP для сервера в виде внешнего ресурса
resource "google_compute_address" "app_ip" {
 name = "reddit-app-ip"
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

# Создаём правило для 22 порта с тем же именем, что в вебе
resource "google_compute_firewall" "firewall_ssh" {
 name = "default-allow-ssh"
 description = "Hallow, SSH!"
 network =
"default"
 allow {
 protocol = "tcp"
 ports = ["22"]
 }
 source_ranges = ["0.0.0.0/0"]

}

