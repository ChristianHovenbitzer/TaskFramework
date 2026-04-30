/// <summary>
/// SingleInstance spy that captures the order of mock collaborator calls during a test.
/// Mocks call <c>Record</c>; tests assert against <c>GetCall</c> / <c>GetCallCount</c>.
/// Always call <c>Reset</c> in test Arrange to isolate runs.
/// </summary>
codeunit 70010 "Call Recorder"
{
    SingleInstance = true;

    var
        Calls: List of [Text];

    procedure Record(CallName: Text)
    begin
        Calls.Add(CallName);
    end;

    procedure GetCallCount(): Integer
    begin
        exit(Calls.Count());
    end;

    procedure GetCall(Index: Integer): Text
    begin
        exit(Calls.Get(Index));
    end;

    procedure Reset()
    begin
        Clear(Calls);
    end;
}
