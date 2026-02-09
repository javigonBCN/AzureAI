table 80111 "OCR Conversion History"
{
    DataClassification = CustomerContent;
    Caption = 'OCR Conversion History';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; "Conversion DateTime"; DateTime)
        {
            Caption = 'Conversion Date Time';
        }
        field(3; "Original Filename"; Text[250])
        {
            Caption = 'Original Filename';
        }
        field(4; "File Type"; Option)
        {
            Caption = 'File Type';
            OptionMembers = PDF,Image;
            OptionCaption = 'PDF,Image';
        }
        field(5; "File Size (KB)"; Integer)
        {
            Caption = 'File Size (KB)';
        }
        field(6; "Pages Processed"; Integer)
        {
            Caption = 'Pages Processed';
        }
        field(7; Status; Option)
        {
            Caption = 'Status';
            OptionMembers = Success,Failed,Processing,Timeout;
            OptionCaption = 'Success,Failed,Processing,Timeout';
        }
        field(8; "Processing Time (sec)"; Integer)
        {
            Caption = 'Processing Time (seconds)';
        }
        field(9; "User ID"; Code[50])
        {
            Caption = 'User ID';
        }
        field(10; "Error Message"; Text[250])
        {
            Caption = 'Error Message';
        }
        field(11; "Output File"; Blob)
        {
            Caption = 'Output File';
            Subtype = Bitmap;
        }
        field(12; "Output Filename"; Text[1000])
        {
            Caption = 'Output Filename';
        }
        field(13; "Words Detected"; Integer)
        {
            Caption = 'Words Detected';
        }
        field(14; "Average Confidence"; Decimal)
        {
            Caption = 'Average Confidence %';
            DecimalPlaces = 2 : 2;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(DateTime; "Conversion DateTime")
        {
        }
    }

    procedure DownloadOutputFile()
    var
        InStr: InStream;
    begin
        if not "Output File".HasValue() then
            Error('No hay archivo de salida disponible');

        CalcFields("Output File");
        "Output File".CreateInStream(InStr);
        DownloadFromStream(InStr, 'Descargar PDF OCR', '', 'PDF Files (*.pdf)|*.pdf', "Output Filename");
    end;

    procedure DeleteOldEntries(DaysToKeep: Integer)
    var
        ConversionHistory: Record "OCR Conversion History";
        CutoffDate: DateTime;
    begin
        CutoffDate := CreateDateTime(CalcDate(StrSubstNo('<-%D>', DaysToKeep), Today), 0T);

        ConversionHistory.SetFilter("Conversion DateTime", '<%1', CutoffDate);
        if ConversionHistory.FindSet() then
            ConversionHistory.DeleteAll();
    end;
}
