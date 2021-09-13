/**
Author:	Dwayne Robinson
Date:	2005-11-09
Since:	2005-11-09
Remark:	Main window and thread loop.
*/
module plain.plainbutton;

public import plain.plainvue;
private import plain.plainstyledata;

debug private import std.stdio;

/// Message identifiers
struct PlainMsgButton {
	enum : PlainMsg.Mids {
		activate=PlainMsg.midNext,
	}
	union { PlainMsg msg; PlainMsg.Mids mid; PlainMsg.Flags flags; }
}

class PlainButton : PlainVue
{
	wchar[] text;			// string is not null terminated
	enum States {
		none=0,
		down=1<<0,
		neutral=3<<0,
		valueMask=3<<0,
		lock=1<<2,
		toggle=1<<4,
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
		const wchar[] text;
		const States state = States.none;
	}

	public this(CreationStruct* cs)
	{
		this();
		text = cs.text;
		state = cs.state;
	}
	
	public this(wchar[] text_, States state_)
	{
		this();
		text = text_;
		state = state_;
	}

	static public PlainVue create(void* param)
	{
		return new PlainButton(cast(CreationStruct*) param);
	}

	//////////// BASIC NOTIFICATIONS ////////////
	override int draw()
	{
		//-debug writefln("drawing %X text=(%s)  state=%d", this, text, cast(int)state);

		DrawLayers(&PlainButton_Layers,
			width, height,
			0,0,width,height,
			flags, state,
			null, 0
		);
		
		// Windows hack for text
		// todo: switch to layer later and remove OS dependent code!
		if (text.length > 0) {
			SIZE sz;
			GetTextExtentPoint32W(PgfxCurrentDisplay.hdcc, text, text.length, &sz);
			//TextOutW(PgfxCurrentDisplay.hdcc, left+11,top+4, text,text.length);
			int x = (PgfxCurrentDisplay.left + (width-sz.cx)/2), y = (PgfxCurrentDisplay.top + (height-sz.cy)/2);
			SetTextColor(PgfxCurrentDisplay.hdcc, 0x555555);
			/*if (state & States.down) {
				TextOutW(PgfxCurrentDisplay.hdcc, x+1,y+1, text,text.length);
			} else {
				TextOutW(PgfxCurrentDisplay.hdcc, x+2,y+2, text,text.length);
			}
			SetTextColor(PgfxCurrentDisplay.hdcc, 0xFFFFFF);
			*/
			SetTextColor(PgfxCurrentDisplay.hdcc, 0xFF000000);
			TextOutW(PgfxCurrentDisplay.hdcc, x,y, text,text.length);
		}

		return 0;
	}

	override int mousePress(PlainMsgMouse.Flags mouseFlags, int button, int down, int x,int y, int pressTime)
	{
		debug(verbose) writefln("PlainButton.mousePress");
		activate(1);
		return 0;
	}
		
	override int mouseRelease(PlainMsgMouse.Flags mouseFlags, int button, int down, int x,int y, int pressTime)
	{
		activate(0);
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
		unpress();
		redraw(Flags.redrawPartial);
		return 0;
	}

	override int keyPress(PlainMsgKey.Flags keyFlags, int code)
	{
		//debug(verbose) writefln("PlainText.keyPress code=%d", code);
		if (code == PlainMsgKey.Codes.enter) {
			activate(2); // always trigger
		} else if (code == PlainMsgKey.Codes.space) {
			if (!(keyFlags & PlainMsgKey.Flags.repeat))
				activate(1); // push in
		} else {
			unpress(); // unpress anything that might have been pressed
			return -1;
		}
		return 0;
	}

	override int keyRelease(PlainMsgKey.Flags keyFlags, int code)
	{
		//-debug(verbose) writefln("PlainText.keyRelease code=%d", code);
		if (code != PlainMsgKey.Codes.space) return -1;
		activate(0);
		return 0;
	}

	override int keyIn(PlainMsgKey.Flags keyFlags, int code)
	{
		redraw(Flags.redrawPartial);
		return 0;
	}

	override int keyOut(PlainMsgKey.Flags keyFlags, int code)
	{
		unpress();
		redraw(Flags.redrawPartial);
		return 0;
	}

	// date: 2005-11-04
	// since: 2005-04-12
	// params:
	//		mode	0=button up, 1=button down, 2=activate regardless
	void activate(int mode)
	{
		int prestate = state;
		bool trigger = false;
		if (state & States.lock) {
			if (mode) { // lock it
				state |= States.down;
				if (prestate != state) trigger = true;
			}
		}
		else if (state & States.toggle) {
			if (mode) { // toggle it
				state ^= States.down;
				trigger = true;
			}
		}
		else {
			switch (mode) {
			case 1:
				state |= States.down; // push but do not trigger yet
				break;
			case 0:
				if (state & States.down)
			case 2:
					trigger = true;
				state &= ~States.down;
			}
		}
		if (state != prestate || trigger) redraw(Flags.redrawPartial);
		if (trigger) {
			// send owner message
			const static PlainMsgButton m = {mid: PlainMsgButton.activate};
			owner(this, m.msg);
		}
	}
	
	void unpress()
	{
		// if state down, not locked, not toggled
		if ((state & States.down) & !(state & (States.lock|States.toggle))) {
			state &= ~States.down;
			redraw(Flags.redrawPartial);
		}
	}

	//////////// OTHER STUFF ////////////

	/// Sets text.
	override public int textSet(int row, in wchar[] text_)
	{
		if (row != 0) return -2;
		text.length = 0;
		text = text_.dup;
		return 0;
	}

	/// For efficiency, it returns a reference to the string. Be SURE to copy it if you must make changes.
	override public int textGet(int row, out wchar[] text_)
	{
		if (row != 0) return -2;
		text_.length = 0;
		text_ = text;
		return 0;
	}

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

}
