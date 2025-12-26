# KINETIX MOBILE - MASTERPLAN V4
## Faza 4: Produkcija (App Store & Monitoring)

**Prioritet:** 🟢 **POSLE TESTIRANJA**  
**Status:** ❌ Nije početo  
**Timeline:** 1-2 nedelje

> **FOKUS:** Produkcijski taskovi - App Store submission, monitoring, branding.

---

## 📋 **ZADACI:**

### **4.1 App Store Preparation** 🟢
- [ ] Custom app icons (iOS/Android)
- [ ] Custom splash screens
- [ ] App Store screenshots
- [ ] Privacy policy
- [ ] Terms of service

### **4.2 Monitoring & Analytics** 🟢
- [ ] Error tracking (Sentry/Crashlytics)
- [ ] Analytics integration (Firebase Analytics)
- [ ] Performance monitoring

### **4.3 Push Notifications & AI Integration** 🟢

**Zahtevi:**
- [ ] Firebase Cloud Messaging integracija
- [ ] Notification permission requests (iOS/Android)
- [ ] Notification handling (foreground/background/terminated)
- [ ] Deep linking (tap notification → open specific page)
- [ ] Notification scheduling (local notifications)

**Tipovi Notifikacija:**
- [ ] **Workout Reminders** (1h pre workout-a)
- [ ] **Trainer Messages** (AI-generated ili manual od trenera)
- [ ] **Streak Reminders** (motivational - "Don't break your streak!")
- [ ] **Penalty Warnings** (pre nego što dođe do penalty-a)
- [ ] **Plan Updates** (novi plan assigned, plan izmene)
- [ ] **Check-in Reminders** (ako nije radio check-in danas)

**AI Integration:**
- [ ] Backend endpoint za AI-generated notifications
- [ ] AI tone (motivational, warning, celebration)
- [ ] Personalized messages based on user progress
- [ ] Integration sa existing AI Messages system (4.1)

**AI Messaging System (Backend Ready):**
- ✅ Backend endpoint: `POST /gamification/generate-message`
- ✅ Backend endpoint: `GET /gamification/messages/:clientId`
- ✅ AI Message Service sa template-based messaging
- ✅ Spreman za LLM integraciju (V4 Phase 2)
- ⚠️ Mobile app treba da prikazuje AI poruke u Dashboard-u
- ⚠️ Mobile app treba da integriše sa Push Notifications (V4)

**Implementation:**
- Backend već ima `AIMessageService` sa tone selection
- Mobile app treba da dodaje AI Messages widget u Dashboard
- Mobile app treba da prikazuje poruke sa različitim tonovima (aggressive, motivational, etc.)

**Fajlovi:**
- `lib/services/notification_service.dart` - **NOVO**
- `lib/services/notification_handler.dart` - **NOVO**
- `lib/data/repositories/notification_repository.dart` - **NOVO**

---

### **4.4 Branding & Polish** 🟢

**Zahtevi:**
- [ ] Custom fonts (brand typography)
- [ ] Color palette finalizacija i dokumentacija
- [ ] Consistent spacing/padding sistema (8px grid)
- [ ] Icon set finalizacija (custom icons gde treba)
- [ ] Button styles standardization
- [ ] Card shadows standardization
- [ ] Animations polish (subtle micro-interactions)
- [ ] Sound effects (opciono - za completion, achievements)

**Fajlovi:**
- `lib/core/theme/app_theme.dart` - **IZMENA**
- `lib/core/constants/app_spacing.dart` - **NOVO** (spacing constants)
- `lib/core/constants/app_typography.dart` - **NOVO** (font styles)
- `lib/core/constants/app_shadows.dart` - **NOVO** (shadow constants)

**Dokumentacija:**
- [ ] Design system documentation (colors, fonts, spacing)
- [ ] Component library screenshots
- [ ] Animation guidelines

---

### **4.5 Performance Optimization** 🟢

**Zahtevi:**
- [ ] Image caching strategy (workout photos, profile pics)
- [ ] Lazy loading za large lists (workout history, calendar)
- [ ] Video caching (downloaded exercise videos)
- [ ] API response caching (reduce network calls)
- [ ] Database query optimization (Isar indexes)
- [ ] App startup time optimization
- [ ] Memory leak detection and fixes
- [ ] Build size optimization (tree-shaking, obfuscation)

**Metrics to Track:**
- [ ] App startup time (target: <2s)
- [ ] Frame render time (target: 60fps)
- [ ] Memory usage (target: <150MB)
- [ ] Network latency (API calls)
- [ ] Database query time

**Fajlovi:**
- `lib/core/utils/performance_monitor.dart` - **NOVO**
- `lib/core/utils/image_cache_manager.dart` - **IZMENA**
- `lib/data/datasources/local_data_source.dart` - **IZMENA** (add indexes)

---

### **4.6 Accessibility** 🟡

**Zahtevi:**
- [ ] Screen reader support (Semantics widgets)
- [ ] Text scaling support (respect system font size)
- [ ] High contrast mode support
- [ ] Keyboard navigation (web)
- [ ] Focus indicators
- [ ] Alt text za slike
- [ ] Color contrast ratio compliance (WCAG AA)

**Priority:**
- 🟢 **HIGH:** Screen reader, Text scaling
- 🟡 **MEDIUM:** Keyboard navigation, Focus indicators
- 🔴 **LOW:** High contrast mode (if not using dark mode)

**Fajlovi:**
- `lib/presentation/widgets/*` - **IZMENA** (add Semantics)
- `lib/core/theme/app_theme.dart` - **IZMENA** (text scaling)

---

### **4.7 Security Hardening** 🟢

**Zahtevi:**
- [ ] API key obfuscation (remove from code)
- [ ] SSL pinning (prevent man-in-the-middle)
- [ ] Secure storage verification (FlutterSecureStorage)
- [ ] Jailbreak/Root detection (opciono)
- [ ] Code obfuscation for release builds
- [ ] ProGuard rules (Android)
- [ ] Debug mode detection (disable sensitive features)

**Fajlovi:**
- `lib/core/constants/api_constants.dart` - **IZMENA**
- `android/app/proguard-rules.pro` - **NOVO**
- `lib/core/utils/security_utils.dart` - **NOVO**

---

## ✅ **CHECKLIST:**

- [ ] **App Store Preparation** (4.1)
  - [ ] Custom app icons
  - [ ] Splash screens
  - [ ] Screenshots
  - [ ] Privacy policy
  - [ ] Terms of service
  
- [ ] **Monitoring & Analytics** (4.2)
  - [ ] Error tracking (Sentry/Crashlytics)
  - [ ] Firebase Analytics
  - [ ] Performance monitoring
  - [ ] User retention metrics
  - [ ] Engagement metrics
  
- [ ] **Push Notifications & AI** (4.3)
  - [ ] FCM integration
  - [ ] Notification handling
  - [ ] Deep linking
  - [ ] AI-generated messages
  - [ ] Trainer messages
  
- [ ] **Branding & Polish** (4.4)
  - [ ] Custom fonts
  - [ ] Color finalization
  - [ ] Spacing system
  - [ ] Animations polish
  
- [ ] **Performance Optimization** (4.5)
  - [ ] Image caching
  - [ ] Lazy loading
  - [ ] API caching
  - [ ] Startup optimization
  
- [ ] **Accessibility** (4.6)
  - [ ] Screen reader support
  - [ ] Text scaling
  - [ ] Keyboard navigation
  
- [ ] **Security Hardening** (4.7)
  - [ ] API key obfuscation
  - [ ] SSL pinning
  - [ ] Code obfuscation

---

## 🔗 **VEZE:**

- **Status:** `docs/MOBILE_STATUS.md`
- **Prethodna Faza:** `docs/MOBILE_MASTERPLAN_V3.md` (UX Improvements)

