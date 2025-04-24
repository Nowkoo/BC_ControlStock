report 60151 "Email Body Word Report"
{
    UsageCategory = None;
    ApplicationArea = All;
    DefaultRenderingLayout = EmailBodyWord;

    dataset
    {
        dataitem(Header; "Sales Invoice Header")
        {
            column(ShipmentDate; Format("Shipment Date", 0, 4))
            {
                //IncludeCaption
            }

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
        layout(EmailBodyWord)
        {
            Type = Word;
            LayoutFile = 'EmailBodyWord.docx';
        }
    }
}