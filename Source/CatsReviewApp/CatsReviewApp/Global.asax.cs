namespace CatsReviewApp
{
    using Microsoft.ApplicationInsights.Extensibility;
    using System.Web.Mvc;
    using System.Web.Optimization;
    using System.Web.Routing;

    public class MvcApplication : System.Web.HttpApplication
    {
        protected void Application_Start()
        {
            AreaRegistration.RegisterAllAreas();
            FilterConfig.RegisterGlobalFilters(GlobalFilters.Filters);
            RouteConfig.RegisterRoutes(RouteTable.Routes);
            BundleConfig.RegisterBundles(BundleTable.Bundles);

            var iKey = System.Web.Configuration.WebConfigurationManager.AppSettings["iKey"];
            if (string.IsNullOrEmpty(iKey)) { throw new System.Exception("Missing instrumentation key in Web.config"); };

            TelemetryConfiguration.Active.InstrumentationKey = iKey;
        }
    }
}
