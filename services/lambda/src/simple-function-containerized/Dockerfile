###################
### Build image ###
###################

FROM mcr.microsoft.com/dotnet/sdk:6.0 as build
WORKDIR /src
COPY "SimpleFunctionContainerized.csproj" ./
RUN dotnet restore "SimpleFunctionContainerized.csproj"

WORKDIR "/src"
COPY . .
RUN dotnet build "SimpleFunctionContainerized.csproj" --configuration Release --output /app/build

RUN dotnet publish "SimpleFunctionContainerized.csproj" \
    # --no-build \
    --configuration Release \
    --runtime linux-x64 \
    --self-contained false \
    --output /app/publish \
    -p:PublishReadyToRun=true

#####################
### Runtime image ###
#####################

FROM public.ecr.aws/lambda/dotnet:6
WORKDIR /var/task
COPY --from=build /app/publish .
CMD ["SimpleFunctionContainerized::SimpleFunctionContainerized.Function::FunctionHandler"]