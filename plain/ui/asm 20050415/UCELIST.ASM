;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
ListCode:

section data
    StartMsgJtbl
    ;AddMsgJtbl Msg.Created,.UpdateScrollHandle
    ;AddMsgJtbl Msg.Redraw,.Draw
    ;AddMsgJtbl Msg.Focus,.ItemFocus
    ;AddMsgJtbl Msg.KeyPress,.KeyPress
    ;AddMsgJtbl Msg.MousePrsRls,.MousePrsRls
    ;AddMsgJtbl Msg.MouseMove,.MouseMove
    AddMsgJtbl Msg.MouseIn,.MouseIn
    ;AddMsgJtbl Msg.MouseOut,.MouseOut

.KeysJtbl:
    ;dd .KeyUp
    ;dd .KeyDown
    ;dd .KeyLeft
    ;dd .KeyRight
    ;dd .KeyHomeRow
    ;dd .KeyEndRow
    ;dd .KeyHomeCol
    ;dd .KeyEndCol
    ;dd .KeyBkSpc

.Keys:
    db 0,VK_UP
    db 0,VK_DOWN
    db 0,VK_LEFT
    db 0,VK_RIGHT
    db 2,VK_HOME,   1,VK_CONTROL
    db 2,VK_END,    1,VK_CONTROL
    db 0,VK_HOME
    db 0,VK_END
    db 0,VK_BACK
    db -1

.DrawRow    equ CommonItemCode.DrawRowW
.DrawCol    equ CommonItemCode.DrawColW
.SelRow     equ CommonItemCode.SelRow
section code


    UseMsgJtbl

;컴컴컴컴컴컴컴컴컴컴
.MouseIn:
    mov eax,Msg.SetItemFocus|FocusMsgFlags.Specified|FocusMsgFlags.SetItem|FocusMsgFlags.SetGroup|FocusMsgFlags.ByMouse
    call SendContainerMsg
    jmp SetCursorImage.Default
    ;clc
    ;ret
