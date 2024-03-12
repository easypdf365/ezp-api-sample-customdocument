pageextension 50901 EZPX_SalesOrderList extends "Sales Order List"
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
                    ToolTip = 'Send the sales order confirmation by email.';
                    Image = MailAttachment;
                    ApplicationArea = All;
                    Promoted = true;
                    PromotedCategory = Category8;

                    trigger OnAction()
                    begin
                        gEZPApiSend.SendByEmail(CustomSalesDocumentCodeLbl, Rec."No.", 'EZPX;', false);
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
                        SalesHeaderRec: Record "Sales Header";
                        EzpQueueRec: Record EZP_Queue;
                        BatchId: Text[80];
                        RecordCount: Integer;
                    begin
                        RecordCount := 0;
                        CurrPage.SetSelectionFilter(SalesHeaderRec);
                        if SalesHeaderRec.FindSet() then begin

                            BatchId := gEZPApiSend.GenerateBatchId(CustomSalesDocumentCodeLbl);
                            repeat
                                gEZPApiSend.SendToBatch(CustomSalesDocumentCodeLbl, SalesHeaderRec."No.", 'EZPX;', BatchId, '');
                                RecordCount += 1;
                            until SalesHeaderRec.Next() = 0;

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
        CustomSalesDocumentCodeLbl: Label 'CUSTOM SALES CONFIRMATION';
}
