/*//////////////////////////////////////////////////////////////////////////////
ftserve.c - Linux command line interface.

Dwayne Robinson
CS372 - PROG1
2004-04-20

Overview:
	You may pass it arguments or type commands inside the prompt.
	Type 'help' for a list of commands.

Compiling:
	flip:
		gcc -o ftserve_linux -lpthread ftserve.c pknft.c string.c -DOSHOST=\"Linux\"
	flop:
		gcc -o ftserve_sparc -lpthread -lxnet ftserve.c pknft.c string.c -DOSHOST="\"Sparc Unix\""

Use:
	On one machine, type: 'listen'
	On another one, type: 'connect flip.engr.orst.edu'
	You can also loopback: 'connect 127.0.0.1'

History:
   20040412	Create this console interface to the server.
   20040502	Finally learned why flop would only return the keys you type after
			pressing four keys, after several wasted hours of searching through
			the helpless man pages and dozens of websites. Apparently even when
			you have put the terminal into nonblocking mode, it still has a
			minimum number of characters it needs to receive before giving them
			to you. So you would type 3 characters, and not until the 4rth key
			was pressed would you receive any of the keys. Stupid.
*/

#include <stdio.h>
#include <sys/time.h>
#include <sys/ioctl.h>
#include <termios.h>
#include <sys/types.h>
#include <unistd.h>

#include "pknft.h"

#ifndef FIONREAD
#include <sys/filio.h> // needed for FIONREAD, flop (Sparc Unix)
#endif

#ifndef OSHOST
#define OSHOST "Unix"
#endif

void DoCommand(char *command);
void DoCommands(char *command);
static int CheckServerNotifications();
static void ErasePrompt();
static void ReadPrompt();

////////////////////////////////////////////////////////////////////////////////

#define CommandLenMax 256
#define CommandWordsMax 5

#ifndef false
enum {false, true};
#endif

extern int PknftPout[2]; // pipe into thread, commands

static fd_set FdsReadable;

// main loop vars
static int alive = true;
static int reprompt = true; // redraw prompt because of interrupt
static char command[CommandLenMax];
static int cmdsize=0;

// recognized commands
static const char commands[] = {"exit\0" "quit\0" "q\0" "cd\0" "help\0"
	"get\0" "listen\0" "close\0" "connect\0" "open\0" "port\0" "type\0"
	"put\0" "disconnect\0" "chat\0" "?\0" "ls\0" //16
	"\0"};

////////////////////////////////////////////////////////////////////////////////
// Console prompt loop.
// Can accept command line args and commands typed directly.
//
int main (int argc, char* argv[])
{
	struct termios old_ts, new_ts;

	printf("PknFt Server " PknFtVersion ", Dwayne Robinson (c)2004 (" OSHOST ")\n");

	if (argc <= 1) {
		printf(
			"Type 'help' for command list or 'exit' when done\n"
			"Example usage: ftserve port 1359, listen\n"
			"               ftserve connect flip.engr.orst.edu, get test.txt\n"
		);
		PknftInit();
	}
	else {
		if (strunparse(command, &argv[1], argc-1, sizeof(command)) != argc-1) {
			printf("Arguments too long\n");
			exit(-1);
		}
		PknftInit();
		DoCommands(command);
	}

	// change default terminal behaviour to read chars manually
	command[0] = '\0';
	ioctl(0, TCGETS, &old_ts);
	new_ts = old_ts;
	new_ts.c_lflag &= ~(ICANON|ECHO);
	new_ts.c_cc[VMIN] = 0; // necessary for flop
    new_ts.c_cc[VTIME] = 255;
	ioctl(0, TCSETS, &new_ts);

	// main console loop
	while (alive) {
		int pending;

		if (reprompt) {
			// reprint prompt
			command[cmdsize] = '\0';
			printf(">%s", command);
			fflush(NULL);
			reprompt = false;
		}
		//printf("command='%s'", command); fflush(NULL);

		// wait for keypress or server notify
		FD_ZERO(&FdsReadable);
		FD_SET(0, &FdsReadable);
		FD_SET(PknftPout[0], &FdsReadable);
		//printf("about to select\n");
		if (select(PknftPout[0]+1, &FdsReadable,NULL,NULL, NULL) < 1) {
			alive = false;
			break;
		}
		//printf("after select\n");

		// keyboard was readable
		if (FD_ISSET(0, &FdsReadable)) {
			ReadPrompt();
		}
		// server notification
		if (FD_ISSET(PknftPout[0], &FdsReadable)) {
			while (CheckServerNotifications() > 0);
		}
	}
	ioctl(0, TCSETS, &old_ts);

	printf("terminating server..."); fflush(NULL);
	PknftCommandStr(PknftCmdExit, NULL);
	PknftFree();
	printf("ok\n");

}

////////////////////////////////////////////////////////////////////////////////
// Can iterate multiple commands, each comma separated.
//
// Like "port 1359, listen"
//
// accepts:	commands string
// returns:	none
void DoCommands(char *commands) {
	char *head = commands;
	char *tail = commands;

	///printf("DoCommands='%s'\n", commands);

	while (true) {
		char c = *tail;
		if (c == 0) {
			DoCommand(head);
			break;
		}
		else if (c == ',') {
			*tail = 0;
			DoCommand(head);
			head = tail+1;
		}
		tail++;
	}
}

////////////////////////////////////////////////////////////////////////////////
// Does a single command
//
// accepts:	command string
// returns:	none
void DoCommand(char *command) {
	char cmdparsed[CommandLenMax];
	char *words[CommandWordsMax];
	strncpy(cmdparsed, command, sizeof(cmdparsed));

	///printf("DoCommand: '%s'\n", command);

	if (strparse(cmdparsed, words, CommandWordsMax) <= 0) return;

	switch( strmatch(words[0], commands) ) {
	case 0: // exit
	case 1: // quit
	case 2: // q
		alive = false;
		break;
	case 3: // cd
	{
		char path[256];
		if(words[1] != NULL && chdir(words[1]) < 0) {
			printf("path %s does not exist\n", words[1]);
		} else {
			getcwd(path, sizeof(path));
			printf("current path: %s\n", path);
		}
		break;
	}
	case 4: // help
	case 15: // ?
		printf(
			"    get {file} - get file\n"
			"    cd {path} - change local path\n"
			"    help - read this\n"
			"    listen - wait for incoming connections\n"
			"    ls - list local files\n"
			"    connect [server/ip] - connect to server\n"
			"    port # - use given port number\n"
			"    type [message] - send short message\n"
			"    quit/exit - stop the server\n"
			);
		break;
	case 5: // get
		PknftCommandStr(PknftCmdGet, command+4);
		break;
	case 6: // listen
		PknftCommandStr(PknftCmdListen, NULL);
		break;
	case 7: // close
	case 13: // disconnect
		PknftCommandStr(PknftCmdDisconnect, NULL);
		break;
	case 8: // connect
	case 9: // open
		PknftCommandStr(PknftCmdConnect, words[1]);
		break;
	case 10: // port
	{
		int port;
		if (words[1] == NULL
			|| (port = atoi(words[1])) < 0
			|| port > 65535) {
			printf("Port must be 0-65535");
		}
		else {
			if (port < 1024)
				printf("Warning: May not be allowed to bind to ports 0-1023\n");
			PknftSetVar(PknftSetPort, port);
			printf("Will use port %d\n",port);
		}
		break;
	}
	case 11: // type
	case 14: // chat
		PknftCommandStr(PknftCmdChat, command+5);
		break;
	case 12: // put file
		PknftCommandStr(PknftCmdPut, command+4);
		break;
	case 16: // ls
	{
		pid_t child = fork();
		if (child == 0) {
			execlp("ls", words[0],words[1],words[2],words[3],words[4],NULL);
		}
		else if (child > 0) {
			waitpid(child, &child, 0);
		}
		break;
	}
	default:
		printf("Invalid command\n");
		break;
	}
}
		
////////////////////////////////////////////////////////////////////////////////
// Checks for and responds to any server notifications, including printing any
// status message.
//
// accepts:	[PknftPout]
// returns:	1 if notification arrived
//			0 if none were pending
static int CheckServerNotifications() {
	int pending=0;
	PknftPipeMsg poutbfr;

	while (true) {
		ioctl(PknftPout[0], FIONREAD, &pending);
		//printf("bytes pending=%d\n", pending);
		if (pending <= 0) return 0;
		pending = read(PknftPout[0], &poutbfr,sizeof(poutbfr.Hdr));
		if (pending <= 0) return 0;
		// The rest of the message MUST be read,
		// even if we don't recognize or care about it.
		// This is essential for synchronization.
		if (poutbfr.Hdr.len > 0)
			read(PknftPout[0], &poutbfr.msg,poutbfr.Hdr.len);

		ErasePrompt();
		printf(" ");
		switch (poutbfr.Hdr.cmd) {
		case PknftCmdStatus:
		{
			printf("%s\n", poutbfr.msg);
			break;
		}
		default:
			printf("unrecognized server notification\n");
		}
	}
	return 1;
}

////////////////////////////////////////////////////////////////////////////////
// Erases the half typed user command in preparation for another string to
// overwrite it.
//
// accepts:	[reprompt]
// returns:	[reprompt]
static void ErasePrompt() {
	char spaces[80];
	int idx = sizeof(spaces)-1;

	if (reprompt) return;
	reprompt = true;

	// erase any existing prompt on screen
	spaces[sizeof(spaces)-1] = '\0';
	while (idx > 0) spaces[--idx] = 8;
	printf(spaces);
	fflush(NULL);
}

////////////////////////////////////////////////////////////////////////////////
// Reads all pending characters from the keyboard into the command buffer.
// Executes the command if Enter is pressed.
//
// accepts:	[command, cmdsize]
// returns:	none
static void ReadPrompt() {
	int pending=0;
	char c;

	ioctl(0, FIONREAD, &pending);
	///printf("key chars=%d\n", pending);
	while (--pending >= 0) {
		read(0, &c, 1);
		if (c == '\b' && cmdsize > 0) {
			cmdsize--;
			write(1, "\b \b", 3);
		}
		else if (c >= ' ' && cmdsize < sizeof(command)-1) {
			command[cmdsize++] = c;
			write(1, &c, 1);
		}
		else if (c == '\n') {
			reprompt = true;
			command[cmdsize] = '\0';
			write(1, &c, 1);
			DoCommands(command);
			cmdsize = 0;
		}
	}
}
