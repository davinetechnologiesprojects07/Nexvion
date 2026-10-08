
# Nexvion Application Analysis

| Item | Finding |
|---|---|
| Frontend | Static HTML/CSS/JS: index.html, products.html, payment.html, style.css, products.css, payment.css, script.js, payment.js |
| Backend | None. No fetch/XHR/axios calls found |
| Database | None. Browser localStorage only (nexvionCart, nexvionUsers, nexvionCurrentUser, nexvionCheckout, nexvionLastOrder) |
| Build process | None. Files are served as-is |
| Dependencies | No package manager. External: Google Fonts, Unsplash images |
| Runtime requirement | Any static web server (Nginx chosen) |
| Port | 80 inside the container |
| API endpoints | None |
| Health endpoint | None in the app. /healthz will be added at the Nginx layer |
| Environment variables | None required |
| Application logs | Nginx access and error logs |
| Security note | Auth and payment are frontend demo only. Passwords/card data must never be treated as real |
| CSP note | Content-Security-Policy must allow fonts.googleapis.com, fonts.gstatic.com, images.unsplash.com |
