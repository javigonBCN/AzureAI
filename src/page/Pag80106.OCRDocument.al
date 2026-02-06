page 80106 "OCR Document"
{

    Caption = 'Documents';
    CardPageID = "CDC Document Card";
    Editable = false;
    PageType = List;
    SourceTable = "CDC Document";
    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the document.';
                }
                field("Document Category Code"; Rec."Document Category Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the category that the document belongs to.';
                }
                field(Control1000000005; Rec.GetSourceID)
                {
                    ApplicationArea = All;
                    Caption = 'Source ID';
                    ToolTip = 'Specifies the primary key of the record this document belong. For purchase related documents this will show the number of the vendor.';
                }
                field(Control1000000010; Rec.GetSourceName)
                {
                    ApplicationArea = All;
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of the record this document belong. For purchase related documents this will show the name of the vendor.';
                }
                field("Created Doc. Table No."; rec."Created Doc. Table No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of the document.';
                }
                field("Created Doc. No."; Rec."Created Doc. No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of the document.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of the document.';
                }
            }
        }
    }
}

