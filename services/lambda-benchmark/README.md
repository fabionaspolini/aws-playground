# Lambda Benchmark

Funções lambdas para comparação de performace .NET JIT vs AOT.

Esse projeto utiliza a VPC default da account AWS para deploy da Lambda e RDA PostgreSQL.

## benchmark-data-access

Métrica: duration time

| Memória   | JIT cold start    | AOT cold start    | JIT next call | AOT next call |
|-----------|-------------------|-------------------|---------------|---------------|
| 256 MB    | 5010.11 ms        | 2259.80 ms        | 243.17 ms     | 22.70 ms      |
| 512 MB    | 2291.14 ms        | 1108.29 ms        | 106.29 ms     | 14.10 ms      |
| 1024 MB   | 1125.59 ms        | 554.04 ms         | 35.63 ms      | 8.94 ms       |


## aot tests

112 mb
268 mb

rd.xml
https://codevision.medium.com/rd-xml-in-corert-43bc69cddf05
https://codevision.medium.com/library-of-rd-xml-files-for-nativeaot-174dcd2438e
https://github.com/kant2002/CoreRtRdXmlExamples/blob/master/SystemTextJsonSerialization/rd.xml