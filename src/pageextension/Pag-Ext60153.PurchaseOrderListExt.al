pageextension 60153 "Purchase Order List Ext" extends "Purchase Order List"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        addbefore(Action10)
        {
            group(StockControl)
            {
                Caption = 'Stock control';
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
                        StockMgmt.DisplayLinkedSalesOrders(Rec);
                    end;
                }

                action(ClearSalesOrders)
                {
                    ApplicationArea = All;
                    Caption = 'Clear linked orders';
                    //Enabled = Rec.Status <> Rec.Status::Released;
                    Image = ClearLog;
                    //ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Clear sales orders linked to this purchase order.';

                    // RunObject = page "Purchase Order List";
                    // RunPageLink = "No." = filter(106005 .. 106007);

                    trigger OnAction()
                    begin
                        StockMgmt.ClearLinkedSalesOrders(Rec);
                    end;
                }
            }
        }
    }

    var
        StockMgmt: Codeunit "Stock Mgmt";
}