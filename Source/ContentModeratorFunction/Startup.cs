using Microsoft.ApplicationInsights.Extensibility;
using Microsoft.Azure.Functions.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection;
using System;

[assembly: FunctionsStartup(typeof(ContentModeratorFunction.Startup))]
namespace ContentModeratorFunction
{
    public class Startup : FunctionsStartup
    {
        public override void Configure(IFunctionsHostBuilder builder)
        {
            builder.Services.AddHttpClient();

            builder.Services.AddSingleton(sp =>
            {
                var telemetryConfiguration = new TelemetryConfiguration();
                telemetryConfiguration.InstrumentationKey = Environment.GetEnvironmentVariable("APPINSIGHTS_INSTRUMENTATIONKEY");
                telemetryConfiguration.TelemetryInitializers.Add(new OperationCorrelationTelemetryInitializer());
                return telemetryConfiguration;
            });
        }
    }
}
