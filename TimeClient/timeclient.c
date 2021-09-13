////////////////////////////////////////////////////////////////////////////////
//	timeclient.c
//
//	CS372 - Program 2
//	Dwayne Robinson
//	2004-05-17
//
//	Uses port 37 to request the current Internet time from a server.
//	Unfortunately very few servers actually support the service anymore.
//
//	Usage:
//		timeclient cs.purdue.edu
//		timeclient cs.purdue.edu tcp gmt   // Use TCP only, Grenwich mean time
//		timeclient cs.purdue.edu udp est   // Use UDP only, Eastern US time
//		timeclient cs.purdue.edu +9        // Japanese time
//
//		Type timeclient with no parameters for more usage.
//
//	Note:
//		Please maximize window to reduce flicker.
//
//	Compiling:
//		Flip - gcc timeclient.c string.c -o timeclient -lm
//		Flop - gcc timeclient.c string.c -o timeclient -lm -lxnet
//		Windows - use the supplied MSVC project
//
//	History:
//	20040517	Create program
//				Add UDP and TCP protocol.
//				Add two dozen recognized time zone names to command line.
//				Finish program up to specs,
//				 Will implement that "something astounding" tomorrow
//	20040518	Ported to Windows (minimal changes)
//				Start "something astounding" - a globe that shows the time zones.
//				Find good time zone image to convert to ASCII.
//				Create basic cylindrical rotation effect with simple texture.
//				Manage to crop it to a rough 'circle' - more like a lemon :-/
//	20040519	Get rid of the lemon shaped globe by using good old hypotenuse
//				 formula instead of problematic arcsin.
//				Convert the time zone map to ASCII 128x32.
//				 After producing unpleasing results with a few ASCII art
//				 programs, resort to manual typing of the array.
//				Add numeric time zones (+8 -4 ...) to command line
//				Change Win version to only end on significant keypresses,
//				 not shift, control, or focus events.
//				Comment and document. Finished.

#include <stdio.h>
#include <time.h>
#include <math.h>
#include <stdlib.h>

#include "timeclient.h"

////////////////////////////////////////////////////////////////////////////////

void EndWithErrMsg(char* msg , int error);
time_t ReadInetTime(SOCKET Socket);
int ConnectTimeSocket(SOCKET Socket, struct sockaddr_in* SockAddr);
void PrintAdjustedTime(char* msg, time_t InetTime, int TimeZone);
void ShowTimeAndWait(time_t InetTime, time_t LocalTime, int TimeZone);
void SyncLocalTimeToInet(int SyncTime, time_t InetTime, time_t* LocalTime);

typedef struct {
	int height; // globe display height in characters (and map size)
	int width; // globe display width in characters
	int wrap; // size of map in characters
	char* pixels; // texture map actually made of ASCII characters
	float* xs; // a precomputed warpmap array for speed
} GlobeInfo;

int GlobeInit(GlobeInfo* globe, int height, int width, char* pixels, int wrap);
void GlobePrint(GlobeInfo* globe, double angle);
void GlobeFree(GlobeInfo* globe);

#ifdef _WINDOWS
	// Aspect ratior set for Command Prompt Terminal 8x12
	#define DefGlobeWidth 48
#endif
#ifdef _LINUX
	// Aspect ratio set for Terminal size 9, especially for
	// SSH remote connection to Linux server
	#define DefGlobeWidth 64
#endif

////////////////////////////////////////////////////////////////////////////////

static const char ArgList[] = {
	"tcp\0" "udp\0" "sync\0" "\0"
	};
enum ArgListEnums {
	ArgTcp, ArgUdp, ArgSync
};
static const char TzNames[] = {
	"gmt\0"	"ut\0"	"utc\0"	"wet\0"
	"cet\0" "eet\0"	"bt\0"	"cct\0"
	"jst\0" "gst\0" "idle\0" "nzst\0"
	"wat\0"	"at\0"	"ast\0"	"est\0"
	"cst\0"	"mst\0"	"pst\0"	"yst\0"
	"ahst\0" "cat\0" "hst\0" "nt\0"
	"idlw\0" "\0"
};
// http://wwp.greenwichmeantime.com/info/timezone.htm
// http://www.worldtimezone.com/
static const int TzValues[] = {
	0,		0,		0,		0,
	1,		2,		3,		8,
	9,		10,		12,		12,
	-1,		-2,		-4,		-5,
	-6,		-7,		-8,		-9,
	-10,	-10,	-10,	-11,
	-12
};
static const char TzLetters[24] = { "Z" "ABCDEFGHIKLM" "XWVUTSRQPON" };

GlobeInfo TzGlobe;
char TzGlobePixels[] = // 1024x480 -> 128x32
	"...............................RRRRR........PPPPPPPP............................................................................"
	"..........................SSS..RRRR.PPPPPPPPPPPPPPPPPP.............AA........C...C...........GG................................."
	"....................T.....S..SRR...Q.PPPPPPPPPPPPPPPP............AA.A..........................................................."
	"................T.......................PPPPPPPPPPPPP...........................CC.........GGGGGGGGG.............K.............."
	"....V...........T..TTTT...S..SRRRRR......PPPPPPPPPPPP..........................C....EEEEGGGGGGGGGGGGIIIIII.KK.KLLL..........M..."
	"..VVVVVVVVUUTTTTTTT...TT.SSSSSR..RRRQ....PPPPPPPP................AAAABBCCC..C.CCCCCEEEEEEGGGGGGGGGIIIIIIIKKKKKLLLLLLLMMMMMMMM..."
	"...VVVVVVVUUUUTTTTTTTTTTSSSSS.R...RRQ.....PPPP......ZZZ.........AAAA.BBCCCCCCCCCCEEEEEEEEEEGGGGGGGIIIIIIIIIKKKLLLLLLLLMMMMMM..M."
	"V.VVVVV...VUUUUUTTTTTTTTSSS......RR............................AAAA.B.CCCCCCCCCEEEEEEEEEGGGGGGGGGHHIIIIIIIIKKKKKLLL...MM........"
	".............VUUTTTTTTSSSSSSR....RRRRRQ...................ZZ...AA...BBCCCCCCCCDEEEEEEFFFFFGGGGGHHHHHHIIIIIIKK.......MM.........."
	"...............UUUTTTSSSSSSSRRRRRRRRRRQQ..................ZZ..AAAAAAABBBCCCCCCEEEEEFFFFFGGGGGGGHHHHHIIIHHIIKKK................W."
	"................UUUTTTTTSSSSRRRRRRRRQ.Q.....................AAAAAAAABBBBBCCCCC.EEEEFFFFFFFHHHHHHHHHHHHHHHHHHKK.................."
	"................UUUTTTTTSSSSSSRRRRR......................ZAAA..AAA.ABB..B..DDC.EEEEEFFFFFHHHHHHHHHHHHHHHHHI....................."
	".................UUTTTTTSSSSSSRRR.........................A..AAA.A....BBBBBCDDCDCDEEEHEHHHHHHHHHHHHHHHHH.I...I.................."
	"....................TTSSSSSSSSR..........................ZZAAAAAAA.AAB..BCCCCDCDC.DEEEEFFHHHHHHHHHHHHHHH........................"
	"....................T.SSS..............................ZZZAAAAAAAAAAABBB.CCCCC...DEEEEEFFFFFFHHHHHHHHHH........................."
	".......................SSS..S.....RQ..................ZZZZZZZAAAAAAAABBBB..CCCCDD.....FFFFF..HHGGG.............................."
	"............................SSS.......................ZZZZZZAAAAAAAABBBBBCCCC.........FFF......GGGG............................."
	"...............................RRRRQQQQ.................ZZZZZAAAAAAAABBBCCCCCC.................G........H......................."
	"................................RRRRQQQQQP.....................AAAAABBBCCCCC...................G...HHH..HH......................"
	"...............................RRRRQQQQQQPPPPPP.................AAABBBBCCC.......................G.....H....IIKK................"
	"................................RRRRQQQQQQPPPPP..................AAABBBBCCC......................................K...L.L.......W"
	".........WW.......................RRQQQQQPPPPP..................BAAABBBBBB..CC..........................HIIII.KK...........M...."
	"...................................QPPQQQPPPP....................BBBBBBBB..CC........................HHHHIIIIIKKKK.....L........"
	"...................................PPPPPPPP.......................BBBBBB.............................HHHHIIIIIKKKKK............."
	"..................................QPPPP.P..........................BB................................HH.....IIKKKK.............."
	"..................................QPPP....................................................................................M....."
	"..................................QPP...................................................................................M......."
	".................................QPP............................................................................................"
	"..................................QQP..........................................................................................."
	"....................................................................................EEEEEEFFFFF................................."
	"XXXXWWWWWVVVVVVUUUUUTTTTTTSS..................POOOOONNNNNNZZZZZAAAAABBBBBBCCCCCDDDDDEEEEEEFFFFFGGGGGHHHHHIIIIIIKKKKKLLLLLMMMMMXX"
	"XXXXWWWWWVVVVVVUUUUUTTTTTTSSSSSRRRRRQQQQQQPPPPPOOOOONNNNNNZZZZZAAAAABBBBBBCCCCCDDDDDEEEEEEFFFFFGGGGGHHHHHIIIIIIKKKKKLLLLLMMMMMXX";


////////////////////////////////////////////////////////////////////////////////
// Console prompt loop.
//
// Accepts:	{servername} [timezone]
// Returns:	 0 - no error, time received
//			-1 - parameter error
//			-2 - invalid server name/ip
//			-3 - time out, server did not respond
//			-4 - serious error (like WinSock init failed)
int main (int argc, char* argv[])
{
	unsigned int Ip;
	SOCKET Socket;
	time_t InetTime, LocalTime;
	int TimeZone=0, SyncTime=0;
	struct sockaddr_in SockAddr;
	int TcpOrUdp=3; // 1-udp only, 2-tcp only, 3-try both
	int arg, cmd;

   #ifdef _LINUX
	fd_set FdsReadable;
	struct timeval TimeOut;
   #endif

   #ifdef _WINDOWS
	WSADATA WsaInit;
   #endif


	////////////////////////////////////////
	// print program info if no parameters
	if (argc <= 1) {
		EndWithErrMsg("Time Client - displays Internet time from a server (port 37)\n"
			"(c)2004 PikenSoft, Dwayne Robinson\n"
			"  timeclient {servername|ip|localhost} [udp|tcp] [sync] [gmt|est|mst|pst|...]\n"
			"  timeclient cs.purdue.edu sync\n"
			"  timeclient 128.10.2.1 udp pst\n"
			"\n"
			" -Time zones can be entered as numeric offsets (-8, +3) or name abbreviations.\n"
			" -The local time can only be synchronized if you have sufficient privileges.\n"
			" -If a server does not support UPD, it will try TCP, but you can force one.\n"
			" -If you want merely to check the local time, type 'localhost' for server.\n"
			" -Few servers actually support port 37 anymore, so you may have to search."
			, -1);
	}

	////////////////////////////////////////
	// check parameters and parse
	if (strcmp(argv[1], "localhost") == 0) TcpOrUdp=0;

	tzset(); // set initial time zone to local time zone
	TimeZone = -(timezone/3600);

	for (arg=2; argv[arg] != NULL; arg++) {
		cmd = strmatch(argv[arg], ArgList);
		switch (cmd) {
		case ArgTcp: TcpOrUdp=2; break;
		case ArgUdp: TcpOrUdp=1; break;
		case ArgSync: SyncTime=1; break;
		default: // check if is time zone
			// is numeric?
			cmd = strmatch(argv[arg], TzNames);
			if (cmd != -1) {
				TimeZone = TzValues[cmd];
			}
			else {
				TimeZone = atoi(argv[arg]);
				if ((TimeZone == 0) && (*argv[arg] != '0')) {
					printf("Don't understand '%s'. It's neither a known argument or time zone\n", argv[arg]);
					exit(-1);
				}
			}
		}
	}

  #ifdef _WINDOWS
	if (WSAStartup(0x101, &WsaInit)) { // bool logic reversed!
		EndWithErrMsg("Winsock initialization failed!",-4);
	}
  #endif


	////////////////////////////////////////
	// resolve host name to IP (only supports by IPv4 for now)
	if (TcpOrUdp) { // *note: no name resolution if on localhost
		printf("Checking server IP..."); fflush(NULL);
		Ip = inet_addr(argv[1]);
		if (Ip == INADDR_NONE) {
			//HOSTENT *Host = gethostbyname(PinBfr.msg);
			struct hostent *Host = gethostbyname(argv[1]);
			if (Host == NULL) {
				EndWithErrMsg("Invalid server name or IP", -2);
			}
			//Ip = ((struct in_addr *)Host->h_addr_list[0])->S_un.S_addr; // windows
			Ip = ((struct in_addr *)Host->h_addr_list[0])->s_addr;
			//dbgmsg( inet_ntoa(*((struct in_addr *)Host->h_addr_list[0]))  );
		}
		SockAddr.sin_family = AF_INET;
		SockAddr.sin_addr.s_addr = Ip; // only IPv4 for now
		SockAddr.sin_port = htons(37); // in silly 'network' order
		SockAddr.sin_zero[0] = 0;
		//printf("valid: %s\n", inet_ntoa(&Ip));
		printf("valid: %s\n", inet_ntoa(SockAddr.sin_addr));
	}	


	////////////////////////////////////////
	// There are three paths below:
	// (a.) use time on local machine only
	// (b.) retrieve time using UDP
	// (c.) retrieve time using TCP
	//
	// Of those, the following combinations are possible:
	// (1) local time only
	// (2) udp only, do nothing more if failed
	// (3) tcp only, do nothing more if failed
	// (4) udp, but then try tcp if udp failed

	////////////////////////////////////////
	// (a.) only use local time (no remote server)
	if (!TcpOrUdp) {
		time(&LocalTime);
		InetTime = LocalTime;
	}

	////////////////////////////////////////
	// (b.) create socket using UDP
	if (TcpOrUdp & 1) {
		printf("Contacting server using UDP..."); fflush(NULL);

		Socket = socket(PF_INET, SOCK_DGRAM, 0);
		if (Socket <= 0) {
			EndWithErrMsg("could not create UDP socket!", -4);
		}
		// send empty UDP packet and wait three seconds
		//printf("  Sending empty UDP packet and waiting for response\n");
		sendto(Socket, "",1, 0, (struct sockaddr*)&SockAddr, sizeof(struct sockaddr));

		InetTime = ReadInetTime(Socket);
		if (InetTime) {
			printf("UDP packet received.\n");
			SyncLocalTimeToInet(SyncTime, InetTime, &LocalTime);
			TcpOrUdp = 0;
		}
		else {
			printf("timed out.\n");
		}
		closesocket(Socket);
	}

	////////////////////////////////////////
	// (c.) create socket using TCP
	if (TcpOrUdp & 2) {
		printf("Contacting server using TCP..."); fflush(NULL);

		Socket = socket(PF_INET, SOCK_STREAM, 0);
		if (Socket <= 0) {
			EndWithErrMsg("could not create TCP socket!", -4);
		}
		if (ConnectTimeSocket(Socket, &SockAddr)) {
			printf("connected...");

			InetTime = ReadInetTime(Socket);
			if (InetTime) {
				printf("32bits received.\n");
				SyncLocalTimeToInet(SyncTime, InetTime, &LocalTime);
				TcpOrUdp = 0;
			}
			else {
				printf("timed out or disconnected.\n");
			}
			closesocket(Socket);
		}
		else {
			printf("could not connect.\n", -3);
		}
	}

  #ifdef _WINDOWS
	WSACleanup();		
  #endif

	////////////////////////////////////////
	// everything fine so just show time now
	if (!TcpOrUdp) {
		ShowTimeAndWait(InetTime, LocalTime, TimeZone);
		return 0; // everything good
	}

	printf("* Server never responded. It may not support the time service.\n");
	return -3; // time out
}

// * Prints the remote server and local time.
// * Displays slowly rotating globe and waits for user
// * Ends program
//
// accepts:	InetTime - seconds since 1900
//			InetTime - seconds since 1900
// returns:	DOES NOT RETURN
void ShowTimeAndWait(time_t InetTime, time_t LocalTime, int TimeZone)
{
	time_t TimeDif = LocalTime-InetTime;
	double GlobeAngle;
	int spin;
	// Set initial angle to highlight the time zone which the
	// local machine is running in.
	// +11 since map is stored relative to the international
	// date line rather than centered over Grenwhich, England.
  #ifdef _LINUX
	fd_set FdsReadable;
	struct timeval TimeOut;
  #endif
  #ifdef _WINDOWS
	CONSOLE_SCREEN_BUFFER_INFO csbi;
	HANDLE conin = GetStdHandle(STD_INPUT_HANDLE);
	HANDLE conout = GetStdHandle(STD_OUTPUT_HANDLE);
	INPUT_RECORD ir;
	int result;
  #endif

	////////////////////////////////////////
	// print server and local times
	printf("time zone used: %d (%c)\n", TimeZone, TzLetters[(TimeZone+24) % 24]);
	PrintAdjustedTime("server time:  ", InetTime, TimeZone);
	PrintAdjustedTime("local time:   ", LocalTime, TimeZone);
	if (InetTime == LocalTime)
		printf("times are synchronized\n");
	else
		printf("time dif:     %d seconds (%s)\n", TimeDif, (LocalTime > InetTime) ? "ahead" : "behind");

	////////////////////////////////////////
	// Initialize globe
  #ifdef _WINDOWS
	// Aspect ratior set for Command Prompt Terminal 8x12
	GlobeInit(&TzGlobe, 32, 48, TzGlobePixels, 128);
  #endif
  #ifdef _LINUX
	// Aspect ratio set for Terminal size 9, especially for
	// SSH remote connection to Linux server
	GlobeInit(&TzGlobe, 32, 64, TzGlobePixels, 128);
  #endif

	// scroll down several lines
	printf("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n");
  #ifdef _WINDOWS
	GetConsoleScreenBufferInfo(conout, &csbi);
	csbi.dwCursorPosition.Y -= 34;
	SetConsoleMode(conin, ENABLE_PROCESSED_INPUT); // no mouse or window events
  #endif

	////////////////////////////////////////
	// show globe slowly rotating and wait for user to stop
	for (GlobeAngle = (TimeZone+11)*128/24, spin=true; spin; GlobeAngle++) {
	  #ifdef _WINDOWS
		SetConsoleCursorPosition(conout, csbi.dwCursorPosition);
		GlobePrint(&TzGlobe, GlobeAngle);
		PrintAdjustedTime("\nserver time:  ", time(NULL)-TimeDif, TimeZone);

		Sleep(100);
		// check for keypresses, ignoring mouse, window, focus...
		while (GetNumberOfConsoleInputEvents(conin, &result) && result > 0) {
			ReadConsoleInput(conin, &ir, 1, &result);
			if (ir.EventType == KEY_EVENT
			&& (ir.Event.KeyEvent.uChar.AsciiChar > 0)) {
				FlushConsoleInputBuffer(conin);
				spin = false;
				break;
			}
		}
	  #endif

	  #ifdef _LINUX
		// jump back up several lines to write over previous text
		printf("çççççççççççççççççççççççççççççççççç\r"); fflush(NULL);
		GlobePrint(&TzGlobe, GlobeAngle);
		PrintAdjustedTime("\nserver time:  ", time(NULL)-TimeDif, TimeZone);

		// check for keypress
		TimeOut.tv_sec = 0;
		TimeOut.tv_usec = 300000;
		FD_ZERO(&FdsReadable);
		FD_SET(0, &FdsReadable);
		if (select(1, &FdsReadable, NULL,NULL, &TimeOut) == 1) break;
	  #endif
	}
	GlobeFree(&TzGlobe);
}

////////////////////////////////////////////////////////////////////////////////
// Connects a socket to the given address (for TCP), timing out after 3 seconds.
//
// accepts:	Socket - which to connect
//			SockAddr - address info and port
// returns:	true if connected
//			false if failed for any reason, forcefully rejected or timeout
int ConnectTimeSocket(SOCKET Socket, struct sockaddr_in* SockAddr)
{
	struct timeval TimeOut;
	static fd_set FdsWriteable, FdsException;

	// put connect into nonblocking
	#ifdef _WINDOWS
	//WSAEventSelect(Socket, ServerEvent, FD_CONNECT|FD_READ|FD_CLOSE|FD_WRITE);
	//ioctlsocket(Socket, FIONBIO, &Socket); // nonblocked I/O, just pass the socket as a value since it is alway nonzero ^_^
    #else //_LINUX
	fcntl(Socket, F_SETFL, fcntl(Socket, F_GETFL)|O_NONBLOCK);
	//ioctl(Socket, FIONBIO, &Socket);
    #endif

	// attempt connect
	if ( connect(Socket, (struct sockaddr*)SockAddr, sizeof(struct sockaddr)) == 0) {
		dbgmsg("ConnectTimeSocket: connected successfully immediately");
		return true;
	}

   #ifdef _LINUX
	if (errno != EWOULDBLOCK && errno != EINPROGRESS && errno == 0) {
	// Linux can return either EWOULDBLOCK or EINPROGRESS
	// added errno = 0 for Sparc Unix
   #endif
   #ifdef _WINDOWS
	if (GetLastError() != WSAEWOULDBLOCK) {
   #endif
		dbgerr("ConnectTimeSocket connect error");
		return false;
	}

	dbgmsg("waiting for connection");
	TimeOut.tv_sec = 3;
	TimeOut.tv_usec = 0;
	FD_ZERO(&FdsWriteable);
	FD_SET(Socket, &FdsWriteable);
	FD_ZERO(&FdsException);
	FD_SET(Socket, &FdsException);
	if (select(Socket+1, NULL, &FdsWriteable, &FdsException, &TimeOut) < 1) {
		dbgerr("ConnectTimeSocket select error/timeout");
		return false;
	}
	if (FD_ISSET(Socket, &FdsException)) {
		dbgerr("ConnectTimeSocket connect refused");
		return false;
	}
	dbgmsg("ConnectTimeSocket: connected successfully after wait");
	return true;
}

////////////////////////////////////////////////////////////////////////////////
// Reads the single dword internet time from server (little endian)
// or times out after 3 seconds.
//
// Converts the int from seconds since 1900 to seconds since 1970
// so that functions like asctime are easier to use.
//
// accepts:	socket - which to read
// returns:	0 if time invalid or time out
//			>0 if time valid
time_t ReadInetTime(SOCKET Socket)
{
	unsigned int InetTime;
	int BytesRead;
	struct timeval TimeOut;
	fd_set FdsReadable;

	TimeOut.tv_sec = 3;
	TimeOut.tv_usec = 0;
	FD_ZERO(&FdsReadable);
	FD_SET(Socket, &FdsReadable);

	if (select(Socket+1, &FdsReadable, NULL, NULL, &TimeOut) == 1) {
		BytesRead = recv(Socket, (char*)&InetTime,4, 0);
		if (BytesRead < 4) return 0;
		return (time_t) (ntohl(InetTime)-2208988800u);
	}
	return 0;
}

////////////////////////////////////////////////////////////////////////////////
// Synchronizes the system's local time to the given Internet time.
//
// accepts:	SyncTime - true/false to actually do the time sync
//				otherwise just sets the local time var and returns.
//			InetTime - the time to synchronize with
// returns:	[LocalTime] - local system time is put here
void SyncLocalTimeToInet(int SyncTime, time_t InetTime, time_t* LocalTime) {
	time(LocalTime);
	if (SyncTime) {
		struct tm* BrokenTime = gmtime(&InetTime);

	  #ifdef _LINUX
		if (stime(&InetTime) == 0)
			printf("Synchronized local time to internet server.\n");
		else
			printf("Error setting local time. Maybe not administrator.\n");
	  #endif

	  #ifdef _WINDOWS
		SYSTEMTIME SysTime;
		SysTime.wYear = BrokenTime->tm_year;
		SysTime.wMonth = BrokenTime->tm_mon;
		SysTime.wDay = BrokenTime->tm_mday;
		SysTime.wHour = BrokenTime->tm_hour;
		SysTime.wMinute = BrokenTime->tm_min;
		SysTime.wSecond = BrokenTime->tm_sec;
		SysTime.wMilliseconds = 0;
		//SysTime.wDayOfWeek = 0; ignored

		if (SetSystemTime(&SysTime))
			printf("Synchronized local time to internet server.\n");
		else
			printf("Error setting local time. Maybe not administrator.\n");
	  #endif
	}
}

////////////////////////////////////////////////////////////////////////////////
// Prints the given time formatted, to a certain time zone.
//
// accepts:	msg - ptr to text
//			time - seconds since 1970
//			TimeZone - number -12 to 12 (0 is UCT)
void PrintAdjustedTime(char* msg, time_t time, int TimeZone)
{
	char* chartime;
	time += (TimeZone*3600);
	chartime = asctime(gmtime(&time));
	if (chartime == NULL) chartime = "<invalid time>";
	printf("%s%s", msg, chartime);
	// compensate for daylight savings time and junk?
}

////////////////////////////////////////////////////////////////////////////////
// Initializes the globe structure. Precomputes the warp map to wrap the 
// texture around a sphere. Currently only warps things in the X direction.
// I might later add a Y offset to the map for rotation around any axis, but
// that is VERY complex, and trig was never a strong point.
//
// accepts:	globe structure
//			height & width - size in characters
//			pixels - ptr to ASCII texture
//			wrap - width of texture in chars (not width of globe)
// returns:	1 on success, 0 if failed to alloc mem
int GlobeInit(GlobeInfo* globe, int height, int width, char* pixels, int wrap)
{
	float* xsptr;
	int row, col, coll, colr;
	double gwh, ghh, x,y, span;

	globe->height = height;
	globe->width = width;
	globe->wrap = wrap;
	globe->pixels = pixels;
	globe->xs = NULL; // for now
	
	if (width  > 128) return 0;			// too wide!
	if (height > 127) return 0;			// too tall!
	xsptr = malloc(height * width * sizeof(float));
	if (xsptr == NULL) return 0;
	globe->xs = xsptr;					// set warp map ptr

	// precompute warp map for x offsets
	gwh = (double)width / 2;			// precalc half width
	ghh = (double)height / 2;
	for (row = 0; row < height; row++) {
		y = (row-ghh+.5)/ghh;			// lateral line
		x = sqrt(1 - y*y);				// x of earth surface at current y
		span = x*gwh;					// span from center axis
		coll = (int) ((1-x)*gwh + .5);	// leftmost column at current row
		colr = width - coll;			// rightmost column
		//printf("row=%3d y=%8f x=%8f l=%3d r=%3d w=%3d s=%8f\n", row, y, x, coll, colr, width, span);
		for (col = 0; col < width; col++) {
			if (col >= coll && col < colr) {
				x = asin(((double)col-gwh+.5) / span);
				*xsptr++ = (float)(x*wrap / (1.57079632679489661923*4));
			}
			else { // not in the globe, off the side
				*xsptr++ = -32768;
			}
		}
	}

	return 1;
}

////////////////////////////////////////////////////////////////////////////////
// Prints a globe, applying precomputed warp effects and rotation amount.
// Technically there is no "rotation" effect. It's just a shifting of the 
// texture map and reapplying it over the sphere.
//
// expects:	GlobeInit has been called
// accepts:	angle - amount to 'shift' map before printing
//			it is not in the standard degree range 0-360
//			but rather ranges from 0 - (map_texture_width-1)
void GlobePrint(GlobeInfo* globe, double angle)
{
	char text[16384];
	char* textptr;
	char* texturerow;
	char chr;
	float* xsptr;
	float xofs;
	int mask, row, col, dummy;

	xsptr = globe->xs;
	if (xsptr == NULL) return; // just in case not initted
	texturerow = globe->pixels;
	mask = globe->wrap - 1; // make AND mask to wrap columns
	textptr = text;

	for (row = globe->height; row > 0; row--) {
		for (col = globe->width; col > 0; col--) {
			xofs = *xsptr++;
			if (xofs == -32768) chr = ' '; // sentinel value meaning out of range
			else				chr = *(texturerow+((int)(xofs+angle) & mask));
			*textptr++ = chr;
		}
		*textptr++ = '\n';
		texturerow += globe->wrap; // next row of pixels in texture map
	}
	*textptr = '\0';
   #ifdef _WINDOWS
	WriteConsole(GetStdHandle(STD_OUTPUT_HANDLE), text, (int)(textptr-text), &dummy, 0);
	//printf(text);
   #endif
   #ifdef _LINUX
	write(1, text, textptr-text);
   #endif
}

////////////////////////////////////////////////////////////////////////////////
// Frees mem alloced by GlobeInit
//
// accepts:	globe structure
void GlobeFree(GlobeInfo* globe)
{
	float* xsptr = globe->xs;
	if (xsptr) { // in case was never initted
		free(xsptr);
		globe->xs = 0;
	}
}

////////////////////////////////////////////////////////////////////////////////
// Prints message and ends program
//
// accepts:	msg - text to display
//			error - error code to return to system
void EndWithErrMsg(char* msg, int error)
{
	printf("%s\n", msg);
	exit(error);
}

/*
Errata:

http://www.linux.com/howtos/Text-Terminal-HOWTO-21.shtml#esc_seq_list

Table of 8-bit DEC control codes (in hexadecimal). Work on VT2xx or later. CSI is the most common. 

ACRONYM  FULL_NAME                      HEX     REPLACES
IND Index (down one line)               84      ESC D
NEL Next Line                           85      ESC E
RI  Reverse Index (one line up)         8D      ESC M
SS2 Single Shift 2                      8E      ESC N
SS3 Single Shift 3                      8F      ESC O
DCS Device Control String               90      ESC P
CSI Control Sequence Introducer)        9B      ESC [
ST  String Terminator

2544028200 = 1980-Aug-13

*/
