////////////////////////////////////////////////////////////////////////////////
// pknft.h

#ifdef PknFt_c // only include the following if PknFt.c using it

//#define _DEBUG

#ifndef _WINDOWS
#define _LINUX
#endif

#ifdef _WINDOWS
 #define WIN32_LEAN_AND_MEAN
 #include <windows.h>
 #include <winsock2.h>

 #ifdef _DEBUG
  //#define dbgmsg(msg, ...) OutputDebugString(msg)
  #define dbgmsg(msg) OutputDebugString(msg);OutputDebugString("\n")
  #define dbgerr OutputDebugString
 #else
 #define dbgmsg(msg) //
 #define dbgerr //
 #undef OutputDebugString
 #define OutputDebugString(msg) //
#endif
#endif


#ifdef _LINUX
 #define _CONSOLE
 #define HANDLE int
 #define MAX_PATH 260

 #define closesocket close // on Linux, these functions are one and the same
 #define CloseHandle close
 #define WriteFile(a,b,c,d,e) write(a,b,c)
 
 #include <unistd.h>
 #include <sys/types.h>

 #include <sys/stat.h>
 #include <fcntl.h>
 #include <sys/select.h>
 
 #include <sys/socket.h>
 //#include <inttypes.h>
 #include <netinet/in.h>
 #include <netdb.h>
 #include <pthread.h>
 #include <sys/ioctl.h>
 //-#include <ioctls.h>

 #include <errno.h>

 // specifically needed for flop (Sparc Unix)
 #include <stropts.h> 
 #include <netinet/in.h>
 #ifndef FIONREAD // silly Flop does not define this
 #include <sys/filio.h>
 #endif
 #ifndef INADDR_NONE
 #define INADDR_NONE -1
 #endif

 #ifdef _DEBUG
  #include <stdio.h>
  #define dbgmsg(msg, ...) printf(msg, ##__VA_ARGS__);printf("\n");
  #define dbgerr(msg) perror(msg)
 #else
  #define dbgmsg(msg, ...) //
  #define dbgerr(msg) //
 #endif
#endif


// private functions
static void Disconnect();
static void StopGet();
static void StopPut();
static void HandleSocketEvent();
static void HandleRemoteWrites();
static void HandleRemoteRequest();
static void HandleLocalRequest();
static void SendPacket(int msg, unsigned char *ptr, int len);
static int GetPacket(int *msg, unsigned char *outptr, int *outlen, int flags);
static void NotifyParentStr(int event, char *msg);
static void ResetConnectVars();
#ifdef _WINDOWS
static int PeekSocket();
#endif

const char *strfilename(const char *filename);


enum {false, true};

#endif

////////////////////////////////////////////////////////////////////////////////
// public functions

int  PknftInit(); // initialize and create server thread
void PknftFree(); // stop server and free resources
int  PknftSetVar(unsigned int var, unsigned int value); // set a variable
int  PknftGetVar(unsigned int var);
void PknftCommand(int cmd, void *msg, int len);
void PknftCommandStr(int cmd, char *msg); // send text command to the server thread
#ifdef _WINDOWS
 int PknftLoop(void* param); // the main thread loop
#endif
#ifdef _LINUX
 void* PknftLoop(void* param); // the main thread loop
#endif

#define PknFtVersion "1.1"


////////////////////////////////////////////////////////////////////////////////

enum {
	PknftSetPort,
	PknftSetIp,
	PknftSetAutoAcceptFiles,
	PknftSetHwnd,
	PknftSetUser,
	PknftSetPass
};

// Messages (commands/notifications) between main and server thread
// Do not confuse these with messages in packets.
// These are notifications sent to the main thread via a pipe or window.
//
// Stop will stop everything. If you only want to stop the get or put,
// send another get/put command with no filename (null).
enum {
	PknftCmdExit, // exit the server (die)
	PknftCmdStop, // stop ALL file activity both directions
	PknftCmdGet, // get file from client (pass null to stop file transfer)
	PknftCmdPut, // put file to client (pass null to stop file transfer)
	PknftCmdGetUpdate, // update on get progress
	PknftCmdPutUpdate, // update on put progress
	PknftCmdConnect, // connect to remote server (either name or ip)
	PknftCmdDisconnect, // disconnect forcefully
	PknftCmdListen, // start listening for and accept connections
	PknftCmdStatus, // error/success message
	PknftCmdUser, // send user name, or user name response
	PknftCmdChat, // send simple text message

	PknftCmdSocketEvent=12345	// this event must NOT be sent by the user
								// as it would be very confusing
};

// Packet headers between servers
// Do not confuse these with messages between threads.
// These are actual packet header values.
//
// Packets are never split. Lower protocols may break them up, which is fine,
// but a message is always sent as a whole message.
//
// New requests can be sent while a previous request is in progress,
// allowing a client to view a file listing even during a file send/receive.
// The servers do not support multiple connections or multiple simultaneous 
// file sends or receipts; however, a file can be sent while another is being 
// received.
//
// All messages are by byte 126. After running tests on several file formats
// (exe,pdf,avi,mpg,mp3,html) I've seen that 0/32/255 usually win the highest
// count and byte 126 is always in the low count. Because of its rarity in
// binary data (and naturally even less in ASCII data), it makes sense to be 
// the message divider.
//
enum {
	PknftHdrNull, // no data, not valid
	PknftHdrVersion, // server protocol version (always sent upon connect)
		// ascii - actual version
		// ascii - minimum version
	PknftHdrKey, // public key (mathematical operation to perform on password)
		// ? undecided yet
	PknftHdrId, // identify self with name and passkey (optional)
		// ? undecided yet
	PknftHdrGet, // file receive request (name only)
		// full path and file name
		// byte to resume from
		// (send with an empty file name to stop a current transfer)
	PknftHdrPut, // file send request (name and file info)
		// full path and file name
		// size
		// date (YYYYMMDDHHmmSS)
		// (send with an empty file name to stop a current transfer)
	PknftHdrGetList, // want file listing
		//
	PknftHdrError, // error response
		//

	// The following data streams are listed in priority.
	// They consist of only a single message byte and a pure data stream.
	// Some of the allotted 16 channels have meanings, but technically
	// they are not strict, as an application could send through whatever
	// channel it wanted. They are just listed here for consistency.
	// Video and audio can be sent to files, pipes, or directly to memory.
	// Directly to memory is the most efficient, but the program must be
	// able to keep up. The address of the next transfer can be set before
	// current one is finished for double buffering.
	PknftHdrData=96,
	PknftHdrDataChat=PknftHdrData, // simple text message
	PknftHdrDataAudio, // chunk of compressed waveform data
	PknftHdrDataList, // chunk of list data (name,date,size)
	PknftHdrDataVideo, // compressed video
	PknftHdrDataClipboard, // clipboard object
	PknftHdrDataFileCrc, // calculation of a file segment's CRC
	PknftHdrDataFile, // chunk of file data (no checksum or sequence tag)
	PknftHdrData7,
	PknftHdrData8,
	PknftHdrData9,
	PknftHdrData10,
	PknftHdrData11,
	PknftHdrData12,
	PknftHdrData13,
	PknftHdrData14,
	PknftHdrData15,

	PknftHdrEnd=126, // end of packet
	PknftHdrControl=127, // control character for byte sub

	// subheaders inside packets //
	//PknftHdrText=128,
	//PknftHdrUser,
	//PknftHdrPass,
	//PknftHdrFilePos,
};

typedef struct {
	struct {
		int sync;				// unused now (synchronizing)
		int src;				// source identifier (unused)
		int cmd;				// command/event
		int len;				// length of message (maybe unused)
	} Hdr;
	unsigned char msg[4096];	// body of message
} PknftPipeMsg;
