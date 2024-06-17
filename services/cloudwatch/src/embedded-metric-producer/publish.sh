#!/bin/sh

dotnet publish -c Release -o publish --framework net8.0 -r linux-x64 -p PublishReadyToRun=true --no-self-contained
