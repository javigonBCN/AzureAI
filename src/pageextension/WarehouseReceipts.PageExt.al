namespace AzureAI.AzureAI;

using Microsoft.Warehouse.Document;

pageextension 80102 "Warehouse Receipts" extends "Warehouse Receipts"
{
    layout
    {
        addfirst(factboxes)
        {
            part("CDC Document Files Factbox"; "CDC Document Files Factbox")
            {
                ApplicationArea = All;
                Caption = 'Attached Files', Comment = 'ESP="Archivos adjuntos"';
                SubPageLink = "Source Table No. Filter" = const(7316), // ID de la tabla Purchase Header
                "Source No. Filter" = FIELD("No."),
                "Find Documents Using" = filter('Document Reference');
            }
        }
    }
}
