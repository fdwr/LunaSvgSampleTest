        DefContainedItem textprompt1
        DefContainedItem TopBtn
        DefContainedItem textprompt2
        DefContainedItem InnerWnd
        DefWindowEnd

;main window items
DefItem TopBtn,ButtonCode,NullGuiItem,ButtonObj.DefGuiFlags, 124,189,12,68
        DefPushButton TopBtn.Text,3,0
        textprompt2.MaxLen equ 21+50
DefItem textprompt1,TextPromptCode,NullGuiItem,TextPromptObj.DefGuiFlags, 130,184,11,68
        DefTextPrompt textprompt2.Text,21,textprompt2.MaxLen,0
DefItem textprompt2,TextPromptCode,NullGuiItem,TextPromptObj.DefGuiFlags, 143,184,11,68
        DefTextPrompt textprompt2.Text,21,textprompt2.MaxLen,0
DefItem InnerWnd,WindowCode,NullGuiItem,WindowObj.DefGuiFlags, 110,108,56,124
        DefWindow NullGuiItem,0,0
        ;DefContainedItem TiWinBg
        DefContainedItem InnerTb
        DefContainedItem HelloBtn
        DefContainedItem HelloBtn2
        DefWindowEnd

;innermost window
        %define GuiObjContainer InnerWnd
;DefItem TiWinBg,WindowBgCode,0,WindowBgObj.DefGuiFlags, 0,0,32000,32000
DefItem InnerTb,TitleBarCode,NullGuiItem,TitleBarObj.DefGuiFlags, 2,2,9,100
        DefTitleBar InnerTb.Text,19,TitleBarObj.HelpButton|TitleBarObj.CloseButton|TitleBarObj.MaxButton
DefItem HelloBtn,ButtonCode,NullGuiItem,ButtonObj.DefGuiFlags, 24,20,12,92
        DefPushButton HelloBtn.Text,22,0
DefItem HelloBtn2,ButtonCode,NullGuiItem,ButtonObj.DefGuiFlags, 37,16,12,92
        DefPushButton HelloBtn.Text,22,0

;main window
        TopBtn.Text: db "Top"
;inner window
        InnerTb.Text: db "Innermost Title Bar"
        HelloBtn.Text: db "Hello from deep inside"
        textprompt2.Text: db "Just some random text"
        times 50 db 0
