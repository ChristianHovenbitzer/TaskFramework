// Minimal local Assert helper — replaces Library Assert dependency for the prototype.
// Using Library Assert would require a BC server with test libraries installed.
// Kept as lightweight helper — no Library Assert dependency required.
codeunit 70001 "Test Assert"
{
    procedure AreEqual(Expected: Variant; Actual: Variant; Message: Text)
    begin
        if Format(Expected) <> Format(Actual) then
            Error('%1\Expected: %2\Actual: %3', Message, Expected, Actual);
    end;

    procedure IsTrue(Condition: Boolean; Message: Text)
    begin
        if not Condition then
            Error('%1', Message);
    end;
}
