// TODO: (Step 8 - Mock via Factory): one mock playing all three Step-4 roles.
// Tests pass this single instance to Factory.SetProcessor / SetUpdater /
// SetArchiver, then assert against the shared Call Recorder.
/// <summary>
/// Mock that implements all three collaborator interfaces and records every call.
/// Does not modify the database — pure spy for orchestration tests.
/// </summary>
codeunit 70012 "Mock Task Runner" implements "ITask Log Updater", "ITask Archiver", "ITask Processor"
{
    procedure UpdateStatus(var TaskLogEntry: Record "Task Log Entry"; NewStatus: Enum "Task Processing Status")
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
