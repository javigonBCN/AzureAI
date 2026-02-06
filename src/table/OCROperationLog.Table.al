table 80102 "OCR Operation Log"
{
    DataClassification = CustomerContent;
    Caption = 'OCR Operation Log';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(3; "Operation DateTime"; DateTime)
        {
            Caption = 'Operation Date Time';
        }
        field(4; "Operation Type"; Option)
        {
            Caption = 'Operation Type';
            OptionMembers = Search,FullAnalysis,TestConnection;
            OptionCaption = 'Search,Full Analysis,Test Connection';
        }
        field(5; "Search Text"; Text[250])
        {
            Caption = 'Search Text';
        }
        field(6; "Results Found"; Integer)
        {
            Caption = 'Results Found';
        }
        field(7; Status; Option)
        {
            Caption = 'Status';
            OptionMembers = Success,Failed,Timeout,Error;
            OptionCaption = 'Success,Failed,Timeout,Error';
        }
        field(8; "Error Message"; Text[250])
        {
            Caption = 'Error Message';
        }
        field(9; "Processing Time (ms)"; Integer)
        {
            Caption = 'Processing Time (ms)';
        }
        field(10; "User ID"; Code[50])
        {
            Caption = 'User ID';
        }
        field(11; "Total Lines Analyzed"; Integer)
        {
            Caption = 'Total Lines Analyzed';
        }
        field(12; "Azure Response Size"; Integer)
        {
            Caption = 'Azure Response Size (bytes)';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(DocumentDate; "Document No.", "Operation DateTime")
        {
        }
    }

    procedure CreateLogEntry(DocumentNo: Code[20]; OperationType: Option; SearchText: Text[250]; Success: Boolean; ErrorMsg: Text[250]; ProcessingTime: Integer; ResultsFound: Integer; TotalLines: Integer)
    begin
        Init();
        "Document No." := DocumentNo;
        "Operation DateTime" := CurrentDateTime;
        "Operation Type" := OperationType;
        "Search Text" := SearchText;
        "Results Found" := ResultsFound;
        if Success then
            Status := Status::Success
        else
            Status := Status::Error;
        "Error Message" := CopyStr(ErrorMsg, 1, MaxStrLen("Error Message"));
        "Processing Time (ms)" := ProcessingTime;
        "User ID" := CopyStr(UserId, 1, MaxStrLen("User ID"));
        "Total Lines Analyzed" := TotalLines;
        Insert(true);
    end;
}
