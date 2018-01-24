#!/bin/bash

git clone https://github.com/Otus-DevOps-2017-11/reddit.git ~/reddit
cd ~/reddit && bundle install
puma -d

#ps -aux | grep puma 
