namespace Techdays.TaskFramework.Impl;

using Techdays.TaskFramework.Impl.Vouchers;

permissionset 60000 "Task Framework Impl"
{
    Caption = 'Task Framework Impl';
    Assignable = true;

    Permissions =
        tabledata "Voucher Journal Line" = RIMD,
        tabledata "Voucher Ledger Entry" = RIMD,
        tabledata "Voucher Register" = RIMD;
}
