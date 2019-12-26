namespace CatsReviewApp.Services
{
    using CatsReviewApp.Models;
    using Microsoft.Azure.Documents;
    using Microsoft.Azure.Documents.Client;
    using Microsoft.Azure.Documents.Linq;
    using Microsoft.Azure.Storage;
    using Microsoft.Azure.Storage.Blob;
    using Microsoft.Azure.Storage.Queue;
    using Microsoft.Extensions.Configuration;
    using Newtonsoft.Json;
    using System;
    using System.Collections.Generic;
    using System.IO;
    using System.Linq;
    using System.Threading.Tasks;

    public class ReviewProvider
    {
        private readonly DocumentClient client;
        private readonly CloudStorageAccount storageAccount;

        private readonly string documentDbName;
        private readonly string documentDbColl;
        private readonly string containerName;
        private readonly string queueName;            

        public ReviewProvider(IConfiguration configuration)
        {
            documentDbName = configuration.GetValue<string>("documentDbName");
            documentDbColl = configuration.GetValue<string>("documentDbColl");

            containerName = configuration.GetValue<string>("containerName");
            queueName = configuration.GetValue<string>("queueName");

            this.client = new DocumentClient(new Uri(configuration.GetValue<string>("documentDbEndpoint")), configuration.GetValue<string>("documentDbKey"));
            this.storageAccount = CloudStorageAccount.Parse(configuration.GetValue<string>("storageAccountConnectionString"));
        }

        public async Task<IEnumerable<CatReview>> GetReviewsAsync()
        {
            IQueryable<CatReview> catReviewsQuery = this.client
                .CreateDocumentQuery<CatReview>(UriFactory.CreateDocumentCollectionUri(this.documentDbName, this.documentDbColl));

            return await this.QueryAsync(catReviewsQuery);
        }

        public async Task<CatReview> GetReviewAsync(Guid id)
        {
            return (await this.client.ReadDocumentAsync<CatReview>(
                UriFactory.CreateDocumentUri(this.documentDbName, this.documentDbColl, id.ToString()),
                new RequestOptions { PartitionKey = new PartitionKey("Reviews") })).Document;
        }

        public async Task<Guid> CreateReviewAsync(Stream image, string reviewText)
        {
            var recordId = Guid.NewGuid();

            // save image
            var blobClient = this.storageAccount.CreateCloudBlobClient();
            var container = blobClient.GetContainerReference(this.containerName);
            var blockBlob = container.GetBlockBlobReference(recordId.ToString());
            await blockBlob.UploadFromStreamAsync(image);

            // save review
            await this.client.CreateDocumentAsync(
                UriFactory.CreateDocumentCollectionUri(this.documentDbName, this.documentDbColl),
                new CatReview
                {
                    Id = recordId,
                    MediaUrl = blockBlob.Uri.ToString(),
                    ReviewText = reviewText,
                    IsApproved = null,
                    Created = DateTime.UtcNow
                });

            // notify through queue
            var queueClient = this.storageAccount.CreateCloudQueueClient();
            var queue = queueClient.GetQueueReference(this.queueName);
            var payload = new { BlobName = recordId.ToString(), DocumentId = recordId.ToString() };
           
            queue.AddMessage(new CloudQueueMessage(JsonConvert.SerializeObject(payload)));
            return recordId;
        }

        private async Task<IEnumerable<T>> QueryAsync<T>(IQueryable<T> query)
        {
            var docQuery = query.AsDocumentQuery();
            var batches = new List<IEnumerable<T>>();

            do
            {
                var batch = await docQuery.ExecuteNextAsync<T>();

                batches.Add(batch);
            }
            while (docQuery.HasMoreResults);

            return batches.SelectMany(b => b);
        }
    }
} 