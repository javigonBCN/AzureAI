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
                    Style = Strong;
                    StyleExpr = true;
                }

                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    MultiLine = true;
                }

                field("Product Code"; Rec."Product Code")
                {
                    ApplicationArea = All;
                }
            }

            group(Amounts)
            {
                Caption = 'Importes';

                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                }

                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = All;
                }

                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = All;
                }

                field(Amount; Rec.Amount)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    StyleExpr = true;
                }

                field("Tax Rate"; Rec."Tax Rate")
                {
                    ApplicationArea = All;
                }

                field("Tax Amount"; Rec."Tax Amount")
                {
                    ApplicationArea = All;
                }
            }

            group(MatchInfo)
            {
                Caption = 'Información de Coincidencia';

                field("Match Found In"; Rec."Match Found In")
                {
                    ApplicationArea = All;
                    Style = Attention;
                    StyleExpr = true;
                }

                field("Confidence Score"; ConfidencePercentage)
                {
                    ApplicationArea = All;
                    Caption = 'Nivel de Confianza';
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
