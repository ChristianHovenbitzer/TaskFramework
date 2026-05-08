// TODO: (Step 3 - DI / Strategy via Interfaces): enum is now extensible, implements
// the interface, and binds each value to its impl. VendorImport and DocumentImport
// moved to the Impl app's enum extension (see TaskTypeExt.EnumExt.al).
enum 50000 "Task Processing Type" implements "ITask Processor"
{
    Extensible = true;
    DefaultImplementation = "ITask Processor" = "Default Task Processor";

    value(0; None)
    {
        Caption = 'None';
        Implementation = "ITask Processor" = "Default Task Processor";
    }
    value(1; LogRetention)
    {
        Caption = 'Log Retention';
        Implementation = "ITask Processor" = "Log Retention Processor";
    }
}
