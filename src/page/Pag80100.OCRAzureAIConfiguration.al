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

            group(Advanced)
            {
                Caption = 'Advanced Settings';

                field("Timeout Seconds"; Rec."Timeout Seconds")
                {
                    ApplicationArea = All;
                    ToolTip = 'Tiempo máximo de espera para la respuesta de Azure AI (en segundos)';
                }
            }

            group(Instructions)
            {
                Caption = 'Instrucciones de Configuración';
                Visible = ShowInstructions;

                field(InstructionsText; InstructionsLbl)
                {
                    ApplicationArea = All;
                    Editable = false;
                    MultiLine = true;
                    ShowCaption = false;
                    Style = StrongAccent;
                    StyleExpr = true;
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

            action(ShowInstructionsAction)
            {
                ApplicationArea = All;
                Caption = 'Show Instructions';
                Image = Info;
                ToolTip = 'Mostrar instrucciones de configuración';

                trigger OnAction()
                begin
                    ShowInstructions := not ShowInstructions;
                    CurrPage.Update(false);
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

        ShowInstructions := (Rec."Endpoint URL" = '') or (Rec."API Key" = '');
    end;

    var
        ShowInstructions: Boolean;
        InstructionsLbl: Label 'PASOS PARA CONFIGURAR AZURE AI DOCUMENT INTELLIGENCE:\1. Crear recurso en Azure Portal (Form Recognizer / Document Intelligence)\2. Copiar el Endpoint URL (ej: https://yourresource.cognitiveservices.azure.com)\3. Copiar una de las API Keys\4. Pegar ambos valores en esta página\5. Presionar "Test Connection" para verificar';
}
