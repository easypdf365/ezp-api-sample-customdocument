pageextension 50903 EZPX_PurchaseOrderList extends "Purchase Order List"
{
    actions
    {
        addlast(processing)
        {
            group(EZPXActionsGroup)
            {
                Caption = 'Custom Document Actions';
                action(EZPXSendByEMail)
                {
                    Caption = 'ezpx|Send by E-Mail';
                    ToolTip = 'Send the purchase order by email.';
                    Image = MailAttachment;
                    ApplicationArea = All;
                    Promoted = true;
                    PromotedCategory = Category8;

                    trigger OnAction()
                    begin
                        gEZPApiSend.SendByEmail(CustomPurchaseDocumentCodeLbl, Rec."No.", 'EZPX;', false);
                    end;
                }
                action(EZPXSendSelectedToBatch)
                {
                    Caption = 'ezpx|Send Selected to Batch';
                    ToolTip = 'Send the selected entries to Easy PDF Batch.';
                    Image = SelectEntries;
                    ApplicationArea = All;
                    Promoted = true;
                    PromotedCategory = Category8;

                    trigger OnAction()
                    var
                        PurchaseHeaderRec: Record "Purchase Header";
                        EzpQueueRec: Record EZP_Queue;
                        BatchId: Text[80];
                        RecordCount: Integer;
                    begin
                        RecordCount := 0;
                        CurrPage.SetSelectionFilter(PurchaseHeaderRec);
                        if PurchaseHeaderRec.FindSet() then begin

                            BatchId := gEZPApiSend.GenerateBatchId(CustomPurchaseDocumentCodeLbl);
                            repeat
                                gEZPApiSend.SendToBatch(CustomPurchaseDocumentCodeLbl, PurchaseHeaderRec."No.", 'EZPX;', BatchId, '');
                                RecordCount += 1;
                            until PurchaseHeaderRec.Next() = 0;

                            if RecordCount > 0 then begin
                                EzpQueueRec.Reset();
                                EzpQueueRec.SetRange(BatchId, BatchId);
                                Page.Run(Page::EZP_Batch, EzpQueueRec);
                            end;

                        end;
                    end;
                }
            }
        }
    }

    var
        gEZPApiSend: Codeunit EZP_API_Send;
        CustomPurchaseDocumentCodeLbl: Label 'CUSTOM PURCHASE ORDER';
}
