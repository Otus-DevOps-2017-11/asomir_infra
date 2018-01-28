# HomePorn 11
## В большой инфраструктуре клювом нихьт клац-клац:

1. Создали reddit_app.yml, куда зафигачили немножко конфигурации нашего приложения и бд. Неплохо приложились. 
2. Копируем конфиг монги на удалённый инстанс с помощью модуля темплейт и добавляем тег,  чтобы иметь возможность запускать отдельные таски, имеющие
определенный тег, а не запускать таски все сразу. 
```yaml
template:
 src: templates/mongod.conf.j2
 dest: /etc/mongod.conf
 mode: 0644
tags: db-tag 
```

3. Создали директорию templates внутри директории ansible, где создали файл mongod.conf.j2 и засунули внутрь параметризированный шаблон

```yaml
# Where and how to store data.
storage:
 dbPath: /var/lib/mongodb
 journal:
 enabled: true
# where to write logging data.
systemLog:
 destination: file
 logAppend: true
 path: /var/log/mongodb/mongod.log
# network interfaces
net:
 port: {{ mongo_port | default('27017') }}
 bindIp: {{ mongo_bind_ip }} 
```
4. Добавили Handler 
```yaml
handlers:
 - name: restart mongod
 become: true
 service: name=mongod state=restarted
```
5. Построили редут. Добавили в наш сценарий таск для копирования файла Unit только теперь с помощью ансибла. Для копирования используем модуль copy, для автостарта используем модуль systemd (нупачимунельзятакбылораньшесделать, а? кровьбольслёзы):

```yaml
- name: Add unit file for Puma
 become: true
 copy:
 src: files/puma.service
 dest: /etc/systemd/system/puma.service
 tags: app-tag
 notify: reload puma
 - name: enable puma
 become: true
 systemd: name=puma enabled=yes
 tags: app-tag
```

6. Добавляем хендлер, который перечитает юнит: 
```yaml
- name: reload puma
 become: true
 systemd: name=puma state=reloaded
```
7. Создали шаблон в директории templates/db_config.j2 куда добавили DATABASE_URL={{ db_host }} - присвоение
переменной DATABASE_URL значения, которое мы передаем через Ansible переменную db_host.

8. Копируем созданный шаблон в аппликуху: 

```yaml
 - name: Add config for DB connection
 template:
 src: templates/db_config.j2
 dest: /home/appuser/db_config
 tags: app-tag 
```

9. Deploy приложопушки и установка зависимостей с помощью модулей гит и бундлер: 

```yaml
- name: Fetch the latest version of application code
 git:
 repo: 'https://github.com/Otus-DevOps-2017-11/reddit.git'
 dest: /home/appuser/reddit
 version: monolith
 tags: deploy-tag
 notify: restart puma
 - name: Bundle install
 bundler:
 state: present
 chdir: /home/appuser/reddit
 tags: deploy-tag 
```

10. Парашютики не забываем: 

```yaml
- name: restart puma
 become: true
 systemd: name=puma state=restarted
```

11. Ненене, так нельзя, так неудобно, давайте делать один плейбук и несколько сценариев
 Сценарий для монгушки:
```yaml
- name: Configure MongoDB
 hosts: db
 tags: db-tag
 become: true
 vars:
 mongo_bind_ip: 0.0.0.0
 tasks:
 - name: Change mongo config file
 template:
 src: templates/mongod.conf.j2
 dest: /etc/mongod.conf
 mode: 0644
 notify: restart mongod
 handlers:
 - name: restart mongod
 service: name=mongod state=restarted
```

 Сценарий для аплижопушки: 
 ```yaml
ansible/reddit_app2.yml
- name: Configure App
 hosts: app
 tags: app-tag
 become: true
 vars:
 db_host: 10.132.0.2
 tasks:
 - name: Add unit file for Puma
 copy:
 src: files/puma.service
 dest: /etc/systemd/system/puma.service
 notify: reload puma
 - name: Add config for DB connection
 template:
 src: templates/db_config.j2
 dest: /home/appuser/db_config
 owner: appuser
 group: appuser
 - name: enable puma
 systemd: name=puma enabled=yes
 handlers:
 - name: reload puma
 systemd: name=puma state=reloaded
```

12. Пересоздали инфраструктуру терраформом, проверили работу сценариев, создали сценарий для работы приложеня в плейбук reddit_app2.yml.
13. Ненене, так нельзя! Давайте сделаем несколько отдельных плейбуков, а старое вообще переименуем:
reddit_app.yml -> reddit_app_one_play.yml
reddit_app2.yml-> reddit_app_multiple_plays.yml
14. В директории ansible три новых файлаapp.yml, db.yml, deploy.yml. Перенесём из больших плейбуков всё соответственно в маленькие и уберём оттудах нахрен теги!
15. Опять накернем инфраструктуру на известный орган. И пересоздадим всё заново.
16. Пора провижининг в покер менять! Прибьём наших старых баш-друзей для установки Руби и Бундлера и сделаем packer_app.yml. А для MongoDB packer_db.yml
17. Заменим секцию Provision в образе app.json на Ansible
```yaml
"provisioners": [
 {
 "type": "ansible",
 "playbook_file": "../ansible/packer_app.yml",
 }
 ]
```
18. Такие же изменения выполним и для db.json
```yaml
"provisioners": [
 {
 "type": "ansible",
 "playbook_file": "../ansible/packer_db.yml",
 }
 ]
```
19. Выполнили билд образов с помощью нового провижинера и на их основе запустили стейдж. Запустили плейбук site.yml.
20. Это невозможно! Просто нереально! Всё работает, всё запустилось, всё работает, можно написать на сайтике красивые слова о любви и радоваться!



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

 

