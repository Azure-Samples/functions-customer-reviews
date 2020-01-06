using Microsoft.AspNetCore.Mvc;

namespace CatsReviewApp.Components
{
    public class StatusLabelViewComponent : ViewComponent
    {
        public IViewComponentResult Invoke(bool? isApproved)
        {
            return View(isApproved);
        }
    }
}
