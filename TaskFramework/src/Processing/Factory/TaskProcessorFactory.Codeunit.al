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
codeunit 50008 "Task Processor Factory" implements "ITask Processor Factory"
{
    Access = Internal;

    var
        Default: Codeunit "Task Processor";

    #region Processor
    var
        CustomProcessor: Interface "ITask Processor";
        HasCustomProcessor: Boolean;

    procedure SetProcessor(Processor: Interface "ITask Processor")
    begin
        CustomProcessor := Processor;
        HasCustomProcessor := true;
    end;

    procedure GetProcessor(): Interface "ITask Processor"
    begin
        if HasCustomProcessor then
            exit(CustomProcessor);
        exit(Default);
    end;
    #endregion Processor

    #region Updater
    var
        CustomUpdater: Interface "ITask Log Updater";
        HasCustomUpdater: Boolean;

    procedure SetUpdater(Updater: Interface "ITask Log Updater")
    begin
        CustomUpdater := Updater;
        HasCustomUpdater := true;
    end;

    procedure GetUpdater(): Interface "ITask Log Updater"
    begin
        if HasCustomUpdater then
            exit(CustomUpdater);
        exit(Default);
    end;
    #endregion

    #region Archiver
    var
        CustomArchiver: Interface "ITask Archiver";
        HasCustomArchiver: Boolean;

    procedure SetArchiver(Archiver: Interface "ITask Archiver")
    begin
        CustomArchiver := Archiver;
        HasCustomArchiver := true;
    end;

    procedure GetArchiver(): Interface "ITask Archiver"
    begin
        if HasCustomArchiver then
            exit(CustomArchiver);
        exit(Default);
    end;
    #endregion
}
