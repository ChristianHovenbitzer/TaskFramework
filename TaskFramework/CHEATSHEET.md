# Step 4 — Factory Routing — Cheat Sheet

> Companion to the "While You Code — Step 4" slide. More room here for details and hints.
> **No copy-paste-ready code on purpose** — type it yourself, that's where the learning happens.

## What you're building in this step

This step reduces the call shape from three role parameters to one factory parameter. The factory supplies the processor, updater, and archiver behind that single object.

By the end:

1. `Task Processor.ProcessTaskEntry` has an overload that takes an `ITask Processor Factory`.
2. Status updates, processing, and archiving all route through `Factory.Get*()`.
3. The factory can return framework defaults or test overrides for any role.
4. Production behaviour is unchanged. This is wiring cleanup that opens a cleaner seam.

## Files you'll touch

**New (Framework app), all in a new `TaskFramework/src/Processing/Factory/` folder:**
- [ITaskProcessorFactory.Interface.al](TaskFramework/src/Processing/Factory/ITaskProcessorFactory.Interface.al) — three methods, one per role: `GetProcessor`, `GetUpdater`, `GetArchiver`
- [TaskProcessorFactory.Codeunit.al](TaskFramework/src/Processing/Factory/TaskProcessorFactory.Codeunit.al) — `Access = Internal`, `implements "ITask Processor Factory"`. Holds the default `Task Processor` and one Set/Get pair per role.

**Modified (Framework app):**
- [TaskProcessor.Codeunit.al](TaskFramework/src/Processing/TaskProcessor.Codeunit.al) — `ProcessTaskEntry` gets a factory-taking overload.

## Tasks (in order)

### 1. Define the Factory interface
**Goal:** the only interface that callers of `ProcessTaskEntry` need to know about.
**Where:** [ITaskProcessorFactory.Interface.al](TaskFramework/src/Processing/Factory/ITaskProcessorFactory.Interface.al).
**Hint:** three methods, one per role:
- `GetProcessor(): Interface "ITask Processor"`
- `GetUpdater(): Interface "ITask Log Updater"`
- `GetArchiver(): Interface "ITask Archiver"`

The role interfaces stay an internal contract between the factory and `Task Processor`.

### 2. Build the Factory codeunit
**Goal:** the production-default + test-override switchboard.
**Where:** [TaskProcessorFactory.Codeunit.al](TaskFramework/src/Processing/Factory/TaskProcessorFactory.Codeunit.al). `Access = Internal`, `implements "ITask Processor Factory"`.
**Hint:** holds a `Default: Codeunit "Task Processor"` and three Set/Get pairs — one per role. The shape for each role is identical:
- `Custom<Role>: Interface "I<Role>"` + `HasCustom<Role>: Boolean`
- `Set<Role>(...)` stores the custom impl and flips the boolean
- `Get<Role>()` returns the custom impl if the boolean is true, otherwise returns `Default`

So production returns the framework default; tests call `Set<Role>(Mock)` to override exactly one role.
**Why the `HasCustom*` boolean** instead of just checking whether the interface variable is set? Interfaces are one of the few AL datatypes that *do* hold a null value — but the language gives you no way to ask at runtime whether the variable is null or assigned. The boolean is the workaround: you track "explicitly set" yourself because the type system won't tell you.

### 3. Add the DI overload for `ProcessTaskEntry`
**Goal:** two `ProcessTaskEntry` procedures — one bare for production, one taking a Factory for tests.
**Where:** [TaskProcessor.Codeunit.al](TaskFramework/src/Processing/TaskProcessor.Codeunit.al).
**Hint:**
- Public `ProcessTaskEntry(var TaskLogEntry)` — body declares `Factory: Codeunit "Task Processor Factory"` and calls the overload with it. One line.
- Public `ProcessTaskEntry(var TaskLogEntry; Factory: Interface "ITask Processor Factory")` — keeps the `OnBeforeProcessTask` event guard, then routes everything through the factory:
  ```
  Factory.GetUpdater().UpdateStatus(TaskLogEntry, TaskLogEntry.Status::Processing);
  Factory.GetProcessor().ProcessTask(TaskLogEntry);
  Factory.GetUpdater().UpdateStatus(TaskLogEntry, TaskLogEntry.Status::Complete);
  Factory.GetArchiver().Archive(TaskLogEntry);
  ```

Same code path either way — there is no "test-only branch" hiding inside `Task Processor`.
**Why the parameter is not `var`:** nothing functional would break, but `var` says "I'll mutate this." A factory you can swap is a configured object, not a return channel. The signature should reflect that.

## Done when

- [ ] `TaskProcessorFactory` codeunit exists, with three `Set*`/`Get*` pairs gated by `HasCustom*` booleans
- [ ] Nothing in `ProcessTaskEntry`'s body sets `Rec.Status` directly — every status touch goes through `Factory.GetUpdater().UpdateStatus(...)`
- [ ] Two ways to call `ProcessTaskEntry` exist: bare and with-factory; the bare version constructs a default factory and delegates
- [ ] `Process All Pending` still processes Vendor / LogRetention / Document tasks identically — the existing tests in `TaskFramework.Tests` still pass without changes
- [ ] App compiles cleanly

## If you get stuck

- The Factory looks like a lot of code, but it's three copies of the same Set/Get pattern. Build one role end-to-end (e.g. Processor) and the other two are mechanical.
- Compiler error "X does not implement Y": you forgot to add the role to the codeunit's `implements` list, or the procedure signature doesn't match the interface exactly.
- Last resort: `git checkout step-4-end` and diff against your work.

## Out of scope for now

Leave these — later steps own them:
- Mock-based tests that exploit the Factory — Step 8
- `Post Vouchers` still flips a status flag instead of journaling — Step 5
- `Post Vouchers` still aborts on the first `Error()` — Step 6
- The `OnBeforeProcessTask` event still publishes from inside the relevant codeunit — Step 7
- The Factory has no telemetry around which role got mocked vs ran default — useful for hardening, not for the workshop.

## Why this step exists

Manual DI works, but it forces every caller to pass three collaborators around. The Factory keeps the seam while reducing the call shape to one parameter. That makes the production path cleaner and gives tests one place to swap any role they need.
