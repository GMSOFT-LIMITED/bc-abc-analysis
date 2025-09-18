table 50102 "ABC Value Buffer"
{
    Caption = 'ABC Value Buffer';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Item No."; Code[20]) { Caption = 'Item No.'; }
        field(2; "Value"; Decimal)     { Caption = 'Value'; DecimalPlaces = 0:5; }
    }

    keys
    {
        key(PK; "Item No.") { Clustered = true; }
        key(ByValue; "Value") { }
    }
}