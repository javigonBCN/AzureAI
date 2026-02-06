codeunit 80101 "OCR Document Search"
{
    procedure SearchInDocument(DocumentCaptureNo: Code[20]; SearchText: Text[100]; var SearchResults: Record "OCR Search Results" temporary): Boolean
    var
        JsonResponse: Text;
        StartTime: DateTime;
        ProcessingTime: Integer;
        TotalLinesFound: Integer;
        Success: Boolean;
        ErrorMsg: Text;
    begin
        StartTime := CurrentDateTime;
        Success := false;
        ErrorMsg := '';

        if DocumentCaptureNo = '' then
            Error('Debe especificar un número de documento');

        if SearchText = '' then
            Error('Debe ingresar un texto a buscar');

        //try TODO
        // Obtener y analizar el documento desde Continia
        JsonResponse := AnalyzeContiniaPDF(DocumentCaptureNo);

        ClearLastError();
        if JsonResponse <> '' then begin
            // Buscar el texto en las líneas extraídas
            TotalLinesFound := FindTextInLines(JsonResponse, SearchText, SearchResults);
            Success := true;
        end;
        if GetLastErrorText() <> '' then begin
            ErrorMsg := GetLastErrorText();
            Success := false;
        end;


        // Calcular tiempo de procesamiento
        ProcessingTime := CurrentDateTime - StartTime;

        // Crear log entry
        LogOperation(DocumentCaptureNo, SearchText, Success, ErrorMsg, ProcessingTime, SearchResults.Count(), TotalLinesFound);

        if not Success then
            Error(ErrorMsg);

        exit(SearchResults.FindFirst());
    end;

    local procedure AnalyzeContiniaPDF(DocumentCaptureNo: Code[20]): Text
    var
        TempBlob: Codeunit "Temp Blob";
        AzureDocIntelligence: Codeunit "OCR Azure Doc Intelligence";
        InStr: InStream;
        OutStr: OutStream;
    begin
        // Extraer el PDF de Continia Document Capture
        ExtractContiniaDocument(DocumentCaptureNo, TempBlob);

        // Enviar a Azure AI Document Intelligence
        exit(AzureDocIntelligence.AnalyzeDocumentForSearch(TempBlob));
    end;

    local procedure ExtractContiniaDocument(DocumentNo: Code[20]; var TempBlob: Codeunit "Temp Blob")
    var
        DCDocuments: Record "CDC Document";
        TempFile: Record "CDC Temp File" temporary;
        InStr: InStream;
        OutStr: OutStream;
    begin
        // Buscar el documento en Continia
        if not DCDocuments.Get(DocumentNo) then
            Error('Documento no encontrado en Continia: %1', DocumentNo);

        if DCDocuments.HasMiscFile() then
            DCDocuments.GetMiscFile(TempFile);

        TempFile.GetDataStream(InStr);
        // Copiar a TempBlob
        TempBlob.CreateOutStream(OutStr);
        CopyStream(OutStr, InStr);
    end;

    local procedure FindTextInLines(JsonResponse: Text; SearchText: Text; var SearchResults: Record "OCR Search Results" temporary): Integer
    var
        AzureDocIntelligence: Codeunit "OCR Azure Doc Intelligence";
        JsonObject: JsonObject;
        AnalyzeResultToken: JsonToken;
        DocumentsToken: JsonToken;
        DocumentToken: JsonToken;
        FieldsToken: JsonToken;
        ItemsToken: JsonToken;
        ItemToken: JsonToken;
        LineNumber: Integer;
        TotalLines: Integer;
        Description: Text;
        Quantity: Text;
        UnitPrice: Text;
        Amount: Text;
        ProductCode: Text;
        UnitOfMeasure: Text;
        TaxAmount: Text;
        TaxRate: Text;
        MatchFields: Text;
        ConfidenceScore: Decimal;
    begin
        JsonObject.ReadFrom(JsonResponse);
        TotalLines := 0;
        LineNumber := 0;

        // Navegar a las líneas del documento
        if JsonObject.Get('analyzeResult', AnalyzeResultToken) then
            if AnalyzeResultToken.AsObject().Get('documents', DocumentsToken) then
                if DocumentsToken.AsArray().Get(0, DocumentToken) then
                    if DocumentToken.AsObject().Get('fields', FieldsToken) then
                        if FieldsToken.AsObject().Get('Items', ItemsToken) then
                            if ItemsToken.AsObject().Get('valueArray', ItemsToken) then begin

                                foreach ItemToken in ItemsToken.AsArray() do begin
                                    LineNumber += 1;
                                    TotalLines += 1;

                                    // Extraer campos de la línea
                                    Description := AzureDocIntelligence.GetFieldValue(ItemToken, 'Description');
                                    ProductCode := AzureDocIntelligence.GetFieldValue(ItemToken, 'ProductCode');
                                    Quantity := AzureDocIntelligence.GetFieldValue(ItemToken, 'Quantity');
                                    UnitPrice := AzureDocIntelligence.GetFieldValue(ItemToken, 'UnitPrice');
                                    Amount := AzureDocIntelligence.GetFieldValue(ItemToken, 'Amount');
                                    UnitOfMeasure := AzureDocIntelligence.GetFieldValue(ItemToken, 'Unit');
                                    TaxAmount := AzureDocIntelligence.GetFieldValue(ItemToken, 'Tax');
                                    TaxRate := AzureDocIntelligence.GetFieldValue(ItemToken, 'TaxRate');

                                    // Calcular confianza promedio
                                    ConfidenceScore := CalculateAverageConfidence(ItemToken, AzureDocIntelligence);

                                    // Buscar coincidencias (case insensitive)
                                    MatchFields := '';
                                    if ContainsText(Description, SearchText, MatchFields, 'Descripción') or
                                       ContainsText(ProductCode, SearchText, MatchFields, 'Código Producto') or
                                       ContainsText(Quantity, SearchText, MatchFields, 'Cantidad') or
                                       ContainsText(UnitPrice, SearchText, MatchFields, 'Precio Unit.') or
                                       ContainsText(Amount, SearchText, MatchFields, 'Importe') or
                                       ContainsText(UnitOfMeasure, SearchText, MatchFields, 'UM') or
                                       ContainsText(TaxAmount, SearchText, MatchFields, 'IVA') or
                                       ContainsText(TaxRate, SearchText, MatchFields, '% IVA') then begin

                                        // Guardar resultado
                                        SearchResults.Init();
                                        SearchResults."Entry No." := LineNumber;
                                        SearchResults."Line No." := LineNumber;
                                        SearchResults.Description := CopyStr(Description, 1, MaxStrLen(SearchResults.Description));
                                        SearchResults."Product Code" := CopyStr(ProductCode, 1, MaxStrLen(SearchResults."Product Code"));
                                        SearchResults.Quantity := CopyStr(Quantity, 1, MaxStrLen(SearchResults.Quantity));
                                        SearchResults."Unit Price" := CopyStr(UnitPrice, 1, MaxStrLen(SearchResults."Unit Price"));
                                        SearchResults.Amount := CopyStr(Amount, 1, MaxStrLen(SearchResults.Amount));
                                        SearchResults."Unit of Measure" := CopyStr(UnitOfMeasure, 1, MaxStrLen(SearchResults."Unit of Measure"));
                                        SearchResults."Tax Amount" := CopyStr(TaxAmount, 1, MaxStrLen(SearchResults."Tax Amount"));
                                        SearchResults."Tax Rate" := CopyStr(TaxRate, 1, MaxStrLen(SearchResults."Tax Rate"));
                                        SearchResults."Match Found In" := CopyStr(MatchFields, 1, MaxStrLen(SearchResults."Match Found In"));
                                        SearchResults."Confidence Score" := ConfidenceScore;
                                        SearchResults.SetFullLineText();
                                        SearchResults.Insert();
                                    end;
                                end;
                            end;

        exit(TotalLines);
    end;

    local procedure ContainsText(SourceText: Text; SearchText: Text; var MatchFields: Text; FieldName: Text): Boolean
    begin
        if StrPos(UpperCase(SourceText), UpperCase(SearchText)) > 0 then begin
            if MatchFields <> '' then
                MatchFields += ', ';
            MatchFields += FieldName;
            exit(true);
        end;
        exit(false);
    end;

    local procedure CalculateAverageConfidence(ItemToken: JsonToken; AzureDocIntelligence: Codeunit "OCR Azure Doc Intelligence"): Decimal
    var
        TotalConfidence: Decimal;
        FieldCount: Integer;
        ConfValue: Decimal;
    begin
        TotalConfidence := 0;
        FieldCount := 0;

        ConfValue := AzureDocIntelligence.GetFieldConfidence(ItemToken, 'Description');
        if ConfValue > 0 then begin
            TotalConfidence += ConfValue;
            FieldCount += 1;
        end;

        ConfValue := AzureDocIntelligence.GetFieldConfidence(ItemToken, 'Amount');
        if ConfValue > 0 then begin
            TotalConfidence += ConfValue;
            FieldCount += 1;
        end;

        if FieldCount > 0 then
            exit(Round(TotalConfidence / FieldCount, 0.01))
        else
            exit(0);
    end;

    local procedure LogOperation(DocumentNo: Code[20]; SearchText: Text[250]; Success: Boolean; ErrorMsg: Text; ProcessingTime: Integer; ResultsCount: Integer; TotalLines: Integer)
    var
        OCRLog: Record "OCR Operation Log";
    begin
        OCRLog.CreateLogEntry(
            DocumentNo,
            OCRLog."Operation Type"::Search,
            SearchText,
            Success,
            CopyStr(ErrorMsg, 1, 250),
            ProcessingTime,
            ResultsCount,
            TotalLines
        );
    end;

    procedure ExportResultsToExcel(var SearchResults: Record "OCR Search Results" temporary)
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        RowNo: Integer;
    begin
        RowNo := 1;

        // Headers
        TempExcelBuffer.NewRow();
        TempExcelBuffer.AddColumn('Línea', false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn('Descripción', false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn('Código', false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn('Cantidad', false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn('Precio Unit.', false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn('Importe', false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn('Encontrado en', false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn('Confianza %', false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);

        // Data
        if SearchResults.FindSet() then
            repeat
                TempExcelBuffer.NewRow();
                TempExcelBuffer.AddColumn(SearchResults."Line No.", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Number);
                TempExcelBuffer.AddColumn(SearchResults.Description, false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                TempExcelBuffer.AddColumn(SearchResults."Product Code", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                TempExcelBuffer.AddColumn(SearchResults.Quantity, false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                TempExcelBuffer.AddColumn(SearchResults."Unit Price", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                TempExcelBuffer.AddColumn(SearchResults.Amount, false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                TempExcelBuffer.AddColumn(SearchResults."Match Found In", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                TempExcelBuffer.AddColumn(SearchResults."Confidence Score" * 100, false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Number);
            until SearchResults.Next() = 0;

        TempExcelBuffer.CreateNewBook('Resultados Búsqueda OCR');
        TempExcelBuffer.WriteSheet('Resultados', CompanyName, UserId);
        TempExcelBuffer.CloseBook();
        TempExcelBuffer.OpenExcel();
    end;
}
