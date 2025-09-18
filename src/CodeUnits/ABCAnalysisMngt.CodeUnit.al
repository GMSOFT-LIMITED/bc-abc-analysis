codeunit 50120 "ABC Analysis Management"
{
   // Caption = 'ABC Analysis Management';
    SingleInstance = false;

    // Grant the minimum rights needed at runtime
    Permissions =
        tabledata Item = RM,
        tabledata "Item Ledger Entry" = R,
        tabledata "Value Entry" = R,
        tabledata "ABC Value Buffer" = RIM;

    /// <summary>
    /// Recalculates ABC classification for all items based on Item Ledger Entries in the past PeriodMonths.
    /// Method:
    ///   - ValueByCost   → sums positive consumption cost from ILE."Cost Amount (Actual)"
    ///   - ValueBySales  → sums positive sales amounts from Value Entry linked to each ILE
    ///   - Quantity      → sums Abs(ILE.Quantity) for outbound entries
    /// Thresholds:
    ///   - AThresholdPct (e.g. 80)
    ///   - BThresholdPct (e.g. 95) cumulative
    /// </summary>
    procedure PerformABCClassification(Method: Enum "ABC Method"; PeriodMonths: Integer; AThresholdPct: Decimal; BThresholdPct: Decimal)
    var
        ILE: Record "Item Ledger Entry";
        VE: Record "Value Entry";
        ItemRec: Record Item;
        Buf: Record "ABC Value Buffer" temporary;
        StartDate: Date;
        CurrItemNo: Code[20];
        CurrSum: Decimal;
        Total: Decimal;
        Cum: Decimal;
        Class: Enum "ABC Class";
        AThreshold: Decimal;
        BThreshold: Decimal;
        Val: Decimal;
        Qty: Decimal;
    begin
        // --- Validate inputs ---
        if PeriodMonths <= 0 then
            Error('Analysis period (months) must be greater than 0.');
        if (AThresholdPct <= 0) or (AThresholdPct >= 100) or (BThresholdPct <= AThresholdPct) or (BThresholdPct > 100) then
            Error('Invalid thresholds. Ensure 0 < A Threshold < B Threshold ≤ 100.');

        // --- Determine date range ---
        StartDate := CalcDate(StrSubstNo('<-%1M>', PeriodMonths), WorkDate());

        // --- Build temp buffer of per-item values from ILE/VE ---
        ILE.Reset();
        ILE.SetCurrentKey("Item No.", "Posting Date");
        ILE.SetRange("Posting Date", StartDate, WorkDate());
        // outbound / consumption-like entries
        ILE.SetFilter("Entry Type", '%1|%2|%3',
                      ILE."Entry Type"::Sale,
                      ILE."Entry Type"::Consumption,
                      ILE."Entry Type"::"Negative Adjmt.");

        CurrItemNo := '';
        CurrSum := 0;

        if ILE.FindSet(false, false) then begin
            repeat
                if ILE."Item No." <> CurrItemNo then begin
                    if CurrItemNo <> '' then begin
                        Buf.Init();
                        Buf."Item No." := CurrItemNo;
                        Buf."Value" := CurrSum;
                        Buf.Insert();
                    end;
                    CurrItemNo := ILE."Item No.";
                    CurrSum := 0;
                end;

                case Method of
                    Method::"ValueByCost":
                        begin
                            // ILE."Cost Amount (Actual)" on issues is typically negative → invert; clip negatives to 0
                            Val := -ILE."Cost Amount (Actual)";
                            if Val < 0 then
                                Val := 0;
                            CurrSum += Val;
                        end;

                    Method::"ValueBySales":
                        begin
                            // Sum positive Sales Amount (Actual) from Value Entries linked to this ILE
                            VE.Reset();
                            VE.SetCurrentKey("Item Ledger Entry No.");
                            VE.SetRange("Item Ledger Entry No.", ILE."Entry No.");
                            if VE.FindSet(false, false) then
                                repeat
                                    Val := VE."Sales Amount (Actual)";
                                    if Val > 0 then
                                        CurrSum += Val;
                                until VE.Next() = 0;
                        end;

                    Method::Quantity:
                        begin
                            // Use absolute quantity for outbound entries
                            Qty := Abs(ILE.Quantity);
                            CurrSum += Qty;
                        end;
                end;
            until ILE.Next() = 0;

            // Flush last group
            if CurrItemNo <> '' then begin
                Buf.Init();
                Buf."Item No." := CurrItemNo;
                Buf."Value" := CurrSum;
                Buf.Insert();
            end;
        end;

        // --- Compute total across all items in buffer ---
        Total := 0;
        Buf.Reset();
        if Buf.FindSet() then
            repeat
                Total += Buf."Value";
            until Buf.Next() = 0;

        // --- If no usage/value at all, set everything to C and exit ---
        if Round(Total, 0.00001) = 0 then begin
            ItemRec.Reset();
            if ItemRec.FindSet(true, false) then
                repeat
                    ItemRec.Validate("ABC Classification", ItemRec."ABC Classification"::C);
                    ItemRec."ABC Calc. Value" := 0;
                    ItemRec."ABC Last Update Date" := WorkDate();
                    ItemRec.Modify();
                until ItemRec.Next() = 0;
            exit;
        end;

        // --- Determine cutoffs ---
        AThreshold := (AThresholdPct / 100) * Total;
        BThreshold := (BThresholdPct / 100) * Total;

        // --- Sort by value desc and assign classes by cumulative contribution ---
        Buf.Reset();
        Buf.SetCurrentKey("Value");
        Buf.Ascending(false);

        Cum := 0;
        if Buf.FindSet() then
            repeat
                Cum += Buf."Value";

                if Cum <= AThreshold then
                    Class := Class::A
                else if Cum <= BThreshold then
                    Class := Class::B
                else
                    Class := Class::C;

                if ItemRec.Get(Buf."Item No.") then begin
                    ItemRec.Validate("ABC Classification", Class);
                    ItemRec."ABC Calc. Value" := Buf."Value";
                    ItemRec."ABC Last Update Date" := WorkDate();
                    ItemRec.Modify();
                end;
            until Buf.Next() = 0;

        // --- Any items with no activity in the period → set to C with value 0 ---
        ItemRec.Reset();
        if ItemRec.FindSet(true, false) then
            repeat
                if not Buf.Get(ItemRec."No.") then begin
                    ItemRec.Validate("ABC Classification", ItemRec."ABC Classification"::C);
                    ItemRec."ABC Calc. Value" := 0;
                    ItemRec."ABC Last Update Date" := WorkDate();
                    ItemRec.Modify();
                end;
            until ItemRec.Next() = 0;
    end;

    /// <summary>
    /// Convenience entry-point: uses values from "ABC Analysis Setup" (or sensible defaults).
    /// </summary>
    procedure PerformUsingSetupOrDefaults()
    var
        Setup: Record "ABC Analysis Setup";
        Method: Enum "ABC Method";
        Months: Integer;
        ATh: Decimal;
        BTh: Decimal;
    begin
        Setup.GetOrCreate(Setup);

        Method := Setup."Default Method";
        Months := Setup."Period (Months)";
        if Months <= 0 then
            Months := 12;

        ATh := Setup."A Threshold %";
        BTh := Setup."B Threshold %";
        if (ATh <= 0) or (BTh <= ATh) or (BTh > 100) then begin
            ATh := 80;
            BTh := 95;
        end;

        PerformABCClassification(Method, Months, ATh, BTh);
    end;
}
