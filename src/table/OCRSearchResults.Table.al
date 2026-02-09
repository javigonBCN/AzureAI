table 80101 "OCR Search Results"
{
    TableType = Temporary;
    Caption = 'OCR Search Results';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.', Comment = 'ESP="Nº Línea"';
        }
        field(3; Description; Text[250])
        {
            Caption = 'Description', Comment = 'ESP="Descripción"';
        }
        field(4; "Product Code"; Text[50])
        {
            Caption = 'Product Code', Comment = 'ESP="Código Producto"';
        }
        field(5; Quantity; Text[50])
        {
            Caption = 'Quantity', Comment = 'ESP="Cantidad"';
        }
        field(6; "Unit Price"; Text[50])
        {
            Caption = 'Unit Price', Comment = 'ESP="Precio Unitario"';
        }
        field(7; Amount; Text[50])
        {
            Caption = 'Amount', Comment = 'ESP="Importe"';
        }
        field(8; "Match Found In"; Text[100])
        {
            Caption = 'Match Found In', Comment = 'ESP="Coincidencia en Campo(s)"';
        }
        field(9; "Unit of Measure"; Text[20])
        {
            Caption = 'Unit of Measure', Comment = 'ESP="Unidad de Medida"';
        }
        field(10; Date; Text[20])
        {
            Caption = 'Date', Comment = 'ESP="Fecha"';
        }
        field(11; "Tax Amount"; Text[50])
        {
            Caption = 'Tax Amount', Comment = 'ESP="Importe IVA"';
        }
        field(12; "Tax Rate"; Text[20])
        {
            Caption = 'Tax Rate', Comment = 'ESP="% IVA"';
        }
        field(13; "Full Line Text"; Text[2048])
        {
            Caption = 'Full Line Text', Comment = 'ESP="Texto Completo de la Línea"';
        }
        field(14; "Confidence Score"; Decimal)
        {
            Caption = 'Confidence Score', Comment = 'ESP="Nivel de Confianza"';
            DecimalPlaces = 2 : 2;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(LineNo; "Line No.")
        {
        }
    }

    procedure SetFullLineText()
    var
        FullText: Text;
    begin
        FullText := '';
        if Description <> '' then
            FullText += 'Desc: ' + Description + ' | ';
        if "Product Code" <> '' then
            FullText += 'Cod: ' + "Product Code" + ' | ';
        if Quantity <> '' then
            FullText += 'Cant: ' + Quantity + ' | ';
        if "Unit Price" <> '' then
            FullText += 'P.Unit: ' + "Unit Price" + ' | ';
        if Amount <> '' then
            FullText += 'Imp: ' + Amount;

        "Full Line Text" := CopyStr(FullText, 1, MaxStrLen("Full Line Text"));
    end;
}
