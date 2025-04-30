pageextension 60150 "Sales Order Ext" extends "Sales Order"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        /*  modify(Release)
         {
             trigger OnBeforeAction()
             var
                 SalesLine: Record "Sales Line";
                 Item: Record "Item";
                 ItemsToPurchase: Record Item temporary;
                 ConfirmPurchase: Boolean;
                 PurchHeaderNoList: List of [Text];
                 Filter: Text;
             begin
                 StockMgmt.ControlStock(Rec);
             end;
         } */

        /* modify(Post)
        {
            trigger OnAfterAction()
            begin
                SendEmail.SendReport(Rec."No.", Rec."Sell-to Customer No.");
            end;
        } */


        addafter(Action21)
        {
            group(StockControl)
            {
                Caption = 'Stock control';
                Image = Inventory;

                action(PostingEmailSetup)
                {
                    ApplicationArea = All;
                    Caption = 'Posting Email Setup';
                    //Enabled = Rec.Status <> Rec.Status::Released;
                    Image = Email;
                    //ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Configure subject and body for the email sent to the customer after posting a sales order.';

                    // RunObject = page "Purchase Order List";
                    // RunPageLink = "No." = filter(106005 .. 106007);

                    trigger OnAction()
                    begin
                        Page.Run(Page::"Posting Email Setup");
                    end;
                }

                action(LinkedOrders)
                {
                    ApplicationArea = All;
                    Caption = 'Linked Orders';
                    //Enabled = Rec.Status <> Rec.Status::Released;
                    Image = RelatedInformation;
                    //ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Display the purchase orders linked to this sales order.';

                    // RunObject = page "Purchase Order List";
                    // RunPageLink = "No." = filter(106005 .. 106007);

                    trigger OnAction()
                    begin
                        StockMgmt.DisplayLinkedPurchaseOrders(Rec);
                    end;
                }

                action(ClearPurchOrders)
                {
                    ApplicationArea = All;
                    Caption = 'Clear linked orders';
                    //Enabled = Rec.Status <> Rec.Status::Released;
                    Image = ClearLog;
                    //ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Clear purchase orders linked to this sales order.';

                    // RunObject = page "Purchase Order List";
                    // RunPageLink = "No." = filter(106005 .. 106007);

                    trigger OnAction()
                    begin
                        StockMgmt.ClearLinkedPurchOrders(Rec);
                    end;
                }
            }
        }
    }

    var
        StockMgmt: Codeunit "Stock Mgmt";
}