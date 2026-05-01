# Step 2 — Clean Structure — Cheat Sheet

> Companion to the "While You Code — Step 2" slide. More room here for details and hints.
> **No copy-paste-ready code on purpose** — type it yourself, that's where the learning happens.

## What you're building in this step

Get business logic out of pages. Move hardcoded values to a Setup record. Drop the
`SingleInstance` state codeunit (it's a hint that something architectural is wrong —
state evaporates on session end and Job Queue doesn't even share a session).

By the end: pages call codeunits, codeunits read config from a record, no in-memory
state floating around.

## Files you'll touch

- `TaskFramework/src/Core/TaskLogEntryCard.page.al` — strip inline logic from the Process action
- `TaskFramework/src/Vouchers/VoucherEntries.Page.al` — collapse two posting paths into one
- `TaskFramework/src/Processing/TaskProcessor.Codeunit.al` — read retention from Setup; drop the self-subscribed state subscriber
- `TaskFramework/src/Processing/TaskProcessingState.Codeunit.al` — remove `SingleInstance`, repurpose as a normal codeunit (or delete entirely)
- `TaskFramework/src/Setup/TaskFrameworkSetup.Table.al` — add the retention field if it isn't there yet

## Tasks (in order)

### 1. Page → Codeunit on Task Log Entry Card
**Goal:** the Process action becomes one line.
**Where:** `TaskLogEntryCard.page.al` — the `OnAction` of the Process action.
**Hint:** the codeunit and procedure already exist (`TaskProcessor.ProcessTaskEntry`). The page should just call it with `Rec`.
**Done when:** no business logic remains in the page; the action body is one line plus a `CurrPage.Update`.

### 2. Consolidate the Voucher posting actions
**Goal:** one posting path, not two.
**Where:** `VoucherEntries.Page.al`.
**Hint:** the page has two actions today — one that flips status inline, one that calls `PostVouchers`. Keep the codeunit path. Delete the inline one.
**Why this matters:** two paths = two behaviors when you'd want exactly one. Page-level "shortcuts" diverge from the real implementation over time.

### 3. Read retention days from Setup
**Goal:** kill `RetentionDays := 30;`.
**Where:** `TaskProcessor.Codeunit.al`, inside `ProcessLogRetention`.
**Hint:** add a retention-days field on `Task Framework Setup` if it doesn't exist; surface it on the setup page; read it via `Setup.GetRecordOnce()` (or `Get` + Init pattern). The Setup record is seeded by the install codeunit.
**Done when:** the value comes from the setup record, the field is editable on the setup page, and changing it changes runtime behavior.

### 4. Drop SingleInstance
**Goal:** `Task Processing State` is no longer `SingleInstance = true`.
**Where:** `TaskProcessingState.Codeunit.al` and the subscriber in `TaskProcessor.Codeunit.al`.
**Hint:** two valid options — (a) delete the codeunit entirely if you don't need the counter, (b) keep it as a normal codeunit and pass it as a `var` parameter where needed. Either way, also remove the `OnBeforeProcessTask` subscriber that calls it (and its publisher in the same file — same-app self-subscription is its own anti-pattern).
**Why this matters:** `SingleInstance` state vanishes when the session ends. Background sessions / Job Queue see a fresh instance every time. State that needs to survive belongs in a table.

## Done when

- [ ] `Task Log Entry Card` Process action contains no logic beyond a codeunit call
- [ ] `Voucher Entries` has one posting action, calling `PostVouchers.PostVoucher`
- [ ] Retention days comes from `Task Framework Setup`; the field is editable on the page
- [ ] `SingleInstance = true` no longer appears anywhere
- [ ] The self-subscribed `OnBeforeProcessTask` event and its handler are gone
- [ ] App compiles, app installs, "Process All Pending" still works end-to-end

## If you get stuck

- See `docs/pattern-status.md` Step 2 section — the ❌ rows are exactly what you're filling in.
- The remaining `// TODO: (Step 2 …)` markers in the code mark the precise spots to edit.
- Last resort: `git checkout step-2-end` and diff against your work.

## Out of scope today

Facade. In modern AL, `internal` + interfaces (Step 3) cover what a Facade did. We'll
revisit this in Step 3 — for now, don't add a Facade codeunit just because the catalog
mentions one.
