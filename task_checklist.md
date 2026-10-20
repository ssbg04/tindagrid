# TindaGrid — Implementation Task Checklist

A phased, actionable roadmap for building the offline-first micro-ERP, POS, local AI assistant, and crowdsourced retail data platform.

---

## 📌 Phase 1: Environment & Cloud Infrastructure Setup

- [x] **1.1 Flutter Mobile & Web PWA Setup**
  - [x] Initialize Flutter project targeting Android (minSdk 24), Web (Offline-First PWA), and later iOS.
  - [x] Configure `web/manifest.json` (standalone display mode, theme colors, app icons).
  - [x] Configure `flutter_service_worker.js` with offline-first caching strategy.
  - [x] Call `navigator.storage.persist()` on web initialization to prevent browser cache eviction.
  - [x] Configure state management (`flutter_riverpod` or `bloc`).
  - [x] Set up Soft UI design system with minimalism, Google Fonts (`Outfit` & `Inter`), Light & Dark themes, and bilingual Taglish/English support (refer to [ui_ux_design.md](file:///f:/SoftwareDevelopment/E-Tindahan/ui_ux_design.md)).
- [x] **1.2 NestJS Monorepo Microservices Workspace Setup**
  - [x] Initialize NestJS monorepo workspace in `backend/` with `nest-cli.json`.
  - [x] Configure `apps/` directory for microservices (`api-gateway`, `sync-service`, `catalog-service`, `storefront-service`, `b2b-analytics-service`).
  - [x] Configure `libs/` directory for shared code (`@lib/database`, `@lib/common`, `@lib/contracts`).
  - [x] Set up Prisma or Drizzle ORM in `libs/database` configured for PostgreSQL.
  - [x] Configure environment variables (`.env`) and validation (`@nestjs/config`).
- [x] **1.3 Neon.tech Database Setup**
  - [x] Create free PostgreSQL project on [neon.tech](https://neon.tech).
  - [x] Enable PostGIS extension (`CREATE EXTENSION IF NOT EXISTS postgis;`).
  - [x] Test serverless connection pooling strings from NestJS.
- [x] **1.4 Cloudflare R2 Storage Setup**
  - [x] Create an R2 bucket (e.g., `tindagrid-storefronts`).
  - [x] Configure CORS policy allowing uploads from mobile/web origins.
  - [x] Generate S3-compatible API access keys (Access Key ID & Secret).
- [x] **1.5 Free Backend Deployment (Render / Vercel)**
  - [x] Connect GitHub repository to Render (Free Web Service).
  - [x] Set up a `/health` endpoint in NestJS.
  - [x] Configure a free ping monitor ([cron-job.org](https://cron-job.org) or UptimeRobot) every 13 minutes to prevent 15-minute idle sleep.

---

## 💾 Phase 2: Local SQLite Database & Offline Engine (Flutter)

- [x] **2.1 SQLite Schema & Migration Setup (`drift` or `powersync`)**
  - [x] `products`: Barcode, name, category, cost price, selling price, current stock, is_tingi.
  - [x] `inventory_logs`: Product ID, change quantity, reason (restock, sale, damage, audit).
  - [x] `sales` & `sale_items`: Timestamp, payment method (Cash/GCash), total amount, profit.
  - [x] `debts` & `debt_items`: Customer name, phone, item list, borrowed date, due date, status.
  - [x] `payables`: Supplier/bodega debts, due dates, reminder notes.
  - [x] `gcash_ledger`: Transaction type (Cash-In/Cash-Out/Payment), amount, fee charged, reference number.
  - [x] `gcash_fee_config`: Fee brackets (min amount, max amount, fixed fee, percentage fee).
  - [x] `sync_queue`: Pending local changes queued for background upload.
- [x] **2.2 Merchant Authentication & PIN Recovery (Zero-Friction & $0 SMS Cost)**
  - [x] Implement Phone Number (`09xx-xxx-xxxx`) + 4–6 Digit Store PIN authentication.
  - [x] Support immediate offline usage without mandatory registration (register on sync/backup).
  - [x] Implement multi-method PIN recovery:
    - [x] Trusted device unlock via `local_auth` (Fingerprint / Face ID / Screen Lock PIN).
    - [x] Security question & answer recovery (Pet name, mother's maiden name, favorite snack).
    - [x] Optional backup email for 6-digit OTP reset.
  - [x] Issue 30-day JWT token saved to Flutter secure storage (`flutter_secure_storage`).
- [x] **2.3 Delta Synchronization & Multi-Device Cloud Sync Engine**
  - [x] Implement local change tracker logging mutations to `sync_queue`.
  - [x] Implement manual **"Sync Now"** button + background worker on internet detection (`connectivity_plus`).
  - [x] Support multi-device login syncing store sales/inventory to owner's laptop or secondary phone.
  - [x] Implement cloud disaster recovery (auto-restore full catalog & ledgers on new device login).
  - [x] Handle conflict resolution (last-write-wins for inventory counts, additive for financial ledgers).

---

## 🛒 Phase 3: Barcode POS & Inventory Management (Flutter Mobile & Web)

- [x] **3.1 Scanner & Audio/Haptic Feedback**
  - [x] Integrate `mobile_scanner` with custom viewfinder overlay and flash toggle for Android/iOS.
  - [x] Configure audio feedback: High beep for success, low double-buzz for failure.
  - [x] Configure haptic feedback via `vibration` (crisp 50ms pulse vs heavy double pulse).
- [x] **3.2 Barcode & Checkout Fallbacks on Flutter Web (Without Scanner Guns)**
  - [x] Integrate laptop/webcam barcode scanning via HTML5 `getUserMedia`.
  - [x] Build **Smartphone Companion Scanner Mode** (pair web POS with phone camera via QR code).
  - [x] Implement instant predictive search bar (type 2 letters to find items) + keyboard Enter.
  - [x] Implement 2-digit Price Look-Up (PLU) shortcut numbers for fast keyboard-only entry.
  - [x] Support USB/wireless barcode scanner guns via Flutter `HardwareKeyboard` listener.
- [x] **3.3 Barcode Auto-Fill & Quick Add**
  - [x] Query local SQLite/IndexedDB database on barcode detection.
  - [x] Query crowdsourced NestJS barcode API if not found locally.
  - [x] Auto-open **"Quick-Add Product"** modal with barcode pre-filled if unrecognized.
- [x] **3.4 Tingi / Sachet Quick-Tap Visual Grid**
  - [x] Grid of customizable picture buttons for unbarcoded goods (eggs, ice, candy, sachets).
  - [x] Quick quantity multipliers (+1, +5, +10).
- [x] **3.5 Cart & Checkout**
  - [x] Dynamic cart with real-time total and estimated merchant profit.
  - [x] Dual-payment selector: Cash (with auto change calculator) vs. GCash.

---

## 📱 Phase 4: GCash Float Ledger, Fee Scheduler & Rate Card PDF

- [x] **4.1 GCash Cash-In & Cash-Out Ledger**
  - [x] Dedicated ledger for Cash-In, Cash-Out, and Store Sales payments.
  - [x] Real-time float calculation (GCash E-Wallet Balance vs. Physical Cash Drawer).
- [x] **4.2 Customizable Fee Schedule (Editable Rates)**
  - [x] UI to create and edit custom fee brackets (e.g., ₱1–₱500 = ₱10; ₱501–₱1,000 = ₱15).
  - [x] Support flat percentage rates (e.g., 1.5% or 2%).
  - [x] Automatic fee calculation at checkout based on transaction amount.
- [x] **4.3 Printable Rate Card PDF Generator**
  - [x] Integrate Flutter packages: `pdf` and `printing`.
  - [x] Design branded, high-contrast PDF layout for GCash service fees.
  - [x] Support printable formats: Standard A4, A5, and 58mm/80mm POS thermal receipt.
  - [x] Options to direct-print to Bluetooth thermal printer or export as image/PDF to share or laminate.
- [x] **4.4 On-Device GCash Receipt OCR**
  - [x] Camera scanner using `google_mlkit_text_recognition`.
  - [x] Regex parser extracting 13-digit GCash Reference Number from customer screen.
  - [x] Duplicate check against existing logged reference numbers to prevent screenshot scams.

---

## 📝 Phase 5: Bi-Directional Debt Tracker (*Utang* & Payables)

- [x] **5.1 Receivables (*Pautang sa Tao*)**
  - [x] Customer directory with contact number and credit limit.
  - [x] Itemized debt logging with partial payment tracking.
  - [x] 1-tap shareable debt reminder via SMS, Messenger, or WhatsApp.
- [x] **5.2 Payables (*Utang sa Bodega*)**
  - [x] Supplier debt ledger tracking upcoming due dates for delivery vans or wholesale agents.
  - [x] In-app banner alert for debts due within 48 hours.

---

## 🤖 Phase 6: Mini Offline Local AI Assistant

- [x] **6.1 Deterministic Intent-to-SQL Engine (Primary / Budget Phones)**
  - [x] Taglish NLP tokenizer and regex slot-filler (dates, names, metrics).
  - [x] Map intents to parameterized local SQLite queries:
    - `INTENT_TOP_DEBTORS`: Query customers with largest unpaid balance.
    - `INTENT_LOW_STOCK`: Query products below minimum safety threshold.
    - `INTENT_SALES_SUMMARY`: Query sales grouped by date and payment mode (Cash vs. GCash).
    - `INTENT_GCASH_PROFIT`: Query total fees collected from Cash-In/Cash-Out.
- [x] **6.2 Optional SLM Pipeline (Capable Phones with >=3GB RAM)**
  - [x] Evaluate `llama_cpp_dart` or ONNX Runtime Mobile with **SmolLM2-135M-Instruct** (4-bit Q4_K_M).
  - [x] System prompt constraining model to valid SQLite `SELECT` queries only.
  - [x] Device RAM check fallback (devices <3GB automatically route to deterministic engine).
- [x] **6.3 Assistant UI**
  - [x] Bottom-sheet chat drawer with voice-to-text / text input.
  - [x] Quick-action suggestion chips (*"Sino may utang?"*, *"Mababang stock"*, *"Benta kahapon"*).

---

## ☁️ Phase 7: Central NestJS Monorepo Microservices & Neon Database

- [x] **7.1 Microservices & Shared Libraries Implementation**
  - [x] **`apps/api-gateway`:** Unified HTTP/REST gateway, JWT merchant auth, rate limiting, and request routing.
  - [x] **`apps/sync-service`:** Delta synchronization workers (`POST /sync/push`, `GET /sync/pull`) & conflict resolution.
  - [x] **`apps/catalog-service`:** Crowdsourced global barcode registry (`GET /barcodes/:code`, `POST /barcodes`).
  - [x] **`apps/storefront-service`:** Store profiles, PostGIS spatial queries, and Cloudflare R2 pre-signed photo upload URLs.
  - [x] **`apps/b2b-analytics-service`:** Rate-limited B2B API protected by API keys (`X-API-Key`) for FMCG retail data feeds.
  - [x] **`libs/database` & `libs/common`:** Shared Prisma client, Neon connection pool, DTOs, guards, and logging interceptors.
- [x] **7.2 PostGIS Spatial Queries**
  - [x] Store geographic point using `ST_SetSRID(ST_MakePoint(lng, lat), 4326)`.
  - [x] Implement radius query (`ST_DWithin`) to find stores within X meters.
- [x] **7.3 Hybrid Deployment Configuration**
  - [x] Set up single-container unified launcher for $0 MVP on Render / Vercel (<150 MB RAM).
  - [x] Configure independent microservice Dockerfiles for future horizontal scaling.


---

## 🌐 Phase 8: Storefront Discovery & Cloudflare Pages Web Link

- [x] **8.1 Storefront Profile & Photo Upload**
  - [x] Flutter camera capture for physical storefront photo.
  - [x] Client-side WebP compression (max 200 KB) using `flutter_image_compress`.
  - [x] Direct S3 upload to Cloudflare R2 via pre-signed URL.
- [x] **8.2 Draft vs. Public Storefront Toggle**
  - [x] Store settings toggle controlling visibility in public directory.
- [x] **8.3 Public Storefront Web App (Cloudflare Pages)**
  - [x] Lightweight standalone web app (HTML/CSS/JS or simple Flutter Web / Svelte) deployed on Cloudflare Pages.
  - [x] Dynamic store page URL: `tindagrid.com/:store-slug`.
  - [x] Display verified photo, address, operating hours, GPS pin on Leaflet/OpenStreetMap, and live product catalog.
- [x] **8.4 Flutter Merchant Web PWA Build & Cloudflare Pages Deployment**
  - [x] Configure production build: `flutter build web --pwa-strategy offline-first --wasm`.
  - [x] Deploy PWA to Cloudflare Pages for `app.tindagrid.com`.
  - [x] Verify PWA installation prompt ("Install App" / "Add to Home Screen") on Chrome & Edge.
  - [x] Test complete offline functionality (disconnect internet and verify app loads & registers sales from Cache).


---

## 🚀 Phase 9: Testing, Optimization & Deployment

- [ ] **9.1 Offline Stress Testing**
  - [ ] Test offline transactions with 500+ items logged without internet.
  - [ ] Test reconnecting to internet and verify delta sync integrity.
- [ ] **9.2 Performance & Memory Optimization**
  - [ ] Verify Flutter app memory stays below 150 MB on entry-level Android devices.
  - [ ] Confirm NestJS production bundle runs under 150 MB RAM on Render.
- [ ] **9.3 Build Automation**
  - [ ] Set up GitHub Actions CI workflow to build release Android APK.
  - [ ] Test release APK installation on budget Android devices (Android 10–14).
