page 50102 "ABC Analysis Setup"
{
    PageType = Card;
    SourceTable = "ABC Analysis Setup";
    Caption = 'ABC Analysis Setup';
    UsageCategory = Administration;
    ApplicationArea = All;

    layout
    {
        area(content)
        {
            group(General)
            {
                field("Default Method"; Rec."Default Method") { ApplicationArea = All; }
                field("Period (Months)"; Rec."Period (Months)") { ApplicationArea = All; }
                field("A Threshold %"; Rec."A Threshold %") { ApplicationArea = All; }
                field("B Threshold %"; Rec."B Threshold %") { ApplicationArea = All; }
                field("Enable Auto Job"; Rec."Enable Auto Job") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.GetOrCreate(Rec);
    end;
}
