# CROP+ — Complete Project Documentation

## Table of Contents
1. [Project Overview](#1-project-overview)
2. [Tech Stack](#2-tech-stack)
3. [Project Structure](#3-project-structure)
4. [App Screens & Features](#4-app-screens--features)
5. [Services & Logic](#5-services--logic)
6. [Data Models](#6-data-models)
7. [Formulas & Calculations](#7-formulas--calculations)
8. [Cloud Functions (Backend)](#8-cloud-functions-backend)
9. [Navigation & Routing](#9-navigation--routing)
10. [UI Theme & Design System](#10-ui-theme--design-system)
11. [Packages Used](#11-packages-used)
12. [What Was Changed From Camera to Satellite](#12-what-was-changed-from-camera-to-satellite)
13. [Known Limitations & Next Steps](#13-known-limitations--next-steps)

---

## 1. Project Overview

**CROP+** (Carbon + Nutrition Calculator) is a Flutter mobile/web app built for small farmers in Tamil Nadu, India. It helps farmers:

- Monitor crop health using **Sentinel-2 satellite NDVI data**
- Calculate **biomass, carbon sequestration, and CO₂ equivalent**
- Earn and sell **carbon credits** on the market
- Get **AI-powered fertilizer and farming recommendations**
- Track **live soil sensor data** (N, P, K, pH, EC, moisture)
- View **15-day climate risk forecasts**
- Sell carbon credits to buyers at ₹2,100–₹3,600 per ton

### Core Value
> No camera. No image uploads. Pure satellite-powered intelligence from 600km above earth — every 5 days automatically.

---

## 2. Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile/Web App | Flutter (Dart) — SDK ^3.11.0 |
| Routing | go_router ^17.3.0 |
| Maps | flutter_map ^7.0.2 (OpenStreetMap — free, no API key) |
| Location | geolocator ^13.0.2 |
| Charts | fl_chart ^1.2.0 |
| Fonts | google_fonts (Plus Jakarta Sans) |
| HTTP | http ^1.2.2 |
| Caching | shared_preferences ^2.3.3 |
| Images | cached_network_image ^3.4.1 |
| Backend | Python FastAPI (local/Pi) |
| Cloud Functions | Firebase Cloud Functions (Node.js 20) |
| Satellite Data | Google Earth Engine — Sentinel-2 SR |
| AI Recommendations | Google Gemini 1.5 Flash |
| Database | Firebase Firestore |
| Storage | Firebase Storage |
| Auth | Firebase Auth |

---

## 3. Project Structure

```
Carbon-tech/
├── app/                          # Flutter app
│   ├── lib/
│   │   ├── main.dart             # App entry, router, bottom nav shell
│   │   ├── theme.dart            # Colors, shadows, shared widgets
│   │   ├── models/
│   │   │   └── farmer.dart       # All data models
│   │   ├── screens/
│   │   │   ├── splash_screen.dart
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   ├── dashboard_screen.dart
│   │   │   ├── satellite_analysis_screen.dart  ← NEW (replaced scan)
│   │   │   ├── carbon_report_screen.dart
│   │   │   ├── fertilizer_screen.dart
│   │   │   ├── climate_screen.dart
│   │   │   ├── sell_carbon_screen.dart
│   │   │   ├── reports_screen.dart
│   │   │   ├── sensor_screen.dart
│   │   │   └── profile_screen.dart
│   │   ├── services/
│   │   │   ├── satellite_service.dart   ← NEW
│   │   │   ├── gemini_service.dart      ← NEW
│   │   │   ├── api_service.dart
│   │   │   ├── auth_service.dart
│   │   │   ├── firestore_service.dart
│   │   │   ├── storage_service.dart
│   │   │   └── mock_data.dart
│   │   └── widgets/
│   │       ├── gauge_bar.dart
│   │       └── stat_card.dart
│   └── pubspec.yaml
├── backend/                      # Python FastAPI
│   ├── main.py
│   ├── carbon_engine.py
│   ├── earth_engine_utils.py
│   ├── sensor_reader.py
│   ├── sensor_simulator.py
│   └── requirements.txt
├── functions/                    # Firebase Cloud Functions
│   ├── index.js                  # getNDVI + Firestore triggers
│   └── package.json
└── firebase.json
```

---

## 4. App Screens & Features

### 4.1 Splash Screen (`/`)
- Shows app logo and branding
- Auto-navigates to login after 2–3 seconds

### 4.2 Login Screen (`/login`)
- Email + password login via Firebase Auth
- "Forgot password" flow
- Navigate to register

### 4.3 Register Screen (`/register`)
- New farmer registration
- Name, phone, village, district, farm size, crop type
- Creates Firestore farmer document

### 4.4 Dashboard Screen (`/dashboard`) — HOME
**The main hub of the app. Contains:**

- **Search bar** (top) — tap to search farm data using Flutter's SearchDelegate with suggestions: Carbon Report, NDVI Trend, Soil Moisture, etc.
- **Notification bell** (top right) with badge count — opens bottom sheet with 3 notifications (carbon credits ready, soil moisture alert, rain forecast)
- **Sensor button** — quick link to /sensors
- **Hero banner** — shows crop health score, earned amount, carbon credits, "Sell →" button, background farming photo
- **Category tiles** — 6 quick-action icons: Satellite, Sensors, Fertilizer, Climate, Carbon, Reports
- **Farm Insights** horizontal scroll cards — Carbon Report, Fertilizer Plan, Climate Risk with images
- **Alerts section** — dismissible alert cards (Nitrogen deficiency, Heat wave warning)
- **Live Soil Data** — 4 boxes showing N (ppm), pH, EC (mS), H₂O (moisture %)
- **NDVI Trend chart** — 7-point line chart with gradient fill
- **AI Tip of the Day** card — green gradient with daily recommendation

### 4.5 Satellite Analysis Screen (`/scan`) — CORE FEATURE
**Replaces old camera scan. Full satellite-based crop analysis.**

#### Input View:
- **Interactive OpenStreetMap** — tap anywhere to drop a green farm pin
- **Live location FAB** (bottom-right blue button) — requests GPS, flies map to user's real location
- **Coordinates pill** (bottom-left) — shows lat/lng updating in real time as you tap
- **"Tap map to select farm location"** hint banner at top
- **Date range picker** — "From" and "To" date buttons (default: last 30 days)
- **Crop dropdown** — Rice, Wheat, Maize, Cotton, Sugarcane, Soybean
- **Stage dropdown** — Vegetative, Reproductive, Maturity
- **"Fetch Satellite Data" button** — triggers the full analysis pipeline

#### Loading States (shown over map):
1. "Fetching Sentinel-2 data…"
2. "Running AI analysis…"

#### Result View (after fetch):
1. **Mini map** (frozen, 160px) showing selected farm pin
2. **Health score ring** (0–100) — color-coded green/amber/red
3. **Status badge** — Healthy / Moderate / Stressed
4. **Last satellite pass date** + source badge (SATELLITE / CACHED / DEMO)
5. **Crop & stage header** with coordinates
6. **Satellite Metrics grid** (2×2):
   - NDVI (0–1 scale, green)
   - Biomass (tons/ha, blue)
   - Carbon (tons C/ha, green)
   - CO₂e (tons/ha, gold)
7. **Carbon Credits box** — credits (tons CO₂e) + farmer payout (90% at ₹2,100/ton)
8. **NDVI Trend chart** — 30-day line chart
9. **AI Recommendations** — 5 items (Fertilizer, Irrigation, Pest Management, Harvest Planning, Carbon Credits)
10. **Action buttons** — "New Analysis" | "Sell Credits"

### 4.6 Carbon Report Screen (`/carbon`)
- Hero farming image
- Summary: total carbon (tons C/ha), CO₂e, stability %
- Carbon Credits card — baseline vs current vs additional carbon, best rate, potential earnings
- 5-year carbon trend line chart (2022–2026)
- Carbon stability bars (permanence %, microbial health %)
- Environmental impact — cars off road equivalent, trees planted equivalent
- Bottom "Sell Carbon Credits" button

### 4.7 Fertilizer Screen (`/fertilizer`)
- N, P, K deficiency analysis from soil sensor data
- Specific fertilizer product recommendations (Urea, DAP, MOP)
- Kg/ha quantities with split application schedule
- Cost calculation and savings vs traditional methods

### 4.8 Climate Screen (`/climate`)
- 15-day forecast from mock weather data
- Temperature, rainfall, soil moisture per day
- Risk level per day: Low / Med / High
- Drought risk %, flood risk %, heat stress % indicators
- Alert cards for upcoming weather events

### 4.9 Sell Carbon Screen (`/sell`)
- 3 market buyer options:
  - Government Market (CCTS) — ₹2,100/credit, 3–5 days
  - International Buyer (Microsoft) — ₹2,850/credit, 7–10 days (BEST PRICE)
  - Premium Buyer (Agroforestry) — ₹3,600/credit, 5–7 days (HIGHEST PRICE)
- Farmer gets 90% of proceeds
- "Sell Now" button per buyer
- Payment calculation shown

### 4.10 Reports Screen (`/reports`)
- Historical analysis reports list
- Carbon trend charts
- Export / share options

### 4.11 Sensor Screen (`/sensors`)
- Live soil sensor readings from hardware (Pi)
- N, P, K, pH, EC, moisture, temperature gauges
- Falls back to simulated data when no hardware connected
- Last reading timestamp

### 4.12 Profile Screen (`/profile`)
- Farmer details — name, phone, village, district
- Farm info — size (ha), crop types, soil type
- App settings — language, notifications
- Logout

---

## 5. Services & Logic

### 5.1 `satellite_service.dart`

**Purpose:** Fetches real NDVI from Google Earth Engine via Cloud Function, calculates all derived values, and caches results.

**Flow:**
```
User taps "Fetch Satellite Data"
  → HTTP GET to Cloud Function /getNDVI
  → Receives NDVI value + satellite date
  → Calculates: Biomass, Carbon, CO₂e, Health Score, Credits, Payout
  → Caches result in SharedPreferences (24hr TTL)
  → If network fails → loads cache
  → If cache expired/empty → returns mock data (NDVI = 0.68)
```

**Key constants:**
- Functions base URL: `https://us-central1-carbon-tech-67a3d.cloudfunctions.net`
- Cache TTL: 24 hours
- Baseline carbon: 45.0 tons C/ha
- Market price: ₹2,100/ton
- Farmer share: 90%

### 5.2 `gemini_service.dart`

**Purpose:** Sends farm + NDVI data to Google Gemini 1.5 Flash and gets 5 structured recommendations.

**Flow:**
```
Receives: crop, stage, NDVI, biomass, carbon, soil N/P/K, district, weather
  → If API key is empty → returns fallback recommendations immediately
  → Else → POST to Gemini API with structured prompt
  → Parses JSON response into 5 categories
  → If Gemini fails → falls back to rule-based recommendations
```

**Fallback rules (when no API key):**
- NDVI < 0.4 → apply 120kg Urea + 60kg DAP
- NDVI < 0.5 → increase irrigation
- NDVI > 0.65 → harvest in 15–20 days
- Else → harvest in 45–60 days

### 5.3 `api_service.dart`

**Purpose:** Communicates with the Python FastAPI backend (Raspberry Pi or localhost).

**Endpoints used:**
- `GET /sensor/latest/{farmId}` — latest hardware sensor reading
- `POST /sensor/reading` — post sensor data from hardware
- `POST /fertilizer` — get fertilizer recommendation

**Fallback:** Returns mock data from `MockData.analysis` when backend is unreachable.

### 5.4 `mock_data.dart`

**Purpose:** Provides demo data so the app works without any real backend/hardware.

**Contains:**
- Farmer: Ramesh Kumar, Tanjavur, Tamil Nadu
- Farm: Rice Farm, 1.0 ha, GeoPoint(10.7867, 79.1378)
- Soil: N=45, P=22, K=118, pH=6.2, EC=1.1, moisture=28%
- Carbon: biomass=3.1, totalCarbon=59.3, CO₂e=217.7
- NDVI history: [0.31, 0.38, 0.45, 0.52, 0.58, 0.63, 0.68]
- 5-year carbon history: 45.0 → 59.3 tons C/ha
- Carbon credits: 1 eligible (12.4t), 1 sold (8.2t at ₹17,220)
- 15-day forecast with temp, rain, moisture, risk level
- 3 market buyer offers

---

## 6. Data Models (`models/farmer.dart`)

| Model | Key Fields |
|-------|-----------|
| `Farmer` | id, name, phone, village, district, farmSize, crops, joinDate |
| `Farm` | id, farmerId, name, location (GeoPoint), area, soilType, crops |
| `GeoPoint` | latitude, longitude |
| `SoilReading` | n, p, k, ph, ec, moisture, temperature |
| `CarbonReading` | biomass, totalCarbon, co2Equivalent |
| `Analysis` | id, farmId, cropType, growthStage, gpr, healthScore, soil, carbon, ndvi, recommendations |
| `CarbonCredit` | id, farmerId, farmId, amount, status, salePrice, soldDate, paymentId |
| `ClimateAlert` | id, farmId, type, severity, riskPercentage, recommendation |
| `Payment` | id, creditId, farmerId, amount, paymentId, status |
| `SatelliteResult` | ndvi, biomass, carbon, co2e, healthScore, carbonCredits, farmerPayment, satelliteDate, source |

---

## 7. Formulas & Calculations

### NDVI → Biomass
```
Biomass (tons/ha) = (3.05 × NDVI) − 0.35
Example: NDVI=0.68 → (3.05 × 0.68) − 0.35 = 1.724 tons/ha
Clamped to minimum 0.0
```

### Biomass → Carbon
```
Carbon (tons C/ha) = Biomass × 0.45
Example: 1.724 × 0.45 = 0.776 tons C/ha
(0.45 = IPCC standard carbon fraction for plant biomass)
```

### Carbon → CO₂ Equivalent
```
CO₂e (tons/ha) = Carbon × 3.67
Example: 0.776 × 3.67 = 2.848 tons CO₂e/ha
(3.67 = molecular weight ratio CO₂/C = 44/12)
```

### NDVI → Health Score
```
Health Score (0–100) = NDVI × 100
Example: NDVI=0.68 → Score=68
> 70 = Healthy (green)
40–70 = Moderate (amber)
< 40 = Stressed (red)
```

### Carbon Credits Calculation
```
Additional Carbon = Current Carbon − Baseline Carbon
Example: 59.3 − 45.0 = 14.3 tons C/ha

Carbon Credits = Additional Carbon × 3.67
Example: 14.3 × 3.67 = 52.5 credits (1 credit = 1 ton CO₂e)

Farmer Payment = Credits × ₹2,100 × 90%
Example: 52.5 × 2,100 × 0.90 = ₹99,225
```

### Nitrogen Recommendation
```
N Demand = Target Yield × N per ton crop
  Rice: 5 tons/ha × 16 kg N/ton = 80 kg N/ha

N Supply = Soil N (ppm) × 2
  45 ppm × 2 = 90 kg N/ha

N Deficit = Demand − Supply (if negative = sufficient)
  80 − 90 = 0 (no deficit in this example)

If deficiency detected:
  Urea Required = (N Deficit / NUE) / 0.46
  NUE = 0.5 (Nitrogen Use Efficiency)
  Urea = 46% nitrogen content
```

### NDVI-Based Fertilizer Table
```
NDVI 0.8–1.0  → 0–25 kg N/ha    | Excellent
NDVI 0.6–0.8  → 25–50 kg N/ha   | Good
NDVI 0.4–0.6  → 50–75 kg N/ha   | Moderate
NDVI 0.2–0.4  → 75–100 kg N/ha  | Poor
NDVI < 0.2    → 100–125 kg N/ha | Critical
```

### Climate Risk
```
Drought Risk Index (DRI):
  DRI = ((SM_critical − SM_current) / SM_critical) × (1 − RF_forecast/RF_required)

Heat Stress Index (HSI):
  HSI = ((T_max − T_optimal) / (T_critical − T_optimal)) × (Days_exposed / 7)

Overall Climate Risk Score (CRS):
  CRS = (0.4×DRI + 0.2×FRI + 0.4×HSI) × 100
```

---

## 8. Cloud Functions (Backend)

### `getNDVI` (NEW)
```
Endpoint: GET /getNDVI
Params: lat, lng, radius (meters), startDate, endDate

Flow:
1. Authenticates with Google Earth Engine via service account
2. Loads COPERNICUS/S2_SR (Sentinel-2 Surface Reflectance)
3. Filters by: location buffer, date range, cloud cover < 20%
4. Calculates NDVI = (B8 − B4) / (B8 + B4)
5. Takes median across date range
6. Reduces to mean NDVI for the buffered region (scale=10m)
7. Returns: { ndvi, date, lat, lng }
8. On error: returns fallback { ndvi: 0.62 }
```

### `healthCheck`
```
GET /healthCheck
Returns: { status: "ok", timestamp: "..." }
```

### `onFarmerCreate` (Firestore trigger)
```
Trigger: New document in farmers/{userId}
Action: Logs new farmer registration
```

### `onAnalysisCreate` (Firestore trigger)
```
Trigger: New document in analyses/{analysisId}
Action: Auto-creates carbon credit record if CO₂e > 0.5 tons
Fields created: farmerId, farmId, amount, status="eligible"
```

### `onCreditSold` (Firestore trigger)
```
Trigger: carbon_credits/{creditId} status changes to "sold"
Action: Creates payment record in payments collection
Fields: creditId, farmerId, amount, paymentId, status="processing"
```

### `expireOldCredits` (Scheduled — daily)
```
Trigger: Every 24 hours
Action: Marks credits older than 365 days as "expired"
```

---

## 9. Navigation & Routing

### Routes
```
/            → SplashScreen
/login       → LoginScreen
/register    → RegisterScreen
/dashboard   → DashboardScreen    (Home tab)
/scan        → SatelliteAnalysisScreen  (Satellite tab)
/carbon      → CarbonReportScreen  (Carbon tab)
/reports     → ReportsScreen       (Reports tab)
/profile     → ProfileScreen       (Profile tab)
/fertilizer  → FertilizerScreen
/climate     → ClimateScreen
/sell        → SellCarbonScreen
/sensors     → SensorScreen
```

### Bottom Navigation Tabs
```
Tab 1: Home      → /dashboard  (home icon)
Tab 2: Satellite → /scan       (satellite_alt icon)  ← was "Crop" camera
Tab 3: Carbon    → /carbon     (eco icon)
Tab 4: Reports   → /reports    (bar_chart icon)
Tab 5: Profile   → /profile    (person icon)
```

---

## 10. UI Theme & Design System

### Color Palette
```dart
kPrimary      = #1B6B3A  (Dark green — brand color)
kPrimaryLight = #E8F5ED  (Light green tint)
kPrimaryMid   = #2E9E58  (Medium green)
kAccentGold   = #F59E0B  (Amber/gold — warnings)
kAccentBlue   = #2563EB  (Blue — sensors/water)
kAccentRed    = #EF4444  (Red — alerts/errors)
kBgWhite      = #FFFFFF
kBgPage       = #F5F6F9  (Light grey page bg)
kBgCard       = #F5F6F9
kTextDark     = #212121
kTextMid      = #616161
kTextGrey     = #9E9E9E
```

### Typography
All text uses **Plus Jakarta Sans** via google_fonts.

### Shared Widgets (in `theme.dart`)
| Widget | Purpose |
|--------|---------|
| `TopRoundedContainer` | White rounded top card (like e-commerce detail screens) |
| `SectionTitle` | Section header with "See All" trailing |
| `StatusBadge` | Colored pill badge (Healthy, ELIGIBLE, CACHED, etc.) |
| `IconBtnWithCounter` | Circle icon button with red notification badge |
| `ProfileMenuRow` | Profile menu item with arrow |
| `GlassCard` | White rounded card with shadow/glow |
| `LabelDivider` | Divider with center text label |
| `SectionLabel` | Section header with optional trailing action |

### Shadows
```dart
kShadowSm = BoxShadow(blur: 8,  offset: (0,2))
kShadowMd = BoxShadow(blur: 16, offset: (0,4)) + BoxShadow(blur: 4, offset: (0,1))
kGlowGreen = BoxShadow(color: green@30%, blur: 20, offset: (0,6))
```

---

## 11. Packages Used

| Package | Version | Purpose |
|---------|---------|---------|
| flutter | SDK | Framework |
| go_router | ^17.3.0 | Declarative routing |
| flutter_map | ^7.0.2 | OpenStreetMap interactive map |
| latlong2 | ^0.9.1 | Lat/Lng coordinates for flutter_map |
| geolocator | ^13.0.2 | Device GPS / live location |
| fl_chart | ^1.2.0 | Line charts, bar charts |
| google_fonts | ^6.2.1 | Plus Jakarta Sans font |
| http | ^1.2.2 | HTTP calls to backend/Cloud Functions/Gemini |
| shared_preferences | ^2.3.3 | Local caching of satellite results |
| cached_network_image | ^3.4.1 | Cached image loading |
| intl | ^0.20.2 | Date formatting |
| percent_indicator | ^4.2.5 | Progress/percentage indicators |
| cupertino_icons | ^1.0.8 | iOS-style icons |

**Removed packages:**
- `image_picker` — removed (no camera functionality)

---

## 12. What Was Changed From Camera to Satellite

| Feature | Before (Camera-Based) | After (Satellite-Based) |
|---------|----------------------|------------------------|
| Input method | Camera capture / Gallery | Tap on OpenStreetMap |
| Location input | None | Interactive map + live GPS |
| Analysis source | GPR (Green Pixel Ratio) | NDVI from Sentinel-2 |
| Health metric | GPR % (0–100%) | NDVI (0.0–1.0) → Score (0–100) |
| Carbon data | Basic estimate | Biomass → Carbon → CO₂e chain |
| Permissions | Camera, storage | Location only |
| Offline | Cache image | Cache NDVI result (24hr) |
| Nav tab icon | Camera icon "Crop" | Satellite icon "Satellite" |
| Screen name | scan_screen.dart | satellite_analysis_screen.dart |
| Dependencies | image_picker | flutter_map, latlong2, geolocator, shared_preferences |
| Result display | GPR bar, deficiency bars | 4-metric grid + credit box |
| Recommendation source | Rule-based only | Gemini AI (with smart fallback) |

---

## 13. Known Limitations & Next Steps

### Current Limitations
1. **Gemini API key** not configured — using smart fallback recommendations
2. **Earth Engine** Cloud Function deployed but needs GCP service account with Earth Engine access enabled
3. **Soil sensors** (N, P, K, pH) use mock data — real hardware (Raspberry Pi) not yet connected in demo
4. **Satellite data** falls back to mock NDVI=0.68 if Cloud Function is unreachable
5. **UPI payments** — sell flow is UI-only, actual payment processing not integrated
6. **No authentication** enforced — app goes to dashboard directly in demo mode

### To Make Production-Ready
1. Replace `_kGeminiKey = ''` in `gemini_service.dart` with real `AIzaSy...` key
2. Deploy Cloud Functions: `cd functions && npm install && firebase deploy --only functions`
3. Enable Earth Engine API in Google Cloud Console for project `carbon-tech-67a3d`
4. Connect real soil sensor hardware to FastAPI backend
5. Enable Firebase Auth and enforce login before dashboard
6. Add Razorpay/UPI SDK for actual payment processing
7. Set up Firestore security rules
8. Add Tamil language localization strings

---

*Documentation generated for CROP+ v1.0.0 — Carbon-tech project*
*Firebase Project: carbon-tech-67a3d*
*Flutter SDK: ^3.11.0 | Node.js: 20 | Python: 3.10+*
