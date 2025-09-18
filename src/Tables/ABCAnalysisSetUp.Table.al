table 50101 "ABC Analysis Setup"
{
    Caption = 'ABC Analysis Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(10; "Default Method"; Enum "ABC Method")
        {
            Caption = 'Default Method';
            DataClassification = CustomerContent;
        }
        field(11; "Period (Months)"; Integer)
        {
            Caption = 'Analysis Period (Months)';
            DataClassification = CustomerContent;
            InitValue = 12;
        }
        field(12; "A Threshold %"; Decimal)
        {
            Caption = 'A Threshold %';
            DataClassification = CustomerContent;
            InitValue = 80.0;
        }
        field(13; "B Threshold %"; Decimal)
        {
            Caption = 'B Threshold % (cum.)';
            DataClassification = CustomerContent;
            InitValue = 95.0;
        }
        field(20; "Enable Auto Job"; Boolean)
        {
            Caption = 'Enable Auto Job';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }

    trigger OnInsert()
    begin
        if "Primary Key" = '' then
            "Primary Key" := 'SETUP';
    end;

    procedure GetOrCreate(var Setup: Record "ABC Analysis Setup")
    begin
        if not Setup.Get('SETUP') then begin
            Setup.Init();
            Setup."Primary Key" := 'SETUP';
            Setup.Insert(true);
        end;
    end;
}