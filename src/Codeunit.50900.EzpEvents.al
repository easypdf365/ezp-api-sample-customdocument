codeunit 50900 EZPX_EzpEvents
{
    // About using the 'CompoundKey' variable
    // CompoundKey is provided as a way for you to pass data to your event subscribers.
    // It is a Text variable and can be used to store whatever you wish (text, json, whatever).
    // You pass it into the EZP_API_* procedures and it resurfaces in the downstream events that are raised
    // You should use the following convention to avoid collision with other extensions that also use the Easy PDF API
    // CompoundKey := '<Prefix>;<data>'
    // Where Prefix = some short, globally unique, identifier for your app.
    // In this app I am using the prefix 'EZPX'.
    // In your event subscriptions the CompoundKey will be passed in - you should test it to see if the event is something you are interested in.
    // E.g.,
    //     if not CompoundKey.StartsWith('EZPX') then exit;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::EZP_API_Events, 'OnGetAppId', '', true, true)]
    /// <summary>
    /// OnGetAppId.
    /// </summary>
    /// <param name="Apps">VAR List of [Guid].</param>
    /// <remarks>Add your app Id - so your custom documents will be visible in the Easy PDF document lists.</remarks>
    internal procedure OnGetAppId(var Apps: List of [Guid])
    begin
        NavApp.GetCurrentModuleInfo(myAppInfo);
        Apps.Add(myAppInfo.Id);
    end;

    // Setup -------------------------------------------------------------------------------------

    [EventSubscriber(ObjectType::Codeunit, Codeunit::EZP_API_Events, 'OnInitializeDocumentSetup', '', true, true)]
    /// <summary>
    /// OnInitializeDocumentSetup.
    /// </summary>
    /// <param name="Scope">Code[50], user scope.</param>
    /// <remarks>Hook into this event to register any custom document types</remarks>
    internal procedure OnInitializeDocumentSetup(Scope: Code[50])
    var
        EZPDocumentRec: Record EZP_Document;
    begin
        // This event fires when Easy PDF is announcing the opportunity for any custom document setup
        // Here you can register custom document types

        NavApp.GetCurrentModuleInfo(myAppInfo);
        gEzpApiDocument.RegisterDocumentCode(myAppInfo.Id, CustomSalesDocumentCodeLbl, Scope, EZPDocumentRec);
        gEzpApiDocument.RegisterDocumentCode(myAppInfo.Id, CustomPurchaseDocumentCodeLbl, Scope, EZPDocumentRec);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::EZP_API_Events, 'OnAfterInsertDocumentSetup', '', true, true)]
    /// <summary>
    /// OnAfterInsertDocumentSetup.
    /// </summary>
    /// <param name="Scope">Code[50], user scope.</param>
    /// <remarks>Hook into this event to register any custom document types</remarks>
    internal procedure OnAfterInsertDocumentSetup(DocumentCode: Code[50]; Scope: Code[50]; var EZPDocumentRec: Record EZP_Document)
    begin
        // This event fires immediately after a new EZP_Document record has been inserted
        // Here you should perform any custom record initialization

        case DocumentCode of
            CustomSalesDocumentCodeLbl:
                begin
                    EZPDocumentRec.Description := CustomSalesDocumentDescriptionLbl;
                    EZPDocumentRec."Report ID" := 205;
                    EZPDocumentRec.Filename := CustomSalesDocumentFilenameLbl;
                    EZPDocumentRec.Modify();
                end;
            CustomPurchaseDocumentCodeLbl:
                begin
                    EZPDocumentRec.Description := CustomPurchaseDocumentDescriptionLbl;
                    EZPDocumentRec."Report ID" := 405;
                    EZPDocumentRec.Filename := CustomPurchaseDocumentFilenameLbl;
                    EZPDocumentRec.Modify();
                end;
        end;
    end;

    // Record Management -------------------------------------------------------------------------

    /// <summary>
    /// OnInitializeRecord.
    /// </summary>
    /// <param name="DocumentCode">Code[50].</param>
    /// <param name="DocumentNo">Code[20].</param>
    /// <param name="CompoundKey">Text.</param>
    /// <param name="ExternalDocumentVar">VAR Variant.</param>
    /// <remarks>Hook into this event to assign the database record associated with the DocumentCode,DocumentNo,CompoundKey.</remarks>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::EZP_API_Events, 'OnInitializeRecord', '', true, true)]
    internal procedure OnInitializeRecord(DocumentCode: Code[50]; DocumentNo: Code[20]; CompoundKey: Text; var ExternalDocumentVar: Variant; var EzpDocumentRec: Record EZP_Document);
    var
        SalesHeaderRec: Record "Sales Header";
        PurchaseHeaderRec: Record "Purchase Header";

        CustomerRec: Record Customer;
        ContactRec: Record Contact;
        ShiptoAddressRec: Record "Ship-to Address";
        SalespersonPurchaserRec: Record "Salesperson/Purchaser";
        VendorRec: Record Vendor;
        ok: Boolean;
    begin
        // This event fires when Easy PDF is preparing to process a document for mailing or printing
        // You need to prime Easy PDF with the database record(s) associated with the document code
        // We will setup references to records that Easy PDF uses when processing the document type for delivery 
        // The built-in types for the SetAssociatedRecordId() procedure are:
        //  'document', 'customer', 'vendor', 'contact', 'shipto' or 'shiptoaddress', 'location', 
        //  'salesperson' or 'purchaser' or 'salespersonpurchaser'
        // In addition, the following can be used for other record types
        //  'custom1', 'custom2', 'custom3', 'custom4', 'custom5'

        case DocumentCode of
            CustomSalesDocumentCodeLbl:
                begin
                    SalesHeaderRec.SetRange("Document Type", "Sales Document Type"::Order);
                    SalesHeaderRec.SetRange("No.", DocumentNo);
                    if SalesHeaderRec.FindFirst() then begin

                        SalesHeaderRec.SetRecFilter();
                        EzpDocumentRec.SetAssociatedRecordId('Document', SalesHeaderRec.RecordId());
                    
                        ok := CustomerRec.Get(SalesHeaderRec."Bill-to Customer No."); // default, get Bill-to Customer
                        if EZPDocumentRec."Send-to Customer Type" = EZPDocumentRec."Send-to Customer Type"::"Sell-to" then
                            ok := CustomerRec.Get(SalesHeaderRec."Sell-to Customer No."); // if Send-to = Sell-to, get Sell-to Customer

                        EzpDocumentRec.SetAssociatedRecordId('Customer', CustomerRec.RecordId());
                        EzpDocumentRec.RecipientType := EZP_RecipientType::Customer;

                        if not IsNullGuid(CustomerRec."Contact ID") then
                            if ContactRec.GetBySystemId(CustomerRec."Contact ID") then
                                EzpDOcumentRec.SetAssociatedRecordId('Contact', ContactRec.RecordId());

                        if SalesHeaderRec."Ship-to Code" <> '' then
                            if ShiptoAddressRec.Get(SalesHeaderRec."Sell-to Customer No.", SalesHeaderRec."Ship-to Code") then
                                EzpDocumentRec.SetAssociatedRecordId('ShiptoAddress', ShiptoAddressRec.RecordId());

                        if (SalesHeaderRec."Salesperson Code" <> '') then
                            if SalespersonPurchaserRec.Get(SalesHeaderRec."Salesperson Code") then
                                EzpDocumentRec.SetAssociatedRecordId('Salesperson', SalespersonPurchaserRec.RecordId());
                    end;
                end;

            CustomPurchaseDocumentCodeLbl:
                begin
                    // You must set filters on the record
                    PurchaseHeaderRec.SetRange("Document Type", "Purchase Document Type"::Order);
                    PurchaseHeaderRec.SetRange("No.", DocumentNo);
                    if PurchaseHeaderRec.FindFirst() then begin

                        PurchaseHeaderRec.SetRecFilter();
                        EzpDocumentRec.SetAssociatedRecordId('Document', PurchaseHeaderRec.RecordId());

                        ok := VendorRec.Get(PurchaseHeaderRec."Buy-from Vendor No."); // default, Buy-from Vendor
                        if EZPDocumentRec."Send-to Vendor Type" = EZPDocumentRec."Send-to Vendor Type"::"Pay-to" then
                            ok := VendorRec.Get(PurchaseHeaderRec."Pay-to Vendor No."); // if Send-to = Pay-to, get Pay-to Vendor

                        EzpDocumentRec.SetAssociatedRecordId('Vendor', VendorRec.RecordId());
                        EzpDocumentRec.RecipientType := EZP_RecipientType::Vendor;

                        if PurchaseHeaderRec."Ship-to Code" <> '' then
                            if ShiptoAddressRec.Get(PurchaseHeaderRec."Sell-to Customer No.", PurchaseHeaderRec."Ship-to Code") then
                                EzpDocumentRec.SetAssociatedRecordId('ShiptoAddress', ShiptoAddressRec.RecordId());;

                        if VendorRec."Primary Contact No." <> '' then
                            if ContactRec.Get(VendorRec."Primary Contact No.") then
                                EzpDocumentRec.SetAssociatedRecordId('Contact', ContactRec.RecordId());

                        if (VendorRec."Purchaser Code" <> '') then
                            if SalespersonPurchaserRec.Get(VendorRec."Purchaser Code") then
                                EzpDocumentRec.SetAssociatedRecordId('Purchaser', SalespersonPurchaserRec.RecordId());
                    end;
                end;
        end
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::EZP_API_Events, 'OnGetReportId', '', true, true)]
    internal procedure OnGetReportId(EZPDocumentRec: Record EZP_Document; CompoundKey: Text; ExternalDocumentVar: Variant; var ReportId: Integer)
    begin
        // This event fires when Easy PDF is retrieving the report id to use for printing the document type
        // Use this event to override the report identified on the EZP_Document record
        //
        // In this sample, since we configured the report id in the OnAfterInsertDocumentSetup event (above) we don't need to do anything.
        // You might use this event for special case override of the default value...
        // See the 'Change Layout' sample for an example of using this event.
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::EZP_API_Events, 'OnGetDeliveryMethod', '', true, true)]
    internal procedure OnGetDeliveryMethod(EZPDocumentRec: Record EZP_Document; CompoundKey: Text; ExternalDocumentVar: Variant; var DeliveryMethod: Enum EZP_DeliveryMethodType);
    var
        EZPDeliveryMethodRec: Record EZP_DeliveryMethod;
        CustomerRec: Record Customer;
        VendorRec: Record Vendor;
    begin
        // Implement to override values retrieved from the Customer/Vendor card
        // Remove this subscriber if you do not intend to override default values

        // Note: The following implementation is not required assuming you configured the RecipientType & Customer/Vendor records in OnInitializeRecord.
        // Below is the default implementation for retrieving the Delivery Method
        // This code is included only for additional insight.

        case EZPDocumentRec.Code of
            CustomSalesDocumentCodeLbl:
                begin
                    // Default method for this Customer
                    CustomerRec := EzpDocumentRec.GetAssociatedRecord('Customer', CustomerRec);
                    DeliveryMethod := CustomerRec.EZP_DeliveryMethod;
                    // Document specific method for this Customer
                    if EZPDeliveryMethodRec.Get(EZP_OwnerType::Customer, CustomerRec."No.", EZPDocumentRec.Code) then
                        DeliveryMethod := EZPDeliveryMethodRec.DeliveryMethod;
                end;
            CustomPurchaseDocumentCodeLbl:
                begin
                    // Default method for this Vendor
                    VendorRec := EzpDocumentRec.GetAssociatedRecord('Vendor', VendorRec);
                    DeliveryMethod := VendorRec.EZP_DeliveryMethod;
                    // Document specific method for this Vendor
                    if EZPDeliveryMethodRec.Get(EZP_OwnerType::Vendor, VendorRec."No.", EZPDocumentRec.Code) then
                        DeliveryMethod := EZPDeliveryMethodRec.DeliveryMethod;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::EZP_API_Events, 'OnGetPreferredLanguage', '', true, true)]
    internal procedure OnGetPreferredLanguage(EZPDocumentRec: Record EZP_Document; CompoundKey: Text; ExternalDocumentVar: Variant; var PreferredLanguage: Code[10]);
    var
        CustomerRec: Record Customer;
        VendorRec: Record Vendor;
    begin
        // Implement to override values retrieved from the Customer/Vendor/Contact card configured in OnAfterInitializeRecord
        // Remove this subscriber if you do not intend to override default values

        // Below is the default implementation for retrieving the Preferred Language.
        // This code is included only for additional insight.

        case EZPDocumentRec.Code of
            CustomSalesDocumentCodeLbl:
                begin
                    // Default language for this Customer
                    CustomerRec := EzpDocumentRec.GetAssociatedRecord('Customer', CustomerRec);
                    PreferredLanguage := CustomerRec."Language Code";
                end;
            CustomPurchaseDocumentCodeLbl:
                begin
                    // Default language for this Vendor
                    VendorRec := EzpDocumentRec.GetAssociatedRecord('Vendor', VendorRec);
                    PreferredLanguage := VendorRec."Language Code";
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::EZP_API_Events, 'OnGetRecipientDetails', '', true, true)]
    internal procedure OnGetRecipientDetails(EZPDocumentRec: Record EZP_Document; CompoundKey: Text; ExternalDocumentVar: Variant; var RecipientType: Enum EZP_RecipientType; var RecipientNo: Code[20]; var RecipientName: Text[100]);
    begin
        // Implement to override values retrieved from the associated Customer/Vendor/Contact card
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::EZP_API_Events, 'OnGetRecipientAddresses', '', true, true)]
    internal procedure OnGetRecipientAddresses(EZPDocumentRec: Record EZP_Document; CompoundKey: Text; ExternalDocumentVar: Variant; var ToAddress: Text; var CcAddress: Text; var BccAddress: Text);
    begin
        // Implement to override default value retrieved from the Address Book, and/or the associated Customer/Vendor/Contact card
        // The default implementation will retrieve addresses from the Address Book for the DocumentCode, and any additional addresses defined on the Document Card, 
        // and any addresses from the related Customer/Vendor/Contact cards
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::EZP_API_Events, 'OnGetAddressBookAddresses', '', true, true)]
    internal procedure OnGetAddressBookAddresses(EZPDocumentRec: Record EZP_Document; CompoundKey: Text; ExternalDocumentVar: Variant; OwnerType: Enum EZP_OwnerType; OwnerNo: Code[20]; var ToAddress: Text; var CcAddress: Text; var BccAddress: Text)
    begin
        // This event fires after Easy PDF has harvested addresses from the Address Book for the given Document/Owner (Customer, Vendor, ...)
        // Here you can implement your own harvesting and replace the addresses passed in with your crop.
        // Note: This event will be raised multiple times when sending a document
        // For instance - for a sales order confirmation:
        // - once when getting addresses for the customer (OwnerType = Customer)
        // - once when getting addresses in the Personal Address Book (OwnerType = User)
        // - once when getting "Additional Recipients" for the document (OwnerType = Document)
        //
        // The default implementation does this
        // EZPAddressRec.Reset();
        // EZPAddressRec.SetRange(DocumentCode, EzpDocument.Code);
        // EZPAddressRec.SetFilter(AddressType, '<>Fax');
        // EZPAddressRec.SetRange(OwnerType, OwnerType);
        // if OwnerNo <> '' then EZPAddressRec.SetRange(OwnerNo, OwnerNo);
        // if EZPAddressRec.FindSet() then
        //     repeat
        //         if EZPAddressRec.Address.Trim() <> '' then
        //             case EZPAddressRec.AddressType of
        //                 EZP_AddressType::"To":
        //                     gEZPToolsCu.AppendEmailAddressess(ToAddress, EZPAddressRec.Address);
        //                 EZP_AddressType::Cc:
        //                     gEZPToolsCu.AppendEmailAddressess(CcAddress, EZPAddressRec.Address);
        //                 EZP_AddressType::Bcc:
        //                     gEZPToolsCu.AppendEmailAddressess(BccAddress, EZPAddressRec.Address);
        //             end;
        //     until EZPAddressRec.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::EZP_API_Events, 'OnGetDocumentEmailAddress', '', true, true)]
    internal procedure OnGetDocumentEmailAddress(EZPDocumentRec: Record EZP_Document; CompoundKey: Text; ExternalDocumentVar: Variant; var Address: Text);
    var
        SalesHeaderRec: Record "Sales Header";
        PurchaseHeaderRec: Record "Purchase Header";
        ContactRec: Record Contact;
    begin
        // Implement to return an address specific to the underlying associated record
        // For example, on the Sales Order page there is a field named 'Email' that is prefilled with the email from the Customer card but can be changed
        // If you implement something similar you can use this event to retrieve that data

        // Here is the default implementation for sales and purchase documents
        // This code is included only for additional insight.

        case EZPDocumentRec.Code of
            CustomSalesDocumentCodeLbl:
                begin
                    // the email displayed on the sales order is the "Sell-to E-Mail" field on the Sales Header
                    SalesHeaderRec := EzpDocumentRec.GetAssociatedRecord('Document', SalesHeaderRec);
                    Address := SalesHeaderRec."Sell-to E-Mail";
                end;
            CustomPurchaseDocumentCodeLbl:
                begin
                    // the email displayed on the purchase order is the Buy-from Contact E-mail
                    PurchaseHeaderRec := EzpDocumentRec.GetAssociatedRecord('Document', PurchaseHeaderRec);
                    if ContactRec.Get(PurchaseHeaderRec."Buy-from Contact No.") then
                        Address := ContactRec."E-Mail";
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::EZP_API_Events, 'OnGetFaxNumber', '', true, true)]
    internal procedure OnGetFaxNumber(EZPDocumentRec: Record EZP_Document; CompoundKey: Text; ExternalDocumentVar: Variant; var FaxNumber: Text);
    begin
        // Implement to return a fax number for the underlying record
        // By default, the number from the customer/vendor/contact or the address book will be used
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::EZP_API_Events, 'OnGetRecordVariables', '', true, true)]
    internal procedure OnGetRecordVariables(EZPDocumentRec: Record EZP_Document; CompoundKey: Text; ExternalDocumentVar: Variant; var RecRef: RecordRef; var FieldRec: Record "Field");
    var
        SalesHeaderRec: Record "Sales Header";
        PurchaseHeaderRec: Record "Purchase Header";
    begin
        // YOU MUST IMPLEMENT THIS EVENT if you are defining a custom document
        // Implement to return a RecordRef and filtered Field record based for the underlying record
        // Used when performing token substitution or printing the record

        case EZPDocumentRec.Code of
            CustomSalesDocumentCodeLbl:
                begin
                    SalesHeaderRec := EzpDocumentRec.GetAssociatedRecord('Document', SalesHeaderRec);
                    RecRef.GetTable(SalesHeaderRec);
                    FieldRec.SetRange(TableNo, Database::"Sales Header");
                end;
            CustomPurchaseDocumentCodeLbl:
                begin
                    PurchaseHeaderRec := EzpDocumentRec.GetAssociatedRecord('Document', PurchaseHeaderRec);
                    RecRef.GetTable(PurchaseHeaderRec);
                    FieldRec.SetRange(TableNo, Database::"Purchase Header");
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::EZP_API_Events, 'OnGetArchivedVersionNo', '', true, true)]
    internal procedure OnGetArchivedVersionNo(EZPDocumentRec: Record EZP_Document; CompoundKey: Text; ExternalDocumentVar: Variant; var ArchivedVersionNo: Integer);
    var
        SalesHeaderRec: Record "Sales Header";
        PurchaseHeaderRec: Record "Purchase Header";
    begin
        // Implement to return a value for the archived version number - displayed on the batch page

        case EZPDocumentRec.Code of
            CustomSalesDocumentCodeLbl:
                begin
                    SalesHeaderRec := EzpDocumentRec.GetAssociatedRecord('Document', SalesHeaderRec);
                    SalesHeaderRec.CalcFields("No. of Archived Versions");
                    ArchivedVersionNo := SalesHeaderRec."No. of Archived Versions";
                end;
            CustomPurchaseDocumentCodeLbl:
                begin
                    PurchaseHeaderRec := EzpDocumentRec.GetAssociatedRecord('Document', PurchaseHeaderRec);
                    SalesHeaderRec.CalcFields("No. of Archived Versions");
                    ArchivedVersionNo := SalesHeaderRec."No. of Archived Versions";
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::EZP_API_Events, 'OnGetValue', '', true, true)]
    internal procedure OnGetValue(EZPDocumentRec: Record EZP_Document; CompoundKey: Text; ExternalDocumentVar: Variant; var Value: Decimal);
    var
        SalesHeaderRec: Record "Sales Header";
        PurchaseHeaderRec: Record "Purchase Header";
    begin
        // Implement to return a value for the record - displayed on the batch page

        case EZPDocumentRec.Code of
            CustomSalesDocumentCodeLbl:
                begin
                    SalesHeaderRec := EzpDocumentRec.GetAssociatedRecord('Document', SalesHeaderRec);
                    SalesHeaderRec.CalcFields("Amount Including VAT");
                    Value := SalesHeaderRec."Amount Including VAT";
                end;
            CustomPurchaseDocumentCodeLbl:
                begin
                    PurchaseHeaderRec := EzpDocumentRec.GetAssociatedRecord('Document', PurchaseHeaderRec);
                    PurchaseHeaderRec.CalcFields("Amount Including VAT");
                    Value := PurchaseHeaderRec."Amount Including VAT";
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::EZP_API_Events, 'OnGetPredefinedToken', '', true, true)]
    internal procedure OnGetPredefinedToken(EZPDocumentRec: Record EZP_Document; CompoundKey: Text; ExternalDocumentVar: Variant; Token: Text; var TokenValue: Text);
    begin
        // Implement to define custom static tokens used during token replacement
        // Static tokens are not bound to field values, they are simple text substitutions as you define them
        // e.g., [[MY_CUSTOM_TOKEN]] --> "My Custom Token"

        case Token of
            'MY_CUSTOM_TOKEN':
                TokenValue := 'My Custom Token';
        end
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::EZP_API_Events, 'OnGetTableFromToken', '', true, true)]
    internal procedure OnGetTableFromToken(EZPDocumentRec: Record EZP_Document; CompoundKey: Text; ExternalDocumentVar: Variant; TableName: Text; var RecRef: RecordRef; var FieldRec: Record Field);
    begin
        // Implement to define related tables used during token replacement

        // An Easy PDF 'token' has the form [[{table}field]]
        // (Actually it has the more general form [[(flags){table}field;length;format;regex]] but for this discussion we ignore the other bits...)
        //
        // When Easy PDF parses a token it extracts the table name from the token (if it exists).
        // If the table name is not one of those defined in OnAfterInitializeRecord the Easy PDF raises this event.
        // In this way, you can define 'related' tables -- for instance, you might have a 'Supplier' table that is related to a 'Product' table..
        // When sending the Product document you could then reference the Supplier.Name field in a token using [[{Supplier}Name]]
        // And in this event subscriber you would do something like:
        // ProductRec := EZPDocumentRec.GetAssociatedRecord('Document', ProductRec);
        // if SupplierRec.Get(ProductRec."Supplier No.") then begin
        //     RecRef.GetTable(SupplierRec);
        //     FieldRec.SetRange(TableNo, RefRef.Number());
        // end;
        // Easy PDF would then use the RecRef and FieldRec to retrieve the Name field from the Supplier record.
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::EZP_API_Events, 'OnDocumentNotPrinted', '', true, true)]
    internal procedure OnDocumentNotPrinted(EZPDocumentRec: Record EZP_Document; CompoundKey: Text; ExternalDocumentVar: Variant);
    var
        SalesHeaderRec: Record "Sales Header";
        PurchaseHeaderRec: Record "Purchase Header";
    begin
        // This event fires after the user previews a report or cancels sending an email (with the printed report attached).
        // If the underlying record is keeping track of printed copies (e.g., Posted Sales Invoice) then this event provides an opportunity
        // to decrement that count -- since preview or unsent email should not increment it.
        // Note: most posted documents don't give Modify permission to the average user -- so you need to verify that the user can modify the record else an error will occur.

        case EZPDocumentRec.Code of
            CustomSalesDocumentCodeLbl:
                begin
                    if gEzpApiUserSetup.HasPermission(EZP_ObjectType::"Table Data", Database::"Sales Header", EZP_PermissionType::Modify) then begin
                        SalesHeaderRec := EzpDocumentRec.GetAssociatedRecord('Document', SalesHeaderRec);
                        SalesHeaderRec."No. Printed" := gMath.Max(SalesHeaderRec."No. Printed" - 1, 0);
                        SalesHeaderRec.Modify();
                        Commit();
                    end;
                end;
            CustomPurchaseDocumentCodeLbl:
                begin
                    if gEzpApiUserSetup.HasPermission(EZP_ObjectType::"Table Data", Database::"Purchase Header", EZP_PermissionType::Modify) then begin
                        PurchaseHeaderRec := EzpDocumentRec.GetAssociatedRecord('Document', PurchaseHeaderRec);
                        PurchaseHeaderRec."No. Printed" := gMath.Max(PurchaseHeaderRec."No. Printed" - 1, 0);
                        PurchaseHeaderRec.Modify();
                        Commit();
                    end;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::EZP_API_Events, 'OnGetCustomReportSelectionKeys', '', true, true)]
    internal procedure OnGetCustomReportSelectionKeys(EZPDocumentRec: Record EZP_Document; CompoundKey: Text; ExternalDocumentVar: Variant; ReportId: Integer; var Usage: Enum "Report Selection Usage"; var SourceType: Integer; var SourceNo: Code[20]);
    var
        CustomerRec: Record Customer;
        VendorRec: Record Vendor;
        CustomReportSelectionRec: Record "Custom Report Selection";
    begin
        // This event fires when before printing the report for a given document type.
        // It provides the opportunity to identify a custom report selection to use when printing the report.
        // You would only use this event if you have extended the "Document Layouts" functionality on the Customer/Vendor card
        // Hook this event to return proper values if you wish to support Customer/Vendor Document Layouts

        // Here is the default implementation for the SALES ORDER and PURCHASE ORDER documents

        case EZPDocumentRec.Code of
            CustomSalesDocumentCodeLbl:
                begin
                    CustomerRec := EzpDocumentRec.GetAssociatedRecord('Customer', CustomerRec);
                    Usage := CustomReportSelectionRec.Usage::"S.Order";
                    SourceType := Database::Customer;
                    SourceNo := CustomerRec."No.";
                end;
            CustomPurchaseDocumentCodeLbl:
                begin
                    VendorRec := EzpDocumentRec.GetAssociatedRecord('Vendor', VendorRec);
                    Usage := CustomReportSelectionRec.Usage::"P.Order";
                    SourceType := Database::Vendor;
                    SourceNo := VendorRec."No.";
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::EZP_API_Events, 'OnGetCustomReportLayoutCode', '', true, true)]
    internal procedure OnGetCustomReportLayoutCode(EZPDocumentRec: Record EZP_Document; CompoundKey: Text; ExternalDocumentVar: Variant; ReportId: Integer; var ReportLayoutCode: Code[20]);
    begin
        // Use this event to identify specific custom report layouts
        // You would generally use this event in combination with the CompoundKey and OnGetReportId event, see the 'Custom Layout' sample
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::EZP_API_Events, 'OnGetCustomerLedgerEntryDocumentCode', '', true, true)]
    internal procedure OnGetCustomerLedgerEntryDocumentCode(LedgerEntryRec: Record "Cust. Ledger Entry"; var DocumentCode: Code[50])
    begin
        // If you have implemented documents that show up in Customer Ledger Entries - and you want to be able to 'Send to Batch'
        // then implement this event returning a DocumentCode when the ledger entry matches your custom record
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::EZP_API_Events, 'OnGetVendorLedgerEntryDocumentCode', '', true, true)]
    internal procedure OnGetVendorLedgerEntryDocumentCode(LedgerEntryRec: Record "Vendor Ledger Entry"; var DocumentCode: Code[50])
    begin
        // ditto above but for vendor ledger entries
    end;

    // Batch -------------------------------------------------------------------------------------

    [EventSubscriber(ObjectType::Codeunit, Codeunit::EZP_API_Events, 'OnBeforeDocumentPosted', '', true, true)]
    internal procedure OnBeforeDocumentPosted(EventType: Text; RecordVar: Variant; var DocumentCode: Code[50]; var DocumentNo: Code[20]; var CompoundKey: Text; var ExternalDocumentVar: Variant; var Handled: Boolean)
    var
        EZPDocumentRec: Record EZP_Document;
        SalesHeaderRec: Record "Sales Header";
    begin

        if  DocumentCode = 'SALES ORDER' then begin
            // Here we are going to 'hijack' the release processing of the 'SALES ORDER' document
            // Note: the EventType parameter is one of: 'POSTED', 'RELEASED', 'ISSSUED', 'EXPORTED'
            if EventType = 'RELEASED' then begin

                SalesHeaderRec := RecordVar;

                // change this to match the criteria of your requirements
                // i.e., what is the reason for hijacking the 'SALES ORDER'
                // here we are just matching to the Adatum company in the Cronus test database
                if SalesHeaderRec."Sell-to Customer No." = '10000' then begin
                    gEzpApiDocument.GetDocumentSetup(UserId(), CustomSalesDocumentCodeLbl, EZPDocumentRec, false);
                    if EZPDocumentRec.SendOnPost then begin
                        DocumentCode := CustomSalesDocumentCodeLbl;
                        CompoundKey := 'EZPX;'
                        // we're setting the CompoundKey here so we know in downstream events that we are the
                        // initiator of the flow.
                    end;
                    if EZPDocumentRec.BatchOnPost then begin
                        DocumentCode := CustomSalesDocumentCodeLbl;
                        CompoundKey := 'EZPX;'
                    end;
                end;
            end;
        end;

    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::EZP_API_Events, 'OnGetReportParametersXml', '', true, true)]
    internal procedure OnGetReportParametersXml(EZPDocumentRec: Record EZP_Document; CompoundKey: Text; ExternalDocumentVar: Variant; ReportId: Integer; RecRef: RecordRef; var ReportParameters: Text)
    begin
        // This event fires when printing a report, or when queueing a batch entry
        // The default implementation will generate an appropriate set of report parameters filtered to the database record associated with the DocumentCode
        // That will be sufficient if your report only requires the filtered record to function properly (e.g., Sales Order Confirmation report).
        //
        // However, if your report requires fields or filters defined on the request page AND you want to be able to send the report WITHOUT SHOWING 
        // the request page (e.g., from batch) then YOU MUST hook this event and return a ReportParameters string that properly invokes the report.
        // You can use the utility functions defined in EZP_API_Tools to facilitate generating the report parameters string.
        // See the sample 'Custom Complex Report' for more details
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::EZP_API_Events, 'OnShowReportRequestPage', '', true, true)]
    internal procedure OnShowReportRequestPage(EZPDocumentRec: Record EZP_Document; CompoundKey: Text; ExternalDocumentVar: Variant; ReportId: Integer; var ReportParameters: Text; var Handled: Boolean)
    begin
        // This event will fire if you call one of the APIs with RunRequestPage = true
        // e.g., EZP_API_Send.SendByEmail(DocumentCode, DocumentNo, CompoundKey, true);
        // In this handler you need to call RunRequestPage for your report and return the report parameters
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::EZP_API_Events, 'OnShowDocumentPage', '', true, true)]
    internal procedure OnShowDocument(EZPDocumentRec: Record EZP_Document; CompoundKey: Text; ExternalDocumentVar: Variant);
    var
        SalesHeaderRec: Record "Sales Header";
        PurchaseHeaderRec: Record "Purchase Header";
    begin
        // Implement to show the document page for the underlying record
        //
        // Here is the default implementation for the SALES ORDER
        // Note: you must call Commit before RunModal or you will likely get a runtime error

        Commit();
        case EZPDocumentRec.Code of
            CustomSalesDocumentCodeLbl:
                begin
                    SalesHeaderRec := EzpDocumentRec.GetAssociatedRecord('Document', SalesHeaderRec);
                    SalesHeaderRec.SetRecFilter();
                    Page.RunModal(Page::"Sales Order", SalesHeaderRec);
                end;
            CustomPurchaseDocumentCodeLbl:
                begin
                    PurchaseHeaderRec := EzpDocumentRec.GetAssociatedRecord('Document', PurchaseHeaderRec);
                    PurchaseHeaderRec.SetRecFilter();
                    Page.RunModal(Page::"Purchase Order", PurchaseHeaderRec);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::EZP_API_Events, 'OnShowRecipientPage', '', true, true)]
    internal procedure OnShowRecipient(EZPDocumentRec: Record EZP_Document; CompoundKey: Text; ExternalDocumentVar: Variant);
    var
        SalesHeaderRec: Record "Sales Header";
        PurchaseHeaderRec: Record "Purchase Header";
        CustomerRec: Record Customer;
        VendorRec: Record Vendor;
    begin
        // Implement to show a recipient page for the underlying record, usually a customer or vendor
        //
        // Here is the default implementation for the SALES ORDER
        // Note: you must call Commit before RunModal or you will likely get a runtime error

        Commit();
        case EZPDocumentRec.Code of
            CustomSalesDocumentCodeLbl:
                begin
                    CustomerRec := EzpDocumentRec.GetAssociatedRecord('Customer', CustomerRec);
                    CustomerRec.SetRecFilter();
                    Page.RunModal(Page::"Customer Card", CustomerRec);
                end;
            CustomPurchaseDocumentCodeLbl:
                begin
                    VendorRec := EzpDocumentRec.GetAssociatedRecord('Vendor', VendorRec);
                    VendorRec.SetRecFilter();
                    Page.RunModal(Page::"Vendor Card", VendorRec);
                end;
        end;
    end;

    // -------------------------------------------------------------------------------------------

    var
        gEzpApiDocument: Codeunit EZP_API_Document;
        gEzpApiUserSetup: Codeunit EZP_API_UserSetup;
        gMath: Codeunit Math;
        myAppInfo: ModuleInfo;

        CustomSalesDocumentCodeLbl: Label 'CUSTOM SALES CONFIRMATION';
        CustomSalesDocumentFilenameLbl: Label 'Custom Sales Confirmation [[No.]]';
        CustomSalesDocumentDescriptionLbl: Label 'Custom Sales Confirmation';

        CustomPurchaseDocumentCodeLbl: Label 'CUSTOM PURCHASE ORDER';
        CustomPurchaseDocumentFilenameLbl: Label 'Custom Purchase Order [[No.]]';
        CustomPurchaseDocumentDescriptionLbl: Label 'Custom Purchase Order';
}