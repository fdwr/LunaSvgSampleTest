; FlanScan
; Peekin
; 2002-11-08
;
; Scans all file listings on the local network.
; -scan forward/backward
; -export listing to text file/html
; -does not list printers
; -scan passworded folders if password given by user
; -rescan individual branches
; -sort by workgroup / machine / total flat form
; -order by name/size
; -filter all files
; -different views, details/names, tree/list
; -commands run/copy/explore/delete

; 2002-11-13 Learned FD sets are actually count/array strutures, not list
;            terminated by a -1 like the help file said.

[section code code]
[section data data]
[section text data]
[section bss bss]
global Main


%define debug
%define UseConsoleDebug
%define UseNetwork
%define UseWinsock
%define UseWindowStyles
%define UseWindowControls
%define UseWindowMsgs
%define UseWindowGfx
%define UseFileSystem
%include "mywininc.asm"         ;standard Windows constants, structs...

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Window structures
section data
align 4, db 0
hwnd:   dd 0                    ;window handle
;hdc:   dd 0                    ;class device context
hfont:  dd 0                    ;default font to use for controls
focus:  dd 0                    ;control that has focus

wc:
.BaseAddress                    equ 400000h ;base address of program (Windows module handle)
istruc WNDCLASS
at WNDCLASS.style,              dd CS_CLASSDC
at WNDCLASS.lpfnWndProc,        dd MsgProc
at WNDCLASS.cbClsExtra,         dd 0
at WNDCLASS.cbWndExtra,         dd 0
at WNDCLASS.hInstance,          dd .BaseAddress ;(default image base is at 4MB)
at WNDCLASS.hIcon,              dd NULL
at WNDCLASS.hCursor,            dd NULL
at WNDCLASS.hbrBackground,      dd COLOR_BTNFACE + 1
at WNDCLASS.lpszMenuName,       dd 1;NULL
at WNDCLASS.lpszClassName,      dd ClassNames.Program
iend

section bss
msg:    resb MSG_size
;ps:    resb PAINTSTRUCT_size

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Huge array of file attributes and names
section bss
alignb 4
EnumLanTable:

; Buffer to hold info on enumerated resources
EnumLanBuffer_size equ 65536
EnumLanBuffer:  resb EnumLanBuffer_size

WSAInit:        resb WSADATA_size

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section data
EnumHandle:     dd 0
EnumCount:      dd -1           ;set to -1 to grab all
EnumSize:       dd EnumLanBuffer_size ; should be large enough to hold all
EnumMode:       dd 0
.None           equ 0           ;not scanning anything
.Scanning       equ 1           ;currently scanning network
.Paused         equ 2           ;scan is paused for the moment

SocketList:     dd 1            ;count one socket handle, MUST follow after
SocketHnd:      dd 0, -1        ;socket handle, and end of list (-1)

SocketTimeout:  dd 4,0          ;wait number of seconds
SocketAddress:  dw AF_INET      ;.sin_family
                db 0,139        ;.sin_port (in silly 'network' order)
SocketIpAdr:    dd 0            ;.sin_addr
                db "FLANSCA",0  ;.sin_zero (socket name)

EnumLanParent:  ;NETRESOURCE
%if 0   ;scan networks
.dwScope:       dd RESOURCE_GLOBALNET
.dwType:        dd RESOURCETYPE_DISK
.dwDisplayType: dd RESOURCEDISPLAYTYPE_GENERIC
.dwUsage:       dd RESOURCEUSAGE_CONTAINER
.lpLocalName:   dd NULL
.lpRemoteName:  dd NULL ;repoint this as necessary
.lpComment:     dd NULL
.lpProvider:    dd NULL

%elif 0 ;scan workgroups in network
.dwScope:       dd 2
.dwType:        dd 0
.dwDisplayType: dd 6
.dwUsage:       dd 2
.lpLocalName:   dd NULL
.lpRemoteName:  dd NULL
.lpComment:     dd TestProvider
.lpProvider:    dd TestProvider

%elif 0 ;scan machines in workgroup
.dwScope:       dd 2
.dwType:        dd 3
.dwDisplayType: dd 1
.dwUsage:       dd 2
.lpLocalName:   dd NULL
.lpRemoteName:  dd TestDomain
.lpComment:     dd NULL
.lpProvider:    dd TestProvider

%elif 1 ;scan shares in machine
.dwScope:       dd 2
.dwType:        dd RESOURCETYPE_DISK
.dwDisplayType: dd 1
.dwUsage:       dd 2
.lpLocalName:   dd NULL
.lpRemoteName:  dd TestMachine
.lpComment:     dd NULL
.lpProvider:    dd TestProvider

%elif 0 ;scan objects in share  ;returns error because not container
.dwScope:       dd 2
.dwType:        dd 1
.dwDisplayType: dd 3
.dwUsage:       dd 5
.lpLocalName:   dd NULL
.lpRemoteName:  dd TestShare
.lpComment:     dd NULL
.lpProvider:    dd TestProvider
%endif

;TestShare:      db "\\PEEKIN\AUDIO",0
;TestMachine:    db "\\bloodblight.gotdns.com",0
TestMachine:    db "\\PEEKIN",0
;TestMachine:    db "\\KALITURBO",0
;TestMachine:    db "\\ANGELFEESHY",0
;TestMachine:    db "\\ZERO",0
;TestMachine:    db "\\BLOODRUNS",0
;TestMachine:    db "\\J0UR-M0M",0
;TestMachine:    db "\\NOBODYREAL",0
TestDomain:     db "DIXON",0
TestProvider:   db "Microsoft Network",0
;TestProvider:   db "Brian's VPN",0

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section text

ProgramTitle:   db "FLanScan 1.0 (ßeta)" ;,0
NullString:     db 0
ClassNames:
.Program:       db "FlanScanner",0
;.Button:        db "BUTTON",0
;.Label:
;.Static:        db "STATIC",0
;.Edit:          db "EDIT",0
;.ListBox:       db "LISTBOX",0
;.Progress:      db "msctls_progress32",0
;.Tab:           db "SysTabControl32",0
ErrMsg:
;.Fatal:        db "MediaFileLister: Fatal Error",0
.NoWindow:      db "Failed to create window.",0
Caption:
Text:
.About:         db "Scans the network for files, accumulating them all into a large list. "
                db "That list can be browsed (list or tree form), searched (for a given file mask), filtered (files of specific types), ordered (name/size/date), and exported (text/html). "
                db "Local area networks can be HUGE, especially when dumb people share their whole hard drive. "
                db "So this program supports up to 100,000 file entries, which is more than twice sufficient for the OSU campus LAN."
                db 10,10
                db "I wrote this after using the program LanScan by Marek Dulko (v2.1.1). "
                db "It was good for making a large list, but lacked some features I wanted, along with a few wanted of my housemates. "
                db "The newest LanScan does more, but I'm too cheap to even pay $15, and this is a good excuse to learn something new."
                db 10,10
                db "For anyone interested: "
                db "The program checks for a computer using Winsock before attempting to access its shares because of the stupid nature of WNetOpenEnum. "
                db "This prevents the annoying 1-2 minute stall upon accessing computers that are residually shown in a workgroup but have actually been turned off."
                db 10,10
                db "Dwayne Robinson",10
                db "FDwR@hotmail.com",10
                db "http://fdwr.tripod.com/",10
                db "PeekinSoft 2002-05-11"
                db 0

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section code

Main:

    debugwrite "starting FlanScan"

%if 0
    api LoadCursor, 0,IDC_ARROW
    mov [wc+WNDCLASS.hCursor],eax
    api LoadIcon, wc.BaseAddress,1
    mov [wc+WNDCLASS.hIcon],eax

    ; register window class
    debugwrite "registering class"
    api RegisterClass, wc
    debugwrite "register result=%X", eax
    test eax,eax
    mov esi,ErrMsg.NoWindow
    jz near EndWithErrMsg

    ;api InitCommonControls

    ; create instance of window
    debugwrite "creating window"
    api CreateWindowEx, WS_EX_ACCEPTFILES|WS_EX_CONTROLPARENT, ClassNames.Program, ProgramTitle, WS_MINIMIZEBOX|WS_MAXIMIZEBOX|WS_VISIBLE|WS_SYSMENU|WS_DLGFRAME|WS_SIZEBOX, 0,0, 400,572, NULL, NULL, wc.BaseAddress, NULL
    debugwrite "window handle=%X", eax
    test eax,eax
    jz near EndWithErrMsg
    ;mov [hwnd],eax


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Main Loop
.Top:
    ;debugpause "entering main loop"

.Next:
    xor eax,eax
    api GetMessage, msg, eax,eax,eax
    test eax,eax
    jz near .End
    mov eax,[msg+MSG.message]
    debugwinmsg "process msg=%X %s W=%X L=%X", eax,edx,[msg+MSG.wParam],[msg+MSG.lParam]
    api IsDialogMessage, [hwnd],msg
    ;api DispatchMessage, msg
    cmp [EnumMode],dword EnumMode.Scanning
    jne .Next

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.ScanLoop:
    jmp .End

%endif


%if 1
    api WSAStartup, 101h, WSAInit
    debugwrite "winsock description %s", WSAInit+WSADATA.szDescription
    debugwrite "winsock status %s", WSAInit+WSADATA.szSystemStatus
    debugwrite "winsock max sockets %d", WSAInit+WSADATA.iMaxSockets
    debugwrite "winsock vendor %s", [WSAInit+WSADATA.lpVendorInfo]

    debugwrite "ws open"
    api WSOpen, AF_INET, SOCK_STREAM, 0
    call ShowWsError
    cmp eax,INVALID_SOCKET
    je near .InvalidSocket
    mov [SocketHnd],eax

    debugwrite "ws gethostbyname"
    api WSGetHostByName, TestMachine+2  ;skip silly "\\"
    ;pointer to HOSTENT if success, null if error
    call ShowWsError
    test eax,eax
    jz near .CloseSocket
    debugwrite " official host name %s",[eax+HOSTENT.h_name]
    debugwrite " host aliases %s",[eax+HOSTENT.h_alias]

    ; get ip from list
    mov ecx,[eax+HOSTENT.h_list]    ;get first IP in list
    mov ecx,[ecx]
    mov ecx,[ecx]
    debugwrite " ip addresses %X",ecx
    mov [SocketIpAdr],ecx

    ; print dotted ip
    debugwrite "ws to dotted"
    api WSToDotted, ecx
    debugwrite " dotted address %s",eax

    ; set non blocking
    api WSIoControl, [SocketHnd], FIONBIO,esp, TRUE
    pop eax ;discard true

    ; attempt connection
    debugwrite "ws connect"
    api WSConnect, [SocketHnd], SocketAddress, SOCKADDR_INET_size
    push eax
    api WSAGetLastError
    mov ebx,eax
    pop eax
    call ShowWsError
    test eax,eax                ;0 means success
    jz .CloseSocket
    cmp ebx,WSAEWOULDBLOCK
    jne .CloseSocket

    ; five second timeout
    debugwrite "ws wait"
    api WSWait, NULL, NULL, SocketList,SocketList, SocketTimeout
    call ShowWsError

.CloseSocket:
    debugwrite "ws close"
    api WSClose, [SocketHnd]
    call ShowWsError
.InvalidSocket:

    ; always call clean up anyway, even init was unsuccessful
    ; since it will simply return error of WASNOTINITIALIZED
    api WSACleanup

    ;jmp .End
%endif

%if 1
    ;api WNetOpenEnum, RESOURCE_GLOBALNET,RESOURCETYPE_DISK,0, NULL,EnumHandle
    api WNetOpenEnum, RESOURCE_GLOBALNET,RESOURCETYPE_DISK,0, EnumLanParent,EnumHandle
    debugwrite "WNetOpenEnum  error=%d",eax
    debugwrite "WNetOpenEnum handle=%X",[EnumHandle]
    cmp eax,NO_ERROR
    jne near .Error

    ;cld
    xor eax,eax
    mov edi,EnumLanBuffer
    mov ecx,EnumLanBuffer_size/4
    rep stosd

    mov dword [EnumCount],-1
    mov dword [EnumSize],EnumLanBuffer_size
    ;mov dword [EnumLanBuffer+NETRESOURCE.lpRemoteName],DummyRemoteName
    api WNetEnumResource, [EnumHandle],EnumCount, EnumLanBuffer,EnumSize
    debugwrite "WNetEnumResource error=%d",eax
    debugwrite "resource size=%d",[EnumSize]
    debugwrite "resource count=%d",[EnumCount]
    ;cmp eax,NO_ERROR

    mov ebx,[EnumCount]
    mov esi,EnumLanBuffer

.NextEnum:
%if 1
    debugwrite ""
    debugwrite "lpLocalName %s", [esi+NETRESOURCE.lpLocalName]
    debugwrite "lpRemoteName %s", [esi+NETRESOURCE.lpRemoteName]
    debugwrite "lpComment %s", [esi+NETRESOURCE.lpComment]
    debugwrite "lpProvider %s", [esi+NETRESOURCE.lpProvider]
    debugwrite "dwScope %d", [esi+NETRESOURCE.dwScope]
    debugwrite "dwType %d", [esi+NETRESOURCE.dwType]
    debugwrite "dwDisplayType %d", [esi+NETRESOURCE.dwDisplayType]
    debugwrite "dwUsage %d", [esi+NETRESOURCE.dwUsage]
%endif

    add esi,NETRESOURCE_size
    dec ebx
    jnz near .NextEnum

    api WNetCloseEnum,[EnumHandle]

    ;api MessageBox, NULL, "Click OK to close program",NULL, 0

%endif

.End:


    api ExitProcess, 0

.Error:
    mov edx,NetworkErrMsgs
    mov ecx,NetworkErrMsgs.NoDef
    call GetStrTblMsg
    debugwrite "network error %d: %s",eax,edx
    jmp short .End


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
MsgProc:
    params .hwnd, .message, .wParam, .lParam

    mov eax,[esp+.message]
    debugwinmsg "win msg=%X %s W=%X L=%X", eax,edx,[esp+.wParam+4],[esp+.lParam]

%if 0
    cmp eax,WM_KEYDOWN
    jne .NotKey
    cmp byte [msg+MSG.wParam],VK_ESCAPE
    je near .EscPress
.NotKey:
    cmp eax,WM_TIMER
    je near .FlashTitle
    cmp eax,WM_DROPFILES
    je .FileDropped
%endif
    cmp eax,WM_COMMAND
    jne .NotCommand
    cmp word [esp+.wParam+2],BN_CLICKED
    je near .Command
.NotCommand:
    cmp eax,WM_ACTIVATE
    je near .Activate
    cmp eax,WM_CREATE
    je near .Create
    cmp eax,WM_SYSCOMMAND
    je near .SysCommand
    cmp eax,WM_WINDOWPOSCHANGED
    je near .Resize
    cmp eax,WM_WINDOWPOSCHANGING
    je .RetFalse
    cmp eax,WM_DESTROY
    je .Destroy

.DefProc:
	extern DefWindowProc
    jmp [DefWindowProc]

.RetTrue:
    mov eax,TRUE
    ret 16

.Destroy:
    ;debugpause "destroying window"
    mov dword [hwnd],0
    api PostQuitMessage,0
.RetFalse:
.Resize:
    xor eax,eax
    ret 16

.Create:
    mov eax,[esp+.hwnd]
    mov [hwnd],eax
    mov [focus],eax
    ;api GetDC, eax              ;get window class display handle
    ;debugwrite "get hdc=%X",eax
    ;mov [hdc],eax
    api GetStockObject, DEFAULT_GUI_FONT
    mov [hfont],eax

    xor eax,eax
    ret 16

.Command:
    mov eax,[esp+.wParam]
    push dword .RetFalse
    cmp eax,IDCANCEL
    je .cmdCancel
    cmp eax,IDHELP
    je .cmdAbout
    ;cmp eax
    jmp short .cmdUnfinished
    xor eax,eax
    ret 16

.cmdCancel:
    cmp [EnumMode],dword EnumMode.Scanning
    ;je near StopScan
    api PostQuitMessage,1
    ret
.cmdAbout:
    api MessageBox, [hwnd],Text.About,ProgramTitle,MB_OK|MB_ICONINFORMATION ;|MB_SETFOREGROUND
    ret
.cmdUnfinished:
    api MessageBox, [hwnd],"Option unfinished",ProgramTitle,MB_OK|MB_ICONINFORMATION ;|MB_SETFOREGROUND
    ret

.Activate:
    cmp word [esp+.wParam],WA_INACTIVE
    je .LoseFocus
    debugwrite "new focus hwnd=%X",[focus]
    api SetFocus, [focus]
    xor eax,eax
    ret 16

.LoseFocus:
    api GetFocus
    test eax,eax
    jz .NullFocus
    mov [focus],eax
    debugwrite "old focus hwnd=%X",eax
    xor eax,eax
.NullFocus:
    ret 16

.SysCommand:
    ; check for minimize
    cmp dword [esp+.wParam],SC_MINIMIZE
    jne .NotMinimize
    api GetFocus
    mov [focus],eax
    debugwrite "old focus hwnd=%X",eax
.NotMinimize:
	extern DefWindowProc
    jmp [DefWindowProc]



;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; (eax=word message number, edx=message table base, ecx=alternate)
; (edx=msg ptr, ecx=byte length; eax)
GetStrTblMsg:
    push ecx
    xor ecx,ecx
    jmp short .Start
.Next:
    mov cl,[edx+2]              ;get string length
    lea edx,[edx+ecx+4]         ;+length, +2 index, +1 length byte, +1 null
.Start:
    cmp [edx],ax
    je .Match
    jb .Next
.NoMatch:
    xor ecx,ecx
    pop edx
    ret
.Match:
    add esp,byte 4              ;release saved var keeping ecx
    add edx,byte 3              ;+2 index number, +1 length byte
    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; (esi=error message ptr)
EndWithErrMsg:
    debugwrite "exiting process from fatal error: %s", esi
    api MessageBox, [hwnd],esi,ProgramTitle,MB_OK|MB_TOPMOST|MB_ICONERROR|MB_TASKMODAL ;|MB_SETFOREGROUND
    api DestroyWindow, [hwnd]
    api ExitProcess, -1


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; (eax=return value)
ShowWsError:
    push ebx
    push eax
    api WSAGetLastError
    mov ebx,eax
    pop eax
    debugwrite " return value=%d",eax
    debugwrite " error code=%d",ebx
    pop ebx
    ret



section text
NetworkErrMsgs:
    StrTblNew 0
    StrTblItem 0,"No error"
    StrTblItem 67,"Bad network name"
    StrTblItem 87,"Invalid parameter"
    StrTblItem 487,"Invalid address"
    StrTblItem 1204,"Bad provider"
    StrTblItem 1207,"Not container"
    StrTblItem 1244,"Require password / User not authenticated to perform this action"
    dw -1
.NoDef: db "Unknown network error",0
    ret
section code

%if 0



main loop idle
    get message
    dispatch
    loop




main loop scanning
    peek message
    if message
        get message
        dispatch
    else
        if scanning main network or workgroup
            WNetEnumResource
            if file/folder enumerated
                add attributes and name to table
            else if no more files
                if folder
                    recurse into next folder
                    WNetOpenEnum
                elif no folders
                    WNetCloseEnum                    
                    retreat up level
                endif
            else if error
                WNetCloseEnum                
                retreat up level
            endif
        elif scanning file
            FindFirstFile
            FindNextFile
            FindClose
        endif
    endif




file entry
    flags dir/archive/hidden/system/readonly/done/important/timeout/selected
    type domain/server/share/file
    next
    parent
    size
    date
    name




%endif
