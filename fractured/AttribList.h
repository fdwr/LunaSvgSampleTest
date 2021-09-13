/**
\file	AtrbList.h
\author	Dwayne Robinson
\since	2003-06-10
\date	2006-04-06
*/

#pragma once
#include "commctrl.h" // need imagelist

#ifdef __STDC__
#define _C_
#endif
#ifdef __cplusplus
#define _C_
#endif
#ifdef _MSC_VER
#define _C_
#endif
//#else __NASM__ ...

#ifdef _C_
////////////////////////////////////////////////////////////////////////////////
// Attribute List defs

#pragma pack(push, 1)     // for byte alignment

#ifdef  UNICODE
#define AttribListClass L"AttribList"
#define AttribOverlayClass L"AttribOverlay"
#else
#define AttribListClass "AttribList"
#define AttribOverlayClass "AttribList"
#endif

struct AttribListItem
{
	union FloatInt {
		int i; float f;
		FloatInt() {};
		FloatInt(float f_) : f(f_) {};
		FloatInt(int i_) : i(i_) {};
	};

	unsigned int flags;	/// misc item flags indicating type, options, and id
	LPTSTR label;		/// name of attribute
	LPTSTR text;		/// value string
	LPTSTR description;
	unsigned int icon;	/// index of icon in image list

	FloatInt value; /// current value
	FloatInt def; /// default value
	FloatInt low; /// low value
	FloatInt high; /// high value
};

//#ifndef ATTRIBLIST_CPP
struct AttribListMetrics;
//#endif

class AttribList {
public:
	HWND hwnd;

private:
	unsigned int total; //total attribute items (including disabled and separators)
	unsigned int selected; // item that keyboard selected
	unsigned int hovered; // item that mouse is over
	unsigned int top; // item at scroll top
	HIMAGELIST himl; //handle to prefilled image list
	AttribListItem* alis; //array of attribute list items

public:
	AttribList(HWND hwnd_);
	static LRESULT __stdcall AttribListProc(HWND hwnd, UINT message, long wParam, long lParam);
	static LRESULT __stdcall AttribOverlayProc(HWND hwnd, UINT message, long wParam, long lParam);
	static HMENU AttribListToMenu(AttribListItem* ali);

	////////////////////////////////////////
	// Attribute List messages

	enum
	{
		WnClicked=0<<16,	// button was clicked, toggle, or new choice
		WnContext=1<<16,	// context menu opened (lParam is actually menu handle, not self)
		WnChoices=2<<16,	// choice menu opened 
		WmSetItems=WM_USER+10,
		WmGetItems=WM_USER+11,
	};

	enum // menu commandidentifiers
	{
		IDAL_PASTE=256, // paste text into edit
		IDAL_COPY, // copy item text or label
		IDAL_COPYALL, // copy all text in attribute list
		IDAL_CLEAR, // clear text from edit
		IDAL_COMMAND, // do button command
		IDAL_TOGGLE,  // switch toggle value
		IDAL_HELP, // get help on selected item
		IDAL_MAX=300 // no IDs will be above this
	};

	enum {SelectByPos=1<<31};

	////////////////////////////////////////
	// Item Flags
	enum
	{
		FlagIdMask=0x0000FFFF, /// lower 16 bits

		TypeShl=16,
		TypeMask=0x7<<TypeShl, /// 3 bits allow 8 types
		//TypeSeparator=0<<19, /// blank space between items
		FlagTitle=1<<TypeShl, /// main list title bar or section divider
		FlagEditable=2<<TypeShl, /// editable text prompt
		FlagPushable=4<<TypeShl, /// simple push button (or checked toggle button)
		FlagNumeric=8<<TypeShl, /// text is numeric (derived from value)
		FlagDecimal=16<<TypeShl, /// use floating point rather than integer
		FlagMenu=32<<TypeShl, /// text is a list, each null separated (double null ends)

		// ... other future types ...
		// file
		// color
		// folder

		FlagDisabled=1<<22, /// item shown grayed but not selectable or editable
		FlagHidden=1<<23, /// item hidden and neither shown nor selectable
		FlagRedraw=1<<24, /// item needs redrawing next WM_PAINT

		FlagNoImage=1<<25,
		FlagIdPlusValue=1<<26, /// offset the id by toggle/menu value (so id+.val)
		FlagNoColon=1<<27, /// no separating colon between name and value
		//FlagCopyStrings=1<<27, /// duplicate an AttribListItem's strings internally (in case they were passed as autos)

		TypeButton=FlagPushable,
		TypeTitle=FlagTitle|FlagDisabled,
		TypeSeparator=FlagDisabled,
		TypeNumeric=FlagNumeric,
		TypeEdit=FlagEditable,
		TypeMenu=FlagMenu,
		TypeLabel=FlagDisabled,
	};

#ifdef ATTRIBLIST_CPP
private:
	LRESULT __stdcall AttribListSubproc(HWND hwnd, UINT message, long wParam, long lParam);
	LRESULT __stdcall AttribOverlaySubproc(HWND hwnd, UINT message, long wParam, long lParam);
	int __stdcall IdToItem(unsigned int item);
	int __stdcall Seek(unsigned int from, int distance, int activeonly);
	int __stdcall Select(unsigned int newitem);
	int __stdcall SelectGiven(unsigned int newitem, unsigned int options);
	void __stdcall SetCaretX(unsigned int newpos);
	void __stdcall DeleteChar();
	void __stdcall InsertChar(unsigned int newchar, unsigned int bufSize);
	void __stdcall SendClickCommand(int index);
	void __stdcall ActivateNearestButton();
	int __stdcall GetSelectedFlags(unsigned int* flags);
	int __stdcall GetHoverRect(int y);
	int __stdcall GetItemRow(unsigned int item, unsigned int top);
	int __stdcall GetItemRect(unsigned int item, int y, RECT* rect);
	void __stdcall GetItemMetrics(AttribListMetrics& alm);
	void __stdcall ScrollBy(int rows, long flags);
	void __stdcall Scroll(int rows, AttribListMetrics& alm);
	void __stdcall SetScrollBars(AttribListMetrics& alm);

	void __stdcall RedrawTitles();
	void __stdcall PostRedraw();
	void __stdcall PostRedrawOverlay();
	void __stdcall Resize();
	int __stdcall ResizeOverlay();

	LPTSTR __stdcall GetChoiceText(int index);
	static int AppendString(HGLOBAL *hmt, TCHAR* text);

	void ShowContextMenu(unsigned int item, int x,int y);
	void ShowSelectedChoiceMenu();
	void ShowGivenChoiceMenu(unsigned int item, int x,int y);
	void SetSelectedButtonValue(int value, int relative);
	//-unsigned int TotalChoices(TCHAR* text);
	//-__inline unsigned int ReverseRGB (unsigned int rgb);
	//-__inline unsigned int abs_(signed int n);
#endif
};

/*
#pragma warning(disable: 4200) // nonstandard extension used : zero-sized array in struct/union
typedef struct
{
	unsigned int total; //total attribute items (including disabled and separators)
	unsigned int selected; //currently selected item
	unsigned int top; //item at scroll top
	HIMAGELIST himl; //handle to prefilled image list
	AttribListItem al[]; //array of attribute list items
} AttribListItems;
*/

#ifndef LB_OKAY // for LCC
#define LB_OKAY             0
#endif

#pragma pack(pop)     // no more byte alignment


#ifndef ATTRIBLIST_CPP
extern "C" WNDCLASSEX wcAttribList;
extern "C" WNDCLASSEX wcAttribOverlay;
//extern "C" HMENU AttribListToMenu(AttribList* al);
#endif


#else // assembler

////////////////////////////////////////////////////////////////////////////////
// Attribute List messages

ALN_CLICKED equ 0<<16	;button was clicked, toggle, or new choice
ALN_CONTEXT equ 1<<16	;context menu opened (lParam is actually menu handle, not self)
ALN_CHOICES equ 2<<16	;choice menu opened

IDAL_PASTE equ 256	; paste text into edit
IDAL_COPY equ 257	; copy item text or label
IDAL_COPYALL equ 258; copy all text in attribute list
IDAL_CLEAR equ 259	; clear text from edit
IDAL_COMMAND equ 260; do button command
IDAL_TOGGLE equ 261	; switch toggle value
IDAL_HELP equ 262	; get help on selected item
IDAL_MAX equ 300	; no IDs will be above this

////////////////////////////////////////////////////////////////////////////////
// Attribute List defs

struc AttribListItem
.flags:		resd 1	; misc item flags indicating type, options, and id
.icon:		resd 1	; index of icon in image list
.label:		resd 1	; text description
.text:		resd 1	; value string
endstruc

struc AttribList
.total:		resd 1	; total attribute items (including disabled and separators)
.selected:	resd 1	; currently selected item
.top: 		resd 1	; item at scroll top
.himl:		resd 1	; handle to prefilled image list
.al:				; array of attribute list items
endstruc

AlfIdMask equ 0x0000FFFF

AlfDisabled equ 1<<16	; item shown grayed but not selectable or editable
AlfHidden equ 1<<17		; item hidden and neither shown nor selectable
AlfRedraw equ 1<<18		; item needs redrawing next WM_PAINT

AlfTypeMask equ 0x00380000	; 3 bits allow 8 types
AlfTypeRs equ 19
AlfSeparator equ 0<<19	; blank space between items
AlfTitle equ 1<<19		; main list title bar or section divider
AlfEdit equ 2<<19		; editable text prompt
AlfButton equ 3<<19		; simple push button
AlfToggle equ 4<<19		; toggle button with checked/unchecked
AlfMenu equ 5<<19		; multichoice menu
AlfLabel equ 6<<19		; filename prompt

; toggle and menu types
AlfNoCheckImage equ 1<<22
AlfChecked equ 1<<24	;button is checked
AlfCheckedRs equ 24
AlfCheckedMask equ -1<<24	; FF000000h

; edit type
AlfNumeric equ 1<<22	;text edit accepts numbers only
AlfLengthRs equ 24		;for text edit, tells maximum length
AlfLengthMask equ -1<<24

AlfTitleType equ AlfTitle|AlfDisabled
AlfSeparatorType equ AlfSeparator|AlfDisabled

#define AlfMenuValue(value) (value<<AlfCheckedRs)
AttribListById equ 1<<31

#endif // assembler

#ifndef LB_OKAY // for LCC
#define LB_OKAY             0
#endif
