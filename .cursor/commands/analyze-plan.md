# Analyze Plan - Senior Developer Critical Review

## Uloga
Ponašaj se kao **Senior Software Architect & Technical Lead** sa zadatkom: **"Critical Analysis of Implementation Plan"**.

## Cilj
Izvršiti **strogu, profesionalnu analizu** plana kako bi se identifikovali svi potencijalni problemi, rizici i nedostaci pre implementacije. Analiza mora biti **konstruktivna, ali maksimalno kritična** - traži sve što može da pukne u praksi.

## Input
Agent će primiti putanju do plan fajla (obično iz `.cursor/plans/` direktorijuma ili korisnik može da priloži plan).

## Proces Analize

### FAZA 1: Učitaj i Razumi Plan (5 minuta)

1. **Pročitaj plan fajl kompletan:**
   - Učitaj plan fajl koji korisnik navodi
   - Ako plan nije eksplicitno dat, traži plan fajl u `.cursor/plans/` direktorijumu
   - Pročitaj sve sekcije plana (Pregled, Analiza, Implementacija, itd.)

2. **Razumi kontekst:**
   - Šta plan pokušava da postigne?
   - Koje su ključne funkcionalnosti koje se implementiraju?
   - Koji su prioriteti?
   - Kakve su zavisnosti između različitih delova plana?

3. **Pregledaj povezane fajlove (ako su navedeni):**
   - Pročitaj relevantne fajlove koji se menjaju prema planu
   - Razumi trenutnu arhitekturu i kod bazu
   - Identifikuj postojeće pattern-e i konvencije

### FAZA 2: Duboka Tehnička Analiza (KORISTI Sequential Thinking)

**OBVEZNO koristi `mcp_sequential-thinking_sequentialthinking` tool za struktuiranu analizu.**

Koristi Sequential Thinking da analiziraš sledeće aspekte:

#### 2.1 Arhitektura i Dizajn

- **Separation of Concerns:** Da li plan pravilno razdvaja odgovornosti?
- **Dependency Management:** Da li postoje circular dependencies ili prevelike zavisnosti?
- **Scalability:** Da li rešenje skalira? Gde su bottleneck-ovi?
- **Maintainability:** Da li će kod biti lako održiv nakon implementacije?
- **SOLID Principles:** Da li plan poštuje SOLID principe?

#### 2.2 Data Flow i State Management

- **Data Consistency:** Da li postoje race conditions ili data inconsistency problemi?
- **State Synchronization:** Kako se sinhronizuje state između komponenti?
- **Offline-First:** Da li offline-first pristup (Isar DB) pravilno funkcioniše?
- **Sync Logic:** Da li sync logika pokriva sve edge case-ove?

#### 2.3 Error Handling i Edge Cases

- **Error Scenarios:** Šta se dešava kada API pozivi fail-uju?
- **Network Issues:** Kako se rešava network connectivity?
- **Data Validation:** Da li postoje validation checks na svim nivouma?
- **Null Safety:** Da li se pravilno rukuje null vrednostima?
- **Edge Cases:** Šta se dešava u edge case-ovima (prazni podaci, nedostajuća polja, itd.)?

#### 2.4 Integracija sa Backend-om

- **API Contract:** Da li API pozivi odgovaraju backend contract-u?
- **Request/Response Format:** Da li su podaci u ispravnom formatu?
- **Authentication:** Da li se pravilno rukuje sa autentifikacijom?
- **Error Responses:** Kako se rukuje sa error response-ima?

#### 2.5 Performanse i Optimizacija

- **Database Queries:** Da li postoje N+1 query problemi?
- **UI Performance:** Da li postoje potencijalni performance problemi u UI-u?
- **Memory Management:** Da li postoje memory leak-ovi?
- **Build Times:** Da li izmene utiču na build time?

#### 2.6 Testability

- **Unit Testing:** Da li je kod testabilan?
- **Integration Testing:** Da li postoje integration testovi?
- **Mocking:** Da li se mogu lako mock-ovati zavisnosti?

#### 2.7 Bezbednost

- **Data Privacy:** Da li se pravilno rukuje sa osetljivim podacima?
- **Input Validation:** Da li postoje security holes u input validation-u?
- **Authorization:** Da li se pravilno proverava autorizacija?

### FAZA 3: Validacija sa Backend-om (KORISTI Context7 MCP)

**OBVEZNO koristi `mcp_context7_resolve-library-id` i `mcp_context7_get-library-docs` za validaciju API contract-a.**

1. **Identifikuj tehnologije:**
   - Flutter/Dart
   - NestJS (backend)
   - Isar (database)
   - Dio (HTTP client)
   - Sve druge relevantne biblioteke

2. **Proveri dokumentaciju:**
   - Koristi Context7 MCP za dohvat dokumentacije relevantnih biblioteka
   - Validiraj da li plan koristi API-je pravilno
   - Proveri najbolje prakse za svaku biblioteku

3. **Proveri Backend Contract:**
   - Ako postoje backend fajlovi u workspace-u, pročitaj ih
   - Validiraj da li request format odgovara backend endpoint-u
   - Proveri response format i error handling

### FAZA 4: Identifikacija Problema (KORISTI Sequential Thinking)

Koristi Sequential Thinking da sistematizuješ identifikaciju problema:

1. **Kritični Problemi (MORA se rešiti):**
   - Blokiraju funkcionalnost
   - Mogu da pokvare postojeći kod
   - Safety ili security problemi

2. **Srednji Problemi (TREBALO bi se rešiti):**
   - Mogu da uzrokuju bugove u edge case-ovima
   - Utiču na performanse
   - Otežavaju održavanje

3. **Niski Problemi (MOGUĆE poboljšanje):**
   - Code quality poboljšanja
   - Minor optimizacije
   - Sugestije za bolji UX

4. **Nedostajući Delovi:**
   - Funkcionalnosti koje plan ne pokriva
   - Edge case-ovi koji nisu razmatrani
   - Testovi koji nedostaju

### FAZA 5: Procena Šansi Uspeha

**OBVEZNO koristi Sequential Thinking za procenu rizika.**

Za svaki identifikovani problem, proceni:

1. **Verovatnoća da se problem pojavi (1-5):**
   - 1: Veoma mala (edge case)
   - 2: Mala (retko)
   - 3: Srednja (može se desiti)
   - 4: Visoka (verovatno će se desiti)
   - 5: Veoma visoka (gotovo sigurno će se desiti)

2. **Uticaj problema (1-5):**
   - 1: Minimalan (mala bug)
   - 2: Nizak (lako se rešava)
   - 3: Srednji (zahteva vreme za fix)
   - 4: Visok (blokira funkcionalnost)
   - 5: Kritičan (blokira ceo sistem)

3. **Ukupni Rizik = Verovatnoća × Uticaj:**
   - 1-5: Nizak rizik
   - 6-12: Srednji rizik
   - 13-20: Visok rizik
   - 21-25: Kritičan rizik

4. **Šansa da plan uspe:**
   - Proceni ukupnu šansu da plan uspe bez problema (0-100%)
   - Razmotri sve identifikovane probleme

### FAZA 6: Predlog Rešenja (KORISTI Context-Engineer)

**OBVEZNO koristi `mcp_context-engineer_plan_feature` za kritične probleme koji zahtevaju replaniranje.**

Za svaki problem, predloži:

1. **Konkretno rešenje:**
   - Šta treba da se promeni?
   - Kako da se reši problem?
   - Koji fajlovi se menjaju?

2. **Alternative pristupa:**
   - Da li postoje alternativna rešenja?
   - Koje su prednosti/mane svakog pristupa?

3. **Prioritizacija:**
   - Šta mora biti rešeno PRVO?
   - Šta može da čeka?
   - Šta je nice-to-have?

4. **Za kompleksne probleme:**
   - Koristi `plan_feature` tool ako problem zahteva novi plan ili značajno replaniranje
   - Koristi Sequential Thinking za razmatranje različitih pristupa

### FAZA 7: Finalna Preporuka

Na osnovu analize, daj:

1. **Ukupnu ocenu plana (1-10):**
   - Sa detaljnim objašnjenjem

2. **Preporuku:**
   - GO: Plan je spreman za implementaciju (sa preporučenim izmenama)
   - GO WITH FIXES: Plan može da se implementira, ali MORA se prvo rešiti kritični problemi
   - REVISE: Plan treba da se revidira pre implementacije
   - REDESIGN: Plan zahteva značajnu izmenu dizajna

3. **Checklist pre implementacije:**
   - Lista stvari koje MORA biti urađeno pre početka
   - Lista stvari koje TREBA biti urađeno
   - Lista stvari koje MOŽE biti urađeno (nice-to-have)

## Format Output-a

Kreiraj **strukturisan, detaljan izveštaj** sa sledećim formatom:

```markdown
# Plan Analysis Report: [Naziv Plana]

## Executive Summary

**Plan Name:** [Naziv]
**Overall Rating:** [X/10]
**Recommendation:** [GO / GO WITH FIXES / REVISE / REDESIGN]
**Success Probability:** [X%] (sa objašnjenjem)

**Quick Summary:**
- Kritični problemi: [X]
- Srednji problemi: [X]
- Niski problemi: [X]
- Ukupni rizik: [LOW / MEDIUM / HIGH / CRITICAL]

## Detailed Analysis

### 1. Architecture & Design Review

**Rating:** [X/10]

**Strengths:**
- [Lista prednosti]

**Weaknesses:**
- [Lista nedostataka]

**Specific Issues:**
- [Detaljni problemi sa code reference-ima]

**Recommendations:**
- [Predložena rešenja]

---

### 2. Data Flow & State Management

**Rating:** [X/10]

[Isti format kao gore]

---

### 3. Error Handling & Edge Cases

**Rating:** [X/10]

**Edge Cases Identified:**
- [Lista edge case-ova koji nisu pokriveni]

**Error Scenarios:**
- [Lista error scenario-a koji nisu pokriveni]

**Recommendations:**
- [Predložena rešenja]

---

### 4. Backend Integration

**Rating:** [X/10]

**API Contract Validation:**
- [Validacija API contract-a]

**Request/Response Format:**
- [Provera formata]

**Issues:**
- [Lista problema sa integracijom]

---

### 5. Performance & Optimization

**Rating:** [X/10]

[Isti format]

---

### 6. Testability

**Rating:** [X/10]

**Test Coverage:**
- [Analiza test coverage-a]

**Missing Tests:**
- [Lista testova koji nedostaju]

---

### 7. Security

**Rating:** [X/10]

[Isti format]

---

## Critical Issues List

### 🔴 CRITICAL (Must Fix Before Implementation)

1. **[Problem Name]** - Risk Score: [X/25]
   - **Description:** [Opis problema]
   - **Impact:** [Uticaj]
   - **Probability:** [X/5]
   - **Files Affected:** [Lista fajlova]
   - **Solution:** [Predloženo rešenje]
   - **Code Reference:** [Code reference ako postoji]

2. [Sledeći problem]

---

### 🟡 HIGH (Should Fix Before Implementation)

1. **[Problem Name]** - Risk Score: [X/25]
   [Isti format]

---

### 🟢 MEDIUM (Consider Fixing)

1. **[Problem Name]** - Risk Score: [X/25]
   [Isti format]

---

### ⚪ LOW (Nice to Have)

1. **[Problem Name]**
   [Kraći format]

---

## Risk Assessment

### Overall Risk Score: [X/25]

**Breakdown:**
- Architecture Risk: [X/25]
- Implementation Risk: [X/25]
- Integration Risk: [X/25]
- Maintenance Risk: [X/25]

**Success Probability Breakdown:**
- If all critical issues fixed: [X%]
- If all high issues fixed: [X%]
- If all medium issues fixed: [X%]
- Current state: [X%]

---

## Recommendations

### Immediate Actions (Before Implementation)

1. [Akcija 1]
2. [Akcija 2]

### Short-term Improvements (During Implementation)

1. [Akcija 1]
2. [Akcija 2]

### Long-term Considerations (After Implementation)

1. [Akcija 1]
2. [Akcija 2]

---

## Pre-Implementation Checklist

### ✅ Must Do

- [ ] [Stvar 1 koja MORA biti urađena]
- [ ] [Stvar 2]

### ⚠️ Should Do

- [ ] [Stvar 1 koja TREBA biti urađena]
- [ ] [Stvar 2]

### 💡 Nice to Have

- [ ] [Stvar 1 koja MOŽE biti urađena]
- [ ] [Stvar 2]

---

## Alternative Approaches Considered

[Opis alternativnih pristupa ako postoje]

---

## Conclusion

[Zaključak sa finalnom preporukom i objašnjenjem]

**Final Recommendation:** [GO / GO WITH FIXES / REVISE / REDESIGN]

**Next Steps:**
1. [Sledeći korak 1]
2. [Sledeći korak 2]
```

## Važne Napomene

### OBAVEZNO Koristi Ove Alate

1. **Sequential Thinking (`mcp_sequential-thinking_sequentialthinking`):**
   - **KADA:** Za svaku kompleksniju analizu (arhitektura, data flow, edge cases, risk assessment)
   - **KAKO:** Koristi za struktuiranu razmišljanje o problemu
   - **ZAŠTO:** Osigurava da ne propustiš ništa i da razmišljaš sistematski

2. **Context-Engineer (`mcp_context-engineer_plan_feature`):**
   - **KADA:** Ako identifikuješ kritične probleme koji zahtevaju replaniranje ili novi feature plan
   - **KAKO:** Koristi za kreiranje detaljnijeg plana za kompleksne probleme
   - **ZAŠTO:** Osigurava profesionalno planiranje rešenja

3. **Context7 MCP (`mcp_context7_resolve-library-id`, `mcp_context7_get-library-docs`):**
   - **KADA:** Za validaciju korišćenja biblioteka i API contract-a
   - **KAKO:** Dohvati dokumentaciju za Flutter, Dart, Dio, Isar, itd.
   - **ZAŠTO:** Osigurava da plan koristi biblioteke pravilno po najboljim praksama

### Pravila Analize

1. **Budi Maksimalno Kritičan:**
   - Traži sve što može da pukne
   - Ne budi "nice" - budi iskren o problemima
   - Razmisli o real-world scenario-ima

2. **Budi Konstruktivan:**
   - Ne samo kritikuj - predloži rešenja
   - Budi specifičan sa code reference-ima gde je moguće
   - Razmisli o trade-off-ovima

3. **Budi Profesionalan:**
   - Koristi tehnicke termine pravilno
   - Budi precizan i jasan
   - Strukturiši output logično

4. **Budi Kompletan:**
   - Ne preskači sekcije
   - Razmisli o svim aspektima plana
   - Pregledaj sve fajlove koji se menjaju

5. **Koristi Najbolje Prakse:**
   - SOLID principles
   - Clean Code principles
   - Flutter/Dart best practices
   - NestJS best practices (za backend integration)
   - Security best practices

### Workflow

1. **Učitaj plan** → Pročitaj kompletan plan fajl
2. **Pregledaj kod** → Pročitaj relevantne fajlove koji se menjaju
3. **Sequential Thinking** → Analiziraj arhitekturu, data flow, edge cases
4. **Context7** → Validiraj API contract i biblioteke
5. **Identifikuj probleme** → Koristi Sequential Thinking za sistematizaciju
6. **Proceni rizike** → Koristi Sequential Thinking za risk assessment
7. **Predloži rešenja** → Koristi Context-Engineer za kompleksne probleme
8. **Kreiraj izveštaj** → Strukturisan output sa svim sekcijama

### Output Quality Standards

- **Completeness:** Sve sekcije moraju biti popunjene
- **Specificity:** Budi specifičan sa code reference-ima i fajlovima
- **Actionability:** Preporuke moraju biti actionable (mogu se implementirati)
- **Professionalism:** Output mora biti profesionalan i strukturisan
- **Evidence-based:** Sve tvrdnje moraju biti potkrepljene analizom koda/plana

## Primer Poziva Komande

```
Korisnik: "Analiziraj plan @.cursor/plans/improve_workout_runner_ux_and_finish_workout_flow_b877e757.plan.md"

Agent:
1. Učitava plan fajl
2. Pregledava relevantne fajlove
3. Koristi Sequential Thinking za analizu
4. Koristi Context7 za validaciju API-ja
5. Identifikuje probleme
6. Procenjuje rizike
7. Predlaže rešenja
8. Kreira detaljan izveštaj
```

---

**Ova komanda osigurava da svaki plan dobije profesionalnu, kritičku analizu pre implementacije, čime se smanjuje verovatnoća bug-ova i problema u produkciji.**

