codeunit 80110 "OCR PDF Converter"
{

    procedure ProcessDocument(DocumentNo: code[20])
    var
        TempBlob: Codeunit "Temp Blob";
        FileName: text;
    begin
        ExtractContiniaDocument(DocumentNo, TempBlob, FileName);
        ConvertToPDFWithOCR(DocumentNo, TempBlob, FileName);
    end;

    local procedure ExtractContiniaDocument(DocumentNo: Code[20]; var TempBlob: Codeunit "Temp Blob"; var FileName: Text)
    var
        DCDocuments: Record "CDC Document";
        TempFile: Record "CDC Temp File" temporary;
        InStr: InStream;
        OutStr: OutStream;
        NotFoundErr: Label 'Document %1 not found in CDC', Comment = 'ESP="Documento %1 no encontrado en CDC"';
        NotFoundAzureErr: Label 'Attachment Document %1 not found', Comment = 'ESP="Documento adjunto %1 no encontrado en CDC"';
    begin
        // Buscar el documento en Continia
        if not DCDocuments.Get(DocumentNo) then
            Error(NotFoundErr, DocumentNo);

        if DCDocuments.HasMiscFile() then
            DCDocuments.GetMiscFile(TempFile)
        else
            Error(NotFoundAzureErr, DocumentNo);

        FileName := TempFile.Name;
        TempFile.GetDataStream(InStr);
        // Copiar a TempBlob
        TempBlob.CreateOutStream(OutStr);
        CopyStream(OutStr, InStr);
    end;

    procedure ConvertToPDFWithOCR(DocumentNo: Code[20]; var TempBlob: Codeunit "Temp Blob"; FileName: Text): Boolean
    var
        AzureConfig: Record "OCR Azure AI Configuration";
        HttpClient: HttpClient;
        HttpContent: HttpContent;
        Headers: HttpHeaders;
        ResponseHeaders: HttpHeaders;
        HttpResponseMessage: HttpResponseMessage;
        RequestUri: Text;
        OperationLocation: Text;
        HeaderValues: array[100] of Text;
        StartTime: DateTime;
        Success: Boolean;
        ErrorMsg: Text;
        InStr: InStream;
        ConnectionErr: Label 'Error connecting to Azure AI Document Intelligence', Comment = 'ESP="Error al conectar con Azure AI Document Intelligence"';
        OperLocationErr: Label 'No Operation-Location was received from Azure, which is the entity that processes the OCR.', Comment = 'ESP="No se recibió Operation-Location de Azure, que es quien procesa el OCR"';
        AzuErr: Label 'Error in AI Azure: %1 - %2\%3', Comment = 'ESP="Error en Azure AI: %1 - %2\%3"';
        VersionErr: Label 'To generate searchable PDFs, you need API Version 2024-11-30 or higher. Update your settings to the correct version.', Comment = 'ESP="Para generar PDF searchable necesita API Version 2024-11-30 o superior.\Actualice la configuración con la versión correcta."';
    begin
        StartTime := CurrentDateTime;
        Success := false;
        ErrorMsg := '';

        // Validar configuración
        AzureConfig.GetInstance();
        ValidateConfiguration(AzureConfig);

        // Validar versión de API (necesita 2024-11-30 para output=pdf)
        if AzureConfig."API Version PDF Searchable" < '2024-11-30' then
            Error(VersionErr);

        // Preparar el contenido del blob
        TempBlob.CreateInStream(InStr);
        HttpContent.WriteFrom(InStr);
        HttpContent.GetHeaders(Headers);
        Headers.Remove('Content-Type');
        Headers.Add('Content-Type', 'application/octet-stream');
        Headers.Add('Ocp-Apim-Subscription-Key', AzureConfig."API Key");

        // CLAVE: Usar prebuilt-read con output=pdf (API 2024-11-30+)
        // Documentación: https://learn.microsoft.com/azure/ai-services/document-intelligence/
        RequestUri := AzureConfig."Endpoint URL PDF Searchable" +
            '/documentintelligence/documentModels/' + AzureConfig."Model ID PDF Searchable" +
            ':analyze?output=pdf' +  // ← Devuelve PDF con capa de texto searchable
            '&api-version=' + AzureConfig."API Version PDF Searchable";

        // Coger archivo 
        if not HttpClient.Post(RequestUri, HttpContent, HttpResponseMessage) then
            Error(ConnectionErr);

        if not HttpResponseMessage.IsSuccessStatusCode() then begin
            // Leer el body del error para más detalles
            ErrorMsg := GetDetailedErrorMessage(HttpResponseMessage);
            Error(AzuErr, HttpResponseMessage.HttpStatusCode(), HttpResponseMessage.ReasonPhrase(), ErrorMsg);
        end;

        // Verificar que el header existe
        ResponseHeaders := HttpResponseMessage.Headers();

        // Obtener Operation-Location para polling
        if not ResponseHeaders.Contains('Operation-Location') then
            Error(OperLocationErr);

        // Obtener el valor de Operation-Location
        ResponseHeaders.GetValues('Operation-Location', HeaderValues);
        if ArrayLen(HeaderValues) > 0 then
            OperationLocation := HeaderValues[1];

        ClearLastError();
        // Polling y obtención del PDF searchable
        GetSearchablePDF(DocumentNo, OperationLocation, AzureConfig, TempBlob);

        Success := true;
        if GetLastErrorText() <> '' then begin
            ErrorMsg := GetLastErrorText();
            Success := false;
        end;

        // Log (sin JsonResponse ya que obtenemos PDF directamente)
        LogConversion(FileName, StartTime, Success, ErrorMsg);

        exit(Success);
    end;

    local procedure GetSearchablePDF(DocumentNo: Code[20]; OperationUrl: Text; AzureConfig: Record "OCR Azure AI Configuration"; var TempBlob: Codeunit "Temp Blob")
    var
        HttpClient: HttpClient;
        HttpResponseMessage: HttpResponseMessage;
        ContentHeaders: HttpHeaders;
        MaxAttempts: Integer;
        Attempt: Integer;
        ProgressDialog: Dialog;
        Found: Boolean;
        DialogTxt: Label 'Process OCR and generate PDF searchable...\\Attempt #1######## of #2########', Comment = 'ESP="Procesando OCR y generando PDF con OCR...\\Intento #1######## de #2########"';
    begin
        MaxAttempts := AzureConfig."Timeout Seconds" div 2;
        Attempt := 0;
        Found := false;

        HttpClient.DefaultRequestHeaders().Clear();
        HttpClient.DefaultRequestHeaders().Add('Ocp-Apim-Subscription-Key', AzureConfig."API Key");
        HttpClient.DefaultRequestHeaders().Add('Accept', '*/*');

        ProgressDialog.Open(DialogTxt);
        repeat
            Sleep(1000);
            Attempt += 1;

            ProgressDialog.Update(1, Attempt);
            ProgressDialog.Update(2, MaxAttempts);

            if HttpClient.Get(OperationUrl, HttpResponseMessage) then
                if HttpResponseMessage.IsSuccessStatusCode() then begin
                    // Con API 2024-11-30 y output=pdf: Cuando el estado es "succeeded", el Content-Type será application/pdf y el PDF estará directamente en el response body                    
                    HttpResponseMessage.Content().GetHeaders(ContentHeaders);
                    // Si no es PDF todavía, verificar el estado en JSON
                    if CheckIfStillProcessing(HttpResponseMessage) then
                        // Continuar polling
                        continue
                    else
                        // Estado succeeded cogemos el PDF, esta en un Endpoint Directo.
                        if TryDownloadSearchablePdf(DocumentNo, OperationUrl, AzureConfig, TempBlob) then begin
                            ProgressDialog.Close();
                            Found := true;
                            exit;
                        end;
                end;
        until (Attempt >= MaxAttempts) or Found;

        ProgressDialog.Close();

        if not Found then
            Error('Timeout o no se pudo obtener el PDF searchable de Azure AI');
    end;

    local procedure CheckIfStillProcessing(var HttpResponseMessage: HttpResponseMessage): Boolean
    var
        ResponseText: Text;
        JsonObject: JsonObject;
        StatusToken: JsonToken;
        Status: Text;
        AzureAIErr: Label 'OCR processing failed in Azure AI', Comment = 'ESP="El procesamiento OCR falló en Azure AI"';
    begin
        HttpResponseMessage.Content().ReadAs(ResponseText);

        if not JsonObject.ReadFrom(ResponseText) then
            exit(true); // No es JSON válido, seguir esperando

        if not JsonObject.Get('status', StatusToken) then
            exit(true);

        Status := StatusToken.AsValue().AsText();

        case Status of
            'running', 'notStarted':
                exit(true); // Todavía procesando
            'failed':
                Error(AzureAIErr);
            'succeeded':
                exit(false); // Completado
            else
                exit(true);
        end;
    end;

    local procedure TryDownloadSearchablePdf(DocumentNo: Code[20]; OperationUrl: Text; AzureConfig: Record "OCR Azure AI Configuration"; var TempBlob: Codeunit "Temp Blob"): Boolean
    var
        HttpClient: HttpClient;
        HttpResponse: HttpResponseMessage;
        PdfUrl: Text;
        ErrorMsg: Text;
        InStr: InStream;
    begin
        //El resultID lo tenemos incustrado en el OperationUrl, así que borramos todo lo que vaya despues del ?api
        OperationUrl := CopyStr(OperationUrl, 1, StrPos(OperationUrl, '?api-version') - 1);
        // Construye la URL de descarga del PDF Ej: https://{endpoint}/documentintelligence/analyzeResults/{resultId}/pdf?api-version=2024-11-30.
        PdfUrl := OperationUrl + '/pdf?api-version=2024-11-30';

        HttpClient.DefaultRequestHeaders().Clear();
        HttpClient.DefaultRequestHeaders().Add('Ocp-Apim-Subscription-Key', AzureConfig."API Key");
        HttpClient.DefaultRequestHeaders().Add('Accept', '*/*'); // clave para binarios

        if not HttpClient.Get(PdfUrl, HttpResponse) then
            Error('No se pudo conectar al endpoint de descarga PDF.');

        if not HttpResponse.IsSuccessStatusCode() then begin
            ErrorMsg := GetDetailedErrorMessage(HttpResponse);
            Error('Error en Azure AI: %1 - %2\%3', HttpResponse.HttpStatusCode(), HttpResponse.ReasonPhrase(), ErrorMsg);
        end;

        HttpResponse.Content().ReadAs(InStr);
        SaveProcessedPDFToCDC(InStr, DocumentNo);
        //ReplaceOriginalPDFInCDC(InStr, DocumentNo);
        exit(true);
    end;

    local procedure ValidateConfiguration(AzureConfig: Record "OCR Azure AI Configuration")
    var
        ConfigErr: Label 'Azure AI Document Intelligence is disabled. Enable it in the settings.', Comment = 'ESP="Azure AI Document Intelligence está deshabilitado. Habilítelo en la configuración."';
    begin
        if not AzureConfig.Enabled then
            Error(ConfigErr);

        AzureConfig.TestField("Endpoint URL PDF Searchable");
        AzureConfig.TestField("API Version PDF Searchable");
        AzureConfig.TestField("Model ID PDF Searchable");
    end;

    local procedure LogConversion(FileName: Text; StartTime: DateTime; Success: Boolean; ErrorMsg: Text)
    var
        ConversionHistory: Record "OCR Conversion History";
        ProcessingTime: Integer;
    begin
        ProcessingTime := (CurrentDateTime - StartTime) div 1000;

        ConversionHistory.Init();
        ConversionHistory."Conversion DateTime" := CurrentDateTime;
        ConversionHistory."Original Filename" := CopyStr(FileName, 1, MaxStrLen(ConversionHistory."Original Filename"));
        ConversionHistory."File Type" := DetermineFileType(FileName);
        ConversionHistory.Status := GetStatus(Success, ErrorMsg);
        ConversionHistory."Processing Time (sec)" := ProcessingTime;
        ConversionHistory."User ID" := CopyStr(UserId, 1, MaxStrLen(ConversionHistory."User ID"));
        ConversionHistory."Error Message" := CopyStr(ErrorMsg, 1, MaxStrLen(ConversionHistory."Error Message"));
        ConversionHistory."Pages Processed" := 0;
        ConversionHistory."Words Detected" := 0;
        ConversionHistory."Average Confidence" := 0;
        ConversionHistory.Insert(true);
    end;

    local procedure DetermineFileType(FileName: Text): Integer
    var
        Extension: Text;
    begin
        Extension := UpperCase(GetFileExtension(FileName));

        case Extension of
            'PDF':
                exit(0); // PDF
            'JPG', 'JPEG', 'PNG', 'BMP', 'TIFF', 'GIF':
                exit(1); // Image
            else
                exit(1); // Default a Image
        end;
    end;

    local procedure GetFileExtension(FileName: Text): Text
    var
        DotPos: Integer;
    begin
        DotPos := StrPos(FileName, '.');
        if DotPos > 0 then
            exit(CopyStr(FileName, DotPos + 1))
        else
            exit('');
    end;

    local procedure GetStatus(Success: Boolean; ErrorMsg: Text): Integer
    begin
        if Success then
            exit(0) // Success
        else
            if StrPos(ErrorMsg, 'Timeout') > 0 then
                exit(3) // Timeout
            else
                exit(1); // Failed
    end;

    local procedure GetDetailedErrorMessage(var HttpResponseMessage: HttpResponseMessage): Text
    var
        ResponseText: Text;
        JsonObject: JsonObject;
        ErrorToken: JsonToken;
        MessageToken: JsonToken;
    begin
        HttpResponseMessage.Content().ReadAs(ResponseText);
        // Intentar parsear como JSON
        if JsonObject.ReadFrom(ResponseText) then
            // Formato típico de error de Azure: { "error": { "message": "..." } }
            if JsonObject.Get('error', ErrorToken) then
                if ErrorToken.AsObject().Get('innererror', MessageToken) then
                    if ErrorToken.AsObject().Get('message', MessageToken) then
                        exit(MessageToken.AsValue().AsText());
        // Si no es JSON, devolver texto plano
        exit(ResponseText);
    end;

    procedure SaveProcessedPDFToCDC(var ProcessedPDF: InStream; OriginalDocNo: Code[20])
    var
        CDCDocument: Record "CDC Document";
        CDCDocNew: Record "CDC Document";
        TempFile2: Record "CDC Temp File" temporary;
        NotFoundErr: Label 'Document %1 not found in CDC', Comment = 'ESP="Documento %1 no encontrado en CDC"';
    begin
        // Obtener documento original para copiar configuración
        if not CDCDocument.Get(OriginalDocNo) then
            Error(NotFoundErr, OriginalDocNo);

        // Crear nuevo documento CDC basado en el original
        CDCDocNew.Init();
        CDCDocNew.TransferFields(CDCDocument, false);

        // Generar nuevo número
        CDCDocNew."No." := '';
        CDCDocNew.Insert(true);

        // Actualizar descripción
        CDCDocNew.FileName := CopyStr(CDCDocNew.FileName, 1, MaxStrLen(CDCDocNew.FileName));
        CDCDocNew."File Extension" := 'pdf';
        CDCDocNew.Description := CopyStr('(OCR) ' + CDCDocument.Description, 1, MaxStrLen(CDCDocNew.Description));
        // Copiar PDF procesado al campo PDF File
        // CDC usa Azure Blob Storage automáticamente si está configurado
        Clear(CDCDocNew."Misc. File");
        TempFile2.CreateFromStream('', ProcessedPDF);
        CDCDocNew.SetMiscFile(TempFile2);

        //Importar nuevo registro
        CDCDocNew.Modify(true);
        //Borrar antiguo.
        CDCDocument.Delete(TRUE);
    end;

    procedure ReplaceOriginalPDFInCDC(var ProcessedPDF: InStream; DocNo: Code[20])
    var
        CDCDocument: Record "CDC Document";
        TempFile2: Record "CDC Temp File" temporary;
        NotFoundErr: Label 'Document %1 not found in CDC', Comment = 'ESP="Documento %1 no encontrado en CDC"';
    begin
        if not CDCDocument.Get(DocNo) then
            Error(NotFoundErr, DocNo);

        // Reemplazar PDF original con el procesado
        // Azure Blob Storage se actualiza automáticamente
        CDCDocument.Description := CopyStr('(OCR) ' + CDCDocument.Description, 1, MaxStrLen(CDCDocument.Description));
        CDCDocument."File Extension" := 'pdf';
        CDCDocument.ClearMiscFile();
        TempFile2.CreateFromStream('', ProcessedPDF);
        CDCDocument.SetMiscFile(TempFile2);


        // Actualizar timestamp
        CDCDocument.Modify(true);
    end;
}
