pageextension 50110 "Item Card Ext. ABC" extends "Item Card"
{
    layout
    {
        addafter("Planning")
        {
            group("ABC Item Classification")
            {
                Caption = 'ABC Classification';
                field("ABC Classification"; Rec."ABC Classification") { ApplicationArea = All; }
                field("ABC Last Update Date"; Rec."ABC Last Update Date") { ApplicationArea = All; }
                field("ABC Calc. Value"; Rec."ABC Calc. Value") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        addlast(Reporting)
        {
            // Existing single report action (kept for convenience)
            action(RecalculateABC)
            {
                ApplicationArea = All;
                Caption = 'Recalculate ABC (Report)';
                Image = Recalculate;
                ToolTip = 'Run the original ABC Analysis Report to recalculate and view results.';
                trigger OnAction()
                begin
                    Report.RunModal(Report::"ABC Analysis by Quantity", true, true);
                end;
            }

            // NEW: ABC by Value (Cost/Sales)
            action(RunABCByValue)
            {
                ApplicationArea = All;
                Caption = 'ABC Analysis by Value';
                Image = Report;
                ToolTip = 'Recalculate and print ABC based on value (Cost or Sales).';
                trigger OnAction()
                begin
                    Report.RunModal(Report::"ABC Analysis by Value", true, true);
                end;
            }

            // NEW: ABC by Quantity
            action(RunABCByQty)
            {
                ApplicationArea = All;
                Caption = 'ABC Analysis by Quantity';
                Image = Report;
                ToolTip = 'Recalculate and print ABC based on total quantity usage.';
                trigger OnAction()
                begin
                    Report.RunModal(Report::"ABC Analysis by Quantity", true, true);
                end;
            }
        }
    }
}