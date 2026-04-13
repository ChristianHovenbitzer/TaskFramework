namespace Techdays.TaskFramework.Impl.Processors;

using Techdays.TaskFramework.Core;
using Techdays.TaskFramework.Processing;
using Techdays.TaskFramework.Vouchers;

// HANDS-ON: This codeunit handles the DocumentImport task type.
// The logic currently lives in TaskProcessor.ProcessDocumentImport() — move it here.
// TODO:
//   1. Add "implements "ITask Processor"" to the codeunit declaration
//   2. Move the document import logic from TaskProcessor into ProcessTask
//      (parse payload, create VoucherEntry, call PostVouchers)
codeunit 60003 "Document Import Processor" implements "ITask Processor"
{
    Access = Internal;

    procedure ProcessTask(var TaskLogEntry: Record "Task Log Entry")
    begin
        // TODO: Move ProcessDocumentImport logic from TaskProcessor here.
    end;
}
