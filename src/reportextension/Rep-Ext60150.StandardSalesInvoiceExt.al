//Report selection sales para cambiar el report predeterminado
reportextension 60150 "Standard Sales Invoice Ext" extends "Standard Sales - Invoice"
{
    dataset
    {

    }

    requestpage
    {
        // Add changes to the requestpage here
    }

    rendering
    {
        layout(CustomWordLayout)
        {
            Type = Word;
            Caption = 'Custom sales invoice';
            Summary = 'Custom sales invoice in Word';
            LayoutFile = 'customlayout.docx';
        }
    }

    labels
    {
        PctDiscountLbl = 'Discount %', Comment = 'Foo', MaxLength = 999, Locked = false;
        TotalDiscountLbl = 'Total discount', Comment = 'Foo', Locked = false;
        TotalVATEC = 'Total VAT|EC', Comment = 'Foo', Locked = false;
    }
}