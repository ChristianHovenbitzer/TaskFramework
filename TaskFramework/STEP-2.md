# Step 2 — Clean Structure

**Patterns:** 3.2 Setup Table · 4.4 Layered Architecture · 1.3 Facade
**Reference:** [pattern-status.md](../docs/pattern-status.md#step-2--clean-structure-separation-of-concerns-setup-table-facade)

## Goal

Pull the prototype apart so the next steps have somewhere to plug in. Three shifts:

1. Configuration moves from code into the Setup table.
2. Pages stop running business logic; codeunits own it.
3. State and side effects live where the call graph can reach them — not inside a `SingleInstance` that nobody owns.

Done right, every page action shrinks to a single delegating call, and `Task Processor` is the front door for everyone else.

## TODOs

Find them with `grep -rn "Step 2" src ../TaskFramework.Impl/src`.

### 1. Add a Log Retention setup field

[TaskFrameworkSetup.Table.al:34](src/Setup/TaskFrameworkSetup.Table.al#L34)

Add a field for "days of archive history to keep". Surface it on [TaskFrameworkSetup.Page.al](src/Setup/TaskFrameworkSetup.Page.al) under the existing `Archive` group. Match the current hardcoded value as `InitValue` so upgrades don't change behavior.

While you are in the Setup table, add a small helper that callers can use to read it without ceremony:

```al
procedure GetRecordOnce(): Record "Task Framework Setup"
```

Get-or-Insert in two lines. Returns `Rec` so the caller can read fields straight off the result. This becomes the standard read path for everything that touches Setup.

> **Discuss:** what should `0` mean — keep nothing, or keep everything? Decide once. (Hint: `MinValue = 1` makes the question go away.)

### 2. Read retention from Setup

[TaskProcessor.Codeunit.al:173](src/Processing/TaskProcessor.Codeunit.al#L173)

Replace the literal `30` with a call to your new `GetRecordOnce()` and read `"Retention Days"` off the result. The format string two lines down already renders `RetentionDays` — leave it; it now mirrors whatever Setup says.

### 3. Reshape the Task Processing State codeunit

[TaskProcessingState.Codeunit.al](src/Processing/TaskProcessingState.Codeunit.al), with consequences in [TaskProcessor.Codeunit.al:35-44](src/Processing/TaskProcessor.Codeunit.al#L35-L44) and `ProcessAllPendingTasks`.

The codeunit itself is fine — what's wrong is **how** it lives and **how** it gets called. Two separate problems, two separate fixes:

**Problem A — `SingleInstance` leakage.** `SingleInstance = true` makes the codeunit a per-session singleton. State leaks across batches and breaks the moment Job Queue, background sessions, or page background tasks run the processor. The metric becomes "whatever happened since this user logged in," which is not what anyone wants.

→ Drop the `SingleInstance` property. The codeunit becomes a normal instance again.

**Problem B — call routed through the wrong mechanism.** Today, `Task Processor` publishes `OnBeforeProcessTask`, then subscribes to its *own* event in the same app just to bump the counter. Publish-and-subscribe-to-yourself is never the right shape: there's no extension benefit, and the subscriber order is undefined the moment a real subscriber appears.

→ Delete the `HandleBeforeProcess` subscriber. The counter call is not extensibility; it is the framework's own bookkeeping. Move it into the framework's own code path.

**The fix in `Task Processor`:**

- Hold `Task Processing State` as a member variable of `Task Processor` — the processor is its lifecycle owner.
- After each successful `ProcessTaskEntry`, call `IncrementProcessedCount` and `SetLastProcessed` directly from the loop. No event hop.
- Expose a `GetTaskProcessingState()` getter so callers (and, later, tests) can read the metrics without grabbing a fresh instance.
- Pass the state codeunit *into* the `OnBeforeProcessTask` event signature so subscribers that legitimately need it (e.g. an external observer in Step 7) can read it. The event itself stays — see TODO 4.

What you've done in pattern terms: the state codeunit is no longer a leaky singleton; it's a **scoped collaborator** owned by the thing that drives it. The metric is now correct per batch, survives Job Queue, and is observable from outside.

> **Discuss:** what's the difference between "state belongs to a session" and "state belongs to a batch"? Which one did the original code accidentally pick? Which one do you want?
>
> **Discuss:** why pass the state into the event instead of letting subscribers `Codeunit.Run` their own copy? (Hint: substitutability and testability — the subscriber sees the same instance the processor sees.)

### 4. Remove the in-app subscriber, keep the event

[TaskProcessor.Codeunit.al:35-44](src/Processing/TaskProcessor.Codeunit.al#L35-L44)

The `OnBeforeProcessTask` event itself is a legitimate extension point — an external app may well want to short-circuit a task. What's wrong is *this app* subscribing to *its own* event. Delete the `HandleBeforeProcess` subscriber. Keep the event declaration. Keep the publish call inside `ProcessTaskEntry`. Step 7 will revisit the event's role; Step 2 only fixes the self-consumption.

### 5. Empty the Process action on the Task Log Entry Card

[TaskLogEntryCard.page.al:44-69](src/Core/TaskLogEntryCard.page.al#L44-L69)

The action duplicates `Task Processor.ProcessTaskEntry` badly — only `VendorImport` works. Shrink the trigger to one call into `Task Processor.ProcessTaskEntry(Rec)`. The page must not know about `Status`, `CurrentDateTime`, or task types.

### 6. Collapse to one posting path on Voucher Entries

[VoucherEntries.Page.al:38-61](src/Vouchers/VoucherEntries.Page.al#L38-L61)

Two actions today: one skips validation, one doesn't. Drop the broken one. The remaining `Post Selected` becomes a tight loop: `SetSelectionFilter`, `ReadIsolation(IsolationLevel::UpdLock)`, `FindSet`, call `PostVouchers.PostVoucher` per record. No status flips on the page, no `Status::Draft` filter, no `Posting Date` assignment — `Post Vouchers` already owns those.

> **Discuss:** the page now has one action. Is the `Post Vouchers` codeunit the *facade*, or is it just the implementation? In this codebase, with one consumer, they're the same thing — adding a wrapper would be ceremony. Step 5 will change the answer when the journal pipeline arrives.

### Buffer — guard clauses

Optional. Flatten any `if … then begin … end else …` blocks you touched using early `exit;` guards.

## Verification

- Every page action: one call, no branching.
- No literal config values left in business code.
- `Task Processing State` exists, is **not** `SingleInstance`, and is held by `Task Processor`.
- The `HandleBeforeProcess` subscriber is gone.
- The `OnBeforeProcessTask` event still exists and is still called.
- Open Setup, change `Retention Days`, run the LogRetention task, confirm the cutoff matches.

## Out of scope

Leave these — later steps own them:

- The monster `case` in `Task Processor` → Step 3 / 4.
- `ProcessVendorImport` and `ProcessDocumentImport` in the framework → Step 3.
- `Post Vouchers` faking posting via status flip → Step 5.
- Single `Error()` aborting the batch → Step 6.
- The role of `OnBeforeProcessTask` as an extension point → Step 7.
