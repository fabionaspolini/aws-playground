using System.Text.Json.Serialization;
using Amazon.Lambda.Core;
using Amazon.Lambda.Serialization.SystemTextJson;
using Basic.Jit;

[assembly: LambdaSerializer(typeof(SourceGeneratorLambdaJsonSerializer<LambdaFunctionJsonSerializerContext>))]

namespace Basic.Jit;

public class Function
{
#pragma warning disable CA1822 // Método sem referência passível de virar static
    public SampleResponse[] FunctionHandler(SampleRequest request, ILambdaContext context)
    {
        context.Logger.LogInformation("Iniciando Basic JIT");
        var result = new List<SampleResponse>();
        for (var i = 1; i <= request.Count; i++)
        {
            var personResponse = request.Person != null
                ? new PersonResponse(
                    FullName: $"{request.Person.FirstName} {request.Person.LastName}",
                    WelcomeMessage: $"Olá {request.Person.FirstName?.ToUpper()} {request.Person.LastName?.ToUpper()}, seja bem vindo ao teste de lambda function")
                : null;
            var mathResponse = request.Math != null
                ? new MathResponse(Math.Sqrt(Math.Pow(request.Math.A, 2) + Math.Pow(request.Math.B, 2)))
                : null;
            if (request.AddAllResponses || i == 1)
                result.Add(new(personResponse, mathResponse));
        }
        context.Logger.LogInformation("Concluído");
        return result.ToArray();
    }
#pragma warning restore CA1822
}

[JsonSerializable(typeof(SampleRequest))]
[JsonSerializable(typeof(SampleResponse[]))]
public partial class LambdaFunctionJsonSerializerContext : JsonSerializerContext
{
}

#pragma warning disable SYSLIB1037 // Source generator deserialization
public record class SampleRequest(PersonRequest? Person, MathRequest? Math, int Count = 1, bool AddAllResponses = true);
public record class PersonRequest(string FirstName, string LastName);
public record class MathRequest(double A, double B);

public record class SampleResponse(PersonResponse? Person, MathResponse? Math);
public record class PersonResponse(string FullName, string WelcomeMessage);
public record class MathResponse(double C);
#pragma warning restore SYSLIB1037