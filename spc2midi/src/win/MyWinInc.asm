; WINNASM.INC
; Dwayne Robinson
; 20041212
;
; _VCLINK must be defined if you plan to use the Microsoft Linker for MSVC.
; MSVC adds function stubs, so the address is actually callable
; directly rather than using the import pointer.
; _DMCLINK is currently the same.
;
; Subset of Windows constants/definitions
;
; UseWindowStyles
; UseWindowControls
; UseWindowMsgs
; UseResources
; UseTextConsole
; UseWindowGfx
; UseWindowPaint
; UseDxDraw
; UseCom
; UseKeyboard
; UseWindowHooks
; UseWindowSysVars
; UseFileSystem
; UseErrorCodes
; UseWinRegistry
; UseMemory
; UseClipboard
; UseMultimedia
; UseProcess
; UseNetwork
; UseWinsock

%ifndef _VCLINK
%ifndef _NOMSLINK
%ifndef _DMCLINK
%error "You must define API calls as either having a stub (_VCLINK) or no stub (_NOMSLINK, _DMCLINK)"
%endif
%endif
%endif

%ifndef winnasm_inc
%define winnasm_inc

%ifdef UseWindowAll
%define UseWindowStyles
%define UseWindowControls
%define UseWindowMsgs
%define UseResources
%define UseTextConsole
%define UseWindowGfx
%define UseWindowPaint
%define UseDxDraw
%define UseCom
%define UseKeyboard
%define UseWindowHooks
%define UseWindowSysVars
%define UseFileSystem
%define UseErrorCodes
%define UseWinRegistry
%define UseMemory
%define UseClipboard
%define UseMultimedia
%define UseProcess
%define UseNetwork
%define UseWinsock
%endif

; For debugging:
;   debug
;   UseConsoleDebug

TRUE equ 1
FALSE equ 0
NULL equ 0
MAX_PATH equ 260
HWND_DESKTOP equ 0
HWND_MESSAGE equ -3
HWND_BROADCAST equ $0ffff
HRESULT_MASK equ 8000FFFFh
ERROR_SUCCESS equ 0
IDC_ARROW equ 32512
COLOR_BTNFACE equ 15
DEFAULT_GUI_FONT equ 17
NO_ERROR equ 0

%ifdef Unicode
;no point for now...
%else
%define CreateDC CreateDCA
%define CreateFile CreateFileA
%define CreateWindowEx CreateWindowExA
%define CreateProcess CreateProcessA
%define CreateFontIndirect CreateFontIndirectA
%define DefWindowProc DefWindowProcA
%define DefScreenSaverProc DefScreenSaverProcA
%define DialogBoxParam DialogBoxParamA
%define DispatchMessage DispatchMessageA
%define DragQueryFile DragQueryFileA
%define DrawText DrawTextA
%define EnumResourceNames EnumResourceNamesA
%define FindFirstFile FindFirstFileA
%define FindNextFile FindNextFileA
%define FindResource FindResourceA
%define FindResourceEx FindResourceExA
%define FindWindow FindWindowA
%define GetCommandLine GetCommandLineA
%define GetClassName GetClassNameA
%define GetCurrentDirectory GetCurrentDirectoryA
%define GetEnvironmentVariable GetEnvironmentVariableA
%define GetFullPathName GetFullPathNameA
%define GetMessage GetMessageA
%define GetModuleFileName GetModuleFileNameA
%define GetModuleHandle GetModuleHandleA
%define GetWindowLong GetWindowLongA
%define GetWindowText GetWindowTextA
%define GetStartupInfo GetStartupInfoA
%define LoadIcon LoadIconA
%define LoadCursor LoadCursorA
%define LoadKeyboardLayout LoadKeyboardLayoutA
%define LoadLibraryEx LoadLibraryExA
%define lstrcat lstrcatA
%define lstrlen lstrlenA
%define lstrcpy lstrcpyA
%define MessageBox MessageBoxA
%define OutputDebugString OutputDebugStringA
%define PlaySound PlaySoundA
%define PostMessage PostMessageA
%define PostThreadMessage PostThreadMessageA
%define PeekMessage PeekMessageA
%define ReadConsole ReadConsoleA
%define ReadConsoleInput ReadConsoleInputA
%define RegisterClass RegisterClassA
%define RegisterWindowMessage RegisterWindowMessageA
%define RegQueryValue RegQueryValueA
%define SendMessage SendMessageA
%define SendMessageTimeout SendMessageTimeoutA
%define SetCurrentDirectory SetCurrentDirectoryA
%define SetEnvironmentVariable SetEnvironmentVariableA
%define SetWindowsHookEx SetWindowsHookExA
%define SetWindowText SetWindowTextA
%define SetConsoleTitle SetConsoleTitleA
%define SystemParametersInfo SystemParametersInfoA
%define WriteConsole WriteConsoleA
%define wsprintf wsprintfA
%define wvsprintf wvsprintfA

%define waveOutGetDevCaps waveOutGetDevCapsA
%define midiOutGetDevCaps midiOutGetDevCapsA

%define ImmConfigureIME ImmConfigureIMEA

%endif

;=============================================================================

struc POINT
.x resd 1
.y resd 1
endstruc

struc RECT
.left           resd 1
.top            resd 1
.right          resd 1
.bottom         resd 1
endstruc

struc MSG
.hwnd           resd 1
.message        resd 1
.wParam         resd 1
.lParam         resd 1
.time           resd 1
.pt:            ;resb POINT_size
.x              resd 1
.y              resd 1
endstruc

;=============================================================================
%ifdef UseWindowStyles
struc WNDCLASS
.style          resd 1
.lpfnWndProc    resd 1
.cbClsExtra     resd 1
.cbWndExtra     resd 1
.hInstance      resd 1
.hIcon          resd 1
.hCursor        resd 1
.hbrBackground  resd 1
.lpszMenuName   resd 1
.lpszClassName  resd 1
endstruc

; Class styles
CS_VREDRAW equ 1
CS_HREDRAW equ 2
CS_DBLCLKS equ 8
CS_OWNDC equ 32
CS_CLASSDC equ 64
CS_PARENTDC equ $80
CS_NOCLOSE equ $200
CS_SAVEBITS equ $800
CS_BYTEALIGNCLIENT equ $1000
CS_BYTEALIGNWINDOW equ $2000
CS_GLOBALCLASS equ $4000
CS_IME equ $10000

; Window styles (retarded)
WS_OVERLAPPED   equ        0
WS_ACTIVECAPTION equ       1
WS_TABSTOP      equ    10000h
WS_MAXIMIZEBOX  equ    10000h
WS_GROUP        equ    20000h
WS_MINIMIZEBOX  equ    20000h
WS_THICKFRAME   equ    40000h
WS_SYSMENU      equ    80000h
WS_HSCROLL      equ   100000h
WS_VSCROLL      equ   200000h
WS_DLGFRAME     equ   400000h
WS_BORDER       equ   800000h
WS_CAPTION      equ  0C00000h
WS_GT           equ  WS_GROUP | WS_TABSTOP
WS_MAXIMIZE     equ  1000000h
WS_CLIPCHILDREN equ  2000000h
WS_CLIPSIBLINGS equ  4000000h
WS_DISABLED     equ  8000000h
WS_VISIBLE      equ 10000000h
WS_MINIMIZE     equ 20000000h
WS_CHILD        equ 40000000h
WS_POPUP        equ 80000000h
WS_TILED        equ WS_OVERLAPPED
WS_ICONIC       equ WS_MINIMIZE
WS_SIZEBOX      equ WS_THICKFRAME
WS_OVERLAPPEDWINDOW equ WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX
WS_TILEDWINDOW equ WS_OVERLAPPEDWINDOW
WS_POPUPWINDOW equ WS_POPUP | WS_BORDER | WS_SYSMENU
WS_CHILDWINDOW equ WS_CHILD
WS_EX_DLGMODALFRAME equ 1h
WS_EX_NOPARENTNOTIFY equ 4h
WS_EX_TOPMOST equ 8h
WS_EX_ACCEPTFILES equ $10
WS_EX_TRANSPARENT equ $20
WS_EX_MDICHILD equ $40
WS_EX_TOOLWINDOW equ $80
WS_EX_WINDOWEDGE equ $100
WS_EX_CLIENTEDGE equ $200
WS_EX_CONTEXTHELP equ $400
WS_EX_RIGHT equ $1000
WS_EX_LEFT equ 0
WS_EX_RTLREADING equ $2000
WS_EX_LTRREADING equ 0
WS_EX_LEFTSCROLLBAR equ $4000
WS_EX_RIGHTSCROLLBAR equ 0
WS_EX_CONTROLPARENT equ $10000
WS_EX_STATICEDGE equ $20000
WS_EX_APPWINDOW equ $40000
WS_EX_OVERLAPPEDWINDOW equ WS_EX_WINDOWEDGE | WS_EX_CLIENTEDGE
WS_EX_PALETTEWINDOW equ WS_EX_WINDOWEDGE | WS_EX_TOOLWINDOW | WS_EX_TOPMOST
CW_USEDEFAULT equ $80000000

; Window field offsets for GetWindowLong()
GWL_WNDPROC equ -4
GWL_HINSTANCE equ -6
GWL_HWNDPARENT equ -8
GWL_STYLE equ -16
GWL_EXSTYLE equ -20
GWL_USERDATA equ -21
GWL_ID equ -12

struc CREATESTRUCT
.lpCreateParams resd 1
.hInstance      resd 1
.hMenu          resd 1
.hwndParent     resd 1
.cy             resd 1
.cx             resd 1
.y              resd 1
.x              resd 1
.style          resd 1
.lpszName       resd 1
.lpszClass      resd 1
.dwExStyle      resd 1
endstruc

struc WndControlStruct
.hwnd           resd 1          ;window handle of control
.hId            resd 1          ;control indentifier
.dwExStyle      resd 1          ;more flags
.lpClassName    resd 1
.lpWindowName   resd 1          ;control text
.dwStyle        resd 1          ;flags
.x              resd 1
.y              resd 1
.nWidth         resd 1
.nHeight        resd 1
endstruc

; WM_WINDOWPOSCHANGING/CHANGED struct pointed to by lParam
struc WINDOWPOS
.hwnd           resd 1
.hwndInsertAfter resd 1
.x              resd 1
.y              resd 1
.cx             resd 1
.cy             resd 1
.flags          resd 1
endstruc

; ShowWindow states
SW_SCROLLCHILDREN equ 1
SW_INVALIDATE equ 2
SW_ERASE equ 4
SW_SMOOTHSCROLL equ 16
SW_HIDE equ 0
SW_SHOWNORMAL equ 1
SW_NORMAL equ 1
SW_SHOWMINIMIZED equ 2
SW_SHOWMAXIMIZED equ 3
SW_MAXIMIZE equ 3
SW_SHOWNOACTIVATE equ 4
SW_SHOW equ 5
SW_MINIMIZE equ 6
SW_SHOWMINNOACTIVE equ 7
SW_SHOWNA equ 8
SW_RESTORE equ 9
SW_SHOWDEFAULT equ 10
SW_FORCEMINIMIZE equ 11
SW_MAX equ 11
SW_PARENTCLOSING equ 1
SW_OTHERZOOM equ 2
SW_PARENTOPENING equ 3
SW_OTHERUNZOOM equ 4

; SetWindowPos Flags
SWP_NOSIZE equ 1
SWP_NOMOVE equ 2
SWP_NOZORDER equ 4
SWP_NOREDRAW equ 8
SWP_NOACTIVATE equ 16
SWP_FRAMECHANGED equ 32
SWP_SHOWWINDOW equ 64
SWP_HIDEWINDOW equ 128
SWP_NOCOPYBITS equ 256
SWP_NOOWNERZORDER equ 512
SWP_NOSENDCHANGING equ 1024
SWP_DRAWFRAME equ SWP_FRAMECHANGED
SWP_NOREPOSITION equ SWP_NOOWNERZORDER
SWP_DEFERERASE equ 8192
SWP_ASYNCWINDOWPOS equ 16384

; GetWindow constants
GW_HWNDFIRST equ 0
GW_HWNDLAST equ 1
GW_HWNDNEXT equ 2
GW_HWNDPREV equ 3
GW_OWNER equ 4
GW_CHILD equ 5
GW_ENABLEDPOPUP equ 6
GW_MAX equ 6

; Special Window Handles
HWND_TOP equ 0
HWND_BOTTOM equ 1
HWND_TOPMOST equ -1
HWND_NOTOPMOST equ -2

; MessageBox constants
MB_OK equ 0
MB_OKCANCEL equ 1
MB_ABORTRETRYIGNORE equ 2
MB_YESNOCANCEL equ 3
MB_YESNO equ 4
MB_RETRYCANCEL equ 5
MB_ICONHAND equ 16
MB_ICONQUESTION equ 32
MB_ICONEXCLAMATION equ 48
MB_ICONASTERISK equ 64
MB_USERICON equ 128
MB_ICONWARNING equ MB_ICONEXCLAMATION
MB_ICONERROR equ MB_ICONHAND
MB_ICONINFORMATION equ MB_ICONASTERISK
MB_ICONSTOP equ MB_ICONHAND
MB_DEFBUTTON1 equ 0
MB_DEFBUTTON2 equ 256
MB_DEFBUTTON3 equ 512
MB_DEFBUTTON4 equ 768
MB_APPLMODAL equ 0
MB_SYSTEMMODAL equ 4096
MB_TASKMODAL equ 8192
MB_HELP equ 16384
MB_NOFOCUS equ 32768
MB_SETFOREGROUND equ 65536
MB_DEFAULT_DESKTOP_ONLY equ 131072
MB_TOPMOST equ 262144
MB_RIGHT equ 524288
MB_RTLREADING equ 1048576
MB_TYPEMASK equ $0f
MB_ICONMASK equ $0f0
MB_DEFMASK equ $0f00
MB_MODEMASK equ $3000
MB_MISCMASK equ $0c000
MB_SERVICE_NOTIFICATION equ $200000
MB_SERVICE_NOTIFICATION_NT3X equ $40000

; MessageBox Identification codes
IDOK equ 1
IDCANCEL equ 2
IDABORT equ 3
IDRETRY equ 4
IDIGNORE equ 5
IDYES equ 6
IDNO equ 7
IDCLOSE equ 8
IDHELP equ 9
%endif


;=============================================================================
%ifdef UseWindowControls

CCHILDREN_TITLEBAR equ 5
CCHILDREN_SCROLLBAR equ 5

; Button
BM_GETCHECK equ $0f0
BM_SETCHECK equ $0f1
BM_GETSTATE equ $0f2
BM_SETSTATE equ $0f3
BM_SETSTYLE equ $0f4
BM_CLICK equ $0f5
BM_GETIMAGE equ $0f6
BM_SETIMAGE equ $0f7
BN_CLICKED equ 0
BN_PAINT equ 1
BN_HILITE equ 2
BN_UNHILITE equ 3
BN_DISABLE equ 4
BN_DOUBLECLICKED equ 5
BN_PUSHED equ BN_HILITE
BN_UNPUSHED equ BN_UNHILITE
BN_DBLCLK equ BN_DOUBLECLICKED
BN_SETFOCUS equ 6
BN_KILLFOCUS equ 7
BS_PUSHBUTTON equ 0
BS_DEFPUSHBUTTON equ 1
BS_CHECKBOX equ 2
BS_AUTOCHECKBOX equ 3
BS_RADIOBUTTON equ 4
BS_3STATE equ 5
BS_AUTO3STATE equ 6
BS_GROUPBOX equ 7
BS_USERBUTTON equ 8
BS_AUTORADIOBUTTON equ 9
BS_OWNERDRAW equ 11
BS_LEFTTEXT equ 32
BS_RIGHTBUTTON equ BS_LEFTTEXT
BS_TEXT equ 0
BS_ICON equ 64
BS_BITMAP equ $80
BS_LEFT equ $100
BS_RIGHT equ $200
BS_CENTER equ $300
BS_TOP equ $400
BS_BOTTOM equ $800
BS_VCENTER equ $0c00
BS_PUSHLIKE equ $1000
BS_MULTILINE equ $2000
BS_NOTIFY equ $4000
BS_FLAT equ $8000
BST_UNCHECKED equ 0
BST_CHECKED equ 1
BST_INDETERMINATE equ 2
BST_PUSHED equ 4
BST_FOCUS equ 8

; ComboBox
CB_OKAY equ 0
CB_ERR equ -1
CB_ERRSPACE equ -2
CB_GETEDITSEL equ 320
CB_LIMITTEXT equ 321
CB_SETEDITSEL equ 322
CB_ADDSTRING equ 323
CB_DELETESTRING equ 324
CB_DIR equ 325
CB_GETCOUNT equ 326
CB_GETCURSEL equ 327
CB_GETLBTEXT equ 328
CB_GETLBTEXTLEN equ 329
CB_INSERTSTRING equ 330
CB_RESETCONTENT equ 331
CB_FINDSTRING equ 332
CB_SELECTSTRING equ 333
CB_SETCURSEL equ 334
CB_SHOWDROPDOWN equ 335
CB_GETITEMDATA equ 336
CB_SETITEMDATA equ 337
CB_GETDROPPEDCONTROLRECT equ 338
CB_SETITEMHEIGHT equ 339
CB_GETITEMHEIGHT equ 340
CB_SETEXTENDEDUI equ 341
CB_GETEXTENDEDUI equ 342
CB_GETDROPPEDSTATE equ 343
CB_FINDSTRINGEXACT equ 344
CB_SETLOCALE equ 345
CB_GETLOCALE equ 346
CB_GETTOPINDEX equ 347
CB_SETTOPINDEX equ 348
CB_GETHORIZONTALEXTENT equ 349
CB_SETHORIZONTALEXTENT equ 350
CB_GETDROPPEDWIDTH equ 351
CB_SETDROPPEDWIDTH equ 352
CB_INITSTORAGE equ 353
CB_MSGMAX equ 354
CBN_ERRSPACE equ -1
CBN_SELCHANGE equ 1
CBN_DBLCLK equ 2
CBN_SETFOCUS equ 3
CBN_KILLFOCUS equ 4
CBN_EDITCHANGE equ 5
CBN_EDITUPDATE equ 6
CBN_DROPDOWN equ 7
CBN_CLOSEUP equ 8
CBN_SELENDOK equ 9
CBN_SELENDCANCEL equ 10
CBS_SIMPLE equ 1
CBS_DROPDOWN equ 2
CBS_DROPDOWNLIST equ 3
CBS_OWNERDRAWFIXED equ 16
CBS_OWNERDRAWVARIABLE equ 32
CBS_AUTOHSCROLL equ 64
CBS_OEMCONVERT equ $80
CBS_SORT equ $100
CBS_HASSTRINGS equ $200
CBS_NOINTEGRALHEIGHT equ $400
CBS_DISABLENOSCROLL equ $800
CBS_UPPERCASE equ $2000
CBS_LOWERCASE equ $4000
STRUC COMBOBOXINFO
.cbSize         resd 1
.rcItem.left        resd 1
.rcItem.top     resd 1
.rcItem.right       resd 1
.rcItem.bottom      resd 1
.rcButton.left      resd 1
.rcButton.top       resd 1
.rcButton.right     resd 1
.rcButton.bottom    resd 1
.stateButton        resd 1
.hwndCombo      resd 1
.hwndItem       resd 1
.hwndList       resd 1
ENDSTRUC

; Common Controls
CCS_TOP equ 1
CCS_NOMOVEY equ 2
CCS_BOTTOM equ 3
CCS_NORESIZE equ 4
CCS_NOPARENTALIGN equ 8
CCS_ADJUSTABLE equ 32
CCS_NODIVIDER equ 64
CCS_VERT equ 128
CCS_LEFT equ CCS_VERT | CCS_TOP
CCS_RIGHT equ CCS_VERT | CCS_BOTTOM
CCS_NOMOVEX equ CCS_VERT | CCS_NOMOVEY

; ScrollBar
SB_HORZ equ 0
SB_VERT equ 1
SB_CTL equ 2
SB_BOTH equ 3
SB_LINEUP equ 0
SB_LINELEFT equ 0
SB_LINEDOWN equ 1
SB_LINERIGHT equ 1
SB_PAGEUP equ 2
SB_PAGELEFT equ 2
SB_PAGEDOWN equ 3
SB_PAGERIGHT equ 3
SB_THUMBPOSITION equ 4
SB_THUMBTRACK equ 5
SB_TOP equ 6
SB_LEFT equ 6
SB_BOTTOM equ 7
SB_RIGHT equ 7
SB_ENDSCROLL equ 8
ESB_ENABLE_BOTH equ 0
ESB_DISABLE_BOTH equ 3
ESB_DISABLE_LEFT equ 1
ESB_DISABLE_RIGHT equ 2
ESB_DISABLE_UP equ 1
ESB_DISABLE_DOWN equ 2
ESB_DISABLE_LTUP equ ESB_DISABLE_LEFT
ESB_DISABLE_RTDN equ ESB_DISABLE_RIGHT
SBARS_SIZEGRIP equ 256
SBM_SETPOS equ 224
SBM_GETPOS equ 225
SBM_SETRANGE equ 226
SBM_SETRANGEREDRAW equ 230
SBM_GETRANGE equ 227
SBM_ENABLE_ARROWS equ 228
SBM_SETSCROLLINFO equ 233
SBM_GETSCROLLINFO equ 234
SBS_HORZ equ 0
SBS_VERT equ 1
SBS_TOPALIGN equ 2
SBS_LEFTALIGN equ 2
SBS_BOTTOMALIGN equ 4
SBS_RIGHTALIGN equ 4
SBS_SIZEBOXTOPLEFTALIGN equ 2
SBS_SIZEBOXBOTTOMRIGHTALIGN equ 4
SBS_SIZEBOX equ 8
SBS_SIZEGRIP equ 16
SIF_RANGE equ 1
SIF_PAGE equ 2
SIF_POS equ 4
SIF_DISABLENOSCROLL equ 8
SIF_TRACKPOS equ 16
SIF_ALL equ SIF_RANGE | SIF_PAGE | SIF_POS | SIF_TRACKPOS
STRUC SCROLLINFO
.cbSize         resd 1
.fMask          resd 1
.nMin           resd 1
.nMax           resd 1
.nPage          resd 1
.nPos           resd 1
.nTrackPos      resd 1
ENDSTRUC
STRUC SCROLLBARINFO
.cbSize             resd 1
.rcScrollBar.left   resd 1
.rcScrollBar.top    resd 1
.rcScrollBar.right  resd 1
.rcScrollBar.bottom resd 1
.dxyLineButton      resd 1
.xyThumbTop         resd 1
.xyThumbBottom      resd 1
.bogus              resd 1
.rgstate            resd CCHILDREN_SCROLLBAR+1
ENDSTRUC

; Static
STM_SETICON equ 368
STM_GETICON equ 369
STM_SETIMAGE equ 370
STM_GETIMAGE equ 371
STM_MSGMAX equ 372
STN_CLICKED equ 0
STN_DBLCLK equ 1
STN_ENABLE equ 2
STN_DISABLE equ 3
SS_LEFT equ 0
SS_CENTER equ 1
SS_RIGHT equ 2
SS_ICON equ 3
SS_BLACKRECT equ 4
SS_GRAYRECT equ 5
SS_WHITERECT equ 6
SS_BLACKFRAME equ 7
SS_GRAYFRAME equ 8
SS_WHITEFRAME equ 9
SS_USERITEM equ 10
SS_SIMPLE equ 11
SS_LEFTNOWORDWRAP equ 12
SS_OWNERDRAW equ 13
SS_BITMAP equ 14
SS_ENHMETAFILE equ 15
SS_ETCHEDHORZ equ 16
SS_ETCHEDVERT equ 17
SS_ETCHEDFRAME equ 18
SS_TYPEMASK equ 31
SS_NOPREFIX equ 128
SS_NOTIFY equ 256
SS_CENTERIMAGE equ $200
SS_RIGHTJUST equ $400
SS_REALSIZEIMAGE equ $800
SS_SUNKEN equ $1000
SS_ENDELLIPSIS equ $4000
SS_PATHELLIPSIS equ $8000
SS_WORDELLIPSIS equ $0c000
SS_ELLIPSISMASK equ $0c000

; Tab
TCS_TABS equ 0
TCS_SINGLELINE equ 0
TCS_RIGHTJUSTIFY equ 0
TCS_SCROLLOPPOSITE equ 1
TCS_BOTTOM equ 2
TCS_RIGHT equ 2
TCS_MULTISELECT equ 4
TCS_FLATBUTTONS equ 8
TCS_FORCEICONLEFT equ 16
TCS_FORCELABELLEFT equ 32
TCS_HOTTRACK equ 64
TCS_VERTICAL equ 128
TCS_BUTTONS equ 256
TCS_MULTILINE equ $200
TCS_FIXEDWIDTH equ $400
TCS_RAGGEDRIGHT equ $800
TCS_FOCUSONBUTTONDOWN equ $1000
TCS_OWNERDRAWFIXED equ $2000
TCS_TOOLTIPS equ $4000
TCS_FOCUSNEVER equ $8000

; Edit
ES_LEFT equ 0
ES_CENTER equ 1
ES_RIGHT equ 2
ES_MULTILINE equ 4
ES_UPPERCASE equ 8
ES_LOWERCASE equ 16
ES_PASSWORD equ 32
ES_AUTOVSCROLL equ 64
ES_AUTOHSCROLL equ 128
ES_NOHIDESEL equ 256
ES_OEMCONVERT equ 1024
ES_READONLY equ 2048
ES_WANTRETURN equ 4096
ES_NUMBER equ 8192

EM_GETSEL equ $0b0
EM_SETSEL equ $0b1
EM_GETRECT equ $0b2
EM_SETRECT equ $0b3
EM_SETRECTNP equ $0b4
EM_SCROLL equ $0b5
EM_LINESCROLL equ $0b6
EM_SCROLLCARET equ $0b7
EM_GETMODIFY equ $0b8
EM_SETMODIFY equ $0b9
EM_GETLINECOUNT equ $0ba
EM_LINEINDEX equ $0bb
EM_SETHANDLE equ $0bc
EM_GETHANDLE equ $0bd
EM_GETTHUMB equ $0be
EM_LINELENGTH equ $0c1
EM_REPLACESEL equ $0c2
EM_GETLINE equ $0c4
EM_LIMITTEXT equ $0c5
EM_CANUNDO equ $0c6
EM_UNDO equ $0c7
EM_FMTLINES equ $0c8
EM_LINEFROMCHAR equ $0c9
EM_SETTABSTOPS equ $0cb
EM_SETPASSWORDCHAR equ $0cc
EM_EMPTYUNDOBUFFER equ $0cd
EM_GETFIRSTVISIBLELINE equ $0ce
EM_SETREADONLY equ $0cf
EM_SETWORDBREAKPROC equ $0d0
EM_GETWORDBREAKPROC equ $0d1
EM_GETPASSWORDCHAR equ $0d2
EM_SETMARGINS equ $0d3
EM_GETMARGINS equ $0d4
EM_SETLIMITTEXT equ EM_LIMITTEXT
EM_GETLIMITTEXT equ $0d5
EM_POSFROMCHAR equ $0d6
EM_CHARFROMPOS equ $0d7
EM_SETIMESTATUS equ $0d8
EM_GETIMESTATUS equ $0d9
EN_SETFOCUS equ 256
EN_KILLFOCUS equ 512
EN_CHANGE equ 768
EN_UPDATE equ 1024
EN_ERRSPACE equ 1280
EN_MAXTEXT equ 1281
EN_HSCROLL equ 1537
EN_VSCROLL equ 1538

; ListBox
LB_OKAY equ 0
LB_CTLCODE equ 0
LB_ERR equ -1
LB_ERRSPACE equ -2
LB_ADDSTRING equ 384
LB_INSERTSTRING equ 385
LB_DELETESTRING equ 386
LB_SELITEMRANGEEX equ 387
LB_RESETCONTENT equ 388
LB_SETSEL equ 389
LB_SETCURSEL equ 390
LB_GETSEL equ 391
LB_GETCURSEL equ 392
LB_GETTEXT equ 393
LB_GETTEXTLEN equ 394
LB_GETCOUNT equ 395
LB_SELECTSTRING equ 396
LB_DIR equ 397
LB_GETTOPINDEX equ 398
LB_FINDSTRING equ 399
LB_GETSELCOUNT equ 400
LB_GETSELITEMS equ 401
LB_SETTABSTOPS equ 402
LB_GETHORIZONTALEXTENT equ 403
LB_SETHORIZONTALEXTENT equ 404
LB_SETCOLUMNWIDTH equ 405
LB_ADDFILE equ 406
LB_SETTOPINDEX equ 407
LB_GETITEMRECT equ 408
LB_GETITEMDATA equ 409
LB_SETITEMDATA equ 410
LB_SELITEMRANGE equ 411
LB_SETANCHORINDEX equ 412
LB_GETANCHORINDEX equ 413
LB_SETCARETINDEX equ 414
LB_GETCARETINDEX equ 415
LB_SETITEMHEIGHT equ 416
LB_GETITEMHEIGHT equ 417
LB_FINDSTRINGEXACT equ 418
LB_SETLOCALE equ 421
LB_GETLOCALE equ 422
LB_SETCOUNT equ 423
LB_INITSTORAGE equ 424
LB_ITEMFROMPOINT equ 425
LB_MSGMAX equ 432
LBN_ERRSPACE equ -2
LBN_SELCHANGE equ 1
LBN_DBLCLK equ 2
LBN_SELCANCEL equ 3
LBN_SETFOCUS equ 4
LBN_KILLFOCUS equ 5
LBS_NOTIFY equ 1
LBS_SORT equ 2
LBS_NOREDRAW equ 4
LBS_MULTIPLESEL equ 8
LBS_OWNERDRAWFIXED equ 16
LBS_OWNERDRAWVARIABLE equ 32
LBS_HASSTRINGS equ 64
LBS_USETABSTOPS equ $80
LBS_NOINTEGRALHEIGHT equ $100
LBS_MULTICOLUMN equ $200
LBS_WANTKEYBOARDINPUT equ $400
LBS_EXTENDEDSEL equ $800
LBS_DISABLENOSCROLL equ $1000
LBS_NODATA equ $2000
LBS_NOSEL equ $4000
LBS_STANDARD equ LBS_NOTIFY | LBS_SORT | WS_VSCROLL | WS_BORDER
DDL_READWRITE equ 0
DDL_READONLY equ 1
DDL_HIDDEN equ 2
DDL_SYSTEM equ 4
DDL_DIRECTORY equ 16
DDL_ARCHIVE equ 32
DDL_POSTMSGS equ 8192
DDL_DRIVES equ 16384
DDL_EXCLUSIVE equ 32768

; Titlebar
STRUC TITLEBARINFO
.cbSize             resd 1
.rcTitleBar.left    resd 1
.rcTitleBar.top     resd 1
.rcTitleBar.right   resd 1
.rcTitleBar.bottom  resd 1
.rgstate            resd CCHILDREN_TITLEBAR+1
ENDSTRUC

; ToolTip
TTS_ALWAYSTIP equ 1
TTS_NOPREFIX equ 2

; TrackBar
TBS_AUTOTICKS equ 1
TBS_VERT equ 2
TBS_HORZ equ 0
TBS_TOP equ 4
TBS_BOTTOM equ 0
TBS_LEFT equ 4
TBS_RIGHT equ 0
TBS_BOTH equ 8
TBS_NOTICKS equ 16
TBS_ENABLESELRANGE equ 32
TBS_FIXEDLENGTH equ 64
TBS_NOTHUMB equ 128
TBS_TOOLTIPS equ 256

; TreeView
TVS_HASBUTTONS equ 1
TVS_HASLINES equ 2
TVS_LINESATROOT equ 4
TVS_EDITLABELS equ 8
TVS_DISABLEDRAGDROP equ 16
TVS_SHOWSELALWAYS equ 32
TVS_RTLREADING equ 64
TVS_NOTOOLTIPS equ 128
TVS_CHECKBOXES equ 256
TVS_TRACKSELECT equ $0200
TVS_SINGLEEXPAND equ $0400
TVS_INFOTIP equ $0800
TVS_FULLROWSELECT equ $1000
TVS_NOSCROLL equ $2000
TVS_NONEVENHEIGHT equ $4000

; Up-Down
UDS_WRAP equ 1
UDS_SETBUDDYINT equ 2
UDS_ALIGNRIGHT equ 4
UDS_ALIGNLEFT equ 8
UDS_AUTOBUDDY equ 16
UDS_ARROWKEYS equ 32
UDS_HORZ equ 64
UDS_NOTHOUSANDS equ 128
UDS_HOTTRACK equ 256

; ListView
LVS_ICON equ 0
LVS_REPORT equ 1
LVS_SMALLICON equ 2
LVS_LIST equ 3
LVS_TYPEMASK equ 3
LVS_SINGLESEL equ 4
LVS_SHOWSELALWAYS equ 8
LVS_SORTASCENDING equ 16
LVS_SORTDESCENDING equ 32
LVS_SHAREIMAGELISTS equ 64
LVS_NOLABELWRAP equ $80
LVS_AUTOARRANGE equ $100
LVS_EDITLABELS equ $200
LVS_NOSCROLL equ $2000
LVS_TYPESTYLEMASK equ $0fc00
LVS_ALIGNTOP equ 0
LVS_ALIGNLEFT equ $800
LVS_ALIGNMASK equ $0c00
LVS_OWNERDRAWFIXED equ $400
LVS_OWNERDATA equ $1000
LVS_NOCOLUMNHEADER equ $4000
LVS_NOSORTHEADER equ $8000
LVM_FIRST equ 1000h ;ListView messages
LVM_GETBKCOLOR equ 1000h
LVM_SETBKCOLOR equ 1001h
LVM_DELETEALLITEMS equ 1009h
LVM_SETEXTENDEDLISTVIEWSTYLE equ 1000h+54
LVS_EX_GRIDLINES equ 1h
LVS_EX_SUBITEMIMAGES equ 2h
LVS_EX_CHECKBOXES equ 4h
LVS_EX_TRACKSELECT equ 8h
LVS_EX_HEADERDRAGDROP equ 10h
LVS_EX_FULLROWSELECT equ 20h ;applies to report mode only
LVS_EX_ONECLICKACTIVATE equ 40h
LVS_EX_TWOCLICKACTIVATE equ 80h
;IE >= 0x0400
LVS_EX_FLATSB equ 100h
LVS_EX_REGIONAL equ 200h
LVS_EX_INFOTIP equ 400h ;listview does InfoTips for you
LVS_EX_UNDERLINEHOT equ 800h
LVS_EX_UNDERLINECOLD equ 1000h
LVS_EX_MULTIWORKAREAS equ 2000h
;endif

; Menu
MF_INSERT equ 0
MF_CHANGE equ $80
MF_APPEND equ $100
MF_DELETE equ $200
MF_REMOVE equ $1000
MF_BYCOMMAND equ 0
MF_BYPOSITION equ $4000
MF_SEPARATOR equ $800
MF_ENABLED equ 0
MF_GRAYED equ 1
MF_DISABLED equ 2
MF_UNCHECKED equ 0
MF_CHECKED equ 8
MF_USECHECKBITMAPS equ $200
MF_STRING equ 0
MF_BITMAP equ 4
MF_OWNERDRAW equ $100
MF_POPUP equ 16
MF_MENUBARBREAK equ 32
MF_MENUBREAK equ 64
MF_UNHILITE equ 0
MF_HILITE equ $80
MF_DEFAULT equ $1000
MF_SYSMENU equ $2000
MF_HELP equ $4000
MF_MOUSESELECT equ $8000
MF_END equ $80
MF_RIGHTJUSTIFY equ $4000
MFS_GRAYED equ 3
MFS_DISABLED equ MFS_GRAYED
MFS_CHECKED equ MF_CHECKED
MFS_HILITE equ MF_HILITE
MFS_ENABLED equ MF_ENABLED
MFS_UNCHECKED equ MF_UNCHECKED
MFS_UNHILITE equ MF_UNHILITE
MFS_DEFAULT equ MF_DEFAULT
MFS_MASK equ $108B
MFS_HOTTRACKDRAWN equ $10000000
MFS_CACHEDBMP equ $20000000
MFS_BOTTOMGAPDROP equ $40000000
MFS_TOPGAPDROP equ $80000000
MFS_GAPDROP equ $0c0000000
MFT_STRING equ MF_STRING
MFT_BITMAP equ MF_BITMAP
MFT_MENUBARBREAK equ MF_MENUBARBREAK
MFT_MENUBREAK equ MF_MENUBREAK
MFT_OWNERDRAW equ MF_OWNERDRAW
MFT_RADIOCHECK equ $200
MFT_SEPARATOR equ MF_SEPARATOR
MFT_RIGHTORDER equ $2000
MFT_RIGHTJUSTIFY equ MF_RIGHTJUSTIFY
IMFS_GRAYED equ MFS_GRAYED
IMFS_DISABLED equ MFS_DISABLED
IMFS_CHECKED equ MFS_CHECKED
IMFS_HILITE equ MFS_HILITE
IMFS_ENABLED equ MFS_ENABLED
IMFS_UNCHECKED equ MFS_UNCHECKED
IMFS_UNHILITE equ MFS_UNHILITE
IMFS_DEFAULT equ MFS_DEFAULT
GMDI_USEDISABLED equ 1
GMDI_GOINTOPOPUPS equ 2
HBMMENU_CALLBACK equ -1
HBMMENU_SYSTEM equ 1
HBMMENU_MBAR_RESTORE equ 2
HBMMENU_MBAR_MINIMIZE equ 3
HBMMENU_MBAR_CLOSE equ 5
HBMMENU_MBAR_CLOSE_D equ 6
HBMMENU_MBAR_MINIMIZE_D equ 7
HBMMENU_POPUP_CLOSE equ 8
HBMMENU_POPUP_RESTORE equ 9
HBMMENU_POPUP_MAXIMIZE equ 10
HBMMENU_POPUP_MINIMIZE equ 11
MIIM_STATE equ 1
MIIM_ID equ 2
MIIM_SUBMENU equ 4
MIIM_CHECKMARKS equ 8
MIIM_TYPE equ 16
MIIM_DATA equ 32
MIIM_STRING equ 64
MIIM_BITMAP equ 128
MIIM_FTYPE equ 256
MIM_MAXHEIGHT equ 1
MIM_BACKGROUND equ 2
MIM_HELPID equ 4
MIM_MENUDATA equ 8
MIM_STYLE equ 16
MIM_APPLYTOSUBMENUS equ $80000000
MNC_IGNORE equ 0
MNC_CLOSE equ 1
MNC_EXECUTE equ 2
MNC_SELECT equ 3
MND_CONTINUE equ 0
MND_ENDMENU equ 1
MNGOF_GAP equ 3
MNGO_NOINTERFACE equ 0
MNGO_NOERROR equ 1
MNS_NOCHECK equ $80000000
MNS_MODELESS equ $40000000
MNS_DRAGDROP equ $20000000
MNS_AUTODISMISS equ $10000000
MNS_NOTIFYBYPOS equ $08000000
MNS_CHECKORBMP equ $04000000
TPM_LEFTBUTTON equ 0
TPM_RIGHTBUTTON equ 2
TPM_LEFTALIGN equ 0
TPM_CENTERALIGN equ 4
TPM_RIGHTALIGN equ 8
TPM_TOPALIGN equ 0
TPM_VCENTERALIGN equ 16
TPM_BOTTOMALIGN equ 32
TPM_HORIZONTAL equ 0
TPM_VERTICAL equ 64
TPM_NONOTIFY equ 128
TPM_RETURNCMD equ 256
struc MENUBARINFO
.cbSize         resd 1
.rcBar.left     resd 1
.rcBar.top      resd 1
.rcBar.right    resd 1
.rcBar.bottom   resd 1
.hMenu          resd 1
.hwndMenu       resd 1
.fBarFocused    resd 1
.fFocused       resd 1
endstruc

; Progress Bar
PBS_SMOOTH equ 0x01
PBS_VERTICAL equ 0x04
PBM_SETRANGE equ 401h
PBM_SETPOS equ 402h
PBM_DELTAPOS equ 403h
PBM_SETSTEP equ 404h
PBM_STEPIT equ 405h
;if _WIN32_IE >= 0x0300
PBM_SETRANGE32 equ 406h         ;wParam = high, lParam = low
struc PBRANGE
.iLow   resd 1
.iHigh  resd 1
endstruc
PBM_GETRANGE equ 407h           ;wParam = return (TRUE ? low : high). lParam = PPBRANGE or NULL
PBM_GETPOS equ 408h
;PBM_SETBKCOLOR equ CCM_SETBKCOLOR  ;lParam = bkColor
;if WIN32_IE >= 0x0400
PBM_SETBARCOLOR equ 409h        ;lParam = bar color

; Tab list
TCM_FIRST equ 1300h
TCM_GETIMAGELIST equ TCM_FIRST+2
TCM_SETIMAGELIST equ TCM_FIRST+3
TCM_GETITEMCOUNT equ TCM_FIRST+4
TCIF_TEXT equ 0001h
TCIF_IMAGE equ 0002h
TCIF_RTLREADING equ 0004h
TCIF_PARAM equ 0008h
TCM_GETITEM equ TCM_FIRST+5
TCM_SETITEM equ TCM_FIRST+6
TCM_SETITEMW equ TCM_FIRST+61
TCM_INSERTITEM equ TCM_FIRST+7
TCM_INSERTITEMW equ TCM_FIRST+62
TCM_DELETEITEM equ TCM_FIRST+8
TCM_DELETEALLITEMS equ TCM_FIRST+9
TCM_GETITEMRECT equ TCM_FIRST+10
TCM_GETCURSEL equ TCM_FIRST+11
TCM_SETCURSEL equ TCM_FIRST+12
TCHT_NOWHERE equ 0001h
TCHT_ONITEMICON equ 0002h
TCHT_ONITEMLABEL equ 0004h
TCHT_ONITEM equ TCHT_ONITEMICON|TCHT_ONITEMLABEL
TCM_HITTEST equ TCM_FIRST+13
TCM_SETITEMEXTRA equ TCM_FIRST+14
TCM_ADJUSTRECT equ TCM_FIRST+40
TCM_SETITEMSIZE equ TCM_FIRST+41
TCM_REMOVEIMAGE equ TCM_FIRST+42
TCM_SETPADDING equ TCM_FIRST+43
TCM_GETROWCOUNT equ TCM_FIRST+44
TCM_GETTOOLTIPS equ TCM_FIRST+45
TCM_SETTOOLTIPS equ TCM_FIRST+46
TCM_GETCURFOCUS equ TCM_FIRST+47
TCM_SETCURFOCUS equ TCM_FIRST+48

struc TC_ITEM
.imask          resd 1
.lpReserved1    resd 1
.lpReserved2    resd 1
.pszText        resd 1
.cchTextMax     resd 1
.iImage         resd 1
.lParam         resd 1
endstruc

struc TC_ITEM_bare
.imask          resd 1
.lpReserved1    resd 1
.lpReserved2    resd 1
.pszText        resd 1
endstruc

%endif


;=============================================================================
%ifdef UseWindowMsgs

%ifndef _VCLINK
[extern DefWindowProc]
%else
[extern _DefWindowProcA@16]
[extern _DefWindowProcW@16]
%endif

WM_NULL equ 0h
WM_CREATE equ 1h
WM_DESTROY equ 2h
WM_MOVE equ 3h
WM_SIZE equ 5h
WM_ACTIVATE equ 6h
 WA_INACTIVE equ 0
 WA_ACTIVE equ 1
 WA_CLICKACTIVE equ 2
WM_SETFOCUS equ 7h
WM_KILLFOCUS equ 08h
WM_ENABLE equ 0Ah
WM_SETREDRAW equ 0Bh
WM_SETTEXT equ 0Ch
WM_GETTEXT equ 0Dh
WM_GETTEXTLENGTH equ 0Eh
WM_PAINT equ 0Fh
WM_CLOSE equ 10h
WM_QUERYENDSESSION equ 11h
WM_QUIT equ 12h
WM_QUERYOPEN equ 13h
WM_ERASEBKGND equ 14h
WM_SYSCOLORCHANGE equ 15h
WM_ENDSESSION equ 16h
WM_SHOWWINDOW equ 18h
WM_WININICHANGE equ 1Ah
WM_DEVMODECHANGE equ 1Bh
WM_ACTIVATEAPP equ 1Ch
WM_FONTCHANGE equ 1Dh
WM_TIMECHANGE equ 1Eh
WM_CANCELMODE equ 1Fh
WM_SETCURSOR equ 20h
WM_MOUSEACTIVATE equ 21h
WM_CHILDACTIVATE equ 22h
WM_QUEUESYNC equ 23h
WM_GETMINMAXINFO equ 24h
WM_PAINTICON equ 26h
WM_ICONERASEBKGND equ 27h
WM_NEXTDLGCTL equ 28h
WM_SPOOLERSTATUS equ 2Ah
WM_DRAWITEM equ 2Bh
WM_MEASUREITEM equ 2Ch
WM_DELETEITEM equ 2Dh
WM_VKEYTOITEM equ 2Eh
WM_CHARTOITEM equ 2Fh
WM_SETFONT equ 30h
WM_GETFONT equ 31h
WM_SETHOTKEY equ 32h
WM_GETHOTKEY equ 33h
WM_QUERYDRAGICON equ 37h
WM_COMPAREITEM equ 39h
WM_COMPACTING equ 41h
WM_OTHERWINDOWCREATED equ 42h
WM_OTHERWINDOWDESTROYED equ 43h
WM_COMMNOTIFY equ 44h
 CN_RECEIVE equ 1h
 CN_TRANSMIT equ 2h
 CN_EVENT equ 4h
WM_WINDOWPOSCHANGING equ 46h
WM_WINDOWPOSCHANGED equ 47h
WM_POWER equ 48h
 PWR_OK equ 1
 PWR_FAIL equ -1
 PWR_SUSPENDREQUEST equ 1
 PWR_SUSPENDRESUME equ 2
 PWR_CRITICALRESUME equ 3
WM_COPYDATA equ 4Ah
WM_CANCELJOURNAL equ 4Bh
WM_NOTIFY equ 4Eh
WM_INPUTLANGUAGECHANGEREQUEST equ 50h
WM_INPUTLANGUAGECHANGE equ 51h
WM_TCARD equ 52h
WM_HELP equ 53h
WM_USERCHANGED equ 54h
WM_NOTIFYFORMAT equ 55h
WM_CONTEXTMENU equ $7b
WM_STYLECHANGING equ $7C
WM_STYLECHANGED equ $7D
WM_DISPLAYCHANGE equ $7E
WM_GETICON equ $7F
WM_SETICON equ $80
WM_NCCREATE equ $81
WM_NCDESTROY equ $82
WM_NCCALCSIZE equ $83
WM_NCHITTEST equ $84
WM_NCPAINT equ $85
WM_NCACTIVATE equ $86
WM_GETDLGCODE equ $87
WM_SYNCPAINT equ $88
WM_NCMOUSEMOVE equ $0a0
WM_NCLBUTTONDOWN equ $0a1
WM_NCLBUTTONUP equ $0a2
WM_NCLBUTTONDBLCLK equ $0a3
WM_NCRBUTTONDOWN equ $0a4
WM_NCRBUTTONUP equ $0a5
WM_NCRBUTTONDBLCLK equ $0a6
WM_NCMBUTTONDOWN equ $0a7
WM_NCMBUTTONUP equ $0a8
WM_NCMBUTTONDBLCLK equ $0a9
WM_KEYFIRST equ $100
WM_KEYDOWN equ $100
WM_KEYUP equ $101
WM_CHAR equ $102
WM_DEADCHAR equ $103
WM_SYSKEYDOWN equ $104
WM_SYSKEYUP equ $105
WM_SYSCHAR equ $106
WM_SYSDEADCHAR equ $107
WM_KEYLAST equ $108
WM_IME_STARTCOMPOSITION equ $10D
WM_IME_ENDCOMPOSITION equ $10E
WM_IME_COMPOSITION equ $10F
WM_IME_KEYLAST equ $10F
WM_INITDIALOG equ $110
WM_COMMAND equ $111
WM_SYSCOMMAND equ $112
WM_TIMER equ $113
WM_HSCROLL equ $114
WM_VSCROLL equ $115
WM_INITMENU equ $116
WM_INITMENUPOPUP equ $117
WM_MENUSELECT equ $11F
WM_MENUCHAR equ $120
WM_ENTERIDLE equ $121
WM_MENURBUTTONUP equ $122
WM_MENUDRAG equ $123
WM_MENUGETOBJECT equ $124
WM_UNINITMENUPOPUP equ $125
WM_MENUCOMMAND equ $126
WM_CTLCOLORMSGBOX equ $132
WM_CTLCOLOREDIT equ $133
WM_CTLCOLORLISTBOX equ $134
WM_CTLCOLORBTN equ $135
WM_CTLCOLORDLG equ $136
WM_CTLCOLORSCROLLBAR equ $137
WM_CTLCOLORSTATIC equ $138
WM_MOUSEFIRST equ $200
WM_MOUSEMOVE equ $200
WM_LBUTTONDOWN equ $201
WM_LBUTTONUP equ $202
WM_LBUTTONDBLCLK equ $203
WM_RBUTTONDOWN equ $204
WM_RBUTTONUP equ $205
WM_RBUTTONDBLCLK equ $206
WM_MBUTTONDOWN equ $207
WM_MBUTTONUP equ $208
WM_MBUTTONDBLCLK equ $209
WM_MOUSELAST_BUTTON equ $209 ; invented constant
WM_MOUSEWHEEL equ $20A
WM_MOUSELAST equ $20A
WM_PARENTNOTIFY equ $210
WM_ENTERMENULOOP equ $211
WM_EXITMENULOOP equ $212
WM_NEXTMENU equ $213
WM_SIZING equ $214
WM_CAPTURECHANGED equ $215
WM_MOVING equ $216
WM_POWERBROADCAST equ $218 
WM_DEVICECHANGE equ $219
WM_MDICREATE equ $220
WM_MDIDESTROY equ $221
WM_MDIACTIVATE equ $222
WM_MDIRESTORE equ $223
WM_MDINEXT equ $224
WM_MDIMAXIMIZE equ $225
WM_MDITILE equ $226
WM_MDICASCADE equ $227
WM_MDIICONARRANGE equ $228
WM_MDIGETACTIVE equ $229
WM_MDISETMENU equ $230
WM_ENTERSIZEMOVE equ $231
WM_EXITSIZEMOVE equ $232
WM_DROPFILES equ $233
WM_MDIREFRESHMENU equ $234
WM_IME_SETCONTEXT equ $281
WM_IME_NOTIFY equ $282
WM_IME_CONTROL equ $283
WM_IME_COMPOSITIONFULL equ $284
WM_IME_SELECT equ $285
WM_IME_CHAR equ $286
WM_IME_REQUEST equ $288
WM_IME_KEYDOWN equ $290
WM_IME_KEYUP equ $291
WM_MOUSEHOVER equ $2A1
WM_MOUSELEAVE equ $2A3
WM_CUT equ $300
WM_COPY equ $301
WM_PASTE equ $302
WM_CLEAR equ $303
WM_UNDO equ $304
WM_RENDERFORMAT equ $305
WM_RENDERALLFORMATS equ $306
WM_DESTROYCLIPBOARD equ $307
WM_DRAWCLIPBOARD equ $308
WM_PAINTCLIPBOARD equ $309
WM_VSCROLLCLIPBOARD equ $30A
WM_SIZECLIPBOARD equ $30B
WM_ASKCBFORMATNAME equ $30C
WM_CHANGECBCHAIN equ $30D
WM_HSCROLLCLIPBOARD equ $30E
WM_QUERYNEWPALETTE equ $30F
WM_PALETTEISCHANGING equ $310
WM_PALETTECHANGED equ $311
WM_HOTKEY equ $312
WM_PRINT equ $317
WM_PRINTCLIENT equ $318
WM_HANDHELDFIRST equ $358
WM_HANDHELDLAST equ $35F
WM_AFXFIRST equ $360
WM_AFXLAST equ $37F
WM_PENWINFIRST equ $380
WM_PENWINLAST equ $38F
WM_APP equ $8000
WM_USER equ $400

; PeekMessage
PM_NOREMOVE equ 0
PM_REMOVE equ 1
PM_NOYIELD equ 2

; SendMessageTimeout
SMTO_NORMAL equ 0
SMTO_BLOCK equ 1
SMTO_ABORTIFHUNG equ 2
SMTO_NOTIMEOUTIFNOTHUNG equ 8 ;>5

; System menu command
SC_ACTION_NONE equ 0
SC_ACTION_RESTART equ 1
SC_ACTION_REBOOT equ 2
SC_ACTION_RUN_COMMAND equ 3
SC_SIZE equ $0f000
SC_MOVE equ $0f010
SC_MINIMIZE equ $0f020
SC_MAXIMIZE equ $0f030
SC_NEXTWINDOW equ $0f040
SC_PREVWINDOW equ $0f050
SC_CLOSE equ $0f060
SC_VSCROLL equ $0f070
SC_HSCROLL equ $0f080
SC_MOUSEMENU equ $0f090
SC_KEYMENU equ $0f100
SC_ARRANGE equ $0f110
SC_RESTORE equ $0f120
SC_TASKLIST equ $0f130
SC_SCREENSAVE equ $0f140
SC_HOTKEY equ $0f150
SC_DEFAULT equ $0f160
SC_MONITORPOWER equ $0f170
SC_CONTEXTHELP equ $0f180
SC_SEPARATOR equ $0f00F
SC_ICON equ SC_MINIMIZE
SC_ZOOM equ SC_MAXIMIZE

MK_LBUTTON equ 1h
MK_RBUTTON equ 2h
MK_SHIFT equ 4h
MK_CONTROL equ 8h
MK_MBUTTON equ 10h

; Hit Test codes
HTERROR equ -2
HTTRANSPARENT equ -1
HTNOWHERE equ 0
HTCLIENT equ 1
HTCAPTION equ 2
HTSYSMENU equ 3
HTGROWBOX equ 4
HTSIZE equ HTGROWBOX
HTMENU equ 5
HTHSCROLL equ 6
HTVSCROLL equ 7
HTMINBUTTON equ 8
HTMAXBUTTON equ 9
HTLEFT equ 10
HTRIGHT equ 11
HTTOP equ 12
HTTOPLEFT equ 13
HTTOPRIGHT equ 14
HTBOTTOM equ 15
HTBOTTOMLEFT equ 16
HTBOTTOMRIGHT equ 17
HTBORDER equ 18
HTOBJECT equ 19
HTREDUCE equ HTMINBUTTON
HTZOOM equ HTMAXBUTTON
HTSIZEFIRST equ HTLEFT
HTSIZELAST equ HTBOTTOMRIGHT
HTCLOSE equ 20
HTHELP equ 21

; child window at point
CWP_ALL equ 0
CWP_SKIPINVISIBLE equ 1
CWP_SKIPDISABLED equ 2
CWP_SKIPTRANSPARENT equ 4

%endif

;=============================================================================
%ifdef UseResources
RT_CURSOR       equ 1
RT_BITMAP       equ 2
RT_ICON         equ 3
RT_MENU         equ 4
RT_DIALOG       equ 5
RT_STRING       equ 6
RT_FONTDIR      equ 7
RT_FONT         equ 8
RT_ACCELERATOR  equ 9
RT_RCDATA       equ 10
RT_MESSAGETABLE equ 11
RT_GROUP_CURSOR equ 12
RT_GROUP_ICON   equ 14
RT_VERSION      equ 16
RT_DLGINCLUDE   equ 17
RT_PLUGPLAY     equ 19
RT_VXD          equ 20
RT_ANICURSOR    equ 21
RT_ANIICON      equ 22
RT_HTML         equ 23

DONT_RESOLVE_DLL_REFERENCES equ 1
LOAD_LIBRARY_AS_DATAFILE equ 2
LOAD_WITH_ALTERED_SEARCH_PATH equ 8

struc IMAGE_RESOURCE_DATA_ENTRY
.OffsetToData           resd 1
.Size                   resd 1
.CodePage               resd 1
.Reserved               resd 1
endstruc

struc IMAGE_RESOURCE_DIRECTORY
.Characteristics        resd 1
.TimeDateStamp          resd 1
.MajorVersion           resw 1
.MinorVersion           resw 1
.NumberOfNamedEntries   resw 1
.NumberOfIdEntries      resw 1
endstruc

struc IMAGE_RESOURCE_DIRECTORY_ENTRY
.Name                   resd 1
.OffsetToData           resd 1
endstruc

;IDC_ARROW equ 32512
IDC_IBEAM equ 32513
IDC_WAIT equ 32514
IDC_CROSS equ 32515
IDC_UPARROW equ 32516
IDC_HANDWRITING equ 32631
IDC_SIZE equ 32640
IDC_ICON equ 32641
IDC_SIZENWSE equ 32642
IDC_SIZENESW equ 32643
IDC_SIZEWE equ 32644
IDC_SIZENS equ 32645
IDC_SIZEALL equ 32646
IDC_NO equ 32648
IDC_HAND equ 32649
IDC_APPSTARTING equ 32650
IDC_HELP equ 32651

%endif

;=============================================================================
%ifdef UseConsoleDebug
  %define UseTextConsole
%endif

%ifdef UseTextConsole
STD_INPUT_HANDLE equ -10
STD_OUTPUT_HANDLE equ -11
STD_ERROR_HANDLE equ -12

ENABLE_PROCESSED_INPUT equ 1
ENABLE_LINE_INPUT equ 2
ENABLE_ECHO_INPUT equ 4
ENABLE_WINDOW_INPUT equ 8
ENABLE_MOUSE_INPUT equ 16
ENABLE_PROCESSED_OUTPUT equ 1
ENABLE_WRAP_AT_EOL_OUTPUT equ 2

MOUSE_MOVED equ 1h
DOUBLE_CLICK equ 2h
KEY_EVENT equ 1h
mouse_eventC equ 2h
WINDOW_BUFFER_SIZE_EVENT equ 4h
MENU_EVENT equ 8h
FOCUS_EVENT equ 10h
CTRL_C_EVENT equ 0
CTRL_BREAK_EVENT equ 1
CTRL_CLOSE_EVENT equ 2
CTRL_LOGOFF_EVENT equ 5
CTRL_SHUTDOWN_EVENT equ 6

FROM_LEFT_1ST_BUTTON_PRESSED equ 1h
RIGHTMOST_BUTTON_PRESSED equ 2h
FROM_LEFT_2ND_BUTTON_PRESSED equ 4h
FROM_LEFT_3RD_BUTTON_PRESSED equ 8h
FROM_LEFT_4TH_BUTTON_PRESSED equ 10h

FOREGROUND_BLUE equ 1h
FOREGROUND_GREEN equ 2h
FOREGROUND_RED equ 4h
FOREGROUND_INTENSITY equ 8h
BACKGROUND_BLUE equ 10h
BACKGROUND_GREEN equ 20h
BACKGROUND_RED equ 40h
BACKGROUND_INTENSITY equ 80h

struc SMALL_RECT
.left               resw 1
.top                resw 1
.right              resw 1
.bottom             resw 1
endstruc

struc KEY_EVENT_RECORD
.bKeyDown           resd 1
.wRepeatCount       resw 1
.wVirtualKeyCode    resw 1
.wVirtualScanCode   resw 1
.uChar              resw 1
.dwControlKeyState  resd 1
endstruc

struc MOUSE_EVENT_RECORD
.dwMousePosition    resd 1
.dwButtonState      resd 1
.dwControlKeyState  resd 1
.dwEventFlags       resd 1
endstruc

struc WINDOW_BUFFER_SIZE_RECORD
.dwSize             resd 1
endstruc

struc MENU_EVENT_RECORD
.dwCommandId        resd 1
endstruc

struc FOCUS_EVENT_RECORD
.bSetFocus          resd 1
endstruc

struc INPUT_RECORD
.EventType          resd 1      ;MS docs are wrong, not a word
.Event:             resb 16
;.KeyEvent
;.MouseEvent
;.WindowBufferSizeEvent
;.MenuEvent
;.FocusEvent
endstruc

struc CHAR_INFO
.Char               resw 1
.Attributes         resw 1
endstruc

struc CONSOLE_SCREEN_BUFFER_INFO
.dwSize             resd 1
.dwCursorPosition   resd 1
.wAttributes        resw 1
.srWindow           resb SMALL_RECT_size
.dwMaximumWindowSize resd 1
endstruc

struc CONSOLE_CURSOR_INFO
.dwSize             resd 1
.bVisible           resd 1
endstruc

%endif


;=============================================================================
%ifdef UseWindowPaint
; Window painting and redrawing

; RedrawWindow
RDW_INVALIDATE equ 1
RDW_INTERNALPAINT equ 2
RDW_ERASE equ 4
RDW_VALIDATE equ 8
RDW_NOINTERNALPAINT equ 16
RDW_NOERASE equ 32
RDW_NOCHILDREN equ 64
RDW_ALLCHILDREN equ 128
RDW_UPDATENOW equ 256
RDW_ERASENOW equ 512
RDW_FRAME equ 1024
RDW_NOFRAME equ 2048

DFC_CAPTION equ 1
DFC_MENU equ 2
DFC_SCROLL equ 3
DFC_BUTTON equ 4
DFC_POPUPMENU equ 5

DFCS_CAPTIONCLOSE equ 0000h
DFCS_CAPTIONMIN equ 0001h
DFCS_CAPTIONMAX equ 0002h
DFCS_CAPTIONRESTORE equ 0003h
DFCS_CAPTIONHELP equ 0004h

DFCS_MENUARROW equ 0000h
DFCS_MENUCHECK equ 0001h
DFCS_MENUBULLET equ 0002h
DFCS_MENUARROWRIGHT equ 0004h
DFCS_SCROLLUP equ 0000h
DFCS_SCROLLDOWN equ 0001h
DFCS_SCROLLLEFT equ 0002h
DFCS_SCROLLRIGHT equ 0003h
DFCS_SCROLLCOMBOBOX equ 0005h
DFCS_SCROLLSIZEGRIP equ 0008h
DFCS_SCROLLSIZEGRIPRIGHT equ 0010h

DFCS_BUTTONCHECK equ 0000h
DFCS_BUTTONRADIOIMAGE equ 0001h
DFCS_BUTTONRADIOMASK equ 0002h
DFCS_BUTTONRADIO equ 0004h
DFCS_BUTTON3STATE equ 0008h
DFCS_BUTTONPUSH equ 0010h

DFCS_INACTIVE equ 0100h
DFCS_PUSHED equ 0200h
DFCS_CHECKED equ 0400h

DFCS_TRANSPARENT equ 0800h
DFCS_HOT equ 1000h

DFCS_ADJUSTRECT equ 2000h
DFCS_FLAT equ 4000h
DFCS_MONO equ 8000h

%endif


;=============================================================================
%ifdef UseWindowGfx
COLOR_SCROLLBAR equ 0
COLOR_BACKGROUND equ 1
COLOR_ACTIVECAPTION equ 2
COLOR_INACTIVECAPTION equ 3
COLOR_MENU equ 4
COLOR_WINDOW equ 5
COLOR_WINDOWFRAME equ 6
COLOR_MENUTEXT equ 7
COLOR_WINDOWTEXT equ 8
COLOR_CAPTIONTEXT equ 9
COLOR_ACTIVEBORDER equ 10
COLOR_INACTIVEBORDER equ 11
COLOR_APPWORKSPACE equ 12
COLOR_HIGHLIGHT equ 13
COLOR_HIGHLIGHTTEXT equ 14
;COLOR_BTNFACE equ 15
COLOR_BTNSHADOW equ 16
COLOR_GRAYTEXT equ 17
COLOR_BTNTEXT equ 18
COLOR_INACTIVECAPTIONTEXT equ 19
COLOR_BTNHIGHLIGHT equ 20
COLOR_3DDKSHADOW equ 21
COLOR_3DLIGHT equ 22
COLOR_INFOTEXT equ 23
COLOR_INFOBK equ 24
COLOR_HOTLIGHT equ 26
COLOR_GRADIENTACTIVECAPTION equ 27
COLOR_GRADIENTINACTIVECAPTION equ 28
COLOR_DESKTOP equ COLOR_BACKGROUND
COLOR_3DFACE equ COLOR_BTNFACE
COLOR_3DSHADOW equ COLOR_BTNSHADOW
COLOR_3DHIGHLIGHT equ COLOR_BTNHIGHLIGHT
COLOR_3DHILIGHT equ COLOR_BTNHIGHLIGHT
COLOR_BTNHILIGHT equ COLOR_BTNHIGHLIGHT

struc PAINTSTRUCT
.hdc            resd 1
.fErase         resd 1
.rcPaint:
.left           resd 1
.top            resd 1
.right          resd 1
.bottom         resd 1
.fRestore       resd 1
.fIncUpdate     resd 1
.rgbReserved    resb 32
endstruc

; BitBlt
SRCCOPY equ $0cc0020            ;dest = source
SRCPAINT equ $0ee0086           ;dest = source OR dest
SRCAND equ $8800c6              ;dest = source AND dest
SRCINVERT equ $660046           ;dest = source XOR dest
SRCERASE equ $440328            ;dest = source AND (NOT dest)
NOTSRCCOPY equ $330008          ;dest = (NOT source)
NOTSRCERASE equ $1100a6         ;dest = (NOT src) AND (NOT dest)
MERGECOPY equ $0c000ca          ;dest = (source AND pattern)
MERGEPAINT equ $0bb0226         ;dest = (NOT source) OR dest
PATCOPY equ $0f00021            ;dest = pattern
PATPAINT equ $0fb0a09           ;dest = DPSnoo
PATINVERT equ $5a0049           ;dest = pattern XOR dest
DSTINVERT equ $550009           ;dest = (NOT dest)
BLACKNESS equ $42               ;dest = BLACK
WHITENESS equ $0ff0062          ;dest = WHITE
NOMIRRORBITMAP equ $80000000    ;

CBM_INIT equ 4
DIB_RGB_COLORS equ 0
DIB_PAL_COLORS equ 1

BI_RGB equ 0
BI_RLE8 equ 1
BI_RLE4 equ 2
BI_BITFIELDS equ 3
BI_JPEG equ 4
BI_PNG equ 5

struc BITMAPFILEHEADER
.bfType         resw 1 ;BM
.bfSize         resd 1
.bfReserved1    resw 1
.bfReserved2    resw 1
.bfOffBits      resd 1
endstruc

struc BITMAPINFOHEADER
.biSize             resd 1
.biWidth            resd 1
.biHeight           resd 1
.biPlanes           resw 1
.biBitCount         resw 1
.biCompression      resd 1
.biSizeImage        resd 1
.biXPelsPerMeter    resd 1
.biYPelsPerMeter    resd 1
.biClrUsed          resd 1
.biClrImportant     resd 1
endstruc

struc LOGPALETTE
.palVersion         resw 1
.palNumEntries      resw 1
.palPalEntry        resd 1
endstruc

struc RGBQUAD
.rgbRed             resb 1
.rgbGreen           resb 1
.rgbBlue            resb 1
.rgbFlags           resb 1
endstruc

PC_RESERVED equ 1
PC_EXPLICIT equ 2
PC_NOCOLLAPSE equ 4

; GetCurrentObject
OBJ_PEN equ 1
OBJ_BRUSH equ 2
OBJ_DC equ 3
OBJ_METADC equ 4
OBJ_PAL equ 5
OBJ_FONT equ 6
OBJ_BITMAP equ 7
OBJ_REGION equ 8
OBJ_METAFILE equ 9
OBJ_MEMDC equ 10
OBJ_EXTPEN equ 11
OBJ_ENHMETADC equ 12
OBJ_ENHMETAFILE equ 13

; GetStockObject
WHITE_BRUSH equ 0
LTGRAY_BRUSH equ 1
GRAY_BRUSH equ 2
DKGRAY_BRUSH equ 3
BLACK_BRUSH equ 4
NULL_BRUSH equ 5
HOLLOW_BRUSH equ NULL_BRUSH
WHITE_PEN equ 6
BLACK_PEN equ 7
NULL_PEN equ 8
OEM_FIXED_FONT equ 10
ANSI_FIXED_FONT equ 11
ANSI_VAR_FONT equ 12
SYSTEM_FONT equ 13
DEVICE_DEFAULT_FONT equ 14
DEFAULT_PALETTE equ 15
SYSTEM_FIXED_FONT equ 16
;DEFAULT_GUI_FONT equ 17
DC_BRUSH equ 18
DC_PEN equ 19
STOCK_LAST equ 19

; CreatePen
PS_SOLID equ 0
PS_DASH equ 1
PS_DOT equ 2
PS_DASHDOT equ 3
PS_DASHDOTDOT equ 4
PS_NULL equ 5
PS_INSIDEFRAME equ 6
PS_USERSTYLE equ 7
PS_ALTERNATE equ 8
PS_STYLE_MASK equ 15
PS_ENDCAP_ROUND equ 0
PS_ENDCAP_SQUARE equ 256
PS_ENDCAP_FLAT equ 512
PS_ENDCAP_MASK equ 3840
PS_JOIN_ROUND equ 0
PS_JOIN_BEVEL equ 4096
PS_JOIN_MITER equ 8192
PS_JOIN_MASK equ 61440
PS_COSMETIC equ 0
PS_GEOMETRIC equ 65536
PS_TYPE_MASK equ 983040

BKMODE_TRANSPARENT equ 1
BKMODE_OPAQUE equ 2
BKMODE_LAST equ 2

; LoadImage
IMAGE_BITMAP equ 0
IMAGE_ICON equ 1
IMAGE_CURSOR equ 2
IMAGE_ENHMETAFILE equ 3
LR_DEFAULTCOLOR equ 0
LR_MONOCHROME equ 1
LR_COLOR equ 2
LR_COPYRETURNORG equ 4
LR_COPYDELETEORG equ 8
LR_LOADFROMFILE equ 16
LR_LOADTRANSPARENT equ 32
LR_DEFAULTSIZE equ 64
LR_VGACOLOR equ 128
LR_LOADMAP3DCOLORS equ 4096
LR_CREATEDIBSECTION equ 8192
LR_COPYFROMRESOURCE equ 16384
LR_SHARED equ 32768

; LOGCOLORSPACE
LCS_CALIBRATED_RGB equ 0
LCS_GM_BUSINESS equ 1
LCS_GM_GRAPHICS equ 2
LCS_GM_IMAGES equ 4
LCS_GM_ABS_COLORIMETRIC equ 8
LCS_SIGNATURE equ 'PSOC'
LCS_sRGB equ 'sRGB'
LCS_WINDOWS_COLOR_SPACE equ 'Win '

; GetDCEx
DCX_WINDOW equ 1
DCX_CACHE equ 2
DCX_NORESETATTRS equ 4
DCX_CLIPCHILDREN equ 8
DCX_CLIPSIBLINGS equ 16
DCX_PARENTCLIP equ 32
DCX_EXCLUDERGN equ 64
DCX_INTERSECTRGN equ 128
DCX_EXCLUDEUPDATE equ 256
DCX_INTERSECTUPDATE equ 512
DCX_LOCKWINDOWUPDATE equ 1024
DCX_VALIDATE equ 2097152

; SetSystemPaletteUse
SYSPAL_ERROR equ 0
SYSPAL_STATIC equ 1
SYSPAL_NOSTATIC equ 2
SYSPAL_NOSTATIC256 equ 3

; SetTextAlign
TA_NOUPDATECP equ 0
TA_UPDATECP equ 1
TA_LEFT equ 0
TA_RIGHT equ 2
TA_CENTER equ 6
TA_TOP equ 0
TA_BOTTOM equ 8
TA_BASELINE equ 24
TA_RTLREADING equ 256
TA_MASK equ TA_BASELINE+TA_CENTER+TA_UPDATECP+TA_RTLREADING

; DrawText
DT_TOP              equ 00000000h
DT_LEFT             equ 00000000h
DT_CENTER           equ 00000001h
DT_RIGHT            equ 00000002h
DT_VCENTER          equ 00000004h
DT_BOTTOM           equ 00000008h
DT_WORDBREAK        equ 00000010h
DT_SINGLELINE       equ 00000020h
DT_EXPANDTABS       equ 00000040h
DT_TABSTOP          equ 00000080h
DT_NOCLIP           equ 00000100h
DT_EXTERNALLEADING  equ 00000200h
DT_CALCRECT         equ 00000400h
DT_NOPREFIX         equ 00000800h
DT_INTERNAL         equ 00001000h
DT_EDITCONTROL      equ 00002000h
DT_PATH_ELLIPSIS    equ 00004000h
DT_END_ELLIPSIS     equ 00008000h
DT_MODIFYSTRING     equ 00010000h
DT_RTLREADING       equ 00020000h
DT_WORD_ELLIPSIS    equ 00040000h


; 3D border styles
BDR_RAISEDOUTER equ 1
BDR_SUNKENOUTER equ 2
BDR_RAISEDINNER equ 4
BDR_SUNKENINNER equ 8

; Border flags
BF_LEFT equ 1
BF_TOP equ 2
BF_RIGHT equ 4
BF_BOTTOM equ 8

BF_TOPLEFT equ (BF_TOP | BF_LEFT)
BF_TOPRIGHT equ (BF_TOP | BF_RIGHT)
BF_BOTTOMLEFT equ (BF_BOTTOM | BF_LEFT)
BF_BOTTOMRIGHT equ (BF_BOTTOM | BF_RIGHT)
BF_RECT equ (BF_LEFT | BF_TOP | BF_RIGHT | BF_BOTTOM)

BF_DIAGONAL equ 10h

; For diagonal lines, the BF_RECT flags specify the end point of the
; vector bounded by the rectangle parameter.
BF_DIAGONAL_ENDTOPRIGHT equ    (BF_DIAGONAL | BF_TOP | BF_RIGHT)
BF_DIAGONAL_ENDTOPLEFT equ     (BF_DIAGONAL | BF_TOP | BF_LEFT)
BF_DIAGONAL_ENDBOTTOMLEFT equ  (BF_DIAGONAL | BF_BOTTOM | BF_LEFT)
BF_DIAGONAL_ENDBOTTOMRIGHT equ (BF_DIAGONAL | BF_BOTTOM | BF_RIGHT)

BF_MIDDLE equ 0800h ;Fill in the middle
BF_SOFT equ   1000h ;For softer buttons
BF_ADJUST equ 2000h ;Calculate the space left over
BF_FLAT equ   4000h ;For flat rather than 3D borders
BF_MONO equ   8000h ;For monochrome borders

%endif

;=============================================================================
%ifdef UseGdiFonts

OUT_DEFAULT_PRECIS        equ 0
OUT_STRING_PRECIS         equ 1
OUT_CHARACTER_PRECIS      equ 2
OUT_STROKE_PRECIS         equ 3
OUT_TT_PRECIS             equ 4
OUT_DEVICE_PRECIS         equ 5
OUT_RASTER_PRECIS         equ 6
OUT_TT_ONLY_PRECIS        equ 7
OUT_OUTLINE_PRECIS        equ 8
OUT_SCREEN_OUTLINE_PRECIS equ 9
OUT_PS_ONLY_PRECIS        equ 10

CLIP_DEFAULT_PRECIS   equ 0
CLIP_CHARACTER_PRECIS equ 1
CLIP_STROKE_PRECIS    equ 2
CLIP_MASK             equ 0xf
CLIP_LH_ANGLES        equ (1<<4)
CLIP_TT_ALWAYS        equ (2<<4)
CLIP_EMBEDDED         equ (8<<4)

DEFAULT_QUALITY        equ 0
DRAFT_QUALITY          equ 1
PROOF_QUALITY          equ 2
NONANTIALIASED_QUALITY equ 3
ANTIALIASED_QUALITY    equ 4

DEFAULT_PITCH          equ 0
FIXED_PITCH            equ 1
VARIABLE_PITCH         equ 2
MONO_FONT              equ 8

ANSI_CHARSET           equ 0
DEFAULT_CHARSET        equ 1
SYMBOL_CHARSET         equ 2
SHIFTJIS_CHARSET       equ 128
HANGEUL_CHARSET        equ 129
HANGUL_CHARSET         equ 129
GB2312_CHARSET         equ 134
CHINESEBIG5_CHARSET    equ 136
OEM_CHARSET            equ 255

JOHAB_CHARSET          equ 130
HEBREW_CHARSET         equ 177
ARABIC_CHARSET         equ 178
GREEK_CHARSET          equ 161
TURKISH_CHARSET        equ 162
VIETNAMESE_CHARSET     equ 163
THAI_CHARSET           equ 222
EASTEUROPE_CHARSET     equ 238
RUSSIAN_CHARSET        equ 204

FS_LATIN1              equ 1
FS_LATIN2              equ 2h
FS_CYRILLIC            equ 4h
FS_GREEK               equ 8h
FS_TURKISH             equ 10h
FS_HEBREW              equ 20h
FS_ARABIC              equ 40h
FS_BALTIC              equ 80h
FS_VIETNAMESE          equ 100h
FS_THAI                equ 10000h
FS_JISJAPAN            equ 20000h
FS_CHINESESIMP         equ 40000h
FS_WANSUNG             equ 80000h
FS_CHINESETRAD         equ 100000h
FS_JOHAB               equ 200000h
FS_SYMBOL              equ 80000000h

; Font Families
FF_DONTCARE         equ (0<<4)  ; Don't care or don't know.
FF_ROMAN            equ (1<<4)  ; Variable stroke width, serifed.
                                    ; Times Roman, Century Schoolbook, etc.
FF_SWISS            equ (2<<4)  ; Variable stroke width, sans-serifed.
                                    ; Helvetica, Swiss, etc.
FF_MODERN           equ (3<<4)  ; Constant stroke width, serifed or sans-serifed.
                                    ; Pica, Elite, Courier, etc.
FF_SCRIPT           equ (4<<4)  ; Cursive, etc.
FF_DECORATIVE       equ (5<<4)  ; Old English, etc.

; Font Weights
FW_DONTCARE         equ 0
FW_THIN             equ 100
FW_EXTRALIGHT       equ 200
FW_LIGHT            equ 300
FW_NORMAL           equ 400
FW_MEDIUM           equ 500
FW_SEMIBOLD         equ 600
FW_BOLD             equ 700
FW_EXTRABOLD        equ 800
FW_HEAVY            equ 900

FW_ULTRALIGHT       equ FW_EXTRALIGHT
FW_REGULAR          equ FW_NORMAL
FW_DEMIBOLD         equ FW_SEMIBOLD
FW_ULTRABOLD        equ FW_EXTRABOLD
FW_BLACK            equ FW_HEAVY

struc LOGFONT
.Height         resd 1
.Width          resd 1
.Escapement     resd 1
.Orientation    resd 1
.Weight         resd 1
.Italic         resb 1
.Underline      resb 1
.StrikeOut      resb 1
.CharSet        resb 1
.OutPrecision   resb 1
.ClipPrecision  resb 1
.Quality        resb 1
.PitchAndFamily resb 1
.FaceName       resb 32
endstruc
%endif

;=============================================================================

;=============================================================================
%ifdef UseDxDraw

; DirectDraw interface
struc IDirectDraw
.QueryInterface         resd 1
.AddRef                 resd 1
.Release                resd 1
.Compact                resd 1
.CreateClipper          resd 1
.CreatePalette          resd 1
.CreateSurface          resd 1
.DuplicateSurface       resd 1
.EnumDisplayModes       resd 1
.EnumSurfaces           resd 1
.FlipToGDISurface       resd 1
.GetCaps                resd 1
.GetDisplayMode         resd 1
.GetFourCCCodes         resd 1
.GetGDISurface          resd 1
.GetMonitorFrequency    resd 1
.GetScanLine            resd 1
.GetVerticalBlankStatus resd 1
.Initialize             resd 1
.RestoreDisplayMode     resd 1
.SetCooperativeLevel    resd 1
.SetDisplayMode         resd 1
.WaitForVerticalBlank   resd 1
; added in v2 interface:
.GetAvailableVidMem     resd 1
; added in v4 interface:
.GetSurfaceFromDC       resd 1
.RestoreAllSurfaces     resd 1
.TestCooperativeLevel   resd 1
.GetDeviceIdentifier    resd 1
.StartModeTest          resd 1
.EvaluateMode           resd 1
endstruc

struc IDirectDrawSurface
.QueryInterface         resd 1
.AddRef                 resd 1
.Release                resd 1
.AddAttachedSurface     resd 1
.AddOverlayDirtyRect    resd 1
.Blt                    resd 1
.BltBatch               resd 1
.BltFast                resd 1
.DeleteAttachedSurface  resd 1
.EnumAttachedSurfaces   resd 1
.EnumOverlayZOrders     resd 1
.Flip                   resd 1
.GetAttachedSurface     resd 1
.GetBltStatus           resd 1
.GetCaps                resd 1
.GetClipper             resd 1
.GetColorKey            resd 1
.GetDC                  resd 1
.GetFlipStatus          resd 1
.GetOverlayPosition     resd 1
.GetPalette             resd 1
.GetPixelFormat         resd 1
.GetSurfaceDesc         resd 1
.Initialize             resd 1
.IsLost                 resd 1
.Lock                   resd 1
.ReleaseDC              resd 1
.Restore                resd 1
.SetClipper             resd 1
.SetColorKey            resd 1
.SetOverlayPosition     resd 1
.SetPalette             resd 1
.Unlock                 resd 1
.UpdateOverlay          resd 1
.UpdateOverlayDisplay   resd 1
.UpdateOverlayZOrder    resd 1
; added in v2 interface:
.GetDDInterface         resd 1
.PageLock               resd 1
.PageUnlock             resd 1
; added in v3 interface:
.SetSurfaceDesc         resd 1
; added in v4 interface:
.SetPrivateData         resd 1
.GetPrivateData         resd 1
.FreePrivateData        resd 1
.GetUniquenessValue     resd 1
.ChangeUniquenessValue  resd 1
; added in v7 interface:
.SetPriority            resd 1
.GetPriority            resd 1
.SetLOD                 resd 1
.GetLOD                 resd 1
endstruc

struc IDirectDrawPalette
.QueryInterface         resd 1
.AddRef                 resd 1
.Release                resd 1
.GetCaps                resd 1
.GetEntries             resd 1
.Initialize             resd 1
.SetEntries             resd 1
endstruc

struc IDirectDrawClipper
.QueryInterface         resd 1
.AddRef                 resd 1
.Release                resd 1
.GetClipList            resd 1
.GetHWnd                resd 1
.Initialize             resd 1
.IsClipListChanged      resd 1
.SetClipList            resd 1
.SetHWnd                resd 1
endstruc

struc IDirectDrawColorControl
.QueryInterface         resd 1
.AddRef                 resd 1
.Release                resd 1
.GetColorControls       resd 1
.SetColorControls       resd 1
endstruc

struc IDirectDrawGammaControl
.QueryInterface         resd 1
.AddRef                 resd 1
.Release                resd 1
.GetGammaRamp           resd 1
.SetGammaRamp           resd 1
endstruc

struc DDCOLORKEY
.dwColorSpaceLowValue   resd 1
.dwColorSpaceHighValue  resd 1
endstruc

struc DDPIXELFORMAT
.dwSize             resd 1
.dwFlags            resd 1
.dwFourCC           resd 1
.dwYUVBitCount:             ;(these four are unioned)
.dwZBufferBitDepth:
.dwAlphaBitDepth:
.dwRGBBitCount      resd 1
.dwRBitMask:
.dwYBitMask         resd 1
.dwGBitMask:
.dwUBitMask         resd 1
.dwBBitMask:
.dwVBitMask         resd 1
.dwYUVAlphaBitMask:
.dwRGBZBitMask:
.dwYUVZBitMask:
.dwRGBAlphaBitMask  resd 1
endstruc

struc DDSCAPS
.dwCaps             resd 1
endstruc

struc DDSURFACEDESC
.dwSize             resd 1
.dwFlags            resd 1
.dwHeight           resd 1
.dwWidth            resd 1
.lPitch:
.dwLinearSize       resd 1
.dwBackBufferCount  resd 1
.dwMipMapCount:
.dwZBufferBitDepth:
.dwRefreshRate      resd 1
.dwAlphaBitDepth    resd 1
.dwReserved         resd 1
.lpSurface          resd 1
.ddckCKDestOverlay  resb DDCOLORKEY_size
.ddckCKDestBlt      resb DDCOLORKEY_size
.ddckCKSrcOverlay   resb DDCOLORKEY_size
.ddckCKSrcBlt       resb DDCOLORKEY_size
.ddpfPixelFormat    resb DDPIXELFORMAT_size
.ddsCaps            resb DDSCAPS_size
endstruc

; SetCooperativeLevel flags
DDSCL_FULLSCREEN            equ 000000001h
DDSCL_ALLOWREBOOT           equ 000000002h
DDSCL_NOWINDOWCHANGES       equ 000000004h
DDSCL_NORMAL                equ 000000008h
DDSCL_EXCLUSIVE             equ 000000010h
DDSCL_ALLOWMODEX            equ 000000040h
DDSCL_SETFOCUSWINDOW        equ 00000080h   ;this window will receive the focus messages
DDSCL_SETDEVICEWINDOW       equ 00000100h   ;this window is associated with the DDRAW object and will cover the screen in fullscreen mode
DDSCL_CREATEDEVICEWINDOW    equ 00000200h   ;app wants DDRAW to create a window to be associated with the DDRAW object

; Blt flags
DDBLT_ALPHADEST                  equ 000000001h
DDBLT_ALPHADESTCONSTOVERRIDE     equ 000000002h
DDBLT_ALPHADESTNEG               equ 000000004h
DDBLT_ALPHADESTSURFACEOVERRIDE   equ 000000008h
DDBLT_ALPHAEDGEBLEND             equ 000000010h
DDBLT_ALPHASRC                   equ 000000020h
DDBLT_ALPHASRCCONSTOVERRIDE      equ 000000040h
DDBLT_ALPHASRCNEG                equ 000000080h
DDBLT_ALPHASRCSURFACEOVERRIDE    equ 000000100h
DDBLT_ASYNC                      equ 000000200h
DDBLT_COLORFILL                  equ 000000400h
DDBLT_DDFX                       equ 000000800h
DDBLT_DDROPS                     equ 000001000h
DDBLT_KEYDEST                    equ 000002000h
DDBLT_KEYDESTOVERRIDE            equ 000004000h
DDBLT_KEYSRC                     equ 000008000h
DDBLT_KEYSRCOVERRIDE             equ 000010000h
DDBLT_ROP                        equ 000020000h
DDBLT_ROTATIONANGLE              equ 000040000h
DDBLT_ZBUFFER                    equ 000080000h
DDBLT_ZBUFFERDESTCONSTOVERRIDE   equ 000100000h
DDBLT_ZBUFFERDESTOVERRIDE        equ 000200000h
DDBLT_ZBUFFERSRCCONSTOVERRIDE    equ 000400000h
DDBLT_ZBUFFERSRCOVERRIDE         equ 000800000h
DDBLT_WAIT                       equ 001000000h
DDBLT_DEPTHFILL                  equ 002000000h

; BltFast flags
DDBLTFAST_NOCOLORKEY        equ 000000000h
DDBLTFAST_SRCCOLORKEY       equ 000000001h
DDBLTFAST_DESTCOLORKEY      equ 000000002h
DDBLTFAST_WAIT              equ 000000010h

; Flip flags
DDFLIP_WAIT   equ 000000001h
DDFLIP_EVEN   equ 000000002h
DDFLIP_ODD    equ 000000004h

DDSD_CAPS                   equ 000000001h
DDSD_HEIGHT                 equ 000000002h
DDSD_WIDTH                  equ 000000004h
DDSD_PITCH                  equ 000000008h
DDSD_BACKBUFFERCOUNT        equ 000000020h
DDSD_ZBUFFERBITDEPTH        equ 000000040h
DDSD_ALPHABITDEPTH          equ 000000080h
DDSD_LPSURFACE              equ 000000800h
DDSD_PIXELFORMAT            equ 000001000h
DDSD_CKDESTOVERLAY          equ 000002000h
DDSD_CKDESTBLT              equ 000004000h
DDSD_CKSRCOVERLAY           equ 000008000h
DDSD_CKSRCBLT               equ 000010000h
DDSD_MIPMAPCOUNT            equ 000020000h
DDSD_REFRESHRATE            equ 000040000h
DDSD_LINEARSIZE             equ 000080000h
DDSD_ALL                    equ 0000FF9EEh

; DirectDrawSurface capability flags
DDSCAPS_RESERVED1           equ 000000001h
DDSCAPS_ALPHA               equ 000000002h
DDSCAPS_BACKBUFFER          equ 000000004h
DDSCAPS_COMPLEX             equ 000000008h
DDSCAPS_FLIP                equ 000000010h
DDSCAPS_FRONTBUFFER         equ 000000020h
DDSCAPS_OFFSCREENPLAIN      equ 000000040h
DDSCAPS_OVERLAY             equ 000000080h
DDSCAPS_PALETTE             equ 000000100h
DDSCAPS_PRIMARYSURFACE      equ 000000200h
DDSCAPS_PRIMARYSURFACELEFT  equ 000000400h
DDSCAPS_SYSTEMMEMORY        equ 000000800h
DDSCAPS_TEXTURE             equ 000001000h
DDSCAPS_3DDEVICE            equ 000002000h
DDSCAPS_VIDEOMEMORY         equ 000004000h
DDSCAPS_VISIBLE             equ 000008000h
DDSCAPS_WRITEONLY           equ 000010000h
DDSCAPS_ZBUFFER             equ 000020000h
DDSCAPS_OWNDC               equ 000040000h
DDSCAPS_LIVEVIDEO           equ 000080000h
DDSCAPS_HWCODEC             equ 000100000h
DDSCAPS_MODEX               equ 000200000h
DDSCAPS_MIPMAP              equ 000400000h
DDSCAPS_RESERVED2           equ 000800000h
DDSCAPS_ALLOCONLOAD         equ 004000000h
DDSCAPS_VIDEOPORT           equ 008000000h
DDSCAPS_LOCALVIDMEM         equ 010000000h
DDSCAPS_NONLOCALVIDMEM      equ 020000000h
DDSCAPS_STANDARDVGAMODE     equ 040000000h
DDSCAPS_OPTIMIZED           equ 080000000h

; DirectDrawSurface lock flags
DDLOCK_SURFACEMEMORYPTR     equ 000000000h
DDLOCK_WAIT                 equ 000000001h
DDLOCK_EVENT                equ 000000002h
DDLOCK_READONLY             equ 000000010h
DDLOCK_WRITEONLY            equ 000000020h
DDLOCK_NOSYSLOCK            equ 000000800h

; DirectDrawPalette capabilities
DDPCAPS_4BIT                equ 000000001h
DDPCAPS_8BITENTRIES         equ 000000002h
DDPCAPS_8BIT                equ 000000004h
DDPCAPS_INITIALIZE          equ 000000008h
DDPCAPS_PRIMARYSURFACE      equ 000000010h
DDPCAPS_PRIMARYSURFACELEFT  equ 000000020h
DDPCAPS_ALLOW256            equ 000000040h
DDPCAPS_VSYNC               equ 000000080h
DDPCAPS_1BIT                equ 000000100h
DDPCAPS_2BIT                equ 000000200h

; DirectDraw errors
DDERR_ALREADYINITIALIZED          equ 088760000h+5
DDERR_CANNOTATTACHSURFACE         equ 088760000h+10
DDERR_CANNOTDETACHSURFACE         equ 088760000h+20
DDERR_CURRENTLYNOTAVAIL           equ 088760000h+40
DDERR_EXCEPTION                   equ 088760000h+55
DDERR_HEIGHTALIGN                 equ 088760000h+90
DDERR_INCOMPATIBLEPRIMARY         equ 088760000h+95
DDERR_INVALIDCAPS                 equ 088760000h+100
DDERR_INVALIDCLIPLIST             equ 088760000h+110
DDERR_INVALIDMODE                 equ 088760000h+120
DDERR_INVALIDOBJECT               equ 088760000h+130
DDERR_INVALIDPIXELFORMAT          equ 088760000h+145
DDERR_INVALIDRECT                 equ 088760000h+150
DDERR_LOCKEDSURFACES              equ 088760000h+160
DDERR_NO3D                        equ 088760000h+170
DDERR_NOALPHAHW                   equ 088760000h+180
DDERR_NOCLIPLIST                  equ 088760000h+205
DDERR_NOCOLORCONVHW               equ 088760000h+210
DDERR_NOCOOPERATIVELEVELSET       equ 088760000h+212
DDERR_NOCOLORKEY                  equ 088760000h+215
DDERR_NOCOLORKEYHW                equ 088760000h+220
DDERR_NODIRECTDRAWSUPPORT         equ 088760000h+222
DDERR_NOEXCLUSIVEMODE             equ 088760000h+225
DDERR_NOFLIPHW                    equ 088760000h+230
DDERR_NOGDI                       equ 088760000h+240
DDERR_NOMIRRORHW                  equ 088760000h+250
DDERR_NOTFOUND                    equ 088760000h+255
DDERR_NOOVERLAYHW                 equ 088760000h+260
DDERR_NORASTEROPHW                equ 088760000h+280
DDERR_NOROTATIONHW                equ 088760000h+290
DDERR_NOSTRETCHHW                 equ 088760000h+310
DDERR_NOT4BITCOLOR                equ 088760000h+316
DDERR_NOT4BITCOLORINDEX           equ 088760000h+317
DDERR_NOT8BITCOLOR                equ 088760000h+320
DDERR_NOTEXTUREHW                 equ 088760000h+330
DDERR_NOVSYNCHW                   equ 088760000h+335
DDERR_NOZBUFFERHW                 equ 088760000h+340
DDERR_NOZOVERLAYHW                equ 088760000h+350
DDERR_OUTOFCAPS                   equ 088760000h+360
DDERR_OUTOFVIDEOMEMORY            equ 088760000h+380
DDERR_OVERLAYCANTCLIP             equ 088760000h+382
DDERR_OVERLAYCOLORKEYONLYONEACTI  equ 088760000h+384
DDERR_PALETTEBUSY                 equ 088760000h+387
DDERR_COLORKEYNOTSET              equ 088760000h+400
DDERR_SURFACEALREADYATTACHED      equ 088760000h+410
DDERR_SURFACEALREADYDEPENDENT     equ 088760000h+420
DDERR_SURFACEBUSY                 equ 088760000h+430
DDERR_CANTLOCKSURFACE             equ 088760000h+435
DDERR_SURFACEISOBSCURED           equ 088760000h+440
DDERR_SURFACELOST                 equ 088760000h+450
DDERR_SURFACENOTATTACHED          equ 088760000h+460
DDERR_TOOBIGHEIGHT                equ 088760000h+470
DDERR_TOOBIGSIZE                  equ 088760000h+480
DDERR_TOOBIGWIDTH                 equ 088760000h+490
DDERR_UNSUPPORTEDFORMAT           equ 088760000h+510
DDERR_UNSUPPORTEDMASK             equ 088760000h+520
DDERR_VERTICALBLANKINPROGRESS     equ 088760000h+537
DDERR_WASSTILLDRAWING             equ 088760000h+540
DDERR_XALIGN                      equ 088760000h+560
DDERR_INVALIDDIRECTDRAWGUID       equ 088760000h+561
DDERR_DIRECTDRAWALREADYCREATED    equ 088760000h+562
DDERR_NODIRECTDRAWHW              equ 088760000h+563
DDERR_PRIMARYSURFACEALREADYEXIST  equ 088760000h+564
DDERR_NOEMULATION                 equ 088760000h+565
DDERR_REGIONTOOSMALL              equ 088760000h+566
DDERR_CLIPPERISUSINGHWND          equ 088760000h+567
DDERR_NOCLIPPERATTACHED           equ 088760000h+568
DDERR_NOHWND                      equ 088760000h+569
DDERR_HWNDSUBCLASSED              equ 088760000h+570
DDERR_HWNDALREADYSET              equ 088760000h+571
DDERR_NOPALETTEATTACHED           equ 088760000h+572
DDERR_NOPALETTEHW                 equ 088760000h+573
DDERR_BLTFASTCANTCLIP             equ 088760000h+574
DDERR_NOBLTHW                     equ 088760000h+575
DDERR_NODDROPSHW                  equ 088760000h+576
DDERR_OVERLAYNOTVISIBLE           equ 088760000h+577
DDERR_NOOVERLAYDEST               equ 088760000h+578
DDERR_INVALIDPOSITION             equ 088760000h+579
DDERR_NOTAOVERLAYSURFACE          equ 088760000h+580
DDERR_EXCLUSIVEMODEALREADYSET     equ 088760000h+581
DDERR_NOTFLIPPABLE                equ 088760000h+582
DDERR_CANTDUPLICATE               equ 088760000h+583
DDERR_NOTLOCKED                   equ 088760000h+584
DDERR_CANTCREATEDC                equ 088760000h+585
DDERR_NODC                        equ 088760000h+586
DDERR_WRONGMODE                   equ 088760000h+587
DDERR_IMPLICITLYCREATED           equ 088760000h+588
DDERR_NOTPALETTIZED               equ 088760000h+589
DDERR_UNSUPPORTEDMODE             equ 088760000h+590
DDERR_NOMIPMAPHW                  equ 088760000h+591
DDERR_INVALIDSURFACETYPE          equ 088760000h+592
DDERR_NOOPTIMIZEHW                equ 088760000h+600
DDERR_NOTLOADED                   equ 088760000h+601
DDERR_DCALREADYCREATED            equ 088760000h+620
DDERR_NONONLOCALVIDMEM            equ 088760000h+630
DDERR_CANTPAGELOCK                equ 088760000h+640
DDERR_CANTPAGEUNLOCK              equ 088760000h+660
DDERR_NOTPAGELOCKED               equ 088760000h+680
DDERR_MOREDATA                    equ 088760000h+690
DDERR_VIDEONOTACTIVE              equ 088760000h+695
DDERR_DEVICEDOESNTOWNSURFACE      equ 088760000h+699
%endif

%ifdef UseCom
[section .text]
;=============================================================================
; Safely frees resources used by a COM interface and sets the object pointer
; to null, calling its release function only if isn't already null.
; This way, a COM object can be redundantly released several times without
; causing the program to crash!
;
; (dword com object indirect ptr)
; (HRESULT)
ReleaseCom:
    mov edx,[esp+4]             ;get indirect ptr to COM object
    xor eax,eax
    xchg [edx],eax              ;null COM ptr and get previous
    test eax,eax
    jz .Ret                     ;already null
    mov edx,[eax]               ;get function table
    mov [esp+4],eax             ;pass object
    jmp [edx+8]                 ;call release function
.Ret:
    ret 4
__SECT__
%endif

;=============================================================================
%ifdef UseKeyboard

; Virtual key codes
VK_LBUTTON         equ 0x01
VK_RBUTTON         equ 0x02
VK_CANCEL          equ 0x03
VK_MBUTTON         equ 0x04
;                      0x05-0x07  Undefined
VK_BACK            equ 0x08
VK_TAB             equ 0x09
;                      0x0A-0x0B  Undefined
VK_CLEAR           equ 0x0C
VK_RETURN          equ 0x0D
VK_ENTER           equ 0x0D ;I've seen far more keyboards with 'Enter'
;                      0x0E-0x0F  Undefined
VK_SHIFT           equ 0x10
VK_CONTROL         equ 0x11
VK_MENU            equ 0x12
VK_PAUSE           equ 0x13
VK_CAPITAL         equ 0x14
VK_KANA            equ 0x15
VK_HANGUL          equ 0x15
VK_JUNJA           equ 0x17
VK_FINAL           equ 0x18
VK_HANJA           equ 0x19
VK_KANJI           equ 0x19
;                      0x1A       Undefined
VK_ESCAPE          equ 0x1B

VK_CONVERT         equ 0x1C
VK_NONCONVERT      equ 0x1D
VK_ACCEPT          equ 0x1E
VK_MODECHANGE      equ 0x1F
VK_SPACE           equ 0x20
VK_PRIOR           equ 0x21
VK_PAGEUP          equ 0x21 ;more familiar keyname
VK_NEXT            equ 0x22
VK_PAGEDOWN        equ 0x22 ;more familiar keyname
VK_END             equ 0x23
VK_HOME            equ 0x24
VK_LEFT            equ 0x25
VK_UP              equ 0x26
VK_RIGHT           equ 0x27
VK_DOWN            equ 0x28
VK_SELECT          equ 0x29
VK_PRINT           equ 0x2A ; OEM specific in Windows 3.1 SDK
VK_EXECUTE         equ 0x2B
VK_SNAPSHOT        equ 0x2C
VK_INSERT          equ 0x2D
VK_DELETE          equ 0x2E
VK_HELP            equ 0x2F
VK_0               equ 0x30
VK_1               equ 0x31
VK_2               equ 0x32
VK_3               equ 0x33
VK_4               equ 0x34
VK_5               equ 0x35
VK_6               equ 0x36
VK_7               equ 0x37
VK_8               equ 0x38
VK_9               equ 0x39
;                      0x3A-0x40  Undefined
VK_A               equ 0x41
VK_B               equ 0x42
VK_C               equ 0x43
VK_D               equ 0x44
VK_E               equ 0x45
VK_F               equ 0x46
VK_G               equ 0x47
VK_H               equ 0x48
VK_I               equ 0x49
VK_J               equ 0x4A
VK_K               equ 0x4B
VK_L               equ 0x4C
VK_M               equ 0x4D
VK_N               equ 0x4E
VK_O               equ 0x4F
VK_P               equ 0x50
VK_Q               equ 0x51
VK_R               equ 0x52
VK_S               equ 0x53
VK_T               equ 0x54
VK_U               equ 0x55
VK_V               equ 0x56
VK_W               equ 0x57
VK_X               equ 0x58
VK_Y               equ 0x59
VK_Z               equ 0x5A

VK_LWIN            equ 0x5B
VK_RWIN            equ 0x5C
VK_APPS            equ 0x5D
;                      0x5E-0x5F Unassigned
VK_NUMPAD0         equ 0x60
VK_NUMPAD1         equ 0x61
VK_NUMPAD2         equ 0x62
VK_NUMPAD3         equ 0x63
VK_NUMPAD4         equ 0x64
VK_NUMPAD5         equ 0x65
VK_NUMPAD6         equ 0x66
VK_NUMPAD7         equ 0x67
VK_NUMPAD8         equ 0x68
VK_NUMPAD9         equ 0x69
VK_MULTIPLY        equ 0x6A
VK_ADD             equ 0x6B
VK_SEPARATOR       equ 0x6C
VK_SUBTRACT        equ 0x6D
VK_DECIMAL         equ 0x6E
VK_DIVIDE          equ 0x6F
VK_F1              equ 0x70
VK_F2              equ 0x71
VK_F3              equ 0x72
VK_F4              equ 0x73
VK_F5              equ 0x74
VK_F6              equ 0x75
VK_F7              equ 0x76
VK_F8              equ 0x77
VK_F9              equ 0x78
VK_F10             equ 0x79
VK_F11             equ 0x7A
VK_F12             equ 0x7B
VK_F13             equ 0x7C
VK_F14             equ 0x7D
VK_F15             equ 0x7E
VK_F16             equ 0x7F
VK_F17             equ 0x80
VK_F18             equ 0x81
VK_F19             equ 0x82
VK_F20             equ 0x83
VK_F21             equ 0x84
VK_F22             equ 0x85
VK_F23             equ 0x86
VK_F24             equ 0x87
;                      0x88-0x8F  Unassigned

VK_NUMLOCK         equ 0x90
VK_SCROLL          equ 0x91
;                      0x92-0x9F  Unassigned
VK_LSHIFT          equ 0xA0 ; differencing between right and left
VK_RSHIFT          equ 0xA1 ; shift/control/alt key. Used only by
VK_LCONTROL        equ 0xA2 ; GetAsyncKeyState() and GetKeyState().
VK_RCONTROL        equ 0xA3
VK_LMENU           equ 0xA4
VK_RMENU           equ 0xA5
;                      0xA6-0xB9  Unassigned

; note that I redefined a few of the constants below for more familiar names
; on the standard 101 keyboard
VK_OEM_1           equ 0xBA
VK_COLON           equ 0xBA
VK_OEM_PLUS        equ 0xBB
VK_PLUS            equ 0xBB
VK_OEM_COMMA       equ 0xBC
VK_COMMA           equ 0xBC
VK_OEM_MINUS       equ 0xBD
VK_MINUS           equ 0xBD
VK_OEM_PERIOD      equ 0xBE
VK_PERIOD          equ 0xBE
VK_OEM_2           equ 0xBF
VK_OEM_3           equ 0xC0
VK_TILDE           equ 0xC0
;                      0xC1-0xDA  Unassigned
VK_OEM_4           equ 0xDB
VK_LBRACKET        equ 0xDB
VK_OEM_5           equ 0xDC
VK_SLASH           equ 0xDC
VK_OEM_6           equ 0xDD
VK_RBRACKET        equ 0xDD
VK_OEM_7           equ 0xDE
VK_QUOTE           equ 0xDE
;                      0xDF-0xE4  OEM specific
VK_PROCESSKEY      equ 0xE5
;                      0xE6       OEM specific
;                      0xE7-0xE8  Unassigned
;                      0xE9-0xF5  OEM specific

VK_ATTN            equ 0xF6
VK_CRSEL           equ 0xF7
VK_EXSEL           equ 0xF8
VK_EREOF           equ 0xF9
VK_PLAY            equ 0xFA
VK_ZOOM            equ 0xFB
VK_NONAME          equ 0xFC
VK_PA1             equ 0xFD
VK_OEM_CLEAR       equ 0xFE

; RegisterHotKey
MOD_ALT equ 1
MOD_CONTROL equ 2
MOD_SHIFT equ 4
MOD_WIN equ 8

; Keyboard Layout API
HKL_PREV equ 0
HKL_NEXT equ 1

; Keyboard Load Layout
KLF_ACTIVATE       equ 00000001h
KLF_SUBSTITUTE_OK  equ 00000002h
KLF_UNLOADPREVIOUS equ 00000004h
KLF_REORDER        equ 00000008h
KLF_REPLACELANG    equ 00000010h
KLF_NOTELLSHELL    equ 00000080h
KLF_SETFORPROCESS  equ 00000100h

%endif

;=============================================================================
%ifdef UseWindowHooks

WH_MIN equ -1
WH_MSGFILTER equ -1
WH_JOURNALRECORD equ 0
WH_JOURNALPLAYBACK equ 1
WH_KEYBOARD equ 2
WH_GETMESSAGE equ 3
WH_CALLWNDPROC equ 4
WH_CBT equ 5
WH_SYSMSGFILTER equ 6
WH_MOUSE equ 7
WH_HARDWARE equ 8
WH_DEBUG equ 9
WH_SHELL equ 10
WH_FOREGROUNDIDLE equ 11
WH_CALLWNDPROCRET equ 12
WH_KEYBOARD_LL equ 13
WH_MOUSE_LL equ 14
WH_MAX equ 14
WH_MINHOOK equ WH_MIN
WH_MAXHOOK equ WH_MAX

struc KBDLLHOOKSTRUCT
.vkCode         resd 1
.scanCode       resd 1
.flags          resd 1
.time           resd 1
.dwExtraInfo    resd 1
endstruc

struc MSLLHOOKSTRUCT
.pt             resb POINT_size
.mouseData      resd 1
.flags          resd 1
.time           resd 1
.dwExtraInfo    resd 1
endstruc

struc DEBUGHOOKINFO
.idThread       resd 1
.idThreadInstaller resd 1
.lParam         resd 1
.wParam         resd 1
.code           resd 1
endstruc

struc MOUSEHOOKSTRUCT
.pt             resb POINT_size
.hwnd           resd 1
.wHitTestCode   resd 1
.dwExtraInfo    resd 1
endstruc

struc HARDWAREHOOKSTRUCT
.hwnd           resd 1
.message        resd 1
.wParam         resd 1
.lParam         resd 1
endstruc

%endif


;=============================================================================
%ifdef UseWindowSysVars

SM_CXSCREEN equ 0
SM_CYSCREEN equ 1
SM_CXVSCROLL equ 2
SM_CYHSCROLL equ 3
SM_CYCAPTION equ 4
SM_CXBORDER equ 5
SM_CYBORDER equ 6
SM_CXDLGFRAME equ 7
SM_CYDLGFRAME equ 8
SM_CYVTHUMB equ 9
SM_CXHTHUMB equ 10
SM_CXICON equ 11
SM_CYICON equ 12
SM_CXCURSOR equ 13
SM_CYCURSOR equ 14
SM_CYMENU equ 15
SM_CXFULLSCREEN equ 16
SM_CYFULLSCREEN equ 17
SM_CYKANJIWINDOW equ 18
SM_MOUSEPRESENT equ 19
SM_CYVSCROLL equ 20
SM_CXHSCROLL equ 21
SM_DEBUG equ 22
SM_SWAPBUTTON equ 23
SM_RESERVED1 equ 24
SM_RESERVED2 equ 25
SM_RESERVED3 equ 26
SM_RESERVED4 equ 27
SM_CXMIN equ 28
SM_CYMIN equ 29
SM_CXSIZE equ 30
SM_CYSIZE equ 31
SM_CXFRAME equ 32
SM_CYFRAME equ 33
SM_CXMINTRACK equ 34
SM_CYMINTRACK equ 35
SM_CXDOUBLECLK equ 36
SM_CYDOUBLECLK equ 37
SM_CXICONSPACING equ 38
SM_CYICONSPACING equ 39
SM_MENUDROPALIGNMENT equ 40
SM_PENWINDOWS equ 41
SM_DBCSENABLED equ 42
SM_CMOUSEBUTTONS equ 43
SM_CXFIXEDFRAME equ SM_CXDLGFRAME
SM_CYFIXEDFRAME equ SM_CYDLGFRAME
SM_CXSIZEFRAME equ SM_CXFRAME
SM_CYSIZEFRAME equ SM_CYFRAME
SM_SECURE equ 44
SM_CXEDGE equ 45
SM_CYEDGE equ 46
SM_CXMINSPACING equ 47
SM_CYMINSPACING equ 48
SM_CXSMICON equ 49
SM_CYSMICON equ 50
SM_CYSMCAPTION equ 51
SM_CXSMSIZE equ 52
SM_CYSMSIZE equ 53
SM_CXMENUSIZE equ 54
SM_CYMENUSIZE equ 55
SM_ARRANGE equ 56
SM_CXMINIMIZED equ 57
SM_CYMINIMIZED equ 58
SM_CXMAXTRACK equ 59
SM_CYMAXTRACK equ 60
SM_CXMAXIMIZED equ 61
SM_CYMAXIMIZED equ 62
SM_NETWORK equ 63
SM_CLEANBOOT equ 67
SM_CXDRAG equ 68
SM_CYDRAG equ 69
SM_SHOWSOUNDS equ 70
SM_CXMENUCHECK equ 71
SM_CYMENUCHECK equ 72
SM_SLOWMACHINE equ 73
SM_MIDEASTENABLED equ 74
SM_MOUSEWHEELPRESENT equ 75
SM_XVIRTUALSCREEN equ 76
SM_YVIRTUALSCREEN equ 77
SM_CXVIRTUALSCREEN equ 78
SM_CYVIRTUALSCREEN equ 79
SM_CMONITORS equ 80
SM_SAMEDISPLAYFORMAT equ 81
SM_CMETRICS equ 83
SPI_GETBEEP equ 1
SPI_SETBEEP equ 2
SPI_GETMOUSE equ 3
SPI_SETMOUSE equ 4
SPI_GETBORDER equ 5
SPI_SETBORDER equ 6
SPI_GETKEYBOARDSPEED equ 10
SPI_SETKEYBOARDSPEED equ 11
SPI_LANGDRIVER equ 12
SPI_ICONHORIZONTALSPACING equ 13
SPI_GETSCREENSAVETIMEOUT equ 14
SPI_SETSCREENSAVETIMEOUT equ 15
SPI_GETSCREENSAVEACTIVE equ 16
SPI_SETSCREENSAVEACTIVE equ 17
SPI_GETGRIDGRANULARITY equ 18
SPI_SETGRIDGRANULARITY equ 19
SPI_SETDESKWALLPAPER equ 20
SPI_SETDESKPATTERN equ 21
SPI_GETKEYBOARDDELAY equ 22
SPI_SETKEYBOARDDELAY equ 23
SPI_ICONVERTICALSPACING equ 24
SPI_GETICONTITLEWRAP equ 25
SPI_SETICONTITLEWRAP equ 26
SPI_GETMENUDROPALIGNMENT equ 27
SPI_SETMENUDROPALIGNMENT equ 28
SPI_SETDOUBLECLKWIDTH equ 29
SPI_SETDOUBLECLKHEIGHT equ 30
SPI_GETICONTITLELOGFONT equ 31
SPI_SETDOUBLECLICKTIME equ 32
SPI_SETMOUSEBUTTONSWAP equ 33
SPI_SETICONTITLELOGFONT equ 34
SPI_GETFASTTASKSWITCH equ 35
SPI_SETFASTTASKSWITCH equ 36
SPI_SETDRAGFULLWINDOWS equ 37
SPI_GETDRAGFULLWINDOWS equ 38
SPI_GETNONCLIENTMETRICS equ 41
SPI_SETNONCLIENTMETRICS equ 42
SPI_GETMINIMIZEDMETRICS equ 43
SPI_SETMINIMIZEDMETRICS equ 44
SPI_GETICONMETRICS equ 45
SPI_SETICONMETRICS equ 46
SPI_SETWORKAREA equ 47
SPI_GETWORKAREA equ 48
SPI_SETPENWINDOWS equ 49
SPI_GETFILTERKEYS equ 50
SPI_SETFILTERKEYS equ 51
SPI_GETTOGGLEKEYS equ 52
SPI_SETTOGGLEKEYS equ 53
SPI_GETMOUSEKEYS equ 54
SPI_SETMOUSEKEYS equ 55
SPI_GETSHOWSOUNDS equ 56
SPI_SETSHOWSOUNDS equ 57
SPI_GETSTICKYKEYS equ 58
SPI_SETSTICKYKEYS equ 59
SPI_GETACCESSTIMEOUT equ 60
SPI_SETACCESSTIMEOUT equ 61
SPI_GETSERIALKEYS equ 62
SPI_SETSERIALKEYS equ 63
SPI_GETSOUNDSENTRY equ 64
SPI_SETSOUNDSENTRY equ 65
SPI_GETHIGHCONTRAST equ 66
SPI_SETHIGHCONTRAST equ 67
SPI_GETKEYBOARDPREF equ 68
SPI_SETKEYBOARDPREF equ 69
SPI_GETSCREENREADER equ 70
SPI_SETSCREENREADER equ 71
SPI_GETANIMATION equ 72
SPI_SETANIMATION equ 73
SPI_GETFONTSMOOTHING equ 74
SPI_SETFONTSMOOTHING equ 75
SPI_SETDRAGWIDTH equ 76
SPI_SETDRAGHEIGHT equ 77
SPI_SETHANDHELD equ 78
SPI_GETLOWPOWERTIMEOUT equ 79
SPI_GETPOWEROFFTIMEOUT equ 80
SPI_SETLOWPOWERTIMEOUT equ 81
SPI_SETPOWEROFFTIMEOUT equ 82
SPI_GETLOWPOWERACTIVE equ 83
SPI_GETPOWEROFFACTIVE equ 84
SPI_SETLOWPOWERACTIVE equ 85
SPI_SETPOWEROFFACTIVE equ 86
SPI_SETCURSORS equ 87
SPI_SETICONS equ 88
SPI_GETDEFAULTINPUTLANG equ 89
SPI_SETDEFAULTINPUTLANG equ 90
SPI_SETLANGTOGGLE equ 91
SPI_GETWINDOWSEXTENSION equ 92
SPI_SETMOUSETRAILS equ 93
SPI_GETMOUSETRAILS equ 94
SPI_SETSCREENSAVERRUNNING equ 97
SPI_SCREENSAVERRUNNING equ SPI_SETSCREENSAVERRUNNING
SPI_GETMOUSEHOVERWIDTH equ 98
SPI_SETMOUSEHOVERWIDTH equ 99
SPI_GETMOUSEHOVERHEIGHT equ 100
SPI_SETMOUSEHOVERHEIGHT equ 101
SPI_GETMOUSEHOVERTIME equ 102
SPI_SETMOUSEHOVERTIME equ 103
SPI_GETWHEELSCROLLLINES equ 104
SPI_SETWHEELSCROLLLINES equ 105
SPI_GETSHOWIMEUI equ 110
SPI_SETSHOWIMEUI equ 111
SPI_GETMOUSESPEED equ 112
SPI_SETMOUSESPEED equ 113
SPI_GETSCREENSAVERRUNNING equ 114
SPI_GETACTIVEWINDOWTRACKING equ 4096
SPI_SETACTIVEWINDOWTRACKING equ 4097
SPI_GETMENUANIMATION equ 4098
SPI_SETMENUANIMATION equ 4099
SPI_GETCOMBOBOXANIMATION equ 4100
SPI_SETCOMBOBOXANIMATION equ 4101
SPI_GETLISTBOXSMOOTHSCROLLING equ 4102
SPI_SETLISTBOXSMOOTHSCROLLING equ 4103
SPI_GETGRADIENTCAPTIONS equ 4104
SPI_SETGRADIENTCAPTIONS equ 4105
SPI_GETMENUUNDERLINES equ 4106
SPI_SETMENUUNDERLINES equ 4107
SPI_GETACTIVEWNDTRKZORDER equ 4108
SPI_SETACTIVEWNDTRKZORDER equ 4109
SPI_GETHOTTRACKING equ 4110
SPI_SETHOTTRACKING equ 4111
SPI_GETFOREGROUNDLOCKTIMEOUT equ 8192
SPI_SETFOREGROUNDLOCKTIMEOUT equ 8193
SPI_GETACTIVEWNDTRKTIMEOUT equ 8194
SPI_SETACTIVEWNDTRKTIMEOUT equ 8195
SPI_GETFOREGROUNDFLASHCOUNT equ 8196
SPI_SETFOREGROUNDFLASHCOUNT equ 8197
SPIF_UPDATEINIFILE equ 1
SPIF_SENDWININICHANGE equ 2
%endif


;=============================================================================
%ifdef UseFileSystem

CREATE_NEW equ 1
CREATE_ALWAYS equ 2
OPEN_EXISTING equ 3
OPEN_ALWAYS equ 4
TRUNCATE_EXISTING equ 5

GENERIC_READ equ 80000000h
GENERIC_WRITE equ 40000000h
FILE_SHARE_READ equ 1h
FILE_SHARE_WRITE equ 2h

INVALID_FILE_HANDLE equ -1
INVALID_HANDLE_VALUE equ -1

FILE_FLAG_NO_BUFFERING equ 20000000h
FILE_FLAG_DELETE_ON_CLOSE equ 4000000h
FILE_FLAG_OVERLAPPED equ 40000000h
FILE_FLAG_POSIX_SEMANTICS equ 1000000h
FILE_FLAG_RANDOM_ACCESS equ 10000000h
FILE_FLAG_SEQUENTIAL_SCAN equ 8000000h
FILE_FLAG_WRITE_THROUGH equ 80000000h
FILE_FLAG_BACKUP_SEMANTICS equ 2000000h
FILE_FLAG_OPEN_REPARSE_POINT equ 200000h
FILE_FLAG_OPEN_NO_RECALL equ 100000h

FILE_BEGIN      equ 0
FILE_CURRENT    equ 1
FILE_END        equ 2

struc FILETIME
.dwLowDateTime      resd 1
.dwHighDateTime     resd 1
endstruc

struc WIN32_FIND_DATA
.dwFileAttributes   resd 1
.ftCreationTime     resb FILETIME_size
.ftLastAccessTime   resb FILETIME_size
.ftLastWriteTime    resb FILETIME_size
.nFileSizeHigh      resd 1
.nFileSizeLow       resd 1
.dwReserved0        resd 1
.dwReserved1        resd 1
.cFileName          resb MAX_PATH
.cAlternate         resb 14 
endstruc

struc WIN32_FIND_DATAW
.dwFileAttributes   resd 1
.ftCreationTime     resb FILETIME_size
.ftLastAccessTime   resb FILETIME_size
.ftLastWriteTime    resb FILETIME_size
.nFileSizeHigh      resd 1
.nFileSizeLow       resd 1
.dwReserved0        resd 1
.dwReserved1        resd 1
.cFileName          resw MAX_PATH ;for Unicode
.cAlternate         resw 14 
endstruc

FILE_ATTRIBUTE_READONLY equ 1
FILE_ATTRIBUTE_HIDDEN equ 2
FILE_ATTRIBUTE_SYSTEM equ 4
FILE_ATTRIBUTE_DIRECTORY equ 16
FILE_ATTRIBUTE_ARCHIVE equ 32
FILE_ATTRIBUTE_ENCRYPTED equ 64
FILE_ATTRIBUTE_NORMAL equ 128
FILE_ATTRIBUTE_TEMPORARY equ 256
FILE_ATTRIBUTE_SPARSE_FILE equ 512
FILE_ATTRIBUTE_REPARSE_POINT equ 1024
FILE_ATTRIBUTE_COMPRESSED equ 2048
FILE_ATTRIBUTE_OFFLINE equ 4096


%if 0

CREATE_NEW equ 1
CREATE_ALWAYS equ 2
OPEN_EXISTING equ 3
OPEN_ALWAYS equ 4
TRUNCATE_EXISTING equ 5

DELETE equ &H10000
READ_CONTROL equ &H20000
WRITE_DAC equ &H40000
WRITE_OWNER equ &H80000
SYNCHRONIZE equ &H100000



STANDARD_RIGHTS_READ equ (READ_CONTROL)
STANDARD_RIGHTS_WRITE equ (READ_CONTROL)
STANDARD_RIGHTS_EXECUTE equ (READ_CONTROL)
STANDARD_RIGHTS_REQUIRED equ &HF0000
STANDARD_RIGHTS_ALL equ &H1F0000

SPECIFIC_RIGHTS_ALL equ &HFFFF

'  The FILE_DATA and FILE_WRITE_DATA constants are also defined in
'  devioctl.h as FILE_READ_ACCESS and FILE_WRITE_ACCESS. The values for these
'  constants *MUST* always be in sync.
'  The values are redefined in devioctl.h because they must be available to
'  both DOS and NT.
'

FILE_READ_DATA equ (&H1)                     '  file pipe
FILE_LIST_DIRECTORY equ (&H1)                '  directory

FILE_WRITE_DATA equ (&H2)                    '  file pipe
FILE_ADD_FILE equ (&H2)                      '  directory

FILE_APPEND_DATA equ (&H4)                   '  file
FILE_ADD_SUBDIRECTORY equ (&H4)              '  directory
FILE_CREATE_PIPE_INSTANCE equ (&H4)          '  named pipe

FILE_READ_EA equ (&H8)                       '  file directory
FILE_READ_PROPERTIES equ FILE_READ_EA

FILE_WRITE_EA equ (&H10)                     '  file directory
FILE_WRITE_PROPERTIES equ FILE_WRITE_EA

FILE_EXECUTE equ (&H20)                      '  file
FILE_TRAVERSE equ (&H20)                     '  directory

FILE_DELETE_CHILD equ (&H40)                 '  directory

FILE_READ_ATTRIBUTES equ (&H80)              '  all

FILE_WRITE_ATTRIBUTES equ (&H100)            '  all

FILE_ALL_ACCESS equ (STANDARD_RIGHTS_REQUIRED Or SYNCHRONIZE Or &H1FF)

FILE_GENERIC_READ equ (STANDARD_RIGHTS_READ Or FILE_READ_DATA Or _
  FILE_READ_ATTRIBUTES Or FILE_READ_EA Or SYNCHRONIZE)

  FILE_GENERIC_WRITE equ (STANDARD_RIGHTS_WRITE Or FILE_WRITE_DATA _
Or FILE_WRITE_ATTRIBUTES Or FILE_WRITE_EA Or FILE_APPEND_DATA Or SYNCHRONIZE)

FILE_GENERIC_EXECUTE equ (STANDARD_RIGHTS_EXECUTE Or _
  FILE_READ_ATTRIBUTES Or FILE_EXECUTE Or SYNCHRONIZE)

  GENERIC_WRITE equ &H40000000
  FILE_SHARE_READ equ &H1
  FILE_SHARE_WRITE equ &H2
  FILE_ATTRIBUTE_READONLY equ &H1
  FILE_ATTRIBUTE_HIDDEN equ &H2
  FILE_ATTRIBUTE_SYSTEM equ &H4
  FILE_ATTRIBUTE_DIRECTORY equ &H10
  FILE_ATTRIBUTE_ARCHIVE equ &H20
  FILE_ATTRIBUTE_NORMAL equ &H80
  FILE_ATTRIBUTE_TEMPORARY equ &H100
  FILE_ATTRIBUTE_COMPRESSED equ &H800
  FILE_NOTIFY_CHANGE_FILE_NAME equ &H1
  FILE_NOTIFY_CHANGE_DIR_NAME equ &H2
  FILE_NOTIFY_CHANGE_ATTRIBUTES equ &H4
  FILE_NOTIFY_CHANGE_SIZE equ &H8
  FILE_NOTIFY_CHANGE_LAST_WRITE equ &H10
  FILE_NOTIFY_CHANGE_SECURITY equ &H100
  MAILSLOT_NO_MESSAGE equ (-1)
  MAILSLOT_WAIT_FOREVER equ (-1)
  FILE_CASE_SENSITIVE_SEARCH equ &H1
  FILE_CASE_PRESERVED_NAMES equ &H2
  FILE_UNICODE_ON_DISK equ &H4
  FILE_PERSISTENT_ACLS equ &H8
  FILE_FILE_COMPRESSION equ &H10
  FILE_VOLUME_IS_COMPRESSED equ &H8000
  IO_COMPLETION_MODIFY_STATE equ &H2
  IO_COMPLETION_ALL_ACCESS equ (STANDARD_RIGHTS_REQUIRED Or _
SYNCHRONIZE Or &H3)
DUPLICATE_CLOSE_SOURCE equ &H1
DUPLICATE_SAME_ACCESS equ &H2
%endif

%endif


;=============================================================================
%ifdef UseErrorCodes

; Set error mode
SEM_FAILCRITICALERRORS equ 1
SEM_NOGPFAULTERRORBOX equ 2
SEM_NOALIGNMENTFAULTEXCEPT equ 4
SEM_NOOPENFILEERRORBOX equ 32768

;ERROR_SUCCESS equ 0
;NO_ERROR equ 0
ERROR_INVALID_FUNCTION equ 1
ERROR_FILE_NOT_FOUND equ 2
ERROR_PATH_NOT_FOUND equ 3
ERROR_TOO_MANY_OPEN_FILES equ 4
ERROR_ACCESS_DENIED equ 5
ERROR_INVALID_HANDLE equ 6
ERROR_ARENA_TRASHED equ 7
ERROR_NOT_ENOUGH_MEMORY equ 8
ERROR_INVALID_BLOCK equ 9
ERROR_BAD_ENVIRONMENT equ 10
ERROR_BAD_FORMAT equ 11
ERROR_INVALID_ACCESS equ 12
ERROR_INVALID_DATA equ 13
ERROR_OUTOFMEMORY equ 14
ERROR_INVALID_DRIVE equ 15
ERROR_CURRENT_DIRECTORY equ 16
ERROR_NOT_SAME_DEVICE equ 17
ERROR_NO_MORE_FILES equ 18
ERROR_WRITE_PROTECT equ 19
ERROR_BAD_UNIT equ 20
ERROR_NOT_READY equ 21
ERROR_BAD_COMMAND equ 22
ERROR_CRC equ 23
ERROR_BAD_LENGTH equ 24
ERROR_SEEK equ 25
ERROR_NOT_DOS_DISK equ 26
ERROR_SECTOR_NOT_FOUND equ 27
ERROR_OUT_OF_PAPER equ 28
ERROR_WRITE_FAULT equ 29
ERROR_READ_FAULT equ 30
ERROR_GEN_FAILURE equ 31
ERROR_SHARING_VIOLATION equ 32
ERROR_LOCK_VIOLATION equ 33
ERROR_WRONG_DISK equ 34
ERROR_SHARING_BUFFER_EXCEEDED equ 36
ERROR_HANDLE_EOF equ 38
ERROR_HANDLE_DISK_FULL equ 39
ERROR_NOT_SUPPORTED equ 50
ERROR_REM_NOT_LIST equ 51
ERROR_DUP_NAME equ 52
ERROR_BAD_NETPATH equ 53
ERROR_NETWORK_BUSY equ 54
ERROR_DEV_NOT_EXIST equ 55
ERROR_TOO_MANY_CMDS equ 56
ERROR_ADAP_HDW_ERR equ 57
ERROR_BAD_NET_RESP equ 58
ERROR_UNEXP_NET_ERR equ 59
ERROR_BAD_REM_ADAP equ 60
ERROR_PRINTQ_FULL equ 61
ERROR_NO_SPOOL_SPACE equ 62
ERROR_PRINT_CANCELLED equ 63
ERROR_NETNAME_DELETED equ 64
ERROR_NETWORK_ACCESS_DENIED equ 65
ERROR_BAD_DEV_TYPE equ 66
ERROR_BAD_NET_NAME equ 67
ERROR_TOO_MANY_NAMES equ 68
ERROR_TOO_MANY_SESS equ 69
ERROR_SHARING_PAUSED equ 70
ERROR_REQ_NOT_ACCEP equ 71
ERROR_REDIR_PAUSED equ 72
ERROR_FILE_EXISTS equ 80
ERROR_CANNOT_MAKE equ 82
ERROR_FAIL_I24 equ 83
ERROR_OUT_OF_STRUCTURES equ 84
ERROR_ALREADY_ASSIGNED equ 85
ERROR_INVALID_PASSWORD equ 86
ERROR_INVALID_PARAMETER equ 87
ERROR_NET_WRITE_FAULT equ 88
ERROR_NO_PROC_SLOTS equ 89
ERROR_TOO_MANY_SEMAPHORES equ 100
ERROR_EXCL_SEM_ALREADY_OWNED equ 101
ERROR_SEM_IS_SET equ 102
ERROR_TOO_MANY_SEM_REQUESTS equ 103
ERROR_INVALID_AT_INTERRUPT_TIME equ 104
ERROR_SEM_OWNER_DIED equ 105
ERROR_SEM_USER_LIMIT equ 106
ERROR_DISK_CHANGE equ 107
ERROR_DRIVE_LOCKED equ 108
ERROR_BROKEN_PIPE equ 109
ERROR_OPEN_FAILED equ 110
ERROR_BUFFER_OVERFLOW equ 111
ERROR_DISK_FULL equ 112
ERROR_NO_MORE_SEARCH_HANDLES equ 113
ERROR_INVALID_TARGET_HANDLE equ 114
ERROR_INVALID_CATEGORY equ 117
ERROR_INVALID_VERIFY_SWITCH equ 118
ERROR_BAD_DRIVER_LEVEL equ 119
ERROR_CALL_NOT_IMPLEMENTED equ 120
ERROR_SEM_TIMEOUT equ 121
ERROR_INSUFFICIENT_BUFFER equ 122
ERROR_INVALID_NAME equ 123
ERROR_INVALID_LEVEL equ 124
ERROR_NO_VOLUME_LABEL equ 125
ERROR_MOD_NOT_FOUND equ 126
ERROR_PROC_NOT_FOUND equ 127
ERROR_WAIT_NO_CHILDREN equ 128
ERROR_CHILD_NOT_COMPLETE equ 129
ERROR_DIRECT_ACCESS_HANDLE equ 130
ERROR_NEGATIVE_SEEK equ 131
ERROR_SEEK_ON_DEVICE equ 132
ERROR_IS_JOIN_TARGET equ 133
ERROR_IS_JOINED equ 134
ERROR_IS_SUBSTED equ 135
ERROR_NOT_JOINED equ 136
ERROR_NOT_SUBSTED equ 137
ERROR_JOIN_TO_JOIN equ 138
ERROR_SUBST_TO_SUBST equ 139
ERROR_JOIN_TO_SUBST equ 140
ERROR_SUBST_TO_JOIN equ 141
ERROR_BUSY_DRIVE equ 142
ERROR_SAME_DRIVE equ 143
ERROR_DIR_NOT_ROOT equ 144
ERROR_DIR_NOT_EMPTY equ 145
ERROR_IS_SUBST_PATH equ 146
ERROR_IS_JOIN_PATH equ 147
ERROR_PATH_BUSY equ 148
ERROR_IS_SUBST_TARGET equ 149
ERROR_SYSTEM_TRACE equ 150
ERROR_INVALID_EVENT_COUNT equ 151
ERROR_TOO_MANY_MUXWAITERS equ 152
ERROR_INVALID_LIST_FORMAT equ 153
ERROR_LABEL_TOO_LONG equ 154
ERROR_TOO_MANY_TCBS equ 155
ERROR_SIGNAL_REFUSED equ 156
ERROR_DISCARDED equ 157
ERROR_NOT_LOCKED equ 158
ERROR_BAD_THREADID_ADDR equ 159
ERROR_BAD_ARGUMENTS equ 160
ERROR_BAD_PATHNAME equ 161
ERROR_SIGNAL_PENDING equ 162
ERROR_MAX_THRDS_REACHED equ 164
ERROR_LOCK_FAILED equ 167
ERROR_BUSY equ 170
ERROR_CANCEL_VIOLATION equ 173
ERROR_ATOMIC_LOCKS_NOT_SUPPORTED equ 174
ERROR_INVALID_SEGMENT_NUMBER equ 180
ERROR_INVALID_ORDINAL equ 182
ERROR_ALREADY_EXISTS equ 183
ERROR_INVALID_FLAG_NUMBER equ 186
ERROR_SEM_NOT_FOUND equ 187
ERROR_INVALID_STARTING_CODESEG equ 188
ERROR_INVALID_STACKSEG equ 189
ERROR_INVALID_MODULETYPE equ 190
ERROR_INVALID_EXE_SIGNATURE equ 191
ERROR_EXE_MARKED_INVALID equ 192
ERROR_BAD_EXE_FORMAT equ 193
ERROR_ITERATED_DATA_EXCEEDS_64k equ 194
ERROR_INVALID_MINALLOCSIZE equ 195
ERROR_DYNLINK_FROM_INVALID_RING equ 196
ERROR_IOPL_NOT_ENABLED equ 197
ERROR_INVALID_SEGDPL equ 198
ERROR_AUTODATASEG_EXCEEDS_64k equ 199
ERROR_RING2SEG_MUST_BE_MOVABLE equ 200
ERROR_RELOC_CHAIN_XEEDS_SEGLIM equ 201
ERROR_INFLOOP_IN_RELOC_CHAIN equ 202
ERROR_ENVVAR_NOT_FOUND equ 203
ERROR_NO_SIGNAL_SENT equ 205
ERROR_FILENAME_EXCED_RANGE equ 206
ERROR_RING2_STACK_IN_USE equ 207
ERROR_META_EXPANSION_TOO_LONG equ 208
ERROR_INVALID_SIGNAL_NUMBER equ 209
ERROR_THREAD_1_INACTIVE equ 210
ERROR_LOCKED equ 212
ERROR_TOO_MANY_MODULES equ 214
ERROR_NESTING_NOT_ALLOWED equ 215
ERROR_EXE_MACHINE_TYPE_MISMATCH equ 216
ERROR_BAD_PIPE equ 230
ERROR_PIPE_BUSY equ 231
ERROR_NO_DATA equ 232
ERROR_PIPE_NOT_CONNECTED equ 233
ERROR_MORE_DATA equ 234
ERROR_VC_DISCONNECTED equ 240
ERROR_INVALID_EA_NAME equ 254
ERROR_EA_LIST_INCONSISTENT equ 255
ERROR_NO_MORE_ITEMS equ 259
ERROR_CANNOT_COPY equ 266
ERROR_DIRECTORY equ 267
ERROR_EAS_DIDNT_FIT equ 275
ERROR_EA_FILE_CORRUPT equ 276
ERROR_EA_TABLE_FULL equ 277
ERROR_INVALID_EA_HANDLE equ 278
ERROR_EAS_NOT_SUPPORTED equ 282
ERROR_NOT_OWNER equ 288
ERROR_TOO_MANY_POSTS equ 298
ERROR_PARTIAL_COPY equ 299
ERROR_OPLOCK_NOT_GRANTED equ 300
ERROR_INVALID_OPLOCK_PROTOCOL equ 301
ERROR_MR_MID_NOT_FOUND equ 317
ERROR_INVALID_ADDRESS equ 487
ERROR_ARITHMETIC_OVERFLOW equ 534
ERROR_PIPE_CONNECTED equ 535
ERROR_PIPE_LISTENING equ 536
ERROR_EA_ACCESS_DENIED equ 994
ERROR_OPERATION_ABORTED equ 995
ERROR_IO_INCOMPLETE equ 996
ERROR_IO_PENDING equ 997
ERROR_NOACCESS equ 998
ERROR_SWAPERROR equ 999
ERROR_STACK_OVERFLOW equ 1001
ERROR_INVALID_MESSAGE equ 1002
ERROR_CAN_NOT_COMPLETE equ 1003
ERROR_INVALID_FLAGS equ 1004
ERROR_UNRECOGNIZED_VOLUME equ 1005
ERROR_FILE_INVALID equ 1006
ERROR_FULLSCREEN_MODE equ 1007
ERROR_NO_TOKEN equ 1008
ERROR_BADDB equ 1009
ERROR_BADKEY equ 1010
ERROR_CANTOPEN equ 1011
ERROR_CANTREAD equ 1012
ERROR_CANTWRITE equ 1013
ERROR_REGISTRY_RECOVERED equ 1014
ERROR_REGISTRY_CORRUPT equ 1015
ERROR_REGISTRY_IO_FAILED equ 1016
ERROR_NOT_REGISTRY_FILE equ 1017
ERROR_KEY_DELETED equ 1018
ERROR_NO_LOG_SPACE equ 1019
ERROR_KEY_HAS_CHILDREN equ 1020
ERROR_CHILD_MUST_BE_VOLATILE equ 1021
ERROR_NOTIFY_ENUM_DIR equ 1022
ERROR_DEPENDENT_SERVICES_RUNNING equ 1051
ERROR_INVALID_SERVICE_CONTROL equ 1052
ERROR_SERVICE_REQUEST_TIMEOUT equ 1053
ERROR_SERVICE_NO_THREAD equ 1054
ERROR_SERVICE_DATABASE_LOCKED equ 1055
ERROR_SERVICE_ALREADY_RUNNING equ 1056
ERROR_INVALID_SERVICE_ACCOUNT equ 1057
ERROR_SERVICE_DISABLED equ 1058
ERROR_CIRCULAR_DEPENDENCY equ 1059
ERROR_SERVICE_DOES_NOT_EXIST equ 1060
ERROR_SERVICE_CANNOT_ACCEPT_CTRL equ 1061
ERROR_SERVICE_NOT_ACTIVE equ 1062
ERROR_FAILED_SERVICE_CONTROLLER_CONNECT equ 1063
ERROR_EXCEPTION_IN_SERVICE equ 1064
ERROR_DATABASE_DOES_NOT_EXIST equ 1065
ERROR_SERVICE_SPECIFIC_ERROR equ 1066
ERROR_PROCESS_ABORTED equ 1067
ERROR_SERVICE_DEPENDENCY_FAIL equ 1068
ERROR_SERVICE_LOGON_FAILED equ 1069
ERROR_SERVICE_START_HANG equ 1070
ERROR_INVALID_SERVICE_LOCK equ 1071
ERROR_SERVICE_MARKED_FOR_DELETE equ 1072
ERROR_SERVICE_EXISTS equ 1073
ERROR_ALREADY_RUNNING_LKG equ 1074
ERROR_SERVICE_DEPENDENCY_DELETED equ 1075
ERROR_BOOT_ALREADY_ACCEPTED equ 1076
ERROR_SERVICE_NEVER_STARTED equ 1077
ERROR_DUPLICATE_SERVICE_NAME equ 1078
ERROR_DIFFERENT_SERVICE_ACCOUNT equ 1079
ERROR_CANNOT_DETECT_DRIVER_FAILURE equ 1080
ERROR_CANNOT_DETECT_PROCESS_ABORT equ 1081
ERROR_NO_RECOVERY_PROGRAM equ 1082
ERROR_END_OF_MEDIA equ 1100
ERROR_FILEMARK_DETECTED equ 1101
ERROR_BEGINNING_OF_MEDIA equ 1102
ERROR_SETMARK_DETECTED equ 1103
ERROR_NO_DATA_DETECTED equ 1104
ERROR_PARTITION_FAILURE equ 1105
ERROR_INVALID_BLOCK_LENGTH equ 1106
ERROR_DEVICE_NOT_PARTITIONED equ 1107
ERROR_UNABLE_TO_LOCK_MEDIA equ 1108
ERROR_UNABLE_TO_UNLOAD_MEDIA equ 1109
ERROR_MEDIA_CHANGED equ 1110
ERROR_BUS_RESET equ 1111
ERROR_NO_MEDIA_IN_DRIVE equ 1112
ERROR_NO_UNICODE_TRANSLATION equ 1113
ERROR_DLL_INIT_FAILED equ 1114
ERROR_SHUTDOWN_IN_PROGRESS equ 1115
ERROR_NO_SHUTDOWN_IN_PROGRESS equ 1116
ERROR_IO_DEVICE equ 1117
ERROR_SERIAL_NO_DEVICE equ 1118
ERROR_IRQ_BUSY equ 1119
ERROR_MORE_WRITES equ 1120
ERROR_COUNTER_TIMEOUT equ 1121
ERROR_FLOPPY_ID_MARK_NOT_FOUND equ 1122
ERROR_FLOPPY_WRONG_CYLINDER equ 1123
ERROR_FLOPPY_UNKNOWN_ERROR equ 1124
ERROR_FLOPPY_BAD_REGISTERS equ 1125
ERROR_DISK_RECALIBRATE_FAILED equ 1126
ERROR_DISK_OPERATION_FAILED equ 1127
ERROR_DISK_RESET_FAILED equ 1128
ERROR_EOM_OVERFLOW equ 1129
ERROR_NOT_ENOUGH_SERVER_MEMORY equ 1130
ERROR_POSSIBLE_DEADLOCK equ 1131
ERROR_MAPPED_ALIGNMENT equ 1132
ERROR_SET_POWER_STATE_VETOED equ 1140
ERROR_SET_POWER_STATE_FAILED equ 1141
ERROR_TOO_MANY_LINKS equ 1142
ERROR_OLD_WIN_VERSION equ 1150
ERROR_APP_WRONG_OS equ 1151
ERROR_SINGLE_INSTANCE_APP equ 1152
ERROR_RMODE_APP equ 1153
ERROR_INVALID_DLL equ 1154
ERROR_NO_ASSOCIATION equ 1155
ERROR_DDE_FAIL equ 1156
ERROR_DLL_NOT_FOUND equ 1157
ERROR_NO_MORE_USER_HANDLES equ 1158
ERROR_MESSAGE_SYNC_ONLY equ 1159
ERROR_SOURCE_ELEMENT_EMPTY equ 1160
ERROR_DESTINATION_ELEMENT_FULL equ 1161
ERROR_ILLEGAL_ELEMENT_ADDRESS equ 1162
ERROR_MAGAZINE_NOT_PRESENT equ 1163
ERROR_DEVICE_REINITIALIZATION_NEEDED equ 1164
ERROR_DEVICE_REQUIRES_CLEANING equ 1165
ERROR_DEVICE_DOOR_OPEN equ 1166
ERROR_DEVICE_NOT_CONNECTED equ 1167
ERROR_NOT_FOUND equ 1168
ERROR_NO_MATCH equ 1169
ERROR_SET_NOT_FOUND equ 1170
ERROR_POINT_NOT_FOUND equ 1171
ERROR_NO_TRACKING_SERVICE equ 1172
ERROR_NO_VOLUME_ID equ 1173
ERROR_CONNECTED_OTHER_PASSWORD equ 2108
ERROR_BAD_USERNAME equ 2202
ERROR_NOT_CONNECTED equ 2250
ERROR_OPEN_FILES equ 2401
ERROR_ACTIVE_CONNECTIONS equ 2402
ERROR_DEVICE_IN_USE equ 2404
ERROR_BAD_DEVICE equ 1200
ERROR_CONNECTION_UNAVAIL equ 1201
ERROR_DEVICE_ALREADY_REMEMBERED equ 1202
ERROR_NO_NET_OR_BAD_PATH equ 1203
ERROR_BAD_PROVIDER equ 1204
ERROR_CANNOT_OPEN_PROFILE equ 1205
ERROR_BAD_PROFILE equ 1206
ERROR_NOT_CONTAINER equ 1207
ERROR_EXTENDED_ERROR equ 1208
ERROR_INVALID_GROUPNAME equ 1209
ERROR_INVALID_COMPUTERNAME equ 1210
ERROR_INVALID_EVENTNAME equ 1211
ERROR_INVALID_DOMAINNAME equ 1212
ERROR_INVALID_SERVICENAME equ 1213
ERROR_INVALID_NETNAME equ 1214
ERROR_INVALID_SHARENAME equ 1215
ERROR_INVALID_PASSWORDNAME equ 1216
ERROR_INVALID_MESSAGENAME equ 1217
ERROR_INVALID_MESSAGEDEST equ 1218
ERROR_SESSION_CREDENTIAL_CONFLICT equ 1219
ERROR_REMOTE_SESSION_LIMIT_EXCEEDED equ 1220
ERROR_DUP_DOMAINNAME equ 1221
ERROR_NO_NETWORK equ 1222
ERROR_CANCELLED equ 1223
ERROR_USER_MAPPED_FILE equ 1224
ERROR_CONNECTION_REFUSED equ 1225
ERROR_GRACEFUL_DISCONNECT equ 1226
ERROR_ADDRESS_ALREADY_ASSOCIATED equ 1227
ERROR_ADDRESS_NOT_ASSOCIATED equ 1228
ERROR_CONNECTION_INVALID equ 1229
ERROR_CONNECTION_ACTIVE equ 1230
ERROR_NETWORK_UNREACHABLE equ 1231
ERROR_HOST_UNREACHABLE equ 1232
ERROR_PROTOCOL_UNREACHABLE equ 1233
ERROR_PORT_UNREACHABLE equ 1234
ERROR_REQUEST_ABORTED equ 1235
ERROR_CONNECTION_ABORTED equ 1236
ERROR_RETRY equ 1237
ERROR_CONNECTION_COUNT_LIMIT equ 1238
ERROR_LOGIN_TIME_RESTRICTION equ 1239
ERROR_LOGIN_WKSTA_RESTRICTION equ 1240
ERROR_INCORRECT_ADDRESS equ 1241
ERROR_ALREADY_REGISTERED equ 1242
ERROR_SERVICE_NOT_FOUND equ 1243
ERROR_NOT_AUTHENTICATED equ 1244
ERROR_NOT_LOGGED_ON equ 1245
ERROR_CONTINUE equ 1246
ERROR_ALREADY_INITIALIZED equ 1247
ERROR_NO_MORE_DEVICES equ 1248
ERROR_NO_SUCH_SITE equ 1249
ERROR_DOMAIN_CONTROLLER_EXISTS equ 1250
ERROR_DS_NOT_INSTALLED equ 1251
ERROR_NOT_ALL_ASSIGNED equ 1300
ERROR_SOME_NOT_MAPPED equ 1301
ERROR_NO_QUOTAS_FOR_ACCOUNT equ 1302
ERROR_LOCAL_USER_SESSION_KEY equ 1303
ERROR_NULL_LM_PASSWORD equ 1304
ERROR_UNKNOWN_REVISION equ 1305
ERROR_REVISION_MISMATCH equ 1306
ERROR_INVALID_OWNER equ 1307
ERROR_INVALID_PRIMARY_GROUP equ 1308
ERROR_NO_IMPERSONATION_TOKEN equ 1309
ERROR_CANT_DISABLE_MANDATORY equ 1310
ERROR_NO_LOGON_SERVERS equ 1311
ERROR_NO_SUCH_LOGON_SESSION equ 1312
ERROR_NO_SUCH_PRIVILEGE equ 1313
ERROR_PRIVILEGE_NOT_HELD equ 1314
ERROR_INVALID_ACCOUNT_NAME equ 1315
ERROR_USER_EXISTS equ 1316
ERROR_NO_SUCH_USER equ 1317
ERROR_GROUP_EXISTS equ 1318
ERROR_NO_SUCH_GROUP equ 1319
ERROR_MEMBER_IN_GROUP equ 1320
ERROR_MEMBER_NOT_IN_GROUP equ 1321
ERROR_LAST_ADMIN equ 1322
ERROR_WRONG_PASSWORD equ 1323
ERROR_ILL_FORMED_PASSWORD equ 1324
ERROR_PASSWORD_RESTRICTION equ 1325
ERROR_LOGON_FAILURE equ 1326
ERROR_ACCOUNT_RESTRICTION equ 1327
ERROR_INVALID_LOGON_HOURS equ 1328
ERROR_INVALID_WORKSTATION equ 1329
ERROR_PASSWORD_EXPIRED equ 1330
ERROR_ACCOUNT_DISABLED equ 1331
ERROR_NONE_MAPPED equ 1332
ERROR_TOO_MANY_LUIDS_REQUESTED equ 1333
ERROR_LUIDS_EXHAUSTED equ 1334
ERROR_INVALID_SUB_AUTHORITY equ 1335
ERROR_INVALID_ACL equ 1336
ERROR_INVALID_SID equ 1337
ERROR_INVALID_SECURITY_DESCR equ 1338
ERROR_BAD_INHERITANCE_ACL equ 1340
ERROR_SERVER_DISABLED equ 1341
ERROR_SERVER_NOT_DISABLED equ 1342
ERROR_INVALID_ID_AUTHORITY equ 1343
ERROR_ALLOTTED_SPACE_EXCEEDED equ 1344
ERROR_INVALID_GROUP_ATTRIBUTES equ 1345
ERROR_BAD_IMPERSONATION_LEVEL equ 1346
ERROR_CANT_OPEN_ANONYMOUS equ 1347
ERROR_BAD_VALIDATION_CLASS equ 1348
ERROR_BAD_TOKEN_TYPE equ 1349
ERROR_NO_SECURITY_ON_OBJECT equ 1350
ERROR_CANT_ACCESS_DOMAIN_INFO equ 1351
ERROR_INVALID_SERVER_STATE equ 1352
ERROR_INVALID_DOMAIN_STATE equ 1353
ERROR_INVALID_DOMAIN_ROLE equ 1354
ERROR_NO_SUCH_DOMAIN equ 1355
ERROR_DOMAIN_EXISTS equ 1356
ERROR_DOMAIN_LIMIT_EXCEEDED equ 1357
ERROR_INTERNAL_DB_CORRUPTION equ 1358
ERROR_INTERNAL_ERROR equ 1359
ERROR_GENERIC_NOT_MAPPED equ 1360
ERROR_BAD_DESCRIPTOR_FORMAT equ 1361
ERROR_NOT_LOGON_PROCESS equ 1362
ERROR_LOGON_SESSION_EXISTS equ 1363
ERROR_NO_SUCH_PACKAGE equ 1364
ERROR_BAD_LOGON_SESSION_STATE equ 1365
ERROR_LOGON_SESSION_COLLISION equ 1366
ERROR_INVALID_LOGON_TYPE equ 1367
ERROR_CANNOT_IMPERSONATE equ 1368
ERROR_RXACT_INVALID_STATE equ 1369
ERROR_RXACT_COMMIT_FAILURE equ 1370
ERROR_SPECIAL_ACCOUNT equ 1371
ERROR_SPECIAL_GROUP equ 1372
ERROR_SPECIAL_USER equ 1373
ERROR_MEMBERS_PRIMARY_GROUP equ 1374
ERROR_TOKEN_ALREADY_IN_USE equ 1375
ERROR_NO_SUCH_ALIAS equ 1376
ERROR_MEMBER_NOT_IN_ALIAS equ 1377
ERROR_MEMBER_IN_ALIAS equ 1378
ERROR_ALIAS_EXISTS equ 1379
ERROR_LOGON_NOT_GRANTED equ 1380
ERROR_TOO_MANY_SECRETS equ 1381
ERROR_SECRET_TOO_LONG equ 1382
ERROR_INTERNAL_DB_ERROR equ 1383
ERROR_TOO_MANY_CONTEXT_IDS equ 1384
ERROR_LOGON_TYPE_NOT_GRANTED equ 1385
ERROR_NT_CROSS_ENCRYPTION_REQUIRED equ 1386
ERROR_NO_SUCH_MEMBER equ 1387
ERROR_INVALID_MEMBER equ 1388
ERROR_TOO_MANY_SIDS equ 1389
ERROR_LM_CROSS_ENCRYPTION_REQUIRED equ 1390
ERROR_NO_INHERITANCE equ 1391
ERROR_FILE_CORRUPT equ 1392
ERROR_DISK_CORRUPT equ 1393
ERROR_NO_USER_SESSION_KEY equ 1394
ERROR_LICENSE_QUOTA_EXCEEDED equ 1395
ERROR_INVALID_WINDOW_HANDLE equ 1400
ERROR_INVALID_MENU_HANDLE equ 1401
ERROR_INVALID_CURSOR_HANDLE equ 1402
ERROR_INVALID_ACCEL_HANDLE equ 1403
ERROR_INVALID_HOOK_HANDLE equ 1404
ERROR_INVALID_DWP_HANDLE equ 1405
ERROR_TLW_WITH_WSCHILD equ 1406
ERROR_CANNOT_FIND_WND_CLASS equ 1407
ERROR_WINDOW_OF_OTHER_THREAD equ 1408
ERROR_HOTKEY_ALREADY_REGISTERED equ 1409
ERROR_CLASS_ALREADY_EXISTS equ 1410
ERROR_CLASS_DOES_NOT_EXIST equ 1411
ERROR_CLASS_HAS_WINDOWS equ 1412
ERROR_INVALID_INDEX equ 1413
ERROR_INVALID_ICON_HANDLE equ 1414
ERROR_PRIVATE_DIALOG_INDEX equ 1415
ERROR_LISTBOX_ID_NOT_FOUND equ 1416
ERROR_NO_WILDCARD_CHARACTERS equ 1417
ERROR_CLIPBOARD_NOT_OPEN equ 1418
ERROR_HOTKEY_NOT_REGISTERED equ 1419
ERROR_WINDOW_NOT_DIALOG equ 1420
ERROR_CONTROL_ID_NOT_FOUND equ 1421
ERROR_INVALID_COMBOBOX_MESSAGE equ 1422
ERROR_WINDOW_NOT_COMBOBOX equ 1423
ERROR_INVALID_EDIT_HEIGHT equ 1424
ERROR_DC_NOT_FOUND equ 1425
ERROR_INVALID_HOOK_FILTER equ 1426
ERROR_INVALID_FILTER_PROC equ 1427
ERROR_HOOK_NEEDS_HMOD equ 1428
ERROR_GLOBAL_ONLY_HOOK equ 1429
ERROR_JOURNAL_HOOK_SET equ 1430
ERROR_HOOK_NOT_INSTALLED equ 1431
ERROR_INVALID_LB_MESSAGE equ 1432
ERROR_SETCOUNT_ON_BAD_LB equ 1433
ERROR_LB_WITHOUT_TABSTOPS equ 1434
ERROR_DESTROY_OBJECT_OF_OTHER_THREAD equ 1435
ERROR_CHILD_WINDOW_MENU equ 1436
ERROR_NO_SYSTEM_MENU equ 1437
ERROR_INVALID_MSGBOX_STYLE equ 1438
ERROR_INVALID_SPI_VALUE equ 1439
ERROR_SCREEN_ALREADY_LOCKED equ 1440
ERROR_HWNDS_HAVE_DIFF_PARENT equ 1441
ERROR_NOT_CHILD_WINDOW equ 1442
ERROR_INVALID_GW_COMMAND equ 1443
ERROR_INVALID_THREAD_ID equ 1444
ERROR_NON_MDICHILD_WINDOW equ 1445
ERROR_POPUP_ALREADY_ACTIVE equ 1446
ERROR_NO_SCROLLBARS equ 1447
ERROR_INVALID_SCROLLBAR_RANGE equ 1448
ERROR_INVALID_SHOWWIN_COMMAND equ 1449
ERROR_NO_SYSTEM_RESOURCES equ 1450
ERROR_NONPAGED_SYSTEM_RESOURCES equ 1451
ERROR_PAGED_SYSTEM_RESOURCES equ 1452
ERROR_WORKING_SET_QUOTA equ 1453
ERROR_PAGEFILE_QUOTA equ 1454
ERROR_COMMITMENT_LIMIT equ 1455
ERROR_MENU_ITEM_NOT_FOUND equ 1456
ERROR_INVALID_KEYBOARD_HANDLE equ 1457
ERROR_HOOK_TYPE_NOT_ALLOWED equ 1458
ERROR_REQUIRES_INTERACTIVE_WINDOWSTATION equ 1459
ERROR_TIMEOUT equ 1460
ERROR_INVALID_MONITOR_HANDLE equ 1461
ERROR_EVENTLOG_FILE_CORRUPT equ 1500
ERROR_EVENTLOG_CANT_START equ 1501
ERROR_LOG_FILE_FULL equ 1502
ERROR_EVENTLOG_FILE_CHANGED equ 1503
ERROR_INSTALL_SERVICE equ 1601
ERROR_INSTALL_USEREXIT equ 1602
ERROR_INSTALL_FAILURE equ 1603
ERROR_INSTALL_SUSPEND equ 1604
ERROR_UNKNOWN_PRODUCT equ 1605
ERROR_UNKNOWN_FEATURE equ 1606
ERROR_UNKNOWN_COMPONENT equ 1607
ERROR_UNKNOWN_PROPERTY equ 1608
ERROR_INVALID_HANDLE_STATE equ 1609
ERROR_BAD_CONFIGURATION equ 1610
ERROR_INDEX_ABSENT equ 1611
ERROR_INSTALL_SOURCE_ABSENT equ 1612
ERROR_BAD_DATABASE_VERSION equ 1613
ERROR_PRODUCT_UNINSTALLED equ 1614
ERROR_BAD_QUERY_SYNTAX equ 1615
ERROR_INVALID_FIELD equ 1616
RPC_S_INVALID_STRING_BINDING equ 1700
RPC_S_WRONG_KIND_OF_BINDING equ 1701
RPC_S_INVALID_BINDING equ 1702
RPC_S_PROTSEQ_NOT_SUPPORTED equ 1703
RPC_S_INVALID_RPC_PROTSEQ equ 1704
RPC_S_INVALID_STRING_UUID equ 1705
RPC_S_INVALID_ENDPOINT_FORMAT equ 1706
RPC_S_INVALID_NET_ADDR equ 1707
RPC_S_NO_ENDPOINT_FOUND equ 1708
RPC_S_INVALID_TIMEOUT equ 1709
RPC_S_OBJECT_NOT_FOUND equ 1710
RPC_S_ALREADY_REGISTERED equ 1711
RPC_S_TYPE_ALREADY_REGISTERED equ 1712
RPC_S_ALREADY_LISTENING equ 1713
RPC_S_NO_PROTSEQS_REGISTERED equ 1714
RPC_S_NOT_LISTENING equ 1715
RPC_S_UNKNOWN_MGR_TYPE equ 1716
RPC_S_UNKNOWN_IF equ 1717
RPC_S_NO_BINDINGS equ 1718
RPC_S_NO_PROTSEQS equ 1719
RPC_S_CANT_CREATE_ENDPOINT equ 1720
RPC_S_OUT_OF_RESOURCES equ 1721
RPC_S_SERVER_UNAVAILABLE equ 1722
RPC_S_SERVER_TOO_BUSY equ 1723
RPC_S_INVALID_NETWORK_OPTIONS equ 1724
RPC_S_NO_CALL_ACTIVE equ 1725
RPC_S_CALL_FAILED equ 1726
RPC_S_CALL_FAILED_DNE equ 1727
RPC_S_PROTOCOL_ERROR equ 1728
RPC_S_UNSUPPORTED_TRANS_SYN equ 1730
RPC_S_UNSUPPORTED_TYPE equ 1732
RPC_S_INVALID_TAG equ 1733
RPC_S_INVALID_BOUND equ 1734
RPC_S_NO_ENTRY_NAME equ 1735
RPC_S_INVALID_NAME_SYNTAX equ 1736
RPC_S_UNSUPPORTED_NAME_SYNTAX equ 1737
RPC_S_UUID_NO_ADDRESS equ 1739
RPC_S_DUPLICATE_ENDPOINT equ 1740
RPC_S_UNKNOWN_AUTHN_TYPE equ 1741
RPC_S_MAX_CALLS_TOO_SMALL equ 1742
RPC_S_STRING_TOO_LONG equ 1743
RPC_S_PROTSEQ_NOT_FOUND equ 1744
RPC_S_PROCNUM_OUT_OF_RANGE equ 1745
RPC_S_BINDING_HAS_NO_AUTH equ 1746
RPC_S_UNKNOWN_AUTHN_SERVICE equ 1747
RPC_S_UNKNOWN_AUTHN_LEVEL equ 1748
RPC_S_INVALID_AUTH_IDENTITY equ 1749
RPC_S_UNKNOWN_AUTHZ_SERVICE equ 1750
EPT_S_INVALID_ENTRY equ 1751
EPT_S_CANT_PERFORM_OP equ 1752
EPT_S_NOT_REGISTERED equ 1753
RPC_S_NOTHING_TO_EXPORT equ 1754
RPC_S_INCOMPLETE_NAME equ 1755
RPC_S_INVALID_VERS_OPTION equ 1756
RPC_S_NO_MORE_MEMBERS equ 1757
RPC_S_NOT_ALL_OBJS_UNEXPORTED equ 1758
RPC_S_INTERFACE_NOT_FOUND equ 1759
RPC_S_ENTRY_ALREADY_EXISTS equ 1760
RPC_S_ENTRY_NOT_FOUND equ 1761
RPC_S_NAME_SERVICE_UNAVAILABLE equ 1762
RPC_S_INVALID_NAF_ID equ 1763
RPC_S_CANNOT_SUPPORT equ 1764
RPC_S_NO_CONTEXT_AVAILABLE equ 1765
RPC_S_INTERNAL_ERROR equ 1766
RPC_S_ZERO_DIVIDE equ 1767
RPC_S_ADDRESS_ERROR equ 1768
RPC_S_FP_DIV_ZERO equ 1769
RPC_S_FP_UNDERFLOW equ 1770
RPC_S_FP_OVERFLOW equ 1771
RPC_X_NO_MORE_ENTRIES equ 1772
RPC_X_SS_CHAR_TRANS_OPEN_FAIL equ 1773
RPC_X_SS_CHAR_TRANS_SHORT_FILE equ 1774
RPC_X_SS_IN_NULL_CONTEXT equ 1775
RPC_X_SS_CONTEXT_DAMAGED equ 1777
RPC_X_SS_HANDLES_MISMATCH equ 1778
RPC_X_SS_CANNOT_GET_CALL_HANDLE equ 1779
RPC_X_NULL_REF_POINTER equ 1780
RPC_X_ENUM_VALUE_OUT_OF_RANGE equ 1781
RPC_X_BYTE_COUNT_TOO_SMALL equ 1782
RPC_X_BAD_STUB_DATA equ 1783
ERROR_INVALID_USER_BUFFER equ 1784
ERROR_UNRECOGNIZED_MEDIA equ 1785
ERROR_NO_TRUST_LSA_SECRET equ 1786
ERROR_NO_TRUST_SAM_ACCOUNT equ 1787
ERROR_TRUSTED_DOMAIN_FAILURE equ 1788
ERROR_TRUSTED_RELATIONSHIP_FAILURE equ 1789
ERROR_TRUST_FAILURE equ 1790
RPC_S_CALL_IN_PROGRESS equ 1791
ERROR_NETLOGON_NOT_STARTED equ 1792
ERROR_ACCOUNT_EXPIRED equ 1793
ERROR_REDIRECTOR_HAS_OPEN_HANDLES equ 1794
ERROR_PRINTER_DRIVER_ALREADY_INSTALLED equ 1795
ERROR_UNKNOWN_PORT equ 1796
ERROR_UNKNOWN_PRINTER_DRIVER equ 1797
ERROR_UNKNOWN_PRINTPROCESSOR equ 1798
ERROR_INVALID_SEPARATOR_FILE equ 1799
ERROR_INVALID_PRIORITY equ 1800
ERROR_INVALID_PRINTER_NAME equ 1801
ERROR_PRINTER_ALREADY_EXISTS equ 1802
ERROR_INVALID_PRINTER_COMMAND equ 1803
ERROR_INVALID_DATATYPE equ 1804
ERROR_INVALID_ENVIRONMENT equ 1805
RPC_S_NO_MORE_BINDINGS equ 1806
ERROR_NOLOGON_INTERDOMAIN_TRUST_ACCOUNT equ 1807
ERROR_NOLOGON_WORKSTATION_TRUST_ACCOUNT equ 1808
ERROR_NOLOGON_SERVER_TRUST_ACCOUNT equ 1809
ERROR_DOMAIN_TRUST_INCONSISTENT equ 1810
ERROR_SERVER_HAS_OPEN_HANDLES equ 1811
ERROR_RESOURCE_DATA_NOT_FOUND equ 1812
ERROR_RESOURCE_TYPE_NOT_FOUND equ 1813
ERROR_RESOURCE_NAME_NOT_FOUND equ 1814
ERROR_RESOURCE_LANG_NOT_FOUND equ 1815
ERROR_NOT_ENOUGH_QUOTA equ 1816
RPC_S_NO_INTERFACES equ 1817
RPC_S_CALL_CANCELLED equ 1818
RPC_S_BINDING_INCOMPLETE equ 1819
RPC_S_COMM_FAILURE equ 1820
RPC_S_UNSUPPORTED_AUTHN_LEVEL equ 1821
RPC_S_NO_PRINC_NAME equ 1822
RPC_S_NOT_RPC_ERROR equ 1823
RPC_S_UUID_LOCAL_ONLY equ 1824
RPC_S_SEC_PKG_ERROR equ 1825
RPC_S_NOT_CANCELLED equ 1826
RPC_X_INVALID_ES_ACTION equ 1827
RPC_X_WRONG_ES_VERSION equ 1828
RPC_X_WRONG_STUB_VERSION equ 1829
RPC_X_INVALID_PIPE_OBJECT equ 1830
RPC_X_WRONG_PIPE_ORDER equ 1831
RPC_X_WRONG_PIPE_VERSION equ 1832
RPC_S_GROUP_MEMBER_NOT_FOUND equ 1898
EPT_S_CANT_CREATE equ 1899
RPC_S_INVALID_OBJECT equ 1900
ERROR_INVALID_TIME equ 1901
ERROR_INVALID_FORM_NAME equ 1902
ERROR_INVALID_FORM_SIZE equ 1903
ERROR_ALREADY_WAITING equ 1904
ERROR_PRINTER_DELETED equ 1905
ERROR_INVALID_PRINTER_STATE equ 1906
ERROR_PASSWORD_MUST_CHANGE equ 1907
ERROR_DOMAIN_CONTROLLER_NOT_FOUND equ 1908
ERROR_ACCOUNT_LOCKED_OUT equ 1909
OR_INVALID_OXID equ 1910
OR_INVALID_OID equ 1911
OR_INVALID_SET equ 1912
RPC_S_SEND_INCOMPLETE equ 1913
RPC_S_INVALID_ASYNC_HANDLE equ 1914
RPC_S_INVALID_ASYNC_CALL equ 1915
RPC_X_PIPE_CLOSED equ 1916
RPC_X_PIPE_DISCIPLINE_ERROR equ 1917
RPC_X_PIPE_EMPTY equ 1918
ERROR_NO_SITENAME equ 1919
ERROR_CANT_ACCESS_FILE equ 1920
ERROR_CANT_RESOLVE_FILENAME equ 1921
ERROR_DS_MEMBERSHIP_EVALUATED_LOCALLY equ 1922
ERROR_DS_NO_ATTRIBUTE_OR_VALUE equ 1923
ERROR_DS_INVALID_ATTRIBUTE_SYNTAX equ 1924
ERROR_DS_ATTRIBUTE_TYPE_UNDEFINED equ 1925
ERROR_DS_ATTRIBUTE_OR_VALUE_EXISTS equ 1926
ERROR_DS_BUSY equ 1927
ERROR_DS_UNAVAILABLE equ 1928
ERROR_DS_NO_RIDS_ALLOCATED equ 1929
ERROR_DS_NO_MORE_RIDS equ 1930
ERROR_DS_INCORRECT_ROLE_OWNER equ 1931
ERROR_DS_RIDMGR_INIT_ERROR equ 1932
ERROR_DS_OBJ_CLASS_VIOLATION equ 1933
ERROR_DS_CANT_ON_NON_LEAF equ 1934
ERROR_DS_CANT_ON_RDN equ 1935
ERROR_DS_CANT_MOD_OBJ_CLASS equ 1936
ERROR_DS_CROSS_DOM_MOVE_ERROR equ 1937
ERROR_DS_GC_NOT_AVAILABLE equ 1938
ERROR_NO_BROWSER_SERVERS_FOUND equ 6118
ERROR_INVALID_PIXEL_FORMAT equ 2000
ERROR_BAD_DRIVER equ 2001
ERROR_INVALID_WINDOW_STYLE equ 2002
ERROR_METAFILE_NOT_SUPPORTED equ 2003
ERROR_TRANSFORM_NOT_SUPPORTED equ 2004
ERROR_CLIPPING_NOT_SUPPORTED equ 2005
ERROR_INVALID_CMM equ 2300
ERROR_INVALID_PROFILE equ 2301
ERROR_TAG_NOT_FOUND equ 2302
ERROR_TAG_NOT_PRESENT equ 2303
ERROR_DUPLICATE_TAG equ 2304
ERROR_PROFILE_NOT_ASSOCIATED_WITH_DEVICE equ 2305
ERROR_PROFILE_NOT_FOUND equ 2306
ERROR_INVALID_COLORSPACE equ 2307
ERROR_ICM_NOT_ENABLED equ 2308
ERROR_DELETING_ICM_XFORM equ 2309
ERROR_INVALID_TRANSFORM equ 2310
ERROR_UNKNOWN_PRINT_MONITOR equ 3000
ERROR_PRINTER_DRIVER_IN_USE equ 3001
ERROR_SPOOL_FILE_NOT_FOUND equ 3002
ERROR_SPL_NO_STARTDOC equ 3003
ERROR_SPL_NO_ADDJOB equ 3004
ERROR_PRINT_PROCESSOR_ALREADY_INSTALLED equ 3005
ERROR_PRINT_MONITOR_ALREADY_INSTALLED equ 3006
ERROR_INVALID_PRINT_MONITOR equ 3007
ERROR_PRINT_MONITOR_IN_USE equ 3008
ERROR_PRINTER_HAS_JOBS_QUEUED equ 3009
ERROR_SUCCESS_REBOOT_REQUIRED equ 3010
ERROR_SUCCESS_RESTART_REQUIRED equ 3011
ERROR_WINS_INTERNAL equ 4000
ERROR_CAN_NOT_DEL_LOCAL_WINS equ 4001
ERROR_STATIC_INIT equ 4002
ERROR_INC_BACKUP equ 4003
ERROR_FULL_BACKUP equ 4004
ERROR_REC_NON_EXISTENT equ 4005
ERROR_RPL_NOT_ALLOWED equ 4006
ERROR_DHCP_ADDRESS_CONFLICT equ 4100
ERROR_WMI_GUID_NOT_FOUND equ 4200
ERROR_WMI_INSTANCE_NOT_FOUND equ 4201
ERROR_WMI_ITEMID_NOT_FOUND equ 4202
ERROR_WMI_TRY_AGAIN equ 4203
ERROR_WMI_DP_NOT_FOUND equ 4204
ERROR_WMI_UNRESOLVED_INSTANCE_REF equ 4205
ERROR_WMI_ALREADY_ENABLED equ 4206
ERROR_WMI_GUID_DISCONNECTED equ 4207
ERROR_WMI_SERVER_UNAVAILABLE equ 4208
ERROR_WMI_DP_FAILED equ 4209
ERROR_WMI_INVALID_MOF equ 4210
ERROR_WMI_INVALID_REGINFO equ 4211
ERROR_INVALID_MEDIA equ 4300
ERROR_INVALID_LIBRARY equ 4301
ERROR_INVALID_MEDIA_POOL equ 4302
ERROR_DRIVE_MEDIA_MISMATCH equ 4303
ERROR_MEDIA_OFFLINE equ 4304
ERROR_LIBRARY_OFFLINE equ 4305
ERROR_EMPTY equ 4306
ERROR_NOT_EMPTY equ 4307
ERROR_MEDIA_UNAVAILABLE equ 4308
ERROR_RESOURCE_DISABLED equ 4309
ERROR_INVALID_CLEANER equ 4310
ERROR_UNABLE_TO_CLEAN equ 4311
ERROR_OBJECT_NOT_FOUND equ 4312
ERROR_DATABASE_FAILURE equ 4313
ERROR_DATABASE_FULL equ 4314
ERROR_MEDIA_INCOMPATIBLE equ 4315
ERROR_RESOURCE_NOT_PRESENT equ 4316
ERROR_INVALID_OPERATION equ 4317
ERROR_MEDIA_NOT_AVAILABLE equ 4318
ERROR_DEVICE_NOT_AVAILABLE equ 4319
ERROR_REQUEST_REFUSED equ 4320
ERROR_FILE_OFFLINE equ 4350
ERROR_REMOTE_STORAGE_NOT_ACTIVE equ 4351
ERROR_REMOTE_STORAGE_MEDIA_ERROR equ 4352
ERROR_NOT_A_REPARSE_POINT equ 4390
ERROR_REPARSE_ATTRIBUTE_CONFLICT equ 4391
ERROR_DEPENDENT_RESOURCE_EXISTS equ 5001
ERROR_DEPENDENCY_NOT_FOUND equ 5002
ERROR_DEPENDENCY_ALREADY_EXISTS equ 5003
ERROR_RESOURCE_NOT_ONLINE equ 5004
ERROR_HOST_NODE_NOT_AVAILABLE equ 5005
ERROR_RESOURCE_NOT_AVAILABLE equ 5006
ERROR_RESOURCE_NOT_FOUND equ 5007
ERROR_SHUTDOWN_CLUSTER equ 5008
ERROR_CANT_EVICT_ACTIVE_NODE equ 5009
ERROR_OBJECT_ALREADY_EXISTS equ 5010
ERROR_OBJECT_IN_LIST equ 5011
ERROR_GROUP_NOT_AVAILABLE equ 5012
ERROR_GROUP_NOT_FOUND equ 5013
ERROR_GROUP_NOT_ONLINE equ 5014
ERROR_HOST_NODE_NOT_RESOURCE_OWNER equ 5015
ERROR_HOST_NODE_NOT_GROUP_OWNER equ 5016
ERROR_RESMON_CREATE_FAILED equ 5017
ERROR_RESMON_ONLINE_FAILED equ 5018
ERROR_RESOURCE_ONLINE equ 5019
ERROR_QUORUM_RESOURCE equ 5020
ERROR_NOT_QUORUM_CAPABLE equ 5021
ERROR_CLUSTER_SHUTTING_DOWN equ 5022
ERROR_INVALID_STATE equ 5023
ERROR_RESOURCE_PROPERTIES_STORED equ 5024
ERROR_NOT_QUORUM_CLASS equ 5025
ERROR_CORE_RESOURCE equ 5026
ERROR_QUORUM_RESOURCE_ONLINE_FAILED equ 5027
ERROR_QUORUMLOG_OPEN_FAILED equ 5028
ERROR_CLUSTERLOG_CORRUPT equ 5029
ERROR_CLUSTERLOG_RECORD_EXCEEDS_MAXSIZE equ 5030
ERROR_CLUSTERLOG_EXCEEDS_MAXSIZE equ 5031
ERROR_CLUSTERLOG_CHKPOINT_NOT_FOUND equ 5032
ERROR_CLUSTERLOG_NOT_ENOUGH_SPACE equ 5033
ERROR_ENCRYPTION_FAILED equ 6000
ERROR_DECRYPTION_FAILED equ 6001
ERROR_FILE_ENCRYPTED equ 6002
ERROR_NO_RECOVERY_POLICY equ 6003
ERROR_NO_EFS equ 6004
ERROR_WRONG_EFS equ 6005
ERROR_NO_USER_KEYS equ 6006
ERROR_FILE_NOT_ENCRYPTED equ 6007
ERROR_NOT_EXPORT_FORMAT equ 6008
SEVERITY_SUCCESS equ 0
SEVERITY_ERROR equ 1
FACILITY_NT_BIT equ $10000000
%endif


;=============================================================================
%ifdef UseWinRegistry

HKEY_CLASSES_ROOT equ $80000000
HKEY_CURRENT_USER equ $80000001
HKEY_LOCAL_MACHINE equ $80000002
HKEY_USERS equ $80000003
HKEY_PERFORMANCE_DATA equ $80000004
HKEY_CURRENT_CONFIG equ $80000005
HKEY_DYN_DATA equ $80000006

REG_SZ equ 1
REG_EXPAND_SZ equ 2
REG_BINARY equ 3
REG_DWORD equ 4
REG_DWORD_LITTLE_ENDIAN equ 4
REG_DWORD_BIG_ENDIAN equ 5
REG_LINK equ 6
REG_MULTI_SZ equ 7
REG_RESOURCE_LIST equ 8
REG_FULL_RESOURCE_DESCRIPTOR equ 9
REG_RESOURCE_REQUIREMENTS_LIST equ 10

KEY_QUERY_VALUE equ 1
KEY_SET_VALUE equ 2
KEY_CREATE_SUB_KEY equ 4
KEY_ENUMERATE_SUB_KEYS equ 8
KEY_NOTIFY equ 16
KEY_CREATE_LINK equ 32
%if 0
KEY_READ equ (STANDARD_RIGHTS_READ | KEY_QUERY_VALUE | KEY_ENUMERATE_SUB_KEYS | KEY_NOTIFY) & ~SYNCHRONIZE
KEY_WRITE equ (STANDARD_RIGHTS_WRITE | KEY_SET_VALUE | KEY_CREATE_SUB_KEY) & ~SYNCHRONIZE
KEY_EXECUTE equ KEY_READ & ~SYNCHRONIZE
KEY_ALL_ACCESS equ (STANDARD_RIGHTS_ALL | KEY_QUERY_VALUE | KEY_SET_VALUE | KEY_CREATE_SUB_KEY | KEY_ENUMERATE_SUB_KEYS | KEY_NOTIFY | KEY_CREATE_LINK) & ~SYNCHRONIZE

REG_OPTION_RESERVED equ 0
REG_OPTION_NON_VOLATILE equ 0
REG_OPTION_VOLATILE equ 1
REG_OPTION_CREATE_LINK equ 2
REG_OPTION_BACKUP_RESTORE equ 4
REG_OPTION_OPEN_LINK equ 8
REG_LEGAL_OPTION equ REG_OPTION_RESERVED | REG_OPTION_NON_VOLATILE | REG_OPTION_VOLATILE | REG_OPTION_CREATE_LINK | REG_OPTION_BACKUP_RESTORE | REG_OPTION_OPEN_LINK
REG_CREATED_NEW_KEY equ 1
REG_OPENED_EXISTING_KEY equ 2
REG_WHOLE_HIVE_VOLATILE equ 1
REG_REFRESH_HIVE equ 2
REG_NO_LAZY_FLUSH equ 4
REG_NOTIFY_CHANGE_NAME equ 1
REG_NOTIFY_CHANGE_ATTRIBUTES equ 2
REG_NOTIFY_CHANGE_LAST_SET equ 4
REG_NOTIFY_CHANGE_SECURITY equ 8
REG_LEGAL_CHANGE_FILTER equ REG_NOTIFY_CHANGE_NAME | REG_NOTIFY_CHANGE_ATTRIBUTES | REG_NOTIFY_CHANGE_LAST_SET | REG_NOTIFY_CHANGE_SECURITY
REG_NONE equ 0
%endif

%endif


;=============================================================================
%ifdef UseMemory

GMEM_FIXED equ 0
GMEM_MOVEABLE equ 2
GMEM_NOCOMPACT equ 16
GMEM_NODISCARD equ 32
GMEM_ZEROINIT equ 64
GMEM_MODIFY equ 128
GMEM_DISCARDABLE equ 256
GMEM_NOT_BANKED equ 4096
GMEM_SHARE equ 8192
GMEM_DDESHARE equ 8192
GMEM_NOTIFY equ 16384
GMEM_LOWER equ GMEM_NOT_BANKED
GMEM_VALID_FLAGS equ $7f72
GMEM_DISCARDED equ 16384
GMEM_INVALID_HANDLE equ 32768
GMEM_LOCKCOUNT equ 255
GHND equ GMEM_MOVEABLE | GMEM_ZEROINIT
GPTR equ GMEM_FIXED | GMEM_ZEROINIT
LMEM_FIXED equ 0
LMEM_MOVEABLE equ 2
LMEM_NOCOMPACT equ 16
LMEM_NODISCARD equ 32
LMEM_ZEROINIT equ 64
LMEM_MODIFY equ 128
LMEM_DISCARDABLE equ 3840
LMEM_VALID_FLAGS equ 3954
LMEM_INVALID_HANDLE equ 32768
LMEM_DISCARDED equ 16384
LMEM_LOCKCOUNT equ 255
LHND equ LMEM_MOVEABLE | LMEM_ZEROINIT
LPTR equ LMEM_FIXED | LMEM_ZEROINIT

%endif


;=============================================================================
%ifdef UseClipboard

CF_TEXT equ 1
CF_BITMAP equ 2
CF_METAFILEPICT equ 3
CF_SYLK equ 4
CF_DIF equ 5
CF_TIFF equ 6
CF_OEMTEXT equ 7
CF_DIB equ 8
CF_PALETTE equ 9
CF_PENDATA equ 10
CF_RIFF equ 11
CF_WAVE equ 12
CF_UNICODETEXT equ 13
CF_ENHMETAFILE equ 14
CF_HDROP equ 15
CF_LOCALE equ 16
CF_MAX equ 17
CF_OWNERDISPLAY equ $80
CF_DSPTEXT equ $81
CF_DSPBITMAP equ $82
CF_DSPMETAFILEPICT equ $83
CF_DSPENHMETAFILE equ $8E
CF_PRIVATEFIRST equ $200
CF_PRIVATELAST equ $2FF
CF_GDIOBJFIRST equ $300
CF_GDIOBJLAST equ $3FF

%endif


;=============================================================================
%ifdef UseMultimedia

MAXERRORLENGTH equ 256  ;!128
MAXPNAMELEN equ 32

CALLBACK_TYPEMASK equ  00070000h ;callback type mask
CALLBACK_NULL equ      00000000h ;no callback
CALLBACK_WINDOW equ    00010000h ;dwCallback is a HWND
CALLBACK_TASK equ      00020000h ;dwCallback is a HTASK
CALLBACK_FUNCTION equ  00030000h ;dwCallback is a FARPROC
CALLBACK_THREAD equ    CALLBACK_TASK ;thread ID replaces 16 bit task
CALLBACK_EVENT equ     00050000h ;dwCallback is an EVENT Handle

; device ID for wave device mapper
WAVE_MAPPER equ -1
MIDI_MAPPER equ -1

; flags for dwFlags parameter in waveOutOpen() and waveInOpen()
WAVE_FORMAT_QUERY equ 0001h
WAVE_ALLOWSYNC equ 0002h
WAVE_MAPPED equ 0004h
WAVE_FORMAT_DIRECT equ 0008h
WAVE_FORMAT_DIRECT_QUERY equ WAVE_FORMAT_QUERY | WAVE_FORMAT_DIRECT

SND_SYNC equ 0000h ;play synchronously (default)
SND_ASYNC equ 0001h ;play asynchronously
SND_NODEFAULT equ 0002h  ;silence (!default) if sound not found
SND_MEMORY equ 0004h  ;pszSound points to a memory file
SND_LOOP equ 0008h ;loop the sound until next sndPlaySound
SND_NOSTOP equ 0010h ;don't stop any currently playing sound
SND_NOWAIT equ 00002000h ;don't wait if the driver is busy
SND_ALIAS equ 00010000h ;name is a registry alias
SND_ALIAS_ID equ 00110000h ;alias is a predefined ID
SND_FILENAME equ 00020000h ;name is file name
SND_RESOURCE equ 00040004h ;name is resource name or atom
SND_PURGE equ 0040h ;purge non-static events for task
SND_APPLICATION equ 0080h  ;look for application specific association

; wave data block header
struc WAVEHDR
.lpData             resd 1      ;pointer to locked data buffer
.dwBufferLength     resd 1      ;length of data buffer
.dwBytesRecorded    resd 1      ;used for input only
.dwUser             resd 1      ;for client's use
.dwFlags            resd 1      ;assorted flags (see defines)
.dwLoops            resd 1      ;loop control counter
.lpNext             resd 1      ;reserved for driver
.reserved           resd 1      ;reserved for driver
endstruc

; flags for dwFlags field of WAVEHDR
WHDR_DONE       equ 00000001h   ; done bit
WHDR_PREPARED   equ 00000002h   ; set if this header has been prepared
WHDR_BEGINLOOP  equ 00000004h   ; loop start block
WHDR_ENDLOOP    equ 00000008h   ; loop end block
WHDR_INQUEUE    equ 00000010h   ; reserved for driver

; extended waveform format structure used for all non-PCM formats. this
;  structure is common to all non-PCM formats.
struc WAVEFORMATEX
.wFormatTag         resw 1      ; format type
.nChannels          resw 1      ; number of channels (i.e. mono, stereo...)
.nSamplesPerSec     resd 1      ; sample rate
.nAvgBytesPerSec    resd 1      ; for buffer estimation
.nBlockAlign        resw 1      ; block size of data
.wBitsPerSample     resw 1      ; number of bits per sample of mono data
.cbSize             resw 1      ; the count in bytes of the size of
                                ; extra information (after cbSize)
endstruc

struc WAVEOUTCAPS
.wMid               resw 1      ; manufacturer ID
.wPid               resw 1      ; product ID
.vDriverVersion     resd 1      ; version of the driver
.szPname            resb MAXPNAMELEN ; product name (NULL terminated string)
.dwFormats          resd 1      ; formats supported
.wChannels          resw 1      ; number of sources supported
.wReserved          resw 1      ; packing
.dwSupport          resd 1      ; functionality supported by driver
endstruc

; time formats (used in MMTIME)
TIME_MS equ 1h
TIME_SAMPLES equ 2h
TIME_BYTES equ 4h
TIME_SMPTE equ 8h
TIME_MIDI equ 10h

struc MMTIME
.wType              resd 1
.ms:
.sample:
.cb:
.midi:
.ticks:
.u:
.smpte:
.smpte.hour         resb 1
.smpte.min          resb 1
.smpte.sec          resb 1
.smpte.frame        resb 1
.smpte.fps          resb 1
.smpte.pad          resb 3
endstruc

struc MIDIOUTCAPS
.wMid               resw 1
.wPid               resw 1
.vDriverVersion     resd 1
.szPname            resb MAXPNAMELEN
.wTechnology        resw 1
.wVoices            resw 1
.wNotes             resw 1
.wChannelMask       resw 1
.dwSupport          resd 1
endstruc

; wTechnology types
MOD_MIDIPORT equ 1
MOD_SYNTH equ 2
MOD_SQSYNTH equ 3
MOD_FMSYNTH equ 4
MOD_MAPPER equ 5

%endif


;=============================================================================
%ifdef UseProcess

struc CRITICAL_SECTION
.Par1 RESD 1
.Par2 RESD 1
.Par3 RESD 1
.Par4 RESD 1
.Par5 RESD 1
.Par6 RESD 1
endstruc

NORMAL_PRIORITY_CLASS equ 20h
IDLE_PRIORITY_CLASS equ 40h
HIGH_PRIORITY_CLASS equ 80h
REALTIME_PRIORITY_CLASS equ 100h

THREAD_BASE_PRIORITY_MIN equ -2
THREAD_BASE_PRIORITY_MAX equ 2
THREAD_BASE_PRIORITY_LOWRT equ 15
THREAD_BASE_PRIORITY_IDLE equ -15
THREAD_PRIORITY_LOWEST equ THREAD_BASE_PRIORITY_MIN
THREAD_PRIORITY_BELOW_NORMAL equ THREAD_PRIORITY_LOWEST+1
THREAD_PRIORITY_NORMAL equ 0
THREAD_PRIORITY_HIGHEST equ THREAD_BASE_PRIORITY_MAX
THREAD_PRIORITY_ABOVE_NORMAL equ THREAD_PRIORITY_HIGHEST-1
THREAD_PRIORITY_TIME_CRITICAL equ THREAD_BASE_PRIORITY_LOWRT
THREAD_PRIORITY_IDLE equ THREAD_BASE_PRIORITY_IDLE

CREATE_SUSPENDED equ 4h

STATUS_WAIT_0 equ 0
STATUS_ABANDONED_WAIT_0 equ $80
STATUS_USER_APC equ $0C0
STATUS_TIMEOUT equ $102
STATUS_PENDING equ $103
STATUS_SEGMENT_NOTIFICATION equ $40000005
STATUS_GUARD_PAGE_VIOLATION equ $80000001
STATUS_DATATYPE_MISALIGNMENT equ $80000002
STATUS_BREAKPOINT equ $80000003
STATUS_SINGLE_STEP equ $80000004
STATUS_ACCESS_VIOLATION equ $0C0000005
STATUS_IN_PAGE_ERROR equ $0C0000006
STATUS_INVALID_HANDLE equ $0C0000008
STATUS_NO_MEMORY equ $0C0000017
STATUS_ILLEGAL_INSTRUCTION equ $0C000001D
STATUS_NONCONTINUABLE_EXCEPTION equ $0C0000025
STATUS_INVALID_DISPOSITION equ $0C0000026
STATUS_ARRAY_BOUNDS_EXCEEDED equ $0C000008C
STATUS_FLOAT_DENORMAL_OPERAND equ $0C000008D
STATUS_FLOAT_DIVIDE_BY_ZERO equ $0C000008E
STATUS_FLOAT_INEXACT_RESULT equ $0C000008F
STATUS_FLOAT_INVALID_OPERATION equ $0C0000090
STATUS_FLOAT_OVERFLOW equ $0C0000091
STATUS_FLOAT_STACK_CHECK equ $0C0000092
STATUS_FLOAT_UNDERFLOW equ $0C0000093
STATUS_INTEGER_DIVIDE_BY_ZERO equ $0C0000094
STATUS_INTEGER_OVERFLOW equ $0C0000095
STATUS_PRIVILEGED_INSTRUCTION equ $0C0000096
STATUS_STACK_OVERFLOW equ $0C00000FD

WAIT_FAILED equ $0ffffffff
WAIT_OBJECT_0 equ STATUS_WAIT_0
WAIT_ABANDONED equ STATUS_ABANDONED_WAIT_0
;WAIT_ABANDONED_0 equ STATUS_ABANDONED_WAIT_0
WAIT_TIMEOUT equ STATUS_TIMEOUT
WAIT_IO_COMPLETION equ STATUS_USER_APC
STILL_ACTIVE equ STATUS_PENDING

struc PROCESSENTRY32
.dwSize                 resd 1
.cntUsage               resd 1
.th32ProcessID          resd 1
.th32DefaultHeapID      resd 1
.th32ModuleID           resd 1
.cntThreads             resd 1
.th32ParentProcessID    resd 1
.pcPriClassBase         resd 1
.dwFlags                resd 1
.szExeFile              resb MAX_PATH
endstruc

struc STARTUPINFO
.cb RESD 1
.lpReserved RESD 1
.lpDesktop RESD 1
.lpTitle RESD 1
.dwX RESD 1
.dwY RESD 1
.dwXSize RESD 1
.dwYSize RESD 1
.dwXCountChars RESD 1
.dwYCountChars RESD 1
.dwFillAttribute RESD 1
.dwFlags RESD 1
.wShowWindow RESW 1
.cbReserved2 RESW 1
.lpReserved2 RESB 1
.hStdInput RESD 1
.hStdOutput RESD 1
.hStdError RESD 1
endstruc

%endif


;=============================================================================
%ifdef UseNetwork

struc NETRESOURCE
.dwScope        resd 1
.dwType         resd 1
.dwDisplayType  resd 1
.dwUsage        resd 1
.lpLocalName    resd 1
.lpRemoteName   resd 1
.lpComment      resd 1
.lpProvider     resd 1
endstruc

RESOURCE_CONNECTED equ 1
RESOURCE_GLOBALNET equ 2
RESOURCE_REMEMBERED equ 3
RESOURCE_RECENT equ 4
RESOURCE_CONTEXT equ 5
RESOURCEDISPLAYTYPE_GENERIC equ 0
RESOURCEDISPLAYTYPE_DOMAIN equ 1
RESOURCEDISPLAYTYPE_SERVER equ 2
RESOURCEDISPLAYTYPE_SHARE equ 3
RESOURCEDISPLAYTYPE_FILE equ 4
RESOURCEDISPLAYTYPE_GROUP equ 5
RESOURCEDISPLAYTYPE_NETWORK equ 6
RESOURCEDISPLAYTYPE_ROOT equ 7
RESOURCEDISPLAYTYPE_SHAREADMIN equ 8
RESOURCEDISPLAYTYPE_DIRECTORY equ 9
RESOURCEDISPLAYTYPE_TREE equ 10
RESOURCEDISPLAYTYPE_NDSCONTAINER equ 11
RESOURCETYPE_ANY equ 0
RESOURCETYPE_DISK equ 1
RESOURCETYPE_PRINT equ 2
RESOURCETYPE_RESERVED equ 8
RESOURCETYPE_UNKNOWN equ $0ffffffff
RESOURCEUSAGE_CONNECTABLE equ 1
RESOURCEUSAGE_CONTAINER equ 2
RESOURCEUSAGE_NOLOCALDEVICE equ 4
RESOURCEUSAGE_SIBLING equ 8
RESOURCEUSAGE_ATTACHED equ 16
RESOURCEUSAGE_ALL equ RESOURCEUSAGE_CONNECTABLE | RESOURCEUSAGE_CONTAINER | RESOURCEUSAGE_ATTACHED
RESOURCEUSAGE_RESERVED equ $080000000

%endif


;=============================================================================
%ifdef UseWinsock

INVALID_SOCKET equ -1
SOCKET_ERROR equ -1

SOCK_STREAM equ 1
SOCK_DGRAM equ 2
SOCK_RAW equ 3
SOCK_RDM equ 4
SOCK_SEQPACKET equ 5
SO_DEBUG equ 00001h
SO_ACCEPTCONN equ 00002h
SO_REUSEADDR equ 00004h
SO_KEEPALIVE equ 00008h
SO_DONTROUTE equ 00010h
SO_BROADCAST equ 00020h
SO_USELOOPBACK equ 00040h
SO_LINGER equ 00080h
SO_OOBINLINE equ 00100h
SOL_SOCKET equ 0FFFFh
SO_DONTLINGER equ (-1-SO_LINGER)
SO_SNDBUF equ 01001h
SO_RCVBUF equ 01002h
SO_SNDLOWAT equ 01003h
SO_RCVLOWAT equ 01004h
SO_SNDTIMEO equ 01005h
SO_RCVTIMEO equ 01006h
SO_ERROR equ 01007h
SO_TYPE equ 01008h
TCP_NODELAY equ 00001h

WSADESCRIPTION_LEN equ 256
WSASYS_STATUS_LEN equ 128

INADDR_ANY equ 000000000h
INADDR_LOOPBACK equ 07F000001h
INADDR_BROADCAST equ 0FFFFFFFFh
INADDR_NONE equ 0FFFFFFFFh

; Address families.
AF_UNSPEC    equ 0      ;unspecified
AF_UNIX      equ 1      ;local to host (pipes, portals)
AF_INET      equ 2      ;internetwork: UDP, TCP, etc.
AF_IMPLINK   equ 3      ;arpanet imp addresses
AF_PUP       equ 4      ;pup protocols: e.g. BSP
AF_CHAOS     equ 5      ;mit CHAOS protocols
AF_IPX       equ 6      ;IPX and SPX
AF_NS        equ 6      ;XEROX NS protocols
AF_ISO       equ 7      ;ISO protocols
AF_OSI       equ AF_ISO ;OSI is ISO
AF_ECMA      equ 8      ;european computer manufacturers
AF_DATAKIT   equ 9      ;datakit protocols
AF_CCITT     equ 10     ;CCITT protocols, X.25 etc
AF_SNA       equ 11     ;IBM SNA
AF_DECnet    equ 12     ;DECnet
AF_DLI       equ 13     ;Direct data link interface
AF_LAT       equ 14     ;LAT
AF_HYLINK    equ 15     ;NSC Hyperchannel
AF_APPLETALK equ 16     ;AppleTalk
AF_NETBIOS   equ 17     ;NetBios-style addresses
AF_VOICEVIEW equ 18     ;VoiceView
AF_FIREFOX   equ 19     ;FireFox
AF_UNKNOWN1  equ 20     ;Somebody is using this!
AF_BAN       equ 21     ;Banyan
AF_MAX       equ 22

;All PF_s = their equivalent address families
PF_UNSPEC    equ AF_UNSPEC
PF_UNIX      equ AF_UNIX
PF_INET      equ AF_INET
PF_IMPLINK   equ AF_IMPLINK
PF_PUP       equ AF_PUP
PF_CHAOS     equ AF_CHAOS
PF_IPX       equ AF_IPX
PF_NS        equ AF_NS
PF_ISO       equ AF_ISO
PF_OSI       equ AF_OSI
PF_ECMA      equ AF_ECMA
PF_DATAKIT   equ AF_DATAKIT
PF_CCITT     equ AF_CCITT
PF_SNA       equ AF_SNA
PF_DECnet    equ AF_DECnet
PF_DLI       equ AF_DLI
PF_LAT       equ AF_LAT
PF_HYLINK    equ AF_HYLINK
PF_APPLETALK equ AF_APPLETALK
PF_NETBIOS   equ AF_NETBIOS
PF_VOICEVIEW equ AF_VOICEVIEW
PF_FIREFOX   equ AF_FIREFOX
PF_UNKNOWN1  equ AF_UNKNOWN1
PF_BAN       equ AF_BAN
PF_MAX       equ AF_MAX

FIONBIO  equ 8004667Eh
FIONSYNC equ 8004667Dh
FIONREAD equ 4004667Fh

WSAEWOULDBLOCK equ 10035

struc TIMEVAL
tv_sec  resd 1  ;seconds
tv_usec resd 1  ;and microseconds
endstruc

struc WSADATA
.wVersion       resw 1
.wHighVersion   resw 1
.szDescription  resb WSADESCRIPTION_LEN+1
.szSystemStatus resb WSASYS_STATUS_LEN+1
.iMaxSockets    resw 1
.iMaxUdpDg      resw 1
.lpVendorInfo   resd 1
endstruc

struc SOCKADDR_INET
.sin_family resw 1
.sin_port   resw 1
.sin_addr   resd 1
.sin_zero   resb 8
endstruc

struc SOCKADDR
.sa_family  resw 1
.sa_data    resw 1
endstruc

struc HOSTENT
.h_name     RESD 1
.h_alias    RESD 1
.h_addr     RESW 1
.h_len      RESW 1
.h_list     RESD 1
endstruc


%endif


;=============================================================================
%include "macros32.inc"

; Call standard API functions contained in DLLs
; using indirect function ptr from import table
;
; (function name ptr, parameters...)
%ifdef _VCLINK
 %macro apimsvc 1-*
    %assign %%i (%0-1)*4
    %rep %0 -1
      %rotate -1
      pushw32d %1
    %endrep
    %rotate -1
    extern %1@%%i
    call %1@%%i                 ;call indirectly via stub
 %endmacro

 %macro api 1+
    apimsvc _%1
 %endmacro

%elifdef _DMCLINK
 ; TODO: What's the difference between this and the VC one above? Merge?
 %macro apidmc 1-*
    %assign %%i (%0-1)*4
    %rep %0 -1
      %rotate -1
      pushw32d %1
    %endrep
    %rotate -1
    extern %1@%%i
    call %1@%%i                 ;call indirectly via stub
 %endmacro

 %macro api 1+
    apidmc _%1
 %endmacro

%else
 %macro api 1-*
    %rep %0 -1
      %rotate -1
      pushw32d %1
    %endrep
    %rotate -1
    extern %1
    call [%1]                   ;call indirectly through function pointer
 %endmacro

 ; TODO: What's the difference between this and 'api'? Merge?
 %macro apiw 1-*
    %rep %0 -1
      %rotate -1
      pushw32d %1
    %endrep
    %rotate -1
    extern %1
    call [%1]                   ;call indirectly through function pointer
 %endmacro

%endif

; Call COM functions (component object model)
; passing the object to the function in the table
;
; (function name offset, object, parameters...)
%macro com 2-*
    %rep %0 -2
      %rotate -1
      pushdword %1
    %endrep
    %rotate -2
    %ifid
      mov edx,[%2]              ;get ptr to function table
      push %2
    %else
      mov eax,[%2]              ;get ptr to COM object
      mov edx,[eax]             ;get ptr to function table
      push eax
    %endif
    call [edx+%1]               ;call very indirectly through function table
%endmacro

%ifdef _UNICODE
; Pushes a single dword item, whether register, address, or string.
; It allocates a temporary string if necessary. 'void' is a special
; identifier to do nothing - useful for api calls which already
; have some of the parameters pushed.
%macro pushw32d 1
	  %ifidni %1,void
      %elifstr %1
[section .string]
		; alignb 4,0
        %%Text: dw %1,0
__SECT__
        push dword %%Text
      %else
        push dword %1
      %endif
%endmacro

%else

; ANSI version of same function
%macro pushw32d 1
	  %ifidni %1,void
      %elifstr %1
[section .string]
		; alignb 4,0
        %%Text: db %1,0
__SECT__
        push dword %%Text
      %else
        push dword %1
      %endif
%endmacro

%endif

; Declares a single string
; (label, string)
%imacro string 2+
[section .string]
      ; alignb 4,0
      %1 equ $
      %ifstr %2
        db %2
      %else
        %2
      %endif
__SECT__
%endmacro

; Declares a single Unicode string
; (label, string)
%imacro stringw 2+
[section .string]
      ; alignb 4,0
      %1 equ $
      %ifstr %2
        dw %2
      %else
        %2
      %endif
__SECT__
%endmacro

; Declares a single null terminated string
; (label, string null terminated)
%imacro stringz 2+
[section .string]
      ; alignb 4,0
      %1 equ $
      %ifstr %2
        db %2,0
      %else
        %2
      %endif
__SECT__
%endmacro

; Declares a pointer to a Unicode null terminated string
; (label, string null terminated)
%imacro stringptrwz 1+
[section .string]
      ; alignb 4,0
      %%Msg equ $
      %ifstr %1
        dw %1,0
      %else
        %1
      %endif
__SECT__
      dd %%Msg
%endmacro


; Restarts string table.
; (base number)
%macro StrTblNew 1
    %assign StrTblId %1-1
%endmacro

; Adds another item to a string table.
; (index, string)
%macro StrTblItem 2
    %if %1<=StrTblId
        %error "StrTblItem: next id < previous id"
    %endif
    %assign StrTblId %1
    dw %1                       ;numeric identifier
    db %%StrLen-$-1             ;length of string
    db %2                       ;string bytes
%%StrLen:
    db 0                        ;terminating null char
%endmacro

; Defines a structure for a child window control
; (control name,    (what to call it in your program)
;  control id,      (unique numeric identifier)
;  class name,      (BUTTON, EDIT, msctls_progress32...)
;  control text,    (initial window text or ptr to text string)
;  style flags,     (the child and visible flags are ORed automatically)
;  ex style flags,  (extended style flags)
;  x,               (left offset)
;  y,               (top offset)
;  width,
;  height
;)
%macro DefWndControl 10
align 4,db 0
%1:
    ; define a WndControlStruct
    dd 0                        ;reserve dword for window handle, initially null
    dd %2                       ;id
    .Id equ %2
    dd %6                       ;ex style flags
    dd %3                       ;class name
%ifstr %4
[section .string]
    %%Msg: db %4,0
__SECT__
    dd %%Msg                    ;window text
%else
    dd %4                       ;window text
%endif
    dd (%5|WS_CHILD)^WS_VISIBLE ;style
    dd %7                       ;x
    dd %8                       ;y
    dd %9                       ;width
    dd %10                      ;height
%endmacro

%ifndef debug
  %macro debugwrite 1-*
  %endmacro
  %macro debugpause 1-*
  %endmacro
%else
  ; Pushes a single dword item - either a register, address, or string.
  ; Similar to pushdword, but the string is either appended with a NULL
  ; or CR/LF/NULL, depending on the debug mode.
  %macro debugpush 1
    %ifstr %1
[section .string]
     %ifdef UseConsoleDebug
      %%Msg: db %1,13,10,0
     %else
      %%Msg: db %1,0
     %endif
__SECT__
     push dword %%Msg
    %else
     push dword %1
    %endif
  %endmacro

  %macro debugwrite 1
  	debugpush %1
    call WriteDebugString
  %endmacro

  %macro debugwrite 2-*
    %rep %0
      %rotate -1
      debugpush %1
    %endrep
    push dword %0*4
    call WriteDebugMsg
  %endmacro

  %macro debugpause 1-*
    %rep %0
      %rotate -1
      debugpush %1
    %endrep
    push dword %0*4
    call PauseDebugMsg
  %endmacro

[section .text]

; Writes formula string to any active debugger. Saves all regs and flags.
; (dwords param byte count, string, param1, param2...)
; (all regs and flags saved)
WriteDebugMsg:
    pusha
    pushf

	; TODO: Change to static text buffer to stack allocated buffer
	;		so multiple threads can call this function without
	;		messing up their output. Actually, I've never had that
	;		occur yet, but... just in case.
    lea esi,[esp+36+12]         ;ptr to array of values
    api wvsprintf, .TextBuffer, [esp+36+8+4], esi
  %ifdef UseConsoleDebug
    mov eax,[.StdOut]
    test eax,eax
    jnz .HandleValid
    api GetStdHandle, STD_ERROR_HANDLE
    mov [.StdOut],eax
  .HandleValid:
    xor ecx,ecx
  .NextChar:
    cmp byte [.TextBuffer+ecx],0
    je .Eos
    inc ecx
    jmp short .NextChar
  .Eos:
    api WriteConsole, eax, .TextBuffer,ecx, .Dummy, NULL
  %else
    api OutputDebugString, .TextBuffer
  %endif

	; mess with the stack so the parameters on it
	; can be popped off leaving all registers as they
	; were when called.
    mov edx,[esp+36]            ;get return address
    mov ecx,[esp+4+36]          ;get byte count of parameters passed
    mov [esp+ecx+4+36],edx      ;set return address
    lea eax,[esp+ecx+4+36]
    mov [esp+36],eax            ;set stack ptr

    popf
    popa
    pop esp
    ret

[section .bss]
alignb 4
.TextBuffer:    resb 1024
.Dummy:         resd 1
[section .data]
align 4,db 0
.StdOut:        dd 0
[section .text]


; Writes a pure string of text, no variables.
; (dword string ptr)
; (all regs and flags saved)
WriteDebugString:
    pusha
    pushf
  %ifdef UseConsoleDebug
    mov eax,[WriteDebugMsg.StdOut]
    test eax,eax
    jnz .HandleValid
    ;api GetStdHandle, STD_ERROR_HANDLE
    api GetStdHandle, STD_OUTPUT_HANDLE
    mov [WriteDebugMsg.StdOut],eax
  .HandleValid:
    mov esi,[esp+32+4+4]
    xor ecx,ecx
  .NextChar:
    cmp byte [esi+ecx],0
    je .Eos
    inc ecx
    jmp short .NextChar
  .Eos:
    ;api WriteFile, eax, esi,ecx, WriteDebugMsg.Dummy, NULL
    api WriteConsole, eax, esi,ecx, WriteDebugMsg.Dummy, NULL
  %else
    api OutputDebugString, [esp+32+4+4]
  %endif
    popf
    popa
    ret 4


PauseDebugMsg:
    pusha
    pushf

    lea esi,[esp+36+12]         ;ptr to array of values
    api wvsprintf, .TextBuffer, [esp+36+8+4], esi
    api GetActiveWindow
    test eax,eax
    jnz .GotHwnd
    api GetForegroundWindow
    ;GetWindowThreadProcessId eax,NULL
.GotHwnd:
    api MessageBox, eax,.TextBuffer,.MsgCaption,0|8192|65536|262144   ;MB_OK|MB_TASKMODAL|MB_SETFOREGROUND|MB_TOPMOST

    mov edx,[esp+36]            ;get return address
    mov ecx,[esp+4+36]          ;get byte count of parameters passed
    mov [esp+ecx+4+36],edx      ;set return address
    lea eax,[esp+ecx+4+36]
    mov [esp+36],eax            ;set stack ptr

    popf
    popa
    pop esp
    ret

[section .bss]
alignb 4
.TextBuffer:	resb 1024 ;equ WriteDebugMsg.TextBuffer
[section .string]
.MsgCaption:	db "Debug Message Pause",0

__SECT__
%endif

%ifdef debug
 %ifdef UseWindowMsgs

  %macro debugwinmsg 2+
    call GetWinMsgName
    debugwrite %1,%2
  %endmacro

[section .string]
WinMsgNames:
    StrTblNew 0
    StrTblItem WM_NULL,"WM_NULL"
    StrTblItem WM_CREATE,"WM_CREATE"
    StrTblItem WM_DESTROY,"WM_DESTROY"
    StrTblItem WM_MOVE,"WM_MOVE"
    StrTblItem WM_SIZE,"WM_SIZE"
    StrTblItem WM_ACTIVATE,"WM_ACTIVATE"
    StrTblItem WM_SETFOCUS,"WM_SETFOCUS"
    StrTblItem WM_KILLFOCUS,"WM_KILLFOCUS"
    StrTblItem WM_ENABLE,"WM_ENABLE"
    StrTblItem WM_SETREDRAW,"WM_SETREDRAW"
    StrTblItem WM_SETTEXT,"WM_SETTEXT"
    StrTblItem WM_GETTEXT,"WM_GETTEXT"
    StrTblItem WM_GETTEXTLENGTH,"WM_GETTEXTLENGTH"
    StrTblItem WM_PAINT,"WM_PAINT"
    StrTblItem WM_CLOSE,"WM_CLOSE"
    StrTblItem WM_QUERYENDSESSION,"WM_QUERYENDSESSION"
    StrTblItem WM_QUIT,"WM_QUIT"
    StrTblItem WM_QUERYOPEN,"WM_QUERYOPEN"
    StrTblItem WM_ERASEBKGND,"WM_ERASEBKGND"
    StrTblItem WM_SYSCOLORCHANGE,"WM_SYSCOLORCHANGE"
    StrTblItem WM_ENDSESSION,"WM_ENDSESSION"
    StrTblItem WM_SHOWWINDOW,"WM_SHOWWINDOW"
    StrTblItem WM_WININICHANGE,"WM_WININICHANGE"
    StrTblItem WM_DEVMODECHANGE,"WM_DEVMODECHANGE"
    StrTblItem WM_ACTIVATEAPP,"WM_ACTIVATEAPP"
    StrTblItem WM_FONTCHANGE,"WM_FONTCHANGE"
    StrTblItem WM_TIMECHANGE,"WM_TIMECHANGE"
    StrTblItem WM_CANCELMODE,"WM_CANCELMODE"
    StrTblItem WM_SETCURSOR,"WM_SETCURSOR"
    StrTblItem WM_MOUSEACTIVATE,"WM_MOUSEACTIVATE"
    StrTblItem WM_CHILDACTIVATE,"WM_CHILDACTIVATE"
    StrTblItem WM_QUEUESYNC,"WM_QUEUESYNC"
    StrTblItem WM_GETMINMAXINFO,"WM_GETMINMAXINFO"

    StrTblItem WM_WINDOWPOSCHANGING,"WM_WINDOWPOSCHANGING"
    StrTblItem WM_WINDOWPOSCHANGED,"WM_WINDOWPOSCHANGED"

    StrTblItem WM_DISPLAYCHANGE,"WM_DISPLAYCHANGE"

    StrTblItem WM_NCCREATE,"WM_NCCREATE"
    StrTblItem WM_NCDESTROY,"WM_NCDESTROY"
    StrTblItem WM_NCCALCSIZE,"WM_NCCALCSIZE"
    StrTblItem WM_NCHITTEST,"WM_NCHITTEST"
    StrTblItem WM_NCPAINT,"WM_NCPAINT"
    StrTblItem WM_NCACTIVATE,"WM_NCACTIVATE"
    StrTblItem WM_GETDLGCODE,"WM_GETDLGCODE"
    StrTblItem WM_SYNCPAINT,"WM_SYNCPAINT"

    StrTblItem WM_NCMOUSEMOVE,"WM_NCMOUSEMOVE"
    StrTblItem WM_NCLBUTTONDOWN,"WM_NCLBUTTONDOWN"
    StrTblItem WM_NCLBUTTONUP,"WM_NCLBUTTONUP"
    StrTblItem WM_NCLBUTTONDBLCLK,"WM_NCLBUTTONDBLCLK"
    StrTblItem WM_NCRBUTTONDOWN,"WM_NCRBUTTONDOWN"
    StrTblItem WM_NCRBUTTONUP,"WM_NCRBUTTONUP"
    StrTblItem WM_NCRBUTTONDBLCLK,"WM_NCRBUTTONDBLCLK"
    StrTblItem WM_NCMBUTTONDOWN,"WM_NCMBUTTONDOWN"
    StrTblItem WM_NCMBUTTONUP,"WM_NCMBUTTONUP"
    StrTblItem WM_NCMBUTTONDBLCLK,"WM_NCMBUTTONDBLCLK"

    StrTblItem WM_KEYDOWN,"WM_KEYDOWN"
    StrTblItem WM_KEYUP,"WM_KEYUP"
    StrTblItem WM_CHAR,"WM_CHAR"
    StrTblItem WM_DEADCHAR,"WM_DEADCHAR"
    StrTblItem WM_SYSKEYDOWN,"WM_SYSKEYDOWN"
    StrTblItem WM_SYSKEYUP,"WM_SYSKEYUP"
    StrTblItem WM_SYSCHAR,"WM_SYSCHAR"
    StrTblItem WM_SYSDEADCHAR,"WM_SYSDEADCHAR"
    StrTblItem WM_KEYLAST,"WM_KEYLAST"

    StrTblItem WM_INITDIALOG,"WM_INITDIALOG"
    StrTblItem WM_COMMAND,"WM_COMMAND"
    StrTblItem WM_SYSCOMMAND,"WM_SYSCOMMAND"
    StrTblItem WM_TIMER,"WM_TIMER"
    StrTblItem WM_HSCROLL,"WM_HSCROLL"
    StrTblItem WM_VSCROLL,"WM_VSCROLL"
    StrTblItem WM_INITMENU,"WM_INITMENU"
    StrTblItem WM_INITMENUPOPUP,"WM_INITMENUPOPUP"
    StrTblItem WM_MENUSELECT,"WM_MENUSELECT"
    StrTblItem WM_MENUCHAR,"WM_MENUCHAR"
    StrTblItem WM_ENTERIDLE,"WM_ENTERIDLE"
    StrTblItem WM_MENURBUTTONUP,"WM_MENURBUTTONUP"
    StrTblItem WM_MENUDRAG,"WM_MENUDRAG"
    StrTblItem WM_MENUGETOBJECT,"WM_MENUGETOBJECT"
    StrTblItem WM_UNINITMENUPOPUP,"WM_UNINITMENUPOPUP"
    StrTblItem WM_MENUCOMMAND,"WM_MENUCOMMAND"
    StrTblItem WM_CTLCOLORMSGBOX,"WM_CTLCOLORMSGBOX"
    StrTblItem WM_CTLCOLOREDIT,"WM_CTLCOLOREDIT"
    StrTblItem WM_CTLCOLORLISTBOX,"WM_CTLCOLORLISTBOX"
    StrTblItem WM_CTLCOLORBTN,"WM_CTLCOLORBTN"
    StrTblItem WM_CTLCOLORDLG,"WM_CTLCOLORDLG"
    StrTblItem WM_CTLCOLORSCROLLBAR,"WM_CTLCOLORSCROLLBAR"
    StrTblItem WM_CTLCOLORSTATIC,"WM_CTLCOLORSTATIC"
    StrTblItem WM_MOUSEMOVE,"WM_MOUSEMOVE"
    StrTblItem WM_LBUTTONDOWN,"WM_LBUTTONDOWN"
    StrTblItem WM_LBUTTONUP,"WM_LBUTTONUP"
    StrTblItem WM_LBUTTONDBLCLK,"WM_LBUTTONDBLCLK"
    StrTblItem WM_RBUTTONDOWN,"WM_RBUTTONDOWN"
    StrTblItem WM_RBUTTONUP,"WM_RBUTTONUP"
    StrTblItem WM_RBUTTONDBLCLK,"WM_RBUTTONDBLCLK"
    StrTblItem WM_MBUTTONDOWN,"WM_MBUTTONDOWN"
    StrTblItem WM_MBUTTONUP,"WM_MBUTTONUP"
    StrTblItem WM_MBUTTONDBLCLK,"WM_MBUTTONDBLCLK"
    StrTblItem WM_MOUSEWHEEL,"WM_MOUSEWHEEL"
    StrTblItem WM_PARENTNOTIFY,"WM_PARENTNOTIFY"
    StrTblItem WM_ENTERMENULOOP,"WM_ENTERMENULOOP"
    StrTblItem WM_EXITMENULOOP,"WM_EXITMENULOOP"
    StrTblItem WM_NEXTMENU,"WM_NEXTMENU"

    StrTblItem WM_SIZING,"WM_SIZING"
    StrTblItem WM_CAPTURECHANGED,"WM_CAPTURECHANGED"
    StrTblItem WM_MOVING,"WM_MOVING"

    StrTblItem WM_ENTERSIZEMOVE,"WM_ENTERSIZEMOVE"
    StrTblItem WM_EXITSIZEMOVE,"WM_EXITSIZEMOVE"
    StrTblItem WM_DROPFILES,"WM_DROPFILES"
    StrTblItem WM_MDIREFRESHMENU,"WM_MDIREFRESHMENU"
    StrTblItem WM_IME_SETCONTEXT,"WM_IME_SETCONTEXT"
    StrTblItem WM_IME_NOTIFY,"WM_IME_NOTIFY"
    StrTblItem WM_IME_CONTROL,"WM_IME_CONTROL"
    StrTblItem WM_IME_COMPOSITIONFULL,"WM_IME_COMPOSITIONFULL"
    StrTblItem WM_IME_SELECT,"WM_IME_SELECT"
    StrTblItem WM_IME_CHAR,"WM_IME_CHAR"
    StrTblItem WM_IME_REQUEST,"WM_IME_REQUEST"
    StrTblItem WM_IME_KEYDOWN,"WM_IME_KEYDOWN"
    StrTblItem WM_IME_KEYUP,"WM_IME_KEYUP"
    StrTblItem WM_MOUSEHOVER,"WM_MOUSEHOVER"
    StrTblItem WM_MOUSELEAVE,"WM_MOUSELEAVE"
    StrTblItem WM_CUT,"WM_CUT"
    StrTblItem WM_COPY,"WM_COPY"
    StrTblItem WM_PASTE,"WM_PASTE"
    StrTblItem WM_CLEAR,"WM_CLEAR"
    StrTblItem WM_UNDO,"WM_UNDO"

    StrTblItem WM_QUERYNEWPALETTE,"WM_QUERYNEWPALETTE"
    StrTblItem WM_PALETTEISCHANGING,"WM_PALETTEISCHANGING"
    StrTblItem WM_PALETTECHANGED,"WM_PALETTECHANGED"
    StrTblItem WM_HOTKEY,"WM_HOTKEY"

    dw -1
.Undefined: db "Undefined",0

[section .text]
; (eax=word message number) (edx=msg ptr; eax)
GetWinMsgName:
    mov edx,WinMsgNames
    xor ecx,ecx
    jmp short .Start
.Next:
    mov cl,[edx+2]              ;get string length
    lea edx,[edx+ecx+4]         ;+length, +2 index, +1 length byte, +1 null
.Start:
    cmp [edx],ax
    je .Match
    jb .Next
; no match found
    mov edx,WinMsgNames.Undefined
    ret
.Match:
    add edx,byte 3              ;+2 index number, +1 length byte
    ret

__SECT__

 %else

  %macro debugwinmsg 2+
  %endmacro

 %endif ; UseWinMsgs
%else

 %macro debugwinmsg 2+
 %endmacro

%endif ; debug


%macro printf 1-*
    %rep %0
      %rotate -1
      pushdword %1
    %endrep
    call PrintF
    lea esp,[esp+%0*4]
%endmacro


%endif // mywininc_asm
