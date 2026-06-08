# Step 5 — Real Posting Pipeline — Cheat Sheet

> Companion to the "While You Code — Step 5" slide. More room here for details and hints.
> **The repetitive boilerplate (all three facades + the Check Line pair) is provided** so
> your time goes to the parts that teach. For everything you *do* write, the hints are
> deliberately not copy-paste-ready — typing it yourself is where the learning happens.

## What you're building in this step

Replace the status-flip "posting" (`Post Vouchers` flips a field on the same record)
with the real BC posting pipeline: a journal of editable staging lines, a ledger of
immutable posted entries, a register that groups each posting run, and the standard
trio of codeunit pairs — **Check Line / Post Line / Post Batch**, each split into a
public facade + an `Access = Internal` Impl — coordinating it all. Document Import
constructs a journal line and runs it through the pipeline.

By the end: posted vouchers cannot be edited, you can see which posting run they came
from, and the entire flow lives in `TaskFramework.Impl` — the framework app no longer
references `Voucher Entry`, `Post Vouchers`, or anything voucher-specific.

## What's already pre-built

To save typing on the largest step, these tables and pages are already in
`TaskFramework.Impl/src/vouchers/`:

- [VoucherJournalLine.table.al](TaskFramework.Impl/src/vouchers/VoucherJournalLine.table.al) and [VoucherJournalLines.page.al](TaskFramework.Impl/src/vouchers/VoucherJournalLines.page.al) — staging
- [VoucherLedgerEntry.table.al](TaskFramework.Impl/src/vouchers/VoucherLedgerEntry.table.al) and [VoucherLedgerEntries.page.al](TaskFramework.Impl/src/vouchers/VoucherLedgerEntries.page.al) — immutable posted records
- [VoucherRegister.table.al](TaskFramework.Impl/src/vouchers/VoucherRegister.table.al) and [VoucherRegisters.page.al](TaskFramework.Impl/src/vouchers/VoucherRegisters.page.al) — groups ledger entries per posting run

Open them. Notice the Ledger Entry page has `Editable = false` and the table is
locked down. That's the lesson: posted records are immutable *because they live in a
different table*, not because we hid the buttons.

## What you'll build

The pipeline is **three codeunit pairs** in `TaskFramework.Impl/src/vouchers/posting/`.
Each pair = one public facade calling one `Access = Internal` Impl. To keep the step
focused on the posting *logic* rather than boilerplate, some of these are already
provided — read them, don't retype them.

**Provided complete — read these as your reference (already in the branch):**

- [VoucherJnlCheckLine.codeunit.al](TaskFramework.Impl/src/vouchers/posting/VoucherJnlCheckLine.codeunit.al) **+** [VoucherJnlCheckLineImpl.codeunit.al](TaskFramework.Impl/src/vouchers/posting/VoucherJnlCheckLineImpl.codeunit.al) — the **whole Check Line pair**, done. This is your worked example of the Public/Impl pattern: open both, see how the facade just forwards to the internal Impl, and how `RunCheck` validates with `TestField`. You build the next two pairs the same way.
- [VoucherJnlPostLine.codeunit.al](TaskFramework.Impl/src/vouchers/posting/VoucherJnlPostLine.codeunit.al) and [VoucherJnlPostBatch.codeunit.al](TaskFramework.Impl/src/vouchers/posting/VoucherJnlPostBatch.codeunit.al) — the **two remaining facades** are provided too (all facades are identical boilerplate). They already reference Impls that **don't exist yet** — that's expected, the branch won't compile until you write them.

**You build (the substance of this step):**

- [VoucherJnlPostLineImpl.codeunit.al](TaskFramework.Impl/src/vouchers/posting/VoucherJnlPostLineImpl.codeunit.al) — create one ledger entry from one journal line *(Task 2)*
- [VoucherJnlPostBatchImpl.codeunit.al](TaskFramework.Impl/src/vouchers/posting/VoucherJnlPostBatchImpl.codeunit.al) — the orchestrator: check all → register → post all → update register → cleanup *(Task 3)*

Optional / "if there's time" — **not provided**, build from scratch:
- `VoucherJnlPostPreview.Codeunit.al`, `VoucherPostPreviewHandler.Codeunit.al`, and `VoucherPostingPreview.Page.al` — standard BC posting preview pattern. Demonstrates how `[CommitBehavior(CommitBehavior::Error)]` plus manual event subscriptions let you "post in memory" and show the resulting ledger entries without actually committing.

**Modified:**
- [DocumentImportProcessor.codeunit.al](TaskFramework.Impl/src/processors/DocumentImportProcessor.codeunit.al) — builds a journal line inline, then calls Post Batch instead of writing to the old Voucher Entry
- [TaskProcessor.codeunit.al](TaskFramework/src/Processing/TaskProcessor.codeunit.al) — `OnBeforeProcessTask` gains a `var Factory: Interface "ITask Processor Factory"` parameter so subscribers can mutate factory wiring before processing

**Deleted (Framework app — these move OUT of the framework):**
- [VoucherEntry.Table.al](TaskFramework/src/Vouchers/VoucherEntry.Table.al)
- [VoucherEntries.Page.al](TaskFramework/src/Vouchers/VoucherEntries.Page.al)
- [VoucherEntryCard.Page.al](TaskFramework/src/Vouchers/VoucherEntryCard.Page.al)
- [PostVouchers.Codeunit.al](TaskFramework/src/Vouchers/PostVouchers.Codeunit.al)

## Tasks (in order)

### 1. Voucher Jnl.-Check Line (pair) — READ, don't write
**This pair is provided complete.** Open both files and study them — they are your
template for Tasks 2 and 3.
**Where:** [VoucherJnlCheckLineImpl.codeunit.al](TaskFramework.Impl/src/vouchers/posting/VoucherJnlCheckLineImpl.codeunit.al) and [VoucherJnlCheckLine.codeunit.al](TaskFramework.Impl/src/vouchers/posting/VoucherJnlCheckLine.codeunit.al).
**What to notice:**
- The Impl has `Access = Internal`, `TableNo = "Voucher Journal Line"`, and an `OnRun` trigger that delegates to `RunCheck(Rec)`. `RunCheck` validates with `TestField` on `"Customer No."`, `Amount`, `"Posting Date"` — `TestField` is chosen so each error names the field automatically.
- The public facade is a thin wrapper: it holds a `var ...Impl: Codeunit` and forwards every call. Nothing else.
**Why a pair?** Public/Impl is the BC-standard split: the public codeunit is the stable callable surface; the Impl carries the logic and is internal-only so other apps can't depend on it. Mirrors how MS does Gen. Jnl. posting. **Tasks 2 and 3 follow this exact shape — the facades are already provided, so you only write their Impls.**

### 2. Voucher Jnl.-Post Line Impl — YOU build this
**Goal:** turn one validated journal line into one ledger entry, tagged with the current Register No.
**The facade** [VoucherJnlPostLine.codeunit.al](TaskFramework.Impl/src/vouchers/posting/VoucherJnlPostLine.codeunit.al) **is already provided** — open it to see exactly which procedures your Impl must expose (it just forwards `RunPosting`, `InitNextEntryNo`, `SetNextRegisterNo`, `GetNextEntryNo`). Your job is to create [VoucherJnlPostLineImpl.codeunit.al](TaskFramework.Impl/src/vouchers/posting/VoucherJnlPostLineImpl.codeunit.al) (`Access = Internal`, same pattern as the Check Line Impl) with the bodies.
**Hint — the Impl carries:**
- `RunPosting(VoucherJnlLine; RegisterNo)` — increments `NextEntryNo`, then `Init → Validate(Entry No.) → Validate(...) → Insert(true)` on `Voucher Ledger Entry`. Raises `OnAfterPostVoucherLine` after insert (the preview handler subscribes to this).
- `InitNextEntryNo()` — locks the table and reads the highest existing Entry No. Call this once per posting run before looping.
- `SetNextRegisterNo(...)` — stores the register number for the loop that follows.
**Don't:** wire G/L posting (Gen. Jnl. Line). Leave a comment noting that's where it would go and move on. The pattern is the point, not the accounting.

### 3. Voucher Jnl.-Post Batch Impl — YOU build this (the heart of the step)
**Goal:** the public entry point. Validates all lines (collecting *all* errors), then creates a register, posts all lines under it, updates the register's entry-range, cleans up.
**The facade** [VoucherJnlPostBatch.codeunit.al](TaskFramework.Impl/src/vouchers/posting/VoucherJnlPostBatch.codeunit.al) **is already provided** (it forwards `PostBatch` and declares the cross-table permissions). Your job is [VoucherJnlPostBatchImpl.codeunit.al](TaskFramework.Impl/src/vouchers/posting/VoucherJnlPostBatchImpl.codeunit.al) — this is the real work of Step 5, so take your time here.
**Hint — five phases on the Impl, in order:**
  1. **Phase 1: Validate all lines.** `[ErrorBehavior(ErrorBehavior::Collect)]` on the procedure plus `ErrorMessageMgt.Activate(ErrorMessageHandler)` lets `TestField` errors accumulate in the handler instead of throwing. Loop the journal lines, call `CheckLine.RunCheck` on each. After the loop, if `ErrorMessageHandler.HasErrors` then `ShowErrors()` and `Error('')` to abort cleanly.
  2. **Phase 2: Create register.** Lock + read last `Voucher Register`, compute next `No.`, init/insert a new register row.
  3. **Phase 3: Post.** `PostLine.SetNextRegisterNo` + `PostLine.InitNextEntryNo`, then loop the journal lines and call `PostLine.RunPosting`. Track first/last entry no.
  4. **Phase 4: Update register.** Set the register's `From Entry No.` / `To Entry No.` and `Modify(true)`.
  5. **Phase 5: Cleanup.** `VoucherJnlLine.DeleteAll(true)` — the journal is consumed.
  *(Skip the preview hook for now — the optional preview task adds an `if PostPreview.IsActive() then PostPreview.ThrowError()` here, but only build that if you reach Task 7.)*
**Why two loops over the same lines:** validation must complete fully — and aggregate every error — before any ledger entry is created. Bail-out on phase 1 leaves no half-posted state.

### 4. Wire Document Import Processor through the new pipeline
**Goal:** Type 3 task creates a journal line inline, then runs Post Batch.
**Where:** [DocumentImportProcessor.codeunit.al](TaskFramework.Impl/src/processors/DocumentImportProcessor.codeunit.al).
**Hint:** parse the payload as today, then `Init → set fields → Insert(true)` on `Voucher Journal Line` (use a `GetNextLineNo` local helper that reads `FindLast` + 10000), then `PostBatchImpl.Run(VoucherJnlLine)`. No more `Voucher Entry` references anywhere.

### 5. Update Task Processor's event signature
**Goal:** the `OnBeforeProcessTask` integration event publishes the Factory so subscribers can mutate it.
**Where:** [TaskProcessor.codeunit.al](TaskFramework/src/Processing/TaskProcessor.codeunit.al).
**Hint:** add `var Factory: Interface "ITask Processor Factory"` as a parameter on the `OnBeforeProcessTask` declaration and pass `Factory` from the Factory-taking `ProcessTaskEntry` overload at the call site.

### 6. Delete the old Voucher Entry world from the framework app
**Goal:** the Framework app stops shipping voucher-specific objects.
**Where:** delete the voucher-specific files under [TaskFramework/src/Vouchers](TaskFramework/src/Vouchers).
**Sanity check:** the framework's `app.json` should not reference any voucher object after this. Permission sets in both apps need updating where they referenced the deleted tables.

### 7. (Optional) Posting preview
**Goal:** demonstrate the BC-standard "post-and-show-without-committing" pattern.
**Where:** create from scratch — `VoucherJnlPostPreview.Codeunit.al`, `VoucherPostPreviewHandler.Codeunit.al`, and `VoucherPostingPreview.Page.al` in the `posting/` folder. (Not provided on this branch; `git checkout step-5-end` to see a finished version.)
**Hint — the trick is twofold:**
- `[CommitBehavior(CommitBehavior::Error)]` on the preview-start procedure causes any `Commit()` to error out — so even if posting "succeeds" nothing actually persists.
- A manual `EventSubscriberInstance = Manual` handler subscribes to `OnAfterPostVoucherLine` (raised by Post Line Impl). It captures every would-be ledger entry into a temporary record. The preview throws a sentinel "Preview mode." error to roll the transaction back, then the page shows the captured temp records.

This is genuinely advanced; treat it as a stretch goal if the room is fast.

## Done when

- [ ] You wrote the two Impls — `Voucher Jnl.-Post Line Impl` and `Voucher Jnl.-Post Batch Impl` — in `TaskFramework.Impl/src/vouchers/posting/` (the three facades + Check Line Impl were provided)
- [ ] Both new Impls are `Access = Internal` and follow the same Public/Impl shape as the provided Check Line pair
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

## Out of scope for now

- **Templates / batches / balancing** — BC standard uses these. We deliberately skip — the codeunit pattern is the lesson, not journal ergonomics.
- **G/L posting via Gen. Jnl. Line** — mark with a comment in Post Line Impl and move on. Wiring this would double the step's length without teaching anything new.
- **Customer Ledger Entries** — same reason as G/L.
