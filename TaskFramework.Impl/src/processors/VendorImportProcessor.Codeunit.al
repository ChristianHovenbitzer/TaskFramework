namespace Techdays.TaskFramework.Impl.Processors;

using Techdays.TaskFramework.Core;
using Techdays.TaskFramework.Processing;
using Microsoft.Purchases.Vendor;

// HANDS-ON: This codeunit handles the VendorImport task type.
// The logic currently lives in TaskProcessor.ProcessVendorImport() — move it here.
// TODO:
//   1. Add "implements "ITask Processor"" to the codeunit declaration
//   2. Move the vendor import logic from TaskProcessor into ProcessTask
//      (parse payload, create Vendor record)
codeunit 60001 "Vendor Import Processor" implements "ITask Processor"
{
    Access = Internal;

    procedure ProcessTask(var TaskLogEntry: Record "Task Log Entry")
    begin
        // TODO: Move ProcessVendorImport logic from TaskProcessor here.
    end;
}
