# Vegora — Freshness at Your Doorstep 🥦🥕

[![Flutter Quality Gate](https://github.com/Dhatchanamoorthi8/Fresh_Veg/actions/workflows/android_release.yml/badge.svg)](https://github.com/Dhatchanamoorthi8/Fresh_Veg/actions)

**Vegora** is a high-performance, multi-branch fresh vegetable shopping and hyper-local delivery mobile application built with Flutter and Supabase.

---

## 🌿 Brand Identity

* **Official Brand Name:** Vegora
* **Official Tagline:** *Freshness at Your Doorstep.*
* **Brand Aesthetics & Color Palette:**
  * **Primary Forest Green:** `#0B6B3A` — Symbolizes natural freshness and organic agriculture.
  * **Fresh Accent Green:** `#4CAF50` — Highlights availability, health, and fresh harvests.
  * **Vibrant Carrot Orange:** `#FF8A00` — Accents sales, discounts, cart actions, and notifications.
  * **Soft Mint Background:** `#E8F5E9` — Clean, light, and accessible reading experience.
  * **Deep Charcoal Text:** `#263238` — Optimal readability and contrast.

---

## 🚀 Key Capabilities

### 1. Customer Shopping Experience
* **Live Multi-Branch Catalog:** Browse fresh vegetables, leafy greens, root vegetables, and exotic produce.
* **Instant Cart & Checkout:** Real-time price calculation, branch-level stock verification, and instant order placement.
* **Dual Authentication:** Secure Email/Password registration and seamless Google Sign-In powered by Supabase Auth.
* **Order Tracking:** Live order statuses from packing to dispatch and doorstep delivery.

### 2. Comprehensive Administrator Hub
* **Multi-Branch Operations:** Real-time branch creation, manager assignments, geofenced delivery zones, and contact configuration.
* **Produce & Catalog Management:** Add new vegetables, categories, units (`kg`, `g`, `bunch`), and images.
* **Dynamic Branch Inventory:** Manage per-branch stock levels, low-stock alerts, and restocking logs.
* **Branch-Specific Pricing:** Set localized rates and flash discounts per region.
* **Role-Based Access Control (RBAC):** Dedicated permissions for `SuperAdmin`, `BranchStaff`, and `DeliveryAgent`.

### 3. Dedicated Staff & Delivery Portals
* **Branch Staff Portal:** In-store order staging, packing workflows, and stock verification.
* **Delivery Agent Hub:** Route optimization, delivery assignment acceptance, and doorstep handoff confirmation.

---

## 📁 Project Architecture

```
lib/
├── app/
│   ├── app.dart                   # VegoraApp root widget & theme definitions
│   └── routes.dart                # GoRouter routing rules & RBAC route guards
├── core/
│   ├── constants/
│   │   ├── app_colors.dart        # Vegora official brand tokens
│   │   └── app_theme.dart         # Material 3 theme typography and component styles
│   └── services/                  # Global utilities & preferences
├── features/
│   ├── admin/                     # Admin command hub & management modules
│   ├── auth/                      # Customer, Admin, Staff, Delivery authentication
│   ├── cart/                      # Shopping basket & checkout workflows
│   ├── home/                      # Customer discovery & product listings
│   ├── orders/                    # Order placement & fulfillment tracking
│   └── splash/                    # Vegora branded splash screen
└── shared/
    ├── models/                    # Produce, Branch, Order, and User models
    └── repositories/              # Supabase database & auth client integrations
```

---

## 🛠️ Getting Started

### Prerequisites
* Flutter SDK (3.24+ recommended)
* Dart SDK (3.5+ recommended)
* Supabase Account & Project

### Setup Environment
1. Clone the repository:
   ```bash
   git clone https://github.com/Dhatchanamoorthi8/Fresh_Veg.git
   cd Fresh_Veg
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure Supabase credentials in your environment or `supabase_config.dart`.

4. Run the application:
   ```bash
   flutter run
   ```

### Quality Assurance & Tests
Execute the comprehensive test suite:
```bash
dart format lib test
flutter analyze
flutter test
```

---

## 📦 Building Android Release APK
To build the signed release APK with Vegora branding and launcher icons:
```bash
flutter build apk --release
```
Artifacts are automatically built and published via GitHub Actions on every push to `main`.
