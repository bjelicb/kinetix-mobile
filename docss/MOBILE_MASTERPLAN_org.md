# KINETIX MOBILE MASTERPLAN

**Role:** Lead Flutter Engineer & UX Designer
**Project:** Kinetix (Offline-First Gym App)
**Platform:** Flutter (iOS/Android)

---

## 1. Executive Summary
Kinetix is a high-performance, offline-first fitness application designed for serious trainees and coaches. It prioritizes speed, reliability, and a futuristic "Cyber" aesthetic. The core technical challenge is ensuring 100% offline availability with a robust synchronization engine that resolves conflicts with the server (NestJS).

---

## 2. Architecture: Clean Architecture + Riverpod
We will adhere to **Clean Architecture** principles to ensure separation of concerns, testability, and scalability.

### **Layer Breakdown**

#### **1. Presentation Layer (UI & State)**
- **Widgets:** Dumb components, purely for rendering.
- **Pages/Screens:** Scaffold containers that listen to Controllers/Providers.
- **Controllers (Riverpod Notifiers):** Handle UI logic, user input, and call UseCases.
- **State:** Immutable state classes (Freezed).

#### **2. Domain Layer (Business Logic)**
- **Entities:** Pure Dart classes (PODOs) representing core business objects.
- **Repositories (Interfaces):** Abstract definitions of data operations.
- **UseCases:** Single-responsibility classes encapsulating business rules (e.g., `LogSetUseCase`, `SyncDataUseCase`).

#### **3. Data Layer (Implementation)**
- **Data Sources:**
    - `LocalDataSource` (Isar): CRUD operations on local DB.
    - `RemoteDataSource` (Dio/Retrofit): API calls to NestJS.
- **Repositories (Implementation):** Orchestrates data flow between Local and Remote sources. Implements the Sync Logic here.
- **Models (DTOs):** JSON serializable classes (JsonSerializable) and Isar Collections.
- **Mappers:** Convert between DTOs, Isar Models, and Domain Entities.

---

## 3. Tech Stack & Dependencies

| Category | Package/Tool | Purpose |
| :--- | :--- | :--- |
| **Framework** | Flutter | Cross-platform UI |
| **State Management** | `flutter_riverpod`, `riverpod_annotation` | Global state, DI, Caching |
| **Routing** | `go_router` | Deep linking, Auth redirection |
| **Local DB** | `isar`, `isar_flutter_libs` | High-performance NoSQL, Offline storage |
| **Networking** | `dio`, `retrofit` | HTTP Client, Type-safe API calls |
| **Code Gen** | `build_runner`, `freezed`, `json_serializable` | Boilerplate reduction, Immutability |
| **UI/Charts** | `fl_chart`, `google_fonts` | Analytics, Typography |
| **Camera** | `camera`, `image_picker` | Check-in verification |
| **Utils** | `fpdart`, `uuid`, `intl` | Functional programming, IDs, Formatting |

---

## 4. Database Schema (Isar)
The local database mirrors the backend but is optimized for mobile access.

### **Collections**

#### **UserCollection**
```dart
@collection
class UserCollection {
  Id id = Isar.autoIncrement;
  @Index(unique: true, replace: true)
  late String serverId; // UUID from backend
  late String email;
  late String role; // 'CLIENT' | 'TRAINER'
  late String name;
  late DateTime lastSync;
}
```

#### **WorkoutCollection**
```dart
@collection
class WorkoutCollection {
  Id id = Isar.autoIncrement;
  @Index(unique: true, replace: true)
  late String serverId;
  late String name;
  late DateTime scheduledDate;
  late bool isCompleted;
  
  // Relations
  final exercises = IsarLinks<ExerciseCollection>();
  
  // Sync Meta
  late bool isDirty; // True if modified locally and needs sync
  late DateTime updatedAt;
}
```

#### **ExerciseCollection**
```dart
@collection
class ExerciseCollection {
  Id id = Isar.autoIncrement;
  late String name;
  late String targetMuscle;
  
  // Embedded Sets for performance
  List<WorkoutSet> sets = [];
}

@embedded
class WorkoutSet {
  late String id; // UUID
  late double weight;
  late int reps;
  late double? rpe;
  late bool isCompleted;
}
```

#### **CheckInCollection**
```dart
@collection
class CheckInCollection {
  Id id = Isar.autoIncrement;
  late String photoLocalPath;
  late String? photoUrl; // Populated after Cloudinary upload
  late DateTime timestamp;
  late bool isSynced;
}
```

---

## 5. State Management Strategy (Riverpod)

### **Global Providers**
1.  **`authProvider`**: Manages authentication state (Authenticated, Unauthenticated, Loading). Persists tokens in `FlutterSecureStorage`.
2.  **`syncProvider`**: A background service notifier that triggers sync jobs.
3.  **`bootstrapProvider`**: Initializes Isar, Dio, and loads initial data on app startup.

### **Feature-Specific Providers**
-   **`workoutControllerProvider`**: Handles logic for the active workout session (start timer, log set, finish workout).
-   **`dashboardControllerProvider`**: Aggregates data for the "Today's Mission" view.

### **Code Gen Example**
```dart
@riverpod
class WorkoutController extends _$WorkoutController {
  @override
  FutureOr<WorkoutState> build() {
    // Load initial state from Isar
  }

  Future<void> logSet(String exerciseId, double weight, int reps) async {
    // 1. Update Local Isar DB
    // 2. Mark as Dirty
    // 3. Update State
    // 4. Trigger Background Sync (Fire & Forget)
  }
}
```

---

## 6. Offline-First Sync Engine
**Principle:** The UI *always* reads from Isar. It never waits for the API.

### **Sync Logic (The "SyncManager")**
The `SyncManager` runs in a background isolate or via `WorkManager` (for OS-level background tasks).

### **Sync Queue Priority**

#### **1. Media-First Sync (Check-Ins)**
Before syncing any JSON data, the `SyncManager` must handle pending media uploads:

-   **Query:** Fetch all `CheckInCollection` records where `photoUrl == null` (indicating local-only photo).
-   **Upload Flow:**
    1.  Request upload signature from NestJS (`POST /media/signature`).
    2.  Upload photo to Cloudinary using the signature.
    3.  Receive `photoUrl` from Cloudinary response.
    4.  Update local `CheckInCollection` record with `photoUrl`.
    5.  Mark record as `isDirty = true` to trigger JSON sync in next step.
-   **Rationale:** The backend expects a valid `photoUrl` when receiving CheckIn data. Media must be uploaded first to prevent validation errors.

#### **2. Push (Local -> Remote)**
After media uploads are complete, sync dirty JSON records:

-   **Query:** Fetch all records where `isDirty == true` (across all collections).
-   **Batch Send:** Send to NestJS API endpoints (e.g., `POST /sync/batch`).
-   **On Success:**
    -   Update `serverId` if it was a new record.
    -   Set `isDirty = false`.
    -   Update `updatedAt` from server response.
-   **On Conflict (409):**
    -   **Silent Resolution:** If the server returns HTTP 409 (Conflict) or updated data, the app MUST:
        1.  Accept the server's version as the source of truth.
        2.  Overwrite the local Isar record with server data.
        3.  Set `isDirty = false`.
        4.  **Do NOT show an error dialog to the user.** This is a background operation.
    -   **Rationale:** Server Wins policy ensures data consistency without user intervention.

#### **3. Pull (Remote -> Local)**
-   **Query:** Call `GET /sync/changes?since={lastSyncTimestamp}`.
-   **Receive:** Delta changes from server.
-   **Conflict Resolution:**
    -   If Server `updatedAt` > Local `updatedAt`: **Overwrite Local**.
    -   If Local is dirty but Server has newer data: **Server Wins** (silently update local record).
    -   Update `lastSyncTimestamp` in `UserCollection` after successful pull.

---

## 7. UI Component Tree & Navigation (GoRouter)

### **Routing Structure**
-   `/splash` (Initial loading)
-   `/login`
-   `/check-in` (Camera flow - Mandatory if not checked in today)
-   `/home` (ShellRoute with BottomNavBar)
    -   `/dashboard` (Role dependent)
    -   `/calendar`
    -   `/profile`
-   `/workout/:id` (Active Workout Runner - FullScreen)

### **Key Screens**

#### **A. Check-In Flow (Mandatory)**
-   **UI:** Full-screen camera viewfinder with overlay.
-   **Action:** Snap photo -> Preview -> Confirm.
-   **Logic:** Save to Isar (Queue upload). Allow user to proceed to app immediately. Upload happens in background.

#### **B. Dashboard (Today's Mission)**
-   **Header:** Greeting + Streak Counter.
-   **Body:**
    -   *Client:* "Today's Workout" Card (Big, actionable). "Nutrition" Summary.
    -   *Trainer:* "Client Alerts" (e.g., 'John missed workout'), "Today's Appointments".

#### **C. Smart Input (Workout Runner)**
-   **Design:** Compact list of sets.
-   **Interaction:**
    -   Tap 'Weight' -> Numpad pops up (Custom widget, not system keyboard).
    -   Tap 'RPE' -> Slider or 1-10 grid.
    -   Swipe Left to delete set.
    -   "Auto-Advance" focus to next field.

#### **D. Analytics (Trainer View)**
-   **Library:** `fl_chart`.
-   **Charts:**
    -   LineChart: Client Strength Progression (Volume vs Time).
    -   BarChart: Weekly Adherence.

---

## 8. Styling & UX (Cyber/Futuristic)
-   **Colors:**
    -   Background: `#0A0A0A` (Almost Black)
    -   Surface: `#1E1E1E` (Dark Grey)
    -   Primary: `#00F0FF` (Neon Cyan)
    -   Secondary: `#FF003C` (Neon Red - for errors/intensity)
    -   Text: `#FFFFFF` (White), `#B3B3B3` (Grey)
-   **Typography:** 'Orbitron' (Headers), 'Inter' (Body).
-   **Effects:**
    -   Glassmorphism on bottom sheets.
    -   Neon glow shadows on active buttons.
    -   Haptic feedback on every successful input.

---

## 9. Implementation Roadmap
1.  **Phase 1: Foundation**
    -   Setup Flutter, Riverpod, GoRouter.
    -   Implement Isar Schemas.
    -   Build Auth flow (Mock API).
2.  **Phase 2: Core Features**
    -   Dashboard UI.
    -   Workout Runner with Smart Input.
    -   Local CRUD operations.
3.  **Phase 3: Sync & Backend Integration**
    -   Implement `SyncManager`.
    -   Integrate Cloudinary for Check-ins.
    -   Connect to NestJS.
4.  **Phase 4: Polish**
    -   Animations.
    -   Offline testing.
    -   Release build optimization.
