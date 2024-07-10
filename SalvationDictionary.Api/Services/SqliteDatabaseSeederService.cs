using SalvationDictionary.Api.Models;

namespace SalvationDictionary.Api.Services;

public class SqliteDatabaseSeederService : IDatabaseSeederService
{
    private readonly ISeedDataProviderService _seedDataProviderService;
    private readonly ILogger<SqliteDatabaseSeederService> _logger;

    public SqliteDatabaseSeederService(ISeedDataProviderService seedDataProviderService, 
        ILogger<SqliteDatabaseSeederService> logger)
    {
        _seedDataProviderService = seedDataProviderService;
        _logger = logger;
    }

    public (IEnumerable<WordTitle> WordTitles, 
    IEnumerable<WordSubtitle> WordSubtitles, 
    IEnumerable<DictionaryEntry> DictionaryEntries) GetSeedDatabase(string seedDataPath)
    {
        _logger.LogInformation("Getting seed data for database from path '{seedDataPath}'...", seedDataPath);

        var seedDataForSalvationDictionary = _seedDataProviderService.LoadSeedDataForSalvationDictionary(seedDataPath);

        var wordTitleCounter = 0;
        var wordSubtitleCounter = 0;
        var textCounter = 0;

        var wordTitles = new List<WordTitle>();
        var wordSubtitles = new List<WordSubtitle>();
        var dictionaryEntries = new List<DictionaryEntry>();

        foreach (var dictionaryWord in seedDataForSalvationDictionary ?? Enumerable.Empty<SeedDictionaryWord>())
        {
            wordTitles.Add(
                new () { Id = ++wordTitleCounter, Title = dictionaryWord.Title });

            foreach (var subtitleWithText in dictionaryWord.SubtitlesWithText)
            {
                if (subtitleWithText.Subtitle is not null)
                {
                    wordSubtitles.Add(
                        new () { Id = ++wordSubtitleCounter, Subtitle = subtitleWithText.Subtitle });
                }

                foreach (var text in subtitleWithText.Text)
                {
                    dictionaryEntries.Add(
                        new () { Id = ++textCounter, 
                            WordTitleId = wordTitleCounter, 
                            WordSubtitleId = subtitleWithText.Subtitle is null ? null : wordSubtitleCounter, 
                            Text = text
                        });
                }
            }

            _logger.LogDebug("Collected data for word '{dictionaryWord}'", dictionaryWord);
        }

        _logger.LogInformation("Finished with getting data for database seeding.");

        return (wordTitles, wordSubtitles, dictionaryEntries);
    }
}