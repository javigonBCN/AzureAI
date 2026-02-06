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
    UsageCategory = None;

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
                    ToolTip = ' ', Comment = 'ESP=" "';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = ' ', Comment = 'ESP=" "';
                    Width = 50;
                }
                field("Product Code"; Rec."Product Code")
                {
                    ApplicationArea = All;
                    ToolTip = ' ', Comment = 'ESP=" "';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                    ToolTip = ' ', Comment = 'ESP=" "';
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = All;
                    ToolTip = ' ', Comment = 'ESP=" "';
                    Caption = 'UM';
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
                }
                field("Tax Rate"; Rec."Tax Rate")
                {
                    ApplicationArea = All;
                    ToolTip = ' ', Comment = 'ESP=" "';
                    Caption = '% IVA';
                }
                field("Tax Amount"; Rec."Tax Amount")
                {
                    ApplicationArea = All;
                    ToolTip = ' ', Comment = 'ESP=" "';
                    Caption = 'Imp. IVA';
                }
                field("Match Found In"; Rec."Match Found In")
                {
                    ApplicationArea = All;
                    ToolTip = ' ', Comment = 'ESP=" "';
                    Style = Attention;
                    StyleExpr = true;
                    Width = 30;
                }
                field("Confidence Score"; Rec."Confidence Score" * 100)
                {
                    ApplicationArea = All;
                    Caption = 'Confianza %';
                    ToolTip = ' ', Comment = 'ESP=" "';
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
                    TempSearchResults: Record "OCR Search Results" temporary;
                    OCRDocSearch: Codeunit "OCR Document Search";
                begin
                    // Copiar registros a tabla temporal
                    if Rec.FindSet() then
                        repeat
                            TempSearchResults := Rec;
                            TempSearchResults.Insert();
                        until Rec.Next() = 0;

                    OCRDocSearch.ExportResultsToExcel(TempSearchResults);
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
        else
            if Rec."Confidence Score" >= 0.80 then
                LineNoStyle := 'Standard'
            else
                LineNoStyle := 'Attention';
    end;

    var
        LineNoStyle: Text;
}
