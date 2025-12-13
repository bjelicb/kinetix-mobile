---
name: Add Sync Logging and Update Checklist
overview: Dodajem detaljne logove u sync_manager.dart za testiranje sync mehanizma (sa sažetkom na kraju) i ažuriram checklist da označi responsive design kao testiran.
todos:
  - id: update_checklist_responsive
    content: Ažurirati V2_TESTING_CHECKLIST.txt - označiti responsive design kao testiran
    status: pending
  - id: add_sync_main_logs
    content: Dodati detaljne logove u sync() metodu sa sažetkom na kraju
    status: pending
  - id: add_push_logs
    content: Dodati logove u _pushChanges() sa brojem elemenata i rezultatom
    status: pending
  - id: add_pull_logs
    content: Poboljšati logove u _pullChanges() sa sažetkom
    status: pending
  - id: add_media_logs
    content: Dodati logove u _syncMedia() metodu
    status: pending
  - id: update_checklist_sync
    content: Ažurirati sekciju 9. SYNC MECHANISM u checklist-u sa detaljnim koracima za testiranje
    status: pending
---

# Plan: Dodavanje Sync Logova i Ažuriranje Checklist-a

## 1. Ažuriranje Checklist-a

- **Fajl**: `V2_TESTING_CHECKLIST.txt`
- Označiti sekciju **10. RESPONSIVE DESIGN** kao `✅ (TESTIRANO)` umesto `X (NISU TESTIRANI)`
- Ažurirati sekciju **9. SYNC MECHANISM** sa detaljnim koracima za testiranje

## 2. Dodavanje Detaljnih Logova u Sync Manager

### 2.1 Glavna Sync Metoda (`sync()`)

- **Fajl**: `lib/services/sync_manager.dart` (linija ~132)
- Dodati log na početak: `[SyncManager] ═══ SYNC START ═══`
- Dodati log nakon svakog koraka (media, push, pull)
- Dodati sažetak na kraju sa ukupnim rezultatom

### 2.2 Push Changes (`_pushChanges()`)

- **Fajl**: `lib/services/sync_manager.dart` (linija ~193)
- Dodati log na početak sa brojem dirty elemenata:
  ```
  [SyncManager] ═══ PUSH CHANGES START ═══
  [SyncManager] → Found: X workouts, Y check-ins, Z plans to sync
  ```

- Dodati log pre slanja batch-a: `[SyncManager] → Sending batch to server...`
- Dodati log nakon uspešnog slanja sa rezultatom
- Dodati sažetak na kraju: `[SyncManager] ═══ PUSH COMPLETE: X success, Y failed ═══`

### 2.3 Pull Changes (`_pullChanges()`)

- **Fajl**: `lib/services/sync_manager.dart` (linija ~457)
- Već ima dobre logove, ali dodati:
  - Sažetak na kraju sa ukupnim rezultatom
  - Log za "No changes" scenario

### 2.4 Media Sync (`_syncMedia()`)

- **Fajl**: `lib/services/sync_manager.dart` (linija ~154)
- Dodati logove:
  ```
  [SyncManager] ═══ MEDIA SYNC START ═══
  [SyncManager] → Found X check-ins without photo URL
  [SyncManager] → Uploaded: X photos successfully
  [SyncManager] ═══ MEDIA SYNC COMPLETE ═══
  ```


## 3. Objašnjenje Testiranja Sync Mehanizma

### Test Scenario 1: Push Changes (Offline → Online)

1. **Offline mode**: Isključi internet/WiFi
2. **Napravi izmene**: 

   - Završi workout (markiraj kao completed)
   - Napravi check-in (ako je implementiran)

3. **Online mode**: Uključi internet
4. **Trigger sync**: App bi trebalo automatski da pozove sync, ili ručno pozovi
5. **Proveri logove**: Trebalo bi da vidiš:

   - `[SyncManager] ═══ SYNC START ═══`
   - `[SyncManager] ═══ PUSH CHANGES START ═══`
   - `[SyncManager] → Found: 1 workouts, 0 check-ins, 0 plans to sync`
   - `[SyncManager] ═══ PUSH COMPLETE: 1 success, 0 failed ═══`

### Test Scenario 2: Pull Changes (Admin → Client)

1. **Admin**: Assign plan klijentu ili update workout status
2. **Client app**: Otvori app (sync bi trebalo automatski da se pozove)
3. **Proveri logove**: Trebalo bi da vidiš:

   - `[SyncManager] ═══ PULL CHANGES START ═══`
   - `[SyncManager] → API response received`
   - `[SyncManager] → Parsed response: Workouts: X, CheckIns: Y, Plans: Z`
   - `[SyncManager] → Workouts processed: X, failed: 0`

### Test Scenario 3: Full Sync Cycle

1. **Napravi izmene offline**: Završi workout
2. **Uključi internet**: Sync bi trebalo automatski da se pozove
3. **Proveri logove**: Trebalo bi da vidiš kompletan ciklus:

   - Media sync
   - Push changes
   - Pull changes
   - Sažetak na kraju

## 4. Gde se Sync Poziva

- **Automatski**: Verovatno u `bootstrap.dart` ili `background_sync_service.dart`
- **Ručno**: Možda u settings ili refresh dugme
- Proveriti gde se poziva `sync()` metoda i dodati log tamo takođe

## 5. Format Logova

Svi logovi treba da imaju:

- Jasne separator linije (`══════`) za početak/kraj sekcija
- Emoji indikatore: `✓` za uspeh, `✗` za grešku, `→` za progres
- Sažetak na kraju sa brojevima (success/failed/total)