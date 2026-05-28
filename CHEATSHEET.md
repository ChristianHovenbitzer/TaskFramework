# Step 6 — Collectible Errors — Cheat Sheet

> Companion to the "While You Code — Step 6" slide. More room here for details and hints.
> **No copy-paste-ready code on purpose** — type it yourself, that's where the learning happens.

## What you're building in this step

Right now `Voucher Jnl.-Check Line` calls `TestField` on the first problem it finds —
users fix it, post again, hit the next error, and so on. You're going to switch to
BC's standard collectible-errors mechanism so all problems on all lines surface in
one go, with a clean separation between blocking errors (stop posting) and
non-blocking warnings (post anyway, surface for the user).

The mechanism is the BC framework's `Error Message Management` codeunit plus the
`[ErrorBehavior(ErrorBehavior::Collect)]` method attribute — no custom table or
hand-rolled collector.

## The demo that motivates it

Three journal lines:
- Line 1 — valid
- Line 2 — Customer No. blank
- Line 3 — Amount = 0 *and* Description blank

Today: post → first error on line 2, nothing else seen, line 3 invisible.
By end of step: post → see Customer No. (line 2) + Amount (line 3) as blocking
errors *and* the Description-empty issue (line 3) as a warning, all on one Error
Messages page. Nothing posts because two blocking errors exist.

## Files you'll touch

**Modified (Impl app):**
- [VoucherJnlCheckLineImpl.codeunit.al](TaskFramework.Impl/src/vouchers/posting/VoucherJnlCheckLineImpl.codeunit.al) — annotate with `[ErrorBehavior(Collect)]`, replace `TestField` with `ErrorMessageMgt.LogErrorMessage` / `LogWarning`
- [VoucherJnlPostBatchImpl.codeunit.al](TaskFramework.Impl/src/vouchers/posting/VoucherJnlPostBatchImpl.codeunit.al) — annotate with `[ErrorBehavior(Collect)]`, activate the handler before phase 1, check `HasErrors` after phase 1, abort cleanly if any

**Available but not used in this step:**
- [TaskErrorLog.Table.al](TaskFramework/src/Core/Errors/TaskErrorLog.Table.al) — a custom error-log table from earlier prototyping. We do **not** use it in Step 6; BC's built-in mechanism is enough. Left in place for participants who want to extend later.

## Tasks (in order)

### 1. Annotate Check Line for collection
**Goal:** every validation in `RunCheck` collects rather than throws on the first miss.
**Where:** [VoucherJnlCheckLineImpl.codeunit.al](TaskFramework.Impl/src/vouchers/posting/VoucherJnlCheckLineImpl.codeunit.al).
**Hint:** add `[ErrorBehavior(ErrorBehavior::Collect)]` immediately above the `procedure RunCheck(...)` declaration. This is what makes any `Error()` raised inside (or any `LogErrorMessage` call) accumulate into the active error message handler instead of throwing immediately.

### 2. Replace `TestField` with `LogErrorMessage` / `LogWarning`
**Goal:** each validation fault becomes a structured entry on the error handler.
**Where:** still [VoucherJnlCheckLineImpl.codeunit.al](TaskFramework.Impl/src/vouchers/posting/VoucherJnlCheckLineImpl.codeunit.al).
**Hint:** declare a local `ErrorMessageMgt: Codeunit "Error Message Management"` variable. Replace each `TestField` with an `if ... = '' then ErrorMessageMgt.LogErrorMessage(...)` block. Six positional parameters: context field no., the formatted message, the source record, the source field no., a help URL (pass `''`).
- Customer No. blank → `LogErrorMessage` (blocking)
- Amount zero → `LogErrorMessage` (blocking)
- Posting Date zero → `LogErrorMessage` (blocking)
- **Description blank → `LogWarning`** (non-blocking — posting can still proceed)

Compose the message via `StrSubstNo` so it includes the field caption *and* the line number. Users on a 50-line journal need to know which line to fix.

### 3. Activate the handler in Post Batch and abort if blocking errors exist
**Goal:** `Post Batch` opts in to error collection, runs Check Line for every line, then decides.
**Where:** [VoucherJnlPostBatchImpl.codeunit.al](TaskFramework.Impl/src/vouchers/posting/VoucherJnlPostBatchImpl.codeunit.al).
**Hint:**
- Add `[ErrorBehavior(ErrorBehavior::Collect)]` above `procedure PostBatch`.
- Declare locals `ErrorMessageMgt: Codeunit "Error Message Management"` and `ErrorMessageHandler: Codeunit "Error Message Handler"`.
- **Before** the phase-1 loop: `ErrorMessageMgt.Activate(ErrorMessageHandler);` — this is what tells the framework "send collected entries here."
- Run the phase-1 loop unchanged — every `LogErrorMessage` / `LogWarning` from Check Line lands in the handler.
- **After** the loop:
  ```
  if ErrorMessageHandler.HasErrors() then begin
      ErrorMessageHandler.ShowErrors();
      Error('');
  end;
  ```
  `ShowErrors()` opens the standard "Error Messages" page with everything filtered to this run. The empty-string `Error('')` is the conventional silent abort that rolls the transaction back without putting another dialog on top.

### 4. Verify the three-line demo
**Goal:** sanity-check end-to-end before moving on.
**Where:** Voucher Journal Lines page in a sandbox.
**Hint:** create the three lines from the demo at the top, click Post. The Error Messages page should show three entries: two errors (blank Customer No. on line 2; zero Amount on line 3) and one warning (blank Description on line 3). Posting aborts.

### 5. Discuss the three feedback mechanisms

| Mechanism                            | Stops? | UI                                | Use for                                                |
|--------------------------------------|:------:|-----------------------------------|--------------------------------------------------------|
| `Error()`                            | yes    | dialog, rolls back txn            | unrecoverable problems outside collected validation    |
| `Error Message Management.LogError…` | no\*   | "Error Messages" page after run   | validation issues you want to aggregate                |
| `Error Message Management.LogWarning`| no     | same page, marked as warning      | soft issues — post anyway, surface for the user        |

\* The `LogError…` call itself doesn't stop, but `HasErrors() → Error('')` at the end of phase 1 stops the whole posting run if anything was logged with error severity.

## Done when

- [ ] `RunCheck` carries `[ErrorBehavior(ErrorBehavior::Collect)]`
- [ ] All `TestField` calls in Check Line are replaced with `LogErrorMessage` / `LogWarning`
- [ ] Empty Description is logged as a `LogWarning` (non-blocking)
- [ ] `PostBatch` carries `[ErrorBehavior(ErrorBehavior::Collect)]` and activates the `Error Message Handler` before phase 1
- [ ] After phase 1, `HasErrors` is checked; if true, `ShowErrors` runs and posting aborts
- [ ] App compiles, install runs, the three-line demo behaves as described

## If you get stuck

- The compiler tells you immediately if you forgot `[ErrorBehavior(Collect)]` — calls to `LogErrorMessage` from a non-collecting context behave differently, and the framework will warn.
- Forgetting `ErrorMessageMgt.Activate(ErrorMessageHandler)` means the page never shows anything and `HasErrors` is always false. The Activate call wires the local handler into the global stream.
- Last resort: `git checkout step-6-end`.

## Out of scope for now

- **Error handler architecture as a general framework concern** (deferred from the 2026-03-13 sync — three options were on the table: enum on the task, interface param on the processor, implementation-controlled). Step 6 just wires journal-validation errors; framework-wide error policy is a separate decision.
- **The `Task Error Log` table** that was prototyped earlier. Step 6's solution doesn't write to it. Treat it as dead code for the workshop; remove later if it stays unused.
- **Errors from outside Check Line.** Errors raised by `Post Line` itself (after validation passed) stay as `Error()` — they're genuinely unexpected.
