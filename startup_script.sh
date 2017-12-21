#!/bin/bash

sudo apt get update
sudo apt get install -y git-core
cd ~
git clone https://github.com/Otus-DevOps-2017-11/asomir_infra.git
cd ~/asomir_infra 
git checkout Infra-2
sudo chmod install_ruby.sh
sudo chmod install_mongo.sh
sudo chmod deploy.sh
install_ruby.sh
install_mongo.sh
deploy.sh