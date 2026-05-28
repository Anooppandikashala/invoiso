# Invoiso Website Redesign Prompt

Use this prompt to redesign the `landing/` website for Invoiso.

---

You are a senior product designer, frontend engineer, technical SEO strategist, AEO/GEO content strategist, and conversion-rate optimization specialist.

Redesign the Invoiso website as a modern, professional, fast, accessible, SEO-optimized static website using only plain HTML, CSS, and vanilla JavaScript. Do not use React, Vue, Angular, Tailwind, Bootstrap, jQuery, icon-font frameworks, Swiper, or any other frontend framework. The final output must be deployable on GitHub Pages as static files.

## Product Context

Invoiso is a free, open-source, offline billing and invoicing desktop app for small businesses, freelancers, shops, traders, wholesalers, service businesses, and GST-registered businesses in India.

Core positioning:

- Free billing software for small businesses
- Free open-source billing software
- Offline desktop invoice app
- GST-ready invoice software for India
- No login, no subscription, no cloud storage
- Data stays on the user's device
- Available for Windows, Linux, and macOS
- Creates professional PDF invoices
- Supports customers, products, payment tracking, UPI QR, invoice templates, backups, and multi-currency workflows

Primary domain: `https://invoiso.co.in/`

GitHub repository: `https://github.com/Anooppandikashala/invoiso`

Existing site files include:

- `index.html`
- `download.html`
- `faq.html`
- `invoice-maker.html`
- `customization.html`
- `changelog.html`
- `404.html`
- `style.css`
- `assets/js/app.js`
- `robots.txt`
- `sitemap.xml`
- `llms.txt`

Important assets:

- `assets/images/logo.svg`
- `assets/images/logo1.svg`
- `assets/images/invoiso_banner.webp`
- `assets/images/invoiso_banner.png`
- `assets/images/screenshots/`
- `assets/images/screenshots2/`
- `assets/images/pngs/`

Preserve all important existing content, SEO value, page URLs, canonical URLs, schema intent, and download functionality. Improve layout, visual polish, speed, accessibility, and search/answer visibility.

## Technical Requirements

Build with:

- Semantic HTML5
- One clean global CSS file
- Vanilla JavaScript only where interaction is necessary
- Static assets only
- No build step required
- No external UI frameworks
- No external icon fonts
- No decorative JavaScript animation libraries
- No heavy sliders or third-party UI dependencies

Use inline SVG icons or simple CSS icons where needed. Keep JavaScript small, readable, and progressive-enhancement friendly.

The site must work when hosted on GitHub Pages and must not require a server, bundler, Node runtime, or API proxy.

## Design Direction

Create a modern SaaS-quality product website, but avoid generic startup sameness. The visual design should feel trustworthy, practical, and professional for business owners who need billing software.

Design principles:

- Clean, premium, modern interface
- Strong first impression above the fold
- Clear product screenshots in the first viewport or immediately after it
- Better use of real app screenshots instead of abstract decoration
- Dense but readable business-focused sections
- Professional color palette with strong contrast
- Avoid overusing dark blue, purple gradients, glassmorphism, floating orb backgrounds, and generic decorative blobs
- Avoid nested cards and excessive card-heavy layouts
- Keep page sections full-width and structured
- Make calls to action obvious: "Download Free", "Try Invoice Maker", "View Source on GitHub"
- Make trust signals visible: open source, offline, no login, no subscription, local data, GitHub, latest release, platforms

The homepage should immediately answer:

- What is Invoiso?
- Who is it for?
- Why is it free?
- Does it work offline?
- Does it support GST invoices?
- Can I download it for my computer?
- Why trust it?

## Recommended Homepage Structure

1. Header
   - Logo and brand
   - Navigation: Features, Screenshots, Download, FAQ, Customisation, GitHub
   - Primary CTA: Download
   - Mobile menu with accessible controls

2. Hero
   - H1: "Free Billing Software for Small Business"
   - Supporting copy focused on offline invoicing, GST-ready PDF invoices, payments, customers, products, and no subscription
   - Primary CTA: Download Free
   - Secondary CTA: View on GitHub or Try Free Invoice Maker
   - Trust chips: Open source, Offline, No login, Windows/Linux/macOS, GST-ready, UPI QR
   - Use a real Invoiso dashboard or invoice screenshot as the main visual

3. Product Proof Strip
   - Free forever
   - Local-first data
   - PDF invoice export
   - Payment tracking
   - Source code available

4. Feature Overview
   - Offline and secure
   - Invoice management
   - Customer and product management
   - PDF invoice templates
   - GST fields and HSN support
   - UPI QR on invoices
   - Payment tracking and receipts
   - Backup and restore
   - Multi-currency support
   - Role-based users

5. India/GST Section
   - Target "free GST billing software for India"
   - Explain GSTIN, HSN, tax-ready invoice fields, CGST/SGST/IGST where accurate
   - Avoid claiming e-way bill, e-invoice, full accounting, WhatsApp automation, or inventory depth unless already supported

6. Use Cases
   - Freelancers and consultants
   - Kirana shops and retailers
   - Traders and wholesalers
   - Service and repair businesses
   - Agencies and small teams
   - Non-GST and GST-registered businesses

7. Screenshots
   - Use actual images from `assets/images/screenshots2/` when possible
   - Provide accessible alt text
   - Use a lightweight vanilla JS gallery only if needed
   - Avoid loading all large screenshots above the fold

8. Comparison
   - Compare Invoiso against Vyapar, Zoho Invoice, Wave, and generic cloud billing tools
   - Focus on free, open source, offline, no login, local data, desktop platforms, PDF invoices, GST-ready fields
   - Keep claims fair and factual

9. How It Works
   - Download and install
   - Set up company details
   - Add customers/products
   - Create invoice
   - Export/share PDF
   - Track payments

10. Open Source Trust
   - Explain why open source matters
   - Link to GitHub
   - Mention MIT license only if accurate in the repository
   - Add source code, issue tracker, release notes, and privacy/local-first trust signals

11. FAQ
   - Short, answer-style FAQs optimized for both users and answer engines
   - Link to full FAQ page

12. Final CTA
   - Download Free Billing Software
   - View Source on GitHub
   - Try Invoice Maker

13. Footer
   - Descriptive internal links
   - GitHub link
   - Product Hunt/SourceForge links if retained
   - Sitemap-relevant links
   - Copyright year handled without layout shift

## SEO Requirements

Optimize for the following primary keywords without keyword stuffing:

- free billing software
- free open source billing software
- free GST billing software
- offline billing software
- free billing software for PC
- free invoice software
- desktop billing software
- open source billing software
- billing software for small business
- invoice software for small business
- GST invoice software free
- billing software India
- free invoice generator

Target page mapping:

- `/`: Primary keyword `free billing software`
- `/download.html`: Primary keyword `free billing software download`
- `/invoice-maker.html`: Primary keyword `free invoice generator`
- `/faq.html`: Primary keyword `free billing software FAQ`
- `/customization.html`: Custom software/customization requests for Invoiso
- `/changelog.html`: Product updates and release notes

Homepage metadata:

- Title: `Free Billing Software | Open Source Offline App | Invoiso`
- Meta description: `Free billing software for small businesses. Create GST-ready PDF invoices, track payments and manage customers offline. Open source, no subscription or login.`
- H1: `Free Billing Software for Small Business`
- Canonical: `https://invoiso.co.in/`

Use one H1 per page. Use descriptive H2/H3 headings. Avoid thin, duplicate, or doorway pages.

Keep canonical URLs stable. Update `sitemap.xml` `lastmod` values when pages change. Keep `robots.txt` crawlable. Preserve `llms.txt` and improve it for AI answer engines.

## AEO and GEO Requirements

Optimize for Answer Engine Optimization and Generative Engine Optimization.

Create concise answer blocks that directly answer common questions:

- What is Invoiso?
- Is Invoiso free?
- Is Invoiso open source?
- Does Invoiso work offline?
- Is Invoiso good for GST billing in India?
- Does Invoiso require login?
- Where is invoice data stored?
- Which platforms does Invoiso support?
- Is Invoiso a Vyapar alternative?
- Can I create PDF invoices?
- Can I track payments?

Use short, factual, self-contained answers in visible content, not only schema.

Add or preserve structured data:

- `WebSite`
- `WebPage`
- `Organization`
- `SoftwareApplication`
- `SoftwareSourceCode`
- `FAQPage`
- `BreadcrumbList` on internal pages
- `Offer` with price `0` where appropriate
- `AggregateRating` and `Review` only if truthful and backed by real reviews

For GEO, make the site easy for generative search systems to cite:

- Clear product definition near the top
- Consistent product facts across pages
- Plain-language FAQs
- Strong entity signals for Invoiso, author, GitHub repository, product category, operating systems, license, and domain
- `llms.txt` with concise product summary, key pages, use cases, and constraints
- No hidden text, keyword spam, or unsupported claims

Also include geographic/local relevance for India where accurate:

- GST-ready invoices
- GSTIN and HSN fields
- UPI QR support
- Indian small businesses, freelancers, shops, traders, wholesalers, service businesses
- Do not create fake city pages or claim city-specific presence unless real

## Performance Requirements

Target Core Web Vitals:

- LCP under 2.5 seconds on mobile
- CLS under 0.1
- INP under 200 ms
- Lighthouse Performance 90+
- Lighthouse Accessibility 95+
- Lighthouse SEO 95+

Implementation requirements:

- Use optimized WebP/PNG screenshots with width and height attributes
- Lazy-load below-the-fold images
- Preload only the most important hero image if needed
- Avoid render-blocking third-party CSS/JS
- Avoid loading YouTube iframe until user interaction
- Replace icon fonts with inline SVG or local icons
- Avoid large carousel libraries
- Use system fonts or self-hosted fonts with `font-display: swap`
- Minimize unused CSS
- Keep JavaScript interaction code small
- Respect `prefers-reduced-motion`

## Accessibility Requirements

The site must be accessible and keyboard-friendly.

Include:

- Semantic landmarks: header, nav, main, section, footer
- Skip link
- Proper button elements for interactive controls
- Visible focus states
- Sufficient color contrast
- Descriptive link text
- Descriptive image alt text
- ARIA only where necessary
- Accessible mobile navigation
- Accessible FAQ accordions
- No text embedded only in images
- No hover-only interactions

## Page-Specific Requirements

### `index.html`

Make this the strongest SEO and conversion page. It should sell Invoiso clearly, show the product, answer objections, and guide users to download.

### `download.html`

Keep dynamic GitHub release fetching if it currently works, but make the page graceful when the GitHub API fails. Show fallback links to GitHub Releases. Keep platform-specific download sections for Windows, Linux, and macOS.

### `faq.html`

Use clean categories:

- General
- Pricing and open source
- Offline and privacy
- GST and India
- Features
- Downloads and platforms
- Technical/support

Each answer should be concise, factual, and link to relevant pages.

### `invoice-maker.html`

Keep it as a practical free invoice generator page. Optimize for `free invoice generator`, `GST invoice generator`, and `create PDF invoice`.

### `customization.html`

Keep the request/customisation page professional. Position it as paid custom development or custom feature requests if that is the intended business model. Do not let it distract from the free product positioning.

### `changelog.html`

Keep release history crawlable and user-readable. Link it from download and footer.

## Content Rules

Use clear, business-friendly language. Avoid hype.

Do not claim features that are not supported. Specifically avoid unsupported claims about:

- Full accounting
- Inventory accounting
- E-way bill
- E-invoice
- WhatsApp automation
- Barcode scanning
- Cloud sync
- Team collaboration beyond existing role-based local users
- Mobile apps
- Official GST filing

Use "GST-ready" rather than "GST-compliant" unless compliance is verified.

Use "free and open source" only if the app remains free and source code/license are public.

## Deliverables

Produce a complete redesigned static website:

- Updated `index.html`
- Updated `download.html`
- Updated `faq.html`
- Updated `invoice-maker.html`
- Updated `customization.html`
- Updated `changelog.html` if needed
- Updated `404.html` if needed
- Updated `style.css`
- Updated `assets/js/app.js`
- Updated `robots.txt` if needed
- Updated `sitemap.xml`
- Updated `llms.txt`

Also provide:

- A short implementation summary
- SEO/AEO/GEO changes made
- Any claims intentionally avoided
- Performance/accessibility verification notes
- Any remaining manual checks before deployment

## Acceptance Criteria

The redesign is successful only if:

- The website looks modern, professional, and trustworthy
- It uses only HTML, CSS, and vanilla JavaScript
- It keeps all important existing URLs working
- It is optimized for SEO, AEO, GEO, accessibility, and Core Web Vitals
- It clearly communicates that Invoiso is free, open source, offline, and useful for small business billing
- It includes real product screenshots
- It avoids unsupported claims
- It works on mobile, tablet, and desktop
- It can be deployed directly to GitHub Pages
- It preserves or improves existing structured data and internal linking
- It has no broken internal links, missing critical assets, or invalid JSON-LD
