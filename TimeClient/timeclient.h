////////////////////////////////////////////////////////////////////////////////
// timeclient.h

//#define _DEBUG

#ifdef _WIN32
 #define _WINDOWS
#else 
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
 #define SOCKET unsigned int

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
 //#include <sys/ioctl.h>
 //#include <ioctls.h>

 #include <errno.h>

 // specifically needed for flop (Sparc Unix)
 #include <stropts.h> 
 #include <netinet/in.h>
 #ifndef FIONREAD // silly Flop does not define this
 //#include <sys/filio.h>
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


enum {false, true};

int strmatch(const char *string, const char *matches);
