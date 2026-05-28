# Step 8 — Mock via Factory — Cheat Sheet

> Companion to the "While You Code — Step 8" slide. More room here for details and hints.
> **No copy-paste-ready code on purpose** — type it yourself, that's where the learning happens.

## What you're building in this step

The payoff of Step 4. The Factory has `SetProcessor` / `SetUpdater` / `SetArchiver`
overrides for exactly this moment. You're going to build:

1. **`Mock Task Runner`** — a single codeunit that implements all three role
   interfaces (`ITask Processor`, `ITask Log Updater`, `ITask Archiver`) and records
   every call into a shared `Call Recorder`. One mock plays all three roles.
2. **`Call Recorder`** — a `SingleInstance` spy that holds a `List of [Text]` of
   the call names in the order they happened. Tests assert against `GetCall(Index)`
   and `GetCallCount`.
3. **Spy-based orchestration tests** in the existing `TaskFrameworkTests`
   codeunit — replace the anti-pattern integration tests with mock-driven tests
   that assert the *order* of `Updater → Processor → Updater → Archiver` calls
   without touching the database for processors.
4. **Per-unit tests** in a new `TaskFrameworkUnitTests` codeunit — one
   comprehensive happy-path test per production unit (Task Processor's
   `UpdateStatus`, `Archive`, plus each impl processor's `ProcessTask`).

By the end: tests run without seeded demo data. The framework's wiring is provable
from outside, and individual units are tested in isolation.

## Files you'll touch

**New (Test app):**
- [CallRecorder.codeunit.al](TaskFramework.Tests/src/mocks/CallRecorder.codeunit.al) — `SingleInstance` spy holding the recorded call list
- [MockTaskRunner.codeunit.al](TaskFramework.Tests/src/mocks/MockTaskRunner.codeunit.al) — implements the three role interfaces; every method records via the recorder
- [TaskFrameworkUnitTests.Codeunit.al](TaskFramework.Tests/src/TaskFrameworkUnitTests.Codeunit.al) — new test codeunit with one comprehensive test per production unit

**Rewritten (Test app):**
- [TaskFrameworkTests.Codeunit.al](TaskFramework.Tests/src/TaskFrameworkTests.Codeunit.al) — replace the anti-pattern integration tests with spy-based orchestration tests. The old tests don't survive — their value is contrast in the slides, not in the repo.

**Modified (Framework / Impl app — small follow-up cleanup):**
- [TaskProcessor.codeunit.al](TaskFramework/src/Processing/TaskProcessor.codeunit.al) — remove the leftover same-app self-subscriber on `OnBeforeProcessTask`
- [InstallTaskFramework.codeunit.al](TaskFramework.Impl/src/install/InstallTaskFramework.codeunit.al) — disable demo-data seeding (`SeedSetup` / `SeedVoucherJournalLines` / `SeedTaskLogEntries`) by commenting out their calls

**Tooling additions (one-time, easy to overlook):**
- `.altestrunner/config.json` — AL Test Runner extension config so tests run from VS Code
- Each app gets a `.codeanalyzer/SOCITAS.ruleset.json` — quiet a few analyzers that misfire on test code
- `TaskFramework.Tests/.vscode/tasks.json` — task-runner shortcuts

These are pre-built/bundled if you check out from `step-8-end`; if you're typing
along, you can skip and run the test runner from the command palette directly.

## Tasks (in order)

### 1. Build the Call Recorder
**Goal:** a shared sink that records the order of mock collaborator calls.
**Where:** [CallRecorder.codeunit.al](TaskFramework.Tests/src/mocks/CallRecorder.codeunit.al).
**Hint:** `SingleInstance = true`. Holds `Calls: List of [Text]`. Three procedures: `Record(CallName: Text)`, `GetCallCount`, `GetCall(Index): Text`, plus a `Reset()` that clears the list. Tests must call `Reset` in Arrange — `SingleInstance` survives across tests.

### 2. Build the Mock Task Runner
**Goal:** one codeunit, three interfaces, every call records into the recorder.
**Where:** [MockTaskRunner.codeunit.al](TaskFramework.Tests/src/mocks/MockTaskRunner.codeunit.al).
**Hint:** `codeunit 70012 "Mock Task Runner" implements "ITask Log Updater", "ITask Archiver", "ITask Processor"`. Each implementation does one thing: `Recorder.Record(StrSubstNo('Updater.UpdateStatus:%1', NewStatus))` etc. No DB writes, no real work — pure spy. The `StrSubstNo` format is part of the contract; tests assert against it.
**Don't:** build a mock framework. A codeunit that records its inputs is the whole pattern.

### 3. Spy-based orchestration tests in `TaskFrameworkTests`
**Goal:** prove the framework calls `Updater(Processing) → Processor → Updater(Complete) → Archiver` in order, without writing to real tables.
**Where:** rewrite [TaskFrameworkTests.Codeunit.al](TaskFramework.Tests/src/TaskFrameworkTests.Codeunit.al).
**Hint — the pattern for every test:**
1. **Arrange:** `Recorder.Reset()`. Init a `TaskLogEntry` *but don't insert* (no DB). Set the `Entry No.` manually so the recorded line includes a known number. Set up Factory: `Factory.SetProcessor(MockRunner); Factory.SetUpdater(MockRunner); Factory.SetArchiver(MockRunner);`.
2. **Act:** `TaskProcessor.ProcessTaskEntry(TaskLogEntry, Factory);` — the Factory-taking overload from Step 4 is the test seam.
3. **Assert:** `Recorder.GetCall(N)` against the expected call name at each index. For example `Recorder.GetCall(2)` should be `'Processor.ProcessTask:1'`.

You'll keep the test names (`TestProcessVendorImportTask`, etc.) but the bodies change completely. The original integration tests are replaced — leave a header comment on each new test pointing out what the old one couldn't assert and what the new one does.

### 4. Per-unit happy-path tests in `TaskFrameworkUnitTests`
**Goal:** one comprehensive test per production unit, exercising the whole happy path.
**Where:** new file [TaskFrameworkUnitTests.Codeunit.al](TaskFramework.Tests/src/TaskFrameworkUnitTests.Codeunit.al).
**Hint:** four tests:
- `TestUpdateStatusDrivesFullLifecycle` — Pending → Processing → Complete via two calls to `TaskProcessor.UpdateStatus`. Assert the timestamps are stamped correctly on each transition.
- `TestArchiveCopiesEntryAndStampsMetadata` — set up a Complete entry with a few non-default fields, call `TaskProcessor.Archive`, assert the archive row exists with all fields copied + `Archived At` stamped.
- `TestVendorImportProcessorProcessTask` — drive a payload through the enum→interface dispatch and assert the Vendor record was created (this *does* hit the DB; that's fine for an impl-processor unit test).
- `TestDocumentImportProcessorProcessTask` — same shape for the voucher pipeline path.

**Why these tests look unlike Step 3 tests:** they're "comprehensive happy path" — single test row in the runner = whole unit verified. They're verifying the *unit* behaves correctly, while the orchestration tests in Step 3 verified the *wiring*.

### 5. Disable install-time seeding
**Goal:** tests don't depend on demo data the install codeunit would otherwise insert.
**Where:** [InstallTaskFramework.codeunit.al](TaskFramework.Impl/src/install/InstallTaskFramework.codeunit.al).
**Hint:** comment out the three `SeedSetup()` / `SeedVoucherJournalLines()` / `SeedTaskLogEntries()` calls in `OnInstallAppPerCompany`. Each test arranges exactly the state it needs.

### 6. Final cleanup — remove the orphan same-app subscriber
**Goal:** delete the in-codeunit `OnBeforeProcessTask` subscriber that snuck in earlier; tighten `Archive` so the call site is uniform.
**Where:** [TaskProcessor.codeunit.al](TaskFramework/src/Processing/TaskProcessor.codeunit.al).
**Hint — two small changes:**
- Delete the `[EventSubscriber] local procedure MyProcedure(var Factory: ...)` near the top of the codeunit. It's the same-app self-subscription anti-pattern from Step 2, and the Factory's default already provides the archiver — so the subscriber is both wrong-shaped and redundant.
- Move the `if TaskLogEntry."Archive After Processing"` guard out of `ProcessTaskEntry` and into `Archive` itself (early-exit at the top of the procedure). After this, `ProcessTaskEntry` calls `Factory.GetArchiver().Archive(...)` *unconditionally* — the call site is uniform, and the "do I archive?" decision is encapsulated by the archiver. This makes the spy-based orchestration tests easier to assert: every successful run records exactly four spy calls (Updater × 2, Processor, Archiver), regardless of the entry's archive flag.

## Done when

- [ ] `Call Recorder` and `Mock Task Runner` exist in `TaskFramework.Tests/src/mocks/`
- [ ] The two existing tests in `TaskFrameworkTests` are rewritten to use the spy and assert call sequence via `Recorder.GetCall(N)`
- [ ] `TaskFrameworkUnitTests` exists with the four per-unit tests
- [ ] None of the orchestration tests insert a `Task Log Entry`, write a payload BLOB, or seed Vendors
- [ ] Install codeunit's `OnInstallAppPerCompany` is empty (comments only)
- [ ] `OnBeforeProcessTask` has no in-codeunit subscriber
- [ ] All tests pass

## If you get stuck

- `Recorder.GetCall(N)` is 1-indexed (AL `List of [Text]`). If your assertion reads index 0 or N+1 you're off by one.
- `SingleInstance` survives across tests — if a test's first assertion fails on a stale call from a previous test, you forgot `Recorder.Reset()` in Arrange.
- `Factory.Set*(MockRunner)` requires the parameter type to match the interface, so `MockRunner` *must* declare `implements "ITask Log Updater", "ITask Archiver", "ITask Processor"`. Compile error here usually means a missing interface declaration.
- Last resort: `git checkout step-8-end`.

## Speaker discussion at wrap-up

Stefan vs Christian on **unit vs integration**:
- Stefan — integration tests prove the real system works; mocks can give false confidence.
- Christian — unit tests are faster and pinpoint what broke; integration tests are slow and brittle.

Both flavors live in the test app: orchestration tests use the spy; per-unit tests
hit the real types when needed. The architecture supports either philosophy — that's
the payoff of the work in Steps 3, 4, and 6, not the tests themselves.

## Out of scope for now

- A general mock framework (Moq-style). A codeunit that records its inputs is enough.
- Test Library / Helper patterns — Christian's call: deprioritised. Tiny local `Test Assert` is enough.
- Mocking the posting pipeline (Check Line / Post Line / Post Batch). Doable in principle, the same way — left as a stretch goal if time permits.
