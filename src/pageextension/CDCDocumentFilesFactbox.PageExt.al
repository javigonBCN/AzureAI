namespace AzureAI.AzureAI;

pageextension 80101 "CDC Document Files Factbox" extends "CDC Document Files Factbox"
{
    actions
    {
        addlast(Processing)
        {
            group(OCRActions)
            {
                Caption = 'OCR Azure', Comment = 'ESP="OCR Azure"';
                Image = Find;
                action(OCRSearch)
                {
                    ApplicationArea = All;
                    Enabled = true;
                    Caption = 'Search with OCR', Comment = 'ESP="Buscar con OCR"';
                    Image = Find;
                    Scope = Repeater;
                    ToolTip = 'Search for specific lines in this document using Azure AI OCR', Comment = 'ESP="Buscar líneas específicas en este documento usando Azure AI OCR"';

                    trigger OnAction()
                    var
                        CDCDocument: Record "CDC Document";
                        OCRDocFinder: Page "OCR Document Finder";
                    begin
                        if CDCDocument.get(Rec."No.") then begin
                            // Abrir la página de búsqueda con el documento actual preseleccionado
                            OCRDocFinder.SetDocumentNo(CDCDocument."No.");
                            OCRDocFinder.Run();
                        end;
                    end;
                }
            }
        }
    }
}