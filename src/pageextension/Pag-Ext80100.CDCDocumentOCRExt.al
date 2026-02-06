pageextension 80100 "CDC Document OCR Ext" extends "GES CDC DragDrop and Scan Fact"
{
    actions
    {
        //TODO CAMPO A ESCANEAR.
        addlast(Processing)
        {
            group(OCRActions)
            {
                Caption = 'OCR AZURE';
                Image = Find;

                action(OCRSearch)
                {
                    ApplicationArea = All;
                    Caption = 'Buscar con OCR';
                    Image = Find;
                    ToolTip = 'Buscar líneas específicas en este documento usando Azure AI OCR';

                    trigger OnAction()
                    var
                        OCRDocFinder: Page "OCR Document Finder";
                    begin
                        // Abrir la página de búsqueda con el documento actual preseleccionado
                        OCRDocFinder.SetDocumentNo(Rec."No.");
                        OCRDocFinder.Run();
                    end;
                }

                action(OCRQuickSearch)
                {
                    ApplicationArea = All;
                    Caption = 'Búsqueda Rápida OCR';
                    Image = Find;
                    ToolTip = 'Realizar una búsqueda rápida en este documento';

                    trigger OnAction()
                    var
                        OCRSearch: Codeunit "OCR Document Search";
                        SearchResults: Record "OCR Search Results" temporary;
                        SearchResultsPage: Page "OCR Search Results";
                        SearchText: Text[100];
                    begin
                        SearchText := '';

                        if not (Rec."PDF File".HasValue()) then
                            Error('Este documento no tiene un PDF adjunto');

                        //if not Dialog.Input(SearchText, 'Ingrese el texto a buscar:') then
                        //    exit;
                        //TODO    
                        SearchText := '00052';
                        if SearchText = '' then
                            exit;

                        // Ejecutar búsqueda
                        if OCRSearch.SearchInDocument(Rec."No.", SearchText, SearchResults) then begin
                            SearchResultsPage.SetTableView(SearchResults);
                            SearchResultsPage.RunModal();
                            Message('Se encontraron %1 coincidencia(s)', SearchResults.Count());
                        end else
                            Message('No se encontraron coincidencias');
                    end;
                }
            }
        }
    }
}
