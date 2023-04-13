namespace AwsPlayground;

// Mesmo modelo sendo utilizado para 2 ORM diferentes

[ServiceStack.DataAnnotations.Alias("Vendas")]
[Amazon.DynamoDBv2.DataModel.DynamoDBTable("Vendas")]
public record class Venda(
    [property: ServiceStack.DataAnnotations.HashKey]
    [property: Amazon.DynamoDBv2.DataModel.DynamoDBHashKey] Guid Id,
    [property: ServiceStack.DataAnnotations.RangeKey]
    [property: Amazon.DynamoDBv2.DataModel.DynamoDBRangeKey] string SK,
    long ExpireOn,
    DateTime Data,
    Cliente Cliente,
    decimal ValorTotal,
    Pagamento Pagamento)
{
    public Guid? ClienteId => Cliente?.Id;

    public Venda() : this(default, default!, default, default, default!, default, default!) { } // AWS .NET Object Persistence Model precisa de um construtor vazio :(
}

public record class Cliente(Guid Id, string Nome)
{
    public Cliente() : this(default, default!) { } // AWS .NET Object Persistence Model precisa de um construtor vazio :(
}

public record class Pagamento(string Metodo, decimal Valor)
{
    public Pagamento() : this(default!, default) { } // AWS .NET Object Persistence Model precisa de um construtor vazio :(
}

public record class VendaItem(
    Guid Id,
    string Nome,
    decimal ValorUnitario,
    decimal Quantidade,
    decimal ValorTotal)
{
    public VendaItem() : this(default, default!, default, default, default) { } // AWS .NET Object Persistence Model precisa de um construtor vazio :(
}

[ServiceStack.DataAnnotations.Alias("Vendas")]
[Amazon.DynamoDBv2.DataModel.DynamoDBTable("Vendas")]
public record class VendaItemRoot(
    [property: ServiceStack.DataAnnotations.HashKey]
    [property: Amazon.DynamoDBv2.DataModel.DynamoDBHashKey] Guid Id,
    [property: ServiceStack.DataAnnotations.RangeKey]
    [property: Amazon.DynamoDBv2.DataModel.DynamoDBRangeKey] string SK,
    long ExpireOn,
    Guid ClienteId,
    VendaItem[] Itens)
{
    public VendaItemRoot() : this(default, default!, default, default, default!) { } // AWS .NET Object Persistence Model precisa de um construtor vazio :(
};