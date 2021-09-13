/**
Author:	Dwayne Robinson
Date:	2005-11-06
Since:	2005-11-06
Brief:	Container for child UI elements.
Remark:	Windows are transparent (must subclass and override draw())*/
module plain.plaincontainer;

debug private import std.stdio;

public import plain.plainvue;

//ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
abstract class PlainContainer : PlainVue
{
	/*
	Generic container for other items. Used by WindowObj and can be 'subclassed'
	by any other object that needs to be a container. Note that only the most
	of functions can work with a pure container - creation, deletion, and setting
	focus. All higher level functions require a window obj - passing mouse and
	redraw messages.
	*/
	struct itemType {
		PlainVue child;			// single entry pointing to a child
		//uint16 keyIdx;
		//uint16 zlayerIdx;
	}

protected:
	//uint16 totalItems;		// items currently contained
	//uint16 maxItems;		// maximum items that may be created
	itemType itemList[];	// ptr to list of items
};


/// Message identifiers
struct PlainMsgWindow {
	enum : PlainMsg.Mids {
		nop=PlainMsg.midNext, // add more later
	}
}


class PlainWindow : PlainContainer
{
protected:
	PlainVue focusItem;		// ptr to item which currently has focus
	PlainVue keyItem;		// ptr to item which currently has key input
	PlainVue mouseItem;		// ptr to item which mouse cursor was last over
	PlainRectSmall mouseRect;	// bounds of active mouse item's boundary area
	PlainRectSmall  redrawRect;	// bounds of area needing redraw

	//enum {
	//	defFlags=PlainVue.defFlags|Flags.redrawHandled|Flags.groupStart,
	//};

	//////////// CREATION FUNCTIONS ////////////
	public this() {
		flags = defFlags;
		focusItem = PlainVueDead;
		keyItem = PlainVueDead;
		mouseItem = PlainVueDead;
	}

	public this(CreationStruct* cs)
	{
		this();
		//text = cs.text;
	}

	// vue's should define their own creation struct so they can be indirectly created via createUnknown()
	align(1) struct CreationStruct {
		const PlainVue.CreationStruct cs = {creator : &create};
		//const States state = States.none;
		//const wchar[] text;
	}

	static public PlainVue create(void* param)
	{
		return new PlainWindow(cast(CreationStruct*) param);
	}

	//////////// BASIC NOTIFICATIONS ////////////

	// 2005-04-08
	override int draw()
	{
		// save window clips
		// combine window redraw area with its container's redraw area
		// draw all items
		//   preclip for item
		//   redraw item (send it a message)
		//   or item's redrawn area to accumulated window redraw
		// loop
		// return clips to container
		bool redrawEverything = (flags & Flags.redrawBg) != 0;
		debug(verbose) writefln("drawing %X with %d items, display@(%d,%d)  clips=(%d,%d, %d,%d)  redrawall=%d", this, itemList.length, PgfxCurrentDisplay.left, PgfxCurrentDisplay.top, PgfxCurrentDisplay.clip.left, PgfxCurrentDisplay.clip.top, PgfxCurrentDisplay.clip.right, PgfxCurrentDisplay.clip.bottom, cast(int)redrawEverything);
		PgfxDisplay display = PgfxCurrentDisplay.display; // save clips
		int totalItems = itemList.length;
		for (int idx = 0; idx < totalItems; idx++) {
			PlainVue child = itemList[idx].child;
			assert(child != null); // child should never be null!
			if (!(child.flags & (Flags.dead|Flags.hidden)) ) {
				if (redrawEverything) // force cascade of complete redrawing
					child.flags |= Flags.redrawBg;
				if (child.flags & Flags.redrawAny) {
					debug(verbose) writefln("drawing  child %X in %X", child, this);
					if (child.setBorderClips(&display)) {
						child.border.drawOnto(this);
					}
					if (child.setClips(&display)) {
						child.draw();
					}
					child.flags &= ~Flags.redrawAny;
				} else {
					debug(verbose) writefln("redraw: skipping child %X in %X", child, this);
				}
			} else {
				debug(verbose) writefln("redraw: skipping hidden child %X in %X", child, this);
			}
		}
		PgfxCurrentDisplay.display = display; // restore clips
		return 0;
	}

	override public int append(void* param)
	{	return append(int.max, param);	}

	override public int append(int newidx, void* param)
	{
		assert(param != null);
		PlainVue child = cast(PlainVue)param;
		debug(verbose) writefln("Appending %X into %X (PlainContainer.append)", child, this);
		int idx = itemList.length;
		itemList.length = itemList.length+1; // increase list size to allow for new child
		itemList[idx].child = child;
		child.index = idx; // set child's index in parent list (important!)
		child.container = this; // set child's container so it can communicate back
		child.inserted();
		// TODO: update child's flags correctly
		// todo: newidx is completely ignored
		return idx;
	}
	
	// Remove given item by object.
	// 2005-11-22
	override public int remove(void* param)
	{
		return remove(0, param);
	}

	// Remove given item by object or index.
	// 2005-11-22
	override public int remove(int idx, void* param)
	{
		PlainVue child;
		if (param != null) { // if item given, use it
			child = cast(PlainVue)param;
			idx = child.index;
			//-writefln("remove 1 idx=%d %X", idx, child);
			if (idx > itemList.length || itemList[idx].child !is child) {
				return -2;
			}
		}
		// todo: remove by id too
		if (idx < itemList.length) { // otherwise, remove by index
			child = itemList[idx].child;
			itemList[idx].child = PlainVueDead;
			// todo: redraw area behind removed element
			//-writefln("remove 2 idx=%d %X", idx, itemList[idx].child);
			redraw(Flags.redrawBg);
			child.index = -1;	// prevent any interaction (any focus setting commands will fail)
			child.removed();
			child.container = PlainVueDead;	// dissassociate with child
			
			// reclaim any trailing items if deleted last item
			// todo: keep lowest index marker
			for (	idx = itemList.length;
					idx > 0 && (itemList[idx-1].child.flags & Flags.dead);
					idx--) {}
			if (idx != itemList.length) itemList.length = idx;
		}
		return 0;
	}
	
	/// adjust flags of vue appropriately (chaining to container). may subclass to prevent changing certain flags.
	override public int flag(Flags setFlags, Flags resetFlags)
	{
		PlainVue.flag(setFlags, resetFlags);
		if (container.flags & Flags.dead) { // reached top of heirarchy
			return flag(this, setFlags, resetFlags);
		} else {
			return container.flag(this, setFlags, resetFlags);
		}
	}

	/// adjust flags of child appropriately. should be subclassed by containers.
	int flag(PlainVue child, Flags setFlags, Flags resetFlags)
	{
		debug(verbose) writefln("%X.flag2 child=%X flags=%d setFlags=%d resetFlags=%d", this, child, cast(int)child.flags, cast(int)setFlags, cast(int)resetFlags);
		resetFlags &= ~setFlags; // flags can not be both set and reset
		setFlags &= ~child.flags;	// clear any bits which are already set
		resetFlags &= child.flags;	// clear any bits which can not be set (already cleared)
		Flags newFlags = child.flags & ~resetFlags | setFlags;
		if (newFlags ^ child.flags) { // if any flags are different
			debug(verbose) writefln("%X.flag2 child=%X flags=%d setFlags=%d resetFlags=%d newFlags=%d", this, child, cast(int)child.flags, cast(int)setFlags, cast(int)resetFlags, cast(int)newFlags);
			if (setFlags & Flags.hidden) {
				redraw(Flags.redrawBg);
			} else if (resetFlags & Flags.hidden) {
				child.redraw(Flags.redrawBg);
			}
			child.flags = newFlags;
			return child.flagged(setFlags, resetFlags);
		}
		return -1;
	}

	// Sends a single short message to all items contained in a window
	// 2005-04-08
	int sendAllItems(inout PlainMsg msg)
	{
		int totalItems = itemList.length;
		for (int idx = 0; idx < totalItems; idx++) {
			PlainVue child = itemList[idx].child;
			if ( child != null && !(child.flags & Flags.dead)) {
				child.send(msg);
			}
		}
		return 0;
	}

	// 2005-04-08
	int setItemFocus(int focusFlags)
	{
		return 0;
	}

	override int keyPress(PlainMsgKey.Flags keyFlags, int code)
	{
		if (keyItem.flags & (Flags.dead|Flags.disabled)) return -1; // |Flags.noKeyFocus
		return keyItem.keyPress(keyFlags, code);
	}

	override int keyRelease(PlainMsgKey.Flags keyFlags, int code)
	{
		if (keyItem.flags & (Flags.dead|Flags.disabled)) return -1; // |Flags.noKeyFocus
		return keyItem.keyRelease(keyFlags, code);
	}

	override int keyChar(PlainMsgKey.Flags keyFlags, int code)
	{
		if (keyItem.flags & (Flags.dead|Flags.disabled)) return -1; // |Flags.noKeyFocus
		return keyItem.keyChar(keyFlags, code);
	}

	// Date: 2005-11-14
	// Since: 2005-04-09
	// To override this function, override the three above press,release,char
	/*final int sendKey(PlainMsgKey.Flags keyFlags, int code)
	{
		debug(verbose) writefln("Sending key %d with flags %d to %X from %X", code, cast(int)keyFlags, keyItem, this);
		if (keyItem.flags & (Flags.dead|Flags.disabled)) return -1; // |Flags.noKeyFocus
		PlainMsgKey msg;
		msg.flags = keyFlags;
		msg.code = code;
		return keyItem.send(msg);
	}*/

	// date: 2005-11-09
	// since: 2005-04-09
	int sendKeyFocus(PlainMsgKey.Flags keyFlags)
	{
		if (keyItem.flags & Flags.dead) return -1;
		if (keyFlags & PlainMsgKey.Flags.setItem) {
			keyItem.flags |= Flags.keyFocus;
		}
		else {
			keyItem.flags &= ~Flags.keyFocus;
		}
		if (!(keyItem.flags & (Flags.noKeyFocus | Flags.disabled | Flags.dead))) {
			PlainMsgKey m;
			m.flags = keyFlags;
			m.code = 0;
			return keyItem.send(m.msg);
		}
		return -1;
	}
	
	// date: 2005-11-09
	// since: 2005-04-09
	override PlainVue keyFocusGet(PlainMsgKey.Flags keyFlags)
	{
		if ( keyFlags & PlainMsgKey.Flags.recurse
		&& !(keyItem.flags & (Flags.disabled|Flags.noKeyFocus|Flags.dead)))
		{     
			return keyItem.keyFocusGet(keyFlags);
		}
		else {
			return keyItem;
		}
	}

	// date: 2005-11-14
	// since: 2005-04-09
	override int keyFocusSet(PlainMsgKey.Flags keyFlags, PlainVue newChild)
	{
		debug writefln("PlainContainer.keyFocusSet to %X in %X", newChild, this);
		if (newChild.flags & (Flags.noKeyFocus|Flags.disabled|Flags.dead)) {
			debug(verbose) writefln("Focus invalid for %X", this);
			return -2;
		}
	
		if (keyFlags & PlainMsgKey.Flags.silent) {
			keyItem = newChild;
		} else if (flags & Flags.keyFocus) { // if container already has focus, chain no higher
			// only if new item different
			//-debug(verbose) writefln("Setting key focus to 2 %X in %X", newChild, this);
			if (newChild != keyItem) {
				//-debug(verbose) writefln("Setting key focus to 3 %X in %X", newChild, this);
				PlainVue oldChild = keyItem;
				keyItem = newChild;
				keyFlags &= ~(PlainMsg.midMask | PlainMsgKey.Flags.setItem);
				// send focus loss to old item and focus gain to new item
				if (!(oldChild.flags & (Flags.dead|Flags.disabled|Flags.noKeyFocus))) {
					oldChild.flags &= ~Flags.keyFocus;
					oldChild.keyOut(keyFlags | PlainMsg.keyOut, 0);
				}
				if (!(newChild.flags & (Flags.dead|Flags.disabled|Flags.noKeyFocus))) {
					newChild.flags |= Flags.keyFocus;
					newChild.keyIn(keyFlags | PlainMsg.keyIn| PlainMsgKey.Flags.setItem, 0);
					return 0;
				}
			} // else item already has key focus, so nop
		}
		else { // window has no focus, so chain message up and wait for cascade down
			keyItem = newChild;
			if (keyFlags & PlainMsgKey.Flags.setContainer) // chain up containers
				return container.keyFocusSet(keyFlags, this);
		}
		return 0;
	}

	override int mousePress(PlainMsgMouse.Flags mouseFlags, int button, int down, int x,int y, int pressTime)
	{	return sendMouse(mouseFlags, button, down, x,y, pressTime);	}

	override int mouseRelease(PlainMsgMouse.Flags mouseFlags, int button, int down, int x,int y, int pressTime)
	{	return sendMouse(mouseFlags, button, down, x,y, pressTime);	}

	override int mouseMove(PlainMsgMouse.Flags mouseFlags, int down, int x,int y)
	{	return sendMouse(mouseFlags, 0, down, x,y, 0);	}

	override int mouseIn(PlainMsgMouse.Flags mouseFlags, int down, int x,int y)
	{	return sendMouseFocus(getItemAt(x,y), mouseFlags, down, x, y);	}

	override int mouseOut(PlainMsgMouse.Flags mouseFlags, int down, int x,int y)
	{	return sendMouseFocus(mouseItem, mouseFlags, down, x, y);	}

	// date: 2005-11-09
	// since: 2005-04-09
	// remark: Focus in/out messagse are not dispatched by this.
	int sendMouse(PlainMsgMouse.Flags mouseFlags, int button, int down, int x,int y, int pressTime)
	{
		PlainVue child = getItemAt(x, y);
		if (child != mouseItem) {
			debug(verbose) writefln("PlainContainer.sendMouse  focus changed new=%X  old=%X", child, mouseItem);
			sendMouseFocus(mouseItem, mouseFlags, down, x, y);
			sendMouseFocus(child, mouseFlags|PlainMsgMouse.Flags.setItem, down, x, y);
			if ((mouseFlags & PlainMsg.midMask) == PlainMsg.move)
				return 0; // if only a mouse move, just return (do not return both mouse move and in/out)
		}
		// relay msg without modification
		if (!(flags & (Flags.noMouseFocus|Flags.disabled|Flags.dead))) {
			debug(verbose) writefln("PlainContainer.sendMouse  flags=%d button=%d,%d @(%d,%d) time=%d", cast(int)mouseFlags, button, down, x,y, pressTime);
			PlainMsgMouse m;
			m.flags = mouseFlags;
			m.button = button;
			m.down = down;
			m.x = x - child.left;
			m.y = y - child.top;
			m.pressTime = pressTime;
			return child.send(m.msg);
		}
		return -1;
	}
	
	// date: 2005-11-09
	// since: 2005-04-09
	// remark:	Calling this changes the current mouse focus item and adjust flags accordingly.
	int sendMouseFocus(PlainVue child, PlainMsgMouse.Flags mouseFlags, int down, int x, int y)
	{
		if (!(child.flags & (Flags.noMouseFocus|Flags.disabled|Flags.dead))) {
			x -= child.left;
			y -= child.top;
			mouseFlags &= ~(PlainMsg.midMask);
			if (mouseFlags & PlainMsgMouse.Flags.setItem) {
				// send mouse focus in message to new item
				mouseFlags |= PlainMsg.mouseIn|PlainMsgMouse.Flags.setItem;
				child.flags |= Flags.mouseFocus;
				mouseItem = child;	// set new mouse item
				debug(verbose) writefln("PlainContainer.sendMouseFocus  new=%X", child);
				return child.mouseIn(mouseFlags, down, x,y);
			} else {
				// send mouse focus out message to old item
				debug(verbose) writefln("PlainContainer.sendMouseFocus  old=%X", child);
				mouseFlags |= PlainMsg.mouseOut;
				child.flags &= ~Flags.mouseFocus; // clear child's mouse focus status
				mouseItem = PlainVueDead;	// no current mouse item
				return child.mouseOut(mouseFlags, down, x,y);
			}
		}
		debug(verbose) writefln("PlainContainer.sendMouseFocus  failed on=%X", child);
		return -1;
	}
	
	// date: 2005-11-09
	// since: 2005-04-09
	PlainVue getItemAt(int x, int y)
	{
		int idx = itemList.length-1;
		for (; idx >= 0; idx--) {
			PlainVue child = itemList[idx].child;
			if ( child != null
			&& !(child.flags & (Flags.dead|Flags.noMouseFocus|Flags.disabled)))
			{
				if (x >= child.left &&  x < child.left + child.width
				&&  y >= child.top  &&  y < child.top  + child.height)
				{
					//mouseItem = child;
					debug(verbose) writefln("PlainContainer.getItemAt  @(%d,%d) is %X", x,y,child); 
					return child;
				}
			}
		}
		debug(verbose) writefln("PlainContainer.getItemAt @(%d,%d) is %X", x,y, PlainVueDead); 
		return PlainVueDead;
	}
	
	int mouseFocusSet()
	{
		// todo: implement
		return -1;
	}

	PlainVue mouseFocusGet()
	{	return mouseItem;	}

	int itemFocusSet()
	{	return -1;	}

	PlainVue itemFocusGet()
	{	return focusItem;	}

	/// This move call sets position and size, applies to THIS object, and chains to the container version.
	override public int move(int leftNew, int topNew, int widthNew, int heightNew)
	{
		return container.move(this, PlainMsgMove.Flags.moveSize, leftNew, topNew, widthNew, heightNew, 0);
	}

	/// This move call sets position, size, & layer, applies to THIS object, and chains to the container version.
	override public int move(PlainMsgMove.Flags moveFlags, int leftNew, int topNew, int widthNew, int heightNew, int layerNew)
	{
		return container.move(this, moveFlags, leftNew, topNew, widthNew, heightNew, layerNew);
	}

	/// This move call applies to a child. Useful for containers to subclass function (for selective redrawing)
	override int move(PlainVue child, PlainMsgMove.Flags moveFlags, int leftNew, int topNew, int widthNew, int heightNew, int layerNew)
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
				if (!(moveFlags & PlainMsgMove.Flags.move)) {
					leftNew = left;
					topNew = top;
				}
				if (!(moveFlags & PlainMsgMove.Flags.size)) {
					widthNew = width;
					heightNew = height;
				}
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
					child.flags |= Flags.redrawBg;
					this.redraw(Flags.redrawBg);
					return moved(moveFlags);
				}
			}
		}
		return -1;
	}

}
