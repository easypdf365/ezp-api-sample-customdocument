pageextension 50902 EZPX_PurchaseOrder extends "Purchase Order"
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
                    ToolTip = 'Send the puchase order by email.';
                    Image = MailAttachment;
                    ApplicationArea = All;
                    Promoted = true;
                    PromotedCategory = Category10;

                    trigger OnAction()
                    begin
                        gEZPApiSend.SendByEmail(CustomPurchaseDocumentCodeLbl, Rec."No.", 'EZPX;', false);
                    end;
                }
            }
        }
    }

    var
        gEZPApiSend: Codeunit EZP_API_Send;
        CustomPurchaseDocumentCodeLbl: Label 'CUSTOM PURCHASE ORDER';
}
