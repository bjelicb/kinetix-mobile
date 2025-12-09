# KINETIX MOBILE - MASTERPLAN V2
## Faza 2: Sync Improvements & Admin Dashboard

**Prioritet:** 🟡 **VISOKI**  
**Status:** ❌ Nije početo  
**Timeline:** 2-3 dana

> **FOKUS:** Poboljšanja sync mehanizma i admin dashboard funkcionalnosti.

---

## ⚠️ **KRITIČNA PRAVILA - MORA SE POŠTOVATI:**

### **1. NE TRPATI SVE U JEDAN FILE:**
- ❌ **ZABRANJENO:** Sva checkbox logika u `workout_runner_page.dart` (1000+ linija)
- ✅ **DOBRO:** Odvojiti:
  - `exercise_checkbox_widget.dart` - Checkbox widget za vežbu
  - `workout_timer_widget.dart` - Timer widget
  - `workout_set_item.dart` - Set item widget (već postoji, koristiti)
  - `fast_completion_dialog.dart` - Dialog za brz checkout warning

**Pravilo:** `workout_runner_page.dart` treba biti max 300 linija. Sve ostalo u widgete.

### **2. UX WORLD-CLASS:**
- ✅ Checkbox completion mora imati **smooth animation**
- ✅ Fast completion poruka mora biti **humoristična i friendly** (ne agresivna)
- ✅ Active plan validation - **jasna poruka** ako plan nije aktivan
- ✅ Koristiti **NeonButton**, **GradientCard**, **Glassmorphism** (već postoje)

### **3. OFFLINE-FIRST UX:**
- ✅ Check-in queue mora raditi **potpuno offline**
- ✅ Queue indicator mora biti **vizuelno jasno vidljiv**
- ✅ Sync status mora biti **real-time** (Riverpod provider)

---

## 📝 **PREPORUČENI REDOSLED IMPLEMENTACIJE (Za Plan Mode):**

**Agent može raditi u bilo kom redosledu, ali OVO JE OPTIMALNO:**

### **FAZA A - Core Functionality (KRITIČNO - Mora prvo):**
1. **2.5 Checkbox Completion** - **PRVO** (core funkcionalnost ne radi bez ovoga)
2. **2.6 Fast Completion Validation** - direktno povezano sa checkbox completion
3. **2.7 Active Plan Validation** - **KRITIČNO** (check-in flow zavisi od ovoga)

### **FAZA B - Utilities (Osnova):**
4. **2.9 Timezone Handling** - **PRVO nakon core** (koristi se u validacijama)
   - Kreiraj `DateUtils` klasu
   - Plan expiration, check-in validation koriste ovo

### **FAZA C - Plan Management:**
5. **2.8 Plan Expiration UI Handling** - koristi DateUtils
6. **2.10 Check-in vs Workout Date Validation** - koristi DateUtils

### **FAZA D - Check-in Edge Cases:**
7. **2.11 Check-in Mandatory Enforcement** - kompleksniji, zavisi od plan validation

### **FAZA E - Sync Improvements:**
8. **2.1 Retry Logic** - nezavisan
9. **2.2 Better Error Handling** - povezano sa retry logic

### **FAZA F - Admin Dashboard:**
10. **2.3 Admin Check-ins Management** - nezavisan
11. **2.4 Admin Analytics** - nezavisan
12. **2.4.1 Plan Builder/Editor** - **KRITIČNO** 🔴 (mora se implementirati)

**Napomena:** Agent može da grupiše zadatke kako mu ima smisla, ali **PRVO uvek core functionality (2.5, 2.7)** jer bez njih aplikacija ne radi kako treba.

---

## 📋 **ZADACI:**

### **2.1 Retry Logic za Failed Sync** 🟡

**Zahtevi:**
- [ ] Retry logika sa eksponencijalnim backoff-om
- [ ] Max retries: 3 puta
- [ ] Retry delay: 1s, 2s, 4s
- [ ] Retry samo za network greške (ne za 401, 403)
- [ ] Queue failed sync-ove za retry pri sledećem pokretanju

**Fajlovi:**
- `lib/services/sync_manager.dart` - **IZMENA**

---

### **2.2 Better Error Handling** 🟡

**Zahtevi:**
- [ ] Specific error messages za različite error tipove
- [ ] Error logging sa context-om
- [ ] Partial success handling
- [ ] Error notification UI (snackbar)

**Fajlovi:**
- `lib/services/sync_manager.dart` - **IZMENA**
- `lib/presentation/widgets/sync_status_indicator.dart` - **IZMENA**

---

### **2.3 Admin Dashboard - Check-ins Management** 🟡

**Zahtevi:**
- [ ] CheckinsManagementCard widget
- [ ] Lista svih check-ins sa filterima
- [ ] Check-in details modal
- [ ] Delete check-in funkcionalnost
- [ ] Export check-ins

**Fajlovi:**
- `lib/presentation/pages/admin_dashboard/widgets/checkins_management_card.dart` - **NOVO**
- `lib/presentation/pages/admin_dashboard/modals/checkin_details_modal.dart` - **NOVO**

---

### **2.4 Admin Dashboard - Analytics** 🟡

**Zahtevi:**
- [ ] AnalyticsCard widget
- [ ] User growth chart
- [ ] Workout completion rates chart
- [ ] Check-in stats chart
- [ ] Trainer performance metrics

**Fajlovi:**
- `lib/presentation/pages/admin_dashboard/widgets/analytics_card.dart` - **NOVO**
- `lib/data/datasources/remote_data_source.dart` - **IZMENA** (dodati analytics metode)

---

### **2.4.1 Admin Dashboard - Plan Builder/Editor** 🔴 **KRITIČNO**

**Zadatak:**
Kompletan Plan Builder/Editor za kreiranje i editovanje planova sa workout days i exercise-ima

**Zahtevi:**
- [ ] Plan Builder page (full-screen editor)
- [ ] Dodavanje/uklanjanje workout days (1-7 dana)
- [ ] Dodavanje/uklanjanje exercise-a u workout day
- [ ] Counter komponente za sets, reps, rest time
- [ ] Realni primeri vežbi (suggestions)
- [ ] Markiranje rest days
- [ ] Exercise notes polje
- [ ] Video URL placeholder (Coming soon funkcionalnost)
- [ ] Preview plan-a pre čuvanja
- [ ] Validacija (min 1 workout day, exercise mora imati name)
- [ ] Integracija sa backend API (createPlan/updatePlan sa workouts array)

**Fajlovi:**
- `lib/presentation/pages/admin_dashboard/plan_builder_page.dart` - **NOVO** (main page)
- `lib/presentation/pages/admin_dashboard/widgets/workout_day_editor.dart` - **NOVO** (workout day card)
- `lib/presentation/pages/admin_dashboard/widgets/exercise_editor.dart` - **NOVO** (exercise item)
- `lib/presentation/pages/admin_dashboard/widgets/exercise_counter.dart` - **NOVO** (sets/reps/rest counter)
- `lib/presentation/pages/admin_dashboard/widgets/exercise_suggestions.dart` - **NOVO** (exercise suggestions)
- `lib/presentation/pages/admin_dashboard/widgets/plan_preview_dialog.dart` - **NOVO** (preview modal)

**Implementacija:**

```dart
// plan_builder_page.dart - Main structure
class PlanBuilderPage extends ConsumerStatefulWidget {
  final Map<String, dynamic>? existingPlan; // null ako kreiranje, popunjeno ako edit
  final String? trainerId; // Trainer ID (required za create)
  final List<User> trainers; // Lista trenera za dropdown
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(existingPlan != null ? 'Edit Plan' : 'Create New Plan'),
        actions: [
          IconButton(
            icon: Icon(Icons.preview_rounded),
            onPressed: _showPreview,
            tooltip: 'Preview Plan',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Basic Info Section
            _buildBasicInfoSection(),
            
            SizedBox(height: 24),
            
            // Workout Days Section
            _buildWorkoutDaysSection(),
            
            SizedBox(height: 24),
            
            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBasicInfoSection() {
    return GradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Basic Information', style: TextStyle(...)),
          SizedBox(height: 16),
          TextField(controller: _nameController, label: 'Plan Name *'),
          TextField(controller: _descriptionController, label: 'Description'),
          DropdownButtonFormField<String>(
            value: _selectedDifficulty,
            items: ['BEGINNER', 'INTERMEDIATE', 'ADVANCED'].map(...),
            onChanged: (value) => setState(() => _selectedDifficulty = value),
          ),
          DropdownButtonFormField<String>(
            value: _selectedTrainerId ?? trainerId,
            items: trainers.map(...),
            onChanged: (value) => setState(() => _selectedTrainerId = value),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWorkoutDaysSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Workout Days (${_workoutDays.length}/7)', style: TextStyle(...)),
            NeonButton(
              text: 'Add Day',
              icon: Icons.add_rounded,
              onPressed: _workoutDays.length < 7 ? _addWorkoutDay : null,
            ),
          ],
        ),
        SizedBox(height: 16),
        ..._workoutDays.asMap().entries.map((entry) {
          final index = entry.key;
          final day = entry.value;
          return WorkoutDayEditor(
            key: ValueKey('day-${day.dayOfWeek}'),
            dayOfWeek: day.dayOfWeek,
            initialData: day,
            onDelete: () => _removeWorkoutDay(index),
            onUpdate: (updatedDay) => _updateWorkoutDay(index, updatedDay),
          );
        }),
      ],
    );
  }
}

// workout_day_editor.dart
class WorkoutDayEditor extends StatelessWidget {
  final int dayOfWeek; // 1-7
  final WorkoutDayData dayData;
  final VoidCallback onDelete;
  final ValueChanged<WorkoutDayData> onUpdate;
  
  // Checkbox za rest day
  // Workout name field
  // Lista exercise-a
  // Add Exercise button
  // Delete day button
}

// exercise_editor.dart
class ExerciseEditor extends StatelessWidget {
  final ExerciseData exercise;
  final VoidCallback onDelete;
  final ValueChanged<ExerciseData> onUpdate;
  
  // Exercise name field (sa suggestions)
  // Sets counter
  // Reps input (može biti "10-12" ili broj)
  // Rest seconds counter
  // Notes field
  // Video URL field (disabled, sa "Coming soon" badge)
}

// exercise_counter.dart
class ExerciseCounter extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  
  // - button, value display, + button
  // Neon/Cyber styling
}
```

**Realni primeri vežbi (suggestions):**
```dart
final exerciseSuggestions = [
  // Upper Body
  'Bench Press', 'Incline Bench Press', 'Push-ups', 'Dumbbell Flyes',
  'Shoulder Press', 'Lateral Raises', 'Bent Over Rows', 'Pull-ups',
  'Lat Pulldown', 'Bicep Curls', 'Tricep Dips', 'Overhead Tricep Extension',
  
  // Lower Body
  'Squats', 'Leg Press', 'Romanian Deadlifts', 'Leg Curls',
  'Leg Extensions', 'Calf Raises', 'Lunges', 'Bulgarian Split Squats',
  
  // Core
  'Plank', 'Crunches', 'Russian Twists', 'Mountain Climbers',
  'Dead Bug', 'Bird Dog', 'Leg Raises',
  
  // Cardio
  'Treadmill Running', 'Rowing Machine', 'Bike', 'Elliptical',
  'HIIT Circuit', 'Sprint Intervals',
];
```

**UI/UX zahtevi:**
- ✅ Cyber/Futuristic tema (Glassmorphism, Neon glow)
- ✅ Smooth animations pri dodavanju/uklanjanju
- ✅ Haptic feedback
- ✅ Drag-to-reorder za exercise-e (optional, bonus)
- ✅ Validation messages (friendly, ne agresivne)
- ✅ Loading states pri čuvanju
- ✅ Success/Error snackbars

**Workflow:**
1. Admin klikne "Create Plan" ili "Edit Plan" u PlanManagementCard
2. Otvara se Plan Builder page (full-screen editor)
3. Popunjava osnovne info (name, description, difficulty, trainer)
4. Dodaje workout days (1-7) - klikom na "Add Workout Day" button
5. Za svaki workout day:
   - Ime workout-a (npr. "Push Day", "Pull Day", "Chest & Triceps")
   - Markira rest day checkbox (ako je rest day)
   - Dodaje exercise-e (klikom na "Add Exercise" button)
6. Za svaki exercise:
   - Bira ime (sa suggestions dropdown - realni primeri)
   - Postavlja sets (counter: 1-10, default: 3)
   - Postavlja reps (input: može "10-12" ili broj, default: "10")
   - Postavlja rest time (counter: 0-300 sekundi, step 15s, default: 60s)
   - Dodaje notes (opciono)
   - Video URL (disabled, sa badge "Coming soon")
7. Preview plan-a (klikom na "Preview" button - modal sa pregledom)
8. Save plan (klikom na "Save Plan" - poziva createPlan/updatePlan sa workouts array)
9. Refresh plan lista u admin dashboard-u

**Realni primeri za workout day names:**
- Upper Body: "Push Day", "Pull Day", "Chest & Triceps", "Back & Biceps"
- Lower Body: "Leg Day", "Quad Focus", "Hamstring & Glutes", "Full Legs"
- Full Body: "Full Body A", "Full Body B", "Strength Day"
- Cardio: "Cardio Day", "HIIT Session", "Endurance Training"
- Rest: Automatski "Rest Day" kada se markira checkbox

**Realni primeri exercise kombinacija:**
```dart
// Push Day Template
- Bench Press (4 sets x 6-8 reps, 90s rest)
- Incline Dumbbell Press (3 sets x 8-10 reps, 60s rest)
- Overhead Press (3 sets x 8-10 reps, 60s rest)
- Lateral Raises (3 sets x 12-15 reps, 45s rest)
- Tricep Dips (3 sets x 10-12 reps, 45s rest)

// Pull Day Template
- Pull-ups (4 sets x 6-10 reps, 90s rest)
- Bent Over Rows (3 sets x 8-10 reps, 60s rest)
- Lat Pulldown (3 sets x 10-12 reps, 60s rest)
- Bicep Curls (3 sets x 12-15 reps, 45s rest)
- Hammer Curls (3 sets x 12-15 reps, 45s rest)

// Leg Day Template
- Barbell Squats (4 sets x 6-8 reps, 120s rest)
- Romanian Deadlifts (3 sets x 8-10 reps, 90s rest)
- Leg Press (3 sets x 10-12 reps, 60s rest)
- Leg Curls (3 sets x 12-15 reps, 45s rest)
- Calf Raises (4 sets x 15-20 reps, 30s rest)
```

**Backend Integration:**
```dart
// plan_builder_page.dart
Future<void> _savePlan() async {
  final workouts = _workoutDays.map((day) => {
    'dayOfWeek': day.dayOfWeek,
    'isRestDay': day.isRestDay,
    'name': day.name,
    'exercises': day.exercises.map((ex) => {
      'name': ex.name,
      'sets': ex.sets,
      'reps': ex.reps.toString(),
      'restSeconds': ex.restSeconds,
      'notes': ex.notes,
      // videoUrl: ex.videoUrl, // Ne šalje se jer nije implementirano
    }).toList(),
    'estimatedDuration': day.estimatedDuration,
    'notes': day.notes,
  }).toList();
  
  final planData = {
    'name': _nameController.text,
    'description': _descriptionController.text,
    'difficulty': _selectedDifficulty,
    'workouts': workouts,
    'isTemplate': false,
  };
  
  if (_existingPlan != null) {
    await ref.read(adminControllerProvider.notifier).updatePlan(
      _existingPlan!['_id'],
      planData,
    );
  } else {
    await ref.read(adminControllerProvider.notifier).createPlan(planData);
  }
}
```

**Video URL Placeholder:**
```dart
// exercise_editor.dart
TextField(
  controller: _videoUrlController,
  enabled: false, // Disabled dok ne implementiramo
  decoration: InputDecoration(
    labelText: 'Video URL',
    prefixIcon: Icon(Icons.video_library_rounded, color: AppColors.textSecondary),
    suffixIcon: Container(
      margin: EdgeInsets.only(right: 8),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded, size: 12, color: AppColors.warning),
          SizedBox(width: 4),
          Text(
            'Coming Soon',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.warning,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
    helperText: 'Video integration will be available in future update',
    helperStyle: TextStyle(
      fontSize: 11,
      color: AppColors.textSecondary.withValues(alpha: 0.7),
      fontStyle: FontStyle.italic,
    ),
  ),
)
```

**Integracija sa postojećim modals:**
```dart
// create_plan_modal.dart - Ažurirati da otvara Plan Builder umesto direktno create
onPressed: () async {
  Navigator.pop(context); // Zatvori modal
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PlanBuilderPage(
        existingPlan: null,
        trainerId: selectedTrainerId,
        trainers: trainers,
      ),
    ),
  ).then((refresh) {
    // Refresh plan lista ako je plan kreiran
    if (refresh == true && mounted) {
      onCreated();
    }
  });
}

// edit_plan_modal.dart - Ažurirati da otvara Plan Builder
onPressed: () async {
  Navigator.pop(context); // Zatvori modal
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PlanBuilderPage(
        existingPlan: plan,
        trainerId: plan['trainerId']?.toString(),
        trainers: trainers,
      ),
    ),
  ).then((refresh) {
    // Refresh plan lista ako je plan ažuriran
    if (refresh == true && mounted) {
      onUpdated();
    }
  });
}

// plan_management_card.dart - Ažurirati edit button
onPlanTap: (plan) {
  // Umesto edit_plan_modal, otvori Plan Builder
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PlanBuilderPage(
        existingPlan: plan,
        trainerId: plan['trainerId']?.toString(),
        trainers: trainers,
      ),
    ),
  ).then((refresh) {
    if (refresh == true) {
      _loadPlans(); // Refresh lista
    }
  });
}
```

**Counter Komponenta (sets/reps/rest):**
```dart
// exercise_counter.dart
class ExerciseCounter extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            // Decrease button
            InkWell(
              onTap: value > min ? () => onChanged(value - 1) : null,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: value > min 
                      ? AppColors.surface1 
                      : AppColors.surface1.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: value > min
                        ? AppColors.primary
                        : AppColors.textSecondary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.remove_rounded,
                  color: value > min
                      ? AppColors.primary
                      : AppColors.textSecondary.withValues(alpha: 0.3),
                  size: 20,
                ),
              ),
            ),
            SizedBox(width: 16),
            // Value display
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.primaryEnd.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                value.toString(),
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: 16),
            // Increase button
            InkWell(
              onTap: value < max ? () => onChanged(value + 1) : null,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: value < max
                      ? AppColors.surface1
                      : AppColors.surface1.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: value < max
                        ? AppColors.primary
                        : AppColors.textSecondary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: value < max
                      ? AppColors.primary
                      : AppColors.textSecondary.withValues(alpha: 0.3),
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
```

**Workout Day Editor - Struktura:**
```dart
// workout_day_editor.dart
class WorkoutDayEditor extends StatefulWidget {
  final int dayOfWeek;
  final WorkoutDayData? initialData;
  final VoidCallback onDelete;
  final ValueChanged<WorkoutDayData> onUpdate;
  
  @override
  Widget build(BuildContext context) {
    return GradientCard(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header sa day number i delete button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Day ${dayOfWeek}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded),
                color: AppColors.error,
                onPressed: onDelete,
              ),
            ],
          ),
          
          // Rest Day Checkbox
          Row(
            children: [
              Checkbox(
                value: _isRestDay,
                onChanged: (value) {
                  setState(() => _isRestDay = value ?? false);
                  _updateDayData();
                },
              ),
              Text('Rest Day'),
            ],
          ),
          
          if (!_isRestDay) ...[
            // Workout Name
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Workout Name *',
                hintText: 'e.g., Push Day, Pull Day, Leg Day',
              ),
            ),
            
            // Exercises List
            ListView.builder(
              shrinkWrap: true,
              itemCount: _exercises.length,
              itemBuilder: (context, index) {
                return ExerciseEditor(
                  exercise: _exercises[index],
                  onDelete: () => _removeExercise(index),
                  onUpdate: (exercise) => _updateExercise(index, exercise),
                );
              },
            ),
            
            // Add Exercise Button
            NeonButton(
              text: 'Add Exercise',
              icon: Icons.add_rounded,
              onPressed: _addExercise,
            ),
          ],
        ],
      ),
    );
  }
}
```

**Exercise Editor - Struktura:**
```dart
// exercise_editor.dart
class ExerciseEditor extends StatefulWidget {
  final ExerciseData? initialData;
  final VoidCallback onDelete;
  final ValueChanged<ExerciseData> onUpdate;
  
  @override
  Widget build(BuildContext context) {
    return GradientCard(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header sa delete button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Exercise',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded),
                color: AppColors.textSecondary,
                onPressed: onDelete,
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Exercise Name sa Suggestions
          ExerciseSuggestionsDropdown(
            initialValue: _exerciseName,
            onChanged: (value) {
              setState(() => _exerciseName = value);
              _updateExercise();
            },
          ),
          
          SizedBox(height: 16),
          
          // Sets, Reps, Rest Row
          Row(
            children: [
              Expanded(
                child: ExerciseCounter(
                  label: 'Sets',
                  value: _sets,
                  min: 1,
                  max: 10,
                  onChanged: (value) {
                    setState(() => _sets = value);
                    _updateExercise();
                  },
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reps', style: TextStyle(...)),
                    TextField(
                      controller: _repsController,
                      decoration: InputDecoration(
                        hintText: '10-12 or 10',
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ExerciseCounter(
                  label: 'Rest (sec)',
                  value: _restSeconds,
                  min: 0,
                  max: 300,
                  step: 15, // Increment by 15 seconds
                  onChanged: (value) {
                    setState(() => _restSeconds = value);
                    _updateExercise();
                  },
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Notes
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: 'Notes (optional)',
              hintText: 'e.g., Focus on form, RPE 7',
            ),
            maxLines: 2,
          ),
          
          SizedBox(height: 12),
          
          // Video URL (Coming Soon)
          TextField(
            controller: _videoUrlController,
            enabled: false,
            decoration: InputDecoration(
              labelText: 'Video URL',
              prefixIcon: Icon(Icons.video_library_rounded),
              suffixIcon: ComingSoonBadge(),
              helperText: 'Video integration coming soon',
            ),
          ),
        ],
      ),
    );
  }
}
```

**Exercise Suggestions Dropdown:**
```dart
// exercise_suggestions.dart
class ExerciseSuggestionsDropdown extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String> onChanged;
  
  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: initialValue ?? ''),
      optionsBuilder: (TextEditingValue value) {
        if (value.text.isEmpty) {
          return exerciseSuggestions;
        }
        return exerciseSuggestions.where((exercise) {
          return exercise.toLowerCase().contains(value.text.toLowerCase());
        });
      },
      onSelected: onChanged,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Exercise Name *',
            hintText: 'Type to search or enter custom name',
            prefixIcon: Icon(Icons.fitness_center_rounded),
            suffixIcon: Icon(Icons.arrow_drop_down_rounded),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    leading: Icon(Icons.fitness_center_rounded, size: 20),
                    title: Text(option),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
```

**Testovi:**
- [ ] Test kreiranja plana sa workout days
- [ ] Test dodavanja/uklanjanja workout days
- [ ] Test dodavanja/uklanjanja exercise-a
- [ ] Test counter komponenti (sets, reps, rest)
- [ ] Test rest day toggle
- [ ] Test validacije (empty plan, exercise bez name)
- [ ] Test editovanja postojećeg plana
- [ ] Test preview funkcionalnosti
- [ ] Test save sa backend API-jem

---

### **2.5 Checkbox Completion Implementation** 🔴 **KRITIČNO**

**Zadatak:**
Implementirati checkbox completion na nivou VEŽBE (exercise level) sa automatskim označavanjem svih set-ova u toj vežbi

**Zahtevi:**
- [ ] Dodati checkbox na nivou VEŽBE (u `_buildExerciseCard`)
- [ ] Klik na checkbox vežbe → automatski toggle SVE set-ove u toj vežbi
- [ ] Ako je vežba unchecked → check sve set-ove
- [ ] Ako je vežba checked → uncheck sve set-ove
- [ ] Vežba se smatra completed ako su SVI set-ovi completed
- [ ] Immediate update u Isar DB (optimistic UI update)
- [ ] Immediate push na server (ako ima internet, background)
- [ ] Ne čekati server response za UI update (optimistic update)
- [ ] Error handling za failed update (rollback optimistic update)
- [ ] Haptic feedback pri checkbox toggle

**Fajlovi:**
- `lib/presentation/pages/workout_runner_page.dart` - **IZMENA**
- `lib/data/repositories/workout_repository.dart` - **IZMENA** (dodati toggleExerciseCompletion metodu)

**Implementacija:**

```dart
// workout_runner_page.dart
bool _isExerciseCompleted(Exercise exercise) {
  // Vežba je completed ako su SVI set-ovi completed
  if (exercise.sets.isEmpty) return false;
  return exercise.sets.every((set) => set.isCompleted);
}

void _toggleExerciseCompletion(int exerciseIndex) async {
  AppHaptic.selection();
  
  final workout = ref.read(workoutControllerProvider(widget.workoutId));
  if (workout == null) return;
  
  final exercise = workout.exercises[exerciseIndex];
  final isCurrentlyCompleted = _isExerciseCompleted(exercise);
  final newCompletedState = !isCurrentlyCompleted;
  
  // Optimistic UI update - toggle sve set-ove
  setState(() {
    for (final set in exercise.sets) {
      set.isCompleted = newCompletedState;
    }
  });
  
  try {
    // Update u Isar DB - toggle sve set-ove u vežbi
    await ref.read(workoutRepositoryProvider).toggleExerciseCompletion(
      workoutId: widget.workoutId,
      exerciseId: exercise.id,
      isCompleted: newCompletedState,
    );
    
    // Push na server (background, ne blokira UI)
    ref.read(syncManagerProvider).pushChanges();
  } catch (e) {
    // Rollback optimistic update
    setState(() {
      for (final set in exercise.sets) {
        set.isCompleted = isCurrentlyCompleted;
      }
    });
    
    // Prikaži error poruku
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error updating exercise: $e')),
    );
  }
}

// U _buildExerciseCard, dodati checkbox pre Exercise Name:
Row(
  children: [
    // Exercise Checkbox (PREČICA)
    GestureDetector(
      onTap: () => _toggleExerciseCompletion(exerciseIndex),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: _isExerciseCompleted(exercise)
              ? AppColors.success
              : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: _isExerciseCompleted(exercise)
                ? AppColors.success
                : AppColors.textSecondary,
            width: 2,
          ),
        ),
        child: _isExerciseCompleted(exercise)
            ? const Icon(
                Icons.check_rounded,
                color: AppColors.textPrimary,
                size: 20,
              )
            : null,
      ),
    ),
    const SizedBox(width: 12),
    Expanded(
      child: Text(
        exercise.name,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    ),
  ],
)
```

**Bonus: Set-ovi i dalje mogu imati individual checkbox-ove** (ako želiš detaljniju kontrolu):
- Korisnik može da klikne na vežbi (prečica) → označi sve set-ove
- ILI može da označava set-ove pojedinačno
- Vežba checkbox automatski se update-uje kada su svi set-ovi completed

**Testovi:**
- [ ] Test checkbox toggle na vežbi (toggle sve set-ove)
- [ ] Test da se vežba smatra completed kad su svi set-ovi completed
- [ ] Test immediate Isar update
- [ ] Test optimistic UI update
- [ ] Test error handling (rollback)
- [ ] Test da svi set-ovi u vežbi se toggle-uju odjednom

---

### **2.6 Fast Completion Validation** 🟡

**Zadatak:**
Validirati da li je vežba prebrzo završena i prikazati humorističnu poruku

**Zahtevi:**
- [ ] Snimiti `workoutStartTime` kada se otvori workout (prvi put)
- [ ] Pri checkbox toggle VEŽBE (prva vežba) proveriti vreme
- [ ] Ako prva vežba završena < 30 sekundi → prikazati poruku
- [ ] Poruka: "Mnogo si brzo ovo uradio, nadam se da stvarno jesi 😉"
- [ ] Validacija samo za prvu vežbu (ne spam-ovati)
- [ ] Prikazati kao snackbar

**Fajlovi:**
- `lib/presentation/pages/workout_runner_page.dart` - **IZMENA**

**Implementacija:**

```dart
// workout_runner_page.dart
DateTime? _workoutStartTime;
bool _hasShownFastCompletionMessage = false;

@override
void initState() {
  super.initState();
  _workoutStartTime = DateTime.now(); // Snimiti start time
}

void _toggleExerciseCompletion(int exerciseIndex) async {
  // ... existing toggle code ...
  
  // Provera za brz checkout (samo za prvu vežbu, samo jednom)
  if (!_hasShownFastCompletionMessage && 
      exerciseIndex == 0 && 
      newCompletedState == true) {
    
    final duration = DateTime.now().difference(_workoutStartTime!);
    
    if (duration.inSeconds < 30) {
      _hasShownFastCompletionMessage = true;
      
      // Prikazati humorističnu poruku
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mnogo si brzo ovo uradio, nadam se da stvarno jesi 😉'),
          duration: Duration(seconds: 4),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }
  
  // ... existing update code ...
}
```

**Testovi:**
- [ ] Test fast completion (< 30s)
- [ ] Test normal completion (> 30s)
- [ ] Test da se poruka prikazuje samo jednom
- [ ] Test da se proverava samo prvi set

---

### **2.7 Active Plan Validation for Check-in** 🔴 **KRITIČNO**

**Zadatak:**
Proveriti da li plan aktivan pre zahteva za check-in

**Zahtevi:**
- [ ] Proširiti `_shouldRequireCheckIn()` u app_router.dart
- [ ] Proveriti da li postoji aktivan plan (planStartDate <= today <= planEndDate)
- [ ] Ako plan nije aktivan → ne zahtevati check-in
- [ ] Ako plan nije aktivan → prikazati poruku na Dashboard umesto workout-a
- [ ] Dodati helper metodu u LocalDataSource: `getActivePlan()`

**Fajlovi:**
- `lib/core/routing/app_router.dart` - **IZMENA** (_shouldRequireCheckIn metoda)
- `lib/data/datasources/local_data_source.dart` - **IZMENA** (dodati getActivePlan metodu)
- `lib/presentation/pages/dashboard_page.dart` - **IZMENA** (dodati proveru aktivnog plana)

**Implementacija:**

```dart
// local_data_source.dart
Future<Plan?> getActivePlan() async {
  final clientProfile = await getClientProfile();
  if (clientProfile == null) return null;
  
  final now = DateTime.now();
  now.setHours(0, 0, 0, 0);
  
  // Proveri planHistory za aktivni plan
  if (clientProfile.planHistory != null) {
    for (final entry in clientProfile.planHistory!) {
      final startDate = DateTime.parse(entry['planStartDate']);
      final endDate = DateTime.parse(entry['planEndDate']);
      startDate.setHours(0, 0, 0, 0);
      endDate.setHours(23, 59, 59, 999);
      
      if (now.isAfter(startDate) && now.isBefore(endDate)) {
        final planId = entry['planId'];
        return await getPlanById(planId);
      }
    }
  }
  
  // Fallback na currentPlanId (backward compatibility)
  if (clientProfile.currentPlanId != null) {
    final startDate = clientProfile.planStartDate;
    final endDate = clientProfile.planEndDate;
    
    if (startDate != null && endDate != null) {
      final start = DateTime.parse(startDate);
      final end = DateTime.parse(endDate);
      start.setHours(0, 0, 0, 0);
      end.setHours(23, 59, 59, 999);
      
      if (now.isAfter(start) && now.isBefore(end)) {
        return await getPlanById(clientProfile.currentPlanId!);
      }
    }
  }
  
  return null; // Nema aktivnog plana
}

// app_router.dart
Future<bool> _shouldRequireCheckIn(User? user) async {
  // ... existing checks ...
  
  // PROVERA AKTIVNOG PLANA
  final localDataSource = LocalDataSource();
  final activePlan = await localDataSource.getActivePlan();
  
  if (activePlan == null) {
    // Nema aktivnog plana → ne zahtevati check-in
    return false;
  }
  
  // Check if user has workouts scheduled for today
  final todayWorkouts = await localDataSource.getTodayWorkouts();
  
  // ... rest of existing logic ...
}

// dashboard_page.dart
Future<void> _checkActivePlan() async {
  final localDataSource = LocalDataSource();
  final activePlan = await localDataSource.getActivePlan();
  
  if (activePlan == null) {
    // Prikazati poruku umesto workout-a
    setState(() {
      _hasActivePlan = false;
    });
  } else {
    setState(() {
      _hasActivePlan = true;
    });
  }
}
```

**Testovi:**
- [ ] Test check-in requirement sa aktivnim planom
- [ ] Test check-in requirement bez aktivnog plana
- [ ] Test check-in requirement sa isteklim planom
- [ ] Test check-in requirement sa budućim planom

---

### **2.8 Plan Expiration UI Handling** 🟡

**Zadatak:**
Prikazati korisničku poruku kada plan ističe ili je istekao

**Zahtevi:**
- [ ] Na Dashboard-u prikazati warning ako plan ističe za < 2 dana
- [ ] Prikazati poruku ako plan već istekao: "Your plan has expired. Contact your trainer for a new plan."
- [ ] Disable workout logging ako plan istekao (samo view mode)
- [ ] Prikazati plan expiration date u Plan Details

**Fajlovi:**
- `lib/presentation/pages/dashboard_page.dart` - **IZMENA**
- `lib/presentation/widgets/plan_expiration_warning.dart` - **NOVO**

---

### **2.9 Timezone Handling** 🟡

**Zadatak:**
Konzistentno rukovanje sa timezone-ovima na mobilnoj strani

**Zahtevi:**
- [ ] Svi datumi se prikazuju u korisnikovom lokalnom timezone-u
- [ ] Sync datumi se konvertuju u UTC pre slanja na server
- [ ] Plan start/end datumi se prikazuju u korisnikovom timezone-u
- [ ] Workout datumi se normalizuju na start of day u lokalnom timezone-u

**Fajlovi:**
- `lib/core/utils/date_utils.dart` - **NOVO**

**Implementacija:**

```dart
// date_utils.dart
class DateUtils {
  /// Normalize date to start of day in local timezone
  static DateTime normalizeToStartOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
  
  /// Normalize date to end of day in local timezone
  static DateTime normalizeToEndOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }
  
  /// Check if date is today (in local timezone)
  static bool isToday(DateTime date) {
    final today = normalizeToStartOfDay(DateTime.now());
    final checkDate = normalizeToStartOfDay(date);
    return today.isAtSameMomentAs(checkDate);
  }
  
  /// Check if date range is active (start <= today <= end)
  static bool isDateRangeActive(DateTime startDate, DateTime endDate) {
    final today = normalizeToStartOfDay(DateTime.now());
    final start = normalizeToStartOfDay(startDate);
    final end = normalizeToEndOfDay(endDate);
    
    return (today.isAfter(start) || today.isAtSameMomentAs(start)) &&
           (today.isBefore(end) || today.isAtSameMomentAs(end));
  }
  
  /// Convert local date to UTC for API
  static DateTime toUtc(DateTime localDate) {
    return localDate.toUtc();
  }
  
  /// Convert UTC date from API to local
  static DateTime fromUtc(DateTime utcDate) {
    return utcDate.toLocal();
  }
}
```

**Testovi:**
- [ ] Test date normalizacije
- [ ] Test timezone konverzije
- [ ] Test provere aktivnog plana

---

### **2.10 Check-in vs Workout Date Validation** 🟡

**Zadatak:**
Validirati da check-in i workout log imaju isti datum

**Zahtevi:**
- [ ] Pri kreiranju check-in-a proveriti da li postoji workout log za taj dan
- [ ] Ako check-in i workout log nisu istog datuma → warning (ali ne blokirati)
- [ ] Prikazati warning: "Check-in date doesn't match workout date"

**Fajlovi:**
- `lib/presentation/pages/check_in_page.dart` - **IZMENA**

---

### **2.11 Check-in Mandatory Enforcement Edge Cases** 🟡

**Zadatak:**
Rukovanje edge case-ovima za mandatory check-in

**Zahtevi:**
- [ ] Offline check-in queue (sačuvati photo lokalno, upload kasnije)
- [ ] Warning ako klijent završi workout bez check-in-a
- [ ] Validacija: check-in mora biti ISTOG DATUMA kao workout (ne dozvoliti check-in za juče)
- [ ] Ako klijent nema internet → queue check-in, dozvoliti pristup workout-u
- [ ] Sync check-in queue kada se konekcija vrati

**Fajlovi:**
- `lib/presentation/pages/check_in_page.dart` - **IZMENA**
- `lib/services/check_in_queue_service.dart` - **NOVO**
- `lib/core/routing/app_router.dart` - **IZMENA** (offline queue handling)

**Implementacija:**

```dart
// check_in_queue_service.dart
class CheckInQueueService {
  // Save check-in locally when offline
  Future<void> queueCheckIn(CheckInData data) async {
    final localDataSource = LocalDataSource();
    await localDataSource.saveQueuedCheckIn(data);
  }
  
  // Upload queued check-ins when online
  Future<void> syncQueuedCheckIns() async {
    final localDataSource = LocalDataSource();
    final queued = await localDataSource.getQueuedCheckIns();
    
    for (final checkIn in queued) {
      try {
        await remoteDataSource.uploadCheckIn(checkIn);
        await localDataSource.removeQueuedCheckIn(checkIn.id);
      } catch (e) {
        logger.e('Error syncing queued check-in: $e');
      }
    }
  }
}

// app_router.dart - _shouldRequireCheckIn
Future<bool> _shouldRequireCheckIn(User? user) async {
  // ... existing checks ...
  
  // Check if there's a queued check-in (offline mode)
  final queuedCheckIn = await checkInQueueService.hasQueuedCheckInForToday();
  if (queuedCheckIn) {
    return false; // Check-in je queued, dozvoli pristup
  }
  
  // ... rest of existing logic ...
}
```

**Testovi:**
- [ ] Test offline check-in queue
- [ ] Test sync queued check-ins
- [ ] Test warning za workout bez check-in
- [ ] Test validacije datuma (check-in mora biti danas)

---

## ✅ **CHECKLIST:**

**Organizacija (Agent može raditi u bilo kom redosledu, ali preporučeno redosled iznad):**

### **Core Functionality (KRITIČNO - Mora prvo):**
- [ ] **2.5 Checkbox Completion** - **PRVO** ⚠️ **KRITIČNO**
- [ ] **2.6 Fast Completion Validation** - direktno povezano
- [ ] **2.7 Active Plan Validation** - **KRITIČNO** ⚠️

### **Utilities:**
- [ ] **2.9 Timezone Handling (DateUtils)** - **PRVO nakon core** ⚠️

### **Plan Management:**
- [ ] **2.8 Plan Expiration UI Handling** - koristi DateUtils
- [ ] **2.10 Check-in vs Workout Date Validation** - koristi DateUtils

### **Check-in:**
- [ ] **2.11 Check-in Mandatory Enforcement Edge Cases**

### **Sync:**
- [ ] Retry logic implementiran
- [ ] Error handling poboljšan

### **Admin Dashboard:**
- [ ] Check-ins Management widget kreiran
- [ ] Analytics widget kreiran
- [ ] **Plan Builder/Editor implementiran** 🔴 **KRITIČNO**
  - [ ] Plan Builder page kreirana
  - [ ] Workout Day Editor widget
  - [ ] Exercise Editor widget
  - [ ] Exercise Counter komponenta (sets/reps/rest)
  - [ ] Exercise Suggestions dropdown
  - [ ] Plan Preview dialog
  - [ ] Integracija sa backend API (createPlan/updatePlan)
  - [ ] Validacija i error handling
  - [ ] Video URL placeholder sa "Coming soon" badge
  - [ ] Rest day toggle funkcionalnost

### **Final:**
- [ ] Testovi napisani (min 20 testova)
- [ ] Plan Builder testovi (min 15 testova)

**⚠️ VAŽNO:** Prvo uvek core functionality (checkbox + active plan validation). Zatim DateUtils. Ostalo može bilo kojim redosledom.

---

## 🔗 **VEZE:**

- **Status:** `docs/MOBILE_STATUS.md`
- **Prethodna Faza:** `docs/MOBILE_MASTERPLAN_V1.md`
- **Sledeća Faza:** `docs/MOBILE_MASTERPLAN_V3.md`

