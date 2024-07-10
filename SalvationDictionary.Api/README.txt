# Salvation Dictionary

## The following steps are not mandatory:

The InitialMigration is already created, but to remove the migration execute `dotnet ef migrations remove` from the API folder - which will remove the last migration.
A newer migration can be created by executing `dotnet ef migrations add InitialMigration` - where InitialMigration is the name we gave it as no other migrations are planed for now (since the database is not expected to have other entities or change the already existing ones).

## Execute the following commands from the API folder when starting the first time:

1. dotnet ef database update - this applies the `InitialMigration` to Sqlite database
2. dotnet run - this runs the Kestrel server which serves the API
3. Execute http commands from the .http file in the project to test the API behavior and supported REST operations.
