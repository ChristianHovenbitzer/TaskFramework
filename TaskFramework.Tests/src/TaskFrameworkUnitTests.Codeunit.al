using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

/// <summary>
/// Unit/integration tests — one comprehensive test per production unit:
///   1. Task Processor.UpdateStatus
///   2. Task Processor.Archive
///   3. Vendor Import Processor.ProcessTask  (dispatched via Task Type enum)
///   4. Document Import Processor.ProcessTask (dispatched via Task Type enum)
///
/// Each test drives the full happy-path through the function and asserts
/// against every observable side effect, so a single green test row in the
/// runner demonstrates that the whole unit works end to end.
/// </summary>
// TODO: (Step 8 - Mock via Factory): new test codeunit holding one comprehensive
// happy-path test per production unit (Task Processor.UpdateStatus and .Archive,
// each impl processor's ProcessTask). Pairs with the spy-driven orchestration
// tests in TaskFrameworkTests.Codeunit.al.
codeunit 70009 "Task Framework Unit Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Test Assert";

    [Test]
    procedure TestUpdateStatusDrivesFullLifecycle()
    var
        TaskLogEntry: Record "Task Log Entry";
        TaskProcessor: Codeunit "Task Processor";
        BeforeProcessing: DateTime;
        BeforeComplete: DateTime;
    begin
        // Arrange — a Pending entry on disk so Modify has something to update.
        TaskLogEntry.Init();
        TaskLogEntry."Task Processing Type" := TaskLogEntry."Task Processing Type"::None;
        TaskLogEntry.Status := TaskLogEntry.Status::Pending;
        TaskLogEntry.Description := 'UpdateStatus lifecycle';
        TaskLogEntry.Insert(true);

        // Act 1 — Pending → Processing.
        BeforeProcessing := CurrentDateTime();
        TaskProcessor.UpdateStatus(TaskLogEntry, TaskLogEntry.Status::Processing);

        // Assert 1 — Status flipped, "Processing Started At" stamped, "Completed At" still empty.
        Assert.AreEqual(TaskLogEntry.Status::Processing, TaskLogEntry.Status, 'Status should be Processing');
        Assert.IsTrue(TaskLogEntry."Processing Started At" >= BeforeProcessing, '"Processing Started At" should be ~now');
        Assert.AreEqual(0DT, TaskLogEntry."Processing Completed At", '"Processing Completed At" must remain unset after Processing');

        // Act 2 — Processing → Complete.
        BeforeComplete := CurrentDateTime();
        TaskProcessor.UpdateStatus(TaskLogEntry, TaskLogEntry.Status::Complete);

        // Assert 2 — Status flipped, "Processing Completed At" stamped.
        Assert.AreEqual(TaskLogEntry.Status::Complete, TaskLogEntry.Status, 'Status should be Complete');
        Assert.IsTrue(TaskLogEntry."Processing Completed At" >= BeforeComplete, '"Processing Completed At" should be ~now');
    end;

    [Test]
    procedure TestArchiveCopiesEntryAndStampsMetadata()
    var
        TaskLogEntry: Record "Task Log Entry";
        ArchiveEntry: Record "Task Log Archive";
        TaskProcessor: Codeunit "Task Processor";
        Before: DateTime;
    begin
        // Arrange — a fully-populated Complete entry flagged for archival.
        TaskLogEntry.Init();
        TaskLogEntry."Task Processing Type" := TaskLogEntry."Task Processing Type"::None;
        TaskLogEntry.Status := TaskLogEntry.Status::Complete;
        TaskLogEntry.Description := 'Archive end-to-end';
        TaskLogEntry."Retry Count" := 2;
        TaskLogEntry."Last Error Message" := 'previous attempt failed';
        TaskLogEntry."Archive After Processing" := true;
        TaskLogEntry.Insert(true);
        Before := CurrentDateTime();

        // Act
        TaskProcessor.Archive(TaskLogEntry);

        // Assert — archive row exists with copied fields, timestamp, and Processed reason.
        Assert.IsTrue(ArchiveEntry.Get(TaskLogEntry."Entry No."), 'Archive entry should exist with same Entry No.');
        Assert.AreEqual(TaskLogEntry.Description, ArchiveEntry.Description, 'Description copied');
        Assert.AreEqual(TaskLogEntry.Status, ArchiveEntry.Status, 'Status copied');
        Assert.AreEqual(TaskLogEntry."Retry Count", ArchiveEntry."Retry Count", 'Retry Count copied');
        Assert.AreEqual(TaskLogEntry."Last Error Message", ArchiveEntry."Last Error Message", 'Last Error Message copied');
        Assert.IsTrue(ArchiveEntry."Archived At" >= Before, '"Archived At" should be ~now');
        Assert.AreEqual(ArchiveEntry."Archive Reason"::Processed, ArchiveEntry."Archive Reason", 'Archive Reason should be Processed');
    end;

    [Test]
    procedure TestVendorImportInsertsVendorFromPayload()
    var
        TaskLogEntry: Record "Task Log Entry";
        Vendor: Record Vendor;
        TaskProcessor: Codeunit "Task Processor";
        BeforeCount: Integer;
    begin
        // Arrange — VendorImport task with a NAME + CITY payload, plus an unknown key
        // to prove the parser ignores extras instead of failing.
        BeforeCount := Vendor.Count();
        TaskLogEntry.Init();
        TaskLogEntry."Task Processing Type" := TaskLogEntry."Task Processing Type"::VendorImport;
        TaskLogEntry.Status := TaskLogEntry.Status::Pending;
        TaskLogEntry.Description := 'Vendor import end-to-end';
        TaskLogEntry.Insert(true);
        TaskLogEntry.SetPayloadText('NAME=Acme;CITY=Berlin;COUNTRY=DE');
        TaskLogEntry.Modify(true);

        // Act — dispatched through the enum to "Vendor Import Processor".
        TaskProcessor.ProcessTask(TaskLogEntry);

        // Assert — exactly one vendor inserted with parsed fields.
        Assert.AreEqual(BeforeCount + 1, Vendor.Count(), 'Exactly one vendor should be inserted');
        Vendor.SetRange(Name, 'Acme');
        Assert.IsTrue(Vendor.FindFirst(), 'Vendor "Acme" should exist');
        Assert.AreEqual('Berlin', Vendor.City, 'City should be "Berlin"');
    end;

    [Test]
    procedure TestDocumentImportStagesAndPostsVoucher()
    var
        TaskLogEntry: Record "Task Log Entry";
        VoucherLedgerEntry: Record "Voucher Ledger Entry";
        TaskProcessor: Codeunit "Task Processor";
        CustomerNo: Code[20];
        BeforeCount: Integer;
        ExpectedDescription: Text;
    begin
        // Arrange — a real customer (so Customer No. validation passes) and a full payload.
        CustomerNo := EnsureCustomer('CUST-DI');
        BeforeCount := VoucherLedgerEntry.Count();
        TaskLogEntry.Init();
        TaskLogEntry."Task Processing Type" := TaskLogEntry."Task Processing Type"::DocumentImport;
        TaskLogEntry.Status := TaskLogEntry.Status::Pending;
        TaskLogEntry.Description := 'Document import end-to-end';
        TaskLogEntry.Insert(true);
        TaskLogEntry.SetPayloadText(StrSubstNo('VOUCHERNO=V-001;CUSTOMERNO=%1;AMOUNT=100', CustomerNo));
        TaskLogEntry.Modify(true);
        ExpectedDescription := 'Imported via task ' + Format(TaskLogEntry."Entry No.");

        // Act — dispatched through the enum: stages a journal line, then posts via PostBatch.
        TaskProcessor.ProcessTask(TaskLogEntry);

        // Assert — exactly one ledger entry posted, carrying every staged field.
        Assert.AreEqual(BeforeCount + 1, VoucherLedgerEntry.Count(), 'Exactly one ledger entry should be posted');
        VoucherLedgerEntry.SetRange("Voucher No.", 'V-001');
        Assert.IsTrue(VoucherLedgerEntry.FindFirst(), 'Ledger entry for V-001 should exist');
        Assert.AreEqual(CustomerNo, VoucherLedgerEntry."Customer No.", 'Customer No. should match payload');
        Assert.AreEqual(100, VoucherLedgerEntry.Amount, 'Amount should match payload');
        Assert.AreEqual(WorkDate(), VoucherLedgerEntry."Posting Date", 'Posting Date should be WorkDate()');
        Assert.AreEqual(ExpectedDescription, VoucherLedgerEntry.Description, 'Description should reference task entry no.');
    end;

    local procedure EnsureCustomer(CustomerNo: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        if not Customer.Get(CustomerNo) then begin
            Customer.Init();
            Customer."No." := CustomerNo;
            Customer.Name := 'Unit Test Customer';
            Customer.Insert(true);
        end;
        exit(CustomerNo);
    end;
}
