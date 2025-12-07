# Admin Dashboard - Plan za Sutra

## 📋 Spisak Funkcionalnosti za Dodavanje

### 1. Check-ins Management
- [ ] Prikaz svih check-in-ova sa filtrima (datum, client, status)
- [ ] Detalji check-in-a (foto, lokacija, vreme)
- [ ] Delete check-in funkcionalnost
- [ ] Export check-in podataka

### 2. Analytics & Reports
- [ ] Dashboard sa grafikonima (korisnici, workout-i, check-in-ovi po vremenu)
- [ ] User engagement metrics
- [ ] Workout completion rates
- [ ] Trainer performance metrics
- [ ] Export reports (PDF/CSV)

### 3. Bulk Operations
- [ ] Bulk user activation/deactivation
- [ ] Bulk assign clients to trainers
- [ ] Bulk delete operations (sa potvrdom)

### 4. Activity Logs / Audit Trail
- [ ] Prikaz svih admin akcija (ko je šta uradio)
- [ ] Filteri po akciji, korisniku, datumu
- [ ] Export logova

### 5. System Settings
- [ ] System configuration
- [ ] Email templates management
- [ ] Notification settings
- [ ] Maintenance mode toggle

### 6. Advanced Search & Filters
- [ ] Napredna pretraga sa više kriterijuma
- [ ] Sačuvani filteri
- [ ] Quick filters (Active users, Inactive users, etc.)

### 7. Export Functionality
- [ ] Export users (CSV/Excel)
- [ ] Export plans (JSON/CSV)
- [ ] Export workouts (CSV)
- [ ] Export check-ins (CSV)

### 8. Notifications Management
- [ ] Prikaz svih notifikacija
- [ ] Send custom notifications
- [ ] Notification templates

### 9. Database Management
- [ ] Database statistics (već postoji, možda poboljšati)
- [ ] Backup/restore opcije
- [ ] Database cleanup tools

### 10. User Activity Tracking
- [ ] Last login tracking
- [ ] Activity timeline per user
- [ ] Session management

---

## 🔧 Refaktorisanje - Plan za Rasterećenje Koda

### Trenutno Stanje
- **3469 linija koda** u jednom fajlu
- Previše widget metoda i modal metoda
- Teško za održavanje i testiranje

### Predložena Struktura

```
lib/presentation/pages/admin_dashboard/
├── admin_dashboard_page.dart          (glavna stranica - ~200 linija)
├── widgets/
│   ├── admin_header.dart              (_buildAdminHeader)
│   ├── system_stats_card.dart         (_buildSystemStats + loading/error)
│   ├── user_management_card.dart      (_buildUserManagementCard)
│   ├── users_list.dart                (_buildUsersList)
│   ├── trainer_management_card.dart   (_buildTrainerManagementCard)
│   ├── plan_management_card.dart      (_buildPlanManagementCard)
│   ├── workout_management_card.dart   (_buildWorkoutManagementCard)
│   ├── database_overview_card.dart    (_buildDatabaseOverview)
│   ├── stat_item.dart                 (_StatItem widget)
│   ├── custom_toggle.dart             (_CustomToggle widget)
│   ├── filter_chip.dart               (_FilterChip widget)
│   ├── user_list_item.dart            (_UserListItem widget)
│   └── plan_detail_item.dart          (_PlanDetailItem widget)
├── modals/
│   ├── create_user_modal.dart         (_showCreateUserModal)
│   ├── edit_user_modal.dart           (_showEditUserModal)
│   ├── user_details_modal.dart        (_showUserDetails)
│   ├── assign_clients_modal.dart      (_showAssignClientsModal)
│   ├── create_plan_modal.dart         (_showCreatePlanModal)
│   ├── edit_plan_modal.dart           (_showEditPlanModal)
│   ├── plan_details_modal.dart        (_showPlanDetailsModal)
│   ├── assign_plan_modal.dart         (_showAssignPlanModal)
│   └── workout_details_modal.dart      (_showWorkoutDetailsModal)
└── controllers/
    └── admin_dashboard_state.dart      (state management - _loadUsers, _loadPlans, etc.)
```

### Koraci za Refaktorisanje

1. **Kreirati folder strukturu**
   ```
   lib/presentation/pages/admin_dashboard/
   ```

2. **Ekstraktovati Widget klase** (najlakše prvo)
   - `_StatItem` → `widgets/stat_item.dart`
   - `_CustomToggle` → `widgets/custom_toggle.dart`
   - `_FilterChip` → `widgets/filter_chip.dart`
   - `_UserListItem` → `widgets/user_list_item.dart`
   - `_PlanDetailItem` → `widgets/plan_detail_item.dart`

3. **Ekstraktovati _build metode** u zasebne widget fajlove
   - Svaki `_build*` metod ide u svoj fajl
   - Koriste `ConsumerWidget` ili `StatelessWidget`
   - Prima potrebne parametre

4. **Ekstraktovati Modal metode** u zasebne fajlove
   - Svaki `_show*` metod ide u svoj fajl
   - Funkcije koje vraćaju `Widget` ili pozivaju `showModalBottomSheet`/`showDialog`

5. **Ekstraktovati State Management**
   - `_loadUsers`, `_loadPlans`, `_loadWorkouts`, `_loadWorkoutStats`
   - Može ostati u glavnom fajlu ili u zasebnom state fajlu

6. **Glavni fajl** (`admin_dashboard_page.dart`)
   - Ostaje samo struktura stranice
   - Importuje ekstraktovane widget-e i modal-e
   - ~200-300 linija koda

### Prednosti Refaktorisanja

✅ **Lakše održavanje** - svaki widget u svom fajlu
✅ **Lakše testiranje** - izolovani widget-i
✅ **Bolja čitljivost** - manji fajlovi
✅ **Reusability** - widget-i se mogu koristiti drugde
✅ **Team collaboration** - manje konflikata u Git-u
✅ **Performance** - lakše za Flutter da optimizuje

### Redosled Implementacije

1. ✅ Kreirati folder strukturu
2. ✅ Ekstraktovati widget klase (5 fajlova)
3. ✅ Ekstraktovati _build metode (8 fajlova)
4. ✅ Ekstraktovati modal metode (9 fajlova)
5. ✅ Refaktorisati glavni fajl
6. ✅ Testirati da sve radi
7. ✅ Cleanup - ukloniti nepotrebne importove

---

## 🎯 Prioriteti za Sutra

### Visoki Prioritet
1. **Refaktorisanje koda** - rasterećenje admin_dashboard_page.dart
2. **Check-ins Management** - dodati sekciju za check-in-ove
3. **Export Functionality** - osnovni export za users, plans, workouts

### Srednji Prioritet
4. **Analytics & Reports** - osnovni grafikon za user growth
5. **Bulk Operations** - bulk activate/deactivate users
6. **Advanced Search** - poboljšati pretragu

### Nizak Prioritet
7. **Activity Logs** - audit trail
8. **System Settings** - konfiguracija sistema
9. **Notifications Management** - upravljanje notifikacijama

---

## 📝 Napomene

- Sve funkcionalnosti treba da koriste postojeće backend endpoint-e
- Ako neki endpoint ne postoji, prvo ga dodati na backend-u
- Koristiti postojeće widget-e i stilove za konzistentnost
- Testirati svaku novu funkcionalnost pre dodavanja sledeće

