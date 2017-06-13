namespace CatsReviewApp.Controllers
{
    using System;
    using System.Threading.Tasks;
    using System.Web.Mvc;
    using CatsReviewApp.Models;
    using System.Linq;
    using CatsReviewApp.Services;

    public class ReviewController : Controller
    {
        private readonly ReviewProvider provider;

        public ReviewController()
        {
            this.provider = new ReviewProvider();
        }

        // GET: Review
        public async Task<ActionResult> Index()
        {
            return this.View((await this.provider.GetReviewsAsync()).OrderByDescending(r => r.Created));
        }

        // GET: Review/Details/5
        public async Task<ActionResult> Details(Guid id)
        {
            return this.View(await this.provider.GetReviewAsync(id));
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
                var id = await this.provider.CreateReviewAsync(newCatReview.Image.InputStream, newCatReview.ReviewText);

                return this.RedirectToAction("Details", new { Id = id });
            }
            catch
            {
                return this.View();
            }
        }
    }
}
