using System.ComponentModel.DataAnnotations;
using System.Web;

namespace CatsReviewApp.Models
{
    public class CreateCatReview : CatReview
    {
        [Display(Name = "Image File")]
        public HttpPostedFileBase Image { get; set; }
    }
}