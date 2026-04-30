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
