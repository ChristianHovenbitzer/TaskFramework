namespace Techdays.TaskFramework.Core;

using Techdays.TaskFramework.Core.Archive;
using Techdays.TaskFramework.Core.Errors;
using Techdays.TaskFramework.Setup;
using Techdays.TaskFramework.Vouchers;

permissionset 50000 "Task Framework - All"
{
    Caption = 'Task Framework - All';
    Assignable = true;

    Permissions =
        tabledata "Task Log Entry" = RIMD,
        tabledata "Task Log Archive" = RIMD,
        tabledata "Task Error Log" = RIMD,
        tabledata "Task Framework Setup" = RIMD,
        tabledata "Voucher Entry" = RIMD;
}
