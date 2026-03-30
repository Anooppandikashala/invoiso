<div align="center">
  <img src="landing/assets/images/logo.svg" alt="Invoiso Logo" width="200" />

  <h1>Invoiso</h1>

  <p><strong>Free offline invoice &amp; billing software for Windows &amp; Linux</strong></p>
  <p>Create professional PDF invoices, track payments, manage customers, products and inventory — entirely offline. Built for small businesses, shops and freelancers. No subscription, no cloud, no account needed.</p>

  <p>
    <a href="https://github.com/Anooppandikashala/invoiso/releases/latest">
      <img src="https://img.shields.io/github/v/release/Anooppandikashala/invoiso?label=Latest%20Release&color=4f8ef7" alt="Latest Release" />
    </a>
    <img src="https://img.shields.io/badge/Platform-Windows%20%7C%20Linux-blue" alt="Platform" />
    <img src="https://img.shields.io/badge/License-MIT-green" alt="License" />
    <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter" alt="Flutter" />
    <img src="https://img.shields.io/badge/Price-Free-brightgreen" alt="Free" />
  </p>

  <p>
    <a href="https://www.producthunt.com/products/invoiso?embed=true&utm_source=badge-featured&utm_medium=badge&utm_campaign=badge-invoiso" target="_blank" rel="noopener noreferrer"><img alt="Invoiso - Free Offline Invoice &amp; Billing Software for all. | Product Hunt" width="250" height="54" src="https://api.producthunt.com/widgets/embed-image/v1/featured.svg?post_id=1105229&theme=light&t=1774412242179" /></a>
    &nbsp;
    <a href="https://www.shipit.buzz/products/invoiso?ref=badge" target="_blank" rel="noopener noreferrer"><img src="https://www.shipit.buzz/api/products/invoiso/badge?theme=light" alt="Featured on Shipit" height="54" /></a>
  </p>

  <p>
    <a href="https://anooppandikashala.github.io/invoisoapp/">🌐 Website</a> &nbsp;·&nbsp;
    <a href="https://anooppandikashala.github.io/invoisoapp/download.html">⬇️ Download</a> &nbsp;·&nbsp;
    <a href="https://anooppandikashala.github.io/invoisoapp/faq.html">❓ FAQ</a> &nbsp;·&nbsp;
    <a href="https://github.com/Anooppandikashala/invoiso/issues">🐛 Report a Bug</a>
  </p>

  <br/>

  <img src="landing/assets/images/pngs/invoiso_banner.png" alt="Invoiso — Free Offline Invoice &amp; Billing Software for Windows and Linux" width="100%" />
</div>

---

## ✨ Features

### Invoicing
- **100% Offline** — All data stored locally in SQLite. No internet required, ever.
- **PDF Invoice Generation** — One-click professional PDFs in Classic, Modern, or Minimal templates.
- **Invoice & Quotation** — Create both invoice and quotation documents with colour-coded status tracking.
- **Invoice Cloning** — Duplicate any invoice or quotation in one click.
- **Bulk Actions** — Multi-select invoices to bulk export CSV, generate PDFs, or move to trash.
- **Soft Delete / Trash** — Deleted invoices go to a recoverable Trash view.
- **CSV Export** — Export invoice data to CSV for spreadsheets or accounting software.

### Payment Tracking
- **Payment Recording** — Record multiple partial or full payments against any invoice.
- **Payment Status** — Automatic Unpaid / Partial / Paid tracking with colour-coded chips.
- **Payment Receipts** — Download a professional PDF receipt for every payment.
- **Outstanding Balance** — Running balance calculated and shown across all views.
- **PDF Payment Summary** — Invoice PDFs show Amount Paid, Amount Due, and a PAID IN FULL stamp.

### Finance & Compliance
- **Multi-Currency** — INR, USD, EUR, GBP, JPY, AED, SGD, AUD, CAD — stored per invoice.
- **GST Ready** — GSTIN fields, HSN codes, per-item or global tax rates for Indian businesses.
- **UPI Payment QR** — Embed a scannable UPI QR code in every PDF (GPay, PhonePe, Paytm).

### Data Management
- **Customer Management** — Full CRUD with search, sort, and pagination.
- **Product & Inventory Management** — Full CRUD with search, sort, and pagination.
- **Backup & Restore** — One-click database backup to any location on your machine.

### Security & Access Control
- **Multi-User Login** — Username and password authentication with session timeout.
- **Role-Based Access** — Admin and standard user roles with separate permissions.
- **Admin-Only Actions** — Company settings, PDF settings, backup/restore, and all deletes restricted to admins.
- **Forced Password Change** — New users must change their password on first login.

### General
- **No Registration** — No account, no email, no cloud sync required.
- **Free Forever** — MIT licensed, open source.

---

## 📸 Screenshots

<div align="center">

| Dashboard | Create Invoice | Invoice PDF |
|:---------:|:--------------:|:-----------:|
| ![Dashboard](landing/assets/images/screenshots/dashboard.png) | ![Create Invoice](landing/assets/images/screenshots/create_new_invoice1.png) | ![Invoice PDF](landing/assets/images/screenshots/invoice_pdf_view.png) |

| Classic Template | Modern Template | Minimal Template |
|:---------------:|:---------------:|:----------------:|
| ![Classic](landing/assets/images/screenshots/template_classic.png) | ![Modern](landing/assets/images/screenshots/template_modern.png) | ![Minimal](landing/assets/images/screenshots/template_minimal.png) |

</div>

---

## 🔐 Default Login

| Username | Password |
|----------|----------|
| `admin`  | `admin`  |

> You will be prompted to change the password on first login.

---

## ⬇️ Download

**Latest version: v3.4.2**

| Platform | Format | Link |
|----------|--------|------|
| **Windows** | `.exe` Installer | [Download v3.4.2](https://anooppandikashala.github.io/invoisoapp/download.html) |
| **Linux** | `.AppImage` (portable) | [Download v3.4.2](https://anooppandikashala.github.io/invoisoapp/download.html) |
| **Linux** | `.deb` Package | [Download v3.4.2](https://anooppandikashala.github.io/invoisoapp/download.html) |

> Always download from the [official website](https://anooppandikashala.github.io/invoisoapp/download.html) or the [GitHub releases page](https://github.com/Anooppandikashala/invoiso/releases/latest).

---

## 🛠️ Build from Source

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) `>=3.3.3 <4.0.0`
- Linux: `clang`, `cmake`, `ninja-build`, `libgtk-3-dev`
- Windows: Visual Studio 2022 with "Desktop development with C++" workload

### Steps

```bash
# 1. Clone the repository
git clone https://github.com/Anooppandikashala/invoiso.git
cd invoiso

# 2. Install dependencies
flutter pub get

# 3. Run in debug mode
flutter run -d linux      # Linux
flutter run -d windows    # Windows

# 4. Build a release binary
flutter build linux --release    # Linux
flutter build windows --release  # Windows
```

Output locations:
- **Linux:** `build/linux/x64/release/bundle/`
- **Windows:** `build/windows/x64/runner/Release/`

---

## 🏗️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | [Flutter](https://flutter.dev) 3.x (Dart) |
| Database | SQLite via [sqflite](https://pub.dev/packages/sqflite) + [sqflite_common_ffi](https://pub.dev/packages/sqflite_common_ffi) |
| PDF Generation | [pdf](https://pub.dev/packages/pdf) + [printing](https://pub.dev/packages/printing) |
| PDF Preview | [syncfusion_flutter_pdfviewer](https://pub.dev/packages/syncfusion_flutter_pdfviewer) |
| QR Codes | [qr](https://pub.dev/packages/qr) |
| State Management | [flutter_riverpod](https://pub.dev/packages/flutter_riverpod) |
| File Picker | [file_picker](https://pub.dev/packages/file_picker) |
| CSV Export | [csv](https://pub.dev/packages/csv) |
| File Sharing | [share_plus](https://pub.dev/packages/share_plus) |
| Image Processing | [image](https://pub.dev/packages/image) |
| Window Management | [window_manager](https://pub.dev/packages/window_manager) |
| Security | [crypto](https://pub.dev/packages/crypto) |

---

## 📁 Project Structure

```
lib/
├── main.dart                        # App entry point, window setup
├── common.dart                      # Shared enums, extensions, data classes
├── constants.dart                   # UI constants, spacing, font sizes
│
├── models/                          # Data models
│   ├── invoice.dart                 # Invoice + PaymentStatus
│   ├── invoice_item.dart            # Line items
│   ├── invoice_payment.dart         # Payment records
│   ├── customer.dart
│   ├── product.dart
│   ├── company_info.dart
│   ├── user.dart                    # User + role (admin/user)
│   └── backup_info.dart / backup_results.dart
│
├── database/                        # SQLite CRUD services
│   ├── database_helper.dart         # DB init, migrations (v1→v6)
│   ├── invoice_service.dart
│   ├── invoice_item_service.dart
│   ├── payment_service.dart         # Payment recording & history
│   ├── customer_service.dart
│   ├── product_service.dart
│   ├── company_info_service.dart
│   ├── settings_service.dart        # Key-value settings store
│   └── user_service.dart
│
├── providers/                       # Riverpod state providers
│   ├── invoice_provider.dart
│   └── product_provider.dart
│
├── screens/                         # UI screens
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── change_password_screen.dart
│   ├── dashboard_screen.dart        # Dashboard + DashboardHome widget
│   ├── create_invoice_screen.dart   # Create / edit invoice & quotation
│   ├── invoice_management_screen.dart
│   ├── customer_management_screen.dart
│   ├── product_management_screen.dart
│   ├── settings_screen.dart         # Settings hub (admin-only sections)
│   ├── invoice_settings_screen.dart
│   ├── pdf_settings_screen.dart
│   ├── backup_management_screen.dart
│   └── user_management_screen.dart
│
├── services/                        # Business logic & file services
│   ├── pdf_service.dart             # PDF generation (3 templates)
│   ├── invoice_pdf_services.dart    # Print, preview, export wrapper
│   ├── payment_receipt_service.dart # Payment receipt PDF generation
│   └── export_service.dart          # CSV & bulk PDF export
│
├── backup/
│   └── backup_manager.dart          # Backup & restore logic
│
├── widgets/
│   └── apply_payment_dialog.dart    # Shared payment dialog & summary card
│
└── utils/
    ├── app_logger.dart
    ├── error_handler.dart
    ├── formatters.dart
    ├── password_utils.dart          # HMAC-SHA256 hashing + salt
    └── session_manager.dart         # Inactivity session timeout
```

---

## 🤝 Contributing

Contributions, bug reports, and feature requests are welcome.

1. **Fork** the repository
2. **Create** a feature branch: `git checkout -b feature/your-feature`
3. **Commit** your changes: `git commit -m "Add your feature"`
4. **Push** to the branch: `git push origin feature/your-feature`
5. **Open a Pull Request**

For bug reports and feature requests, please use [GitHub Issues](https://github.com/Anooppandikashala/invoiso/issues).

---

## 📄 License

Invoiso is released under the [MIT License](LICENSE).
Copyright © 2025 [Anoop Pandikashala](https://github.com/Anooppandikashala)

---

<div align="center">
  <p>If Invoiso saves you time, consider supporting its development.</p>

  [![Buy Me a Coffee](https://img.buymeacoffee.com/button-api/?text=Buy%20me%20a%20coffee&emoji=☕&slug=anoopp&button_colour=FFDD00&font_colour=000000&font_family=Cookie&outline_colour=000000&coffee_colour=ffffff)](https://www.buymeacoffee.com/anoopp)
</div>
