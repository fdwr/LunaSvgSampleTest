;Things To Fix:
;  Rewrite in C++! (tired of this asm)
;  Give it a real GUI!
;  Numbered format tables
;  Complete separating FileTiles from BlitTiles to allow multiple views

; Tilemap Viewer - Savestate/Rom array viewer
; PikenSoft (c)2001-2018
;
; By Dwayne Robinson (FDwR@hotmail.com)
; http://pikensoft.com/
; http://fdwr.tripod.com/snes.htm
; Assembly compiled with NASM/YASM and WDOSX
;
;--------------------------------------------------

;%define debug

%include "Version.asm"
%define WinDos.programNameDefine "Tilemap Viewer ", ProgramVersionStr
%define WinDos.windowClassNameDefine "TilemapViewer"
[section code code]
[section data data]
[section text code]
[section bss bss]

%include "WinDos.asm"
%include "Common.asm"

%ifnmacro debugwrite 1-*
%macro debugwrite 1+ ;Dummy to avoid build errors in DOS
%endmacro
%endif

Safety                  equ 0   ;for ensuring things do not have invalid values
Personal                equ 1   ;set to true for snapshot output and such

%ifdef WinVer
Screen.DefaultWidth     equ 640
Screen.DefaultHeight    equ 480
%else ; DOS
Screen.DefaultWidth     equ 320
Screen.DefaultHeight    equ 200
%endif

WindowRedraw:
.StatusBar      equ 1
.Partial        equ 1
.Scroll         equ 2
.SizeChange     equ 4   ;change of wrap width
.UnitChange     equ 8   ;either change of unit size, mask, or shift
.ModeChange     equ 16  ;viewing mode has changed
.Complete       equ 128
ViewWindow.Width        equ Screen.DefaultWidth - (2*4)
ViewWindow.Height       equ Screen.DefaultHeight - 20
ViewWindow.TopRow       equ 4
ViewWindow.LeftCol      equ 4
ViewWindow.MaxTileWrap  equ 512
FileOpen.Read           equ 0
FileOpen.ReadWrite      equ 2
FileOpen.FullAccess     equ 64

TileFormat:
.ColorBlocks    equ 0
.NumericValue   equ 1
.FontChar       equ 2
.Vram           equ 3
.TileTable      equ 4
.BrrSample      equ 5
.FirstBplMode   equ 6
.Snes2          equ 6
.Snes4          equ 7
.Snes8          equ 8
.Gb             equ 9
.Nes            equ 10
.LastBplMode    equ 10
.SnesMode7      equ 11
.Total          equ 12

BlitTileStruct:
.Blitter        equ 0           ;called show tiles
.Init           equ 4           ;called to initialize blitter routine
.Expander       equ 8           ;expands source units to dwords
.SrcPtr         equ 12          ;ptr to first byte of source range
.SrcWrap        equ 16          ;number of tile units per row, 1-512 (ViewWindow.MaxTileWrap)
.SrcRange       equ 20          ;total range of source bytes the window displays
.Bits           equ 24          ;size in bits of source units
.Mask           equ 28          ;bitmask to AND each unit with
.Shift          equ 32          ;number of bits to bring value down (right shift)
.SrcBit         equ 33          ;bit offset
.Format         equ 34          ;how to display tile data, including colored blocks, numbers, or tile graphics
.Orientation    equ 35          ;direction to display tiles (default columns right then row down)
.OrientRotate   equ 1           ;horizontal/vertical or vertical/horizontal (default horizontal then vertical)
.OrientFlipH    equ 2           ;proceed down or up (default down)
.OrientFlipV    equ 4           ;proceed left or right (default right)
.BackwardsEndian equ 8          ;logical or backwards endianness
.DestPtr        equ 36          ;ptr to gfx buffer or even screen directly
.DestWrap       equ 40          ;width of destination in pixels
.DestHeight     equ 44          ;pixel height of entire window
.DestWidth      equ 48
.Rows           equ 52          ;(dest window height / tile height) or less
.Cols           equ 56          ;(dest window width / tile width) or less
.Size           equ 60
.Height         equ 60          ;pixel height of each tile unit
.Width          equ 61
.Change         equ 64          ;flags to indicate various changes

GuiColorTop             equ 7
GuiColorMidTop          equ 15
GuiColorBack            equ 8
GuiColorMidBottom       equ 8
GuiColorBottom          equ 0
GuiColorBackDword       equ 8080808h
GuiColorText            equ 15

File.BufferByteSize     equ 262144 ;old value 98304
;ExportBuffer.Size      equ 262144

NumStringMaxLen         equ 10

;string control character values
SccCr           equ 13 ;carriage return
SccLf           equ 10 ;line feed
SccBlack        equ 128
SccWhite        equ 143
SccGray         equ 135
SccRed          equ 140
SccYellow       equ 142
SccGreen        equ 138
SccCyan         equ 139
SccBlue         equ 137
SccPurple       equ 141

MainLoopMessageType:
.Rest           equ 0
.Key            equ 1
.Mouse          equ 2
.Redraw         equ 3

;============================================================
section bss
Bss.Start:

DataSelector:   resw 1
PspSelector:    resw 1

alignb 4
StartOptions:
.Count:         resd 1  ;number of parameters
.Ptrs:          resd 1  ;array of pointers to each one
.Env:           resd 1  ;command environment strings
.Goto:          resd 1
.TileTableBase: resd 1
.VramBase:      resd 1
.Selector:      resw 1  ;command environment selector
.Flags_Goto     equ 1

section data
DsBase:

%ifdef WinVer
TextMessage:    db "Not finished.",0
%endif

;============================================================
section code
bits 32                         ;flat addressing is great!
global _WdosxStart              ;great (free!) extender
global Main

_WdosxStart:
Main:

%ifdef WinVer

    mov dword [WinDos.displayWidth], Screen.DefaultWidth
    mov dword [WinDos.displayHeight],Screen.DefaultHeight
    call WinDosInitialize

    WinDosWaitForNoEvents EndProgram

    call WinDosGetCommandLine
    call WinDosParseCommandLine     ;-> ecx=param count, eax=param pointers
    mov [StartOptions.Count],ecx    ;save the number of parameters
    mov [StartOptions.Ptrs],eax     ;array of pointers to each one

%elifdef DosVer

    mov [StartOptions.Count],esi    ;save the number of parameters
    mov [StartOptions.Ptrs],edi     ;array of pointers to each one
    mov [StartOptions.Env],ebp      ;and command environment strings
    mov [PspSelector],es
    push ds
    pop es

%endif

%ifdef WinVer
    call SetGraphicsMode

    ; Show help if no options given.
    cmp byte [StartOptions.Count],1 ;must be at least one parameter after executable name
    ja .AtLeastOneParameter
    call KeyHelp
    call GetFileNameFromUser
    jc .HadZeroParameters

    mov esi,eax                         ;eax=filename
    call OpenGivenViewingFile
    mov eax,ViewWindowScroll.Init
    call MainLoop.SetMessageHandler
    jmp short .HadZeroParameters

.AtLeastOneParameter:
    mov eax,ViewWindowScroll.Init
    call MainLoop.SetMessageHandler

    call CheckStartOptions
    call OpenAllFiles
.HadZeroParameters:

%elifdef DosVer

    call CheckStartOptions
    call OpenAllFiles

    call SetGraphicsMode
    mov eax,ViewWindowScroll.Init
    call MainLoop.SetMessageHandler

%endif


;------------------------------
MainLoop:
.CheckEvents:
    WinDosCheckForEvent EndProgram
.ProcessEvents:
    call GetKeyPress
    jnc .NoKeyPress
    mov ebx,MainLoopMessageType.Key
    call [.MessageHandler]
    jmp short .CheckEvents
.NoKeyPress:
;.NextMouseChange:
    ;call Mouse.GetInfo
    ;mov ebx,MainLoopMessageType.Mouse
    ;jmp short .NextMouseChange
.NextRest:
    mov ebx,MainLoopMessageType.Rest
    call [.MessageHandler]
    WinDosWaitForEvent EndProgram

%ifdef WinVer
    ;TODO: Move this out of the main loop to the message handler instead.
    cmp dword [WinDos.msg+MSG.message],WM_DROPFILES
    je .FileDropped
%endif

    jmp .ProcessEvents

%ifdef WinVer
.FileDropped:
    ; Close existing file, and open new one.
    mov esi,WinDos.dragAndDropFile
    call OpenGivenViewingFile
    jmp .ProcessEvents
%endif

.SetMessageHandler:
    mov [.MessageHandler],eax
    ret

.GetMessageHandler:
    mov eax,[.MessageHandler]
    ret

.EndProgram:
    mov dword [.MessageHandler],.End
    ret

section data
align 4
; (ebx=MainLoopMessageType) ()
.MessageHandler: dd .End
section code

.End:
    add esp,byte 4
    ; fall through into EndProgram

;------------------------------
EndProgram:
    call CloseAllFiles
    call SetTextMode

    xor eax,eax             ;exit code is zero, no problems
    jmp short .Immediately

.WithMessage:;public entry
%ifdef DosVer
    call SetTextMode
    mov al,1                ;exit code is set since problem occurred
    mov ah,9                ;function to print string
    int 21h                 ;call DOS
%elifdef WinVer
    api MessageBoxA, 0, edx, "TileMapViewer", MB_ICONWARNING
%endif
.Immediately:;public entry (edx=message)
    mov ah,4Ch              ;die, exit code is in al
    int 21h

CheckStartOptions:
    cmp byte [StartOptions.Count],1 ;must be at least one parameter after executable name
    ja .AtLeastOneParameter
%ifdef DosVer
    mov edx,Text.Info
    jmp EndProgram.WithMessage
%else
    ret
%endif
.AtLeastOneParameter:
    xor edx,edx
    cld                             ;all string operations are forward
.Next:
    call .GetNext
    jbe near .End
    cmp byte [esi],'-'
    jne .FileName
    mov al,[esi+1]
    mov edi,.ParamList
    mov ecx,.ParamListLen
    repne scasb
    jnz .NotFound
    sub edi,.ParamList+1                ;get jump table index from amount edi was read forward
    jmp dword [.ParamJtbl+edi*4]
.NotFound:
    mov edx,Text.UnknownParameter
    jmp EndProgram.WithMessage

.FileName:
    movzx ecx,byte [Files.ToOpen]
    cmp cl,4
    jae .NoMoreFiles
    inc byte [Files.ToOpen]
    shl ecx,4                           ;*16
    mov [Files+Files.EntryName+ecx],esi ;set ptr to filename
    ;mov [File.Name],esi                ;set ptr to name
.NoMoreFiles:
    jmp .Next
.Goto:
    call .GetNext
    jbe near .End
    mov [StartOptions.Goto],esi
    or dword [StartOptions.Flags],StartOptions.Flags_Goto
    jmp .Next
;.UnitAdjust:
;    call .GetNext
;    jbe near .End
;    call .GetNumber
;    mov [ViewWindow.UnitAdjust],eax
;    jmp .Next
.WrapWidth:
    call .GetNext
    jbe near .End
    push edx                        ;save parameter count
    call StringToNum
    pop edx                         ;retrieve parameter count
    cmp eax,ViewWindow.MaxTileWrap
    ja .NoWrapSet
    test eax,eax
    jz .NoWrapSet
    mov [FileTiles.SrcWrap],eax
.NoWrapSet:
    jmp .Next
.UnitSize:
    call .GetNext
    jbe near .End
    push edx                        ;save parameter count
    call StringToNum
    pop edx                         ;retrieve parameter count
    ;eax=bites
    mov edi,FileTiles
    call ExpandTileUnit.SetBits
.NotUnitSize:
    jmp .Next
.Mode:
    call .GetNext
    jbe near .End
    push edx
    mov ebx,.ModeList
    call .GetStringMatch ;(esi=search text, ebx=string match list) (eax=match index)
    jne .NotMode
    mov esi,.ModeInfo
    call SetViewingMode
.NotMode:
    pop edx
    jmp .Next
.SetFileReadOnly:
    or byte [File.Attribs],File.Atr_ReadOnly
    jmp .Next
.LoadVram:
    call .GetNext
    jz near .End
    mov ebx,16                      ;file offset is in hex
    call .GetNumberAnyRadix
    jz .LoadVramEnd
    mov [StartOptions.VramBase],eax
    call .GetNumber
    and eax,65535                   ;wrap within 64k
    mov dword [Vram.Base],eax       ;set first tile to first byte
    mov cl,[Files.ToOpen]
    mov [File.Vram],cl              ;mark file as holding VRAM
    ;call .GetNumber
    ;jz .LoadVramEnd 
    ;cmp eax,8                       ;bitplane may be 1-8
    ;ja .LoadVramEnd
    ;test eax,eax
    ;jz .LoadVramEnd
    ;mov [Vram.Bitdepth],al
.LoadVramEnd:
    jmp .Next
.LoadTileTable:
    call .GetNext
    jz near .End
    mov ebx,16                      ;file offset is in hex
    call .GetNumberAnyRadix
    jz near .Next
    mov [StartOptions.TileTableBase],eax
    mov cl,[Files.ToOpen]
    mov [File.TileTable],cl
    call .GetNumber
    jz near .Next
    cmp al,16
    jbe .TileHeightOk
    mov al,16
  .TileHeightOk:
    mov [TileTable.Height],al
    call .GetNumber
    jz near .Next
    cmp al,16
    jbe .TileWidthOk
    mov al,16
  .TileWidthOk:
    mov [TileTable.Width],al
    call .GetNumber
    jz near .Next
    cmp al,2
    jbe .TileByteSizeOk
    mov al,2
  .TileByteSizeOk:
    mov [TileTable.Bytes],al
    call .GetNumber
    jz near .Next
    or byte [TileTable.Options],TileTable.Flipped
    jmp .Next
.SidewaysOrientation:
    or byte [FileTiles.Orientation],BlitTileStruct.OrientRotate
    jmp .Next

.GetNext:
    inc edx
    cmp [StartOptions.Count],edx
    jbe .GetNext_End                ;if current parameter is beyond last
    mov esi,[StartOptions.Ptrs]     ;get ptr to table of parameters
    mov esi,[esi+edx*4]
.GetNext_End:
    ret
;(esi=source string) (eax=number, esi=source string of next number)
.GetNumber:
    mov ebx,10
;(esi=source string, ebx=radix) (eax=number, esi=source string of next number)
.GetNumberAnyRadix:
    mov ecx,NumStringMaxLen         ;set string length
    push edx                        ;save parameter count
    call StringToNum.AnyRadix
    pushf                           ;save zero flag
    cmp byte [esi],','              ;check if comma
    jne .GetNumberNotComma
    inc esi
.GetNumberNotComma:
    popf
    pop edx                         ;retrieve parameter count
    ret

; Searches through a string list for given text.
; (esi=search text, ebx=string list) (zf=match, eax=index)
.GetStringMatch:
    ;get string's length
    cld
    xor eax,eax             ;search for null
    mov ecx,16              ;maximum length of search string
    mov edx,ecx             ;make a copy of max length for later
    mov edi,esi             ;copy source for string length search
    cld                     ;as always, look forward
    repne scasb             ;search for the end, until null is found
    not ecx                 ;negate count and subtract null at the end
    add edx,ecx             ;get length

    ;xor eax,eax             ;zero match index
    mov ecx,eax             ;zero compare string length

.NextCompare:
    mov cl,[ebx]            ;get of length compare string
    inc ebx                 ;first character of compare string
    cmp edx,ecx             ;if lengths are different, don't bother
    jne .DifLen             ;comparing the characters
    mov edi,ebx
    rep cmpsb
    je .Match
    inc eax
    add esi,ecx             ;compensate for change in esi after search
    add ebx,edx             ;advance next string in list
    sub esi,edx
    jmp short .NextCompare
.DifLen:
    inc eax
    add ebx,ecx             ;advance next string in list
    test ecx,ecx            ;last string if length is zero
    jnz .NextCompare
    test ebx,ebx            ;do dummy operation to clear zero flag
.Match:
    ;ret

.End:
    ret

section data
.ParamList:     db "vtrmuwgo"
.ParamListLen   equ $-.ParamList
align 4
.ParamJtbl:     dd .LoadVram,.LoadTileTable,.SetFileReadOnly,.Mode,.UnitSize,.WrapWidth,.Goto,.SidewaysOrientation

.ModeList:      db 2,"cb",3,"num",4,"text",4,"vram",2,"tt",3,"spc",5,"snes2",5,"snes4",5,"snes8",4,"gb",3,"nes",5,"mode7",0
.ModeInfo:      ;tile format, unit size in bits, wrap, orientation, gfx converter
db TileFormat.ColorBlocks,-1,-1,-1, 0, 0, 0  ;blocks
db TileFormat.NumericValue,-1,-1,-1, 0, 0, 0  ;numbers
db TileFormat.FontChar, -1,-1, -1, 0, 0, 0  ;text, byte if ASCII, word if unicode/Japanese
db TileFormat.Vram,     -1,-1, -1, 0, 0, 0  ;vram/word/32
db TileFormat.TileTable,-1,-1, -1, 0, 0, 0  ;tile table
db TileFormat.BrrSample, 8, 9,  1, 0, 0, 0  ;spc sample/9/9
db TileFormat.Snes2,     16,32,-1, 0, 0, 0  ;snes2
db TileFormat.Snes4,     16,32,-1, 0, 0, 0  ;snes4
db TileFormat.Snes8,     16,32,-1, 0, 0, 0  ;snes8
db TileFormat.Gb,        8, 32,-1, 0, 0, 0  ;gb
db TileFormat.Nes,       8, 32,-1, 0, 0, 0  ;nes
db TileFormat.SnesMode7, 16,32,128, 0, 0, 0  ;mode7

section code

;() (cf=canceled, eax=filename from GetFileNameFromUser.fileName)
GetFileNameFromUser:
%ifdef WinVer
    section bss
    align 4, resb 1
    .openFileName:      resb OPENFILENAME_size
    .fileName:          resb MAX_PATH
    section data
    .extensionFilterList: db "All",0,"*.*",0,0
    section code

    ; Show open file dialog
    mov ecx,OPENFILENAME_size
    mov edi,.openFileName
    call ZeroFill
    mov dword [.openFileName+OPENFILENAME.lStructSize],OPENFILENAME_size
    mov dword [.openFileName+OPENFILENAME.lpstrFile],.fileName
    mov dword [.openFileName+OPENFILENAME.nMaxFile],MAX_PATH
    mov dword [.openFileName+OPENFILENAME.Flags],OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST
    mov dword [.openFileName+OPENFILENAME.lpstrFilter],.extensionFilterList
    mov dword [.openFileName+OPENFILENAME.nFilterIndex],0
    mov eax,[WinDos.hwnd]
    mov dword [.openFileName+OPENFILENAME.hwndOwner],eax

    api GetOpenFileName, .openFileName
    test eax,eax
    jz .Canceled
    mov eax,[.openFileName+OPENFILENAME.lpstrFile]
    ret
.Canceled:
    stc
%else ; DosVer
    ; [todo] Ask for name via typeable prompt, same as goto function.
    mov esi,Text.PromptOpenFilename
    call ViewingWindowPrompt
    ;(esi=typed string, cf=cancel)
    mov eax,esi
%endif
    ret

;------------------------------
;(esi=file name)
OpenGivenViewingFile:
    ; Close existing file, and open new one.
    push esi
    call CloseAllFiles
    mov byte [Files.ToOpen],1
    pop dword [Files+Files.EntryName]
    call OpenAllFiles
    mov byte [ViewWindow.Change],WindowRedraw.Complete
    ret

;------------------------------
;do until no more filenames
;   open file
;   end with error message if could not be opened
;   load vram if specified
;   load tile table if specified
;   close file unless current file is for viewing
;loop
;set viewing file's position
OpenAllFiles:
    debugwrite "OpenAllFiles"
    mov edi,File.Buffer
    mov ecx,File.BufferByteSize
    call ZeroFill

    xor eax,eax
    mov dword [File.Position],eax
    mov dword [ViewWindow.FilePosition],eax
    mov [ViewWindow.FileOffsetBase],eax
    and byte [ViewWindow.Options],~ViewWindow.UseOffsetBase

    movzx ecx,byte [Files.ToOpen]   ;must be at least one file given,
    test ecx,ecx                    ;the viewing file
    jnz .FilesToOpen
    mov edx,Text.NoFilesGiven
    jmp EndProgram.WithMessage
.FilesToOpen:
    dec ecx         ;open each file in last-to-first order
    mov ebx,ecx
    shl ebx,4       ;*16
    push ebx
    push ecx
    jmp short .FirstFile
.NextFile:
    mov ah,3Eh                  ;close file opened in the previous loop
    mov ebx,[File.Handle]
    int 21h
.FirstFile:
    mov ebx,[esp+4]             ;get current file number
    mov edx,[Files+Files.EntryName+ebx]

    ;mov byte [File.Attribs],0
    mov [File.Name],edx
    call OpenFile ;() (edx=message if cf)
    jc near EndProgram.WithMessage

    mov bl,[esp]
    cmp [File.TileTable],bl
    jne .NoTileTable
    mov edx,[StartOptions.TileTableBase]
    mov edi,TileTable
    mov ecx,32768
    call LoadFilePart
    test byte [TileTable.Options],TileTable.Flipped
    jz .NoTileTableFlip
    call FlipTileTable
.NoTileTableFlip:
    or byte [TileTable.Options],TileTable.Loaded
    mov bl,[esp]
.NoTileTable:
    cmp [File.Vram],bl
    jne near .NoVram
    mov edx,[StartOptions.VramBase]
    mov edi,Vram
    mov ecx,65536
    call LoadFilePart.AbsoluteOffset ;Load VRAM
    and byte [Vram.Options],~Vram.Cached
    or byte [Vram.Options],Vram.Loaded
.NoVram:
    cmp byte [File.Vram],-1         ;do not load VRAM from savestate if another file is specified
    jne near .NoZst
    cmp byte [File.Type],File.Type_Zst
    jne near .NoZst
    mov edx,20C13h                  ;Load VRAM
    mov edi,Vram
    mov ecx,65536
    call LoadFilePart.AbsoluteOffset
    mov edx,1560                    ;Load palette
    mov edi,Vram.CgramPalette
    mov ecx,512
    call LoadFilePart.AbsoluteOffset
    xor edx,edx                     ;Load registers
    mov edi,File.Buffer
    mov ecx,160
    call LoadFilePart.AbsoluteOffset
    mov ecx,3                       ;Move in bg map pointers
    xor eax,eax
    xor ebx,ebx
.NextBgMapBase:
;Read in each of the savestates bg tilemap and graphics offsets in VRAM
    mov ax,[File.Buffer+107+ecx*2]  ;offset of bg tilemap
    mov bx,[File.Buffer+143+ecx*2]  ;offset of tile graphics
    mov [BgMapBases+ecx*4],eax
    mov [BgTileBases+ecx*4],ebx
    dec ecx
    jns .NextBgMapBase
    movzx ecx,byte [File.Buffer+102];get video mode
    cmp cl,7                        ;check specially for mode7 to zero the tilemap offset.
    jne .NotMode7
    mov dword [BgTileBases],0       ;the mode7 tile graphics always start at 0, regardless of other registers.
    mov dword [BgMapBases],0        ;the mode7 tilemap always starts at 0, regardless of the BG1SC register.
.NotMode7:
    mov [Vram.Base],ebx             ;set VRAM base to base of first bg
    mov eax,[BgModeToBitdepthTable+ecx*4] ;get bitdepths of each bg for mode
    mov [BgBitdepths],eax
    mov [Vram.Bitdepth],al          ;use bitdepth of first bg
    mov eax,[BgModeToTileFormatsTable+ecx*4] ;get tile formats of each bg for current mode
    mov [BgTileFormats],eax         ;set all 4 tile formats, 1 per bg
    mov [Vram.TileFormat],al

    or byte [Vram.Options],Vram.Loaded
    mov esi,Vram.CgramPalette
    mov edi,Vram.Palette
    call ConvertPaletteSnesToPc
.NoZst:
    sub dword [esp+4],Files.EntryByteSize ;back one entry to earlier entry
    dec dword [esp]         ;one less file
    jns near .NextFile
    add esp,byte 8

    mov eax,[File.Position]
    test eax,eax
    jz .NoRelativeOffset
    ;if file position was set to anything other than zero, then set the
    ;offset base relative, otherwise set it absolute.
    mov [ViewWindow.FileOffsetBase],eax
    or byte [ViewWindow.Options],ViewWindow.UseOffsetBase
.NoRelativeOffset:
    test dword [StartOptions.Flags],StartOptions.Flags_Goto
    jz .NoPreGoto
    ;do goto if one was given from the command line.
    mov esi,[StartOptions.Goto]
    call GotoFilePos
.NoPreGoto:
    cmp [File.Length],eax   ;past end of file?
    ja .PositionInRange     ;no, position ok
    mov eax,[File.Length]
    dec eax                 ;otherwise set to (length_of_file - 1)
.PositionInRange:
    mov [ViewWindow.FilePosition],eax
    ret

CloseAllFiles:
    cmp dword [File.Handle], 0
    je .AlreadyClosed
    mov ax,3E00h            ;function to close file
    mov ebx,[File.Handle]   ;get file's handle
    int 21h                 ;call DOS
    mov dword [File.Handle],0
 
    mov edi,Files.Entries
    mov ecx,Files.EntriesTotalBytes
    call ZeroFill
.AlreadyClosed:
    ret

;------------------------------
;([File.Name]) (eax=position ;cf=error, edx=ptr to error message)
;1. try to open file
;2. try readonly if first open failed
;3. get file length, ending if length is zero
;4. determine file type and set position
OpenFile:
    mov edx,[File.Name]                 ;get ptr to name
    test byte [File.Attribs],File.Atr_ReadOnly
    jnz .TryReadOnly
    mov ax,3D00h|FileOpen.FullAccess|FileOpen.ReadWrite ;function to open file
    int 21h                             ;call DOS
    jnc .FileOpened                     ;if no error opening
    or byte [File.Attribs],File.Atr_ReadOnly
.TryReadOnly:
    mov ax,3D00h|FileOpen.FullAccess|FileOpen.Read  ;attempt read only
    int 21h                             ;call DOS
    jnc .FileOpened                     ;if no error opening
.FileOpenFailed:
    mov edx,Text.FileOpenError          ;set ptr to error message
    stc                                 ;in case not already set by label caller
    ret

.FileOpened:
    mov [File.Handle],eax               ;save file handle for later reads
    mov ebx,eax                         ;copy file handle to ebx
    xor ecx,ecx                         ;set relative offset to 0
    mov eax,4202h                       ;function to get and set file position
    xor edx,edx                         ;set relative offset from end to 0
    int 21h
    jc .FileReadError                   ;end if position setting error
    shl edx,16                          ;adjust upper sixteen bits of file position
    mov dx,ax                           ;fill in lower sixteen bits
    test edx,edx
    jnz .FileLengthOk                   ;end if file is empty, zero bytes
.FileReadError:
    mov edx,Text.FileReadError          ;set ptr to error message
    stc                                 ;error
    ret
.FileLengthOk:
    mov [File.Length],edx
    mov dword [File.BufferBase],-1
    ;once opened, reset cache by setting bufferbase to -1.
    ;cache is gauranteed to be refreshed before displaying tiles, since
    ;the data it needs resides before the bufferbase.

.DetermineType:
;Check if the file is an SNES ROM with 512 byte header
    ;mov edx,[File.Length]
    cmp edx,32768+512
    jb .NotRomWithHeader
    and edx,32767
    mov eax,512             ;set to first byte after header
    cmp edx,eax
    jne .NotRomWithHeader
    mov byte [File.Type],File.Type_Rom
    jmp .SetRelativePosition
.NotRomWithHeader:
;Check if the file being viewed is a ZSNES savestate or movie
    xor edx,edx
    mov edi,File.Buffer
    mov ecx,30
    call LoadFilePart.AbsoluteOffset
    cld
    mov esi,File.Buffer
    mov edi,Text.ZSNESSavestateID
    mov ecx,Text.ZSNESSavestateID_Len
    repe cmpsb
    jne .NotZsnesSavestate
    mov byte [File.Type],File.Type_Zst
    mov eax,3091                    ;offset of WRAM in savestate
    ;jmp short .SetRelativePosition
.SetRelativePosition:
    mov [File.Position],eax
    ;or byte [File.Attribs],File.Atr_RelativeOffset
    ;clc
    ret
.NotZsnesSavestate:
    mov byte [File.Type],File.Type_Any
    xor eax,eax     ;default starting position if not a savestate or ROM
    mov [File.Position],eax
    ;clc
    ret

;------------------------------
;(edx=file position, ecx=bytes to read, edi=ptr to destination)
LoadFilePart:
    add edx,[File.Position] ;get file position plus base offset
.AbsoluteOffset:
    push ecx
    mov ebx,[File.Handle]
    shld ecx,edx,16         ;upper part of edx into cx
    mov eax,4200h           ;function to get and set file position
    int 21h
    mov edx,edi
    pop ecx
    mov ah,3Fh
    int 21h
    ret

;------------------------------
SetGraphicsMode:
.Video:
    mov ax,13h
    int 10h

    mov esi,RainbowPalette
    call SetPalette

.InitMouse:
    xor eax,eax
    int 33h                 ;returned value should be FFFFh
    inc ax                  ;ax should now be 0 if value was FFFFh
    setz byte [Mouse.Installed]
    ret

;------------------------------
;(esi=palette table uint24[256]) ()
SetPalette:
    cld
    mov dx,3C8h
    xor al,al
    out dx,al
    ;mov dx,3C9h
    inc edx
    mov ecx,768
.NextEntry:
    lodsb
    out dx,al
    loop .NextEntry
    ret

;------------------------------
SetTextMode:
    mov ax,0x0F00           ;get video mode first
    int 10h                 ;call video bios
    cmp al,0x03             ;check if already text mode, to avoid clearing the screen.
    je .AlreadyTextMode
    mov ax,0x0003           ;boring text mode
    int 10h                 ;call video bios
.AlreadyTextMode:
    ret

;------------------------------------------------------------
ViewWindowScroll:
.Init:
    debugwrite "ViewWindowScroll.Init"
    mov al,[FileTiles.Format]
    mov edi,FileTiles
    call SetTileFormat
    call RedrawViewingWindowPage
    ;call Mouse.Show
    mov eax,.MessageHandler
    jmp MainLoop.SetMessageHandler

;if window position has changed an no key input is waiting, then redraw window
;sit in loop waiting for key input
;(ebx=message type, eax=message details)
.MessageHandler:
    cmp ebx,MainLoopMessageType.Key
    je .ReactKeyPress
    ;cmp ebx,MainLoopMessageType.Mouse
    ;je .ReactKeyPress
    cmp ebx,MainLoopMessageType.Redraw
    je .RedrawFully
    cmp ebx,MainLoopMessageType.Rest
    jne .WaitForInput
    test byte [ViewWindow.Change],-1
    jnz .Redraw
.WaitForInput:
    ret

.Redraw:
    call Mouse.Hide
    call RedrawViewingWindow
    mov byte [ViewWindow.Change],0
    jmp Mouse.Show
    ;ret

.RedrawFully:
    debugwrite "ViewWindowScroll.RedrawFully"
    call Mouse.Hide
    call RedrawViewingWindowPage
    mov byte [ViewWindow.Change],WindowRedraw.Complete
    call RedrawViewingWindow
    mov byte [ViewWindow.Change],0
    jmp Mouse.Show
    ;ret

;(eax=keypress)
.ReactKeyPress:
    mov esi,.ScrollKeys
    call KeyScanFor
    jnc .ScrollAmount
    ;cmp byte [.EntryLock],.EntryLockNone
    ;je .CheckOtherKeys
    ;0-9,A-F? add letter to prompt
    ;Enter? process value in prompt
.CheckOtherKeys:
    debugwrite "keypress=%X", eax

    mov esi,.Keys
    call KeyScanFor
    jc .WaitForInput
    jmp [.KeysJtbl+ecx*4]   ;jump to the right key response

.ScrollAmount:
    movsx eax,byte [.ScrollKeysStepTable+ecx]
    test byte [FileTiles.Orientation],BlitTileStruct.OrientRotate
    jz .NoRotatedScroll
    xor cl,2
.NoRotatedScroll:
    test cl,2                ;test for vertical or horizontal
    jz near .ScrollByRow
    jmp .ScrollByTile
.ByteBack:
    mov eax,-1
    xor edx,edx
    jmp .ScrollByByte
.ByteForward:
    mov eax,1
    xor edx,edx
    jmp .ScrollByByte
.BankBack:
    mov eax,-32768
    xor edx,edx
    jmp .ScrollByByte
.BankForward:
    mov eax,32768
    xor edx,edx
    jmp .ScrollByByte
.ScrollHome:
    mov eax,[ViewWindow.FileOffsetBase]
    xor edx,edx                     ;zero bit offset
    cmp [ViewWindow.FilePosition],eax
    ja near .SetFilePosition    ;if current file pos > file base, set to base
    cmp [ViewWindow.FilePosition],dword 0
    je near .SetFilePosition    ;if current file pos = 0, set to base
    xor eax,eax                 ;else current file pos < file base, set to 0
    jmp .SetFilePosition
.ScrollEnd:
    mov eax,[File.Length]
    xor edx,edx                 ;zero bit offset
    dec eax
    jmp .SetFilePosition
.DecWrap:
    mov eax,[FileTiles.SrcWrap]
    dec eax
    jmp .CheckWidth
.IncWrap:
    mov eax,[FileTiles.SrcWrap]
    inc eax
    jmp .CheckWidth
;.DecAdjust:
;    dec dword [ViewWindow.UnitAdjust]
;    jmp .SetFullChange
;.IncAdjust:
;    inc dword [ViewWindow.UnitAdjust]
;    jmp .SetFullChange
.HalfWrap:
    mov eax,[FileTiles.SrcWrap]
    shr eax,1
    jmp .CheckWidth
.DoubleWrap:
    mov eax,[FileTiles.SrcWrap]
    shl eax,1
    jmp .CheckWidth
.ToggleUnitSize:
    mov eax,[FileTiles.Bits]
    mov esi,[FileTiles.Mask]
    mov cl,[FileTiles.Shift]
    xchg [FileTiles.PrevBits],eax  ;toggle between current and previous bits
    xchg [FileTiles.PrevMask],esi
    xchg [FileTiles.PrevShift],cl
    mov dl,[FileTiles.Orientation]
    xor dl,[FileTiles.PrevOrient]
    and dl,BlitTileStruct.BackwardsEndian
    xor [FileTiles.Orientation],dl
    xor [FileTiles.PrevOrient],dl
    mov [FileTiles.Mask],esi
    mov [FileTiles.Shift],cl
    ;(al=bits)
.SetUnitSize:
    mov edi,FileTiles
    call ExpandTileUnit.SetBits
    mov al,[FileTiles.Format]
    push dword .SetFullChange
    ;mov edi,FileTiles
    jmp SetTileFormat
.NextUnitSize:
    mov eax,[FileTiles.Bits]
    cmp eax,8
    je .ShiftUnitSize           ;there is no high-endian form for bytes
    xor byte [FileTiles.Orientation],BlitTileStruct.BackwardsEndian
    test byte [FileTiles.Orientation],BlitTileStruct.BackwardsEndian
    jnz .SetUnitSize
.ShiftUnitSize:
    shl eax,1
    and eax,63
    jnz .SetUnitSize
    mov eax,1
    and byte [FileTiles.Orientation],~BlitTileStruct.BackwardsEndian
    jmp short .SetUnitSize
.NextPalette:
    mov al,[FileTiles.PaletteIndex]
    inc al
    and al,1                            ;wrap between 2 available palettes
    jz .NextPaletteUseDefault
    test byte [Vram.Options],Vram.Loaded
    jz .NextPaletteUseDefault
    mov esi,Vram.Palette
    jmp short .NextPaletteSetValue
.NextPaletteUseDefault:
    mov esi,RainbowPalette
    xor eax,eax
.NextPaletteSetValue: ;(al=palette index, edx=palette table pointer)
    mov [FileTiles.PaletteIndex],al
    mov dword [Display.PalettePtr],esi
    call SetPalette; (esi=palette ptr)
    jmp .SetFullChange
.DecMask:
    mov eax,[FileTiles.Mask]
    shr eax,1
    jmp short .SetMask
.IncMask:
    mov eax,[FileTiles.Mask]
    shl eax,1
    ;jmp short .SetMask
.SetMask:
    or eax,1
    mov [FileTiles.Mask],eax
    jmp .SetPartialChange
.DecShift:
    mov al,-1
    jmp short .SetShift
.IncShift:
    mov al,1
    ;jmp short .SetShift
.SetShift:
    add al,[FileTiles.Shift]
    cmp al,32
    jae near .WaitForInput
    mov [FileTiles.Shift],al
    jmp .SetPartialChange
.Help:
    call KeyHelp
    jmp .WaitForInput
.ToggleHexDec:
    mov al,16                       ;default position in hex
    cmp [ViewWindow.PosRadix],al
    jne .FilePosNotHex
    mov al,10
  .FilePosNotHex:
    mov [ViewWindow.PosRadix],al
    jmp .SetStatBarChange
.ToggleUseBase:
    xor byte [ViewWindow.Options],ViewWindow.UseOffsetBase
    jmp .SetStatBarChange
;.ToggleStepSize:
;    rol byte [ViewWindow.StepSize],4
;    jmp .SetStatBarChange
.FindBytes:
    jmp .SetStatBarChange
.SetData:
    mov esi,Text.PromptColorValue
    call ViewingWindowPrompt
    jbe near .WaitForInput          ;cancel
    mov ecx,4                       ;set string length
    mov ebx,16
    call StringToNum.AnyRadix
    jz near .WaitForInput           ;cancel
    mov [ViewWindow.WriteDataValue],eax
    ;jmp .WaitForInput
.WriteData:
    test byte [File.Attribs],File.Atr_ReadOnly
    jnz near .WaitForInput
    or byte [ViewWindow.Change],WindowRedraw.Scroll
    call SetViewWindowUnit
    jmp .WaitForInput
.SetPosToBase:
    mov eax,[ViewWindow.FilePosition]
    mov [ViewWindow.FileOffsetBase],eax
    or byte [ViewWindow.Options],ViewWindow.UseOffsetBase   ;set to relative
    jmp .SetStatBarChange
.ToggleMode:
    mov al,[FileTiles.Format]
    xchg [FileTiles.PrevFormat],al
    jmp short .SetViewMode
.NextMode:
    mov al,[FileTiles.Format]
    inc al                          ;set next mode
    cmp al,TileFormat.Total
    jb .SetViewMode
    xor al,al
.SetViewMode:
    mov edi,FileTiles
    call SetTileFormat           ;set up current mode
    jmp .SetFullChange
.ToggleOrientation:
    xor byte [FileTiles.Orientation],BlitTileStruct.OrientRotate
    jmp .SetFullChange
.SetViewingMode:
    lea eax,[ecx-.KeysListNumbersOffset]
    mov esi,NumberedFormatsTbl
    call SetViewingMode
    jmp .SetFullChange
.Goto:
    mov esi,Text.PromptGotoPosition
    call ViewingWindowPrompt
    jbe near .SetStatBarChange      ;cancel
    call GotoFilePos
    jc near .SetStatBarChange       ;string was null, error, or no change
    xor edx,edx                     ;zero bit offset
    jmp .SetFilePosition

.ScrollByRow: ;(eax=rows to scroll +-)
    imul dword [FileTiles.SrcWrap]
.ScrollByTile: ;(eax=tiles to scroll +-)
    mov edx,[FileTiles.Bits]
    imul eax,edx                ;x * bits
    dec edx                     ;make unit mask from (bits - 1)
    movzx ecx,byte [FileTiles.SrcBit]
    not edx                     ;make mask for nearest whole unit alignment
    and edx,7                   ;limit bit range 0-7
    add eax,ecx                 ;add scroll amount to current bit offset
    and edx,eax                 ;get new bit offset
    sar eax,3                   ;get new byte scroll
.ScrollByByte: ;(eax=file adjust, edx=new bit offset)
    mov ebx,[ViewWindow.FilePosition]
    add eax,ebx
.CheckFilePosition:
;(eax=new file position, ebx=old position, edx=bit offset, fl=tested eax)
    mov ecx,[File.Length]
    js .PositionNegative
    cmp eax,ecx
    jae .PositionBeyondEnd
.SetPosition: ;(eax=file position, edx=bit offset)
    mov [ViewWindow.FilePosition],eax ;set position to last byte in file
    mov [FileTiles.SrcBit],dl
    or byte [ViewWindow.Change],WindowRedraw.Scroll
    jmp .WaitForInput
.PositionNegative:
    test ebx,ebx                    ;is it already at the beginning?
    jz near .WaitForInput           ;yes, so return to loop
    xor eax,eax                     ;set position to first byte in file
    jmp short .SetPosition
.PositionBeyondEnd:
    jmp .WaitForInput               ;return to loop
    dec ecx                         ;last position in a file is size-1
    cmp ebx,ecx                     ;is it already at the end?
    je near .WaitForInput           ;yes, so return to loop
    mov eax,ecx                     ;set position to last byte in file
    jmp short .SetPosition

.SetFilePosition: ;(eax=new file position, edx=bit offset)
    mov ebx,[ViewWindow.FilePosition]
    test eax,eax
    jmp .CheckFilePosition

.CheckWidth: ;(eax=new wrap)
    cmp eax,ViewWindow.MaxTileWrap
    ja near .WaitForInput
    test eax,eax
    jz near .WaitForInput
    mov [FileTiles.SrcWrap],eax
    ;jmp short .SetFullChange

.SetFullChange:
    mov byte [ViewWindow.Change],WindowRedraw.Complete
    jmp .WaitForInput
.SetPartialChange:
    or byte [ViewWindow.Change],WindowRedraw.UnitChange|WindowRedraw.StatusBar|WindowRedraw.Scroll
    jmp .WaitForInput
.SetStatBarChange:
    or byte [ViewWindow.Change],WindowRedraw.StatusBar
    jmp .WaitForInput
.OpenFileFromUser:
    call GetFileNameFromUser
    jc .WaitForInput
    mov esi,eax                         ;eax=filename
    jmp OpenGivenViewingFile
    ;ret
.QuitEnd:
    jmp MainLoop.EndProgram

.Keys:
dd .KeysList
db .KeysListNormalKeyCount,.KeysListExtendedKeyCount

.KeysList:
db "][}{+-*/uhbBmMgfwoUp"
.KeysListNumbersOffset  equ $-.KeysList
db "123456789" ; == NumberedFormatsTbl.Size
db 15 ;Ctrl+O
db ""
.KeysListNormalKeyCount equ $-.KeysList
; Extended keys start here.
db 116,115, 118,132, 119,117, 83,59
.KeysListExtendedKeyCount equ $-.KeysList-.KeysListNormalKeyCount

.KeysJtbl:
dd .IncWrap         ;']'
dd .DecWrap         ;'['
;dd .IncAdjust      ;'}'
;dd .DecAdjust      ;'{'
dd .DoubleWrap      ;'}' double wrap
dd .HalfWrap        ;'{' half wrap
dd .IncShift        ;'+' increment shift
dd .DecShift        ;'-' decrement shift
dd .IncMask         ;'*' increment mask
dd .DecMask         ;'/' decrement mask
dd .ToggleUnitSize  ;'u' toggle unit size between byte/word
dd .ToggleHexDec    ;'h' toggle between decimal and hex
dd .ToggleUseBase   ;'b' use or do not use offset base
dd .SetPosToBase    ;'B' set offset base to current file position
dd .ToggleMode      ;'m'
dd .NextMode        ;'M'
dd .Goto            ;'g' goto position
dd .FindBytes       ;'f' find data
dd .SetData         ;'w' set data value (color)
dd .ToggleOrientation ;'o' normal or sideways
dd .NextUnitSize    ;'U' 1,2,4,8,16
dd .NextPalette     ;'p'
dd .SetViewingMode,.SetViewingMode,.SetViewingMode;1-3
dd .SetViewingMode,.SetViewingMode,.SetViewingMode;4-6
dd .SetViewingMode,.SetViewingMode,.SetViewingMode;7-9
dd .OpenFileFromUser;Ctrl+O
dd .QuitEnd         ;'' escape, do you really want to quit :(
; Extended keys start here:
dd .ByteForward     ;Ctrl+Right
dd .ByteBack        ;Ctrl+Left
dd .BankForward     ;Ctrl+PgDn
dd .BankBack        ;Ctrl+PgUp +-32k
dd .ScrollHome      ;Ctrl+Home
dd .ScrollEnd       ;Ctrl+End
;dd .ToggleStepSize  ;Insert  toggle between 1 and 16 unit step size
dd .WriteData       ;Delete  change unit to current "color"
dd .Help            ;F1      help!

.ScrollKeys:
dd .ScrollKeysList
db 0,8

.ScrollKeysList:
db '','HPKMIQGO'    ;Up,Down,Left,Right,PgUp,PgDn,Home,End

.ScrollKeysStepTable:
db -1,1,-1,1,-16,16,-16,16

;.EntryLock:     db 0            ;mode, goto, edit
;.EntryLockNone  equ 0
;.EntryLockGoto  equ 1
;.EntryLockEdit  equ 2
;.EntryLockMode  equ 3
;.EntryLockUnit  equ 4
;.ToolButtonDown:db 0
;.Tool:          db 0            ;currently used tool
;.ToolSelect     equ 0
;.ToolPen        equ 1
;.ToolGetUnit    equ 2
;.ToolWrite      equ 3

;------------------------------
; Used to goto a:
;   Relative/absolute position
;   Bg map base
;   Low ROM address
;
; (esi=numeric string) (eax=new position, cf=error)
GotoFilePos:
    cmp word [esi],"lr"
    je .RomBank

    cmp word [esi],"bg"
    je .Bg

.Absolute:
    mov ecx,NumStringMaxLen
    movzx ebx,byte [ViewWindow.PosRadix];decimal or hex
    call StringToNum.AnyRadix
    jz .Error                       ;string was null
.RelativePos:
    test byte [ViewWindow.Options],ViewWindow.UseOffsetBase
    jz .End
    add eax,[ViewWindow.FileOffsetBase]
.End:
    ret
.Error:
    stc
    ret

.RomBank:
    mov ebx,16                      ;ROM bank addresses are in hex
    mov ecx,NumStringMaxLen
    add esi,byte 2
    call StringToNum.AnyRadix
    jz .Error                       ;string was null
    shl ax,1                        ;(bank \ 2) | (offset & 7FFFh)
    shr eax,1
    jmp short .RelativePos

.Bg:
    movzx ebx,byte [esi+2]
    sub bl,'1'
    cmp bl,3                        ;bg's can be 1-4 (plane 0-3)
    ja .Error                       ;illegal bg
    ;cmp byte [File.Type],File.Type_Zst
    ;jne .Error
    mov dl,[BgBitdepths+ebx]
    test dl,dl
    jz .Error
    mov [Vram.Bitdepth],dl
    mov al,[BgTileFormats+ebx]      ;get tile format of selected bg
    mov ecx,[BgTileBases+ebx*4]     ;get tile graphics base
    push dword [BgMapBases+ebx*4]   ;map base
    mov [Vram.Base],ecx
    mov [Vram.TileFormat],al
    mov ecx,32                      ;most bg's use blocks of 32x32
    cmp al,TileFormat.SnesMode7
    jne .NotMode7
    mov ecx,128                     ;mode 7 uses 128 unit wrap
.NotMode7:
    mov dword [FileTiles.SrcWrap],ecx
    mov eax,[FileTiles.Bits]
    cmp eax,16
    je .TileBitsAlreadySet
    mov [FileTiles.PrevBits],eax
    mov dword [FileTiles.Bits],16
  .TileBitsAlreadySet:
    mov byte [FileTiles.Orientation],0
    mov dword [FileTiles.Expander],ExpandTileUnit.WordLh
    mov byte [ViewWindow.Change],WindowRedraw.Complete
    test byte [Vram.Options],Vram.Loaded
    jz .VramNotLoaded
    and byte [Vram.Options],~Vram.Cached
    mov al,TileFormat.Vram
    mov edi,FileTiles
    call SetTileFormat
  .VramNotLoaded:
    pop eax                         ;pop saved map base
    add eax,134163                  ;offset of VRAM in ZSNES savestate
    ret ;() (eax=new file offset)


;------------------------------
; () ()
KeyHelp:
    call .RedrawFullScreen
    call MainLoop.GetMessageHandler
    mov [.PreviousRoutine],eax
    mov eax,KeyHelp.MessageHandler
    jmp MainLoop.SetMessageHandler
    ;ret

.MessageHandler:
    cmp ebx,MainLoopMessageType.Key
    je .KeyPressed
    cmp ebx,MainLoopMessageType.Redraw
    je .RedrawFullScreen
    ;cmp ebx,MainLoopMessageType.Rest
    ;jne .End
    test byte [.Change],-1
    jnz near .RedrawHelpPage
.End:
    ret

.KeyPressed:
    test al,al
    jnz .Done
    mov ecx,1                       ;row down (forward)
    cmp ah,'P'
    je .ScrollHelpPage
    neg ecx                         ;row up (backward)
    cmp ah,'H'
    je .ScrollHelpPage
    mov ecx,22                      ;page down (forward)
    cmp ah,'Q'
    je .ScrollHelpPage
    neg ecx                         ;page up (backward)
    cmp ah,'I'
    jne .Done
.ScrollHelpPage:
    mov esi,Text.KeyHelp
    mov edi,[.HelpTextPtr]
    call ControlStringSeekRow.Relative
    mov [.HelpTextPtr],esi
    mov byte [.Change],-1
    ret
.Done:
    mov eax,[.PreviousRoutine]
    call MainLoop.SetMessageHandler  ;restore old routine and return there
    mov eax,[.PreviousRoutine]
    mov ebx,MainLoopMessageType.Redraw
    jmp eax
    ;ret

;Public function () ()
.RedrawFullScreen:
    mov eax,GuiColorBackDword
    call ClearScreen

    push dword (Screen.DefaultHeight-8)|((Screen.DefaultWidth-8)<<16)    ;height/width
    push dword 4|(4<<16)        ;top/left
    call DrawBorder
    add esp,byte 8
    jmp short .RedrawHelpText   ; skip DrawBox since already filled by ClearScreen.

.RedrawHelpPage:
    push dword GuiColorBack      ;color
    push dword (Screen.DefaultHeight-6-6)|((Screen.DefaultWidth-8)<<16) ;height/width
    push dword 6|(4<<16)       ;row/col
    call DrawBox
    add esp,byte 12
.RedrawHelpText:
    push dword ((Screen.DefaultHeight-6-6) / (GuiFont.GlyphPixelHeight+1)) | (((Screen.DefaultWidth-4-4) / (GuiFont.GlyphPixelWidth+1))<<16) ;height/width in chars
    ;push dword 19|(6<<16)       ;row/col
    push dword 6|(6<<16)       ;row/col
    push dword [.HelpTextPtr];Text.KeyHelp
    call PrintControlString
    mov byte [.Change],0
    add esp,byte 12
    jmp DisplayToScreen
    ;ret

section data
align 4
.ReturnTo:          dd 0
.PreviousRoutine:   dd 0
.HelpTextPtr:       dd Text.KeyHelp
.Change:            db -1
section code

;(esi=control string ptr) (esi=ptr to new position)
;Returns pointer within control string to specified row or label.
ControlStringSeekRow:
;(esi, ecx=new row)
.Absolute:
;(esi, edi=previous ptr, ecx=rows from current row)
.Relative:
    dec ecx
    ;jc .End                 ;end if rows was zero
    js .FindBackwards       ;work backwards
.FindForwards:
    mov esi,edi
.FindForNext:
    mov al,[edi]
    inc edi
    test al,al
    jz .EndForFind
    cmp al,SccCr
    jne .FindForNext
    mov esi,edi
    dec ecx
    jns .FindForNext
    clc
    ret
.EndForFind:
    stc
    ret
.FindBackwards:;.FindBackNext:
    cmp edi,esi
    jbe .EndBackFind
    dec edi
    cmp byte [edi],SccCr
    jne .FindBackwards
    inc ecx
    js .FindBackwards
    lea esi,[edi+1]
    clc
    ret
.EndBackFind:
    cmp ecx,-1
    ret
;(esi, ecx=four character label)
;.Label:
;.End:
;    ret

;------------------------------
%if 0
StartKeyWait:
    call MainLoop.GetMessageHandler
    mov [.PreviousRoutine],eax
    mov ebx,[esp]
    mov eax,StartKeyWait.Wait
    mov [.ReturnTo],ebx
    jmp MainLoop.SetMessageHandler
    ;ret
.Wait:
    call GetKeyPress
    jc .Return
    ;clc
    ret
.Return:
    mov eax,[.PreviousRoutine]
    call MainLoop.SetMessageHandler
    jmp dword [.ReturnTo]

section data
.ReturnTo:       dd 0
.PreviousRoutine:dd 0
section code
%endif

;------------------------------
RedrawViewingWindowPage:
    debugwrite "RedrawViewingWindowPage"
    mov eax,GuiColorBackDword
    call ClearScreen

    push dword ViewWindow.Height|(ViewWindow.Width<<16)
    push dword 4|(4<<16)
    call DrawBorder
    ;add esp,byte 8

    push dword 9|((Screen.DefaultWidth-8)<<16)
    push dword (Screen.DefaultHeight-13)|(4<<16)
    call DrawBorder
    ;add esp,byte 8
    add esp,byte 8+8
    ret

;------------------------------
RedrawViewingWindow:
    debugwrite "RedrawViewingWindow"
    mov bl,[ViewWindow.Change]
    cmp bl,WindowRedraw.StatusBar
    jbe near .StatusBar
    cmp bl,WindowRedraw.SizeChange
    jb .ViewWindow

    debugwrite "RedrawViewingWindow/DrawBorder"
    call BlitTiles.Resize
    call BlitTiles.DrawBorder

.ViewWindow:
    ;**for now just redraw entire screen.
    ;figure out if window has completely changed or simply moved.
    ;if it has merely been moved, then the existing tiles onscreen can
    ;just be scrolled, with only the new portions being redrawn.
    ;after the height has been determined, the total byte size is
    ;calculated based on it and the current wrap.
    ;then it checks if the area to be redrawn has its information in the
    ;buffer. if not, then it refreshes the buffer.
    ;then set .TileSource of BlitTiles to FilePosition - BufferBase
    mov esi,[ViewWindow.FilePosition]
    mov ebx,[File.BufferBase]
    mov ecx,[FileTiles.SrcRange]  ;get window byte range
    cmp esi,ebx             ;check that needed data is not before buffer
    jb .RefreshBuffer       ;it is so refresh
    add ebx,File.BufferByteSize ;get end of buffer
    sub ebx,ecx             ;get byte after last in needed range
    cmp esi,ebx             ;check that needed data is not after buffer
    jb .AfterRefresh        ;it is not
.RefreshBuffer:
    call RefreshFileBuffer
.AfterRefresh:

    mov eax,[ViewWindow.FilePosition]
    sub eax,[File.BufferBase]
    add eax,File.Buffer
    mov [FileTiles.SrcPtr],eax

    debugwrite "RedrawViewingWindow/BlitTiles"
    call BlitTiles

.StatusBar:
    mov byte [NumToString.FillChar],' '

    mov eax,[ViewWindow.FilePosition]
    movzx ebx,byte [ViewWindow.PosRadix]
    mov edx,'    '
    mov edi,StatusBar.Pos+1
    test byte [ViewWindow.Options],ViewWindow.UseOffsetBase
    jz .NoOffsetBase
    sub eax,[ViewWindow.FileOffsetBase]
    mov edx,'  r '
  .NoOffsetBase:
    cmp bl,10
    je .PosInDec
    mov dh,'h'
  .PosInDec:
    mov dl,[FileTiles.SrcBit]
    add dl,'0'
    mov ecx,8
    mov [edi+9],edx
    call NumToString.AnyRadix
    stosb
    mov [StatusBar.Pos+ecx],byte '@'

    mov eax,[FileTiles.SrcWrap]
    mov edi,StatusBar.Wrap+1
    mov ecx,3
    call NumToString.AnyLength
    stosb
    mov [StatusBar.Wrap+ecx],byte 'x'

    mov eax,[FileTiles.Bits]
    mov edi,StatusBar.Bits+1
    mov ecx,2
    call NumToString.AnyLength
    stosb
    mov [StatusBar.Bits+ecx],byte '#'
    test byte [FileTiles.Orientation],BlitTileStruct.BackwardsEndian
    mov dl,'+'
    jz .LittleEndian
    mov dl,'-'
  .LittleEndian:
    mov [StatusBar.Bits+3],dl

;    mov esi,Text.StatusBar_Absolute
;    test byte [ViewWindow.Options],ViewWindow.UseOffsetBase
;    jz .ViewingAbsolute
;    mov esi,Text.StatusBar_Relative
;  .ViewingAbsolute:
;    mov ebx,21|(8<<8)
;    mov edi,Text.StatusBar+15
;    mov ecx,4
;    call .CopyStatusBarString

    ; show mask & shift
    mov eax,[FileTiles.Mask]
    mov ebx,16
    mov ecx,4
    mov edi,StatusBar.Mask+1
    call NumToString.AnyRadix
    stosb
    mov [StatusBar.Mask+ecx],byte '&'

    movzx eax,byte [FileTiles.Shift]
    mov ecx,2
    mov edi,StatusBar.Shift+2
    call NumToString.AnyLength
    stosb
    stosb
    mov [StatusBar.Shift+ecx],word '>>'

    call .StatusBarClearBackground

    push dword (StatusBar.PixelY)|(StatusBar.PixelX<<16)  ;row/col
    push dword StatusBar
    mov byte [PrintCharString.Color],GuiColorText
    call PrintCharStringStd
    add esp,byte 8
.End:
    ;copy buffer to display
    debugwrite "RedrawViewingWindow.End"
    call DisplayToScreen

    ret

.StatusBarClearBackground:
    debugwrite ".StatusBarClearBackground"
    push dword GuiColorBack  ;color
    push dword StatusBar.PixelHeight|((StatusBar.PixelWidth)<<16) ;height/width
    push dword (StatusBar.PixelY)|(StatusBar.PixelX<<16)  ;row/col
    call DrawBox
    add esp,byte 12
    ret

;----------------------------------------
;(esi=ptr to title, edi=destination, ecx=maximum buffer size including null)
CopyNullTerminatedString:
    push esi
    push edi
    test ecx,ecx
    lea edx,[edi+ecx-1]                 ;save end of buffer for later
    jz .EmptyDestination
.Continue:
    mov al,[esi]
    inc esi
    test al,al
    mov [edi],al
    jz .Null
    inc edi
    dec ecx
    jnz .Continue
    jmp short .End
.Null:
    ;fill in remaining destination with zeroes.
    mov [edi],al
    inc edi
    dec ecx
    jnz .Null
.End:
    mov byte [edx],0                    ;ensure null terminated regardless of source
.EmptyDestination:
    pop edi
    pop esi
    ret

%if 0
.CopyStatusBarString:
    cld
    movzx edi,bl
    movzx ecx,bh
    add edi,Text.StatusBar
    rep movsb
    ret
%endif

;----------------------------------------
;(esi=ptr to title) (esi=string, cf=cancel)
ViewingWindowPrompt:
    cld
    mov edi,CharStrBuffer
    mov ecx,CharStrBuffer_Len
    call CopyNullTerminatedString

    call RedrawViewingWindow.StatusBarClearBackground

    push dword CharStrBuffer_Len<<8 ;maxlength and zero default length
    push dword StatusBar.PixelY|(StatusBar.PixelX<<16) ;row/col
    push dword CharStrBuffer
    call Mouse.Hide
    call GetUserString
    pushf                       ;save cf for Escape and zf for null string
    call Mouse.Show
    mov byte [ViewWindow.Change],WindowRedraw.StatusBar
    mov esi,CharStrBuffer       ;return pointer to text
    popf
    lea esp,[esp+12]
    ret

;----------------------------------------
; Given a source unit buffer, source expander, tile blitter, and destination
; buffer, it will blit a grid of tiles. That destination buffer be off screen,
; or directly to the screen. This routine can only handle 32bit source units,
; so all bitsizes (1,2,4,8,16bit) are converted up to dwords first before
; blitting by the expander routine. Bit masking and shifting are also
; simultaneously applied here. Then each unit is read and passed directly to
; the blitter which will display the data unit, differently depending on the
; current tile format. Whether shown as a color block, number, font character,
; graphic tile, or other form is completely up to the called routine.
;
; For the fastest blitting time, called routines are allowed to use all the
; registers (eax-edx,esi,edi,ebp, but no segment regs) without needing to
; restore them upon return.
;
; Available colormapping should someday include addition and palette table.
; The table is very slow but produces the best looking results. No
; colormapping at all may result in a few odd colors, but is the fastest
; method.
;
BlitTiles:
section data
; Except for .InfoPtr (which points to the current BlitTileStruct structure),
; all these are temporary variables used in the loop. Each call, their values
; are either copied directly from or calculated from the current
; BlitTileStruct.
 align 4
.InfoPtr:       dd FileTiles
.Blitter:       dd BlitTile.ColorBlocks ;routine called to show tiles
.Expander:      dd ExpandTileUnit.Byte
.SrcRowPtr:     dd File.Buffer  ;source of tiles
.Mask:          dd 65535        ;2^16-1
.Shift:         dd 0
.SrcBit         equ .Shift+1
.DestPtr:
.DestRowPtr:    dd 0            ;address of current row
.Cols:          dd 32           ;columns per row
.RowsLeft:      dd 20           ;rows remaining in loop
.ColsLeft:      dd 32           ;columns remaining in loop
.SrcPtr:        dd File.Buffer  ;source of tiles
.SourceWrap:    dd 32           ;wrap width of tilemap
.DestHeight:    dd 100          ;active area of visible window
.DestWidth:     dd 200          ;active area of visible window
.DestColInc:    dd 4            ;bytes to next tile (tilewidth)
.DestRowInc:    dd Screen.DefaultWidth*4 ;bytes between rows (destwrap * tileheight)
.DestWrap:      dd Screen.DefaultWidth ;pixel wrap to next row in destination
section code

    ; Reinitialize values
    mov esi,[.InfoPtr]
    MovDwordViaEax [.Blitter],[esi+BlitTileStruct.Blitter]
    MovDwordViaEax [.Expander],[esi+BlitTileStruct.Expander]
    MovDwordViaEax [.SrcRowPtr],[esi+BlitTileStruct.SrcPtr]
    MovDwordViaEax [.Mask],[esi+BlitTileStruct.Mask]
    MovDwordViaEax [.Shift],[esi+BlitTileStruct.Shift]
    MovDwordViaEax [.DestRowPtr],[esi+BlitTileStruct.DestPtr]
    MovDwordViaEax [.Cols],[esi+BlitTileStruct.Cols]
    MovDwordViaEax [.RowsLeft],[esi+BlitTileStruct.Rows]

    mov esi,[.InfoPtr]
    movzx eax,byte [esi+BlitTileStruct.Height]    ;get tile height
    ;next row = tileheight * destination_width (320 for the screen)
    imul dword [esi+BlitTileStruct.DestWrap]
    movzx ebx,byte [esi+BlitTileStruct.Width]
    test byte [esi+BlitTileStruct.Orientation],1
    jz .NormalOrientation
    xchg eax,ebx                    ;swap row and column increments
  .NormalOrientation:
    mov [.DestRowInc],eax           ;bytes to next tile row
    mov [.DestColInc],ebx           ;bytes to next column

    ;movzx ebx,byte [BlitTiles.TileWidth]
    ;imul ebx,dword [BlitTiles.Cols] ;boxwidth=tilewidth*columns
    ;mov [.DestWidth],ebx

    mov eax,[esi+BlitTileStruct.SrcWrap]
    %if Safety
      cmp eax,ViewWindow.MaxTileWrap
      jbe .ok
      int3
     .ok:
    %endif
    imul dword [esi+BlitTileStruct.Bits]  ;wrap * unitsize
    mov [.SourceWrap],eax   ;store source bit wrap

    push ebp                ;save base pointer since routine might not
    call [esi+BlitTileStruct.Init] ;allow output routine the chance to do any-
                            ;thing it might need to before being called.
.NextRow:
    mov ebx,[.Cols]
    mov esi,[.SrcRowPtr]    ;get source address
    mov edi,BlitTilesBuffer ;buffer to expand source units into 1k dwords
    mov [.ColsLeft],ebx     ;set column count for inner loop
    mov edx,[.Mask]         ;select only desired bits
    mov [.SrcPtr],edi       ;set buffer as source for inner loop
    mov ecx,[.Shift]        ;get amount to shift value by and source bit
    call [.Expander]        ;the expander not only expands smaller unit sizes
    mov edi,[.DestRowPtr]   ;grab destination for output routine

.NextCol:                   ; to dwords, but also applies masking and shifting
    mov esi,[.SrcPtr]       ;get source address
    push edi                ;save destination before call
    mov eax,[esi]           ;get next unit
    call [.Blitter]         ;jump directly to output routine
    pop edi
    add dword [.SrcPtr],byte 4 ;next dword
    add edi,[.DestColInc]
    dec dword [.ColsLeft]
    jg .NextCol

    ;add wrap to source
    ;move screen output to next line

    movzx eax,byte [.SrcBit]
    mov edi,[.DestRowPtr]
    add eax,[.SourceWrap]   ;add source bit increment
    mov esi,eax             ;copy source increment
    and eax,7               ;limit source bit offset 0-7
    shr esi,3               ;get source address byte increment
    add edi,[.DestRowInc]
    mov [.SrcBit],al        ;set bit offset for next row
    add [.SrcRowPtr],esi    ;move one row down in source
    mov [.DestRowPtr],edi   ;move screen destination down tileheight*destwidth
    dec dword [.RowsLeft]
    jg near .NextRow
    pop ebp

    ;colormap here, or do whatever else needs to be done
.End:
    ret

.Resize:
    mov esi,[.InfoPtr]

    mov ecx,[esi+BlitTileStruct.SrcWrap]

    mov eax,[esi+BlitTileStruct.DestHeight]
    movzx ebx,byte [esi+BlitTileStruct.Height]
    xor edx,edx
    ;test ebx,ebx            ;test for division by zero
    ;jz near .End            ;!
    div ebx                 ;Rows = WindowHeight \ TileHeight
    test byte [esi+BlitTileStruct.Orientation],1
    jz .NormalRows
    cmp eax,ecx             ;check if Rows is greater than UnitWrap
    jb .RowsWithinWrap      ;Rows < UnitWrap
    mov eax,ecx             ;So set Rows to UnitWrap
  .RowsWithinWrap:
    mov [esi+BlitTileStruct.Cols],eax
    jmp short .SidewaysRows
  .NormalRows:
    mov [esi+BlitTileStruct.Rows],eax
  .SidewaysRows:
    imul ebx                ;window pixel height = TileHeight * rows
    mov [.DestHeight],eax

    mov eax,[esi+BlitTileStruct.DestWidth]
    movzx ebx,byte [esi+BlitTileStruct.Width]
    xor edx,edx
    ;test ebx,ebx            ;test for division by zero
    ;jz near .End            ;!
    div ebx                 ;Cols = WindowWidth \ TileWidth
    test byte [esi+BlitTileStruct.Orientation],1
    jnz .SidewaysCols
    cmp eax,ecx             ;check if Cols is greater than UnitWrap
    jb .ColsWithinWrap      ;Cols < UnitWrap
    mov eax,ecx             ;So set Cols to UnitWrap
  .ColsWithinWrap:
    mov [esi+BlitTileStruct.Cols],eax
    jmp short .NormalCols
  .SidewaysCols:
    mov [esi+BlitTileStruct.Rows],eax
  .NormalCols:
    imul ebx                ;window pixel width = TileWidth * columns
    mov [.DestWidth],eax

    mov eax,[esi+BlitTileStruct.Rows]
    imul dword [esi+BlitTileStruct.Bits]  ;(rows * bits) * unitwrap
    imul ecx
    shr eax,3                   ;convert bits to bytes
    mov [esi+BlitTileStruct.SrcRange],eax  ;set window byte range

    ret

.DrawBorder:
    mov esi,[.InfoPtr]
    mov ecx,[esi+BlitTileStruct.DestWidth]
    mov edi,[.DestWidth]
    sub ecx,edi
    jbe .NoSideBorder
    mov edx,[esi+BlitTileStruct.DestWrap]
    shrd ebx,ecx,16         ;set box width
    add edi,[esi+BlitTileStruct.DestPtr]  ;left side of box
    sub edx,ecx             ;get wrap (destwrap - boxwidth)
    mov bx,[esi+BlitTileStruct.DestHeight]
    mov eax,(GuiColorBack<<8)+(GuiColorBack<<24)
    call DrawPatternBox.ByReg
  .NoSideBorder:

    mov esi,[.InfoPtr]
    mov ecx,[esi+BlitTileStruct.DestHeight]
    mov edi,[.DestHeight]
    sub ecx,edi
    jbe .NoBottomBorder
    mov edx,[esi+BlitTileStruct.DestWrap]
    mov ebx,[esi+BlitTileStruct.DestWidth]  ;get box width
    imul edi,edx                    ;DestHeight * DestWrap
    sub edx,ebx                     ;get wrap (destwrap - boxwidth)
    add edi,[esi+BlitTileStruct.DestPtr]  ;top row of box
    shl ebx,16                      ;set box width
    mov eax,(GuiColorBack<<8)+(GuiColorBack<<24)
    mov bx,cx                       ;set box height
    call DrawPatternBox.ByReg
  .NoBottomBorder:

    ret


;----------------------------------------
ExpandTileUnit:
;Lh means from low to high, or from least significant bit to most.
;Hl means high to low, or reverse order (backwards endian).

;(esi=packed source, edi=expanded destination, cl=unit shift, ch=bit offset, ebx=count, edx=mask)
.DwordLh:
    xor eax,eax
.NextDwordLh:
    lodsd
    shr eax,cl
    and eax,edx
    stosd
    dec ebx
    jg .NextDwordLh
    ret

;(esi=packed source, edi=expanded destination, cl=unit shift, ch=bit offset, ebx=count, edx=mask)
.DwordHl:
    xor eax,eax
.NextDwordHl:
    lodsd
    bswap eax
    shr eax,cl
    and eax,edx
    stosd
    dec ebx
    jg .NextDwordHl
    ret

; For word tilemaps or unicode text
;(esi=packed source, edi=expanded destination, cl=unit shift, ch=bit offset, ebx=count, edx=mask)
.WordLh:
    xor eax,eax
    and edx,0FFFFh          ;limit mask 0-65535
.NextWordLh:
    lodsw
    shr eax,cl
    and eax,edx
    stosd
    dec ebx
    jg .NextWordLh
    ret

; For those funky big endian processors, or for reversed short integers like
; those found in the headers of MIDI files.
;(esi=packed source, edi=expanded destination, cl=unit shift, ch=bit offset, ebx=count, edx=mask)
.WordHl:
    xor eax,eax
    and edx,0FFFFh          ;limit mask 0-65535
.NextWordHl:
    lodsw
    xchg al,ah
    shr eax,cl
    and eax,edx
    stosd
    dec ebx
    jg .NextWordHl
    ret

; For byte tilemaps or ASCII text
;(esi=packed source, edi=expanded destination, cl=unit shift, ch=bit offset, ebx=count, edx=mask)
.Byte:
    xor eax,eax
    and edx,0FFh            ;limit mask 0-255
.NextByte:
    lodsb
    shr eax,cl
    and eax,edx
    stosd
    dec ebx
    jg .NextByte
    ret

;(esi=packed source, edi=expanded destination, cl=unit shift, ch=bit offset, ebx=count, edx=mask)
.NybbleLh:
    xor eax,eax
    mov dh,0Fh
    shr dh,cl
    and dl,dh                   ;limit mask 0-15
    cmp ch,4
    jb .NextNlh
    lodsb
    jmp short .SecondNlh
.NextNlh:
    lodsb
    shr al,cl
    mov dh,al
    and al,dl
    stosd
    dec ebx
    jle .NlhEnd
    mov al,dh
.SecondNlh:
    shr al,4
    and al,dl
    stosd
    dec ebx
    jg .NextNlh
.NlhEnd:
    ret

; For 4bit bitmaps or icons
;(esi=packed source, edi=expanded destination, cl=unit shift, ch=bit offset, ebx=count, edx=mask)
.NybbleHl:
    xor eax,eax
    mov dh,0Fh
    shr dh,cl
    and dl,dh                   ;limit mask 0-15
    cmp ch,4
    jb .NextNhl
    lodsb
    shr al,cl
    and al,dl
    jmp short .SecondNhl
.NextNhl:
    lodsb
    shr al,cl
    mov dh,al
    shr al,4
    and al,dl
    stosd
    dec ebx
    jle .NhlEnd
    and dh,dl
    mov al,dh
.SecondNhl:
    stosd
    dec ebx
    jg .NextNhl
.NhlEnd:
    ret

; Possibly useful for Virtual Boy gfx
;(esi=packed source, edi=expanded destination, cl=unit shift, ch=bit offset, ebx=count, edx=mask)
.DbitLh:
    xor eax,eax
    mov dh,03h
    lodsb                       ;get first byte
    shr dh,cl
    shr al,cl
    and dl,dh                   ;limit mask 0-3
    mov dh,al                   ;copy byte to spare
    cmp ch,2                    ;if bit offset 0-1
    jb .Dblh1
    cmp ch,4                    ;bit offset 2-3
    jb .Dblh2
    cmp ch,6                    ;if bit offset 4-5
    jb .Dblh3
    jmp short .Dblh4            ;else bit offset 6-7
.DblhNext:
    lodsb
    shr al,cl
    mov dh,al
.Dblh1:
    and al,dl
    stosd
    dec ebx
    jle .DblhEnd
    mov al,dh
.Dblh2:
    shr al,2
    and al,dl
    stosd
    dec ebx
    jle .DblhEnd
    mov al,dh
.Dblh3:
    shr al,4
    and al,dl
    stosd
    dec ebx
    jle .DblhEnd
    mov al,dh
.Dblh4:
    shr al,6
    and al,dl
    stosd
    dec ebx
    jg .DblhNext
.DblhEnd:
    ret

; Possibly useful for Windows CE 4-color bitmaps.
;(esi=packed source, edi=expanded destination, cl=unit shift, ch=bit offset, ebx=count, edx=mask)
.DbitHl:
    xor eax,eax
    mov dh,03h
    lodsb                       ;get first byte
    shr dh,cl
    shr al,cl
    and dl,dh                   ;limit mask 0-3
    mov dh,al                   ;copy byte to spare
    cmp ch,2                    ;if bit offset 0-1
    jb .Dbhl1
    cmp ch,4                    ;bit offset 2-3
    jb .Dbhl2
    cmp ch,6                    ;if bit offset 4-5
    jb .Dbhl3
    jmp short .Dbhl4            ;else bit offset 6-7
.DbhlNext:
    lodsb
    shr al,cl
    mov dh,al
.Dbhl1:
    shr al,6
    and al,dl
    stosd
    dec ebx
    jle .DbhlEnd
    mov al,dh
.Dbhl2:
    shr al,4
    and al,dl
    stosd
    dec ebx
    jle .DbhlEnd
    mov al,dh
.Dbhl3:
    shr al,2
    and al,dl
    stosd
    dec ebx
    jle .DbhlEnd
    mov al,dh
.Dbhl4:
    and al,dl
    stosd
    dec ebx
    jg .DbhlNext
.DbhlEnd:
    ret

;(esi=packed source, edi=expanded destination, cl=unit shift, ch=bit offset, ebx=count, edx=mask)
.BitLh:
    xor eax,eax
    movzx ecx,ch                ;copy source bit offset
    mov dh,[esi]                ;get first eight bits
    shr dh,cl                   ;preshift for source bit offset
    neg ecx                     ;negate bit offset so that bits remaining = 8 - bit offset
    add ecx,byte 8              ;assume a full byte remains
    sub ebx,ecx                 ;bits left >= 8
    jge .BlhNext
    add ecx,ebx                 ;less than eight bits remaining
    jmp short .BlhNext
.BlhNextByte:
    mov dh,[esi]                ;get next eight bits
.BlhNext:
    shr dh,1
    setc al
    stosd
    dec ecx
    jg .BlhNext
    add ecx,byte 8              ;assume a full byte remains
    inc esi
    sub ebx,ecx                 ;bits left >= 8
    jge .BlhNextByte
    add ecx,ebx                 ;less than eight bits remaining
    jg .BlhNextByte
.BlhEnd:
    ret

;(esi=packed source, edi=expanded destination, cl=unit shift, ch=bit offset, ebx=count, edx=mask)
.BitHl:
    xor eax,eax
    movzx ecx,ch                ;copy source bit offset
    mov dh,[esi]                ;get first eight bits
    shl dh,cl                   ;preshift for source bit offset
    neg ecx                     ;negate bit offset so that bits remaining = 8 - bit offset
    add ecx,byte 8              ;assume a full byte remains
    sub ebx,ecx                 ;bits left >= 8
    jge .BhlNext
    add ecx,ebx                 ;less than eight bits remaining
    jmp short .BhlNext
.BhlNextByte:
    mov dh,[esi]                ;get next eight bits
.BhlNext:
    shl dh,1
    setc al
    stosd
    dec ecx
    jg .BhlNext
    add ecx,byte 8              ;assume a full byte remains
    inc esi
    sub ebx,ecx                 ;bits left >= 8
    jge .BhlNextByte
    add ecx,ebx                 ;less than eight bits remaining
    jg .BhlNextByte
.BhlEnd:
    ret

.SetBits:
; (al=bits, edi=BlitTileStruct structure)
    cmp al,32                   ;is number of bits valid
    ja .End
    test al,al
    jz .End
    movzx eax,al
    bsf esi,eax
    shl esi,1                   ;*2 for every even/odd .ExpanderJtbl entry
    test byte [edi+BlitTileStruct.Orientation],BlitTileStruct.BackwardsEndian  ;check if lh or hl
    jz .UseLh                   ;logical endian
    inc esi                     ;use high/low (backwards endian) instead of low/high routine
.UseLh:
    mov ebx,[.ExpanderJtbl+esi*4] ;get expander routine
    mov [edi+BlitTileStruct.Expander],ebx
    mov [FileTiles.Bits],eax
.End:
    ret

section data
align 4
.ExpanderJtbl:
dd .BitLh,.BitHl
dd .DbitLh,.DbitHl
dd .NybbleLh,.NybbleHl
dd .Byte,.Byte
dd .WordLh,.WordHl
dd .DwordLh,.DwordHl
section code

;----------------------------------------
; Following are a few of the output routines BlitTiles can use.
; They may safely use any general register they need to.
; Registers passed to them include esi=tile source, edi=output destination,
; and eax=tile value at source. The destination is an absolute destination
; rather than a screen position, so that the output routines can also draw to
; off screen buffers rather than directly to the video memory. This will also
; later allow snapshots of the window to be exported to image files.
;
; (esi=source, eax=dword from source, edi=destination buffer)
;
;----------------------------------------
BlitTile:
; This is the default for viewing tiles, simply draws solid blocks of color
.ColorBlocksTable:
    mov ebx,eax
    and eax,1023
    shr ebx,6
    mov al,[Vram.TileColors+eax]
    and ebx,0x0070             ;mask only palette bits
    add al,bl
    jmp short .ColorBlocks
.ColorBlocksXor:
    xor al,ah
    jmp short .ColorBlocks
.ColorBlocksAdd:
    add al,ah
    ;jmp short .ColorBlocks
.ColorBlocks:
    mov ah,al
    shrd ebx,eax,16
    shld eax,ebx,16
    mov edx,[BlitTiles.DestWrap]
    mov dword [edi],eax
    mov dword [edi+edx],eax
    lea ebx,[edx*2+edx]
    mov dword [edi+edx*2],eax
    mov dword [edi+ebx],eax
    ret

;----------------------------------------
; (esi=source, eax=dword from source, edi=destination buffer)
; Display little hex numbers with colored backgrounds
.NumericValue:
    ;Clear the background behind the number.
    push edi
    mov esi,SmallHexFont.GlyphPixelHeight+2
    movzx ebx,byte [FileTiles.Width];
    mov edx,[BlitTiles.DestWrap]
    sub edx,ebx
.NextNumBgLine:
    mov ecx,ebx
    rep stosb
    add edi,edx
    dec esi
    jnz .NextNumBgLine
    pop edi

    ;Select glyph color based on how light the background color is.
    ;Add the R G B channels together to gauge lightness (ignoring lower bits)
    mov ecx,eax
    and ecx,255                         ;clamp to palette entry size
    lea ebx,[ecx*2+ecx]
    add ebx,[Display.PalettePtr]
    mov ecx,[ebx]                       ;read BGRA value
    and ecx,00FCFCFCh
    mov ebx,ecx
    shr ebx,8
    add ecx,ebx
    shr ebx,8
    add ecx,ebx
    and ecx,000003FFh
    cmp ecx,(64*3)*1/2
    mov ebx,(GuiColorTop<<16)           ;light gray is a readable default
    jb .NumericValueDimColor
    mov ebx,(GuiColorBack<<16)          ;dark gray is better with light background
.NumericValueDimColor:

;    mov ebx,eax             ;copy color
;    cmp bl,GuiColorBack
;    jne .NumColorOk
;    dec ebx
;  .NumColorOk:
;    shl ebx,16              ;shift color into upper 16 bits
;    or ebx,5|(5<<8)         ;merge character height/width with color
    or ebx,SmallHexFont.GlyphPixelHeight|(SmallHexFont.GlyphPixelWidth<<8);merge character height/width with color
    push ebx                ;save character height/width/color

    ;Convert the value to digits.
    ;(eax=dword tile element from source)
    mov esi,.DigitChars+.DigitCharsMaxCount ;set character destination right justified
    xor ebx,ebx                 ;zero out upper 24 bits of radix
    mov cl,[.NumDigits]         ;get number of digits in number
    mov bl,[.Radix]             ;get binary, decimal, or hex radix
    mov byte [.DigitCounter],cl ;set counter for output loop
  .DivNextChar:
    xor edx,edx                 ;set edx to zero for next division
    dec esi                     ;move backwards one character
    div ebx                     ;divide number by the decimal base
    mov [esi],dl                ;output result
    dec cl                      ;one less character to output
    jnz .DivNextChar

    ;add centered offset to destination
    add edi,[BlitTiles.DestWrap]
    add edi,byte 2              ;move 2 pixels right
  .DrawNextChar:
    mov ebx,[esp]               ;get character height/width/color
    xor eax,eax                 ;cancel out upper 24 bits
    push edi                    ;save screen destination for next loop
    mov al,byte [esi]           ;grab character
    push esi                    ;save current character ptr
    mov edx,[BlitTiles.DestWrap]
    sub edx,byte SmallHexFont.GlyphPixelWidth ;set screen wrap for blit
    imul eax,SmallHexFont.GlyphPixelHeight ;width cancels out because 8-bits per scanline
    lea esi,[SmallHexFont.Chars+eax]
    call FontMonochromeChar
    pop esi
    pop edi
    inc esi                     ;next character
    add edi,byte SmallHexFont.GlyphPixelWidth + 1 ;move right by glyph width in pixel
    dec byte [.DigitCounter]
    jnz .DrawNextChar

    add esp,byte 4              ;release character height/width/color
    ret

;----------------------------------------
.ClearBg:
    ;clear screen with background color
    mov eax,[BlitTiles.DestWidth]
    mov edx,[BlitTiles.DestWrap]
    shrd ebx,eax,16             ;store width in upper 16 bits of ebx
    mov edi,[BlitTiles.DestPtr] ;get buffer destination
    mov bx,[FileTiles.DestHeight] ;set height of box;
    mov al,GuiColorBack         ;set background color behind numbers
    call DrawBox.ByReg
.DoNada:                        ;use tail end of for DoNada
    ret

;----------------------------------------
.CheckVram:
    test byte [Vram.Options],Vram.Cached
    jnz .VramAlreadyCached
    test byte [Vram.Options],Vram.Loaded
    jz .VramNotLoaded
    or byte [Vram.Options],Vram.Cached
    jmp CacheVram
 .VramNotLoaded:
    mov dword [BlitTiles.Blitter],.VramDefault
 .VramAlreadyCached:
    ret

.VramDefault:
    mov esi,.VramDefaultTile
    jmp short .SnesBlank

;   0     1     2       3       4       5       6       7       8       9       ?
;
;         o   o o o   o o     o o o   o o o     o     o   o     o o   o o o   o o
;   o     o       o     o       o       o     o   o   o   o   o   o   o   o     o o
;         o       o     o o     o     o o o   o   o   o o o   o o     o o o   o o

;----------------------------------------
; (esi=source, eax=dword from source, edi=destination buffer)
;.Gbc:
;.SegaGen:
;.SnesM7:
.Gb:;GameBoy tilemap byte, no vh flip, palette, or layer
    shl eax,4
    add eax,[Vram.Base]         ;add either 0 or 800h
    and eax,0FFFh               ;wrap within 256 tiles
    shl eax,2                   ;*64 bytes per tile graphic
    lea esi,[Vram.Buffer+eax]
 .GbBlit:
    mov edx,[BlitTiles.DestWrap]
    mov ecx,8                   ;eight rows to blit
    sub edx,byte 8
 .GbNextRow:
    movsd
    movsd
    add edi,edx
    dec ecx
    jnz .GbNextRow
    ret

;----------------------------------------
; (esi=source, eax=dword from source, edi=destination buffer)
.Nes:
.SnesMode7:
    mov esi,eax
    and esi,255                 ;wrap within 256 tiles
    shl esi,6                   ;*64 bytes per 8x8 tile graphic
    add esi,Vram.Buffer
    jmp short .GbBlit

;----------------------------------------
; (esi=source, eax=dword from source, edi=destination buffer)
.SnesBpl:;SNES tilemap word
    mov esi,eax                 ;get tile address
    and esi,1023
    shl esi,6                   ;*64 bytes per tile graphic
    add esi,Vram.Buffer

.SnesBlank:
    mov ebx,eax
    shr ebx,6
    and ebx,112                 ;get palette
    mov bh,bl                   ;extend palette to word
    shrd ecx,ebx,16
    shld ebx,ecx,16             ;extend palette to dword

    mov edx,[BlitTiles.DestWrap]
    test eax,32768              ;test for vertical tile flip
    jz .SnesNoVflip
    lea edi,[edi+edx*8]         ;move eight rows down
    sub edi,edx                 ;and one back up
    neg edx
.SnesNoVflip:

    mov ecx,8                   ;eight rows to blit
    test eax,16384              ;test for horizontal tile flip
    jnz .SnesNextRowHf

.SnesNextRow:
    mov eax,[esi]
    add eax,ebx
    mov [edi],eax
    mov eax,[esi+4]
    add eax,ebx
    mov [edi+4],eax
    add esi,byte 8
    add edi,edx
    dec ecx
    jnz .SnesNextRow
    ret

.SnesNextRowHf:;horizontal flip
    mov eax,[esi]
    add eax,ebx
    xchg al,ah
    rol eax,16
    xchg al,ah
    mov [edi+4],eax
    mov eax,[esi+4]
    add eax,ebx
    xchg al,ah
    rol eax,16
    xchg al,ah
    mov [edi],eax
    add esi,byte 8
    add edi,edx
    dec ecx
    jnz .SnesNextRowHf
    ret

;----------------------------------------
; (esi=source, eax=dword from source, edi=destination buffer)
.TileTable:
    mov edx,[BlitTiles.DestWrap]
    shl edx,3                   ;*8
    push dword [TileTable.Size] ;save rows/cols
    push edx                    ;save increment to next destination row
    imul dword [TileTable.Inc]  ;get eax * size_per_tile_table
    push edi                    ;save destination
    and eax,32767               ;wrap within 32k
    lea esi,[eax+TileTable]     ;set source
  .TtNextRow:
    .TtNextCol:
        push edi
        push esi
        mov eax,[esi]
        call .SnesBpl
        pop esi
        pop edi
        add esi,byte 2
        add edi,byte 8          ;move right to next tile
        dec byte [esp+9]        ;one less column
        jnz .TtNextCol
      pop edi
      add edi,[esp]             ;move down to next row
      push edi
      mov al,[TileTable.Width]  ;get columns
      mov [esp+9],al            ;reset for next row
      dec byte [esp+8]          ;one less row
      jnz .TtNextRow
    add esp,12
    ret

;----------------------------------------
; (esi=source, eax=dword from source, edi=destination buffer)
.FontChar:
    ;use table to translate character and then blit font
    ;mov ebx,[CharTransTable.Ptr]
    ;mov eax,[ebx+eax]
    ;nop
    movzx eax,al
.FontCharByReg:
    mov ebx,DefaultTileFont.GlyphPixelHeight | (DefaultTileFont.GlyphPixelWidth<<8) | (GuiColorTop<<16);character height/width/color
    ;cmp al,GuiColorTop
    ;jne .FcNotGray
    ;and ebx,00FFFFFFh       ;turn number color from gray number to black
.FcNotGray:
    mov edx,[BlitTiles.DestWrap]
    lea esi,[DefaultTileFont.Chars + eax * (64/8)] ; Should be DefaultTileFont.GlyphPixelCount, not 64 literally, but compiler complains??
    lea edi,[edi+edx+1]     ;start one row down and column over
    sub edx,DefaultTileFont.GlyphPixelWidth ;subtract width of character from DestWrap
    jmp FontMonochromeChar

;----------------------------------------
; (esi=source, eax=dword from source, edi=destination buffer)
.BrrSample:
    ;get range
    ;ignore filter
    ;shift each byte by range
    ;mov esi,[BlitTiles.SrcRowPtr]     ;get true byte source ptr
    mov edx,[BlitTiles.DestWrap]
    mov ebp,edi
    test eax,1                  ;if end of sample
    jz .BrsNotEnd
    add edi,byte 15             ;mark end of sample
    mov ecx,128/2
.BrsNextEndDot:
    mov byte [edi],0Fh          ;draw white dotted line
    lea edi,[edi+edx*2]
    ;add edi,edx
    dec ecx
    jnz .BrsNextEndDot
.BrsNotEnd:
    mov edi,edx                 ;copy dest wrap
    shl edi,6                   ;*64
    add ebp,edi
    mov cl,al                   ;put range from header byte into cl
    mov ch,8                    ;8 bytes, two nybbles each makes 16 samples
    add cl,2<<4
    not cl
    shr cl,4                    ;top four bits down so that shift is now in cl
.BrsNextSample:
    inc esi
    mov bl,[esi]
    mov al,bl
    shl bl,4
    sar al,cl
    sar bl,cl
    and eax,127
    and ebx,127
    mov edi,ebp
    test al,64
    jnz .BrsNextLnS
.BrsNextLnUs:
    mov byte [edi],1
    add edi,edx
    dec al
    jns .BrsNextLnUs
    sub edi,edx
    mov byte [edi],9
    jmp short .BrsLnEnd
.BrsNextLnS:
    sub edi,edx
    mov byte [edi],1
    inc al
    jno .BrsNextLnS
    mov byte [edi],9
.BrsLnEnd:
    inc ebp

    mov edi,ebp
    test bl,64
    jnz .BrsNextHnS
.BrsNextHnUs:
    mov byte [edi],1
    add edi,edx
    dec bl
    jns .BrsNextHnUs
    sub edi,edx
    mov byte [edi],9
    jmp short .BrsHnEnd
.BrsNextHnS:
    sub edi,edx
    mov byte [edi],1
    inc bl
    jno .BrsNextHnS
    mov byte [edi],9
.BrsHnEnd:
    ;imul eax,edx
    ;imul ebx,edx
    ;mov byte [edi+eax],9
    ;inc edi
    ;mov byte [edi+ebx],9
    inc ebp
    dec ch
    jnz .BrsNextSample
    ret

;----------------------------------------
.InitWaveSample:
    mov cl,[FileTiles.Bits];
    mov eax,ecx
    shl eax,3
    mov edx,[BlitTiles.DestWrap]
    and eax,64
    shl edx,6                   ;DestWrap * 64
    mov [.UnitXor],eax          ;for toggling 8bit unsigned
    sub cl,7
    ja .WvsSetUnit
    xor cl,cl
.WvsSetUnit:
    mov [.ScaleShift],cl
    mov [.DestBase],edx
    jmp .ClearBg

;----------------------------------------
; (esi=source, eax=dword from source, edi=destination buffer)
.WaveSample:
    mov cl,[.ScaleShift]
    mov edx,[BlitTiles.DestWrap]
    shr eax,cl
    xor eax,[.UnitXor]          ;for unsigned 8bit sounds
    add edi,[.DestBase]
    test eax,64
    jnz .WvsFirstS
    and eax,127
.WvsNextUs:
    mov byte [edi],1            ;wave center dark blue
    add edi,edx
    dec eax
    jns .WvsNextUs
    sub edi,edx
    mov byte [edi],9            ;wave tip bright blue
    jmp short .WvsEnd
.WvsFirstS:
    or eax,0FFFFFF80h
.WvsNextS:
    sub edi,edx
    mov byte [edi],1            ;wave center dark blue
    inc eax
    js .WvsNextS
    mov byte [edi],9            ;wave tip bright blue
.WvsEnd:
    ret

section data
align 4
.DestBase:      dd 0
.UnitXor:       dd 0
.ScaleShift:
.NumDigits:     db 2
.Radix:         db 16
.DigitCounter:  db 2
.DigitChars:    db '................'
.DigitCharsMaxCount equ 16
.VramDefaultTile:
    db 0, 1, 2, 3, 4, 5, 6, 7
    db 1, 2, 3, 4, 5, 6, 7, 8
    db 2, 3,10, 9, 8, 7, 8, 9
    db 3, 4, 9, 8, 7, 6, 9,10
    db 4, 5, 8, 7, 6, 5,10,11
    db 5, 6, 7, 6, 5, 4,11,12
    db 6, 7, 8, 9,10,11,12,13
    db 7, 8, 9,10,11,12,13,14
.BplTbl1:
.BplTblSnes2:   db 0,1,1,1,1,1,1,1,  1,1,1,1,1,1,1,1
.BplTblNes2:    db 0,8,-7,8,-7,8,-7,8,-7,8,-7,8,-7,8,-7,8,1,8,-7,8,-7,8,-7,8,-7,8,-7,8,-7,8,-7,8
.BplTblSnes3:   db 0,1,15,-14,1,14,-13,1,13,-12,1,12,-11,1,11,-10,1,10,-9,1,9,-8,1,8
.BplTblSnes4:   db 0,1,15,1,-15,1,15,1,-15,1,15,1,-15,1,15,1,-15,1,15,1,-15,1,15,1,-15,1,15,1,-15,1,15,1
.BplTblSnes8:   db 0,1,15,1,15,1,15,1,-47,1,15,1,15,1,15,1,-47,1,15,1,15,1,15,1,-47,1,15,1,15,1,15,1,-47,1,15,1,15,1,15,1,-47,1,15,1,15,1,15,1,-47,1,15,1,15,1,15,1,-47,1,15,1,15,1,15,1
section code

;----------
; Given the mode number, this sets up the necessary variables in BlitTiles
; for it to work right. For example, mumeric display requires that the tile
; width be at least wide enough for the complete number to fit.
;
; (al=mode, edi=BlitTileStruct structure)
SetTileFormat:
    cmp al,TileFormat.Total
    jae .End
    movzx eax,al
.Restart:
    mov [edi+BlitTileStruct.Format],al
    mov ebx,[.BlitterJtbl+eax*4]  ;get format display routine
    mov ecx,[.InitJtbl+eax*4]   ;get display init routine
    mov [edi+BlitTileStruct.Blitter],ebx
    mov [edi+BlitTileStruct.Init],ecx
    jmp [.ModeJtbl+eax*4]       ;do setup now

.ColorBlocks:
    mov word [edi+BlitTileStruct.Size],4|(4<<8)  ;set both height and width
.End:
    ret

; calculate pixel width of number based on current unit size
.NumericValue:
    movzx ebx,byte [BlitTile.Radix]  ;base of the number system
    mov cl,[edi+BlitTileStruct.Bits]
    mov eax,1
    shl eax,cl                  ;create hole of zeroes equal to number of bits
    dec eax                     ;invert low zeroes to ones
    mov ecx,1                   ;number width must be at least one character
    ;and eax,[edi+BlitTileStruct.Mask]
.NvNextDigit:
    xor edx,edx                 ;zero top 32 bits of quotient
    div ebx                     ;divide number by the current radix
    test eax,eax                ;see if we are done with the number
    jz .NvLastDigit             ;nothing but zeroes left
    inc ecx                     ;count an extra character
    cmp ecx,byte 10             ;number must be <=10
    jb .NvNextDigit
.NvLastDigit:
    mov [BlitTile.NumDigits],cl ;save number of digits highest value has
    lea ecx,[ecx*2+ecx]         ;*3
    lea ecx,[ecx*2+4]           ;*2+4  "(ecx*6)+4"
    mov byte [edi+BlitTileStruct.Height],7  ;set tile height
    mov [edi+BlitTileStruct.Width],cl
    ret

.FontChar:
    mov word [edi+BlitTileStruct.Size],(DefaultTileFont.GlyphPixelHeight+1) | ( (DefaultTileFont.GlyphPixelWidth+1)<<8)  ;set both height and width
    ret

; this is really a pseudomode. all it does is jump back to the top to set the
; mode to whatever the last vram mode was.
.Vram:
    mov al,[Vram.TileFormat]
    jmp short .Restart

; set bitplane table, set tile converter
;(eax=TileFormat mode)
.VramBpl:
    mov [Vram.TileFormat],al
    sub eax,byte TileFormat.FirstBplMode
    mov ecx,[.VramBplTbls+eax*4]
    mov dword [Vram.Converter],BitplaneToLinear
    mov [Vram.BplTbl],ecx
    mov word [edi+BlitTileStruct.Size],8|(8<<8)  ;set both height and width
    ret

;(eax=TileFormat mode)
.Mode7Tile:
    mov [Vram.TileFormat],al
    mov dword [Vram.Converter],Mode7ToLinear
    mov word [edi+BlitTileStruct.Size],8|(8<<8)  ;set both height and width
    ret

.TileTable:
    mov eax,[TileTable.Size]    ;get rows/cols
    lea ecx,[eax*8]             ;get table rows/cols * 8
    and ecx,0011100000111000b   ;no tile table larger than 8x8
    mov [edi+BlitTileStruct.Size],cx  ;set both height and width
    imul ah                     ;rows * cols (upper two bytes are zero)
    shl eax,1                   ;*2 since each cell is a word
    mov [TileTable.Inc],eax     ;save increment between tile tables
    ret

.BrrSample:
    ;test orientation
    ;test byte [FileTiles.Orientation],BlitTileStruct.OrientRotate
    ;jnz .HBrrSample
    mov word [edi+BlitTileStruct.Size],128|(16<<8)  ;set both height and width
    ret

.WaveSample:
    ;test orientation
    ;test byte [FileTiles.Orientation],BlitTileStruct.OrientRotate
    ;jnz .HBrrSample
    mov word [edi+BlitTileStruct.Size],128|(1<<8)  ;set both height and width
    ret

;.ActualPixels:
;        mov word [edi+BlitTileStruct.Size],1|(1<<8)  ;set both height and width
;        ret
;.BitplaneTileImage:
;        mov bl,[edi+BlitTileStruct.Height]        ;get tile height
;        mov bh,8                                ;set tile width
;        cmp bl,4                                ;must not be less than 4
;        ja .Bpl_HeightNotUnder                  ;it is more
;        mov bl,4                                ;set height to 4
;    .Bpl_HeightNotUnder:
;        cmp bl,16                               ;must not be more than 16
;        jb .Bpl_HeightNotOver                   ;it is less
;        mov bl,16                               ;set height to 16
;    .Bpl_HeightNotOver:
;        mov [edi+BlitTileStruct.Size],bx
;        mov word [edi+BlitTileStruct.Size],8|(8<<8)  ;set both height and width
;        ret

section data
align 4
.BlitterJtbl:
    dd BlitTile.ColorBlocks
    dd BlitTile.NumericValue
    dd BlitTile.FontChar
    dd BlitTile.DoNada
    dd BlitTile.TileTable
    dd BlitTile.WaveSample;dd BlitTile.BrrSample
    dd BlitTile.SnesBpl
    dd BlitTile.SnesBpl
    dd BlitTile.SnesBpl
    dd BlitTile.Gb
    dd BlitTile.Nes
    dd BlitTile.SnesMode7
.InitJtbl:
    dd BlitTile.DoNada          ;color blocks
    dd BlitTile.DoNada          ;numeric
    dd BlitTile.ClearBg         ;font character
    dd BlitTile.CheckVram       ;vram default
    dd BlitTile.CheckVram       ;tile table
    dd BlitTile.InitWaveSample  ;brr sample ;dd BlitTile.ClearBg
    dd BlitTile.CheckVram       ;snes 2
    dd BlitTile.CheckVram       ;snes 4
    dd BlitTile.CheckVram       ;snes 8
    dd BlitTile.CheckVram       ;gb
    dd BlitTile.CheckVram       ;nes
    dd BlitTile.CheckVram       ;mode 7
.ModeJtbl: ; TileFormat.Total
    dd .ColorBlocks     ;TileFormat.ColorBlocks
    dd .NumericValue    ;TileFormat.NumericValue
    dd .FontChar        ;TileFormat.FontChar
    dd .Vram            ;TileFormat.Vram
    dd .TileTable       ;TileFormat.TileTable
    dd .WaveSample      ;TileFormat.BrrSample
    dd .VramBpl         ;TileFormat.Snes2
    dd .VramBpl         ;TileFormat.Snes4
    dd .VramBpl         ;TileFormat.Snes8
    dd .VramBpl         ;TileFormat.Gb
    dd .VramBpl         ;TileFormat.Nes
    dd .Mode7Tile       ;TileFormat.SnesMode7
.ModeJtblCount equ ($ - .ModeJtbl) / 4 ; Should = TileFormat.Total
;Assertion fails with YASM, even though NASM supports it.
;%if .ModeJtblCount != TileFormat.Total
;  %error "Update .ModeJtbl to match TileFormat.Total"
;%endif
.VramBplTbls:
    dd BlitTile.BplTblSnes2 ;TileFormat.Snes2
    dd BlitTile.BplTblSnes4 ;TileFormat.Snes4
    dd BlitTile.BplTblSnes8 ;TileFormat.Snes8
    dd BlitTile.BplTblSnes2 ;TileFormat.Gb
    dd BlitTile.BplTblNes2  ;TileFormat.Nes
.VramBplTblsCount equ ($ -.VramBplTbls) / 4 ; Should  = TileFormat.LastBplMode - TileFormat.FirstBplMode + 1
    ; SNES Mode 7 is not included in the list as it is not a bitplane mode.
section code

;------------------------------
; Set several variables for the viewing mode, including the tile format,
; wrap width, unit size, orientation...
;
; (esi=format info base ptr, eax=index) ()
SetViewingMode:
    lea esi,[esi+eax*8]
    mov eax,[esi]
    cmp al,TileFormat.Total
    jae .SkipMode
    mov [FileTiles.Format],al
  .SkipMode:
    test ah,ah
    js .SkipUnit
    mov [FileTiles.Bits],ah
  .SkipUnit:
    shr eax,16
    test al,al
    js .SkipWrap
    movzx ebx,al
    mov [FileTiles.SrcWrap],ebx
  .SkipWrap:
    test ah,ah
    js .SkipOrientation
    mov [FileTiles.Orientation],ah
  .SkipOrientation:
    mov al,[FileTiles.Format]
    mov edi,FileTiles
    jmp SetTileFormat
    ;ret

;------------------------------
;(ViewWindow.WriteDataValue, ViewWindow.FilePosition, FileTiles.Bits)
SetViewWindowUnit:
    mov ax,4200h                    ;function to set file position
    mov edx,[ViewWindow.FilePosition]
    mov ebx,[File.Handle]           ;get file handle
    shld ecx,edx,16                 ;set cx to upper word of esi
    int 21h                         ;call DOS
    mov ax,4000h                    ;function to write to file
    ;mov ebx,[File.Handle]           ;viewing file handle
    mov edx,ViewWindow.WriteDataValue;set source data for write
    mov ecx,[FileTiles.Bits]        ;set bytes to write
    shr ecx,3
    jz .End
    int 21h                         ;call DOS
.InBuffer:
    mov esi,[File.BufferBase]
    mov edi,[ViewWindow.FilePosition]
    lea ebx,[esi+File.BufferByteSize]
    cmp edi,ebx
    jae .End
    sub edi,esi
    jb .End
    mov eax,[ViewWindow.WriteDataValue]
    add edi,File.Buffer
    mov bl,[FileTiles.Bits]
    cmp bl,8
    ja .NotByte
    mov [edi],al
    ret
.NotByte:
    cmp bl,16
    ja .NotWord
    mov [edi],ax
.NotWord:
.End:
    ret

;------------------------------
; (esi=new file position, ecx=data size)
; Refills the buffer with the needed part of the file.
; It goes forward when the needed data is after the buffer, and backwards
; when the data was before the buffer.
; Based on the size of the required data string and the direction last taken,
; the routine will either advance completely or only partially in the current
; direction.
;
RefreshFileBuffer:
    ;in the future:
    ;first check that file number is the right one
    ;merge file changes into read data
    cmp esi,[File.BufferBase]
    jb .BeforeBase
    test byte [File.Attribs],File.Atr_Direction     ;was direction last moved forwards?
    jnz .CompleteForwardRefill      ;already moving forward
.PartialForwardRefill:
    or byte [File.Attribs],File.Atr_Direction  ;set last moved direction to forward
    cmp ecx,File.BufferByteSize/2
    jae .CompleteForwardRefill
    lea esi,[esi+ecx-File.BufferByteSize/2]
    %ifdef debug
      mov edx,Text.ForwardPartial
    %endif
.CompleteForwardRefill:
    %ifdef debug
      jmp .ReadinFile
      mov edx,Text.ForwardComplete
    %endif
    jmp .ReadinFile                 ;do nothing, simply leaving esi as is

.BeforeBase:
    test byte [File.Attribs],File.Atr_Direction     ;was direction last moved backwards?
    jz .CompleteBackwardRefill      ;already moving backward
.PartialBackwardRefill:
    and byte [File.Attribs],~File.Atr_Direction     ;set last moved direction to backward
    cmp ecx,File.BufferByteSize/2
    jae .CompleteBackwardRefill
    sub esi,File.BufferByteSize/2
    %ifdef debug
      mov edx,Text.BackwardPartial
    %endif
    jmp .ReadinFile
.CompleteBackwardRefill:
    lea esi,[esi+ecx-File.BufferByteSize]
    %ifdef debug
      mov edx,Text.BackwardComplete
    %endif
    ;jmp .ReadinFile                 ;just fall through

.ReadinFile:
    test esi,esi
    jns .PositionPositive
    xor esi,esi
.PositionPositive:
    mov [File.BufferBase],esi
    mov edx,esi                     ;copy file position to edx
    mov eax,4200h                   ;function to set file position
    mov ebx,[File.Handle]           ;get file handle
    shld ecx,esi,16                 ;set cx to upper word of esi
    int 21h                         ;call DOS
    mov eax,3F00h                   ;function to read file
    mov ebx,[File.Handle]           ;get file handle
    mov ecx,File.BufferByteSize     ;set number of bytes to read
    mov edx,File.Buffer             ;set destination to the file buffer
    int 21h                         ;call DOS
    ret

;------------------------------
; BitplaneToLinear (esi=raw tile source, edi=linear destination, ecx=bitdepth) ()
; No regs preserved, not even ebp
;
; Converts bitplane tiles from VRAM to 8x8 linear bitmaps.
; This routine works for any bitplane mode, including 1,2,3,4, & 8.
; It can even work for NES and GameBoy graphics, with the right table.
;
; Basically this function loops the number of bitplanes that are in the tile,
; ORing each bitplane onto the current pixel row and rolling them until the
; full color depth for eight pixel columns is achieved. This is not the
; fastest code for translation, but it is the most versatile, being able to
; handle any bitplane format without compromising on too much speed.
;
align 16
BitplaneToLinear:
    ;ecx=bitplanes
    ;(ebx=ptr to jump table)
    ;esi=ptr to raw source data
    ;edi=ptr to linear bitmap or screen
    ;edx=bitmap or screen width
    ;ebp is destroyed

    mov ebx,[Vram.BplTbl]
    mov ch,8        ;set row counter to 8 rows

.NextRow:
    ;cl=bitplane counter
    ;ch=data
    ;eax=pixel columns 0-3 of current row
    ;edx=pixel columns 4-7 of current row

    push ecx        ;save bitplanes and row counter
    xor edx,edx
    xor eax,eax     ;set both to zero
.NextBitplane:
    movsx ebp,byte [ebx]    ;move source to next bitplane (same row) using table
    add esi,ebp
    inc ebx         ;next pointer in table
    mov ch,[esi]    ;get next single bitplane row

    test ecx,256
    jz .1
    or edx,01000000h
.1: test ecx,4096
    jz .2
    or eax,01000000h
.2: test ecx,512
    jz .3
    or edx,00010000h
.3: test ecx,8192
    jz .4
    or eax,00010000h
.4: test ecx,1024
    jz .5
    or edx,00000100h
.5: test ecx,16384
    jz .6
    or eax,00000100h
.6: test ecx,2048
    jz .7
    or edx,00000001h
.7: test ecx,32768
    jz .8
    or eax,00000001h
.8: ror edx,1       ;rolling right would reverse the the bits, not desirable
    ror eax,1       ;roll pixels left to not let the next bitplane clobber this one
    dec cl
    jnz .NextBitplane

    pop ecx         ;retrieve bitplanes and row counter
    rol eax,cl      ;compensate for the above ror's by rolling it left by
    rol edx,cl      ;the same number of bitplanes it was rolled right.
    mov [edi],eax   ;write first four left pixels
    mov [edi+4],edx ;write second four right pixels
    ;add edi,[TileDestWidth] ;add bitmap width to dest for next row down
    add edi,byte 8
    dec ch
    jnz near .NextRow
    ret

;------------------------------
; Mode7ToLinear (esi=raw tile source, edi=linear destination) ()
; No regs preserved, not even ebp
;
; Converts SNES mode 7 tiles from VRAM to 8x8 linear bitmaps.
;
Mode7ToLinear:
    mov ecx,32                  ;8*8 pixels / 2 pixels per loop
.Next:
    lodsd
    ror eax,8
    mov ah,al
    ror eax,8
    stosw
    dec ecx
    jnz .Next
    ret

;------------------------------
;(esi=source palette uint16[256], edi=destination uint24[256])
ConvertPaletteSnesToPc:
    mov ecx,256         ;the SNES has a 256-color palette
    cld                 ;as always, go forward
.NextColor:
    lodsw               ;get BGR color tuple (the SNES color is reversed from normal)
    shl eax,3           ;isolate red
    shr al,2            ;divide by factor
    stosb               ;save red to destination
    shr eax,5           ;get green and blue
    and eax,(31<<3)|(31<<8) ;mask out any extra bits
    shl ah,3            ;move blue higher
    shr eax,2           ;divide both by factor
    stosw               ;store green and blue
    dec ecx
    jnz .NextColor
    ret

;------------------------------
CacheVram:
    mov ecx,[Vram.Bitdepth]
    shl ecx,3                       ;*8 to get bytes per tile
    jnz .BitDepthOk
    mov dword [Vram.Bitdepth],4
    mov ecx,4*8
.BitDepthOk:
    cmp byte [Vram.TileFormat],TileFormat.SnesMode7
    jne .NotMode7
    shl ecx,1                       ;*2 for mode 7 (128 bytes per tile)
.NotMode7:
    push ecx                        ;store bytes per tile
    push dword -1024                ;total tiles to convert
    push dword Vram.Buffer          ;destination
    mov esi,[Vram.Base]             ;source, VRAM base for current bg
.NextTile:
    mov edi,[esp]
    push esi
    mov ecx,[Vram.Bitdepth]
    add esi,Vram
    call dword [Vram.Converter]
    ;<-
    mov esi,[esp+4]                 ;use tile just converted to cache as source
    call CountTileColors            ;() (al=color index most frequently encountered)
    mov ebx,[esp+8]                 ;get current tile - 1024
    mov [Vram.TileColors+1024+ebx],al
    ;->
    pop esi

    add dword [esp],byte 64         ;next 8x8 tile in cache destination
    add si,[esp+8]                  ;next tile in VRAM (wrap in 64k)
    inc dword [esp+4]               ;one less tile
    jl .NextTile
    add esp,byte 12
    ret

;------------------------------
; (esi=8x8 64-byte tile) (al=most frequent color index)
; Finds the most frequent color in an 8x8 tile by counting all the colors
; and returning the one with the highest score. To discourage transparency
; from being returned too often, its score is always halved.
CountTileColors:
    cld
    sub esp,256

    mov edi,esp
    xor eax,eax
    mov ecx,256/4
    rep stosd

    ;build histogram
    mov ecx,63
.NextPix:
    mov al,[esi+ecx]
    inc byte [esp+eax]
    dec ecx
    jns .NextPix

    ;find most frequent color
    shr byte [esp],3            ;occurence for transparent color /8
    xor ebx,ebx                 ;zero color value
    mov ecx,255
    mov eax,ebx                 ;start with transparency as most frequent
.Next:
    cmp [esp+ecx],bl            ;compare current color value to most frequent
    jbe .Less
    mov bl,[esp+ecx]            ;current color is higher, so grab color value
    mov eax,ecx                 ;set most frequent color
.Less:
    dec ecx
    jns .Next

    add esp,256
    ret

%if 0
;------------------------------
FillVramPattern:
    cld
    mov edx,65536/64            ;number of tiles
    mov edi,Vram.Buffer         ;destination
.NextTile:
    mov esi,.DefaultImage
    mov ecx,64/4                ;bytes per image 8*8
    rep movsd
    dec edx
    jnz .NextTile
    ret

.DefaultImage:;a rather generic 'x'
    db 1,1,0,0,0,1,1,0
    db 1,2,1,0,1,2,1,0
    db 0,1,2,1,2,1,0,0
    db 0,0,1,2,1,0,0,0
    db 0,1,2,1,2,1,0,0
    db 1,2,1,0,1,2,1,0
    db 1,1,0,0,0,1,1,0
    db 0,0,0,0,0,0,0,0
%endif

;------------------------------
; Some games like Mario World use tile table that go down/right/down instead
; of the usual right/down/right. For them to be displayed properly, they must
; be set to the down/right/down order.
;
; 1 3  =>  1 2
; 2 4      3 4
;
FlipTileTable:
    mov eax,[TileTable.Size]
    mov ebx,eax
    imul ah                 ;get rows * columns
    and eax,127
    jz near .End            ;prevent division by zero
    mov ecx,eax
    test ebx,10000h
    jnz .UseByteTiles
    shl ecx,1               ;*2 for words
  .UseByteTiles:
    mov eax,32768           ;size of tile table
    xor edx,edx             ;zero upper quotient
    idiv ecx                ;get tiletablesize / tilesize
    dec eax                 ;start out with one less tile
    shl eax,16              ;set loop counter to top word
    mov ax,bx               ;set low word to rows and columns
    mov esi,TileTable
    cld
    test ebx,10000h
    jz .WordTiles

.ByteTiles:
    sub esp,ecx             ;reserve size of one tile on stack
    lea edx,[ecx-1]         ;set to tilesize - 1
    push esi                ;save tile pointer
.NextTileByte:
    lea edi,[esp+4]         ;destination of copy is stack
    mov esi,[esp]           ;get source in TileTable
    lea ecx,[edx+1]         ;get bytes per tile
    rep movsb               ;copy tile to stack

    mov edi,[esp]           ;get current tile ptr
    mov [esp],esi           ;save ptr to tile after current
    lea esi,[esp+4]         ;set source to stack
    mov bl,al               ;set rows
    mov cl,ah               ;set row increment to columns
.NextRowByte:
    mov bh,ah               ;reset columns
.NextColByte:
    movsb                   ;transfer tile table byte
    lea esi,[esi+ecx-1]     ;next row down
    dec bh                  ;one less column
    jnz .NextColByte
    sub esi,edx             ;back to top row
    dec bl                  ;one less row
    jnz .NextRowByte

    sub eax,65536           ;one less tile
    jns .NextTileByte
    lea esp,[esp+edx+1+4]   ;free stack
.End:
    ret

.WordTiles:
    sub esp,ecx
    lea edx,[ecx-2]
    push esi                ;save tile pointer
.NextTileWord:
    lea edi,[esp+4]         ;destination of copy is stack
    mov esi,[esp]           ;get source in TileTable
    lea ecx,[edx+2]         ;get bytes per tile
    rep movsb               ;copy tile to stack

    mov edi,[esp]
    mov [esp],esi
    lea esi,[esp+4]
    mov bl,al               ;set rows
    mov cl,ah               ;set row increment to columns
.NextRowWord:
    mov bh,ah               ;reset columns
.NextColWord:
    movsw                   ;transfer tile table word
    lea esi,[esi+(ecx*2)-2] ;next row down
    dec bh                  ;one less column
    jnz .NextColWord
    sub esi,edx             ;back to top row
    dec bl                  ;one less row
    jnz .NextRowWord

    sub eax,65536           ;one less tile
    jns .NextTileWord
    lea esp,[esp+edx+2+4]   ;free stack
    ret

;--------------------------------------------------
;(edx=text source)
PrintMessage:
    mov ah,9                ;function to print string
    int 21h                 ;call DOS
    xor eax,eax
    int 16h
    ret

;------------------------------
; (edx=screen pos)
; Cheap temporary function.
PrintNum:
.At:                        ;call here to print at a specific location
    push eax                ;save number
    mov ah,2                ;function to set cursor
    xor ebx,ebx             ;page zero
    int 10h                 ;call video BIOS
    pop eax                 ;retrieve number
.AtCsr:                     ;call here to print at cursor location
    movzx ebx,byte [.Radix] ;base of the number system
    mov ecx,10              ;default maximum of ten characters
    mov edi,NumStrBuffer
    call NumToString.AnyRadix
    mov edx,NumStrBuffer
    mov ah,9
    int 21h
    ret

.Radix:         db 10

PrintString:
    push esi                ;save string
    mov ah,2                ;function to set cursor
    xor ebx,ebx             ;page zero
    int 10h                 ;call video BIOS
    pop edx                 ;retrieve string
    mov ah,9
    int 21h
    ret

;--------------------------------------------------
; GRAPHICS
;--------------------------------------------------
%include "gfx.asm"

;--------------------------------------------------
; USER INPUT
;--------------------------------------------------
;------------------------------
; () (cf=keypress, eax=<scan code and ASCII char>or<zero for nothing>)
; Gets a single keypress from BIOS (not silly DOS).
;
align 16
GetKeyPress:
    mov ah,1                ;function to check key buffer status
    int 16h                 ;call BIOS
    jz .NoneWaiting         ;zero flag is set, no keys are in buffer
    xor eax,eax             ;function to get first key press
    int 16h                 ;call BIOS
%if Personal                ;leave out for public release
    cmp ax,'q'<<8           ;Alt+F10 for grabbing screenshots :)
    jne .NoSnapshot
    call SaveSnapshot
    jmp short .NoneWaiting
.NoSnapshot:
%endif
    stc                     ;set carry flag to indicate keypress
    ret

.NoneWaiting:
    xor eax,eax             ;also clears carry and sets zero flag (clc)
    ret

;------------------------------
; (dword=string destination, dword=screen pos, byte=starting length, byte=max length) (cf=esc)
; Gets a string of input of from user until Enter or Esc is pressed.
; Currently very cruddy way to get input, but it does work.
; Returns a null terminated string of characters one less than max length.
;
GetUserString:
    .Dest           equ 4
    .ScreenPos      equ 8
    .CurLength      equ 12
    .MaxLength      equ 13

    mov byte [PrintCharString.Color],GuiColorText
    dec byte [esp+.MaxLength]       ;max is one less because of terminating null
    jnz .DisplayString              ;check that we did not make 255
    mov byte [esp+.MaxLength],0
.DisplayString:
    ;clear background
    push dword GuiColorBack         ;color
    movzx ecx,byte [esp+.MaxLength+4]
    imul ecx,GuiFont.GlyphPixelWidth + 1
    shl ecx,16                      ;move width into upper word
    mov cl,GuiFont.GlyphPixelHeight ;set height
    push ecx                        ;height/width
    push dword [esp+.ScreenPos+8]   ;row/column
    call DrawBox

    ;draw caret
    movzx edx,byte [esp+.CurLength+12]
    imul edx,byte GuiFont.GlyphPixelWidth + 1
    movzx ebx,word [esp+.ScreenPos+12] ;set row
    add dx,[esp+.ScreenPos+14]      ;add column
    mov ecx,GuiFont.GlyphPixelHeight
    mov al,GuiColorTop
    call BlitLineFast.Vertical

    ;draw string
    push dword [esp+.ScreenPos+12]  ;row/column
    push dword [esp+.Dest+16]       ;get string destination
    call PrintCharStringStd
    call DisplayToScreen
    add esp,byte 12+8
.NextChar:
    xor eax,eax             ;function to get or wait for key press
    int 16h                 ;call BIOS
    mov edi,[esp+.Dest]     ;get string destination
    cmp al,' '
    jb .ControlChar         ;less than space
    mov ebx,[esp+.CurLength];get both current length and maxlength
    cmp bl,bh               ;make sure length is less than max
    jae .NextChar           ;end if no more characters will fit
    movzx ebx,bl            ;make into a pointer
    xor ah,ah               ;make null after character
    mov [edi+ebx],ax        ;add character and null to string
    inc bl                  ;move to next character pos in string
    mov [esp+.CurLength],bl
    jmp short .DisplayString
.ControlChar:
    cmp al,8
    jne .NotBackspace
    movzx ebx,byte [esp+.CurLength]
    test ebx,ebx
    jz .NextChar            ;string is already empty
    dec ebx                 ;move back one character
    mov byte [edi+ebx],0    ;put null at position of last character
    mov [esp+.CurLength],bl
    jmp .DisplayString
.NotBackspace:
    cmp al,13
    jne .NotEnter
    test byte [esp+.CurLength],255  ;set or clear zf
    ;clc                            ;already cleared by test
    ;jmp short .End
.End:
    movzx ebx,byte [esp+.CurLength] ;make text length into pointer
    mov byte [edi+ebx],0            ;put null on end
    ret
.NotEnter:
    cmp al,27
    jne .NextChar
    stc
    jmp short .End

;------------------------------
; (al=key, esi=keylist struct) (cf=error keypress not found, ecx=keynumber)
;
; Pass a scan structure to it, which points to a list of keys, number of normal keys, and
; number of extended.
;
KeyScanFor:
    cld
    mov edi,[esi]
    movzx ecx,byte [esi+4]
    test al,al
    jz .ExtendedKey
    repne scasb
    jnz .NotFound
    not cl
    add cl,[esi+4]
    clc
    ret

.ExtendedKey:
    add edi,ecx
    mov al,ah
    mov cl,[esi+5]
    repne scasb
    jnz .ExtendedKeyNotFound
    not cl
    add cl,[esi+5]
    xor al,al               ;put null back into al
    add cl,[esi+4]
    clc
    ret

.ExtendedKeyNotFound:
    xor al,al               ;put null back into al
.NotFound:
    stc
    ret

;--------------------------------------------------
; STRING MANIPULATION
;--------------------------------------------------
;------------------------------
; (eax=value, edi=text destination, ?ecx=max string length, ?ebx=radix) (ecx=offset of first digit)
; Turns a 32bit unsigned number into a decimal string, writing it to edi.
; Potential problems: It does not check that radix passed to it is valid, so
; passing a negative radix could have unpredictable results, or passing it
; zero could cause a divide overflow. Passing a string length longer than the
; destination really is will cause it to overwrite data. 4294967295 is the
; largest number it can handle.
;
NumToString:
    mov ecx,NumStringMaxLen ;default maximum of ten characters
.AnyLength:                 ;since the largest 32bit is 4gb
    mov ebx,10              ;base of the decimal system
.AnyRadix:                  ;for hexadecimal and binary (even octal)
    xor edx,edx             ;set top 32 bits of quotient to zero
    lea edi,[edi+ecx-1]     ;start from rightmost character in number
.NextChar:
    div ebx                 ;divide number by the decimal base
    mov dl,[.CharTable+edx] ;get ASCII character from table
    ;add dl,48              ;make remainder into an ASCII character
    mov [edi],dl            ;output result
    dec edi                 ;move backwards one character
    test eax,eax            ;see if we are done with the number
    jz .FillInBlanks        ;nothing but zeroes left
    xor edx,edx             ;set edx to zero again for next division
    dec ecx                 ;one less character to output
    jnz .NextChar
    ret

.FillInBlanks:
    mov al,[.FillChar]      ;fill in with spaces or zeroes
    dec ecx                 ;one less than current count
    mov edx,ecx
    std                     ;move backwards
    rep stosb               ;for number of characters remaining
    mov ecx,edx
    ret

section data
.FillChar:      db ' '
.CharTable:     db '0123456789ABCDEF'
section code

;==============================
; String to Number
; (esi=text source, ?ebx=radix, ?ecx=length of string)
; (eax=value, zf=no number)
;
; Turns a string representation of a number into a 32bit unsigned number.
; Ends at a non-numeric digit, including puncuation, extended characters,
; null, or any other control character. Returns zero for a an empty string.
;
StringToNum:
    ;set default returned number to zero
    ;start at first number
    ;do until number (<0 >9 <A >Z)
    ;  multiply by radix and add to value
    ;loop
    ;return value and string length
    mov ecx,NumStringMaxLen ;default maximum of ten characters
.AnyLength:                     ;since the largest 32bit is 4gb
    mov ebx,10              ;base of the decimal system
.AnyRadix:                      ;for hexadecimal and binary (even octal)
    xor edx,edx             ;set top 32 bits of digit place to zero
    mov edi,ecx             ;copy length
    xor eax,eax             ;set return value to zero
.NextChar:
    mov dl,[esi]            ;get digit
    sub dl,48               ;"0"=48->0  "9"=57->9
    jc .End                 ;character is less than '0'
    cmp dl,10
    jb .AddPlaceValue       ;digit is 0-9
    and dl,~32              ;make uppercase by turning off fifth bit
    cmp dl,'A'-48
    jb .End                 ;character is less than 'A'
    cmp dl,'F'-48
    ja .End                 ;character is greater than 'F' (15)
    sub dl,7                ;(65-48)+10  "A"=65->10  "F"=86->15
.AddPlaceValue:
    imul eax,ebx            ;multiply existing number by radix
    add eax,edx             ;add new digit
    inc esi                 ;move forwards one character
    dec cl                  ;one less character to check
    jnz .NextChar
.End:
    sub edi,ecx             ;set zero flag accordingly
    ;mov ecx,edi
    ret

;------------------------------
;
Mouse:
;(changes eax)
.Show:
    mov eax,1
    jmp short .MouseDriverCall
;(changes eax)
.Hide:
    mov eax,2
    ;jmp short .MouseDriverCall
.MouseDriverCall:
    test byte [Mouse.Installed],1
    jz .NoMouseInstalled
    int 33h
.NoMouseInstalled:
    ret
;(cf=true:indicates movement or button press)
.GetInfo:
    test byte [Mouse.Installed],1
    jz .NoMouseInstalled    ;test also clears cf
    mov eax,3
    int 33h
    movzx ecx,cx
    xor eax,eax
    movzx edx,dx
    shr ecx,1
    cmp [Mouse.Row],edx
    jne .MouseMove
    cmp [Mouse.Col],ecx
    je .NoMouseMove
.MouseMove:
    mov [Mouse.Row],edx
    mov [Mouse.Col],ecx
    inc eax
    ;call .RedrawPointer
    stc
    ret
.NoMouseMove:
    clc
    ret

.RedrawPointer:
    mov edi,[Mouse.Row]
    mov edx,[Display.Width]
    imul edi,edx
    mov esi,Mouse.DefaultPointerImage
    sub edx,byte 16
    add edi,[Mouse.Col]
    add edi,[WinDos.displayMemoryBase]
    mov ch,16
.NextRow:
    mov cl,4
.NextCol:
    mov eax,[edi]
    and eax,[esi]
    or  eax,[esi+256]
    mov [edi],eax
    add esi,byte 4
    add edi,byte 4
    dec cl
    jnz .NextCol
    add edi,edx
    dec ch
    jnz .NextRow
    ret

;--------------------------------------------------
; CONSTANTS, VARIABLES, TEXT MESSAGES, FONTS...
;--------------------------------------------------
section data

align 4
StartOptions.Flags:         dd 0
File.Name:          dd 0    ;pointer to file's ASCIIZ name
File.Attribs:       db 0
Files.ToOpen:       db 0
File.TileTable:     db -1
File.Vram:          db -1

align 4
ViewWindow:
.FilePosition:  dd 0            ;current position in file (window's top left)
.FileOffsetBase:dd 0            ;base to subtract from position to get offset
.MarkBase:      dd 0
.MarkHeight:    dw 0
.MarkWidth:     dw 0
.WriteDataValue:dd 0            ;value of data last written
.PosRadix:      db 16           ;radix of displayed file position 10|16
.Options:       db 0
.UseOffsetBase  equ 1           ;whether or not to use the offset base
.Change:        db WindowRedraw.Complete ;flags to indicate various changes

; FileTiles is an instance of BlitTileStruct.
FileTiles:
.Blitter:       dd BlitTile.ColorBlocks
.Init:          dd BlitTile.DoNada
.Expander:      dd ExpandTileUnit.Byte
.SrcPtr:        dd File.Buffer
.SrcWrap:       dd 64
.SrcRange:      dd 8192
.Bits:          dd 8
.Mask:          dd 65535
.Shift:         db 0
.SrcBit:        db 0
.Format:        db TileFormat.ColorBlocks
.Orientation:   db 0
.DestPtr:       dd Display.Buffer+(Screen.DefaultWidth*4)+4;0A0000h+(320*4)+4 four rows down, four cols over
.DestWrap:      dd Screen.DefaultWidth
.DestHeight:    dd ViewWindow.Height
.DestWidth:     dd ViewWindow.Width
.Rows:          dd 40
.Cols:          dd 64
.Size:
.Height:        db 4
.Width:         db 4, 0,0
.Change:        dd WindowRedraw.Complete

.PaletteIndex:  db 0
.PrevBits:      dd 16
.PrevMask:      dd 65535
.PrevShift:     db 0
.PrevSrcBit:    db 0
.PrevFormat:    db TileFormat.ColorBlocks
.PrevOrient:    db 0

NumberedFormatsTbl:;tile format, unit size in bits, wrap, orientation
db     TileFormat.ColorBlocks,  -1,-1,-1,-1, 0, 0, 0  ;blocks
db     TileFormat.NumericValue, -1,-1,-1,-1, 0, 0, 0  ;numbers
db     TileFormat.FontChar,     -1,-1,-1,-1, 0, 0, 0  ;text, byte if ASCII, word if unicode/Japanese
db     TileFormat.Vram,         -1,-1,-1,-1, 0, 0, 0  ;vram/word/32
db     TileFormat.TileTable,    -1,-1,-1,-1, 0, 0, 0  ;tile table
db     TileFormat.BrrSample,     8, 9, 1,-1, 0, 0, 0  ;spc sample/9/9
db    -1,-1,-1,-1,-1, 0, 0, 0
db    -1,-1,-1,-1,-1, 0, 0, 0
db    -1,-1,-1,-1,-1, 0, 0, 0
.Size equ 9

align 4
BgMapBases:         dd 0,0,0,0  ;base in VRAM of each bg's tilemap
BgTileBases:        dd 0,0,0,0  ;base in VRAM of each bg's tile graphics
BgBitdepths:        db 4,4,2,1  ;default is mode 1
BgTileFormats:      db TileFormat.Snes4,TileFormat.Snes4,TileFormat.Snes2,-1 ; default is the common mode 1
BgModeToBitdepthTable:      db 2,2,2,2, 4,4,2,0, 4,4,0,0, 8,4,0,0, 8,2,0,0, 4,2,0,0, 4,0,0,0, 8,0,0,0
BgModeToTileFormatsTable:   db TileFormat.Snes2,TileFormat.Snes2,TileFormat.Snes2,TileFormat.Snes2,
                            db TileFormat.Snes4,TileFormat.Snes4,TileFormat.Snes2,-1
                            db TileFormat.Snes4,TileFormat.Snes4,-1,-1
                            db TileFormat.Snes8,TileFormat.Snes4,-1,-1
                            db TileFormat.Snes8,TileFormat.Snes2,-1,-1
                            db TileFormat.Snes4,TileFormat.Snes2,-1,-1
                            db TileFormat.Snes4,-1,-1,-1
                            db TileFormat.SnesMode7,-1,-1,-1
section bss
alignb 4
TileTable:          resb 32768
section data
.Size:
.Height:            db 2
.Width:             db 2
.Bytes:             db 2,0
.Inc:               dd 0        ;byte size of each tile group

section bss
alignb 4
Vram:
.Gfx:               resd 65536  ;bitplane tiles
.Buffer:            resb 65536  ;cached linear graphics
.TileColors:        resb 1024   ;dominant color of each tile
.CgramPalette:      resb 256*2  ;256*sizeof(uint16)
.Palette:           resb 256*3  ;256*sizeof(uint24)
section data
align 4
.Base:              dd 16384
.Bitdepth:          dd 4
.Converter:         dd BitplaneToLinear
.BplTbl:            dd BlitTile.BplTblSnes4
.TileFormat:        db TileFormat.Snes4
;note that SNES bit modes 1, 2, and GameBoy all use the same table

;align 4
Vram.Options:
TileTable.Options:  db 0
Vram.Cached         equ 1
Vram.Loaded         equ 2
TileTable.Flipped   equ 4   ;tiles use down/right/down order like Mario World
TileTable.Loaded    equ 8

;------------------------------
align 4
Display:
.BasePtr            dd Display.Buffer
.Height:            dd Screen.DefaultHeight
.Width:             dd Screen.DefaultWidth
.PalettePtr:        dd RainbowPalette ; r8g8b8[256] 0..<=63

section bss
alignb 4
.Buffer             resb Screen.DefaultWidth * Screen.DefaultHeight ;off screen buffer (to reduce visible redraw)
section data

DefaultTileFont:
.Chars:             incbin "Default8x8_1bit.fnt" ;1bpp pixels
.GlyphPixelWidth    equ 8
.GlyphPixelHeight   equ 8
.GlyphPixelCount    equ .GlyphPixelHeight * .GlyphPixelWidth

GuiFont:
.Chars:             equ $-128       ;adjust base pointer since font only includes characters 32-127
.GlyphPixelHeight   equ 7
.GlyphPixelWidth    equ 5
                    incbin "Gui5x7_1bit.fnt"
SmallHexFont:
.Chars:             incbin "SmallHex5x5_1bit.fnt"
.GlyphPixelWidth    equ 5
.GlyphPixelHeight   equ 5

RainbowPalette:     incbin "rainbow.pal"

Mouse.DefaultPointerImage:
                    ;incbin "csrhand.lbm"

;          (0.........1.........2.........3.........4.........5.........6.........7.........)
Text:
.KeyHelp:
        db SccWhite,"Tilemap Viewer ",SccWhite,ProgramVersionStr," 2001 - File pattern viewer",SccCr
        db SccBlack,"<-",SccRed,"P",SccYellow,"i",SccGreen,"k",SccCyan,"e",SccPurple,"n",SccBlack,"->",SccCr
        db SccCr
        ;db SccRed,"                ","T",SccYellow,"i",SccGreen,"l",SccCyan,"e",SccBlue,"m",SccPurple,"a",SccRed,"p ",SccYellow,"V",SccGreen,"i",SccCyan,"e",SccBlue,"w",SccPurple,"e",SccRed,"r ",SccWhite,ProgramVersionStr,SccCr,SccCr
        db SccGreen,"Scrolling forward/backward:",SccCr
        db SccCyan,"  ",24,32,25,32,27,32,26,SccWhite,"           Step row/column",SccCr
        db SccCyan,"  PgUp PgDn         ",SccWhite,"Step 16 rows",SccCr
        db SccCyan,"  Home End          ",SccWhite,"Step 16 columns",SccCr
        db SccCyan,"  Ctrl",SccWhite,"+(",SccCyan,27,32,26,SccWhite,")        Step single byte",SccCr
        db SccCyan,"  Ctrl",SccWhite,"+(",SccCyan,"PgUp PgDn",SccWhite,")  Jump 32k (one low ROM bank)",SccCr
        db SccCyan,"  Ctrl",SccWhite,"+(",SccCyan,"Home End",SccWhite,")   Jump to beginning or end",SccCr
        db SccCr
        db SccGreen,"Changing window wrap:",SccCr
        db SccCyan,"  [ ]    ",SccWhite,"Decrease/Increase width by one",SccCr
        db SccCyan,"  { }    ",SccWhite,"Half/Double width",SccCr
        db SccCyan,"  o      ",SccWhite,"Orientation right-down/down-right",SccCr
        db SccCr
        db SccGreen,"Changing unit:",SccCr
        db SccCyan,"  u      ",SccWhite,"Toggle unit size (1,2,4,8,16,32 bit)",SccCr
        db SccCyan,"  U      ",SccWhite,"Next unit size",SccCr
        db SccCyan,"  - +    ",SccWhite,"Decrease/Increase shift",SccCr
        db SccCyan,"  / *    ",SccWhite,"Decrease/Increase bitmask",SccCr
        db SccCr
        db SccGreen,"Changing display format:",SccCr
        db SccCyan,"  m M    ",SccWhite,"Cycle through modes",SccCr
        db SccCyan,"  1      ",SccWhite,"Colored blocks",SccCr
        db SccCyan,"  2      ",SccWhite,"Hex numbers",SccCr
        db SccCyan,"  3      ",SccWhite,"ASCII character set",SccCr
        db SccCyan,"  4      ",SccWhite,"VRAM graphics",SccCr
        db SccCyan,"  5      ",SccWhite,"Tile table graphics",SccCr
        db SccCyan,"  6      ",SccWhite,"BRR sound sample",SccCr
        db SccCr
        db SccGreen,"Other:",SccCr
        db SccCyan,"  g      ",SccWhite,"Goto position (Hex address or bg#)",SccCr
        db SccCyan,"  h      ",SccWhite,"Offset radix hex/dec",SccCr
        db SccCyan,"  b      ",SccWhite,"Base offset on/off",SccCr
        db SccCyan,"  B      ",SccWhite,"Set offset base to current position",SccCr
        db SccCyan,"  w      ",SccWhite,"Write unit to file with new hex value",SccCr
        db SccCyan,"  Del    ",SccWhite,"Write another unit to same value as 'w'",SccCr
        db SccCyan,"  F1     ",SccWhite,"See this help",SccCr
        db SccCyan,"  Ctrl",SccWhite,"+",SccCyan,"o ",SccWhite,"Open file",SccCr
        db SccCyan,"  Esc    ",SccWhite,"Go do better things",SccCr
        db SccCr
        ;db 0
.Info:
        db "Tilemap Viewer Usage:",13,10
        db 10
        db "Usage:",13,10
        db "  tmv [-options] mainfile [[-moreoptions] file]...",13,10
        db 10
        db "Options:",13,10
        db "  -g #          Goto relative position (in hex)",13,10
        db "  -w #          Set tile wrap width (1-512)",13,10
        db "  -m #          Viewing mode (1-6)",13,10
        db "  -u #          Unit size in bits (8,16)",13,10
        db "  -o            Sideways orientation",13,10
        db "  -r            Open file as read-only",13,10
        db "  -v o,b        Load VRAM from",13,10
        db "                (file offset,tile base)",13,10
        db "  -t o,h,w,b,f  Load tile table from",13,10
        db "                (offset,height,width,bytes,flip)",13,10
        db 10
        db "Examples:",13,10
        db "  tmv zelda.zst",13,10
        db "  tmv -g 2000 -u 16 zelda.zst -t 78000,2,2,2 zelda.smc",13,10
        db "  tmv -g 110000 -w 256 mario2.smc",13,10
        db "  tmv -g 127CE2 -w 32 -m 2 dkc.fig",13,10
        db "  tmv -t 20AAD6,4,4,2 -g 203836 -w 16 -u 16 -o dkc.fig dkc.zs9",13,10
        db 10
        db "Compiled with NASM/YASM compiler and WDOSX.",13,10
        db "Viewer written by Dwayne Robinson.",13,10
        db 10
        db "email:    FDwR@hotmail.com",13,10
        db "homepage: http://pikensoft.com/",13,10
        db "          http://members.tripod.com/FDwR/snes.htm",13,10
        db 0,"$"
.FileOpenError:         db "Could not open the file. Check that it was spelled right.",0,"$"
;.FileShareError:       db "Could not open the file for editing. Attempting read-only mode.",0,"$"
.FileReadError:         db "An error occurred trying to read file.",0,"$"
.NoFilesGiven:          db "No file was given to view. Please specify a savestate, ROM, or other file.",0,"$"
.UnknownParameter:      db "Unknown parameter in command line.",0,"$"
.ZSNESSavestateID:      db "ZSNES Save State File"
.ZSNESSavestateID_Len:  equ $-.ZSNESSavestateID
;.StatusBar_Relative:    db "relative"
;.StatusBar_Absolute:    db "absolute"
.PromptColorValue:      db "Color value",0
.PromptGotoPosition:    db "Goto position",0
.PromptOpenFilename:    db "Open filename",0
%ifdef debug
.ForwardPartial:        db 'forward partial  ",0,"$'
.ForwardComplete:       db 'forward complete ",0,"$'
.BackwardPartial:       db 'backward partial ",0,"$'
.BackwardComplete:      db 'backward complete",0,"$'
%endif

StatusBar:
.Pos:   db "@12345678.9hr "
.Wrap:  db "x123 "
.Bits:  db "#12l "
.Mask:  db "&1234 "
.Shift: db ">>12",0
.PixelHeight equ GuiFont.GlyphPixelHeight
.PixelWidth  equ Screen.DefaultWidth-5-5
.PixelY equ Screen.DefaultHeight-.PixelHeight-5
.PixelX equ 5

NumStrBuffer:           ;*10
CharStrBuffer:          db ".................................................."
CharStrBuffer_Len   equ $-CharStrBuffer

;--------------------------------------------------
; UNITIALIZED VARIABLES (could be set to anything)
;--------------------------------------------------
section bss

alignb 4
File:
.Handle:        resd 1          ;DOS handle for reading file
.Length:        resd 1          ;what else, the file's length
.BufferBase:    resd 1          ;file position first byte in buffer is from
.Position:      resd 1
.Buffer:        resb File.BufferByteSize
.Atr_Direction  equ 1           ;indicates which direction was last taken, 0=backwards, 1=forwards
.Atr_ReadOnly   equ 2           ;file is supposed to be opened in read only mode
.Type:          resb 0          ;indicates savestate, ROM, or other
.Type_Any       equ 0
.Type_Zst       equ 1
.Type_Rom       equ 2

alignb 4
Files:
.Maximum            equ 4
.EntryByteSize      equ 16  ;bytes per info block
.EntriesTotalBytes  equ .Maximum * .EntryByteSize  ; 4 files, 16 bytes
.Entries            resd .EntriesTotalBytes
; TODO: Change these to a struct
.EntryPosition      equ 0   ;current position in file
.EntryOffsetBase    equ 4   ;base to subtract from position to get offset
.EntryHandle        equ 8   ;DOS handle for reading file
.EntryName          equ 12  ;pointer to file's ASCIIZ name

Mouse.Row:      resd 1
Mouse.Col:      resd 1
Mouse.Installed:resb 1

BlitTilesBuffer:resb ViewWindow.MaxTileWrap * 4 ;buffer to hold a row of uint32's.

;CharTransTable:
;.Ptr:           resd 1          ;(dd .User)
;.Active:        resb 256        ;used for translation of other sets to ASCII
;.User:          resb 256        ;table the user selected

Bss.End:
Bss.Size         equ Bss.End-Bss.Start
