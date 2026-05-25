# Product Management (Flutter Web + Firestore)

Production-ready Flutter Web application for managing products with full CRUD operations backed by **Cloud Firestore**.

## Links

- **Live app:** https://syedaliraza102.github.io/fluter/
- **Repository:** https://github.com/syedaliraza102/fluter
- **Deploy status:** https://github.com/syedaliraza102/fluter/actions

## Features

- Add, view, edit, and delete products
- Real-time product list via `StreamBuilder`
- Search products by name
- Form validation (required name, numeric price/stock)
- Loading, empty, and error states
- Firebase error handling with user-facing messages

## Project structure

```
lib/
├── main.dart              # Firebase init & app entry
├── home_page.dart         # UI, dialogs, StreamBuilder list
├── product_service.dart   # Firestore CRUD
├── firebase_options.dart  # Firebase config (replace placeholders)
└── models/
    └── product.dart       # Product model & Firestore mapping
```

## Firestore schema

**Collection:** `products`

| Field       | Type      | Required |
|-------------|-----------|----------|
| name        | string    | yes      |
| description | string    | yes      |
| price       | number    | yes      |
| stock       | number    | yes      |
| imageUrl    | string    | no       |
| createdAt   | timestamp | no (set on create) |

## Setup

### 1. Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.2+)
- A [Firebase](https://console.firebase.google.com/) project

### 2. Enable Firestore

1. Open Firebase Console → your project → **Build** → **Firestore Database**
2. Create database (start in **test mode** for development, then apply rules below)
3. Enable **Web** app in Project settings and copy config values

### 3. Configure Firebase in Flutter

**Option A — FlutterFire CLI (recommended):**

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This regenerates `lib/firebase_options.dart` with your project credentials.

**Option B — Manual:** Edit `lib/firebase_options.dart` and replace `YOUR_*` placeholders with values from Firebase Console → Project settings → Your apps → Web app.

### 4. Firestore security rules (development)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /products/{productId} {
      allow read, write: if true; // Restrict in production (e.g. require auth)
    }
  }
}
```

For production, require authentication and scope writes to authenticated users.

### 5. Install dependencies & run

```bash
cd e:\astapor\fluter
flutter pub get
flutter run -d chrome
```

Build for production:

```bash
flutter build web
```

Output is in `build/web/`.

## Testing

Unit tests use `fake_cloud_firestore`:

```bash
flutter test
```

## Architecture notes

- **product_service.dart** — All Firestore access; UI never calls Firestore directly
- **home_page.dart** — Presentation only; injectable `ProductService` for tests
- **async/await** with **try/catch** for Firebase operations
- Real-time updates via `watchProducts()` stream and `StreamBuilder`
