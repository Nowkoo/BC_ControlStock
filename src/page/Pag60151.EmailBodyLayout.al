page 60151 "Email Body Layout"
{
    PageType = List;
    ApplicationArea = All;
    Caption = 'Email Body Word Layouts';
    Extensible = false;
    SourceTable = "Custom Report Layout";
    UsageCategory = Lists;
    InsertAllowed = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the Code.';
                    Visible = false;
                }
                field("Report ID"; Rec."Report ID")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = false;
                    ToolTip = 'Specifies the object ID of the report.';
                }
                field("Report Name"; Rec."Report Name")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = false;
                    ToolTip = 'Specifies the name of the report.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the report layout.';
                }
                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Business Central company that the report layout applies to. You to create report layouts that can only be used on reports when they are run for a specific to a company. If the field is blank, then the layout will be available for use in all companies.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the file type of the report layout. The following table includes the types that are available:';
                }
            }
        }
    }

    actions
    {
        area(Creation)
        {
            action(New)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'New Layout';
                Image = Word;
                ToolTip = 'Upload a new Word layout file to use as email body when posting a sales order.';
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    UploadWordLayout(Report::"Email Body Word Report");
                end;
            }

            action(ExportLayout)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Export Layout';
                Image = Export;
                ToolTip = 'Export a Word layout file.';
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    Rec.ExportReportLayout('', true);
                end;
            }

            action(RunReport)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Run Report';
                Image = "Report";
                ToolTip = 'Run a test report.';
                Promoted = true;
                PromotedCategory = Process;


                trigger OnAction()
                begin
                    Rec.RunCustomReport();
                end;
            }
        }
    }

    local procedure UploadWordLayout(ReportID: Integer)
    var
        CustomReportLayout: Record "Custom Report Layout";
        TempBlob: Codeunit "Temp Blob";
        OutputTempBlob: Codeunit "Temp Blob";
        DocumentReportMgt: Codeunit "Document Report Mgt.";
        OutStr: OutStream;
        InStr: InStream;
        LayoutType: Option;

        FileMgt: Codeunit "File Management";
        FileName: Text;
        FileFilterTxt: Text;
        ImportTxt: Text;
        ErrorMessage: Text;
        XmlPart: Text;
    begin
        LayoutType := CustomReportLayout.Type::Word.AsInteger();
        XmlPart := CustomReportLayout.GetWordXmlPart(ReportID);

        CustomReportLayout.Init();
        CustomReportLayout."Report ID" := ReportID;
        CustomReportLayout.Type := "Custom Report Layout Type".FromInteger(LayoutType);
        CustomReportLayout.Description := CopyStr(StrSubstNo(CopyOfTxt, BuiltInTxt), 1, MaxStrLen(CustomReportLayout.Description));
        CustomReportLayout."Built-In" := false;
        CustomReportLayout.Code := CustomReportLayout.GetDefaultCode(ReportID);
        CustomReportLayout."Email Layout" := true;

        OutputTempBlob.CreateOutStream(OutStr);

        case LayoutType of
            CustomReportLayout.Type::Word.AsInteger():
                begin
                    FileName := FileMgt.BLOBImportWithFilter(TempBlob, ImportTxt, '', FileFilterWordTxt, FileFilterWordTxt);
                    if FileName = '' then
                        exit;

                    TempBlob.CreateInStream(InStr);
                    ErrorMessage := DocumentReportMgt.TryUpdateWordLayout(InStr, OutStr, '', XmlPart);
                    // Validate the Word document layout against the layout of the current report
                    if ErrorMessage = '' then begin
                        CustomReportLayout.Insert(true);
                        CopyStream(OutStr, InStr);
                        DocumentReportMgt.ValidateWordLayout(ReportID, InStr, true, true);
                        CustomReportLayout.SetLayoutBlob(OutputTempBlob);
                    end;
                end;
        end;

        if CustomReportLayout."File Extension" <> '' then
            CustomReportLayout."File Extension" := CopyStr(UpperCase(FileMgt.GetExtension(FileName)), 1, 30);
        CustomReportLayout.SetDefaultCustomXmlPart();
        CustomReportLayout."Layout Last Updated" := RoundDateTime(CurrentDateTime);

        Commit();

        if ErrorMessage <> '' then
            Message(ErrorMessage);
    end;

    var
        BuiltInTxt: Label 'Built-in layout';
        CopyOfTxt: Label 'Copy of %1';
        NewLayoutTxt: Label 'New layout';
        FileFilterWordTxt: Label 'Word Files (*.docx)|*.docx', Comment = '{Split=r''\|''}{Locked=s''1''}';
}