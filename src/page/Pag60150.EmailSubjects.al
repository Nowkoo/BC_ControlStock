page 60150 "Email Subjects"
{
    PageType = List;
    ApplicationArea = All;
    Caption = 'Posting Email Setup';
    Extensible = false;
    SourceTable = "Email Subjects";
    UsageCategory = Lists;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group("Email Body Layout")
            {
                Caption = 'Email Body Layout';
                field("Selected layout"; SelectedLayout)
                {
                    ToolTip = 'Selected layout';
                    ApplicationArea = All;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        CustomReportLayout: Record "Custom Report Layout";
                    begin
                        CustomReportLayout.Reset();
                        if Page.RunModal(Page::"Custom Report Layouts", CustomReportLayout) = Action::LookupOK then begin
                            SelectedLayout := CustomReportLayout."Report Name" + ' - ' + CustomReportLayout.Description;
                            //almacenar el código del layout y cargarlo al body del correo cuando se cree el correo
                            Message(CustomReportLayout.code)
                        end;
                    end;
                }
            }

            group("Email Subject")
            {
                Caption = 'Email Subject by Customer Type';
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
    }

    actions
    {
        area(Processing)
        {
            action(test)
            {
                trigger OnAction()
                var
                    CustomReportLayout: Record "Custom Report Layout";
                begin
                    CustomReportLayout.Reset();
                    if Page.RunModal(Page::"Custom Report Layouts", CustomReportLayout) = Action::LookupOK then
                        Message(CustomReportLayout."Report Name");
                end;
            }
        }
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

    var
        SelectedLayout: Text;
}