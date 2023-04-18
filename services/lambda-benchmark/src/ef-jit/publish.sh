#!/bin/sh

dotnet publish -c Release -o publish --framework net6.0 -r linux-x64 -p PublishReadyToRun=true --no-self-contained
