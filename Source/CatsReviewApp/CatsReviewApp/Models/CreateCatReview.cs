using Microsoft.AspNetCore.Http;
using System.ComponentModel.DataAnnotations;

namespace CatsReviewApp.Models
{
    public class CreateCatReview : CatReview
    {
        [Display(Name = "Image File")]
        public IFormFile Image { get; set; }
    }
}