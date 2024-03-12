pageextension 50904 EZPX_Document extends EZP_DocumentCard
{
    trigger OnOpenPage()
    begin
        if gEZPDocumentRec.Code = CustomSalesDocumentCodeLbl then begin
            
            // enable the batch group
            gBatchGroupVisible := true;
            gBatchOnPostVisible := true;
            gSendOnPostVisible := true;
            if gBatchOnPostVisible then
                gBatchOnPostEnabled := (not gEZPDocumentRec.SendOnPost);
            if gSendOnPostVisible then
                gSendOnPostEnabled := (not gEZPDocumentRec.BatchOnPost);
        end;
    end;
        
    var
        CustomSalesDocumentCodeLbl: Label 'CUSTOM SALES CONFIRMATION';
        CustomPurchaseDocumentCodeLbl: Label 'CUSTOM PURCHASE ORDER';
}
