page 80103 "OCR Operation Log"
{
    PageType = List;
    SourceTable = "OCR Operation Log";
    Caption = 'OCR Operation Log';
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = true;
    ModifyAllowed = false;
    UsageCategory = History;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
                field("Operation DateTime"; Rec."Operation DateTime")
                {
                    ApplicationArea = All;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;

                    //TODO
                    // trigger OnDrillDown()
                    // var
                    //     DCDocuments: Record "CDC Document";
                    // begin
                    //     if DCDocuments.Get(Rec."Document No.") then begin
                    //         Page.Run(Page::"CDC Document", DCDocuments);
                    //     end;
                    // end;
                }
                field("Operation Type"; Rec."Operation Type")
                {
                    ApplicationArea = All;
                }
                field("Search Text"; Rec."Search Text")
                {
                    ApplicationArea = All;
                    Width = 30;
                }
                field("Results Found"; Rec."Results Found")
                {
                    ApplicationArea = All;
                    Style = Favorable;
                    StyleExpr = Rec."Results Found" > 0;
                }
                field("Total Lines Analyzed"; Rec."Total Lines Analyzed")
                {
                    ApplicationArea = All;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    StyleExpr = StatusStyle;
                }
                field("Processing Time (ms)"; Rec."Processing Time (ms)")
                {
                    ApplicationArea = All;
                    Caption = 'Time (ms)';
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = All;
                }
                field("Error Message"; Rec."Error Message")
                {
                    ApplicationArea = All;
                    Visible = false;
                    Width = 50;
                }
            }
        }

        area(FactBoxes)
        {
            part(Statistics; "OCR Log Statistics FactBox")
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DeleteOldEntries)
            {
                ApplicationArea = All;
                Caption = 'Delete Old Entries';
                Image = Delete;
                ToolTip = 'Eliminar registros anteriores a una fecha';

                trigger OnAction()
                var
                    OCRLog: Record "OCR Operation Log";
                    DeleteBeforeDate: Date;
                begin
                    DeleteBeforeDate := CalcDate('<-30D>', Today);
                    if not Confirm('¿Eliminar todos los registros anteriores a %1?', false, DeleteBeforeDate) then
                        exit;

                    OCRLog.SetFilter("Operation DateTime", '<%1', CreateDateTime(DeleteBeforeDate, 0T));
                    if OCRLog.FindSet() then begin
                        OCRLog.DeleteAll();
                        Message('Registros eliminados correctamente');
                        CurrPage.Update(false);
                    end else
                        Message('No se encontraron registros antiguos para eliminar');
                end;
            }

            action(ExportLog)
            {
                ApplicationArea = All;
                Caption = 'Export to Excel';
                Image = Excel;
                ToolTip = 'Exportar log a Excel';

                trigger OnAction()
                var
                    OCRLog: Record "OCR Operation Log";
                    TempExcelBuffer: Record "Excel Buffer" temporary;
                begin
                    OCRLog.CopyFilters(Rec);

                    // Headers
                    TempExcelBuffer.NewRow();
                    TempExcelBuffer.AddColumn('Entry No.', false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
                    TempExcelBuffer.AddColumn('Date Time', false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
                    TempExcelBuffer.AddColumn('Document No.', false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
                    TempExcelBuffer.AddColumn('Operation Type', false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
                    TempExcelBuffer.AddColumn('Search Text', false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
                    TempExcelBuffer.AddColumn('Results', false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
                    TempExcelBuffer.AddColumn('Status', false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
                    TempExcelBuffer.AddColumn('Time (ms)', false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
                    TempExcelBuffer.AddColumn('User', false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
                    TempExcelBuffer.AddColumn('Error', false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);

                    // Data
                    if OCRLog.FindSet() then
                        repeat
                            TempExcelBuffer.NewRow();
                            TempExcelBuffer.AddColumn(OCRLog."Entry No.", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Number);
                            TempExcelBuffer.AddColumn(OCRLog."Operation DateTime", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Date);
                            TempExcelBuffer.AddColumn(OCRLog."Document No.", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                            TempExcelBuffer.AddColumn(Format(OCRLog."Operation Type"), false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                            TempExcelBuffer.AddColumn(OCRLog."Search Text", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                            TempExcelBuffer.AddColumn(OCRLog."Results Found", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Number);
                            TempExcelBuffer.AddColumn(Format(OCRLog.Status), false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                            TempExcelBuffer.AddColumn(OCRLog."Processing Time (ms)", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Number);
                            TempExcelBuffer.AddColumn(OCRLog."User ID", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                            TempExcelBuffer.AddColumn(OCRLog."Error Message", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                        until OCRLog.Next() = 0;

                    TempExcelBuffer.CreateNewBook('OCR Operation Log');
                    TempExcelBuffer.WriteSheet('Log', CompanyName, UserId);
                    TempExcelBuffer.CloseBook();
                    TempExcelBuffer.OpenExcel();
                end;
            }

            action(Refresh)
            {
                ApplicationArea = All;
                Caption = 'Refresh';
                Image = Refresh;
                ToolTip = 'Refrescar la vista';

                trigger OnAction()
                begin
                    CurrPage.Update(false);
                end;
            }
        }

        area(Navigation)
        {
            action(FilterSuccess)
            {
                ApplicationArea = All;
                Caption = 'Show Successful Only';
                Image = FilterLines;
                ToolTip = 'Mostrar solo operaciones exitosas';

                trigger OnAction()
                begin
                    Rec.SetRange(Status, Rec.Status::Success);
                    CurrPage.Update(false);
                end;
            }

            action(FilterErrors)
            {
                ApplicationArea = All;
                Caption = 'Show Errors Only';
                Image = ErrorLog;
                ToolTip = 'Mostrar solo operaciones con error';

                trigger OnAction()
                begin
                    Rec.SetFilter(Status, '<>%1', Rec.Status::Success);
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
        SetStatusStyle();
    end;

    local procedure SetStatusStyle()
    begin
        case Rec.Status of
            Rec.Status::Success:
                StatusStyle := 'Favorable';
            Rec.Status::Failed, Rec.Status::Error:
                StatusStyle := 'Unfavorable';
            Rec.Status::Timeout:
                StatusStyle := 'Attention';
        end;
    end;

    var
        StatusStyle: Text;
}
