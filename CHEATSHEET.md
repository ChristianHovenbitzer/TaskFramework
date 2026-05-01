# Step 4 — Factory Routing — Cheat Sheet

> Companion to the "While You Code — Step 4" slide. More room here for details and hints.
> **No copy-paste-ready code on purpose** — type it yourself, that's where the learning happens.

## What you're building in this step

Add a `Task Processor Factory` codeunit that maps `Task Type` → `ITask Processor` and
introduce a public/internal overload pair on `Task Processor.ProcessTaskEntry` so test
code can inject a mock instead of going through the enum binding.

By the end: the Factory is the *single place* that decides "which implementation for
which task type?", and the test app has a clean seam to swap it.

## Files you'll touch

**New (Framework app):**
- `TaskFramework/src/Processing/TaskProcessorFactory.Codeunit.al` — the Factory

**Modified (Framework app):**
- `TaskFramework/src/Processing/TaskProcessor.Codeunit.al` — add internal overload, public delegates to it via the Factory

## Tasks (in order)

### 1. Create the Factory codeunit
**Goal:** one method, `GetProcessor(TaskType): Interface "ITask Processor"`.
**Where:** new file `TaskProcessorFactory.Codeunit.al` in `TaskFramework/src/Processing/`.
**Hint:** the body is one line — `exit(TaskType)`. The enum→interface binding already does the work; the Factory is the *named seam* for it.
**Common reaction:** "this looks pointless." It's deliberately thin today. Its value shows up the moment you need test overrides, configuration-based selection, or a second interface (error handlers, validators) — Step 8 cashes in immediately.

### 2. Add the DI overload pair on Task Processor
**Goal:** two `ProcessTaskEntry` procedures — public (no Processor parameter) and `internal` (takes a `Processor: Interface "ITask Processor"`).
**Where:** `TaskProcessor.Codeunit.al`.
**Hint:**
- The **internal** version contains the actual logic — status updates, the call to `Processor.ProcessTask`, archive trigger.
- The **public** version resolves the processor via the Factory and calls the internal overload. One line in its body.
- Make the parameter version `internal` so only same-app and test-app callers (with internal access) can inject. Production code goes through the public entry point.

### 3. Wire callers through the Factory
**Goal:** the public `ProcessTaskEntry` no longer does `Processor := TaskLogEntry."Task Processing Type"` directly.
**Where:** still `TaskProcessor.Codeunit.al`.
**Hint:** declare `Factory: Codeunit "Task Processor Factory"` locally, call `Factory.GetProcessor(TaskLogEntry."Task Processing Type")`, pass the result into the internal overload.

### 4. Sanity-check the access modifiers
**Goal:** the impl processors are still `Access = Internal`. The interface and Factory are `public` (default). The internal overload is reachable by the test app via `internalsVisibleTo` in the framework's `app.json` (set up during Step 8 — confirm it isn't accidentally locked down).

## Done when

- [ ] `Task Processor Factory` exists with a single `GetProcessor` method
- [ ] `Task Processor` has a public `ProcessTaskEntry(var TaskLogEntry)` AND an `internal procedure ProcessTaskEntry(var TaskLogEntry; Processor: Interface "ITask Processor")`
- [ ] The public entry routes through the Factory; the internal entry contains the actual logic
- [ ] `Process All Pending` still processes Vendor / LogRetention / Document tasks identically
- [ ] App compiles, no warnings about unused vars or unreachable code

## If you get stuck

- The Factory body really is one line. Don't overthink it.
- If the compiler complains about ambiguous overloads, double-check the parameter lists differ (one has 1 param, one has 2).
- See `docs/pattern-status.md` Step 4 section.
- Last resort: `git checkout step-4-end`.

## Why this step is short

Christian's framing from the sync calls: *"Now we have 5-6 interfaces, it's messy again,
we need a solution."* — the Factory emerges naturally from interface proliferation.
Today we have one interface, so the Factory looks tiny. The pattern is what we're
locking in; the payoff compounds as the system grows.
