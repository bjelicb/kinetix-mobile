# KINETIX MOBILE - MASTERPLAN V3
## Faza 3: UX Improvements

**Prioritet:** 🟢 **SREDNJI**  
**Status:** ❌ Nije početo  
**Timeline:** 1-2 dana

> **FOKUS:** UI/UX poboljšanja za bolje korisničko iskustvo.

---

## ⚠️ **KRITIČNA PRAVILA - MORA SE POŠTOVATI:**

### **1. NE TRPATI SVE U JEDAN FILE:**
- ❌ **ZABRANJENO:** Jedan `empty_state.dart` sa 50 if-ova za različite screen-ove
- ✅ **DOBRO:** Odvojiti po tipu:
  - `empty_state_widget.dart` - Base widget
  - `empty_state_illustrations.dart` - Ilustracije (constants)
  - Koristiti parametre za različite poruke

### **2. UX WORLD-CLASS:**
- ✅ Empty states moraju imati **ilustracije** (ne samo ikone)
- ✅ Skeleton loaders moraju imati **shimmer effect**
- ✅ Offline banner mora biti **ne-intruzivan** (ne blokira UI)
- ✅ Error messages moraju biti **friendly i actionable** (ne samo "Error occurred")

### **3. PERFORMANSE:**
- ✅ Skeleton loaders moraju biti **performant** (ne blokiraju UI thread)
- ✅ Empty states moraju imati **lazy loading** za ilustracije

---

## 📋 **ZADACI:**

### **3.1 Offline Mode - Better UX** 🟢

**Zahtevi:**
- [ ] Offline banner na vrhu ekrana
- [ ] Disable funkcionalnosti koje zahtevaju internet
- [ ] Queue indicator (koliko izmena čeka sync)
- [ ] Auto-hide banner kada se konekcija vrati

**Fajlovi:**
- `lib/presentation/widgets/offline_banner.dart` - **NOVO**

---

### **3.2 Network Error Handling** 🟢

**Zahtevi:**
- [ ] Specific error messages (No internet, Server unavailable, etc.)
- [ ] Retry button za failed operacije
- [ ] Error snackbar sa action button-om

**Fajlovi:**
- `lib/presentation/widgets/error_snackbar.dart` - **NOVO**

---

### **3.3 Empty States** 🟢

**Zahtevi:**
- [ ] Empty state za Dashboard
- [ ] Empty state za Calendar
- [ ] Empty state za Workout History
- [ ] Empty state za Check-ins
- [ ] Ilustracije za empty states

**Fajlovi:**
- `lib/presentation/widgets/empty_state.dart` - **NOVO**

---

### **3.4 Loading States Improvements** 🟢

**Zahtevi:**
- [ ] Skeleton loaders umesto spinner-a
- [ ] Progress indicators za sync operacije
- [ ] Shimmer effect
- [ ] Consistent loading UI

**Fajlovi:**
- `lib/presentation/widgets/skeleton_loader.dart` - **NOVO**

---

### **3.5 Plan History Visualization** 🟡

**Zadatak:**
Grafički prikaz istorije planova za klijenta

**Zahtevi:**
- [ ] Plan History timeline page (grafički prikaz)
- [ ] Filter by trainer, date range
- [ ] Prikaz: start/end datumi, trainer, plan name
- [ ] Visual indicator za aktivni plan
- [ ] Tap na plan → prikaz detalja

**Fajlovi:**
- `lib/presentation/pages/plan_history_page.dart` - **NOVO**
- `lib/presentation/widgets/plan_timeline_widget.dart` - **NOVO**

---

### **3.6 Sync Conflict Logging** 🟡

**Zadatak:**
Log-ovati sync conflict-e za debugging i monitoring

**Zahtevi:**
- [ ] Log-ovati kada se dešava conflict (Server Wins)
- [ ] Prikazati conflict log u Settings (opciono, za debugging)
- [ ] Track conflict count po tipu (workout, check-in, plan)
- [ ] Analytics: koliko conflict-a se dešava (indikator problema)

**Fajlovi:**
- `lib/services/sync_manager.dart` - **IZMENA**
- `lib/data/models/sync_conflict_log.dart` - **NOVO** (Isar collection)

---

### **3.7 Demo/Presentation Mode** 🟢

**Zadatak:**
Omogućiti prezentaciju aplikacije bez backend servera (mock mode)

**Zahtevi:**
- [ ] Dodati `USE_DEMO_MODE` flag u `ApiConstants` ili env config
- [ ] Integrisati `MockRemoteDataSource` u dependency injection
- [ ] Mock login: bilo koji email/password radi (generiše mock token)
- [ ] Mock podaci: planovi, workout logs, check-ins, trainers, clients
- [ ] Demo mode indicator u UI (opciono, banner "Demo Mode")
- [ ] Prebacivanje između mock i real mode (Settings ili build config)

**Fajlovi:**
- `lib/core/constants/api_constants.dart` - **IZMENA** (dodati `USE_DEMO_MODE`)
- `lib/data/datasources/mock_remote_data_source.dart` - **IZMENA** (kompletan mock)
- `lib/main.dart` - **IZMENA** (DI setup za mock vs real)
- `lib/data/repositories/auth_repository_impl.dart` - **IZMENA** (conditional DI)
- `lib/data/repositories/workout_repository_impl.dart` - **IZMENA** (conditional DI)
- `lib/data/repositories/admin_repository_impl.dart` - **IZMENA** (conditional DI)

**Mock Podaci:**
- Mock trainers (3-5 trenera sa različitim imenima)
- Mock clients (10-15 klijenata, različiti treneri)
- Mock plans (5-7 planova, različite težine)
- Mock workout logs (historical data za poslednjih 2 nedelje)
- Mock check-ins (sa mock photo URLs)
- Mock analytics data (streak, penalties, progress)

**Implementacija:**
```dart
// lib/core/constants/api_constants.dart
class ApiConstants {
  static const bool USE_DEMO_MODE = bool.fromEnvironment('DEMO_MODE', defaultValue: false);
  // ... ostalo
}

// lib/main.dart
final remoteDataSourceProvider = Provider<RemoteDataSource>((ref) {
  if (ApiConstants.USE_DEMO_MODE) {
    final storage = FlutterSecureStorage();
    return MockRemoteDataSource(storage);
  }
  return RemoteDataSource(...);
});
```

**Usage:**
- Development: `flutter run --dart-define=DEMO_MODE=true`
- Presentation: `flutter run --dart-define=DEMO_MODE=true --release`
- Production: `flutter run` (normal mode)

---

### **3.8 Video Player Integration** 🟢

**Zadatak:**
Video playback za exercise tutorials

**Zahtevi:**
- [ ] Video player widget (video_player package)
- [ ] Fullscreen mode
- [ ] Playback controls (play, pause, seek, volume)
- [ ] Thumbnail preview (pre load)
- [ ] Integration u Workout Runner page
- [ ] Integration u Exercise Details (Plan Details page)
- [ ] Loading state dok video se učitava
- [ ] Error handling (video ne može da se učita)
- [ ] Auto-play on tap (opciono)
- [ ] Video caching (cache downloaded videos)

**Fajlovi:**
- `lib/presentation/widgets/video_player_widget.dart` - **NOVO**
- `lib/presentation/pages/workout_runner_page.dart` - **IZMENA**
- `lib/presentation/pages/plan_details_page.dart` - **IZMENA**
- `lib/presentation/widgets/exercise_video_player.dart` - **NOVO**

**Implementacija:**

```dart
// video_player_widget.dart
class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool showControls;
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeVideo(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.hasError) {
          return Container(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: AppColors.error),
                  SizedBox(height: 8),
                  Text('Video unavailable', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
          );
        }
        
        return GestureDetector(
          onTap: () => _toggleFullscreen(context),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: VideoPlayer(_controller),
          ),
        );
      },
    );
  }
  
  Future<void> _toggleFullscreen(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullscreenVideoPlayer(videoUrl: videoUrl),
        fullscreenDialog: true,
      ),
    );
  }
}

// workout_runner_page.dart
Widget _buildExerciseVideo(Exercise exercise) {
  if (exercise.videoUrl == null || exercise.videoUrl!.isEmpty) {
    return SizedBox.shrink();
  }
  
  return Padding(
    padding: EdgeInsets.only(bottom: 16),
    child: VideoPlayerWidget(
      videoUrl: exercise.videoUrl!,
      autoPlay: false,
      showControls: true,
    ),
  );
}
```

**Testovi:**
- [ ] Test video player initialization
- [ ] Test fullscreen mode
- [ ] Test playback controls
- [ ] Test error handling
- [ ] Test video caching
- [ ] Test integration u Workout Runner

---

## ✅ **CHECKLIST:**

- [ ] Offline mode UX poboljšan (offline banner, queue indicator UI)
- [x] Network error handling poboljšan ✅ **KOMPLETIRANO** (ErrorHandler sa SnackBar/Dialog - pre-empted tokom V2)
- [x] Empty states dodati ✅ **KOMPLETIRANO** (EmptyState widget - pre-empted tokom V2)
- [x] Loading states poboljšani ✅ **KOMPLETIRANO** (ShimmerLoader sa shimmer effect - pre-empted tokom V2)
- [ ] **Plan history visualization implementirana**
- [ ] **Sync conflict logging implementirana** (Isar collection)
- [ ] **Demo/Presentation mode implementiran (mock data, offline prezentacija)**
- [ ] **Video Player Integration implementirana**
  - [ ] Video player widget
  - [ ] Fullscreen mode
  - [ ] Playback controls
  - [ ] Integration u Workout Runner
  - [ ] Integration u Plan Details
  - [ ] Error handling

---

## 🔗 **VEZE:**

- **Status:** `docs/MOBILE_STATUS.md`
- **Sledeća Faza:** `docs/MOBILE_MASTERPLAN_V4.md` (Produkcija)

