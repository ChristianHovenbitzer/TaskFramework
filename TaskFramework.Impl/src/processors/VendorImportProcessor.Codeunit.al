using Microsoft.Purchases.Vendor;

codeunit 60001 "Vendor Import Processor" implements "ITask Processor"
{
    Access = Internal;

    var
        ImportedVendorNameLbl: Label 'Imported Vendor %1';
        PayloadKeyNameTok: Label 'NAME', Locked = true;
        PayloadKeyCityTok: Label 'CITY', Locked = true;


    procedure ProcessTask(var TaskLogEntry: Record "Task Log Entry")
    var
        Vendor: Record Vendor;
        PayloadText: Text;
        InStr: InStream;
        VendorName: Text[100];
        VendorCity: Text[50];
    begin
        TaskLogEntry.CalcFields(Payload);
        if TaskLogEntry.Payload.HasValue() then begin
            TaskLogEntry.Payload.CreateInStream(InStr, TextEncoding::UTF8);
            InStr.ReadText(PayloadText);
        end;

        VendorName := CopyStr(ExtractValue(PayloadText, PayloadKeyNameTok), 1, 100);
        VendorCity := CopyStr(ExtractValue(PayloadText, PayloadKeyCityTok), 1, 50);

        if VendorName = '' then
            VendorName := StrSubstNo(ImportedVendorNameLbl, TaskLogEntry."Entry No.");

        Vendor.Init();
        Vendor.Name := VendorName;
        Vendor.City := VendorCity;
        Vendor.Insert(true);
    end;

    local procedure ExtractValue(PayloadText: Text; FieldKey: Text): Text
    var
        Part: List of [Text];
        Segment: Text;
        i: Integer;
    begin
        Part := PayloadText.Split(';');
        for i := 1 to Part.Count() do begin
            Segment := Part.Get(i).Trim();
            if Segment.IndexOf(FieldKey + '=') = 1 then
                exit(CopyStr(Segment, StrLen(FieldKey) + 2));
        end;
        exit('');
    end;
}
