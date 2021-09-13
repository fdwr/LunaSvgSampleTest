/**
Author:	Dwayne Robinson
Date:	2005-10-31
Since:	2005-10-31
Brief:	User control element, root of all other UI elements.
Remark:	Look in PlainDefs for messaging constants.
*/
module plain.plainvue;

debug private import std.stdio;

public import PlainConfig;
public import plain.plaindefs;

// PlainVue : "Plain View" piken's layered interface visual user element
abstract class PlainVue : PlainRecipient
{
	enum Flags : uint {
		dead=1<<0,			// item does not exist, should not receive messages (used to delete an item in a container without shifting all the others). A container can technically die before the children, but this could orphan the children.
		hidden=1<<1,		// does not receive draw messages because it has no visible form or is currently invisible. Hidden items are not also disabled, and can still receive any mouse or key input sent their way. This allows an item to stay invisible but appear upon mouse over.
		mouseFocus=1<<2,	// cursor is currently over item or item has grabbed mouse focus
		mouseFocusB=1<<2,	// bit
		noMouseFocus=1<<3,	// does not receive mouse input (like a static picture or label)
		keyFocus=1<<4,		// item has key focus. Note this is only set if the item currently has key focus AND its container has key focus. It is also possible to have this flag set without being active (like a temporary popup menu or tooltip)
		keyFocusB=4,		// bit
		noKeyFocus=1<<5,	// does not receive keyboard input (like a title bar or label)
		allFocus=1<<6,		// items receive all focus messages, not just significant ones, like being the active item and losing focus or vice versa. other high level focus changes, like container or group are not usually sent to the item.
		groupStart=1<<7,	// starts a new tab group, stopping focus advancement on either this item or active group item
		itemFocus=1<<8,	// item is currently active in the group (0=no item focus, 1=item focus), regardless of whether that group is active
		/*#if FocusMsgFlags.SetItem != .ItemFocus
		#error "ItemFocusFlags and GuiObj flags must match!"
		#endif
		#if KeyMsgFlags.SetItem != .ItemFocus
		#error "KeyFocusFlags and GuiObj flags must match!"
		#endif*/
		groupFocus=1<<9,	// item is in active group (0=no group focus, 1=group focus), regardless of whether the container is active
		containerFocus=1<<10,// item's container is active
		fullFocus=itemFocus|groupFocus|containerFocus,	// if all bits set, item has full focus
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
		recursing=1<<22,	//flags key focus is currently being set (to prevent recursion from messing with a previous call)
	};
	enum {
		defFlags=Flags.redrawBg,
	}
	static assert (PlainMsgFocus.Flags.setItem==Flags.itemFocus && PlainMsgFocus.Flags.setGroup==Flags.groupFocus && PlainMsgFocus.Flags.setContainer==Flags.containerFocus);
	static assert (PlainMsgDraw.Flags.bg==Flags.redrawBg && PlainMsgDraw.Flags.partial==Flags.redrawPartial && PlainMsgDraw.Flags.special==Flags.redrawSpecial && PlainMsgDraw.Flags.forced==Flags.redrawForced && PlainMsgDraw.Flags.any==Flags.redrawAny && PlainMsgDraw.Flags.handled==Flags.redrawHandled && PlainMsgDraw.Flags.complex==Flags.redrawComplex);

	union {
		Flags flags;	/// flags to determine object behaviour (invisible, disabled, gets focus, mouse responsive, needs redrawing)
		bit flagBits[32];	/// individually addressable
		static assert(Flags.sizeof >= 4);
	}
	PlainDelegate owner;	/// either another item or listening coding, notified of significant changes in data
	PlainVue container;	/// containing window (mostly like a subclass of PlainVue too)
	package int16 index;				/// index of object in parent window list (may vary depending on the order of object creation)
	int16 id;			/// id for contextual help or multi-language mapping (not globally unique since multiple instances of the same vue may have same id, but SHOULD be unique within a given container)
	union {
		PlainRectSmall rect;
		struct {
			int16 left; int16 top;		/// offset of object within parent window (in pixels)
			int16 width; int16 height;	/// size in pixels (not stupid twips)
		}
	}
	PlainVue border;
	union {
		PlainRectSmall borderRect;
		struct {
			int16 borderLeft; int16 borderTop;		/// offset of object within parent window (in pixels)
			int16 borderWidth; int16 borderHeight;	/// size in pixels (not stupid twips)
		}
	}

	static PlainVue mouseHolder;	/// current object to have complete focus of mouse

	//////////// CREATION FUNCTIONS ////////////
	static this()
	{
		// create dead end black hole
		PlainVueDead = new PlainVueDeadClass();
		//owner = &deadOwner;	// either another item or listening coding, notified of significant changes in data
		PlainVueDead.container = PlainVueDead;	// make container refer to self
		PlainVueDead.border = PlainVueDead;	// no border
		PlainVueDead.flags = // set a ton of flags to ensure no code does anything with this object
			 Flags.dead
			|Flags.hidden
			|Flags.disabled
			|Flags.noMouseFocus
			|Flags.noKeyFocus
			|Flags.noItemFocus
			|Flags.redrawAny
			|Flags.fixedLayer
			|Flags.fixedPosition
			|Flags.recursing
			|Flags.allFocus;
		mouseHolder = PlainVueDead; // holder of the mouse
	}

	public this()
	{
		flags = defFlags;

		// initially the object has no owner, container, or border
		owner = &deadOwner;	// either another item or listening coding, notified of significant changes in data
		container = PlainVueDead;	// containing window (mostly like a subclass of PlainVue too)
		border = PlainVueDead;
	}

	// vue's should define their own creation struct so they can be indirectly created via createUnknown()
	typedef PlainVue function(void*) CreatorFunction;
	align(1) struct CreationStruct {
		CreatorFunction creator = null; //&create; /// the function to call that fills in the object
		// ... more specific fields after
	}

	public this(CreationStruct* cs)
	{
		//flags = defFlags
	}

	static public PlainVue create(void* param); // can't actually create an instance
	/*{
		return new PlainVue(cast(CreationStruct*) param);
	}*/

	static public PlainVue createUnknown(CreationStruct* param); // can't actually create an instance
	/*{
		return param.creator(param);
	}*/

	//////////// SENDING FUNCTIONS ////////////
	public int send(inout PlainMsg m_)
	{
		PlainMsgAll* m = cast(PlainMsgAll*)&m_;
		//MessageBoxA(null, "Inside Send", "Hello", MB_OK);

		/*PlainMsgMouse* ms = cast(PlainMsgMouse*)&m_;
		//writef("%X\n", m);
		writef("%X\n", &m_);
		writef("%d\n", *(cast(int*)&m_));
		writef("%d\n", cast(int)ms.button);
		writef("%d\n", cast(int)ms.down);
		*/
		//-debug writefln("PlainVue.send");
		switch (m.mid) {
		
		//////////// BASIC NOTIFICATIONS ////////////
		case PlainMsg.create:
			break;
		case PlainMsg.destroy:
			
			break;
		case PlainMsg.inserted:
			break;
		case PlainMsg.removed:
			break;
		case PlainMsg.flagged:
			break;
		case PlainMsg.moved:
			break;
		case PlainMsg.timed:
			break;
		case PlainMsg.focused:
			break;
		case PlainMsg.draw:
			return draw();
		case PlainMsg.help:
			break;
	
		//////////// INPUT NOTIFICATIONS ////////////
		case PlainMsg.keyPress:
			return keyPress(m.key.flags, m.key.code);
		case PlainMsg.keyRelease:
			return keyRelease(m.key.flags, m.key.code);
		case PlainMsg.keyChar:
			return keyChar(m.key.flags, m.key.code);
		case PlainMsg.keyIn:
			return keyIn(m.key.flags, m.key.code);
		case PlainMsg.keyOut:
			return keyOut(m.key.flags, m.key.code);
		case PlainMsg.mousePress:
			return mousePress(m.mouse.flags, m.mouse.button, m.mouse.down, m.mouse.x,m.mouse.y, m.mouse.pressTime);
		case PlainMsg.mouseRelease:
			return mouseRelease(m.mouse.flags, m.mouse.button, m.mouse.down, m.mouse.x,m.mouse.y, m.mouse.pressTime);
		case PlainMsg.mouseMove:
			return mouseMove(m.mouse.flags, m.mouse.down, m.mouse.x,m.mouse.y);
		case PlainMsg.mouseIn:
			return mouseIn(m.mouse.flags, m.mouse.down, m.mouse.x,m.mouse.y);
		case PlainMsg.mouseOut:
			return mouseOut(m.mouse.flags, m.mouse.down, m.mouse.x,m.mouse.y);
		//mouseWheel,

		//////////// CONTAINER RELATED ////////////
		case PlainMsg.insert:
			break;
		case PlainMsg.append:
			break;
		case PlainMsg.remove:
			break;
		case PlainMsg.access:
			break;
		case PlainMsg.redraw:
			return redraw(m.draw.flags);
		case PlainMsg.flag:
			break;
		case PlainMsg.move:
			break;
		case PlainMsg.location:
			break;
		case PlainMsg.extents:
			extents(m.extents.element, m.extents.rect);
			break;
		//activate,		/// either set/get item highlight
	
		case PlainMsg.itemFocusSet:
			//itemFocusSet(
			break;
		case PlainMsg.itemFocusGet:
			//itemFocusGet(
			break;
		case PlainMsg.keyFocusSet:
			//keyFocusSet
			break;
		case PlainMsg.keyFocusGet:
			//keyFocusGet
			break;
		case PlainMsg.mouseFocusSet:
			//mouseFocusSet
			break;
		case PlainMsg.mouseFocusGet:
			//mouseFocusGet
			break;

		case PlainMsg.textSet:
			//textSet(
			break;
		case PlainMsg.textGet:
			//textGet(
			break;
		case PlainMsg.valueSet:
			//valueSet(
			break;
		case PlainMsg.valueGet:
			//valueGet(
			break;
		case PlainMsg.stateSet:
			//stateSet();
			break;
		case PlainMsg.stateGet:
			//stateGet();
			break;

		default:
			break;
		}

		return -1;
	}

	private int deadOwner(PlainVue source, inout PlainMsg msg)
	{
		return -1;
	}

	//////////// BASIC NOTIFICATIONS ////////////
	int destroy()
	out {
		assert(flags & Flags.dead);
	}
	body {
		flags |= Flags.dead;
		return -1;
	}

	/// inserted into container (either first time after creation or moved from one container to another)
	int inserted()
	{
		debug writefln("Inserted %X into %X", this, container);
		return -1;
	}

	/// removed from container (either will be destroyed or moved from one container to another)
	int removed()
	{
		return -1;
	}

	/// flags were changed. subclass if interested in those changes. focus changes are NOT received via this call.
	int flagged(Flags setFlags, Flags resetFlags)
	in {
		assert(setFlags != 0 || resetFlags != 0); // at least some flag must have changed
	}
	body {
		return -1;
	}

	/// object was moved. subclass if need redrawing or recalculation of contents.
	int moved(PlainMsgMove.Flags moveFlags)
	{
		return -1;
	}

	int timed()
	{
		return -1;
	}

	int focused(PlainMsgFocus.Flags focusFlags)
	{
		return -1;
	}

	int help()
	{
		return -1;
	}

	//////////// DRAWING RELATED ////////////
	/// No flags are passed to this function because they have already been set in the class.
	public int draw()
	{
		return -1;
	}

	/**
	Draw onto another control (really only useful for borders or unusual highlight effects)
	date: 2005-11-15
	remark:
		All sizing calculation should be done relative to the given control rather than self.
		No normal VUE should ever need to implement this function, unless it exclusively
		draws its border (no other border's allowed).
	*/
	public int drawOnto(PlainVue base)
	{
		return -1;
	}

	public int redraw(PlainMsgDraw.Flags redrawFlags)
	{
		//-debug writefln("PlainVue.redraw item=%X", this);
		redrawFlags &= Flags.redrawAny; // exclude any message or other flags
		if (flags & (Flags.redrawAny|Flags.hidden|Flags.dead)) {
			// return early if any flags set
			//-debug writefln("PlainVue.redraw already flagged");
			flags |= redrawFlags;
			return 0;
		}
		//-debug writefln("PlainVue.redraw newly flagged,   container=%X", container);
		flags |= redrawFlags;
		container.redraw(PlainMsg.redraw | Flags.redrawPartial);

		return 0;
	}
	
	/// sets clips for an object, in preparation for drawing.
	int setClips(PgfxDisplay* displayIn)
	{
		//debug writefln("display clips in for %X   @(%d,%d, %d,%d)  display@(%d,%d)  clips=(%d,%d, %d,%d)", this, left, top, width, height, displayIn.left, displayIn.top, displayIn.clip.left, displayIn.clip.top, displayIn.clip.right, displayIn.clip.bottom);
		with (PgfxCurrentDisplay) {
			left = displayIn.left + this.left;
			top  = displayIn.top  + this.top;
			clip.left   = (left > displayIn.clip.left)  ?  left : displayIn.clip.left;
			clip.top    = (top > displayIn.clip.top )  ?  top : displayIn.clip.top;
			clip.right  = (left + this.width < displayIn.clip.right)  ?  left + this.width : displayIn.clip.right;
			clip.bottom = (top + this.height < displayIn.clip.bottom)  ?  top + this.height : displayIn.clip.bottom;
		}
		//debug writefln("display clips out for %X  @(%d,%d, %d,%d)  display(%d,%d)  clips(%d,%d, %d,%d)", this, left, top, width, height, PgfxCurrentDisplay.left, PgfxCurrentDisplay.top, PgfxCurrentDisplay.clip.left, PgfxCurrentDisplay.clip.top, PgfxCurrentDisplay.clip.right, PgfxCurrentDisplay.clip.bottom);
		if (PgfxCurrentDisplay.clip.bottom <= PgfxCurrentDisplay.clip.top
		 || PgfxCurrentDisplay.clip.right <= PgfxCurrentDisplay.clip.left) {
			return 0; // no visible area
		}
		return 1;
	}

	/// sets clips for an object's border, in preparation for drawing.
	int setBorderClips(PgfxDisplay* display)
	{
		PgfxCurrentDisplay.left = display.left + borderLeft;
		PgfxCurrentDisplay.top  = display.top  + borderTop;
		PgfxCurrentDisplay.clip.left   = (borderLeft               > display.clip.left)   ? borderLeft               : display.clip.left;
		PgfxCurrentDisplay.clip.top    = (borderTop                > display.clip.top )   ? borderTop                : display.clip.top;
		PgfxCurrentDisplay.clip.right  = (borderLeft + borderWidth < display.clip.right)  ? borderLeft + borderWidth : display.clip.right;
		PgfxCurrentDisplay.clip.bottom = (borderTop + borderHeight < display.clip.bottom) ? borderTop + borderHeight : display.clip.right;
		if (PgfxCurrentDisplay.clip.bottom <= PgfxCurrentDisplay.clip.top
		 || PgfxCurrentDisplay.clip.right <= PgfxCurrentDisplay.clip.left) {
			return 0; // no visible area
		}
		return 1;
	}

	//////////// INPUT NOTIFICATIONS ////////////
	int keyPress(PlainMsgKey.Flags keyFlags, int code)
	{	return -1;	}

	int keyRelease(PlainMsgKey.Flags keyFlags, int code)
	{	return -1;	}

	int keyChar(PlainMsgKey.Flags keyFlags, int code)
	{	return -1;	}

	int keyIn(PlainMsgKey.Flags keyFlags, int code)
	{	return -1;	}

	int keyOut(PlainMsgKey.Flags keyFlags, int code)
	{	return -1;	}

	int mousePress(PlainMsgMouse.Flags mouseFlags, int button, int down, int x,int y, int pressTime)
	{	return -1;	}

	int mouseRelease(PlainMsgMouse.Flags mouseFlags, int button, int down, int x,int y, int pressTime)
	{	return -1;	}

	int mouseMove(PlainMsgMouse.Flags mouseFlags, int down, int x,int y)
	{	return -1;	}

	int mouseIn(PlainMsgMouse.Flags mouseFlags, int down, int x,int y)
	{	return -1;	}

	int mouseOut(PlainMsgMouse.Flags mouseFlags, int down, int x,int y)
	{	return -1;	}

	//////////// CONTAINER RELATED ////////////
	
	/// Insert new item at given position (if positive) or id (if negative)
	public int insert(void* param, int idx)
	{	return -1;	}

	/// Append new item (typically to end, but maybe somewhere in the middle for an ordered list)
	public int append(void* param)
	{	return append(0, param);	}

	public int append(int idx, void* param)
	{	return insert(param, int.max);	}

	/// Remove the item by pointer (if not null), position (if positive), or id (if negative)
	public int remove(int idx, void* param)
	{	return -1;	}

	// Remove given item by object.
	public int remove(void* param)
	{	return -1;	}

	/// Access the item by pointer (if not null), position (if positive), or id (if negative)
	public void* access(int idx, void* param)
	{	return null;	}

	/// adjust flags of vue appropriately (chaining to container). may subclass to prevent changing certain flags.
	public int flag(Flags setFlags, Flags resetFlags)
	{
		if (container.flags & Flags.dead) { // reached top of heirarchy
			return flag(this, setFlags, resetFlags);
		} else {
			return container.flag(this, setFlags, resetFlags);
		}
	}

	/// adjust flags of child appropriately. should be subclassed by containers.
	int flag(PlainVue child, Flags setFlags, Flags resetFlags)
	{
		with (child) {
			resetFlags &= ~setFlags; // flags can not be both set and reset
			Flags newFlags = flags & ~resetFlags | setFlags;
			if (newFlags ^ flags) { // if any flags are different
				flags = newFlags;
				return flagged(setFlags, resetFlags);
			}
		}
		return -1;
	}

	/// gets actual position of vue on display. maybe subclassed if objects do special offsetting of child vue's.
	public int location(inout PlainRect rect)
	{
		rect.left += left;
		rect.right += left;
		rect.top += top;
		rect.bottom += top;
		if (!(container.flags & Flags.dead))
			container.location(rect);
		return 0;
	}

	/// Gets the preferred extents of a given element, usually for calculating an item's best size.
	public int extents(PlainMsgExtents.Elements element, inout PlainRect rect)
	{
		rect.left = rect.right = rect.top = rect.bottom = 0;
		return -1;
	}

	int itemFocusSet()
	{	return -1;	}

	public PlainVue itemFocusGet()
	{	return this;	} // no subitems, so just return self

	public int keyFocusSet(PlainMsgKey.Flags keyFlags, PlainVue newChild)
	{	return -1;	}

	public PlainVue keyFocusGet(PlainMsgKey.Flags keyFlags)
	{	return this;	} // no subitems, so just return self

	public int mouseFocusSet()
	{	return -1;	}

	public PlainVue mouseFocusGet()
	{	return this;	} // no subitems, so just return self

	/// This move call sets position and size, applies to THIS object, and chains to the container version.
	public int move(int leftNew, int topNew, int widthNew, int heightNew)
	{
		return container.move(this, PlainMsgMove.Flags.moveSize, leftNew, topNew, widthNew, heightNew, 0);
	}

	/// This move call sets position, size, & layer, applies to THIS object, and chains to the container version.
	public int move(PlainMsgMove.Flags moveFlags, int leftNew, int topNew, int widthNew, int heightNew, int layerNew)
	{
		return container.move(this, moveFlags, leftNew, topNew, widthNew, heightNew, layerNew);
	}

	/// This move call applies to a child. Useful for containers to subclass function (for selective redrawing)	int move(PlainVue child, PlainMsgMove.Flags moveFlags, int leftNew, int topNew, int widthNew, int heightNew, int layerNew)
	{
		if (!(child.flags & (Flags.dead | Flags.fixedPosition))) {
			with (child) {
				// record previous values
				/*
				int leftPrev = left,
					topPrev = top,
					widthPrev = width,
					heightPrev = height,
					layerPrev = layer;
				*/
				if ( // any of them actually different
					left != leftNew ||
					top != topNew ||
					width != widthNew ||
					height != heightNew
					//layer != layerNew
				) {
					left = leftNew;
					top = topNew;
					width = widthNew;
					height = heightNew;
					//layer = layerNew;
					return moved(moveFlags);
				}
			}
		}
		return -1;
	}

	//////////// ITEM FUNCTIONS ////////////


	public int textSet(int idx, in wchar[] text)
	{	return -1;	}

	public int textGet(int idx, out wchar[] text)
	{	return -1;	}

	public int valueSet(int value, int idx)
	{	return -1;	}

	public int valueGet(int idx)
	{	return -1;	}
	
	public int stateSet(int stateSet, int stateClear)
	{	return -1;	}
	
	public int stateGet()
	{	return -1;	}

	/*public int valueGet(int idx, out int value)
	{
		value = valueGet(idx);
	}*/

	//////////// UTILITY FUNCTIONS ////////////
	
	/// Traces and returns the root of the given vue. note - multiple roots can exist for different chains.
	public final PlainVue getRoot()
	{
		PlainVue root = this;
		while (!(root.container.flags & (Flags.dead))) {
			root = container;
		}
	}
}


/// A little black hole to eat all messages but do absolutely nothing.
/// This substitutable singleton sentinel spares countless null checks throughout the code.
public static PlainVueDeadClass PlainVueDead;

// This empty object is simply a dead end for messages.
private static class PlainVueDeadClass : PlainVue
{
	////////////////////////////////////////
	override int send(inout PlainMsg m_)
	{	return -1;	}
	
	override int draw()
	{	return -1;	}
	
	override int redraw(PlainMsgDraw.Flags redrawFlags)
	{	return -1;	}
	
	override int move(PlainMsgMove.Flags moveFlags, int left_, int top_, int width_, int height_, int layer_)
	{	return -1;	}

	//override int move(PlainVue target, PlainMsgMove.Flags moveFlags, int left_, int top_, int width_, int height_, int layer_)
	//{	return -1;	}
	
	override int keyFocusSet(PlainMsgKey.Flags keyFlags, PlainVue newChild)
	{	return 0;	} // return success always, since this call was probably a dead end in an upward chain

	private int dummyOwner(PlainVue source, inout PlainMsg msg)
	{	return -1;	}
}
