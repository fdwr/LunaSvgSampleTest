// File: guidefs.h
// Project: CS419b HW1
// Date: 2005-04-08
// 
// Both C and assembly versions are object oriented and fully compatible with
// each other.

#ifndef guidefs_h
#define guidefs_h

#include "guioptions.h"

#ifndef _WINDOWS
#ifndef _DOS
#error "Either _DOS or _WINDOWS must be defined"
#endif
#endif

;////////////////////////////////////////
#ifdef __NASM_MAJOR__
	%define ASM
	%include "macros32.inc"

	; This below is ONLY necessary when compiling to OBJ format,
	; since NASM otherwise makes the segments 16 bit.
	; Any other format (COFF/WIN32) automatically assumes 32 bit.
	[bits 32]
	[segment .data use32]
	[segment .text use32]
	[segment .bss  use32]

	%ifdef _WINDOWS
	%define UseWindowAll
	%include "winnasm.inc"
	%endif

#else // C

	#include "basictypes.h"

	#if defined(_WINDOWS) && !defined(_WINDOWS_)
	#define WIN32_LEAN_AND_MEAN		// Exclude rarely-used stuff from Windows headers
	#include <windows.h>
	#endif

	#pragma pack(push, 1)     // let me do the packing! (for byte alignment)
#endif

#include "pgfx.h"


////////////////////////////////////////////////////////////////////////////////
// Asm structures and constants

#ifdef ASM

GuiObj:
	.null equ 1<<0,			// item does not exist, should never be sent messages (this flag is used to delete an item in a container without shifting all the others down one)
	.hidden equ 1<<1,		// does not receive draw messages because it has no visible form or is currently invisible. Hidden items are not also disabled, and can still receive any mouse or key input sent their way. This allows an item to stay invisible but appear upon mouse over.
	.mouseFocus equ 1<<2,	// cursor is currently over item or item has grabbed mouse focus
	.mouseFocusB equ 1<<2,	// bit
	.noMouseFocus equ 1<<3,	// does not receive mouse input (like a static picture or label)
	.keyFocus equ 1<<4,		// item has key focus. Note this is only set if the item currently has key focus AND its container has key focus. It is also possible to have this flag set without being active (like a temporary popup menu or tooltip)
	.keyFocusB equ 4,		// bit
	.noKeyFocus equ 1<<5,	// does not receive keyboard input (like a title bar or label)
	.allFocus equ 1<<6,		// items receive all focus messages, not just significant ones, like being the active item and losing focus or vice versa. other high level focus changes, like container or group are by default not made aware to the item.
	.groupStart equ 1<<7,	// starts a new tab group, stopping focus advancement on either this item or active group item
	.itemFocus equ 1<<8,	// item is currently active in the group (0 equ item focus, 1 equ no item focus), regardless of whether that group is active
	.groupFocus equ 1<<9,	// item is in active group (0 equ group focus, 1 equ no group focus), regardless of whether the container is active
	.containerFocus equ 1<<10,// item's container is active
	.fullFocus equ .itemFocus|.groupFocus|.containerFocus,	// if any bit is set, item does not have full focus (note: since zero is easier to test for than all ones, the flags are reversed, so all three flags zero means full focus)
	.noItemFocus equ 1<<11,	// the item is skipped when looking for the next item to receive focus (when pressing tab). Note an item CAN still receive item focus if explicitly set.
	.redrawBg equ 1<<12,		// indicates to container an item's background needs redrawing;  indicates to item that its background has been redrawn and that it must now completely redraw itself
	.redrawPartial equ 1<<13,// item needs to redraw part of itself, not neccessarily all of it
	.redrawSpecial equ 1<<14,// item specific flag (different meaning to each item)
	.redrawForced equ 1<<15,	// tells item it some other item redrew itself, forcing this one to also be redrawn
	.redrawAny equ .redrawPartial|.redrawBg|.redrawSpecial|.redrawForced,	// either part or all of the item needs redrawing
	.redrawHandled equ 1<<16,// tells container this item handles setting the redrawn update area, usually because it is a window that contains subitems, otherwise the container does it for the item
	.redrawComplex equ 1<<17,// more complex zlayered redrawing, since items may be overlapped (painter's algorithm)
	.fixedLayer equ 1<<18,	// drawing layer should never change, used by backgrounds or foreground status windows
	.fixedPosition equ 1<<19,// position should never change, used by fixed items like nonmoveable windows
	.disabled equ 1<<20,		// item can not receive either mouse or keyboard input. Unlike NoKeyFocus and NoMouseFocus which are fairly permanent attributes, Disabled may change often depending on program circumstancs.
	.importantMsgs equ 1<<21,// tells item to only send important messages (like a menu choice being chosen, not simply selected; or a tab being clicked, not simply hovered)
	.keyRecurse equ 1<<22,	//flags key focus is currently being set (to prevent recursion from messing with a previous call)

	.defFlags equ .redrawBg|.itemFocus|.groupFocus|.containerFocus

WindowObj:
	.defFlags equ GuiObj.defFlags|GuiObj.redrawHandled|GuiObj.groupStart

RootWindowObj:
	.defFlags equ WindowObj.defFlags|GuiObj.fixedLayer|GuiObj.fixedPosition

WindowBgObj:
	.defFlags equ GuiObj.defFlags|GuiObj.groupStart|GuiObj.fixedLayer|GuiObj.fixedPosition

PreviewObj:
	.defFlags equ GuiObj.defFlags

ButtonObj:
	.defFlags equ GuiObj.defFlags

AttribListObj:
	.defFlags equ GuiObj.defFlags

TitleBarObj:
	.defFlags equ (GuiObj.defFlags|GuiObj.noKeyFocus|GuiObj.allFocus)^GuiObj.itemFocus

extern _NullGuiObj
NullGuiObj equ _NullGuiObj
%ifdef PlainUseBorder
extern _BorderObjInstance // OwnerCallbackObj 
BorderObjInstance equ _BorderObjInstance
%endif

%macro DefGuiControlsStart 0
%define DefGuiObj_Container NullGuiObj
%define DefGuiObj_Border BorderObjInstance
%endmacro

%define RootWindowObjEntry ?entry@RootWindowObj@@SAHPAVGuiObj@@HUGuiMsgParams@@ZZ
%define PreviewObjEntry    ?entry@PreviewObj@@SAHPAVGuiObj@@HUGuiMsgParams@@ZZ
%define ButtonObjEntry     ?entry@ButtonObj@@SAHPAVGuiObj@@HUGuiMsgParams@@ZZ
%define AttribListObj      ?entry@AttribListObj@@SAHPAVGuiObj@@HUGuiMsgParams@@ZZ
%define TitleBarObjEntry   ?entry@TitleBarObj@@SAHPAVGuiObj@@HUGuiMsgParams@@ZZ

extern RootWindowObjEntry
extern PreviewObjEntry
extern ButtonObjEntry
extern TitleBarObjEntry
extern AttribListObjEntry

// (code,owner,flags,left,top,width,height)
%macro DefGuiObj 8
	global _%1
	global %1
_%1:
%1:
	dd %2
	%ifidni %3,default
		dd %1Callback
	%else
		dd %3
	%endif
	dd DefGuiObj_Container
	dd %4
	dw 0,0
	dw %5,%6,%7,%8
	dd DefGuiObj_Border ;NullGuiObj
	dw %5-4,%6-4,%7+8,%8+8
%endmacro

// (code,owner,flags,left,top,width,height)
%macro DefGuiObjIdx 9
	global _%1
	global %1
_%1:
%1:
	dd %2
	%ifidni %3,default
		dd %1Callback
	%else
		dd %3
	%endif
	dd DefGuiObj_Container
	dd %4
	dw 0,%9
	dw %5,%6,%7,%8
	dd DefGuiObj_Border ;NullGuiObj
	dw %5-4,%6-4,%7+8,%8+8
%endmacro

// image ptr
%macro DefPreviewObj 1
	dd %1
	dd 0, 0
%endmacro

%macro DefContainerObj 2-*
	dw %0-1					// items currently contained
	dw %0-1					// maximum items that may be created
	dd %%list				// ptr to list of items
	dd %1					// ptr to item which currently has focus
%%list:
	%rep %0-1
		%rotate 1
		dd %1
	%endrep
%endmacro

; (focus item, items...)
%macro DefWindowObj 2-*
	dw %0-1					// items currently contained
	dw %0-1					// maximum items that may be created
	dd %%list				// ptr to list of items
	dd %1					// ptr to item which currently has focus

	dd %1, NullGuiObj
	dw 0,0,0,0
	dw 0,0,16383,16383

%%list:
	%rep %0-1
		%rotate 1			// add each child item to window list
		dd %1
	%endrep
%endmacro

%macro DefButtonObj 1-2 0
	dd %%str				// string is not null terminated
	dd (%%strend-%%str)/2	// number of characters in title text
	db %2					// state

[section .string]
	align 4,db 0
	%%str equ $
	dw %1
	%%strend equ $
__SECT__
%endmacro

%macro DefTitleBarObj 1-2 0
	dd %%str				// string is not null terminated
	dd (%%strend-%%str)/2	// number of characters in title text
	dd %2					// flags

[section .string]
	align 4,db 0
	%%str equ $
	dw %1
	%%strend equ $
__SECT__
%endmacro

%macro DefCallbackObj 1
extern _%1Owner
%1Callback:
	dd _%1Owner
%endmacro


////////////////////////////////////////////////////////////////////////////////
// C structures and constants

#else // C

enum {
	PlainFlags_Active=1,	// UI currently initialized and active
};

class GuiMsg {
public:
  enum {
	//컴컴컴컴컴컴컴컴컴컴 FUNDAMENTAL
	created,		// item was created and should initialize itself
	destroyed,		// release resources used by item
	draw,			// informs item it should draw itself now (not the same as redraw!)
	flagsChanged,	// flags have been changed
	movedSized,		// item was moved or resized
	time,			// item time is now or past due
	focus,			// item focus gained/lost, either Tab key or mouse activation
	help,			// request help from item

	//컴컴컴컴컴컴컴컴컴컴 INPUT
	keyPress,		// key press
	keyRelease,		// key release
	keyChar,		// character
	keyIn,			// key focus in, usually from being tabbed to
	keyOut,			// key focus out, usually from being tabbed from
	mousePress,		// button press
	mouseRelease,	// button release
	mouseMove,		// simple move over item, no button change
	mouseIn,		// mouse focus in, entered item's boundary
	mouseOut,		// mouse focus out, exited item's boundary
	//mouseWheel,

	//컴컴컴컴컴컴컴컴컴컴 CONTAINER RELATED
	create,			// sent to a container to create an item or main layer to create container window
	destroy,		// same as above but to destroy a container/item
	redraw,			// item within window needs redrawing, sent from item to container (posted for later)
	setFlags,		// request flags be changed properly by container
	move,			// request resizing/repositioning of object

	setItemFocus,	// set item or group that appears active
	setKeyFocus,	// set which item has key focus
	setMouseFocus,	// set which item receives mouse focus, usually for an item to temporarily grab all mouse input for itself
	setLayer,		// request item's zlayer order be changed

	getItemFocus,	// get item or group that appears active
	getKeyFocus,	// get which item has key focus
	getMouseFocus,	// get which item receives mouse focus, usually for an item to temporarily grab all mouse input for itself
	getLayer,		// get item's zlayer order

	nop,
	mask=255		// only pay attention to lower 8bits for message meaning
  } types;
};



//  These flags are used by: Focus, SetItemFocus, GetItemFocus
class FocusMsgFlags {
public:
  enum {
	setItem=256,		// activate item in group (does not alone activate group) otherwise the existing active item of the group is used
	setGroup=512,		// activate group in window (does not alone activate container)
	getItem=setItem,	// alias, get active item of group
	getGroup=setGroup,	// alias, get active group of container
	setContainer=1024,	// activates item's container (chaining up), or means a new container activated and item's container either lost or gained focus
	relative=2048,		// relative to current item, will wrap / else absolute item index given
	specified=4096,		// relative seek start from item specified, otherwise from current item
	reverse=8192,		// seek previous item, otherwise relative seeks procede forward
	recurse=32768,		// recurse to get contained item in lower levels
	silent=1<<16,		// steals focus without sending any messages to previous item, all flags also remain the same so other items still appear active
	noWrap=131072,		// relative should not wrap (if there are no more items, the call will fail)
	byMouse=262144,		// focus was set because mouse was moved over item
	repeat=33554432		// repeated keypress (key held down)
  };
};

typedef struct {
	int code;
} KeyMsg;

//  These flags are used by: KeyPress,KeyRelease,KeyChar,KetIn,KeyOut,SetKeyFocus
class KeyMsgFlags {
public:
  enum {
	setItem=256,
	setContainer=1024,	// grab key focus all the way up to the top level
	recurse=32768,		// recurse to get contained item in lower levels
	silent=1<<16,		// steals focus without sending any messages to previous item
	windowInOut=131072,	// entered/exited main window (MS Window's compile)
	byMouse=262144,		// focus was set because mouse was moved over item
	repeat=33554432		// repeated keypress (key held down)
  };
};

#define PlainKeyDown(key)  (PlainKeyboard.buttons[key>>5] &   (1<<(key & 31)) )
#define PlainKeySet(key)   __asm mov eax,key __asm bts dword ptr PlainKeyboard.buttons, eax
#define PlainKeyClear(key) __asm mov eax,key __asm btr dword ptr PlainKeyboard.buttons, eax
//#define PliKeySet(key)   (PlainKeyboard.buttons[key>>5] |=  (1<<(key & 31)) )
//#define PliKeyClear(key) (PlainKeyboard.buttons[key>>5] &= ~(1<<(key & 31)) )

typedef struct {
	int col;
	int row;
} MouseMsg;

typedef struct {
	int flags;
} RedrawMsg;

//  These flags are used by: MousePrsRls,MouseMove,MouseIn,MouseOut,SetMouseFocus
class MouseMsgFlags {
public:
  enum {
	setItem=1<<8,		// gained focus
	setContainer=1<<10,	// grab mouse focus all the way up to the top level
	buttonsLs=11,		// buttons mask left shift
	leftButton=1<<11,	// left button down
	rightButton=1<<12,	// right button down
	middleButton=1<<13,	// middle press or release
	reset=1<<14,		// resets mouse boundaries to container maximum
	recurse=1<<15,		// recurse to get contained item in lower levels
	silent=1<<16,		// steals focus without sending any messages to previous item, all flags also remain the same so other items still appear active
	mouseMoved=1<<17,	// mouse was moved (useful for button press/release message)
	windowInOut=1<<18,	// entered/exited main window (MS Window's compile)
	specified=1<<19,	// get item at position
	verticalPush=1<<20,	// cursor pushed beyond top/bottom boundary
	horizontalPush=1<<21,// cursor pushed beyond left/right boundary
  };
};

class LayerMsgFlags {
public:
  enum {
	setItem=256,		// set item's layer order
	setContainer=1024,	// bring container to back or front also
	specified=4096,		// item gave another to be relative to
	reverse=8192		// sets item to back rather than front
  };
};

class MoveMsgFlags {
public:
  enum {
	sizedHeight=256,	// item sized, height was changed
	sizedWidth=512,
	movedRow=1024,		// item moved, top row was changed
	movedCol=2048,
	movedLayer=4096,
	invisible=8192,		// does not redraw anything
	silent=1<<16		// sends no messages to item
  };
};

typedef struct {
	union {
		KeyMsg key;
		MouseMsg mouse;
		RedrawMsg redraw;
	};
} GuiMsgParams;

////////////////////////////////////////////////////////////////////////////////

//컴컴컴컴컴컴컴컴컴컴
typedef struct {
	int16 left;
	int16 top;
	int16 right;
	int16 btm;
} WindowRectSmall;

//컴컴컴컴컴컴컴컴컴컴
class GuiObj; // define for sake of the circular reference

class OwnerCallbackObj {
public:
	int (*code)(GuiObj*, int, ...);// item message handler (or intercepting code)
};

#define DefOwnerCallbackObj(name) extern "C" const OwnerCallbackObj name##Callback = \
	{(int (__cdecl *)(GuiObj *,int,...))& name##Owner};

//컴컴컴컴컴컴컴컴컴컴
class GuiObj {
public:
	int (*code)(GuiObj*, int, ...);// item message handler (or intercepting code)
	OwnerCallbackObj* owner;// item or indirect callback to owner, notified of significant changes in data (technically, since only the item ever uses this variable, any 4 byte info can be stored here)
	GuiObj* container;		// ptr to containing window's data structure
	int32 flags;			// flags to determine object behaviour (invisible, disabled, gets focus, mouse responsive, needs redrawing)
	int16 idx;				// index of object in parent window list
	int16 extraIdx;			// don't know yet, maybe a help context id or id for group items
	union {
		WindowRectSmall rect;
		struct {
			int16 left; int16 top;		// offset of object within parent window (in pixels)
			int16 width; int16 height;	// size in pixels (not stupid twips)
		};
	};
	OwnerCallbackObj* border;
	union {
		WindowRectSmall borderRect;
		struct {
			int16 borderLeft; int16 borderTop;		// offset of object within parent window (in pixels)
			int16 borderWidth; int16 borderHeight;	// size in pixels (not stupid twips)
		};
	};

	enum { // flags
		null=1<<0,			// item does not exist, should never be sent messages (this flag is used to delete an item in a container without shifting all the others down one)
		hidden=1<<1,		// does not receive draw messages because it has no visible form or is currently invisible. Hidden items are not also disabled, and can still receive any mouse or key input sent their way. This allows an item to stay invisible but appear upon mouse over.
		mouseFocus=1<<2,	// cursor is currently over item or item has grabbed mouse focus
		mouseFocusB=1<<2,	// bit
		noMouseFocus=1<<3,	// does not receive mouse input (like a static picture or label)
		keyFocus=1<<4,		// item has key focus. Note this is only set if the item currently has key focus AND its container has key focus. It is also possible to have this flag set without being active (like a temporary popup menu or tooltip)
		keyFocusB=4,		// bit
		noKeyFocus=1<<5,	// does not receive keyboard input (like a title bar or label)
		allFocus=1<<6,		// items receive all focus messages, not just significant ones, like being the active item and losing focus or vice versa. other high level focus changes, like container or group are by default not made aware to the item.
		groupStart=1<<7,	// starts a new tab group, stopping focus advancement on either this item or active group item
		itemFocus=1<<8,	// item is currently active in the group (0=item focus, 1=no item focus), regardless of whether that group is active
		/*#if FocusMsgFlags.SetItem != .ItemFocus
		#error "ItemFocusFlags and GuiObj flags must match!"
		#endif
		#if KeyMsgFlags.SetItem != .ItemFocus
		#error "KeyFocusFlags and GuiObj flags must match!"
		#endif*/
		groupFocus=1<<9,	// item is in active group (0=group focus, 1=no group focus), regardless of whether the container is active
		containerFocus=1<<10,// item's container is active
		notFullFocus=itemFocus|groupFocus|containerFocus,	// if any bit is set, item does not have full focus (note: since zero is easier to test for than all ones, the flags are reversed, so all three flags zero means full focus)
		noItemFocus=1<<11,	// the item is skipped when looking for the next item to receive focus (when pressing tab). Note an item CAN still receive item focus if explicitly set.
		redrawBg=1<<12,		// indicates to container an item's background needs redrawing;  indicates to item that its background has been redrawn and that it must now completely redraw itself
		redrawPartial=1<<13,// item needs to redraw part of itself, not neccessarily all of it
		redrawSpecial=1<<14,// item specific flag (different meaning to each item)
		redrawForced=1<<15,	// tells item it some other item redrew itself, forcing this one to also be redrawn
		redrawAny=redrawPartial|redrawBg|redrawSpecial|redrawForced,	// either part or all of the item needs redrawing
		redrawHandled=1<<16,// tells container this item handles setting the redrawn update area, usually because it is a window that contains subitems, otherwise the container does it for the item
		redrawComplex=1<<17,// more complex zlayered redrawing, since items may be overlapped (painter's algorithm)
		fixedLayer=1<<18,	// drawing layer should never change, used by backgrounds or foreground status windows
		fixedPosition=1<<19,// position should never change, used by fixed items like nonmoveable windows
		disabled=1<<20,		// item can not receive either mouse or keyboard input. Unlike NoKeyFocus and NoMouseFocus which are fairly permanent attributes, Disabled may change often depending on program circumstancs.
		importantMsgs=1<<21,// tells item to only send important messages (like a menu choice being chosen, not simply selected; or a tab being clicked, not simply hovered)
		keyRecurse=1<<22,	//flags key focus is currently being set (to prevent recursion from messing with a previous call)

		defFlags=redrawBg
	};

	int GuiObj::draw();
	int GuiObj::redraw(int redrawFlags);
	int GuiObj::setClips(PgtDisplay* pgtd);
	int GuiObj::setBorderClips(PgtDisplay* display);
};

// Gets an ojbect type's entry point, casting to a compatible function pointer,
// for the benefit of variable parameters list on the caller's side, and easily
// accesible parametrs on the callee's side.
//
// usage: GuiObjEntry(WindowBgObj);
#define GuiObjEntry(type) (int (__cdecl*)(class GuiObj*,int,...))&##type##::entry

#define DefGuiObj(code,owner,container,flags,left,top,width,height) \
	code, \
	owner, container, \
	flags, \
	0,0, \
	left,top,width,height, \
	(OwnerCallbackObj*)&NullGuiObj, \
	left,top,width,height

//컴컴컴컴컴컴컴컴컴컴
/*
Generic container for other items. Used by WindowObj and can be 'subclassed'
by any other object that needs to be a container. Note that only the most
of functions can work with a pure container - creation, deletion, and setting
focus. All higher level functions require a window obj - passing mouse and
redraw messages.
*/
class ContainerObjItem {
public:
	GuiObj* child;			// single entry pointing to a child
	//uint16 keyIdx;
	//uint16 zlayerIdx;
};

class ContainerObj : public GuiObj {
public:
	uint16 totalItems;		// items currently contained
	uint16 maxItems;		// maximum items that may be created
	ContainerObjItem* itemList;// ptr to list of items
	void* focusItem;		// ptr to item which currently has focus
};

//컴컴컴컴컴컴컴컴컴컴
#ifdef PlainUseWindow
class WindowObj : public ContainerObj {
public:
	GuiObj* keyItem;		// ptr to item which currently has key input
	GuiObj* mouseItem;		// ptr to item which mouse cursor was last over
	WindowRectSmall mouseRect;	// bounds of active mouse item's boundary area
	WindowRectSmall redrawRect;	// bounds of area needing redraw

	enum {
		defFlags=GuiObj::defFlags|GuiObj::redrawHandled|GuiObj::groupStart
	};

	//static int entry(GuiObj* obj, int msg, GuiMsgParams gmp, ...);
	static int entry(GuiObj* obj, int msg, GuiMsgParams gmp, ...);
	int draw();
	int sendKey(int msg, int code);
	int sendMouse(int msg, int col, int row);
	static int sendMouseFocus(GuiObj* child, int msg, int focusFlag, int col, int row);
	GuiObj* getItemAt(int col, int row);
	int sendAllItems(int msg);
	int setItemFocus(int focusFlags);
	int setKeyFocus(int msg, GuiObj* newChild);
	GuiObj* getKeyFocus(int msg);
	int relayKeyFocus(int msg);
	//int redraw();
};
extern "C" int (* const WindowObjEntry)();
// can use this too __declspec(dllexport) 
#endif

//컴컴컴컴컴컴컴컴컴컴
#ifdef PlainUseRootWindow
class RootWindowObj : public WindowObj {
public:
	GuiObj* keyItem;		// ptr to item which currently has key input
	GuiObj* mouseItem;		// ptr to item which mouse cursor was last over
	WindowRectSmall mouseRect;	// bounds of active mouse item's boundary area
	WindowRectSmall redrawRect;	// bounds of area needing redraw

	enum {
		defFlags=WindowObj::defFlags|GuiObj::fixedLayer|GuiObj::fixedPosition
	};

	static int entry(GuiObj* obj, int msg, GuiMsgParams gmp, ...);
	int draw();
	//int redraw();
};
extern "C" int (* const RootWindowObjEntry)();
#endif

//컴컴컴컴컴컴컴컴컴컴
#ifdef PlainUseWindowBg
class WindowBgObj : public GuiObj {
public:
	enum {
		defFlags=GuiObj::defFlags|GuiObj::groupStart|GuiObj::fixedLayer|GuiObj::fixedPosition
	};

	static int entry(GuiObj* obj, int msg, GuiMsgParams gmp, ...);
	int draw();
	int focus(int flags);
};
extern "C" int (* const WindowBgObjEntry)();
#endif

//컴컴컴컴컴컴컴컴컴컴
#ifdef PlainUsePreview
class PreviewObj : public GuiObj {
public:
	PgtImage* image;
	int32 scrollLeft;
	int32 scrollTop;

	enum {
		defFlags=GuiObj::defFlags
	};

	static int entry(GuiObj* obj, int msg, GuiMsgParams gmp, ...);
	int draw();
};
extern "C" int (* const PreviewObjEntry)();
#define DefPreviewObj(image) \
	image, \
	0, 0
#endif

//컴컴컴컴컴컴컴컴컴컴
#ifdef PlainUseTitleBar
class TitleBarObj : public GuiObj {
public:
	uint16* text;			// string is not null terminated
	uint32 textLen;			// number of characters in title text
	uint32 buttonFlags;

	enum {
		closeButton=1<<0,	// "X"  has close button
		helpButton=1<<1,	// "?"  has help button in upper right corner
		maxButton=1<<2,		// ">>" has maximize button
		minButton=1<<3,		// "<<" has minimize button
		groupIndicate=1<<7	// changes active indication for group level
	};
	enum {
		defFlags=(GuiObj::defFlags|GuiObj::noKeyFocus|GuiObj::allFocus)^GuiObj::itemFocus
	};
	enum msg {
		close=255,
	};

	static int entry(GuiObj* obj, int msg, GuiMsgParams gmp, ...);
	int focus(int focusFlags);
	int draw();
};
extern "C" int (* const TitleBarObjEntry)();
#endif

//컴컴컴컴컴컴컴컴컴컴
#ifdef PlainUseBorder
class BorderObj : public GuiObj {
public:
	enum {
		defFlags=GuiObj::defFlags|GuiObj::fixedLayer|GuiObj::fixedPosition|GuiObj::noMouseFocus|GuiObj::noKeyFocus|GuiObj::noItemFocus
	};

	static int entry(GuiObj* obj, int msg, GuiMsgParams gmp, ...);
	int draw();
};
extern "C" int (* const BorderObjEntry)();
extern "C" OwnerCallbackObj BorderObjInstance;
//#define DefBorderObj(image)
#endif

//컴컴컴컴컴컴컴컴컴컴
#ifdef PlainUseButton
class ButtonObj : public GuiObj {
public:
	uint16* text;			// string is not null terminated
	uint32 textLen;			// number of characters in title text
	uint8 state;
	enum {
		stateDown=1<<0,
		stateLock=1<<1,
		stateToggle=1<<2
	};
	enum {
		defFlags=GuiObj::defFlags
	};
	enum msg {
		click=255,
	};

	static int entry(GuiObj* obj, int msg, GuiMsgParams gmp, ...);
	int draw();
	void activate(bool mode);
};
extern "C" int (* const ButtonObjEntry)();

#endif

//컴컴컴컴컴컴컴컴컴컴
#ifdef PlainUseAttribListObj
class AttribListObj : public GuiObj {
public:
	/*
	uint16* text;			// string is not null terminated
	uint32 textLen;			// number of characters in title text
	uint8 state;
	enum {
		stateDown=1<<0,
		stateLock=1<<1,
		stateToggle=1<<2
	};
	*/
	enum {
		defFlags=GuiObj::defFlags
	};
	enum msg {
		click=255,
	};

	static int entry(GuiObj* obj, int msg, GuiMsgParams gmp, ...);
	int draw();
	void activate(bool mode);
};
extern "C" int (* const AttribListEntry)();

#endif

#ifndef ASM
#pragma pack(pop)     // for original alignment
#endif


//컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴

//typedef 
struct  PlainKeyboard {
	int msg;				// last key message received
	int code;				// last character code or scan code
	uint32 buttons[8];		// 256 bit array
	// ex: if (PliKeyDown(VK_ESCAPE)) ...
}; // PltKeyboard;

struct PlainMouse {
	int rowDif;				// pixel change, ignoring clipping
	int colDif;
	#ifdef _DOS
	int rowFine;			// motion counter change in mickeys
	int colFine;
	#endif
	int left;				// left pixel of constrained region
	int top;				// top pixel of constrained region
	int right;				// right pixel+1 of constrained region
	int bottom;				// bottom pixel+1 of constrained region
	union {
		uint32 buttons;
		struct {
			uint8 down;		// currently down
			uint8 pressed;	// pressed since last call
			uint8 released;	// released since last call
			uint8 flags;
		};
	};
	// ex: if (PlainMouse.buttons & leftPress) ...
	enum {
		leftDown      = 0x00001,
		rightDown     = 0x00002,
		middleDown    = 0x00004,
		leftPress     = 0x00100,
		rightPress    = 0x00200,
		middlePress   = 0x00400,
		leftRelease   = 0x10000,
		rightRelease  = 0x20000,
		middleRelease = 0x40000
	};
	int lastClick;
	int clickTime;
	#ifdef _WINDOWS
	HWND hwnd;
	#endif
	#ifdef _DOS
	int numButtons;			// some mouse drivers report 3 when the mouse really only has 2?
	#endif					// >=0 also indicates the presence of a mouse (else zero if no driver)
};


#ifndef guicode_cpp
	extern "C" GuiObj NullGuiObj;
	#ifdef _WINDOWS
	extern "C" MSG	PlainThreadMsg;
	#endif
	extern "C" int  AckMsg(GuiObj* obj, int msg, ...);
	extern "C" int  IgnoreMsg(GuiObj* obj, int msg, ...);
	extern "C" int  PlainInit(GuiObj* root);
	extern "C" int  PlainDeinit(GuiObj* root);
	extern "C" HWND PlainCreateWin(GuiObj* root, LPTSTR title, int left, int top, int width, int height);
	extern "C" int  PlainDestroyWin(HWND hwnd);
	extern "C" void PlainDrawFrame(HWND hwnd, GuiObj* root);
	extern "C" PlainMouse PlainMouse;
	extern "C" PlainKeyboard PlainKeyboard;
#endif

extern "C" PgtLayer PlainCursor_Default;
extern "C" PgtLayer PlainCursor_Pan;
extern "C" PgtLayer PlainCursor_Edit;

#endif // C

#endif // GUIDEFS_H
