# Offline Check-In Testing Guide

## ✅ Preporučena Metoda: Android Developer Options - Network Throttling

### Koraci:

1. **Settings** → **Developer Options**
2. Pronađi **"Network throttling"** ili **"Mobile data always active"**
3. Ispalji **Airplane Mode** (ali ostavi WiFi ON za ADB)
4. Ili koristi **"Select app to always run without network"** - dodaj Kinetix app

Ova metoda **NE prekida ADB konekciju**!

---

## 🔧 Alternativna Metoda: USB Debugging + Airplane Mode

### Koraci:

1. Isključi **WiFi debugging**
2. Poveži telefon preko **USB kabla**
3. Omogući **USB debugging**
4. Proveri: `adb devices` (treba da vidiš device)
5. Sada možeš da uključiš **Airplane Mode** - ADB će raditi preko USB-a!

---

## 📱 Pratiti Logove Bez Flutter Connection

Čak i ako Flutter connection prekine, možeš pratiti logove preko `adb logcat`:

### Opcija 1: Filter za Check-In logove

```powershell
# Otvori PowerShell u projektu folderu
adb logcat -c  # Clear logs first

# Watch check-in logs
adb logcat | Select-String -Pattern "CheckInService|CheckInQueue|SyncManager"
```

### Opcija 2: Sačuvaj logove u fajl

```powershell
# Sačuvaj sve logove u fajl
adb logcat > checkin_test_logs.txt

# Ili samo check-in related
adb logcat | Select-String -Pattern "CheckIn" > checkin_test_logs.txt
```

### Opcija 3: Koristi skriptu

```powershell
# Pokreni skriptu
.\scripts\watch_checkin_logs.ps1
```

---

## 🧪 Test Scenarijo

### 1. Priprema
```powershell
# 1. Pokreni Flutter app
flutter run

# 2. U drugom terminalu, pokreni logcat watcher
adb logcat | Select-String -Pattern "CheckIn"
```

### 2. Test Offline Check-In

1. **Isključi internet** (koristi Network Throttling ili Airplane Mode + WiFi za ADB)
2. **Uradi check-in** u app-u
3. **Očekivani logovi:**
   ```
   [CheckInService] 📴 OFFLINE MODE DETECTED
   [CheckInService] → Check-in will be QUEUED locally
   [CheckInService] 📴 CHECK-IN QUEUED FOR SYNC
   [CheckInService] → isSynced: false
   ```

### 3. Test Sync kada se internet vrati

1. **Uključi internet** (isključi Airplane Mode ili Network Throttling)
2. **⚠️ VAŽNO: Sync se NE poziva automatski!** Treba da uradiš **MANUAL SYNC**:
   - Otvori Settings (⚙️ ikona)
   - Klikni na "Manual Sync" dugme
   - ILI: Logout i Login ponovo (sync se poziva pri login-u)
3. **Očekivani logovi:**
   ```
   [SyncManager] ═══════ MEDIA SYNC START ═══════
   [CheckInQueue:Sync] ═══════ QUEUED CHECK-INS SYNC START ═══════
   [CheckInQueue:Sync] 📦 Found 1 queued check-in(s) to sync
   [CheckInQueue:Sync] 📤 Processing check-in 1/1
   [CheckInQueue:Sync] 📸 Uploading photo to Cloudinary...
   [CheckInQueue:Sync] ✅ Photo uploaded successfully
   [CheckInQueue:Sync] 📡 Creating check-in on server...
   [CheckInQueue:Sync] 📡 Sending POST /checkins request to backend...
   [CheckInQueue:Sync] ✅ Server check-in creation SUCCESS
   [CheckInQueue:Sync] → Backend should have received and saved check-in to MongoDB
   **Backend logovi:**
   [CheckInsController] POST /checkins - CREATE CHECK-IN REQUEST
   [CheckInsService] ✅ CHECK-IN SAVED TO MONGODB
   [CheckInQueue:Sync] 📊 SYNC SUMMARY
   [CheckInQueue:Sync] ✅ Successful: 1
   ```

---

## 💡 Saveti

1. **Ako koristiš WiFi debugging:** Ne isključuj WiFi u potpunosti - koristi Network Throttling umesto toga
2. **Ako koristiš USB debugging:** Možeš bezbedno isključiti WiFi i mobilne podatke
3. **Logovi su ključni:** Uvek prati `adb logcat` dok testiraš offline funkcionalnost
4. **Test na pravom telefonu:** Emulator možda ne simulira offline mode 100% tačno

---

## 🔍 Debugging Tips

### Proveri da li je check-in queue-ovan:

```powershell
# U Flutter app-u, dodaj debug button ili koristi adb shell
adb shell
run-as com.kinetix.mobile  # ili tvoj package name
cd databases
# proveri Isar database
```

### Proveri sync status:

U logovima traži:
- `isSynced: false` = queue-ovan za sync
- `isSynced: true` = već sync-ovan
- `photoUrl: NULL` = photo nije upload-ovan
- `photoUrl: https://...` = photo upload-ovan

