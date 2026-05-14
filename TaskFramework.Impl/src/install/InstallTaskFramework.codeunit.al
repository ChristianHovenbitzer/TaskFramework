codeunit 60002 "Install Task Framework"
{
    Access = Internal;
    Subtype = Install;

    // TODO: (Step 8 - Mock via Factory): comment out these seed calls. Tests should
    // arrange their own state — auto-seeding pollutes test runs with data they
    // didn't ask for. Leave the Seed* procedures in place; they're useful when
    // demoing the workshop scenario interactively.

    var
        TaskDescVendorImportLbl: Label 'Import vendor from webshop';
        TaskDescVoucherImportLbl: Label 'Voucher import batch 2026-03-01';
        TaskDescWeeklyCleanupLbl: Label 'Weekly cleanup';
        TaskErrSampleLbl: Label 'An error occurred.';
        TaskDescNightlyImportLbl: Label 'Scheduled nightly import';
        NextDayFormulaTok: Label '<+1D>', Locked = true;
        VendorPayloadWorkshopTok: Label 'NAME=Workshop Vendor GmbH;CITY=Munich;COUNTRY=DE', Locked = true;
        VoucherPayloadSampleTok: Label 'VOUCHERNO=VOUCH-010;CUSTOMERNO=10000;AMOUNT=100.00', Locked = true;
        VendorPayloadNightlyTok: Label 'NAME=Nightly Import Vendor;CITY=Berlin;COUNTRY=DE', Locked = true;
        VoucherNo1Tok: Label 'VOUCH-001', Locked = true;
        VoucherNo2Tok: Label 'VOUCH-002', Locked = true;
        VoucherNo3Tok: Label 'VOUCH-003', Locked = true;
        VoucherNo4Tok: Label 'VOUCH-004', Locked = true;
        VoucherNo5Tok: Label 'VOUCH-005', Locked = true;
        Customer10000Tok: Label '10000', Locked = true;
        Customer20000Tok: Label '20000', Locked = true;
        Customer30000Tok: Label '30000', Locked = true;
        VoucherDescGiftCard1Lbl: Label 'Gift Card Purchase - Web Order 1001';
        VoucherDescGiftCard2Lbl: Label 'Gift Card Purchase - Web Order 1002';
        VoucherDescGiftCard3Lbl: Label 'Gift Card Purchase - Web Order 1003';
        VoucherDescAdjustmentLbl: Label 'Adjustment';
        VoucherDescGiftCardRedeemLbl: Label 'Gift Card Redemption';

    trigger OnInstallAppPerCompany()
    begin
        SeedSetup();
        SeedVoucherJournalLines();
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
        VoucherJnlLine.Validate("Voucher No.", VoucherNo1Tok);
        VoucherJnlLine.Validate("Customer No.", Customer10000Tok);
        VoucherJnlLine.Validate(Amount, 100.00);
        VoucherJnlLine.Validate("Posting Date", WorkDate());
        VoucherJnlLine.Validate(Description, VoucherDescGiftCard1Lbl);
        VoucherJnlLine.Insert(true);

        // Line 2: Valid voucher
        LineNo += 10000;
        VoucherJnlLine.Init();
        VoucherJnlLine.Validate("Line No.", LineNo);
        VoucherJnlLine.Validate("Voucher No.", VoucherNo2Tok);
        VoucherJnlLine.Validate("Customer No.", Customer20000Tok);
        VoucherJnlLine.Validate(Amount, 250.00);
        VoucherJnlLine.Validate("Posting Date", WorkDate());
        VoucherJnlLine.Validate(Description, VoucherDescGiftCard2Lbl);
        VoucherJnlLine.Insert(true);

        // Line 3: Missing Customer No. (invalid - for testing)
        LineNo += 10000;
        VoucherJnlLine.Init();
        VoucherJnlLine.Validate("Line No.", LineNo);
        VoucherJnlLine.Validate("Voucher No.", VoucherNo3Tok);
        VoucherJnlLine.Validate(Amount, 50.00);
        VoucherJnlLine.Validate("Posting Date", WorkDate());
        VoucherJnlLine.Validate(Description, VoucherDescGiftCard3Lbl);
        VoucherJnlLine.Insert(true);

        // Line 4: Zero amount (invalid - for testing)
        LineNo += 10000;
        VoucherJnlLine.Init();
        VoucherJnlLine.Validate("Line No.", LineNo);
        VoucherJnlLine.Validate("Voucher No.", VoucherNo4Tok);
        VoucherJnlLine.Validate("Customer No.", Customer10000Tok);
        VoucherJnlLine.Validate(Amount, 0.00);
        VoucherJnlLine.Validate("Posting Date", WorkDate());
        VoucherJnlLine.Validate(Description, VoucherDescAdjustmentLbl);
        VoucherJnlLine.Insert(true);

        // Line 5: Negative amount (redemption)
        LineNo += 10000;
        VoucherJnlLine.Init();
        VoucherJnlLine.Validate("Line No.", LineNo);
        VoucherJnlLine.Validate("Voucher No.", VoucherNo5Tok);
        VoucherJnlLine.Validate("Customer No.", Customer30000Tok);
        VoucherJnlLine.Validate(Amount, -75.00);
        VoucherJnlLine.Validate("Posting Date", WorkDate());
        VoucherJnlLine.Validate(Description, VoucherDescGiftCardRedeemLbl);
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
        TaskLogEntry.Description := TaskDescVendorImportLbl;
        TaskLogEntry."Created At" := CurrentDateTime();
        TaskLogEntry.Verbosity := TaskLogEntry.Verbosity::Normal;
        TaskLogEntry."Correlation Id" := CreateGuid();
        TaskLogEntry."Archive After Processing" := true;
        TaskLogEntry.Insert(true);
        TaskLogEntry.CalcFields(Payload);
        TaskLogEntry.Payload.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(VendorPayloadWorkshopTok);
        TaskLogEntry.Modify(true);

        // Entry 2: Completed document import
        TaskLogEntry.Init();
        TaskLogEntry."Entry No." := 0;
        TaskLogEntry."Task Processing Type" := "Task Processing Type"::DocumentImport;
        TaskLogEntry.Status := "Task Processing Status"::Complete;
        TaskLogEntry.Description := TaskDescVoucherImportLbl;
        TaskLogEntry."Created At" := CurrentDateTime();
        TaskLogEntry."Processing Completed At" := CurrentDateTime();
        TaskLogEntry.Verbosity := TaskLogEntry.Verbosity::Detailed;
        TaskLogEntry."Correlation Id" := CreateGuid();
        TaskLogEntry."Archive After Processing" := true;
        TaskLogEntry.Insert(true);
        TaskLogEntry.CalcFields(Payload);
        TaskLogEntry.Payload.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(VoucherPayloadSampleTok);
        TaskLogEntry.Modify(true);

        // Entry 3: Failed log retention
        TaskLogEntry.Init();
        TaskLogEntry."Entry No." := 0;
        TaskLogEntry."Task Processing Type" := "Task Processing Type"::LogRetention;
        TaskLogEntry.Status := "Task Processing Status"::Failed;
        TaskLogEntry.Description := TaskDescWeeklyCleanupLbl;
        TaskLogEntry."Created At" := CurrentDateTime();
        TaskLogEntry."Last Error Message" := TaskErrSampleLbl;
        TaskLogEntry.Verbosity := TaskLogEntry.Verbosity::Minimal;
        TaskLogEntry."Correlation Id" := CreateGuid();
        TaskLogEntry.Insert(true);

        // Entry 4: Pending vendor import scheduled for the future
        TaskLogEntry.Init();
        TaskLogEntry."Entry No." := 0;
        TaskLogEntry."Task Processing Type" := "Task Processing Type"::VendorImport;
        TaskLogEntry.Status := "Task Processing Status"::Pending;
        TaskLogEntry.Description := TaskDescNightlyImportLbl;
        TaskLogEntry."Created At" := CurrentDateTime();
        TaskLogEntry.Verbosity := TaskLogEntry.Verbosity::Normal;
        TaskLogEntry."Correlation Id" := CreateGuid();
        TaskLogEntry."Earliest Processing DateTime" := CreateDateTime(CalcDate(NextDayFormulaTok, Today()), 020000T);
        TaskLogEntry.Insert(true);
        TaskLogEntry.CalcFields(Payload);
        TaskLogEntry.Payload.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(VendorPayloadNightlyTok);
        TaskLogEntry.Modify(true);
    end;
}
