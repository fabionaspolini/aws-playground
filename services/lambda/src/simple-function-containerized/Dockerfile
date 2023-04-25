###################
### Build image ###
###################

FROM mcr.microsoft.com/dotnet/sdk:6.0 as publish
WORKDIR /src
COPY ./SimpleFunctionContainerized.csproj ./
RUN dotnet restore "SimpleFunctionContainerized.csproj"

COPY . .
RUN dotnet publish "SimpleFunctionContainerized.csproj" \
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
COPY --from=publish /app/publish .
CMD ["SimpleFunctionContainerized::SimpleFunctionContainerized.Function::FunctionHandler"]