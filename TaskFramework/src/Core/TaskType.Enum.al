namespace Techdays.TaskFramework.Core;

enum 50000 "Task Type"
{
    // ANTI-PATTERN: Extensible = false — no other app can add task types.
    // Business-specific values belong in the impl app via enum extension.
    //
    // TODO (Step 3 - DI / Strategy via Interfaces):
    //   1. Set Extensible = true.
    //   2. Add `implements "ITask Processor"` to the enum header.
    //   3. On each value, bind its implementation codeunit via
    //      Implementation = "ITask Processor" = "Vendor Import Processor"; etc.
    //   4. Move the business-specific values (VendorImport, LogRetention,
    //      DocumentImport) into an enum extension in TaskFramework.Impl so the
    //      framework itself knows NOTHING about them.
    Extensible = false;

    value(0; None) { Caption = 'None'; }
    value(1; VendorImport) { Caption = 'Vendor Import'; }
    value(2; LogRetention) { Caption = 'Log Retention'; }
    value(3; DocumentImport) { Caption = 'Document Import'; }
}
