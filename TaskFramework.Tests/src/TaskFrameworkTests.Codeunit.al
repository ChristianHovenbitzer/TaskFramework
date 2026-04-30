using Microsoft.Purchases.Vendor;

// ANTI-PATTERN: These tests demonstrate what happens when code is untestable.
// Problems:
// - They depend on real database records (real Vendor table, real Voucher Entry table)
// - They can't mock anything — no interfaces, no dependency injection
// - They're tightly coupled to the monster codeunit
// - Side effects are real: Vendor records are created, vouchers are posted
// - Error tests can only verify the FIRST error, not ALL errors
// - No test isolation: tests may interfere with each other
// After refactoring (interfaces, facade, factory), these same scenarios
// become testable with mocks and proper isolation.
codeunit 70000 "Task Framework Tests"
{
    Subtype = Test;

    var
        Assert: Codeunit "Test Assert";

    // =========================================================================
    // TASK PROCESSING TESTS
    // =========================================================================

    [Test]
    procedure VendorImportTaskCreatesVendorAndCompletesTask()
    var
        TaskLogEntry: Record "Task Log Entry";
        TaskProcessor: Codeunit "Task Processor";
        VendorCount: Integer;
        Vendor: Record Vendor;
    begin
        // Arrange
        // ANTI-PATTERN: We must count real Vendors before and after
        // because we can't inject a mock vendor repository
        VendorCount := Vendor.Count();

        TaskLogEntry.Init();
        TaskLogEntry."Task Processing Type" := TaskLogEntry."Task Processing Type"::VendorImport;
        TaskLogEntry.Status := TaskLogEntry.Status::Pending;
        TaskLogEntry.Description := 'Test vendor import';
        TaskLogEntry.Insert(true);
        WritePayloadToEntry(TaskLogEntry, 'NAME=Test Vendor AutoTest;CITY=Berlin');

        // Act
        // ANTI-PATTERN: Calling the monster codeunit — no way to inject a mock processor
        TaskProcessor.ProcessTaskEntry(TaskLogEntry);

        // Assert
        TaskLogEntry.Get(TaskLogEntry."Entry No.");
        Assert.AreEqual(TaskLogEntry.Status::Complete, TaskLogEntry.Status,
            'Task should be Complete after processing');

        // ANTI-PATTERN: We have to query the real Vendor table to verify side effects
        Assert.AreEqual(VendorCount + 1, Vendor.Count(),
            'Expected exactly one new Vendor to be created');
    end;

    [Test]
    procedure DocumentImportTaskCreatesAndPostsVoucher()
    var
        TaskLogEntry: Record "Task Log Entry";
        TaskProcessor: Codeunit "Task Processor";
        VoucherEntry: Record "Voucher Entry";
    begin
        // Arrange
        TaskLogEntry.Init();
        TaskLogEntry."Task Processing Type" := TaskLogEntry."Task Processing Type"::DocumentImport;
        TaskLogEntry.Status := TaskLogEntry.Status::Pending;
        TaskLogEntry.Description := 'Test document import';
        TaskLogEntry.Insert(true);
        WritePayloadToEntry(TaskLogEntry, 'VOUCHERNO=TEST-DOC-001;CUSTOMERNO=10000;AMOUNT=250.00;POSTINGDATE=2026-01-01');

        // Act
        TaskProcessor.ProcessTaskEntry(TaskLogEntry);

        // Assert
        TaskLogEntry.Get(TaskLogEntry."Entry No.");
        Assert.AreEqual(TaskLogEntry.Status::Complete, TaskLogEntry.Status,
            'Task should be Complete after processing');

        // ANTI-PATTERN: Must query real Voucher Entry table to verify
        // and we can't control what PostVoucher does internally
        VoucherEntry.SetRange("Voucher No.", 'TEST-DOC-001');
        Assert.IsTrue(VoucherEntry.FindFirst(),
            'Expected Voucher Entry to be created');
        Assert.AreEqual('Posted', VoucherEntry.Status,
            'Voucher should be posted immediately (no staging)');
    end;

    [Test]
    procedure LogRetentionTaskDeletesOldArchiveEntries()
    var
        TaskLogEntry: Record "Task Log Entry";
        TaskProcessor: Codeunit "Task Processor";
        Archive: Record "Task Log Archive";
    begin
        // Arrange: Create an old archive entry (60 days ago)
        Archive.Init();
        Archive."Entry No." := 99990;
        Archive."Task Type" := "Task Processing Type"::VendorImport;
        Archive.Status := "Task Processing Status"::Complete;
        Archive.Description := 'Old entry for retention test';
        Archive."Archived At" := CreateDateTime(CalcDate('<-60D>', Today()), 0T);
        Archive."Archive Reason" := Archive."Archive Reason"::Processed;
        Archive.Insert();

        TaskLogEntry.Init();
        TaskLogEntry."Task Processing Type" := TaskLogEntry."Task Processing Type"::LogRetention;
        TaskLogEntry.Status := TaskLogEntry.Status::Pending;
        TaskLogEntry.Description := 'Test retention';
        TaskLogEntry.Insert(true);

        // Act
        TaskProcessor.ProcessTaskEntry(TaskLogEntry);

        // Assert
        TaskLogEntry.Get(TaskLogEntry."Entry No.");
        Assert.AreEqual(TaskLogEntry.Status::Complete, TaskLogEntry.Status,
            'Task should be Complete after processing');

        // ANTI-PATTERN: Hardcoded 30 day retention — we can't configure this from the test
        Assert.IsTrue(not Archive.Get(99990),
            'Old archive entry should have been deleted by retention');
    end;

    [Test]
    procedure ProcessTaskEntryArchivesWhenFlagIsSet()
    var
        TaskLogEntry: Record "Task Log Entry";
        TaskProcessor: Codeunit "Task Processor";
        Archive: Record "Task Log Archive";
    begin
        // Arrange
        TaskLogEntry.Init();
        TaskLogEntry."Task Processing Type" := TaskLogEntry."Task Processing Type"::VendorImport;
        TaskLogEntry.Status := TaskLogEntry.Status::Pending;
        TaskLogEntry.Description := 'Test archiving';
        TaskLogEntry."Archive After Processing" := true;
        TaskLogEntry.Insert(true);
        WritePayloadToEntry(TaskLogEntry, 'NAME=Archive Test Vendor;CITY=Munich');

        // Act
        TaskProcessor.ProcessTaskEntry(TaskLogEntry);

        // Assert
        Assert.IsTrue(Archive.Get(TaskLogEntry."Entry No."),
            'Task should be archived after processing');
        Assert.AreEqual(Archive."Archive Reason"::Processed, Archive."Archive Reason",
            'Archive reason should be Processed');
    end;

    [Test]
    procedure ProcessTaskEntryFailsForUnknownTaskType()
    var
        TaskLogEntry: Record "Task Log Entry";
        TaskProcessor: Codeunit "Task Processor";
    begin
        // Arrange
        TaskLogEntry.Init();
        TaskLogEntry."Task Processing Type" := TaskLogEntry."Task Processing Type"::None;
        TaskLogEntry.Status := TaskLogEntry.Status::Pending;
        TaskLogEntry.Description := 'Test unknown type';
        TaskLogEntry.Insert(true);

        // Act + Assert
        // ANTI-PATTERN: The Error() in the CASE else branch is not caught gracefully
        asserterror TaskProcessor.ProcessTaskEntry(TaskLogEntry);
        Assert.IsTrue(
            GetLastErrorText().Contains('Unknown task type'),
            'Expected error about unknown task type');
    end;

    // =========================================================================
    // VOUCHER POSTING TESTS
    // =========================================================================

    [Test]
    procedure PostVoucherSucceedsWithValidData()
    var
        VoucherEntry: Record "Voucher Entry";
        PostVouchers: Codeunit "Post Vouchers";
    begin
        // Arrange
        VoucherEntry.Init();
        VoucherEntry."Voucher No." := 'TEST-POST-001';
        VoucherEntry."Customer No." := '10000';
        VoucherEntry.Amount := 100.00;
        VoucherEntry."Posting Date" := WorkDate();
        VoucherEntry.Insert(true);

        // Act
        PostVouchers.PostVoucher(VoucherEntry);

        // Assert
        // ANTI-PATTERN: "Posting" is just a status flip — no ledger entries, no register
        VoucherEntry.Get(VoucherEntry."Entry No.");
        Assert.AreEqual('Posted', VoucherEntry.Status,
            'Voucher should be Posted after posting');
    end;

    [Test]
    procedure PostVoucherFailsWhenCustomerNoIsMissing()
    var
        VoucherEntry: Record "Voucher Entry";
        PostVouchers: Codeunit "Post Vouchers";
    begin
        // Arrange
        VoucherEntry.Init();
        VoucherEntry."Voucher No." := 'TEST-ERR-001';
        VoucherEntry."Customer No." := '';
        VoucherEntry.Amount := 100.00;
        VoucherEntry."Posting Date" := WorkDate();
        VoucherEntry.Insert(true);

        // Act + Assert
        asserterror PostVouchers.PostVoucher(VoucherEntry);
        Assert.IsTrue(
            GetLastErrorText().Contains('Customer No.'),
            'Expected error about Customer No.');
    end;

    [Test]
    procedure PostVoucherFailsWhenAmountIsZero()
    var
        VoucherEntry: Record "Voucher Entry";
        PostVouchers: Codeunit "Post Vouchers";
    begin
        // Arrange
        VoucherEntry.Init();
        VoucherEntry."Voucher No." := 'TEST-ERR-002';
        VoucherEntry."Customer No." := '10000';
        VoucherEntry.Amount := 0;
        VoucherEntry."Posting Date" := WorkDate();
        VoucherEntry.Insert(true);

        // Act + Assert
        asserterror PostVouchers.PostVoucher(VoucherEntry);
        Assert.IsTrue(
            GetLastErrorText().Contains('Amount'),
            'Expected error about Amount');
    end;

    [Test]
    procedure PostVoucherFailsWhenPostingDateIsMissing()
    var
        VoucherEntry: Record "Voucher Entry";
        PostVouchers: Codeunit "Post Vouchers";
    begin
        // Arrange
        VoucherEntry.Init();
        VoucherEntry."Voucher No." := 'TEST-ERR-003';
        VoucherEntry."Customer No." := '10000';
        VoucherEntry.Amount := 50.00;
        VoucherEntry."Posting Date" := 0D;
        VoucherEntry.Insert(true);

        // Act + Assert
        asserterror PostVouchers.PostVoucher(VoucherEntry);
        Assert.IsTrue(
            GetLastErrorText().Contains('Posting Date'),
            'Expected error about Posting Date');
    end;

    [Test]
    procedure PostVoucherOnlyReportsFirstError()
    var
        VoucherEntry: Record "Voucher Entry";
        PostVouchers: Codeunit "Post Vouchers";
    begin
        // Arrange: BOTH Customer No. missing AND Amount = 0
        VoucherEntry.Init();
        VoucherEntry."Voucher No." := 'TEST-ERR-MULTI';
        VoucherEntry."Customer No." := '';
        VoucherEntry.Amount := 0;
        VoucherEntry."Posting Date" := WorkDate();
        VoucherEntry.Insert(true);

        // Act + Assert
        // ANTI-PATTERN: We can only verify the FIRST error.
        // The second error (Amount) is never reported to the user.
        // After refactoring with collectible errors, BOTH errors surface.
        asserterror PostVouchers.PostVoucher(VoucherEntry);
        Assert.IsTrue(
            GetLastErrorText().Contains('Customer No.'),
            'Expected error about Customer No. (first error only)');
        // We CANNOT assert on the Amount error here — it's invisible!
    end;

    // =========================================================================
    // BATCH PROCESSING TESTS
    // =========================================================================

    [Test]
    procedure ProcessAllPendingSkipsTasksScheduledForFuture()
    var
        TaskLogEntry: Record "Task Log Entry";
        TaskProcessor: Codeunit "Task Processor";
    begin
        TaskLogEntry.DeleteAll(false);

        // Arrange: Create a task scheduled for tomorrow
        TaskLogEntry.Init();
        TaskLogEntry."Task Processing Type" := TaskLogEntry."Task Processing Type"::VendorImport;
        TaskLogEntry.Status := TaskLogEntry.Status::Pending;
        TaskLogEntry.Description := 'Future task - should not process';
        TaskLogEntry."Earliest Processing DateTime" := CreateDateTime(CalcDate('<+1D>', Today()), 0T);
        TaskLogEntry.Insert(true);
        WritePayloadToEntry(TaskLogEntry, 'NAME=Future Vendor;CITY=Hamburg');

        // Act
        TaskProcessor.ProcessAllPendingTasks();

        // Assert: Task should still be Pending
        TaskLogEntry.Get(TaskLogEntry."Entry No.");
        Assert.AreEqual(TaskLogEntry.Status::Pending, TaskLogEntry.Status,
            'Future-scheduled task should remain Pending');
    end;

    // =========================================================================
    // HELPERS
    // =========================================================================

    local procedure WritePayloadToEntry(var TaskLogEntry: Record "Task Log Entry"; PayloadText: Text)
    var
        OutStr: OutStream;
    begin
        TaskLogEntry.Payload.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(PayloadText);
        TaskLogEntry.Modify(false);
    end;
}
