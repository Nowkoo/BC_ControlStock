codeunit 60151 "Email Mgmt"
{
    procedure GetSubject(CustomerNo: Code[20]): Text
    var
        Customer: Record Customer;
        EmailSubject: Record "Email Subjects";
    begin
        Customer.SetFilter("No.", CustomerNo);
        if Customer.FindFirst() then begin
            EmailSubject.SetRange("Customer Type", Customer."Customer Type");
            if EmailSubject.FindFirst() then
                exit(EmailSubject.Subject);
        end;
    end;

    procedure GetEmailAddress(CustomerNo: Code[20]): Text
    var
        Customer: Record Customer;
    begin
        Customer.SetFilter("No.", CustomerNo);
        if Customer.FindFirst() then
            exit(Customer."E-Mail");
    end;

    procedure GetEmailBody(var SalesInvoiceHeader: Record "Sales Invoice Header"): Text
    var
        InStream: InStream;
        OutStream: OutStream;
        TempBlob: Codeunit "Temp Blob";
        RecordRef: RecordRef;

        //Root: XmlElement;
        XmlDoc: XmlDocument;
        XmlNode: XmlNode;
        NodesToSelect: List of [Text];
        ResultingTxt: Text;
        Txt: Text;
    begin
        Clear(TempBlob);
        RecordRef.GetTable(SalesInvoiceHeader);
        TempBlob.CreateOutStream(OutStream);

        if Report.SaveAs(Report::"Email Body RDL Report", '', ReportFormat::Xml, OutStream, RecordRef) then begin
            TempBlob.CreateInStream(InStream);
            if XmlDocument.ReadFrom(InStream, XmlDoc) then begin
                // XmlDoc.GetRoot(Root);
                // Message(Root.InnerXml);

                NodesToSelect.AddRange('//Label[@name="Greetings"]', '//DataItem[@name="Customer"]', '//Label[@name="AddressTxt"]', '//Column[@name="BillToAddress"]', '//Label[@name="DateTxt"]', '//Column[@name="ShipmentDate"]');
                foreach Txt in NodesToSelect do begin
                    XmlDoc.SelectSingleNode(Txt, XmlNode);
                    ResultingTxt := ResultingTxt + XmlNode.AsXmlElement().InnerText + ' ';
                end;

                Exit(ResultingTxt);
            end;
        end;
    end;

    procedure AddReportAsAttachment(var SalesInvoiceHeader: Record "Sales Invoice Header"; var EmailItem: Record "Email Item")
    var
        InStream: InStream;
        OutStream: OutStream;
        TempBlob: Codeunit "Temp Blob";
        RecordRef: RecordRef;

        ReportLayoutSelectionLocal: Record "Report Layout Selection";
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
        LastUsedParameters: Text;
    begin
        ReportLayoutSelectionLocal.SetTempLayoutSelected('1306-000001'); // subir a Custom Report Layouts y mirar código en el inspector
        LastUsedParameters := CustomLayoutReporting.GetReportRequestPageParameters(Report::"Standard Sales - Invoice");

        Clear(TempBlob);
        RecordRef.GetTable(SalesInvoiceHeader);
        TempBlob.CreateOutStream(OutStream);

        if Report.SaveAs(Report::"Standard Sales - Invoice", LastUsedParameters, ReportFormat::Pdf, OutStream, RecordRef) then begin
            TempBlob.CreateInStream(InStream);
            EmailItem.AddAttachment(InStream, 'Custom sales invoice.pdf');
        end;
    end;

    procedure SendReport(SalesHeaderNo: Code[20]; CustomerNo: Code[20])
    var
        TempEmailItem: Record "Email Item" temporary;
        GlobalHideDialog: Boolean;
        GlobalEmailScenario: Enum "Email Scenario";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        Clear(TempEmailItem);

        SalesInvoiceHeader.SetFilter("Order No.", SalesHeaderNo);
        if not SalesInvoiceHeader.FindSet() then
            exit;

        TempEmailItem.SetBodyText(GetEmailBody(SalesInvoiceHeader));
        TempEmailItem."Send to" := GetEmailAddress(CustomerNo);
        TempEmailItem.Subject := GetSubject(CustomerNo);
        AddReportAsAttachment(SalesInvoiceHeader, TempEmailItem);
        TempEmailItem.Send(GlobalHideDialog, GlobalEmailScenario);
    end;
}