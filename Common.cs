//restore packages
Update-Package -Reinstall

//datetime wrong format
<system.web>
    <globalization uiCulture="en-AU" culture="en-AU" />



//JS date to C# datetime using moment.js
https://stackoverflow.com/a/49026060
JavaScript : var dateString = moment(new Date()).format('LLLL')

C# : DateTime.Parse(dateString);


//Setup EF Core + Migration
https://stackoverflow.com/a/52201760

dotnet ef database update --project


dotnet ef dbcontext scaffold "Server=.\;Database=loven;Trusted_Connection=True;" Microsoft.EntityFrameworkCore.SqlServer -o Models/Entities -c "PostContext" --force

Authorize Authenticate .NET Core

https://github.com/cornflourblue/aspnet-core-3-role-based-authorization-api



///egerload include 
IQueryable<T> GetAll(params Expression<Func<T, object>>[] iProperties);
public IQueryable<T> GetAll(Expression<Func<T, object>>[] iProperties = null)
{
    var queryable = this.PostContext.Set<T>().AsQueryable();
    if (iProperties != null)
    {
        foreach (Expression<Func<T, object>> iProperty in iProperties)
        {
            queryable = queryable.Include<T, object>(iProperty);
        }
    }
    return queryable.AsNoTracking();
}
userService.GetAll(x => x.UserRoles)