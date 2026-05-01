# Step 8 — Mock via Interface — Cheat Sheet

> Companion to the "While You Code — Step 8" slide. More room here for details and hints.
> **No copy-paste-ready code on purpose** — type it yourself, that's where the learning happens.

## What you're building in this step

The payoff of Step 3 + Step 4. You have an `ITask Processor` interface (Step 3) and an
`internal` DI overload on `Task Processor.ProcessTaskEntry` that accepts a processor by
parameter (Step 4). Now build a **Mock Task Processor** in the test app, inject it via
that overload, and write tests that prove framework logic without touching real Vendors,
Vouchers, or BLOBs.

The two test codeunits already in `TaskFramework.Tests/src/` are the "before" — they
hit real tables and demonstrate everything wrong with non-mockable code. Leave them as
contrast and add the new mock-based tests alongside.

## Files you'll touch

**New (Test app):**
- `TaskFramework.Tests/src/MockTaskProcessor.Codeunit.al` — implements `ITask Processor`
- `TaskFramework.Tests/src/TaskProcessorTests.Codeunit.al` (or extend the existing test codeunit) — the new isolated tests

**Read-only:**
- `TaskFramework/src/Processing/TaskProcessor.Codeunit.al` — already has the public/internal overload pair
- `TaskFramework.Tests/src/TaskFrameworkTests.Codeunit.al` — keep as the "before" contrast; the comment block at the top explains why those tests are anti-patterns

## Tasks (in order)

### 1. Build the Mock Task Processor
**Goal:** a codeunit implementing `ITask Processor` that records what happened, doesn't do real work, and can be told to fail.
**Where:** new file `MockTaskProcessor.Codeunit.al` in the test app.
**Hint — the four members:**
- `WasCalled: Boolean` and `LastEntryNo: Integer` — record what `ProcessTask` was given
- `ShouldFail: Boolean` — toggled by tests for the error path
- `ProcessTask(var TaskLogEntry)` — sets WasCalled, captures Entry No., throws if ShouldFail
- A small set of getters — `VerifyWasCalled`, `GetLastEntryNo`, `SetShouldFail`
**Don't:** build a mock framework. A codeunit with booleans and getters is the whole pattern.

### 2. Happy-path test — verify the processor is called once with the right entry
**Goal:** prove the framework forwards a task entry to the bound processor exactly once.
**Where:** new test codeunit (or alongside the existing tests).
**Hint:** instantiate `MockTaskProcessor`, create a pending `Task Log Entry`, call the **internal** overload `TaskProcessor.ProcessTaskEntry(TaskLogEntry, MockProcessor)` — yes, the test app reaches the internal overload, that's why it's `internal` and not `local`. Then assert `MockProcessor.VerifyWasCalled()` and that `LastEntryNo` matches.

### 3. Error-path test — failure flips status, doesn't crash the test
**Goal:** when the processor throws, the framework marks the entry Failed and doesn't propagate.
**Where:** same place.
**Hint:** `MockProcessor.SetShouldFail(true)` before the call. Use `asserterror` around the framework call. Re-fetch the entry from the database afterwards (the in-memory record is stale) and assert `Status = Failed`.
**Watch:** if you find your test passing because of a different exception, your assertion isn't pinned tightly enough. Use `GetLastErrorText().Contains(...)` to check it's *your* simulated error.

### 4. Lifecycle test — Pending → Processing → Complete
**Goal:** the framework moves the entry through the right statuses.
**Where:** same place.
**Hint:** record `Processing Started At` and `Processing Completed At` are set by the framework, not the processor. Assert both are non-zero and ordered correctly. The mock can verify `WasCalled` while the framework's status transitions surround it.

### 5. (Bonus) Mock-driven posting pipeline test
**Goal:** test `Voucher Jnl.-Post Batch` with a Check Line mock that always passes — proves the orchestration logic independent of validation rules.
**Where:** if time permits.
**Hint:** requires extracting Check Line via an interface too. Decide on the fly whether this is in scope for the workshop time budget — fine to skip and discuss verbally.

## Done when

- [ ] `Mock Task Processor` exists in the test app and implements `ITask Processor`
- [ ] At least three new tests pass: happy path (called once with correct entry), error path (status=Failed), lifecycle (Pending → Processing → Complete)
- [ ] None of the new tests create `Vendor` records or write BLOB payloads
- [ ] The "before" tests in `TaskFrameworkTests.Codeunit.al` still exist and still demonstrate the anti-pattern (don't delete them — they're the contrast)
- [ ] Test app compiles, all tests run, all pass

## If you get stuck

- See `docs/pattern-status.md` Step 8 section.
- Compilation issue on the internal overload? Confirm the framework's `app.json` lists the test app's GUID under `internalsVisibleTo` (set up earlier in the workshop). Without that, the test app sees only the public overload and DI is broken.
- If the mock's `WasCalled` is always false, double-check you're calling the **internal** `ProcessTaskEntry(entry, processor)` overload, not the public one (which goes through the Factory and ignores your mock).
- Last resort: `git checkout step-8-end`.

## Speaker discussion at wrap-up

Stefan vs Christian on **unit vs integration**:
- Stefan — integration tests prove the real system works; mocks can give false confidence.
- Christian — unit tests are faster and pinpoint what broke; integration tests are slow and brittle.

There's no single right answer. The framework supports both — that's the payoff of the
architecture, not the tests themselves. Surface this to the audience and let them weigh in.

## Out of scope today

- Building a real mock framework (Moq-style). A codeunit with booleans is enough for our purposes.
- Test Library / Helper patterns — Christian's call: deprioritised. We use a tiny local `Test Assert` codeunit instead.
