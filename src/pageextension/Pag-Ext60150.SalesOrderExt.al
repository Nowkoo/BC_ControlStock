//AUTORELLENAR CAMPOS DE HEADER Y LINES
//LEER TEXTO DE UN RDLC??
pageextension 60150 "Sales Order Ext" extends "Sales Order"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        modify(Release)
        {
            trigger OnBeforeAction()
            var
                SalesLines: Record "Sales Line";
                Item: Record "Item";
                ItemsToPurchase: Record Item temporary;
                ConfirmPurchase: Boolean;
            begin
                //Buscar líneas de pedido de la cabecera
                SalesLines.SetRange("Document Type", Rec."Document Type");
                SalesLines.SetRange("Document No.", Rec."No.");
                if SalesLines.FindSet() then
                    repeat
                        //Buscar producto asociado a la línea y si no hay stock almacenarlo en una tabla temporal
                        Item.SetRange("No.", SalesLines."No.");
                        Item.FindFirst();
                        if not Item.IsEmpty then begin
                            Item.CalcFields(Inventory);
                            if SalesLines.Quantity > Item.Inventory then begin
                                ItemsToPurchase := Item;
                                ItemsToPurchase.Insert();
                            end;
                        end;
                    until SalesLines.Next() = 0;

                //Si falta stock, preguntar si se quiere crear un pedido de compra. Si no se quiere, error.
                if not ItemsToPurchase.IsEmpty then begin
                    ConfirmPurchase := Dialog.Confirm(ConfirmPurchaseLabel);
                    if ConfirmPurchase then begin
                        SalesLines.FindSet();
                        StockMgmt.PurchaseMissingItems(ItemsToPurchase, SalesLines);
                    end;
                    Error(ErrorNotEnoughStockLabel);
                end;
            end;
        }

        modify(Post)
        {
            trigger OnAfterAction()
            begin
                SendEmail.SendReport(Rec."No.", Rec."Sell-to Customer No.");
            end;
        }


        addafter(Action21)
        {
            action(EmailSubjects)
            {
                ApplicationArea = All;
                Caption = 'Email Subjects';
                //Enabled = Rec.Status <> Rec.Status::Released;
                Image = ReleaseDoc;
                //ShortCutKey = 'Ctrl+F9';
                ToolTip = 'Set an email subject for each type of customer.';

                trigger OnAction()
                begin
                    Page.Run(Page::"Email Subjects");
                end;
            }
        }
    }


    var
        StockMgmt: Codeunit "Stock Mgmt";
        SendEmail: Codeunit "Email Mgmt";
        ErrorNotEnoughStockLabel: Label 'Sale Order could not be released because there is not enough stock.';
        ConfirmPurchaseLabel: Label 'There is not enough stock of some of the products, do you want to create a purchase order for the missing amounts?';
}