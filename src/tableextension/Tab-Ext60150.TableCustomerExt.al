tableextension 60150 "Table Customer Ext" extends Customer
{
    fields
    {
        field(60150; "Customer Type"; Enum "Customer Type Enum")
        {
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        // Add changes to keys here
    }

    fieldgroups
    {
        // Add changes to field groups here
    }
}