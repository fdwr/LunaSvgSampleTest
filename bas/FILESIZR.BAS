'1998-04-16
'Used to set the size of a file in Qbasic - file must already be open.
'
'This allows existing files to be worked on without needing to completely
'destroy them and and recreate them in 'OUTPUT' mode - which as you know
'sets the original to zero and erases everything in it. On the other hand,
'working with files in binary mode is great, but you can't lessen the size
'once they are made. They could only get bigger and bigger every time you
'added something to the end, never being able size them back down again.
'If you had a database or sprite library that was too large all fit in memory
'you just had to accept that it could only grow one way size, at least until
'now anyway. Don't you think is was sort of stupid to not include their own
'version of a simple (but useful) SetFileSize command?
DEFINT A-Z
DECLARE SUB SetFileSize (FileNum, FileSize&)

TYPE Register
  AX AS INTEGER
  BX AS INTEGER
  CX AS INTEGER
  DX AS INTEGER
  BP AS INTEGER
  SI AS INTEGER
  DI AS INTEGER
  FLAGS AS INTEGER
  DS AS INTEGER
  ES AS INTEGER
END TYPE
DIM SHARED regs AS Register

PRINT
PRINT "This program shows how set the size of an open file to anything you want"
PRINT "Press any key for a little demo..."
SLEEP: IF INKEY$ = CHR$(27) THEN END

PRINT
PRINT "Opening temporary test file '~test.tmp'"
OPEN "~test.tmp" FOR BINARY AS 1
text$ = STRING$(100, 65)
PUT 1, 1, text$

PRINT "DOS file handle:"; FILEATTR(1, 2)
PRINT "Length of file:"; LOF(1)

PRINT "Set new size to fifty..."
SetFileSize 1, 50

PRINT "New file length:"; LOF(1)

CLOSE 1
KILL "~test.tmp"

PRINT " See, it worked!"

SUB SetFileSize (FileNum, FileSize&)

'We'll need to know the actual DOS file handle, so get it using function 2
  FileHandle = FILEATTR(FileNum, 2)
 
'Set file pointer - works like Qbasic's SEEK command
'  regs.AX = &H4200     'DOS function 42h = set file pointer
'  regs.bx = FileHandle 'the true DOS file handle, not Qbasic's
'File position, the size to set the file (zero based!)
'  regs.cx = FileSize& AND &HFFFF 'get low word by ANDing file size with 65535 (filter out upper eight bits, leaving the lower eight)
'  regs.dx = FileSize& \ &H10000  'get high word by shifting it right by 65536 (shift the high part of the number eights bits down)
'  CALL interruptx(&H21, regs, regs)

  SEEK 1, FileSize& + 1'Set file position at end to keep 'FileSize&' number of bytes plus one

'Just use the Qbasic SEEK statement since it does the same thing. The DOS
'method was simply included for completeness. One note about using SEEK,
'unlike the true zero based referencing of files, Qbasic always starts at one
'with strings, arrays, and files (which can really be annoying sometimes). So,
'you will need to add to the file position one more than number of bytes you
'want to keep to the. If you wanted to keep seventy-three, set it to seventy-
'four. (actually you can set the default array size by using OPTION BASE; too
'bad you can't use it for strings and files too!)

'Truncate file to new size - here it is, the important part
  regs.AX = &H4000     'DOS function 40h = write data using file handle
  regs.BX = FileHandle 'The true DOS file handle, not Qbasic's
  regs.CX = 0          'Number of bytes to write, none, null, nada, absolute nothingness
                       'If you ask me, it's sort of a stupid way to do things.
                       'They should have a dedicated function just for setting
                       'the file size which would accept absolute and relative
                       'size adjusting, but at least it even exists!
  regs.DS = 0          'Segment of write buffer, nowheresville
  regs.DX = 0          'Offset from segment to write buffer, nadatown
                       'Since we're writing zero bytes, it does not matter what
                       'these point to, so just set them to zero. Actually you
                       'don't even need to set these last two to zero, since
                       'whatever they might already equal won't matter.
  CALL interruptx(&H21, regs, regs) 'What does actually does it

END SUB