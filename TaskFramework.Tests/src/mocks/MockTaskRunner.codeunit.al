namespace Techdays.TaskFramework.Tests.Mocks;

using Techdays.TaskFramework.Core;
using Techdays.TaskFramework.Processing;
using Techdays.TaskFramework.Processing.Factory;

/// <summary>
/// Mock that implements all three collaborator interfaces and records every call.
/// Does not modify the database — pure spy for orchestration tests.
/// </summary>
codeunit 70012 "Mock Task Runner" implements "ITask Log Updater", "ITask Archiver", "ITask Processor"
{
    procedure UpdateStatus(var TaskLogEntry: Record "Task Log Entry"; NewStatus: Enum "Task Status")
    var
        Recorder: Codeunit "Call Recorder";
    begin
        Recorder.Record(StrSubstNo('Updater.UpdateStatus:%1', NewStatus));
    end;

    procedure Archive(var TaskLogEntry: Record "Task Log Entry")
    var
        Recorder: Codeunit "Call Recorder";
    begin
        Recorder.Record(StrSubstNo('Archiver.Archive:%1', TaskLogEntry."Entry No."));
    end;

    procedure ProcessTask(var TaskLogEntry: Record "Task Log Entry")
    var
        Recorder: Codeunit "Call Recorder";
    begin
        Recorder.Record(StrSubstNo('Processor.ProcessTask:%1', TaskLogEntry."Entry No."));
    end;
}
