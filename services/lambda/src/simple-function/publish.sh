#!/bin/sh

dotnet publish -c Release -o publish --framework net6.0 -r linux-musl-x64 -p PublishReadyToRun=true --no-self-contained
