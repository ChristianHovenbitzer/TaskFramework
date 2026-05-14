codeunit 60002 "Install Task Framework"
{
    Access = Internal;
    Subtype = Install;

    // TODO: (Step 8 - Mock via Factory): seed calls commented out so tests start
    // from a clean state. The Seed* procedures are kept available for interactive
    // workshop demos; uncomment when you want the populated company.
    trigger OnInstallAppPerCompany()
    begin
        // SeedSetup();
        // SeedVoucherJournalLines();
        // SeedTaskLogEntries();
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
            SetupRec.Insert(false);
        end;
    end;

    local procedure SeedVoucherJournalLines()
    var
        VoucherJnlLine: Record "Voucher Journal Line";
        LineNo: Integer;
    begin
        if not VoucherJnlLine.IsEmpty() then
            exit;

        LineNo := 10000;

        // Line 1: Valid voucher
        VoucherJnlLine.Init();
        VoucherJnlLine.Validate("Line No.", LineNo);
        VoucherJnlLine.Validate("Voucher No.", 'VOUCH-001');
        VoucherJnlLine.Validate("Customer No.", '10000');
        VoucherJnlLine.Validate(Amount, 100.00);
        VoucherJnlLine.Validate("Posting Date", WorkDate());
        VoucherJnlLine.Validate(Description, 'Gift Card Purchase - Web Order 1001');
        VoucherJnlLine.Insert(true);

        // Line 2: Valid voucher
        LineNo += 10000;
        VoucherJnlLine.Init();
        VoucherJnlLine.Validate("Line No.", LineNo);
        VoucherJnlLine.Validate("Voucher No.", 'VOUCH-002');
        VoucherJnlLine.Validate("Customer No.", '20000');
        VoucherJnlLine.Validate(Amount, 250.00);
        VoucherJnlLine.Validate("Posting Date", WorkDate());
        VoucherJnlLine.Validate(Description, 'Gift Card Purchase - Web Order 1002');
        VoucherJnlLine.Insert(true);

        // Line 3: Missing Customer No. (invalid - for testing)
        LineNo += 10000;
        VoucherJnlLine.Init();
        VoucherJnlLine.Validate("Line No.", LineNo);
        VoucherJnlLine.Validate("Voucher No.", 'VOUCH-003');
        VoucherJnlLine.Validate(Amount, 50.00);
        VoucherJnlLine.Validate("Posting Date", WorkDate());
        VoucherJnlLine.Validate(Description, 'Gift Card Purchase - Web Order 1003');
        VoucherJnlLine.Insert(true);

        // Line 4: Zero amount (invalid - for testing)
        LineNo += 10000;
        VoucherJnlLine.Init();
        VoucherJnlLine.Validate("Line No.", LineNo);
        VoucherJnlLine.Validate("Voucher No.", 'VOUCH-004');
        VoucherJnlLine.Validate("Customer No.", '10000');
        VoucherJnlLine.Validate(Amount, 0.00);
        VoucherJnlLine.Validate("Posting Date", WorkDate());
        VoucherJnlLine.Validate(Description, 'Adjustment');
        VoucherJnlLine.Insert(true);

        // Line 5: Negative amount (redemption)
        LineNo += 10000;
        VoucherJnlLine.Init();
        VoucherJnlLine.Validate("Line No.", LineNo);
        VoucherJnlLine.Validate("Voucher No.", 'VOUCH-005');
        VoucherJnlLine.Validate("Customer No.", '30000');
        VoucherJnlLine.Validate(Amount, -75.00);
        VoucherJnlLine.Validate("Posting Date", WorkDate());
        VoucherJnlLine.Validate(Description, 'Gift Card Redemption');
        VoucherJnlLine.Insert(true);
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
        TaskLogEntry."Created At" := CurrentDateTime();
        TaskLogEntry.Verbosity := TaskLogEntry.Verbosity::Normal;
        TaskLogEntry."Correlation Id" := CreateGuid();
        TaskLogEntry."Archive After Processing" := true;
        TaskLogEntry.Insert(true);
        TaskLogEntry.CalcFields(Payload);
        TaskLogEntry.Payload.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText('NAME=Workshop Vendor GmbH;CITY=Munich;COUNTRY=DE');
        TaskLogEntry.Modify(true);

        // Entry 2: Completed document import
        TaskLogEntry.Init();
        TaskLogEntry."Entry No." := 0;
        TaskLogEntry."Task Processing Type" := "Task Processing Type"::DocumentImport;
        TaskLogEntry.Status := "Task Processing Status"::Complete;
        TaskLogEntry.Description := 'Voucher import batch 2026-03-01';
        TaskLogEntry."Created At" := CurrentDateTime();
        TaskLogEntry."Processing Completed At" := CurrentDateTime();
        TaskLogEntry.Verbosity := TaskLogEntry.Verbosity::Detailed;
        TaskLogEntry."Correlation Id" := CreateGuid();
        TaskLogEntry."Archive After Processing" := true;
        TaskLogEntry.Insert(true);
        TaskLogEntry.CalcFields(Payload);
        TaskLogEntry.Payload.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText('VOUCHERNO=VOUCH-010;CUSTOMERNO=10000;AMOUNT=100.00');
        TaskLogEntry.Modify(true);

        // Entry 3: Failed log retention
        TaskLogEntry.Init();
        TaskLogEntry."Entry No." := 0;
        TaskLogEntry."Task Processing Type" := "Task Processing Type"::LogRetention;
        TaskLogEntry.Status := "Task Processing Status"::Failed;
        TaskLogEntry.Description := 'Weekly cleanup';
        TaskLogEntry."Created At" := CurrentDateTime();
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
        TaskLogEntry."Created At" := CurrentDateTime();
        TaskLogEntry.Verbosity := TaskLogEntry.Verbosity::Normal;
        TaskLogEntry."Correlation Id" := CreateGuid();
        TaskLogEntry."Earliest Processing DateTime" := CreateDateTime(CalcDate('<+1D>', Today()), 020000T);
        TaskLogEntry.Insert(true);
        TaskLogEntry.CalcFields(Payload);
        TaskLogEntry.Payload.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText('NAME=Nightly Import Vendor;CITY=Berlin;COUNTRY=DE');
        TaskLogEntry.Modify(true);
    end;
}
