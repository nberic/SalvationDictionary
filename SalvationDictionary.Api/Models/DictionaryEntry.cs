namespace SalvationDictionary.Api.Models;

public record DictionaryEntry
{
    public int Id { get; init; }

    public required int WordTitleId { get; init; }

    public WordTitle? Title { get; init; }

    public int? WordSubtitleId { get; init; }

    public WordSubtitle? Subtitle { get; init; }

    public required string Text { get; init; }
    
}

public record WordTitle
{
    public int Id { get; init; }

    public required string Title {get; init; }
}

public record WordSubtitle
{
    public int Id { get; init; }

    public required string Subtitle { get; init; }
}