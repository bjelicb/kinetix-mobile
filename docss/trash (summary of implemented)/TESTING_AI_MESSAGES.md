# Vodič za Testiranje AI Messages Management

## ✅ Status Implementacije

**Admin strana:** ✅ **POTPUNO FUNKCIONALNA**
- Batch endpoint za učitavanje svih poruka (`GET /gamification/messages/all`)
- Custom Message tab radi (šalje custom message i tone na backend)
- Quick Templates tab radi (frontend template-i sa metadata)
- Nema 429 grešaka (jedan zahtev umesto N zahteva)
- Sve funkcionalnosti rade profesionalno

**Klijentska strana:** ✅ **IMPLEMENTIRANA**
- Preview card na dashboard-u prikazuje najnovije 3 poruke
- Full stranica sa svim porukama (`/ai-messages`)
- Mark as read funkcionalnost
- Unread badge indikator

---

## 📍 Admin Dashboard - Lokacija

**AI Messages Management** se nalazi na **Admin Dashboard** stranici, **posle Workout Management Card-a**, a **pre Database Overview Card-a**.

### Navigacija:
1. Uloguj se kao **ADMIN** korisnik
2. Idi na **Admin Dashboard** (glavni meni)
3. Scrolluj dole do **"AI Messages"** sekcije
4. Sekcija ima:
   - Header sa ikonom 🤖 (smart_toy_rounded) i naslovom "AI Messages"
   - "Create Message" button (NeonButton, desno gore)
   - Search bar za pretragu poruka
   - Filter chips: All, Motivational, Warning, Aggressive, Empathetic
   - Lista poslatih poruka (scroll view)

---

## 📍 Klijentska Strana - Lokacija

**AI Messages** se prikazuju na **Dashboard** stranici za klijente.

### Navigacija:
1. Uloguj se kao **CLIENT** korisnik
2. Idi na **Dashboard** (glavni meni)
3. Scrolluj dole do **"AI Messages"** preview card-a
4. **Preview card** prikazuje:
   - Header sa ikonom 🤖 i naslovom "AI Messages"
   - Unread badge (broj nepročitanih poruka)
   - Preview najnovije poruke (tone badge, poruka, "X more messages")
   - Klik na card vodi na full stranicu sa svim porukama
5. **Full stranica** (`/ai-messages`) prikazuje:
   - AppBar sa naslovom i unread badge-om
   - Listu svih poruka (sortirano po datumu, najnovije prvo)
   - Klik na poruku je označava kao pročitanu

---

## 🧪 Test Scenariji

### Scenario 1: Template-based Message (MISSED_WORKOUTS)

1. **Klikni "Create Message" button**
2. **Odaberi klijenta** iz dropdown-a (mora biti CLIENT role)
3. **Klikni "Quick Templates" tab** (prvi tab)
4. **Odaberi "Missed Workouts" template** (prvi u listi)
5. **Unesi "Missed Count"** (npr. 3) u polje koje se pojavi
6. **Klikni "Send Message"**
7. **Očekivano:**
   - Modal se zatvara
   - Snackbar sa "Message sent successfully" (zeleno)
   - Lista poruka se refresh-uje
   - Nova poruka se pojavljuje na vrhu liste

---

### Scenario 2: Template-based Message (STREAK)

1. **Klikni "Create Message"**
2. **Odaberi klijenta**
3. **Klikni "Quick Templates" tab**
4. **Odaberi "Streak" template** (drugi u listi)
5. **Unesi "Streak (days)"** (npr. 7)
6. **Klikni "Send Message"**
7. **Očekivano:** Poruka se šalje sa motivacionim tonom

---

### Scenario 3: Template-based Message (WEIGHT_SPIKE)

1. **Klikni "Create Message"**
2. **Odaberi klijenta**
3. **Klikni "Quick Templates" tab**
4. **Odaberi "Weight Spike" template**
5. **Unesi "Weight Change (kg)"** (npr. 2.5)
6. **Klikni "Send Message"**
7. **Očekivano:** Poruka se šalje sa warning tonom

---

### Scenario 4: Template-based Message (SICK_DAY)

1. **Klikni "Create Message"**
2. **Odaberi klijenta**
3. **Klikni "Quick Templates" tab**
4. **Odaberi "Sick Day" template**
5. **Klikni "Send Message"** (nema dodatnih polja)
6. **Očekivano:** Poruka se šalje sa empathetic tonom

---

### Scenario 5: Filter Messages by Tone

1. **Na AI Messages card-u, klikni filter chip "Motivational"**
2. **Očekivano:** Lista prikazuje samo motivational poruke
3. **Klikni "All"** - vraća sve poruke

---

### Scenario 6: Search Messages

1. **U search bar-u, ukucaj deo poruke** (npr. "treninga")
2. **Očekivano:** Lista se filtrira po sadržaju poruke

---

### Scenario 7: Custom Message (Custom Message Tab)

1. **Klikni "Create Message"**
2. **Odaberi klijenta**
3. **Klikni "Custom Message" tab** (drugi tab)
4. **Odaberi tone** (Motivational, Warning, Aggressive, Empathetic)
5. **Unesi custom message tekst** (min. 10 karaktera)
6. **Opciono: Odaberi trigger** (za backend kategorizaciju)
7. **Klikni "Send Message"**
8. **Očekivano:** Poruka se šalje sa unetim tekstom i odabranim tonom

---

## 🧪 Test Scenariji - Klijentska Strana

### Scenario 8: View Messages on Dashboard (Preview)

1. **Uloguj se kao CLIENT korisnik**
2. **Idi na Dashboard**
3. **Scrolluj dole do "AI Messages" preview card-a**
4. **Očekivano:**
   - Card se prikazuje ako postoje poruke
   - Prikazuje najnoviju poruku (tone badge, tekst, max 2 linije)
   - Unread badge prikazuje broj nepročitanih poruka
   - Ako ima više od 1 poruke, prikazuje "+X more messages"

---

### Scenario 9: View All Messages (Full Page)

1. **Na Dashboard-u, klikni na "AI Messages" preview card**
2. **Očekivano:**
   - Otvara se `/ai-messages` stranica
   - Prikazuje sve poruke (sortirano po datumu, najnovije prvo)
   - AppBar prikazuje unread badge
   - Svaka poruka ima tone badge i datum

---

### Scenario 10: Mark Message as Read

1. **Na `/ai-messages` stranici, klikni na nepročitanu poruku**
2. **Očekivano:**
   - Poruka se označava kao pročitana (optimistic update)
   - Unread badge se smanjuje
   - Poruka gubi "unread" indikator
   - Backend se ažurira (PATCH `/gamification/messages/:messageId/read`)

---

### Scenario 11: Empty State

1. **Uloguj se kao CLIENT korisnik koji nema poruka**
2. **Idi na Dashboard**
3. **Očekivano:**
   - "AI Messages" preview card se NE prikazuje (SizedBox.shrink)
4. **Idi direktno na `/ai-messages` stranicu**
5. **Očekivano:**
   - Prikazuje empty state sa ikonom i tekstom
   - "No Messages Yet" poruka

---

## 🔍 Backend API Endpoints

### 1. Generate AI Message (Admin only)
```
POST /api/gamification/generate-message
```

**Request Body:**
```json
{
  "clientId": "string",
  "trigger": "MISSED_WORKOUTS" | "STREAK" | "WEIGHT_SPIKE" | "SICK_DAY",
  "customMessage": "string (optional)",  // Za Custom Message tab
  "tone": "MOTIVATIONAL" | "WARNING" | "AGGRESSIVE" | "EMPATHETIC (optional)",  // Za Custom Message tab
  "metadata": {
    "missedCount": 3,        // za MISSED_WORKOUTS
    "streak": 7,              // za STREAK
    "weightChange": 2.5       // za WEIGHT_SPIKE
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "_id": "messageId",
    "clientId": "clientId",
    "message": "Message text",
    "tone": "MOTIVATIONAL" | "WARNING" | "AGGRESSIVE" | "EMPATHETIC",
    "trigger": "MISSED_WORKOUTS" | "STREAK" | "WEIGHT_SPIKE" | "SICK_DAY",
    "isRead": false,
    "createdAt": "2024-01-01T00:00:00.000Z",
    "updatedAt": "2024-01-01T00:00:00.000Z",
    "metadata": { ... }
  }
}
```

### 2. Get All Messages (Admin only - Batch endpoint)
```
GET /api/gamification/messages/all
```

**Response:**
```json
[
  {
    "id": "messageId",
    "clientId": "clientId",
    "message": "Message text",
    "tone": "MOTIVATIONAL",
    "trigger": "STREAK",
    "isRead": false,
    "createdAt": "2024-01-01T00:00:00.000Z",
    "updatedAt": "2024-01-01T00:00:00.000Z",
    "metadata": { ... }
  },
  ...
]
```

**Napomena:** Admin koristi batch endpoint (`/all`) umesto pojedinačnih zahteva po klijentu. Ovo eliminiše 429 greške i poboljšava performanse.

### 3. Get Messages for Client (Client/Trainer/Admin)
```
GET /api/gamification/messages/:clientId
```

**Response:**
```json
[
  {
    "id": "messageId",
    "clientId": "clientId",
    "message": "Message text",
    "tone": "MOTIVATIONAL",
    "trigger": "STREAK",
    "isRead": false,
    "createdAt": "2024-01-01T00:00:00.000Z",
    "updatedAt": "2024-01-01T00:00:00.000Z",
    "metadata": { ... }
  },
  ...
]
```

**Napomena:** Klijenti koriste ovaj endpoint da učitaju svoje poruke.

### 4. Mark Message as Read (Client only)
```
PATCH /api/gamification/messages/:messageId/read
```

**Response:**
```json
{
  "message": "Message marked as read"
}
```

---

## 🐛 Debugging

### Ako poruke ne dolaze:

1. **Proveri backend log-ove:**
   - Backend treba da loguje `AI_MESSAGE_GENERATE` operacije
   - Proveri da li se endpoint poziva

2. **Proveri frontend log-ove:**
   - Otvori DevTools / Console
   - Traži `[RemoteDataSource:AIMessage]` log-ove
   - Traži `[AdminController]` log-ove

3. **Proveri network request:**
   - Otvori Network tab u DevTools
   - Traži `POST /gamification/generate-message`
   - Proveri request body i response

4. **Proveri da li postoji CLIENT korisnik:**
   - Admin Dashboard → User Management
   - Mora postojati bar jedan korisnik sa role = "CLIENT"

---

## ✅ Checklist za Testiranje - Admin Strana

- [x] AI Messages card se prikazuje na Admin Dashboard-u
- [x] "Create Message" button otvara modal
- [x] Client dropdown prikazuje sve CLIENT korisnike
- [x] Quick Templates tab prikazuje 4 kategorije template-a
- [x] Template selection radi (highlight-uje se)
- [x] Metadata input polja se pojavljuju na osnovu trigger-a
- [x] Metadata input se automatski scroll-uje kada se template odabere
- [x] "Send Message" šalje poruku na backend
- [x] Poruka se pojavljuje u listi nakon slanja (refresh radi)
- [x] Filter chips filtriraju poruke po tone-u
- [x] Search bar filtrira poruke po tekstu
- [x] Poruke se sortiraju po datumu (najnovije prvo)
- [x] Unread badge se prikazuje za nepročitane poruke
- [x] Custom Message tab radi (šalje custom message i tone)
- [x] Batch endpoint radi (nema 429 grešaka)
- [x] Lista se refresh-uje nakon kreiranja poruke

---

## ✅ Checklist za Testiranje - Klijentska Strana

- [ ] AI Messages preview card se prikazuje na Dashboard-u (ako postoje poruke)
- [ ] Preview card prikazuje najnoviju poruku
- [ ] Unread badge prikazuje tačan broj nepročitanih poruka
- [ ] Klik na preview card vodi na `/ai-messages` stranicu
- [ ] Full stranica prikazuje sve poruke
- [ ] Poruke su sortirane po datumu (najnovije prvo)
- [ ] Klik na nepročitanu poruku je označava kao pročitanu
- [ ] Unread badge se ažurira nakon mark as read
- [ ] Empty state se prikazuje kada nema poruka
- [ ] Preview card se ne prikazuje kada nema poruka

---

## 📝 Napomene

### Admin Strana
- ✅ **Custom Message tab radi** - backend podržava custom message i tone
- ✅ **Quick Templates tab radi** - frontend template-i sa metadata replacement
- ✅ **Batch endpoint implementiran** - `/gamification/messages/all` (Admin only)
- ✅ **Nema 429 grešaka** - jedan zahtev umesto N zahteva
- ✅ **Sve funkcionalnosti rade profesionalno**

### Klijentska Strana
- ✅ **Preview card implementiran** - prikazuje najnovije 3 poruke na dashboard-u
- ✅ **Full stranica implementirana** - `/ai-messages` sa svim porukama
- ✅ **Mark as read funkcionalnost** - optimistic update sa rollback na grešku
- ✅ **Unread badge** - prikazuje broj nepročitanih poruka

### Backend
- ✅ **Batch endpoint** - `GET /gamification/messages/all` (Admin only)
- ✅ **Custom message support** - `POST /gamification/generate-message` prihvata `customMessage` i `tone`
- ✅ **Template generation** - ako nema `customMessage`, generiše iz template-a

