/**
Author:	Dwayne Robinson
Date:	2005-12-05
Since:	2005-12-05
Remark:	Menu.
*/
module plain.plainmenu;


//top,left,text,imageidx,flags,additional items

public import plain.plainvue;
private import plain.plainstyledata;

debug private import std.stdio;

/// Message identifiers
public struct PlainMsgMenu {
	enum : PlainMsg.Mids {
		activate=PlainMsg.midNext,	/// choice activated
		select,	/// choice selected
		scroll,	/// scrolling happened (not actually supported yet, but long menus may need it)
		close,	/// menu is trying to close
	}
	union { PlainMsg msg; PlainMsg.Mids mid; PlainMsg.Flags flags; }
	int selected;
}

class PlainMenu : PlainVue
{
	enum {
		defFlags=PlainVue.defFlags
	};
	struct itemType {
		wchar[] text;
		int imageId;
		int flags;
	}
	enum ItemFlags {
		hidden=1,
		selected=2,
		redraw=4,
		disable=8,
	};
	enum States {
		none=0,
	};

	itemType itemList[];	// ptr to list of items
	States state = States.none;
	int selected; /// selected menu choice
	
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
		//text = cs.text; todo: parse menu entries
		//state = cs.state;
	}
	
	public this(wchar[] text_, States state_)
	{
		this();
		//text = text_; // TODO: actually parse the menu entries :-/
		itemList.length = 3;
		itemList[0].text = "Chobits Sumomo";
		itemList[1].text = "Asuka";
		itemList[2].text = "Rei";
		//state = state_;
	}

	static public PlainVue create(void* param)
	{
		return new PlainMenu(cast(CreationStruct*) param);
	}

	//////////// BASIC NOTIFICATIONS ////////////
	override int draw()
	{
		//-debug writefln("drawing %X text=(%s)  state=%d", this, text, cast(int)state);

		DrawLayers(&PlainMenu_Layers, // todo: change to plainmenu
			width, height,
			0,0,width,height,
			flags, state,
			null, 0
		);

		// Windows hack for text
		// todo: switch to layer later and remove OS dependent code!
		if (itemList.length > 0) {
			SIZE sz;
			GetTextExtentPoint32W(PgfxCurrentDisplay.hdcc, "A", 1, &sz);
			SetTextColor(PgfxCurrentDisplay.hdcc, 0xFF8080FF);
			int x = PgfxCurrentDisplay.left+6,  y = PgfxCurrentDisplay.top+4;
			for (int idx = 0; idx < itemList.length; idx++) {
				if (idx == selected) {
					DrawLayers(&PlainMenuSelect_Layers,
						width, height,
						//10,idx*sz.cy,width,sz.cy,
						4,idx*sz.cy+4, width-4,idx*sz.cy + sz.cy+4,
						flags, state,
						null, 0
					);
				}
				TextOutW(PgfxCurrentDisplay.hdcc, x,y, itemList[idx].text, itemList[idx].text.length);
				y += sz.cy;
			}
		}
		return 0;
	}

	override int mouseMove(PlainMsgMouse.Flags mouseFlags, int down, int x,int y)
	{
		SIZE sz;
		GetTextExtentPoint32W(PgfxCurrentDisplay.hdcc, "A", 1, &sz);
		int row = (y-4) / sz.cy; // todo: remove specific code
		if (row < 0 || row >= itemList.length) return 0;
		selectedSet(row);
		return 0;
	}

	override int mousePress(PlainMsgMouse.Flags mouseFlags, int button, int down, int x,int y, int pressTime)
	{
		// todo: replace all static code with current style based code
		debug(verbose) writefln("PlainMenu.mousePress");
		const static PlainMsgMenu m = {mid: PlainMsgMenu.activate};
		m.selected = selected;
		owner(this, m.msg); // ignore whether owner paid attention to it
		// todo: check the cursor is currently actually over a choice
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

		const static PlainMsgMenu m = {mid: PlainMsgMenu.close};
		m.selected = selected;
		if ( owner(this, m.msg) == 0)	// owner did not want the close
			return 0;
		container.remove(this);
		return 0;
	}

	override int keyPress(PlainMsgKey.Flags keyFlags, int code)
	{
		//debug(verbose) writefln("PlainText.keyPress code=%d", code);
		switch (code) {
		case PlainMsgKey.Codes.enter:
			{
				const static PlainMsgMenu m = {mid: PlainMsgMenu.activate};
				m.selected = selected;
				if ( owner(this, m.msg) == -1) // if owner ignored it, return that the menu ignored it too
					return -1;
			}
			break;
		case PlainMsgKey.Codes.up:
			selectedSet(selected-1);
			break;
		case PlainMsgKey.Codes.down:
			selectedSet(selected+1);
			break;
		case PlainMsgKey.Codes.escape:
			{
				const static PlainMsgMenu m = {mid: PlainMsgMenu.close};
				m.selected = selected;
				if ( owner(this, m.msg) == 0)	// owner did not want the close
					return 0;
				container.remove(this);
				return 0;
			}
			break;
		default:
			return -1;
		}

		return 0;
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

	//////////// PRIVATE STUFF ////////////

	/// Sets/clears state flags.
	protected int selectedSet(int selected_)
	{
		if (selected_ < 0 || selected_ >= itemList.length) return -1;
		if (selected_ != selected) {
			selected = selected_;
			redraw(Flags.redrawPartial);
			const static PlainMsgMenu m = {mid: PlainMsgMenu.select};
			m.selected = selected;
			owner(this, m.msg);
		}
		return 0;
	}


	//////////// OTHER STUFF ////////////

	/// Sets text.
	override public int textSet(int row, in wchar[] text_)
	{
		if (cast(uint)row >= itemList.length) return -2;
		itemList[row].text = text_.dup;
		return 0;
	}

	/// For efficiency, it returns a reference to the string. Be SURE to copy it if you must make changes.
	override public int textGet(int row, out wchar[] text_)
	{
		if (cast(uint)row >= itemList.length) return -2;
		text_.length = 0;
		text_ = itemList[row].text;
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
