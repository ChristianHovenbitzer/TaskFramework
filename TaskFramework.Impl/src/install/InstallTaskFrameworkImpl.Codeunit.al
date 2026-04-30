// This install codeunit is intentionally minimal.
// ANTI-PATTERN: The impl app exists structurally but is nearly empty.
// All task type logic that belongs here is incorrectly placed in the framework app.
//
// TODO (Step 3 - DI / Strategy via Interfaces): this app will receive the
// concrete processors (Vendor Import, Log Retention, Document Import) and the
// "Task Type" enum extension.
// TODO (Step 5 - Journal → Posting → Ledger Entry): this app will also receive
// the voucher posting pipeline (Check Line, Post Line, Post Batch) and the
// Voucher Journal Line / Ledger Entry / Register tables.
// By the end of the workshop, the framework app will know nothing about
// vendors, documents, or accounting — all of that lives here.
codeunit 60000 "Install Task Framework Impl"
{
    Subtype = Install;

    trigger OnInstallAppPerDatabase()
    begin
        // Nothing to install — all demo data is seeded by the framework app's Install codeunit.
        // This app will grow significantly during the workshop.
    end;
}
