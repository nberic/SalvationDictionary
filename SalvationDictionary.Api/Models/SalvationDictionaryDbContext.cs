using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using SalvationDictionary.Api.Services;

namespace SalvationDictionary.Api.Models;

public class SalvationDictionaryDbContext : DbContext
{
    public DbSet<WordTitle> WordTitles { get; set; }
    public DbSet<WordSubtitle> WordSubtitles { get; set; }
    public DbSet<DictionaryEntry> DictionaryEntries { get; set; }
    private readonly IDatabaseSeederService _databaseSeederService;
    private readonly string _seedDataPath;

    public SalvationDictionaryDbContext(IDatabaseSeederService databaseSeederService,
        DbContextOptions<SalvationDictionaryDbContext> options, 
        IOptions<SeedDataContentConfiguration> seedDataContentConfigurationOptions)
    : base(options)
    {
        _databaseSeederService = databaseSeederService;
        _seedDataPath = seedDataContentConfigurationOptions.Value.SeedDataFilePath;
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<WordTitle>().HasKey(wt => wt.Id);

        modelBuilder.Entity<WordSubtitle>().HasKey(ws => ws.Id);
        
        modelBuilder.Entity<DictionaryEntry>().HasKey(de => de.Id);

        modelBuilder.Entity<DictionaryEntry>()
            .HasOne(de => de.Title);

        var allDataForSeeding = _databaseSeederService.GetSeedDatabase(_seedDataPath);

        modelBuilder.Entity<WordTitle>().HasData(allDataForSeeding.WordTitles);
        modelBuilder.Entity<WordSubtitle>().HasData(allDataForSeeding.WordSubtitles);
        modelBuilder.Entity<DictionaryEntry>().HasData(allDataForSeeding.DictionaryEntries);
    }
}