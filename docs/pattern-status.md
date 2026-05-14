# Pattern Status — Task Framework Workshop

Maps every pattern and anti-pattern from the catalog to its current location in the
codebase, plus what is still missing (added during the hands-on steps).

> **Legend**
> - ✅ Present — intentionally baked in (anti-pattern) or already implemented
> - ❌ Missing — will be added / fixed during the corresponding workshop step
> - ⏭ Buffer — optional content if time allows
> - 🚫 Dropped — out of scope, not covered in workshop

Pattern numbers (1.1, 2.3, …) refer to `docs/patterns/pattern-catalog.md`.

---

## Step 1 — "What's Wrong Here?" (Anti-Pattern Prototype)

These problems are **intentionally baked in** so the audience can spot them.

| # | Anti-Pattern | File | Status |
|---|---|---|:---:|
| 1.6 | `SingleInstance` codeunit storing mutable state | `src/Processing/TaskProcessingState.Codeunit.al` | ✅ |
| 2.1 | Publishing **and** subscribing own events in same app | `src/Processing/TaskProcessor.Codeunit.al:19–31` | ✅ |
| — | Monster `CASE` routing — framework knows all task types | `src/Processing/TaskProcessor.Codeunit.al:62–71` | ✅ |
| — | No error isolation in batch loop | `src/Processing/TaskProcessor.Codeunit.al:37–45` | ✅ |
| 4.4 | Business logic in page trigger (`OnAction` processes inline) | `src/Core/TaskLogEntryCard.page.al:44–68` | ✅ |
| 6.1 | `ERROR()` stops on first problem, no detail | `src/Vouchers/PostVouchers.Codeunit.al:12–18` | ✅ |
| 4.1 | Posting is a status flip — no ledger, no register | `src/Vouchers/PostVouchers.Codeunit.al:22–25` | ✅ |
| 3.2 | Hardcoded retention period (30 days), ignores Setup | `src/Processing/TaskProcessor.Codeunit.al:116` | ✅ |
| 4.6 | Impl app nearly empty — all logic wrongly in framework | `TaskFramework.Impl/src/install/InstallTaskFrameworkImpl.Codeunit.al` | ✅ |
| 2.1 | Event subscriber ordering dependency (App ID–based, unstable) | `src/Processing/TaskProcessor.Codeunit.al:24–31` | ✅ |

---

## Step 2 — Clean Structure (Separation of Concerns, Setup Table, Facade)

**Patterns: 3.2 Setup Table · 4.4 Layered Architecture · 1.3 Facade**

| # | Item | File | Status |
|---|---|---|:---:|
| 3.2 | Setup table with all config fields (Verbosity, Batch Size, Archive, Retry…) | `src/Setup/TaskFrameworkSetup.Table.al` | ✅ |
| 3.2 | Setup page with grouped layout | `src/Setup/TaskFrameworkSetup.Page.al` | ✅ |
| 3.2 | Setup seeded on install | `src/Install/InstallTaskFramework.codeunit.al` | ✅ |
| 1.3 | Facade codeunit — single entry point pages call | `src/Processing/` — `Task Framework Facade` | ❌ |
| 3.2 | `ProcessLogRetention` reads retention days from Setup | `src/Processing/TaskProcessor.Codeunit.al:116` | ❌ (hardcoded 30) |
| 4.4 | Business logic extracted from `OnAction` page trigger | `src/Core/TaskLogEntryCard.page.al:44–68` | ❌ |
| 1.4 | Guard clauses replacing nested IF blocks in processing | mentioned when coding | ⏭ |

---

## Step 3 — Interface Revolution

**Patterns: 1.1 DI/Strategy · 1.7 Enum · 1.8 Method Codeunit (before) · 2.2 Handled Pattern (before)**

| # | Item | File | Status |
|---|---|---|:---:|
| 1.7 | `TaskType` enum — discriminator for factory + interface binding | `src/Core/TaskType.Enum.al` | ✅ |
| 1.7 | `TaskStatus` enum | `src/Core/TaskStatus.Enum.al` | ✅ |
| 1.7 | `TaskVerbosity` enum | `src/Core/TaskVerbosity.enum.al` | ✅ |
| 1.7 | `TaskErrorHandler` enum | `src/Core/Errors/TaskErrorHandler.enum.al` | ✅ |
| 1.7 | `TaskArchiveReason` enum | `src/Core/Archive/TaskArchiveReason.enum.al` | ✅ |
| 1.8 | `OnBeforeProcessTask(var IsHandled)` — the "before" story | `src/Processing/TaskProcessor.Codeunit.al:19–31` | ✅ (anti-pattern, shown as "before") |
| 2.2 | `IsHandled` subscriber claiming task type — silent conflicts | `src/Processing/TaskProcessor.Codeunit.al:24–31` | ✅ (anti-pattern, shown as "before") |
| 1.1 | `ITaskProcessor` interface | `src/Processing/` — `ITaskProcessor.Interface.al` | ❌ |
| 1.1 | `VendorImport Processor` implementing `ITaskProcessor` | `TaskFramework.Impl/src/` | ❌ |
| 1.1 | `LogRetention Processor` implementing `ITaskProcessor` | `TaskFramework.Impl/src/` | ❌ |
| 1.1 | `DocumentImport Processor` implementing `ITaskProcessor` | `TaskFramework.Impl/src/` | ❌ |

---

## Step 3.5 — Dependency Injection by Hand

**Patterns: 1.1 Dependency Injection · ISP — Interface Segregation**

Splits the *how* of processing into injectable roles — manual DI, no Factory yet (that's Step 4).

| # | Item | File | Status |
|---|---|---|:---:|
| 1.1 | `ITask Log Updater` role interface — `UpdateStatus(var TaskLogEntry; NewStatus)` | `src/Processing/Factory/ITaskLogUpdater.interface.al` | ✅ |
| 1.1 | `ITask Archiver` role interface — `Archive(var TaskLogEntry)` | `src/Processing/Factory/ITaskArchiver.interface.al` | ✅ |
| 1.1 | `Task Processor` implements `ITask Processor`, `ITask Log Updater`, `ITask Archiver` | `src/Processing/TaskProcessor.Codeunit.al` | ✅ |
| 1.1 | `UpdateStatus` / `Archive` / `ProcessTask` extracted as interface-shaped procedures | `src/Processing/TaskProcessor.Codeunit.al` | ✅ |
| 1.1 | `ProcessTaskEntry` overload taking the three roles as parameters — manual DI | `src/Processing/TaskProcessor.Codeunit.al` | ✅ |
| 1.1 | `ProcessTaskEntry` body routes status / dispatch / archive through injected roles | `src/Processing/TaskProcessor.Codeunit.al` | ✅ |

---

## Step 4 — Factory Routing

**Pattern: 1.2 Factory**

| # | Item | File | Status |
|---|---|---|:---:|
| 1.2 | `Task Processor Factory` — maps `TaskType` enum → `ITaskProcessor` impl | `src/Processing/` — `TaskProcessorFactory.Codeunit.al` | ❌ |
| 1.2 | `CASE` routing removed from `Task Processor` | `src/Processing/TaskProcessor.Codeunit.al:62–71` | ❌ |

---

## Step 5 — Posting Pipeline + Builder

**Patterns: 4.1 Journal → Posting → Ledger Entry · 1.5 Builder · 3.1 Archiving**

| # | Item | File | Status |
|---|---|---|:---:|
| 3.1 | `Task Log Archive` table (all fields incl. Verbosity, Correlation Id, Archive Reason) | `src/Core/Archive/TaskLogArchive.table.al` | ✅ |
| 3.1 | `Task Log Archive` page | `src/Core/Archive/TaskLogArchive.page.al` | ✅ |
| 3.1 | `Archive After Processing` flag triggers `ArchiveEntry` on complete | `src/Processing/TaskProcessor.Codeunit.al:77–102` | ✅ |
| — | `Earliest Processing DateTime` filter in batch loop | `src/Processing/TaskProcessor.Codeunit.al:41` | ✅ |
| 4.1 | `Voucher Entry` table (draft staging, anti-pattern placeholder) | `src/Vouchers/VoucherEntry.Table.al` | ✅ (replaced in Step 5) |
| 4.1 | `Post Vouchers` codeunit (stub — status flip, no ledger) | `src/Vouchers/PostVouchers.Codeunit.al` | ✅ (replaced in Step 5) |
| 4.1 | `Voucher Journal Line` table | `src/Vouchers/` | ❌ |
| 4.1 | `Voucher Ledger Entry` table | `src/Vouchers/` | ❌ |
| 4.1 | `Voucher Register` table | `src/Vouchers/` | ❌ |
| 4.1 | `Voucher Jnl.-Check Line` codeunit | `src/Vouchers/` | ❌ |
| 4.1 | `Voucher Jnl.-Post Line` codeunit | `src/Vouchers/` | ❌ |
| 4.1 | `Voucher Jnl.-Post Batch` codeunit | `src/Vouchers/` | ❌ |
| 1.5 | `Voucher Journal Line Builder` codeunit | `src/Vouchers/` | ❌ |

---

## Step 6 — Error Handling

**Patterns: 6.1 Collectible Errors · 6.2 Notification Pattern**

| # | Item | File | Status |
|---|---|---|:---:|
| 6.1 | `Task Error Log` table (Entry No., Line No., Error Message, Is Blocking, Correlation Id…) | `src/Core/Errors/TaskErrorLog.table.al` | ✅ |
| 6.1 | Error collector codeunit — writes to `Task Error Log` | `src/Core/Errors/` | ❌ |
| 6.1 | Processor / posting use collector instead of `ERROR()` | `src/Processing/TaskProcessor.Codeunit.al` | ❌ |
| 6.2 | Notification shown after batch (Error / Message / Notification distinction) | `src/Processing/` | ❌ |

---

## Step 7 — Events & Extensibility

**Pattern: 2.1 Publisher/Subscriber**

| # | Item | File | Status |
|---|---|---|:---:|
| 2.1 | `OnBeforeProcessTask` integration event declared | `src/Processing/TaskProcessor.Codeunit.al:19–22` | ✅ (self-consumed — anti-pattern) |
| 2.1 | Self-consumption removed (subscriber moved to Impl or deleted) | `src/Processing/TaskProcessor.Codeunit.al:24–31` | ❌ |
| 2.3 | `OnAfterProcessTask` integration event (code-level process event) | `src/Processing/TaskProcessor.Codeunit.al` | ❌ |
| 2.3 | `OnBeforePost` / `OnAfterPost` in posting pipeline | `src/Vouchers/` | ❌ |
| 2.4 | Discovery event — task type self-registration | Step 7 buffer | ⏭ |
| 2.5 | Manual event subscriber (`BindSubscription` / `UnbindSubscription`) | Step 7 buffer | ⏭ |

---

## Step 8 — Testing

**Patterns: 5.3 Mock via Interface · 5.1 Test Isolation**

| # | Item | File | Status |
|---|---|---|:---:|
| 5.1 | Test app project | `TaskFramework.Tests/` | ❌ |
| 5.3 | Mock `ITaskProcessor` implementation | `TaskFramework.Tests/src/` | ❌ |
| 5.3 | Test codeunit — processes task via injected mock | `TaskFramework.Tests/src/` | ❌ |

---

## Step 9 — Big Picture

**Patterns: 4.5 Internal Modularization · 6.3 Telemetry · 4.6 App Composition**

| # | Item | File | Status |
|---|---|---|:---:|
| 4.5 | Namespace structure (`Core`, `Core.Archive`, `Core.Errors`, `Processing`, `Setup`, `Vouchers`) | All `*.al` files | ✅ |
| 4.6 | Three-app structure (Framework · Impl · Tests) | Repo root | ✅ structure, ❌ content split |
| 6.3 | Telemetry emitted inside `ITaskProcessor` interface contract | depends on Step 3 | ❌ |
| D.1 | Companion Table vs. Table Extension — audience discussion point | Step 9 buffer | ⏭ |
| N.1 | Seams (Vieko/Directions) — defined swap points, AI relevance | Step 9 buffer | ⏭ |

---

## Dropped Patterns

These are in the catalog but explicitly out of scope for the workshop.

| # | Pattern | Reason |
|---|---|---|
| 2.3 | ~~Process Events~~ (as standalone) | Covered within 2.1 — not a distinct pattern |
| 5.2 | ~~Test Library / Helper~~ | Christian not a fan; deprioritised |
| 6.4 | ~~Assisted Setup / Wizard~~ | Christian strongly against |
| 1.9 | ~~Temp Table as Data Structure~~ | Audience likely knows; low score (12) |
| 3.3 | Header / Line | Quick mention only — no hands-on |
| 3.4 | Supplemental / Related Table | Catalog only — not in shortlist |
| 4.2 | Document → Posted Document | Slide / analogy only |
| 4.3 | Management / Helper Codeunit | "Not as important anymore" — covered by 1.3 |
| 6.5 | Number Series | Catalog only — not in shortlist |
| N.2 | ~~Transactions / Data Consistency~~ | "That's Day 2" — fills its own workshop |
| N.3 | ~~Queries~~ | Own topic, out of scope |
| N.4 | Page Background Tasks | Out of scope |

---

## Quick Reference — Objects by Namespace

| Namespace | Objects present |
|---|---|
| `Techdays.TaskFramework.Core` | `Task Log Entry`, `Task Type`, `Task Status`, `Task Verbosity`, `Task Log Entry Card`, `Task Log Entries` |
| `Techdays.TaskFramework.Core.Archive` | `Task Log Archive` (table + page), `Task Archive Reason` |
| `Techdays.TaskFramework.Core.Errors` | `Task Error Log`, `Task Error Handler` |
| `Techdays.TaskFramework.Processing` | `Task Processor`, `Task Processing State` |
| `Techdays.TaskFramework.Setup` | `Task Framework Setup` (table + page) |
| `Techdays.TaskFramework.Vouchers` | `Voucher Entry`, `Post Vouchers`, `Voucher Entry Card`, `Voucher Entries` |
| `Techdays.TaskFramework.Install` | `Install Task Framework` |
| `Techdays.TaskFramework.Impl` | `Install Task Framework Impl` |
