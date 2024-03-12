pageextension 50900 EZPX_SalesOrder extends "Sales Order"
{
    layout
    {
    }

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
                    PromotedCategory = Category11;

                    trigger OnAction()
                    begin
                        gEZPApiSend.SendByEmail(CustomSalesDocumentCodeLbl, Rec."No.", 'EZPX;', false);
                    end;
                }
            }
        }
    }

    var
        gEZPApiSend: Codeunit EZP_API_Send;
        CustomSalesDocumentCodeLbl: Label 'CUSTOM SALES CONFIRMATION';
}
