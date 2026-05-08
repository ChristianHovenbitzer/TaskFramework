# Step 3 — The Interface Revolution — Cheat Sheet

> Companion to the "While You Code — Step 3" slide. More room here for details and hints.
> **No copy-paste-ready code on purpose** — type it yourself, that's where the learning happens.

## What you're building in this step

Replace the monster `CASE` in `Task Processor` with an interface. Each task type
gets its own codeunit implementing `ITask Processor`. The `Task Type` enum binds
each value to its implementation, so a single line —
`Processor := TaskLogEntry."Task Processing Type"` — replaces the entire routing block.

By the end: the framework still owns generic infrastructure work (log retention,
a default fallback) but **knows nothing about Vendors, Vouchers, or Documents**.
That business-specific code lives in the Implementation app, plugged in via an
enum extension.

## Files you'll touch

**New (in Framework app):**
- `TaskFramework/src/Processing/ITaskProcessor.Interface.al` — the contract
- `TaskFramework/src/Processing/DefaultTaskProcessor.Codeunit.al` — fallback for `None` and unbound values; required because the enum's `DefaultImplementation` references it
- `TaskFramework/src/Processing/LogRetentionProcessor.Codeunit.al` — generic infrastructure, stays in the framework

**New (in Impl app):**
- `TaskFramework.Impl/src/processors/VendorImportProcessor.Codeunit.al` — `internal`, `implements "ITask Processor"`
- `TaskFramework.Impl/src/processors/DocumentImportProcessor.Codeunit.al` — same shape
- `TaskFramework.Impl/src/processors/TaskTypeExt.EnumExt.al` — adds `VendorImport` and `DocumentImport` to the enum

**Modified (Framework app):**
- `TaskFramework/src/Core/TaskType.Enum.al` — `Extensible = true`, `implements "ITask Processor"`, `DefaultImplementation = ...`, bind `None` and `LogRetention` to their impls; **delete** the `VendorImport` and `DocumentImport` values (they move to the extension)
- `TaskFramework/src/Processing/TaskProcessor.Codeunit.al` — the monster shrinks; CASE goes, per-type local procedures go, `ExtractValue` goes
- `TaskFramework/src/Core/TaskLogEntries.page.al` — the New action's default `Task Processing Type` must switch from `VendorImport` (which is now an extension value the framework can't see) to `LogRetention`

**Moved out of Framework:**
- `TaskFramework/src/Install/InstallTaskFramework.codeunit.al` → `TaskFramework.Impl/src/install/InstallTaskFramework.codeunit.al` — the install codeunit seeds Vendor/Voucher demo data, so it belongs in the Impl app

## Tasks (in order)

### 1. Define the interface
**Goal:** declare the contract every task type must satisfy.
**Where:** new file `TaskFramework/src/Processing/ITaskProcessor.Interface.al`.
**Hint:** one method — `ProcessTask(var TaskLogEntry: Record "Task Log Entry")`. That's the whole interface for now. Resist the urge to add error or telemetry parameters — that comes later.

### 2. Create the processor codeunits — codeunit *first*, then enum
**Goal:** five new codeunits, each implementing `ITask Processor`, all `Access = Internal` (only the enum is public).

In the **Framework app** (`TaskFramework/src/Processing/`):
- `Default Task Processor` — handles the `None` value and any unbound enum values. Body: `Error('No processor registered for task type %1.', TaskLogEntry."Task Processing Type")`.
- `Log Retention Processor` — generic archive cleanup; body is the old `ProcessLogRetention` content from `TaskProcessor.Codeunit.al`.

In the **Impl app** (`TaskFramework.Impl/src/processors/`):
- `Vendor Import Processor` — body is the old `ProcessVendorImport`.
- `Document Import Processor` — body is the old `ProcessDocumentImport`.

**Why this order matters:** create the codeunit *before* the enum extension references it. If you extend the enum first, the `Implementation = "ITask Processor" = "Vendor Import Processor"` line points at a codeunit that doesn't exist yet — symbol references break and the compiler complains in confusing ways.

**Hint:** the crude `ExtractValue` helper can live as a `local procedure` in each processor that needs it (Vendor and Document do; LogRetention doesn't), or as a single shared utility — your call. End branch keeps it as a duplicated local — fine for now, can be refactored later.

### 3. Wire the enum to the interface
**Goal:** the enum implements the interface and routes to the new codeunits.
**Where:** `TaskFramework/src/Core/TaskType.Enum.al` and the new enum extension in Impl.

On the framework enum:
- Flip `Extensible = false` to `true`.
- Add `implements "ITask Processor"` to the enum header.
- Add `DefaultImplementation = "ITask Processor" = "Default Task Processor";`.
- On `None`, add `Implementation = "ITask Processor" = "Default Task Processor"`.
- Keep `LogRetention` and bind it: `Implementation = "ITask Processor" = "Log Retention Processor"`.
- **Delete the `VendorImport` and `DocumentImport` values** — they're moving to the Impl app.

In the Impl app, create `TaskTypeExt.EnumExt.al`:
```
enumextension 60000 "Task Type Ext." extends "Task Processing Type"
```
with `value(60000; VendorImport)` and `value(60001; DocumentImport)`, each binding to its processor codeunit via `Implementation = "ITask Processor" = "..."`.

**Decision point:** business-specific values belong in the extension, not in the framework enum. `LogRetention` stays in the framework because retention is generic infrastructure — it has no business semantics. This split is what makes the Impl app a true plug-in.

### 4. Slim down Task Processor — kill the monster
**Goal:** the entire CASE block becomes one line.
**Where:** `TaskFramework/src/Processing/TaskProcessor.Codeunit.al`.
**Hint:** declare `Processor: Interface "ITask Processor"`, assign `Processor := TaskLogEntry."Task Processing Type"` (enum→interface), call `Processor.ProcessTask(TaskLogEntry)`. Delete `ProcessVendorImport`, `ProcessLogRetention`, `ProcessDocumentImport`, and `ExtractValue`. The framework no longer needs the `using Microsoft.Purchases.Vendor;` line — drop it.
**Heads-up:** once you delete `VendorImport` from the framework enum, the framework's `TaskLogEntries` page can no longer reference it. The New action defaults to `Task Processing Type::VendorImport` — change that to `LogRetention`, which is still in the framework enum.

### 5. Move the Install codeunit out of the framework
**Goal:** the framework app stops seeding Vendor and Voucher demo data — that's the Impl app's concern.
**Where:** move `TaskFramework/src/Install/InstallTaskFramework.codeunit.al` to `TaskFramework.Impl/src/install/InstallTaskFramework.codeunit.al`.
**Hint:** change the codeunit ID from the framework range (50002) to the impl range (60002), and delete the now-empty `TaskFramework/src/Install/` folder. The existing minimal `Install Task Framework Impl` codeunit (60000) can stay alongside it.
**Why this matters:** seeding `VOUCH-001`, `Workshop Vendor GmbH`, etc. requires the Voucher Entry table and the business-specific enum values — the framework can't reach those once they're in the Impl app's enum extension. The install belongs where the data lives.

## Done when

- [ ] `ITask Processor` interface exists in the Framework app
- [ ] `Default Task Processor` and `Log Retention Processor` exist in the Framework app, both `internal`
- [ ] `Vendor Import Processor` and `Document Import Processor` exist in the Impl app, both `internal`
- [ ] The framework's `Task Type` enum: `Extensible = true`, implements the interface, has `DefaultImplementation`, contains only `None` and `LogRetention`, and binds each to its impl
- [ ] The Impl app's enum extension adds `VendorImport` and `DocumentImport`, each bound to its processor
- [ ] `Task Processor` no longer contains a CASE on Task Type, no per-type local procedures, no `using Microsoft.Purchases.Vendor`
- [ ] `TaskLogEntries` page New action defaults to `LogRetention` (was `VendorImport`)
- [ ] The framework's Install codeunit has been moved to the Impl app
- [ ] App compiles, install runs, "Process All Pending" still works for all three task types

## If you get stuck

- See `STEP-3.md` (in the Framework app folder) for Christian's longer reference write-up — it covers the same ground in more depth.
- The `// TODO: (Step 3 …)` markers in the code mark the precise spots to edit.
- Ordering trap: codeunit must exist before the enum tries to bind to it. If symbols look weird, save and rebuild after each new file.
- Last resort: `git checkout step-3-end` and diff against your work.

## Heads-up: where Step 3 stops

The Impl app's install codeunit and the framework page actions still reference
specific task types by name (`VendorImport`, `LogRetention`, `DocumentImport`).
That's fine — the Impl app *should* know about its own types, and Step 4
(Factory) addresses what's left of the hardcoding inside the framework.
