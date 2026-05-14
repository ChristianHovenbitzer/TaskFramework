# Step 3.5 — Dependency Injection by Hand — Cheat Sheet

> Companion to the "While You Code — Step 3.5" slide. More room here for details and hints.
> **No copy-paste-ready code on purpose** — type it yourself, that's where the learning happens.

## What you're building in this step

Step 3 made the *what* swappable (which processor runs for a task type). Step 3.5
makes the *how* swappable: status updates, archiving, and the processor lookup each
become an injectable role. No Factory yet — the caller passes the implementations
in by hand. That keeps the leap small; Step 4 adds the Factory so nobody has to
pass three arguments forever.

By the end:

1. Two new role interfaces — `ITask Log Updater` and `ITask Archiver` — sit next to
   the Step 3 `ITask Processor`.
2. `Task Processor` implements all three. The framework's own behaviour *is* the
   default for every role — no empty `Default*` codeunits.
3. `ProcessTaskEntry` has a second overload taking the three roles as parameters.
   The bare public version delegates to it, passing `this` three times.
4. Nothing in `ProcessTaskEntry`'s body flips `Rec.Status` or calls a local archive
   procedure — every step routes through an injected interface.
5. Production behaviour is unchanged. This is a pure refactor that opens a seam;
   Step 8 cashes it in with mocks.

## Files you'll touch

**New (Framework app), all in a new `TaskFramework/src/Processing/Factory/` folder:**
- `ITaskLogUpdater.interface.al` — single method `UpdateStatus(var TaskLogEntry; NewStatus)`
- `ITaskArchiver.interface.al` — single method `Archive(var TaskLogEntry)`

**Modified (Framework app):**
- `TaskFramework/src/Processing/TaskProcessor.Codeunit.al` — header now `implements "ITask Processor", "ITask Log Updater", "ITask Archiver"`; the status flips and archive logic move into interface-shaped procedures; `ProcessTaskEntry` gets a roles-taking overload.

## Tasks (in order)

### 1. Define the two role interfaces
**Goal:** two narrow interfaces, one per role, alongside the existing `ITask Processor`.
**Where:** new files in a new `TaskFramework/src/Processing/Factory/` folder.
- `ITaskLogUpdater` — `procedure UpdateStatus(var TaskLogEntry: Record "Task Log Entry"; NewStatus: Enum "Task Processing Status");`
- `ITaskArchiver` — `procedure Archive(var TaskLogEntry: Record "Task Log Entry");`
**Why two small interfaces and not one fat `ITaskWorkflow`?** ISP — Interface Segregation Principle. A test that only cares about archiving shouldn't be forced to stub `UpdateStatus`. Narrow interfaces keep the mock surface honest. *Discuss when you get there: what would tip you the other way — and is it ever the right call?*
**Why a folder called `Factory/` when there's no factory yet?** These three interfaces are the vocabulary the Step 5 Factory will route between. Put them where they'll live and you skip a move later.

### 2. Make `Task Processor` implement the role interfaces
**Goal:** the framework's own behaviour becomes the default for all three roles.
**Where:** `TaskProcessor.Codeunit.al`.
**Hint:** change the header to `codeunit 50000 "Task Processor" implements "ITask Processor", "ITask Log Updater", "ITask Archiver"`. The compiler now demands a real procedure for each interface method — that's Task 3.
**Why not three new `Default Updater` / `Default Archiver` codeunits?** The framework's behaviour already exists and is correct. Wrapping it in empty ceremony codeunits adds files and names for nothing.

### 3. Extract the role bodies into interface-shaped procedures
**Goal:** the logic doesn't change — it moves out of `ProcessTaskEntry` into procedures that match the interface signatures.
**Where:** `TaskProcessor.Codeunit.al`.
**Hint:**
- `UpdateStatus(var TaskLogEntry; NewStatus)` — the inline status flips currently in `ProcessTaskEntry`. Branch on `NewStatus = ::Processing` vs `::Complete` to pick which timestamp to set, then `Modify()`.
- `Archive(var TaskLogEntry)` — rename the existing `local procedure ArchiveEntry` to `Archive` and promote it to a public `procedure`. Body stays verbatim.
- `ProcessTask(var TaskLogEntry)` — wrap the Step 3 enum→interface dispatch (`Processor := TaskLogEntry."Task Processing Type"; Processor.ProcessTask(TaskLogEntry);`) so `Task Processor` is its own default `ITask Processor`.

### 4. Add the DI overload for `ProcessTaskEntry`
**Goal:** two `ProcessTaskEntry` procedures — one bare for production, one taking the three roles for injection.
**Where:** `TaskProcessor.Codeunit.al`.
**Hint:**
- Public `ProcessTaskEntry(var TaskLogEntry)` — one line: delegate to the overload, passing `this` for all three roles.
- Public `ProcessTaskEntry(var TaskLogEntry; ITaskProcessor: Interface "ITask Processor"; ITaskLogUpdater: Interface "ITask Log Updater"; ITaskArchiver: Interface "ITask Archiver")` — keeps the `OnBeforeProcessTask` event guard, then routes the body through its parameters:
  ```
  ITaskLogUpdater.UpdateStatus(TaskLogEntry, TaskLogEntry.Status::Processing);
  ITaskProcessor.ProcessTask(TaskLogEntry);
  ITaskLogUpdater.UpdateStatus(TaskLogEntry, TaskLogEntry.Status::Complete);
  ITaskArchiver.Archive(TaskLogEntry);
  ```
Same code path either way — there is no "test-only branch" hiding inside `Task Processor`.
**Why pass `this` three times?** After Task 2, `Task Processor` *is* a valid `ITask Processor`, `ITask Log Updater`, and `ITask Archiver`. The bare version is just "inject myself" — the production default.
**Why the parameters are not `var`:** an injected role is a configured collaborator, not a return channel. `var` would say "I'll mutate this" — and you won't.

## Done when

- [ ] Two new role interfaces (`ITask Log Updater`, `ITask Archiver`) live in `TaskFramework/src/Processing/Factory/`
- [ ] `Task Processor` declares `implements "ITask Processor", "ITask Log Updater", "ITask Archiver"` and has a real procedure for every interface method
- [ ] `UpdateStatus`, `Archive`, and `ProcessTask` exist as interface-shaped procedures — no logic lost, none changed
- [ ] Nothing in `ProcessTaskEntry`'s body sets `Rec.Status` directly or calls `ArchiveEntry` — every step goes through a parameter
- [ ] Two ways to call `ProcessTaskEntry` exist: bare and with-roles; the bare version delegates with `this, this, this`
- [ ] `Process All Pending` still processes Vendor / LogRetention / Document tasks identically — the existing tests in `TaskFramework.Tests` still pass without changes
- [ ] App compiles cleanly

## If you get stuck

- Compiler error "X does not implement Y": you added the role to the `implements` list but the procedure signature doesn't match the interface exactly — check parameter types and `var`.
- The body refactor is mechanical: build `UpdateStatus` end-to-end first, then `Archive`, then `ProcessTask`. Each one empties a few more lines out of `ProcessTaskEntry`.
- Last resort: `git checkout step-4.5-end` and diff against your work.

## Out of scope today

Leave these — later steps own them:
- A Factory that *picks* which implementation runs for each role, so callers stop passing three arguments. **Step 5.**
- Mock-based tests that inject a fake updater or archiver. The seam exists now; the tests arrive in **Step 8.**
- `Post Vouchers` still flips a status flag instead of journaling. **Step 5.**
- `Post Vouchers` still aborts on the first `Error()`. **Step 6.**
- The `OnBeforeProcessTask` event still publishes from inside the codeunit it's relevant to. **Step 7.**

## Why this step exists

Step 3 used the enum-as-factory shortcut to dispatch processors. That works for *one*
axis of variability — which task type runs which body. The moment you need a *second*
axis — same task type but a mocked status updater, or a mocked archiver — the enum
binding can't help you. Step 3.5 carves the named seams (the role interfaces) and
wires them by hand, so the dependency is *visible* in the signature. Step 5 hides
that wiring behind a Factory; Step 8 cashes it in when the test suite arrives. Doing
the injection by hand first means the Factory arrives as an *ergonomic* improvement,
not a magic black box.
