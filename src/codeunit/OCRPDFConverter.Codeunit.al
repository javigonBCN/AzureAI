codeunit 80110 "OCR PDF Converter"
{

    procedure ProcessDocument(DocumentNo: code[20])
    var
        TempBlob: Codeunit "Temp Blob";
        FileName: text;
    begin
        ExtractContiniaDocument(DocumentNo, TempBlob, FileName);
        ConvertToPDFWithOCR(TempBlob);
    end;

    local procedure ExtractContiniaDocument(DocumentNo: Code[20]; var TempBlob: Codeunit "Temp Blob"; var FileName: Text)
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

        FileName := TempFile.Name;
        TempFile.GetDataStream(InStr);
        // Copiar a TempBlob
        TempBlob.CreateOutStream(OutStr);
        CopyStream(OutStr, InStr);
    end;

    procedure ConvertToPDFWithOCR(var TempBlob: Codeunit "Temp Blob"): Boolean
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
        OutStr: OutStream;
        OutputFile: OutStream;
        ConnectionErr: Label 'Error connecting to Azure AI Document Intelligence', Comment = 'ESP="Error al conectar con Azure AI Document Intelligence"';
        OperLocationErr: Label 'No Operation-Location was received from Azure, which is the entity that processes the OCR.', Comment = 'ESP="No se recibió Operation-Location de Azure, que es quien procesa el OCR"';
    begin
        StartTime := CurrentDateTime;
        Success := false;
        ErrorMsg := '';

        // Validar configuración
        AzureConfig.GetInstance();
        ValidateConfiguration(AzureConfig);

        // Validar versión de API (necesita 2024-11-30 para output=pdf)
        if AzureConfig."API Version PDF Searchable" < '2024-11-30' then
            Error('Para generar PDF searchable necesita API Version 2024-11-30 o superior.\' +
                  'Actualice la configuración con la versión correcta.');

        // Preparar el contenido del blob
        TempBlob.CreateInStream(InStr);
        HttpContent.WriteFrom(InStr);
        //HttpContent.WriteFrom(CreateBase64JsonPayload(InStr));
        HttpContent.GetHeaders(Headers);
        Headers.Remove('Content-Type');
        Headers.Add('Content-Type', 'application/octet-stream');
        Headers.Add('Ocp-Apim-Subscription-Key', AzureConfig."API Key");

        // CLAVE: Usar prebuilt-read con output=pdf (API 2024-11-30+)
        // Documentación: https://learn.microsoft.com/azure/ai-services/document-intelligence/
        RequestUri := AzureConfig."Endpoint URL PDF Searchable" +
            '/documentintelligence/documentModels/prebuilt-read:analyze' +
            '?output=pdf' +  // ← Devuelve PDF con capa de texto searchable
            '&api-version=' + AzureConfig."API Version PDF Searchable";

        //TODO Repe
        // HttpClient.DefaultRequestHeaders().Clear();
        // HttpClient.DefaultRequestHeaders().Add('Ocp-Apim-Subscription-Key', Config."API Key");

        // Enviar archivo a Azure
        if not HttpClient.Post(RequestUri, HttpContent, HttpResponseMessage) then
            Error(ConnectionErr);

        if not HttpResponseMessage.IsSuccessStatusCode() then begin
            // Leer el body del error para más detalles
            ErrorMsg := GetDetailedErrorMessage(HttpResponseMessage);
            Error('Error en Azure AI: %1 - %2\%3',
                HttpResponseMessage.HttpStatusCode(),
                HttpResponseMessage.ReasonPhrase(),
                ErrorMsg);
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
        GetSearchablePDF(OperationLocation, AzureConfig, OutputFile);

        Success := true;
        if GetLastErrorText() <> '' then begin
            ErrorMsg := GetLastErrorText();
            Success := false;
        end;

        // Log (sin JsonResponse ya que obtenemos PDF directamente)
        //LogConversion(FileName, StartTime, Success, ErrorMsg);

        exit(Success);
    end;

    local procedure GetSearchablePDF(OperationUrl: Text; AzureConfig: Record "OCR Azure AI Configuration"; var OutputPDF: OutStream)
    var
        HttpClient: HttpClient;
        HttpResponseMessage: HttpResponseMessage;
        ContentHeaders: HttpHeaders;
        MaxAttempts: Integer;
        Attempt: Integer;
        ContentType: array[100] of Text;
        Document: Text;
        InStr: InStream;
        ProgressDialog: Dialog;
        Found: Boolean;
    begin
        MaxAttempts := AzureConfig."Timeout Seconds" div 2;
        Attempt := 0;
        Found := false;

        HttpClient.DefaultRequestHeaders().Clear();
        HttpClient.DefaultRequestHeaders().Add('Ocp-Apim-Subscription-Key', AzureConfig."API Key");
        HttpClient.DefaultRequestHeaders().Add('Accept', '*/*');

        ProgressDialog.Open('Procesando OCR y generando PDF searchable...\\Intento #1######## de #2########');
        repeat
            Sleep(1000);
            Attempt += 1;

            ProgressDialog.Update(1, Attempt);
            ProgressDialog.Update(2, MaxAttempts);

            if HttpClient.Get(OperationUrl, HttpResponseMessage) then
                if HttpResponseMessage.IsSuccessStatusCode() then begin
                    // Con API 2024-11-30 y output=pdf: Cuando el estado es "succeeded", el Content-Type será application/pdf y el PDF estará directamente en el response body                    
                    HttpResponseMessage.Content().GetHeaders(ContentHeaders);
                    //if ContentHeaders.TryGetValues('Content-Type', ContentType) then
                    // Obtener Operation-Location para polling
                    if not ContentHeaders.Contains('Content-Type') then
                        Error('No tiene content-type');
                    // Obtener el valor de Operation-Location
                    if ContentHeaders.GetValues('Content-Type', ContentType) then begin
                        if ArrayLen(ContentType) > 0 then
                            Document := ContentType[1];
                        if StrPos(Document, 'application/pdf') > 0 then begin
                            // ¡PDF encontrado en el body!
                            ProgressDialog.Close();
                            HttpResponseMessage.Content().ReadAs(InStr);
                            CopyStream(OutputPDF, InStr);
                            Found := true;
                            exit;
                        end;
                    end;
                    // Si no es PDF todavía, verificar el estado en JSON
                    if CheckIfStillProcessing(HttpResponseMessage) then
                        // Continuar polling
                        continue
                    else
                        // Estado succeeded pero no encontramos PDF
                        // Intentar extraer de JSON
                        if TryExtractPdfFromJson(HttpResponseMessage, OutputPDF) then begin
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

    local procedure CheckIfStillProcessing(var
                                               HttpResponseMessage: HttpResponseMessage): Boolean
    var
        ResponseText: Text;
        JsonObject: JsonObject;
        StatusToken: JsonToken;
        Status: Text;
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
                Error('El procesamiento OCR falló en Azure AI');
            'succeeded':
                exit(false); // Completado
            else
                exit(true);
        end;
    end;

    local procedure TryExtractPdfFromJson(var HttpResponseMessage: HttpResponseMessage; var OutputPDF: OutStream): Boolean
    var
        ResponseText: Text;
        JsonObject: JsonObject;
        PdfToken: JsonToken;
        Base64Content: Text;
    begin
        HttpResponseMessage.Content().ReadAs(ResponseText);

        if not JsonObject.ReadFrom(ResponseText) then
            exit(false);

        // Buscar PDF en diferentes ubicaciones posibles
        // Ubicación 1: campo "pdf" directo
        if JsonObject.Get('pdf', PdfToken) then begin
            Base64Content := PdfToken.AsValue().AsText();
            ConvertBase64ToPdf(Base64Content, OutputPDF);
            exit(true);
        end;

        // Ubicación 2: analyzeResult.pdf
        if JsonObject.Get('analyzeResult', PdfToken) then
            if PdfToken.AsObject().Get('pdf', PdfToken) then begin
                Base64Content := PdfToken.AsValue().AsText();
                ConvertBase64ToPdf(Base64Content, OutputPDF);
                exit(true);
            end;

        exit(false);
    end;

    local procedure ConvertBase64ToPdf(Base64Content: Text; var OutputPDF: OutStream)
    var
        Base64Convert: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
    begin
        TempBlob.CreateOutStream(OutStr);
        Base64Convert.FromBase64(Base64Content, OutStr);
        TempBlob.CreateInStream(InStr);
        CopyStream(OutputPDF, InStr);
    end;

    local procedure ValidateConfiguration(AzureConfig: Record "OCR Azure AI Configuration")
    var
        ConfigErr: Label 'Azure AI Document Intelligence is disabled. Enable it in the settings.', Comment = 'ESP="Azure AI Document Intelligence está deshabilitado. Habilítelo en la configuración."';
    begin
        if not AzureConfig.Enabled then
            Error(ConfigErr);

        AzureConfig.TestField("Endpoint URL PDF Searchable");
        AzureConfig.TestField("API Key");
        //TODO 
        //AzureConfig.TestField("Model ID");
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

        // Nota: No podemos extraer estadísticas detalladas cuando usamos output=pdf
        // ya que no recibimos el JSON con la info de páginas/palabras
        // Solo recibimos el PDF searchable
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

    local procedure CreateBase64JsonPayload(var FileStream: InStream): Text
    var
        Base64Convert: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        Base64String: Text;
        JsonObject: JsonObject;
        JsonText: Text;
        OutStr: OutStream;
    begin
        Base64String := Base64Convert.ToBase64(FileStream);

        // Crear JSON payload según Azure Document Intelligence API
        // Formato: { "base64Source": "data:application/pdf;base64,JVBERi0xLj..." }
        JsonObject.Add('base64Source', Base64String);
        JsonObject.WriteTo(JsonText);
        exit(JsonText);
    end;
}
