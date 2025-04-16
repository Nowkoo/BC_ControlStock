// Welcome to your new AL extension.
// Remember that object names and IDs should be unique across all extensions.
// AL snippets start with t*, like tpageext - give them a try and happy coding!

pageextension 60200 CustomerExt extends "Customer Card"
{
    layout
    {
        addafter(Priority)
        {
            field("Customer Type"; Rec."Customer Type")
            {
                ApplicationArea = All;
                ToolTip = 'Select a Customer Type.';
            }
        }
    }
}