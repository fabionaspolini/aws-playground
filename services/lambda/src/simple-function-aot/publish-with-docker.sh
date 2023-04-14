#!/bin/sh
# docker run --name tempLambdaBuildContainer-c0b2dbc4-96a5-4e05-873b-9db0dd224805 \
#     --rm \
#     --volume "/home/fabio/sources/samples/aws-playground":/tmp/source/ \
#     -i -u 1000:1000 \
#     -e DOTNET_CLI_HOME=/tmp/dotnet \
#     -e XDG_DATA_HOME=/tmp/xdg public.ecr.aws/sam/build-dotnet7:latest-x86_64 \
#     dotnet publish "/tmp/source/services/lambda/src/simple-function-aot" \
#         --output "/tmp/source/services/lambda/src/simple-function-aot/bin/Release/net7.0/publish" \
#         --configuration "Release" \
#         --framework "net7.0" \
#         --self-contained true \
#         /p:GenerateRuntimeConfigurationFiles=true \
#         --runtime linux-x64 \
#         /p:StripSymbols=true
#     public.ecr.aws/sam/build-dotnet7:latest-x86_64