using System;
using System.Collections.Generic;
using System.IO;
using System.Threading.Tasks;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Newtonsoft.Json;

namespace ContentModeratorFunction.Tests
{
    public class ReviewPoco
    {
        public string ReviewText { get; set; }
    }

    public class AppSettingsFile
    {
        public Dictionary<string, string> Values { get; set; } = new Dictionary<string, string>();
    }

    [TestClass]
    public class TestContent
    {
        [ClassInitialize]
        public static void Initialize(TestContext context)
        {
            using (StreamReader r = new StreamReader("local.settings.json"))
            {
                string json = r.ReadToEnd();
                var appsettings = JsonConvert.DeserializeObject<AppSettingsFile>(json);

                foreach (var keyValue in appsettings.Values)
                {
                    Environment.SetEnvironmentVariable(keyValue.Key, keyValue.Value);
                }
            }
        }

        [TestMethod]
        public async Task TestTextModeration()
        {
            bool passes = await AnalyzeImage.PassesTextModeratorAsync(new ReviewPoco { ReviewText = "Donna" });

            Assert.IsTrue(passes);
        }

        [TestMethod]
        public async Task TestImageModeration()
        {
            using (var stream = new FileStream(@"TestImages\moxie.jpg", FileMode.Open))
            {
                var response = await AnalyzeImage.PassesImageModerationAsync(stream);

                Assert.IsTrue(response.Item1);
            }
        }
    }
}
