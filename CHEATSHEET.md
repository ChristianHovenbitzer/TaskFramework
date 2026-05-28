# Step 3 — The Interface Revolution — Cheat Sheet

> Companion to the "While You Code — Step 3" slide. More room here for details and hints.
> **No copy-paste-ready code on purpose** — type it yourself, that's where the learning happens.

## What you're building in this step

Kill the monster `case` in `Task Processor`. Replace it with one line of interface dispatch driven by the enum.

After Step 3:

1. The framework knows `None` and `LogRetention`. Nothing else. No `VendorImport`, no `DocumentImport`.
2. Adding a fourth task type means one enum extension value plus one codeunit in the consuming app. Zero edits to the framework.
3. `Task Processor.ProcessTaskEntry` shrinks and stops mentioning vendors, documents, or any other domain.
4. Vendors and documents live in `TaskFramework.Impl`. The framework no longer compiles a single `Record Vendor` reference.

## Files you'll touch

- [TaskType.Enum.al](TaskFramework/src/Core/TaskType.Enum.al) — make the enum extensible, bind it to the interface, and reduce framework-owned values to `None` and `LogRetention`
- [TaskProcessor.Codeunit.al](TaskFramework/src/Processing/TaskProcessor.Codeunit.al) — collapse the routing block to interface dispatch and remove domain-specific procedures
- [TaskLogEntries.page.al](TaskFramework/src/Core/TaskLogEntries.page.al) — change the default task type for the New action
- [ITaskProcessor.Interface.al](TaskFramework/src/Processing/ITaskProcessor.Interface.al) — new interface contract
- [DefaultTaskProcessor.Codeunit.al](TaskFramework/src/Processing/DefaultTaskProcessor.Codeunit.al) — new fallback implementation in the Framework app
- [LogRetentionProcessor.Codeunit.al](TaskFramework/src/Processing/LogRetentionProcessor.Codeunit.al) — extract log-retention processing into its own Framework processor
- [VendorImportProcessor.Codeunit.al](TaskFramework.Impl/src/processors/VendorImportProcessor.Codeunit.al) — new Impl-app processor
- [DocumentImportProcessor.Codeunit.al](TaskFramework.Impl/src/processors/DocumentImportProcessor.Codeunit.al) — new Impl-app processor
- [TaskTypeExt.EnumExt.al](TaskFramework.Impl/src/processors/TaskTypeExt.EnumExt.al) — enum extension for business-specific task types
- [InstallTaskFramework.codeunit.al](TaskFramework/src/Install/InstallTaskFramework.codeunit.al) — move this out of the Framework app
- [InstallTaskFramework.codeunit.al](TaskFramework.Impl/src/install/InstallTaskFramework.codeunit.al) — relocated install codeunit in the Impl app

## Tasks (in order)

### 1. Define the interface
**Goal:** declare the contract every task type must satisfy.
**Where:** [ITaskProcessor.Interface.al](TaskFramework/src/Processing/ITaskProcessor.Interface.al).
**Hint:** one method only:

```al
procedure ProcessTask(var TaskLogEntry: Record "Task Log Entry");
```

No return value, no `IsHandled`, no error string. The contract is "do the thing, or `Error()`."

### 2. Create the processor codeunits — codeunit first, enum second
**Goal:** new processor codeunits in both apps, all `Access = Internal`.

In the **Framework app**:
- [DefaultTaskProcessor.Codeunit.al](TaskFramework/src/Processing/DefaultTaskProcessor.Codeunit.al) — fallback for `None` and unbound values
- [LogRetentionProcessor.Codeunit.al](TaskFramework/src/Processing/LogRetentionProcessor.Codeunit.al) — move the old `ProcessLogRetention` body here

In the **Impl app**:
- [VendorImportProcessor.Codeunit.al](TaskFramework.Impl/src/processors/VendorImportProcessor.Codeunit.al) — move the old `ProcessVendorImport` body here
- [DocumentImportProcessor.Codeunit.al](TaskFramework.Impl/src/processors/DocumentImportProcessor.Codeunit.al) — move the old `ProcessDocumentImport` body here

**Why this order matters:** create the codeunit before the enum or enum extension references it. Otherwise the `Implementation = "ITask Processor" = "..."` binding points at a codeunit that does not exist yet.

**Hint:** keep `ExtractValue` as a local helper inside the processors that need it. Do not pre-abstract it here.

### 3. Bind the enum to the interface
**Goal:** the enum implements the interface and routes to the new codeunits.
**Where:** [TaskType.Enum.al](TaskFramework/src/Core/TaskType.Enum.al) and [TaskTypeExt.EnumExt.al](TaskFramework.Impl/src/processors/TaskTypeExt.EnumExt.al).

On the framework enum:
- flip `Extensible = false` to `true`
- add `implements "ITask Processor"`
- add `DefaultImplementation = "ITask Processor" = "Default Task Processor"`
- bind `None` to `Default Task Processor`
- keep `LogRetention` and bind it to `Log Retention Processor`
- delete `VendorImport` and `DocumentImport` from the framework enum

In the Impl app:
- create the enum extension
- add `VendorImport` and `DocumentImport`
- bind each extension value to its processor

**Why this split matters:** business-specific values belong in the extension, not in the framework enum. `LogRetention` stays in the framework because it is infrastructure, not business logic.

### 4. Move the install codeunit to Impl
**Goal:** the framework app stops seeding Vendor and Voucher demo data.
**Where:** move [InstallTaskFramework.codeunit.al](TaskFramework/src/Install/InstallTaskFramework.codeunit.al) to [TaskFramework.Impl/src/install/InstallTaskFramework.codeunit.al](TaskFramework.Impl/src/install/InstallTaskFramework.codeunit.al).
**Hint:** the codeunit ID must move to the Impl range. The framework app should no longer compile against business-specific task types or demo data.

### 5. Slim down Task Processor — kill the monster
**Goal:** the entire CASE block becomes one line.
**Where:** [TaskProcessor.Codeunit.al](TaskFramework/src/Processing/TaskProcessor.Codeunit.al).
**Hint:** declare `Processor: Interface "ITask Processor"`, assign `Processor := TaskLogEntry."Task Processing Type"`, call `Processor.ProcessTask(TaskLogEntry)`. Delete the CASE block, the per-type local procedures, and `ExtractValue`.
**Also fix:** [TaskLogEntries.page.al](TaskFramework/src/Core/TaskLogEntries.page.al) can no longer default new rows to `VendorImport`, because that value moved into the extension. Change the default to `LogRetention`.

## Done when

- [ ] `ITask Processor` interface exists in the Framework app
- [ ] `Default Task Processor` and `Log Retention Processor` exist in the Framework app, both `internal`
- [ ] `Vendor Import Processor` and `Document Import Processor` exist in the Impl app, both `internal`
- [ ] The framework enum is extensible, implements the interface, has `DefaultImplementation`, and contains only `None` and `LogRetention`
- [ ] The Impl app enum extension adds `VendorImport` and `DocumentImport`, each bound to its processor
- [ ] `Task Processor` no longer contains a CASE on task type, no per-type local procedures, and no `using Microsoft.Purchases.Vendor`
- [ ] `TaskLogEntries` defaults to `LogRetention`
- [ ] The framework's Install codeunit has been moved to the Impl app
- [ ] App compiles, install runs, "Process All Pending" still works for all three task types

## If you get stuck

- The `// TODO: (Step 3 …)` markers in the code mark the precise spots to edit.
- Ordering trap: codeunit must exist before the enum tries to bind to it. If symbols look weird, save and rebuild after each new file.
- Last resort: `git checkout step-3-end` and diff against your work.

## Out of scope today

- The `OnBeforeProcessTask` self-published event — Step 7
- `Task Processor.ProcessTaskEntry` resolves the interface inline. A factory makes that swappable for tests — Step 4
- The Impl processors still hand-parse payloads with `ExtractValue` — Step 5
- `Post Vouchers` still flips a status flag — Step 5
- `Error()` in `Default Task Processor` still aborts a batch — Step 6
- No tests yet for the new processors — Step 8
