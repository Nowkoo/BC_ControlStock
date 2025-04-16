page 60150 "Email Subjects"
{
    PageType = List;
    ApplicationArea = All;
    Caption = 'Email Subjects';
    Extensible = false;
    SourceTable = "Email Subjects";
    UsageCategory = Lists;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Customer Type"; Rec."Customer Type")
                {
                    ToolTip = 'Type of the customer.';
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Subject"; Rec."Subject")
                {
                    ToolTip = 'Specify a subject for the email to this customer type.';
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {

    }

    trigger OnOpenPage()
    var
        EmailSubjectsRec: Record "Email Subjects";
        EnumItem: List of [Text];
        IntCount: Integer;
        Subject: Text;
    begin
        if EmailSubjectsRec.IsEmpty() then begin
            EmailSubjectsRec.Init();
            EnumItem := "Customer Type Enum".Names();

            for IntCount := 0 to EnumItem.Count - 1 do begin
                EmailSubjectsRec.Init();
                EmailSubjectsRec."Customer Type" := "Customer Type Enum".FromInteger(IntCount);
                EmailSubjectsRec.Subject := '';
                EmailSubjectsRec.Insert();
            end;
        end;
    end;

    local procedure GetEmailByCustomerType(CustomerType: Enum "Customer Type Enum"): Text
    var
        EmailSubjectsRec: Record "Email Subjects";
    begin
        EmailSubjectsRec.Init();
        EmailSubjectsRec.Get(CustomerType);
        if not EmailSubjectsRec.IsEmpty then
            exit(EmailSubjectsRec.Subject);
    end;
}