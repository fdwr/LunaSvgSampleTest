/**
File:	LargeCopyClass.h
Author:	Dwayne Robinson
Date:	20051018
Since:	20051018
Remark:	Header file for abstract class.
*/

#include <tchar.h>
#include <vector>


typedef union _LargeCopyInt {
// Same as ULARGE_INTEGER, but eliminates dependency on Windows.h
    struct {
        unsigned long valueLow; 
        signed   long valueHigh; 
    };
    __int64 value;
} LargeCopyInt;

class LargeCopyClass
{
public:
	// copying variables
	static bool stillCopying;
	static LargeCopyInt fileSize; // current file's byte size
	static LargeCopyInt filePos; // current file's byte size
	static int fileIndex; // current file's index in list
	static int duplicateAction; // action upon duplicate file
	static int copyTime;
	static char flush; // flush each chunk

	// the file data chunk
	static unsigned char* chunkData;
	static unsigned long chunkSize; // byte size of data chunks

	// files to copy
	static std::vector<TCHAR> fileNameList; // contiguous list of names
	static std::vector<int>   fileNameIdxs; // indexes to first character of name

	/// begins the copy process, returning number of files copied (skipped files not counted)
	static int startCopy(TCHAR* filePath);

	/// fills filename list from text file, open dialog selections, dropped files...
	static void getFileNames();
	/// updates controls to show new file being copied
	static void fileCopyStarted();
	/// previous file stopped
	static void fileCopyStopped();
	/// may check keyboard or message loop input
	static void checkInput();
	/// returns the number of button chosen or -1 on close
	static int confirmAction(TCHAR* message, TCHAR* actions);

	enum actions { resume, replace, skip, prompt };
};
