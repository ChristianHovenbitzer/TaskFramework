# Step 5 — Real Posting Pipeline — Cheat Sheet

> Companion to the "While You Code — Step 5" slide. More room here for details and hints.
> **No copy-paste-ready code on purpose** — type it yourself, that's where the learning happens.

## What you're building in this step

Replace the status-flip "posting" (`Post Vouchers` flips a field on the same record)
with the real BC posting pipeline: a journal of editable staging lines, a ledger of
immutable posted entries, a register that groups each posting run, and the standard
trio of codeunits — **Check Line / Post Line / Post Batch** — coordinating it all.
Document Import wires through a Builder so journal lines are constructed correctly.

By the end: posted vouchers cannot be edited, you can see which posting run they came
from, and the entire flow lives in `TaskFramework.Impl` — the framework app no longer
references `Voucher Entry`, `Post Vouchers`, or anything voucher-specific.

## What's already pre-built

To save typing on the largest step, these tables and pages are already in
`TaskFramework.Impl/src/vouchers/`:

- `Voucher Journal Line` (table + page) — staging
- `Voucher Ledger Entry` (table + page) — immutable posted records
- `Voucher Register` (table + page) — groups ledger entries per posting run

Open them. Notice the page on Ledger Entry has `Editable = false` and the table is
locked down. That's the lesson: posted records are immutable *because they live in a
different table*, not because we hid the buttons.

## What you'll build

**New codeunits in `TaskFramework.Impl/src/vouchers/`:**
- `Voucher Jnl.-Check Line` — validate one journal line
- `Voucher Jnl.-Post Line` — create one ledger entry from one journal line
- `Voucher Jnl.-Post Batch` — orchestrator: check all → register → post all → cleanup
- `Voucher Journal Builder` — `CreateFromTaskPayload`, encodes the correct insertion sequence

**Modified:**
- `TaskFramework.Impl/src/processors/DocumentImportProcessor.Codeunit.al` — uses Builder + Post Batch instead of writing directly to the old Voucher Entry

**Deleted (Framework app — these move OUT of the framework):**
- `TaskFramework/src/Vouchers/VoucherEntry.Table.al`
- `TaskFramework/src/Vouchers/VoucherEntries.Page.al`
- `TaskFramework/src/Vouchers/VoucherEntryCard.Page.al`
- `TaskFramework/src/Vouchers/PostVouchers.Codeunit.al`

## Tasks (in order)

### 1. Voucher Jnl.-Check Line
**Goal:** validate a single journal line; `Error()` on the first problem (we'll improve to collectible errors in Step 6).
**Where:** `TaskFramework.Impl/src/vouchers/VoucherJnlCheckLine.Codeunit.al`.
**Hint:** one procedure — `RunCheck(VoucherJnlLine: Record "Voucher Journal Line")`. Validate Customer No., Amount, Posting Date. Include line number in the error message so users know which line is wrong.

### 2. Voucher Jnl.-Post Line
**Goal:** turn one validated journal line into one ledger entry, tagged with the current Register No.
**Where:** `TaskFramework.Impl/src/vouchers/VoucherJnlPostLine.Codeunit.al`.
**Hint:** signature `RunPosting(VoucherJnlLine; var RegisterNo: Integer)`. Init the ledger entry, copy fields, set `Register No.`, `Insert(true)`. The ledger entry primary key (`Entry No.`) is `AutoIncrement` — don't set it.
**Don't:** wire G/L posting (Gen. Jnl. Line). Leave a comment noting that's where it would go and move on. The pattern is the point, not the accounting.

### 3. Voucher Jnl.-Post Batch — the orchestrator
**Goal:** the public entry point. Validates all lines, then creates a register, then posts all lines under that register, then cleans up.
**Where:** `TaskFramework.Impl/src/vouchers/VoucherJnlPostBatch.Codeunit.al`.
**Hint — four phases, in order:**
  1. **Phase 1: Validate.** Loop journal lines, call `Check Line` on each. If any throws, nothing posts.
  2. **Phase 2: Create register.** One register per posting run. Insert it, capture its `No.`.
  3. **Phase 3: Post.** Loop again, call `Post Line` with the register no.
  4. **Phase 4: Cleanup.** Set the register's `From Entry No.` / `To Entry No.`, modify it. Delete the journal lines (they're consumed).
**Why two loops:** validation must complete fully before any ledger entry is created. Bail-out on phase 1 leaves no half-posted state.

### 4. Voucher Journal Builder
**Goal:** one place that knows how to build a `Voucher Journal Line` correctly.
**Where:** `TaskFramework.Impl/src/vouchers/VoucherJournalBuilder.Codeunit.al`.
**Hint — the canonical insertion sequence (Eric Hougaard / Stefan):**
```
Init → Validate(PK) → Insert(true) → Validate(other fields) → Modify(true)
```
Why this order matters: `Insert(true)` triggers `OnInsert`, and downstream `Validate` calls expect the record to exist with its PK set. Also pick the next `Line No.` (sort by `Line No. desc`, take first + 10000).

### 5. Wire Document Import Processor through the new pipeline
**Goal:** Type 3 task creates a journal line via the Builder, then runs Post Batch.
**Where:** `TaskFramework.Impl/src/processors/DocumentImportProcessor.Codeunit.al`.
**Hint:** `ProcessTask` body becomes roughly: parse payload → `Builder.CreateFromTaskPayload(TaskLogEntry, JnlLine)` → set a filter on the journal line → `PostBatch.Run(JnlLine)`. No more `VoucherEntry` references.

### 6. Delete the old Voucher Entry world from the framework app
**Goal:** the Framework app stops shipping voucher-specific objects.
**Where:** delete `TaskFramework/src/Vouchers/` contents. Drop the entire folder.
**Sanity check:** the framework's `app.json` should not reference any voucher object after this.

## Done when

- [ ] Three codeunits — Check Line, Post Line, Post Batch — exist in the Impl app
- [ ] Voucher Journal Builder uses Init → Validate(PK) → Insert → Validate → Modify
- [ ] Document Import Processor builds journal lines and calls Post Batch (no direct Voucher Entry creation)
- [ ] Old `Voucher Entry` table, page, card, and `Post Vouchers` codeunit are deleted from the Framework app
- [ ] Posting a journal with a missing Customer No. errors *before any ledger entry is created*
- [ ] Posted vouchers appear on `Voucher Ledger Entries` (read-only) — not on `Voucher Journal Lines` anymore
- [ ] A Voucher Register row groups the entries from one posting run
- [ ] App compiles, install runs, end-to-end Document Import flow still works

## If you get stuck

- See `docs/pattern-status.md` Step 5 section — the ❌ rows are exactly what you're filling in.
- The `// TODO: (Step 5 …)` markers in the framework's Vouchers folder mark what to delete.
- Phase 1 must fully complete before phase 2 starts. If you find yourself looping once and posting inline, you've collapsed two phases.
- Last resort: `git checkout step-5-end`.

## Out of scope today

- **Templates / batches / balancing** — BC standard uses these. We deliberately skip — the codeunit pattern (Check / Post Line / Post Batch) is the lesson, not journal ergonomics.
- **G/L posting via Gen. Jnl. Line** — mark with a comment in Post Line and move on. Wiring this would double the step's length without teaching anything new.
- **Collectible errors in Check Line** — Step 6 replaces the `Error()` calls with a collector.
