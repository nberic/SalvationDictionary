using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SalvationDictionary.Api.Models;
using SalvationDictionary.Api.Services;

var builder = WebApplication.CreateBuilder(args);
builder.Logging.ClearProviders();
builder.Logging.AddConsole();


// Add services to the container.
builder.Services.Configure<SeedDataContentConfiguration>(
    builder.Configuration.GetSection("SeedDataContentConfiguration"));
    
builder.Services.AddSingleton<ISeedDataProviderService, SeedDataFromJsonProviderService>();
builder.Services.AddSingleton<IDatabaseSeederService, SqliteDatabaseSeederService>();

builder.Services.AddDbContext<SalvationDictionaryDbContext>(options => 
    options.UseSqlite(builder.Configuration.GetConnectionString("SqliteConnection")));

// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();
var random = new Random();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.MapGet("/api/SalvationDictionary", (SalvationDictionaryDbContext salvationDictionaryDbContext) =>
{
    var allData = salvationDictionaryDbContext
        .DictionaryEntries
        .Include(de => de.Title)
        .Include(de => de.Subtitle)
        .OrderBy(de => de.Id)
        .ToList();

    return Results.Ok(allData);
})
.Produces<IEnumerable<SeedDictionaryWord>>()
.WithName("GetSalvationDictionary")
.WithOpenApi();

app.MapGet("/api/SalvationDictionary/Random", (SalvationDictionaryDbContext salvationDictionaryDbContext) =>
{
    var numberOfEntries = salvationDictionaryDbContext.DictionaryEntries.Count();
    var randomSkipCount = random.Next(0, numberOfEntries);
    var randomlySelectedDictionaryEntry = salvationDictionaryDbContext
        .DictionaryEntries
        .Skip(randomSkipCount)
        .Take(1)
        .Include(de => de.Title)
        .Include(de => de.Subtitle)
        .FirstOrDefault();
    
    return Results.Ok(randomlySelectedDictionaryEntry);
})
.Produces<SeedDictionaryWord>()
.WithName("GetSalvationDictionaryRandomItem")
.WithOpenApi();

app.MapGet("/api/SalvationDictionary/{id}", ([FromRoute]int id, SalvationDictionaryDbContext salvationDictionaryDbContext) =>
{
    var matchingItem = salvationDictionaryDbContext
        .DictionaryEntries
        .Where(de => de.Id == id)
        .Include(de => de.Title)
        .Include(de => de.Subtitle)
        .OrderBy(de => de.Id);

    if (!matchingItem.Any())
    {
        return Results.NotFound();
    }

    return Results.Ok(matchingItem);
})
.Produces<SeedDictionaryWord>()
.WithName("GetSalvationDictionaryPerItemId")
.WithOpenApi();

app.Run();
