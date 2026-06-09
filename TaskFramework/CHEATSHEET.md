# Step 2 — Clean Structure — Cheat Sheet

> Companion to the "While You Code — Step 2" slide. More room here for details and hints.
> **No copy-paste-ready code on purpose** — type it yourself, that's where the learning happens.

## What you're building in this step

Pull the prototype apart so the next steps have somewhere to plug in. Three shifts:

1. Configuration moves from code into the Setup table.
2. Pages stop running business logic; codeunits own it.
3. State and side effects live where the call graph can reach them — not inside a `SingleInstance` that nobody owns.

Done right, every page action shrinks to a single delegating call, and `Task Processor` is the front door for everyone else.

## Files you'll touch

- [TaskFrameworkSetup.Table.al](TaskFramework/src/Setup/TaskFrameworkSetup.Table.al) — add the retention field and a small helper to read Setup without ceremony
- [TaskFrameworkSetup.Page.al](TaskFramework/src/Setup/TaskFrameworkSetup.Page.al) — surface the retention field in the existing `Archive` group
- [TaskProcessor.Codeunit.al](TaskFramework/src/Processing/TaskProcessor.Codeunit.al) — read retention from Setup; reshape how processing state is owned and updated; remove the in-app self-subscriber
- [TaskProcessingState.Codeunit.al](TaskFramework/src/Processing/TaskProcessingState.Codeunit.al) — drop `SingleInstance`
- [TaskLogEntryCard.page.al](TaskFramework/src/Core/TaskLogEntryCard.page.al) — shrink the Process action to one delegating call
- [VoucherEntries.Page.al](TaskFramework/src/Vouchers/VoucherEntries.Page.al) — collapse the two posting paths into one

## Tasks (in order)

### 1. Add a Log Retention setup field
**Goal:** configuration moves into Setup instead of living as a hardcoded literal.
**Where:** [TaskFrameworkSetup.Table.al](TaskFramework/src/Setup/TaskFrameworkSetup.Table.al) and [TaskFrameworkSetup.Page.al](TaskFramework/src/Setup/TaskFrameworkSetup.Page.al).
**Hint:** add a field for "days of archive history to keep" and surface it under the existing `Archive` group. Match the current hardcoded value as `InitValue` so upgrades do not silently change behavior.
**Also add:** a small helper on the Setup table:

```al
procedure GetRecordOnce(): Record "Task Framework Setup"
```

Get-or-Insert in two lines. Return `Rec` so callers can read fields straight off the result. This becomes the standard read path for Setup.

> **Discuss:** what should `0` mean — keep nothing, or keep everything? Decide once. `MinValue = 1` makes the question go away.

### 2. Read retention from Setup
**Goal:** kill the hardcoded `RetentionDays := 30;`.
**Where:** [TaskProcessor.Codeunit.al](TaskFramework/src/Processing/TaskProcessor.Codeunit.al), inside `ProcessLogRetention`.
**Hint:** call your new `GetRecordOnce()` helper and read `"Retention Days"` from the returned record. The format string below it can stay; it now mirrors whatever Setup says.

### 3. Reshape the Task Processing State codeunit
**Goal:** keep the codeunit, but stop treating it like a leaky singleton.
**Where:** [TaskProcessingState.Codeunit.al](TaskFramework/src/Processing/TaskProcessingState.Codeunit.al) and [TaskProcessor.Codeunit.al](TaskFramework/src/Processing/TaskProcessor.Codeunit.al).
**Problem A — `SingleInstance` leakage:** `SingleInstance = true` makes the codeunit a per-session singleton. State leaks across batches and breaks the moment Job Queue, background sessions, or page background tasks run the processor.
**Fix A:** drop the `SingleInstance` property. The codeunit becomes a normal instance again.

**Problem B — wrong call path:** `Task Processor` publishes `OnBeforeProcessTask`, then subscribes to its *own* event in the same app just to bump the counter. That gives no extension benefit and is the wrong shape.
**Fix B:** delete the `HandleBeforeProcess` subscriber. Move the counter updates into the framework's own code path.

**The intended shape in `Task Processor`:**
- hold `Task Processing State` as a member variable of `Task Processor`
- after each successful `ProcessTaskEntry`, call `IncrementProcessedCount` and `SetLastProcessed` directly from the loop
- expose a `GetTaskProcessingState()` getter so callers can read the metrics without grabbing a fresh instance
- pass the state codeunit into the `OnBeforeProcessTask` event signature so legitimate external subscribers can inspect the same state instance later

### 4. Remove the in-app subscriber, keep the event
**Goal:** keep the extension point, remove the self-consumption.
**Where:** [TaskProcessor.Codeunit.al](TaskFramework/src/Processing/TaskProcessor.Codeunit.al).
**Hint:** delete `HandleBeforeProcess`. Keep the `OnBeforeProcessTask` event declaration. Keep the publish call inside `ProcessTaskEntry`. Step 7 will revisit the event's role; Step 2 only fixes the self-subscription.

### 5. Empty the Process action on the Task Log Entry Card
**Goal:** the Process action becomes one line.
**Where:** [TaskLogEntryCard.page.al](TaskFramework/src/Core/TaskLogEntryCard.page.al).
**Hint:** the codeunit and procedure already exist. The page should just call `TaskProcessor.ProcessTaskEntry(Rec)`.
**Done when:** no business logic remains in the page.

### 6. Collapse to one posting path on Voucher Entries
**Goal:** one posting path, not two.
**Where:** [VoucherEntries.Page.al](TaskFramework/src/Vouchers/VoucherEntries.Page.al).
**Hint:** drop the broken second action. Keep the selection-loop shape, but replace inline status flipping with a call to `PostVouchers.PostVoucher(VoucherEntry)` inside the loop. No status changes on the page, no posting-date assignment, no duplicate behavior.

> **Discuss:** the page now has one action. Is the `Post Vouchers` codeunit the facade, or just the implementation? In this codebase, with one consumer, they are effectively the same thing. Step 5 changes the answer when the journal pipeline arrives.

### Buffer — guard clauses
Optional. Flatten any `if ... then begin ... end else ...` blocks you touch using early `exit;` guards.

## Verification

- [ ] `Task Log Entry Card` Process action contains no logic beyond a codeunit call
- [ ] `Voucher Entries` has one posting action, calling `PostVouchers.PostVoucher`
- [ ] Retention days comes from `Task Framework Setup`; the field is editable on the page
- [ ] `Task Processing State` exists, is not `SingleInstance`, and is held by `Task Processor`
- [ ] The `HandleBeforeProcess` self-subscriber is gone
- [ ] The `OnBeforeProcessTask` event still exists and is still called
- [ ] App compiles, app installs, "Process All Pending" still works end-to-end

## If you get stuck

- The remaining `// TODO: (Step 2 …)` markers in the code mark the precise spots to edit.
- Last resort: `git checkout step-2-end` and diff against your work.

## Out of scope for now

- The monster `case` in `Task Processor` — Step 3 / 4
- `ProcessVendorImport` and `ProcessDocumentImport` in the framework — Step 3
- `Post Vouchers` faking posting via status flip — Step 5
- Single `Error()` aborting the batch — Step 6
- The role of `OnBeforeProcessTask` as an extension point — Step 7
