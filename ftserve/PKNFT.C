/*//////////////////////////////////////////////////////////////////////////////
pknft.c - main server code (shared by both Windows and Linux)

PknFt (Piken's File Transfer Server)
Dwayne Robinson (c)PikenSoft 2004

Overall view:
	(1) main thread (user interface)
		sends commands to server via pipe interface
		receives notifications back via either
			<Linux> an outbound pipe
			<Windows> messages posted to a window
	(2) server thread
		responds to local server commands
		responds to socket events and remote requests

Compiling:
	Linux:
		gcc:
			Needs -lpthread option

	Sparc Unix
		gcc:
			Needs both -lpthread and -lxnet options

	Windows:
		MS Visual Studio 6 or .NET:
			Needs WS2_32.Lib

History:
   20040406	Start project.
   20040408	Think about implementation extensively, considering how to make it
			work on both Windows and Linux. Finally decide on pipes as means of
			communication between main and server thread. They should allow the
			most flexibility. Communication through semophores and shared
			memory would result in more blocking.
   20040411	Server compiles! All commands from the main thread are processed;
			however, but no file communication is actually implemented yet.
   20040418	So apparently pipes, even no when data is waiting, are considered
			always signaled. That caused my loop to read the data that was not 
			there, blocking it permanently - the very thing I wanted to avoid.
			How stupid. When the other side closes the connection, select sets
			the socket as 'readable', but there is nothing to READ.
   20040419	Change the windows implementation to use WSAEventSelect instead.
			The code is much cleaner, smaller, and uses fewer resources.
			GetPacket unbytestuffing finished.
			Test functionality with Linux successfully, but need to change
			some of the connect and accept code before it will communicate.
   20040420	Run out of time to finish project
   20040502 Flip connects to Flip, Win to Win, Flip to Win, Win to Flip,
			Win to Flop, but Flop can not connect to Win or Flip?
			Flop will not even attempt to connect to Flip. It briefly connects
			to Win then immediately disconnects.
		  -	Figure out why. Sparc does not return the usual inprogress or
			wouldblock error. Instead, it just returns 0. How unhelpful >_<
			So now, every operating system can connect to every other system.


Todo:
	Writing to generic handles, including devices and pipes
	Writing directly to memory for speed or temporary objects
	Multiple streams for multiplexing video and audio
	Callbacks or event triggers for each stream.
	Thinking of merging local and remote requests
	Change all parameters to Unicode.

Notes:
	Only one instance of this server can be invoked per process.

*/

#define PknFt_c // so that extra header information is included
#include "pknft.h"

static int Port=1359; // used by some prog called ftsrv, so seemed fitting
static int Ip=0x0100007F; // initial no connection with another computer
static u_int Socket=0; // open connection between other end
static int AcceptFiles=1; // automatically serve files without confirm
static int AcceptClients=1; // accept connections without being told to
static struct sockaddr_in SockAddr;
static char FilePath[MAX_PATH];
static char FileNameIn[MAX_PATH];
static char FileNameOut[MAX_PATH];
static HANDLE FileHandIn=0;
static HANDLE FileHandOut=0;
static HANDLE FileSizeIn;
static HANDLE FileSizeOut;
static int IoCount;				// just to waste number of bytes actually read

static PknftPipeMsg PinBfr;
int PknftMsgId = 0x400+13;

#ifdef _WINDOWS
HANDLE PknftPin[2] = {NULL,NULL}; // pipe into thread, commands
HANDLE PknftPout[2] = {NULL,NULL}; // pipe out from thread, notifications
static HANDLE ServerThread;
static HANDLE ServerEvent; // triggered upon new incoming data
HWND PknftHwnd = NULL;		// hwnd to send notifications to
int Dummy;					// misc dummy var
#endif

#ifdef _LINUX
int PknftPin[2] = {0,0}; // pipe into thread, commands
int PknftPout[2] = {0,0}; // pipe out from thread, notifications
static pthread_t ServerThread;
#endif

static int Mode=0;
static enum {
	ModeStopped=0,				// idle, waiting for commands
	ModeListening=1,			// waiting for incoming connections
	ModeConnecting=2,			// attempting to connect to machine
	ModeConnected=4,			// either accepted or connected
	ModeGetting=8,				// receiving a file
	ModePutting=16,				// sending a file
	ModeListing=32,				// listing folder
	ModeDying=64,				// shutting down

	// these two mean that data is either coming in or out, of any form
	// including connection, listening, getting/sending files, listing...
	ModeActive=ModeListening|ModeConnecting|ModeConnected,
	ModeReading=ModeListening|ModeGetting|ModeConnected,
	ModeWriting=ModePutting
	// Peceiving or sending a folder listing is exclusive
	// and stalls any file transfers until finished.
} Modes;

#define PacketBufferSize 16384
static int SendBufferLen=0; // bytes built so far, reset after full packet send
static int PackBufferLen=0; // bytes received so far, reset after full packet processed
static int RecvBufferLen=0;
static int PackBufferOverflow=0; // flag an error occurred during receive, like buffer overflow
static char SendBuffer[PacketBufferSize+4];// build packets before sending
static char RecvBuffer[PacketBufferSize+4];// incoming data ready to be processed
static char PackBuffer[PacketBufferSize+4];// raw, unencoded socket data
static char FileBuffer[PacketBufferSize+4];// buffer for local file reads

#ifdef _WINDOWS
static WSANETWORKEVENTS SocketEventList;
#endif

static fd_set FdsWriteable;
static fd_set FdsReadable;
static fd_set FdsException;

////////////////////////////////////////////////////////////////////////////////
// Initializes server, creates thread, events, com pipes
//
// accepts:	none
// returns:	true on success
//			false on error
int PknftInit() {
  #ifdef _WINDOWS
	WSADATA WsaInit;
  #endif

	dbgmsg("PknftInit");

	Mode = ModeStopped;
  #ifdef _WINDOWS
		if (WSAStartup(0x101, &WsaInit)) // bool logic reversed!
			goto WinsockFailed;

		// pipe for communicating to server thread
		if (!CreatePipe(&PknftPin[0], &PknftPin[1], NULL, 1024)) 
			goto PinFailed;

		// event for server thread
		ServerEvent = CreateEvent(NULL, 0,0, NULL);
		if (ServerEvent == NULL)
			goto EventFailed;

		// where all the action occurs
		ServerThread = CreateThread(NULL, 0, (LPTHREAD_START_ROUTINE)PknftLoop, 0, 0, &Dummy);
		if (ServerThread == NULL) 
			goto ThreadFailed;

		ResetConnectVars();

	return true;

		// error cleanup in reverse order //
		//SlThreadFailed:
		//	CloseHandle(ServerThread);
		ThreadFailed:
			CloseHandle(ServerEvent);
		EventFailed:
			CloseHandle(PknftPin[0]);
			CloseHandle(PknftPin[1]);
		PinFailed:
			WSACleanup();		
		WinsockFailed:

			MessageBox(NULL, "File server initialization failed.", "PknftInit", MB_OK);

	return false;	

  #else
		if (pipe(&PknftPin[0])) goto PinFailed;
		if (pipe(&PknftPout[0])) goto PoutFailed;

		// handle request by passing onto child thread
		if ( pthread_create(&ServerThread, NULL, PknftLoop, NULL) != 0)
			goto ThreadFailed;
		pthread_detach(ServerThread); // remove thread resources when done

		dbgmsg("File server init succeeded");
	return true;

		// error cleanup in reverse order //
		ThreadFailed:
			close(PknftPout[0]);
			close(PknftPout[1]);
		PoutFailed:
			close(PknftPin[0]);
			close(PknftPin[1]);
		PinFailed:
		dbgmsg("File server init failed");
	return false;

  #endif
}

////////////////////////////////////////////////////////////////////////////////
// Sets one of the server variables.
//
// accepts:	var - number identifying variable
//			value - new value to assign
// return:	true if success
//			false if variable does not exist or illegal value
int PknftSetVar(unsigned int var, unsigned int value) {
	switch (var)
	{
	case PknftSetPort:
		Port=value;
		break;
	case PknftSetIp:
		Ip=value;
		break;
	case PknftSetAutoAcceptFiles:
		AcceptFiles=value;
		break;
  #ifdef _WINDOWS
	case PknftSetHwnd: // set who to send notifications to
		PknftHwnd=(HWND)value;
		break;
  #endif
	default:
		return false;
	}
	return true;
}

////////////////////////////////////////////////////////////////////////////////
// Sets one of the server variables.
//
// accepts:	var - number identifying variable
// returns:	the variable value
//			0 if unknown variable
int PknftGetVar(unsigned int var) {
	switch (var)
	{
	case PknftSetPort:
		return Port;
	case PknftSetIp:
		return Ip;
	case PknftSetAutoAcceptFiles:
		return AcceptFiles;
  #ifdef _WINDOWS
	case PknftSetHwnd: // set who to send notifications to
		return (int)PknftHwnd;
  #endif
	default:
		return false;
	}
}

////////////////////////////////////////////////////////////////////////////////
// Frees all resources used by the file server.
// Also unblocks the server thread so it can exit.
//
// Calling this before telling the thread to stop though will stop any file transfers
// without notifying the other end nicely.
//
// accepts:	none
// returns:	none
void PknftFree() {
	dbgmsg("PknftFree");

	Mode |= ModeDying;
  #ifdef _WINDOWS
	CloseHandle(ServerEvent);
	// After hanging the program several times, I learned that the pipes MUST
	// be closed in this order. If you attempt to close the read end before
	// the write end, the thread freezes permanently.
	// Unsure if the same thing happens on Linux, but just in case, I'm doing
	// that one the same way.
	CloseHandle(PknftPin[1]);
	CloseHandle(PknftPin[0]);
	//CloseHandle(PknftPout[0]);
	//CloseHandle(PknftPout[1]);
  #else // _LINUX
	close(PknftPin[1]);
	close(PknftPin[0]);
	close(PknftPout[1]);
	close(PknftPout[0]);
  #endif

	if (Socket) closesocket(Socket); Socket=0;
	if (FileHandIn) CloseHandle(FileHandIn);	FileHandIn=0;
	if (FileHandOut) CloseHandle(FileHandOut);	FileHandOut=0;
	Mode = ModeStopped;

  #ifdef _WINDOWS
	WSACleanup();
  #endif
}

////////////////////////////////////////////////////////////////////////////////
// The main server loop that checks for events and commands,
// and dispatches them to the proper routines.
// The Windows and Linux versions are significantly different
// enought to warrant their own complete versions of this function.
// Not called directly - meant to be as an independant thread.
//
// accepts:	param not used
// returns:	int is always false
#ifdef _WINDOWS
int PknftLoop(void *param) {

	dbgmsg("PknftLoop: entered");

	while (!(Mode & ModeDying)) {
		// Theoretically, using a pipe for control could allow the server to 
		// not only be controlled from a different process, but an entirely 
		// different machine too.
		if (!PeekNamedPipe(PknftPin[0], NULL,0, NULL,&IoCount,NULL)) {
			dbgmsg("PknftLoop: pipe closed, breaking loop");
			break;
		}
		if (IoCount) { // triggered by pipe message
			HandleLocalRequest();
		}
		else if (PeekSocket()) { // check if network event occurred
			HandleSocketEvent();
		}
		else if (Mode & ModeWriting) { // write any file in progress
			HandleRemoteWrites();
		}
		else { // wait for next pipe command or socket event
			if (WaitForSingleObject(ServerEvent, INFINITE) != WAIT_OBJECT_0) {
				dbgmsg("PknftLoop: event closed, breaking loop");
				break;
			}
			ResetEvent(ServerEvent); // reset to trigger next call
		}
	} // end while
	dbgmsg("PknFtLoop: exiting");
	return false;
#endif

#ifdef _LINUX
void * PknftLoop(void *param) {

	dbgmsg("PknftLoop: entered");

	while (!(Mode & ModeDying)) {
		FD_ZERO(&FdsReadable);
		FD_SET(PknftPin[0], &FdsReadable);
		if (Mode & ModeReading) FD_SET(Socket, &FdsReadable);
		FD_ZERO(&FdsWriteable);
		if (Mode & (ModeWriting|ModeConnecting)) FD_SET(Socket, &FdsWriteable);
		//dbgmsg("PknftLoop: about to select");
		if (select((Socket > PknftPin[0] ? Socket : PknftPin[0])+1, &FdsReadable, &FdsWriteable, NULL, NULL) <= 0) {
			break; // one of fds is invalid. server probably dying.
		}
		//dbgmsg("PknftLoop: out of select");
		if (FD_ISSET(PknftPin[0], &FdsReadable)) {
			HandleLocalRequest();
		}
		if (FD_ISSET(Socket, &FdsReadable)) {
			///dbgmsg("  PknftLoop: select readable");
			HandleSocketEvent();
		}
		if (FD_ISSET(Socket, &FdsWriteable)) {
			///dbgmsg("  PknftLoop: select writeable");
			HandleRemoteWrites();
		}

	} // end while

	dbgmsg("PknftLoop: exiting at end");
	return NULL;
#endif

}

#ifdef _WINDOWS
////////////////////////////////////////////////////////////////////////////////
// Checks if socket events are waiting
//
// accepts:	none
// returns:	the events pending mask (lNetworkEvents)
static int PeekSocket() {
	if (!(Mode & ModeActive)) return false;

	if (WSAEnumNetworkEvents(Socket, ServerEvent, &SocketEventList) != 0) {
		//! notify parent
		if (Socket) {closesocket(Socket); Socket=0;}
		Mode = ModeStopped;
		return false;
	}
	return SocketEventList.lNetworkEvents; // nonzero if any bits set because of event
}
#endif

////////////////////////////////////////////////////////////////////////////////
// Handles events like connect, new socket data, disconnect...
//
// accepts:	none
// returns:	none
static void HandleSocketEvent() {

#ifdef _WINDOWS
	if (SocketEventList.lNetworkEvents & FD_READ) {
		int FlushSocket = true; // read all incoming socket data
		while (GetPacket(&PinBfr.Hdr.cmd, RecvBuffer, &RecvBufferLen, FlushSocket) > 0) {
			FlushSocket = false;
			HandleRemoteRequest();
		}
	}
	if (SocketEventList.lNetworkEvents & FD_CONNECT) {
		Mode &= ~(ModeListening|ModeConnecting|ModeConnected);
		if (SocketEventList.lNetworkEvents & FD_WRITE) {
			// if Writeable, connection established
			Mode |= ModeConnected;
			ResetConnectVars();
			NotifyParentStr(PknftCmdStatus, "Outgoing connection accepted");
		}
		else {
			closesocket(Socket);
			NotifyParentStr(PknftCmdStatus, "Outgoing connection failed");
		}
	}
	// Note: writeability is actually polled, not checked here
	//else if (SocketEventList.lNetworkEvents & FD_WRITE) {
	//	...
	//}
	if (SocketEventList.lNetworkEvents & FD_ACCEPT) {
		int AdrSize = sizeof(SockAddr);
		int OldSocket = Socket;

		Mode &= ~(ModeListening|ModeConnecting|ModeConnected);
		// if readable, accept connection
		Socket = accept(OldSocket, (struct sockaddr*) &SockAddr, &AdrSize);
		if (Socket > 0) {
			Mode |= ModeConnected;
			ResetConnectVars();
			NotifyParentStr(PknftCmdStatus, "Incoming connection accepted");
		}
		else {
			Socket=0;
			NotifyParentStr(PknftCmdStatus, "Listen failed");
		}
		closesocket(OldSocket); // close original socket regardless of success/fail
	}
	if (SocketEventList.lNetworkEvents & FD_CLOSE) {
		Mode &= ~ModeConnected;
		NotifyParentStr(PknftCmdStatus, "Was disconnected by remote server");
		Disconnect();
	}

#endif

#ifdef _LINUX
	if (Mode & ModeConnected) {
		int ReadSocket;

		ioctl(Socket, FIONREAD, &ReadSocket);
		if (ReadSocket <= 0) { // ensure was not closed on us
			Mode &= ~ModeConnected;
			NotifyParentStr(PknftCmdStatus, "Was disconnected by remote server");
			Disconnect();
		}
		else {
			int ReadSocket = true;
			while (GetPacket(&PinBfr.Hdr.cmd, RecvBuffer, &RecvBufferLen, ReadSocket) > 0) {
				ReadSocket = false;
				HandleRemoteRequest();
			}
		}
	}
	else if (Mode & ModeListening) {
		int AdrSize = sizeof(SockAddr);
		int OldSocket = Socket;

		Mode &= ~(ModeListening|ModeConnecting|ModeConnected);
		// if readable, accept connection
		Socket = accept(OldSocket, (struct sockaddr*) &SockAddr, &AdrSize);
		if (Socket > 0) {
			Mode |= ModeConnected;
			ResetConnectVars();
			NotifyParentStr(PknftCmdStatus, "Incoming connection accepted");
		}
		else {
			Socket=0;
			NotifyParentStr(PknftCmdStatus, "Listen failed");
		}
		closesocket(OldSocket); // close original socket regardless of success/fail
	}
#endif

}

////////////////////////////////////////////////////////////////////////////////
// Sends whatever needs to be sent to client, including chunks of files,
// file listings, or maybe audio streams. The inverse of HandleLocalRequest.
//
// accepts:	[Mode] (it knows what needs to be done each call)
// returns:	none
static void HandleRemoteWrites() {

#ifdef _LINUX
	// Although I would prefer this to be in HandleSocketEvent,
	// this special case is for Linux.
	if (Mode & ModeConnecting) {
		dbgmsg("connected");
		Mode &= ~(ModeListening|ModeConnecting|ModeConnected);
		Mode |= ModeConnected;
		NotifyParentStr(PknftCmdStatus, "Outgoing connection accepted");
	}
	else
#endif

	if (Mode & ModeListing) {
		// list contents of folder
	}
	else if (Mode & ModePutting) {
	  #ifdef _WINDOWS
		if (ReadFile(FileHandOut, FileBuffer, PacketBufferSize-2048, &IoCount, NULL)
			&& IoCount > 0) {
	  #endif
	  #ifdef _LINUX
		IoCount = read(FileHandOut, FileBuffer, PacketBufferSize-2048);
		dbgmsg("HandleRemoteWrites: writing %d bytes", IoCount);
		if (IoCount > 0) {
	  #endif
			SendPacket(PknftHdrDataFile, FileBuffer,IoCount);
		}
		else {
			StopPut();
			NotifyParentStr(PknftCmdStatus, "Reached end of file and stopped (put)");
		}
	}
}

////////////////////////////////////////////////////////////////////////////////
// Handles user commands, local commands from the main thread.
// 
// accepts:	[PknftPin]
// returns:	none
static void HandleLocalRequest() {

  #ifdef _WINDOWS
	// read message header and body
	ReadFile(PknftPin[0], &PinBfr,sizeof(PinBfr.Hdr), &IoCount,NULL);
	if (PinBfr.Hdr.len > 0)
		ReadFile(PknftPin[0], &(PinBfr.msg),PinBfr.Hdr.len, &IoCount,NULL);
  #endif
  #ifdef _LINUX
	read(PknftPin[0], &PinBfr,sizeof(PinBfr.Hdr));
	if (PinBfr.Hdr.len > 0)
		read(PknftPin[0], &(PinBfr.msg),PinBfr.Hdr.len);
  #endif

	////////////////////////////////////////////////////////////////////////////
	// do action depending on message
	switch (PinBfr.Hdr.cmd) {
	//?case PknftCmdSocketEvent:
	//	dbgmsg("HandleLocalRequest: network data");
	//	HandleSocketEvent();
	//	break;
	//
	// exit the server (die) ///////////////////////////////////////////////////
	case PknftCmdExit:
		
		Disconnect();
		Mode |= ModeDying;
		//NotifyParentStr(PknftCmdError  exit);
		return;

	// stop ALL file activity both directions //////////////////////////////////
	case PknftCmdStop:
		if (!(Mode & ModeConnected)) {
			NotifyParentStr(PknftCmdStatus, "Not connected (stop)");
			break;
		}
		StopGet();
		StopPut();
		break;

	// get file from client ////////////////////////////////////////////////////
	case PknftCmdGet:
		if (!(Mode & ModeConnected)) {
			NotifyParentStr(PknftCmdStatus, "Not connected (get)");
			break;
		}
		StopGet();
		if (!FileNameOut[0]) break;
		// does nothing now
		break;

	// put file to client //////////////////////////////////////////////////////
	case PknftCmdPut:
		if (!(Mode & ModeConnected)) {
			NotifyParentStr(PknftCmdStatus, "Not connected (put)");
			break;
		}
		StopPut();

		if (!PinBfr.msg[0]) break;

		dbgmsg(PinBfr.msg);
	   #ifdef _WINDOWS
		//FileHandOut = CreateFile(PinBfr.ptr, GENERIC_READ,FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_FLAG_SEQUENTIAL_SCAN, NULL);
		FileHandOut = CreateFile(PinBfr.msg, GENERIC_READ,FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_FLAG_SEQUENTIAL_SCAN, NULL);
	   #else //_LINUX
		FileHandOut = open(PinBfr.msg, O_RDONLY);
	   #endif
		strncpy(FileNameOut, strfilename(PinBfr.msg), sizeof(FileNameOut));
		dbgmsg(FileNameOut);
		if ((signed)FileHandOut <= 0) {
			NotifyParentStr(PknftCmdStatus, "Can not open file (put)");
			break;
		}
		SendPacket(PknftHdrPut, FileNameOut,strlen(FileNameOut)+1);

		Mode |= ModePutting;
		NotifyParentStr(PknftCmdStatus, "Sending file (put)");
		break;

	// start listening for and accept connections //////////////////////////////
	case PknftCmdListen:
		if (Mode & ModeConnected) {
			NotifyParentStr(PknftCmdStatus, "Already connected (listen)");
			break;
		}
		if (Mode & (ModeConnecting|ModeListening))
			Disconnect();

		dbgmsg("Listen: Creating socket");

		Socket = socket(AF_INET, SOCK_STREAM, 0);
		if (Socket <= 0) {
			NotifyParentStr(PknftCmdStatus, "Could not create socket (listen)");
			break;			
		}

		// Disable Nagle algorithm
		//retval = 0;
		//setsockopt(sockfd, IPPROTO_TCP, TCP_NODELAY, &retval, sizeof(check)); 

		setsockopt(Socket, SOL_SOCKET, SO_REUSEADDR, (char*)&Socket, sizeof(Socket)); // SO_REUSEPORT

		// bind to given port to listen for incoming connections
		SockAddr.sin_family = AF_INET;
		SockAddr.sin_addr.s_addr = INADDR_ANY;
		SockAddr.sin_port = htons((short)Port);
		if ( bind(Socket, (struct sockaddr*) &SockAddr, sizeof(SockAddr))
			!= 0) {
			dbgmsg("Listen: bind failed");
			closesocket(Socket); Socket=0;
			NotifyParentStr(PknftCmdStatus, "Could not bind to port (listen)");
			break;
		}
		dbgmsg("Listen: bind succeeded");

		// establish listening queue
		if ( listen(Socket, 1) != 0) {
			dbgmsg("PknftLoop: listen failed");
			closesocket(Socket); Socket=0;
			NotifyParentStr(PknftCmdStatus, "Could not set connection queue (listen)");
			break;
		}
		dbgmsg("PknftLoop: listen succeeded");

		// put accept into nonblocking
	  #ifdef _WINDOWS
		WSAEventSelect(Socket, ServerEvent, FD_ACCEPT|FD_READ|FD_CLOSE|FD_WRITE);
		//ioctlsocket(Socket, FIONBIO, &Socket); // nonblocked I/O, just pass the socket as a value since it is alway nonzero ^_^
      #else //_LINUX
		fcntl(Socket, F_SETFL, fcntl(Socket, F_GETFL)|O_NONBLOCK);
		//ioctl(Socket, FIONBIO, &Socket);
      #endif

		Mode |= ModeListening;
		NotifyParentStr(PknftCmdStatus, "Waiting for incoming connections (listen)");
		break;

	// connect to remote server (either name or ip) ////////////////////////////
	case PknftCmdConnect:
		if (Mode & ModeConnected) {
			// already busy doing something, must stop first
			NotifyParentStr(PknftCmdStatus, "Already connected (connect)");
			break;
		}
		if (Mode & (ModeConnecting|ModeListening))
			Disconnect();

		// resolve host name (only supports by IPv4 for now)
		Ip = inet_addr(PinBfr.msg);
		if (Ip == INADDR_NONE) {
			//HOSTENT *Host = gethostbyname(PinBfr.msg);
			struct hostent *Host = gethostbyname(PinBfr.msg);
			if (Host == NULL) {
				NotifyParentStr(PknftCmdStatus, "Invalid server name or IP (connect)");
				break;
			}
			//Ip = ((struct in_addr *)Host->h_addr_list[0])->S_un.S_addr; // windows
			Ip = ((struct in_addr *)Host->h_addr_list[0])->s_addr;
			//dbgmsg( inet_ntoa(*((struct in_addr *)Host->h_addr_list[0]))  );
		}

		// create and setup socket
		Socket = socket(PF_INET, SOCK_STREAM, 0);
		//dbgmsg("PknftLoop: socket %d", Socket);
		if (Socket <= 0) {
			NotifyParentStr(PknftCmdStatus, "Could not create connection socket (connect)");
			break;
		}
		dbgmsg(PinBfr.msg);
		SockAddr.sin_family = AF_INET;
		SockAddr.sin_addr.s_addr = Ip; // only IPv4 for now
		//SockAddr.sin_addr.s_addr = 128|(193<<8)|(32<<16)|(61<<24);
		SockAddr.sin_port = htons((short)Port); // in silly 'network' order
		
		// put connect into nonblocking
	  #ifdef _WINDOWS
		WSAEventSelect(Socket, ServerEvent, FD_CONNECT|FD_READ|FD_CLOSE|FD_WRITE);
		//ioctlsocket(Socket, FIONBIO, &Socket); // nonblocked I/O, just pass the socket as a value since it is alway nonzero ^_^
      #else //_LINUX
		fcntl(Socket, F_SETFL, fcntl(Socket, F_GETFL)|O_NONBLOCK);
		//ioctl(Socket, FIONBIO, &Socket);
      #endif

		// attempt connect
		NotifyParentStr(PknftCmdStatus, "Attempting to contact server... (connect)");
		if ( connect(Socket, (struct sockaddr*)&SockAddr, sizeof(SockAddr)) != 0) {
		  #ifdef _LINUX
			dbgmsg("connect errno=%d", errno);
			// Linux can return either EWOULDBLOCK or EINPROGRESS
			// added errno = 0 for Sparc Unix
			if (errno == EWOULDBLOCK || errno == EINPROGRESS || errno == 0) {
		  #endif
		  #ifdef _WINDOWS
			if (GetLastError()==WSAEWOULDBLOCK) {
		  #endif
				Mode |= ModeConnecting;
			}
			else {
				closesocket(Socket); Socket=0;
				NotifyParentStr(PknftCmdStatus, "Outgoing connection failed (connect)");
				//NotifyParentStr(PknftCmdError  error connect);
			}
		}
		break;

	case PknftCmdChat:
		if (!(Mode & ModeConnected)) {
			NotifyParentStr(PknftCmdStatus, "Not connected (chat)");
			break;
		}
		SendPacket(PknftHdrDataChat, PinBfr.msg, strlen(PinBfr.msg)+1);
		//send(Socket, PinBfr.msg, strlen(PinBfr.msg),0); (raw send for debug)
		break;

	// disconnect forcefully ///////////////////////////////////////////////////
	case PknftCmdDisconnect:
		Disconnect();
		break;
	}
}


////////////////////////////////////////////////////////////////////////////////
// Takes action upon receipt of client request.
// 
// accepts:	[PinBfr] with request
// returns:	none
static void HandleRemoteRequest() {

	////////////////////////////////////////////////////////////////////////////
	// do action depending on message
	switch (PinBfr.Hdr.cmd) {
	case PknftHdrDataChat:
		//dbgmsg("Chat data");
		NotifyParentStr(PknftCmdStatus, RecvBuffer);
		break;

	// exit the server (die) ///////////////////////////////////////////////////
	case PknftHdrDataFile:
		if ((signed)FileHandIn > 0) {
			//NotifyParentStr(PknftCmdStatus, "File data received:");
			//NotifyParentStr(PknftCmdStatus, RecvBuffer);
			WriteFile(FileHandIn, RecvBuffer, RecvBufferLen, &IoCount, NULL);
		}
		break;
	case PknftHdrGet:
		// a get from them means a put to us
		NotifyParentStr(PknftCmdStatus, "Put request received (get to them)");
		//NotifyParentStr(PknftCmdStatus, RecvBuffer);
		break;
	case PknftHdrPut:
		// a put from them means a get to us

		///*
		StopGet();
		if (!RecvBuffer[0]) {
			NotifyParentStr(PknftCmdStatus, "End of receipt file (get)");
			break;
		}

		NotifyParentStr(PknftCmdStatus, "Getting file");
		NotifyParentStr(PknftCmdStatus, RecvBuffer);
		//strncpy(FileNameIn, RecvBuffer, sizeof(FileNameIn)); //! temp
		wsprintf(FileNameIn, "in_%s", RecvBuffer);

	   #ifdef _WINDOWS
		FileHandIn = CreateFile(FileNameIn, GENERIC_WRITE,FILE_SHARE_READ, NULL, OPEN_ALWAYS, FILE_FLAG_SEQUENTIAL_SCAN, NULL);
	   #else //_LINUX
		FileHandIn = open(FileNameIn, O_CREAT|O_WRONLY, S_IRUSR|S_IWUSR|S_IRGRP|S_IWGRP|S_IROTH);
		dbgmsg("Get: FileHandIn=%d errno=%d\n", FileHandIn, errno);
	   #endif
		if ((signed)FileHandIn <= 0) {
			NotifyParentStr(PknftCmdStatus, "Can not create receipt file (get)");
			break;
		}
		Mode |= ModeGetting;
		NotifyParentStr(PknftCmdStatus, "Created receipt file (get)");
		//*/

		break;
	}
}

////////////////////////////////////////////////////////////////////////////////
// Disconnects. Closes files if necessary.
//
// accepts:	none
// returns:	none
static void Disconnect() {
	int PrevMode = Mode;
	// terminate all file transfers
	// close all files/sockets

	// steps should be performed in this order
	StopGet();
	StopPut();
	Mode = ModeStopped;
	if (Socket) {closesocket(Socket); Socket=0;}
	if (PrevMode & ModeConnected) {
		NotifyParentStr(PknftCmdStatus, "Disconnected from remote server");
	} else if (PrevMode & ModeConnecting) {
		NotifyParentStr(PknftCmdStatus, "Canceled outgoing connection");
	} else if (PrevMode & ModeListening) {
		NotifyParentStr(PknftCmdStatus, "Canceled listen for incoming connections");
	}
	//NotifyParentStr(PknftCmdError  disconnect);
}

////////////////////////////////////////////////////////////////////////////////
// Closes the file coming in.
//
// accepts:	[FileHandIn]
// returns:	none
static void StopGet() {
	if (Mode & ModeGetting) {
		Mode &= ~ModeGetting;
		CloseHandle(FileHandIn); FileHandIn=0;
		//NotifyParentStr(PknftCmdError  receive stopped);
	}
}

////////////////////////////////////////////////////////////////////////////////
// Closes the file going out.
//
// accepts:	[FileHandOut]
// returns:	none
static void StopPut() {
	if (Mode & ModePutting) {
		Mode &= ~ModePutting;
		CloseHandle(FileHandOut); FileHandOut=0;
		SendPacket(PknftHdrPut, "",1); // end of file
		//NotifyParentStr(PknftCmdError  send stopped);
	}
}

////////////////////////////////////////////////////////////////////////////////
// If a full packet has been received, decodes the message out of the receive
// buffer. It will only return a full packet, and only one at a time.
// This routine does not care about whatever substructure the packet may have.
// That is not its job.
//
// *this was so much smaller before error checking was added :/
//
// Technical point: 'packets' in this protocol are not the same size as the
//		lower layer packets used to carry these messages. Although the server
//		itself is specifically designed for TCP/IP, the protocol itself should
//		work over anything, including raw phone line connections and even non 
//		telecommunications mediums like pipes.
//
// Overview:
//  get socket data
//	scan all the new bytes received
//  if no terminator found, return
//	expand bytes
//	shift all remaining data down
//
// accepts:	msg - ptr to set message id
//			outptr - buffer ptr to fill with message data (decoded packet)
//				This buffer MUST be >= PacketBufferSize
//			outlen - ptr to set received message data length
//			flags - currently only flag is to flush socket read buffer
// returns:	1 if retrieved whole packet
//			0 if need more data first
//			-1 if error, like socket was closed or buffer overflow
static int GetPacket(int *msg, unsigned char *outptr, int *outlen, int flags) {
	unsigned char *ptrbase = outptr;
	unsigned char *inptr;
	unsigned char c;
	int count = 0;

	// grab new data and continue only if a terminator has been received
	if (flags & 1) {
		count = recv(Socket, PackBuffer+PackBufferLen, PacketBufferSize-PackBufferLen, 0);
		// not checking for errors here, but it usually returns WSAEWOULDBLOCK
		//if (inlen <= 0) return -1;
	}
	if (count > 0) PackBufferLen += count;
	if (PackBufferLen <= 0) return 0;

  #ifdef _DEBUG
	dbgmsg("GetPacket data:");
	PackBuffer[PackBufferLen] = 0;
	dbgmsg(PackBuffer);
	dbgmsg("\n");
  #endif

	while (true) {
		// check for terminator
		count = PackBufferLen;
		for (inptr = PackBuffer; ;) {
			if (count-- <= 0) {
				if (PackBufferLen >= PacketBufferSize) {
					PackBufferOverflow = true;
					PackBufferLen = 0;
				}
				return 0;	
			}
			if (*inptr++ == PknftHdrEnd) break;
		}
		dbgmsg("GetPacket: terminator found");
		if (!PackBufferOverflow) break;
		// there was a packet overflow last time
		dbgmsg("GetPacket: wasting overflow");
		PackBufferLen = count;
		memmove(PackBuffer, inptr, PackBufferLen);
		PackBufferOverflow = false;
	}

	dbgmsg("GetPacket: decoding message");
	// decode data (unbytestuff)
	// Currently there is no compression, just byte substitution.
	// If a newer protocol uses compression, this code will no longer be valid,
	// and the remote machine should refuse communication or use a lower
	// protocol.

	if (PackBuffer[0] == PknftHdrEnd) { // skip empty packet
		*msg = PknftHdrEnd;
		*outlen = 0;
		PackBufferLen--;
	}
	else {
		for (inptr = PackBuffer+1; ;) {
			c = *inptr++;
			if ((unsigned)(c-PknftHdrEnd) <= 1) {
				if (c == PknftHdrEnd) break;
				c = (*inptr++) - 2;	//128->126 129->127
			}
			*outptr++ = c;
		}
		*msg = PackBuffer[0];
		*outlen = (outptr - ptrbase);
		ptrbase = &PackBuffer[0]; // <-hack for GCC to work right
		PackBufferLen -= (inptr - ptrbase);
	}

	// shift any remaining data forward in buffer
	if (PackBufferLen>0)
		memmove(PackBuffer, inptr, PackBufferLen);

	return 1;
}

////////////////////////////////////////////////////////////////////////////////
// Sends messages and encoding and appending terminator.
//
// Terminator:
//	126 is used as a packet terminator exclusively (no other interpretation)
//	127 is a miscellaneous function character.
//
// Byte substitution:
//	126 is replaced with 127 128
//	127 is replaced with 127 129
//
// accepts:	msg - message id to send
//			inptr - ptr to message data
//			inlen - length of data
// returns:	none
static void SendPacket(int msg, unsigned char *inptr, int inlen) {
	unsigned char SendBuffer[PacketBufferSize*2+4];
	unsigned char c;
	int sendlen;
	int outlen=1; // count message byte and trailer

	if (inlen > PacketBufferSize) return; // too big!

	SendBuffer[0] = msg;
	for (; inlen && outlen<(PacketBufferSize*2); inlen--) {
		c = *inptr++;
		if ((unsigned)(c-PknftHdrEnd) <= 1) {
			SendBuffer[outlen]   = PknftHdrControl;
			SendBuffer[outlen+1] = c+2; // 126->128 127->129
			outlen+=2;
		} else {
			SendBuffer[outlen++] = c;
		}
	}
	SendBuffer[outlen++] = PknftHdrEnd;

	// The socket is always nonblocking except here in this
	// send function (connect, accept, and read are not blocked)
	// I should make this non-blocking as well, but...
	do {
		sendlen = send(Socket, SendBuffer, outlen, 0);
		if (sendlen >= 0) {
			outlen -= sendlen;
		}
		else { // error. if not block error, then abort
		  #ifdef _LINUX
			if (errno != EWOULDBLOCK) {
		  #endif
		  #ifdef _WINDOWS
			if (GetLastError() != WSAEWOULDBLOCK) {
		  #endif
				dbgmsg("SendPacket: error sending");
				break; // uh-oh, socket error
			}
			// else wait for it to become available
			FD_ZERO(&FdsWriteable);
			FD_SET(Socket, &FdsWriteable);
			select(0, NULL,&FdsWriteable,NULL, NULL);
		}
	} while (outlen > 0);
}

////////////////////////////////////////////////////////////////////////////////
// Notify the parent thread/window that initialized the server of a
// relevant event.
//
// Hmm. Whether to do synchronous or async?
//
// accepts:	event - id of event that occurred
//			msg - ptr to message string
// returns:	none
static void NotifyParentStr(int event, char *msg) {
  #ifdef _WINDOWS
	//PostMessage(PknftHwnd, PknftMsgId, event, (long)param);
	SendMessage(PknftHwnd, PknftMsgId, event, (long)msg);
	#ifdef _DEBUG
	dbgmsg(msg);
	dbgmsg("");
	#endif
  #endif

  #ifdef _LINUX
	PknftPipeMsg PoutBfr;
	PoutBfr.Hdr.sync = 0; // nothing for now
	PoutBfr.Hdr.src = PknftMsgId;
	PoutBfr.Hdr.cmd = event;
	PoutBfr.Hdr.len = strlen(msg)+1;
	if (PoutBfr.Hdr.len > sizeof(PoutBfr.msg)) PoutBfr.Hdr.len = sizeof(PoutBfr.msg);
	memcpy(PoutBfr.msg, msg, PoutBfr.Hdr.len);
	write(PknftPout[1], &PoutBfr, sizeof(PoutBfr.Hdr)+PoutBfr.Hdr.len);
	//write(1, msg, PoutBfr.Hdr.len); //!
	//write(1, "\n", 1); //!
  #endif
}

////////////////////////////////////////////////////////////////////////////////
// doesn't do much now, but I plan for it to initialize more later
// Called when a connection is first made.
//
// accepts:	none
// returns:	none
static void ResetConnectVars() {
	PackBufferOverflow = 0;
	PackBufferLen = 0;
}

////////////////////////////////////////////////////////////////////////////////
// Sends a string to PknftCommand, including the null terminator.
//
// accepts:	cmd - server command to perform
//			msg - command information (like a filename)
// returns:	none
void PknftCommandStr(int cmd, char *msg) {
	int len = 0;
	if (msg != NULL) len = strlen(msg)+1;
	PknftCommand(cmd, msg, len);
}

////////////////////////////////////////////////////////////////////////////////
// Posts a command to the server, to perform as soon as it can.
//
// Because this function simply passes the message and does not wait for 
// the server thread to respond, there is no success/failure return value.
// Instead, a notification will be sent back. While this makes the code
// more complex, it allows the server to continue uninterrupted and prevents
// the main thread from being blocked (unless the pipe becomes too full)
//
// accepts:	cmd - server command to perform
//			msg - command information (like a filename)
//			len - length of message in bytes
// returns:	none
void PknftCommand(int cmd, void *msg, int len) {
	// local copy to not overwrite file variable
	PknftPipeMsg PoutBfr;
	int IoCount;

	PoutBfr.Hdr.sync = 0; // nothing for now
	PoutBfr.Hdr.src = PknftMsgId;
	PoutBfr.Hdr.cmd = cmd;
	PoutBfr.Hdr.len = len;

	memcpy(PoutBfr.msg, msg, len);
	
  #ifdef _WINDOWS
	WriteFile(PknftPin[1], &PoutBfr, sizeof(PoutBfr.Hdr)+len, &IoCount, NULL);
	SetEvent(ServerEvent); // trigger server thread if sleeping
  #endif
  #ifdef _LINUX
	//dbgmsg("PknftCommand: writing to pipe");
	write(PknftPin[1], &PoutBfr, sizeof(PoutBfr.Hdr)+len);
  #endif
}
