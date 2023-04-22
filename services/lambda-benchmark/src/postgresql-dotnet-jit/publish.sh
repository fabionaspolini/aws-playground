#!/bin/sh
# rm -rf bin/Release/publish
dotnet publish \
    -c Release \
    -o bin/Release/publish \
    --framework net6.0 \
    -r linux-x64 \
    -p PublishReadyToRun=true \
    --no-self-contained
