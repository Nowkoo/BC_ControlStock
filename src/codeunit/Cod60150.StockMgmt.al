codeunit 60150 "Stock Mgmt"
{
    procedure GetSalesLinesForSalesHeader(SalesHeader: Record "Sales Header") RecRef: RecordRef
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");

        if SalesLine.FindSet() then begin
            RecRef.Open(Database::"Sales Line");
            RecRef.SetTable(SalesLine);
            exit(RecRef);
        end;
    end;

    procedure PurchaseMissingItems(var ItemToPurchase: Record Item temporary; var SalesLine: Record "Sales Line")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QuantityToOrder: Decimal;
        ItemFound: Boolean;
    begin
        if ItemToPurchase.FindSet() then
            repeat
                ItemToPurchase.CalcFields(Inventory);
                QuantityToOrder := CalculateQuantityToOrder(SalesLine, ItemToPurchase);

                //Si sales line tiene ya purchase line asociada, la buscamos para modificarla
                if not (SalesLine."Purch. Order Line No." = 0) and (SalesLine."Purchase Order No." = '') then
                    ItemFound := FindAndModifyPurchaseLine(PurchaseLine, PurchaseHeader."No.", ItemToPurchase."No.", QuantityToOrder);

                //Si no la encontramos, buscamos pedidos de compra abiertos para el proveedor
                if not ItemFound then begin
                    PurchaseHeader.Reset();
                    PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
                    PurchaseHeader.SetFilter("Buy-from Vendor No.", ItemToPurchase."Vendor No.");
                    PurchaseHeader.SetFilter(Status, '=%1', PurchaseHeader.Status::Open);

                    //Si hay un pedido de compra abierto para el proveedor: si hay una línea con el mismo producto la modificamos y si no creamos una nueva
                    if PurchaseHeader.FindSet() then begin
                        repeat
                            ItemFound := FindAndModifyPurchaseLine(PurchaseLine, PurchaseHeader."No.", ItemToPurchase."No.", QuantityToOrder);
                        until (PurchaseHeader.Next() = 0) or ItemFound;

                        if not ItemFound then
                            FillAndInsertPurchaseLine(PurchaseLine, PurchaseHeader, ItemToPurchase."No.", QuantityToOrder);
                    end

                    //Si no hay un pedido de compra abierto para el proveedor, creamos un nuevo pedido de compra.
                    else begin
                        FillAndInsertPurchaseHeader(PurchaseHeader, ItemToPurchase, QuantityToOrder);
                        FillAndInsertPurchaseLine(PurchaseLine, PurchaseHeader, ItemToPurchase."No.", QuantityToOrder);
                        Message('Insertado el pedido de compra ' + PurchaseHeader."No.");
                    end;

                    LinkSalesLineToPurchLine(SalesLine, PurchaseLine);
                end;
            until ItemToPurchase.Next() = 0;

        Commit();
    end;

    local procedure FindAndModifyPurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeaderNo: Code[20]; ItemNo: Code[20]; QuantityToOrder: Decimal) ItemFound: Boolean
    begin
        PurchaseLine.Reset();
        PurchaseLine.SetFilter("Document No.", PurchaseHeaderNo);
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetFilter("No.", ItemNo);

        if PurchaseLine.FindFirst() then begin
            PurchaseLine.Quantity := PurchaseLine.Quantity + QuantityToOrder;
            PurchaseLine.Modify();
            exit(true);
        end;
    end;

    local procedure LinkSalesLineToPurchLine(SalesLine: Record "Sales Line"; PurchaseLine: Record "Purchase Line")
    begin
        SalesLine."Purch. Order Line No." := PurchaseLine."Line No.";
        SalesLine."Purchase Order No." := PurchaseLine."Document No.";
        SalesLine.Modify();
    end;

    local procedure CalculateQuantityToOrder(var SalesLines: Record "Sales Line"; ItemToPurchase: Record Item): Decimal
    var
        QuantityToOrder: Decimal;
    begin
        SalesLines.SetFilter("No.", ItemToPurchase."No.");
        if SalesLines.FindFirst() then begin
            if ItemToPurchase.Inventory > 0 then
                QuantityToOrder := SalesLines.Quantity - ItemToPurchase.Inventory
            else
                QuantityToOrder := SalesLines.Quantity;
            exit(QuantityToOrder);
        end;
    end;

    local procedure FillAndInsertPurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; QuantityToOrder: Decimal)
    begin
        PurchaseLine.Reset();
        PurchaseLine.Init();
        PurchaseLine."Document No." := PurchaseHeader."No.";
        PurchaseLine."Document Type" := PurchaseLine."Document Type"::Order;
        PurchaseLine.SetPurchHeader(PurchaseHeader);
        PurchaseLine.AddItem(PurchaseLine, ItemNo);
        PurchaseLine.Quantity := QuantityToOrder;
        PurchaseLine.Modify();
    end;

    local procedure FillAndInsertPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; ItemToPurchase: Record Item; QuantityToOrder: Decimal)
    var
        Vendor: Record Vendor;
    begin
        PurchaseHeader.Reset();
        PurchaseHeader.Init();
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Order;
        PurchaseHeader."Buy-from Vendor No." := ItemToPurchase."Vendor No.";
        PurchaseHeader."Pay-to Vendor No." := ItemToPurchase."Vendor No.";

        Vendor.SetFilter("No.", ItemToPurchase."Vendor No.");
        if Vendor.FindFirst() then
            PurchaseHeader."Buy-from Vendor Name" := Vendor.Name;

        PurchaseHeader.Insert(true);
    end;

    /* local procedure RemovePurchLineFromSalesLines(PurchaseLine: Record "Purchase Line")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Purch. Order Line No.", PurchaseLine."Line No.");
        SalesLine.SetRange("Purchase Order No.", PurchaseLine."Document No.");
        if SalesLine.FindSet() then
            repeat
                Message('test');
                SalesLine."Purch. Order Line No." := 0;
                SalesLine."Purchase Order No." := '';
            until SalesLine.next = 0;
    end; */
}