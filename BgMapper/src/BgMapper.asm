; BgMapper - Savestate viewer and graphics exporter
; PikenSoft (uncopyright)1998..2021
;
; By Dwayne Robinson (FDwR@hotmail.com)
; http://pikensoft.com/
; http://fdwr.tripod.com/snes.htm
; https://github.com/fdwr/BgMapper
; Assembly compiled with NASM and WDOSX
; Started on Sept 23,1998
;
; Major Thanks to:
;   ZsKnight for answering my annoying questions and the savestate format
;   Qwertie for for his great collection of SNES documents
;   Gaz for his memory and system exiting functions
;
; bgmfuncs.asm - All of the helper routines for this prog
; memory.inc   - Memory allocation (Thanks to Gaz)
; system.inc   - Program startup/shutdown
; bgtile.asm   - Tile conversion, savestate loading, scene rendering
;
; Some of the small routines do save all regs, while the larger ones do not
; save any of the general registers; but always ds, es, and ebp.
;
;--------------------------------------------------

%define ProgVersion ".177"
Safety                  equ 1
Debug                   equ 0

;------------------------------
;  EndProgram
;  StartOptionsCheck
;  Initialize
;  PrintStatus
;  PrintString
;  MainLoop
;  PageViewVram
;  PageViewScene
;  PageSceneInfo
;  GetSceneInfo
;  PageHelp
;  ClearBackground
;  RestoreFullPalette
;  ExportScene
;------------------------------

BITS 32                     ;flat addressing is great!
GLOBAL Main                 ;great (free!) extender
GLOBAL _WdosxStart

%include "bgmapper.mac"     ;essential definitions and macros, just kept out for clarity
%include "system.mac"       ;used for a clean exit
%include "memory.mac"       ;used for memory allocation
    
;------------------------------
; Here it starts
;
SECTION .text

_WdosxStart:
Main:
                                            ;save ptr to command line parameters
    mov [StartOptCount],esi                 ;the number of parameters
    mov [StartOptPtrs],edi                  ;array of pointers to each one
    mov [StartOptEnv],ebp                   ;command environment strings
    mov [StartOptSelector],es               ;save selector
    push ds                                 ;now that es is saved, make sure es equals ds
    pull es                                 ;we don't want any crashes!
    call StartOptionsCheck                  ;interpret what commandline parameters say
    jc near EndProgram.WithMessage          ;edx should already be set to error message
    test byte [StartOptions],0FFh           ;check if any parameters were given
    mov edx,StartOptionMessages.HelpText    ;set in case jump is taken
    jz near EndProgram.WithMessage          ;otherwise end with version info and options
    test byte [StartOptions],StartOptions.FileGiven   ;check if file was given
    mov edx,Messages.NoFileGiven            ;no file was given
    jz near EndProgram.WithMessage

    call Initialize.Heap        ;allocate a memory heap
    call Initialize.Savestate   ;load the file specified

    test byte [StartOptions],StartOptions.ZstInfoOnly
    jz .SkipZstInfo
    call GetSceneInfo.ResetToFirstItem
    jmp short .FirstSceneInfoItem
  .NextSceneInfoItem:
    mov edx,esi
    mov ah,9                    ;DOS: print string
    int 21h
  .FirstSceneInfoItem:
    call GetSceneInfo
    jnc .NextSceneInfoItem
    jmp short EndProgram
  .SkipZstInfo:

    call Initialize.EverythingElse  ;sets the screen mode and mouse
    call PageViewScene
    call MainLoop

EndProgram:
    Exit                        ;call all exit routines before dying
    mov ax,4C00h                ;DOS: terminate program
    int 21h                     ;bye-bye :-)

.WithMessage:
    push edx                    ;save message ptr
    Exit                        ;call all exit routines, but do not die yet
    pop esi                     ;retrieve message and ptr
    call PrintString
    mov ax,4C01h                ;DOS: terminate program
    int 21h                     ;bye-bye :-/

;------------------------------------------------------------
; STARTUP FUNCTIONS
;------------------------------------------------------------
;------------------------------
; StartOptionsCheck () (cf=error, edx=message ptr if error) - Does not preserve regs
;
; Checks the command line parameters and sets StartOptions accordingly
; Can return with success or an error and text message.
; May not directly end the program, but returning carry indicates that it should be ended.
;
StartOptionsCheck:
    mov edx,1               ;start with first parameter
    push eax                ;make storage for dword
    cld                     ;as always, go forward
.NextParameter:
    cmp edx,[StartOptCount] ;check that not greater than last one
    jae .NoneLeft           ;checked them all
    call .GetNextParameter  ;get next parameter option
    cmp al,'-'              ;is it an option?
    jne near .FileNameFound ;if not, assume it is the filename
    inc esi                 ;next character
    mov edi,.List           ;set option string pointer to first one
    mov [esp],esi           ;make a copy
    xor ebx,ebx             ;set compare option to first one
    movzx ecx,byte [edi]    ;get length of option string
.CompareNextOption:
    inc edi                 ;first character of option string
    lea eax,[edi+ecx]       ;get next option string after this one
    repe cmpsb              ;compare parameter with current option string
    je .DoOption            ;there is a match
    mov cl,[eax]            ;no match, get length of next option string
    inc ebx                 ;next option number
    mov esi,[esp]           ;reset parameter character to first one
    mov edi,eax             ;next option string
    test ecx,ecx            ;check that we have not reached last option
    jnz .CompareNextOption  ;keep on comparing
    mov edx,StartOptionMessages.InvalidParameter
.Exit:
    pull eax                ;cheap restore stack
    stc                     ;flag error, unkown parameter
    ret

.NoneLeft:
    pull eax        ;cheap restore stack
    clc         ;no errors, all parameters were ok
    ret

.DoOption:
    ;option match is given a number in ebx
    ;using a jump table, the option is jumped directly too
    ;then it either exits with an error or returns to get the next parameter
    cmp ebx,.JumpTableSize                  ;just in case of something weird
    jae .NextParameter                      ;bad option passed on
    jmp [.JumpTable+ebx*4]                  ;jump to the right response
  .AuthorInfo:
    mov edx,StartOptionMessages.AuthorInfo  ;set text message ptr
    jmp short .Exit
  .Help:
    mov edx,StartOptionMessages.HelpText    ;set text message ptr
    jmp short .Exit
  .VideoMode:
    cmp edx,[StartOptCount]                 ;check that a video mode is given
    jae .VideoModeError
    call .GetNextParameter
    sub al,48                               ;turn ASCII number into real one
    cmp al,ScreenModesNum                   ;make sure it is a valid one
    jae .VideoModeError
    or byte [StartOptions],StartOptions.VideoModeGiven    ;flag that video mode was given
    mov [ScreenListMode],al                 ;save screen mode for later reading
    jmp .NextParameter
   .VideoModeError:
    mov edx,StartOptionMessages.InvalidScrnMode ;set text message ptr
    jmp short .Exit
  .ZstVideoMode:
    cmp edx,[StartOptCount]                 ;check that a video mode is given
    jae .ZstVideoModeError
    call .GetNextParameter
    sub al,48                               ;turn ASCII number into real one
    cmp al,8                                ;make sure it is a valid one
    jae .ZstVideoModeError
    or dword [StartOptions],StartOptions.ZstVideoModeGiven    ;flag that zst video mode was given
    mov [ZstVideoMode],al                   ;save screen mode for later reading
    jmp .NextParameter
   .ZstVideoModeError:
    mov edx,StartOptionMessages.InvalidZstVideo ;set text message ptr
    jmp short .Exit
  .ZstInfoOnly:
    or byte [StartOptions],StartOptions.ZstInfoOnly
    jmp .NextParameter
  .FullStatusDisplay:
    or byte [StartOptions],StartOptions.StatusDisplay
    jmp .NextParameter
  .FileNameFound:
    mov edi,SavestateFilename
    mov ecx,256/4       ;copy up to 256 bytes from source
    rep movsd
    or byte [StartOptions],StartOptions.FileGiven
    jmp .NextParameter

.GetNextParameter:
    mov esi,[StartOptPtrs]  ;get pointer to table
    mov esi,[esi+edx*4] ;get pointer to string
    mov al,[esi]        ;get first character of parameter
    inc edx         ;for next parameter
    ret

.List:
    ;first byte is length of string (null included)
    ;then follows the null terminated
    ;since the length is one byte, an option can actually be fairly long
    db 3,'fv',0     ;force SNES video mode
    db 2,'v',0      ;video mode
    db 2,'?',0      ;help
    db 2,'h',0      ;also help
    db 3,'sd',0     ;display status info when starting
    db 5,'info',0   ;savestate information only
    db 0            ;the last option a zero counter

align 4,db 0
.JumpTableSize equ 6
.JumpTable:
    dd .ZstVideoMode,.VideoMode,.AuthorInfo,.Help,.FullStatusDisplay,.ZstInfoOnly

;------------------------------
; Initialize ()
; Sets up various necessities
; Has the power to end the program
;
; Allocates memory heap
; Initializes all the variables
; Loads the any file specified
; Sets the screen mode
; Sets up the mouse
;
Initialize:
.Heap:
    mov esi,Messages.HeapInitializing
    call PrintStatus
    HeapInit 1048576*2      ;make some memory available
    mov edx,Messages.HeapInitErr
    jc near EndProgram.WithMessage  ;if such a thing would ever happen?
    ret

.Savestate:
    call SaveStateLoad              ;read in the savestate
    mov edx,Messages.ErrorLoadingFile ;in case it did not load
    jc near EndProgram.WithMessage
    call VramReset                  ;clear both graphics and palette tables
    mov esi,Messages.FileWasLoaded  ;everything went ok
    call PrintStatus                ;print message or filename
    ret

.EverythingElse:

;--mouse--
    call MouseInitialize        ;check for a mouse and set up pointer variables
    mov esi,Messages.NoMouse    ;assume no mouse exists at first
    mov al,[MouseButtons]       ;get number of buttons mouse has
    test al,al                  ;check if no mouse
    jz .NoMousePresent          ;zero buttons, no mouse was detected
    add al,48                   ;turn into an ASCII number
    mov esi,Messages.MouseExists
    mov [Messages.MouseButtons],al  ;move number of buttons into message
  .NoMousePresent:
    call PrintStatus

;--wait for user--
    test byte [StartOptions],StartOptions.StatusDisplay   ;is full status display set?
    jz .SkipDisplayWait             ;end if not
    mov esi,Messages.PressAnyKey
    call PrintString
    call UserWait                   ;wait for user to see status
    cmp al,27                       ;escape pressed?
    je near EndProgram
  .SkipDisplayWait:

;--set video mode--
    call SetFullVideoMode           ;set to mode 13h for now
    AtExit SetVideoMode.Text        ;make sure text mode is restored later
    call RestoreFullPalette.Set

;--reset mouse--
    xor eax,eax                     ;reset mouse because of changing video mode
    call MouseFunction
    call MouseGetInfo               ;get and set initial mouse row and column
    call Pointer.Show               ;show mouse **

    ret

;.0:
;   ;check for long filenames
;   test byte [StartOptions],StartOpLongFilenamesSet ;is use explicitly set
;   jnz .SkipWindows95Check             ;yes, so do not detect Win95
;   mov ax,440Dh                     ;DOS: IOCTL information
;   mov cx,870h
;   mov bx,0
;   int 21h                     ;see if Win95 exists
;   jc .1                       ;error so not Win95
;   jmp short .UseLongFilenames         ;is Win95
;  .SkipWindows95Check:
;   test byte [StartOptions],StartOpLongFilenamesSet ;use or do not use?
;   jz .1                       ;do not use
;  .UseLongFilenames:
;   or dword [MainOptions],MainOpLongFilenamesUse   ;use long filenames
;.1:
;   ;check for a file given from the command line
;   test byte [StartOptions],StartOptions.FileGiven
;   jnz .FilenameGiven
;   mov byte [SavestateFilename],0          ;set filename to null
;  .FilenameGiven:

;------------------------------
; PrintStatus (esi=message ptr) ()
;
; Small function used during initialization to output startup status messages
;
PrintStatus:
    test byte [StartOptions],StartOptions.StatusDisplay   ;is full status display set?
    jz PrintString.End          ;skip if not
PrintString:
    call GetStrLength           ;get length of message
    mov edx,esi                 ;copy text ptr to edx
    add esi,eax
    push dword [esi]
    ;push esi                    ;save message end ptr
    mov dword [esi],240D0Ah     ;put terminator with line end (silly dollar sign)
    mov ah,9                    ;DOS: print string
    int 21h
    ;pop esi
    pop dword [esi]
.End:
    ret

;------------------------------------------------------------
; MAIN FUNCTION PAGES
;------------------------------------------------------------
;------------------------------
; Responsible for calling a function when another page lets it know
; This is what calls the title page, main menu, load window, scene viewer...
; Assumes screen mode and palette have been set, mouse set up, file loaded...
;
MainLoop:
    ;check if a function needs to be called and if so, call that page
    ;otherwise just open the main menu
.Start:
    mov esi,MainMenuStruct
    call MenuCreateAndWait
    jc short .End
    cmp al,MainPageReloadScene
    je .1
    cmp al,MainPageVramViewer
    je .2
    cmp al,MainPageSceneInfo
    je .4
    cmp al,MainPageSceneViewer
    je .5
    ;cmp al,MainPageTilemapViewer
    ;je .6
    cmp al,MainProgExit
    jne .Start
.End:
    ret

.1:
    call SaveStateLoad
    call RestoreFullPalette.Set
    jmp short .Start
.2:
    call PageViewVRAM
    jmp short .Start
;.3:
    ;call DumbTileSpeedTest
    ;jmp short .Start
.4:
    call PageSceneInfo
    jmp short .Start
.5: call PageViewScene
    jmp short .Start
;.6:
    ;call PageViewTilemaps
    ;jmp short .Start

align 4
Pages:
.Redraw:    dd 0

;------------------------------
; Displays the tile graphics in VRAM and WRAM
; Also shows the 256 color SNES palette
;
; Assumes a savestate has been loaded
;
PageViewVRAM:
  .TileWindow_Height    equ 24
  .TileWindow_Width     equ 16
  .ColorBlocks_Height   equ 7
  .ColorBlocks_Width    equ 11
  .ColorBlocks_LeftCol  equ 316-(16*.ColorBlocks_Width)
  .ColorBlocks_TopRow   equ 4
  .Draw_Full            equ 128
  .Draw_ColorBlocks     equ 4
  .Draw_Info            equ 2
  .Draw_TileWindow      equ 1
    mov [FontColorsPtr],dword FontColors1   ;set current font color set
    mov [VramTileFill.Dimensions],dword .TileWindow_Width | (.TileWindow_Height<<16)
    mov [Pages.Redraw],byte .Draw_Full | .Draw_ColorBlocks | .Draw_Info | .Draw_TileWindow
    jmp .Draw

.InputLoop:
    call KeyGetPress
    jnc .NoKeysPressed
    cmp al,27       ;escape?
    je .End
    mov esi,.ScrollKeys
    call KeyScan
    jnc .NoKeysPressed
    jmp dword [.KeysJumpTable+ecx*4] ;jump to the right key response
  .NoKeysPressed:
    call MouseGetInfo
    jnc .InputLoop
    movzx eax,word [MouseRow]
    movzx ebx,word [MouseCol]
    mov esi,.MouseAreas
    call ScanMouseAreas
    jnc .InputLoop
    jmp dword [.MouseJumpTable+ecx*4] ;jump to the right key response
.End:
    ret

;(eax=row, ebx=column)
;set color at tile if left click, get color of tile if right click,
;set drawing color and default colors to tile if right double click
.MouseTileWindow:
    mov edx,[MouseBtns]         ;get mouse buttons pressed and released
    test edx,10003h             ;left/right press or left drag?
    jz near .InputLoop
    shr eax,3                   ;/8 pixel row to tile row
    shr ebx,3                   ;/8 pixel column to tile column
    shl eax,4                   ;*16 number of tiles per row
    lea ecx,[eax+ebx]
    test edx,3                  ;left or right button pressed?
    jnz .MtwButtonPressed
    cmp ecx,[.PreviousChangedTile]
    je near .InputLoop
.MtwButtonPressed:
    mov [.PreviousChangedTile],ecx
    mov esi,[VramTileFill.SourceTile]
    call SeekVramTiles
    mov al,[.Palette]
    ;decide what to do based on whether left or right is clicked
    test [MouseBtns],byte 2     ;check if right button was pressed
    jnz .MtwRightButton
    call SetVramTilePalette
    jmp .Change
.MtwRightButton:
    call GetVramTilePalette
    mov [.Palette],al           ;set drawing color
    cmp [MouseClickTime],dword 7;double right click?
    ja .InfoChange
    mov [VramFormat.PaletteBase],al ;if so, then change default palette too
    jmp .Change
;(eax=row, ebx=column)
;set default colors if left click, set drawing color if right click
.MouseColoredBlocks:
    test [MouseBtnsPressed],byte 3  ;left/right press?
    jz near .InputLoop
    mov ecx,.ColorBlocks_Height
    xor edx,edx
    div ecx                     ;get row
    mov esi,eax
    mov ecx,.ColorBlocks_Width
    mov eax,ebx                 ;set dividend to mouse column
    xor edx,edx
    div ecx                     ;get column
    shl esi,4                   ;row * 16
    add eax,esi                 ;column + row
    and eax,~3
    test [MouseBtns],byte 1     ;check if right button was pressed
    jnz .McbColorSelect
    mov [VramFormat.PaletteBase],al
    jmp .Change
.McbColorSelect:
    mov [.Palette],al
    jmp short .InfoChange
.KeyToggleRadix:
    mov bl,16                   ;assume hexadecimal
    cmp byte [InfoDefaultRadix],bl
    jne .RadixToHex
    mov bl,10                   ;change to decimal
  .RadixToHex:
    mov [InfoDefaultRadix],bl
    ;jmp short .InfoChange
.InfoChange:
    or byte [Pages.Redraw],.Draw_Info
    jmp .Draw
;.KeyExport:
    ;call ExportScene.Graphics
    ;mov dword [VramTileFill.Dimensions],16 | (23<<16)   ;restore window
    ;jmp short .Change
.KeyChangeFormat:
    mov eax,ecx
    call VramFormatDefault
    jmp .Change
.KeyFormatVram:
    call VramFormatMainParts
    jmp .Change
.KeyUnformatVram:
    call VramReset.Format
    jmp .Change
.KeyPaletteVram:
    call VramFormatSetPalettes
    jmp short .Change
.KeyUnpaletteVram:
    call VramReset.Palette
    jmp short .Change
.KeyExport:
    mov esi,GfxExportMenuStruct
    call MenuCreateAndWait
    jc .KeyExport_Cancel
    cmp al,ExportScene.TotalFunctions
    jae .KeyExport_Cancel
    movzx eax,al
    call dword [ExportScene.FunctionTable+eax*4]
    ;call RestoreFullPalette.Now
.KeyExport_Cancel:
    mov [Pages.Redraw],byte .Draw_Full | .Draw_ColorBlocks | .Draw_Info | .Draw_TileWindow
    mov dword [FontColorsPtr],FontColors1   ;reset current font color set
    jmp .Draw

.PreviousPalette:
    mov al,-1
    jmp short .PaletteChange
.NextPalette:
    mov al,1
    ;jmp short .PaletteChange
.PaletteChange:
    mov cl,[VramFormat.BitDepth]
    mov bl,[.Palette]
    shr bl,cl                   ;mask off lowest bits
    add bl,al
    shl bl,cl
    mov [.Palette],bl
    mov [VramFormat.PaletteBase],bl
    jmp short .Change

.KeyScroll:
    mov ecx,[.ScrollKeyValues-(.ScrollKeysIndex*4)+ecx*4]
    ;jmp short .ScrollChange
.ScrollChange:
    mov esi,[VramTileFill.SourceTile]
    call SeekVramTiles
    jz near .InputLoop          ;if no change then just jump back
    mov [VramTileFill.SourceTile],esi

.Change:
    or byte [Pages.Redraw],.Draw_Info | .Draw_TileWindow
.Draw:
    call Pointer.Hide

    test byte [Pages.Redraw],.Draw_Full
    jz .DrawColoredBlocks
    mov al,ColorLrGray
    call DrawClearScreen
    DrawBorder 3,4+(8*.TileWindow_Height),3,4+(8*.TileWindow_Width),1
    DrawBorder 3,4+(16*.ColorBlocks_Height),315-(16*.ColorBlocks_Width),316,1
    ;DrawBorder 4+(16*.ColorBlocks_Height),15+(16*.ColorBlocks_Height),316-(16*.ColorBlocks_Width),315,0

  .DrawColoredBlocks:
    test byte [Pages.Redraw],.Draw_ColorBlocks
    jz .DrawInfo
    sub esp,byte DrawBox.Stack+2                ;allocate variables
    mov byte [esp+DrawBox.Stack+0],16       ;set vertical count
    mov byte [esp+DrawBox.Color],0      ;set first color
    mov dword [esp+DrawBox.TopRow],.ColorBlocks_TopRow|((.ColorBlocks_TopRow+.ColorBlocks_Height-1)<<16)        ;set row
  .NextBlockRow:
    mov byte [esp+DrawBox.Stack+1],16       ;set horizontal count
    mov dword [esp+DrawBox.LeftCol],.ColorBlocks_LeftCol|((.ColorBlocks_LeftCol+.ColorBlocks_Width-1)<<16)  ;set column
  .NextBlock:
    call _DrawBox                   ;draw colored block
    add dword [esp+DrawBox.LeftCol],.ColorBlocks_Width|(.ColorBlocks_Width<<16) ;next column to the right
    inc byte [esp+DrawBox.Color]                ;next color
    dec byte [esp+DrawBox.Stack+1]          ;one less column
    jnz .NextBlock                  ;loop until row complete
    add dword [esp+DrawBox.TopRow],.ColorBlocks_Height|(.ColorBlocks_Height<<16)    ;next block down
    dec byte [esp+DrawBox.Stack+0]              ;one less row
    jnz .NextBlockRow               ;loop until blocks are complete
    add esp,byte DrawBox.Stack+2

  .DrawInfo:
    test byte [Pages.Redraw],.Draw_Info
    jz .DrawTiles
    mov eax,[VramTileFill.SourceTile]
    mov edi,.InfoStr+5
    mov ebx,[InfoDefaultRadix]
    mov ecx,5
    call NumToString.OfRadix
    movzx eax,byte [VramFormat.PaletteBase]
    mov edi,.InfoStr+15
    mov ecx,3
    call NumToString.OfLength
    movzx eax,byte [.Palette]
    mov edi,.InfoStr+19
    mov ecx,3
    call NumToString.OfLength
    DrawBox 189,196,137,136+(22*8),ColorLrGray
    FontBlitStr .InfoStr,22,189,137

  .DrawTiles:
    test byte [Pages.Redraw],.Draw_TileWindow
    jz .EndDraw
    call VramTileFill
    mov esi,BgScene.ImageBuffer
    mov edi,0A0000h+(320*4+4)
    mov ecx,(.TileWindow_Height*8)+((.TileWindow_Width*8)<<16)
    mov edx,320-(.TileWindow_Width*8)
    call CopyBufferToScreen ;CopyPalettedBufferToScreen

  .EndDraw:
    mov byte [Pages.Redraw],0
    ;call Pointer.Show
    ;jmp .InputLoop
    push dword .InputLoop
    jmp Pointer.Show

SECTION .data
.ScrollKeys:
    dd .ScrollKeysList
    db 12,6
    
.ScrollKeysList:
    db '1' ;tile format change
    db '2'
    db '3'
    db '4'
    db '-' ;minus (palette change)
    db '+' ;plus
    db 'h' ;hex/dec
    db '0' ;export graphics
    db '8' ;format VRAM
    db '*' ;clear formatting
    db '9' ;autopalette
    db '(' ;clear palettes

.ScrollKeysIndex    equ $-.ScrollKeysList
    db 'H' ;up
    db 'P' ;down
    db 'I' ;page up
    db 'Q' ;page down
    db 'K' ;left
    db 'M' ;right

.MouseAreas:
    dd $+8,2
    dw 4,4,.TileWindow_Height*8,128
    dw .ColorBlocks_TopRow,.ColorBlocks_LeftCol,.ColorBlocks_Height*16,.ColorBlocks_Width*16

align 4
.KeysJumpTable:
    dd .KeyChangeFormat,.KeyChangeFormat,.KeyChangeFormat,.KeyChangeFormat
    dd .PreviousPalette,.NextPalette,.KeyToggleRadix,.KeyExport
    dd .KeyFormatVram,.KeyUnformatVram,.KeyPaletteVram,.KeyUnpaletteVram
    dd .KeyScroll,.KeyScroll,.KeyScroll,.KeyScroll,.KeyScroll,.KeyScroll
    ;dd VramFormatMainParts,VramReset.Format,VramFormatSetPalettes,VramReset.Palette
.MouseJumpTable:
    dd .MouseTileWindow,.MouseColoredBlocks

.ScrollKeyValues:
    dd -16,16,-16*16,16*16,-1,1

.PreviousChangedTile:   dd 65536
.Palette:               db 0
.InfoStr:               db 'Byte:xxxxx Pal:xxx/xxx'
SECTION .text

;------------------------------
; PageViewScene ()
;
; the main part that lets the user scroll the scene around
; scrolls unchanged portions and calls the routines to redraw new portions
; assumes a savestate has been loaded
;
PageViewScene:
  .Draw_Scene           equ 1
  .Draw_RegenScene      equ 2
  .Draw_Message         equ 4
    ;monitor keypresses
    ;adjust variables if scroll keys
    ;return if escape
    ;**check for mouse input
    ;redraw scene with any new messages
    ;mov esi,CursorImages+256;!!!
    ;call CursorSetImage
    call CacheReset
    mov [FontStylePtr],dword FontOutline    ;set font for menu
    mov [BgScene.BackgroundColor],byte ColorLrBg
    mov [Pages.Redraw],byte .Draw_RegenScene
    jmp short .AfterInputLoop

.SetRedraw:
    or [Pages.Redraw],al
.InputLoop:
    call KeyGetPress.Single
    jc .CheckKey
    test byte [Pages.Redraw],255
    jz .InputLoop
.AfterInputLoop:
    call .Draw
    jmp short .InputLoop
.End:
    ret

.CheckKey:
    cmp al,27               ;escape?
    je .End
    mov esi,.ScrollKeys
    call KeyScan
    jnc near .CheckOtherKeys
    shr ecx,1
    mov dx,[.ScrollKeyValues+ecx*2]
    mov al,.Draw_RegenScene
    jnc .ChangeY
    add word [BgScene.ScrollX],dx
    jmp short .SetRedraw
  .ChangeY:
    add word [BgScene.ScrollY],dx
    jmp short .SetRedraw
.CheckOtherKeys:
    mov esi,.OtherKeys
    call KeyScan
    jnc near .InputLoop          ;return if no keys matched
    jmp [.OtherKeysJumpTable+ecx*4] ;jump to the right key response

.KeyTogglePlane:                ;1234 !@#$
    add cl,4                    ;if cl is 4-7 then make it 8-11
    and ecx,3|8
    btc word [BgScene.VisiblePlanes],cx
    call .MakeMessagePt
    mov al,.Draw_RegenScene|.Draw_Message
    jmp .SetRedraw
.KeyToggleMainSprites:      ;5
    xor word [BgScene.VisiblePlanes],0010h
    jmp .InputLoop
.KeyToggleSubSprites:           ;%
    xor word [BgScene.VisiblePlanes],1000h
    jmp .InputLoop
.KeyResetPlanes:                ;6
    mov ax,[SnesState.MainScreen] ;get main screen and subscreen
    mov [BgScene.VisiblePlanes],ax
    mov esi,.MsgPlanesReset
    call .SetMessageCopy
    call .MakeMsgBgs
    mov al,.Draw_RegenScene|.Draw_Message
    jmp .SetRedraw
.KeyMergeToMainPlanes:          ;7
    mov ax,[SnesState.MainScreen] ;get main screen and subscreen
    or al,ah                    ;combine subscreen and main screens
    xor ah,ah                   ;turn off subscreens
    mov [BgScene.VisiblePlanes],ax
    mov esi,.MsgMainScreensOn
    call .SetMessageCopy
    call .MakeMsgBgs
    mov al,.Draw_RegenScene|.Draw_Message
    jmp .SetRedraw
.KeyResetCenter:                ;BackSpace
    mov dword [BgScene.ScrollY],((256-320)/2)<<16
    mov al,.Draw_RegenScene
    jmp .SetRedraw
.KeyInvertPalette:              ;8
    mov esi,.MsgPaletteNormal
    xor byte [BgScene.Options],BgScene.Options_InvertPalette
    test byte [BgScene.Options],BgScene.Options_InvertPalette
    jz .PaletteNotInverted
    mov esi,.MsgPaletteInverted
  .PaletteNotInverted:
    mov [.MsgPtr],esi
    call RestoreFullPalette.Now
    mov al,.Draw_Message
    jmp .SetRedraw
.KeyHelp:                       ;";"
    call PageSceneHelp
    mov al,.Draw_Scene
    jmp .SetRedraw
.KeyExport:                     ;0
    mov esi,ExportMenuStruct
    call MenuCreateAndWait
    jc .KeyExport_Cancel
    cmp al,ExportScene.TotalFunctions
    jae .KeyExport_Cancel

    movzx eax,al
    push eax
    call dword [ExportScene.FunctionTable+eax*4]
    pop eax
    mov esi,[ExportScene.MsgTable+eax*4]    ;assume no error
    jnc .KeyExport_SetMessage
    mov esi,ExportScene.MsgOpenFailed

 .KeyExport_SetMessage:
    mov [.MsgPtr],esi
    call RestoreFullPalette.Now
    mov al,.Draw_RegenScene|.Draw_Message
    jmp .SetRedraw
 .KeyExport_Cancel:
    mov al,.Draw_Scene
    jmp .SetRedraw
.KeyAlignBg:
    mov esi,AlignMenuStruct
    call MenuCreateAndWait
    jc .KeyAlignBg_Cancel
    movzx ebx,al
    imul ebx,SnesState.BgInfo_Size
    mov edx,[ebx+SnesState.Scroll]  ;get both scroll Y and X
    and edx,2047|(2047<<16)
    shld ecx,edx,16
    neg edx
    neg ecx
    mov dword [.MsgPtr],.MsgBgAligned
    mov [BgScene.ScrollY],dx
    mov [BgScene.ScrollX],cx
    mov al,.Draw_RegenScene|.Draw_Message
    jmp .SetRedraw
.KeyAlignBg_Cancel:
    mov al,.Draw_Scene
    jmp .SetRedraw

.Draw:
    test [Pages.Redraw],byte .Draw_RegenScene
    jz .DrawFromBuffer
    call RenderCompleteScene
.DrawFromBuffer:
    call Pointer.Hide
    call RenderCompleteScene.UpdateScreen

.PrintMessage:
    test [Pages.Redraw],byte .Draw_Message
    jz .NoMessage
    mov esi,[.MsgPtr]
    call GetStrLength
    mov dword [FontColorsPtr],FontColors1   ;set current font color set
    FontBlitStr esi,ax,190,2
.NoMessage:
    mov byte [Pages.Redraw],0
    call Pointer.Show
    ;call MouseGetInfo
    ;call CursorShow
    ret

.SetMessageCopy:
    mov edi,.MsgText
    mov dword [.MsgPtr],edi
    call GetStrLength
    mov ecx,eax
    ;cld!
    rep movsb
    ret

.MakeMessagePt: ;cx = bit (Pt=plane toggle)
    cld
    mov esi,.MsgText
    mov [.MsgPtr],esi
    mov edi,esi
    mov eax,'Sub '
    add edi,byte 3
    test cl,1000b
    jnz .MakeMsgPtNotMain
    mov eax,'Main'
    inc edi
.MakeMsgPtNotMain:
    mov [esi],eax
    mov dword [edi],' bg '
    mov ebx,ecx         ;copy
    and bl,3            ;get plane number
    add bl,49           ;make into an ASCII number
    mov [edi+4],bl
    bt [BgScene.VisiblePlanes],cx
    mov eax,' on '
    jc .MakeMsgPtOn
    mov eax,' off'
.MakeMsgPtOn:
    add edi,byte 5
    stosd
    mov ecx,.MsgText+20
    sub ecx,edi
    mov al,' '
    rep stosb
    ;call .MakeMsgBgs
    ;ret
    jmp short .MakeMsgBgs

.MakeMsgBgs:            ;edi must point to destination, df=0
    mov dx,[BgScene.VisiblePlanes]
    call .MakeMsgBgsRow ;pass edx, first the main screens
    mov al,' '
    stosb
    shr edx,8           ;then bring the subscreens down
    call .MakeMsgBgsRow
    xor al,al
    stosb
    ret
.MakeMsgBgsRow:         ;edx must have scene visibility mask
    xor ecx,ecx
  .MakeMsgBgsNext:
    bt edx,ecx
    mov al,'.'
    jnc .MakeMsgBgsOff
    mov al,cl
    add al,49           ;make into an ASCII number
  .MakeMsgBgsOff:
    stosb
    inc ecx
    cmp ecx,4
    jb .MakeMsgBgsNext
    ret

SECTION .data
.ScrollKeys:
    dd .ScrollKeysList
    db 4,8

.ScrollKeysList:
    db  '-' ;(pixel up)
    db  '/' ;(pixel left)
    db  '+' ;(pixel down)
    db  '*' ;(pixel right)
    db  'H' ;up key
    db  'K' ;left
    db  'P' ;down key
    db  'M' ;right
    db  'Q' ;page down
    db  'O' ;end
    db  'I' ;page up
    db  'G' ;home

align 2
.ScrollKeyValues:
    dw -1,1,-8,8,128,-128

.OtherKeys:
    dd .OtherKeysList
    db 16,1

.OtherKeysList:
    db '1234!@#$5%67890',8, ';'

align 4
.OtherKeysJumpTable:
    dd .KeyTogglePlane,.KeyTogglePlane,.KeyTogglePlane,.KeyTogglePlane
    dd .KeyTogglePlane,.KeyTogglePlane,.KeyTogglePlane,.KeyTogglePlane
    dd .KeyToggleMainSprites,.KeyToggleSubSprites,.KeyResetPlanes
    dd .KeyMergeToMainPlanes,.KeyInvertPalette,.KeyAlignBg,.KeyExport
    dd .KeyResetCenter,.KeyHelp

.MsgPtr:  dd .MsgText
.MsgText: db "$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$",0
.MsgPlanesReset:     db "Bgs reset to normal ",0
.MsgMainScreensOn:   db "Screens merged      ",0
.MsgPaletteInverted: db "Palette inverted",0
.MsgPaletteNormal:   db "Palette normal",0
.MsgBgAligned:       db "Aligned to bg top/left",0
SECTION .text

;------------------------------
; PageLoadFile ()
;
;PageLoadFile:
;allocates memory for savestate work
;returns if memory error
;loads parts of file
;checks that file is indeed a savestate, returns if not
;moves parts of savestate into their right variables
;returns success
;   ret

;------------------------------
; PageSceneInfo ()
;
PageSceneInfo:
    call Pointer.Hide
    call ClearBackground
    call GetSceneInfo.ResetToFirstItem
    push dword 4|(4<<16)            ;starting row and column
    jmp .FirstSceneInfoItem
  .NextSceneInfoItem:
    ;FontBlitStr esi,cx,[esp],4
    push dword [esp]                ;set row and column
    push cx                         ;set string length
    push esi                        ;set text ptr
    call _FontBlitStr
    add esp,byte 10
    add dword [esp],byte 8
  .FirstSceneInfoItem:
    call GetSceneInfo               ;esi=text ptr, ecx=length of text
    jnc .NextSceneInfoItem
    add esp,byte 4
    call Pointer.Show
    call UserWait                   ;wait long enough for user to see info
    ret

;------------------------------
; Returns string of info.
;
; () (esi=ptr to string, ecx=length, cf=end)
GetSceneInfo:
    jmp dword [.LastCall]
.FirstItem:
    mov dword [.ItemNamePtr],.TextItemNames
    mov byte [.OutputLineTab],15

    call .NextItemName
    mov esi,SavestateFilename
    call GetStrLength
    mov ecx,28
    cmp eax,ecx
    ja .FilenameTooLong
    mov ecx,eax
.FilenameTooLong:
    add byte [.OutputLinePos],cl
    rep movsb
    call .ReturnStringNext
    call .NextItemName
    call .ReturnStringNext

    call .NextItemName
    movzx eax,byte [SnesState.ProgramBank]
    call .NextValue_Hex
    mov byte [edi],':'              ;separate with a colon
    inc byte [.OutputLinePos]       ;advance current position in output line
    movzx eax,word [SnesState.ProgramCounter]
    call .NextValue_Hex
    call .ReturnStringNext

    call .NextItemName
    movzx eax,byte [SnesState.ScanLine]
    call .NextValue
    call .ReturnStringNext

    call .NextItemName
    movzx eax,byte [SnesState.VideoMode]
    call .NextValue
    test byte [SnesState.Bg3Priority],1
    jz .NoBg3Priority
    mov dword [edi],' bg3'
    mov byte [edi+4],0
    add byte [.OutputLinePos],4     ;advance current position in output line
.NoBg3Priority:
    call .ReturnStringNext

    call .NextItemName
    movzx eax,byte [SnesState.OAMSmallSize]
    call .NextValue
    mov byte [edi],','              ;separate with a comma
    inc byte [.OutputLinePos]       ;advance current position in output line
    movzx eax,byte [SnesState.OAMLargeSize]
    call .NextValue
    call .ReturnStringNext

    call .NextItemName
    mov eax,[SnesState.OAMTileBase]
    call .NextValue_Default
    call .ReturnStringNext

    call .NextItemName
    mov al,[SnesState.MainScreen]
    call .NextValue_Binary
    call .ReturnStringNext

    call .NextItemName
    mov al,[SnesState.SubScreen]
    call .NextValue_Binary
    call .ReturnStringNext

    call .NextItemName
    mov al,byte [SnesState.AddScreen]
    call .NextValue_Binary
    mov al,byte [SnesState.AddScreen]
    test al,01000000b               ;test bit 6
    jz .NormalAddSub
    mov esi,.TextHalf               ;state half add/sub if bit set
    call .CopyString
  .NormalAddSub:
    mov esi,.TextAdd
    test al,10000000b               ;test bit 7
    jz .AddMode
    mov esi,.TextSub
  .AddMode:
    call .CopyString
    call .ReturnStringNext

    call .NextItemName
    movzx eax,byte [SnesState.FixedColor]
    call .NextValue_Default
    mov byte [edi],' '              ;separate numbers
    inc byte [.OutputLinePos]       ;advance current position in output line
    movzx eax,byte [SnesState.FixedColor+1]
    call .NextValue_Default
    mov byte [edi],' '              ;separate numbers
    inc byte [.OutputLinePos]       ;advance current position in output line
    movzx eax,byte [SnesState.FixedColor+2]
    call .NextValue_Default
%if 0
    int3;
    test byte [SnesState.AddScreen],00100000b   ;test bit 5
    jz .NoBackgroundAddSub
    mov esi,.TextBgAddSub
    call .CopyString
  .NoBackgroundAddSub:
%endif
    call .ReturnStringNext

    call .NextItemName              ;separator
    mov dword [.BgItem],6           ;set first bg item to output for following loop
    call .ReturnStringNext
  .NextBgItem:
    sub esp,8                       ;variable space
    mov dword [esp],0               ;start with first bg (zero based)
    mov dword [esp+4],SnesState.BgInfo
    mov byte [.OutputLineTab],15
    call .NextItemName
  .NextBg:
    mov ebx,[.BgItem]
    mov esi,[esp+4]
    jmp [.BgItemJumpTable+ebx*4]

  .BgBitdepth:
    movzx eax,byte [esi+Bg.BitDepth]
    jmp short .PrintBgInfo
  .BgMapBase:
    movzx eax,word [esi+Bg.MapBase]
    jmp short .PrintBgInfo
  .BgMapSize:
    movzx eax,byte [esi+Bg.MapWidth]
    movzx ebx,byte [esi+Bg.MapHeight]
    call .NextDimValue
    jmp short .AfterPrintBgInfo
  .BgTileSize:
    movzx eax,byte [esi+Bg.TileHeight]
    movzx ebx,byte [esi+Bg.TileWidth]
    call .NextDimValue
    jmp short .AfterPrintBgInfo
  .BgScrollX:
    movzx eax,word [esi+Bg.ScrollX]
    jmp short .PrintBgInfo
  .BgScrollY:
    movzx eax,word [esi+Bg.ScrollY]
    jmp short .PrintBgInfo
  .BgTileBase:
    movzx eax,word [esi+Bg.TileBase]
  .PrintBgInfo:
    call .NextValue_Default ;print the value of eax
  .AfterPrintBgInfo:
    add dword [esp+4],SnesState.BgInfo_Size ;next bg ptr
    inc dword [esp]                 ;next bg number
    add byte [.OutputLineTab],6
    cmp dword [esp],4               ;check that we have not gone beyond
    jb near .NextBg                 ;do while bg is 0-3
    add esp,byte 8

    dec dword [.BgItem]             ;one less bg info item
    js .NoMoreBgItems
    jmp .ReturnString
.NoMoreBgItems:
    call .ReturnStringNext

.End:
    xor ecx,ecx                     ;null length string
    stc                             ;flag no more info items remain
    ret

.ResetToFirstItem:
    mov dword [.LastCall],GetSceneInfo.FirstItem
    ret

.ReturnStringNext:
    pop dword [.LastCall]
.ReturnString:
    movzx ecx,byte [.OutputLinePos] ;get length of message
    mov esi,.OutputLine
    mov dword [esi+ecx],240D0Ah     ;put terminator with line end (silly dollar sign)
    clc
    ret

.NextItemName:
    ;clear buffer with new item name
    mov esi,[.ItemNamePtr]          ;get ptr of current item name
    movzx ecx,byte [esi]            ;get length of description
    mov edi,.OutputLine             ;set position in output line to beginning
    inc esi                         ;move source to title name
    mov [.OutputLinePos],cl         ;save current position in output line
    cld
    rep movsb
    mov [.ItemNamePtr],esi          ;store ptr for next call
    ret

.NextValue_Binary:
    call .PadWithSpace
    mov ecx,5|('0'<<8)              ;set counter and ASCII character 0
    mov ebx,eax
    add byte [.OutputLinePos],cl
.NextValue_BinaryDigit:
    inc ch
    mov al,ch
    shr ebx,1
    jc .NextValue_BinaryOn
    mov al,"."
.NextValue_BinaryOn:
    stosb
    dec cl
    jnz .NextValue_BinaryDigit
    ret

.NextValue_Hex:
    mov ebx,16              ;base sixteen
    jmp short .NextValue_AnyRadix
.NextValue_Default:
    mov ebx,[InfoDefaultRadix]
    jmp short .NextValue_AnyRadix
;(eax=Number, edi)
.NextValue:
    mov ebx,10              ;base ten
;(eax=Number, ebx=Radix, edi)
.NextValue_AnyRadix:
    ;fill in with padded nulls up to current tab index
    call .PadWithSpace

    push edi
    mov edi,.InfoValue          ;set destination
    mov cl,5
    call NumToString.OfRadix
    lea esi,[.InfoValue+ecx]    ;set source
    pop edi
    neg ecx                     ;get negation of offset of first digit
    ;lea edi,[.OutputLine+edx]
    add ecx,byte 5              ;get 5 - offset to get length of string
    add [.OutputLinePos],cl     ;add number of digits to number
    cld
    rep movsb                   ;copy number to output line
    ret

;(eax=First number, ebx=Second number)
.NextDimValue:
    push ebx                    ;saved second value
    call .NextValue
    pop eax                     ;retrieve second value
    movsb                       ;transfer x
    inc byte [.OutputLinePos]   ;advance current position in output line
    call .NextValue
    ret 

;(edi) - Saves eax and ebx
.PadWithSpace:
    movzx ecx,byte [.OutputLinePos]
    push eax                    ;save any number value in register
    ;mov edx,ecx                ;copy space counter to cur pos
    lea edi,[.OutputLine+ecx]   ;get position in output line
    sub cl,[.OutputLineTab]     ;get pos - tab
    jae .TabInvalid             ;pos >= tab
    neg cl                      ;make counter positive
    mov al,' '                  ;set space character
    ;add edx,ecx                ;add tab to pos
    add [.OutputLinePos],cl     ;save new pos
    cld
    rep stosb                   ;output spaces
.TabInvalid:
    pop eax                     ;retrieve number
    ret

;(esi=String to copy, edi) - Saves eax and ebx
.CopyString:
    movzx ecx,byte [esi]        ;get length of string
    inc esi
    add byte [.OutputLinePos],cl
    cld
    rep movsb
    ret

SECTION .data
align 4
.BgItemJumpTable:
    dd .BgScrollY,.BgScrollX,.BgTileSize,.BgMapSize,.BgTileBase,.BgMapBase,.BgBitdepth
.ItemNamePtr:       dd .TextItemNames
.LastCall:          dd GetSceneInfo.FirstItem   ;last part of routine called
.BgItem:            dd 0                    ;counter for current bg
.OutputLinePos:     db 0
.OutputLineTab:     db 20
.InfoValue:         db '.....x'
.TextItemNames:
    LenStr "Filename: "
    LenStr ""
    LenStr "Program pos"
    LenStr "Scan line"
    LenStr "Video mode"
    LenStr "Sprite sizes"
    LenStr "Sprite base"
    LenStr "Mainscreens"
    LenStr "Subscreens"
    LenStr "Transparent"
    ;LenStr "Add/Sub mode"
    LenStr "Back color"
    LenStr ""
    LenStr "Bitdepth"
    LenStr "Map data base"
    LenStr "Tile graphics"
    LenStr "Map Size"
    LenStr "Tile size"
    LenStr "Scroll X"
    LenStr "Scroll Y"
.TextHalf:  LenStr " half"
.TextAdd:   LenStr " addition"
.TextSub:   LenStr " subtraction"
.TextBgAddSub: LenStr " translucent"
SECTION .bss
.OutputLine:        resb 80
SECTION .text

;------------------------------
; Eventually this could be used to randomly select a background from a image file
; and load both its image and corresponding palette
;
PageSceneHelp:
    call PaletteDim
    call PaletteSetGuiColors
    call PaletteSet
    FontBlitPar Messages.KeyHelp,(200-(15*9))/2,8
    call UserWait           ;wait long enough for user to see info
    ;call RestoreFullPalette.Set
    ;ret
    jmp RestoreFullPalette.Set

;------------------------------------------------------------
; SaveStateLoad () (cf=error, al=error code if cf)
;
SaveStateLoad:
    mov ax,3D00h                ;DOS: open file, access mode=0
    mov edx,SavestateFilename   ;what else, the filename
    int 21h
    jc .ErrorOpen               ;in case of file error, usually bad filename
    push eax                    ;save and pass handle
    call SavestateParse         ;read in the parts of a savestate
    pop ebx                     ;get saved file handle
    push eax                    ;save status message
    pushfd                      ;save carry as error indicator
    mov ah,3Eh                  ;DOS: close file
    int 21h
    popfd                       ;get carry as error indicator again
    pop eax
    jc .End                     ;file is not readable or memory error
    mov [SavestateStatus],al    ;set to return value of SaveStateParse
    clc
.End:
    ret

.ErrorOpen:
    mov al,SavestateOpenErr
    ret

;------------------------------
ClearBackground:
    mov edi,0A0000h
    mov eax,ColorLrDark<<24|ColorLrBlack<<16|ColorLrDark<<8|ColorLrBlack
    mov edx,200
.NextRow:
    mov ecx,320/4
    rep stosd
    rol eax,8
    dec edx
    jnz .NextRow
    ret

;------------------------------
RestoreFullPalette:
    ;cmp byte [.PaletteRestored],0
    ;jnz .End
.Now:                       ;public
    call CgramPaletteConvert    ;fill in palette with SNES colors
    mov eax,[ScreenPalette]     ;get color 0
    mov edi,ScreenPalette+(ColorLrBg*3)
    call SetColorBackground.GivenColor
    call PaletteSetGuiColors
    call PaletteSet         ;refresh changes to screen
    mov byte [.PaletteRestored],-1  ;mark palette as set
.End:
    ret
.Set:
    push dword PaletteSet           ;refresh changes to screen after filling palette
    jmp short .Now
.FlagOff:               ;public
    mov byte [.PaletteRestored],0   ;mark palette as needing to be set
    ret

SECTION .data
.PaletteRestored:   db 0
SECTION .text

;------------------------------
;use an array of 100 bits
;check all files in directory
;open returned file
;save dimensions and header
;convert cgram to palette
;add in rgb color constant
;save palette
;set palette flagoff
;render scene
;write scene pixels to bitmap starting from bottom row
ExportScene:
.TotalFunctions equ 6
.ImageNormal:
    mov eax,200             ;set image height
    mov ebx,320             ;set image width
    jmp short .Image
.ImageLarge:
    mov eax,512             ;set image height
    mov ebx,512             ;set image width
    jmp short .Image
.ImageHuge:
    mov eax,1024            ;set image height
    mov ebx,1024            ;set image width
    ;jmp short .Image

.Image:
    ;rows per section = image buffer size / width
    ;save Y scroll, height, and width
    ;Y scroll += height - rows per section
    ;set scene height and width
    ;  render scene
    ;  subtract rows per section from rows remaining
    ;  if rows remaining >= 0
    ;    write rows per section
    ;  else
    ;    write rows remaining
    ;  move Y scroll down by rows per section
    ;  loop while rows remaining > 0
    ;restore scene height and width
    ;restore Y scroll

    push dword [BgScene.Height] ;save old scene dimensions
    push dword [BgScene.Width]
    push dword [BgScene.Scroll] ;save X/Y scroll
    push eax                    ;save height
    push ebx                    ;save width
    mov esi,.BitmapOutputFile
    call .OpenFile              ;if successful, returns handle on stack
    jnc .ImageFileOpened
    add esp,byte 20
    stc
    ret
.ImageFileOpened:
    mov eax,BgScene.ImageBufferSize
    mov ebx,[esp+4]             ;get width
    xor edx,edx
    div ebx                     ;divide buffer size by width to get height
    cmp eax,[esp+8]             ;check if calculated height is greater than entire height
    jbe .HeightOk
    mov eax,[esp+8]             ;get maximum height
.HeightOk:
    mov [BgScene.Width],ebx
    mov [BgScene.Height],eax
    mov eax,[esp+8]             ;get entire scene height
    call WriteImage.BmpHeader   ;eax=height ebx=width
    mov byte [BgScene.BackgroundColor],0
    call .GetPalette
    call WriteImage.BmpPalette

.MorePages:
    call RenderCompleteScene
    mov esi,BgScene.ImageBuffer ;or BlitTileImage.BufferDest
    mov ecx,[BgScene.Height]    ;number of rows to blit
    add [BgScene.ScrollY],cx    ;move a page down
    sub [esp+8],ecx             ;one less page to draw
    jae .NotLastPage
    add ecx,[esp+8]             ;final page
.NotLastPage:
    call WriteImage.BmpRows
    cmp dword [esp+8],0         ;was last page just drawn?
    jg .MorePages

    pop ebx
    add esp,byte 8              ;release dimension sizes of image
    pop dword [BgScene.Scroll]  ;restore X/Y scroll
    pop dword [BgScene.Width]   ;restore old scene dimensions
    pop dword [BgScene.Height]
    mov byte [BgScene.BackgroundColor],ColorLrBg ;to not clash with GUI colors
    jmp .CloseFileGivenHandle

.End:
    ret

.Palette:
    mov esi,.PaletteOutputFile
    call .OpenFile      ;if successful, returns handle on stack
    jc .End
    call .GetPalette
    call WriteImage.RgbPalette
    jmp .CloseFile      ;retrieve file handle on stack and close

.RawPalette:
    mov esi,.PaletteOutputFile
    call .OpenFile      ;if successful, returns handle on stack
    jc .End
    mov edx,SnesState.CGRAM
    mov ecx,512         ;256 RGB words
    call WriteImage.AnyPalette
    jmp .CloseFile      ;retrieve file handle on stack and close

.Graphics:
    mov esi,.GraphicsOutputFile
    call .OpenFile      ;if successful, returns handle on stack
    jc .End
    call .GetPalette
    push dword [VramTileFill.SourceTile]    ;save for VRAM viewing window
    call VramTilesTotal
    add eax,byte 15
    shr eax,4               ;/16 round up to nearest row
    push eax                ;set counter
    shl eax,3               ;*8 set image height
    mov ebx,128             ;set image width
    push dword [esp+8]      ;pass file handle
    call WriteImage.BmpHeader
    call WriteImage.BmpPalette
    mov dword [VramTileFill.SourceTile],0   ;start at first tile
    mov dword [VramTileFill.Dimensions],16 | (16<<16)
    jmp short .FirstVramPage

  .NextVramPage:
    call VramTileFill           ;convert SNES bitplane tiles into linear bitmap
    mov esi,BgScene.ImageBuffer ;source of pixel data
    mov ecx,128                 ;number of pixel rows to write
    call WriteImage.BmpRows
    mov esi,[VramTileFill.SourceTile]
    mov ecx,16*16
    call SeekVramTilesForward
    mov [VramTileFill.SourceTile],esi       ;jump to next page
  .FirstVramPage:
    sub dword [esp+4],byte 16
    ja .NextVramPage
    call VramTileFill               ;convert SNES bitplane tiles into linear bitmap
    mov ecx,[esp+4]                 ;get tile rows remaining
    mov esi,BgScene.ImageBuffer     ;source of pixel data
    add ecx,16
    shl ecx,3                       ;*8 number of pixel rows to write
    call WriteImage.BmpRows

    add esp,byte 8          ;get rid of counter and file handle
    pop dword [VramTileFill.SourceTile]
    ;jmp .CloseFile      ;retrieve file handle on stack and close

.CloseFile:                     ;retrieve file handle on stack and close
    pull ebx                    ;grab file handle
.CloseFileGivenHandle:
    mov ah,3Eh                  ;DOS: close file
    int 21h
    ;clc
    ret

.OpenFile:                      ;open file at edx and get palette
    ;allocate table for 1000 entries
    mov dword [esi+5],'???.'
    sub esp,128                 ;1000 / 8 = 125
    ;fill table with all ones, meaning available.
    mov eax,-1
    mov edi,esp
    mov ecx,31                  ;1000 / 32 = 31.25
    cld
    rep stosd
    mov dword [edi],~255        ;last 8 bits in table, reserve following 24

    push esi
    mov ah,1Ah                  ;set data transfer for find first
    mov edx,DiskTransfer
    int 21h
    ;find first file matching wildcard
    mov ah,4Eh                  ;find first file
    mov ecx,1|2|4|16|32         ;read-only/hidden/system/directory/archive
    mov edx,esi
    int 21h
    jc .NoMoreFiles

.GetFileNumber:
    mov esi,DiskTransfer+1Eh+5
    xor eax,eax
    xor ebx,ebx
    mov ecx,3
.GetNextDigit:
    mov bl,byte [esi]           ;get next digit
    lea eax,[eax*4+eax]
    sub bl,'0'
    jb .NextFileName
    cmp bl,9
    ja .NextFileName
    inc esi
    lea eax,[eax*2+ebx]
    loop .GetNextDigit
    btc dword [esp+4],eax
.NextFileName:
    mov ah,4Fh                  ;find next file
    int 21h
    jnc .GetFileNumber
.NoMoreFiles:

    xor esi,esi
    mov ecx,32
.NextFileNumber:
    mov edx,[esp+4+esi]
    bsf eax,edx
    jnz .FileNumberFound
    add esi,byte 4
    loop .NextFileNumber
    mov eax,999
    jmp short .SetFileNumber
.FileNumberFound:
    lea eax,[esi*8+eax]
.SetFileNumber:

    mov ebx,'.000'
    mov ecx,3
    mov esi,10
.SetNextDigit:
    xor edx,edx
    idiv esi
    rol ebx,8
    add bl,dl
    loop .SetNextDigit
    pop edx
    mov [edx+5],ebx
    add esp,128

    ;open file for output
    xor ecx,ecx             ;no attributes
    mov ah,3Ch              ;DOS: create file
    int 21h
    jc .OpenFileReturn
    xchg eax,[esp]          ;swap return with file handle
    jmp eax                 ;return to caller
.OpenFileReturn:
    ret

.GetPalette:
    call CgramPaletteConvert    ;fill in palette with SNES colors
    mov edi,ScreenPalette
    jmp SetColorBackground

SECTION .data
align 4
.FunctionTable:         dd .ImageNormal,.ImageLarge,.ImageHuge
                        dd .Graphics,.Palette,.RawPalette
.MsgTable:              dd .MsgSceneExported,.MsgLrgSceneExported,.MsgHugeSceneExported
                        dd .MsgVramExported,.MsgPaletteExported,.MsgCgramExported
.MsgSceneExported:      db "Scene snapshot saved (320x200)",0
.MsgLrgSceneExported:   db "Large snapshot saved (512x512)",0
.MsgHugeSceneExported:  db "Huge snapshot saved  (1024x1024)",0
.MsgVramExported:       db "VRAM graphics saved",0 
.MsgPaletteExported:    db "Scene palette saved",0 
.MsgCgramExported:      db "CGRAM palette saved",0
.MsgOpenFailed:         db "Error exporting to file!?"
.BitmapOutputFile:      db 'bgimg000.bmp',0
.PaletteOutputFile:     db 'bgimg000.pal',0
.GraphicsOutputFile:    db 'bgvrm000.bmp',0
SECTION .text

;------------------------------
;
; PageViewTilemaps ()
;
%if 0 ; todo...
PageViewTilemaps:
    call Pointer.Hide
    mov al,ColorLrGray
    call DrawClearScreen
;   DrawBorder 3,4+(8*23),3,4+(8*16),1
    mov al,[.PaletteBase]
    shl al,cl
    jmp .RemakePaletteBase

.InputLoop:
    call KeyGetPress.Single
    jc .CheckKeys
    cmp byte [Pages.Redraw],0
    jz .InputLoop
    jmp .RedrawTileWindow

.CheckKeys:
    movzx ebx,word [.TileBase]

    cmp ax,'H'<<8               ;up key?
    je .0
    cmp ax,'P'<<8               ;down key?
    je .1
    cmp ax,'I'<<8               ;page up?
    je .2
    cmp ax,'Q'<<8               ;page down?
    je .3
    cmp ax,'K'<<8               ;left?
    je .4
    cmp ax,'M'<<8               ;right?
    je .5
    cmp al,' '
    je .6
    cmp al,27                   ;escape?
    jne .InputLoop
.End:
    call Pointer.Show
    ret

.0: sub ebx,32*2
    jmp short .ScrollChange
.1: add ebx,32*2
    jmp short .ScrollChange
.2: sub ebx,32*32
    jmp short .ScrollChange
.3: add ebx,32*32
    jmp short .ScrollChange
.4: mov bl,-1
    jmp short .PaletteChange
.5: mov bl,1
    jmp short .PaletteChange
.6: inc byte [.CurPlane]
    mov cl,byte [.CurPlane]
    and ecx,3
    imul ebx,ecx,SnesState.BgInfo_Size
    test byte [SnesState.BitDepth+ebx],15
    jnz .PlaneIsActive
    xor ecx,ecx
    xor ebx,ebx
  .PlaneIsActive:
    mov [.CurPlane],cl
    mov ax,[ebx+SnesState.MapBase]
    mov word [.TileBase],ax
    mov cl,[SnesState.BitDepth+ebx]
    mov al,[.PaletteBase]
    shr al,cl
    mov [.PaletteIncr],cl
    shl al,cl
    jmp short .RemakePaletteBase

.ScrollChange:
    mov [.TileBase],bx
    mov byte [Pages.Redraw],-1
    jmp .InputLoop

.PaletteChange:
    mov cl,[.PaletteIncr]
    mov al,[.PaletteBase]
    shl bl,cl
    add al,bl
.RemakePaletteBase:
    mov [.PaletteBase],al
    mov ah,al
    mov ecx,eax
    shl eax,16
    mov ax,cx
    mov [TileRoutines.Palette],eax
    mov byte [Pages.Redraw],-1
    jmp .InputLoop

.RedrawTileWindow:
    mov bx,[.TileBase]
    mov [BgScene.TileBase],bx
    push word [.CurPlane]

    call _RenderBgDumb
    add esp,byte 2
    mov byte [Pages.Redraw],0
    jmp .InputLoop

alignb 4
.TileBase:      dw 0
.CurPlane:      dw 0
.PaletteBase:   db 0
.PaletteIncr:   db 4

%endif

;============================================================
; HELPER ROUTINES (INCLUDES)
;============================================================
%include "bgmfuncs.asm" ;most of my helper routines
%include "bgtile.asm"   ;routines for tile translation and related
;%include "routs.inc"   ;gaz's protected mode routines
%include "memory.inc"
%include "system.inc"

;============================================================
; DATA CONSTANTS AND VARIABLES
;============================================================
SECTION .data

;------------------------------
; Main variables
;------------------------------
    align 4
SnesMemoryPtrs:                         ;points to each piece of memory and tells the size
    dd SnesState.VRAM,  65536   ;64k of video ram
    dd SnesState.ERAM,  65536   ;64k of external ram
    dd SnesState.WRAM,  131072  ;128k of work ram
    dd SnesState.OAM,   544     ;128 sprites
    dd SnesState.CGRAM, 512     ;256 colors plus background color

    MainOptions:        dd 0    ;up to 32 flags for various options
    StartOptions:       dd 0    ;up to 8 flags to hold command line options
    .FileGiven          equ 1   ;file was specified
    .ZstInfoOnly        equ 2
    .VideoModeGiven     equ 4
    ;.UseLongFilenames  equ 64
    .StatusDisplay      equ 128
    .ZstVideoModeGiven  equ 256

    InfoDefaultRadix:   dd 16   ;radix that information is shown in (dec/hex)
    SavestateStatus:    db 0    ;flags whether a savestate is loaded
    ZstVideoMode:       db 0

;------------------------------
; Data used by the scene viewer
;------------------------------
    align 4
PlaneTypeTable:
    db 1,1,1,1, 2,2,1,0, 2,2,0,0, 3,2,0,0, 3,1,0,0, 2,1,0,0, 2,0,0,0, 3,0,0,0
PlaneInfoTable:             ;bit shift, bits, color mask
    db 0,0,0,0,  2,1,3,0,  4,2,15,0,  8,3,255,0
PlaneVramFormatTable:
        db 0,0,0,0, 1,1,0,0, 1,1,0,0, 2,1,0,0, 2,0,0,0, 1,0,0,0, 1,0,0,0, 1,1,0,0
PlaneMasks:                 ;bits mask for active planes
    db 1111b,0111b,0011b,0011b,0011b,0011b,0001b,0001b
SpriteSizes:                ;sprites size pairs
    db 8,16,8,32,8,64,16,32,16,64,32,64,32,64,32,64

;------------------------------
; GUI color info
;------------------------------
;the four basic GUI colors, black, white, gray, and sky blue
align 4
    GuiColorsNum equ 5      ;the GUI colors use four out of 256
    ColorLrBlack    equ 0   ;color definitions for 256 color mode
    ColorLrDark     equ 16
    ColorLrGray     equ 32
    ColorLrLight    equ 48
    ColorLrWhite    equ 64
    ColorLrBg       equ 80  ;used in scene for background color constant
    ColorLrBack     equ ColorLrGray
    ColorLrFront    equ ColorLrGray
    ColorLrTop      equ ColorLrLight
    ColorLrBottom   equ ColorLrBlack

GuiColorsData:
    db 0,0,0, 18,18,24, 28,28,40, 48,48,63, 63,63,63

;------------------------------
; Fonts - my two little character sets
;------------------------------
FontOutline equ $-(32*16)
    incbin "font1.fnt"
    ;incbin "font2.fnt" // For a font with shadow behind it instead.

;I've always wondered where all these people get the fonts for their graphics programs.
;The first one, which some may recognize, was taken from DKC1 (using another little SNES
;prog I wrote) and edited a little to look better, while the second one was taken from
;the pc's BIOS rom at FA6E0h. There were quite a few other good choices of game fonts,
;but it had to be a complete character set - not just all uppercase like many games.

FontStylePtr:   dd FontOutline  ;the current font table being used
FontColorsPtr:  dd FontColors1  ;the current font colormap
FontColors0:    dw 0,64,0,32
FontColors1:    dw 0,48,0,32
FontColors2:    dw 0,32,0,9
FontColors3:    dw 0,16,0,0

CursorImages:
    incbin "cursors.lbm",0,768
CursorColorTable:
    db ColorLrBlack,ColorLrDark,ColorLrGray,ColorLrLight,ColorLrWhite,

;------------------------------
; Basic screen mode info
;------------------------------
ScreenModesNum equ 1        ;currently there is only mode 13h
ScreenModesInfo:
    dw 200,320,8        ;mode 13h 320x200:256
;   dw 240,320,8        ;all others are vesa modes
;   dw 480,640,8
;   dw 240,320,15
;   dw 480,640,15

ScreenPalettePtr:
    dd ScreenPalette

;------------------------------
MenuColors:
    dw 0,ColorLrLight,ColorLrBlack,0  ;inactive choice
    dw 0,ColorLrWhite,ColorLrLight,0  ;active choice
    dw 0,ColorLrDark, ColorLrBlack,0  ;inactive disabled
    dw 0,ColorLrWhite,ColorLrBlack,0  ;active disabled

;------------------------------
; Various strings used throughout the program
;------------------------------
StartOptionMessages:
  .AuthorInfo:
    db 'Built with the NASM compiler and WDOSX extender.',13,10
    db 'Written by Dwayne Robinson, to map out the classics.',13,10
    db 10
    db '  FDwR@hotmail.com',13,10
    db '  http://pikensoft.com/',0
    db '  http://fdwr.tripod.com/snes.htm',0
    db '  https://github.com/fdwr/BgMapper',0
  .HelpText:
    db 'BgMapper ',ProgVersion,' - Savestate Viewer, (uncopyright)1998..2021 PikenSoft',13,10
    db 'Supports the ZSNES emulator savestates (zst & zmv)',13,10
    db 10
    db 'Usage:',13,10
    db '  bgmapper [-options] savestate',13,10
    db 10
    db 'Startup options:',13,10
    db '  -info  only show technical info on savestate',13,10
    db '  -sd    startup status display',13,10
    db '  -fv    force SNES video mode',0
    db '  -?     version/author information',0
    .InvalidParameter:  db 'Unknown parameter',0
    .InvalidScrnMode:   db 'Only mode 0 (320x200:256) is supported for now',0
    .InvalidZstVideo:   db 'Select an SNES video mode 0-7',0

Messages:
    .NewLine:           db 13,10,'$'
    .PressAnyKey:       db 13,10,'Press a key or button to continue.',0
    .HeapInitializing:  db 'Allocating memory for savestate and scene.',0
    .HeapInitErr:       db 'Could not allocate memory for main environment.',0
    .MouseExists:       db 'Mouse detected with '
    .MouseButtons:      db '  buttons',0
    .NoMouse:           db 'No mouse was detected.',0
    .NoFileGiven:       db 'No file given to view.',0
    .ErrorLoadingFile:  db 'Could not load the viewing file.',0
    .FileWasLoaded:     db 'File loaded successfully.',0
  .KeyHelp:
    db 133,'            =',132,'=',131,'=',130,' Keys ',131,'=',132,'=',133,'=',129
    db 129
    db 130,"Up Down Left Right   ",131,"Eight pixels",129
    db 130,"PgUp PgDn Home End   ",131,"Half a screen",129
    db 130,"- + / *              ",131,"Single pixel",129
    db 130,"Backspace            ",131,"Recenter scene",129
    db 129
    db 130,"1",131,"-",130,"4          ",131,"Toggle on/off mainscreens",129
    db 130,"Shift",131,"+(",130,"1",131,"-",130,"4",131,")  Toggle on/off subscreens",129
    db 130,"6            ",131,"Restore bgs to normal",129
    db 130,"7            ",131,"Merge all layers",129
    db 130,"8            ",131,"Invert palette",129
    db 130,"9            ",131,"Bg alignment",129
    db 130,"0            ",131,"Export menu",129
    db 130,"Esc          ",131,"Return to the menu"
    db 129,129,129
    db "(uncopyright)1998..2021 ",132,"(:",131,"Piken",132,":)",0

align 4
MainMenuStruct:
    dd MainMenuList
    dw 5,MainPageSceneViewer    ;total choices and initial choice
    dw 2,2                      ;top row and left column
MainMenuList:
;   MenuChoice .0,MainPageLoadScene,MenuListDisabled
    MenuChoice .1,MainPageReloadScene,MenuListDivider
    MenuChoice .2,MainPageSceneInfo,0
;   MenuChoice .5,MainPageTilemapViewer,0
    MenuChoice .3,MainPageSceneViewer,0
    MenuChoice .4,MainPageVramViewer,MenuListDivider
;   MenuChoice .6,MainPageSpriteList,MenuListDivider
;   MenuChoice .9,MainPage.Help,MenuListDivider
;   MenuChoice .7,MainPageOptions,MenuListDisabled
    MenuChoice .8,MainProgExit,0
;   .0: db "Load state',0
    .1: db "Reload",0
    .2: db "Info",0
    .3: db "Scene",0
    .4: db "Graphics",0
;   .5: db "Tilemap",0
;   .6: db 'Sprites',0
;   .7: db 'Options',0
    .8: db 'Exit',0
;   .9: db 'Help',0

align 4
ExportMenuStruct:
    dd ExportMenuList
    dw 6,0                      ;total choices and initial choice
    dd MenuCenterEquate         ;top row and left column are centered
ExportMenuList:
    MenuChoice .0,0,0
    MenuChoice .1,1,0
    MenuChoice .2,2,0
    MenuChoice .3,3,0
    MenuChoice .4,4,0
    MenuChoice .5,5,0
    .0: db "0 Scene snapshot",0
    .1: db "1 Large snapshot",0
    .2: db "2 Huge snapshot",0
    .3: db "3 VRAM graphics",0
    .4: db "4 RGB palette",0
    .5: db "5 Raw palette",0

align 4
AlignMenuStruct:
    dd AlignMenuList
    dw 4,0                      ;total choices and initial choice
    dd MenuCenterEquate         ;top row and left column are centered
AlignMenuList:
    MenuChoice .0,0,0
    MenuChoice .1,1,0
    MenuChoice .2,2,0
    MenuChoice .3,3,0
    .0: db "1rst Bg",0
    .1: db "2nd  Bg",0
    .2: db "3rd  Bg",0
    .3: db "4rth Bg",0

align 4
GfxExportMenuStruct:
    dd GfxExportMenuList
    dw 3,0                      ;total choices and initial choice
    dd MenuCenterEquate         ;top row and left column are centered
GfxExportMenuList:
    MenuChoice .0,3,0
    MenuChoice .1,4,0
    MenuChoice .2,5,0
    .0: db "0 VRAM graphics",0
    .1: db "1 RGB palette",0
    .2: db "2 Raw palette",0

;------------------------------
; VARIABLE SPACE SECTION (initialized upon startup)
;------------------------------
SECTION .bss
alignb 4
;hold info about command line parameters
    StartOptCount:      resd 1  ;number of parameters
    StartOptPtrs:       resd 1  ;array of pointers to each one
    StartOptEnv:        resd 1  ;command environment strings
    StartOptSelector:   resd 1  ;command environment selector
    DiskTransfer:       resb 128;for find first/next

    SavestateFilename:  resb 256;full path and filename of savestate last loaded

;video mode info
    alignb 4
    ScreenPtr:  resd 1  ;pointer to video memory (not used yet)
    ScreenHeight:   resw 1  ;200/240/480
    ScreenWidth:    resw 1  ;320/640
    ScreenBits: resb 1  ;8/15
    ScreenPixByte:  resb 1  ;0=byte per pixel  1=two bytes per pixel
    ScreenMode: resb 1  ;VESA mode used
    ScreenListMode: resb 1  ;mode used from list (0-4)
    ScreenPalette: resb 768 ;256 color palette

;used by the graphics routines
    alignb 4
    ScreenBuffer:   resd 1  ;where to output screen writes, can be either directly to
                ;visible screen or to a temporary buffer
    ScreenClipTop:  resw 1  ;0
    ScreenClipBtm:  resw 1  ;ScreenHeight-1
    ScreenClipLeft: resw 1  ;0
    ScreenClipRite: resw 1  ;ScreenWidth-1

;the current GUI colors, they may change according to whether in 256 or 32768 color mode
GuiColorsCurrent:
    GuiColorBlack:  resw 1
    GuiColorDark:   resw 1
    GuiColorGray:   resw 1
    GuiColorLight:  resw 1
    GuiColorWhite:  resw 1

    GuiColorBack:   resw 1
    GuiColorFront:  resw 1
    GuiColorTop:    resw 1
    GuiColorBottom: resw 1

;------------------------------
;<the complete SNES state>
;Originally I had this dynamically allocated, but it had to reference a
;pointer everytime, and since there was only going to be one SNES state
;of a constant size loaded at a time (although not every game has ERAM used
;"StarFox" and "Yoshi's Island"). Plus this way, the program will not start
;if you do not have enough memory to begin with.
alignb 4
SnesState:
    .VRAM:      resb 65536
    .ERAM:      resb 65536
    .WRAM:      resb 131072
    .OAM:       resb 544
    .CGRAM:     resb 512
    .CycleCount:    resw 1
    .ScanLine:  resw 1  ;0-261 the last vivisible line is 223
    .ProgramCounter:    resw 1
    .ProgramBank:   resb 1
    .VideoMode: resb 1  ;0-7
    .Bg3Priority:   resb 1  ;if bg3 has the highest priority in vmode 1
    .Brightness:    resb 1  ;0-15, 15 is full normal brightness
    .MainScreen:    resb 1  ;bits 0-3 for planes, bit 4 for sprites
    .SubScreen: resb 1  ;bits 0-3 for planes, bit 4 for sprites
    .AddScreen: resb 1  ;bits 0-3 for planes, bit 4 for sprites
    ;               bit 5 for background, bit 6=normal/half, bit 7=add/sub
    .MosaicApplied: resb 1  ;same again (except not applied to sprites)
    .MosaicSize:    resb 1  ;0-15 in pixels
    .FixedColor:    resb 4  ;background color constant
    .Window1Left:   resb 1  ;0-255 in pixels for both windows
    .Window1Right:  resb 1
    .Window2Left:   resb 1
    .Window2Right:  resb 1
    .WindowMainScrn:resb 1  ;bits 0-3 for planes, bit 4 for sprites
    .WindowSubScrn: resb 1  ;bits 0-3 for planes, bit 4 for sprites
    .WindowAttrib:  resb 3
    ;  which windows are applied and if they are clipped in or out
    ;  four bits for each: BG1 BG2 BG3 BG4 OAM
    ;   0 - Window1 in or out   (0=in 1=out)
    ;   1 - Window1 enable  (0=off 1=on)
    ;   2 - Window2 in or out   (0=in 1=out)
    ;   3 - Window2 enable  (0=off 1=on)
    .WindowMasking      resb 2
    ;  how two windows overlapping work over bgs and sprites
    ;  two bits each: BG1 BG2 BG3 BG4 OAM
    ;  values: 0=OR 1=AND   2=XOR   3=XNOR
    .OAMTileBase:   resd 1  ;0-49152 in bytes (16384 increments)
    .OAMSizeSelect: resb 1  ;0-5
    .OAMSmallSize:  resb 1  ;8/16/32/64
    .OAMLargeSize:  resb 1  ;8/16/32/64
    alignb 2
    .BgInfo:        ;start for each of the four plane's information
        ;!bit depth/bit shift/colormask are all grouped together
    .BitDepth:      resb 1  ;2/4/8 - Bitdepth is zero if that plane is inactive
    .BitShift:      resb 1  ;1,2,3
    .ColorMask:     resb 1  ;simply (1<<BitDepth)-1
                    resb 1
    .MapBase:       resw 1  ;0-64k (increments of 1024)
    .TileBase:      resw 1  ;0-64k (increments of 4096)
    .MapHeight:     resb 1  ;32/64 in tiles
    .MapWidth:      resb 1
    .TileSize:      ;paired word
    .TileHeight:    resb 1  ;8/16 (valid combinations are 8x8,16x16,16x8 in pixels)
    .TileWidth:     resb 1
    .PixelHeight:   resw 1  ;256/512/1024 (pixels = tilesize * mapsize)
    .PixelWidth:    resw 1
    .Scroll:
    .ScrollY:       resw 1
    .ScrollX:       resw 1  ;0-2047 (0-65535 if using mode 7) in pixels
    alignb 2
    .BgInfo_Size    equ $-.BgInfo
    .BgInfo2:       resb .BgInfo_Size
    .BgInfo3:       resb .BgInfo_Size
    .BgInfo4:       resb .BgInfo_Size
    SnesState_Size equ $-SnesState

    Bg:
    .BitDepth       equ SnesState.BitDepth-SnesState.BgInfo
    .MapBase        equ SnesState.MapBase-SnesState.BgInfo
    .TileBase       equ SnesState.TileBase-SnesState.BgInfo
    .MapHeight      equ SnesState.MapHeight-SnesState.BgInfo
    .MapWidth       equ SnesState.MapWidth-SnesState.BgInfo
    .MapSize        equ .MapHeight
    .TileHeight     equ SnesState.TileHeight-SnesState.BgInfo
    .TileWidth      equ SnesState.TileWidth-SnesState.BgInfo
    .TileSizes      equ .TileHeight
    .PixelHeight    equ SnesState.PixelHeight-SnesState.BgInfo
    .PixelWidth     equ SnesState.PixelWidth-SnesState.BgInfo
    .ScrollY        equ SnesState.ScrollY-SnesState.BgInfo
    .ScrollX        equ SnesState.ScrollX-SnesState.BgInfo
