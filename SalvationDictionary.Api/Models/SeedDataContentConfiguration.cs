namespace SalvationDictionary.Api.Models;

public record SeedDataContentConfiguration
{
    public string SeedDataFilePath { get; init; } = @".\seed-data.json";
}
