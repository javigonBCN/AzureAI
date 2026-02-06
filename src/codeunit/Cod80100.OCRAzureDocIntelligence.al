codeunit 80100 "OCR Azure Doc Intelligence"
{
    procedure AnalyzeDocumentForSearch(var TempBlob: Codeunit "Temp Blob"): Text
    var
        AzureConfig: Record "OCR Azure AI Configuration";
        HttpClient: HttpClient;
        HttpContent: HttpContent;
        Headers: HttpHeaders;
        HttpResponseMessage: HttpResponseMessage;
        InStr: InStream;
        RequestUri: Text;
        ResponseText: Text;
        OperationLocation: Text;
        StartTime: DateTime;
    begin
        StartTime := CurrentDateTime;

        // Validar configuración
        AzureConfig.GetInstance(AzureConfig);
        ValidateConfiguration(AzureConfig);

        // Preparar el contenido del PDF
        TempBlob.CreateInStream(InStr);
        HttpContent.WriteFrom(InStr);
        Headers.Clear();
        Headers.Add('Content-Type', 'application/pdf');
        Headers.Add('Ocp-Apim-Subscription-Key', AzureConfig."API Key");

        // Configurar request
        RequestUri := AzureConfig."Endpoint URL" +
            '/formrecognizer/documentModels/' + AzureConfig."Model ID" +
            ':analyze?api-version=' + AzureConfig."API Version";

        // Enviar a Azure
        if not HttpClient.Post(RequestUri, HttpContent, HttpResponseMessage) then
            Error('Error al conectar con Azure AI Document Intelligence');

        if not HttpResponseMessage.IsSuccessStatusCode() then
            Error('Error en Azure AI: %1 - %2', HttpResponseMessage.HttpStatusCode(), HttpResponseMessage.ReasonPhrase());

        // Obtener Operation-Location para polling
        //TODO Tratar Json
        // if not HttpResponseMessage.Headers().ContainsKey('Operation-Location') then
        //     Error('No se recibió Operation-Location de Azure');

        // HttpResponseMessage.Headers().GetValues('Operation-Location', OperationLocation);

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
    begin
        MaxAttempts := AzureConfig."Timeout Seconds" div 2;
        Attempt := 0;

        HttpClient.DefaultRequestHeaders().Clear();
        HttpClient.DefaultRequestHeaders().Add('Ocp-Apim-Subscription-Key', AzureConfig."API Key");
        repeat
            Sleep(2000); // Esperar 2 segundos entre intentos
            Attempt += 1;

            ProgressDialog.Update(1, Attempt);
            ProgressDialog.Update(2, MaxAttempts);

            if HttpClient.Get(OperationUrl, HttpResponseMessage) then begin
                if HttpResponseMessage.IsSuccessStatusCode() then begin
                    HttpResponseMessage.Content().ReadAs(ResponseText);
                    if JsonResponse.ReadFrom(ResponseText) then begin
                        if JsonResponse.Get('status', StatusToken) then begin
                            Status := StatusToken.AsValue().AsText();
                            if Status = 'succeeded' then
                                exit(ResponseText)
                            else if Status = 'failed' then
                                Error('El análisis del documento falló en Azure AI');
                        end;
                    end;
                end;
            end;
        until Attempt >= MaxAttempts;

        Error('Timeout esperando respuesta de Azure AI. Intente nuevamente o aumente el timeout en la configuración.');
    end;

    local procedure ValidateConfiguration(AzureConfig: Record "OCR Azure AI Configuration")
    begin
        if not AzureConfig.Enabled then
            Error('Azure AI Document Intelligence está deshabilitado. Habilítelo en la configuración.');

        if AzureConfig."Endpoint URL" = '' then
            Error('Debe configurar el Endpoint URL de Azure AI');

        if AzureConfig."API Key" = '' then
            Error('Debe configurar la API Key de Azure AI');

        if AzureConfig."Model ID" = '' then
            Error('Debe especificar un Model ID');
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
