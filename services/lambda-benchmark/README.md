# Lambda Benchmark

Funções lambdas para comparação de performace .NET JIT vs AOT.

Esse projeto utiliza a VPC default da account AWS para deploy da Lambda e RDA PostgreSQL.

- [Setup](#setup)
- [Imagem AWS para publish AOT](#imagem-aws-para-publish-aot)
- [Benchmark](#benchmark)
  - [1. Função simples com um log + string upper case - **256 MB RAM**](#1-função-simples-com-um-log--string-upper-case---256-mb-ram)
  - [2. Ler variável de ambiente + consultar tabela no PostgreSQL + formatação data + imprimir linhas no stdout - **256 MB RAM**](#2-ler-variável-de-ambiente--consultar-tabela-no-postgresql--formatação-data--imprimir-linhas-no-stdout---256-mb-ram)
  - [3. Framework tests - **256 MB RAM**](#3-framework-tests---256-mb-ram)
  - [4. Refazer - Usar várias libs .NET](#4-refazer---usar-várias-libs-net)
- [rd.xml](#rdxml)
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
```

Linha de comando utilizada pelo cli `dotnet lambda deploy-function`:

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

## Benchmark

Métrica: Tempo total (init + duration)

### 1. Função simples com um log + string upper case - **256 MB RAM**

| Runtime       | 1º exec   | max exec  | min exec  | Max memory used   |
|---------------|-----------|-----------|-----------|-------------------|
| .NET 6 JIT    | 429 ms    | 12 ms     | 2 ms      | 65 mb             |
| .NET 7 AOT    | 314 ms    | 2 ms      | 1 ms      | 46 mb             |
| Python 3.9    | 122 ms    | 3 ms      | 2 ms      | 37 mb             |
| NodeJS 18     | 233 ms    | 2 ms      | 2 ms      | 69 mb             |

### 2. Ler variável de ambiente + consultar tabela no PostgreSQL + formatação data + imprimir linhas no stdout - **256 MB RAM**

| Runtime       | 1º exec   | max exec  | min exec  | Max memory used   |
|---------------|-----------|-----------|-----------|-------------------|
| .NET 6 JIT    | 2661 ms   | 41 ms     | 5 ms      | 100 mb            |
| .NET 7 AOT    | 1262 ms   | 4 ms      | 3 ms      |                   |
| Python 3.9    | 436 ms    | 52 ms     | 36 ms     | 51 mb             |
| NodeJS 18     |           |           |           |                   |

### 3. Framework tests - **256 MB RAM**

| Framework     | JIT 1º exec   | AOT 1º exec   | JIT max exec  | AOT max exec  | JIT min exec  | AOT min exec  | JIT Max memory used   | AOT Max memory used   |
|---------------|---------------|---------------|---------------|---------------|---------------|---------------|-----------------------|-----------------------|
| Dapper        | 3019 ms       | n/a           | 151 ms        | n/a           | 15 ms         | n/a           | 107 mb                | n/a                   |
| Dapper.AOT    | 2633 ms       | 1286 ms       | 65 ms         | 4 ms          | 9 ms          | 3 ms          | 101 mb                | 115 mb                |
| EF Core       | 6701 ms       | 2604 ms       | 733 m         | 10 ms         | 19 ms         | 4 ms          | 127 mb                | 182 mb                |
| Refit         | 1751 ms       | 744 ms        | 198 ms        | 51 ms         | 50 ms         | 44 ms         | 79 mb                 | 60 mb                 |
| Npgsql        | 2540 ms       | 1156 ms       | 39 ms         | 4 ms          | 11 ms         | 3 ms          | 95 mb                 | 116 mb                |

> *n/a: Teste não se aplica no ambiente. Existe outro pacote com outro nome para runtime.*  
> ***EF Core:** Muita configuração manual no arquivo [rd.xml](src/ef-aot/rd.xml). A solução é muito sensível e varia conforme design da classe sendo persistida. **Não recomendado ir para produção**.*


### 4. Refazer - Usar várias libs .NET

| Memória   | JIT cold start    | AOT cold start    | JIT next exec | AOT next exec |
|-----------|-------------------|-------------------|---------------|---------------|
| 256 MB    | 5010.11 ms        | 2259.80 ms        | 243.17 ms     | 22.70 ms      |
| 512 MB    | 2291.14 ms        | 1108.29 ms        | 106.29 ms     | 14.10 ms      |
| 1024 MB   | 1125.59 ms        | 554.04 ms         | 35.63 ms      | 8.94 ms       |

## rd.xml

[Runtime directives (rd.xml) configuration file reference](https://learn.microsoft.com/en-us/windows/uwp/dotnet-native/runtime-directives-rd-xml-configuration-file-reference)

Quando a biblioteca não está preparada para build AOT é necessário informar neste arquivo as classes e métodos acessados dinamicamente com generics para não haver a otimização e ofuscação do mesmo no build nativo.

No arquivo `.csproj` adicione:

```xml
<ItemGroup>
    <RdXmlFile Include="rd.xml" />
</ItemGroup>
```

Exemplo de arquivo [rd.xml](src/ef-aot/rd.xml).

Exemplos de erros por falta de configuração do rd.xml em runtime:

```log
- 'Microsoft.EntityFrameworkCore.ChangeTracking.EntryCurrentValueComparer`1[System.Guid]' is missing native code or metadata. This can happen for code that is not compatible with trimming or AOT. Inspect and fix trimming and AOT related warnings that were generated when the app was published. For more information see https://aka.ms/nativeaot-compatibility
- 'Microsoft.EntityFrameworkCore.ChangeTracking.EntryCurrentValueComparer`1[System.Guid]' is missing native code or metadata...
- 'Microsoft.EntityFrameworkCore.ChangeTracking.EntryCurrentValueComparer`1[System.Guid]'...
- 'Microsoft.EntityFrameworkCore.ChangeTracking.ValueComparer+DefaultValueComparer`1[System.Guid]'...
- 'Npgsql.EntityFrameworkCore.PostgreSQL.Storage.Internal.Mapping.NpgsqlArrayArrayTypeMapping+SingleDimensionalArrayComparer`1[Microsoft.EntityFrameworkCore.LTree]'...
- 'Microsoft.EntityFrameworkCore.Infrastructure.ExpressionExtensions.ValueBufferTryReadValue[System.Guid](Microsoft.EntityFrameworkCore.Storage.ValueBuffer&,System.Int32,Microsoft.EntityFrameworkCore.Metadata.IPropertyBase)'...
```


## Notas

https://github.com/hez2010/EFCore.NativeAOT/blob/master/rd.xml

https://codevision.medium.com/rd-xml-in-corert-43bc69cddf05
https://codevision.medium.com/library-of-rd-xml-files-for-nativeaot-174dcd2438e
https://github.com/kant2002/CoreRtRdXmlExamples/blob/master/SystemTextJsonSerialization/rd.xml

https://learn.microsoft.com/en-us/dotnet/core/deploying/native-aot/warnings/il3050
