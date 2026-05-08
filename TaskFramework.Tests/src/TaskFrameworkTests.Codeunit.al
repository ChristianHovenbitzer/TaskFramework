using System.Utilities;

// TODO: (Step 8 - Mock via Factory): bodies of the existing tests rewritten with
// the spy: Factory.SetProcessor/SetUpdater/SetArchiver(MockRunner), call the
// Factory-taking ProcessTaskEntry overload, assert call sequence via Recorder.
// Old anti-pattern tests are gone — their value lives in the slides as contrast.
codeunit 70000 "Task Framework Tests"
{
    Subtype = Test;

    var
        Assert: Codeunit "Test Assert";

    /// <summary>
    /// Step 0 version: needed real DB state and could not assert the Vendor side effect
    /// because the processor was hard-wired into the monster codeunit.
    /// Step 8 version: TaskType-driven processing is verified through the factory seam —
    /// a mock processor records that the vendor-import task was forwarded to it,
    /// and a mock updater confirms the entry reached Complete. No DB interaction.
    /// </summary>
    [Test]
    procedure TestProcessVendorImportTask()
    var
        TaskLogEntry: Record "Task Log Entry";
        TaskProcessor: Codeunit "Task Processor";
        Factory: Codeunit "Task Processor Factory";
        MockRunner: Codeunit "Mock Task Runner";
        Recorder: Codeunit "Call Recorder";
    begin
        // Arrange
        Recorder.Reset();

        TaskLogEntry.Init();
        TaskLogEntry."Entry No." := 1;
        TaskLogEntry."Task Processing Type" := TaskLogEntry."Task Processing Type"::VendorImport;
        TaskLogEntry.Status := TaskLogEntry.Status::Pending;
        TaskLogEntry.Description := 'Test vendor import';

        Factory.SetProcessor(MockRunner);
        Factory.SetUpdater(MockRunner);
        Factory.SetArchiver(MockRunner);

        // Act
        TaskProcessor.ProcessTaskEntry(TaskLogEntry, Factory);

        // Assert — the vendor-import entry reached the processor and was marked Complete.
        Assert.AreEqual('Processor.ProcessTask:1', Recorder.GetCall(2), 'Processor should run for entry 1');
        Assert.AreEqual('Updater.UpdateStatus:Complete', Recorder.GetCall(3), 'Entry should reach Complete');
    end;

    /// <summary>
    /// Step 0 version: only asserted that timestamps were set — call order between
    /// updater, processor, and archiver was unobservable inside the monster codeunit.
    /// Step 8 version: the spy proves the exact sequence
    /// Updater(Processing) → Processor → Updater(Complete) → Archiver.
    /// </summary>
    [Test]
    procedure TestProcessTaskRecordsTimestampsButHidesCallOrder()
    var
        TaskLogEntry: Record "Task Log Entry";
        TaskProcessor: Codeunit "Task Processor";
        Factory: Codeunit "Task Processor Factory";
        MockRunner: Codeunit "Mock Task Runner";
        Recorder: Codeunit "Call Recorder";
    begin
        // Arrange
        Recorder.Reset();

        TaskLogEntry.Init();
        TaskLogEntry."Entry No." := 1;
        TaskLogEntry."Task Processing Type" := TaskLogEntry."Task Processing Type"::VendorImport;
        TaskLogEntry.Status := TaskLogEntry.Status::Pending;
        TaskLogEntry.Description := 'Test ordering';
        TaskLogEntry."Archive After Processing" := true;

        Factory.SetProcessor(MockRunner);
        Factory.SetUpdater(MockRunner);
        Factory.SetArchiver(MockRunner);

        // Act
        TaskProcessor.ProcessTaskEntry(TaskLogEntry, Factory);

        // Assert — full collaborator sequence is now exposed.
        Assert.AreEqual(4, Recorder.GetCallCount(), 'Expected exactly 4 collaborator calls');
        Assert.AreEqual('Updater.UpdateStatus:Processing', Recorder.GetCall(1), 'Step 1: Processing');
        Assert.AreEqual('Processor.ProcessTask:1', Recorder.GetCall(2), 'Step 2: Processor');
        Assert.AreEqual('Updater.UpdateStatus:Complete', Recorder.GetCall(3), 'Step 3: Complete');
        Assert.AreEqual('Archiver.Archive:1', Recorder.GetCall(4), 'Step 4: Archive');
    end;

    /// <summary>
    /// Step 0 version: asserterror only ever caught the FIRST error — so the test
    /// name described the bug, not the desired behaviour.
    /// Step 6 fixed posting with ErrorBehavior::Collect + Error Message Management.
    /// Step 8 version: this test now proves the inverse — posting does NOT stop on
    /// the first error; all required-field violations surface in one pass.
    /// </summary>
    [Test]
    procedure TestPostVoucherStopsOnFirstError()
    var
        VoucherJnlLine: Record "Voucher Journal Line";
        TempErrorMessage: Record "Error Message" temporary;
        CheckLine: Codeunit "Voucher Jnl.-Check Line";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
    begin
        // Arrange — three independent hard violations on a single in-memory line.
        VoucherJnlLine.Init();
        VoucherJnlLine."Line No." := 10000;
        VoucherJnlLine."Voucher No." := 'TEST-001';
        VoucherJnlLine."Customer No." := '';
        VoucherJnlLine.Amount := 0;
        VoucherJnlLine."Posting Date" := 0D;
        VoucherJnlLine.Description := '';

        ErrorMessageMgt.Activate(ErrorMessageHandler);

        // Act
        CheckLine.RunCheck(VoucherJnlLine);

        // Assert — all three errors collected; the check no longer stops at the first.
        Assert.IsTrue(ErrorMessageHandler.HasErrors(), 'Expected collected errors');
        ErrorMessageHandler.AppendTo(TempErrorMessage);
        TempErrorMessage.SetRange("Message Type", TempErrorMessage."Message Type"::Error);
        Assert.AreEqual(3, TempErrorMessage.Count(), 'Expected 3 errors (Customer No., Amount, Posting Date)');
    end;
}
