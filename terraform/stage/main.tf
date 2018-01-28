provider "google" {
  version = "1.4.0"
  project = "${var.project}"
  region  = "${var.region}"
}

# Подключение SSH ключей для пользователя asomirl И appuser
resource "google_compute_project_metadata" "ssh-asomirl" {
  metadata {
    ssh-keys = "asomirl:${file(var.public_key_path)}\n appuser:${file(var.public_key_path)}"
  }
}

# Подключаем модуль с приложухой
module "app" {
  source          = "../modules/app"
  public_key_path = "${var.public_key_path}"
  zone            = "${var.zone}"
  app_disk_image  = "${var.app_disk_image}"

  # Добавим-ка сюда внутренний адресочек Монги-Донги, чтобы подключиться к ней
  db_address = "${module.db.db_internal_ip}"
}

# Подключаем модуль создания Монги-Дудки-Бонги
module "db" {
  source          = "../modules/db"
  public_key_path = "${var.public_key_path}"
  zone            = "${var.zone}"
  db_disk_image   = "${var.db_disk_image}"
}

# Подключаем модуль создания VPC
module "vpc" {
  source        = "../modules/vpc"
  source_ranges = ["0.0.0.0/0"]
}
