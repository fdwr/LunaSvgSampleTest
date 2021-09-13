;TMV Find
%define Program.TitleDef "TMV Find GUI Test"
%define Program.ClassDef "PknTmvGuiTest"

        DefWindow window21,0,0
        DefContainedItem mainbg
        DefContainedItem atrbar11
        DefContainedItem window21
        DefContainedItem window36
        DefContainedItem tabstrip0
        DefContainedItem FloatMenu
        DefContainedItem floatpic
        DefWindowEnd

DefItem mainbg,MainBgCode,0,MainBgObj.DefFlags, 0,0,Screen.Height,Screen.Width
        DefTitleBar Program.Title,17,TitleBarObj.HelpButton|TitleBarObj.CloseButton|TitleBarObj.MinButton

        DefMenuList mnuMain,IgnoreMsg
        DefMenuListItem .File,       .0,.FileImg,    MenuListObj.Opens, mnuFile
        DefMenuListItem .Control,    .1,.ControlImg, 0
        DefMenuListItem .Seek,       .2,.SeekImg,    0
        DefMenuListItem .Goto,       .3,.GotoImg,    0
        DefMenuListItem .View,       .4,.ViewImg,    0
        DefMenuListItem .Options,    .5,.OptionsImg, 0
        DefMenuListItem .Quit,       .6,.QuitImg,    MenuListObj.Separator
        DefMenuListEnd
        DefMenuList mnuFile,IgnoreMsg
        DefMenuListItem .Load,       .0,0, 0
        DefMenuListItem .Save,       .1,0, 0
        DefMenuListItem .Record,     .2,0, 0
        DefMenuListItem .Settings,   .3,0, MenuListObj.Opens, mnuFileSets
        DefMenuListItem .ExportWave, .4,0, 0
        DefMenuListItem .LogAsm,     .5,0, 0
        DefMenuListEnd
        DefMenuList mnuFileSets,IgnoreMsg
        DefMenuListItem .Reload,     .0,0, 0
        DefMenuListItem .Save,       .1,0, 0
        DefMenuListItem .Always,     .2,0, 0
        DefMenuListItem .Prompt,     .3,0, 0
        DefMenuListItem .Never,      .4,0, 0
        DefMenuListEnd
DefItem tabstrip0,TabStripCode,TabOwner,TabStripObj.DefFlags, 24,0,400,18
        DefTabStrip
        DefTabStripItem tab1.Name,4,0,48
        DefTabStripItem tab2.Name,4,0,40
        DefTabStripItem tab3.Name,5,0,48
        DefTabStripItem tab4.Name,4,0,40
        DefTabStripItem tab5.Name,4,0,48
        DefTabStripItem tab6.Name,3,0,32
        DefTabStripItem tab7.Name,3,0,40
        DefTabStripItem tab8.Name,4,0,40
        DefTabStripItem tab9.Name,5,0,40
        DefTabStripItem tab10.Name,1,0,24
        DefTabStripEnd
DefItem atrbar11,AtrBarCode,NullGuiItem,TabStripObj.DefFlags, 384+48,20,16,620
        DefTabStrip
        DefTabStripItem atrbaritem12.Name,10,0,96
        DefTabStripItem atrbaritem13.Name,12,0,88
        DefTabStripItem atrbaritem14.Name,4,0,56
        DefTabStripItem atrbaritem15.Name,3,0,48
        DefTabStripItem atrbaritem16.Name,5,0,48
        DefTabStripItem atrbaritem17.Name,3,0,40
        DefTabStripItem atrbaritem18.Name,3,0,40
        DefTabStripItem atrbaritem19.Name,5,0,72
        DefTabStripItem atrbaritem20.Name,12,0,120
        DefTabStripEnd

DefItem window21,FrameCode,NullGuiItem,FrameObj.DefFlags, 24,198,374,438
        DefWindow button27,0,0
        DefContainedItem titlebar22
        DefContainedItem border23
        DefContainedItem scroll24
        DefContainedItem scroll25
        DefContainedItem border26
        DefContainedItem button27
        DefWindowEnd

DefItem window36,EfxFrameCode,NullGuiItem,FrameObj.DefFlags, 24-4,0,384,200
        DefWindow textprompt44,0,0
        DefContainedItem windowbg35
        DefContainedItem titlebar37
        DefContainedItem border38
        DefContainedItem textprompt39
        DefContainedItem button40
        DefContainedItem button41
        DefContainedItem button42
        DefContainedItem border43
        DefContainedItem textprompt44
        DefContainedItem border45
        DefContainedItem border46
        DefContainedItem label47
        DefContainedItem list48
        DefContainedItem scroll49
        DefContainedItem button50
        DefContainedItem button51
        DefContainedItem button52
        DefContainedItem button53
        DefContainedItem button54
        DefContainedItem button55
        DefWindowEnd
DefItem floatpic,FloatPicCode,NullGuiItem,GuiObj.DefFlags|GuiObj.NoKeyFocus, 100,200,200,256
;DefItem floatpic,FloatPicCode,NullGuiItem,GuiObj.DefFlags|GuiObj.NoKeyFocus, 100,200,200,248
;floatpic:

;window21
DefItem titlebar22,TitleBarCode,NullGuiItem,TitleBarObj.DefFlags, 0,0,18,438
        DefTitleBar titlebar22.Text,12,TitleBarObj.CloseButton|TitleBarObj.MaxButton
DefItem border23,BorderCode,0,BorderObj.DefFlags, 20,0,340,420
DefItem scroll24,ScrollHandleCode,NullGuiItem,ScrollHandleObj.DefFlags, 20,422,340,12
        DefScrollHandle 100,0,0,1,10
DefItem scroll25,ScrollHandleCode,NullGuiItem,ScrollHandleObj.DefFlags, 362,0,12,420
        DefScrollHandle 100,0,0,1,10
DefItem border26,BorderCode,0,BorderObj.DefFlags, 362,422,12,12
DefItem button27,ButtonCode,MenuButtonOwner,ButtonObj.DefFlags, 320,66,24,96+32
        DefPushButton button27.Text,12,0

;window36
DefItem windowbg35,WindowBgCode,0,WindowBgObj.DefFlags, 0,0,2048,2048
DefItem titlebar37,TitleBarCode,NullGuiItem,TitleBarObj.DefFlags, 4,24,18,172
        DefTitleBar titlebar37.Text,9,TitleBarObj.CloseButton|TitleBarObj.MaxButton
DefItem border38,BorderCode,0,BorderObj.DefFlags, 24,24,24,172
        textprompt39.MaxLen equ 19+50
DefItem textprompt39,TextPromptCode,NullGuiItem,TextPromptObj.DefFlags|GuiObj.GroupStart, 26,26,20,152
        DefTextPrompt textprompt39.Text,19,textprompt39.MaxLen,0
DefItem button40,ButtonCode,ButtonOwner,ButtonObj.DefFlags, 50,24,24,56
        DefPushButton button40.Text,4,0
DefItem button41,ButtonCode,ButtonOwner,ButtonObj.DefFlags, 50,82,24,56
        DefPushButton button41.Text,4,0
DefItem button42,ButtonCode,ButtonOwner,ButtonObj.DefFlags, 50,140,24,56
        DefPushButton button42.Text,4,0
DefItem border43,BorderCode,0,BorderObj.DefFlags, 78,24,24,172
        textprompt44.MaxLen equ 50
DefItem textprompt44,TextPromptCode,NullGuiItem,TextPromptObj.DefFlags|GuiObj.GroupStart, 80,26,20,168
        DefTextPrompt textprompt44.Text,75,textprompt44.MaxLen,0
DefItem border45,BorderCode,0,BorderObj.DefFlags, 104,24,220,158
DefItem border46,BorderCode,0,BorderObj.DefFlags, 106,26,20,154
DefItem label47,LabelCode,0,LabelObj.DefFlags, 110,30,16,146
        DefLabel label47.Text,8,LabelObj.AlignLeft
DefItem list48,ListCode,NullGuiItem,ListObj.DefFlags|GuiObj.Disabled, 126,26,192,154
        ;DefList ...
DefItem scroll49,ScrollHandleCode,NullGuiItem,ScrollHandleObj.DefFlags, 104,184,220,12
        DefScrollHandle 100,0,0,1,10
DefItem button50,ButtonCode,ButtonOwner,ButtonObj.DefFlags|GuiObj.GroupStart, 328,24,24,56
        DefPushButton button50.Text,4,0
DefItem button51,ButtonCode,ButtonOwner,ButtonObj.DefFlags, 328,82,24,56
        DefPushButton button51.Text,4,0
DefItem button52,ButtonCode,ButtonOwner,ButtonObj.DefFlags, 328,140,24,56
        DefPushButton button52.Text,4,0
DefItem button53,ButtonCode,ButtonOwner,ButtonObj.DefFlags, 354,24,24,56
        DefPushButton button53.Text,6,0
DefItem button54,ButtonCode,ButtonOwner,ButtonObj.DefFlags, 354,82,24,56
        DefPushButton button54.Text,6,0
DefItem button55,ButtonCode,ButtonOwner,ButtonObj.DefFlags, 354,140,24,56
        DefPushButton button55.Text,4,0

windowbg56.Idx equ 0
windowbg56.Gic equ floatpic
DefItem windowbg56,WindowBgCode,0,WindowBgObj.DefFlags, 0,0,2048,2048


DefImageStruct mnuMain.FileImg,14,14
        db 2,2,2,2,2,2,14,15,15,15,15,15,15,2,2,2,2,2,2,15,14,15,15,15,15,15
        db 15,14,2,2,2,2,15,15,14,15,15,15,15,15,15,14,2,2,2,15,15,15,14,15
        db 15,15,15,15,15,14,2,2,15,15,15,15,14,15,15,15,15,15,15,14,2,15,15
        db 15,15,15,14,15,15,15,15,15,15,14,14,14,14,14,14,14,15,15,15,15,15
        db 15,15,14,15,15,15,15,15,15,15,15,15,15,15,15,15,14,15,15,15,15,15
        db 15,15,15,15,15,15,15,15,14,15,15,15,15,15,15,15,15,15,15,15,15,15
        db 14,15,15,15,15,15,15,15,15,15,15,15,15,15,14,15,15,15,15,15,15,15
        db 15,15,15,15,15,15,14,15,15,15,15,15,15,15,15,15,15,15,15,15,14,2
        db 14,14,14,14,14,14,14,14,14,14,14,14,14
DefImageStruct mnuMain.ControlImg,14,14
        db 7,7,7,7,7,7,7,7,7,7,7,7,7,2,7,7,7,6,6,7,7,7,7,7,7,7,7,6,7,7,7,6,2,6,7,7,7,7,7,7,7,6,7,7
        db 7,6,2,2,6,7,7,7,7,7,7,6,7,7,7,6,2,2,2,6,7,7,7,7,7,6,7,7,7,6,2,2,2,2,6,7,7,7,7,6,7,7,7,6,2,2,2,2,2,6
        db 7,7,7,6,7,7,7,6,2,2,2,2,2,7,7,7,7,6,7,7,7,6,2,2,2,2,7,7,7,7,7,6,7,7,7,6,2,2,2,7,7,7,7,7
        db 7,6,7,7,7,6,2,2,7,7,7,7,7,7,7,6,7,7,7,6,2,7,7,7,7,7,7,7,7,6,7,7,7,7,7,7,7,7,7,7,7,7,7,6,2,6,6,6,6,6,6,6,6,6,6,6,6,6
DefImageStruct mnuMain.SeekImg,14,14
        db 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,9,8,2,9,2,2,2,2,2,2,2,2,2,9,9,8,2,9,9,2,2,2,2,2,2,2,9
        db 9,9,8,2,9,9,9,2,2,2,2,2,9,9,9,9,8,2,9,9,9,9,2,2,2,9,9,9,9,9,8,2,9,9,9,9,9,2,9,9,9,9,9,9,8,2,9,9
        db 9,9,9,9,8,9,9,9,9,9,8,2,9,9,9,9,9,8,2,8,9,9,9,9,8,2,9,9,9,9,8,8,2,2,8,9,9,9,8,2,9,9,9,8,8
        db 2,2,2,2,8,9,9,8,2,9,9,8,8,2,2,2,2,2,2,8,9,8,2,9,8,8,2,2,2,2,2,2,2,2,8,8,2,8,8,2,2,2,2,2,2,2,2,2,2,8,2,8,2,2,2,2,2
DefImageStruct mnuMain.GotoImg,14,14
        db 2,2,2,2,2,2,2,2,2,2,2,2,2,2,11,11,11,11,11,11,11,11,11,11,11,11,11,2,10,11,11,11,11,11,11,11
        db 11,11,11,11,10,10,2,10,11,11,11,11,11,11,11,11,11,10,10,2,2,2,10,11,11,11,11,11,11,11,10,10
        db 2,2,2,2,2,10,11,11,11,11,11,10,10,2,2,2,2,2,2,2,10,11,11,11,10,10,2,2,2,2,2,2,2,2,2,10,11,10
        db 10,2,2,2,2,2,2,2,2,2,2,2,10,10,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,11,11,11,11,11,11,11,11
        db 11,11,11,11,11,2,11,11,11,11,11,11,11,11,11,11,11,11,11,10,11,11,11,11,11,11,11,11,11,11,11,11,11,10,2,10,10,10,10,10,10,10,10,10,10,10,10,10
DefImageStruct mnuMain.ViewImg,14,14
        db 2,2,2,2,7,7,7,2,2,2,2,2,2,2,2,2,7,7,7,7,7,7,7,2,2,2,2,2,2,7,7,7,6,6,6,7,7,7,2,2,2,2,2,7,7,6,2,2,2,6,7,7,2,2
        db 2,2,7,7,6,2,2,2,2,2,6,7,7,2,2,2,7,7,6,2,2,2,2,2,2,7,7,2,2,2,7,7,6,2,2,2,2,2,2,7,7,2,2,2,6,7,7,6,2,2,2,2,6,7
        db 6,2,2,2,2,7,7,7,2,2,2,6,7,7,7,2,2,2,2,6,7,7,7,7,7,7,7,7,7,7,2,2,2,2,6,6,7,7,7,6,7,7,7,7,7,2,2,2,2,2,6,6,6,2
        db 6,7,7,7,7,6,2,2,2,2,2,2,2,2,2,6,7,7,6,2,2,2,2,2,2,2,2,2,2,2,6,6,2,2
DefImageStruct mnuMain.OptionsImg,14,14
        db 13,13,13,13,13,13,13,13,13,13,13,13,13,2,13,13,12,12,12,12,12,12,12,12,12,12,13,12,13,13,12,2,2,2,2,2,2,2,2
        db 2,13,12,13,13,13,13,13,13,13,13,13,13,13,13,13,12,13,13,13,13,13,13,13,13,13,13,13,13,13,12,13,13,12,12,13
        db 13,12,12,13,13,12,12,13,12,13,13,12,2,13,13,12,2,13,13,12,2,13,12,13,13,13,13,13,13,13,13,13,13,13,13,13,12
        db 13,13,13,13,13,13,13,13,13,13,13,13,13,12,13,13,12,12,13,13,12,12,12,12,12,12,13,12,13,13,12,2,13,13,12,2,2
        db 2,2,2,13,12,13,13,13,13,13,13,13,13,13,13,13,13,13,12,13,13,13,13,13,13,13,13,13,13,13,13,13,12,2,12,12,12,12,12,12,12,12,12,12,12,12,12
DefImageStruct mnuMain.QuitImg,14,14
        db 15,15,15,2,2,2,2,2,2,2,15,15,15,2,15,15,15,15,2,2,2,2,2,15,15,15,15,14,15,15,15,15,15,2,2,2,15,15,15,15,15,14
        db 14,15,15,15,15,15,2,15,15,15,15,15,14,14,2,14,15,15,15,15,15,15,15,15,15,14,14,2,2,2,14,15,15,15,15,15,15,15
        db 14,14,2,2,2,2,2,14,15,15,15,15,15,14,14,2,2,2,2,2,2,15,15,15,15,15,15,15,2,2,2,2,2,2,15,15,15,15,15,15,15,15
        db 15,2,2,2,2,15,15,15,15,15,14,15,15,15,15,15,2,2,15,15,15,15,15,14,14,14,15,15,15,15,15,2,15,15,15,15,14,14,2
        db 2,14,15,15,15,15,14,15,15,15,14,14,2,2,2,2,14,15,15,15,14,2,14,14,14,2,2,2,2,2,2,14,14,14,14


section text
        tab1.Name: db "Menu"
        tab2.Name: db "Goto"
        tab3.Name: db "Color"
        tab4.Name: db "Unit"
        tab5.Name: db "Mode"
        tab6.Name: db "Pal"
        tab7.Name: db "Map"
        tab8.Name: db "File"
        tab9.Name: db "Tiles"
        tab10.Name: db "?"
        atrbaritem12.Name: db "@24048576r"
        atrbaritem13.Name: db "Color Blocks"
        atrbaritem14.Name: db "=45h"
        atrbaritem15.Name: db "#4+"
        atrbaritem16.Name: db "&FFFF"
        atrbaritem17.Name: db ">>0"
        atrbaritem18.Name: db "x32"
        atrbaritem19.Name: db "Brush"
        atrbaritem20.Name: db "allstars.smc"
        titlebar22.Text: db "Tiles Window"
        button27.Text: db "Drop Menu >>"
        label30.Text: db "Draw"
        label31.Text: db "Fill"
        label32.Text: db "Associate"
        label33.Text: db "Flood"
        label34.Text: db "Select"
        titlebar37.Text: db "Goto/Find"
        textprompt39.Text: db ">23<=48,a,b,a,b+3ab"
        times 50 db 0
        button40.Text: db "Find"
        button41.Text: db "Scan"
        button42.Text: db "Frwd"
        textprompt44.Text: db "102492 ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏ More text to make this prompt long enough to scroll"
        ;textprompt44.Text equ Keyboard.Buffer
        times 50 db 0
        label47.Text: db "Position"
        button50.Text: db "Goto"
        button51.Text: db "Seek"
        button52.Text: db "Base"
        button53.Text: db "Insert"
        button54.Text: db "Delete"
        button55.Text: db "Edit"
        mnuMain.0: db "File",0
        mnuMain.1: db "Control",0
        mnuMain.2: db "Seek",0
        mnuMain.3: db "Goto",0
        mnuMain.4: db "View",0
        mnuMain.5: db "Options",0
        mnuMain.6: db "Quit",0
        mnuFile.0: db "Load...",0
        mnuFile.1: db "Save...",0
        mnuFile.2: db "Record...",0
        mnuFile.3: db "Settings >",0
        mnuFile.4: db "Export wave >",0
        mnuFile.5: db "Log disassembly",0
        mnuFileSets.0: db "Reload",0
        mnuFileSets.1: db "Save",0
        mnuFileSets.2: db "Always",0
        mnuFileSets.3: db "Prompt",0
        mnuFileSets.4: db "Never",0

        ButtonNotReady: db "If only... Sorry, none of the buttons do anything yet :-/",13
                        db "Like I said, I'm ",'"working" on a Windows version ;-)',0
        .len equ $-ButtonNotReady
        TabNotReady: db "This is a test and only a test,",13,13
                     db "Had this been a real emergency,",13
                     db "the beep you just heard would have been followed",13
                     db "by at least some semi-useful reaction",0
        .len equ $-TabNotReady

section data
aligndd
WndMoverTimer: dd 0
section code

aligndd
dd ButtonOwner
ButtonOwner:
;%ifdef WinVer
;    api MessageBeep, MB_OK
;    api MessageBox, [hwnd],TabNotReady,Program.Title,MB_ICONEXCLAMATION|MB_TASKMODAL|MB_SETFOREGROUND|MB_TOPMOST
;%endif
    or dword [button40+GuiObj.Flags],GuiObj.Disabled
    cmp [WndMoverTimer],dword 0
    je .SetTimer

    push dword WndMover
    call DestroyTimerObj
    pop dword [WndMoverTimer]
    clc
    ret

.SetTimer:
    push dword WndMover
    call CreateTimer
    mov [WndMoverTimer],esi
    pop eax
    clc
    ret

aligndd
dd MenuButtonOwner
MenuButtonOwner:
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; (dword parent submenu ptr,
;  dword selected submenu,
;  dword owner,
;  dword flags/alignment
;  words top,left
;  words height,width)
; (; ebx)
    mov ebx,button27
    push dword [ebx+GuiObj.Size]
    call GetItemAbsPosition
    push cx
    push dx
    push dword FloatMenuObj.AlignCol|FloatMenuObj.AlignRow
    push dword NullGuiItem
    push dword mnuMain
    push dword mnuMain
    call FloatMenuCode.Show
    add esp,byte 24
    ;clc
    ret

aligndd
dd TabOwner
TabOwner:
    cmp al,TabStripMsg.Activate
    jne .Ignore
%ifdef WinVer
    api MessageBox, [hwnd],ButtonNotReady,Program.Title,MB_OK|MB_ICONINFORMATION|MB_TASKMODAL|MB_SETFOREGROUND|MB_TOPMOST
%endif
.Ignore:
    stc
    ret

dd WndMover
WndMover:
    mov ebx,window36
    mov eax,[ebx+GuiObj.Pos]
    add eax,1<<16;64<<16
    cmp eax,438<<16
    jb .Continue
    push dword WndMover
    call DestroyTimerObj
    pop dword [WndMoverTimer]
    ret
.Continue:
    push dword 80008000h        ;size (unchanged)
    push eax
    mov eax,Msg.MoveSize
    call SendContainerMsg
    add esp,byte 8
.Skip:
    ret

FloatPicCode:
    cmp al,Msg.Redraw
    jne .NotRedraw
    push dword 27;213 ;transparent color index
    push dword FloatPicImage
    push dword [ebx+GuiObj.Size]  ;200|(256<<16)
    push dword 0
    call DrawImageTrans
    add esp,byte 16
    ;clc
    ret
.NotRedraw:
    cmp al,Msg.SetMouseFocus
    jne .Ignore
    ;mov eax,Msg.SetMouseFocus|MouseFocusFlags.SetContainer
    jmp SendContainerMsg
.Ignore:
    mov ebx,windowbg56
    mov [esp+4],ebx
    jmp WindowBgCode

EfxFrameCode:
    ;jmp FrameCode
    cmp al,Msg.Redraw
    jne near FrameCode

    push dword [Display.Ptr]
    push dword [Display.Height]
    push dword [Display.Width]
    mov dword [Display.Ptr],.DisplayBuffer
    mov dword [Display.Height],384
    mov dword [Display.Width],200
    push ebx
    call FrameCode
    pop ebx
    pop dword [Display.Width]
    pop dword [Display.Height]
    pop dword [Display.Ptr]

%if 0
; darken with black hash
    mov edi,.DisplayBuffer
    mov eax,00FF00FFh
    mov ebx,384
.NextRow:
    mov ecx,200/4
.NextCol:
    and [edi],eax
    add edi,byte 4
    dec ecx
    jg .NextCol
    rol eax,8
    dec ebx
    jg .NextRow
%elif 0
; flip buffer vertically
    mov esi,.DisplayBuffer
    mov edi,.DisplayBuffer+(383*200)
    mov ebx,384/2
.NextRow:
    mov ecx,200 -4
.NextCol:
    mov eax,[esi+ecx]
    xchg [edi+ecx],eax
    mov [esi+ecx],eax
    sub ecx,byte 4
    jge .NextCol
    add esi,200
    sub edi,200
    dec ebx
    jg .NextRow
%endif

%if 0
    push dword .DisplayBuffer
    push dword 384|(200<<16)
    push dword 0
    call DrawImageOpaque
    add esp,byte 12
%elif 0
    push dword 3
    push dword .DisplayBuffer
    push dword 384|(200<<16)
    push dword 0
    call DrawImageTrans
    add esp,byte 16
%elif 1
    push dword .ColorMap
    push dword .DisplayBuffer
    push dword 384|(200<<16)
    push dword 0
    call DrawImageMapped
    add esp,byte 16
%endif

    ret

section bss
.DisplayBuffer: resb 384*200
section data
;.ColorMap:      db 1,2,3,4,5,5, 6,7,8,9,10,11,12,13,14,15
.ColorMap:      db 1,2,8,6,7,11, 6,7,8,9,10,11,12,13,14,15
section code

section data
    FloatPicImage: incbin "testpic.lbm"
