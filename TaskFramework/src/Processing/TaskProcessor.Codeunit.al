namespace Techdays.TaskFramework.Processing;

using Techdays.TaskFramework.Core;
using Techdays.TaskFramework.Core.Archive;
using Techdays.TaskFramework.Setup;
using Techdays.TaskFramework.Vouchers;
using Microsoft.Purchases.Vendor;

// ANTI-PATTERN: This codeunit is the central problem.
// - It knows about ALL task type business logic (VendorImport, LogRetention, DocumentImport)
// - Adding a new task type means editing this codeunit in the framework app
//
// TODO (Step 3 - DI / Strategy via Interfaces):
//   1. Create "ITask Processor" interface with a ProcessTask(var TaskLogEntry) method.
//   2. Update the "Task Type" enum to implement "ITask Processor", set Extensible = true,
//      and bind each enum value to its concrete implementation.
//   3. Move each ProcessXxxImport procedure into its own codeunit in TaskFramework.Impl
//      (Access = Internal, implements "ITask Processor").
//   4. Replace the CASE block below with: Processor := TaskLogEntry."Task Type";
//      Processor.ProcessTask(TaskLogEntry);
//   5. Remove the per-type local procedures and the self-subscribed event plumbing.
codeunit 50000 "Task Processor"
{
    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessTask(var TaskLogEntry: Record "Task Log Entry"; TaskProcessingState: Codeunit "Task Processing State"; var IsHandled: Boolean)
    begin
    end;


    #region Process Task Entry
    var
        TaskProcessingState: Codeunit "Task Processing State";

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
        //
        // TODO (Step 6 - Collectible Errors): change Check Line's Error() calls to
        // LogError(ErrorLog, ..., IsBlocking) writing to the "Task Error Log" table,
        // and have Post Batch collect all errors before deciding whether to post.
        // Show the full error list (Message or Error Log page) instead of stopping
        // on the first failure.
        Clear(TaskProcessingState);

        TaskLogEntry.SetRange(Status, TaskLogEntry.Status::Pending);
        TaskLogEntry.SetFilter("Earliest Processing DateTime", '%1|<%2', 0DT, CurrentDateTime);
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
        TaskLogEntry."Processing Started At" := CurrentDateTime;
        TaskLogEntry.Modify();

        // THE MONSTER CASE
        // ANTI-PATTERN: Framework app knows about VendorImport, LogRetention, DocumentImport.
        // Adding task type 4 means editing this file in the framework app.
        //
        // TODO (Step 3 - DI / Strategy via Interfaces): replace this entire CASE with
        //      Processor := TaskLogEntry."Task Type";
        //      Processor.ProcessTask(TaskLogEntry);
        // TODO (Step 4 - Factory Pattern): add an internal overload
        //      procedure ProcessTaskEntry(var TaskLogEntry; Processor: Interface "ITask Processor")
        // and have the public entry resolve the processor via "Task Processor Factory".
        // This overload is what makes Step 8 testable.
        case TaskLogEntry."Task Type" of
            "Task Type"::VendorImport:
                ProcessVendorImport(TaskLogEntry);
            "Task Type"::LogRetention:
                ProcessLogRetention(TaskLogEntry);
            "Task Type"::DocumentImport:
                ProcessDocumentImport(TaskLogEntry);
            else
                Error('Unknown task type: %1', TaskLogEntry."Task Type");
        end;

        TaskLogEntry.Status := TaskLogEntry.Status::Complete;
        TaskLogEntry."Processing Completed At" := CurrentDateTime;
        TaskLogEntry.Modify();

        if TaskLogEntry."Archive After Processing" then
            ArchiveEntry(TaskLogEntry);
    end;
    #endregion Process Task Entry

    local procedure ArchiveEntry(var TaskLogEntry: Record "Task Log Entry")
    var
        Archive: Record "Task Log Archive";
    begin
        Archive.Init();
        Archive."Entry No." := TaskLogEntry."Entry No.";
        Archive."Task Type" := TaskLogEntry."Task Type";
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
        Archive."Archived At" := CurrentDateTime;
        Archive."Archive Reason" := Archive."Archive Reason"::Processed;
        Archive.Insert();
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
        // The framework should know NOTHING about Vendors.
        //
        // TODO (Step 3 - DI / Strategy via Interfaces): move this whole procedure into
        // a new codeunit "Vendor Import Processor" in TaskFramework.Impl (Access = Internal,
        // implements "ITask Processor"). Delete this local procedure from the framework.
        TaskLogEntry.CalcFields(Payload);
        if TaskLogEntry.Payload.HasValue() then begin
            TaskLogEntry.Payload.CreateInStream(InStr, TextEncoding::UTF8);
            InStr.ReadText(PayloadText);
        end;

        // Crude "parsing" — another anti-pattern
        VendorName := CopyStr(ExtractValue(PayloadText, 'NAME'), 1, 100);
        VendorCity := CopyStr(ExtractValue(PayloadText, 'CITY'), 1, 50);

        if VendorName = '' then
            VendorName := 'Imported Vendor ' + Format(TaskLogEntry."Entry No.");

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
        TaskFrameworkSetup.GetRecordOnce();
        RetentionDays := TaskFrameworkSetup."Retention Days";
        CutoffDate := CalcDate('<-' + Format(RetentionDays) + 'D>', Today());

        Archive.SetFilter("Archived At", '<%1', CreateDateTime(CutoffDate, 0T));
        Archive.DeleteAll();

        TaskLogEntry.Description := 'Cleaned up archive entries older than ' + Format(RetentionDays) + ' days.';
        TaskLogEntry.Modify();
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
        //
        // TODO (Step 3 - DI / Strategy via Interfaces): move this into a new
        // "Document Import Processor" codeunit in TaskFramework.Impl.
        // TODO (Step 5 - Journal → Posting → Ledger Entry): once the processor lives in
        // the Impl app, have it build Voucher Journal Lines via a Builder
        // (CreateFromTaskPayload, Init → Validate PK → Insert → Validate fields → Modify)
        // and then run "Voucher Jnl.-Post Batch" to post them through the Check Line /
        // Post Line / Post Batch pipeline.
        TaskLogEntry.CalcFields(Payload);
        if TaskLogEntry.Payload.HasValue() then begin
            TaskLogEntry.Payload.CreateInStream(InStr, TextEncoding::UTF8);
            InStr.ReadText(PayloadText);
        end;

        VoucherNo := CopyStr(ExtractValue(PayloadText, 'VOUCHERNO'), 1, 20);
        CustomerNo := CopyStr(ExtractValue(PayloadText, 'CUSTOMERNO'), 1, 20);
        Evaluate(Amount, ExtractValue(PayloadText, 'AMOUNT'));

        if VoucherNo = '' then
            VoucherNo := 'VOUCH-TASK-' + Format(TaskLogEntry."Entry No.");

        VoucherEntry.Init();
        VoucherEntry."Voucher No." := VoucherNo;
        VoucherEntry."Customer No." := CustomerNo;
        VoucherEntry.Amount := Amount;
        VoucherEntry.Description := 'Imported via task ' + Format(TaskLogEntry."Entry No.");
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
        for i := 1 to Part.Count do begin
            Segment := Part.Get(i).Trim();
            if Segment.IndexOf(FieldKey + '=') = 1 then
                exit(CopyStr(Segment, StrLen(FieldKey) + 2));
        end;
        exit('');
    end;
}
