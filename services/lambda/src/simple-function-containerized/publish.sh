#!/bin/sh

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 452970698287.dkr.ecr.us-east-1.amazonaws.com
docker build -t 452970698287.dkr.ecr.us-east-1.amazonaws.com/simple-function-containerized:latest .
docker push 452970698287.dkr.ecr.us-east-1.amazonaws.com/simple-function-containerized:latest