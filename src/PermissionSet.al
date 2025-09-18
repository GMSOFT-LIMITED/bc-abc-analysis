permissionset 50140 "ABC Mgr"
{
    Assignable = true;
    Caption = 'ABC Analysis Manager';
    Permissions =
        tabledata Item = RM,
        tabledata "Item Ledger Entry" = R,
        tabledata "Value Entry" = R,
        tabledata "ABC Analysis Setup" = RIMD,
        tabledata "ABC Value Buffer" = RIMD,
        codeunit "ABC Analysis Management" = X,
        codeunit "ABC Analysis Job" = X,
         page "ABC Analysis Setup" = X,
        table "ABC Analysis Setup" = X,
        table "ABC Value Buffer" = X;
}
