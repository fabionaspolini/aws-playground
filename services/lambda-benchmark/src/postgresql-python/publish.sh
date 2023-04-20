#!/bin/sh
pip install -r requirements.txt --target ./packages

mkdir -p ./publish/
cp -r ./packages/* ./publish/
cp *.* ./publish/