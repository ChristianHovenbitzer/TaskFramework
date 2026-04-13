namespace Techdays.TaskFramework.Core.Archive;

enum 50004 "Task Archive Reason"
{
    Extensible = false;

    value(0; Processed) { Caption = 'Processed'; }
    value(1; Retention) { Caption = 'Retention'; }
    value(2; Manual) { Caption = 'Manual'; }
}
