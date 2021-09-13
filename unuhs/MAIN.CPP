////////////////////////////////////////////////////////////////////////////////
// UnUHS decrypts UHS (game help) files

////////////////////////////////////////////////////////////////////////////////
// header files
#include <windows.h>
#include <stdio.h>
#include <richedit.h>
//#include <string.h>
#include "resource.h"

////////////////////////////////////////////////////////////////////////////////
// function prototypes

CALLBACK DialogProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);
char* GetOpenFileName();
int ReadUhsFile(LPSTR lpCmdLine);
int ReadFileData(char* filename, int parser(char* data, int size, void* param), void* param);
int ParseUhsFile(char* text, int size, char* filename);
char* ParseFile_NextLine(char* data);
char* ParseFile_NextNumber(char* data);
void WriteText(LPSTR start, LPSTR end);
void SetCharFormat(CHARFORMAT* cf);

void InitUhsDecryptionTables();
void DecryptUhsHint(LPSTR text);

extern "C" int strmatchn(const char *strng, const char *matches);

////////////////////////////////////////////////////////////////////////////////
// global vars

HWND mainHwnd, editHwnd;
LPSTR uhsFilename = NULL;

unsigned char UhsDecryptionTable[256];

////////////////////////////////////////////////////////////////////////////////
// code

//int main(int argc, char ** argv) {
int __stdcall WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow) {
	uhsFilename = lpCmdLine;
	LoadLibrary("RICHED32.DLL");
	InitUhsDecryptionTables();
	DialogBox(GetModuleHandle(NULL), MAKEINTRESOURCE(IDD_UNUHS), NULL, DialogProc);
	return 0;
}

CALLBACK DialogProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam) {
	switch (uMsg) {
	case WM_INITDIALOG:
		DefWindowProc(
			hwnd,
			WM_SETICON,
			TRUE,
			(LPARAM) LoadIcon(GetModuleHandle(NULL), MAKEINTRESOURCE(IDI_UNUHS))
		);
		mainHwnd = hwnd;
		editHwnd = GetDlgItem(mainHwnd, IDC_UhsText);

		// read file from command line
		if (lstrlen(uhsFilename) > 0) {
			if (ReadUhsFile(uhsFilename) <= 0)
				return -1;
		}
		else {
		// or request using open dialog
			uhsFilename = GetOpenFileName();
			if (uhsFilename != NULL)
				ReadUhsFile(uhsFilename);
		}

		return TRUE;
		//break;
	case WM_COMMAND:
		switch (wParam) {
		case ID_OPEN:
		{
			char* filename = GetOpenFileName();
			if (filename != NULL)
				ReadUhsFile(filename);
			break;
		}
		case ID_SAVE:
			break;
		case ID_COPY:
			SendMessage(editHwnd, WM_COPY, 0,0);
			break;
		}
		break;
	case WM_CLOSE:
		EndDialog(hwnd, 0);
	}
	return FALSE;
}


int ReadUhsFile(LPSTR filename) {
	int status = 
		ReadFileData(filename, (int (__cdecl *)(char *,int,void *))ParseUhsFile, filename);

	if (status <= 0) {
		MessageBox(NULL, "Could not open the given file :-/", "UnUHS", MB_OK);
	} else {
		char title[256], fullpath[MAX_PATH];
		char *dummy;
		GetFullPathName(filename, MAX_PATH, fullpath, &dummy);
		sprintf(title, "UnUHS - %3s", fullpath);
		SetWindowText(mainHwnd, title);
	}

	return status;
}


// Prompts user the UHS file
char* GetOpenFileName() {
	char static filename[MAX_PATH];
	static OPENFILENAME ofn = {
		sizeof(OPENFILENAME),
		NULL,GetModuleHandle(NULL),
		"UHS Files (*.uhs)\0*.uhs\0All files (*.*)\0*.*\0\0",
		NULL,0,1,
		filename,MAX_PATH,
		NULL,0,
		".", // current directory
		"Select data file to open",
		OFN_EXPLORER|OFN_FILEMUSTEXIST|OFN_HIDEREADONLY|OFN_PATHMUSTEXIST|OFN_ENABLESIZING,
		0,0,"uhs",
		0,NULL,NULL
	}; 
	filename[0]='\0';
	ofn.hwndOwner=mainHwnd;

	if (!GetOpenFileName(&ofn)) {
		return NULL;
	}
	return filename;
}


// Reads entire file into memory and parses from there
//
// In:  file - string path and name
//		parser - function that handles text data
// Out: returns TRUE for success
int ReadFileData(char* filename, int parser(char* data, int size, void* param), void* param) {
	HANDLE fh;	// file handle
	DWORD fp;	// file pointer
	HGLOBAL fm;	// file memory block
	DWORD status = FALSE;

	// attempt to open
	fh = CreateFile(filename, GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_FLAG_SEQUENTIAL_SCAN, NULL);
	if (fh != INVALID_HANDLE_VALUE) {

		// check file length
		fp = SetFilePointer(fh, 0, NULL, FILE_END); // set to file end just to get size
		//if (fp < 1048576*32) { // abort on ridiculously large file
		SetFilePointer(fh, 0, NULL, FILE_BEGIN); // restore to front of file

		// allocate block of memory
		fm = GlobalAlloc(GMEM_FIXED, fp+1);
		if (fm != NULL) {

			// whole file in (since small enough to)
			if (ReadFile(fh, (char*)fm, fp, &status, NULL)) {
				*((char*)fm+fp) = 0; // tack null char

				parser((char*)fm, fp, param);
				status = TRUE;
			}
			GlobalFree(fm);
		}
		CloseHandle(fh);
	}

	return status;
}


// Parses in memory scene file of object filenames.
// Can recurse and include scene files within scene files.
//
// In:  data - text file in memory
// Out: text written to edit control
int ParseUhsFile(char* text, int size, char* filename) {
	enum {mode_none, mode_text1, mode_text2, mode_question, mode_hint};
	int mode = mode_none;
	int match;
	bool rehyphenate = false;
	char* next;		// next line or word or whatever needed
	CHARFORMAT cf = { 
		sizeof(CHARFORMAT), // cbSize
		//0, // _wPad1
		CFM_COLOR, //dwMask
		0, //dwEffects
    	0, //yHeight
    	0, //yOffset
		0x0000FF, //crTextColor
    	0, //bCharSet
    	0, //bPitchAndFamily
    	0, //szFaceName[LF_FACESIZE]
    	//0, //_wPad2
	};

	SendMessage(editHwnd, WM_SETTEXT, 0, (LPARAM)"");
	SendMessage(editHwnd, EM_SETBKGNDCOLOR , FALSE, (LPARAM)0xA45C5C);
	SendMessage(editHwnd, WM_SETREDRAW, FALSE, (LPARAM)0);

	while (*text) {
		next = ParseFile_NextLine(text);
		switch (mode) {
		case mode_none:
			text = ParseFile_NextNumber(text);

			// depending on the word following the number,
			// determine the next mode
			match = strmatchn(text,
				"hint\0"	//0
				"subject\0"	//1
				"comment\0"	//2
				"credit\0"	//3
				"version\0"	//4
				"link\0"	//5
				"blank\0"	//6
				"text\0"	//7
				"nesthint\0"//8
				"\0");
			switch (match) {
			case 2: // comment
			case 3: // credit
			case 4: // version
			case 5: // link
				mode = mode_text1;
				break;
			case 7: // text
				mode = mode_text1;
				break;
			case 6:	// blank
				next = ParseFile_NextLine(next);
				break;
			case 1: // subject
				mode = mode_text2;
				break;
			case 0: // hint
			case 8: // nesthint (not actually implemented)
			default:
				mode = mode_question;
				break;
			}
			cf.crTextColor = 0xFFFFFF;
			SetCharFormat(&cf);
			//WriteText(text, next); // don't print word
			WriteText(next-2, next); // just print new line
			break;
		case mode_text1:
			cf.crTextColor = 0x00FFFF;
			SetCharFormat(&cf);
			WriteText(text, next);
			mode++;
			break;
		case mode_question:
			cf.crTextColor = 0x00FF00;
			SetCharFormat(&cf);
			WriteText(text, next);
			mode++;
			rehyphenate = true;
			break;
		case mode_hint:
			cf.crTextColor = 0xFFFF00;
			SetCharFormat(&cf);
			SendMessage(editHwnd, EM_REPLACESEL, FALSE, (LPARAM) ((rehyphenate) ? "- " :  "  "));
			rehyphenate = false;
			DecryptUhsHint(text);
			// decrypt text
			//break; // fall through
		case mode_text2:
			WriteText(text, next);
			if (*next == '=') {
				//text = ParseFile_NextLine(next);
				//WriteText(next, text);
				text = ParseFile_NextNumber(ParseFile_NextLine(next));
				match = strmatchn(text,
					"link\0"	//1
					"\0");
				switch (match) {
				case 0: // link
					next = ParseFile_NextLine(
							ParseFile_NextLine(
							 ParseFile_NextLine(text)));
					break;
				default:
					mode = mode_none;
					break;
				}
			}
			if (*next == '-') {
				//text = ParseFile_NextLine(next);
				//WriteText(next, text);
				next = ParseFile_NextLine(next);
				rehyphenate = true;
			}
			//else if (*next >= '0' && *next <= '9' && *ParseFile_NextLine(next) != '-') {
			else if (*next >= '0' && *next <= '9' && *next != '-') {
				mode = mode_none;
			}
			break;
		}
		text = next;
	}
	SendMessage(editHwnd, EM_SETSEL, -1, (LPARAM)0);
	SendMessage(editHwnd, WM_SETREDRAW, TRUE, (LPARAM)0);
	InvalidateRect(editHwnd, NULL, TRUE);
	return TRUE;
}


void SetCharFormat(CHARFORMAT* pcf) {
	SendMessage(
		editHwnd,
		EM_SETCHARFORMAT,
		(WPARAM)SCF_SELECTION,
		(LPARAM)pcf
	);
}


// returns ptr to next line
char* ParseFile_NextLine(char* data) {
	char c;
	while (c = *data, c != '\r' && c != '\n' && c != '\0') data++;
	while (c = *data, c == '\r' || c == '\n') data++;
	return data;
}


// writes text to edit control
void WriteText(LPSTR start, LPSTR end) {
	char c = *(end);
	*(end) = '\0';
	SendMessage(editHwnd, EM_REPLACESEL, FALSE, (LPARAM)start);
	*(end) = c;
}

// returns ptr to next number after any separators
char* ParseFile_NextNumber(char* data) {
	char c;
	while (c = *data, (c >= '0' && c <= '9') || c == '.' || c == '-') data++;
	while (c = *data, c == ' ' || c == ',' || c == '/' || c == '\t') data++;
	return data;
}


void InitUhsDecryptionTables() {
	int i;
	unsigned char UhsDecryptionPairs[] = {

	//lwz {wGSJ Ar pAFr Jw JpFu Jw DrI CwI p FwGs {DtFr'
	//You won't be able to talk to her for a long while.
	//-
	//1zJ |wz qpG pJ FrpyJ JI| Jw srJ tGJw JDr qpyJFr Jw CtGB wzJ {DrIr yDr ty'
	//But you can at least try to get into the castle to find out where she is.
	//-
	//:Dr szpIB Bwsy {tFF wGF| FrJ |wz JDIwzsD tC |wz qpG HIwKr |wzSIr Iw|pFJ|'
	//The gaurd dogs will only let you through if you can prove you're royalty.
	//6wwu pIwzGB JDr ArpqD CwI HIwwC'
	//Look around the beach for proof

		' ',' ',
		'!','"',
		'"','$',
		'#','&',
		'$','(',
		'%','*',
		'&',',',
		'\'','.',
		'(','0',
		')','2',
		'*','4',
		'+','6',
		',','8',
		'-',':',
		'.','<',
		'/','>',
		'0','@',
		'1','B',
		'2','D',
		'3','F',
		'4','H',
		'5','J',
		'6','L',
		'7','N',
		'8','P',
		'9','R',
		':','T',
		';','V',
		'<','X',
		'=','Z',
		'>','\\',
		'?','^',
		'@','`',
		'A','b',
		'B','d',
		'C','f',
		'D','h',
		'E','j',
		'F','l',
		'G','n',
		'H','p',
		'I','r',
		'J','t',
		'K','v',
		'L','x',
		'M','z',


		'P','!',
		'Q','#',
		'R','%',
		'S','\'',
		'T',')',
		'U','+',
		'V','-',
		'W','/',
		'X','1',
		'Y','3',
		'Z','5',
		'[','7',
		'\\','.',


		'_','?',
		'`','A',
		'a','C',
		'b','E',
		'c','G',
		'd','I',
		'e','K',
		'f','M',
		'g','O',
		'h','Q',
		'i','S',
		'j','U',
		'k','W',
		'l','Y',
		'm','[',
		'n',']',
		'o','_',
		'p','a',
		'q','c',
		'r','e',
		's','g',
		't','i',
		'u','k',
		'v','m',
		'w','o',
		'x','q',
		'y','s',
		'z','u',
		'{','w',
		'|','y'
/*
		' ',' ',
		'!','\"',
		'$','(',
		'&',',',
		':','T',
		';','V',
		'\'','.',
		'_','?',
		'`','A',
		'{','w',
		'|','y',
		'<','X',
		'=','Z',
		'>','\\',
		'?','^',
		'@','`',
		'*','4',
		'+','6',
		',','8',
		'-',':',
		'.','<',
		'/','>',
		'0','@',
		'1','B',
		'2','D',
		'3','F',
		'4','H',
		'5','J',
		'6','L',
		'7','N',
		'8','P',
		'9','R',
		'A','b',
		'a','C',
		'B','d',
		'b','E',
		'C','f',
		'c','G',
		'D','h',
		'd','I',
		'E','j',
		'e','K',
		'F','l',
		'f','M',
		'G','n',
		'g','O',
		'H','p',
		'h','Q',
		'I','r',
		'i','S',
		'J','t',
		'j','U',
		'K','v',
		'k','W',
		'L','x',
		'l','Y',
		'M','z',
		'm','[',
		'n',']',
		'o','_',
		'p','a',
		'q','c',
		'r','e',
		'S','\'',
		's','g',
		'T',')',
		't','i',
		'u','k',
		'U','+',
		'V','-',
		'v','m',
		'W','/',
		'w','o',
		'x','q',
		'y','s',
		'z','u'
*/
	};

	unsigned char UhsDecryptionPairs2[] = {
	// Used for nesthint, which apparently uses a more complex
	// substitution or formula that considers previous characters.
	// Meh, don't want to figure it out...
	//
	//e%^iY*5szi|Koo%0yf[!.ilo38sxpuG1}, ">@)Gy*gI#C0y /Q:iPqPFv<-(@;L!2
	//Visit your Aunt. The Save Game spot is situated on the first floor.
	//
	//e%^iY*0ljwdyotv"gwT..*s^N,--h"5:AO{c~;46Rmz&F3D#~2#LRv5~JIhHZ#FEk
	//Visit the house near the tavern. Accept the quest to rescue Mary.
	//
	//b$P'X*%r%kdozg t^%gJ.oznN{-%*$Gq/"}r9D%*j%)nD3Fx8
	//She's in the forest. You can't enter yet, though.
	//
	//V+ktT*0ljw]l[ouqgwW<{y^Ny2+h"Gn6'!n K!6*t#mH5N"n@
	//Go to the abandoned mine after buying a Longsword.
	//
	//V+kt\y<whiaoht1gZ%gJ
	//Go two screens east.
	//
	//V+ksF !$y_a*av*"b s0v{+Z0y:{r~,pA{!n~Y@oMz5}>*K0x!&]>i1}UTr.-6<1]ReEvgi.y?
	//v1d ^y1$w\omofu"p{_(.}to38E&x0(,4q*o%7N
	//Go save the guy in the abandoned mine. You will now learn of the Cast. The
	//guy you rescued will give you a scroll.
	//
	//c$Pneq+$yf|~bf
	//Then go to the
	//
	//c$Pnq*#s%kk*niv
	//Then, go to the
	//
	//R+^tX*N4%^kv^/
	//Costs 20 gold.
	//
	//R}Y Go<ftlcrn!vx^$l3v{}^N1;,#s(zAp-y9,@"Ms|yL-Qt8
	//Can be bought everywhere you can buy a longsword.

		//'','', <- room for expansion, in case I missed any
		//'','',
		//'','',
		//'','',
		'V','G'
	};


	for (i=0; i<256; i++) {
		UhsDecryptionTable[i] = i;
	}
	for (i=0;
		 i< (sizeof(UhsDecryptionPairs) / sizeof(char));
		 i+=2) {
		UhsDecryptionTable[UhsDecryptionPairs[i]] = UhsDecryptionPairs[i+1];
	}
}

// decrypts the simple letter substitution
void DecryptUhsHint(LPSTR text) {
	unsigned char c;
	while (true) {
		c = *text;
		switch (c) {
		case '\r':
		case '\n':
		case '\0':
			return;
		default:
			*text = UhsDecryptionTable[c];
			//*text = ((c-16)<<1) & 127; ??
			//*text = ((127-c)<<1) & 127; ??
			text++;
		}
	}
}
