report 50131 "ABC Analysis by Value"
{
    Caption = 'ABC Analysis by Value';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    DefaultLayout = Word;
    WordLayout = 'layouts/ABCAnalysisByValue.docx';

    dataset
    {
        dataitem(Item; Item)
        {
            // Pareto order
            DataItemTableView = SORTING("ABC Calc. Value") ORDER(Descending);

            // columns for Word layout binding
            column(Item_No_; "No.") { }
            column(Description; Description) { }
            column(ABC_Class; "ABC Classification") { }
            column(ABC_Value; "ABC Calc. Value") { }
            column(ABC_LastUpdate; "ABC Last Update Date") { }
            column(PercentOfTotal; PercentOfTotal) { }
            column(CumulativePercent; CumulativePercent) { }

            trigger OnPreDataItem()
            var
                Itm2: Record Item;
            begin
                // compute Total over the same filtered set
                Total := 0;
                Running := 0;

                Itm2.CopyFilters(Item);
                if Itm2.FindSet(false, false) then
                    repeat
                        Total += Itm2."ABC Calc. Value";
                    until Itm2.Next() = 0;

                if Total = 0 then
                    Total := 1; // avoid div/0, will show 0% everywhere
            end;

            trigger OnAfterGetRecord()
            begin
                PercentOfTotal := Round(("ABC Calc. Value" / Total) * 100, 0.01, '=');
                Running += "ABC Calc. Value";
                CumulativePercent := Round((Running / Total) * 100, 0.01, '=');
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(content)
            {
                group(Options)
                {
                    field(ValueMethod; ValueMethod)
                    {
                        Caption = 'Value Method';
                        ApplicationArea = All;
                        ToolTip = 'Choose whether to classify by Cost value or Sales value.';
                    }
                    field(PeriodMonths; PeriodMonths)
                    {
                        Caption = 'Analysis Period (Months)';
                        ApplicationArea = All;
                    }
                    field(UseSetupThresholds; UseSetupThresholds)
                    {
                        Caption = 'Use Setup Thresholds';
                        ApplicationArea = All;
                      //  InitValue = true;
                    }
                    field(AThresholdPct; AThresholdPct)
                    {
                        Caption = 'A Threshold %';
                        ApplicationArea = All;
                        Editable = not UseSetupThresholds;
                    }
                    field(BThresholdPct; BThresholdPct)
                    {
                        Caption = 'B Threshold % (cum.)';
                        ApplicationArea = All;
                        Editable = not UseSetupThresholds;
                    }
                }
            }
        }
    }

    var
        Mgmt: Codeunit "ABC Analysis Management";
        Setup: Record "ABC Analysis Setup";
        // request vars
        ValueMethod: Option "Value by Cost","Value by Sales";
        PeriodMonths: Integer;
        UseSetupThresholds: Boolean;
        AThresholdPct: Decimal;
        BThresholdPct: Decimal;
        // runtime vars for dataset math
        Total: Decimal;
        Running: Decimal;
        PercentOfTotal: Decimal;
        CumulativePercent: Decimal;

    trigger OnInitReport()
    begin
        Setup.GetOrCreate(Setup);
        // default from Setup
        case Setup."Default Method" of
            Setup."Default Method"::"ValueBySales":
                ValueMethod := ValueMethod::"Value by Sales";
            else
                ValueMethod := ValueMethod::"Value by Cost";
        end;

        PeriodMonths := Setup."Period (Months)";
        if PeriodMonths <= 0 then
            PeriodMonths := 12;

        UseSetupThresholds := true;
        AThresholdPct := Setup."A Threshold %";
        BThresholdPct := Setup."B Threshold %";
    end;

    trigger OnPreReport()
    var
        MethodEnum: Enum "ABC Method";
        ATh: Decimal;
        BTh: Decimal;
    begin
        // choose method enum
        case ValueMethod of
            ValueMethod::"Value by Sales":
                MethodEnum := MethodEnum::"ValueBySales";
            else
                MethodEnum := MethodEnum::"ValueByCost";
        end;

        if UseSetupThresholds then begin
            ATh := Setup."A Threshold %";
            BTh := Setup."B Threshold %";
        end else begin
            ATh := AThresholdPct;
            BTh := BThresholdPct;
        end;

        // Recalculate before printing
        Mgmt.PerformABCClassification(MethodEnum, PeriodMonths, ATh, BTh);
    end;
}
