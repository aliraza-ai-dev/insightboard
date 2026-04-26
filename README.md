# InsightBoard — AI-Powered Business Dashboard App

# 📊 InsightBoard — AI-Powered Business Dashboard App

![Flutter](https://img.shields.io/badge/Flutter-3.41-blue?logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-Enabled-orange?logo=firebase)
![AI](https://img.shields.io/badge/Claude%20AI-Powered-purple)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green)
![License](https://img.shields.io/badge/License-MIT-lightgrey)

## Overview
InsightBoard is a complete Flutter + Firebase business intelligence app with AI-powered data analysis, interactive charts, team collaboration, and automated reporting.

## Features (16 Complete)

### 1. CSV/Excel File Upload → Auto-Generate Charts
- Upload `.csv`, `.xlsx`, `.xls` files via file picker
- Auto-parse columns, detect types (numeric, text, date)
- AI suggests optimal chart types based on data structure

### 2. AI Data Analysis (Natural Language)
- Ask questions in plain English about your data
- Powered by Anthropic Claude API
- Fallback local analysis when API unavailable
- Suggested queries for quick insights

### 3. AI Report Generator (PDF Export)
- Auto-generates comprehensive business reports
- Cover page, KPI summary, AI analysis, data tables
- Professional PDF layout with branding
- Uses `pdf` + `printing` packages

### 4. Interactive Charts (Bar, Line, Pie, Heatmap)
- Built with `fl_chart` library
- Bar, Line, Pie, Scatter, Area, Heatmap charts
- Touch tooltips, legends, responsive sizing
- Multi-series support

### 5. Real-Time Dashboard with KPI Cards
- Live KPI cards with change indicators
- Revenue, Users, Conversion Rate, Avg Order Value
- Color-coded trend arrows

### 6. AI Predictions/Forecasting
- Exponential smoothing + linear trend model
- Confidence score based on data variance
- Visual forecast chart with historical vs predicted
- AI-generated forecast insights

### 7. Team Collaboration
- Invite members via email
- Roles: Owner, Admin, Editor, Viewer
- Accept/decline invitations
- Member management (change role, remove)

### 8. Scheduled Reports (Daily/Weekly/Monthly)
- Configure report schedule in Report Generator
- Email delivery configuration
- Report history with download/share

### 9. Data Source Connectors
- Google Sheets (URL/ID input)
- REST API (GET/POST, auth headers)
- Database connectors (PostgreSQL, MySQL, MongoDB)
- Visual connector cards with forms

### 10. Custom Dashboard Builder (Drag & Drop)
- Widget palette: KPI, Bar, Line, Pie, Heatmap, Scatter, Area, Text, AI Insight
- Drag-to-reorder widgets
- Per-widget configuration (title, data source)
- Save/load custom layouts

### 11. Export to PDF/PNG/CSV
- PDF: Full report with cover page and charts
- Export format selector in Report Generator
- Share via system share sheet

### 12. Push Notifications for Anomaly Alerts
- Local notifications via `flutter_local_notifications`
- Channels: Anomaly Alerts, Reports, Team, Scheduled
- Severity-based priority (critical → max)

### 13. Multi-Workspace Support
- Create multiple workspaces
- Workspace switcher in app bar
- Each workspace has own datasets, charts, members
- Emoji icons for workspaces

### 14. Admin Panel
- Usage stats (datasets, charts, reports, AI queries, storage)
- Storage usage progress bar
- Billing management (Pro Plan display)
- Danger zone (workspace deletion)

### 15. Dark/Light Theme
- Full Material 3 theming
- Indigo primary + Cyan secondary
- Catppuccin-inspired dark theme
- Toggle in Settings

### 16. Onboarding with Sample Data
- 4-page onboarding flow
- Feature highlights with icons
- Load sample sales or analytics data
- Skip option

---

## Project Structure

```
lib/
├── main.dart                          # App entry point
├── theme.dart                         # Light/Dark themes
├── models/
│   └── all_models.dart                # All data models (User, Workspace, Dataset,
│                                        Chart, KPI, Dashboard, Report, Anomaly, Invitation)
├── services/
│   ├── auth_service.dart              # Firebase Auth
│   ├── data_service.dart              # CSV/Excel parsing, data aggregation, sample data
│   ├── ai_service.dart                # AI analysis, forecasting, anomaly detection,
│   │                                    chart suggestions
│   ├── workspace_service.dart         # Workspace CRUD, team, dashboards, charts, KPIs
│   ├── report_pdf_service.dart        # PDF report generation
│   └── notification_service.dart      # Push/local notifications
├── providers/
│   └── app_provider.dart              # Central state management (ChangeNotifier)
├── screens/
│   ├── auth_screen.dart               # Login / Signup with tabs
│   ├── main_shell.dart                # Bottom nav + workspace switcher + notifications
│   ├── onboarding/
│   │   └── onboarding_screen.dart     # 4-page onboarding
│   ├── dashboard/
│   │   ├── dashboard_screen.dart      # Main dashboard (KPIs, charts, AI insights,
│   │   │                                anomalies, heatmap)
│   │   └── dashboard_builder_screen.dart  # Drag-drop custom dashboard builder
│   ├── upload/
│   │   └── upload_screen.dart         # File upload + data connectors + preview + suggestions
│   ├── analysis/
│   │   └── ai_analysis_screen.dart    # AI chat, forecasting, anomaly detection (3 tabs)
│   ├── reports/
│   │   └── reports_screen.dart        # Report generator + schedule + history
│   └── settings/
│       └── settings_screen.dart       # Profile, theme, team, admin, API config
└── widgets/
    └── charts/
        └── chart_widgets.dart         # Reusable chart components (bar, line, pie, forecast)
```

---

## Setup Instructions

### 1. Create Flutter Project
```bash
flutter create insightboard
cd insightboard
```

### 2. Replace Files
Copy all files from this package into your Flutter project, replacing the default `lib/` folder and `pubspec.yaml`.

### 3. Firebase Setup
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create new project: `insightboard`
3. Add Android app (package: `com.example.insightboard`)
4. Add iOS app
5. Download and place config files:
   - `google-services.json` → `android/app/`
   - `GoogleService-Info.plist` → `ios/Runner/`
6. Run `flutterfire configure` (recommended)

### 4. Enable Firebase Services
In Firebase Console, enable:
- **Authentication** → Email/Password
- **Cloud Firestore** → Create database (start in test mode)
- **Firebase Storage** → Enable

### 5. Firestore Security Rules (Development)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 6. AI Configuration
Replace `YOUR_ANTHROPIC_API_KEY` in `lib/services/ai_service.dart` with your actual Anthropic API key. Or configure it through Settings → API Configuration in the app.

### 7. Install Dependencies & Run
```bash
flutter pub get
flutter run
```

---

## Firestore Collections

| Collection | Purpose |
|---|---|
| `users` | User profiles and preferences |
| `workspaces` | Workspace config, members, roles |
| `workspaces/{id}/charts` | Chart configurations |
| `workspaces/{id}/kpis` | KPI card configurations |
| `datasets` | Dataset metadata |
| `datasets/{id}/data` | Data rows in chunks |
| `dashboards` | Custom dashboard layouts |
| `reports` | Report metadata and schedules |
| `anomalies` | Detected anomaly alerts |
| `invitations` | Team invitations |

---

## Key Dependencies

| Package | Purpose |
|---|---|
| `firebase_core/auth/firestore/storage` | Backend |
| `provider` | State management |
| `fl_chart` | Interactive charts |
| `csv` + `excel` | File parsing |
| `pdf` + `printing` | Report generation |
| `file_picker` | File upload |
| `google_fonts` | Typography |
| `flutter_local_notifications` | Push notifications |
| `http` | AI API calls |
| `uuid` | Unique IDs |
| `intl` | Date formatting |

---

## Customization

### Theme Colors
Edit `lib/theme.dart` → `AppColors` class:
```dart
static const primary = Color(0xFF6366F1);    // Change primary color
static const secondary = Color(0xFF06B6D4);  // Change secondary color
```

### AI Model
Edit `lib/services/ai_service.dart`:
```dart
'model': 'claude-sonnet-4-20250514',  // Change model
```

### Sample Data
Edit `lib/services/data_service.dart`:
- `generateSampleSalesData()` — Sales data
- `generateSampleWebAnalytics()` — Web analytics data

---

## Notes
- All `withOpacity()` calls use `withValues(alpha:)` for Flutter 3.x compatibility
- Local anomaly detection uses z-score (>2σ threshold)
- Forecasting uses exponential smoothing + linear regression
- PDF reports support up to 50 rows per table (configurable)
- Firebase Storage used for dataset file backups
- Data rows stored in Firestore chunks of 200 rows


## 👨‍💻 Developer
Built by **Ali Raza** — Flutter Developer
- GitHub: [@aliraza-ai-dev](https://github.com/aliraza-ai-dev)
- Available for freelance Flutter projects

## ⭐ Support
If you find this useful, please give it a star!
