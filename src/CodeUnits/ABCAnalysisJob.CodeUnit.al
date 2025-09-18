codeunit 50123 "ABC Analysis Job"
{
   // Caption = 'ABC Analysis Job Runner';

    Subtype = Normal;

    Permissions = tabledata "ABC Analysis Setup" = R,
                  tabledata Item = RM,
                  tabledata "Item Ledger Entry" = R,
                  tabledata "Value Entry" = R,
                  tabledata "ABC Value Buffer" = RIM;

  //  [InherentPermissions]
  //  [InherentEntitlements]
    procedure RunJob()
    var
        Mgmt: Codeunit "ABC Analysis Management";
    begin
        Mgmt.PerformUsingSetupOrDefaults();
    end;
}
