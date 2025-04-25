codeunit 60150 "Stock Mgmt"
{
    [EventSubscriber(ObjectType::Table, Database::"Sales Header", OnBeforePerformManualRelease, '', true, true)]
    local procedure ControlStock(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        Item: Record "Item";
        PurchaseHeaderNo: Code[20];
        PurchHeaderNoList: List of [Text];
        Filter: Text;
        DialogDisplayed: Boolean;
        ConfirmPurchase: Boolean;
        PurchaseHeader: Record "Purchase Header";
        IsEmptySalesLine: Boolean;
    begin
        //Buscar líneas de pedido de la cabecera
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindSet() then
            repeat
                //Buscar producto asociado a la línea. Si no hay stock y la línea no ha sido lanzada antes, preguntamos si se quiere comprar una sola vez. 
                //Se crearán o modificarán pedidos de compra para cada uno de los productos de los que falte stock.
                if Item.Get(SalesLine."No.") then begin
                    Item.CalcFields(Inventory);
                    if (SalesLine.Quantity > Item.Inventory) and not HasPurchLineLinked(SalesLine) then begin
                        if not DialogDisplayed then begin
                            ConfirmPurchase := Dialog.Confirm(ConfirmPurchaseLabel);
                            DialogDisplayed := true;
                        end;

                        if ConfirmPurchase then begin
                            PurchaseHeaderNo := PurchaseItem(Item, SalesLine);
                            if StrLen(PurchaseHeaderNo) <> 0 then
                                PurchHeaderNoList.Add(PurchaseHeaderNo);
                        end;
                    end;
                end;
            until SalesLine.Next() = 0
        else
            IsEmptySalesLine := true;

        //Mensaje de confirmación y display de los pedidos de compra, si los hay
        if ConfirmPurchase then begin
            Commit();
            RemoveRepeated(PurchHeaderNoList);
            Filter := GetFilterFromListOfPurchHeaderNo(PurchHeaderNoList);
        end;

        if not IsEmptySalesLine then begin
            if PurchHeaderNoList.Count <> 0 then begin
                if (PurchHeaderNoList.Count = 1) and PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchHeaderNoList.Get(1)) then begin
                    Page.Run(Page::"Purchase Order", PurchaseHeader)
                end
                else
                    RunFilteredPurchaseOrders(Filter);
                Error(ErrorTryReleaseWhenReceived);
            end
            else begin
                PurchHeaderNoList := DisplayLinkedOrders(SalesHeader);
                if PurchHeaderNoList.Count() <> 0 then
                    Error(ErrorAllLinesAreLinked);
            end;
            Error(ErrorNotEnoughStockLabel);
        end;
    end;

    procedure DisplayLinkedOrders(SalesHeader: Record "Sales Header") PurchHeaderNoList: List of [Text]
    var
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        Filter: Text;
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindSet() then
            repeat
                if HasPurchLineLinked(SalesLine) then begin
                    PurchHeaderNoList.Add(SalesLine."Purchase Line Document No");
                end;
            until SalesLine.Next() = 0;

        RemoveRepeated(PurchHeaderNoList);
        Filter := GetFilterFromListOfPurchHeaderNo(PurchHeaderNoList);

        if PurchHeaderNoList.Count() <> 0 then begin
            if (PurchHeaderNoList.Count() = 1) then begin
                if PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchHeaderNoList.Get(1)) then
                    Page.Run(Page::"Purchase Order", PurchaseHeader)
            end
            else
                RunFilteredPurchaseOrders(Filter);
        end
        else
            Message(NoLinkedOrdersLabel);
        exit(PurchHeaderNoList)
    end;

    local procedure PurchaseItem(ItemToPurchase: Record Item; SalesLine: Record "Sales Line"): Text
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QuantityToOrder: Decimal;
        ItemFound: Boolean;
    begin
        ItemFound := false;
        ItemToPurchase.CalcFields(Inventory);
        QuantityToOrder := CalculateQuantityToOrder(SalesLine, ItemToPurchase);

        //Buscamos pedidos de compra abiertos para el proveedor
        PurchaseHeader.Reset();
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetFilter("Buy-from Vendor No.", ItemToPurchase."Vendor No.");
        PurchaseHeader.SetFilter(Status, '=%1', PurchaseHeader.Status::Open);

        //Si hay un pedido de compra abierto para el proveedor: si hay una línea con el mismo producto la modificamos, sino creamos una nueva
        if PurchaseHeader.FindSet() then begin
            repeat
                ItemFound := FindAndModifyPurchaseLine(PurchaseLine, PurchaseHeader."No.", ItemToPurchase."No.", QuantityToOrder);
            until (PurchaseHeader.Next() = 0) or ItemFound;

            if not ItemFound then begin
                PurchaseHeader.FindFirst();
                FillAndInsertPurchaseLine(PurchaseLine, PurchaseHeader, ItemToPurchase."No.", QuantityToOrder);
            end;
        end
        //Si no hay un pedido de compra abierto para el proveedor, creamos un nuevo pedido de compra.
        else begin
            FillAndInsertPurchaseHeader(PurchaseHeader, ItemToPurchase);
            FillAndInsertPurchaseLine(PurchaseLine, PurchaseHeader, ItemToPurchase."No.", QuantityToOrder);
        end;

        LinkSalesLineToPurchLine(SalesLine, PurchaseLine);
        exit(PurchaseHeader."No.");
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
        SalesLine."Purchase Line No" := PurchaseLine."Line No.";
        SalesLine."Purchase Line Document No" := PurchaseLine."Document No.";
        SalesLine.Modify();
    end;

    local procedure HasPurchLineLinked(SalesLine: Record "Sales Line"): Boolean
    var
        PurchaseLine: Record "Purchase Line";
    begin
        exit(
            (SalesLine."Purchase Line No" <> 0)
            and (SalesLine."Purchase Line Document No" <> '')
            and (PurchaseLine.Get(PurchaseLine."Document Type"::Order, SalesLine."Purchase Line Document No", SalesLine."Purchase Line No"))
            );
    end;

    local procedure CalculateQuantityToOrder(var SalesLine: Record "Sales Line"; ItemToPurchase: Record Item): Decimal
    var
        QuantityToOrder: Decimal;
    begin
        if ItemToPurchase.Inventory > 0 then
            QuantityToOrder := SalesLine.Quantity - ItemToPurchase.Inventory
        else
            QuantityToOrder := SalesLine.Quantity;
        exit(QuantityToOrder);
    end;

    local procedure FillAndInsertPurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; QuantityToOrder: Decimal)
    var
        LastLine: Record "Purchase Line";
    begin
        PurchaseLine.Reset();
        PurchaseLine.Init();
        PurchaseLine."Document No." := PurchaseHeader."No.";
        PurchaseLine."Document Type" := PurchaseLine."Document Type"::Order;
        PurchaseLine.SetPurchHeader(PurchaseHeader);

        LastLine.SetRange("Document No.", PurchaseHeader."No.");
        LastLine.SetRange("Document Type", PurchaseHeader."Document Type"::Order);

        if LastLine.FindLast() then begin
            PurchaseLine.AddItem(LastLine, ItemNo);

            //Buscamos la línea que acabamos de insertar
            PurchaseLine.Reset();
            PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
            PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
            PurchaseLine.FindLast();
        end
        else
            PurchaseLine.AddItem(PurchaseLine, ItemNo);

        PurchaseLine.Validate(Quantity, QuantityToOrder);
        PurchaseLine.Modify();
    end;

    local procedure FillAndInsertPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; ItemToPurchase: Record Item)
    var
        Vendor: Record Vendor;
    begin
        PurchaseHeader.Reset();
        PurchaseHeader.Init();
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Order;
        PurchaseHeader.Validate("Buy-from Vendor No.", ItemToPurchase."Vendor No.");
        PurchaseHeader.Validate("Pay-to Vendor No.", ItemToPurchase."Vendor No.");
        PurchaseHeader.Insert(true);
    end;

    local procedure RunFilteredPurchaseOrders(Filter: Text)
    var
        PurchOrder: Page "Purchase Order List";
        PurchHeader: Record "Purchase Header";
    begin
        PurchHeader.SetFilter("No.", Filter);
        PurchOrder.SetTableView(PurchHeader);
        PurchOrder.Editable := true;
        PurchOrder.Run();
    end;

    local procedure RemoveRepeated(var TxtList: List of [Text])
    var
        Txt: Text;
        Set: List of [Text];
    begin
        foreach Txt in TxtList do begin
            if not Set.Contains(Txt) then
                Set.Add(Txt);
        end;
        TxtList := Set;
    end;

    local procedure GetFilterFromListOfPurchHeaderNo(PurchHeaderNoList: List of [Text]) Filter: Text
    var
        PurchNo: Text;
        NoList: List of [Text];
    begin
        foreach PurchNo in PurchHeaderNoList do begin
            if not NoList.Contains(PurchNo) then begin
                NoList.Add(PurchNo);
                Filter := Filter + PurchNo + '|';
            end;
        end;
        if Filter <> '' then
            Filter := Filter.Remove(Text.StrLen(Filter));
        exit(Filter);
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
     ;
    end; */

    var
        StockMgmt: Codeunit "Stock Mgmt";
        SendEmail: Codeunit "Email Mgmt";
        ErrorTryReleaseWhenReceived: Label 'Sale Order was not released. Try again when the items are received.';
        ErrorAllLinesAreLinked: Label 'All the items in this order are already linked to a purchase order. Sale Order was not released. Try again when the items are received.';
        ErrorNotEnoughStockLabel: Label 'Sale Order was not released because there is not enough stock of one or more items.';

        ConfirmPurchaseLabel: Label 'There is not enough stock of one or more items in the order. Do you want to purchase the missing amounts?';
        PurchasedOrdersLabel: Label 'One or more purchase orders have been created or modified.';
        NoLinkedOrdersLabel: Label 'There are no linked purchase orders for this sale order.';
}