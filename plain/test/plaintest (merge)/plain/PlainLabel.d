/**
Author:	Dwayne Robinson
Date:	2005-11-21
Since:	2005-11-21
Remark:	Simple text label.
*/
module plain.plainlabel;

public import plain.plainvue;
private import plain.plainstyledata;

debug private import std.stdio;


class PlainLabel : PlainVue
{
	wchar[] text;			// string is not null terminated
	enum States : uint32 {
		none=0,
		alignLeft=0, // characters start from the left column
		alignRight=1, // characters align to right column
		alignCenter=2, // length of string is centered
		alignMask=3,
		blockLeft=0, // keep characters on left side visible
		blockRight=4, // keep characters on right side visible
		blockCenter=8, // do not allow text to extend either direction off the screen, wrap both sides
		blockMask=12,
	};
	States state = States.none;
	enum {
		defFlags=PlainVue.defFlags|Flags.noMouseFocus|Flags.noKeyFocus
		// maybe the default behavior should accept mouse clicks and forward them
		// to the next item in the container.
	};
	
	//////////// CREATION FUNCTIONS ////////////
	public this() {
		flags = defFlags;
	}

	// vue's should define their own creation struct so they can be indirectly created via createUnknown()
	align(1) struct CreationStruct {
		const PlainVue.CreationStruct cs = {creator : &create};
		const States state = States.none;
		const wchar[] text;
	}

	public this(CreationStruct* cs)
	{
		this();
		state = cs.state;
		text = cs.text;
	}
	
	public this(wchar[] text_, States state_)
	{
		this();
		text = text_;
		state = state_;
	}

	static public PlainVue create(void* param)
	{
		return new PlainLabel(cast(CreationStruct*) param);
	}

	//////////// BASIC NOTIFICATIONS ////////////
	override int draw()
	{
		//-debug writefln("drawing %X", this);

		/*DrawLayers(&PlainBgBare_Layers,
			width, height,
			0,0,width,height,
			flags, 0,
			null, 0
		);*/

		// Windows hack for text
		// todo: switch to layer later and remove OS dependent code!
		if (text.length > 0) {
			version (Windows) { //todo: remove Win specific
				//SIZE sz;
				//GetTextExtentPoint32W(PgfxCurrentDisplay.hdcc, text, text.length, &sz);
				//int x = (PgfxCurrentDisplay.left + (width-sz.cx)/2), y = (PgfxCurrentDisplay.top + (height-sz.cy)/2);
				int x = (PgfxCurrentDisplay.left + 0), y = (PgfxCurrentDisplay.top + 0);
				SetTextColor(PgfxCurrentDisplay.hdcc, 0x00000000);
				TextOutW(PgfxCurrentDisplay.hdcc, x,y, text,text.length);
			}
		}

		return 0;
	}
	
	/// Gets the preferred extents of a given element, usually for calculating an item's best size.
	override int extents(PlainMsgExtents.Elements element, inout PlainRect rect)
	{
		rect.left = rect.right =
		rect.top = rect.bottom = 0;

		switch (element) {
		case element.sizePref:
		case element.sizeMin:
			{
				version (Windows) { //todo: remove Win specific
					SIZE sz;
					GetTextExtentPoint32W(PgfxCurrentDisplay.hdcc, text, text.length, &sz);
					rect.right = sz.cx;
					rect.bottom = sz.cy;
				}
			}
			break;
		case element.sizeMax:
			rect.right = rect.bottom = 32768;
			break;
		case element.placement:
		default:
			return -1;
		}
		return 0;
	}

}
