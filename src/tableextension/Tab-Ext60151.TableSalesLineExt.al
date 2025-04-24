tableextension 60151 "Table Sales Line Ext" extends "Sales Line"
{
    fields
    {
        modify(Quantity)
        {
            trigger OnAfterValidate()
            begin
                UpdatePurchLineQuantity();
            end;
        }

        field(60150; "Purchase Line No"; Integer)
        {
            DataClassification = CustomerContent;
        }
        field(60151; "Purchase Line Document No"; Code[20])
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


    local procedure UpdatePurchLineQuantity()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        QuantityToAdd: Decimal;
    begin
        QuantityToAdd := Rec.Quantity - xRec.Quantity;

        if (Rec."Purchase Line No" = 0) and (Rec."Purchase Line Document No" = '') then
            exit;

        if PurchaseLine.Get(PurchaseLine."Document Type"::Order, Rec."Purchase Line Document No", "Purchase Line No") then begin
            PurchaseHeader := PurchaseLine.GetPurchHeader();

            if not PurchaseHeader.IsEmpty() then begin
                if PurchaseHeader.Status <> PurchaseHeader.Status::Open then
                    exit;

                PurchaseLine.Quantity := PurchaseLine.Quantity + QuantityToAdd;
                PurchaseLine.Modify();
                Commit();
            end;
        end;
    end;
}