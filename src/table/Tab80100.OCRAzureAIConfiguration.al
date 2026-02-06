table 80100 "OCR Azure AI Configuration"
{
    DataClassification = CustomerContent;
    Caption = 'Azure AI Configuration';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            DataClassification = SystemMetadata;
            Caption = 'Primary Key';
        }
        field(2; "Endpoint URL"; Text[250])
        {
            DataClassification = CustomerContent;
            Caption = 'Azure Endpoint URL';
            ToolTip = 'URL del endpoint de Azure AI Document Intelligence (ej: https://yourresource.cognitiveservices.azure.com)';

            trigger OnValidate()
            begin
                if "Endpoint URL" <> '' then
                    "Endpoint URL" := DelChr("Endpoint URL", '>', '/');
            end;
        }
        field(3; "API Key"; Text[100])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'API Key';
            ExtendedDatatype = Masked;
            ToolTip = 'API Key de Azure AI Document Intelligence';
        }
        field(4; "Model ID"; Text[50])
        {
            DataClassification = CustomerContent;
            Caption = 'Document Model ID';
            InitValue = 'prebuilt-invoice';
            ToolTip = 'ID del modelo a utilizar (prebuilt-invoice, prebuilt-receipt, o modelo personalizado)';
        }
        field(5; "API Version"; Text[20])
        {
            DataClassification = CustomerContent;
            Caption = 'API Version';
            InitValue = '2023-07-31';
            ToolTip = 'Versión de la API de Azure AI Document Intelligence';
        }
        field(6; "Timeout Seconds"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Timeout (seconds)';
            InitValue = 120;
            MinValue = 30;
            MaxValue = 300;
            ToolTip = 'Tiempo máximo de espera para la respuesta de Azure AI';
        }
        field(7; Enabled; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Enabled';
            InitValue = true;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    procedure GetInstance(var AzureConfig: Record "OCR Azure AI Configuration")
    begin
        if not AzureConfig.Get() then begin
            AzureConfig.Init();
            AzureConfig."Primary Key" := '';
            AzureConfig.Insert();
        end;
    end;

    procedure TestConnection(): Boolean
    var
        HttpClient: HttpClient;
        HttpResponseMessage: HttpResponseMessage;
        RequestUri: Text;
    begin
        if ("Endpoint URL" = '') or ("API Key" = '') then
            Error('Debe configurar el Endpoint y API Key antes de probar la conexión');

        RequestUri := "Endpoint URL" + '/formrecognizer/info?api-version=' + "API Version";

        HttpClient.DefaultRequestHeaders.Clear();
        HttpClient.DefaultRequestHeaders.Add('Ocp-Apim-Subscription-Key', "API Key");

        if HttpClient.Get(RequestUri, HttpResponseMessage) then begin
            if HttpResponseMessage.IsSuccessStatusCode then begin
                Message('Conexión exitosa con Azure AI Document Intelligence');
                exit(true);
            end else
                Error('Error al conectar: %1 - %2', HttpResponseMessage.HttpStatusCode, HttpResponseMessage.ReasonPhrase);
        end else
            Error('No se pudo establecer conexión con Azure AI');

        exit(false);
    end;
}
