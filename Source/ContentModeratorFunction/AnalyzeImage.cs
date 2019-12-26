using Microsoft.ApplicationInsights;
using Microsoft.ApplicationInsights.Extensibility;
using Microsoft.Azure.CognitiveServices.Vision.ComputerVision;
using Microsoft.Azure.CognitiveServices.Vision.ComputerVision.Models;
using Microsoft.Azure.WebJobs;
using Newtonsoft.Json.Linq;
using System;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;

namespace ContentModeratorFunction
{
    public class AnalyzeImage
    {
        private readonly HttpClient httpClient;
        private readonly TelemetryClient telemetryClient;

        public AnalyzeImage(IHttpClientFactory httpClientFactory, TelemetryConfiguration telemetryConfiguration)
        {
            httpClient = httpClientFactory.CreateClient();
            telemetryClient = new TelemetryClient(telemetryConfiguration);
        }

        /// Function entry point. Review image and text and set inputDocument.isApproved.
        [FunctionName("ReviewImageAndText")]
        public async Task ReviewImageAndText(
            [QueueTrigger("%queue-name%")]  ReviewRequestItem queueInput,
            [Blob("input-images/{BlobName}", FileAccess.Read)]  Stream image,
            [CosmosDB("customerReviewData", "reviews", Id = "{DocumentId}", PartitionKey = "Reviews", ConnectionStringSetting = "customerReviewDataDocDB")]  dynamic inputDocument)
        {
            bool passesText = await PassesTextModeratorAsync(inputDocument);

            (bool containsCat, string caption) = await PassesImageModerationAsync(image); // use Vision APIs
            inputDocument.IsApproved = containsCat && passesText;
            inputDocument.Caption = caption;

            EmitCustomTelemetry(containsCat, passesText);
        }

        private async Task<(bool, string)> PassesImageModerationAsync(Stream image)
        {
            var client = new ComputerVisionClient(
                new ApiKeyServiceClientCredentials(ApiKey),
                httpClient,
                false);

            client.Endpoint = ApiRoot;
            var result = await client.AnalyzeImageInStreamAsync(image, VisualFeatures);

            bool containsCat = result.Description.Tags.Take(5).Contains(SearchTag);
            string message = result?.Description?.Captions.FirstOrDefault()?.Text;

            return (containsCat, message);
        }

        private async Task<bool> PassesTextModeratorAsync(dynamic document)
        {
            if (document.ReviewText == null)
            {
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

        private static readonly string SearchTag = "cat";
        private static readonly string ApiRoot = $"https://{Environment.GetEnvironmentVariable("AssetsLocation")}.api.cognitive.microsoft.com";
        private static string ApiUri = $"{ApiRoot}/contentmoderator/moderate/v1.0/ProcessText/Screen?language=eng";
        private static readonly string ApiKey = Environment.GetEnvironmentVariable("MicrosoftVisionApiKey");

        private static readonly VisualFeatureTypes[] VisualFeatures = { VisualFeatureTypes.Description };

        public class ReviewRequestItem
        {
            public string DocumentId { get; set; }
            public string BlobName { get; set; }
        }

        private void EmitCustomTelemetry(bool passesImage, bool passesText)
        {
            try
            {
                telemetryClient.Context.Operation.Name = "AnalyzeReview";

                telemetryClient.TrackMetric("ModerationResult", GetModerationResult(passesImage, passesText));

            }
            catch
            {
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