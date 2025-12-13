# Kompletno Preimenovanje Projekta: Kinetix → Zero Option

## Pregled
Ovaj plan pokriva potpuno preimenovanje Flutter projekta sa "Kinetix" na "Zero Option", uključujući sve aspekte - od Dart koda, preko platform konfiguracija, do workspace foldera.

---

## 1. DART KOD I KONSTANTE

### 1.1 Main App Klasa
**Fajl:** `lib/main.dart`
- Linija 14: `KinetixApp()` → `ZeroOptionApp()`
- Linija 19: `class KinetixApp` → `class ZeroOptionApp`
- Linija 20: `const KinetixApp` → `const ZeroOptionApp`
- Linija 29: `title: 'Kinetix'` → `title: 'Zero Option'`

### 1.2 App Constants
**Fajl:** `lib/core/constants/app_constants.dart`
- Linija 3: `appName = 'Kinetix'` → `'Zero Option'`

### 1.3 UI Tekstovi
**Fajl:** `lib/presentation/pages/login_page.dart`
- Linija 98: `'KINETIX'` → `'ZERO OPTION'`

**Fajl:** `lib/presentation/widgets/modals/about_dialog.dart`
- Linija 31: `'About Kinetix'` → `'About Zero Option'`
- Linija 55: `'Kinetix - Your personal fitness companion'` → `'Zero Option - Your personal fitness companion'`

**Fajl:** `lib/presentation/pages/admin_dashboard/widgets/admin_header.dart`
- Linija 38: `'Kinetix'` → `'Zero Option'`

**Fajl:** `lib/presentation/pages/onboarding_page.dart`
- Linija 24: `'Welcome to Kinetix'` → `'Welcome to Zero Option'`

### 1.4 Interni Identifikatori
**Fajl:** `lib/services/background_sync_service.dart`
- Linija 10: `'kinetix_sync_task'` → `'zero_option_sync_task'`
- Linija 11: `'kinetix_sync_oneoff'` → `'zero_option_sync_oneoff'`

**Fajl:** `lib/core/utils/image_cache_manager.dart`
- Linija 16: `'kinetix_image_cache'` → `'zero_option_image_cache'`

**Fajl:** `lib/presentation/pages/settings/services/settings_export_service.dart`
- Linija 25: `'kinetix_workouts_...'` → `'zero_option_workouts_...'`
- Linija 52: `'kinetix_workouts_...'` → `'zero_option_workouts_...'`

### 1.5 Import Aliasi (Opciono)
**Fajlovi:** 
- `lib/presentation/pages/dashboard_page.dart` (linija 9, 171)
- `lib/presentation/pages/workout_history_page.dart` (linija 12, 202)
- `lib/presentation/pages/admin_dashboard/widgets/user_management_card.dart` (linija 8, 66)

**Napomena:** `kinetix_search` je samo alias - može ostati ili promeniti u `zeroOptionSearch` za konzistentnost

---

## 2. PACKAGE NAME (pubspec.yaml)

**Fajl:** `pubspec.yaml`
- Linija 1: `name: kinetix_mobile` → `name: zero_option_mobile`
- Linija 2: `description: "Kinetix - Offline-First..."` → `"Zero Option - Offline-First..."`

**VAŽNO:** Nakon promene package name-a, mora se pokrenuti:
```bash
flutter clean
flutter pub get
```

---

## 3. ANDROID KONFIGURACIJA

### 3.1 Build Gradle
**Fajl:** `android/app/build.gradle.kts`
- Linija 9: `namespace = "com.kinetix.kinetix_mobile"` → `"com.zerooption.zero_option_mobile"`
- Linija 24: `applicationId = "com.kinetix.kinetix_mobile"` → `"com.zerooption.zero_option_mobile"`

### 3.2 AndroidManifest.xml
**Fajl:** `android/app/src/main/AndroidManifest.xml`
- Linija 3: `android:label="kinetix_mobile"` → `"Zero Option"`

**Ostali manifest fajlovi** (debug, profile):
- Proveriti da li imaju specifične labele koje treba menjati

### 3.3 Package Struktura i MainActivity.kt
**Fajl:** `android/app/src/main/kotlin/com/kinetix/kinetix_mobile/MainActivity.kt`

**KORACI:**
1. Kreirati novu folder strukturu: `android/app/src/main/kotlin/com/zerooption/zero_option_mobile/`
2. Premestiti `MainActivity.kt` u novi folder
3. Promeniti package deklaraciju: `package com.kinetix.kinetix_mobile` → `package com.zerooption.zero_option_mobile`
4. Obrisati staru folder strukturu: `android/app/src/main/kotlin/com/kinetix/`

### 3.4 Settings Gradle (Opciono)
**Fajl:** `android/settings.gradle.kts`
- Proveriti da li postoje reference na `kinetix_mobile` i ažurirati ako postoje

### 3.5 IML Fajlovi
**Fajlovi:**
- `android/kinetix_mobile_android.iml` → Preimenovati u `zero_option_mobile_android.iml`
- `kinetix_mobile.iml` → Preimenovati u `zero_option_mobile.iml`

**VAŽNO:** Ovi fajlovi se obično regenerišu, ali bolje je ručno preimenovati.

---

## 4. iOS KONFIGURACIJA

### 4.1 Info.plist
**Fajl:** `ios/Runner/Info.plist`
- Linija 8: `CFBundleDisplayName` → `"Zero Option"`
- Linija 16: `CFBundleName` → `"zero_option_mobile"`

### 4.2 Xcode Projekt
**Fajl:** `ios/Runner.xcodeproj/project.pbxproj`

**Pronaći i zameniti:**
- `com.kinetix.kinetixMobile` → `com.zerooption.zeroOptionMobile` (6 pojavljivanja)
  - Linije: 371, 387, 404, 419, 550, 572

**VAŽNO:** Ovo je kompleksan fajl - preporučeno je otvoriti projekat u Xcode i promeniti:
1. Target → Runner → General → Bundle Identifier: `com.kinetix.kinetixMobile` → `com.zerooption.zeroOptionMobile`
2. Target → Runner → Display Name: `Kinetix Mobile` → `Zero Option`

### 4.3 macOS Info.plist i Konfiguracije
**Fajl:** `macos/Runner/Info.plist`
- Proveriti i ažurirati bundle identifikatore i display name ako postoje

**Fajl:** `macos/Runner/Configs/AppInfo.xcconfig`
- Linija 8: `PRODUCT_NAME = kinetix_mobile` → `zero_option_mobile`
- Linija 11: `PRODUCT_BUNDLE_IDENTIFIER = com.kinetix.kinetixMobile` → `com.zerooption.zeroOptionMobile`
- Linija 14: `PRODUCT_COPYRIGHT` → Ažurirati sa "com.zerooption"

**Fajl:** `macos/Runner.xcodeproj/project.pbxproj`
- Pronaći i zameniti sve reference na `kinetix_mobile.app` → `zero_option_mobile.app`
- Pronaći i zameniti `com.kinetix.kinetixMobile` → `com.zerooption.zeroOptionMobile`
- **VAŽNO:** Proveriti i ažurirati `TEST_HOST` putanje koje referišu na app bundle

**Fajl:** `macos/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme`
- Pronaći i zameniti sve reference na `kinetix_mobile.app` → `zero_option_mobile.app` (4 pojavljivanja)

---

## 5. WINDOWS KONFIGURACIJA

### 5.1 CMakeLists.txt
**Fajl:** `windows/CMakeLists.txt`
- Linija 3: `project(kinetix_mobile LANGUAGES CXX)` → `project(zero_option_mobile LANGUAGES CXX)`
- Linija 7: `set(BINARY_NAME "kinetix_mobile")` → `"zero_option_mobile"`

### 5.2 Main.cpp
**Fajl:** `windows/runner/main.cpp`
- Linija 30: `window.Create(L"kinetix_mobile", ...)` → `L"zero_option_mobile"`

### 5.3 Runner.rc (Resource File)
**Fajl:** `windows/runner/Runner.rc`
- Linija 92: `VALUE "CompanyName", "com.kinetix"` → `"com.zerooption"`
- Linija 93: `VALUE "FileDescription", "kinetix_mobile"` → `"zero_option_mobile"`
- Linija 95: `VALUE "InternalName", "kinetix_mobile"` → `"zero_option_mobile"`
- Linija 96: `VALUE "LegalCopyright", "Copyright (C) 2025 com.kinetix..."` → Ažurirati sa "com.zerooption"
- Linija 97: `VALUE "OriginalFilename", "kinetix_mobile.exe"` → `"zero_option_mobile.exe"`
- Linija 98: `VALUE "ProductName", "kinetix_mobile"` → `"zero_option_mobile"`

---

## 6. LINUX KONFIGURACIJA

### 6.1 CMakeLists.txt
**Fajl:** `linux/CMakeLists.txt`
- Linija 7: `set(BINARY_NAME "kinetix_mobile")` → `"zero_option_mobile"`
- Linija 10: `set(APPLICATION_ID "com.kinetix.kinetix_mobile")` → `"com.zerooption.zero_option_mobile"`

### 6.2 My Application.cc
**Fajl:** `linux/runner/my_application.cc`
- Linija 48: `gtk_header_bar_set_title(header_bar, "kinetix_mobile")` → `"Zero Option"`
- Linija 52: `gtk_window_set_title(window, "kinetix_mobile")` → `"Zero Option"`

---

## 7. WEB KONFIGURACIJA

### 5.1 Manifest.json
**Fajl:** `web/manifest.json`
- Linija 2: `"name": "kinetix_mobile"` → `"Zero Option"`
- Linija 3: `"short_name": "kinetix_mobile"` → `"Zero Option"`
- Linija 8: `"description": "A new Flutter project."` → `"Zero Option - Offline-First Gym App"`

### 5.2 Index.html
**Fajl:** `web/index.html`
- Linija 26: `apple-mobile-web-app-title="kinetix_mobile"` → `"Zero Option"`
- Linija 32: `<title>kinetix_mobile</title>` → `<title>Zero Option</title>`

---

## 8. WORKSPACE FOLDER PREIMENOVANJE

### 8.1 Windows/Mac/Linux
**Trenutni folder:** `C:\Users\bjeli\Documents\Kinetix-Mobile`
**Novi folder:** `C:\Users\bjeli\Documents\ZeroOption-Mobile`

**KORACI:**
1. Zatvoriti IDE (Cursor/VS Code)
2. Preimenovati folder sa `Kinetix-Mobile` na `ZeroOption-Mobile`
3. Otvoriti novi folder u IDE-u
4. Ažurirati workspace settings ako postoje

### 8.2 Git Repository (ako se koristi)
**KORACI:**
1. Ako postoji `.git/config`, proveriti remote URL-ove
2. Ako repository ima "kinetix" u nazivu, možda će biti potrebno ažurirati remote URL

---

## 9. DOKUMENTACIJA

### 9.1 README.md
**Fajl:** `README.md`
- Linija 1: `# Kinetix Mobile` → `# Zero Option Mobile`
- Linija 3: Ažurirati opis sa "Kinetix" na "Zero Option"

### 9.2 Dokumentacija u docs/ folderu
**Proveriti i ažurirati:**
- Svi fajlovi u `docss/` folderu koji sadrže "Kinetix" reference
- Proveriti: `MOBILE_MASTERPLAN*.md`, `MOBILE_STATUS.md`, itd.

---

## 10. REDOSLED IZVRŠAVANJA

1. **Backup** - Napraviti backup celog projekta pre početka
2. **Dart kod** - Promeniti sve Dart reference
3. **pubspec.yaml** - Promeniti package name
4. **Android** - Ažurirati build.gradle, manifeste, i premestiti MainActivity
5. **iOS** - Ažurirati Info.plist, Xcode projekat, i AppInfo.xcconfig
6. **macOS** - Ažurirati Xcode projekat, AppInfo.xcconfig, i scheme fajlove
7. **Windows** - Ažurirati CMakeLists.txt, main.cpp, i Runner.rc
8. **Linux** - Ažurirati CMakeLists.txt i my_application.cc
9. **Web** - Ažurirati manifest.json i index.html
10. **IML fajlovi** - Preimenovati
11. **Dokumentacija** - Ažurirati README i docs
12. **Workspace** - Preimenovati folder (poslednji korak)
13. **Clean & Rebuild** - Pokrenuti `flutter clean && flutter pub get`
14. **Test** - Testirati na svim platformama

---

## VAŽNE NAPOMENE

### Pre Promena:
- **BACKUP** - Obavezno napraviti kompletan backup projekta
- **Git** - Commit-ovati trenutno stanje pre promena
- **Close IDE** - Zatvoriti IDE pre preimenovanja foldera

### Šta NIJE potrebno menjati:
- **Git commit history** - Ovo ostaje istorija i nije problem
- **Package dependencies** - Ne menjaju se
- **Database schema** - Ako koristi Isar, proveriti da li ime baze treba menjati

### Posle Promena:
1. **Flutter Clean:** `flutter clean`
2. **Reinstall:** `flutter pub get`
3. **Rebuild:** `flutter build android/ios/web`
4. **Test:** Testirati sve funkcionalnosti

### Potencijalni Problemi:
- **Android:** Ako imate instaliranu staru verziju app-a, nova verzija sa drugim package ID-om će biti tretirana kao nova aplikacija
- **iOS:** Bundle identifier promena zahteva novi provisioning profile za production
- **Cached Data:** Može biti potrebno obrisati cache na device-u

---

## PROVERA KONZISTENTNOSTI

Nakon svih promena, pokrenuti:
```bash
# Pronaći sve preostale reference na svim platformama
grep -r -i "kinetix" lib/
grep -r -i "kinetix" android/
grep -r -i "kinetix" ios/
grep -r -i "kinetix" macos/
grep -r -i "kinetix" windows/
grep -r -i "kinetix" linux/
grep -r -i "kinetix" web/
```

**NAPOMENA:** Očekivano je da će neki fajlovi i dalje sadržati "kinetix" ako je to deo dokumentacije ili test podataka. Fokus na kritične konfiguracije.

---

## ANALIZA RIZIKA I REKOMENDACIJE

### ⚠️ NIVO RIZIKA: SREDNJI do VISOK

#### NISKI RIZICI (lako reversibilno):
- ✅ **Dart kod** - Lako promeniti nazad
- ✅ **UI tekstovi** - Lako promeniti nazad
- ✅ **pubspec.yaml** - Lako promeniti nazad
- ✅ **Web konfiguracije** - Lako promeniti nazad

#### SREDNJI RIZICI (zahtevaju rebuild):
- ⚠️ **Android package name** - Menjanje `applicationId` znači nova aplikacija
  - **Posledice:** Stara i nova verzija će koegzistirati kao različite aplikacije
  - **Rešenje:** Korisnici moraju deinstalirati staru verziju ručno
- ⚠️ **iOS bundle identifier** - Menjanje zahteva novi provisioning profile za production
  - **Posledice:** Ne može se publish-ovati na App Store sa istim bundle ID-em
  - **Rešenje:** Kreirati novi App ID u Apple Developer portalu
- ⚠️ **Windows/Linux/macOS** - Build konfiguracije su reverzibilne ali zahtevaju rebuild

#### VISOKI RIZICI (mogu imati posledice):
- 🔴 **Workspace folder preimenovanje** - Može pokvariti IDE settings, Git history, i path reference
  - **Rizik:** Ako nešto pođe po zlu, teže je vraćanje
  - **Rešenje:** Backup pre preimenovanja, proveriti Git remote URL-ove nakon

### ✅ SIGURNOSNE MERA ZAŠTITE:

1. **BACKUP (OBAVEZNO):**
   ```bash
   # Napraviti kompletan backup pre bilo koje promene
   cp -r Kinetix-Mobile Kinetix-Mobile-BACKUP
   # Ili na Windows:
   xcopy /E /I Kinetix-Mobile Kinetix-Mobile-BACKUP
   ```

2. **Git Commit:**
   ```bash
   git add .
   git commit -m "Backup pre preimenovanja u Zero Option"
   ```

3. **Postepeno Testiranje:**
   - Ne menjati sve odjednom
   - Prvo Dart kod → test → onda platforme → test → onda folder

4. **Flutter Clean Posle Svake Platforme:**
   ```bash
   flutter clean
   flutter pub get
   ```

### ⚠️ POTENCIJALNI PROBLEMI:

1. **Android:**
   - Ako imaš instaliranu aplikaciju, nova verzija će biti nova aplikacija
   - Korisnici će morati deinstalirati staru verziju
   - Shared preferences i database podaci NEĆE biti preneseni

2. **iOS:**
   - Bundle identifier promena zahteva novi App ID u Apple Developer portalu
   - Production provisioning profile mora biti kreiran ponovo
   - TestFlight i App Store release će biti nova aplikacija

3. **Git:**
   - Ako koristiš remote repository sa "kinetix" u nazivu, može biti konfuzno
   - History ostaje isti (to je OK)

4. **IDE Settings:**
   - Cursor/VS Code workspace settings mogu imati hardcodovane putanje
   - Može biti potrebno reimportovati projekat

5. **Generated Files:**
   - `build/`, `.dart_tool/`, `.flutter-plugins` će se regenerisati
   - IML fajlovi će se možda regenerisati (bolje ih ne menjati)

### 📋 PREPORUČENI REDOSLED (Minimalno rizično):

1. **Backup** ✅
2. **Git commit** ✅
3. **Dart kod promene** (reversibilno)
4. **Test Dart promene** (pokrenuti app)
5. **pubspec.yaml** (reversibilno)
6. **Test sa novim package name-om**
7. **Android promene** (srednji rizik)
8. **Test Android build**
9. **iOS promene** (srednji rizik)
10. **Test iOS build**
11. **Ostale platforme** (niskog rizika)
12. **Web promene** (niskog rizika)
13. **Dokumentacija** (niskog rizika)
14. **Folder preimenovanje** (visoki rizik - poslednje)

### ✅ PLAN JE KOMPLETAN?

**DA** - Plan pokriva:
- ✅ Svi Dart fajlovi
- ✅ Svi platform-specifični konfiguracije (Android, iOS, macOS, Windows, Linux, Web)
- ✅ Package konfiguracije
- ✅ Native kod fajlovi
- ✅ Resource fajlovi
- ✅ Dokumentacija

**Dodatno pokriveno:**
- ✅ Windows CMakeLists.txt, main.cpp, Runner.rc
- ✅ Linux CMakeLists.txt, my_application.cc
- ✅ macOS AppInfo.xcconfig, scheme fajlovi
- ✅ Sve Xcode projekat reference

**Šta NIJE uključeno (intencionalno):**
- ❌ Test fajlovi (mogu ostati sa "kinetix" referencama - to je OK za test podatke)
- ❌ Dokumentacija u `docss/` (opciono, možete kasnije)
- ❌ Git commit history (ostaje - to je OK)

---

## TODO LISTA

### Faza 1: Dart Kod
- [ ] Promeniti KinetixApp klasu u main.dart
- [ ] Ažurirati app_constants.dart
- [ ] Promeniti UI tekstove (login, about, admin, onboarding)
- [ ] Ažurirati interni identifikatori (sync, cache, export)

### Faza 2: Package i Platform
- [ ] Promeniti package name u pubspec.yaml
- [ ] Ažurirati Android build.gradle.kts
- [ ] Ažurirati Android manifeste
- [ ] Premestiti i ažurirati MainActivity.kt
- [ ] Ažurirati iOS Info.plist
- [ ] Ažurirati iOS Xcode projekat (bundle identifier)
- [ ] Ažurirati macOS AppInfo.xcconfig i Xcode projekat
- [ ] Ažurirati macOS scheme fajlove
- [ ] Ažurirati Windows CMakeLists.txt, main.cpp, i Runner.rc
- [ ] Ažurirati Linux CMakeLists.txt i my_application.cc
- [ ] Ažurirati Web manifest.json i index.html

### Faza 3: Struktura i Dokumentacija
- [ ] Preimenovati IML fajlove
- [ ] Ažurirati README.md
- [ ] Ažurirati dokumentaciju u docs/

### Faza 4: Finalizacija
- [ ] Preimenovati workspace folder
- [ ] Pokrenuti flutter clean
- [ ] Pokrenuti flutter pub get
- [ ] Testirati aplikaciju na Android/iOS/Web

