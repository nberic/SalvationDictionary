using SalvationDictionary.Api.Models;

namespace SalvationDictionary.Api.Services;

public interface ISeedDataProviderService
{
    IEnumerable<SeedDictionaryWord>? LoadSeedDataForSalvationDictionary(string seedDataPath);
}