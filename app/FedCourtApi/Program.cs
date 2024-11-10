using FedCourtApi;
using Microsoft.EntityFrameworkCore;
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;
using Azure.Core;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.Configuration.AddAzureKeyVault(new Uri($"https://kv-fedtest-65t5.vault.azure.net/"), new DefaultAzureCredential());

builder.Services.AddDbContextFactory<MyDbContext>(options =>
    
    options.UseSqlServer(builder.Configuration["ToDoDbConnectionString"]));
    
var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
    app.UseDeveloperExceptionPage();    
}

app.UseHttpsRedirection();

app.MapGet("/dbmigrate", async () =>
{

    var todoDbContextFactory = app.Services.GetRequiredService<IDbContextFactory<MyDbContext>>();
        
    var dbContext = todoDbContextFactory.CreateDbContext();

        dbContext.Database.Migrate();
        dbContext.ToDos.Add(new ToDo() {Title = "Do Gardening", IsComplete = false });
        await dbContext.SaveChangesAsync();
        
    return Results.Ok();
});

app.MapGet("/healthy", async () =>
{
    var todoDbContextFactory = app.Services.GetRequiredService<IDbContextFactory<MyDbContext>>();
    
    var dbContext = todoDbContextFactory.CreateDbContext();

    try
    {
        var todos = await dbContext.ToDos.ToListAsync();
        return Results.Ok();
    }
    catch (Exception e)
    {
        return Results.Problem(e.InnerException?.Message);
    }
    
});

app.MapGet("/todo", async () =>
{
    var todoDbContextFactory = app.Services.GetRequiredService<IDbContextFactory<MyDbContext>>();
    
    var dbContext = todoDbContextFactory.CreateDbContext();

    try
    {
        var todo = await dbContext.ToDos.FindAsync(1);
        return Results.Ok(todo);
    }
    catch (Exception e)
    {
        return Results.Problem(e.InnerException?.Message);
    }
});

app.MapGet("/alive", () => Results.Ok());

app.Run();
