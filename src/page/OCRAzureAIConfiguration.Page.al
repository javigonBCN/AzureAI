page 80100 "OCR Azure AI Configuration"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "OCR Azure AI Configuration";
    Caption = 'Azure AI Document Intelligence Configuration';
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                    ToolTip = 'Habilitar o deshabilitar la integración con Azure AI';
                }
            }

            group(AzureSettings)
            {
                Caption = 'Azure Settings';

                field("Endpoint URL"; Rec."Endpoint URL")
                {
                    ApplicationArea = All;
                    ToolTip = 'URL del endpoint de Azure AI Document Intelligence';
                    ShowMandatory = true;

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }

                field("API Key"; Rec."API Key")
                {
                    ApplicationArea = All;
                    ToolTip = 'API Key de Azure AI Document Intelligence';
                    ShowMandatory = true;
                    ExtendedDatatype = Masked;

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }

                field("Model ID"; Rec."Model ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'ID del modelo a utilizar (prebuilt-invoice, prebuilt-receipt, o un modelo personalizado)';
                }

                field("API Version"; Rec."API Version")
                {
                    ApplicationArea = All;
                    ToolTip = 'Versión de la API de Azure AI';
                }
            }
            group(Download)
            {

                Caption = 'Download PDF OCR', Comment = 'ESP="Descarga PDF OCR"';
                field("Endpoint URL PDF Searchable"; Rec."Endpoint URL PDF Searchable")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                    ToolTip = 'URL del endpoint de Azure AI Document Intelligence';
                }

                field("API Key PDF OCR"; Rec."API Key")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                    ExtendedDatatype = Masked;
                    ToolTip = 'API Key de Azure AI Document Intelligence';
                }

                field("API Version PDF Searchable"; Rec."API Version PDF Searchable")
                {
                    ApplicationArea = All;
                    ToolTip = 'Versión de la API de Azure AI';
                }

                field("Auto Download"; Rec."Auto Download")
                {
                    ApplicationArea = All;
                    ToolTip = 'Descargar automáticamente el PDF después de procesar';
                }

                field("Output Format"; Rec."Output Format")
                {
                    ApplicationArea = All;
                    ToolTip = 'Formato del PDF de salida';
                }
            }

            group(Advanced)
            {
                Caption = 'Advanced Settings';

                field("Timeout Seconds"; Rec."Timeout Seconds")
                {
                    ApplicationArea = All;
                    ToolTip = 'Tiempo máximo de espera para la respuesta de Azure AI (en segundos)';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(TestConnection)
            {
                ApplicationArea = All;
                Caption = 'Test Connection';
                Image = TestDatabase;
                ToolTip = 'Probar la conexión con Azure AI Document Intelligence';

                trigger OnAction()
                begin
                    Rec.TestConnection();
                end;
            }
            action(OpenAzurePortal)
            {
                ApplicationArea = All;
                Caption = 'Open Azure Portal';
                Image = Web;
                ToolTip = 'Abrir el portal de Azure';

                trigger OnAction()
                begin
                    Hyperlink('https://portal.azure.com/#view/Microsoft_Azure_ProjectOxford/CognitiveServicesHub/~/FormRecognizer');
                end;
            }
        }

        area(Navigation)
        {
            action(ViewOperationLog)
            {
                ApplicationArea = All;
                Caption = 'Operation Log';
                Image = Log;
                ToolTip = 'Ver el registro de operaciones OCR';
                RunObject = Page "OCR Operation Log";
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec."Primary Key" := '';
            Rec.Insert();
        end;
    end;
}
