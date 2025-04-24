pageextension 60151 "Sales Order List Ext" extends "Sales Order List"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        addafter(Action12)
        {
            action(EmailSubjects)
            {
                ApplicationArea = All;
                Caption = 'Email Subjects';
                //Enabled = Rec.Status <> Rec.Status::Released;
                Image = ReleaseDoc;
                //ShortCutKey = 'Ctrl+F9';
                ToolTip = 'Set an email subject for each type of customer.';

                // RunObject = page "Purchase Order List";
                // RunPageLink = "No." = filter(106005 .. 106007);

                trigger OnAction()
                begin
                    Page.Run(Page::"Email Subjects");
                end;
            }

            action(LinkedOrders)
            {
                ApplicationArea = All;
                Caption = 'Linked Orders';
                //Enabled = Rec.Status <> Rec.Status::Released;
                Image = ReleaseDoc;
                //ShortCutKey = 'Ctrl+F9';
                ToolTip = 'Display the purchase orders linked to this sales order.';

                // RunObject = page "Purchase Order List";
                // RunPageLink = "No." = filter(106005 .. 106007);

                trigger OnAction()
                begin
                    StockMgmt.DisplayLinkedOrders(Rec);
                end;
            }
        }
    }

    var
        StockMgmt: Codeunit "Stock Mgmt";
}