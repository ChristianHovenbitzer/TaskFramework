// TODO: (Step 3 - DI / Strategy via Interfaces): moved here from the Framework
// app and renumbered to the 60000 range. Seeds Vendor and Voucher demo data —
// references business-specific enum values (VendorImport, DocumentImport) that
// only exist in the Impl app's enum extension.
codeunit 60002 "Install Task Framework"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    begin
        SeedSetup();
        SeedVoucherEntries();
        SeedTaskLogEntries();
    end;

    local procedure SeedSetup()
    var
        SetupRec: Record "Task Framework Setup";
    begin
        if not SetupRec.Get() then begin
            SetupRec.Init();
            SetupRec."Primary Key" := '';
            SetupRec.Enabled := true;
            SetupRec."Max Retry Count" := 3;
            SetupRec."Execution Interval (Seconds)" := 60;
            SetupRec."Default Verbosity" := SetupRec."Default Verbosity"::Normal;
            SetupRec."Enable Batches" := true;
            SetupRec."Batch Size" := 10;
            SetupRec."Archive Enabled" := true;
            SetupRec.Insert();
        end;
    end;

    local procedure SeedVoucherEntries()
    var
        VoucherEntry: Record "Voucher Entry";
    begin
        if not VoucherEntry.IsEmpty() then
            exit;

        // Entry 1: Valid draft voucher
        VoucherEntry.Init();
        VoucherEntry."Voucher No." := 'VOUCH-001';
        VoucherEntry."Customer No." := '10000';
        VoucherEntry.Amount := 100.00;
        VoucherEntry.Status := VoucherEntry.Status::Draft;
        VoucherEntry.Description := 'Gift Card Purchase - Web Order 1001';
        VoucherEntry.Insert(true);

        // Entry 2: Already posted voucher
        VoucherEntry.Init();
        VoucherEntry."Entry No." := 0; // Reset auto-increment to avoid conflict
        VoucherEntry."Voucher No." := 'VOUCH-002';
        VoucherEntry."Customer No." := '20000';
        VoucherEntry.Amount := 250.00;
        VoucherEntry.Status := VoucherEntry.Status::Posted;
        VoucherEntry."Posting Date" := WorkDate();
        VoucherEntry.Description := 'Gift Card Purchase - Web Order 1002';
        VoucherEntry.Insert(true);

        // Entry 3: Missing Customer No. (invalid)
        VoucherEntry.Init();
        VoucherEntry."Entry No." := 0; // Reset auto-increment to avoid conflict
        VoucherEntry."Voucher No." := 'VOUCH-003';
        VoucherEntry."Customer No." := '';
        VoucherEntry.Amount := 50.00;
        VoucherEntry.Status := VoucherEntry.Status::Draft;
        VoucherEntry.Description := 'Gift Card Purchase - Web Order 1003';
        VoucherEntry.Insert(true);

        // Entry 4: Zero amount (invalid)
        VoucherEntry.Init();
        VoucherEntry."Entry No." := 0; // Reset auto-increment to avoid conflict
        VoucherEntry."Voucher No." := 'VOUCH-004';
        VoucherEntry."Customer No." := '10000';
        VoucherEntry.Amount := 0.00;
        VoucherEntry.Status := VoucherEntry.Status::Draft;
        VoucherEntry.Description := 'Adjustment';
        VoucherEntry.Insert(true);

        // Entry 5: Negative amount (redemption)
        VoucherEntry.Init();
        VoucherEntry."Entry No." := 0; // Reset auto-increment to avoid conflict
        VoucherEntry."Voucher No." := 'VOUCH-005';
        VoucherEntry."Customer No." := '30000';
        VoucherEntry.Amount := -75.00;
        VoucherEntry.Status := VoucherEntry.Status::Draft;
        VoucherEntry.Description := 'Gift Card Redemption';
        VoucherEntry.Insert(true);
    end;

    local procedure SeedTaskLogEntries()
    var
        TaskLogEntry: Record "Task Log Entry";
        OutStr: OutStream;
    begin
        if not TaskLogEntry.IsEmpty() then
            exit;

        // Entry 1: Pending vendor import
        TaskLogEntry.Init();
        TaskLogEntry."Entry No." := 0;
        TaskLogEntry."Task Processing Type" := "Task Processing Type"::VendorImport;
        TaskLogEntry.Status := "Task Processing Status"::Pending;
        TaskLogEntry.Description := 'Import vendor from webshop';
        TaskLogEntry."Created At" := CurrentDateTime;
        TaskLogEntry.Verbosity := TaskLogEntry.Verbosity::Normal;
        TaskLogEntry."Correlation Id" := CreateGuid();
        TaskLogEntry."Archive After Processing" := true;
        TaskLogEntry.Insert(true);
        TaskLogEntry.CalcFields(Payload);
        TaskLogEntry.Payload.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText('NAME=Workshop Vendor GmbH;CITY=Munich;COUNTRY=DE');
        TaskLogEntry.Modify();

        // Entry 2: Completed document import
        TaskLogEntry.Init();
        TaskLogEntry."Entry No." := 0;
        TaskLogEntry."Task Processing Type" := "Task Processing Type"::DocumentImport;
        TaskLogEntry.Status := "Task Processing Status"::Complete;
        TaskLogEntry.Description := 'Voucher import batch 2026-03-01';
        TaskLogEntry."Created At" := CurrentDateTime;
        TaskLogEntry."Processing Completed At" := CurrentDateTime;
        TaskLogEntry.Verbosity := TaskLogEntry.Verbosity::Detailed;
        TaskLogEntry."Correlation Id" := CreateGuid();
        TaskLogEntry."Archive After Processing" := true;
        TaskLogEntry.Insert(true);
        TaskLogEntry.CalcFields(Payload);
        TaskLogEntry.Payload.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText('VOUCHERNO=VOUCH-010;CUSTOMERNO=10000;AMOUNT=100.00');
        TaskLogEntry.Modify();

        // Entry 3: Failed log retention
        TaskLogEntry.Init();
        TaskLogEntry."Entry No." := 0;
        TaskLogEntry."Task Processing Type" := "Task Processing Type"::LogRetention;
        TaskLogEntry.Status := "Task Processing Status"::Failed;
        TaskLogEntry.Description := 'Weekly cleanup';
        TaskLogEntry."Created At" := CurrentDateTime;
        TaskLogEntry."Last Error Message" := 'An error occurred.';
        TaskLogEntry.Verbosity := TaskLogEntry.Verbosity::Minimal;
        TaskLogEntry."Correlation Id" := CreateGuid();
        TaskLogEntry.Insert(true);

        // Entry 4: Pending vendor import scheduled for the future
        TaskLogEntry.Init();
        TaskLogEntry."Entry No." := 0;
        TaskLogEntry."Task Processing Type" := "Task Processing Type"::VendorImport;
        TaskLogEntry.Status := "Task Processing Status"::Pending;
        TaskLogEntry.Description := 'Scheduled nightly import';
        TaskLogEntry."Created At" := CurrentDateTime;
        TaskLogEntry.Verbosity := TaskLogEntry.Verbosity::Normal;
        TaskLogEntry."Correlation Id" := CreateGuid();
        TaskLogEntry."Earliest Processing DateTime" := CreateDateTime(CalcDate('<+1D>', Today()), 020000T);
        TaskLogEntry.Insert(true);
        TaskLogEntry.CalcFields(Payload);
        TaskLogEntry.Payload.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText('NAME=Nightly Import Vendor;CITY=Berlin;COUNTRY=DE');
        TaskLogEntry.Modify();
    end;
}
