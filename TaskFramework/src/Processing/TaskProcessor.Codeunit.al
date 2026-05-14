using Microsoft.Purchases.Vendor;

// ANTI-PATTERN: This codeunit is the central problem.
// - It knows about ALL task type business logic (VendorImport, LogRetention, DocumentImport)
// - Adding a new task type means editing this codeunit in the framework app
// - Step 3 will replace this CASE routing with ITaskProcessor interface + enum-interface binding
codeunit 50000 "Task Processor"
{
    var
        ImportedVendorNameLbl: Label 'Imported Vendor %1';
        ImportedViaTaskLbl: Label 'Imported via task %1';
        CleanupDescLbl: Label 'Cleaned up archive entries older than %1 days.';
        DueDatePendingFilterTok: Label '%1|<%2', Locked = true;
        RetentionDateFormulaTok: Label '<-%1D>', Locked = true;
        ArchivedBeforeFilterTok: Label '<%1', Locked = true;
        PayloadKeyNameTok: Label 'NAME', Locked = true;
        PayloadKeyCityTok: Label 'CITY', Locked = true;
        PayloadKeyVoucherNoTok: Label 'VOUCHERNO', Locked = true;
        PayloadKeyCustomerNoTok: Label 'CUSTOMERNO', Locked = true;
        PayloadKeyAmountTok: Label 'AMOUNT', Locked = true;
        VoucherNoTaskFormatTok: Label 'VOUCH-TASK-%1', Locked = true;

    // TODO: (Step 2 - Separation of Concerns): event signature now passes the state
    // codeunit so subscribers can read it. The in-app self-subscriber is gone.
    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessTask(var TaskLogEntry: Record "Task Log Entry"; TaskProcessingState: Codeunit "Task Processing State"; var IsHandled: Boolean)
    begin
    end;


    #region Process Task Entry
    var
        TaskProcessingState: Codeunit "Task Processing State";
        UnknownTaskTypeErr: Label 'Unknown task type: %1';

    procedure GetTaskProcessingState(): Codeunit "Task Processing State"
    begin
        exit(TaskProcessingState);
    end;

    procedure ProcessAllPendingTasks()
    var
        TaskLogEntry: Record "Task Log Entry";
    begin
        // ANTI-PATTERN: No error isolation.
        // If ProcessTaskEntry throws for entry 3 of 10, entries 4-10 never run.
        // Step 6 will fix this with proper error handling.
        // TODO: (Step 2 - Separation of Concerns): state is held as a local var on this
        // codeunit and Clear()ed per run; counter calls moved inline here from the
        // deleted self-subscriber.
        Clear(TaskProcessingState);

        TaskLogEntry.SetRange(Status, TaskLogEntry.Status::Pending);
        TaskLogEntry.SetFilter("Earliest Processing DateTime", DueDatePendingFilterTok, 0DT, CurrentDateTime());
        if TaskLogEntry.FindSet(true) then
            repeat
                ProcessTaskEntry(TaskLogEntry);
                TaskProcessingState.IncrementProcessedCount();
                TaskProcessingState.SetLastProcessed(TaskLogEntry."Entry No.");
            until TaskLogEntry.Next() = 0;
    end;

    procedure ProcessTaskEntry(var TaskLogEntry: Record "Task Log Entry")
    var
        IsHandled: Boolean;
    begin
        OnBeforeProcessTask(TaskLogEntry, TaskProcessingState, IsHandled);
        if IsHandled then
            exit;

        TaskLogEntry.Status := TaskLogEntry.Status::Processing;
        TaskLogEntry."Processing Started At" := CurrentDateTime();
        TaskLogEntry.Modify(false);

        // THE MONSTER CASE
        // ANTI-PATTERN: Framework app knows about VendorImport, LogRetention, DocumentImport.
        // Adding task type 4 means editing this file in the framework app.
        case TaskLogEntry."Task Processing Type" of
            "Task Processing Type"::VendorImport:
                ProcessVendorImport(TaskLogEntry);
            "Task Processing Type"::LogRetention:
                ProcessLogRetention(TaskLogEntry);
            "Task Processing Type"::DocumentImport:
                ProcessDocumentImport(TaskLogEntry);
            else
                Error(UnknownTaskTypeErr, TaskLogEntry."Task Processing Type");
        end;

        TaskLogEntry.Status := TaskLogEntry.Status::Complete;
        TaskLogEntry."Processing Completed At" := CurrentDateTime();
        TaskLogEntry.Modify(false);

        ArchiveEntry(TaskLogEntry);
    end;
    #endregion Process Task Entry

    local procedure ArchiveEntry(var TaskLogEntry: Record "Task Log Entry")
    var
        Archive: Record "Task Log Archive";
    begin
        if not TaskLogEntry."Archive After Processing" then
            exit;

        Archive.Init();
        Archive."Entry No." := TaskLogEntry."Entry No.";
        Archive."Task Type" := TaskLogEntry."Task Processing Type";
        Archive.Status := TaskLogEntry.Status;
        Archive.Description := TaskLogEntry.Description;
        Archive."Created At" := TaskLogEntry."Created At";
        Archive."Processing Started At" := TaskLogEntry."Processing Started At";
        Archive."Processing Completed At" := TaskLogEntry."Processing Completed At";
        Archive."Last Error Message" := TaskLogEntry."Last Error Message";
        Archive."Retry Count" := TaskLogEntry."Retry Count";
        Archive.Verbosity := TaskLogEntry.Verbosity;
        Archive."Correlation Id" := TaskLogEntry."Correlation Id";
        Archive."Archive After Processing" := TaskLogEntry."Archive After Processing";
        Archive."Earliest Processing DateTime" := TaskLogEntry."Earliest Processing DateTime";
        Archive."Archived At" := CurrentDateTime();
        Archive."Archive Reason" := Archive."Archive Reason"::Processed;
        Archive.Insert(false);
    end;

    local procedure ProcessVendorImport(var TaskLogEntry: Record "Task Log Entry")
    var
        Vendor: Record Vendor;
        PayloadText: Text;
        InStr: InStream;
        VendorName: Text[100];
        VendorCity: Text[50];
    begin
        // ANTI-PATTERN: Inline business logic — creating a Vendor from a task payload.
        // This logic belongs in a separate VendorImportProcessor codeunit in the impl app.
        // The framework should know NOTHING about Vendors.
        TaskLogEntry.CalcFields(Payload);
        if TaskLogEntry.Payload.HasValue() then begin
            TaskLogEntry.Payload.CreateInStream(InStr, TextEncoding::UTF8);
            InStr.ReadText(PayloadText);
        end;

        // Crude "parsing" — another anti-pattern
        VendorName := CopyStr(ExtractValue(PayloadText, PayloadKeyNameTok), 1, 100);
        VendorCity := CopyStr(ExtractValue(PayloadText, PayloadKeyCityTok), 1, 50);

        if VendorName = '' then
            VendorName := StrSubstNo(ImportedVendorNameLbl, TaskLogEntry."Entry No.");

        Vendor.Init();
        Vendor.Name := VendorName;
        Vendor.City := VendorCity;
        Vendor.Insert(true);
    end;

    local procedure ProcessLogRetention(var TaskLogEntry: Record "Task Log Entry")
    var
        Archive: Record "Task Log Archive";
        TaskFrameworkSetup: Record "Task Framework Setup";
        RetentionDays: Integer;
        CutoffDate: Date;
    begin
        // TODO: (Step 2 - Separation of Concerns): retention days now read from Setup
        // (was hardcoded 30).
        TaskFrameworkSetup.GetRecordOnce();
        RetentionDays := TaskFrameworkSetup."Retention Days";
        CutoffDate := CalcDate(StrSubstNo(RetentionDateFormulaTok, RetentionDays), Today());

        Archive.SetFilter("Archived At", ArchivedBeforeFilterTok, CreateDateTime(CutoffDate, 0T));
        Archive.DeleteAll(false);

        TaskLogEntry.Description := StrSubstNo(CleanupDescLbl, RetentionDays);
        TaskLogEntry.Modify(false);
    end;

    local procedure ProcessDocumentImport(var TaskLogEntry: Record "Task Log Entry")
    var
        VoucherEntry: Record "Voucher Entry";
        PostVouchers: Codeunit "Post Vouchers";
        PayloadText: Text;
        InStr: InStream;
        VoucherNo: Code[20];
        CustomerNo: Code[20];
        Amount: Decimal;
    begin
        // ANTI-PATTERN: Document import logic inline in framework.
        // Parses payload, creates Voucher Entry, IMMEDIATELY posts it — no staging/review.
        // Step 5 will: create Journal Lines via Builder, batch-post via Jnl.-Post Batch.
        TaskLogEntry.CalcFields(Payload);
        if TaskLogEntry.Payload.HasValue() then begin
            TaskLogEntry.Payload.CreateInStream(InStr, TextEncoding::UTF8);
            InStr.ReadText(PayloadText);
        end;

        VoucherNo := CopyStr(ExtractValue(PayloadText, PayloadKeyVoucherNoTok), 1, 20);
        CustomerNo := CopyStr(ExtractValue(PayloadText, PayloadKeyCustomerNoTok), 1, 20);
        Evaluate(Amount, ExtractValue(PayloadText, PayloadKeyAmountTok));

        if VoucherNo = '' then
            VoucherNo := StrSubstNo(VoucherNoTaskFormatTok, TaskLogEntry."Entry No.");

        VoucherEntry.Init();
        VoucherEntry."Voucher No." := VoucherNo;
        VoucherEntry."Customer No." := CustomerNo;
        VoucherEntry.Amount := Amount;
        VoucherEntry.Description := StrSubstNo(ImportedViaTaskLbl, TaskLogEntry."Entry No.");
        VoucherEntry.Insert(true);

        // Immediately post — no staging, no review, no batch validation
        PostVouchers.PostVoucher(VoucherEntry);
    end;

    // Crude key=value parser for the anti-pattern payload format "KEY=VALUE;KEY2=VALUE2"
    local procedure ExtractValue(PayloadText: Text; FieldKey: Text): Text
    var
        Part: List of [Text];
        Segment: Text;
        i: Integer;
    begin
        Part := PayloadText.Split(';');
        for i := 1 to Part.Count() do begin
            Segment := Part.Get(i).Trim();
            if Segment.IndexOf(FieldKey + '=') = 1 then
                exit(CopyStr(Segment, StrLen(FieldKey) + 2));
        end;
        exit('');
    end;
}
