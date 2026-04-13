namespace Techdays.TaskFramework.Core;

// HANDS-ON: This enum needs to implement "ITask Processor" via enum-interface binding.
// TODO:
//   1. Add "using Techdays.TaskFramework.Processing;" at the top
//   2. Add "implements "ITask Processor"" after the enum name
//   3. Change Extensible to true (so impl app can add task types via enum extension)
//   4. Add DefaultImplementation = "ITask Processor" = "Default Task Processor"
//   5. For each value, add Implementation = "ITask Processor" = <CorrespondingProcessor>
//   6. Move VendorImport and DocumentImport values to the enum extension in the impl app
//      (only None and LogRetention stay in the framework app)
enum 50000 "Task Type"
{
    Extensible = false;

    value(0; None) { Caption = 'None'; }
    value(1; VendorImport) { Caption = 'Vendor Import'; }
    value(2; LogRetention) { Caption = 'Log Retention'; }
    value(3; DocumentImport) { Caption = 'Document Import'; }
}
