codeunit 50005 "Log Retention Processor" implements "ITask Processor"
{
    Access = Internal;

    var
        CleanupDescLbl: Label 'Cleaned up archive entries older than %1 days.';
        RetentionDateFormulaTok: Label '<-%1D>', Locked = true;
        ArchivedBeforeFilterTok: Label '<%1', Locked = true;


    procedure ProcessTask(var TaskLogEntry: Record "Task Log Entry")
    var
        Archive: Record "Task Log Archive";
        TaskFrameworkSetup: Record "Task Framework Setup";
        RetentionDays: Integer;
        CutoffDate: Date;
    begin
        TaskFrameworkSetup.GetRecordOnce();
        RetentionDays := TaskFrameworkSetup."Retention Days";
        CutoffDate := CalcDate(StrSubstNo(RetentionDateFormulaTok, RetentionDays), Today());

        Archive.SetFilter("Archived At", ArchivedBeforeFilterTok, CreateDateTime(CutoffDate, 0T));
        Archive.DeleteAll(false);

        TaskLogEntry.Description := StrSubstNo(CleanupDescLbl, RetentionDays);
        TaskLogEntry.Modify(false);
    end;
}
