table 60151 "Extension Configuration"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Key Field"; Code[20])
        {
            DataClassification = CustomerContent;
            Editable = false;

        }
        field(2; "Selected Layout Code"; Code[20])
        {
            DataClassification = CustomerContent;

        }
        field(3; "Selected Layout Name"; Text[80])
        {
            DataClassification = CustomerContent;

        }
    }

    keys
    {
        key(Pk; "Key Field")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    trigger OnInsert()
    begin

    end;

    trigger OnModify()
    begin

    end;

    trigger OnDelete()
    begin

    end;

    trigger OnRename()
    begin

    end;
}