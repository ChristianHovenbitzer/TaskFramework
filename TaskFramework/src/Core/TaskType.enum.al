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
