page 80104 "OCR Result Detail FactBox"
{
    PageType = CardPart;
    SourceTable = "OCR Search Results";
    Caption = 'Detalle de Línea';

    layout
    {
        area(Content)
        {
            group(Details)
            {
                Caption = 'Información de la Línea';

                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = ' ', Comment = 'ESP=" "';
                    Style = Strong;
                    StyleExpr = true;
                }

                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = ' ', Comment = 'ESP=" "';
                    MultiLine = true;
                }

                field("Product Code"; Rec."Product Code")
                {
                    ApplicationArea = All;
                    ToolTip = ' ', Comment = 'ESP=" "';
                }
            }

            group(Amounts)
            {
                Caption = 'Importes';

                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                    ToolTip = ' ', Comment = 'ESP=" "';
                }

                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = All;
                    ToolTip = ' ', Comment = 'ESP=" "';
                }

                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = All;
                    ToolTip = ' ', Comment = 'ESP=" "';
                }

                field(Amount; Rec.Amount)
                {
                    ApplicationArea = All;
                    ToolTip = ' ', Comment = 'ESP=" "';
                    Style = Strong;
                    StyleExpr = true;
                }

                field("Tax Rate"; Rec."Tax Rate")
                {
                    ApplicationArea = All;
                    ToolTip = ' ', Comment = 'ESP=" "';
                }

                field("Tax Amount"; Rec."Tax Amount")
                {
                    ApplicationArea = All;
                    ToolTip = ' ', Comment = 'ESP=" "';
                }
            }

            group(MatchInfo)
            {
                Caption = 'Información de Coincidencia';

                field("Match Found In"; Rec."Match Found In")
                {
                    ApplicationArea = All;
                    ToolTip = ' ', Comment = 'ESP=" "';
                    Style = Attention;
                    StyleExpr = true;
                }

                field("Confidence Score"; ConfidencePercentage)
                {
                    ApplicationArea = All;
                    Caption = 'Nivel de Confianza';
                    ToolTip = ' ', Comment = 'ESP=" "';
                    Style = Favorable;
                    StyleExpr = Rec."Confidence Score" >= 0.90;
                }
            }

            group(FullText)
            {
                Caption = 'Texto Completo';

                field("Full Line Text"; Rec."Full Line Text")
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    ShowCaption = false;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        ConfidencePercentage := StrSubstNo('%1%', Round(Rec."Confidence Score" * 100, 0.01));
    end;

    var
        ConfidencePercentage: Text;
}
