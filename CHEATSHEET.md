# Step 6 — Collectible Errors — Cheat Sheet

> Companion to the "While You Code — Step 6" slide. More room here for details and hints.
> **No copy-paste-ready code on purpose** — type it yourself, that's where the learning happens.

## What you're building in this step

Right now `Voucher Jnl.-Check Line` calls `Error()` on the first problem it finds —
users fix it, post again, hit the next error, and so on. You're going to replace that
with a collector: `Check Line` writes every problem into the `Task Error Log`, and
`Post Batch` decides whether to fail at the end of phase 1.

Bonus: distinguish **blocking** errors (stop posting) from **non-blocking** warnings
(post anyway, surface as a Notification).

## The demo that motivates it

Three journal lines:
- Line 1 — valid
- Line 2 — Customer No. blank
- Line 3 — Amount = 0 *and* Description blank

Today: post → first error on line 2, nothing else seen, line 3 invisible.
By end of step: post → see all three problems at once, line 3 reported as a warning,
nothing posts because line 2 is blocking.

## Files you'll touch

**Modified (Impl app):**
- `TaskFramework.Impl/src/vouchers/posting/VoucherJnlCheckLineImpl.codeunit.al` — collect into `Task Error Log` instead of `Error()`
- `TaskFramework.Impl/src/vouchers/posting/VoucherJnlPostBatchImpl.codeunit.al` — check for blocking errors before phase 2

**Read-only (already shaped right by Christian):**
- `TaskFramework/src/Core/Errors/TaskErrorLog.Table.al` — `Line No.`, `Error Message` (Text[2048]), `Is Blocking`, `Source`, `Correlation Id`

## Tasks (in order)

### 1. Add `var ErrorLog: Record "Task Error Log"` to Check Line
**Goal:** Check Line writes into a passed-in error log instead of throwing.
**Where:** `VoucherJnlCheckLineImpl.codeunit.al`.
**Hint:** change the signature to `RunCheck(VoucherJnlLine; var ErrorLog: Record "Task Error Log")`. Replace each `Error('...')` with a call to a small `LogError` helper that does Init + assign + Insert against `ErrorLog`. Set the `Source` field to the journal line number so the user can locate which line failed.
**Don't yet:** turn the helper into a separate codeunit / interface. Keep it as a `local procedure` for now — error-handler architecture is still under discussion (decision deferred from the 2026-03-13 sync).

### 2. Mark blocking vs. non-blocking
**Goal:** required-field misses are blocking; soft issues are warnings.
**Where:** still `VoucherJnlCheckLineImpl.codeunit.al`.
**Hint:** missing Customer No. / zero Amount / missing Posting Date → `Is Blocking = true`. Empty Description → `Is Blocking = false` (warning only). Pass `IsBlocking` as a parameter to your `LogError` helper.

### 3. Wire Check Line through Post Batch's phase 1
**Goal:** Post Batch runs Check Line for every line, accumulates errors, *then* decides.
**Where:** `VoucherJnlPostBatchImpl.codeunit.al`.
**Hint:** declare `ErrorLog: Record "Task Error Log"` as a temporary record (`temporary` keyword if you want it not to persist) — or persist to the real table if you want the user to inspect afterwards. Pass it to `Check Line` in the phase-1 loop. After the loop:
  - filter `Is Blocking = true`
  - if any: surface them all (page or compound message), then `Error('Posting stopped: %1 error(s) found.', Count)`. Phase 2 never runs.
  - if none but warnings exist: send a `Notification` and proceed to phase 2.

### 4. Show all errors at once
**Goal:** the user sees every problem from a single click, not one at a time.
**Where:** Post Batch's failure path.
**Hint:** simplest first cut — concatenate the messages into a single `Error()` call. Cleaner — open the Task Error Log page filtered to this run's `Correlation Id`. Either is fine for the workshop; pick the one that fits the time budget.

### 5. Demo the three feedback mechanisms
**Goal:** know which to use when.
**Where:** code + a slide-side discussion at wrap-up.

| Mechanism     | Stops? | UI                         | Use for                          |
|---------------|:------:|----------------------------|----------------------------------|
| `Error()`     | yes    | dialog, rolls back txn     | blocking errors, invalid state   |
| `Message()`   | no     | dialog after proc completes| success confirmation             |
| `Notification`| no     | non-blocking banner        | warnings, suggestions, FYI       |

Use a `Notification` for the empty-Description warning — that's the demo payoff.

## Done when

- [ ] `Voucher Jnl.-Check Line.RunCheck` no longer calls `Error()` directly
- [ ] All Check Line problems are written to `Task Error Log` with `Is Blocking` set
- [ ] Empty Description is logged as a non-blocking warning
- [ ] Post Batch fails with **all** blocking errors visible at once, not just the first
- [ ] If only warnings exist, posting succeeds and a `Notification` surfaces them
- [ ] App compiles, install runs, the three-line demo above behaves as described

## If you get stuck

- See `docs/pattern-status.md` Step 6 section.
- The `// TODO: (Step 6 …)` markers are at the spots that change.
- Common gotcha: `var` parameter on the error log — without `var`, the caller never sees what you wrote.
- Last resort: `git checkout step-6-end`.

## Out of scope today

- **Error handler architecture** (enum on table vs. interface parameter vs. implementation-internal). Three valid options were discussed in the 2026-03-13 sync; the decision is deferred. For now, keep the collector as a `local procedure` inside Check Line.
- **Errors from outside the posting pipeline.** This step covers Check Line. Errors raised by `Post Line` itself (after validation passed) stay as `Error()` — they're genuinely unexpected.
