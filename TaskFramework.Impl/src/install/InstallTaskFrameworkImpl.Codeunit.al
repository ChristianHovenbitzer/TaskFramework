// This install codeunit is intentionally minimal.
// Step 3 already landed the concrete processors + Task Type enum extension here.
codeunit 60000 "Install Task Framework Impl"
{
    Access = Internal;
    Subtype = Install;

    trigger OnInstallAppPerDatabase()
    begin
        // Nothing to install — all demo data is seeded by the framework app's Install codeunit.
        // This app will grow significantly during the workshop.
    end;
}
