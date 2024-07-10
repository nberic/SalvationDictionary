using System.Text.Json;
using SalvationDictionary.Api.Models;

namespace SalvationDictionary.Api.Services;

public class SeedDataFromJsonProviderService : ISeedDataProviderService
{
    private readonly ILogger<SeedDataFromJsonProviderService> _logger;

    public SeedDataFromJsonProviderService(ILogger<SeedDataFromJsonProviderService> logger)
    {
        _logger = logger;
    }

    public IEnumerable<SeedDictionaryWord>? LoadSeedDataForSalvationDictionary(string seedDataPath)
    {
        IEnumerable<SeedDictionaryWord>? salvationDictionary = null;
        
        try
        {
            var jsonString = File.ReadAllText(seedDataPath);
            salvationDictionary = JsonSerializer.Deserialize<IEnumerable<SeedDictionaryWord>>(jsonString);
        }
        catch(FileNotFoundException exception)
        {
            _logger.LogError(exception, "Unable to find file: '{seedDataPath}'", seedDataPath);
        }
        catch(JsonException exception)
        {
            _logger.LogError(exception, "The format of JSON file '{seedDataPath}' is invalid: }", seedDataPath);
        }
        catch(Exception exception)
        {
            _logger.LogError(exception, "Unknown error occurred.");
        }

        return salvationDictionary;
    }
}