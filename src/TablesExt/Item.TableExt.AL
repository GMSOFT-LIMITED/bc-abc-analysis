tableextension 50100 "Item Ext. ABC" extends Item
{
    fields
    {
        field(50100; "ABC Classification"; Enum "ABC Class")
        {
            Caption = 'ABC Classification';
            DataClassification = CustomerContent;
            ToolTip = 'A/B/C class based on Pareto analysis of usage value.';
        }
        field(50101; "ABC Last Update Date"; Date)
        {
            Caption = 'ABC Last Update Date';
            DataClassification = SystemMetadata;
            ToolTip = 'Date when ABC classification was last recalculated.';
        }
        field(50102; "ABC Calc. Value"; Decimal)
        {
            Caption = 'ABC Value (Period)';
            DataClassification = CustomerContent;
            DecimalPlaces = 0:5;
            ToolTip = 'Total value used for latest ABC classification (LCY or units).';
        }
    }
}