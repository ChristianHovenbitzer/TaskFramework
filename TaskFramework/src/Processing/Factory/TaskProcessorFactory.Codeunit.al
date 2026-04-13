namespace Techdays.TaskFramework.Processing.Factory;

using Techdays.TaskFramework.Core;
using Techdays.TaskFramework.Processing;

// HANDS-ON: Implement the Task Processor Factory.
// This is the default factory that returns the standard implementations.
// Tests can inject custom implementations via Set* methods.
//
// TODO:
//   1. Add "implements "ITask Processor Factory"" to the codeunit declaration
//   2. For each dependency (Processor, Updater, Archiver):
//      - Add a custom variable + HasCustom boolean
//      - Add Set*(value) procedure
//      - Add Get*() procedure that returns custom if set, else default
//   3. The default for all three is the "Task Processor" codeunit itself
//      (it will implement all three interfaces)
codeunit 50008 "Task Processor Factory"
{
    Access = Internal;
}
