codeunit 60003 "Document Import Processor" implements "ITask Processor"
{
    Access = Internal;

    procedure ProcessTask(var TaskLogEntry: Record "Task Log Entry")
    var
        VoucherJnlLine: Record "Voucher Journal Line";
        PostBatch: Codeunit "Voucher Jnl.-Post Batch Impl";
        PayloadText: Text;
        InStr: InStream;
        VoucherNo: Code[20];
        CustomerNo: Code[20];
        Amount: Decimal;
    begin
        TaskLogEntry.CalcFields(Payload);
        if TaskLogEntry.Payload.HasValue() then begin
            TaskLogEntry.Payload.CreateInStream(InStr, TextEncoding::UTF8);
            InStr.ReadText(PayloadText);
        end;

        VoucherNo := CopyStr(ExtractValue(PayloadText, 'VOUCHERNO'), 1, 20);
        CustomerNo := CopyStr(ExtractValue(PayloadText, 'CUSTOMERNO'), 1, 20);
        Evaluate(Amount, ExtractValue(PayloadText, 'AMOUNT'));

        if VoucherNo = '' then
            VoucherNo := 'VOUCH-TASK-' + Format(TaskLogEntry."Entry No.");

        // Build journal line (staging)
        VoucherJnlLine.Init();
        VoucherJnlLine."Line No." := GetNextLineNo();
        VoucherJnlLine."Voucher No." := VoucherNo;
        VoucherJnlLine."Customer No." := CustomerNo;
        VoucherJnlLine.Amount := Amount;
        VoucherJnlLine."Posting Date" := WorkDate();
        VoucherJnlLine.Description := 'Imported via task ' + Format(TaskLogEntry."Entry No.");
        VoucherJnlLine.Insert(true);

        // Post through pipeline: Check → Post Line → Ledger Entry + Register
        PostBatch.Run(VoucherJnlLine);
    end;

    local procedure GetNextLineNo(): Integer
    var
        VoucherJnlLine: Record "Voucher Journal Line";
    begin
        if VoucherJnlLine.FindLast() then
            exit(VoucherJnlLine."Line No." + 10000);
        exit(10000);
    end;

    local procedure ExtractValue(PayloadText: Text; FieldKey: Text): Text
    var
        Part: List of [Text];
        Segment: Text;
        i: Integer;
    begin
        Part := PayloadText.Split(';');
        for i := 1 to Part.Count do begin
            Segment := Part.Get(i).Trim();
            if Segment.IndexOf(FieldKey + '=') = 1 then
                exit(CopyStr(Segment, StrLen(FieldKey) + 2));
        end;
        exit('');
    end;
}
