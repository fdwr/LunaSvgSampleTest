/**
Author:	Dwayne Robinson
Date:	2005-11-14
Since:	2005-11-14
Remark:	Text edit.
*/
module plain.plainedit;

public import plain.plainvue;
private import plain.plainstyledata;

debug private import std.stdio;

/// Message identifiers
struct PlainMsgText {
	enum : PlainMsg.Mids {
		change=PlainMsg.midNext,	// text was modified (typed character/bkspc/del)
		select,	// caret was moved (left/right/home/end/mouse click)
		scroll,	// text was scrolled
		reallocString,	//request string reallocation, when the number of characters typed exceeds the maximum size
	}
	union { PlainMsg msg; PlainMsg.Mids mid; PlainMsg.Flags flags; }
}


class PlainEdit : PlainVue
{
	wchar[] text;			// string is not null terminated
	int textLength = 0;	// to allow the actual array to be a different size than the visible length
	int maxLength = 65536;	// maximum number of characters allowed.
	int caretPos;	// character position of caret
	int selectPos;	// character position of selection start
	ushort scrollY, scrollX;	// top pixel row and left pixel column
	version (none) {
		ushort caretRow, caretCol;
		ushort selectRow, selectCol;
	}	
	public enum States : int {
		none=0,
		alignLeft = 0,           // characters start from the left column
		alignRight = 1,           // characters align to right column
		alignCenter = 2,           // length of string is centered
		alignMask = 3,
		blockLeft = 0,           // keep characters on left side visible
		blockRight = 4,           // keep characters on right side visible
		blockCenter = 8,           // do not allow text to extend either direction off the screen, wrap both sides
		blockMask = 12,
		locked = 16,          // text can't be edited
		invalid = 32,          // text should should be specially highlighted for error (maybe all red)
		modified = 64,		// text has been changed (by user, not program).
		//password = 128,	// password entry, so only show character count
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
		textLength = text.length;
		state = cs.state;
	}
	
	public this(wchar[] text_, States state_)
	{
		this();
		text = text_;
		textLength = text.length;
		state = state_;
	}

	static public PlainVue create(void* param)
	{
		return new PlainEdit(cast(CreationStruct*) param);
	}

	//////////// BASIC NOTIFICATIONS ////////////
	override int draw()
	{
		debug(verbose) writefln("drawing %X", this);

		debug(verbose) writefln("drawing %X layers", this);
		DrawLayers(&PlainEdit_Layers,
			width, height,
			0,0,width,height,
			flags, state,
			null, 0
		);

		//-debug writefln("drawing %X text", this);
		// Windows hack for text
		// todo: switch to layer later and remove OS dependent code!
		int caretX = 0;
		if (textLength > 0) {
			// draw text
			IntersectClipRect(PgfxCurrentDisplay.hdcc, PgfxCurrentDisplay.clip.left, PgfxCurrentDisplay.clip.top, PgfxCurrentDisplay.clip.right, PgfxCurrentDisplay.clip.bottom);
			//SIZE sz;
			//GetTextExtentPoint32W(PgfxCurrentDisplay.hdcc, text, textLength, &sz);
			//TextOutW(PgfxCurrentDisplay.hdcc, left+11,top+4, text,textLength);
			int x = PgfxCurrentDisplay.left + scrollX + 4,
				y = PgfxCurrentDisplay.top + scrollY + 1;
			SetTextColor(PgfxCurrentDisplay.hdcc, 0xFF000000);
			TextOutW(PgfxCurrentDisplay.hdcc, x,y, text,textLength);
			SelectClipRgn(PgfxCurrentDisplay.hdcc, null);
			
			// calc caret position
			SIZE sz;
			GetTextExtentPoint32W(PgfxCurrentDisplay.hdcc, text, caretPos, &sz);
			caretX = sz.cx - scrollX;
		}
		DrawLayers(&PlainEditCaret_Layers,
			width, height,
			caretX+3, scrollY, width,height,
			//0,0, width, height,
			flags, state,
			null, 0
		);
		return 0;
	}

	override int mousePress(PlainMsgMouse.Flags mouseFlags, int button, int down, int x,int y, int pressTime)
	{
		if (button == 0 || button == 1) { // only left or right button
			debug(verbose) writefln("Setting focus to self %X", this);
			container.keyFocusSet(PlainMsgKey.Flags.setItem | PlainMsgKey.Flags.setContainer | PlainMsgKey.Flags.byMouse, this);
			return 0;
		}
		return -1; // ignore middle or x buttons
	}

	override int mouseRelease(PlainMsgMouse.Flags mouseFlags, int button, int down, int x,int y, int pressTime)
	{	return -1;	}

	override int keyChar(PlainMsgKey.Flags keyFlags, int code)
	{
		debug(verbose) writefln("PlainEdit.keyChar code=%d", code);
		PlainMsgKey m;
		m.flags = keyFlags;
		m.code = code;
		owner(this, m.msg);
		//code = m.code; // in case owner changed code
		return insertChar(m.code);
	}

	/// Insert the character at the current caret.
	final private int insertChar(int code)
	{
		if (code < 32) return -1; // control character not recognized
		if (state & States.locked) return -2; // can't modify locked string
		if (textLength >= maxLength) {
			const static PlainMsgText m = {mid: PlainMsgText.reallocString};
			owner(this, m.msg);
			if (textLength >= maxLength) return -2; // still string max size, so abort
		}
		
		// modify text
		debug(verbose) writefln("PlainEdit.insertChar  text before >%.*s<", textLength, text);
		if (textLength + 1 > text.length) text.length = text.length + 256; // grow by chunks
		// Grr... D should support overlapping array copies - would be so much cleaner!
		debug(verbose) writefln("PlainEdit.insertChar  textLength=%d  caretPos=%d", textLength, caretPos);
		memmove(&text[caretPos]+1, &text[caretPos], (textLength-caretPos) * text[0].sizeof);
		text[caretPos] = code;
		textLength++;
		state |= States.modified;
		selectPos = caretPos; // todo: remove hack
		debug(verbose) writefln("PlainEdit.insertChar  text after  >%.*s<", textLength, text);

		// notify owner
		const static PlainMsgText m = {mid: PlainMsgText.change};
		owner(this, m.msg);
		setCaretPos(caretPos+1);

		redraw(Flags.redrawPartial);
		return 0;
	}

	/// Delete the character at the current caret.
	final private int deleteChar()
	{
		if (caretPos >= textLength || state & States.locked) return -2; // if caret at end, string empty, or locked
		debug(verbose) writefln("PlainEdit.deleteChar  text before >%.*s<", textLength, text);
		textLength--;
		//if (textLength + 256 < text.length) text.length = text.length - 256; // shrink by chunks
		// Grr... D should support overlapping array copies - would be so much cleaner!
		debug(verbose) writefln("PlainEdit.deleteChar  textLength=%d tl-cp=%d", textLength, textLength-caretPos);
		// Use "&text[caretPos]+1" instead of &text[caretPos+1]" to avoid any out of bounds errors when at end
		memmove(&text[caretPos], &text[caretPos]+1, (textLength-caretPos) * text[0].sizeof);
		state |= States.modified;
		selectPos = caretPos; // todo: remove hack
		debug(verbose) writefln("PlainEdit.deleteChar  text  after  >%.*s<", textLength, text);

		// notify owner
		const static PlainMsgText m = {mid: PlainMsgText.change};
		owner(this, m.msg);

		redraw(Flags.redrawPartial);
		return 0;
	}

	override int keyPress(PlainMsgKey.Flags keyFlags, int code)
	out (result) {
		debug(verbose) writefln("return PlainEdit.keyPress=%d", result);
	}
	body {
		PlainMsgKey m;
		m.flags = keyFlags;
		m.code = code;
		owner(this, m.msg);
		code = m.code; // in case owner changed code

		debug(verbose) writefln("PlainEdit.keyPress code=%d", code);
		alias PlainMsgKey.Codes c;
		switch (code) {
		case c.up:
			break;
		case c.down:
			break;
		case c.left:
			return setCaretPos(caretPos-1);
		case c.right:
			return setCaretPos(caretPos+1);
		case c.insert:
			break;
		case c.deleteKey:
			return deleteChar();
		case c.back:
			if (caretPos <= 0) return -2;
			setCaretPos(caretPos-1);
			return deleteChar();
		case c.select:
			caretPos = 0;
			selectPos = textLength;
			redraw(Flags.redrawPartial);
			break;
		case c.home:
			return setCaretPos(0);
		case c.end:
			return setCaretPos(textLength);
		case c.clear:
			if (textLength <= 0) return -2;
			textLength = 0;
			text.length = 0;
			caretPos = 0;
			selectPos = 0;
			redraw(Flags.redrawPartial);
			break;
		case c.menu:
			break;
		default:
			return -1;
		}
		return 0;
	}
	
	final int setCaretPos(int caretPos_)
	{
		debug(verbose) writefln("PlainEdit.setCaretPos text before >%.*s<", caretPos, text);
		if (caretPos_ > textLength) caretPos_ = textLength;
		if (caretPos_ < 0) caretPos_ = 0;
		if (caretPos_ != caretPos) {
			caretPos = caretPos_;
			selectPos = caretPos; // todo: remove hack
			debug(verbose) writefln("PlainEdit.setCaretPos text  after >%.*s<", caretPos, text);
			const static PlainMsgText m = {mid: PlainMsgText.select};
			owner(this, m.msg);
			redraw(Flags.redrawPartial);
			return 0;
		}
		/*
		if (textLength > 0) {
			SIZE sz;
			GetTextExtentPoint32W(PgfxCurrentDisplay.hdcc, text, textLength, &sz);
			//TextOutW(PgfxCurrentDisplay.hdcc, left+11,top+4, text,textLength);
			int x = PgfxCurrentDisplay.left + scrollY + 1,
				y = PgfxCurrentDisplay.top + scrollY + 1;
			SetTextColor(PgfxCurrentDisplay.hdcc, 0xFFFFFF);
			TextOutW(PgfxCurrentDisplay.hdcc, x,y, text,textLength);
		}
		switch (state & States.alignMask) {
		case alignLeft:
		case alignRight:
		case alignCenter:
		}
		*/

		return -2;
	}

	override int keyIn(PlainMsgKey.Flags keyFlags, int code)
	{
		debug(verbose) writefln("PlainEdit.KeyIn");
		redraw(Flags.redrawPartial);
		return 0;
	}

	override int keyOut(PlainMsgKey.Flags keyFlags, int code)
	{
		debug(verbose) writefln("PlainEdit.KeyOut");
		redraw(Flags.redrawPartial);
		return 0;
	}

	override int mouseIn(PlainMsgMouse.Flags mouseFlags, int down, int x,int y)
	{
		container.keyFocusSet(PlainMsgKey.Flags.setItem | PlainMsgKey.Flags.byMouse, this);
		return 0;
	}

	//////////// OTHER STUFF ////////////

	/// Sets text. *note this does not trigger an owner event and resets the modified flag
	override public int textSet(int row, in wchar[] text_)
	{
		if (row != 0) return -2;
		text.length = 0;
		text = text_.dup;
		textLength = text.length;
		caretPos = selectPos = 0;
		state &= ~States.modified; // <- should it?
		redraw(Flags.redrawBg);
		return 0;
	}

	/// For efficiency, it returns a reference to the string. Be SURE to copy it if you must make changes.
	override public int textGet(int row, out wchar[] text_)
	{
		if (row != 0) return -2;
		text_.length = 0;
		text.length = textLength;
		//text_ = text.dup;
		text_ = text;
		return 0;
	}

	/// Sets/clears state flags.
	override public int stateSet(int stateSet, int stateClear)
	{
		States newState = (state & ~stateClear) | stateSet;
		if (newState != state) {
			state = newState;
			redraw(Flags.redrawBg);
		}
		return 0;
	}
	
	override public int stateGet()
	{
		return state;
	}

	//////////// INVARIANTS ////////////
	invariant {
		assert(textLength <= text.length);
		assert(caretPos >= 0);
		assert(caretPos <= textLength);
		assert(selectPos >= 0);
		assert(selectPos <= textLength);
		//assert(text.length <= maxLength); // allow this in case new text should be set that is longer
	}

	/*
	// default layer graphics
	private const static PgfxPixel pixelNormal = {i32: 0xFF6644DD};
	private const static PgfxLayerImage imageNormal = {
		pixels: &pixelNormal,
		type: PgfxLayerImage.typeImage,
		bpp: 5,		wrap: 4,
		width: 1,		height: 1,
		xorg: 0,		yorg: 0,
	};
	const static PgfxPixel pixelFocus = {i32: 0xFF9977FF};
	const static PgfxLayerImage imageFocus = {
		pixels: &pixelFocus,
		type: PgfxLayerImage.typeImage,
		bpp: 5,		wrap: 4,
		width: 1,		height: 1,
		xorg: 0,		yorg: 0,
	};
	private const static PgfxPixel pixelInvalid = {i32: 0xFFDD4466};
	private const static PgfxLayerImage imageInvalid = {
		pixels: &pixelInvalid,
		type: PgfxLayerImage.typeImage,
		bpp: 5,		wrap: 4,
		width: 1,		height: 1,
		xorg: 0,		yorg: 0,
	};
	
	private const static PgfxLayer[7] layersBackground = [
		{ // invalid state
			image: null,
			flags: PgfxLayer.Bops.stateSpecific | PgfxLayer.Flags.more,
			ifSet: States.invalid, ifClear: 0
		},
		{
			image: &imageInvalid,
			flags: PgfxLayer.Bops.opaque | PgfxLayer.Flags.tile | PgfxLayer.Flags.more,
			left: 0, top: 0,		right: 0, bottom: 0
		},
		{ // valid state
			image: null,
			flags: PgfxLayer.Bops.stateSpecific | PgfxLayer.Flags.more,
			ifSet: 0, ifClear: States.invalid
		},
		{ // key focus (todo: change to item focus to allow relay items)
			image: null,
			flags: PgfxLayer.Bops.stateGeneric | PgfxLayer.Flags.more,
			ifSet: Flags.keyFocus, ifClear: 0
		},
		{
			image: &imageFocus,
			flags: PgfxLayer.Bops.opaque | PgfxLayer.Flags.tile | PgfxLayer.Flags.more,
			left: 0, top: 0,		right: 0, bottom: 0
		},
		{ // normal (no key focus)
			image: null,
			flags: PgfxLayer.Bops.stateGeneric | PgfxLayer.Flags.more,
			ifSet: 0, ifClear: Flags.keyFocus
		},
		{
			image: &imageNormal,
			flags: PgfxLayer.Bops.opaque | PgfxLayer.Flags.tile,
			left: 0, top: 0,		right: 0, bottom: 0
		},
	];

	const static PgfxPixel pixelCaret = {i32: 0xFFFFFFFF};
	const static PgfxLayerImage imageCaret = {
		pixels: &pixelCaret,
		type: PgfxLayerImage.typeImage,
		bpp: 5,		wrap: 4,
		width: 1,		height: 1,
		xorg: 0,		yorg: 0,
	};
	const static PgfxLayer layersCaret = {
		image: &imageCaret,
		flags: PgfxLayer.Bops.opaque | PgfxLayer.Flags.tile,
		left: 0, top: 0,		right: 0, bottom: 0
	};
	*/

}
