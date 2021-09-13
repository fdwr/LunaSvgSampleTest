/**
Author:	Dwayne Robinson
Date:	2005-10-31
Since:	2005-10-31
Brief:	Global definitions.
Remark:	Look in PlainVue for the root ui object.
*/
module plain.plaindefs;

package alias  byte   int8;
package alias ubyte  uint8;
package alias  short  int16;
package alias ushort uint16;
package alias  int    int32;
package alias uint   uint32;
package alias  long   int64;
package alias ulong  uint64;
static assert (int8.sizeof == 1 && int16.sizeof == 2 && int32.sizeof == 4 && int64.sizeof == 8);

package import pgfx.pgfxdefs;
private import plain.plainvue;

////////////////////////////////////////////////////////////////////////////////

/// Message (just a union of message identifier and flags)
union PlainMsg
{
	alias uint8 Mids;
	enum : Mids {
		//mixin PlainMsgEnums
		//////////// FUNDAMENTAL ////////////
		nop,
		create,			/// item was created and should initialize itself
		destroy,		/// release resources used by item
		inserted,		/// initialize anything upon entry to container
		removed,		/// free anything upon exit from container
		flagged,		/// flags have been changed
		moved,			/// item was moved or resized
		timed,			/// item time is now or past due
		focused,		/// item focus gained/lost, either Tab key or mouse activation
		draw,			/// item it should draw itself now (not the same as redraw!)
		help,			/// request help from item
	
		//////////// INPUT NOTIFICATIONS ////////////
		keyPress,		/// key press
		keyRelease,		/// key release
		keyChar,		/// character
		keyIn,			/// key focus in, usually from being tabbed to
		keyOut,			/// key focus out, usually from being tabbed from
		mousePress,		/// button press
		mouseRelease,	/// button release
		mouseMove,		/// simple move over item, no press/release/in/out
		mouseIn,		/// mouse focus in, entered item's boundary. Focus already changed upon notification. An additional mouse move is not sent.
		mouseOut,		/// mouse focus out, exited item's boundary. Focus already changed upon notification. An additional mouse move is not sent.
		//mouseWheel,
	
		//////////// CONTAINER RELATED ////////////
		insert,			/// create new item at location (Vue for window, string for list, value struct for attribute list...)
		append,			/// append new item to end of list
		remove,			/// remove item at location
		access,			/// access element at location (use positive for position, negative numbers for ids if supported)
		redraw,			/// item within window needs redrawing, sent from item to container (posted for later)
		flag,			/// request flags be changed properly by container
		move,			/// change size/position of item
		location,		/// get location information of item (recurses when necessary to find absolute position)
		extents,		/// return preferred extents of item (important for dynamic resizing information)
		//activate,		/// either set/get item highlight
	
		itemFocusSet,	/// set item or group that appears active
		itemFocusGet,	/// get item or group that appears active
		keyFocusSet,	/// set which item has key focus
		keyFocusGet,	/// get which item has key focus
		mouseFocusSet,	/// set which item receives mouse focus, usually for an item to temporarily grab all mouse input for itself
		mouseFocusGet,	/// get which item receives mouse focus
		
		//////////// ITEM RELATED ////////////
		textSet,	/// as expected (not all items have text, but since so many do, this is standard)
		textGet,	/// as expected
		valueSet,	/// set integral value
		valueGet,	/// get integral value
		stateSet,	/// set item specific state flags
		stateGet,	/// get item specific state flags

		midNext,
	}
	enum : uint { midMask = 255} /// only pay attention to lower 8bits for message meaning
	enum Flags {		
		important = 1<<31,
	}
	Mids mid;
	Flags flags;
}

/// Message used by: move, location
struct PlainMsgMove
{
	enum Flags : PlainMsg.Flags {
		moveLeft=1<<8,		/// left changed or should be changed
		moveTop=1<<9,		/// top changed or should be changed
		move=moveLeft|moveTop,
		sizeWidth=1<<10,	/// width changed or should be changed
		sizeHeight=1<<11,	/// height changed or should be changed
		size=sizeWidth|sizeHeight,
		moveSize=move|size,
		moveLayer=1<<12,		/// layer changed or should be changed
		chainLayer=1<<13,	///	bring container to back or front also
		invisible=1<<14,		/// do not redraw anything
		relative=1<<15,		/// movement is relative to current position
		moveRelative=move|relative,
		silent=1<<16		/// send no messages to items
	}

	union { PlainMsg msg; PlainMsg.Mids mid; Flags flags; }
	PlainVue target; /// object to move or moved
	//int left, top, width, height, layer; /// previous size values
}

/// Message used by: mousePrs/Rls/Move/In/Out/SetMouseFocus
struct PlainMsgMouse
{
	enum Flags : PlainMsg.Flags {
		setItem=1<<8,		/// set item's focus (is set on mouseIn, clear on mouseOut)
		setContainer=1<<10,	/// grab mouse focus all the way up to the top level
		reset=1<<14,		/// resets mouse boundaries to container maximum
		recurse=1<<15,		/// recurse to get contained item in lower levels
		silent=1<<16,		/// steals focus without sending any messages to previous item, flags remain the same so other items still appear active
		mouseMoved=1<<17,	/// mouse was moved (useful for button press/release message)
		windowInOut=1<<18,	/// entered/exited main window (MS Window's compile)
		specified=1<<19,	/// get item at position
		verticalPush=1<<20,	/// cursor pushed beyond top/bottom boundary
		horizontalPush=1<<21,	/// cursor pushed beyond left/right boundary
	} 

	union { PlainMsg msg; PlainMsg.Mids mid; Flags flags; }
	int button;	/// button pressed or released
	int down;		/// currently down
	enum Buttons {
		leftDown      = 0x00001,
		rightDown     = 0x00002,
		middleDown    = 0x00004,
	}
	int x,y;			/// column and row of hot spot relative to vue
	int pressTime;		/// time between clicks (milliseconds since previous click)
}

///  Message used by: KeyPress,KeyRelease,KeyChar,KeyIn,KeyOut,SetKeyFocus
struct PlainMsgKey {
	enum Flags : PlainMsg.Flags {
		setItem=1<<8,	/// set item
		setContainer=1<<10,	/// grab key focus all the way up to the top level
		recurse=1<<14,		/// recurse to get contained item in lower levels
		silent=1<<16,		/// steals focus without sending any messages to previous item
		windowInOut=1<<17,	/// entered/exited main window (MS Window's compile)
		byMouse=1<<18,		/// focus was set because mouse was moved over item
		repeat=1<<19		/// repeated keypress (key held down)
	}

	union { PlainMsg msg; PlainMsg.Mids mid; Flags flags; }
	int code;	/// either virtual key code or Unicode character code
	version (Windows) {
		enum Codes : uint { // todo: fill in the remainder later
			cancel = VK_CANCEL,
			back = VK_BACK,
			tab = VK_TAB,
			clear = VK_CLEAR,
			enter = VK_RETURN,
			shift = VK_SHIFT,
			control = VK_CONTROL,
			alt = VK_MENU,
			pause = VK_PAUSE,
			capital = VK_CAPITAL,
			escape = VK_ESCAPE,
			space = VK_SPACE,
			previous = VK_PRIOR,
			pageUp = VK_PRIOR,
			next = VK_NEXT,
			pageDown = VK_NEXT,
			end = VK_END,
			home = VK_HOME,
			left = VK_LEFT,
			up = VK_UP,
			right = VK_RIGHT,
			down = VK_DOWN,
			select = VK_SELECT,
			print = VK_PRINT,
			execute = VK_EXECUTE,
			snapshot = VK_SNAPSHOT,
			insert = VK_INSERT,
			deleteKey = VK_DELETE,
			help = VK_HELP,
			/*
			VK_0,
			VK_1,
			VK_2,
			VK_3,
			VK_4,
			VK_5,
			VK_6,
			VK_7,
			VK_8,
			VK_9,
			VK_A,
			VK_B,
			VK_C,
			VK_D,
			VK_E,
			VK_F,
			VK_G,
			VK_H,
			VK_I,
			VK_J,
			VK_K,
			VK_L,
			VK_M,
			VK_N,
			VK_O,
			VK_P,
			VK_Q,
			VK_R,
			VK_S,
			VK_T,
			VK_U,
			VK_V,
			VK_W,
			VK_X,
			VK_Y,
			VK_Z,
			*/
			systemLeft = VK_LWIN,//Left Windows key (Microsoft Natural keyboard) 
			systemRight = VK_RWIN,//Right Windows key (Natural keyboard)
			menu = VK_APPS,//Applications key (Natural keyboard)
			/*
			VK_NUMPAD0,
			VK_NUMPAD1,
			VK_NUMPAD2,
			VK_NUMPAD3,
			VK_NUMPAD4,
			VK_NUMPAD5,
			VK_NUMPAD6,
			VK_NUMPAD7,
			VK_NUMPAD8,
			VK_NUMPAD9,
			VK_MULTIPLY,
			VK_ADD,
			VK_SEPARATOR,
			VK_SUBTRACT,
			VK_DECIMAL,
			VK_DIVIDE,
			VK_F1,
			VK_F2,
			VK_F3,
			VK_F4,
			VK_F5,
			VK_F6,
			VK_F7,
			VK_F8,
			VK_F9,
			VK_F10,
			VK_F11,
			VK_F12,
			VK_F13,
			VK_F14,
			VK_F15,
			VK_F16,
			VK_F17,
			VK_F18,
			VK_F19,
			VK_F20,
			VK_F21,
			VK_F22,
			VK_F23,
			VK_F24,
			VK_NUMLOCK,
			VK_SCROLL,
			*/
			shiftLeft = VK_LSHIFT,
			controlLeft = VK_LCONTROL,
			altLeft = VK_LMENU,
			shiftRight = VK_RSHIFT,
			controlRight = VK_RCONTROL,
			altRight = VK_RMENU,
			/*
			VK_PROCESSKEY,
			*/
		}
	}
	version (SDL) {
		//enum Codes : uint { }
	}
	/**
	remark:	Since key and character come as two separate messages, there are
	 			not two separate fields for each.
	 remark:	No modifiers are passed, since ALL keys can be considered
				modifiers. For example, you could press Tab+Q for a special key combo.
	*/
}

///  Message used by: Focus, SetItemFocus, GetItemFocus
struct PlainMsgFocus {
	enum Flags : PlainMsg.Flags {
		setItem=1<<8,		/// activate item in group (does not alone activate group) otherwise the existing active item of the group is used
		setGroup=1<<9,		/// activate group in window (does not alone activate container) or get active group
		setContainer=1<<10,	/// activates item's container (chaining up), or means a new container activated and item's container either lost or gained focus
		relative=1<<11,		/// relative to current item, will wrap / else absolute item index given
		specified=1<<12,		/// relative seek start from item specified, otherwise from current item
		reverse=1<<13,		/// seek previous item, otherwise relative seeks procede forward
		recurse=1<<14,		/// recurse to get contained item in lower levels
		silent=1<<16,		/// steals focus without sending any messages to previous item, all flags also remain the same so other items still appear active
		noWrap=1<<17,		/// relative should not wrap (if there are no more items, the call will fail)
		byMouse=1<<18,		/// focus was set because mouse was moved over item
		repeat=1<<19	/// repeated keypress (key held down)
	}

	union { PlainMsg msg; PlainMsg.Mids mid; Flags flags; }
}

/// Message used by: Draw, Redraw
struct PlainMsgDraw {
	enum Flags : PlainMsg.Flags {
		bg=1<<12,		// indicates to container an item's background needs redrawing;  indicates to item that its background has been redrawn and that it must now completely redraw itself
		partial=1<<13,	// item needs to redraw part of itself, not neccessarily all of it
		special=1<<14,	// item specific flag (different meaning to each item)
		forced=1<<15,	// tells item it some other item redrew itself, forcing this one to also be redrawn
		any=partial|bg|special|forced,	// either part or all of the item needs redrawing
		handled=1<<16,	// tells container this item handles setting the redrawn update area, usually because it is a window that contains subitems, otherwise the container does it for the item
		complex=1<<17,	// more complex zlayered redrawing, since items may be overlapped (painter's algorithm)
	}

	union { PlainMsg msg; PlainMsg.Mids mid; Flags flags; }
}

/// Message used by: extents
struct PlainMsgExtents
{
	union { PlainMsg msg; PlainMsg.Mids mid; PlainMsg.Flags flags; }
	enum Elements : uint32 {
		sizePref, /// preferred size of item (windows usually query this element)
		sizeMin, /// minimum allowable size (i.e. a button should not be smaller than its text)
		sizeMax, /// maximum allowable size (perhaps a window that should not be too large)
		placement, /// get placement of item (like status bar at bottom, title bar at top)
	}
	Elements element;	/// element to query
	PlainRect rect;	/// top/left, 
}

/// Message used by: insert, remove, 
struct PlainMsgModify
{
	enum Flags : PlainMsg.Flags {
		moveLeft=1<<8,		/// left changed or should be changed
		moveTop=1<<9,		/// top changed or should be changed
		move=moveLeft|moveTop,
		sizeWidth=1<<10,	/// width changed or should be changed
		sizeHeight=1<<11,	/// height changed or should be changed
		size=sizeWidth|sizeHeight,
		moveSize=move|size,
		moveLayer=1<<12,		/// layer changed or should be changed
		chainLayer=1<<13,	///	bring container to back or front also
		invisible=1<<14,		/// do not redraw anything
		relative=1<<15,		/// movement is relative to current position
		moveRelative=move|relative,
		silent=1<<16		/// send no messages to items
	}

	union { PlainMsg msg; PlainMsg.Mids mid; Flags flags; }
	PlainVue target; /// object to move or moved
	//int left, top, width, height, layer; /// previous size values
}



/// Union of all message types for simplicity.
/// Do does not support struct inheritance (yet!)
/// so we need cheap hacks of union and composition
/// for now :-|
union PlainMsgAll
{
	PlainMsg msg;
	PlainMsg.Mids mid;
	PlainMsg.Flags flags;

	PlainMsgMouse mouse;
	PlainMsgKey key;
	PlainMsgMove move;
	PlainMsgFocus focus;
	PlainMsgDraw draw;
	PlainMsgExtents extents;
}


////////////////////////////////////////////////////////////////////////////////

typedef int delegate(PlainVue source, inout PlainMsg msg) PlainDelegate;

interface PlainRecipient
{
	/**
	Params:
		source = object the message came from
		m = ptr to message union
	*/
	public int send(inout PlainMsg m);
}

struct PlainRect {
	int32 left;
	int32 top;
	int32 right;
	int32 bottom;
}

struct PlainRectSmall {
	int16 left;
	int16 top;
	int16 right;
	int16 bottom;
}
