// This install codeunit is intentionally minimal.
// Steps 3-5 landed processors, factory, and voucher posting pipeline here.
codeunit 60000 "Install Task Framework Impl"
{
    Subtype = Install;

    trigger OnInstallAppPerDatabase()
    begin
        // Nothing to install — all demo data is seeded by the framework app's Install codeunit.
        // This app will grow significantly during the workshop.
    end;
}
