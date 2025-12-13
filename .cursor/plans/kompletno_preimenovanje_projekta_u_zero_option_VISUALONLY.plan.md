# Kompletno Preimenovanje Projekta: Kinetix → Zero Option

## Pregled

Ovaj plan pokriva potpuno preimenovanje Flutter projekta sa "Kinetix" na "Zero Option", uključujući sve aspekte - od Dart koda, preko platform konfiguracija, do workspace foldera.

---

## 1. DART KOD I KONSTANTE

### 1.1 Main App Klasa

**Fajl:** [lib/main.dart](lib/main.dart)

- Linija 14: `KinetixApp()` → `ZeroOptionApp()`
- Linija 19: `class KinetixApp` → `class ZeroOptionApp`
- Linija 20: `const KinetixApp` → `const ZeroOptionApp`
- Linija 29: `title: 'Kinetix'` → `title: 'Zero Option'`

### 1.2 App Constants

**Fajl:** [lib/core/constants/app_constants.dart](lib/core/constants/app_constants.dart)

- Linija 3: `appName = 'Kinetix'` → `'Zero Option'`

### 1.3 UI Tekstovi

**Fajl:** [lib/presentation/pages/login_page.dart](lib/presentation/pages/login_page.dart)

- Linija 98: `'KINETIX'` → `'ZERO OPTION'`

**Fajl:** [lib/presentation/widgets/modals/about_dialog.dart](lib/presentation/widgets/modals/about_dialog.dart)

- Linija 31: `'About Kinetix'` → `'About Zero Option'`
- Linija 55: `'Kinetix - Your personal fitness companion'` → `'Zero Option - Your personal fitness companion'`

**Fajl:** [lib/presentation/pages/admin_dashboard/widgets/admin_header.dart](lib/presentation/pages/admin_dashboard/widgets/admin_header.dart)

- Linija 38: `'Kinetix'` → `'Zero Option'`

**Fajl:** [lib/presentation/pages/onboarding_page.dart](lib/presentation/pages/onboarding_page.dart)

- Linija 24: `'Welcome to Kinetix'` → `'Welcome to Zero Option'`

### 1.4 Interni Identifikatori

**Fajl:** [lib/services/background_sync_service.dart](lib/services/background_sync_service.dart)

- Linija 10: `'kinetix_sync_task'` → `'zero_option_sync_task'`
- Linija 11: `'kinetix_sync_oneoff'` → `'zero_option_sync_oneoff'`

**Fajl:** [lib/core/utils/image_cache_manager.dart](lib/core/utils/image_cache_manager.dart)

- Linija 16: `'kinetix_image_cache'` → `'zero_option_image_cache'`

**Fajl:** [lib/presentation/pages/settings/services/settings_export_service.dart](lib/presentation/pages/settings/services/settings_export_service.dart)

- Linija 25: `'kinetix_workouts_...'` → `'zero_option_workouts_...'`
- Linija 52: `'kinetix_workouts_...'` → `'zero_option_workouts_...'`

### 1.5 Import Aliasi (Opciono)

**Fajlovi:**

- [lib/presentation/pages/dashboard_page.dart](lib/presentation/pages/dashboard_page.dart) (linija 9, 171)
- [lib/presentation/pages/workout_history_page.dart](lib/presentation/pages/workout_history_page.dart) (linija 12, 202)
- [lib/presentation/pages/admin_dashboard/widgets/user_management_card.dart](lib/presentation/pages/admin_dashboard/widgets/user_management_card.dart) (linija 8, 66)
- **Napomena:** `kinetix_search` je samo alias - može ostati ili promeniti u `zeroOptionSearch` za konzistentnost

---

## 2. PACKAGE NAME (pubspec.yaml)

**Fajl:** [pubspec.yaml](pubspec.yaml)

- Linija 1: `name: kinetix_mobile` → `name: zero_option_mobile`
- Linija 2: `description: "Kinetix - Offline-First..."` → `"Zero Option - Offline-First..."`

**⚠️ VAŽNO:** Nakon promene package name-a, mora se pokrenuti:

```bash
flutter clean
flutter pub get
```

---

## 3. ANDROID KONFIGURACIJA

### 3.1 Build Gradle

**Fajl:** [android/app/build.gradle.kts](android/app/build.gradle.kts)

- Linija 9: `namespace = "com.kinetix.kinetix_mobile"` → `"com.zerooption.zero_option_mobile"`
- Linija 24: `applicationId = "com.kinetix.kinetix_mobile"` → `"com.zerooption.zero_option_mobile"`

### 3.2 AndroidManifest.xml

**Fajl:** [android/app/src/main/AndroidManifest.xml](android/app/src/main/AndroidManifest.xml)

- Linija 3: `android:label="kinetix_mobile"` → `"Zero Option"`

**Ostali manifest fajlovi** (debug, profile):

- Proveriti da li imaju specifične labele koje treba menjati

### 3.3 Package Struktura i MainActivity.kt

**Fajl:** [android/app/src/main/kotlin/com/kinetix/kinetix_mobile/MainActivity.kt](android/app/src/main/kotlin/com/kinetix/kinetix_mobile/MainActivity.kt)

**KORACI:**

1. Kreirati novu folder strukturu: `android/app/src/main/kotlin/com/zerooption/zero_option_mobile/`
2. Premestiti `MainActivity.kt` u novi folder
3. Promeniti package deklaraciju: `package com.kinetix.kinetix_mobile` → `package com.zerooption.zero_option_mobile`
4. Obrisati staru folder strukturu: `android/app/src/main/kotlin/com/kinetix/`

### 3.4 Settings Gradle (Opciono)

**Fajl:** [android/settings.gradle.kts](android/settings.gradle.kts)

- Proveriti da li postoje reference na `kinetix_mobile` i ažurirati ako postoje

### 3.5 IML Fajlovi

**Fajlovi:**

- [android/kinetix_mobile_android.iml](android/kinetix_mobile_android.iml) → Preimenovati u `zero_option_mobile_android.iml`
- [kinetix_mobile.iml](kinetix_mobile.iml) → Preimenovati u `zero_option_mobile.iml`

**⚠️ VAŽNO:** Ovi fajlovi se obično regenerišu, ali bolje je ručno preimenovati.

---

## 4. iOS KONFIGURACIJA

### 4.1 Info.plist

**Fajl:** [ios/Runner/Info.plist](ios/Runner/Info.plist)

- Linija 8: `CFBundleDisplayName` → `"Zero Option"`
- Linija 16: `CFBundleName` → `"zero_option_mobile"`

### 4.2 Xcode Projekt

**Fajl:** [ios/Runner.xcodeproj/project.pbxproj](ios/Runner.xcodeproj/project.pbxproj)

**Pronaći i zameniti:**

- `com.kinetix.kinetixMobile` → `com.zerooption.zeroOptionMobile` (6 pojavljivanja)
  - Linije: 371, 387, 404, 419, 550, 572

**⚠️ VAŽNO:** Ovo je kompleksan fajl - preporučeno je otvoriti projekat u Xcode i promeniti:

1. Target → Runner → General → Bundle Identifier: `com.kinetix.kinetixMobile` → `com.zerooption.zeroOptionMobile`
2. Target → Runner → Display Name: `Kinetix Mobile` → `Zero Option`

### 4.3 macOS Info.plist (ako postoji)

**Fajl:** [macos/Runner/Info.plist](macos/Runner/Info.plist)

- Proveriti i ažurirati bundle identifikatore i display name ako postoje

---

## 5. WEB KONFIGURACIJA

### 5.1 Manifest.json

**Fajl:** [web/manifest.json](web/manifest.json)

- Linija 2: `"name": "kinetix_mobile"` → `"Zero Option"`
- Linija 3: `"short_name": "kinetix_mobile"` → `"Zero Option"`
- Linija 8: `"description": "A new Flutter project."` → `"Zero Option - Offline-First Gym App"`

### 5.2 Index.html

**Fajl:** [web/index.html](web/index.html)

- Linija 26: `apple-mobile-web-app-title="kinetix_mobile"` → `"Zero Option"`
- Linija 32: `<title>kinetix_mobile</title>` → `<title>Zero Option</title>`

---

## 6. WORKSPACE FOLDER PREIMENOVANJE

### 6.1 Wi