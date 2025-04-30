page 60150 "Posting Email Setup"
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
            group("Email Body Layout")
            {
                Caption = 'Email Body Word Layout';

                field("Selected layout"; SelectedLayout)
                {
                    Caption = 'Selected layout';
                    ToolTip = 'Selected layout';
                    ApplicationArea = All;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        CustomReportLayout: Record "Custom Report Layout";
                        LayoutDisplayName: Text;
                    begin
                        CustomReportLayout.Reset();
                        CustomReportLayout.SetRange(Type, CustomReportLayout.Type::Word);
                        CustomReportLayout.SetRange("Report ID", Report::"Email Body Word Report");

                        if Page.RunModal(Page::"Email Body Layout", CustomReportLayout) = Action::LookupOK then begin
                            LayoutDisplayName := CustomReportLayout."Report Name" + ' - ' + CustomReportLayout.Description;
                            SelectedLayout := LayoutDisplayName;
                            if CustomReportLayout.Type <> CustomReportLayout.Type::Word then
                                Error(ErrorNotWordLayout);

                            UpdateLayoutInConfig(CustomReportLayout.code, LayoutDisplayName);
                        end;
                    end;
                }
            }
        }
    }

    local procedure UpdateLayoutInConfig(CustomReportLayoutCode: Code[20]; LayoutDisplayName: Text)
    var
        ExtensionConfiguration: Record "Extension Configuration";
    begin
        if not ExtensionConfiguration.Get() then begin
            ExtensionConfiguration.Init();
            ExtensionConfiguration."Key Field" := '';
            ExtensionConfiguration."Selected Layout Code" := CustomReportLayoutCode;
            ExtensionConfiguration."Selected Layout Name" := LayoutDisplayName;
            ExtensionConfiguration.Insert()
        end
        else begin
            ExtensionConfiguration."Selected Layout Code" := CustomReportLayoutCode;
            ExtensionConfiguration."Selected Layout Name" := LayoutDisplayName;
            ExtensionConfiguration.Modify();
        end;
        Commit();
    end;

    local procedure InitSelectedLayout()
    var
        ExtensionConfiguration: Record "Extension Configuration";
        CustomReportLayout: Record "Custom Report Layout";
    begin
        if ExtensionConfiguration.Get() then begin
            SelectedLayout := ExtensionConfiguration."Selected Layout Name";
        end;
    end;

    local procedure InitEmailSubjects()
    var
        EmailSubjectsRec: Record "Email Subjects";
        EnumItem: List of [Text];
        IntCount: Integer;
        Subject: Text;

        ExtensionConfiguration: Record "Extension Configuration";
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

    trigger OnOpenPage()
    begin
        InitSelectedLayout();
        InitEmailSubjects();
    end;

    var
        SelectedLayout: Text;
        ErrorNotWordLayout: Label 'Please select a Word layout.';
}