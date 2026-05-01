# Step 3 — The Interface Revolution — Cheat Sheet

> Companion to the "While You Code — Step 3" slide. More room here for details and hints.
> **No copy-paste-ready code on purpose** — type it yourself, that's where the learning happens.

## What you're building in this step

Replace the monster `CASE` in `Task Processor` with an interface. Each task type
gets its own codeunit implementing `ITask Processor`. The `Task Type` enum binds
each value to its implementation, so a single line —
`Processor := TaskLogEntry."Task Processing Type"` — replaces the entire routing block.

By the end: the **Framework app knows nothing about Vendors, Vouchers, or Documents**.
All of that lives in the Implementation app, plugged in via the interface.

## Files you'll touch

**New (in Framework app):**
- `TaskFramework/src/Processing/ITaskProcessor.Interface.al` — the contract

**New (in Impl app):**
- `TaskFramework.Impl/src/Processors/VendorImportProcessor.Codeunit.al` — `internal`, `implements "ITask Processor"`
- `TaskFramework.Impl/src/Processors/LogRetentionProcessor.Codeunit.al` — same shape
- `TaskFramework.Impl/src/Processors/DocumentImportProcessor.Codeunit.al` — same shape
- (Optional) `DefaultTaskProcessor.Codeunit.al` — handle the `None` case

**Modified (Framework app):**
- `TaskFramework/src/Core/TaskType.Enum.al` — `Extensible = true`, `implements "ITask Processor"`, bind each value to its impl
- `TaskFramework/src/Processing/TaskProcessor.Codeunit.al` — the monster shrinks; CASE goes, per-type local procedures go, `ExtractValue` goes

## Tasks (in order)

### 1. Define the interface
**Goal:** declare the contract every task type must satisfy.
**Where:** new file `TaskFramework/src/Processing/ITaskProcessor.Interface.al`.
**Hint:** one method — `ProcessTask(var TaskLogEntry: Record "Task Log Entry")`. That's the whole interface for now. Resist the urge to add error or telemetry parameters — that comes later.

### 2. Move per-type logic into impl codeunits — codeunit *first*, then enum
**Goal:** three new codeunits in `TaskFramework.Impl`, each implementing `ITask Processor`.
**Where:** `TaskFramework.Impl/src/Processors/`. Make each codeunit `Access = Internal` — only the enum is public.
**Why this order matters:** create the codeunit *before* the enum extension references it. If you extend the enum first, the `Implementation = "ITask Processor" = "Vendor Import Processor"` line points at a codeunit that doesn't exist yet — symbol references break and the compiler complains in confusing ways.
**Hint:** copy the body of `ProcessVendorImport` into `Vendor Import Processor.ProcessTask`, same for the other two. The crude `ExtractValue` helper can live as a `local procedure` in each codeunit, or as a single shared utility — your call.

### 3. Make the Task Type enum extensible and bind it
**Goal:** the enum implements the interface and routes to your new codeunits.
**Where:** `TaskFramework/src/Core/TaskType.Enum.al`.
**Hint:** flip `Extensible = false` to `true`, add `implements "ITask Processor"` to the enum header, then on each `value()` add `Implementation = "ITask Processor" = "Vendor Import Processor"` (etc).
**Decision point:** the business-specific enum values (VendorImport, LogRetention, DocumentImport) belong in an **enum extension in the Impl app**, not in the framework's enum. The framework's enum should only have `None`. This is what makes the Impl app a true plug-in.

### 4. Slim down Task Processor — kill the monster
**Goal:** the entire CASE block becomes one line.
**Where:** `TaskFramework/src/Processing/TaskProcessor.Codeunit.al`.
**Hint:** declare `Processor: Interface "ITask Processor"`, assign `Processor := TaskLogEntry."Task Processing Type"` (enum→interface), call `Processor.ProcessTask(TaskLogEntry)`. Delete `ProcessVendorImport`, `ProcessLogRetention`, `ProcessDocumentImport`, and `ExtractValue`. The framework no longer needs the `using Microsoft.Purchases.Vendor;` line — drop it.

### 5. Delete the self-subscribed event
**Goal:** remove `OnBeforeProcessTask` and its in-codeunit subscriber.
**Where:** `TaskProcessor.Codeunit.al`, top of the file.
**Why:** publishing and subscribing to your own event in the same app is an anti-pattern — you can just call the function. We'll re-introduce a *real* extensibility event in Step 7.

## Done when

- [ ] `ITask Processor` interface exists in the Framework app
- [ ] Three (or four) processor codeunits exist in the Impl app, all `internal` and implementing the interface
- [ ] The `Task Type` enum is extensible, implements the interface, and binds each value to its impl codeunit
- [ ] `Task Processor` no longer contains a CASE on Task Type, and no longer references `Vendor`
- [ ] The self-subscribed `OnBeforeProcessTask` event is gone
- [ ] App compiles, install runs, "Process All Pending" still works for all three task types

## If you get stuck

- See `docs/pattern-status.md` Step 3 section — the ❌ rows are exactly what you're filling in.
- The `// TODO: (Step 3 …)` markers in the code mark the precise spots to edit.
- Ordering trap: codeunit must exist before the enum tries to bind to it. If symbols look weird, save and rebuild after each new file.
- Last resort: `git checkout step-3-end` and diff against your work.

## Heads-up: where Step 3 stops

You'll notice the page actions and the install codeunit still hardcode specific task
types. That's fine — Step 4 (Factory) is what closes that loop. Don't try to also
remove `TaskLogEntry."Task Processing Type"` references everywhere right now.
