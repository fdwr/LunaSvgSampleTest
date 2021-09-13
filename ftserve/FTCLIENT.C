////////////////////////////////////////////////////////////////////////////////
// ftclient.c - Linux command
//
// A very simplified version of the program that just sends a given file to a
// client. It has no interface and supports no command processing. All 
// arguments are passed via the command line.
//
// 

#include <stdio.h>
#include <sys/ioctl.h>
#include <sys/time.h>
#include "pknft.h"

static void CheckServerNotifications();

//-----------------------------------------------------------------------------

#define ProgVersion "1.0"
#define CommandLenMax 256
#define CommandWordsMax 5
enum {false, true};

extern int PknftPout[2]; // pipe into thread, commands

//-----------------------------------------------------------------------------

char commands[] = {"exit\0" "quit\0" "q\0" "cd\0" "get\0" "help\0" "listen\0" 
					"close\0" "connect\0" "open\0" "port\0" "\0"};

int main (int argc, char* argv[])
{
	//pthread_t tid;
	char command[CommandLenMax];
	char *words[CommandWordsMax];
	struct timeval timeout;
	int cmdsize;
	int alive = true;
	int port;
	char c;

	//int clientsock;
	//int retval;
	//fd_set fds; // removed because test script caused select to not work right

	if (argc != 2
	|| ((port = atoi(argv[1])) <= 1024)
	||  port > 65535) {
		printf("PknFt Server " ProgVersion "\nUsage: ftserve (port 1024-65535)\n");
		exit(1);
	}

	printf("PknFt Server " ProgVersion "\nReady, type 'help' for command list\n");

	PknftInit();
	PknftSetVar(PknftSetPort, atoi(argv[1]));
	printf("Will use port %d\n",atoi(argv[1]));

	while (alive) {
		printf(":>");
		cmdsize = 0;
		while ((c = getchar()) != '\n') {
			if (c >= 32 && cmdsize < sizeof(command)-1) {
				command[cmdsize++] = c;
				//putchar(input);
			}
		}
		command[cmdsize] = '\0';

		CheckServerNotifications();

		if (strparse(command, words, CommandWordsMax) <= 0) continue;

		switch( strmatch(words[0], commands) ) {
		case 0:
		case 1:
		case 2:
			alive = false;
			break;
		case 3:
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
		case 4:
			printf(
				"    get {file} - get file\n"
				"    cd {path} - change local path\n"
				"    help - read this\n"
				"    port # - use port number\n"
				"    quit/exit - stop the server\n"
				);
			break;
		case 5:
			printf("not implemented :(\n");
			break;
		case 6:
			PknftCommandStr(PknftCmdListen, NULL);
			break;
		case 7:
			PknftCommandStr(PknftCmdDisconnect, NULL);
			break;
		case 8:
		case 9:
			PknftCommandStr(PknftCmdConnect, words[1]);
			break;
		case 10:
		{
			int port;
			if (words[1] == NULL
			  || (port = atoi(words[1])) < 1024
			  || port > 65535) {
				printf("Port should be 1024-65535");
			} else {
				PknftSetVar(PknftSetPort, port);
				printf("Will use port %d\n",port);
			}
			break;
		}
		default:
			printf("Invalid command\n");
			break;
		}
		CheckServerNotifications();
	}
	PknftCommandStr(PknftCmdExit, NULL);
	PknftFree();

	printf("terminated server\n");
}

static void CheckServerNotifications() {
	int count;
	PknftPipeMsg poutbfr;

	while (true) {
		ioctl(PknftPout[0], FIONREAD, &count);
		//printf("count=%d\n", count);
		if (count <= 0) break;
		count = read(PknftPout[0], &poutbfr,sizeof(poutbfr.Hdr));
		if (count <= 0) break;
		if (poutbfr.Hdr.len > 0)
			read(PknftPout[0], &poutbfr.msg,poutbfr.Hdr.len);
		printf("%s\n", poutbfr.msg);
	}
}
