////////////////////////////////////////////////////////////////////////////////
// Attribute List constants/structures
// 20040809

#ifdef __STDC__
#define _C_
#endif
#ifdef __cplusplus
#define _C_
#endif
#ifdef _MSC_VER
#define _C_
#endif


#ifdef _C_
////////////////////////////////////////////////////////////////////////////////
// Attribute List messages

#ifdef  UNICODE
#define AtrListClass AtrListClassW
#define AtrOverlayClass AtrOverlayClassW
#else
#define AtrListClass AtrListClassA
#define AtrOverlayClass AtrOverlayClassA
#endif

enum
{
	ALN_CLICKED=0<<16,	// button was clicked, toggle, or new choice
	ALN_CONTEXT=1<<16,	// context menu opened (lParam is actually menu handle, not self)
	ALN_CHOICES=2<<16	// choice menu opened 
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


////////////////////////////////////////////////////////////////////////////////
// Attribute List defs

#pragma pack(push, 1)     // for byte alignment
typedef struct
{
	unsigned int flags;	//misc item flags indicating type, options, and id
	unsigned int icon;	//index of icon in image list
	LPWSTR label;		//text description (Unicode)
	LPWSTR text;		//value string (Unicode)
} AttribListItem;

typedef struct
{
	unsigned int total; //total attribute items (including disabled and separators)
	unsigned int selected; //currently selected item
	unsigned int top; //item at scroll top
	HIMAGELIST himl; //handle to prefilled image list
	AttribListItem al[]; //array of attribute list items
} AttribList;

typedef enum
{
	AlfIdMask=0x0000FFFF,

	AlfDisabled=1<<16, // item shown grayed but not selectable or editable
	AlfHidden=1<<17, // item hidden and neither shown nor selectable
	AlfRedraw=1<<18, // item needs redrawing next WM_PAINT

	AlfTypeMask=0x00380000, // 3 bits allow 8 types
	AlfTypeRs=19,
	AlfSeparator=0<<19, // blank space between items
	AlfTitle=1<<19, // main list title bar or section divider
	AlfEdit=2<<19, // editable text prompt
	AlfButton=3<<19, // simple push button
	AlfToggle=4<<19, // toggle button with checked/unchecked
	AlfMenu=5<<19, // multichoice menu
	AlfLabel=6<<19, // filename prompt

	// toggle and menu types

	AlfNoCheckImage=1<<22,
	AlfChecked=1<<24, //button is checked
	AlfCheckedRs=24,
	AlfCheckedMask=-1<<24, // FF000000h

	// edit type
	AlfNumeric=1<<22, //text edit accepts numbers only
	AlfLengthRs=24, //for text edit, tells maximum length
	AlfLengthMask=-1<<24,

	AlfTitleType=AlfTitle|AlfDisabled,
	AlfSeparatorType=AlfSeparator|AlfDisabled,
};

#define AlfMenuValue(value) (value<<AlfCheckedRs)
#define AttribListById 1<<31

#ifndef LB_OKAY // for LCC
#define LB_OKAY             0
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
.label:		resd 1	; text description (Unicode)
.text:		resd 1	; value string (Unicode)
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

#endif

#ifndef LB_OKAY // for LCC
#define LB_OKAY             0
#endif
