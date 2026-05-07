# Step 3 — Interface Revolution

**Patterns:** 1.1 DI / Strategy · 1.7 Enum implements Interface · 1.8 Method Codeunit (before) · 2.2 Handled Pattern (before)
**Reference:** [pattern-status.md](../docs/pattern-status.md#step-3--interface-revolution)

## Goal

Kill the monster `case` in `Task Processor`. Replace it with one line of interface dispatch driven by the enum.

After Step 3:

1. The framework knows `None` and `LogRetention`. Nothing else. No `VendorImport`, no `DocumentImport`.
2. Adding a fourth task type means **one enum extension value + one codeunit** in the consuming app. Zero edits to the framework.
3. `Task Processor.ProcessTaskEntry` shrinks to ~15 lines and stops mentioning vendors, documents, or any other domain.
4. Vendors live in `TaskFramework.Impl`. So do documents. The framework app no longer compiles a single `Record Vendor` reference.

## TODOs

Find them with `grep -rn "Step 3" src ../TaskFramework.Impl/src`.

### 1. Define the interface

New file: `src/Processing/ITaskProcessor.Interface.al`.

One method only:

```al
procedure ProcessTask(var TaskLogEntry: Record "Task Log Entry");
```

No return value, no `IsHandled`, no error string. The contract is "do the thing, or `Error()`." Keep it small — every method here is one every implementer is forced to write.

> **Discuss:** why no `Boolean` return? (Hint: substitutability — Step 6's collectible-error work would force every implementer to learn the same return convention. Defer it.)

### 2. Bind the enum to the interface

[TaskType.Enum.al](src/Core/TaskType.Enum.al) — three changes to the header, one per value:

- Header: `implements "ITask Processor"`, `Extensible = true`, `DefaultImplementation = "ITask Processor" = "Default Task Processor"`.
- On every value: `Implementation = "ITask Processor" = "<Codeunit Name>";`.
- **Reduce the framework values to `None` and `LogRetention` only.** `VendorImport` and `DocumentImport` move to an enum extension in Impl (TODO 7). The framework's enum must not name them.

> **Discuss:** why bother with `DefaultImplementation` on top of per-value `Implementation`? Walk through what happens when an external app extends the enum but forgets to bind the new value.

### 3. Create the default implementation

New file: `src/Processing/DefaultTaskProcessor.Codeunit.al`.

A one-procedure codeunit that errors with "No processor registered for task type %1." This is the safety net for `None` and any future enum extension that adds a value but forgets `Implementation`. Mark `Access = Internal`.

### 4. Extract `LogRetention` into its own processor

New file: `src/Processing/LogRetentionProcessor.Codeunit.al`. `Access = Internal`, `implements "ITask Processor"`.

Move the body of `ProcessLogRetention` (currently in [TaskProcessor.Codeunit.al](src/Processing/TaskProcessor.Codeunit.al)) into the new codeunit's `ProcessTask` method, verbatim.

> **Discuss:** why does `Log Retention Processor` stay in the framework instead of moving to Impl? (Hint: it operates on `Task Log Archive` — a framework-owned table. Vendors and documents are domain concerns; archive cleanup is housekeeping.)

### 5. Move `VendorImport` to Impl

New file: `../TaskFramework.Impl/src/processors/VendorImportProcessor.Codeunit.al`. Codeunit ID in the Impl range (e.g. 60001). `Access = Internal`, `implements "ITask Processor"`.

Move `ProcessVendorImport` from [TaskProcessor.Codeunit.al](src/Processing/TaskProcessor.Codeunit.al) into it. The `ExtractValue` helper goes along — duplicate it as a private helper inside the new codeunit. (Yes, two copies. Step 5's Builder will eliminate the duplication once both processors stop hand-parsing payloads. Don't pre-abstract.)

After this move, the framework no longer references `Record Vendor` or `Microsoft.Purchases.Vendor`. Confirm by removing the `using` from [TaskProcessor.Codeunit.al:1](src/Processing/TaskProcessor.Codeunit.al#L1).

### 6. Move `DocumentImport` to Impl

New file: `../TaskFramework.Impl/src/processors/DocumentImportProcessor.Codeunit.al`. Same shape as TODO 5. Move `ProcessDocumentImport` from [TaskProcessor.Codeunit.al](src/Processing/TaskProcessor.Codeunit.al). Carries its own copy of `ExtractValue` for now.

Note that this processor still calls `Post Vouchers.PostVoucher` directly — that's Step 5's problem. Don't refactor it here.

### 7. Wire the enum extension in Impl

New file: `../TaskFramework.Impl/src/processors/TaskTypeExt.EnumExt.al`.

`enumextension … extends "Task Processing Type"` with two values:

- `value(60000; VendorImport)` — `Implementation = "ITask Processor" = "Vendor Import Processor"`
- `value(60001; DocumentImport)` — `Implementation = "ITask Processor" = "Document Import Processor"`

Captions match what the framework used to publish. The IDs come from the Impl object range, **not** the framework range — that's the whole point of moving them out.

> **Discuss:** existing seeded rows store the enum as an **integer** in SQL. Before Step 3 the framework had `value(1; VendorImport)`, `value(2; LogRetention)`, `value(3; DocumentImport)`. After Step 3 the framework keeps only `value(0; None)` and `value(1; LogRetention)`, and the extension introduces `60000`/`60001`. So a row that stored `1` now resolves to `LogRetention`, not `VendorImport` — silently wrong. A row that stored `2` or `3` resolves to no enum value and BC renders the bare integer. In production this needs an upgrade codeunit; in this workshop the install codeunit re-seeds, so demo data lines up.

### 8. Move the install codeunit to Impl

The framework's [Install Task Framework](src/Install/InstallTaskFramework.codeunit.al) seeds rows that name `VendorImport` and `DocumentImport`. Those values now live in Impl, so the install codeunit must too — otherwise the framework app fails to compile against names it no longer knows.

Move the file to `../TaskFramework.Impl/src/install/InstallTaskFramework.codeunit.al`, change the `codeunit` ID to one in the Impl range (e.g. `60002`), and add the `using` directives for the framework namespaces it depends on.

> **Discuss:** the codeunit ID changes (50002 → 60002). For a fresh workshop install that's invisible. For an upgrade you'd need to rename or migrate. Note the cost of the move; don't try to fix it here.

### 9. Collapse the dispatch in `Task Processor`

[TaskProcessor.Codeunit.al](src/Processing/TaskProcessor.Codeunit.al) — replace the entire CASE block (and the three `Process*Import` local procedures it calls, and the `ExtractValue` helper) with two lines:

```al
Processor := TaskLogEntry."Task Processing Type";
Processor.ProcessTask(TaskLogEntry);
```

Declare `Processor: Interface "ITask Processor"` in the local var block. The `OnBeforeProcessTask` event and the surrounding state-handling stay exactly as Step 2 left them — Step 7 owns the event story.

After this edit, [TaskProcessor.Codeunit.al](src/Processing/TaskProcessor.Codeunit.al) should be roughly **half its current size** and contain zero domain-specific code.

## Verification

- `Task Processor` no longer mentions `Vendor`, `Voucher`, or `Archive` (the last lives in `Log Retention Processor` now).
- The framework's `Task Processing Type` enum lists only `None` and `LogRetention`.
- `TaskFramework.Impl` compiles four new objects: the enum extension, two processors, and the relocated install codeunit.
- Adding a hypothetical `EmailImport` task type requires zero changes in the framework — prove it by sketching the diff in your head: one enum extension value, one new codeunit.
- Run the seeded tasks end-to-end: vendor import still creates a vendor, log retention still purges archive rows, document import still posts a voucher.
- `grep -rn "Process[A-Z][a-z]*Import" src` returns nothing in the framework.

## Out of scope

Leave these — later steps own them:

- The `OnBeforeProcessTask` self-published event. Step 7.
- `Task Processor.ProcessTaskEntry` resolves the interface inline. A `Task Processor Factory` makes that swappable for tests. Step 4.
- Both Impl processors hand-parse payloads with their own `ExtractValue` copy. A `Voucher Journal Line Builder` and proper payload typing replace it. Step 5.
- `Post Vouchers` still flips a status flag. Step 5.
- `Error()` in `Default Task Processor` still aborts a batch. Step 6 will collect instead of throw.
- No tests yet for the new processors. Step 8 — once the Factory exists, the mock-via-interface pattern becomes trivial.
