/**
File:	LargeCopyClass.cpp
Author:	Dwayne Robinson
Date:	20051018
Since:	20051018
Remark:	Partial implementation for abstract class.
		The user interface is missing for generalization.
*/

#include "LargeCopyClass.h"
#include "basictypes.h"
#include "stringex.h"
#include <vector>

#define WIN32_LEAN_AND_MEAN		// Exclude rarely-used stuff from Windows headers
#include <windows.h>
#include <windowsx.h>
#undef try		// restore what the stupid header file broke,
#undef catch	// redefining 'try' and causing unnecessary grief. 20051018


////////////////////////////////////////////////////////////////////////////////

// copying variables
unsigned long	LargeCopyClass::chunkSize = 1048576;
unsigned char*	LargeCopyClass::chunkData = null;
bool			LargeCopyClass::stillCopying;
LargeCopyInt	LargeCopyClass::fileSize; // current file's byte size
LargeCopyInt	LargeCopyClass::filePos; // current file's byte size
int				LargeCopyClass::fileIndex; // current file's index in list
int				LargeCopyClass::duplicateAction = LargeCopyClass::actions::prompt; // action upon duplicate file
int				LargeCopyClass::copyTime = 0;
char			LargeCopyClass::flush = true;

// files to copy
std::vector<TCHAR> LargeCopyClass::fileNameList; // contiguous list of names
std::vector<int>   LargeCopyClass::fileNameIdxs; // indexes to name's first character


////////////////////////////////////////////////////////////////////////////////

LargeCopyClass::startCopy(TCHAR* filePath)
{
	fileIndex = 0;
	int filesCopied = 0;
	TCHAR filePathOut[1024];

	HANDLE fileHandleIn = NULL, fileHandleOut = NULL;

	// append trailing slash to path
	// there MUST be a Windows function to do this?
	strncpyex(filePathOut, filePath, elmsof(filePathOut));
	int filePathLen = lstrlen(filePathOut);
	if (filePathLen > 0) {
		if (filePathOut[filePathLen-1] != '\\' && filePathOut[filePathLen-1] != '/') {
			filePathOut[filePathLen++] = '\\';
			filePathOut[filePathLen] = '\0';
		}
	}

	int copyTimeStart = GetTickCount();

	for (stillCopying=true; stillCopying && fileIndex < fileNameIdxs.size(); fileIndex++) {
		// open file
		// get file size
		// read big chunk
		// write big chunk

		// open next input file
		TCHAR* fileName = &fileNameList[ fileNameIdxs[fileIndex] ];
		fileHandleIn = CreateFile(fileName,
			GENERIC_READ, FILE_SHARE_READ, NULL,
			OPEN_EXISTING, FILE_FLAG_SEQUENTIAL_SCAN|FILE_FLAG_NO_BUFFERING,
			NULL);
		if (fileHandleIn == NULL) {
			continue;
		}
		FILETIME fileTimeCreated = {0,0}, fileTimeModified = {0,0};
		GetFileTime(fileHandleIn, &fileTimeCreated, null, &fileTimeModified);

		// open output file
		strncpyex(
			filePathOut+filePathLen,
			strfilename(fileName), 
			elmsof(filePathOut) - filePathLen
			);
		fileHandleOut = CreateFile(filePathOut,
			GENERIC_WRITE, FILE_SHARE_READ, NULL,
			OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL|FILE_FLAG_SEQUENTIAL_SCAN|FILE_FLAG_NO_BUFFERING,
			NULL
			);
		if (fileHandleOut == NULL) {
			CloseHandle(fileHandleIn);
			continue;
		}

		// get file size and set initial output position
		fileSize.value = 0;
		filePos.value = 0;
		fileSize.valueLow = SetFilePointer( fileHandleIn,	0,&fileSize.valueHigh, FILE_END);
		filePos.valueLow  = SetFilePointer( fileHandleOut,	0,&filePos.valueHigh,  FILE_END);

		int action = 0;
		if (filePos.value > 0) {
			if (duplicateAction == actions::prompt) {
				action = confirmAction(
					T("This file already exists partially\r\n")
					T("Do you want to replace or resume it?"),
					T("Resume\0Replace\0Skip\0Cancel\0\0")
					);
			} else {
				action = duplicateAction;
			}
		}

		switch (action) {
		case 1: // replace
			filePos.value = 0;
			// break;

		case 0: // resume
			if (action == actions::resume && filePos.value >= fileSize.value)
				break;

			// do nothing, leaving position where it is at end
			// filePos.value = end;
			// break;

			SetFilePointer(fileHandleIn,  filePos.valueLow,&filePos.valueHigh, FILE_BEGIN);
			SetFilePointer(fileHandleOut, filePos.valueLow,&filePos.valueHigh, FILE_BEGIN);

			// allocate enough memory for copy
			while (true) {
				if (chunkData == null) chunkData = (unsigned char*) GlobalAlloc(GMEM_FIXED, chunkSize+4096);
				if (chunkData != null) break;

				if (
					confirmAction(
						T("Chunk size is too large for memory too hold."),
						T("Try smaller\0Cancel\0\0")
						) == 0)
				{
					chunkSize /= 2;
				} else {
					stillCopying = false;
					break;
				}
			}
			if (stillCopying == false) break;

			fileCopyStarted();
			// copy in chunks
			{
				unsigned long ioSize = 65536*2; // size of input/output requests (variable)
				unsigned long ioTransferred; // bytes transferred
				unsigned char* chunkDataAligned = (unsigned char*) ((int)(chunkData+4095) & ~4095); // may not work with 64bit!

				while (stillCopying) {

					// read in until buffer full
					unsigned long chunkRead = 0; // number bytes in buffer filled
					while (stillCopying && chunkRead < chunkSize) {
						// normal chunk read
						int time = GetTickCount();
						ReadFile(
							fileHandleIn,
							chunkDataAligned+chunkRead,
							(chunkRead + ioSize <= chunkSize) ? ioSize : chunkSize-chunkRead,
							&ioTransferred,
							null);
						if (ioTransferred <= 0) break; // end of file (or error?)

						// adjust I/O size according to timing
						time = GetTickCount() - time;
						if (time < 500){
							if (ioTransferred == ioSize) {
								// read very short, so safely increase io transfer
								ioSize *= 2;
								if (ioSize > chunkSize) ioSize = chunkSize;
							}
						}
						else if (time > 1000) {
							// read took too long, so decrease io transfer
							ioSize /= 2;
							if (ioSize < 65536) ioSize = 65536;
						}
						chunkRead += ioTransferred;
						checkInput();
					}
					if (flush) FlushFileBuffers(fileHandleIn);

					// write out until buffer empty
					unsigned long chunkWritten = 0; // number bytes in buffer flushed
					while (stillCopying && chunkWritten < chunkRead) {
						WriteFile(
							fileHandleOut,
							chunkDataAligned+chunkWritten,
							(chunkWritten + ioSize <= chunkRead) ? ioSize : chunkRead-chunkWritten,
							&ioTransferred,
							null);
						//-ioTransferred  = (chunkWritten + ioSize <= chunkRead) ? ioSize : chunkRead-chunkWritten;
						chunkWritten  += ioTransferred;
						filePos.value += ioTransferred;
						checkInput();
					}
					if (flush) FlushFileBuffers(fileHandleOut);

					if (chunkRead < chunkSize) break; // nothing more to read
				}
			}
			SetEndOfFile(fileHandleOut);
			SetFileTime(fileHandleOut,
				(fileTimeCreated.dwLowDateTime && fileTimeCreated.dwHighDateTime) ? &fileTimeCreated : null,
				null,
				(fileTimeModified.dwLowDateTime && fileTimeModified.dwHighDateTime) ? &fileTimeModified: null);
			fileCopyStopped();

			filesCopied++;
			break;

		default:
		case 3: // cancel
			stillCopying = false;
			// break;

		case 2: // skip
			break;
		}
		CloseHandle(fileHandleIn);
		CloseHandle(fileHandleOut);
	}

	if (chunkData != null) {
		GlobalFree(chunkData);
		chunkData = null;
	}

	copyTime = GetTickCount() - copyTimeStart;
	
	stillCopying = false;
	return filesCopied;
}
