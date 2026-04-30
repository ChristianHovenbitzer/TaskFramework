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
