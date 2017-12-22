gcloud compute instances create reddit-app-2\ --boot-disk-size=10GB \  --image-family ubuntu-1604-lts \  --image-project=ubuntu-os-cloud \  --zone=europe-west1-d \  --machine-type=g1-small \  --tags puma-server \  --restart-on-failure --metadata startup-script='#!/bin/bash; cd ~
wget https://github.com/Otus-DevOps-2017-11/asomir_infra/blob/Infra-2/startup_script.sh
sudo chmod +x ~/startup_script.sh
sudo sh startup_script.sh
'