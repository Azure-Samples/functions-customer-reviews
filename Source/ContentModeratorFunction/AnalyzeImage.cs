using System;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using Microsoft.ApplicationInsights;
using Microsoft.ApplicationInsights.Extensibility;
using Microsoft.Azure.WebJobs;
using Microsoft.ProjectOxford.Vision;
using Newtonsoft.Json.Linq;

namespace ContentModeratorFunction
{
    public class AnalyzeImage
    {
        /// Function entry point. Review image and text and set inputDocument.isApproved.
        [FunctionName("ReviewImageAndText")]
        public static async Task ReviewImageAndText(
            [QueueTrigger("%queue-name%")]  ReviewRequestItem queueInput,
            [Blob("input-images/{BlobName}", FileAccess.Read)]  Stream image,
            [DocumentDB("customerReviewData", "reviews", Id = "{DocumentId}", PartitionKey = "Reviews", ConnectionStringSetting = "customerReviewDataDocDB")]  dynamic inputDocument)
        {
            bool passesText = await PassesTextModeratorAsync(inputDocument);

            (bool containsCat, string caption) = await PassesImageModerationAsync(image); // use Vision APIs
            inputDocument.IsApproved = containsCat && passesText;
            inputDocument.Caption = caption;

            EmitCustomTelemetry(containsCat, passesText);
        }

        public static async Task<(bool, string)> PassesImageModerationAsync(Stream image)
        {
            var client = new VisionServiceClient(ApiKey);
            var result = await client.AnalyzeImageAsync(image, VisualFeatures);

            bool containsCat = result.Description.Tags.Take(5).Contains(SearchTag);
            string message = result?.Description?.Captions.FirstOrDefault()?.Text;
            return (containsCat, message);
        }

        public static async Task<bool> PassesTextModeratorAsync(dynamic document)
        {
            if (document.ReviewText == null) {
                return true;
            }

            string content = document.ReviewText;                
            StringContent stringContent = new StringContent(content);
            httpClient.DefaultRequestHeaders.Add("Ocp-Apim-Subscription-Key", Environment.GetEnvironmentVariable("ContentModerationApiKey"));
            var response = await httpClient.PostAsync(ApiUri, stringContent);

            response.EnsureSuccessStatusCode();

            JObject data = JObject.Parse(await response.Content.ReadAsStringAsync());
            JToken token = data["Terms"];

            //If we have Terms in result it failed the moderation (Terms will have the bad terms)
            return !token.HasValues;
        }

        #region Helpers

        private static string ApiUri = "https://westus.api.cognitive.microsoft.com/contentmoderator/moderate/v1.0/ProcessText/Screen?language=eng";
        private static readonly string SearchTag = "cat";
        private static readonly string ApiKey = Environment.GetEnvironmentVariable("MicrosoftVisionApiKey");
        static HttpClient httpClient = new HttpClient();

        private static readonly VisualFeature[] VisualFeatures = { VisualFeature.Description };

        public class ReviewRequestItem
        {
            public string DocumentId { get; set; }
            public string BlobName { get; set; }
        }

        private static void EmitCustomTelemetry(bool passesImage, bool passesText)
        {
            TelemetryClient telemetry = new TelemetryClient();
            string key = TelemetryConfiguration.Active.InstrumentationKey = Environment.GetEnvironmentVariable("APPINSIGHTS_INSTRUMENTATIONKEY", EnvironmentVariableTarget.Process);

            try {
                telemetry.Context.Operation.Name = "AnalyzeReview";

                telemetry.TrackMetric("ModerationResult", GetModerationResult(passesImage, passesText));
                
            }
            catch {
                // avoid fail processing due to telemetry record saving issues
            }
        }

        private static short GetModerationResult(bool passesImage, bool passesText)
        {
            if (passesImage & passesText)
                return 0;
            if (passesImage & !passesText)
                return 1;
            if (!passesImage & passesText)
                return 2;
            else
                return 3;
        }
        #endregion  

    }
}