using System;
using System.ComponentModel.DataAnnotations;
using Newtonsoft.Json;

namespace CatsReviewApp.Models
{
    public class CatReview
    {
        [JsonProperty(PropertyName ="id")]
        public Guid Id { get; set; }

        public string MediaUrl { get; set; }

        [Display(Name = "Review")]
        public string ReviewText { get; set; }

        public bool? IsApproved { get; set; }

        [Display(Name = "Caption")]
        public string Caption { get; set; }

        [JsonProperty(PropertyName = "reviewId")]
        public string ReviewId { get; set; } = "Reviews";

        public DateTime Created { get; set; }
    }
}