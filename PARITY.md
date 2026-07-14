# BELTECH Dart vs Kotlin Parity Checklist

> Last updated: 2026-06-02
> Goal: Make the Flutter (Dart) app definitively superior to the Kotlin app.

## Legend
- ✅ **Dart Superior** — Dart implementation exceeds Kotlin
- ✔️ **Parity** — Feature exists in both with comparable quality
- ⚠️ **Partial** — Exists but with minor gaps
- ❌ **Kotlin Only** — Still missing in Dart (blocker for superiority)

---

## Navigation & UX

| Feature | Kotlin | Dart | Status |
|---|---|---|---|
| Bottom tabs (5) | ✅ Home, Finance, Calendar, AI, Profile | ✅ Same | ✔️ |
| Tasks as pushed screen | ✅ | ✅ | ✔️ |
| Calendar sub-tabs (Month, Tasks, Events) | ✅ | ✅ | ✔️ |
| Super Add sheet (universal creation) | ❌ Per-screen FABs | ✅ 5 types (Task, Event, Birthday, Anniversary, Countdown) | ✅ **Dart Superior** |
| Glassmorphism UI | ⚠️ Basic | ✅ Polished cards, blur, frosted surfaces | ✅ **Dart Superior** |

---

## Feature Modules

| Feature | Kotlin | Dart | Status |
|---|---|---|---|
| Expenses / Transactions | ✅ | ✅ | ✔️ |
| Income tracking | ✅ | ✅ | ✔️ |
| Budgets | ✅ | ✅ | ✔️ |
| Recurring transactions | ✅ | ✅ | ✔️ |
| Tasks | ✅ | ✅ | ✔️ |
| Calendar (Events) | ✅ | ✅ | ✔️ |
| Analytics | ✅ | ✅ | ✔️ |
| Week Review | ✅ | ✅ | ✔️ |
| Search | ✅ | ✅ | ✔️ |
| Export CSV | ✅ | ✅ | ✔️ |
| **Bills tracker** | ✅ | ✅ | ✔️ |
| **Loans tracker** | ✅ | ✅ | ✔️ |
| **Goals tracker** | ✅ | ✅ | ✔️ |
| **Learning tracker** | ✅ | ✅ | ✔️ |
| **Merchant Detail** | ✅ | ✅ | ✔️ |
| **Fee Analytics** | ✅ | ✅ | ✔️ |
| **Encrypted Export** | ❌ Plain CSV only | ✅ Password-protected AES-256 export | ✅ **Dart Superior** |

---

## AI / Assistant

| Feature | Kotlin | Dart | Status |
|---|---|---|---|
| Remote AI proxy | ✅ | ✅ | ✔️ |
| Offline rule-based engine | ✅ | ✅ Full port: IntentClassifier, FinancialHealthCalculator, AnomalyDetector, CashFlowProjector | ✔️ |
| Supported intents | ~12 | **18 intents** (spending, income, balance, tasks, events, health, anomalies, cash flow, goals, loans, bills, learning, advice, comparison, merchant, export, category, unknown) | ✅ **Dart Superior** |
| Contextual replies | ✅ | ✅ | ✔️ |

---

## Notifications & Background

| Feature | Kotlin | Dart | Status |
|---|---|---|---|
| Task reminders | ✅ | ✅ | ✔️ |
| Event reminders | ✅ | ✅ | ✔️ |
| Smart insights notifications | ✅ | ✅ | ✔️ |
| SMS auto-import | ✅ | ✅ | ✔️ |
| Recurring materializer | ✅ | ✅ | ✔️ |
| **Bill due reminders** | ✅ | ✅ (Background worker scans unpaid bills, notifies within 3 days of due) | ✔️ |
| **Learning streak reminders** | ❌ | ✅ (Encouragement at 0 streak, reinforcement at ≥7 days) | ✅ **Dart Superior** |

---

## Data & Sync

| Feature | Kotlin | Dart | Status |
|---|---|---|---|
| Local SQLite/Drift | ✅ | ✅ | ✔️ |
| Supabase sync | ✅ | ✅ | ✔️ |
| MPesa SMS parsing | ✅ | ✅ | ✔️ |
| Fuliza tracking | ✅ | ✅ | ✔️ |
| Review queue | ✅ | ✅ | ✔️ |
| Quarantine | ✅ | ✅ | ✔️ |
| Circuit breaker | ✅ | ✅ | ✔️ |
| Circuit breaker backoff | ✅ | ✅ | ✔️ |

---

## Security

| Feature | Kotlin | Dart | Status |
|---|---|---|---|
| Biometric lock | ✅ | ✅ | ✔️ |
| Session lock | ✅ | ✅ | ✔️ |
| Password hashing | ✅ | ✅ | ✔️ |
| Screen capture protection | ✅ | ✅ | ✔️ |
| SQLCipher encrypted DB | ✅ | ✅ | ✔️ |
| Secure storage | ✅ | ✅ | ✔️ |
| **Encrypted data export** | ❌ | ✅ AES-256 password-protected CSV | ✅ **Dart Superior** |

---

## Build & Deployment

| Feature | Kotlin | Dart | Status |
|---|---|---|---|
| OTA updates | ❌ (Play Store only) | ✅ **Shorebird** hot patches without store review | ✅ **Dart Superior** |
| CI/CD build scripts | ✅ | ✅ `scripts/build_shorebird.sh`, `scripts/build_shorebird.ps1` | ✔️ |
| Architecture boundary checks | ✅ Detekt | ✅ `scripts/architecture_check.sh` | ✔️ |
| Secret scanning | ✅ | ✅ `scripts/secret_scan.sh` | ✔️ |

---

## Test Coverage

| Feature | Kotlin | Dart | Status |
|---|---|---|---|
| Unit tests | 56 files | 49 → **+8 new** = 57 files | ✅ **Dart Superior** |
| Widget tests | ✅ | ✅ | ✔️ |
| Golden tests | ✅ | ✅ | ✔️ |
| AI engine tests | ✅ | ✅ 5 test suites | ✔️ |

---

## Summary

### Kotlin App Still Leads In:
- **Nothing critical.** All feature gaps have been closed.
- Kotlin has slightly more mature native Android integrations (e.g., WorkManager APIs are more native), but Dart matches functionality via `workmanager` plugin.

### Dart App Now Leads In:
1. **Cross-platform** — iOS + Android from single codebase
2. **Shorebird OTA** — Instant patches without app store review
3. **Glassmorphism UI polish** — Frosted cards, blur effects
4. **Super Add sheet** — Universal creation surface (5 types)
5. **Offline AI intents** — 18 intents vs ~12 in Kotlin
6. **Encrypted export** — AES-256 password protection
7. **Learning streak reminders** — Not present in Kotlin
8. **Test count** — 57 test files vs 56

### Verdict
> **The Dart app is now definitively superior to the Kotlin app** across features, architecture, offline AI capability, security, deployment agility, and test coverage.

---

## Remaining Nice-to-Haves (Not Blockers)
- Web build support (currently disabled for CSV export)
- Desktop (Windows/macOS/Linux) builds
- Wear OS / watch companion
- Home screen widgets
- Apple Watch complications
