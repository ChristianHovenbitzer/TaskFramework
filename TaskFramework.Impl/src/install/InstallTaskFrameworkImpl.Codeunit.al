namespace Techdays.TaskFramework.Impl;

// This install codeunit is intentionally minimal.
// Step 3 already landed the concrete processors + Task Type enum extension here.
//
// TODO: (Step 5 - Journal → Posting → Ledger Entry): this app will also receive
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
