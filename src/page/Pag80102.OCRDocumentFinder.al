page 80102 "OCR Document Finder"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Tasks;
    Caption = 'OCR Document Finder';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            group(DocumentSelection)
            {
                Caption = 'Selección de Documento';

                field(DocumentNo; DocumentNo)
                {
                    ApplicationArea = All;
                    Caption = 'Nº Documento Continia';
                    ToolTip = 'Seleccione el documento de Continia Document Capture a analizar';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        DCDocuments: Record "CDC Document";
                    begin
                        //DCDocuments.SetRange(Status, DCDocuments.Status::Registered, DCDocuments.Status::Released);
                        if Page.RunModal(page::"OCR Document", DCDocuments) = Action::LookupOK then begin
                            DocumentNo := DCDocuments."No.";
                            DocumentDescription := DCDocuments.Description;
                            UpdateDocumentInfo();
                            Text := DocumentNo;
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        if DocumentNo <> '' then
                            UpdateDocumentInfo();
                    end;
                }

                field(DocumentDescription; DocumentDescription)
                {
                    ApplicationArea = All;
                    Caption = 'Descripción';
                    Editable = false;
                }
                field(HasPDF; HasPDF)
                {
                    ApplicationArea = All;
                    Caption = 'PDF Adjunto';
                    Editable = false;
                    Style = Favorable;
                    StyleExpr = HasPDF;
                }
            }

            group(SearchCriteria)
            {
                Caption = 'Criterios de Búsqueda';

                field(SearchText; SearchText)
                {
                    ApplicationArea = All;
                    Caption = 'Texto a Buscar';
                    ToolTip = 'Ingrese el texto a buscar en las líneas del documento (código, descripción, cantidad, precio, etc.)';

                    trigger OnValidate()
                    begin
                        SearchText := DelChr(SearchText, '<>', ' ');
                    end;
                }

                field(SearchExamples; SearchExamplesText)
                {
                    ApplicationArea = All;
                    Caption = 'Ejemplos';
                    Editable = false;
                    MultiLine = true;
                    ShowCaption = true;
                }
            }

            group(Results)
            {
                Caption = 'Resultados';
                Visible = SearchPerformed;

                field(ResultsCount; ResultsCount)
                {
                    ApplicationArea = All;
                    Caption = 'Resultados Encontrados';
                    Editable = false;
                    Style = Strong;
                    StyleExpr = true;
                }

                field(TotalLinesAnalyzed; TotalLinesAnalyzed)
                {
                    ApplicationArea = All;
                    Caption = 'Total Líneas Analizadas';
                    Editable = false;
                }

                field(ProcessingTime; ProcessingTimeText)
                {
                    ApplicationArea = All;
                    Caption = 'Tiempo de Procesamiento';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Search)
            {
                ApplicationArea = All;
                Caption = 'Buscar con OCR';
                Image = Find;
                ToolTip = 'Analizar el documento con Azure AI y buscar el texto especificado';
                trigger OnAction()
                var
                    OCRSearch: Codeunit "OCR Document Search";
                    SearchResults: Record "OCR Search Results" temporary;
                    SearchResultsPage: Page "OCR Search Results";
                    StartTime: DateTime;
                begin
                    ValidateSearch();

                    StartTime := CurrentDateTime;

                    // Ejecutar búsqueda
                    if OCRSearch.SearchInDocument(DocumentNo, SearchText, SearchResults) then begin
                        // Mostrar resultados
                        ResultsCount := SearchResults.Count();
                        SearchPerformed := true;
                        ProcessingTimeText := Format(CurrentDateTime - StartTime);

                        // Obtener total de líneas del último log
                        GetLastLogInfo();

                        CurrPage.Update(false);

                        // Abrir página de resultados
                        SearchResultsPage.SetTableView(SearchResults);
                        SearchResultsPage.RunModal();

                        Message('%1 coincidencia(s) encontrada(s) en %2 líneas', ResultsCount, TotalLinesAnalyzed);
                    end else begin
                        SearchPerformed := true;
                        ResultsCount := 0;
                        ProcessingTimeText := Format(CurrentDateTime - StartTime);
                        GetLastLogInfo();
                        Message('No se encontraron coincidencias para: "%1"', SearchText);
                    end;
                end;
            }

            action(ClearSearch)
            {
                ApplicationArea = All;
                Caption = 'Limpiar';
                Image = ClearFilter;
                ToolTip = 'Limpiar los criterios de búsqueda';

                trigger OnAction()
                begin
                    Clear(SearchText);
                    Clear(ResultsCount);
                    Clear(TotalLinesAnalyzed);
                    Clear(ProcessingTimeText);
                    SearchPerformed := false;
                    CurrPage.Update(false);
                end;
            }

            action(ViewDocument)
            {
                ApplicationArea = All;
                Caption = 'Ver Documento PDF';
                Image = Document;
                ToolTip = 'Abrir el documento PDF de Continia';
                Enabled = HasPDF;

                trigger OnAction()
                var
                    DCDocuments: Record "CDC Document";
                    Document2: Record "GES CDC Document";
                    TempFile: Record "CDC Temp File" temporary;
                    TempFile2: Record "GES CDC Temp File" temporary;
                    FileManagement: Codeunit "File Management";
                    InStr: InStream;
                    OutStr: OutStream;
                    FilePath: Text;
                begin
                    if DocumentNo = '' then
                        exit;

                    if not DCDocuments.Get(DocumentNo) then
                        exit;

                    // Si el documento tiene un campo Blob con el PDF
                    if DCDocuments.HasMiscFile() then
                        DCDocuments.GetMiscFile(TempFile);


                    Document2.TransferFields(DCDocuments);

                    TempFile.Name := CopyStr(Document2.GetDocFileDescription() + '.' + Document2."File Extension", 1, 199);

                    TempFile2.TransferFields(TempFile);
                    TempFile2.Open();
                end;
            }
        }

        area(Navigation)
        {
            action(Configuration)
            {
                ApplicationArea = All;
                Caption = 'Azure AI Configuration';
                Image = Setup;
                ToolTip = 'Configurar Azure AI Document Intelligence';
                RunObject = Page "OCR Azure AI Configuration";
            }

            action(OperationLog)
            {
                ApplicationArea = All;
                Caption = 'Operation Log';
                Image = Log;
                ToolTip = 'Ver el registro de operaciones OCR';
                RunObject = Page "OCR Operation Log";
            }
        }

        area(Promoted)
        {
            actionref(SearchRef; Search) { }
            actionref(ClearRef; ClearSearch) { }
            actionref(ViewDocRef; ViewDocument) { }
        }
    }

    trigger OnOpenPage()
    begin
        SearchExamplesText := 'Ejemplos de búsqueda:\- Código de producto: "12345"\- Descripción: "TORNILLO"\- Cantidad: "100"\- Precio: "25.50"';
    end;

    local procedure ValidateSearch()
    begin
        if DocumentNo = '' then
            Error('Debe seleccionar un documento');

        if SearchText = '' then
            Error('Debe ingresar un texto a buscar');

        if not HasPDF then
            Error('El documento seleccionado no tiene PDF adjunto');
    end;

    local procedure UpdateDocumentInfo()
    var
        DCDocuments: Record "CDC Document";
    begin
        Clear(DocumentDescription);
        HasPDF := false;

        if DocumentNo = '' then
            exit;

        if DCDocuments.Get(DocumentNo) then begin
            //DocumentDescription := DCDocuments.Description;
            //VendorName := DCDocuments."Buy-from Vendor Name";
            //DCDocuments.CalcFields("PDF File");
            IF DCDocuments."File Extension" = 'pdf' then
                HasPDF := true;
        end;

        CurrPage.Update(false);
    end;

    local procedure GetLastLogInfo()
    var
        OCRLog: Record "OCR Operation Log";
    begin
        OCRLog.SetCurrentKey("Entry No.");
        OCRLog.SetRange("Document No.", DocumentNo);
        if OCRLog.FindLast() then
            TotalLinesAnalyzed := OCRLog."Total Lines Analyzed";
    end;

    procedure SetDocumentNo(NewDocumentNo: Code[20])
    begin
        DocumentNo := NewDocumentNo;
        UpdateDocumentInfo();
        CurrPage.Update(false);
    end;

    var
        DocumentNo: Code[20];
        SearchText: Text[100];
        DocumentDescription: Text[250];
        VendorName: Text[100];
        HasPDF: Boolean;
        SearchPerformed: Boolean;
        ResultsCount: Integer;
        TotalLinesAnalyzed: Integer;
        ProcessingTimeText: Text;
        SearchExamplesText: Text;
}
