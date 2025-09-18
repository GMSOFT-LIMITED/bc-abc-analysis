report 50132 "ABC Analysis by Quantity"
{
    Caption = 'ABC Analysis by Quantity';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    DefaultLayout = Word;
    WordLayout = 'layouts/ABCAnalysisByQuantity.docx';

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = SORTING("ABC Calc. Value") ORDER(Descending);

            column(Item_No_; "No.") { }
            column(Description; Description) { }
            column(ABC_Class; "ABC Classification") { }
            // Note: here "ABC Calc. Value" stores the total quantity contribution (units)
            column(Quantity_Total; "ABC Calc. Value") { Caption = 'Total Quantity'; }
            column(ABC_LastUpdate; "ABC Last Update Date") { }

            column(PercentOfTotal; PercentOfTotal) { }
            column(CumulativePercent; CumulativePercent) { }

            trigger OnPreDataItem()
            var
                Itm2: Record Item;
            begin
                Total := 0;
                Running := 0;

                Itm2.CopyFilters(Item);
                if Itm2.FindSet(false, false) then
                    repeat
                        Total += Itm2."ABC Calc. Value";
                    until Itm2.Next() = 0;

                if Total = 0 then
                    Total := 1;
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
                    field(PeriodMonths; PeriodMonths)
                    {
                        Caption = 'Analysis Period (Months)';
                        ApplicationArea = All;
                    }
                    field(UseSetupThresholds; UseSetupThresholds)
                    {
                        Caption = 'Use Setup Thresholds';
                        ApplicationArea = All;
                  //      InitValue = true;
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
        PeriodMonths: Integer;
        UseSetupThresholds: Boolean;
        AThresholdPct: Decimal;
        BThresholdPct: Decimal;
        Total: Decimal;
        Running: Decimal;
        PercentOfTotal: Decimal;
        CumulativePercent: Decimal;

    trigger OnInitReport()
    begin
        Setup.GetOrCreate(Setup);

        PeriodMonths := Setup."Period (Months)";
        if PeriodMonths <= 0 then
            PeriodMonths := 12;

        UseSetupThresholds := true;
        AThresholdPct := Setup."A Threshold %";
        BThresholdPct := Setup."B Threshold %";
    end;

    trigger OnPreReport()
    var
        ATh: Decimal;
        BTh: Decimal;
        MethodEnum: Enum "ABC Method";
    begin
        MethodEnum := MethodEnum::Quantity;

        if UseSetupThresholds then begin
            ATh := Setup."A Threshold %";
            BTh := Setup."B Threshold %";
        end else begin
            ATh := AThresholdPct;
            BTh := BThresholdPct;
        end;

        Mgmt.PerformABCClassification(MethodEnum, PeriodMonths, ATh, BTh);
    end;
}
