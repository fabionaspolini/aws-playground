#!/bin/sh
account_id=$1

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $account_id.dkr.ecr.us-east-1.amazonaws.com
docker build -t $account_id.dkr.ecr.us-east-1.amazonaws.com/simple-function-containerized:latest .
docker push $account_id.dkr.ecr.us-east-1.amazonaws.com/simple-function-containerized:latest