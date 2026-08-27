# StockShield

StockShield — Gramik stock audit Flutter app, Dark Store users ke liye physical stock audit.

Yeh app **Gramik backend** ke dedicated Stock Audit API use karti hai (`/mobile/stock-audit/api`) — **sirf Dark Store login**. Web `/mobile/login` unchanged.

## Features

- OTP login (mobile number)
- Business location select
- Store products list with search (product / variant / SKU)
- Per-variant qty input + row Save/Update
- Bulk **Save Stocks**
- Variant menu: **Update Damage Quantity**, **Comment**
- Stock audit detail screen (damage qty + comment)
- 1 hour inactivity auto logout
- Native mobile UI: branded splash, rounded app bar, sticky save bar, bottom nav

## Project structure

```
lib/
├── main.dart
├── app.dart
├── core/           # config, theme, network, storage, utils, shared widgets
├── features/
│   ├── auth/       # login + session
│   └── stock_audit/# home, variant audit, API models
└── routing/        # go_router
```

## Setup

1. Flutter SDK (3.12+)
2. Dependencies:

```bash
cd StockAudit
flutter pub get
```

3. **Backend URL** — default live: `https://lens-api.gramik.in`

Local dev override:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:5000
```

## Run

```bash
flutter run
```

## API endpoints used

| Method | Path |
|--------|------|
| POST | `/mobile/stock-audit/api/login` |
| POST | `/mobile/stock-audit/api/verify-otp` |
| GET | `/mobile/stock-audit/api/business-locations` |
| GET | `/mobile/stock-audit/api/business-locations/:id/products` |
| GET | `/mobile/stock-audit/api/stock-audits/detail` |
| POST | `/mobile/stock-audit/api/stock-audits/bulk` |
| POST | `/mobile/stock-audit/api/stock-audits/comment` |
| POST | `/mobile/stock-audit/api/stock-audits/discrepancy` |
