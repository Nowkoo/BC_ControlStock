codeunit 60151 "Email Mgmt"
{
    [EventSubscriber(ObjectType::Page, Page::"Sales Order", OnPostDocumentBeforeNavigateAfterPosting, '', true, true)]
    local procedure SendReport(var SalesHeader: Record "Sales Header")
    var
        TempEmailItem: Record "Email Item" temporary;
        GlobalHideDialog: Boolean;
        GlobalEmailScenario: Enum "Email Scenario";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    //MailManagement: Codeunit "Mail Management";
    begin
        Clear(TempEmailItem);
        Clear(SalesInvoiceHeader);

        SalesInvoiceHeader.SetRange("Order No.", SalesHeader."No.");
        if not SalesInvoiceHeader.FindSet() then
            exit;

        TempEmailItem.SetBodyText(GetEmailBody(SalesInvoiceHeader));
        TempEmailItem.Validate("Send to", GetEmailAddress(SalesHeader."Sell-to Customer No."));
        TempEmailItem.Subject := GetSubject(SalesHeader."Sell-to Customer No.");
        AddReportAsAttachment(SalesInvoiceHeader, TempEmailItem);
        GlobalHideDialog := true;
        TempEmailItem.Send(GlobalHideDialog, GlobalEmailScenario);
        //MailManagement.Send(TempEmailItem, GlobalEmailScenario);
    end;

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

    //nuevo botón:
    // abrir nueva pág que muestre lista de custom report layouts solo de tipo word y permita añadirlos o copiarlos usando mismos métodos que custom report layout.
    //btn para seleccionar un layout de la lista y btn para crear nuevo layout
    //extender custom report layouts para añadir campo email layout que al insertar desde la nueva pág se pone en true, la nueva pág muestra solo los que tienen ese campo en true.
    //crear tabla que almacene el layout seleccionado o añadir otro campo a custom report layouts para saber cuál es

    //btn abre custom report layouts y custom report layouts tiene un nuevo botón para configurar el email body

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

        if Report.SaveAs(Report::"Email Body Word Report", '', ReportFormat::Html, OutStream, RecordRef) then begin
            TempBlob.CreateInStream(InStream);
            InStream.ReadText(ResultingTxt);

            // if XmlDocument.ReadFrom(InStream, XmlDoc) then begin
            //     // XmlDoc.GetRoot(Root);
            //     // Message(Root.InnerXml);

            //     NodesToSelect.AddRange('//Label[@name="Greetings"]', '//DataItem[@name="Customer"]', '//Label[@name="AddressTxt"]', '//Column[@name="BillToAddress"]', '//Label[@name="DateTxt"]', '//Column[@name="ShipmentDate"]');
            //     foreach Txt in NodesToSelect do begin
            //         XmlDoc.SelectSingleNode(Txt, XmlNode);
            //         ResultingTxt := ResultingTxt + XmlNode.AsXmlElement().InnerText + ' ';
            //     end;
            // end;

            Exit(ResultingTxt);
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
}