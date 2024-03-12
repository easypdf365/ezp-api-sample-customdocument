Easy PDF Custom Documents sample

This sample adds custom Easy PDF Documents for the sales order and purchase order.

It shows how to:
- register a new document type
- configure a new document setup (OnAfterInsertDocumentSetup)
- initialize a document and associated records (OnInitializeRecord)
- use a CompoundKey when sending a document
- make use of the EZP_Document record and CompoundKey in event subscribers

Note: this sample subscribes to most Easy PDF events  
Normally you would not do that, but it is done within to give some insight

Further note:
See API documentation online at--
https://easypdf365.com/guides

