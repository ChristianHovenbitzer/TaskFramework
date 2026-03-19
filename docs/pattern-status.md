# Pattern Status — Task Framework Workshop

Maps every workshop pattern and anti-pattern to its current location in the codebase,
and tracks what is still missing (i.e. added during the hands-on steps).

> **Legend**
> - ✅ Present — intentionally baked in (anti-pattern) or already implemented
> - ❌ Missing — will be added / fixed during the corresponding workshop step

---

## Step 1 — "What's Wrong Here?" (Anti-Pattern Prototype)

These problems are **intentionally baked in** so the audience can spot them.

| Anti-Pattern | File | Notes |
|---|---|---|
| `SingleInstance` codeunit storing mutable state | `src/Processing/TaskProcessingState.Codeunit.al` | ✅ State lost on session end; breaks Job Queue |
| Publishing **and** subscribing own events in same app | `src/Processing/TaskProcessor.Codeunit.al:19–31` | ✅ Zero benefit — just call the function directly |
| Monster `CASE` routing — framework knows all task types | `src/Processing/TaskProcessor.Codeunit.al:62–71` | ✅ Adding task type 4 requires editing the framework |
| No error isolation in batch loop | `src/Processing/TaskProcessor.Codeunit.al:37–45` | ✅ Entry 3 of 10 throws → entries 4–10 never run |
| Business logic in page trigger (`OnAction` processes inline) | `src/Core/TaskLogEntryCard.page.al:44–68` | ✅ Duplicated, untestable, bypasses processor |
| `ERROR()` stops on first problem, no detail | `src/Vouchers/PostVouchers.Codeunit.al:12–18` | ✅ Customer missing AND amount zero → only see Customer error |
| Posting is a status flip — no ledger, no register | `src/Vouchers/PostVouchers.Codeunit.al:22–25` | ✅ "Posted" record is still editable |
| Hardcoded retention period (30 days), ignores Setup | `src/Processing/TaskProcessor.Codeunit.al:116` | ✅ Setup table exists but is not read |
| Impl app nearly empty — all logic wrongly in framework | `TaskFramework.Impl/src/install/InstallTaskFrameworkImpl.Codeunit.al` | ✅ VendorImport, LogRetention, DocumentImport belong in Impl |

---

## Step 2 — Clean Structure (Separation of Concerns, Setup Table, Facade)

**Patterns: 3.2 Setup Table · 4.4 Layered Architecture · 1.3 Facade**

| Item | File | Status |
|---|---|:---:|
| Setup Table with all config fields (Verbosity, Batch Size, Archive, Retry…) | `src/Setup/TaskFrameworkSetup.Table.al` | ✅ |
| Setup Page with grouped layout | `src/Setup/TaskFrameworkSetup.Page.al` | ✅ |
| Setup table seeded on install | `src/Install/InstallTaskFramework.codeunit.al` | ✅ |
| Facade codeunit — single entry point for pages | `src/Processing/` — `Task Framework Facade` | ❌ |
| `ProcessLogRetention` reads retention days from Setup | `src/Processing/TaskProcessor.Codeunit.al:116` | ❌ (hardcoded 30) |
| Business logic extracted from `OnAction` page trigger | `src/Core/TaskLogEntryCard.page.al:44–68` | ❌ |

---

## Step 3 — Interface Revolution

**Patterns: 1.1 DI/Strategy · 1.7 Enum · 1.8 Method Codeunit (before) · 2.2 Handled Pattern (before)**

| Item | File | Status |
|---|---|:---:|
| `TaskType` enum — discriminator for factory + interface binding | `src/Core/TaskType.Enum.al` | ✅ |
| `TaskStatus` enum | `src/Core/TaskStatus.Enum.al` | ✅ |
| `TaskVerbosity` enum | `src/Core/TaskVerbosity.enum.al` | ✅ |
| `OnBeforeProcessTask(var Handled)` — the "before" (Method Codeunit / Handled Pattern) | `src/Processing/TaskProcessor.Codeunit.al:19–31` | ✅ (anti-pattern, shown as "before") |
| `ITaskProcessor` interface | `src/Processing/` — `ITaskProcessor.Interface.al` | ❌ |
| `VendorImport Processor` implementing `ITaskProcessor` | `TaskFramework.Impl/src/` | ❌ |
| `LogRetention Processor` implementing `ITaskProcessor` | `TaskFramework.Impl/src/` | ❌ |
| `DocumentImport Processor` implementing `ITaskProcessor` | `TaskFramework.Impl/src/` | ❌ |

---

## Step 4 — Factory Routing

**Pattern: 1.2 Factory**

| Item | File | Status |
|---|---|:---:|
| `Task Processor Factory` — maps `TaskType` enum → `ITaskProcessor` impl | `src/Processing/` — `TaskProcessorFactory.Codeunit.al` | ❌ |
| `CASE` routing removed from `TaskProcessor` | `src/Processing/TaskProcessor.Codeunit.al:62–71` | ❌ |

---

## Step 5 — Posting Pipeline + Builder

**Patterns: 4.1 Journal → Posting → Ledger Entry · 1.5 Builder · 3.1 Archiving**

| Item | File | Status |
|---|---|:---:|
| `Task Log Archive` table (all new fields incl. Verbosity, Correlation Id, Archive Reason) | `src/Core/Archive/TaskLogArchive.table.al` | ✅ |
| `Task Log Archive` page | `src/Core/Archive/TaskLogArchive.page.al` | ✅ |
| `Archive After Processing` flag triggers `ArchiveEntry` on complete | `src/Processing/TaskProcessor.Codeunit.al:77–102` | ✅ |
| `Earliest Processing DateTime` filter in batch loop | `src/Processing/TaskProcessor.Codeunit.al:41` | ✅ |
| `TaskArchiveReason` enum | `src/Core/Archive/TaskArchiveReason.enum.al` | ✅ |
| `Voucher Entry` table (draft staging, anti-pattern placeholder) | `src/Vouchers/VoucherEntry.Table.al` | ✅ (replaced in Step 5) |
| `Post Vouchers` codeunit (stub — status flip, no ledger) | `src/Vouchers/PostVouchers.Codeunit.al` | ✅ (replaced in Step 5) |
| `Voucher Journal Line` table | `src/Vouchers/` | ❌ |
| `Voucher Ledger Entry` table | `src/Vouchers/` | ❌ |
| `Voucher Register` table | `src/Vouchers/` | ❌ |
| `Voucher Jnl.-Check Line` codeunit | `src/Vouchers/` | ❌ |
| `Voucher Jnl.-Post Line` codeunit | `src/Vouchers/` | ❌ |
| `Voucher Jnl.-Post Batch` codeunit | `src/Vouchers/` | ❌ |
| `Voucher Journal Line Builder` codeunit | `src/Vouchers/` | ❌ |

---

## Step 6 — Error Handling

**Patterns: 6.1 Collectible Errors · 6.2 Notification Pattern**

| Item | File | Status |
|---|---|:---:|
| `Task Error Log` table (structure: Entry No., Line No., Error Message, Is Blocking, Correlation Id…) | `src/Core/Errors/TaskErrorLog.table.al` | ✅ |
| `Task Error Handler` enum | `src/Core/Errors/TaskErrorHandler.enum.al` | ✅ |
| Error collector codeunit — writes to `Task Error Log` | `src/Core/Errors/` | ❌ |
| Processor / posting use collector instead of `ERROR()` | `src/Processing/TaskProcessor.Codeunit.al` | ❌ |
| Notification shown after batch (Error / Message / Notification) | `src/Processing/` | ❌ |

---

## Step 7 — Events & Extensibility

**Pattern: 2.1 Publisher/Subscriber**

| Item | File | Status |
|---|---|:---:|
| `OnBeforeProcessTask` integration event declared | `src/Processing/TaskProcessor.Codeunit.al:19–22` | ✅ (but self-consumed — anti-pattern) |
| Self-consumption removed (subscriber moved to Impl or deleted) | `src/Processing/TaskProcessor.Codeunit.al:24–31` | ❌ |
| `OnAfterProcessTask` integration event | `src/Processing/TaskProcessor.Codeunit.al` | ❌ |
| `OnBeforePost` / `OnAfterPost` in posting pipeline | `src/Vouchers/` | ❌ |

---

## Step 8 — Testing

**Patterns: 5.3 Mock via Interface · 5.1 Test Isolation**

| Item | File | Status |
|---|---|:---:|
| Test app project | `TaskFramework.Tests/` | ❌ |
| Mock `ITaskProcessor` implementation | `TaskFramework.Tests/src/` | ❌ |
| Test codeunit — processes task via injected mock | `TaskFramework.Tests/src/` | ❌ |

---

## Step 9 — Big Picture

**Patterns: 4.5 Internal Modularization · 6.3 Telemetry · 4.6 App Composition**

| Item | File | Status |
|---|---|:---:|
| Namespace structure (`Core`, `Core.Archive`, `Core.Errors`, `Processing`, `Setup`, `Vouchers`) | All `*.al` files | ✅ |
| Three-app split (Framework · Impl · Tests) | Repo root | ✅ structure, ❌ content split |
| Telemetry emitted inside `ITaskProcessor` contract | `ITaskProcessor.Interface.al` | ❌ (depends on Step 3) |

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
