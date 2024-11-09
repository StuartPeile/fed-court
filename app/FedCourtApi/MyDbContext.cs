

using Microsoft.EntityFrameworkCore;

namespace FedCourtApi
{

    
    public class MyDbContext(DbContextOptions options) : DbContext(options)
    {
        
        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {

            modelBuilder.Entity<ToDo>()
                .HasKey(e=>e.Id);
            
            base.OnModelCreating(modelBuilder);
        }

        public DbSet<ToDo> ToDos { get; set; }
    }

    public record ToDo
    {
        public int Id { get; init; }
        
        public string Title { get; init; }
        
        public bool IsComplete { get; init; }
    }
}
