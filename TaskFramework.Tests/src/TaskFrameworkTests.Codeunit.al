namespace Techdays.TaskFramework.Tests;

using Techdays.TaskFramework.Core;
using Techdays.TaskFramework.Vouchers;
using Techdays.TaskFramework.Processing;

// ANTI-PATTERN: These tests demonstrate what happens when code is untestable.
// Problems with these tests:
// - They depend on real database records (Cronus vendors, customers)
// - They can't mock anything — interfaces exist (Step 3) but no DI overload yet
// - They're tightly coupled to the monster codeunit
// - Test 1 creates real Vendor records (side effects!)
// - Test 2 can only verify the first error, not ALL errors
//
// TODO (Step 8 - Mock via Interface): replace everything below with mock-based
// tests. Requires Step 4 to add the internal ProcessTaskEntry(entry; Processor)
// DI overload first:
//   1. Create a "Mock Task Processor" codeunit in this test app that
//      implements "ITask Processor". Record whether it was called and with what
//      entry; add a ShouldFail flag for error-path tests.
//   2. Write a happy-path test: create a pending entry, inject the mock via
//      the internal ProcessTaskEntry(entry; Processor) overload, verify the
//      mock was called exactly once.
//   3. Write an error-path test: ShouldFail = true, verify the entry status
//      ends in Failed.
//   4. Write a lifecycle test: verify Pending → Processing → Complete.
//   5. Bonus: test Check Line with a mock that records which lines were
//      validated and asserts all errors were collected (Step 6 payoff).
codeunit 70000 "Task Framework Tests"
{
    Subtype = Test;

    var
        Assert: Codeunit "Test Assert";

    [Test]
    procedure TestProcessVendorImportTask()
    var
        TaskLogEntry: Record "Task Log Entry";
        TaskProcessor: Codeunit "Task Processor";
    begin
        // Arrange
        // ANTI-PATTERN: Creating real database state in a test, no cleanup/isolation
        TaskLogEntry.Init();
        TaskLogEntry."Task Type" := TaskLogEntry."Task Type"::VendorImport;
        TaskLogEntry.Status := TaskLogEntry.Status::Pending;
        TaskLogEntry.Description := 'Test vendor import';
        TaskLogEntry.Insert(true);

        // Write payload to BLOB
        WritePayloadToEntry(TaskLogEntry, 'NAME=Test Vendor AutoTest;CITY=Berlin');

        // Act
        // ANTI-PATTERN: Calling the monster codeunit directly — no way to inject a mock
        TaskProcessor.ProcessTaskEntry(TaskLogEntry);

        // Assert
        // Re-read the record to get updated status
        TaskLogEntry.Get(TaskLogEntry."Entry No.");
        Assert.AreEqual(TaskLogEntry.Status::Complete, TaskLogEntry.Status, 'Task should be Complete after processing');
        // PROBLEM: We can't assert anything about the Vendor that was created
        // without querying the database directly — side effects are invisible here
    end;

    [Test]
    procedure TestPostVoucherStopsOnFirstError()
    var
        VoucherEntry: Record "Voucher Entry";
        PostVouchers: Codeunit "Post Vouchers";
    begin
        // Arrange: Create a voucher entry with missing Customer No.
        VoucherEntry.Init();
        VoucherEntry."Voucher No." := 'TEST-001';
        VoucherEntry."Customer No." := '';  // Missing!
        VoucherEntry.Amount := 100.00;
        VoucherEntry."Posting Date" := WorkDate();
        VoucherEntry.Insert(true);

        // Act + Assert
        // ANTI-PATTERN: asserterror only tests the FIRST error.
        // We can't verify that Amount = 0 also produces an error in the same call
        // because ERROR() stops on the first failure.
        // Step 6 will fix this: all errors will be collected before reporting.
        asserterror PostVouchers.PostVoucher(VoucherEntry);
        Assert.IsTrue(
            GetLastErrorText().Contains('Customer No.'),
            'Expected error about Customer No. to be raised');
    end;

    local procedure WritePayloadToEntry(var TaskLogEntry: Record "Task Log Entry"; PayloadText: Text)
    var
        OutStr: OutStream;
    begin
        TaskLogEntry.Payload.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(PayloadText);
        TaskLogEntry.Modify(false);
    end;
}
