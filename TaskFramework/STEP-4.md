# Step 4 — Factory Routing

**Patterns:** 1.2 Factory · 1.1 DI / Strategy (extended) · ISP applied
**Reference:** [pattern-status.md](../docs/pattern-status.md#step-4--factory-routing)

## Goal

Step 3 made the *what* swappable (which processor runs for a task type). Step 4 makes the *how* swappable: status updates, archiving, and processor lookup all become injectable so Step 8 can mock each one independently.

After Step 4:

1. `Task Processor.ProcessTaskEntry` has a second overload that takes an `ITask Processor Factory`. The single-arg public version delegates to it with a default.
2. The status flip and archive call inside `ProcessTaskEntry` route through `Factory.GetUpdater()` and `Factory.GetArchiver()` instead of being inline.
3. A test can override any *one* of `Processor`, `Updater`, `Archiver` and let the other two run as production.
4. `Task Processor` itself implements all three default roles. No new "Default Updater" / "Default Archiver" codeunits — the framework's own behavior *is* the default.

## TODOs

Find them with `grep -rn "Step 4" src ../TaskFramework.Impl/src ../TaskFramework.Tests/src`.

### 1. Define the role interfaces

Two new files in a new folder `src/Processing/Factory/`:

- `ITaskLogUpdater.Interface.al` — one method: `UpdateStatus(var TaskLogEntry: Record "Task Log Entry"; NewStatus: Enum "Task Status");`
- `ITaskArchiver.Interface.al` — one method: `Archive(var TaskLogEntry: Record "Task Log Entry");`

Both are deliberately tiny. The `ITask Processor` interface already exists from Step 3 — it joins these two as the third role.

> **Discuss:** why three small interfaces instead of one big `ITaskProcessorWorkflow`? (Hint: ISP. A test that only cares about archiving shouldn't be forced to stub `UpdateStatus`. Narrow interfaces keep the mock surface honest.)

### 2. Define the Factory interface

New file: `src/Processing/Factory/ITaskProcessorFactory.Interface.al`.

Three methods, one per role:

```al
procedure GetProcessor(): Interface "ITask Processor";
procedure GetUpdater(): Interface "ITask Log Updater";
procedure GetArchiver(): Interface "ITask Archiver";
```

This is the only interface a caller of `ProcessTaskEntry` needs to know about. The three role interfaces stay an internal contract between the factory and `Task Processor`.

### 3. Build the Factory codeunit

New file: `src/Processing/Factory/TaskProcessorFactory.Codeunit.al`. `Access = Internal`, `implements "ITask Processor Factory"`.

Holds a `Default: Codeunit "Task Processor"` and three Set/Get pairs — one per role. The pattern for each role is the same:

```al
var
    CustomXxx: Interface "IXxx";
    HasCustomXxx: Boolean;

procedure SetXxx(Xxx: Interface "IXxx") begin … end;
procedure GetXxx(): Interface "IXxx" begin if HasCustomXxx then exit(CustomXxx); exit(Default); end;
```

So the production path returns the framework default; tests call `SetXxx(Mock)` to override exactly one role.

> **Discuss:** why `HasCustomXxx: Boolean` instead of just checking whether `CustomXxx` is set? Interfaces are one of the few AL datatypes that *do* hold a null value — but the language gives you no way to ask at runtime whether the variable is null or assigned. The boolean is the workaround: you track "explicitly set" yourself because the type system won't tell you.

### 4. Make `Task Processor` implement the role interfaces

[TaskProcessor.Codeunit.al](src/Processing/TaskProcessor.Codeunit.al) — change the header:

```al
codeunit 50000 "Task Processor" implements "ITask Log Updater", "ITask Archiver", "ITask Processor"
```

Then move three pieces of existing logic into interface-shaped procedures:

- `UpdateStatus(var TaskLogEntry; NewStatus)` — the status flip and timestamp logic that's currently inline at lines 58-60 and 65-67. Branch on `NewStatus = Processing` vs `Complete` to pick which timestamp to set.
- `Archive(var TaskLogEntry)` — rename the existing local `ArchiveEntry` to `Archive` and bump it to `procedure` (no longer local).
- `ProcessTask(var TaskLogEntry)` — wrap the Step 3 dispatch (`Processor := TaskLogEntry."Task Type"; Processor.ProcessTask(...)`) so `Task Processor` becomes its own default `ITaskProcessor`.

`Task Processor` now wears three hats. The Factory routes between them.

### 5. Add the DI overload for `ProcessTaskEntry`

[TaskProcessor.Codeunit.al:49](src/Processing/TaskProcessor.Codeunit.al#L49) — split the existing `ProcessTaskEntry` into two:

```al
procedure ProcessTaskEntry(var TaskLogEntry: Record "Task Log Entry")
var Factory: Codeunit "Task Processor Factory";
begin
    ProcessTaskEntry(TaskLogEntry, Factory);
end;

procedure ProcessTaskEntry(var TaskLogEntry: Record "Task Log Entry"; Factory: Interface "ITask Processor Factory")
begin
    // OnBefore + IsHandled stay as Step 2 left them
    Factory.GetUpdater().UpdateStatus(TaskLogEntry, TaskLogEntry.Status::Processing);
    Factory.GetProcessor().ProcessTask(TaskLogEntry);
    Factory.GetUpdater().UpdateStatus(TaskLogEntry, TaskLogEntry.Status::Complete);
    if TaskLogEntry."Archive After Processing" then
        Factory.GetArchiver().Archive(TaskLogEntry);
end;
```

The public single-arg version is the production API. The two-arg overload is the test seam. Same code path either way — there is no "test-only branch" hiding inside `Task Processor`.

> **Discuss:** what would break if you made the overload's `Factory` parameter `var`? (Nothing functional, but it leaks intent — `var` says "I'll mutate this." A factory you can swap is a configured object, not a return channel.)

## Verification

- Two ways to call `ProcessTaskEntry` exist: bare and with-factory.
- `Task Processor` declares `implements "ITask Log Updater", "ITask Archiver", "ITask Processor"`.
- Nothing in `ProcessTaskEntry`'s body sets `Rec.Status` directly — every status touch goes through `Factory.GetUpdater().UpdateStatus(...)`.
- The Factory has three `Set*` procedures and three `Get*` procedures, each gated by a `HasCustom*` boolean.
- Existing seeded tasks still process end-to-end without touching a single test.
- The current tests at [TaskFrameworkTests.Codeunit.al](../TaskFramework.Tests/src/TaskFrameworkTests.Codeunit.al) still call `TaskProcessor.ProcessTaskEntry(TaskLogEntry)` (single-arg) and still pass — the overload is additive.

## Out of scope

Leave these — later steps own them:

- The actual mock-based tests that exploit the Factory. Step 8.
- `Post Vouchers` still flips a status flag instead of journaling. Step 5.
- `Post Vouchers` still aborts on the first `Error()`. Step 6.
- The `OnBeforeProcessTask` event still publishes from inside the same codeunit it's relevant to. Step 7.
- The Factory has no telemetry around which role got mocked vs ran default — useful for hardening, not for the workshop.
