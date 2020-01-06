namespace CatsReviewApp.Controllers
{
    using CatsReviewApp.Models;
    using CatsReviewApp.Services;
    using Microsoft.AspNetCore.Mvc;
    using System;
    using System.Linq;
    using System.Threading.Tasks;

    public class ReviewController : Controller
    {
        private readonly ReviewProvider reviewProvider;

        public ReviewController(ReviewProvider reviewProvider)
        {
            this.reviewProvider = reviewProvider;
        }

        // GET: Review
        public async Task<ActionResult> Index()
        {
            return this.View((await this.reviewProvider.GetReviewsAsync()).OrderByDescending(r => r.Created));
        }

        // GET: Review/Details/5
        public async Task<ActionResult> Details(Guid id)
        {
            return this.View(await this.reviewProvider.GetReviewAsync(id));
        }

        // GET: Review/Create
        public ActionResult Create()
        {
            return this.View();
        }

        // POST: Review/Create
        [HttpPost]
        public async Task<ActionResult> Create(CreateCatReview newCatReview)
        {
            try
            {
                var id = await this.reviewProvider.CreateReviewAsync(newCatReview.Image.OpenReadStream(), newCatReview.ReviewText);

                return this.RedirectToAction("Details", new { Id = id });
            }
            catch
            {
                return this.View();
            }
        }
    }
}
