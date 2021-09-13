/**
Author:	Dwayne Robinson
Date:	2005-11-22
Since:	2005-11-22
Remark:	Text list item.
*/
module plain.plainlist;


//top,left,text,imageidx,flags,additional items

public import plain.plainvue;
private import plain.plainstyledata;

debug private import std.stdio;

/// Message identifiers
struct PlainMsgList {
	enum : PlainMsg.Mids {
		activate=PlainMsg.midNext,
		select,
		scroll,
	}
	union { PlainMsg msg; PlainMsg.Mids mid; PlainMsg.Flags flags; }
}

class PlainList : PlainVue
{
	struct itemType {
		wchar[] text;
		int imageId;
		int flags;
		short left, top;	// not useful for flat lists, but needed for x,y lists
	}
	itemType itemList[];	// ptr to list of items
	wchar[] text;			// default text when list is empty
	enum States {
		none=0,
	};
	States state = States.none;
	enum {
		defFlags=PlainVue.defFlags
	};
	
	//////////// CREATION FUNCTIONS ////////////
	public this() {
		flags = defFlags;
	}

	// vue's should define their own creation struct so they can be indirectly created via createUnknown()
	align(1) struct CreationStruct {
		const PlainVue.CreationStruct cs = {creator : &create};
		//const States state = States.none;
		const wchar[] text;
	}

	public this(CreationStruct* cs)
	{
		this();
		text = cs.text;
		//state = cs.state;
	}
	
	public this(wchar[] text_, States state_)
	{
		this();
		text = text_;
		itemList.length = 3;
		itemList[0].text = "Hello";
		itemList[1].text = "Blue";
		itemList[2].text = "Belldandy";
		//state = state_;
	}

	static public PlainVue create(void* param)
	{
		return new PlainList(cast(CreationStruct*) param);
	}

	//////////// BASIC NOTIFICATIONS ////////////
	override int draw()
	{
		//-debug writefln("drawing %X text=(%s)  state=%d", this, text, cast(int)state);

		DrawLayers(&PlainList_Layers,
			width, height,
			0,0,width,height,
			flags, state,
			null, 0
		);

		// Windows hack for text
		// todo: switch to layer later and remove OS dependent code!
		debug writefln("here");
		if (itemList.length <= 0 && text.length > 0) {
			debug writefln("here2");
			SIZE sz;
			GetTextExtentPoint32W(PgfxCurrentDisplay.hdcc, text, text.length, &sz);
			int x = (PgfxCurrentDisplay.left + (width-sz.cx)/2), y = (PgfxCurrentDisplay.top + 1); //(height-sz.cy)/2);
			SetTextColor(PgfxCurrentDisplay.hdcc, 0xFF8080FF);
			TextOutW(PgfxCurrentDisplay.hdcc, x,y, text,text.length);
		} else {
			debug writefln("here3");
			SIZE sz;
			GetTextExtentPoint32W(PgfxCurrentDisplay.hdcc, "A", 1, &sz);
			SetTextColor(PgfxCurrentDisplay.hdcc, 0xFF8080FF);
			int x = PgfxCurrentDisplay.left+4,  y = PgfxCurrentDisplay.top;
			for (int idx = 0; idx < itemList.length; idx++) {
				TextOutW(PgfxCurrentDisplay.hdcc, x,y, itemList[idx].text, itemList[idx].text.length);
				y += sz.cy;
			}
		}
		return 0;
	}

	override int mousePress(PlainMsgMouse.Flags mouseFlags, int button, int down, int x,int y, int pressTime)
	{
		debug(verbose) writefln("PlainList.mousePress");
		return 0;
	}
		
	override int mouseRelease(PlainMsgMouse.Flags mouseFlags, int button, int down, int x,int y, int pressTime)
	{
		return 0;
	}

	//int mouseMove() { }

	override int mouseIn(PlainMsgMouse.Flags mouseFlags, int down, int x,int y)
	{
		container.keyFocusSet(PlainMsgKey.Flags.setItem | PlainMsgKey.Flags.setContainer | PlainMsgKey.Flags.byMouse, this);
		redraw(Flags.redrawPartial);
		return 0;
	}
	
	override int mouseOut(PlainMsgMouse.Flags mouseFlags, int down, int x,int y)
	{
		redraw(Flags.redrawPartial);
		return 0;
	}

	override int keyPress(PlainMsgKey.Flags keyFlags, int code)
	{
		//debug(verbose) writefln("PlainText.keyPress code=%d", code);
		if (code == PlainMsgKey.Codes.enter) {
		}
		return -1;
	}

	override int keyRelease(PlainMsgKey.Flags keyFlags, int code)
	{
		//-debug(verbose) writefln("PlainText.keyRelease code=%d", code);
		if (code != PlainMsgKey.Codes.space) return -1;
		return -1;
	}

	override int keyIn(PlainMsgKey.Flags keyFlags, int code)
	{
		redraw(Flags.redrawPartial);
		return 0;
	}

	override int keyOut(PlainMsgKey.Flags keyFlags, int code)
	{
		redraw(Flags.redrawPartial);
		return 0;
	}

	//////////// OTHER STUFF ////////////

	/// Sets text.
	override public int textSet(int row, in wchar[] text_)
	{
		if (cast(uint)row >= itemList.length) return -2;
		//text.length = 0;
		//text = text_.dup;
		text.length = 0;
		itemList[row].text = text_.dup;
		return 0;
	}

	/// For efficiency, it returns a reference to the string. Be SURE to copy it if you must make changes.
	override public int textGet(int row, out wchar[] text_)
	{
		if (cast(uint)row >= itemList.length) return -2;
		//text_.length = 0;
		//text_ = text;
		text.length = 0;
		text = itemList[row].text;
		return 0;
	}

	/*
	/// Sets/clears state flags.
	override public int stateSet(int stateSet, int stateClear)
	{
		States newState = (state & ~stateClear) | stateSet;
		if (newState != state) {
			state = newState;
			redraw(Flags.redrawPartial);
		}
		return 0;
	}
	
	override public int stateGet()
	{
		return state;
	}
	*/

	/*
	/// Sets/clears values.
	override public int valueSet(int idx, int value)
	{
		if (idx != 0) return -2;
		States newState = (state & ~States.valueMask) | value;
		//-debug writefln("valueSet %d %d", cast(int)newState, cast(int)state);
		if (newState != state) {
			//-debug writefln("valueSet different %d %d", cast(int)newState, cast(int)state);
			state = newState;
			redraw(Flags.redrawPartial);
		}
		return 0;
	}
	
	override public int valueGet(int idx)
	{
		if (idx != 0) return -2;
		return state & States.valueMask;
	}
	*/
}
