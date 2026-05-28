# Step 3.5 — Dependency Injection by Hand — Cheat Sheet

> Companion to the "While You Code — Step 3.5" slide. More room here for details and hints.
> **No copy-paste-ready code on purpose** — type it yourself, that's where the learning happens.

## What you're building in this step

Step 3 made the *what* swappable. Step 3.5 makes the *how* swappable: status updates, archiving, and processing each become injectable roles. No Factory yet — the caller passes the implementations in by hand. Step 4 hides that wiring behind one object later.

By the end:

1. Two new role interfaces — `ITask Log Updater` and `ITask Archiver` — sit next to the Step 3 `ITask Processor`.
2. `Task Processor` implements all three. The framework's own behaviour is the default for every role.
3. `ProcessTaskEntry` has a second overload taking the three roles as parameters.
4. Nothing in `ProcessTaskEntry` flips status or archives directly anymore — every step routes through an injected interface.
5. Production behaviour is unchanged. This is a pure refactor that opens a seam.

## Files you'll touch

- [ITaskLogUpdater.interface.al](TaskFramework/src/Processing/Factory/ITaskLogUpdater.interface.al) — new role interface for status updates
- [ITaskArchiver.interface.al](TaskFramework/src/Processing/Factory/ITaskArchiver.interface.al) — new role interface for archiving
- [TaskProcessor.Codeunit.al](TaskFramework/src/Processing/TaskProcessor.Codeunit.al) — implement the role interfaces, extract interface-shaped procedures, and add the overload that takes the three roles

## Tasks (in order)

### 1. Define the two role interfaces
**Goal:** two narrow interfaces, one per role, alongside the existing `ITask Processor`.
**Where:** [ITaskLogUpdater.interface.al](TaskFramework/src/Processing/Factory/ITaskLogUpdater.interface.al) and [ITaskArchiver.interface.al](TaskFramework/src/Processing/Factory/ITaskArchiver.interface.al).
- `ITaskLogUpdater` — `procedure UpdateStatus(var TaskLogEntry: Record "Task Log Entry"; NewStatus: Enum "Task Processing Status");`
- `ITaskArchiver` — `procedure Archive(var TaskLogEntry: Record "Task Log Entry");`
**Why two small interfaces instead of one fat one?** A test that only cares about archiving should not have to stub status updates too. Keep the interfaces narrow.
**Why a folder called `Factory/` already?** These roles are the vocabulary the next step will route between. Put them where they will live.

### 2. Make `Task Processor` implement the role interfaces
**Goal:** the framework's own behaviour becomes the default for all three roles.
**Where:** [TaskProcessor.Codeunit.al](TaskFramework/src/Processing/TaskProcessor.Codeunit.al).
**Hint:** change the header to implement `ITask Processor`, `ITask Log Updater`, and `ITask Archiver`. The compiler will then force you to add matching procedures.
**Why not extra `Default*` codeunits?** The framework already has the real behaviour. Wrapping it in ceremony codeunits adds noise without value.

### 3. Extract the role bodies into interface-shaped procedures
**Goal:** the logic doesn't change — it moves out of `ProcessTaskEntry` into procedures that match the interface signatures.
**Where:** [TaskProcessor.Codeunit.al](TaskFramework/src/Processing/TaskProcessor.Codeunit.al).
**Hint:**
- `UpdateStatus(var TaskLogEntry; NewStatus)` — the inline status flips currently in `ProcessTaskEntry`. Branch on `NewStatus = ::Processing` vs `::Complete` to pick which timestamp to set, then `Modify()`.
- `Archive(var TaskLogEntry)` — rename the existing `local procedure ArchiveEntry` to `Archive` and promote it to a public `procedure`. Body stays verbatim.
- `ProcessTask(var TaskLogEntry)` — wrap the Step 3 enum→interface dispatch (`Processor := TaskLogEntry."Task Processing Type"; Processor.ProcessTask(TaskLogEntry);`) so `Task Processor` is its own default `ITask Processor`.

### 4. Add the DI overload for `ProcessTaskEntry`
**Goal:** two `ProcessTaskEntry` procedures — one bare for production, one taking the three roles for injection.
**Where:** [TaskProcessor.Codeunit.al](TaskFramework/src/Processing/TaskProcessor.Codeunit.al).
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
- Last resort: `git checkout step-3.5-end` and diff against your work.

## Out of scope for now

Leave these — later steps own them:
- A Factory that picks which implementation runs for each role, so callers stop passing three arguments — Step 4
- Mock-based tests that inject a fake updater or archiver — Step 8
- `Post Vouchers` still flips a status flag instead of journaling — Step 5
- `Post Vouchers` still aborts on the first `Error()` — Step 6
- The `OnBeforeProcessTask` event still publishes from inside the relevant codeunit — Step 7

## Why this step exists

Step 3 used enum binding to dispatch processors. That solves one axis of variability: which processor runs for a task type. The moment you need a second axis — same task type, but a mocked status updater or mocked archiver — the enum cannot help you. Step 3.5 carves those seams explicitly and wires them by hand first, so Step 4's Factory arrives as an ergonomic improvement rather than a magic black box.
