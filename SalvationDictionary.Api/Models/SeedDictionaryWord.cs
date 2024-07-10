namespace SalvationDictionary.Api.Models;

public record SeedDictionaryWord
{
    public required string Title { get; init; }
    public required IEnumerable<SubtitleWithText> SubtitlesWithText { get; init; }
}

public record SubtitleWithText
{
    public string? Subtitle { get; init; }
    public required IEnumerable<string> Text { get; init; }
}
