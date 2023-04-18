# Lambda Benchmark

Funções lambdas para comparação de performace .NET JIT vs AOT.

Esse projeto utiliza a VPC default da account AWS para deploy da Lambda e RDA PostgreSQL.

- [Setup](#setup)
- [Imagem AWS para publish AOT](#imagem-aws-para-publish-aot)
- [Benchmark](#benchmark)
- [Notas](#notas)

## Setup

Configurar diretório no host para compartilhar nuget packages e otimizar build.

```bash
sudo mkdir /tmp/dotnet-aot-docker-volume/
sudo chown 1000 /tmp/dotnet-aot-docker-volume/
```

## Imagem AWS para publish AOT

Image: `public.ecr.aws/sam/build-dotnet7:latest-x86_64`

```bash
dir="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"

docker run --rm \
    --volume "$dir":/tmp/source/ \
    -i \
    -u 1000:1000 \
    -e DOTNET_CLI_HOME=/tmp/dotnet \
    -e XDG_DATA_HOME=/tmp/xdg \
    public.ecr.aws/sam/build-dotnet7:latest-x86_64 \
        dotnet publish "/tmp/source" \
            --output "/tmp/source/publish" \
            --configuration "Release" \
            --framework "net7.0" \
            --self-contained true \
            /p:GenerateRuntimeConfigurationFiles=true \
            --runtime linux-x64 \
            /p:StripSymbols=true
```

Linha de comando dotnet lambda deploy-function

```bash
docker run \
    --name tempLambdaBuildContainer-0b343be4-aabc-4377-ac1c-8cd3ce0be050 \
    --rm \
    --volume "/home/fabio/sources/samples/aws-playground":/tmp/source/ \
    -i \
    -u 1000:1000 \
    -e DOTNET_CLI_HOME=/tmp/dotnet \
    -e XDG_DATA_HOME=/tmp/xdg public.ecr.aws/sam/build-dotnet7:latest-x86_64 \
        dotnet publish "/tmp/source/services/lambda-benchmark/src/basic-aot" \
            --output "/tmp/source/services/lambda-benchmark/src/basic-aot/bin/Release/net7.0/publish" \
            --configuration "Release" \
            --framework "net7.0" \
            --self-contained true \
            /p:GenerateRuntimeConfigurationFiles=true \
            --runtime linux-x64 \
            /p:StripSymbols=true
```

/tmp/dotnet/.nuget/packages/

## Benchmark

Métrica: duration time

| Memória   | JIT cold start    | AOT cold start    | JIT next exec | AOT next exec |
|-----------|-------------------|-------------------|---------------|---------------|
| 256 MB    | 5010.11 ms        | 2259.80 ms        | 243.17 ms     | 22.70 ms      |
| 512 MB    | 2291.14 ms        | 1108.29 ms        | 106.29 ms     | 14.10 ms      |
| 1024 MB   | 1125.59 ms        | 554.04 ms         | 35.63 ms      | 8.94 ms       |

Framework tests - Billed duration com **256 MB RAM**

| Memória       | JIT 1º exec   | AOT 1º exec   | JIT max exe   | AOT max exec  | JIT min exec  | AOT min exec  | JIT Max memory used   | AOT Max memory used   |
|---------------|---------------|---------------|---------------|---------------|---------------|---------------|-----------------------|-----------------------|
| Dapper        | 3019 ms       | n/a           | 151 ms        | n/a           | 15ms          | n/a           | 107 mb                | n/a                   |
| Dapper.AOT    | 2633 ms       | 1286 ms       | 65 ms         | 4 ms          | 9 ms          | 3 ms          | 101 mb                | 115 mb                |
| EF Core       | 6701 ms       | 2604 ms       | 733 m         | 10 ms         | 19ms          | 4 ms          | 127 mb                | 182 mb                |
| Refit         | 1751 ms       | 744 ms        | 198 ms        | 51 ms         | 50ms          | 44 ms         | 79 mb                 | 60 mb                 |

> *n/a: Teste não se aplica no ambiente. Existe outro pacote com outro nome para runtime.*  
> *EF Core: Muita configuração manual no arquivo [rd.xml](src/ef-aot/rd.xml)*

## Notas

112 mb
268 mb

rd.xml
https://github.com/hez2010/EFCore.NativeAOT/blob/master/rd.xml

https://codevision.medium.com/rd-xml-in-corert-43bc69cddf05
https://codevision.medium.com/library-of-rd-xml-files-for-nativeaot-174dcd2438e
https://github.com/kant2002/CoreRtRdXmlExamples/blob/master/SystemTextJsonSerialization/rd.xml

https://learn.microsoft.com/en-us/dotnet/core/deploying/native-aot/warnings/il3050



'Microsoft.EntityFrameworkCore.ChangeTracking.EntryCurrentValueComparer`1[System.Guid]' is missing native code or metadata


Microsoft.EntityFrameworkCore.ChangeTracking.EntryCurrentValueComparer`1[System.Guid]
Microsoft.EntityFrameworkCore.ChangeTracking.ValueComparer+DefaultValueComparer`1[System.Guid]
Npgsql.EntityFrameworkCore.PostgreSQL.Storage.Internal.Mapping.NpgsqlArrayArrayTypeMapping+SingleDimensionalArrayComparer`1[Microsoft.EntityFrameworkCore.LTree]

'Microsoft.EntityFrameworkCore.Infrastructure.ExpressionExtensions.ValueBufferTryReadValue[System.Guid](Microsoft.EntityFrameworkCore.Storage.ValueBuffer&,System.Int32,Microsoft.EntityFrameworkCore.Metadata.IPropertyBase)