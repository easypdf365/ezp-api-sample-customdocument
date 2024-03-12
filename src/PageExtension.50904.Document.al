pageextension 50904 EZPX_Document extends EZP_DocumentCard
{
    trigger OnOpenPage()
    begin
        if gEZPDocumentRec.Code = CustomSalesDocumentCodeLbl then begin
            
            // enable fields on the Easy PDF Document card for our custom documents

            gBatchOnPostVisible :=
                gBatchOnPostVisible or
                (gEZPDocumentRec.Code in [
                    CustomSalesDocumentCodeLbl
                    ]);

            gSendOnPostVisible :=
                gSendOnPostVisible or
                (gEZPDocumentRec.Code in [
                    CustomSalesDocumentCodeLbl
                ]);

            if gBatchOnPostVisible then
                gBatchOnPostEnabled := (not gEZPDocumentRec.SendOnPost);
            if gSendOnPostVisible then
                gSendOnPostEnabled := (not gEZPDocumentRec.BatchOnPost);

            gBatchGroupVisible :=
                gBatchGroupVisible or
                gBatchOnPostVisible or
                gSendOnPostVisible;

            gJobQueueGroupVisible :=
                gJobQueueGroupVisible or
                gBatchOnPostVisible;

            gShiptoControlVisible :=
                gShiptoControlVisible or
                (gEZPDocumentRec.Code in [
                    CustomSalesDocumentCodeLbl
                    ]);

            gSendToCustomerTypeVisible :=
                gSendToCustomerTypeVisible or
                (gEZPDocumentRec.Code in [
                    CustomSalesDocumentCodeLbl
                    ]);

            gCopySalespersonVisible :=
                gCopySalespersonVisible or
                (gEZPDocumentRec.Code in [
                    CustomSalesDocumentCodeLbl
                    ]);

            gAddToAttachedDocumentsVisible :=
                (gEZPDocumentRec.Code in [
                    CustomSalesDocumentCodeLbl
                    ]);
        end;
    end;
        
    var
        CustomSalesDocumentCodeLbl: Label 'CUSTOM SALES CONFIRMATION';
        CustomPurchaseDocumentCodeLbl: Label 'CUSTOM PURCHASE ORDER';
}
