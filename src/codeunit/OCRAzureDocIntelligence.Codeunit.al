codeunit 80100 "OCR Azure Doc Intelligence"
{
    procedure AnalyzeDocumentForSearch(var TempBlob: Codeunit "Temp Blob"): Text
    var
        AzureConfig: Record "OCR Azure AI Configuration";
        HttpClient: HttpClient;
        HttpContent: HttpContent;
        Headers: HttpHeaders;
        ResponseHeaders: HttpHeaders;
        HttpResponseMessage: HttpResponseMessage;
        InStr: InStream;
        RequestUri: Text;
        ResponseText: Text;
        HeaderValues: array[100] of Text;
        OperationLocation: Text;
        ConnectionErr: Label 'Error connecting to Azure AI Document Intelligence', Comment = 'ESP="Error al conectar con Azure AI Document Intelligence"';
        OperLocationErr: Label 'No Operation-Location was received from Azure, which is the entity that processes the OCR.', Comment = 'ESP="No se recibió Operation-Location de Azure, que es quien procesa el OCR"';
    begin
        // Validar configuración
        AzureConfig.GetInstance();
        ValidateConfiguration(AzureConfig);

        // Preparar el contenido del blob
        TempBlob.CreateInStream(InStr);
        HttpContent.WriteFrom(InStr);
        HttpContent.GetHeaders(Headers);
        Headers.Remove('Content-Type');
        Headers.Add('Content-Type', 'application/octet-stream');
        Headers.Add('Ocp-Apim-Subscription-Key', AzureConfig."API Key");

        // Configurar request
        RequestUri := AzureConfig."Endpoint URL" +
            '/formrecognizer/documentModels/' + AzureConfig."Model ID" +
            ':analyze?api-version=' + AzureConfig."API Version";

        // Enviar a Azure
        if not HttpClient.Post(RequestUri, HttpContent, HttpResponseMessage) then
            Error(ConnectionErr);

        if not HttpResponseMessage.IsSuccessStatusCode() then
            Error('Error en Azure AI: %1 - %2', HttpResponseMessage.HttpStatusCode(), HttpResponseMessage.ReasonPhrase());

        // Verificar que el header existe
        ResponseHeaders := HttpResponseMessage.Headers();

        if not ResponseHeaders.Contains('Operation-Location') then
            Error(OperLocationErr);

        // Obtener el valor de Operation-Location
        ResponseHeaders.GetValues('Operation-Location', HeaderValues);
        if ArrayLen(HeaderValues) > 0 then
            OperationLocation := HeaderValues[1];

        // Esperar y obtener resultados
        ResponseText := WaitForAnalysisResults(OperationLocation, AzureConfig);

        exit(ResponseText);
    end;

    local procedure WaitForAnalysisResults(OperationUrl: Text; AzureConfig: Record "OCR Azure AI Configuration"): Text
    var
        HttpClient: HttpClient;
        HttpResponseMessage: HttpResponseMessage;
        ResponseText: Text;
        JsonResponse: JsonObject;
        StatusToken: JsonToken;
        MaxAttempts: Integer;
        Attempt: Integer;
        Status: Text;
        ProgressDialog: Dialog;
        AnylisisErr: Label 'The document analysis failed in Azure AI.', Comment = 'ESP="El análisis del documento falló en Azure AI"';
        TimeoutErr: Label 'Timeout waiting for a response from Azure AI. Please try again or increase the timeout in the settings.', Comment = 'ESP="Timeout esperando respuesta de Azure AI. Intente nuevamente o aumente el timeout en la configuración."';
        DialogTxt: Label 'Processing document with Azure AI...\\Attempt #1######## of #2########', Comment = 'ESP="Procesando documento con Azure AI...\\Intento #1######## de #2########"';
    begin
        MaxAttempts := AzureConfig."Timeout Seconds" div 2;
        Attempt := 0;

        ProgressDialog.Open(DialogTxt);

        HttpClient.DefaultRequestHeaders().Clear();
        HttpClient.DefaultRequestHeaders().Add('Ocp-Apim-Subscription-Key', AzureConfig."API Key");
        repeat
            Sleep(2000); // Esperar 2 segundos entre intentos
            Attempt += 1;

            ProgressDialog.Update(1, Attempt);
            ProgressDialog.Update(2, MaxAttempts);

            if HttpClient.Get(OperationUrl, HttpResponseMessage) then
                if HttpResponseMessage.IsSuccessStatusCode() then begin
                    HttpResponseMessage.Content().ReadAs(ResponseText);
                    if JsonResponse.ReadFrom(ResponseText) then
                        if JsonResponse.Get('status', StatusToken) then begin
                            Status := StatusToken.AsValue().AsText();
                            if Status = 'succeeded' then
                                exit(ResponseText)
                            else
                                if Status = 'failed' then
                                    Error(AnylisisErr);
                        end;
                end;
        until Attempt >= MaxAttempts;

        Error(TimeoutErr);
    end;

    local procedure ValidateConfiguration(AzureConfig: Record "OCR Azure AI Configuration")
    var
        ConfigErr: Label 'Azure AI Document Intelligence is disabled. Enable it in the settings.', Comment = 'ESP="Azure AI Document Intelligence está deshabilitado. Habilítelo en la configuración."';
    begin
        if not AzureConfig.Enabled then
            Error(ConfigErr);

        AzureConfig.TestField("Endpoint URL");
        AzureConfig.TestField("API Key");
        AzureConfig.TestField("Model ID");
    end;

    procedure ExtractBlobFromStream(var InStr: InStream; var TempBlob: Codeunit "Temp Blob")
    var
        OutStr: OutStream;
    begin
        TempBlob.CreateOutStream(OutStr);
        CopyStream(OutStr, InStr);
    end;

    procedure GetFieldValue(ItemToken: JsonToken; FieldName: Text): Text
    var
        ValueObjectToken: JsonToken;
        FieldToken: JsonToken;
        ContentToken: JsonToken;
    begin
        if ItemToken.AsObject().Get('valueObject', ValueObjectToken) then
            if ValueObjectToken.AsObject().Get(FieldName, FieldToken) then
                if FieldToken.AsObject().Get('content', ContentToken) then
                    exit(ContentToken.AsValue().AsText());
        exit('');
    end;

    procedure GetFieldConfidence(ItemToken: JsonToken; FieldName: Text): Decimal
    var
        ValueObjectToken: JsonToken;
        FieldToken: JsonToken;
        ConfidenceToken: JsonToken;
        ConfidenceValue: Decimal;
    begin
        if ItemToken.AsObject().Get('valueObject', ValueObjectToken) then
            if ValueObjectToken.AsObject().Get(FieldName, FieldToken) then
                if FieldToken.AsObject().Get('confidence', ConfidenceToken) then
                    if Evaluate(ConfidenceValue, Format(ConfidenceToken.AsValue().AsDecimal())) then
                        exit(ConfidenceValue);
        exit(0);
    end;
}
