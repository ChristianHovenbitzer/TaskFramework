namespace Techdays.TaskFramework.Core;

enum 50001 "Task Status"
{
    Extensible = true;

    value(0; Pending) { Caption = 'Pending'; }
    value(1; Processing) { Caption = 'Processing'; }
    value(2; Complete) { Caption = 'Complete'; }
    value(3; Failed) { Caption = 'Failed'; }
}
