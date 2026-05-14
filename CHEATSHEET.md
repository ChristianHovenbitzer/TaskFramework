# Step 4 — Factory Routing — Cheat Sheet

> Companion to the "While You Code — Step 4" slide. More room here for details and hints.
> **No copy-paste-ready code on purpose** — type it yourself, that's where the learning happens.

## What you're building in this step

Step 3 made the *what* swappable (which processor runs for a task type). Step 4
makes the *how* swappable: status updates, archiving, and processor lookup all
become injectable so Step 8 can mock each one independently.

By the end:

1. `Task Processor.ProcessTaskEntry` has a second overload that takes an
   `ITask Processor Factory`. The single-arg public version delegates to it
   with a default factory.
2. The status flip and archive call inside `ProcessTaskEntry` route through
   `Factory.GetUpdater()` and `Factory.GetArchiver()` instead of being inline.
3. A test can override any *one* of `Processor`, `Updater`, or `Archiver` and
   let the other two run as production. (Done by step 3.5)
4. `Task Processor` itself implements all three default roles. No new
   "Default Updater" / "Default Archiver" codeunits — the framework's own
   behavior *is* the default. (Done by step 3.5)

## Files you'll touch

**New (Framework app), all in a new `TaskFramework/src/Processing/Factory/` folder:**
- `ITaskProcessorFactory.Interface.al` — three methods, one per role: `GetProcessor`, `GetUpdater`, `GetArchiver`
- `TaskProcessorFactory.Codeunit.al` — `Access = Internal`, `implements "ITask Processor Factory"`. Stateful: holds `Default: Codeunit "Task Processor"` and a Set/Get pair per role.

**Modified (Framework app):**
- `TaskFramework/src/Processing/TaskProcessor.Codeunit.al` — `ProcessTaskEntry` gets a Factory-taking overload.

## Tasks (in order)

### 1. Define the Factory interface
**Goal:** the only interface that callers of `ProcessTaskEntry` need to know about.
**Where:** new file `ITaskProcessorFactory.Interface.al` in the same folder.
**Hint:** three methods, one per role:
- `GetProcessor(): Interface "ITask Processor"`
- `GetUpdater(): Interface "ITask Log Updater"`
- `GetArchiver(): Interface "ITask Archiver"`

The role interfaces stay an internal contract between the factory and `Task Processor`.

### 2. Build the Factory codeunit
**Goal:** the production-default + test-override switchboard.
**Where:** `TaskProcessorFactory.Codeunit.al`. `Access = Internal`, `implements "ITask Processor Factory"`.
**Hint:** holds a `Default: Codeunit "Task Processor"` and three Set/Get pairs — one per role. The shape for each role is identical:
- `Custom<Role>: Interface "I<Role>"` + `HasCustom<Role>: Boolean`
- `Set<Role>(...)` stores the custom impl and flips the boolean
- `Get<Role>()` returns the custom impl if the boolean is true, otherwise returns `Default`

So production returns the framework default; tests call `Set<Role>(Mock)` to override exactly one role.
**Why the `HasCustom*` boolean** instead of just checking whether the interface variable is set? Interfaces are one of the few AL datatypes that *do* hold a null value — but the language gives you no way to ask at runtime whether the variable is null or assigned. The boolean is the workaround: you track "explicitly set" yourself because the type system won't tell you.

### 3. Add the DI overload for `ProcessTaskEntry`
**Goal:** two `ProcessTaskEntry` procedures — one bare for production, one taking a Factory for tests.
**Where:** `TaskProcessor.Codeunit.al`.
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

- [ ] `TaskProcessorFactory` codeunit exists, With three `Set*`/`Get*` pairs gated by `HasCustom*` booleans
- [ ] Nothing in `ProcessTaskEntry`'s body sets `Rec.Status` directly — every status touch goes through `Factory.GetUpdater().UpdateStatus(...)`
- [ ] Two ways to call `ProcessTaskEntry` exist: bare and with-factory; the bare version constructs a default factory and delegates
- [ ] `Process All Pending` still processes Vendor / LogRetention / Document tasks identically — the existing tests in `TaskFramework.Tests` still pass without changes
- [ ] App compiles cleanly

## If you get stuck

- The Factory looks like a lot of code, but it's three copies of the same Set/Get pattern. Build one role end-to-end (e.g. Processor) and the other two are mechanical.
- Compiler error "X does not implement Y": you forgot to add the role to the codeunit's `implements` list, or the procedure signature doesn't match the interface exactly.
- Last resort: `git checkout step-4-end` and diff against your work.

## Out of scope today

Leave these — later steps own them:
- Mock-based tests that exploit the Factory. **Step 8.**
- `Post Vouchers` still flips a status flag instead of journaling. **Step 5.**
- `Post Vouchers` still aborts on the first `Error()`. **Step 6.**
- The `OnBeforeProcessTask` event still publishes from inside the codeunit it's relevant to. **Step 7.**
- The Factory has no telemetry around which role got mocked vs ran default — useful for hardening, not for the workshop.

## Why this step exists

Step 3 used the enum-as-factory shortcut to dispatch processors. That works for *one* axis of variability (which task type runs which body). The moment you need a *second* axis — same task type but a mocked status updater, or a mocked archiver — the enum binding can't help you. The Factory is the named seam where multi-axis variability lives. Step 8 cashes in immediately when the test suite arrives.
