page 80105 "OCR Log Statistics FactBox"
{
    PageType = CardPart;
    SourceTable = "OCR Operation Log";
    Caption = 'Estadísticas';

    layout
    {
        area(Content)
        {
            cuegroup(Statistics)
            {
                Caption = 'Estadísticas Generales';

                field(TotalOperations; TotalOperations)
                {
                    ApplicationArea = All;
                    Caption = 'Total Operaciones';
                    ToolTip = ' ', Comment = 'ESP=" "';
                    StyleExpr = 'Strong';

                    trigger OnDrillDown()
                    var
                        OCRLog: Record "OCR Operation Log";
                    begin
                        Page.Run(Page::"OCR Operation Log", OCRLog);
                    end;
                }

                field(SuccessfulOperations; SuccessfulOperations)
                {
                    ApplicationArea = All;
                    Caption = 'Exitosas';
                    ToolTip = ' ', Comment = 'ESP=" "';
                    StyleExpr = 'Favorable';
                }

                field(FailedOperations; FailedOperations)
                {
                    ApplicationArea = All;
                    Caption = 'Fallidas';
                    ToolTip = ' ', Comment = 'ESP=" "';
                    StyleExpr = 'Unfavorable';
                }

                field(SuccessRate; SuccessRateText)
                {
                    ApplicationArea = All;
                    Caption = 'Tasa de Éxito';
                    ToolTip = ' ', Comment = 'ESP=" "';
                    StyleExpr = 'Standard';
                }
            }

            cuegroup(Performance)
            {
                Caption = 'Rendimiento';

                field(AvgProcessingTime; AvgProcessingTimeText)
                {
                    ApplicationArea = All;
                    Caption = 'Tiempo Promedio';
                    ToolTip = 'Tiempo promedio de procesamiento en segundos';
                }

                field(TotalDocuments; TotalDocuments)
                {
                    ApplicationArea = All;
                    Caption = 'Documentos Analizados';
                    ToolTip = ' ', Comment = 'ESP=" "';
                }

                field(TotalResults; TotalResults)
                {
                    ApplicationArea = All;
                    Caption = 'Resultados Encontrados';
                    ToolTip = ' ', Comment = 'ESP=" "';
                }
            }

            cuegroup(Recent)
            {
                Caption = 'Actividad Reciente';

                field(OperationsToday; OperationsToday)
                {
                    ApplicationArea = All;
                    Caption = 'Hoy';
                    ToolTip = ' ', Comment = 'ESP=" "';
                }

                field(OperationsThisWeek; OperationsThisWeek)
                {
                    ApplicationArea = All;
                    Caption = 'Esta Semana';
                    ToolTip = ' ', Comment = 'ESP=" "';
                }

                field(OperationsThisMonth; OperationsThisMonth)
                {
                    ApplicationArea = All;
                    Caption = 'Este Mes';
                    ToolTip = ' ', Comment = 'ESP=" "';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        CalculateStatistics();
    end;

    trigger OnAfterGetRecord()
    begin
        CalculateStatistics();
    end;

    local procedure CalculateStatistics()
    var
        OCRLog: Record "OCR Operation Log";
        TotalTime: BigInteger;
        SecondTxt: Label '%1 sec', Comment = 'ESP="%1 seg"';
    begin
        // Total operaciones
        OCRLog.Reset();
        TotalOperations := OCRLog.Count();

        // Operaciones exitosas
        OCRLog.SetRange(Status, OCRLog.Status::Success);
        SuccessfulOperations := OCRLog.Count();

        // Operaciones fallidas
        OCRLog.Reset();
        OCRLog.SetFilter(Status, '<>%1', OCRLog.Status::Success);
        FailedOperations := OCRLog.Count();

        // Tasa de éxito
        if TotalOperations > 0 then
            SuccessRateText := StrSubstNo(SecondTxt, Round((SuccessfulOperations / TotalOperations) * 100, 0.1))
        else
            SuccessRateText := 'N/A';

        // Tiempo promedio
        OCRLog.Reset();
        OCRLog.SetRange(Status, OCRLog.Status::Success);
        if OCRLog.FindSet() then begin
            TotalTime := 0;
            repeat
                TotalTime += OCRLog."Processing Time (ms)";
            until OCRLog.Next() = 0;

            if SuccessfulOperations > 0 then
                AvgProcessingTimeText := StrSubstNo(SecondTxt, Round((TotalTime / SuccessfulOperations) / 1000, 0.01))
            else
                AvgProcessingTimeText := 'N/A';
        end else
            AvgProcessingTimeText := 'N/A';

        // Total documentos únicos
        OCRLog.Reset();
        if OCRLog.FindSet() then begin
            TotalDocuments := 0;
            repeat
                OCRLog.SetRange("Document No.", OCRLog."Document No.");
                if OCRLog.FindFirst() then
                    TotalDocuments += 1;
                OCRLog.SetRange("Document No.");
                OCRLog.FindLast();
            until OCRLog.Next() = 0;
        end;

        // Total resultados
        OCRLog.Reset();
        OCRLog.CalcSums("Results Found");
        TotalResults := OCRLog."Results Found";

        // Operaciones recientes
        OCRLog.Reset();
        OCRLog.SetRange("Operation DateTime", CreateDateTime(Today, 0T), CurrentDateTime);
        OperationsToday := OCRLog.Count();

        OCRLog.Reset();
        OCRLog.SetRange("Operation DateTime", CreateDateTime(CalcDate('<-CW>', Today), 0T), CurrentDateTime);
        OperationsThisWeek := OCRLog.Count();

        OCRLog.Reset();
        OCRLog.SetRange("Operation DateTime", CreateDateTime(CalcDate('<-CM>', Today), 0T), CurrentDateTime);
        OperationsThisMonth := OCRLog.Count();
    end;

    var
        TotalOperations: Integer;
        SuccessfulOperations: Integer;
        FailedOperations: Integer;
        SuccessRateText: Text;
        AvgProcessingTimeText: Text;
        TotalDocuments: Integer;
        TotalResults: Integer;
        OperationsToday: Integer;
        OperationsThisWeek: Integer;
        OperationsThisMonth: Integer;
}
