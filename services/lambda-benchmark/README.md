# Lambda Benchmark

Funções lambdas para comparação de performace .NET JIT vs AOT.

Esse projeto utiliza a VPC default da account AWS para deploy da Lambda e RDA PostgreSQL.

- [Imagem AWS para publish AOT](#imagem-aws-para-publish-aot)
- [Benchmark](#benchmark)
- [Notas](#notas)

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

/tmp/dotnet/.nuget/packages/

## Benchmark

Métrica: duration time

| Memória   | JIT cold start    | AOT cold start    | JIT next exec | AOT next exec |
|-----------|-------------------|-------------------|---------------|---------------|
| 256 MB    | 5010.11 ms        | 2259.80 ms        | 243.17 ms     | 22.70 ms      |
| 512 MB    | 2291.14 ms        | 1108.29 ms        | 106.29 ms     | 14.10 ms      |
| 1024 MB   | 1125.59 ms        | 554.04 ms         | 35.63 ms      | 8.94 ms       |

Framework tests - Billed duration com **256 MB RAM**

| Memória       | JIT 1º exe | AOT 1º exec | JIT max exe | AOT max exec | JIT min exec | AOT min exec | JIT Max memory used | AOT Max memory used |
|---------------|------------|-------------|-------------|--------------|--------------|--------------|---------------------|---------------------|
| Dapper        | 3019 ms    | n/a         | 151 ms      | n/a          | 15ms         | n/a          | 107 mb              | n/a                 |
| Dapper.AOT    | 2633 ms    | 1286 ms     | 65 ms       | 4 ms         | 9 ms         | 3 ms         | 101 mb              | 115 mb              |
| EF Core       | 6701 ms    | error       | 733 m       | error        | 19ms         | error        | 127 mb              | error               |

*n/a: Teste não se aplica no ambiente. Existe outro pacote para a plataforma.*

## Notas

112 mb
268 mb

rd.xml
https://codevision.medium.com/rd-xml-in-corert-43bc69cddf05
https://codevision.medium.com/library-of-rd-xml-files-for-nativeaot-174dcd2438e
https://github.com/kant2002/CoreRtRdXmlExamples/blob/master/SystemTextJsonSerialization/rd.xml

https://learn.microsoft.com/en-us/dotnet/core/deploying/native-aot/warnings/il3050



'Microsoft.EntityFrameworkCore.ChangeTracking.EntryCurrentValueComparer`1[System.Guid]' is missing native code or metadata


2023-04-17T12:20:42.093-03:00	2023-04-17T15:20:42.093Z 07b67dbf-4d0e-493f-92c1-3095d8511a70 fail System.NotSupportedException: 'Microsoft.EntityFrameworkCore.ChangeTracking.EntryCurrentValueComparer`1[System.Guid]' is missing native code or metadata. This can happen for code that is not compatible with trimming or AOT. Inspect and fix trimming and AOT related warnings that were generated when the app was published. For more information see https://aka.ms/nativeaot-compatibility

2023-04-17T12:20:42.093-03:00	at System.Reflection.Runtime.General.TypeUnifier.WithVerifiedTypeHandle(RuntimeConstructedGenericTypeInfo, RuntimeTypeInfo[]) + 0x98

2023-04-17T12:20:42.093-03:00	at Microsoft.EntityFrameworkCore.ChangeTracking.Internal.CurrentValueComparerFactory.Create(IPropertyBase propertyBase) + 0x8b

2023-04-17T12:20:42.093-03:00	at Microsoft.EntityFrameworkCore.Internal.NonCapturingLazyInitializer.EnsureInitialized[TParam,TValue](TValue& target, TParam param, Func`2 valueFactory) + 0x24

2023-04-17T12:20:42.093-03:00	at Microsoft.EntityFrameworkCore.Infrastructure.ModelValidator.ValidateTypeMappings(IModel model, IDiagnosticsLogger`1 logger) + 0x16b

2023-04-17T12:20:42.093-03:00	at Microsoft.EntityFrameworkCore.Infrastructure.ModelValidator.Validate(IModel model, IDiagnosticsLogger`1 logger) + 0x136

2023-04-17T12:20:42.093-03:00	at Microsoft.EntityFrameworkCore.Infrastructure.RelationalModelValidator.Validate(IModel model, IDiagnosticsLogger`1 logger) + 0x23

2023-04-17T12:20:42.093-03:00	at Npgsql.EntityFrameworkCore.PostgreSQL.Infrastructure.Internal.NpgsqlModelValidator.Validate(IModel model, IDiagnosticsLogger`1 logger) + 0x1a

2023-04-17T12:20:42.093-03:00	at Microsoft.EntityFrameworkCore.Infrastructure.ModelRuntimeInitializer.Initialize(IModel model, Boolean designTime, IDiagnosticsLogger`1 validationLogger) + 0x158

2023-04-17T12:20:42.093-03:00	at Microsoft.EntityFrameworkCore.Infrastructure.ModelSource.GetModel(DbContext context, ModelCreationDependencies modelCreationDependencies, Boolean designTime) + 0xf0

2023-04-17T12:20:42.093-03:00	at Microsoft.EntityFrameworkCore.Internal.DbContextServices.CreateModel(Boolean designTime) + 0x141

2023-04-17T12:20:42.093-03:00	at Microsoft.EntityFrameworkCore.Internal.DbContextServices.get_Model() + 0x1a

2023-04-17T12:20:42.093-03:00	at Microsoft.Extensions.DependencyInjection.ServiceLookup.CallSiteRuntimeResolver.VisitFactory(FactoryCallSite, RuntimeResolverContext) + 0xf

2023-04-17T12:20:42.093-03:00	at Microsoft.Extensions.DependencyInjection.ServiceLookup.CallSiteRuntimeResolver.VisitCache(ServiceCallSite, RuntimeResolverContext, ServiceProviderEngineScope, RuntimeResolverLock) + 0xa5

2023-04-17T12:20:42.093-03:00	at Microsoft.Extensions.DependencyInjection.ServiceLookup.CallSiteRuntimeResolver.VisitScopeCache(ServiceCallSite, RuntimeResolverContext) + 0x18

2023-04-17T12:20:42.093-03:00	at Microsoft.Extensions.DependencyInjection.ServiceLookup.CallSiteVisitor`2.VisitCallSite(ServiceCallSite callSite, TArgument argument) + 0xe0

2023-04-17T12:20:42.093-03:00	at Microsoft.Extensions.DependencyInjection.ServiceLookup.CallSiteRuntimeResolver.VisitConstructor(ConstructorCallSite, RuntimeResolverContext) + 0x83

2023-04-17T12:20:42.093-03:00	at Microsoft.Extensions.DependencyInjection.ServiceLookup.CallSiteRuntimeResolver.VisitCache(ServiceCallSite, RuntimeResolverContext, ServiceProviderEngineScope, RuntimeResolverLock) + 0xa5

2023-04-17T12:20:42.093-03:00	at Microsoft.Extensions.DependencyInjection.ServiceLookup.CallSiteRuntimeResolver.VisitScopeCache(ServiceCallSite, RuntimeResolverContext) + 0x18

2023-04-17T12:20:42.093-03:00	at Microsoft.Extensions.DependencyInjection.ServiceLookup.CallSiteVisitor`2.VisitCallSite(ServiceCallSite callSite, TArgument argument) + 0xe0

2023-04-17T12:20:42.093-03:00	at Microsoft.Extensions.DependencyInjection.ServiceLookup.CallSiteRuntimeResolver.VisitConstructor(ConstructorCallSite, RuntimeResolverContext) + 0x83

2023-04-17T12:20:42.093-03:00	at Microsoft.Extensions.DependencyInjection.ServiceLookup.CallSiteRuntimeResolver.VisitCache(ServiceCallSite, RuntimeResolverContext, ServiceProviderEngineScope, RuntimeResolverLock) + 0xa5

2023-04-17T12:20:42.093-03:00	at Microsoft.Extensions.DependencyInjection.ServiceLookup.CallSiteRuntimeResolver.VisitScopeCache(ServiceCallSite, RuntimeResolverContext) + 0x18

2023-04-17T12:20:42.093-03:00	at Microsoft.Extensions.DependencyInjection.ServiceLookup.CallSiteVisitor`2.VisitCallSite(ServiceCallSite callSite, TArgument argument) + 0xe0

2023-04-17T12:20:42.093-03:00	at Microsoft.Extensions.DependencyInjection.ServiceLookup.CallSiteRuntimeResolver.VisitConstructor(ConstructorCallSite, RuntimeResolverContext) + 0x83

2023-04-17T12:20:42.093-03:00	at Microsoft.Extensions.DependencyInjection.ServiceLookup.CallSiteRuntimeResolver.VisitCache(ServiceCallSite, RuntimeResolverContext, ServiceProviderEngineScope, RuntimeResolverLock) + 0xa5

2023-04-17T12:20:42.093-03:00	at Microsoft.Extensions.DependencyInjection.ServiceLookup.CallSiteRuntimeResolver.VisitScopeCache(ServiceCallSite, RuntimeResolverContext) + 0x18

2023-04-17T12:20:42.093-03:00	at Microsoft.Extensions.DependencyInjection.ServiceLookup.CallSiteVisitor`2.VisitCallSite(ServiceCallSite callSite, TArgument argument) + 0xe0

2023-04-17T12:20:42.093-03:00	at Microsoft.Extensions.DependencyInjection.ServiceLookup.CallSiteRuntimeResolver.VisitConstructor(ConstructorCallSite, RuntimeResolverContext) + 0x83

2023-04-17T12:20:42.093-03:00	at Microsoft.Extensions.DependencyInjection.ServiceLookup.CallSiteRuntimeResolver.VisitCache(ServiceCallSite, RuntimeResolverContext, ServiceProviderEngineScope, RuntimeResolverLock) + 0xa5

2023-04-17T12:20:42.093-03:00	at Microsoft.Extensions.DependencyInjection.ServiceLookup.CallSiteRuntimeResolver.VisitScopeCache(ServiceCallSite, RuntimeResolverContext) + 0x18

2023-04-17T12:20:42.093-03:00	at Microsoft.Extensions.DependencyInjection.ServiceLookup.CallSiteVisitor`2.VisitCallSite(ServiceCallSite callSite, TArgument argument) + 0xe0

2023-04-17T12:20:42.093-03:00	at Microsoft.Extensions.DependencyInjection.ServiceLookup.CallSiteRuntimeResolver.VisitConstructor(ConstructorCallSite, RuntimeResolverContext) + 0x83

2023-04-17T12:20:42.093-03:00	at Microsoft.Extensions.DependencyInjection.ServiceLookup.CallSiteRuntimeResolver.VisitCache(ServiceCallSite, RuntimeResolverContext, ServiceProviderEngineScope, RuntimeResolverLock) + 0xa5

2023-04-17T12:20:42.093-03:00	at Microsoft.Extensions.DependencyInjection.ServiceLookup.CallSiteRuntimeResolver.VisitScopeCache(ServiceCallSite, RuntimeResolverContext) + 0x18

2023-04-17T12:20:42.093-03:00	at Microsoft.Extensions.DependencyInjection.ServiceLookup.CallSiteVisitor`2.VisitCallSite(ServiceCallSite callSite, TArgument argument) + 0xe0

2023-04-17T12:20:42.093-03:00	at Microsoft.Extensions.DependencyInjection.ServiceLookup.CallSiteRuntimeResolver.Resolve(ServiceCallSite, ServiceProviderEngineScope) + 0x1e

2023-04-17T12:20:42.093-03:00	at Microsoft.Extensions.DependencyInjection.ServiceProvider.GetService(Type, ServiceProviderEngineScope) + 0x71

2023-04-17T12:20:42.093-03:00	at Microsoft.Extensions.DependencyInjection.ServiceProviderServiceExtensions.GetRequiredService(IServiceProvider, Type) + 0x51

2023-04-17T12:20:42.093-03:00	at Microsoft.Extensions.DependencyInjection.ServiceProviderServiceExtensions.GetRequiredService[T](IServiceProvider) + 0x2f

2023-04-17T12:20:42.093-03:00	at Microsoft.EntityFrameworkCore.DbContext.get_DbContextDependencies() + 0x35

2023-04-17T12:20:42.093-03:00	at Microsoft.EntityFrameworkCore.DbContext.get_ContextServices() + 0x13c

2023-04-17T12:20:42.093-03:00	at Microsoft.EntityFrameworkCore.DbContext.get_Model() + 0x9

2023-04-17T12:20:42.093-03:00	at Microsoft.EntityFrameworkCore.Internal.InternalDbSet`1.get_EntityType() + 0x3e

2023-04-17T12:20:42.093-03:00	at Microsoft.EntityFrameworkCore.Internal.InternalDbSet`1.get_EntityQueryable() + 0x21

2023-04-17T12:20:42.093-03:00	at Microsoft.EntityFrameworkCore.Internal.InternalDbSet`1.System.Linq.IQueryable.get_Provider() + 0x6

2023-04-17T12:20:42.093-03:00	at Microsoft.EntityFrameworkCore.EntityFrameworkQueryableExtensions.AsNoTracking[TEntity](IQueryable`1 source) + 0x2a

2023-04-17T12:20:42.093-03:00	at DataAccess.Aot.SampleUseCase.<ExecuteAsync>d__3.MoveNext() + 0x64

2023-04-17T12:20:42.093-03:00	--- End of stack trace from previous location ---

2023-04-17T12:20:42.093-03:00	at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw() + 0x1c

2023-04-17T12:20:42.093-03:00	at System.Runtime.CompilerServices.TaskAwaiter.ThrowForNonSuccess(Task) + 0xc2

2023-04-17T12:20:42.093-03:00	at DataAccess.Aot.Function.<FunctionHandlerAsync>d__4.MoveNext() + 0x1ca

2023-04-17T12:20:42.093-03:00	--- End of stack trace from previous location ---

2023-04-17T12:20:42.093-03:00	at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw() + 0x1c

2023-04-17T12:20:42.093-03:00	at System.Runtime.CompilerServices.TaskAwaiter.ThrowForNonSuccess(Task) + 0xc2

2023-04-17T12:20:42.093-03:00	at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification(Task) + 0x44

2023-04-17T12:20:42.093-03:00	at Amazon.Lambda.RuntimeSupport.HandlerWrapper.<>c__DisplayClass26_0`2.<<GetHandlerWrapper>b__0>d.MoveNext() + 0x104

2023-04-17T12:20:42.093-03:00	--- End of stack trace from previous location ---

2023-04-17T12:20:42.093-03:00	at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw() + 0x1c

2023-04-17T12:20:42.093-03:00	at System.Runtime.CompilerServices.TaskAwaiter.ThrowForNonSuccess(Task) + 0xc2

2023-04-17T12:20:42.093-03:00	at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification(Task) + 0x44

2023-04-17T12:20:42.093-03:00	at Amazon.Lambda.RuntimeSupport.LambdaBootstrap.<InvokeOnceAsync>d__17.MoveNext() + 0x1f7

2023-04-17T12:20:42.116-03:00	END RequestId: 07b67dbf-4d0e-493f-92c1-3095d8511a70