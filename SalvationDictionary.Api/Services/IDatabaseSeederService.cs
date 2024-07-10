using SalvationDictionary.Api.Models;

namespace SalvationDictionary.Api.Services;

public interface IDatabaseSeederService
{
    (IEnumerable<WordTitle> WordTitles, 
    IEnumerable<WordSubtitle> WordSubtitles, 
    IEnumerable<DictionaryEntry> DictionaryEntries) GetSeedDatabase(string seedDataPath);
}