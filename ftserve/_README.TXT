PknFt Server
Dwayne Robinson
(c) 2004 PikenSoft

Overall server view:
   -Completely separate module from user interface, no dependencies.
   -Runs in a separate thread from the user interface, so that it can execute
    without holding up the user's typed commands or typed commands.
   -Built upon compatible Berkeley sockets, meaning it can be compiled for
    Unix, Linux, or Windows.
   -Uses its own protocol that can send arbitrary binary data streams.
    Currently it only supports only file and text streams, but it will be
    expanded to include audio, video, and remote clipboard objects.
   -All streams can be safely interleaved.

Executable files:
    PknFtw.exe - compiled for Windows (95 to XP)
    ftserve_linux - compiled for Flip
    ftserve_sparc - compiled for Flop

Use:
    There is no client version. The server and client are the same program.
    Before a connection is made, one end must be in listening mode, and the
    other should then connect to the listener. Once connected, you can
    transfer files either direction and send small text messages.

    The Windows version is fairly intuitive:
        On one, click listen.
        On the other, type the server address, and click connect.
        The type choose File|Put to send a file.

    For the Unix version:
        On one, type 'ftserve listen'
        On the other, type 'ftserve connect flip.engr.orst.edu'
        Then type 'put filename'

        You can type commands either on the command line, or inside
        the prompt.

Compiling:
    Each interface has its own compiling needs.

    Linux/Unix console version: read the top of "ftserve.c".
        ftserve.c - command line user interface
        pknft.c - server core
        pknft.h - server header
        string.c - misc extra string functions

        flip:
            gcc -o ftserve_linux -lpthread ftserve.c pknft.c string.c -DOSHOST=\"Linux\"
        flop:
            gcc -o ftserve_sparc -lpthread -lxnet ftserve.c pknft.c string.c -DOSHOST="\"Sparc Unix\""

    Windows version: you can use the included project "PknFtW.dsp".
        pknftw.c - window user interface
        pknft.c - server core
        pknft.h - server header
        string.c - misc extra string functions
        PknFtW.dsp - project file
        stdafx.h - standard stuff
        stdafx.cpp - standard stuff
        pknft.rc - resource script
        resource.h - resource constants
        pknft.manifest - for XP common controls
        PknFtW.ico - icon file

Known bugs:
   -Sometimes the Windows version does not always receive the end of file
    notification, and does not close the file (you must disconnect first).
    The problem does not happen in the Linux version.

   -Really large files have data integrity problems. The first meg of both
    files is fine, then suddenly they start differing. I'm guessing that I
    somehow allowed them to become out of sync with each other.
