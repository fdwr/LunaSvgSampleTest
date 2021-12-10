; Compiles into VKC.DAT
%INCLUDE "KEYCODES.ASM"

;-----------------------------------------------------------------------------
; Scancode to virtual keycode table

    db 0 ;0
    db VK_ESCAPE    ;1
    db VK_1         ;2
    db VK_2         ;3
    db VK_3         ;4
    db VK_4         ;5
    db VK_5         ;6
    db VK_6         ;7
    db VK_7         ;8
    db VK_8         ;9
    db VK_9         ;A
    db VK_0         ;B
    db VK_MINUS     ;C
    db VK_PLUS      ;D
    db VK_BACK      ;E
    db VK_TAB       ;F
    db VK_Q         ;10
    db VK_W         ;11
    db VK_E         ;12
    db VK_R         ;13
    db VK_T         ;14
    db VK_Y         ;15
    db VK_U         ;16
    db VK_I         ;17
    db VK_O         ;18
    db VK_P         ;19
    db VK_LBRACKET  ;1A
    db VK_RBRACKET  ;1B
    db VK_RETURN    ;1C
    db VK_CONTROL   ;1D
    db VK_A         ;1E
    db VK_S         ;1F
    db VK_D         ;20
    db VK_F         ;21
    db VK_G         ;22
    db VK_H         ;23
    db VK_J         ;24
    db VK_K         ;25
    db VK_L         ;26
    db VK_COLON     ;27
    db VK_QUOTE     ;28
    db VK_TILDE     ;29
    db VK_SHIFT     ;2A
    db VK_SLASH     ;2B
    db VK_Z         ;2C
    db VK_X         ;2D
    db VK_C         ;2E
    db VK_V         ;2F
    db VK_B         ;30
    db VK_N         ;31
    db VK_M         ;32
    db VK_COMMA     ;33
    db VK_PERIOD    ;34
    db VK_OEM_2     ;35
    db VK_SHIFT     ;36
    db VK_MULTIPLY  ;37 (Also VK_SNAPSHOT)
    db VK_MENU      ;38
    db VK_SPACE     ;39
    db VK_CAPITAL   ;3A
    db VK_F1        ;3B
    db VK_F2        ;3C
    db VK_F3        ;3D
    db VK_F4        ;3E
    db VK_F5        ;3F
    db VK_F6        ;40
    db VK_F7        ;41
    db VK_F8        ;42
    db VK_F9        ;43
    db VK_F10       ;44
    db VK_PAUSE     ;45
    db VK_SCROLL    ;46
    db VK_HOME      ;47
    db VK_UP        ;48
    db VK_PAGEUP    ;49 (PRIOR)
    db VK_SUBTRACT  ;4A
    db VK_LEFT      ;4B
    db VK_NUMPAD5   ;4C
    db VK_RIGHT     ;4D
    db VK_ADD       ;4E
    db VK_END       ;4F
    db VK_DOWN      ;50
    db VK_PAGEDOWN  ;51 (NEXT)
    db VK_INSERT    ;52
    db VK_DELETE    ;53
    db 0 ;54
    db 0 ;55
    db 0 ;56
    db VK_F11       ;57
    db VK_F12       ;58
    db 0 ;59
    db 0 ;5A
    db 0 ;5B
    db 0 ;5C
    db 0 ;5D
    db 0 ;5E
    db 0 ;5F
    db 0 ;60
    db 0 ;61
    db 0 ;62
    db 0 ;63
    db 0 ;64
    db 0 ;65
    db 0 ;66
    db 0 ;67
    db 0 ;68
    db 0 ;69
    db 0 ;6A
    db 0 ;6B
    db 0 ;6C
    db 0 ;6D
    db 0 ;6E
    db 0 ;6F
    db 0 ;70
    db 0 ;71
    db 0 ;72
    db 0 ;73
    db 0 ;74
    db 0 ;75
    db 0 ;76
    db 0 ;77
    db 0 ;78
    db 0 ;79
    db 0 ;7A
    db 0 ;7B
    db 0 ;7C
    db 0 ;7D
    db 0 ;7E
    db 0 ;7F

;-----------------------------------------------------------------------------
; ASCII to ANSI conversion table
; Since ASCII and ANSI characters are mapped differently

    db 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
    db 16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31
    db ' !"',"#$%&'()*+,-./"
    db "0123456789:;<=>?"
    db "@ABCDEFGHIJKLMNO"
    db "PQRSTUVWXYZ[\]^_"
    db "`abcdefghijklmno"
    db "pqrstuvwxyz{|}~"

    ; ANSI (Notepad)      ASCII (Edit)
    db "«¸È‚‰‡ÂÁÍÎËÔÓÏƒ≈" ;"ÄÅÇÉÑÖÜáàâäãåçéè"
    db "…Ê∆ÙˆÚ˚˘ˇ÷‹¢£•PÉ" ;"êëíìîïñóòôöõúùûü"
    db "·ÌÛ˙Ò—™∫ø_¨Ωº°´ª" ;"†°¢£§•¶ß®©™´¨≠ÆØ"
    db "___¶¶¶¶++¶¶+++++" ;"∞±≤≥¥µ∂∑∏π∫ªºΩæø"
    db "+--+-+¶¶++--¶-+-" ;"¿¡¬√ƒ≈∆«»… ÀÃÕŒœ"
    db "-=-+++++=++_=¶¶=" ;"–—“”‘’÷◊ÿŸ⁄€‹›ﬁﬂ"
    db "_ﬂ_∂__µ_________" ;"‡·‚„‰ÂÊÁËÈÍÎÏÌÓÔ"
    db "_±____˜_∞ï∑_n≤__" ;"ÒÚÛÙıˆ˜¯˘˙˚¸˝˛ˇ"

;-----------------------------------------------------------------------------
%if 0
; Scancode to character conversion tables (American English, QWERTY codepage)
;
; Not included because there are too many international variations and
; keyboard configurations that make this mapping useless.

    db 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0   ;0
    db 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0   ;1
    db 32,0,0,0,0,0,0,0, 0,0,0,0, 0,0,0,0   ;2
    db "0123456789",         0,0, 0,0,0,0   ;3
    db 0,"abcdefghijklmno"                  ;4
    db "pqrstuvwxyz",          0, 0,0,0,0   ;5
    db "0123456789*+|-./"                   ;6
    db 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0   ;7

    db 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0   ;8
    db 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0   ;9
    db 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0   ;A
    db 0,0,0,0, 0,0,0,0, 0,0,';=',',-./'    ;B
    db '`',0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0   ;C
    db 0,0,0,0, 0,0,0,0, 0,0,0,"[\]'",  0   ;D
    db 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0   ;E
    db 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0   ;F

;-----------------------------------------------------------------------------
    db 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0   ;0
    db 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0   ;1
    db 32,0,0,0,0,0,0,0, 0,0,0,0, 0,0,0,0   ;2
    db ")!@#$%^&*(",         0,0, 0,0,0,0   ;3
    db 0,"ABCDEFGHIJKLMNO"                  ;4
    db "PQRSTUVWXYZ",          0, 0,0,0,0   ;5
    db "0123456789*+|-./"                   ;6
    db 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0   ;7

    db 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0   ;8
    db 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0   ;9
    db 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0   ;A
    db 0,0,0,0, 0,0,0,0, 0,0,':+','<_>?'    ;B
    db '~',0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0   ;C
    db 0,0,0,0, 0,0,0,0, 0,0,0,'{|}"',  0   ;D
    db 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0   ;E
    db 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0   ;F
%endif
