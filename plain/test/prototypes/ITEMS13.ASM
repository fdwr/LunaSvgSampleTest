%define ProgramTitleDef "ANSI Character Test"
%define ProgramClassDef "PknAnsiCharTest"

        DefWindow textprompt17,0,0
        DefContainedItem windowbg0
        DefContainedItem label1
        DefContainedItem label2
        DefContainedItem label3
        DefContainedItem label4
        DefContainedItem label5
        DefContainedItem label6
        DefContainedItem label7
        DefContainedItem label8
        DefContainedItem label9
        DefContainedItem label10
        DefContainedItem label11
        DefContainedItem label12
        DefContainedItem label13
        DefContainedItem label14
        DefContainedItem label15
        DefContainedItem border16
        DefContainedItem textprompt17
        DefContainedItem button18
        DefContainedItem button19
      %ifdef WinVer
        DefContainedItem button20
        DefContainedItem button21
      %endif
        DefWindowEnd

DefItem windowbg0,WindowNcCode,0,WindowNcObj.DefGuiFlags, 0,0,Screen.Height,Screen.Width
DefItem label1,LabelCode,0,LabelObj.DefGuiFlags, 6,6,16,240
        DefLabel label1.Text,19,LabelObj.AlignLeft
DefItem label2,LabelCode,0,LabelObj.DefGuiFlags, 52,8,16,180
        DefLabel label2.Text,15,LabelObj.AlignLeft
DefItem label3,LabelCode,0,LabelObj.DefGuiFlags, 68,8,16,180
        DefLabel label3.Text,16,LabelObj.AlignLeft
DefItem label4,LabelCode,0,LabelObj.DefGuiFlags, 84,8,16,180
        DefLabel label4.Text,16,LabelObj.AlignLeft
DefItem label5,LabelCode,0,LabelObj.DefGuiFlags, 100,8,16,180
        DefLabel label5.Text,17,LabelObj.AlignLeft
DefItem label6,LabelCode,0,LabelObj.DefGuiFlags, 116,8,16,180
        DefLabel label6.Text,16,LabelObj.AlignLeft
DefItem label7,LabelCode,0,LabelObj.DefGuiFlags, 132,8,16,180
        DefLabel label7.Text,15,LabelObj.AlignLeft
DefItem label8,LabelCode,0,LabelObj.DefGuiFlags, 148,8,16,180
        DefLabel label8.Text,16,LabelObj.AlignLeft
DefItem label9,LabelCode,0,LabelObj.DefGuiFlags, 164,8,16,180
        DefLabel label9.Text,16,LabelObj.AlignLeft
DefItem label10,LabelCode,0,LabelObj.DefGuiFlags, 180,8,16,180
        DefLabel label10.Text,16,LabelObj.AlignLeft
DefItem label11,LabelCode,0,LabelObj.DefGuiFlags, 196,8,16,180
        DefLabel label11.Text,16,LabelObj.AlignLeft
DefItem label12,LabelCode,0,LabelObj.DefGuiFlags, 212,8,16,180
        DefLabel label12.Text,16,LabelObj.AlignLeft
DefItem label13,LabelCode,0,LabelObj.DefGuiFlags, 228,8,16,180
        DefLabel label13.Text,16,LabelObj.AlignLeft
DefItem label14,LabelCode,0,LabelObj.DefGuiFlags, 244,8,16,180
        DefLabel label14.Text,16,LabelObj.AlignLeft
DefItem label15,LabelCode,0,LabelObj.DefGuiFlags, 260,8,16,180
        DefLabel label15.Text,16,LabelObj.AlignLeft
DefItem border16,BorderCode,0,BorderObj.DefGuiFlags, 24,4,24,300
        textprompt17.MaxLen equ 25+50
DefItem textprompt17,TextPromptCode,NullGuiItem,TextPromptObj.DefGuiFlags, 26,6,20,296
        DefTextPrompt textprompt17.Text,25,textprompt17.MaxLen,0
DefItem button18,ButtonCode,btnCloseOwner,ButtonObj.DefGuiFlags, 54,230,24,72
        DefPushButton button18.Text,5,0
DefItem button19,ButtonCode,btnClickOwner,ButtonObj.DefGuiFlags, 82,230,24,72
        DefPushButton button19.Text,11,0
      %ifdef WinVer
DefItem button20,ButtonCode,btnAboutOwner,ButtonObj.DefGuiFlags, 110,230,24,72
        DefPushButton button20.Text,8,0
DefItem button21,ButtonCode,btnSysMenuOwner,ButtonObj.DefGuiFlags, 138,230,24,72
        DefPushButton button21.Text,7,0
      %endif

        label1.Text: db "ANSI character test"
        label2.Text: db " !#$%&'()*+,-./"
        label3.Text: db "0123456789:;<=>?"
        label4.Text: db "@ABCDEFGHIJKLMNO"
        label5.Text: db "PQRSTUVWXYZ[\]^_"
        label6.Text: db "`abcdefghijklmno"
        label7.Text: db "pqrstuvwxyz{|}~"
        label8.Text: db "€‚ƒ„…†‡ˆ‰Š‹Œ"
        label9.Text: db "‘’“”•–—˜™š›œŸ"
        label10.Text: db " ¡¢£¤¥¦§¨©ª«¬­®¯"
        label11.Text: db "°±²³´µ¶·¸¹º»¼½¾¿"
        label12.Text: db "ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏ"
        label13.Text: db "ĞÑÒÓÔÕÖ×ØÙÚÛÜİŞß"
        label14.Text: db "àáâãäåæçèéêëìíîï"
        label15.Text: db "ğñòóôõö÷øùúûüışÿ"
        textprompt17.Text: db "(type special chars here)"
        times 50 db 0
        button18.Text: db "Close"
        button19.Text: db "Click Koro!"
      %ifdef WinVer
        button20.Text: db "About..."
        button21.Text: db "SysMenu"
      %endif
        AboutText:  db "Written to test the extended ANSI character set, "
                    db "specifically character page cf 863",13
                    db 10,10
                    db "Peekin 2002-07-01",0,"$"

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section bss
Fire:
.ShadeRange equ 80
.ShadeSep   equ 40
.RndValue:  resd 0BFFCh

Particles:
.MaxCount   equ 2000
.Brightness equ 22;18
.MaxDistance equ 800
.Distance:  resd .MaxCount      ;distance of particle from center
.AngleY:    resd .MaxCount      ;y rotation (clockwise/countercw)
.AngleZ:    resd .MaxCount      ;z rotation (forward/backward)
section data
.BaseY:     dd Screen.Height/2
.BaseX:     dd Screen.Width/2
section bss

section data
aligndd
SineTable:
.Degrees    equ 1024
incbin "..\win\sinewave.dat"

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section code

dd btnCloseOwner
btnCloseOwner:
  %ifdef WinVer
    api PostQuitMessage,0
  %else
    and dword [GuiFlags],~GuiFlags.Active
  %endif
    ret

dd btnAboutOwner
btnAboutOwner:
  %ifdef WinVer
    api MessageBox, [hwnd],AboutText,ProgramTitle,MB_OK|MB_ICONINFORMATION
  %else
    mov ah,9
    mov edx,AboutText
    int 21h
  %endif
    ret

dd btnSysMenuOwner
btnSysMenuOwner:
  %ifdef WinVer
    ;push dword [hwnd]
    ;push dword WM_SYSCOMMAND
    ;push dword SC_TASKLIST
    ;push dword 100|(100<<16)
    ;call [DefWindowProc]

    api GetSystemMenu, [hwnd],FALSE
    xor edx,edx
    pushrev eax,dword SC_SIZE,edx,   eax,dword SC_MAXIMIZE,edx,  eax, edx, dword [msg+MSG.x],dword [msg+MSG.y], edx, dword [hwnd], edx
    api RemoveMenu;, eax,SC_SIZE,0
    api RemoveMenu;, eax,SC_MAXIMIZE,0
    api TrackPopupMenu;, eax, 0, [msg+MSG.x],[msg+MSG.y], 0, [hwnd], NULL
    clc
  %else
    stc
  %endif
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
dd btnClickOwner
btnClickOwner:
    push dword AnimateFire
    cmp [AnimateFire.Timer],dword 0
    je .SetTimer

    ;push dword AnimateFire
    call DestroyTimerObj
    mov [esp],dword 0
    pop dword [AnimateFire.Timer]
    mov dword [windowbg0+GuiObj.Code],WindowNcCode
    or dword [MainWindow+GuiObj.Flags],GuiObj.RedrawBg|GuiObj.Redraw
    mov dword [MainWindow+WindowObj.RedrawTopLeft],0
    mov dword [MainWindow+WindowObj.RedrawBtmRight],Screen.Height|(Screen.Width<<16)
    clc
    ret

.SetTimer:
    call InitParticles
    call CreateFirePalette
    ;debugpause "before clear screen"
    cld
    mov edi,Screen.Buffer
    mov ecx,(Screen.Height*Screen.Width)/4
    xor eax,eax
    rep stosd
  %ifdef DosVer
    mov esi,Display.Palette
    call SetPalette
  %endif

    ;push dword AnimateFire
    call CreateTimer
    ;debugpause "timer =%x",esi
    mov [AnimateFire.Timer],esi
    pop eax
    mov dword [windowbg0+GuiObj.Code],InterceptNcCode
    clc
    ret

InterceptNcCode:
    cmp eax,Msg.Redraw
    jne near WindowNcCode
    stc
    ret

dd AnimateFire
AnimateFire:
    call AdvanceFlames
    call DrawParticles
    or dword [MainWindow+GuiObj.Flags],GuiObj.RedrawBg|GuiObj.Redraw
    mov dword [MainWindow+WindowObj.RedrawTopLeft],0
    mov dword [MainWindow+WindowObj.RedrawBtmRight],Screen.Height|(Screen.Width<<16)

    ret

section data
.Timer: dd 0
section code


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; create fire palette
CreateFirePalette:
    cld
    mov edi,Display.Palette+(16*4)
    mov ecx,256-16
    mov eax,4                   ;PC_RESERVED=1,PC_EXPLICIT=2,PC_NOCOLLAPSE=4
    ;xor eax,eax
    rep stosd
    ;xor ecx,ecx

    mov edi,Display.Palette+2   ;for blue fire
    ;mov edi,Display.Palette
    mov dl,3
.NextColor:                     ; alternate palette generation
    xor eax,eax                 ; (Patrick Sundberg)
    push edi
    xor ebx,ebx                 ;zero accumulator
    ;ecx=0
    mov cl,Fire.ShadeRange-1
.L1:
    mov ah,al
    shl ah,2
    cmp edi,Display.Palette+(16*4)
    jb .SkipColor
    mov [edi],ah
.SkipColor:
    add ebx,(4194304/Fire.ShadeRange)<<16
    adc eax,0
    add edi,byte 4
    loop .L1
    ;ecx=0
    ;mov cl,256-Fire.ShadeRange+1
.L2:
    mov [edi],ah
    add edi,byte 4
    cmp edi,Display.Palette+1024
    jb .L2
    pop edi
    add edi,Fire.ShadeSep*4-1 ;for blue fire
    ;add edi,Fire.ShadeSep*4+1
    dec dl
    jg .NextColor
    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
InitParticles:
    mov edi,(Particles.MaxCount-1)*4
;%define UseSimpleRnd
%ifdef UseSimpleRnd
    mov eax,0BFFCh
%else
    mov eax,082775212h          ; set initial seed values
    mov ebx,03914AC5Fh
    mov ecx,0B460D9C3h
%endif
.Next:
    call .GetRng
    and esi,SineTable.Degrees-1
    mov dword [Particles.AngleY+edi],esi
    call .GetRng
    and esi,SineTable.Degrees-1
    mov dword [Particles.AngleZ+edi],esi
    call .GetRng
    ;and esi,255
    ;or esi,128
    ;mov dword [Particles.Distance+edi],esi
    push eax
    xor edx,edx
    mov esi,Particles.MaxDistance
    div esi
    mov dword [Particles.Distance+edi],200
    pop eax
    sub edi,byte 4
    jge .Next
    ret

; (eax=previous random value)
; (eax=new random value, edx=eax)
.GetRng:
%ifdef UseSimpleRnd
    mov ecx,33797
    mul ecx
    inc eax
%else
    mov edx,ecx                 ; R4=R3
    mov ecx,ebx                 ; R3=R2
    mov ebx,eax                 ; R2=R1

    mov eax,edx                 ; R1 = R4 + (R3<=R2 ? R3 : R2)
    cmp ecx,ebx
    jbe .Less
    add eax,ebx                 ; +R2
    jmp short .EndRng
.Less:
    add eax,ecx                 ; +R3
.EndRng:
%endif
    mov esi,eax                 ;make copy
    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; advance flames by one frame
AdvanceFlames:

; flame animation, smoothing
    xor edx,edx
    mov ecx,Screen.Width
    xor eax,eax
    mov ebx,(Screen.Height/2)+1
    mov edi,Screen.Buffer
.FsNext:
    mov ax,[edi+(Screen.Width*2)-1]
    add al,ah                         
    setc ah
    mov dl,[edi+(Screen.Width*2)+1]
    add eax,edx
    mov dl,[edi+(Screen.Width*4)]
    add eax,edx
    shr eax,2
    jz .Zero                    ; cool a bit...
    dec eax
.Zero:
    cmp al,16
    jae .FlameClr
    xor al,al
.FlameClr:
    stosb
    add eax,edx                 ; double the height
    shr eax,1
    adc eax,0
    cmp al,16
    jae .FlameClr2
    xor al,al
.FlameClr2:
    mov [edi+Screen.Width-1],al
    loop .FsNext
    mov ecx,Screen.Width
    add edi,ecx                 ;skip a line
    dec ebx
    jg .FsNext


;%if 0
; flame generator bottom bar
    mov ecx,Screen.Width
    ; assumes edi=generator bar offset (bottom of flame buffer)
.FgNext:
    ;in ax,40h                  ; read from timer
    ;push ax
    ;add ax,[Fire.RndValue]
    ;pop word [Fire.RndValue]   ; "seed" is first two bytes of code
    ;mov ah,al
    mov eax,33797
    mul dword [Fire.RndValue]
    inc eax
    mov [Fire.RndValue],eax
    and ah,03Fh
    add ah,100;0CFh
    mov al,ah
    stosw
    stosw
    loop .FgNext
;%endif


; flame feedback
; feeds fire back into itself for more turbulent flame variation
    mov ecx,Screen.Width
    mov edi,Screen.Buffer+(Screen.Width*(Screen.Height+4))  ;plasma (likely my favorite)
.FfNext:
    mov al,[edi+(Screen.Width*-101)]  ;top of flames feed back into bottom
    ;shl al,5                     ;select top three bits
    ;and al,111011b
    ;xor al,1010110b
    shl al,3                     ;select top bits
    add [edi],al
    inc edi
    loop .FfNext

DoNothing:
    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
DrawParticles:
    mov ebx,(Particles.MaxCount-1)*4
.Next:
    ; xy distance = z * distance
    mov eax,[Particles.AngleZ+ebx]
    mov eax,[SineTable+eax*4]
    imul eax,[Particles.Distance+ebx]
    ;imul eax,150
    sar eax,16
    ;mov eax,50

    ; x & y
    mov edx,[Particles.AngleY+ebx]
    mov ecx,edx
    mov edx,[SineTable+edx*4]
    add ecx,256                 ;get cosine
    imul edx,eax
    and ecx,1024-1
    sar edx,16
    mov ecx,[SineTable+ecx*4]
    imul ecx,eax
    sar ecx,16
    add edx,[Particles.BaseY]
    add ecx,[Particles.BaseX]

; (edx=row, ecx=col)
.At:
    cmp edx,Screen.Height
    jae .OffScreen
    cmp ecx,Screen.Width
    jae .OffScreen
%if Screen.Width=320
    mov eax,edx
    shl edx,6
    shl eax,8
    add edx,eax
%elif Screen.Width=640
    mov eax,edx
    shl edx,7
    shl eax,9
    add edx,eax
%else
    imul edx,Screen.Width
%endif
    add [Screen.Buffer+edx+ecx],byte Particles.Brightness
    jnc .NoOverFlow
    mov [Screen.Buffer+edx+ecx],byte 255
.NoOverFlow:
.OffScreen:

    ; move particle for next frame
    add dword [Particles.AngleY+ebx],byte 2
    and dword [Particles.AngleY+ebx],SineTable.Degrees-1
    add dword [Particles.AngleZ+ebx],byte 3
    and dword [Particles.AngleZ+ebx],SineTable.Degrees-1

    sub ebx,byte 4
    jns near .Next
    ret
