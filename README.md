#Homework 06
## Startup script, который будет запускаться для создания инстанса.

gcloud compute instances create reddit-app-3 --zone=europe-west1-d --boot-disk-size=10GB --image-family ubuntu-1604-lts --image-project=ubuntu-os-cloud --machine-type=g1-small --tags puma-server --metadata-from-file startup-script=startup_script.sh --restart-on-failure

##Скрипт создания правил Файрволла для Пума сервера с 9292 портом
gcloud compute --project=infra-189218 firewall-rules create default-puma-server --direction=INGRESS --priority=1000 --network=default --action=ALLOW --rules=tcp:9292 --source-ranges=0.0.0.0/0 --target-tags=puma-server 
