# HomeWork 10
## Что мы тут понаделали

1. Создали инвентори файл, который потом переделали в YAML, где описали наши хосты и их айпишники, их добавили в группы, соответственно, APP и DB.
2. Попинговали хосты поимённо, потом по группам, попинговали по умолчанию - всё пингуется. Спасибо SSH-ключикам! 
3. Позапускали айптаймы на наших хостах, посмотрели на время, - самую могущественную силу на Земле.
4. Проверили, есть ли у нас Руби и Бундлер и каких они версий. Делали проверки на инстансах по очереди. Вначале шеллом, потом коммандом. Всё на месте. Благодать! Шеллом удалось запустить обедве проверки сразу, модуль command - заболтил. Слава великому Комманду!
5. Проверили Коммандом и Шеллом статус монги. Использовали соответственно 
   ```
        $ ansible db -m command -a 'systemctl status mongod' 
        $ ansible db -m shell -a 'systemctl status mongod'
   ```
6. Попробовали всё то же самое с помощью модулей systemd и service, соответственно:
```
        $ ansible db -m systemd -a name=mongod 
        $ ansible db -m service -a name=mongod 
```
7. Красота трудноописуемая! Я в восторге! В результате выполнения можно посмотреть много плюшек: набор переменных, которые потом можно использовать в своих самых коварных целях. Или кавайных - я ещё не сумел разобраться. 
8. Использовали модуль гит для клонирования репочки:
```
        $ ansible app -m git -a 'repo=https://github.com/Otus-DevOps-2017-11/reddit.git dest=/home/appuser/reddit'
```
9. Сделали всё то же самое с модулем command
```
        $ ansible app -m command -a 'git clone https://github.com/Otus-DevOps-2017-11/reddit.git /home/appuser/reddit'
```
10. Решили попробовать повторить команду, но получили болта. Второй раз тот же фокус не проканывает. Иммутабле такое иммутабле.
11. Мораль сей басни такова, что модули вещь крутецкая. Шелл отстой! Цой жив!
12. Котэ, одмин, шредер.  


# HomeWork 09
## Что мы тут понаделали:

 1. Импортировали правило из GCP "default-allow-ssh" и создали отдельный ресурс с разрешением подключаться по SSH к 22 порту. 
 2. Создаём ресурс IP адреса для нашего сервера АРР.
 3. Ссылаемся на созданный IP адрес nat_ip = "${google_compute_address.app_ip.address}"
 4. Создали 2 новых шаблона db.json и app.json для создания инстанса, соответственно, с установленной Монгой и с установленной Руби. 
 5. Создаём 2 виртуалки: app.tf, - конфигурация с приложением, - устанавливается из заготовленного в app.json пироге , и db.tf, - конфигурация с базой данных, устанавливается из заготовленного db.json. В APP создаём IP адрес и конфигурацию файрволла для IP 9292 для инстансов, помеченных ["reddit-app"]. И добавили db_disk_image и app_disk_image в файл переменных. Создали в db.tf правило файервола, которое даёт доступ приложению к БД.
 6. Создали файл vpc.tf, куда вынесли правило файерволла для доступа по SSH для всех инстансов в сети. 
 7. Разбили db, app и vpc на отдельные модули, о чём честно рассказали в main.tf в папке terraform. Добавили выходные переменные, чтобы видеть, какие мы получили IP.
 8. Удалили db.tf, vpc.tf и app.tf из директории Terraform. Ой-ой-ой, что же сейчас будет? 
 9. Всё прошло гладко. В файерволле добавляли и удаляли свой IP, давали доступ всем и только себе, каждый раз безжалостно удаляя труды Терраформа. Когда надо работает, когда не надо - не работает. 
 10. Поделили файлы между двумя папками "prod" и "stage". Забавно, - можно запускаться из каждой из папок. А внутри можно менять правила для файерволла. 
 11. Удалили из папки terraform файлы main.tf, outputs.tf, terraform.tfvars, variables.tf, т.к. они
теперь перенесены в stage и prod. 


# HomeWork 08
## Что мы тут понаписали:

 1. В main.tf мы прописываем провайдера, где разворачиваем машины, читаем имя project и region из variables.ts
 2. Создаём ресурс с именем reddit-app на машине g1-small, за зоной идём в variables.ts Присваиваем тег reddit-app
 3. Добавление SSH ключей для моего пользователя asomirl из места, которое указано в terraform.tfvars, - то есть в public_key_path = "~/.ssh/id_rsa.pub"
 4. Определение загрузочного диска disk_image = "reddit-base-1515001795" снова из terraform.tfvars
 5. Включаем  подключение по ssh с путём к приватному ключу private_key_path = "~/.ssh/id_rsa"
 6. Копируем puma-service из files/puma.service в папку "/tmp/puma.service"
 7. Запуск скрипта деплоя, удалённый запуск через remote-exec скрипт из папки "files/deploy.sh"
 8. Создание правила для firewall с именем allow-puma-default в сети default с открытым доступом по TCP to port 9292 для машин с тегом reddit-app
 9. После выполнения главного скрипта на вывод выйдет то, что описано в  output: IP созданного инстанса. 
 10. Идём по указанному IP с портом 9292 и радуемся жизни. 
 
## Задание с одной звёздочкой

 1. Добавили resource "google_compute_project_metadata" "ssh-asomirl" - хрень, которая добавляет метаданные в проект. 
 2. Сделали добавление двух ключей, вернее, одного ключа с разными именами: от имени asomirl и appuser
 3. В веб-морде добавил appuser_web, но сволочь терраформ нагло его удалил. Да какого >_< 

# HomeWork 07

## Билд с применением файла с переменными

packer build -var-file=variables.json ubuntu16.json

# Homework 06
## Startup script, который будет запускаться для создания инстанса.

gcloud compute instances create reddit-app-3 --zone=europe-west1-d --boot-disk-size=10GB --image-family ubuntu-1604-lts --image-project=ubuntu-os-cloud --machine-type=g1-small --tags puma-server --metadata-from-file startup-script=startup_script.sh --restart-on-failure

## Скрипт создания правил Файрволла для Пума сервера с 9292 портом

gcloud compute --project=infra-189218 firewall-rules create default-puma-server --direction=INGRESS --priority=1000 --network=default --action=ALLOW --rules=tcp:9292 --source-ranges=0.0.0.0/0 --target-tags=puma-server

# HomeWork 05
## Подключение к Someinternalhost в одну строку
 $ ssh -At asomirl@35.205.183.251 ssh 10.132.0.3 Welcome to Ubuntu 16.04.3 LTS (GNU/Linux 4.13.0-1002-gcp x86_64)

Documentation: https://help.ubuntu.com
Management: https://landscape.canonical.com
Support: https://ubuntu.com/advantage
Get cloud support with Ubuntu Advantage Cloud Guest: http://www.ubuntu.com/business/services/cloud

0 packages can be updated. 0 updates are security updates.

Last login: Mon Dec 18 20:46:42 2017 from 10.132.0.2

Подключение в одну команду
На локальной машине прописываем в ~/.ssh/config следующее:

Host bastion Hostname 35.205.183.251 User asomirl CertificateFile ~/ssh/asomirl Host someinternalhost Hostname 10.132.0.3 User asomirl CertificateFile ~/ssh/asomirl ProxyCommand ssh bastion -W %h:%p 

Затем можем подключиться командой

'''ssh someinternalhost'''

Host bastion internal ip 10.132.0.2 external ip 35.205.183.251 Host someinternalhost	internal ip 10.132.0.3

 

