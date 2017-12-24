#Homework 06
## Startup script, который будет запускаться для создания инстанса.

gcloud compute --project=infra-189218 firewall-rules create default-puma-server --direction=INGRESS --priority=1000 --network=default --action=ALLOW --rules=tcp:9292 --source-ranges=0.0.0.0/0 --target-tags=puma-server --metadata-from-file startup-script=startup_script.sh
