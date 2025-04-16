//Report selection sales para cambiar el report predeterminado
reportextension 60150 "Standard Sales Invoice Ext" extends "Standard Sales - Invoice"
{
    dataset
    {
        // Add changes to dataitems and columns here
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
}