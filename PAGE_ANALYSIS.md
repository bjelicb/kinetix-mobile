# ANALIZA PAGE FAJLOVA - RASTERECENJE

## OPTIMALNO: 200-300 linija po page-u

---

## KRITIČNO PREOPTEREĆENI (>800 linija)

### 1. workout_runner_page.dart - 1062 linija
**STATUS:** KRITIČNO PREOPTEREĆEN

**Šta izdvojiti:**
- `_buildExerciseCard` → `widgets/workout/exercise_card_widget.dart`
- `_buildSetRow` → `widgets/workout/set_row_widget.dart`
- `_buildInputField` → `widgets/workout/input_field_widget.dart`
- `_buildFinishButton` → `widgets/workout/finish_button_widget.dart`
- `_buildHeader` → `widgets/workout/workout_header_widget.dart`
- `_togglePause`, `_startTimer`, `_stopTimer` → `services/workout_timer_service.dart`
- `_showNumpad`, `_showRpePicker` → `services/workout_input_service.dart`
- `_saveValue`, `_saveRpe`, `_deleteSet`, `_undoDelete`, `_toggleExerciseCompletion` → `services/workout_state_service.dart`
- `_checkCheckInStatus` → `services/workout_validation_service.dart`

**Rezultat:** 1062 → ~250 linija (page) + widgeti (~400) + servisi (~350)

---

### 2. plan_builder_page.dart - 927 linija
**STATUS:** KRITIČNO PREOPTEREĆEN

**Šta izdvojiti:**
- `_buildBasicInfoSection` → već izdvojeno u `plan_builder/widgets/basic_info_section.dart` ✓
- `_buildWorkoutDaysSection` → već izdvojeno u `plan_builder/widgets/workout_days_section.dart` ✓
- `_loadExistingPlan`, `_savePlan` → već izdvojeno u `plan_builder/plan_builder_service.dart` ✓
- `_updateWorkoutDay`, `_deleteWorkoutDay`, `_addWorkoutDay` → `plan_builder/plan_builder_service.dart` (dodati)
- `_showPreview` → `services/plan_preview_service.dart`

**Rezultat:** 927 → ~300 linija (page) + već postoje widgeti + servisi (~400)

---

### 3. dashboard_page.dart - 838 linija
**STATUS:** PREOPTEREĆEN

**Šta izdvojiti:**
- `_buildHeader` → `widgets/dashboard/header_widget.dart`
- `_buildQuickStats` → `widgets/dashboard/quick_stats_widget.dart`
- `_buildStatCardExpanded` → `widgets/dashboard/stat_card_widget.dart`
- `_buildTodaysMission` → `widgets/dashboard/todays_mission_widget.dart`
- `_buildClientContent` → `widgets/dashboard/client_content_widget.dart`
- `_buildTrainerContent` → `widgets/dashboard/trainer_content_widget.dart`
- `_loadBalance`, `_loadWeighIn`, `_loadMuscleGroups` → `services/dashboard_data_service.dart`
- `_checkPaywall` → `services/paywall_service.dart`
- `_getGreeting`, `_getThemeGradient`, `_getThemeColor` → `utils/theme_utils.dart`

**Rezultat:** 838 → ~250 linija (page) + widgeti (~350) + servisi (~200)

---

## PREOPTEREĆENI (500-800 linija)

### 4. profile_page.dart - 757 linija
**STATUS:** PREOPTEREĆEN

**Šta izdvojiti:**
- `_buildHeader` → `widgets/profile/header_widget.dart`
- `_buildStatistics` → `widgets/profile/statistics_widget.dart`
- `_buildStatCard` → `widgets/profile/stat_card_widget.dart`
- `_buildPersonalInfo` → `widgets/profile/personal_info_widget.dart`
- `_buildInfoRow` → `widgets/profile/info_row_widget.dart`
- `_buildSettings` → `widgets/profile/settings_widget.dart`
- `_buildSettingTile` → `widgets/profile/setting_tile_widget.dart`
- `_buildLogoutButton` → `widgets/profile/logout_button_widget.dart`
- `_showAboutDialog` → `modals/about_dialog.dart`
- `_showLogoutConfirmation` → `modals/logout_confirmation_dialog.dart`
- Statistics calculation → `services/profile_stats_service.dart`

**Rezultat:** 757 → ~200 linija (page) + widgeti (~400) + servisi (~150)

---

### 5. calendar_page.dart - 609 linija
**STATUS:** PREOPTEREĆEN

**Šta izdvojiti:**
- Calendar widget logika → već izdvojeno u `widgets/calendar/workout_calendar_widget.dart` ✓
- Verifikovati da li treba dodatno rasterećenje

**Rezultat:** 609 → ~300 linija (page) + već postoje widgeti (~300)

---

### 6. workout_edit_page.dart - 594 linija
**STATUS:** PREOPTEREĆEN

**Šta izdvojiti:**
- `_buildExerciseList` → `widgets/workout_edit/exercise_list_widget.dart`
- `_buildExerciseCard` → `widgets/workout_edit/exercise_card_widget.dart`
- `_buildSetEditor` → `widgets/workout_edit/set_editor_widget.dart`
- `_saveWorkout`, `_deleteWorkout` → `services/workout_edit_service.dart`
- Form validation → `services/workout_validation_service.dart`

**Rezultat:** 594 → ~250 linija (page) + widgeti (~250) + servisi (~100)

---

### 7. check_in_page.dart - 551 linija
**STATUS:** PREOPTEREĆEN

**Šta izdvojiti:**
- `_buildCameraPreview` → `widgets/check_in/camera_preview_widget.dart`
- `_buildCapturedImagePreview` → `widgets/check_in/image_preview_widget.dart`
- `_saveCheckIn` → `services/check_in_service.dart`
- GPS capture logic → `services/location_service.dart`
- Image compression → `services/image_compression_service.dart`
- Check-in validation → `services/check_in_validation_service.dart`

**Rezultat:** 551 → ~200 linija (page) + widgeti (~200) + servisi (~150)

---

## PRIHVATLJIVI (300-500 linija)

### 8. exercise_selection_page.dart - 488 linija
**STATUS:** PRIHVATLJIVO (blizu granice)

**Šta izdvojiti (opciono):**
- Exercise list building → `widgets/exercise/exercise_list_widget.dart`
- Search/filter logic → `services/exercise_search_service.dart`

**Rezultat:** 488 → ~350 linija (page) + widgeti/servisi (~150)

---

### 9. settings_page.dart - 484 linija
**STATUS:** PRIHVATLJIVO (blizu granice)

**Šta izdvojiti (opciono):**
- Settings sections → `widgets/settings/settings_section_widget.dart`
- Settings tiles → `widgets/settings/setting_tile_widget.dart`

**Rezultat:** 484 → ~350 linija (page) + widgeti (~150)

---

### 10. analytics_page.dart - 430 linija
**STATUS:** PRIHVATLJIVO (blizu granice)

**Šta izdvojiti (opciono):**
- Chart widgets → već izdvojeno u `widgets/progress_chart.dart` ✓
- Analytics calculations → `services/analytics_service.dart`

**Rezultat:** 430 → ~300 linija (page) + servisi (~130)

---

## OK (<300 linija)

### 11-20. Ostali page-ovi
- plan_details_page.dart - 377 ✓
- admin_dashboard_page.dart - 339 ✓
- check_in_history_page.dart - 295 ✓
- workout_history_page.dart - 290 ✓
- login_page.dart - 282 ✓
- payment_page.dart - 260 ✓
- weigh_in_page.dart - 246 ✓
- onboarding_page.dart - 215 ✓
- ai_messages_page.dart - 201 ✓
- splash_page.dart - 93 ✓

---

## SUMARNI PRIORITET RASTERECENJA

1. **workout_runner_page.dart** (1062) - HITNO
2. **plan_builder_page.dart** (927) - HITNO  
3. **dashboard_page.dart** (838) - VISOK
4. **profile_page.dart** (757) - VISOK
5. **calendar_page.dart** (609) - SREDNJI
6. **workout_edit_page.dart** (594) - SREDNJI
7. **check_in_page.dart** (551) - SREDNJI
8. **exercise_selection_page.dart** (488) - NIZAK
9. **settings_page.dart** (484) - NIZAK
10. **analytics_page.dart** (430) - NIZAK

---

## PRAVILA RASTERECENJA

### Widget extraction:
- `_build*` metode → `widgets/{section}/{name}_widget.dart`
- Svi builderi sa više od 50 linija → izdvoji

### Service extraction:
- `_load*`, `_fetch*`, `_save*`, `_delete*`, `_create*`, `_update*` → `services/{name}_service.dart`
- API calls → `services/{domain}_api_service.dart`
- Validation logic → `services/{domain}_validation_service.dart`
- Business logic → `services/{domain}_business_service.dart`

### Utility extraction:
- Helper funkcije (`_get*`, `_format*`, `_calculate*`) → `utils/{name}_utils.dart`
- Constants → `constants/{name}_constants.dart`

### Modal extraction:
- `_show*` dialogs → `modals/{name}_modal.dart` ili `widgets/{section}/{name}_dialog.dart`

