namespace Techdays.TaskFramework.Impl.Processors;

using Techdays.TaskFramework.Core;
using Techdays.TaskFramework.Processing;

// HANDS-ON: This enum extension adds business-specific task types from the Implementation app.
// TODO:
//   1. Add VendorImport (60000) with Implementation = "ITask Processor" = "Vendor Import Processor"
//   2. Add DocumentImport (60001) with Implementation = "ITask Processor" = "Document Import Processor"
enumextension 60000 "Task Type Ext." extends "Task Type"
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
