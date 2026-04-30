// This install codeunit is intentionally minimal.
// Steps 3 and 4 already landed the concrete processors, Task Type enum extension,
// and Task Processor Factory here.
//
// TODO: (Step 5 - Journal → Posting → Ledger Entry)
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
