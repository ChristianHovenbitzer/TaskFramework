# Step 5 — Real Posting Pipeline — Cheat Sheet

> Companion to the "While You Code — Step 5" slide. More room here for details and hints.
> **No copy-paste-ready code on purpose** — type it yourself, that's where the learning happens.

## What you're building in this step

Replace the status-flip "posting" (`Post Vouchers` flips a field on the same record)
with the real BC posting pipeline: a journal of editable staging lines, a ledger of
immutable posted entries, a register that groups each posting run, and the standard
trio of codeunit pairs — **Check Line / Post Line / Post Batch**, each split into a
public facade + an `Access = Internal` Impl — coordinating it all. Document Import
constructs a journal line and runs it through the pipeline.

By the end: posted vouchers cannot be edited, you can see which posting run they came
from, validation errors are collected (not bail-on-first), and the entire flow lives
in `TaskFramework.Impl` — the framework app no longer references `Voucher Entry`,
`Post Vouchers`, or anything voucher-specific.

## What's already pre-built

To save typing on the largest step, these tables and pages are already in
`TaskFramework.Impl/src/vouchers/`:

- `Voucher Journal Line` (table + page) — staging
- `Voucher Ledger Entry` (table + page) — immutable posted records
- `Voucher Register` (table + page) — groups ledger entries per posting run

Open them. Notice the Ledger Entry page has `Editable = false` and the table is
locked down. That's the lesson: posted records are immutable *because they live in a
different table*, not because we hid the buttons.

## What you'll build

**New codeunit pairs in `TaskFramework.Impl/src/vouchers/posting/`** (each pair = one public facade calling one `Access = Internal` Impl):

- `Voucher Jnl.-Check Line` (60013) + `Voucher Jnl.-Check Line Impl` (60010) — validate one journal line
- `Voucher Jnl.-Post Line` (60014) + `Voucher Jnl.-Post Line Impl` (60011) — create one ledger entry from one journal line
- `Voucher Jnl.-Post Batch` (60015) + `Voucher Jnl.-Post Batch Impl` (60012) — orchestrator: check all (collecting errors) → register → post all → update register → cleanup

Optional / "if there's time":
- `Voucher Jnl.-Post Preview` (60017) + `Voucher Post. Preview Handler` (60016) + `Voucher Posting Preview` (page) — standard BC posting preview pattern. Demonstrates how `[CommitBehavior(CommitBehavior::Error)]` + manual event subscriptions let you "post in memory" and show the resulting ledger entries without actually committing.

**Modified:**
- `TaskFramework.Impl/src/processors/DocumentImportProcessor.codeunit.al` — builds a journal line inline, then calls `PostBatchImpl.Run(JnlLine)` instead of writing to the old Voucher Entry
- `TaskFramework/src/Processing/TaskProcessor.codeunit.al` — `OnBeforeProcessTask` event signature gains a `var Factory: Interface "ITask Processor Factory"` parameter so subscribers can mutate factory wiring before processing

**Deleted (Framework app — these move OUT of the framework):**
- `TaskFramework/src/Vouchers/VoucherEntry.Table.al`
- `TaskFramework/src/Vouchers/VoucherEntries.Page.al`
- `TaskFramework/src/Vouchers/VoucherEntryCard.Page.al`
- `TaskFramework/src/Vouchers/PostVouchers.Codeunit.al`

## Tasks (in order)

### 1. Voucher Jnl.-Check Line (pair)
**Goal:** validate one journal line via the BC `TableNo` + `OnRun` invocation pattern; the Impl uses `TestField` for missing data so errors carry the field name automatically.
**Where:** new files `VoucherJnlCheckLineImpl.codeunit.al` (60010, `Access = Internal`) and `VoucherJnlCheckLine.codeunit.al` (60013, the public facade) in `TaskFramework.Impl/src/vouchers/posting/`.
**Hint:** the Impl has `TableNo = "Voucher Journal Line"` plus an `OnRun` trigger that delegates to `RunCheck(Rec)`. `RunCheck` calls `TestField` on `"Customer No."`, `Amount`, `"Posting Date"`. The public facade is a thin wrapper that holds an `Impl` codeunit variable and forwards every call.
**Why a pair?** Public/Impl is the BC-standard split: the public codeunit is the stable callable surface; the Impl carries the logic and is internal-only so other apps can't depend on it. Mirrors how MS does Gen. Jnl. posting.

### 2. Voucher Jnl.-Post Line (pair)
**Goal:** turn one validated journal line into one ledger entry, tagged with the current Register No.
**Where:** new files `VoucherJnlPostLineImpl.codeunit.al` (60011) and `VoucherJnlPostLine.codeunit.al` (60014) in the same folder.
**Hint — Impl carries:**
- `RunPosting(VoucherJnlLine; RegisterNo)` — increments `NextEntryNo`, then `Init → Validate(Entry No.) → Validate(...) → Insert(true)` on `Voucher Ledger Entry`. Raises `OnAfterPostVoucherLine` after insert (the preview handler subscribes to this).
- `InitNextEntryNo()` — locks the table and reads the highest existing Entry No. Call this once per posting run before looping.
- `SetNextRegisterNo(...)` — stores the register number for the loop that follows.
**Don't:** wire G/L posting (Gen. Jnl. Line). Leave a comment noting that's where it would go and move on. The pattern is the point, not the accounting.

### 3. Voucher Jnl.-Post Batch (pair) — the orchestrator
**Goal:** the public entry point. Validates all lines (collecting *all* errors), then creates a register, posts all lines under it, updates the register's entry-range, cleans up.
**Where:** new files `VoucherJnlPostBatchImpl.codeunit.al` (60012) and `VoucherJnlPostBatch.codeunit.al` (60015) in the same folder.
**Hint — five phases on the Impl, in order:**
  1. **Phase 1: Validate all lines.** `[ErrorBehavior(ErrorBehavior::Collect)]` on the procedure plus `ErrorMessageMgt.Activate(ErrorMessageHandler)` lets `TestField` errors accumulate in the handler instead of throwing. Loop the journal lines, call `CheckLine.RunCheck` on each. After the loop, if `ErrorMessageHandler.HasErrors` then `ShowErrors()` and `Error('')` to abort cleanly.
  2. **Phase 2: Create register.** Lock + read last `Voucher Register`, compute next `No.`, init/insert a new register row.
  3. **Phase 3: Post.** `PostLine.SetNextRegisterNo` + `PostLine.InitNextEntryNo`, then loop the journal lines and call `PostLine.RunPosting`. Track first/last entry no.
  4. **Phase 4: Update register.** Set the register's `From Entry No.` / `To Entry No.` and `Modify(true)`.
  5. **Phase 5: Cleanup.** `VoucherJnlLine.DeleteAll(true)` — the journal is consumed.
  Plus, after Phase 5: if `PostPreview.IsActive()` then `PostPreview.ThrowError()` (only relevant if you do the optional preview task).
**Why two loops over the same lines:** validation must complete fully — and aggregate every error — before any ledger entry is created. Bail-out on phase 1 leaves no half-posted state.

### 4. Wire Document Import Processor through the new pipeline
**Goal:** Type 3 task creates a journal line inline, then runs Post Batch.
**Where:** `TaskFramework.Impl/src/processors/DocumentImportProcessor.codeunit.al`.
**Hint:** parse the payload as today, then `Init → set fields → Insert(true)` on `Voucher Journal Line` (use a `GetNextLineNo` local helper that reads `FindLast` + 10000), then `PostBatchImpl.Run(VoucherJnlLine)`. No more `Voucher Entry` references anywhere.

### 5. Update Task Processor's event signature
**Goal:** the `OnBeforeProcessTask` integration event publishes the Factory so subscribers can mutate it.
**Where:** `TaskFramework/src/Processing/TaskProcessor.codeunit.al`.
**Hint:** add `var Factory: Interface "ITask Processor Factory"` as a parameter on the `OnBeforeProcessTask` declaration and pass `Factory` from the Factory-taking `ProcessTaskEntry` overload at the call site.

### 6. Delete the old Voucher Entry world from the framework app
**Goal:** the Framework app stops shipping voucher-specific objects.
**Where:** delete `TaskFramework/src/Vouchers/` contents. Drop the entire folder.
**Sanity check:** the framework's `app.json` should not reference any voucher object after this. Permission sets in both apps need updating where they referenced the deleted tables.

### 7. (Optional) Posting preview
**Goal:** demonstrate the BC-standard "post-and-show-without-committing" pattern.
**Where:** new files `VoucherJnlPostPreview.Codeunit.al`, `VoucherPostPreviewHandler.Codeunit.al`, `VoucherPostingPreview.Page.al` in `TaskFramework.Impl/src/vouchers/posting/`.
**Hint — the trick is twofold:**
- `[CommitBehavior(CommitBehavior::Error)]` on the preview-start procedure causes any `Commit()` to error out — so even if posting "succeeds" nothing actually persists.
- A manual `EventSubscriberInstance = Manual` handler subscribes to `OnAfterPostVoucherLine` (raised by Post Line Impl). It captures every would-be ledger entry into a temporary record. The preview throws a sentinel "Preview mode." error to roll the transaction back, then the page shows the captured temp records.

This is genuinely advanced; treat it as a stretch goal if the room is fast.

## Done when

- [ ] Six new codeunits — three Public + three Impl pairs — exist in `TaskFramework.Impl/src/vouchers/posting/`
- [ ] Check Line uses `TestField` (not `Error()`) so missing-field errors carry the field name
- [ ] Post Batch's validate phase runs under `[ErrorBehavior(ErrorBehavior::Collect)]` and shows all errors via `ErrorMessageHandler.ShowErrors()` before aborting
- [ ] Document Import Processor builds journal lines inline and calls `PostBatchImpl.Run` (no direct Voucher Entry creation)
- [ ] Old `Voucher Entry` table, page, card, and `Post Vouchers` codeunit are deleted from the Framework app
- [ ] `TaskProcessor` event `OnBeforeProcessTask` carries the Factory parameter
- [ ] Posting a journal with a missing Customer No. errors *before any ledger entry is created*, and shows ALL validation issues (Customer No. + Amount + Posting Date) in one go, not just the first
- [ ] Posted vouchers appear on `Voucher Ledger Entries` (read-only) — not on `Voucher Journal Lines` anymore
- [ ] A `Voucher Register` row groups the entries from one posting run with `From Entry No.` / `To Entry No.` populated
- [ ] App compiles, install runs, end-to-end Document Import flow still works

## If you get stuck

- Public/Impl pair: the public codeunit holds the Impl as a `var` and forwards calls. That's all. Don't reinvent it.
- Compiler error "Codeunit X has no procedure Y": the public facade probably forgot to forward a method that the Impl exposes.
- Phase 1 must fully complete before phase 2 starts. If you find yourself looping once and posting inline, you've collapsed two phases.
- Last resort: `git checkout step-5-end`.

## Out of scope today

- **Templates / batches / balancing** — BC standard uses these. We deliberately skip — the codeunit pattern is the lesson, not journal ergonomics.
- **G/L posting via Gen. Jnl. Line** — mark with a comment in Post Line Impl and move on. Wiring this would double the step's length without teaching anything new.
- **Customer Ledger Entries** — same reason as G/L.
