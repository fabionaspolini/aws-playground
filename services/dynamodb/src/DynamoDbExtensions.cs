using Amazon.DynamoDBv2.DocumentModel;
using Amazon.DynamoDBv2.Model;

namespace AwsPlayground;

public static class DocumentExtensions
{
    public static string Humanize(this Document document, string? baseProperty = null)
    {
        if (document == null || !document.Any())
            return string.Empty;
        var text = string.Join(", ", document.OrderBy(x => x.Value switch
        {
            DynamoDBList => 2,
            Document => 1,
            _ => 0
        }).Select(selector: x =>
        {
            if (x.Value is Document nested)
                return nested.Humanize(x.Key);
            if (x.Value is DynamoDBList list)
                return $"{(baseProperty != null ? $"{baseProperty}." : "")}{x.Key}: {list.Entries.Count}";
            return $"{(baseProperty != null ? $"{baseProperty}." : "")}{x.Key}: {x.Value}";
        }));
        return text;
    }

    public static string Humanize(this Dictionary<string, AttributeValue> attributeMap, string? baseProperty = null) => Document.FromAttributeMap(attributeMap).Humanize(baseProperty);

    public static string Humanize(this AttributeValue value) => value.S ?? value.N;

    // Convert datetime to UNIX time
    public static long ToUnixTime(this DateTime dateTime)
    {
        var dto = new DateTimeOffset(dateTime.ToUniversalTime());
        return dto.ToUnixTimeSeconds();
    }

    // Convert datetime to UNIX time including miliseconds
    public static long ToUnixTimeMilliSeconds(this DateTime dateTime)
    {
        var dto = new DateTimeOffset(dateTime.ToUniversalTime());
        return dto.ToUnixTimeMilliseconds();
    }
}
