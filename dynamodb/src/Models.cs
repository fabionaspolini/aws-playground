namespace AwsPlayground;

[ServiceStack.DataAnnotations.Alias("Vendas")]
public record class Venda(
    [property: ServiceStack.DataAnnotations.HashKey] Guid Id,
    [property: ServiceStack.DataAnnotations.RangeKey] string SK,
    long ExpireOn,
    DateTime Data,
    Cliente Cliente,
    decimal ValorTotal,
    Pagamento Pagamento)
{
    public Guid? ClienteId => Cliente?.Id;
}

public record class Cliente(Guid Id, string Nome);

public record class Pagamento(string Metodo, decimal Valor);

public record class VendaItem(
    Guid Id,
    string Nome,
    decimal ValorUnitario,
    decimal Quantidade,
    decimal ValorTotal);

[ServiceStack.DataAnnotations.Alias("Vendas")]
public record class VendaItemRoot(
    [property: ServiceStack.DataAnnotations.HashKey] Guid Id,
    [property: ServiceStack.DataAnnotations.RangeKey] string SK,
    long ExpireOn,
    Guid ClienteId,
    VendaItem[] Itens);