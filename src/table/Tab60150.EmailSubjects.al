table 60150 "Email Subjects"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Customer Type"; Enum "Customer Type Enum")
        {
            DataClassification = ToBeClassified;

        }
        field(2; "Subject"; Text[60])
        {
            DataClassification = ToBeClassified;

        }
    }

    keys
    {
        key(Pk; "Customer Type")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    var
        myInt: Integer;

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