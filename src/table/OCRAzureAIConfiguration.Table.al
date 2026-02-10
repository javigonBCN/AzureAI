table 80100 "OCR Azure AI Configuration"
{
    DataClassification = CustomerContent;
    Caption = 'Azure AI Configuration';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            DataClassification = SystemMetadata;
            Caption = 'Primary Key', Comment = 'ESP="Clave Primaria"';
        }
        field(2; "Endpoint URL"; Text[250])
        {
            DataClassification = CustomerContent;
            Caption = 'Azure Endpoint URL', Comment = 'ESP="Azure Endpoint URL"';
            ToolTip = 'Azure AI Document Intelligence endpoint URL (ex: https://yourresource.cognitiveservices.azure.com)', Comment = 'ESP="URL del endpoint de Azure AI Document Intelligence (ej: https://yourresource.cognitiveservices.azure.com)"';

            trigger OnValidate()
            begin
                if "Endpoint URL" <> '' then
                    "Endpoint URL" := DelChr("Endpoint URL", '>', '/');
            end;
        }
        field(3; "API Key"; Text[100])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'API Key', Comment = 'ESP="API Key"';
            ExtendedDatatype = Masked;
            ToolTip = 'Azure AI Document Intelligence API Key', Comment = 'ESP="API Key de Azure AI Document Intelligence"';
        }
        field(4; "Model ID"; Text[50])
        {
            DataClassification = CustomerContent;
            Caption = 'Document Model ID', Comment = 'ESP="ID Modelo documento"';
            InitValue = 'prebuilt-invoice';
            ToolTip = 'ID of the model to use (prebuilt-invoice, prebuilt-receipt, or custom model)', Comment = 'ESP="ID del modelo a utilizar (prebuilt-invoice, prebuilt-receipt, o modelo personalizado)"';
        }
        field(5; "API Version"; Text[20])
        {
            DataClassification = CustomerContent;
            Caption = 'API Version', Comment = 'ESP="API Versión"';
            InitValue = '2023-07-31';
            ToolTip = 'Azure AI Document Intelligence API Version', Comment = 'ESP="Versión de la API de Azure AI Document Intelligence"';
        }
        field(6; "Timeout Seconds"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Timeout (seconds)', Comment = 'ESP="Tiempo de espera (segundos)"';
            InitValue = 120;
            MinValue = 30;
            MaxValue = 300;
            ToolTip = 'Maximum wait time for Azure AI response', Comment = 'ESP="Tiempo máximo de espera para la respuesta de Azure AI"';
        }
        field(7; Enabled; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Enabled', Comment = 'ESP="Habilitado"';
            InitValue = true;
        }
        field(10; "Endpoint URL PDF Searchable"; Text[250])
        {
            DataClassification = CustomerContent;
            Caption = 'Endpoint URL PDF Searchable';
            ToolTip = 'URL del endpoint de Azure AI Document Intelligence';

            trigger OnValidate()
            begin
                if "Endpoint URL PDF Searchable" <> '' then
                    "Endpoint URL PDF Searchable" := DelChr("Endpoint URL PDF Searchable", '>', '/');
            end;
        }
        field(11; "Model ID PDF Searchable"; Text[50])
        {
            DataClassification = CustomerContent;
            Caption = 'Document Model ID PDF Searchable', Comment = 'ESP="ID Modelo documento PDF OCR"';
            InitValue = 'prebuilt-read';
            ToolTip = 'ID of the model to use (prebuilt-read or custom model)', Comment = 'ESP="ID del modelo a utilizar (prebuilt-read o modelo personalizado)"';
        }
        field(12; "API Version PDF Searchable"; Text[20])
        {
            DataClassification = CustomerContent;
            Caption = 'API Version PDF Searchable', Comment = 'ESP="API Versión PDF Searchable"';
            InitValue = '2024-11-30';
            ToolTip = 'Azure AI Document Intelligence API Version', Comment = 'ESP="Versión de la API de Azure AI Document Intelligence"';
        }
        field(13; "Output Format"; Option)
        {
            DataClassification = CustomerContent;
            Caption = 'Output Format', Comment = 'ESP="Formato de salida"';
            OptionMembers = PDF,PDFA;
            OptionCaption = 'PDF,PDF/A (Archival)';
            InitValue = PDF;
            ToolTip = 'Formato del PDF de salida (PDF estándar o PDF/A para archivo)';
        }
        field(15; "Auto Download"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Auto Download After Processing', Comment = 'ESP="Autodescarga despues de proceso"';
            InitValue = true;
            ToolTip = 'Descargar automáticamente el archivo procesado';
        }

    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    procedure GetInstance()
    begin
        if not Rec.Get() then begin
            Rec.Init();
            Rec."Primary Key" := '';
            Rec.Insert();
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
