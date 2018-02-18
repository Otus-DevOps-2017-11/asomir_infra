#HomeWork 13
## Разработка и тестирование Ansible ролей и плейбуков
### Локальная разработка с Vagrant

1. Установили VritualBox и Vagrant, в директории ansible создали Vagrantfile с нашими виртуалками app и db:

```buildoutcfg
Vagrant.configure("2") do |config|

  config.vm.provider :virtualbox do |v|
    v.memory = 512 #Столько памяти мы отдадим виртуалке 
  end

  config.vm.define "dbserver" do |db| 
    db.vm.box = "ubuntu/xenial64" # Какую ось ставим?
    db.vm.hostname = "dbserver"
    db.vm.network :private_network, ip: "10.10.10.10" # Внутренний айпишник
  end
  
  config.vm.define "appserver" do |app|
    app.vm.box = "ubuntu/xenial64"
    app.vm.hostname = "appserver"
    app.vm.network :private_network, ip: "10.10.10.20"
  end
end
```
2. Проверим, что бокс скачался 
```bash
vagrant box list 
```
Проверим статус VMs:

```bash
vagrant status 
```

Проверим SSH доступ к appservder  и пинганём dbserver 

```bash
$ vagrant ssh appserver
ubuntu@appserver:~$ ping -c 2 10.10.10.20 
```
### Провижининг

3. Добавили провижинер ансамбля 

```yamlex
db.vm.provision "ansible" do |ansible|
    ansible.playbook = "playbooks/site.yml"
    ansible.groups = {
    "db" => ["dbserver"],
    "db:vars" => {"mongo_bind_ip" => "0.0.0.0"}
}
end
```

Запустили провижининг,
 
```bash
$ vagrant provision dbserver
``` 
 
 Но необходим питон. Создали файлик base.ym в папку с плейбуками, который сразу внесли в site.yml

```yamlex

---
- name: Check && install python
  hosts: all
  become: true
  gather_facts: False

  tasks:
    - name: Install python for Ansible
      raw: test -e /usr/bin/python || (apt -y update && apt install -y python-minimal)
      changed_when: False
```

Добавили install_mongo.yml

```yamlex
- name: Add APT key
  apt_key:
    id: "EA312927"
    keyserver: keyserver.ubuntu.com
  tags: install

- name: Add APT repository
  apt_repository:
    repo: deb [ arch=amd64,arm64 ] http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 multiverse
    state: present
  tags: install

- name: Install mongodb package
  apt:
    name: mongodb-org
    state: present
  tags: install

- name: Configure service supervisor
  systemd:
    name: mongod
    enabled: yes
    state: started
  tags: install
```

И config_mongo.yml

```yamlex

---
- name: Change mongo config file
  template:
    src: templates/mongod.conf.j2
    dest: /etc/mongod.conf
    mode: 0644
  notify: restart mongod
```
4. Вызываем таск вначале инсталляции Монги, затем её конфигурирования:

db/tasks/main.yml 
```yamlex
# tasks file for db
- name: Show info about the env this host belongs to
 debug:
 msg: "This host is in {{ env }} environment!!!"
- include: install_mongo.yml
- include: config_mongo.yml 
```

5. Применим роль для локальной машины dbserver: 

```bash
$ vagrant provision dbserver
```
6. Заходим по SSH на appserver

```bash
$ vagrant ssh appserver
```
и проверяем телнетом доступность порта 27017

```bash
ubuntu@appserver:~$ telnet 10.10.10.10 27017
``` 

7. Включим в нашу роль app конфигурацию из packer_app.yml плейбука, необходимую для настройки хоста приложения
Создаём файл для тасков ruby.yml внутри роли app и копируем в него ТАСКИ из плейбука packer_app.yml

```yamlex
- name: Install ruby and rubygems and required packages
  apt: "name={{ item }} state=present"
  with_items:
    - ruby-full
    - ruby-bundler
    - build-essential
  tags: ruby
```

8. Настройки puma сервера вынесли в отдельный файл для тасков

```yamlex
- name: Add unit file for Puma
  copy:
    src: puma.service
    dest: /etc/systemd/system/puma.service
  notify: restart puma

- name: Add config for DB connection
  template:
    src: db_config.j2
    dest: /home/appuser/db_config
    owner: appuser
    group: appuser

- name: enable puma
  systemd: name=puma enabled=yes
```

9. В файле app/tasks/main.yml вызываем таски в нужном порядке:

```yamlex
- name: Show info about the env this host belongs to
 debug:
 msg: "This host is in {{ env }} environment!!!"
- include: ruby.yml
- include: puma.yml 
```

### Провижиним appserver

10. В ansible/Vagrantfile определяем ансибл провижининг аппсервера 

```yamlex
Vagrant.configure("2") do |config|

  config.vm.provider :virtualbox do |v|
    v.memory = 512
  end

  config.vm.define "dbserver" do |db|
    db.vm.box = "ubuntu/xenial64"
    db.vm.hostname = "dbserver"
    db.vm.network :private_network, ip: "10.10.10.10"

    db.vm.provision "ansible" do |ansible|
      ansible.playbook = "playbooks/site.yml"
      ansible.groups = {
      "db" => ["dbserver"],
      "db:vars" => {"mongo_bind_ip" => "0.0.0.0"}
      }
    end
  end

  config.vm.define "appserver" do |app|
    app.vm.box = "ubuntu/xenial64"
    app.vm.hostname = "appserver"
    app.vm.network :private_network, ip: "10.10.10.20"

    app.vm.provision "ansible" do |ansible|
      ansible.playbook = "playbooks/site.yml"
      ansible.groups = {
      "app" => ["appserver"],
      "app:vars" => { "db_host" => "10.10.10.10"}
      }
    end
  end
end
```

11. Применили провижининг:

```bash
$ vagrant provision appserver
```
12. Добавим переменные по умолчанию внутри роли app/defaults/main.yml 

```yamlex
db_host: 127.0.0.1
env: local
deploy_user: appuser 
```

13. В app/tasks/puma.yml добавили унит темплейтом дзындзи

```yamlex
- name: Add unit file for Puma
 template:
 src: puma.service.j2
 dest: /etc/systemd/system/puma.service
 notify: reload puma
```

14. Переместили unit из директории app/files в директорию app/templates и переименовали в puma.service.j2
В созданном шаблоне поменяли все упоминания appuser на переменную deploy_user

app/templates/puma.service.j2 

```buildoutcfg
[Unit]
Description=Puma HTTP Server
After=network.target
[Service]
Type=simple
EnvironmentFile=/home/{{ deploy_user }}/db_config
User={{ deploy_user }}
WorkingDirectory=/home/{{ deploy_user }}/reddit
ExecStart=/bin/bash -lc 'puma'
Restart=always
[Install]
WantedBy=multi-user.target
```
15. То же самое сделаем в app/tasks/puma.yml

```yamlex
- name: Add unit file for Puma
 template:
 src: puma.service.j2
 dest: /etc/systemd/system/puma.service
 notify: reload puma
- name: Add config for DB connection
 template:
 src: db_config.j2
 dest: "/home/{{ deploy_user }}/db_config"
 owner: "{{ deploy_user }}"
 group: "{{ deploy_user }}"
- name: enable puma
 systemd: name=puma enabled=yes 
```

16. ansible/playbooks/deploy.yml 

```yamlex
- name: Deploy App
 hosts: app
 vars:
 deploy_user: appuser
 tasks:
 - name: Fetch the latest version of application code
 git:
 repo: 'https://github.com/Otus-DevOps-2017-11/reddit.git'
 dest: "/home/{{ deploy_user }}/reddit"
 version: monolith
 notify: restart puma
 - name: bundle install
 bundler:
 state: present
 chdir: "/home/{{ deploy_user }}/reddit"
handlers:
 - name: restart puma
 become: true
 systemd: name=puma state=restarted
```

### Переопределение переменных

17. Добавим extra_vars переменные в блок определения провижинера в Vagrantfile
extra_vars имеют самый высокий приоритет перед остальными.


```yamlex
Vagrant.configure("2") do |config|

  config.vm.provider :virtualbox do |v|
    v.memory = 512
  end

  config.vm.define "dbserver" do |db|
    db.vm.box = "ubuntu/xenial64"
    db.vm.hostname = "dbserver"
    db.vm.network :private_network, ip: "10.10.10.10"

    db.vm.provision "ansible" do |ansible|
      ansible.playbook = "playbooks/site.yml"
      ansible.groups = {
      "db" => ["dbserver"],
      "db:vars" => {"mongo_bind_ip" => "0.0.0.0"}
      }
    end
  end

  config.vm.define "appserver" do |app|
    app.vm.box = "ubuntu/xenial64"
    app.vm.hostname = "appserver"
    app.vm.network :private_network, ip: "10.10.10.20"

    app.vm.provision "ansible" do |ansible|
      ansible.playbook = "playbooks/site.yml"
      ansible.groups = {
      "app" => ["appserver"],
      "app:vars" => { "db_host" => "10.10.10.10"}
      }
      ansible.extra_vars = {
        "deploy_user" => "ubuntu"
      }
    end
  end
end
```

### Проверка роли

18. Применим провижининг для хоста appserver:

```bash
$ vagrant provision appserver
```
19. Перепроверяем. Удаляем созданные машины, создаём окружение снова 

```bash
$ vagrant destroy -f 
$ vagrant up 
```
### Установка зависимостей 

20. В файл ansible/requirements.txt добавили

```buildoutcfg
ansible>=2.4
molecule>=2.6
testinfra>=1.10
python-vagrant>=0.5.15 
```

21. Устанавливаем: 

```bash
 pip install -r requirements.txt
 
```

### Тестирование db роли

22. Используем команду molecule init для создания заготовки тестов для роли db. Выполнили команду ниже в директории с ролью ansible/roles/db
Указываем Vagrant как драйвер для создания VMs

```bash
$ molecule init scenario --scenario-name default -r db -d vagrant 
```

23. Добавим несколько тестов, используя модули Testinfra, для
проверки конфигурации, настраиваемой ролью db

db/molecule/default/tests/test_default.py 

```python
import os

import testinfra.utils.ansible_runner

testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
    os.environ['MOLECULE_INVENTORY_FILE']).get_hosts('all')

# check if MongoDB is enabled and running
def test_mongo_running_and_enabled(host):
    mongo = host.service("mongod")
    assert mongo.is_running
    assert mongo.is_enabled

# check if configuration file contains the required line
def test_config_file(File):
    config_file = File('/etc/mongod.conf')
    assert config_file.contains('bindIp: 0.0.0.0')
    assert config_file.is_file
```

24. Описание тестовой машины, которая создается Molecule для тестов
содержится в файле db/molecule/default/molecule.yml

```yamlex
driver:
 name: vagrant
 provider:
 name: virtualbox
lint:
 name: yamllint
platforms:
 - name: instance
 box: ubuntu/xenial64
provisioner:
 name: ansible
 lint:
 name: ansible-lint
```

25. Создаём тестовую машину и Посмотрим список созданных инстансов, которыми управляет Molecule: 

```bash
$ molecule create 
$ molecule list 
```

### Тестирование роли

26. Подключаемся внутрь нашей машины 

```bash
$ molecule login -h instance
```

27. Molecule init генерирует плейбук для применения нашей роли. Данный плейбук можно посмотреть по
пути. Добавим туда суперпользователя, Дополнительно зададим еще переменную
mongo_bind_ip.

db/molecule/default/playbook.yml

```yamlex
- name: Converge
 become: true
 hosts: all
 vars:
 mongo_bind_ip: 0.0.0.0
 roles:
 - role: db
```


28. Применим playbook.yml, в котором вызывается наша роль к
созданному хосту:

```bash
$ molecule converge
```

29. Прогоняем тесты

```bash
$ molecule verify 
```

### Самостоятельная работа

1. Написали тест к роли db для проверки того, что БД слушает по
нужному порту (27017)

```python
# check if mongoDB is listening 27017 port
def test_mongo_listening_27017(host):
    assert host.socket('tcp://0.0.0.0:27017').is_listening
```

2. Для установки руби и запуска бандлера, а также установки монги в пакере использовали роль app и db

```yamlex
- name: Install Ruby && Bundler
  hosts: all
  become: true
  roles:
    app

```

```yamlex
# Создаём пакером имидж Монги
- name: Install MongoDB 3.2
  hosts: all
  become: true
  roles:
    db
```

3. В packer/db.json добавили 

```yamlex
  "provisioners": [
    {
      "type": "ansible",
      "playbook_file": "../ansible/playbooks/packer_db.yml",
      "ansible_env_vars": [
        "ANSIBLE_ROLES_PATH={{ pwd }}/ansible/roles"
      ]
    }
  ]
```

В packer/app.json добавили 


```yamlex
  "provisioners": [
    {
      "type": "ansible",
      "playbook_file": "../ansible/playbooks/packer_app.yml",
      "extra_arguments": ["--tags","build-date,ruby"],
      "ansible_env_vars": ["ANSIBLE_ROLES_PATH={{ pwd }}/ansible/roles"]
    }
  ]

```


# HomeWork 12
## Как я получил эту роль...
### Структура ролей

1. В одной далёкой-далёкой галактике в директории ansible была создана папка roles, где были выполнены команды 
```bash
$ ansible-galaxy init app
$ ansible-galaxy init db
```
В результате взрыва этих сверхновых команд мы получили две новых суперструктуры 

```markdown
db
├── README.md
├── defaults #Где хранятся переменные по умолчанию
│   └── main.yml 
├── handlers
│   └── main.yml
├── meta
│   └── main.yml #Где хранится роль о самом создателе
├── tasks # Где можно узнать, какие задачи нам уготовлены
│   └── main.yml
├── tests
│   ├── inventory
│   └── test.yml
└── vars #Территория переменных, которые никогда не должны переопределяться
 └── main.yml 
```

2. Секция таск откололась от ansible/db.yml и прилетела прямо в файл в директории tasks роли db

```yamlex
# tasks file for db
- name: Change mongo config file
  template:
    src: templates/mongod.conf.j2
    dest: /etc/mongod.conf
    mode: 0644
  notify: restart mongod
```
3. Тем временем в новую директорию для шаблонов templates в директории роли ansble/roles/db был скопирован
шаблонизированный конфиг для MongoDB из директории ansible/templates. Особенностью ролей также является, что модули template и copy,
которые используются в тасках роли, Ansible будут по умолчанию проверять наличие шаблонов и файлов в директориях роли
templates и files соответсвенно. 

```yamlex
# tasks file for db
- name: Change mongo config file
 template:
     src: mongod.conf.j2
     dest: /etc/mongod.conf
     mode: 0644
 notify: restart mongod
```
4. А хендлер получил своё собственное конечное назначение ansible/roles/db/handlers/main.yml

```yamlex
- name: restart mongod
  service: name=mongod state=restarted
```

5. Директорию ansible/roles/db/defaults/main.yml заняла коварная стайка переменных по умолчанию. Узнаем же, о чём они молчат: 

```yamlex
# defaults file for db
mongo_port: 27017
mongo_bind_ip: 127.0.0.1
```

6. Вивисекция tasks из сценария плейбука ansible/app.yml была вставлена в файл для тасков роли app.
При этом src в модулях copy и template были указаны только имена файлов.
ansible/roles/app/tasks/main.yml 
```yamlex
# tasks file for app
- name: Add unit file for Puma
  copy:
     src: puma.service
     dest: /etc/systemd/system/puma.service
     notify: restart puma
- name: Add config for DB connection
  template:
     src: db_config.j2
     dest: /home/appuser/db_config
     owner: appuser
     group: appuser
- name: enable puma
  systemd: name=puma enabled=yes
```

7. В директории роли ansible/roles/app появились директории для шаблонов и файлов: templates & files, куда были немедленно присланы в директории роли
db_config.j2 и puma.service.

8. В ansible/roles/app/handlers/main.yml немедленно отправился хендлер 

```yamlex
# handlers file for app
- name: restart puma
  systemd: name=puma state=restarted
```
9. Была определена переменная по умолчанию в ansible/roles/app/defaults/main.yml для задания адреса подключения к MongoDB:

```yamlex
# defaults file for app
db_host: 127.0.0.1
```

### Вызов ролей

10. Сегодня роли  выглядят совершенно иначе:
ansible/app.yml

```yamlex
- name: Configure App
  hosts: app
  become: true
  vars:
   db_host: 10.132.0.2
  roles:
    - app
``` 
ansible/db.yml 

```yamlex
- name: Configure MongoDB
  hosts: db
  become: true
  vars:
    mongo_bind_ip: 0.0.0.0
  roles:
    - db
```
### Проверка ролей

11. Пора проверить код на прочность: 
```bash
$ ansible-playbook site.yml --check
$ ansible-playbook site.yml
```

### Окружения 

12. Была создана ansible/environments, внутри две директории для наших окружений stage и prod, внутри по файлу inventory из директории ansible.
13. И начался деплой на на prod окружении:

```bash
$ ansible-playbook -i environments/prod/inventory deploy.yml
```

A стейдж стал окружением по умолчанию: 
ansible/ansible.cfg 

```buildoutcfg
[defaults]
inventory = ./environments/stage/inventory
remote_user = appuser
private_key_file = ~/.ssh/appuser
host_key_checking = False
```
14. Создадим директорию group_vars в директориях наших окружений. Скопируем в файл переменные, определенные в
плейбуке ansible/app.yml. 
ansible/environments/stage/group_vars/app 
```buildoutcfg
db_host: 10.132.0.2
```
ansible/environments/stage/group_vars/db 
```buildoutcfg
mongo_bind_ip: 0.0.0.0
```
15. Файл с переменными для  группы all, которые будут доступны всем хостам окружения
ansible/environments/stage/group_vars/all 

```buildoutcfg
env: stage
```

prod/group_vars/all

```buildoutcfg
env: prod
```

16. Для дебага используем модуль debug для вывода значения переменной окружения
ansible/roles/app/tasks/main.yml
ansible/roles/db/tasks/main.yml

```yamlex
# tasks file for app
- name: Show info about the env this host belongs to
 debug:
 msg: "This host is in {{ env }} environment!!!"
```

17. Зачистили папку энсибл от старого хлама. В папке ansible из файлов остается
только ansible.cfg и requirements.txt

18. Наложили магию улучшения на ansible.cfg 

```buildoutcfg
[defaults]
inventory = ./environments/stage/inventory
remote_user = appuser
private_key_file = ~/.ssh/appuser
host_key_checking = False
roles_path = ./roles # где роли, Билли?
retry_files_enabled = False # нам больше не нужны ретри файлы
[diff]
always = True # diff фарева!
context = 5 
```

19. Раскатаем всю силу нашей магии в прод

```bash
 ansible-playbook -i environments/prod/inventory playbooks/site.yml --check
$ ansible-playbook -i environments/prod/inventory playbooks/site.yml
```

### Коммьюнити роли

20. Используем всю мощь и силу jdauphant.nginx из ansible-galaxy  и настроим
проксирование нашего приложения с помощью nginx. Создадим файлы environments/stage/
requirements.yml и environments/prod/requirements.yml а внутри

```yamlex
- src: jdauphant.nginx
version: v2.13
```

21. РОЛЬ УСТАНОВИСЯ!

```bash
ansible-galaxy install -r environments/stage/requirements.yml
```

22. Добавим в stage/group_vars/app и prod/group_vars/app кунгфу переменных 

```buildoutcfg
nginx_sites:
 default:
 - listen 80
 - server_name "reddit"
 - location / {
 proxy_pass http://127.0.0.1:9292;
 }
```
### Самостоятельная магия
23. В терраформе в модуле апп добавили 80 порт

```hcl-terraform
# Создание правила для firewall
resource "google_compute_firewall" "firewall_puma" {
  name    = "allow-puma-default"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80", "9292"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["reddit-app"]
}
```

24. Добавили вызов магии jdauphant.nginx в app.yml

```yamlex
- name: Configure App
  hosts: app
  become: true

  roles:
    - app
    - jdauphant.nginx
```
25. Применили магию скрижали site.yml для окружения stage - приложение теперь доступно на 80 порту! Это победа светлой магии! 


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
