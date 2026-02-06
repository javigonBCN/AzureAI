page 80101 "OCR Search Results"
{
    PageType = List;
    SourceTable = "OCR Search Results";
    SourceTableTemporary = true;
    Caption = 'Resultados de Búsqueda OCR';
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                    StyleExpr = LineNoStyle;
                    Caption = 'Línea Nº';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Width = 50;
                }
                field("Product Code"; Rec."Product Code")
                {
                    ApplicationArea = All;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = All;
                    Caption = 'UM';
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = All;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = All;
                }
                field("Tax Rate"; Rec."Tax Rate")
                {
                    ApplicationArea = All;
                    Caption = '% IVA';
                }
                field("Tax Amount"; Rec."Tax Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Imp. IVA';
                }
                field("Match Found In"; Rec."Match Found In")
                {
                    ApplicationArea = All;
                    Style = Attention;
                    StyleExpr = true;
                    Width = 30;
                }
                field("Confidence Score"; Rec."Confidence Score" * 100)
                {
                    ApplicationArea = All;
                    Caption = 'Confianza %';
                    DecimalPlaces = 0 : 2;

                    trigger OnDrillDown()
                    begin
                        Message('Nivel de confianza del OCR: %1%\Línea: %2', Round(Rec."Confidence Score" * 100, 0.01), Rec."Line No.");
                    end;
                }
            }
        }

        area(FactBoxes)
        {
            part(DetailFactBox; "OCR Result Detail FactBox")
            {
                ApplicationArea = All;
                SubPageLink = "Entry No." = field("Entry No.");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ExportToExcel)
            {
                ApplicationArea = All;
                Caption = 'Export to Excel';
                Image = Excel;
                ToolTip = 'Exportar resultados a Excel';

                trigger OnAction()
                var
                    OCRDocSearch: Codeunit "OCR Document Search";
                    TempSearchResults: Record "OCR Search Results" temporary;
                begin
                    // Copiar registros a tabla temporal
                    if Rec.FindSet() then
                        repeat
                            TempSearchResults := Rec;
                            TempSearchResults.Insert();
                        until Rec.Next() = 0;

                    //TODO
                    //OCRDocSearch.ExportResultsToExcel(TempSearchResults);
                end;
            }

            action(CopyLineNumber)
            {
                ApplicationArea = All;
                Caption = 'Copy Line Number';
                Image = Copy;
                ToolTip = 'Copiar número de línea al portapapeles';

                trigger OnAction()
                begin
                    Message('Número de línea: %1', Rec."Line No.");
                end;
            }

            action(ShowFullText)
            {
                ApplicationArea = All;
                Caption = 'Show Full Line Text';
                Image = ViewDetails;
                ToolTip = 'Mostrar texto completo de la línea';

                trigger OnAction()
                begin
                    Message('Línea completa:\%1', Rec."Full Line Text");
                end;
            }
        }

        area(Navigation)
        {
            action(FilterByConfidence)
            {
                ApplicationArea = All;
                Caption = 'Filter High Confidence';
                Image = FilterLines;
                ToolTip = 'Filtrar solo resultados con alta confianza (>90%)';

                trigger OnAction()
                begin
                    Rec.SetFilter("Confidence Score", '>0.9');
                    CurrPage.Update(false);
                end;
            }

            action(ClearFilters)
            {
                ApplicationArea = All;
                Caption = 'Clear Filters';
                Image = ClearFilter;
                ToolTip = 'Limpiar todos los filtros';

                trigger OnAction()
                begin
                    Rec.Reset();
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetStyles();
    end;

    local procedure SetStyles()
    begin
        if Rec."Confidence Score" >= 0.95 then
            LineNoStyle := 'Favorable'
        else if Rec."Confidence Score" >= 0.80 then
            LineNoStyle := 'Standard'
        else
            LineNoStyle := 'Attention';
    end;

    var
        LineNoStyle: Text;
}
