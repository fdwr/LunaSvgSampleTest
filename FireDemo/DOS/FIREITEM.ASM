.Items:
        DefContainedItem btnFast
        DefContainedItem btnQuit
        DefContainedItem lblTitle
        DefWindowEnd

DefItem btnFast,ButtonCode,NullGuiItem,ButtonObj.DefGuiFlags, 168,4,12,40
        DefPushButton .Text,4,ButtonObj.Toggle
DefItem btnQuit,ButtonCode,btnQuit.Owner,ButtonObj.DefGuiFlags, 184,4,12,40
        DefPushButton .Text,4,0
DefItem lblTitle,LabelCode,0,LabelObj.DefGuiFlags, 0,0,8,180
        DefLabel .Text,46,LabelObj.AlignLeft

        btnFast.Text: db "Fast"
        btnQuit.Text: db "Quit"
        lblTitle.Text: db "Surface of the Sun, Dwayne Robinson 2001-10-26"
