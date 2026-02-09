permissionset 80100 GeneratedPermission
{
    Assignable = true;
    Permissions = tabledata "OCR Azure AI Configuration" = RIMD,
        tabledata "OCR Operation Log" = RIMD,
        tabledata "OCR Search Results" = RIMD,
        table "OCR Azure AI Configuration" = X,
        table "OCR Operation Log" = X,
        table "OCR Search Results" = X,
        codeunit "OCR Azure Doc Intelligence" = X,
        codeunit "OCR Document Search" = X,
        page "OCR Azure AI Configuration" = X,
        page "OCR Document" = X,
        page "OCR Document Finder" = X,
        page "OCR Log Statistics FactBox" = X,
        page "OCR Operation Log" = X,
        page "OCR Result Detail FactBox" = X,
        page "OCR Search Results" = X,
        tabledata "OCR Conversion History" = RIMD,
        table "OCR Conversion History" = X,
        codeunit "OCR PDF Converter" = X;
}