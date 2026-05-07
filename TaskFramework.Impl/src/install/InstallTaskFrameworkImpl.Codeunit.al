// This install codeunit is intentionally minimal.
// ANTI-PATTERN: The impl app exists structurally but is nearly empty.
// All task type logic that belongs here is incorrectly placed in the framework app.
codeunit 60000 "Install Task Framework Impl"
{
    Subtype = Install;

    trigger OnInstallAppPerDatabase()
    begin
        // Nothing to install — all demo data is seeded by the framework app's Install codeunit.
        // This app will grow significantly during the workshop.
    end;
}
