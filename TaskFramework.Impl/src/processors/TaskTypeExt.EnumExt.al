// TODO: (Step 3 - DI / Strategy via Interfaces): new enum extension. Adds the
// business-specific task types VendorImport and DocumentImport that previously
// sat in the framework enum, each bound to its impl codeunit.
enumextension 60000 "Task Type Ext." extends "Task Processing Type"
{
    value(60000; VendorImport)
    {
        Caption = 'Vendor Import';
        Implementation = "ITask Processor" = "Vendor Import Processor";
    }
    value(60001; DocumentImport)
    {
        Caption = 'Document Import';
        Implementation = "ITask Processor" = "Document Import Processor";
    }
}
