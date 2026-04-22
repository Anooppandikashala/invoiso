// ─── Testimonials ────────────────────────────────────────────────────────────
// To add a new review, push another object into this array.
var testimonials = [
  //Uncomment after client approval:
  /*{
    name: 'Keyson',
    location: 'Jamaica',
    text: 'All-in-all, your app is a very fantastic piece of software! I look forward to supporting this project in the future, where you can probably add more features or what not! Well done bro! 👏 👏👏',
    stars: 5,
  },*/
  {
    name: 'Raul V',
    location: '',
    text: 'I\u2019ve been looking for a long time for a simple but useful invoicing program, multi platform. I found complete accounting suites, complicated, and not really useful if you just want to create invoices and keep record of payments and sales taxes. Then I found Invoiso and I was amazed!, beautiful interface and functionality, it does everything you need without complicating things like the full accounting suites. Try it, you will not be disappointed.',
    stars: 5,
  }
];

(function buildTestimonials() {
  if (testimonials.length === 0) {
    var section = document.getElementById('testimonials');
    if (section) section.style.display = 'none';
    return;
  }
  var grid = document.getElementById('testimonials-grid');
  if (!grid) return;
  if (testimonials.length === 1) grid.classList.add('single');
  else if (testimonials.length === 2) grid.classList.add('double');
  testimonials.forEach(function (t) {
    var starsHtml = '';
    for (var i = 0; i < 5; i++) {
      starsHtml += i < t.stars
        ? '<i class="fas fa-star" aria-hidden="true"></i>'
        : '<i class="far fa-star" aria-hidden="true"></i>';
    }
    var card = document.createElement('div');
    card.className = 'testimonial-card';
    card.innerHTML =
      '<div class="testimonial-header">' +
        '<div class="testimonial-stars" aria-label="' + t.stars + ' out of 5 stars">' + starsHtml + '</div>' +
        '<div class="testimonial-meta">' +
          '<span class="testimonial-name">' + t.name + '</span>' +
          (t.location ? '<span>, </span><span class="testimonial-location">' + t.location + '</span>' : '') +
        '</div>' +
      '</div>' +
      '<p class="testimonial-text">' + t.text + '</p>';
    grid.appendChild(card);
  });
})();

// ─── YouTube facade ───────────────────────────────────────────────────────────
// Inject iframe only when user clicks the thumbnail — saves ~520 KB of YouTube JS
document.addEventListener('click', function (e) {
  var el = e.target.closest('.yt-facade');
  if (!el) return;
  var iframe = document.createElement('iframe');
  iframe.src = 'https://www.youtube-nocookie.com/embed/' + el.dataset.id +
               '?rel=0&autoplay=1&origin=https://invoiso.co.in';
  iframe.title = el.dataset.title || 'Video';
  iframe.allow = 'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture';
  iframe.setAttribute('referrerpolicy', 'strict-origin-when-cross-origin');
  iframe.setAttribute('allowfullscreen', '');
  iframe.style.cssText = 'position:absolute;top:0;left:0;width:100%;height:100%;border:0;';
  el.innerHTML = '';
  el.appendChild(iframe);
  el.removeAttribute('role');
  el.removeAttribute('tabindex');
  el.style.cursor = 'default';
});
document.addEventListener('keydown', function (e) {
  if ((e.key === 'Enter' || e.key === ' ') && document.activeElement.classList.contains('yt-facade')) {
    e.preventDefault();
    document.activeElement.click();
  }
});

// ─── DOMContentLoaded ────────────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', function () {

  document.getElementById('year').textContent = new Date().getFullYear();

  // Lazy-load Swiper JS when screenshots section approaches the viewport
  var screenshotsSection = document.getElementById('screenshots');
  if (screenshotsSection) {
    if ('IntersectionObserver' in window) {
      new IntersectionObserver(function (entries, obs) {
        if (entries[0].isIntersecting) {
          obs.disconnect();
          loadSwiper();
        }
      }, { rootMargin: '400px' }).observe(screenshotsSection);
    } else {
      loadSwiper(); // fallback for old browsers
    }
  }

  // Mobile menu
  var hamburgerBtn = document.getElementById('hamburger-btn');
  var mobileMenu   = document.getElementById('mobile-menu');
  hamburgerBtn.addEventListener('click', function () {
    var isOpen = !mobileMenu.classList.contains('hidden');
    mobileMenu.classList.toggle('hidden');
    hamburgerBtn.setAttribute('aria-expanded', String(!isOpen));
  });
  mobileMenu.querySelectorAll('a').forEach(function (link) {
    link.addEventListener('click', function () {
      mobileMenu.classList.add('hidden');
      hamburgerBtn.setAttribute('aria-expanded', 'false');
    });
  });

  // 3D tilt effect for feature cards
  document.querySelectorAll('.feature-card').forEach(function (card) {
    card.addEventListener('mousemove', function (e) {
      var rect    = card.getBoundingClientRect();
      var x       = e.clientX - rect.left;
      var y       = e.clientY - rect.top;
      var rotateX = ((y / rect.height) - 0.5) * -16;
      var rotateY = ((x / rect.width)  - 0.5) *  16;
      card.style.transform = 'perspective(800px) rotateX(' + rotateX + 'deg) rotateY(' + rotateY + 'deg) translateZ(8px)';
    });
    card.addEventListener('mouseleave', function () {
      card.style.transform = '';
    });
  });

});

// ─── Swiper lazy loader ───────────────────────────────────────────────────────
function loadSwiper() {
  var script = document.createElement('script');
  script.src = 'https://cdn.jsdelivr.net/npm/swiper@10/swiper-bundle.min.js';
  script.onload = initScreenshots;
  document.body.appendChild(script);
}

// ─── Screenshots + Swiper init (runs only after Swiper JS loads) ──────────────
function initScreenshots() {
  var screenshots = [
    { src: 'login.png',                          text: 'Invoice Login Page',            alt: 'Invoiso login screen \u2014 secure desktop invoicing app for Windows and Linux',                          category: 'Invoices' },
    { src: 'dashboard.png',                      text: 'Invoice Dashboard Page',        alt: 'Invoiso dashboard showing total revenue, invoice count, and recent invoices overview',               category: 'Invoices' },
    { src: 'create_new_invoice1.png',            text: 'Create Invoice Page',           alt: 'Create a new invoice in Invoiso \u2014 select customer, add products, apply tax rate',                    category: 'Invoices' },
    { src: 'create_new_invoice2.png',            text: 'Create Invoice with Products',  alt: 'Invoiso invoice creation screen with products and line items added',                                 category: 'Invoices' },
    { src: 'invoice_actions.png',                text: 'Invoice Created Successfully',  alt: 'Invoice created successfully in Invoiso \u2014 ready to preview, print or export as PDF',                 category: 'Invoices' },
    { src: 'invoice_simple_view.png',            text: 'Invoice Details Page',          alt: 'Invoice details view in Invoiso showing customer info, line items and total amount due',             category: 'Invoices' },
    { src: 'edit_invoice.png',                   text: 'Edit Your Invoice',             alt: 'Edit an existing invoice in Invoiso \u2014 update customer, products and tax settings',                   category: 'Invoices' },
    { src: 'duplicate_invoice_list.png',         text: 'Duplicate Invoice Action',      alt: 'Invoice Duplicating action',                                                                         category: 'Invoices' },
    { src: 'invoice_lists_and_actions.png',      text: 'Invoice Listing Page',          alt: 'Invoice management list in Invoiso showing all invoices with search, filter and bulk actions',       category: 'Invoices' },
    { src: 'invoice_pdf_view.png',               text: 'Sample Invoice PDF',            alt: 'Professional PDF invoice generated by Invoiso with company logo, itemised list and total amount',    category: 'PDF' },
    { src: 'invoice_print_view.png',             text: 'Sample Invoice PDF Print View', alt: 'Professional PDF invoice Print View',                                                                category: 'PDF' },
    { src: 'Invoice_template_selection_screen.png', text: 'Invoice Templates',          alt: 'Invoiso PDF template selection \u2014 Classic, Modern and Minimal invoice templates side by side',      category: 'PDF' },
    { src: 'template_classic.png',               text: 'Classic Invoice Template',      alt: 'Classic PDF invoice template with branded company header and itemised table \u2014 Invoiso',            category: 'PDF' },
    { src: 'template_modern.png',                text: 'Modern Invoice Template',       alt: 'Modern PDF invoice template with blue header block and professional layout \u2014 Invoiso',             category: 'PDF' },
    { src: 'template_minimal.png',               text: 'Minimal Invoice Template',      alt: 'Minimal PDF invoice template \u2014 clean, simple and distraction-free design \u2014 Invoiso',           category: 'PDF' },
    { src: 'customer_list.png',                  text: 'Customer Management Page',      alt: 'Customer management screen in Invoiso showing client list with search, sort and edit options',       category: 'Clients' },
    { src: 'edit_customer.png',                  text: 'Customer Editing Page',         alt: 'Edit customer details in Invoiso \u2014 name, email, phone, address and GSTIN fields',                  category: 'Clients' },
    { src: 'product_list.png',                   text: 'Product Management Page',       alt: 'Product management screen in Invoiso showing items with price, stock and HSN code',                  category: 'Products' },
    { src: 'edit_product.png',                   text: 'Product Editing Page',          alt: 'Edit product in Invoiso \u2014 set name, price, stock, HSN code and tax rate',                          category: 'Products' },
    { src: 'system_users_management.png',        text: 'User Management Page',          alt: 'User management screen in Invoiso \u2014 add and manage app users with role-based access',              category: 'Settings' },
    { src: 'Company_settings_page.png',          text: 'Organisation Information',      alt: 'Company information settings in Invoiso \u2014 name, address, phone, email, GSTIN and logo',            category: 'Settings' },
    { src: 'invoice_settings_page.png',          text: 'Invoice Settings',              alt: 'Invoice settings screen in Invoiso \u2014 configure prefix, currency, tax and UPI QR code',             category: 'Settings' },
    { src: 'backup_and_restore_page.png',        text: 'Backup Management',             alt: 'Backup and restore screen in Invoiso \u2014 one-click database backup to keep your data safe',          category: 'Settings' },
    { src: 'software_info_page.png',             text: 'About Invoiso',                 alt: 'About Invoiso screen \u2014 version, developer info and open source license details',                   category: 'Settings' },
  ];

  // Build slides
  var wrapper = document.getElementById('screenshots-wrapper');
  screenshots.forEach(function (item, index) {
    var slide = document.createElement('div');
    slide.classList.add('swiper-slide');
    slide.dataset.customText = item.text;
    slide.innerHTML =
      '<img src="assets/images/screenshots/' + item.src + '" ' +
           'alt="' + item.alt + '" ' +
           'loading="lazy" width="1280" height="800" data-index="' + index + '" />';
    wrapper.appendChild(slide);
  });

  // Init Swiper
  var swiper = new Swiper('.screenshots-swiper', {
    effect: 'coverflow',
    grabCursor: true,
    centeredSlides: true,
    slidesPerView: 'auto',
    loop: true,
    autoplay: { delay: 4000, disableOnInteraction: false, pauseOnMouseEnter: true },
    coverflowEffect: { rotate: 25, stretch: 0, depth: 250, modifier: 1, slideShadows: false },
    pagination: { el: '.swiper-pagination', clickable: true, dynamicBullets: true },
    navigation: { nextEl: '.swiper-button-next', prevEl: '.swiper-button-prev' },
    breakpoints: { 640: { slidesPerView: 1 }, 768: { slidesPerView: 1.5 }, 1024: { slidesPerView: 2 } },
  });

  // Category filter chips
  var chipCategories = [
    { id: 'All',      icon: 'fas fa-th-large'    },
    { id: 'Invoices', icon: 'fas fa-file-invoice' },
    { id: 'PDF',      icon: 'fas fa-file-pdf'    },
    { id: 'Clients',  icon: 'fas fa-users'       },
    { id: 'Products', icon: 'fas fa-box'         },
    { id: 'Settings', icon: 'fas fa-cog'         },
  ];
  var chipsEl = document.getElementById('screenshots-chips');
  chipCategories.forEach(function (cat) {
    var count = cat.id === 'All'
      ? screenshots.length
      : screenshots.filter(function (s) { return s.category === cat.id; }).length;
    var btn = document.createElement('button');
    btn.className = 'screenshot-chip' + (cat.id === 'All' ? ' active' : '');
    btn.dataset.category = cat.id;
    btn.type = 'button';
    btn.setAttribute('aria-pressed', cat.id === 'All' ? 'true' : 'false');
    btn.innerHTML = '<i class="' + cat.icon + '" aria-hidden="true"></i> ' + cat.id +
                    ' <span class="chip-count">' + count + '</span>';
    btn.addEventListener('click', function () {
      chipsEl.querySelectorAll('.screenshot-chip').forEach(function (c) {
        c.classList.remove('active');
        c.setAttribute('aria-pressed', 'false');
      });
      btn.classList.add('active');
      btn.setAttribute('aria-pressed', 'true');
      var targetIndex = cat.id === 'All'
        ? 0
        : screenshots.findIndex(function (s) { return s.category === cat.id; });
      swiper.slideToLoop(targetIndex < 0 ? 0 : targetIndex, 600);
    });
    chipsEl.appendChild(btn);
  });

  // Caption + chip sync
  var captionCatEl  = document.getElementById('caption-category');
  var captionTextEl = document.getElementById('custom-bottom-text');
  function updateCaption() {
    var s = screenshots[swiper.realIndex];
    if (!s) return;
    if (captionCatEl)  captionCatEl.textContent  = s.category;
    if (captionTextEl) captionTextEl.textContent = s.text;
    chipsEl.querySelectorAll('.screenshot-chip').forEach(function (c) {
      var match = c.dataset.category === s.category;
      c.classList.toggle('active', match);
      c.setAttribute('aria-pressed', match ? 'true' : 'false');
    });
  }
  swiper.on('slideChange', updateCaption);
  updateCaption();

  // Image preview modal
  var previewModal = document.getElementById('imagePreview');
  var previewImg   = document.getElementById('previewImg');
  var currentImage = 0;
  function openPreview(index) {
    currentImage = index;
    previewImg.src = 'assets/images/screenshots/' + screenshots[index].src;
    previewImg.alt = screenshots[index].alt;
    previewModal.style.display = 'flex';
    document.getElementById('closePreviewBtn').focus();
  }
  function closePreview() { previewModal.style.display = 'none'; }
  function changeImage(dir) {
    currentImage = (currentImage + dir + screenshots.length) % screenshots.length;
    previewImg.src = 'assets/images/screenshots/' + screenshots[currentImage].src;
    previewImg.alt = screenshots[currentImage].alt;
  }
  document.getElementById('closePreviewBtn').addEventListener('click', closePreview);
  document.getElementById('prevImgBtn').addEventListener('click', function () { changeImage(-1); });
  document.getElementById('nextImgBtn').addEventListener('click', function () { changeImage(1); });
  wrapper.addEventListener('click', function (e) {
    var img = e.target.closest('img[data-index]');
    if (img) openPreview(parseInt(img.dataset.index, 10));
  });
  document.addEventListener('keydown', function (e) {
    if (previewModal.style.display === 'flex') {
      if (e.key === 'Escape')     closePreview();
      if (e.key === 'ArrowLeft')  changeImage(-1);
      if (e.key === 'ArrowRight') changeImage(1);
    }
  });
  previewModal.addEventListener('click', function (e) {
    if (e.target === previewModal) closePreview();
  });
}

// ─── Navbar scroll effect ─────────────────────────────────────────────────────
window.addEventListener('scroll', function () {
  document.querySelector('.navbar').classList.toggle('scrolled', window.scrollY > 50);
});

// ─── Scroll-reveal ────────────────────────────────────────────────────────────
(function initReveal() {
  var revealEls = document.querySelectorAll('.reveal');
  if (!revealEls.length) return;
  var observer = new IntersectionObserver(function (entries) {
    entries.forEach(function (entry) {
      if (entry.isIntersecting) {
        entry.target.classList.add('visible');
        observer.unobserve(entry.target);
      }
    });
  }, { threshold: 0.12 });
  revealEls.forEach(function (el) { observer.observe(el); });
})();

// ─── Navbar active section highlight ─────────────────────────────────────────
(function initNavHighlight() {
  var sections = document.querySelectorAll('main section[id]');
  var navLinks = document.querySelectorAll('.navbar nav ul a[href^="#"]');
  if (!sections.length || !navLinks.length) return;
  var observer = new IntersectionObserver(function (entries) {
    entries.forEach(function (entry) {
      if (entry.isIntersecting) {
        navLinks.forEach(function (a) {
          a.classList.toggle('nav-active', a.getAttribute('href') === '#' + entry.target.id);
        });
      }
    });
  }, { rootMargin: '-40% 0px -50% 0px' });
  sections.forEach(function (s) { observer.observe(s); });
})();

// ─── Nav link click tracking ──────────────────────────────────────────────────
(function trackNavClicks() {
  var links = document.querySelectorAll('.navbar a');
  links.forEach(function (a) {
    a.addEventListener('click', function () {
      if (typeof gtag !== 'function') return;
      gtag('event', 'nav_click', {
        link_text: a.textContent.trim(),
        link_url: a.getAttribute('href'),
      });
    });
  });
})();
