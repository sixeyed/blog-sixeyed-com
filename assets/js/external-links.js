// Make external links and redirects open in new tab
document.addEventListener('DOMContentLoaded', function() {
  // Select all external links and /l/ redirects in post content
  const externalLinks = document.querySelectorAll('.page__content a[href^="http"]:not([href*="blog.sixeyed.com"]), .page__content a[href^="https"]:not([href*="blog.sixeyed.com"]), .page__content a[href^="/l/"]');
  
  externalLinks.forEach(link => {
    link.setAttribute('target', '_blank');
    link.setAttribute('rel', 'noopener noreferrer');
  });
});