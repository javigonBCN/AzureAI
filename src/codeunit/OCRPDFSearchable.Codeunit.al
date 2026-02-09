//codeunit 80102 "OCR PDF Searchable"
//{
//TODO Referencia luego borrar.
//COPILOT
// procedure MakePdfSearchable(SourcePdfInStream: InStream; var OcrPdfOutStream: OutStream)
// var
//     Client: HttpClient;
//     Req: HttpRequestMessage;
//     Resp: HttpResponseMessage;
//     Headers: HttpHeaders;
//     OperationLocation: Text;
//     PollResp: HttpResponseMessage;
//     StatusJson: Text;
//     Done: Boolean;
//     WaitMs: Integer;
// begin
//     // 1) POST analyze con output=pdf
//     Req.Method := 'POST';
//     Req.SetRequestUri(Endpoint + '/documentintelligence/documentModels/prebuilt-read:analyze?api-version=2024-11-30');
//     Req.Content := SourcePdfInStream; // contenido binario PDF
//     Req.GetHeaders(Headers);
//     Headers.Add('Ocp-Apim-Subscription-Key', ApiKey);
//     Headers.Add('Content-Type', 'application/pdf');
//     Headers.Add('Accept', 'application/json');
//     // parámetro de salida en cabecera o query; en REST es común usar body con 'output': ['pdf'] o query 'output=pdf'
//     Headers.Add('output', 'pdf');

//     Client.Send(Req, Resp);
//     if Resp.HttpStatusCode <> 202 then
//         Error('Analyze: %1 %2', Resp.HttpStatusCode, GetBody(Resp));

//     OperationLocation := Resp.GetHeader('Operation-Location');

//     // 2) Polling hasta succeeded
//     repeat
//         Sleep(2000);
//         Client.Get(OperationLocation, PollResp);
//         StatusJson := GetBody(PollResp);
//         Done := StatusJson.Contains('"status":"succeeded"') or StatusJson.Contains('"status":"failed"');
//     // opcional: leer 'retry-after'
//     until Done;

//     if StatusJson.Contains('"status":"failed"') then
//         Error('El análisis ha fallado: %1', StatusJson);

//     // 3) Descargar el PDF OCR (endpoint de resultado PDF por resultId)
//     // Normalmente Operation-Location termina en .../analyzeResults/{resultId}
//     // Construye URL de descarga PDF si es distinta (v4 expone descarga del PDF generado)
//     Client.Get(OperationLocation + '/pdf', Resp); // según doc/SDK, puede ser este u otro path análogo
//     if Resp.IsSuccessStatusCode() then
//         Resp.Content.ReadAs(OcrPdfOutStream)
//     else
//         Error('Descarga PDF: %1 %2', Resp.HttpStatusCode, GetBody(Resp));
// end;

//}
