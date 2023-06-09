#!/bin/sh
dir="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
# rm -rf "$dir/bin/Release/publish"
docker run --rm \
    --volume "$dir":/tmp/source/ \
    --volume "/tmp/dotnet-aot-docker-volume":/tmp/dotnet/ \
    -i \
    -u 1000:1000 \
    -e DOTNET_CLI_HOME=/tmp/dotnet \
    -e XDG_DATA_HOME=/tmp/xdg \
    public.ecr.aws/sam/build-dotnet7:latest-x86_64 \
        dotnet publish "/tmp/source" \
            --output "/tmp/source/bin/Release/publish" \
            --configuration "Release" \
            --framework "net7.0" \
            --self-contained true \
            /p:GenerateRuntimeConfigurationFiles=true \
            --runtime linux-x64 \
            /p:StripSymbols=true
