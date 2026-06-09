// TODO: (Step 4 - Factory Pattern): new factory codeunit. Stateful Set/Get pair
// per role, gated by HasCustom* booleans (interfaces hold null with no runtime
// "is set?" check, so the boolean tracks "explicitly set" for us). Default backend
// is Task Processor itself, which implements all three role interfaces.
codeunit 50008 "Task Processor Factory" implements "ITask Processor Factory"
{
    var
        Default: Codeunit "Task Processor";

    #region Processor
    var
        CustomProcessor: Interface "ITask Processor";
        HasCustomProcessor: Boolean;

    procedure SetProcessor(Processor: Interface "ITask Processor")
    begin
        CustomProcessor := Processor;
        HasCustomProcessor := true;
    end;

    procedure GetProcessor(): Interface "ITask Processor"
    begin
        if HasCustomProcessor then
            exit(CustomProcessor);
        exit(Default);
    end;
    #endregion Processor

    #region Updater
    var
        CustomUpdater: Interface "ITask Log Updater";
        HasCustomUpdater: Boolean;

    procedure SetUpdater(Updater: Interface "ITask Log Updater")
    begin
        CustomUpdater := Updater;
        HasCustomUpdater := true;
    end;

    procedure GetUpdater(): Interface "ITask Log Updater"
    begin
        if HasCustomUpdater then
            exit(CustomUpdater);
        exit(Default);
    end;
    #endregion

    #region Archiver
    var
        CustomArchiver: Interface "ITask Archiver";
        HasCustomArchiver: Boolean;

    procedure SetArchiver(Archiver: Interface "ITask Archiver")
    begin
        CustomArchiver := Archiver;
        HasCustomArchiver := true;
    end;

    procedure GetArchiver(): Interface "ITask Archiver"
    begin
        if HasCustomArchiver then
            exit(CustomArchiver);
        exit(Default);
    end;
    #endregion
}
