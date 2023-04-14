#!/bin/sh

dotnet publish \
    --output "publish" \
    --configuration "Release" \
    --framework "net7.0" \
    --self-contained true \
    /p:GenerateRuntimeConfigurationFiles=true \
    --runtime linux-x64 \
    /p:StripSymbols=true