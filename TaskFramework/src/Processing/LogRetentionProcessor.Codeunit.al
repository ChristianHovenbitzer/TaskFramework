namespace Techdays.TaskFramework.Processing;

using Techdays.TaskFramework.Core;
using Techdays.TaskFramework.Core.Archive;
using Techdays.TaskFramework.Setup;

codeunit 50005 "Log Retention Processor" implements "ITask Processor"
{
    Access = Internal;

    procedure ProcessTask(var TaskLogEntry: Record "Task Log Entry")
    var
        Archive: Record "Task Log Archive";
        TaskFrameworkSetup: Record "Task Framework Setup";
        RetentionDays: Integer;
        CutoffDate: Date;
    begin
        TaskFrameworkSetup.GetRecordOnce();
        RetentionDays := TaskFrameworkSetup."Retention Days";
        CutoffDate := CalcDate('<-' + Format(RetentionDays) + 'D>', Today());

        Archive.SetFilter("Archived At", '<%1', CreateDateTime(CutoffDate, 0T));
        Archive.DeleteAll();

        TaskLogEntry.Description := 'Cleaned up archive entries older than ' + Format(RetentionDays) + ' days.';
        TaskLogEntry.Modify();
    end;
}
