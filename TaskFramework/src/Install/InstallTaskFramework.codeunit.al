// TODO: (Step 3 - DI / Strategy via Interfaces): move this whole codeunit into the
// Impl app (TaskFramework.Impl/src/install/), renumber to the 60000 range, and
// delete this folder. The framework shouldn't seed Vendor or Voucher demo data
// — that lives in the Impl app once business-specific enum values move there.
codeunit 50002 "Install Task Framework"
{
    Access = Internal;
    Subtype = Install;

    var
        VoucherDescGiftCard1Lbl: Label 'Gift Card Purchase - Web Order 1001';
        VoucherDescGiftCard2Lbl: Label 'Gift Card Purchase - Web Order 1002';
        VoucherDescGiftCard3Lbl: Label 'Gift Card Purchase - Web Order 1003';
        VoucherDescAdjustmentLbl: Label 'Adjustment';
        VoucherDescGiftCardRedeemLbl: Label 'Gift Card Redemption';
        TaskDescVendorImportLbl: Label 'Import vendor from webshop';
        TaskDescVoucherImportLbl: Label 'Voucher import batch 2026-03-01';
        TaskDescWeeklyCleanupLbl: Label 'Weekly cleanup';
        TaskErrSampleLbl: Label 'An error occurred.';
        TaskDescNightlyImportLbl: Label 'Scheduled nightly import';
        Customer10000Tok: Label '10000', Locked = true;
        Customer20000Tok: Label '20000', Locked = true;
        Customer30000Tok: Label '30000', Locked = true;
        VoucherNo1Tok: Label 'VOUCH-001', Locked = true;
        VoucherNo2Tok: Label 'VOUCH-002', Locked = true;
        VoucherNo3Tok: Label 'VOUCH-003', Locked = true;
        VoucherNo4Tok: Label 'VOUCH-004', Locked = true;
        VoucherNo5Tok: Label 'VOUCH-005', Locked = true;
        NextDayFormulaTok: Label '<+1D>', Locked = true;
        VendorPayloadWorkshopTok: Label 'NAME=Workshop Vendor GmbH;CITY=Munich;COUNTRY=DE', Locked = true;
        VoucherPayloadSampleTok: Label 'VOUCHERNO=VOUCH-010;CUSTOMERNO=10000;AMOUNT=100.00', Locked = true;
        VendorPayloadNightlyTok: Label 'NAME=Nightly Import Vendor;CITY=Berlin;COUNTRY=DE', Locked = true;


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
            SetupRec.Insert(false);
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
        VoucherEntry."Voucher No." := VoucherNo1Tok;
        VoucherEntry."Customer No." := Customer10000Tok;
        VoucherEntry.Amount := 100.00;
        VoucherEntry.Status := VoucherEntry.Status::Draft;
        VoucherEntry.Description := VoucherDescGiftCard1Lbl;
        VoucherEntry.Insert(true);

        // Entry 2: Already posted voucher
        VoucherEntry.Init();
        VoucherEntry."Entry No." := 0; // Reset auto-increment to avoid conflict
        VoucherEntry."Voucher No." := VoucherNo2Tok;
        VoucherEntry."Customer No." := Customer20000Tok;
        VoucherEntry.Amount := 250.00;
        VoucherEntry.Status := VoucherEntry.Status::Posted;
        VoucherEntry."Posting Date" := WorkDate();
        VoucherEntry.Description := VoucherDescGiftCard2Lbl;
        VoucherEntry.Insert(true);

        // Entry 3: Missing Customer No. (invalid)
        VoucherEntry.Init();
        VoucherEntry."Entry No." := 0; // Reset auto-increment to avoid conflict
        VoucherEntry."Voucher No." := VoucherNo3Tok;
        VoucherEntry."Customer No." := '';
        VoucherEntry.Amount := 50.00;
        VoucherEntry.Status := VoucherEntry.Status::Draft;
        VoucherEntry.Description := VoucherDescGiftCard3Lbl;
        VoucherEntry.Insert(true);

        // Entry 4: Zero amount (invalid)
        VoucherEntry.Init();
        VoucherEntry."Entry No." := 0; // Reset auto-increment to avoid conflict
        VoucherEntry."Voucher No." := VoucherNo4Tok;
        VoucherEntry."Customer No." := Customer10000Tok;
        VoucherEntry.Amount := 0.00;
        VoucherEntry.Status := VoucherEntry.Status::Draft;
        VoucherEntry.Description := VoucherDescAdjustmentLbl;
        VoucherEntry.Insert(true);

        // Entry 5: Negative amount (redemption)
        VoucherEntry.Init();
        VoucherEntry."Entry No." := 0; // Reset auto-increment to avoid conflict
        VoucherEntry."Voucher No." := VoucherNo5Tok;
        VoucherEntry."Customer No." := Customer30000Tok;
        VoucherEntry.Amount := -75.00;
        VoucherEntry.Status := VoucherEntry.Status::Draft;
        VoucherEntry.Description := VoucherDescGiftCardRedeemLbl;
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
        TaskLogEntry.Description := TaskDescVendorImportLbl;
        TaskLogEntry."Created At" := CurrentDateTime();
        TaskLogEntry.Verbosity := TaskLogEntry.Verbosity::Normal;
        TaskLogEntry."Correlation Id" := CreateGuid();
        TaskLogEntry."Archive After Processing" := true;
        TaskLogEntry.Insert(true);
        TaskLogEntry.CalcFields(Payload);
        TaskLogEntry.Payload.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(VendorPayloadWorkshopTok);
        TaskLogEntry.Modify(false);

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
        TaskLogEntry.Modify(false);

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
        TaskLogEntry.Modify(false);
    end;
}
