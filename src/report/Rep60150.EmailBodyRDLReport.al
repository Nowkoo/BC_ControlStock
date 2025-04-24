report 60150 "Email Body RDL Report"
{
    UsageCategory = None;
    ApplicationArea = All;
    DefaultRenderingLayout = EmailBodyRDL;

    dataset
    {
        dataitem(Header; "Sales Invoice Header")
        {
            column(ShipmentDate; Format("Shipment Date", 0, 4))
            {
                //IncludeCaption
            }
            column(BillToAddress; "Bill-to Address")
            {

            }
            /*    dataitem(Line; "Sales Invoice Line")
               {
                   DataItemLink = "Document No." = field("No.");
                   DataItemLinkReference = Header;
                   //DataItemTableView = sorting("Document No.", "Line No.");
               } 
            */

            dataitem(Customer; Customer)
            {
                DataItemLink = "No." = field("Sell-to Customer No.");
                DataItemLinkReference = Header;

                column(Name; "Name")
                {

                }
            }
        }
    }

    rendering
    {
        layout(EmailBodyRDL)
        {
            Type = RDLC;
            LayoutFile = 'EmailBodyRDL.rdlc';
        }
    }

    labels
    {
        Greetings = 'Hello ', Comment = 'Foo', MaxLength = 999, Locked = true;
        AddressTxt = 'Your order will be sent to ', Comment = 'Foo', Locked = false;
        DateTxt = 'on date ', Comment = 'Foo', Locked = false;
    }
}