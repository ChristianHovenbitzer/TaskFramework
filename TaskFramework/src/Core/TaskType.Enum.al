enum 50000 "Task Processing Type"
{
    // ANTI-PATTERN: Extensible = false — no other app can add task types.
    // Business-specific values belong in the impl app via enum extension.
    Extensible = false;

    value(0; None) { Caption = 'None'; }
    value(1; VendorImport) { Caption = 'Vendor Import'; }
    value(2; LogRetention) { Caption = 'Log Retention'; }
    value(3; DocumentImport) { Caption = 'Document Import'; }
}
