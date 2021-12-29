;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Graphics Routines
;
; Todo:
;   Add palette management for Window's version when in 256 color mode.
;
; Supports lines, rectangles, simple fonts (2 colors with transparency),
; mouse cursors, screen clearing, palette setting, transparent images, color
; mapped images, and rectangular clipping. All the routines can theoretically
; work with a screen of ANY size, but unfortunately only 16bit pixels.
;
; These routines are mainly used in my GUI, but can actually used with any
; program. Theoretically, since they are all self contained and can all draw
; to a virtual screen (rather than directly, which can be done too), it is
; possible to use them under any 32bit x86 OS, either DOS, Windows, or Linux.
;
; Since there are quite a few routines in this source, in an effort to reduce
; executable bloat, only routines defined as 'used' are included in the
; compile. If a program never uses the mouse cursor, it would be pointless to
; fill the executable with dead code, so just leave UseGuiCursor undefined.
;
; Mouse cursor routines = UseGuiCursor
; Font routines = UseGuiFonts
; GUI specific clipping = UseGuiGfx
; Default palette = UseGuiPalette
; Display buffer = UseDisplayBuffer (interrim virtual screen)
;
;
; DrawPoint                     draws single pixel of given color
; DrawRect                      draws solid color rectangle
; DrawHline                     draws horizontal line
; DrawVline                     vertical line
; DrawBorder                    draws a concave/convex shaded border
; BlitTwoColorFont              draws single character
; BlitTwoColorFontV             draws single character vertically right 90ø
; BlitString                    blits text string
; BlitStringV                   blits text string vertically
; ClearScreen
; SetPalette
; DrawImageOpaque               draws 8bit indexed image opaquely
; DrawImageTrans                draws image with transparency
; DrawImageMapped               draws image using colormap
; DrawImageTiled                draws an opaque image tiled.
; DrawCursor                    gets background behind cursor and draws image
; HideCursor                    restores background behind cursor
; ClipCursorImage               used only by the draw/hide cursor functions
; TransferCursorArea            used only by the draw/hide cursor functions
; SetCursorImage                sets current cursor appearance
; GetRectClips                  determines clips for rectangular region
; GetFontClips                  determines clips for font string
; SaveClips                     saves current clips on stack
; RestoreClips
; SaveDisplayVars               saves display variables on stack
; RestoreDisplayVars
; TransferScreen                transfers screen buffer to physical screen
; GetTextLenWidth               returns pixel width of given string length
; GetTextWidthLen               returns character length of given pixel width
; SetRedrawArea                 sets redraw area to given boundary
; OrRedrawArea                  combines given boundary with redraw area
; AndClips                      determines intersection of two clip sets
; OrClips                       combines display clips with saved clips
; CopyClips                     copies clips from one set to another
; EmptyClips                    sets clip set to its minimum extents
; OffsetGuiClips                adds GUI item's offset to clips
; SetGuiItemClips               sets clips for specified GUI item
; SetGuiItemRedraw              sets redraw area for specified GUI item
; AddClipsToRedrawRange         marks area as needing transfering to screen

%ifndef GfxDefsInc
%include "gfxdefs.asm"          ;Requires graphics definitions
%endif

GfxAddressCheck equ -1

section code
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; The simplest possible graphics routine, and yet never actually needed until
; MUCH later for the help bubble (after 35 others had already been completed)
; (words Row, Col, Color)
DrawPoint:
    movsx edi,word [esp+4]      ; get top row
    cmp [Display.ClipTop],edi   ; if top row < top clip then return
    jg .FullClip
    cmp [Display.ClipBtm],edi   ; if top row >= bottom clip then return
    jle .FullClip

    movsx ecx,word [esp+6]      ; get left column
    cmp [Display.ClipLeft],ecx  ; if left column < left clip then return
    jg .FullClip
    cmp [Display.ClipRight],ecx ; if left column >= right clip then return
    jle .FullClip               ;   set right column to right clip

    ; note that shifted multiplication can't be used here because this
    ; routine was designed to work with any destination of any width, not
    ; just the standard 320x200 screen.
    imul edi,[Display.Width]    ; row * screen width
    mov eax,[esp+8]             ; get color (only the lowest word)
    shl edi,1
    add edi,[Display.Ptr]

    mov [edi+ecx*2],ax          ;set pixel ((row * width) + col)
.FullClip:
    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Draw Horizontal Line
; (words TopRow, LeftCol, Width, Color)
DrawHline:
    movsx eax,word [esp+4]      ; get top row
    mov edi,[Display.Width]
    cmp [Display.ClipTop],eax   ; if top row < top clip then return
    jg .FullClip
    cmp [Display.ClipBtm],eax   ; if top row >= bottom clip then return
    jle .FullClip
    imul edi,eax

    movsx eax,word [esp+6]      ; get left column
    movzx ecx,word [esp+8]      ; get width
    cmp [Display.ClipLeft],eax
    lea ebx,[eax+ecx]           ; right column = left column + width
    jle .LeftOk                 ; if left column < left clip
    mov eax,[Display.ClipLeft]  ;   difference = left clip - left column
.LeftOk:                        ; endif
    cmp [Display.ClipRight],ebx ; if right column > right clip
    jge .RightOk                ;   set right column to right clip
    mov ebx,[Display.ClipRight] ; endif
.RightOk:
    sub ebx,eax                 ; clipped width = right side - left side
    jle .FullClip               ; exit if clipped width <= 0
    ;mov [Display.ClipWidth],ebx
    add edi,eax                 ; add column to destination
    shl edi,1                   ;*2bpp
    ;mov [Display.ClipPtr],edi

    add edi,[Display.Ptr]
    mov eax,[esp+10]            ;get color
;(edi=destination ptr, al=color, ebx=height, edx=dest wrap)
.ByReg:
    cld                         ;as always, go forward
	shrd esi,eax,16
	shld eax,esi,16
	;eax now consists of four pixels all the same color

    mov ecx,ebx                 ;copy clipped width
    shr ecx,1                   ;width / 2
	rep stosd
    mov ecx,ebx
    and ecx,1                   ;width modulus 2
    rep stosw
.FullClip:
    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Draw Vertical Line
; (words TopRow, LeftCol, Height, Color)
DrawVline:
    movsx edi,word [esp+6]      ; get left column
    mov edx,[Display.Width]
    cmp [Display.ClipLeft],edi  ; if left column < left clip then return
    jg .FullClip
    cmp [Display.ClipRight],edi ; if left column >= right clip then return
    jle .FullClip               ;   set right column to right clip

    movsx eax,word [esp+4]      ; get top row
    movzx ecx,word [esp+8]      ; get height
    cmp [Display.ClipTop],eax
    lea ebx,[eax+ecx]           ; bottom row = top row + height
    jle .TopOk                  ; if top row < top clip
    mov eax,[Display.ClipTop]   ;   difference = bottom clip - bottom column
.TopOk:                         ; endif
    cmp [Display.ClipBtm],ebx   ; if bottom row > bottom clip
    jge .BtmOk                  ;   set bottom row to bottom clip
    mov ebx,[Display.ClipBtm]   ; endif
.BtmOk:
    sub ebx,eax                 ; clipped height = bottom side - top side
    jle .FullClip               ; exit if clipped height <= 0
    ;mov [Display.ClipHeight],ebx ;return actual height blit

    imul eax,edx                ; destination = top row * screen width
    add edi,eax
    shl edi,1                   ;*2bpp
    mov eax,[esp+10]            ;get color
    shl edx,1                   ;destwidth*2bpp
    add edi,[Display.Ptr]
;(edi=destination ptr, al=color, ebx=height, edx=dest wrap)
.ByReg:
.NextRow:
    mov [edi],ax
    add edi,edx
    dec ebx
    jg .NextRow
.FullClip:
    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Draws a singled colored rectangle.
;
; (words TopRow, LeftCol, Height, Width, Color)
DrawRect.GivenCords: ;(pass four coordinates rather than Top/Left/Height/Width)
    mov ax,[esp+DrawRect.TopRow]
    mov cx,[esp+DrawRect.LeftCol]
    sub [esp+DrawRect.Height],ax
    sub [esp+DrawRect.Width],cx
DrawRect:
.TopRow     equ 4
.LeftCol    equ 6
.Size       equ 8
.Height     equ 8
.Width      equ 10
.Color      equ 12

    call GetRectClips
    jc .FullClip
    ;mov ebx,[Display.ClipWidth-2]
    shl ebx,16
    mov bx,[Display.ClipHeight]
    ;mov edi,[Display.ClipPtr]
    ;mov edx,[Display.ClipWrap]

.Start:
  %if GfxAddressCheck
    cmp edi,Screen.Bytes
    jb .Ok
    int3
  .Ok:
  %endif
    add edi,[Display.Ptr]
    mov ax,[esp+.Color]         ;get color

;(ax=color,
; ebx=height/width,
; edi=destination,
; edx=wrap (destination BYTE width)
.ByReg:                         ;calling by register can be a bit faster
    cld
    mov esi,edi                 ;copy destination

    shrd ecx,eax,16
    and esi,1                   ;get bytes to next higher word
    shld eax,ecx,16             ;fill eax dword with pixels
    shl esi,16                  ;move to upper word
    xor ecx,ecx                 ;zero top bits for loop
    sub ebx,esi                 ;remaining width = width - first strip length
    jae .WidthPositive
    add ebx,esi                 ;reverse subtraction above
    xor esi,esi
.WidthPositive:
    shr esi,16                  ;return to lower word

.NextLine:
    mov ecx,esi                 ;(-destination) % 2
    rep stosw
    shld ecx,ebx,15             ;(remaining width) \ 2
    rep stosd
    ;shld ecx,ebx,16
    ;and ecx,1                   ;(remaining width) % 2
    bt ebx,16
    adc ecx,0
    rep stosw
    add edi,edx

    ;add ax,(0<<10)|(0<<5)|1
    ;add eax,(0<<26)|(0<<21)|(1<<16)

    dec bx
    jg .NextLine
.FullClip:
    ret

.NoClip:
    movzx ecx,word [esp+.TopRow]
    movzx edx,word [esp+.Width]
    movzx eax,word [esp+.LeftCol]
    mov edi,[Display.Width]     ;get screen width
    neg edx
    add edx,edi                 ;get wrap width (screen width - rect width)
    imul edi,ecx                ;top row * screen width
    mov ebx,[esp+.Size]         ;get height and width (hl=width:height)
    add edi,eax                 ;(row * screen width) + left column
    shl edi,1                   ;*2bpp
    jmp .Start


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Repeats an alternating four pixel pattern.
;
; (words TopRow, LeftCol, Height, Width, Color)
DrawPattern.GivenCords: ;(pass four coordinates rather than Top/Left/Height/Width)
    mov ax,[esp+DrawRect.TopRow]
    mov cx,[esp+DrawRect.LeftCol]
    sub [esp+DrawRect.Height],ax
    sub [esp+DrawRect.Width],cx
DrawPattern:
.TopRow     equ 4
.LeftCol    equ 6
.Size       equ 8
.Height     equ 8
.Width      equ 10
.Color      equ 12

    call GetRectClips
    jc .FullClip
    ;mov ebx,[Display.ClipWidth-2]
    shl ebx,16
    mov bx,[Display.ClipHeight]
    ;mov edi,[Display.ClipPtr]
    ;mov edx,[Display.ClipWrap]

.Start:
  %if GfxAddressCheck
    cmp edi,Screen.Bytes
    jb .Ok
    int3
  .Ok:
  %endif
    add edi,[Display.Ptr]
    mov eax,[esp+.Color]        ;get color pattern

;(eax=color,
; ebx=height/width,
; edi=destination,
; edx=wrap (destination width))
.ByReg:                         ;calling by register can be a bit faster
    cld
    mov esi,edi                 ;copy destination
    neg esi
    xor ecx,ecx                 ;zero top bits for loop
    and esi,3                   ;get bytes to next higher dword
    shl esi,16                  ;move to upper word
    sub ebx,esi                 ;remaining width = width - first strip length
    jae .WidthPositive
    add ebx,esi                 ;reverse subtraction above
    xor esi,esi
.WidthPositive:
    shr esi,16                  ;return to lower word

.NextLine:
    push eax
    mov ecx,esi                 ;(-destination) % 4
    test esi,esi
    jle .SkipLeft
.NextLeft:
    and [edi],al
    rol eax,8                   ;rotate pattern to next pixel
    loop .NextLeft
.SkipLeft:
    shld ecx,ebx,14             ;(remaining width) \ 4
    jle .SkipMiddle
.NextMiddle:
    and [edi],eax
    rol eax,8                   ;rotate pattern to next pixel
    loop .NextMiddle
.SkipMiddle:
    shld ecx,ebx,16
    and ecx,3                   ;(remaining width) % 4
    jle .SkipRight
.NextRight:
    and [edi],al
    rol eax,8                   ;rotate pattern to next pixel
    loop .NextRight
.SkipRight:
    pop eax
    add edi,edx
    rol eax,8                   ;rotate pattern to next pixel
    dec bx
    jg .NextLine
.FullClip:
    ret

.NoClip:
    movzx ecx,word [esp+.TopRow]
    movzx edx,word [esp+.Width]
    movzx eax,word [esp+.LeftCol]
    mov edi,[Display.Width]     ;get screen width
    neg edx
    add edx,edi                 ;get wrap width (screen width - rect width)
    imul edi,ecx                ;top row * screen width
    mov ebx,[esp+.Size]         ;get height and width (hl=width:height)
    add edi,eax                 ;(row * screen width) + left column
    jmp .Start


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Draws a singled colored rectangle.
;
; (words TopRow, LeftCol, Height, Width, Shift)
DrawShade.GivenCords: ;(pass four coordinates rather than Top/Left/Height/Width)
    mov ax,[esp+DrawRect.TopRow]
    mov cx,[esp+DrawRect.LeftCol]
    sub [esp+DrawRect.Height],ax
    sub [esp+DrawRect.Width],cx
DrawShade:
.TopRow     equ 4
.LeftCol    equ 6
.Size       equ 8
.Height     equ 8
.Width      equ 10
.Shift      equ 12

    call GetRectClips
    jnc .Visible
    ret
.Visible:
    ;mov ebx,[Display.ClipWidth-2]
    shl ebx,16
    mov bx,[Display.ClipHeight]
    ;mov edi,[Display.ClipPtr]
    ;mov edx,[Display.ClipWrap]

.Start:
  %if GfxAddressCheck
    cmp edi,Screen.Bytes
    jb .Ok
    int3
  .Ok:
  %endif
    add edi,[Display.Ptr]
    mov cl,[esp+.Shift]         ;get shift
    ;mov ch,

;(ax=color,
; ebx=height/width,
; edi=destination,
; edx=wrap (destination BYTE width)
.ByReg:                         ;calling by register can be a bit faster
    ; *** currently these values are constant ***
    mov eax,00111101111011110011110111101111b ;ignore new msb
    mov cl,2

    cld
    mov esi,edi                 ;copy destination
    and esi,1                   ;get bytes to next higher word (2bpp)
    setnz ch
    shl esi,16                  ;move to upper word
    sub ebx,esi                 ;remaining width = width - first strip length
    jae .WidthPositive
    add ebx,esi                 ;reverse subtraction above
    xor ch,ch
.WidthPositive:

    ; the loop below is unrolled into words and dwords, so that two pixels
    ; can be blitted per loop. The leftmost pixel blit was added for dword
    ; aligned memory access, to save a cycle for every pixel write.
.NextLine:
    test ch,ch                  ;draw left pixel
    jz .NoLeft
    mov ax,[edi]                ;get pixel
    shr ax,cl                   ;shade bits
    and ax,0001110011100111b    ;discard msb
    sub [edi],ax
    add edi,byte 2
.NoLeft:
    shld esi,ebx,15             ;(remaining width) \ 2
.NextDword:
    mov eax,[edi]               ;get pixels
    shr eax,cl                  ;shade bits
    and eax,0011100111001110001110011100111b ;discard msb
    sub [edi],eax
    add edi,byte 4
    dec esi
    jg .NextDword
    test ebx,1<<16              ;draw right end pixel, if odd remaining width
    jz .NoRight
    mov ax,[edi]                ;get pixel
    shr ax,cl                   ;shade bits
    and ax,0001110011100111b    ;discard msb
    sub [edi],ax
    add edi,byte 2
.NoRight:
    add edi,edx
    dec bx
    jg .NextLine
.FullClip:
    ret

.NoClip:
    movzx ecx,word [esp+.TopRow]
    movzx edx,word [esp+.Width]
    movzx eax,word [esp+.LeftCol]
    mov edi,[Display.Width]     ;get screen width
    neg edx
    add edx,edi                 ;get wrap width (screen width - rect width)
    imul edi,ecx                ;top row * screen width
    mov ebx,[esp+.Size]         ;get height and width (hl=width:height)
    add edi,eax                 ;(row * screen width) + left column
    shl edi,1                   ;*2bpp
    jmp .Start


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Draws either a concave or convex four sided border. Mainly used by GUI
; objects.
;
; (words TopRow, LeftCol, height, width, mode)
DrawBorder:
.Pos        equ 8               ;+ebp
.TopRow     equ 8
.LeftCol    equ 10
.Size       equ 12
.Height     equ 12
.Width      equ 14
.Mode       equ 16
 .Convex    equ 0
 .Concave   equ 1
 .Filled    equ 2
 .NoEdge    equ 4
.Color      equ -4

    mov eax,01000304h
    mov eax,GuiClrTop|(GuiClrLeft<<8)|(GuiClrBtm<<16)|(GuiClrRight<<24)

    mov dword [.TtColor],GuiClrDark
    mov dword [.TbColor],GuiClrShadow
    mov dword [.BtColor],GuiClrHighlight
    mov dword [.BbColor],GuiClrBright
    mov dword [.LlColor],GuiClrDim
    mov dword [.LrColor],GuiClrDark
    mov dword [.RlColor],GuiClrBright
    mov dword [.RrColor],GuiClrLight

;(eax=four byte colors)
.GivenColors:
    push ebp
    mov ebp,esp

    test byte [ebp+.Mode],.NoEdge
    jnz near .HasNoEdge

%ifdef UseSmallScreen
    test byte [ebp+.Mode],.Concave
    jz .IsConvex
    rol eax,16                  ;swap border colors
.IsConvex:
    push eax
%else
    test byte [ebp+.Mode],.Concave
    jnz .IsConcave

    mov eax,[.TtColor]          ;swap top/bottom sides
    mov edx,[.TbColor]
    xchg [.BtColor],eax
    xchg [.BbColor],edx
    mov [.TtColor],eax
    mov [.TbColor],edx;dword 0;edx
    mov ecx,[.LlColor]          ;swap left/right sides
    mov eax,[.LrColor]
    xchg [.RlColor],ecx
    xchg [.RrColor],eax
    mov [.LlColor],ecx
    mov [.LrColor],eax
.IsConcave:
%endif

%ifdef UseSmallScreen

    mov ecx,[ebp+.Pos]
    mov edx,[.ebp+.Color+0-2]    ;get top color (shifted 16 bits up)
    mov dx,[ebp+.Width]
    sub dx,byte 2
    add ecx,0|(1<<16)           ;row/col
    push edx                    ;width/color
    push ecx                    ;row/col
    call DrawHline              ;top

    mov dl,[ebp+.Color+2]       ;get bottom color
    mov [esp+6],dl              ;set color
    mov ax,[ebp+.Height]        ;get height
    dec ax                      ;get bottom row
    add [esp],ax                ;set top row
    call DrawHline              ;bottom
    
    mov edx,[ebp+.Color+1-2]    ;get left color (shifted 16 bits up)
    mov ecx,[ebp+.Pos]
    mov dx,[ebp+.Height]
    sub dx,byte 2
    add ecx,1|(0<<16)           ;row/col
    push edx
    push ecx                    ;row/col
    call DrawVline              ;left

    mov dl,[ebp+.Color+3]       ;get right color
    mov [esp+6],dl              ;set color
    mov ax,[ebp+.Width]         ;get width
    dec ax                      ;get right column
    add [esp+2],ax              ;set left column
    call DrawVline              ;right
.HasNoEdge:

    test byte [ebp+.Mode],.Filled
    jz .NoFill
    mov edx,[ebp+.Size]         ;get height|width
    mov ecx,[ebp+.Pos]          ;get row/col
    sub edx,20000h              ;width-2
    add ecx,10001h
    sub dx,byte 2               ;height-2
   %if GuiDebugMode & 8
    ;redraw indicator hack
    ;cycles through set of colors every call
    mov eax,[.FmColor]
    inc eax
    and eax,7
    add eax,8
    mov [.FmColor],eax
    push eax
   %else
    push dword [.FmColor]       ;fill middle color
   %endif
    push edx                    ;height/width
    push ecx                    ;row/col
    call DrawRect
    ;add esp,byte 12
.NoFill:

%else ;large screen

    mov edx,[.TtColor-2]        ;get topmost color (shifted 16 bits up)
    mov ecx,[ebp+.Pos]
    mov dx,[ebp+.Width]
    sub dx,byte 2
    add ecx,0|(1<<16)           ;row/col
    push edx                    ;width/color
    push ecx                    ;row/col
    call DrawHline              ;top side

    mov dx,[.TbColor]           ;get topunder color
    mov [esp+6],dx              ;set color
    inc word [esp]              ;row one down
    call DrawHline              ;top side

    mov dx,[.BbColor]           ;get bottommost color
    mov [esp+6],dx              ;set color
    mov ax,[ebp+.Height]        ;get height
    sub ax,byte 2               ;get bottom row
    add [esp],ax                ;set top row
    call DrawHline              ;bottom side
    
    mov dx,[.BtColor]           ;get bottomover color
    mov [esp+6],dx              ;set color
    dec word [esp]              ;row one up
    call DrawHline              ;bottom side

  %if 1 ;more contrast on sides
    mov edx,[.LlColor-2]        ;get leftmost color (shifted 16 bits up)
    mov ecx,[ebp+.Pos]
    mov dx,[ebp+.Height]
    sub dx,byte 2
    add ecx,1|(0<<16)           ;row/col
    push edx
    push ecx                    ;row/col
    call DrawVline              ;left outer

    mov dx,[.LrColor]           ;get left color
    mov [esp+6],dx              ;set color
    inc word [esp+2]            ;row col right
    call DrawVline              ;left side inner

    mov dx,[.RrColor]           ;get rightmost color
    mov [esp+6],dx              ;set color
    mov ax,[ebp+.Width]         ;get width
    sub ax,byte 2               ;get right column
    add [esp+2],ax              ;set left column
    call DrawVline              ;right outer

    mov dx,[.RlColor]           ;get right color
    mov [esp+6],dx              ;set color
    dec word [esp+2]            ;row col left
    call DrawVline              ;right inner

  %else ;less contrast
    mov edx,2<<16               ;set width
    mov ecx,[ebp+.Pos]
    push dword [ebp+1-4]        ;pass left color
    mov dx,[ebp+.Height]
    sub dx,byte 2
    add ecx,1|(0<<16)           ;row/col
    push edx
    push ecx                    ;row/col
    call DrawRect               ;left side

    mov dl,[ebp+3-4]            ;get right color
    mov [esp+8],dl              ;set color
    mov ax,[ebp+.Width]         ;get width
    sub ax,byte 2               ;get right column
    add [esp+2],ax              ;set left column
    call DrawRect               ;right side
  %endif

.HasNoEdge:

    test byte [ebp+.Mode],.Filled
    jz .NoFill
    mov edx,[ebp+.Size]         ;get height|width
    mov ecx,[ebp+.Pos]
    sub edx,40004h              ;width-4 | height-4
    add ecx,20002h
   %if GuiDebugMode & 8
    ;redraw indicator hack
    ;cycles through set of colors every call
    mov eax,[.FmColor]
    inc eax
    ;and eax,7
    ;add eax,8
    mov [.FmColor],eax
    push eax
   %else
    push dword [.FmColor]       ;fill middle color
   %endif
    push edx                    ;height/width
    push ecx                    ;row/col
    call DrawRect
    ;add esp,byte 12
.NoFill:

%endif
    mov esp,ebp
    pop ebp
    ret

section data
.FmColor:   dd GuiClrNeutral
.TtColor:   dd GuiClrDark
.TbColor:   dd GuiClrShadow
.BtColor:   dd GuiClrHighlight
.BbColor:   dd GuiClrBright
.LlColor:   dd GuiClrDim
.LrColor:   dd GuiClrDark
.RlColor:   dd GuiClrBright
.RrColor:   dd GuiClrLight
section code


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Draws a simple opaque image.
;
; (words TopRow, LeftCol, Height, Width, dword Source)
DrawImageOpaque:

.Top    equ 4
.Left   equ 6
.Height equ 8
.Width  equ 10
.Source equ 12

    call GetRectClips
    jc .FullClip
    ;mov edi,[Display.ClipPtr]
    ;mov edx,[Display.ClipWrap]
    ;mov ebx,[Display.ClipWidth]

    movsx esi,word [esp+.Width]
    neg ebx
    add ebx,esi                 ;source wrap = image width - clipped width
    imul esi,[Display.ClipTopOfs]
  %if GfxAddressCheck
    cmp edi,Screen.Bytes
    jb .Ok
    int3
  .Ok:
  %endif
    add edi,[Display.Ptr]
    add esi,[Display.ClipLeftOfs]
    shl ebx,1                   ;*2bpp
    shl esi,1                   ;*2bpp
    mov eax,[Display.ClipWidth]
    add esi,[esp+.Source]       ;source offset + image width * top clip adjustment

    cld
.NextRow:
    mov ecx,eax
    shr ecx,1                   ;/2
    rep movsd                   ;move dwords at a time
    ;rep stosd
    mov ecx,eax
    and ecx,1                   ;remaining odd byte (if any)
    rep movsw                   ;move any remaining pixels
    add esi,ebx                 ;Source+=[Display.ClipWidth]
    add edi,edx                 ;Dest+=[Display.ClipWrap]
    dec dword [Display.ClipHeight]
    jg .NextRow

.FullClip:
    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Draws a simple transparent image.
;
; (words TopRow, LeftCol, Height, Width, dword SourcePixels, byte Transparent color)
DrawImageTrans:

.Top    equ 4
.Left   equ 6
.Height equ 8
.Width  equ 10
.Source equ 12
.Color  equ 16

    call GetRectClips
    jc .FullClip
    ;mov edi,[Display.ClipPtr]
    ;mov edx,[Display.ClipWrap]
    ;mov ebx,[Display.ClipWidth]

    movsx esi,word [esp+.Width]
    neg ebx
    add ebx,esi                 ;source wrap = image width - clipped width
    imul esi,[Display.ClipTopOfs]
  %if GfxAddressCheck
    cmp edi,Screen.Bytes
    jb .Ok
    int3
  .Ok:
  %endif
    add edi,[Display.Ptr]
    add esi,[Display.ClipLeftOfs]
    shl esi,1
    add esi,[esp+.Source]       ;source offset + image width * top clip adjustment
    mov ah,[esp+.Color]

    shl ebx,1
    cld
.NextRow:
    mov ecx,[Display.ClipWidth]
.NextCol:
    ;lodsb
    ;cmp al,ah
    lodsw
    cmp ax,0FFFFh
    je .Trans
    stosw
    dec ecx
    jg .NextCol
    jmp short .EndRow
.Trans:
    add edi,byte 2
    dec ecx
    jg .NextCol
.EndRow:
    add esi,ebx                 ;Source+=[Display.ClipWidth]
    add edi,edx                 ;Dest+=[Display.ClipWrap]
    dec dword [Display.ClipHeight]
    jg .NextRow

.FullClip:
    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Draws a colormapped image, 8bit to 16bit pixels using map.
;
; (words TopRow, LeftCol, Height, Width, dword SourcePixels, dword ColorMapPtr)
DrawImageMapped:

.Top        equ 4
.Left       equ 6
.Height     equ 8
.Width      equ 10
.Source     equ 12
.ColorMap   equ 16

    call GetRectClips
    jc .FullClip
    ;mov edi,[Display.ClipPtr]
    ;mov edx,[Display.ClipWrap]
    ;mov ebx,[Display.ClipWidth]

    movsx esi,word [esp+.Width]
    neg ebx
    add ebx,esi                 ;source wrap = image width - clipped width
    imul esi,[Display.ClipTopOfs]
  %if GfxAddressCheck
    cmp edi,Screen.Bytes
    jb .Ok
    int3
  .Ok:
  %endif
    add edi,[Display.Ptr]
    add esi,[Display.ClipLeftOfs]
    mov edx,[esp+.ColorMap]
    add esi,[esp+.Source]       ;source offset + image width * top clip adjustment

    cld
    xor eax,eax
.NextRow:
    mov ecx,[Display.ClipWidth]
.NextCol:
    lodsb
    mov ax,[edx+eax*2]
    stosw
    dec ecx
    mov eax,0
    jg .NextCol
.EndRow:
    add esi,ebx                 ;Source+=[Display.ClipWidth]
    add edi,[Display.ClipWrap]  ;Dest+=[Display.ClipWrap]
    dec dword [Display.ClipHeight]
    jg .NextRow

.FullClip:
    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Draws an opaque image tiled.
;
; (words TopRow, LeftCol, Height, Width, dword ImageStruc)
DrawImageTiled:

.RowCounter     equ 0
;.ImageWidth    equ -8 (use ebx)
.ImageHeight    equ 4
.Top            equ 12
.Left           equ 14
.Height         equ 16
.Width          equ 18
.Image          equ 20

    call GetRectClips
    jnc .NotFullClip
.FullClip:
    ret
.NotFullClip:
    ;mov edi,[Display.ClipPtr]
    ;mov edx,[Display.ClipWrap]
    ;mov ebx,[Display.ClipWidth]

    ; get image dimensions and copy on stack
    mov esi,[esp+.Image-8]      ;get image ptr
    movzx edx,word [esi+ImageStruct.Height]
    movzx ebx,word [esi+ImageStruct.Width]
    test edx,edx                ;check for zero or negative size
    jle .FullClip               ;to prevent possible div by zero
    test ebx,ebx
    jle .FullClip
    push edx                    ;push dword height
    push edx                    ;set initial row counter

    ; determine top/left modulus
    mov eax,[Display.ClipLeftOfs]
    xor edx,edx
    div ebx                     ;clip left ofs %% image width
    mov [Display.ClipLeftOfs],edx
    mov eax,[Display.ClipTopOfs]
    xor edx,edx
    div dword [esp+.ImageHeight];clip top ofs %% image height
    ;mov [Display.ClipTopOfs],edx
    mov eax,edx
    sub [esp+.RowCounter],edx   ;image height - clip top ofs
    add edi,[Display.Ptr]
    imul ebx                    ;clip top ofs * image width
    cld
    shl eax,1
    add eax,[esp+.Image]

.NextRow:
    mov esi,[Display.ClipLeftOfs]
    mov ecx,ebx
    mov edx,[Display.ClipWidth] ;get width of single row
    sub ecx,esi                 ;image width - left clip offset
    lea esi,[eax+esi*2]         ;source ptr + left clip offset
    jmp short .FirstStrip

; ecx=strip length, edx=row counter, esi=image ptr, eax=image row ptr, ebx=image width
.NextStrip:
    mov ecx,ebx                 ;get image width
    mov esi,eax
.FirstStrip:
    sub edx,ecx
    jge .TransferStrip
    add ecx,edx
    test edx,edx
.TransferStrip:
    rep movsw
    jg .NextStrip

.EndRow:
    dec dword [esp+.RowCounter]
    jg .SameTile                ;still drawing same tile (not next one yet)
    mov edx,[esp+.ImageHeight]
    mov eax,[esp+.Image]
    mov [esp+.RowCounter],edx   ;set row counter = image height
    jmp short .NextTile
.SameTile:
    lea eax,[eax+ebx*2]         ;Source+=ImageWidth
.NextTile:
    add edi,[Display.ClipWrap]  ;Dest+=[Display.ClipWrap]
    dec dword [Display.ClipHeight]
    jg .NextRow

    add esp,byte 8
    ret


%ifdef UseGuiFonts
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Blits a single character of the standard two color / transparency font.
; The routine can blit characters ranging 1-16 pixels wide, 1-255 high.
;
;if first bit set then
;plotpixel:
;  if second bit set then
;    use second color
;  else
;    use first color
;else
;  end row if no more opaque pixels
;  loop until next opaque pixel
;  goto plotpixel
;next row
;
BlitTwoColorFont:
  %if GfxAddressCheck
    cmp edi,Screen.Bytes
    jb .Ok
    int3
  .Ok:
  %endif
    add edi,[Display.Ptr]

;(esi=font character pixel source,
; edi=pixel destination,
; al/ah=first/second color,
; bl/bh=width,height,
; cl =preshift,
; edx=wrap)
.ByReg:
    push ebp                    ;will be used for font pixel data
    shl ecx,1                   ;preshift*2 since each pixel is two bits

.NextRow:
    mov ebp,[esi]               ;get next 16 pixel row
    push edi
    mov ch,bl                   ;reset column counter
    shr ebp,cl                  ;preshift for left clipping
.NextPixel:
    ;if first bit is clear then skip transparent pixel
    shr ebp,1
    jnc .ClearPixel
.CheckPixelColor:
    ;if second bit is clear then use first color, if set then use second
    shr ebp,1
    jc .SecondPixelColor
    mov [edi],ax                ;write first color
.NextCol:
    add edi,byte 2
    dec ch                      ;one less column
    jg .NextPixel
    jmp short .EndRow

.NextClearPixel:                ;loop until opaque pixel found
    shr ebp,2
    jc .CheckPixelColor
.ClearPixelLoop:
    add edi,byte 2
    dec ch                      ;one less column
    jg .NextClearPixel
.ClearPixel:
    ;enter a tight loop if more opaque pixels remain from the above shift
    jnz .ClearPixelLoop
    ;else end row if there are only more transparent pixels afterwards
    jmp short .EndRow

.SecondPixelColor:
    push eax
    push ecx
    mov ecx,[edi]
    and eax,111101111011111b
    and ecx,111101111011111b
    add eax,ecx
    rcr eax,1
    mov [edi],ax                ;write second color (less common occurence)
    pop ecx
    pop eax
    add edi,byte 2
    dec ch                      ;one less column
    jg .NextPixel

.EndRow:
    pop edi
    add esi,byte 4              ;src += bytes per row
    add edi,edx                 ;dest += dest wrap width
    dec bh                      ;one less row
    jg .NextRow

    pop ebp
    ret
%endif


%ifdef UseGuiFonts
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;if first bit set then
;plotpixel:
;  if second bit set then
;    use second color
;  else
;    use first color
;else
;  end row if no more opaque pixels
;  loop until next opaque pixel
;  goto plotpixel
;next row
;
BlitTwoColorFontV:
  %if GfxAddressCheck
    cmp edi,Screen.Bytes
    jb .Ok
    int3
  .Ok:
  %endif
    add edi,[Display.Ptr]

;(esi=font character pixel source,
; edi=pixel destination,
; ax=color,
; bl/bh=width,height,
; cl =preshift,
; edx=wrap)
.ByReg:
    push ebp                    ;will be used for font pixel data
    shl ecx,1                   ;preshift*2 since each pixel is two bits

.NextRow:
    mov ebp,[esi]               ;get next 16 pixel row
    push edi
    mov ch,bl                   ;reset column counter
    shr ebp,cl                  ;preshift for left clipping
.NextPixel:
    ;if first bit is clear then skip transparent pixel
    shr ebp,1
    jnc .ClearPixel
.CheckPixelColor:
    ;if second bit is clear then use first color, if set then use second
    shr ebp,1
    jc .SecondPixelColor
    mov [edi],ax                ;write first color
.NextCol:
    add edi,edx                 ;dest += dest wrap width
    dec ch                      ;one less column
    jg .NextPixel
    jmp short .EndRow

.NextClearPixel:                ;loop until opaque pixel found
    shr ebp,2
    jc .CheckPixelColor
.ClearPixelLoop:
    add edi,edx                 ;dest += dest wrap width
    dec ch                      ;one less column
    jg .NextClearPixel
.ClearPixel:
    ;enter a tight loop if more opaque pixels remain from the above shift
    jnz .ClearPixelLoop
    ;else end row if there are only more transparent pixels afterwards
    jmp short .EndRow

.SecondPixelColor:
    push eax
    push ecx
    mov ecx,[edi]
    and eax,111101111011111b
    and ecx,111101111011111b
    add eax,ecx
    rcr eax,1
    mov [edi],ax                ;write second color (less common occurence)
    pop ecx
    pop eax
    add edi,edx                 ;dest += dest wrap width
    dec ch                      ;one less column
    jg .NextPixel

.EndRow:
    pop edi
    add esi,byte 4
    dec edi
    dec bh                      ;one less row
    jg .NextRow

    pop ebp
    ret
%endif


%ifdef UseGuiFonts
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; The code for clipping is contained in here rather than in the individual
; character blitter each time it is called.
;
; (words row, column, string ptr, dwords string length)
; (esi=character just after last one blit)
BlitString:
    call GetFontClips
    jc .FullClip
;.AlreadyClipped:
    mov esi,[esp+8]             ;get string ptr
    push dword [esp+12]         ;save text length counter
    jmp short .FirstChar        ;in case length is zero characters
.FullClip:
    ret

.NextChar:
    ; get character info, calc offset to character pixels
    push edi
    push esi
    movzx esi,byte [esi]        ;get character
    mov ecx,[Font.SizesPtr]
    movzx ebx,byte [esi+ecx]    ;get width of character
    shl esi,FontDefCharShl      ;*32||64
    inc ebx                     ;move right by character size plus one column
    add esi,[Display.ClipCharsPtr];+= graphics base of character set
    add [esp+4],ebx             ;add character width to destination

    ;if ptr greater than right clip
    ;  clip width
    ;  skip if width < 1
    ;endif
    ;if ptr less than left clip
    ;  clip width
    ;  skip if width < 1
    ;  get preshift
    ;  add preshift to destination
    ;endif

    ; clip character on right side
    lea edx,[edi+ebx]
    cmp [Display.ClipRight],edx ; if right col > end right clip
    jge .RightOk
    mov ebx,[Display.ClipRight] ; width = right clip - current col
    sub ebx,edi
    jle .Skip
.RightOk:

    ; clip character on left side
    xor ecx,ecx                 ;no character preshift if no left clipping
    cmp [Display.ClipLeft],edi  ;if left col < left clip
    jle .LeftOk
    mov ecx,[Display.ClipLeft]
    sub ecx,edi                 ;preshift = left clip - current col
    sub ebx,ecx                 ;width -= (left ptr - current ptr)
    jbe .Skip
    add edi,ecx                 ;destination += preshift
.LeftOk:

    ; draw character
    shl edi,1
    mov eax,[Font.Colors]
    mov edx,[Display.Width]
    add edi,[Display.ClipPtr]
    shl edx,1
    mov bh,[Display.ClipHeight] ;get height of character
    call BlitTwoColorFont

.Skip:
    pop esi
    pop edi
    inc esi                     ;next character
.FirstChar:
    dec dword [esp]             ;decrement string length counter
    jns .NextChar
    add esp,byte 4              ;release counter

    mov [Display.ClipPtr],edi
    mov [esp+8],esi
.End:
    ret
%endif


%ifdef UseGuiFonts
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; The code for clipping is contained in here rather than in the individual
; character blitter each time it is called.
;
; (words row, column, string ptr, dwords string length)
; (esi=character just after last one blit)
BlitStringV:
    call GetFontClipsV
    jc .FullClip
;.AlreadyClipped:
    mov esi,[esp+8]             ;get string ptr
    push dword [esp+12]         ;save text length counter
    jmp short .FirstChar        ;in case length is zero characters
.FullClip:
    ret

.NextChar:
    ; get character info, calc offset to character pixels
    push edi
    push esi
    movzx esi,byte [esi]        ;get character
    mov ecx,[Font.SizesPtr]
    movzx ebx,byte [esi+ecx]    ;get width of character
    shl esi,FontDefCharShl      ;*32||64
    inc ebx                     ;move right by character size plus one column
    add esi,[Display.ClipCharsPtr];+= graphics base of character set
    add [esp+4],ebx             ;add character width to destination

    ;if ptr greater than right clip
    ;  clip width
    ;  skip if width < 1
    ;endif
    ;if ptr less than left clip
    ;  clip width
    ;  skip if width < 1
    ;  get preshift
    ;  add preshift to destination
    ;endif

    ; clip character on bottom side
    lea edx,[edi+ebx]
    cmp [Display.ClipBtm],edx   ; if current bottom row > end right clip
    jge .BtmOk
    mov ebx,[Display.ClipBtm]   ; width = right clip - bottom row
    sub ebx,edi
    jle .Skip
.BtmOk:

    ; clip character on top side
    xor ecx,ecx                 ;no character preshift if no left clipping
    cmp [Display.ClipTop],edi   ;if top row < top clip
    jle .TopOk
    mov ecx,[Display.ClipTop]
    sub ecx,edi                 ;preshift = top clip - current row
    sub ebx,ecx                 ;height -= clip top
    jbe .Skip
    add edi,ecx                 ;destination += preshift
.TopOk:

    ; draw character
    mov edx,[Display.Width]
    mov eax,[Font.Colors]
    imul edi,edx                ;row * dest wrap width
    mov bh,[Display.ClipHeight] ;get height of character
    add edi,[Display.ClipPtr]
    call BlitTwoColorFontV

.Skip:
    pop esi
    pop edi
    inc esi                     ;next character
.FirstChar:
    dec dword [esp]             ;decrement string length counter
    jns .NextChar
    add esp,byte 4              ;release counter

    mov [Display.ClipPtr],edi
    mov [esp+8],esi
.End:
    ret
%endif


%if 0
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
ClearScreen:
    mov eax,02020202h
;(eax=color)
.Given:
    cld
    mov ecx,(Screen.Height*Screen.Width)/4
    mov edi,Screen.Buffer
    rep stosd
    ret
%endif


%ifdef DosVer
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;(esi=palette)
SetPalette:
    mov ecx,256
;(esi=palette, ecx=count)
.GivenCount:
    xor eax,eax
;(esi=palette, eax=starting reg, ecx=count)
.GivenIndexes:
    mov edx,3C8h
    out dx,al
    inc edx
%if 1
.Next:
    mov eax,[esi]
    and eax,0FCFCFCh            ;necessary??
    shr eax,2
    out dx,al
    shr eax,8
    out dx,al
    shr eax,8
    out dx,al
    add esi,byte 4
    dec ecx
    jg .Next
%elif 0
.Next:
    mov eax,[esi]
    and eax,0FCFCFCh            ;necessary??
    rol eax,8+6
    out dx,al
    rol eax,8
    out dx,al
    rol eax,8
    out dx,al
    add esi,byte 4
    dec ecx
    jg .Next
%else
    inc edx
    and ecx,511
    lea ecx,[ecx*2+ecx]
    cld
    rep outsb
%endif
    ret
%endif


%ifdef UseGuiCursor
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Draws the current cursor image to the display, saving the area behind the
; cursor first.
;
; Unlike all the other graphics routines, the cursor is NOT clipped to the
; current rectangle, only the display.
DrawCursor:

    ; clip image based on mouse row/col
    mov edx,[Cursor.Row]
    mov ecx,[Cursor.Col]
    mov [Cursor.RowPrev],edx
    mov [Cursor.ColPrev],ecx
    sub edx,[Cursor.RowOffset]
    sub ecx,[Cursor.ColOffset]
    mov [Cursor.RowHide],edx
    mov [Cursor.ColHide],ecx
    call ClipCursorImage

    ; first grab region of screen under cursor
    or byte [Display.RedrawFlags],Display.ShowCursor
    push ebp
    push esi
    push edi
    push ebx
    push eax
    call TransferCursorArea
    pop eax
    pop ebx
    pop edi
    pop esi

    ; calculate transfer ptrs and wraps for cursor image
    ; eax=clipped width, esi=cursor ptr, edi=screen ptr
    mov edx,[Display.Width]
    mov ebp,Cursor.Size
    sub edx,eax
    sub ebp,eax

    shl edx,1                   ;display wrap*2bpp
    shl ebp,1                   ;cursor wrap*2bpp

    ; overlay transparent cursor image
.NextRow:
    mov ah,al                   ;reset width counter
    sub ah,2                    ;two fewer pixels
    jl .FinishRow
.NextStrip:
    mov ecx,[edi]
    and ecx,[esi+Cursor.Mask]
    or  ecx,[esi+Cursor.Image]
    mov [edi],ecx
    add esi,byte 4
    add edi,byte 4
    sub ah,2
    jge .NextStrip
.FinishRow:
    cmp ah,-1                   ;compensate for underflow, make positive
    jl .EndRow
    mov cl,[edi]
    and cl,[esi+Cursor.Mask]
    or  cl,[esi+Cursor.Image]
    mov [edi],cl
    add esi,byte 2
    add edi,byte 2
.EndRow:
    add esi,ebp
    add edi,edx
    dec ebx
    jg .NextRow

    pop ebp
    ret
%endif


%ifdef UseGuiCursor
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Restores the display area that was behind the cursor.
HideCursor:

%ifdef WinVer
    ; ensure that if cursor has been moved, that it is redrawn (invalidated)
    ; note that moving the cursor, not necessarily the mouse, causes a redraw.
    ; for example, when moving the main window with the mouse, the cursor
    ; relative to the window remains stationary. also, when pushing against a
    ; confined border, the mouse moves but the cursor remains stuck against
    ; the side.
    mov edx,[Cursor.RowPrev]
    mov ecx,[Cursor.ColPrev]
    cmp [Cursor.Row],edx
    jne .Moved
    cmp [Cursor.Col],ecx
    je .Unmoved
.Moved:
    or byte [Display.RedrawFlags],Display.RedrawCursor
.Unmoved:
%endif

    mov edx,[Cursor.RowHide]
    mov ecx,[Cursor.ColHide]
    call ClipCursorImage
    and byte [Display.RedrawFlags],~Display.ShowCursor
    jmp TransferCursorArea
%endif


%ifdef UseGuiCursor
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Given a row and column, returns clipped row, column, height, width, and
; display destination. If the cursor is off screen completely, this routine
; will return the caller's caller to prevent any further drawing.
;
; (edx=row, ecx=col)
; (edx=clipped row, ecx=clipped col,
;  eax=clipped width, ebx=clipped height,
;  esi=source offset, edi=display ptr)
ClipCursorImage:
    mov ebx,Cursor.Size
    mov edi,[Display.Height]
    xor esi,esi                 ;zero initial source offset
    mov eax,ebx

    ; clip vertically
    sub edi,ebx                 ;display height - cursor size
    test edx,edx
    jge .TopOk
    add ebx,edx                 ;cursor height += negative cursor row
    jle .Offscreen
    sub esi,edx                 ;source offset += -(row)
    xor edx,edx                 ;clip row top (0)
    shl esi,Cursor.SizeShl
    jmp short .BtmOk
.TopOk:
    sub edi,edx
    jge .BtmOk
    add ebx,edi                 ;cursor height += negative cursor row right side
    jle .Offscreen
.BtmOk:

    ; clip horizontally
    mov edi,[Display.Width]
    sub edi,eax                 ;display width - cursor size
    test ecx,ecx
    jge .LeftOk
    add eax,ecx                 ;cursor width += negative cursor col
    jle .Offscreen
    sub esi,ecx                 ;source offset += negative cursor col
    xor ecx,ecx                 ;clip row top (0)
    jmp short .RightOk
.LeftOk:
    sub edi,ecx
    jge .RightOk
    add eax,edi                 ;cursor width += negative cursor col right side
    jle .Offscreen
.RightOk:

    ; dest ptr = (row * display width) + col
    mov edi,edx
    imul edi,[Display.Width]
    add edi,ecx
    shl esi,1
    shl edi,1
    add edi,[Display.Ptr]
    ret

.Offscreen:
    pop eax                     ;discard return value
    ;api MessageBeep,-1
    ret
%endif


%ifdef UseGuiCursor
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Transfers the area behind the cursor either from or to the display,
; depending on whether it is being shown or hidden.
;
; (eax=clipped width, ebx=clipped height,
;  ecx=clipped col, edx=clipped row,
;  esi=source offset, edi=display ptr)
; (none)
TransferCursorArea:
    ; set invalidated rectangle
    mov [Display.RedrawTop],edx
    mov [Display.RedrawLeft],ecx
    add ecx,eax
    add edx,ebx
    mov [Display.RedrawBtm],edx
    mov [Display.RedrawRight],ecx

    ; calculate transfer ptrs and wraps
    push ebp
    mov edx,[Display.Width]
    mov ebp,Cursor.Size
    add esi,Cursor.BgImage
    sub edx,eax
    sub ebp,eax
    ; (eax=clipped height, ebx=clipped width,
    ;  ebp=cursor wrap, edx=display wrap,
    ;  esi=bg image, edi=display ptr)

    ; swap them if hiding cursor (else showing)
    test byte [Display.RedrawFlags],Display.ShowCursor
    jz .Hidden
    xchg esi,edi                ;swap source and dest ptrs
    xchg ebp,edx                ;swap source and dest wraps
.Hidden:

    shl edx,1                   ;wrap *2bpp
    shl ebp,1

    ; transfer pixels, either from display to bg, or vice-versa
.NextRow:
    mov ecx,eax
    shr ecx,1
    rep movsd                   ;first transfer dwords
    mov ecx,eax
    and ecx,1
    rep movsw                   ;then any remaining bytes
    add esi,ebp                 ;source ptr += source wrap
    add edi,edx                 ;dest ptr += dest wrap
    dec ebx
    jg .NextRow
    pop ebp

    ; invalidate region around cursor if necessary
    test byte [Display.RedrawFlags],Display.RedrawCursor ;if moved or cursor changed
    jz .Valid
  %ifdef UseDisplayBuffer
    mov esi,Display.Redraws
    call AddClipsToRedrawRange.Given
  %endif
  %ifdef WinVer
    api InvalidateRect, [hwnd],Display.Redraws,FALSE
  %endif
.Valid:

    ret
%endif


%ifdef UseGuiCursor
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sets the current cursor image. Does nothing if they are the same image.
; Just in case, the image really has been changed, you can call .Now.
;
; (esi=16x16 cursor image with hot spot)
; (cf=0 always succeeds; ebx)
SetCursorImage.Default:
    mov esi,GuiCursor.Default
SetCursorImage:
    cmp [Cursor.Ptr],esi
    je .Same
.Now:
    mov edx,[esi+Cursor.SizeOf]   ;get hot spot row
    mov ecx,[esi+Cursor.SizeOf+4] ;get hot spot col
; (esi=16x16 cursor image, ecx=col offset, edx=row offset)
.Given:
    cld
    xor edi,edi
    mov [Cursor.ColOffset],ecx
    mov [Cursor.RowOffset],edx
    mov [Cursor.Ptr],esi
    mov ecx,Cursor.Size*Cursor.Size
.NextPixel:
    lodsw
    cmp ax,0FFFFh
    je .Transparent
    mov [edi+Cursor.Image],ax
    mov [edi+Cursor.Mask],word 0
.EndLoop:
    add edi,byte 2
    dec ecx
    jnz .NextPixel
    or byte [Display.RedrawFlags],Display.RedrawCursor
.Same:
    ;clc
    ret
.Transparent:
    mov [edi+Cursor.Image],word 0
    mov [edi+Cursor.Mask],ax
    jmp short .EndLoop
%endif


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Used by several rectangular drawing routines to obtain correctly clipped
; variables. Sets carry if completely clipped.
;
; (words top row, left column, height, width)
; (cf=full clip, edi=destination offset ptr, ebx=width, edx=wrap)
GetRectClips:
    movsx eax,word [esp+8]      ; get top row
    movzx ecx,word [esp+12]     ; get height
    mov edi,[Display.Width]
    mov ebx,eax                 ; copy top row
.CheckTop:
    cmp [Display.ClipTop],eax   ; if top row < top clip
    jle .TopOk                  ;   difference = bottom clip - bottom column
    mov edx,[Display.ClipTop]   ; endif
    mov eax,edx
    sub edx,ebx
    mov [Display.ClipTopOfs],edx
    jmp short .CheckBtm
  .TopOk:
    mov dword [Display.ClipTopOfs],0;set vertical offset to 0
.CheckBtm:
    add ebx,ecx                 ; bottom row = top row + height
    cmp [Display.ClipBtm],ebx   ; if bottom row > bottom clip
    jge .BtmOk                  ;   set bottom row to bottom clip
    mov ebx,[Display.ClipBtm]   ; endif
  .BtmOk:
    sub ebx,eax                 ; clipped height = bottom side - top side
    jle .FullClip               ; exit if clipped height <= 0
    imul edi,eax                ; destination = top row * screen width
    mov [Display.ClipHeight],ebx

    movsx eax,word [esp+10]     ; get left column
    movzx ecx,word [esp+14]     ; get width
    mov ebx,eax                 ; copy left column
.CheckLeft:
    cmp [Display.ClipLeft],eax  ; if left column < left clip
    jle .LeftOk                 ;   difference = left clip - left column
    mov edx,[Display.ClipLeft]  ; endif
    mov eax,edx
    sub edx,ebx
    mov [Display.ClipLeftOfs],edx
    jmp short .CheckRight
  .LeftOk:
    mov dword [Display.ClipLeftOfs],0;set horizontal offset to 0
.CheckRight:
    add ebx,ecx                 ; right column = left column + width
    cmp [Display.ClipRight],ebx ; if right column > right clip
    jge .RightOk                ;   set right column to right clip
    mov ebx,[Display.ClipRight] ; endif
  .RightOk:
    sub ebx,eax                 ; clipped width = right side - left side
    jle .FullClip               ; exit if clipped width <= 0

    mov edx,[Display.Width]     ; wrap = (display width - clipped width)*bpp
    mov [Display.ClipWidth],ebx
    sub edx,ebx
    add edi,eax                 ; destination += left column
    shl edx,1                   ; *2bpp
    shl edi,1                   ; *2bpp
    mov [Display.ClipWrap],edx
    mov [Display.ClipPtr],edi
    clc
    ret

.FullClip:                      ; called if item to be drawn is off the
    stc                         ; screen, completely out of its parent
    ret                         ; window, or has a zero or negative size.


%ifdef UseGuiFonts
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; (dword ret adr, words row, column)
; (cf=full clip, edi=destination column offset)
GetFontClips:
.Top        equ 8
.Left       equ 10

    movsx eax,word [esp+.Top]
    movzx ecx,byte [Font.Height]; get character height
    mov esi,[Font.CharsPtr]
    mov ebx,eax                 ; copy top row

.CheckTop:
    cmp [Display.ClipTop],eax   ; if top row < top clip
    jle .TopOk
    mov edx,[Display.ClipTop]
    mov eax,edx                 ;   set top row to top clip
    sub edx,ebx                 ;   difference = top clip - top row
    lea esi,[esi+edx*4]         ;   *4 bytes per character row
.TopOk:                         ; endif

.CheckBtm:
    add ebx,ecx                 ; bottom row = top row + height
    cmp [Display.ClipBtm],ebx   ; if bottom row > bottom clip
    jge .BtmOk                  ;   set bottom row to bottom clip
    mov ebx,[Display.ClipBtm]   ; endif
.BtmOk:
    sub ebx,eax                 ; clipped height = bottom side - top side
    mov [Display.ClipHeight],ebx ; set character height
    jle .FullClip               ; exit if clipped height <= 0

    ; set destination
    imul eax,[Display.Width]    ; destination = top row * screen width
    movsx edi,word [esp+.Left]  ; return left offset in edi
    shl eax,1                   ; *2bpp
    mov [Display.ClipCharsPtr],esi
    mov [Display.ClipPtr],eax

    clc
    ret

.FullClip:                      ; called if item to be text is off the
    stc                         ; screen, or completely out of its clip
    ret                         ; window


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
GetFontClipsV:
.Top        equ 8
.Left       equ 10

    ;int3;
    movsx eax,word [esp+.Left]
    movzx ecx,byte [Font.Height]; get character height
    mov esi,[Font.CharsPtr]
    mov ebx,eax                 ; copy left col

.CheckLeft:
    cmp [Display.ClipLeft],eax ; if left col < left clip
    jle .LeftOk
    mov eax,[Display.ClipLeft]  ;   set left col = left clip
.LeftOk:                        ; endif

.CheckRight:
    add ebx,ecx                 ; right col = left col + width
    cmp [Display.ClipRight],ebx ; if right col > right clip
    jge .RightOk
    ;mov edx,[Display.ClipRight]
    ;sub edx,ebx                 ;   difference = right clip - right column
    ;add ebx,edx                 ;   set right col to right clip
    ;lea esi,[esi+edx*4]         ;   *4 bytes per character row
    mov edx,ebx
    mov ebx,[Display.ClipRight] ;   set right col to right clip
    sub edx,ebx                 ;   difference = right column - right clip
    lea esi,[esi+edx*4]         ;   *4 bytes per character row
.RightOk:                       ; endif
    lea ecx,[ebx-1]
    sub ebx,eax                 ; clipped width = right side - left side
    mov [Display.ClipHeight],ebx ; set character height (rotated character)
    jle .FullClip               ; exit if clipped width <= 0

    ; set destination
    movsx edi,word [esp+.Top]   ; return top row in edi
    mov [Display.ClipPtr],ecx
    mov [Display.ClipCharsPtr],esi

    clc
    ret

.FullClip:                      ; called if item to be text is off the
    stc                         ; screen, or completely out of its clip
    ret                         ; window

%endif

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Save all the clipping variables onto stack for use with the merge functions.
;
; ()
; (; !edx)
SaveClips:
    pop edx
    push dword [Display.Ptr]
    push dword [Display.Top]
    push dword [Display.Left]
    push dword [Display.ClipBtm]
    push dword [Display.ClipRight]
    push dword [Display.ClipTop]
    push dword [Display.ClipLeft]
    jmp edx

SavedClips:
.ClipLeft       equ 0           ;clip relative to Left
.ClipTop        equ 4           ;clip relative to Top
.ClipRight      equ 8
.ClipBtm        equ 12
.Left           equ 16          ;current window column offset
.Top            equ 20          ;current window row offset
.Ptr            equ 24          ;current offset relative to top/left
.SizeOf         equ 28
;.RedrawTop      equ 28          ;redraw bound relative to Top
;.RedrawBtm      equ 32
;.RedrawLeft     equ 36          ;redraw bound relative to Left
;.RedrawRight    equ 40
;.SizeOf        equ 44


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Restores all the clipping variables from stack, pushed by SaveClips.
;
; ()
; (; !edx)
RestoreClips:
    pop edx
    pop dword [Display.ClipLeft]
    pop dword [Display.ClipTop]
    pop dword [Display.ClipRight]
    pop dword [Display.ClipBtm]
    pop dword [Display.Top]
    pop dword [Display.Left]
    pop dword [Display.Ptr]
    jmp edx


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Saves the display variables onto stack for later restoring. Can be used by
; any routine that intends to mess around with these.
;
; ()
; (; !edx)
SaveDisplayVars:
    pop edx
    push dword [Display.Height]
    push dword [Display.Width]
    push dword [Display.Ptr]
    push dword [Display.Top]
    push dword [Display.Left]
    push dword [Display.RedrawBtm]
    push dword [Display.RedrawRight]
    push dword [Display.RedrawTop]
    push dword [Display.RedrawLeft]
    push dword [Display.ClipBtm]
    push dword [Display.ClipRight]
    push dword [Display.ClipTop]
    push dword [Display.ClipLeft]
    jmp edx

SavedDisplayVars:
.ClipLeft       equ 0           ;clip relative to Left
.ClipTop        equ 4           ;clip relative to Top
.ClipRight      equ 8
.ClipBtm        equ 12
.RedrawLeft     equ 16          ;redraw bound relative to Left
.RedrawTop      equ 20          ;redraw bound relative to Top
.RedrawRight    equ 24
.RedrawBtm      equ 28
.Left           equ 32          ;current window column offset
.Top            equ 36          ;current window row offset
.Ptr            equ 40          ;current offset relative to top/left
.Height         equ 44
.Width          equ 48
.SizeOf         equ 52


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Restores the display variables from the stack, pushed by SaveDisplayVars.
; IMPORTANT: Restore must be called at the same stack level (esp same) as
; Save was called at.
;
; ()
; (; !edx)
RestoreDisplayVars:
    pop edx
    pop dword [Display.ClipLeft]
    pop dword [Display.ClipTop]
    pop dword [Display.ClipRight]
    pop dword [Display.ClipBtm]
    pop dword [Display.RedrawLeft]
    pop dword [Display.RedrawTop]
    pop dword [Display.RedrawRight]
    pop dword [Display.RedrawBtm]
    pop dword [Display.Left]
    pop dword [Display.Top]
    pop dword [Display.Ptr]
    pop dword [Display.Width]
    pop dword [Display.Height]
    jmp edx


%ifdef UseGuiGfx
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Simply sets the screen clips to the four dimensions. To pass the four words
; via the stack, simply push them on, and set esi=esp before calling.
;
; *** This routine sets the Redraw boundaries ***
;
; (esi=ptr to words top, left, bottom, right [or SavedClips structure])
; (; ebx, esi)
SetRedrawArea:
.ClipTop    equ 0
.ClipLeft   equ 2
.ClipBtm    equ 4
.ClipRight  equ 6

    movsx eax,word [esi+.ClipTop]
    movsx edi,word [esi+.ClipLeft]
    movsx ecx,word [esi+.ClipBtm]
    movsx edx,word [esi+.ClipRight]

    mov [Display.RedrawTop],eax
    mov [Display.RedrawLeft],edi
    mov [Display.RedrawBtm],ecx
    mov [Display.RedrawRight],edx

    ret
%endif


%ifdef UseGuiGfx
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Combines the screen clips with the four dimensions. To pass the four words
; via the stack, simply push them on, and set esi=esp before calling.
;
; *** Currently this routine sets the Redraw boundaries ***
;
; (esi=ptr to words top, left, bottom, right [or SavedClips structure])
; (; ebx, esi)
OrRedrawArea:
.ClipTop    equ 0
.ClipLeft   equ 2
.ClipBtm    equ 4
.ClipRight  equ 6

    movsx eax,word [esi+.ClipTop]
    movsx edi,word [esi+.ClipLeft]
    movsx ecx,word [esi+.ClipBtm]
    movsx edx,word [esi+.ClipRight]

    cmp [Display.RedrawTop],eax
    jle .TopSame
    mov [Display.RedrawTop],eax
.TopSame:
    cmp [Display.RedrawLeft],edi
    jle .LeftSame
    mov [Display.RedrawLeft],edi
.LeftSame:
    cmp [Display.RedrawBtm],ecx
    jge .BtmSame
    mov [Display.RedrawBtm],ecx
.BtmSame:
    cmp [Display.RedrawRight],edx
    jge .RightSame
    mov [Display.RedrawRight],edx
.RightSame:
    ret
%endif


%ifdef UseGuiGfx
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Determines the intersection ("and's") of two clip sets.
;
; (esi=source clip set, edi=destination clip set)
; (; ebx, esi, edi)
AndClips.RedrawToDisplay:
    mov esi,Display.Redraws

AndClips.ToDisplay:
    mov edi,Display.Clips

AndClips:
    mov ecx,[esi+SavedClips.ClipTop]
    mov edx,[esi+SavedClips.ClipLeft]
    cmp [edi+SavedClips.ClipTop],ecx
    jge .TopSame
    mov [edi+SavedClips.ClipTop],ecx
.TopSame:
    cmp [edi+SavedClips.ClipLeft],edx
    jge .LeftSame
    mov [edi+SavedClips.ClipLeft],edx
.LeftSame:

    mov ecx,[esi+SavedClips.ClipBtm]
    mov edx,[esi+SavedClips.ClipRight]
    cmp [edi+SavedClips.ClipBtm],ecx
    jle .BtmSame
    mov [edi+SavedClips.ClipBtm],ecx
.BtmSame:
    cmp [edi+SavedClips.ClipRight],edx
    jle .RightSame
    mov [edi+SavedClips.ClipRight],edx
.RightSame:
    ret
%endif


%ifdef UseGuiGfx
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Determines the combination ("or's") of two clip sets.
;
; (esi=source clip set, edi=destination clip set)
; (; ebx, esi, edi)
OrClips.FromDisplay:
    mov esi,Display.Clips

OrClips:
    mov ecx,[esi+SavedClips.ClipTop]
    mov edx,[esi+SavedClips.ClipLeft]
    cmp [edi+SavedClips.ClipTop],ecx
    jle .TopSame
    mov [edi+SavedClips.ClipTop],ecx
.TopSame:
    cmp [edi+SavedClips.ClipLeft],edx
    jle .LeftSame
    mov [edi+SavedClips.ClipLeft],edx
.LeftSame:

    mov ecx,[esi+SavedClips.ClipBtm]
    mov edx,[esi+SavedClips.ClipRight]
    cmp [edi+SavedClips.ClipBtm],ecx
    jge .BtmSame
    mov [edi+SavedClips.ClipBtm],ecx
.BtmSame:
    cmp [edi+SavedClips.ClipRight],edx
    jge .RightSame
    mov [edi+SavedClips.ClipRight],edx
.RightSame:
    ret
%endif


%ifdef UseGuiGfx
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Copies clips from one set to another.
;
; (esi=source clip set, edi=destination clip set)
; (; ebx, esi, edi)
CopyClips.RedrawToDisplay:
    mov esi,Display.Redraws
    mov edi,Display.Clips
    jmp short CopyClips

CopyClips.DisplayToRedraw:
    mov edi,Display.Redraws

CopyClips.FromDisplay:
    mov esi,Display.Clips

CopyClips:
    mov ecx,[esi+SavedClips.ClipTop]
    mov edx,[esi+SavedClips.ClipLeft]
    mov [edi+SavedClips.ClipTop],ecx
    mov [edi+SavedClips.ClipLeft],edx
    mov ecx,[esi+SavedClips.ClipBtm]
    mov edx,[esi+SavedClips.ClipRight]
    mov [edi+SavedClips.ClipBtm],ecx
    mov [edi+SavedClips.ClipRight],edx
    ret
%endif


%ifdef UseGuiGfx
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sets the dimensions of a clip to its minimum extents (or rather its maximum
; negative extents), making it invalid to draw in.
;
; (ebx=gui item ptr, esi=container's redraw bounds saved clips ptr)
; (; ebx,esi,edi)
EmptyClips.Redraw:
    mov edi,Display.Redraws
EmptyClips:
    mov dword [edi+SavedClips.ClipLeft],32767
    mov dword [edi+SavedClips.ClipTop],32767
    mov dword [edi+SavedClips.ClipRight],-32768
    mov dword [edi+SavedClips.ClipBtm],-32768
    ret
%endif


%ifdef UseGuiGfx
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Add's a GUI item's top/left offset to the clips.
;
; (ebx=gui item)
; (; ebx,esi)
OffsetGuiClips:
    movsx eax,word [ebx+GuiObj.Top]
    movsx ecx,word [ebx+GuiObj.Left]
    add [Display.ClipTop],eax
    add [Display.ClipLeft],ecx
    add [Display.ClipBtm],eax
    add [Display.ClipRight],ecx
    ret
%endif


%ifdef UseGuiGfx
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Merges the dimensions of a given GUI item from the stack saved clips of
; that item's container, adjusting the current screen clips. The top/left of
; the item is added to the saved clips, while the clips boundaries are
; subtracted from them. Used by container's before relaying redraw messages
; to their items.
;
; Since all clipping is relative to the saved clips passed to this routine
; (rather than the static display clip variables) it is possible to do all
; container drawing to an offscreen temporary buffer, allowing special
; effects like pixel fades and dissolves.
;
; (ebx=gui item ptr, esi=stack saved clips ptr)
; (; ebx,esi)
SetGuiItemClips.FromDisplay:
    mov esi,Display.Clips

SetGuiItemClips:
    movsx eax,word [ebx+GuiObj.Top]
    movsx edi,word [ebx+GuiObj.Left]
    mov ecx,eax
    push eax
    push edi
    push eax
    push edi

    ; add GUI items relative top/left to display top/left
    ; calcualte display ptr (top*width)+left
    imul ecx,[Display.Width]    ;row * screen width
    add eax,[esi+SavedClips.Top]
    add ecx,edi
    shl ecx,1                   ;*2bpp
    add edi,[esi+SavedClips.Left]
    add ecx,[esi+SavedClips.Ptr]
    mov [Display.Top],eax
    mov [Display.Left],edi
    mov [Display.Ptr],ecx

    pop edx
    pop ecx
    pop edi
    pop eax

    ; if gui top >= sclip top
    ;   clip top = 0
    ; else
    ;   clip top = sclip top - gui top
    ; endif
    sub eax,[esi+SavedClips.ClipTop]
    neg eax
    jge .TopOkay
    xor eax,eax
.TopOkay:
    mov [Display.ClipTop],eax
    mov [Display.RedrawTop],eax

.CheckLeft:
    ; if gui left >= clip left
    ;   clip left = 0
    ; else
    ;   clip left = sclip left - gui left
    ; endif
    sub edi,[esi+SavedClips.ClipLeft]
    neg edi
    jge .LeftOkay
    xor edi,edi
.LeftOkay:
    mov [Display.ClipLeft],edi
    mov [Display.RedrawLeft],edi

.CheckBtm:
    ; if sclip bottom - gui top <= item height
    ;   clip bottom = height
    ; else
    ;   clip bottom = sclip bottom - gui top
    ; endif
    sub ecx,[esi+SavedClips.ClipBtm]
    neg ecx
    cmp [ebx+GuiObj.Height],cx
    jge .ClippedBtm
    movzx ecx,word [ebx+GuiObj.Height]
.ClippedBtm:
    mov [Display.ClipBtm],ecx
    mov [Display.RedrawBtm],ecx

.CheckRight:
    ; if sclip right - gui left <= item width
    ;   clip right = width
    ; else
    ;   clip right = sclip right - gui left
    ; endif
    sub edx,[esi+SavedClips.ClipRight]
    neg edx
    cmp [ebx+GuiObj.Width],dx
    jge .ClippedRight
    movzx edx,word [ebx+GuiObj.Width]
.ClippedRight:
    mov [Display.ClipRight],edx
    mov [Display.RedrawRight],edx
    ret
%endif


%ifdef UseGuiGfx
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sets the redraw variables for an item, given a saved clip set with the
; redraw boundaries in them.
;
; (ebx=gui item ptr, esi=container's redraw bounds saved clips ptr)
SetGuiItemRedraw.FromRedraw:
    mov esi,Display.Redraws

SetGuiItemRedraw:
    ; leave alone top/left of display
    ; leave alone display ptr

    movsx eax,word [ebx+GuiObj.Top]
    movsx edi,word [ebx+GuiObj.Left]
    neg eax
    neg edi
    mov ecx,eax
    mov edx,edi
    add eax,[esi+SavedClips.ClipTop]
    add edi,[esi+SavedClips.ClipLeft]
    add ecx,[esi+SavedClips.ClipBtm]
    add edx,[esi+SavedClips.ClipRight]

    cmp [Display.ClipTop],eax
    jle .TopSame
    mov eax,[Display.ClipTop]
.TopSame:
    cmp [Display.ClipLeft],edi
    jle .LeftSame
    mov edi,[Display.ClipLeft]
.LeftSame:
    cmp [Display.ClipBtm],ecx
    jge .BtmSame
    mov ecx,[Display.ClipBtm]
.BtmSame:
    cmp [Display.ClipRight],edx
    jge .RightSame
    mov edx,[Display.ClipRight]
.RightSame:

    mov [Display.RedrawTop],eax
    mov [Display.RedrawLeft],edi
    mov [Display.RedrawBtm],ecx
    mov [Display.RedrawRight],edx
    ret
%endif


%ifdef UseDisplayBuffer
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Transfers image from screen buffer to physical display.
;
; !Warning! This routine assumes the redraw ranges ARE correct. If they were
; set incorrectly, it wouldn't be surprising to see this routine transfer
; more than it should.
;
; ([Display.ClipTop,Display.ClipLeft...])

TransferScreen:
 %ifdef DosVer
  %if UseDisplayBuffer=2 ;full screen transfer
    ; entire buffer is copied to display, even if only a button was clicked
    cld
    mov esi,Screen.Buffer
    mov edi,Screen.Adr
    mov ecx,(Screen.Height*Screen.Width)/4
    rep movsd

  %elif UseDisplayBuffer=1 ;selective transfer
    ; only copies pixel rows that have changed

    push dword [Display.Height] ;set row counter
    mov eax,[Display.RedrawRangePtr]
    mov esi,Screen.Buffer
    mov edi,[Display.BasePtr] ;Screen.Adr
    cld
.NextRow:
    ; determine strip length
    mov ecx,[eax]
    and ecx,~3
    add esi,ecx
    lea edx,[-Screen.Width+ecx] ;remaining wrap width after transfer
    add edi,ecx
    sub ecx,[eax+4]
    and ecx,~3
    sub edx,ecx                 ;remaining wrap width after transfer

    ; transfer row
    neg ecx
  %if GfxAddressCheck
    cmp ecx,Screen.Width
    jbe .Ok
    int3
  .Ok:
  %endif

    shr ecx,2                   ;/4 for dwords
    rep movsd

  %if GfxAddressCheck
    cmp edi,Screen.Adr+Screen.Bytes
    jbe .Ok2
    int3
  .Ok2:
  %endif

    ; reset strip length & advance row
    mov dword [eax],0
    sub esi,edx
    mov dword [eax+4],0
    sub edi,edx
    add eax,byte 8
    dec dword [esp]             ;one less row
    jg .NextRow
    pop ecx                     ;discard counter

  %endif

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 %elifdef WinVer
    ;api BeginPaint, [hwnd],ps
    xor eax,eax
    ;api SetDIBitsToDevice, [hdc],eax,eax, Screen.Width,Screen.Height,eax,eax, eax,Screen.Height, Screen.Buffer,Display.BmpHeader,DIB_RGB_COLORS
    ;api SetDIBitsToDevice, [hdc],eax,eax, Screen.Width,Screen.Height,eax,eax, eax,Screen.Height, Screen.Buffer,Display.BmpHeader,DIB_PAL_COLORS
    ;api SetDIBitsToDevice, [hdc],eax,eax, Screen.Width,Screen.Height,eax,eax, eax,Screen.Height, [Display.Ptr],Display.BmpHeader,DIB_RGB_COLORS
    api BitBlt, [hdc],eax,eax,Screen.Width,Screen.Height, [Display.hdcc],eax,eax, SRCCOPY
    ;api EndPaint, [hwnd],ps
 %endif

    ret

%endif


%ifdef UseDisplayBuffer
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Marks area of screen as being updated and needing transference from virtual
; screen to real screen.
;
; !Warning! This routine assumes the clips ARE correct. If they were
; calculated incorrectly, it wouldn't be surprising to later see the
; TransferScreen routine transfer more than it should.
;
; ()
; (; ebx,esi)
AddClipsToRedrawRange:
    mov esi,Display.Clips
.Given: ;(esi=redraw bounds saved clips ptr)
    cmp dword [Display.RedrawRangePtr],0
    je .End

    mov eax,[esi+SavedClips.ClipTop]
    mov edi,[esi+SavedClips.ClipBtm]
    sub edi,eax                 ;height = bottom - top
    jle .End                    ;TopClip >= BtmClip
    add eax,[Display.Top]       ;row += top

    mov ecx,[Display.Left]
    mov edx,ecx
    add ecx,[esi+SavedClips.ClipLeft]
    add edx,[esi+SavedClips.ClipRight]
    cmp ecx,edx
    jge .End                    ;LeftClip >= RightClip

    shl eax,3                   ;*8 bytes per edge range
    add eax,[Display.RedrawRangePtr]
.NextRow:
    cmp [eax+4],edx
    jae .RightSame
    cmp [eax+4],dword 0
    mov [eax+4],edx
    jbe .SetLeft
.RightSame:
    cmp [eax],ecx
    jbe .LeftSame
.SetLeft:
    mov [eax],ecx
.LeftSame:
    add eax,byte 8
    dec edi
    jg .NextRow
.End:
    ret
%endif


%ifdef UseDisplayBuffer
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Should be called after using TransferScreen. Intentionally separated so
; that it can be called from anywhere.
ClearRedrawArea:
    cld
    mov ecx,[Display.Height]
    xor eax,eax
    mov edi,[Display.RedrawRangePtr]
    shl ecx,1                   ;*2 for two the dwords, left and right sides
    rep stosd
    ret
%endif


%ifdef UseGuiFonts
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Get Text Width
; (dwords text ptr, text length)
; (eax=pixel width)
;
; Returns the pixel width for a text string by adding up the widths of all
; the characters. Character spacing is one pixel.
;
GetTextLenWidth:
    mov esi,[esp+4]             ;get text ptr
    xor eax,eax                 ;zero width counter
    mov ecx,[esp+8]             ;get text length
    xor edx,edx
    mov ebx,[Font.SizesPtr]     ;get ptr to current font's size table
    dec ecx
    js .End
    ;mov dl,byte [esi]
    ;mov al,byte [ebx+edx]       ;get width of first character
    ;jmp short .FirstChar
.NextChar:
    mov dl,byte [esi]
    mov dl,byte [ebx+edx]       ;get width of character
    lea eax,[eax+edx+1]         ;add character width to destination, plus separation of one pixel space
.FirstChar:
    inc esi
    dec ecx                     ;decrement string length counter
    jns .NextChar
.End:
    ret
%endif


%ifdef UseGuiFonts
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Returns the number of whole characters that will fit in a given pixel width.
; If the string is less than the maximum width, it will simply return the
; number of characters in the string. If the last character is clipped, it
; will not be included.
;
; (dwords text ptr, text length, maximum width)
; (eax=whole characters)
GetTextWidthLen:
.Forward:
    mov eax,[esp+8]             ;get maximum text length
    mov esi,[esp+4]             ;get text ptr
    test eax,eax
    jz .Abort
    mov ecx,[esp+12]            ;get maximum width
    xor edx,edx                 ;zero character ptr
    mov ebx,[Font.SizesPtr]     ;get ptr to current font's size table

.NextChar:
    mov dl,byte [esi]
    mov dl,byte [ebx+edx]       ;get width of character
    sub ecx,edx                 ;subtract character width from total width
    jl .End                     ;end loop if total width has been exceded or matched
    dec ecx                     ;subtract separation of one pixel space
    inc esi
    dec eax                     ;decrement string length counter
    jg .NextChar                ;continue if not zero or less
.End:
    neg eax
    add eax,[esp+8]
.Abort:
    ;(edx=width of last character, ecx=final count)
    ret

.Nearest:
    push dword [esp+12]         ;chain call
    push dword [esp+12]
    push dword [esp+12]
    call .Forward
    cmp eax,[esp+8]             ;end if return value >= string length
    jae .nEnd
    neg ecx                     ;count should be negative or zero
    shl ecx,1
    cmp ecx,edx
    adc eax,0
.nEnd:
    add esp,byte 12
    ret

%if 0
    mov esi,[esp+4]             ;get text ptr
    mov ecx,[esp+8]             ;get maximum text length
    xor eax,[esp+12]            ;get width
    xor edx,edx
    mov ebx,[Font.SizesPtr]     ;get ptr to current font's size table
    test ecx,ecx
    jz .End
    mov dl,byte [esi]
    mov dl,byte [ebx+edx]       ;get width of first character
    jmp short .FirstChar
.NextChar:
    inc edx                     ;add separation of one pixel space
    sub eax,edx                 ;subtract character width from total width
    jle .End                    ;end loop if total width has been exceded or matched
    mov dl,byte [esi]
    mov dl,byte [ebx+edx]       ;get width of character
.FirstChar:
    inc esi
    dec ecx                     ;decrement string length counter
    jg .NextChar                ;continue if not zero or less
.End:
    mov eax,[esp+8]
    sub eax,ecx
    ret
%endif

.Reverse:
;Starts from the back of a given string instead of front
; (dwords text ptr, text length, maximum width)
    mov eax,[esp+8]             ;get maximum text length
    mov esi,[esp+4]             ;get text ptr
    test eax,eax
    jle .rEnd
    lea esi,[esi+eax-1]         ;char ptr + length -1
    mov ecx,[esp+12]            ;get maximum width
    xor edx,edx                 ;zero character ptr
    mov ebx,[Font.SizesPtr]     ;get ptr to current font's size table

.rNextChar:
    mov dl,byte [esi]
    mov dl,byte [ebx+edx]       ;get width of character
    sub ecx,edx                 ;subtract character width from total width
    jl .End                     ;end loop if total width has been exceded or matched
    dec ecx                     ;subtract separation of one pixel space
    dec esi                     ;char ptr --
    dec eax                     ;decrement string length counter
    jg .rNextChar               ;continue if not zero or less
.rEnd:
    neg eax
    add eax,[esp+8]
    ret
%endif


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section data
align 4, db 0

; Note the Display variables and Screen constants (found in the graphics
; definitions file) are completely separate and different. The two are
; intentionally separated to break any static relationship between the
; graphics operations and the physical screen. The screen constants obviously
; relate to the actual VGA screen. Otoh, the more abstract Display variables
; hold information of the current field that all graphics functions draw to
; (whether that be to the virtual screen, a bitmap array in memory, or even
; directly to the screen). All the graphics operations are dynamic, able to
; render to a display of any size; and all are clipped. Their one limitation
; is only supporting 8bit drawing.

Display:
; These must only be changed if the video mode is changed, or a temporary
; off screen buffer is being used (for special effects). If changed by an
; item, they must be restored before returning to the container.
.Height:        dd Screen.Height
.Width:         dd Screen.Width
%ifdef DosVer
.BasePtr:       dd Screen.Adr   ;actual base of display (!imperative that this be restored if changed!)
%endif
%ifdef UseGuiPalette
.Palette:       dd GuiPalette
%endif

; ! these must be the same order as the SavedClips structure !

; The clipping area is where drawing operations must stay inside. For GUI
; items, this area is relative to their top/left. Items must stay within the
; clip area, but need not draw to the extent the clips are set. Since the
; container can not know exactly how much its contained items need to redraw,
; they may be given more area than they actually need.
;
; An item should never make the clips larger than those passed to item by its
; container, only shrunk. Drawing outside the display buffer could cause a
; nice GPF. There is no need for an item to restore these if changed, but it
; should return them large enough to encompass the area actually redrawn -
; so the container knows.
.Clips:
.ClipLeft:      dd 0            ;clip relative to Left
.ClipTop:       dd 0            ;clip relative to Top
.ClipRight:     dd Screen.Width
.ClipBtm:       dd Screen.Height

; These usually point within the main display buffer, but can actually point
; anywhere. Ptr can be set instead to pixel array (bitmap data).
.Left:          dd 0            ;current window column offset
.Top:           dd 0            ;current window row offset
.Ptr:           dd Screen.Buffer;current offset relative to top/left (might change each clipping operation)

%ifdef UseGuiGfx
; The redraw area is where the item should redraw because other items either
; under or over have redrawn themselves. It is always within the clip area,
; relative to the items top/left. If the item needs to be completely redrawn
; (not just a portion) the redraw area will be as large as the clip area. The
; difference between the two areas is that the clips are where it is 'allowed'
; to draw; the redraw area is where is 'should' draw.
.Redraws:
.RedrawLeft:    dd 32767
.RedrawTop:     dd 32767        ;top area to redraw (relative to Top)
.RedrawRight:   dd -32768
.RedrawBtm:     dd -32768
%ifdef UseDisplayBuffer
.RedrawRangePtr:dd Screen.RedrawRange
%endif
%endif

.RedrawItems    equ 1
.RedrawCursor   equ 2           ;cursor was moved or changed
.ShowCursor     equ 4           ;cursor is visible (not hidden)
.CursorMoved    equ 8           ;cursor was moved or changed
.RedrawPalette  equ 16          ;redraw because of palette change
.RedrawFlags:   dd .RedrawItems|.RedrawCursor   ;flags what needs redrawing

; these clipping variables are dynamic and can change every gfx operation
.ClipHeight:    dd Screen.Height
.ClipWidth:     dd Screen.Width
.ClipTopOfs:    dd 0            ;offset from top after clip
.ClipLeftOfs:   dd 0            ;offset from left after clip, example: a bitmap to be shown at column 50 is left clipped at 65, so the left offset is 15
.ClipBtmOfs:    dd 0
.ClipRightOfs:  dd 0
.ClipPtr:       dd 0;Screen.Adr
.ClipWrap:      dd 0
.ClipCharsPtr:  dd 0

%ifdef WinVer
.hdib:          dd 0            ;handle to DIB section
.hdcc:          dd 0            ;handle of compatible DC
.BmpHeader:
dd BITMAPINFOHEADER_size        ;.biSize
dd Screen.Width                 ;.biWidth
dd -Screen.Height               ;.biHeight
dw 1                            ;.biPlanes
dw 16                           ;.biBitCount
dd 0;BI_BITFIELDS               ;.biCompression
dd Screen.Width*Screen.Height   ;.biSizeImage
dd 0                            ;.biXPelsPerMeter
dd 0                            ;.biYPelsPerMeter
dd 0;256                        ;.biClrUsed (arbitrary for now)
dd 0;16                         ;.biClrImportant
;dd 001Fh,03E0h,7C00h            ;masks in BGR order (yes, it is silly)
%endif

%ifdef UseGuiFonts
Font:
.Size:
.Height:        db FontDefHeight;total height of character from top to bottom extension
.Width:         db FontDefWidth
.BodyHeight:    db FontDefHbody ;height of character's main body, not including the bottom extension found in "y","g","p","q"...
                db 0            ;(alignment filler)
.Colors:        db 4,3,0,0      ;fore color/border color/shadow color/background color
.CharsPtr:      dd GuiFontLetters
.SizesPtr:      dd GuiFontSizes
.CharacterSpacing   equ 1
%endif

%ifdef UseGuiCursor
; Notice there are no mouse specific variables in here. That's because the
; graphics routines have nothing to do with the mouse driver. They simply
; display the cursor. After all, it's possible for a cursor to exist without
; a mouse connected to the computer. Some games allow you to control the
; cursor with a joystick.
Cursor:
.Row:           dd 16384        ;current pixel position
.Col:           dd 16384        ;(start off screen)
.RowDif         equ Mouse.RowDif ;pixel change, ignoring clipping
.ColDif         equ Mouse.ColDif
.RowOffset:     dd 0            ;amount cursor image is offset from actual
.ColOffset:     dd 15           ; mouse position (cursor hot-spot)
.RowPrev:       dd 0            ;previous hotspot position of cursor
.ColPrev:       dd 0
.RowHide:       dd 0            ;previous pixel position of cursor image (Row and RowOffset are summed)
.ColHide:       dd 0            ;(Col and ColOffset are summed)
%ifdef WinVer
.Top:           dd -32768
.Left:          dd -32768
.Btm:           dd 32767
.Right:         dd 32767
%else ;DosVer
.Top:           dd 0
.Left:          dd 0
.Btm:           dd Screen.Height
.Right:         dd Screen.Width
%endif
.Ptr:           dd 0            ;pointer to last used cursor
section bss
.SizeOf         equ .Size*.Size*2 ;*** temporary until 16bit cursors created ***
.Image:         resb .SizeOf  ;colored pixels to OR screen with
.Mask:          resb .SizeOf  ;mask to AND screen contents with
.BgImage:       resb .SizeOf  ;section of screen behind cursor
section data
%endif
