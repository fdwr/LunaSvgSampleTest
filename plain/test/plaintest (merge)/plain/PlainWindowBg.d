/**
Author:	Dwayne Robinson
Date:	2005-11-15
Since:	2005-11-15
Remark:	Nearly bare background for window or other container.
*/
module plain.plainwindowbg;

public import plain.plainvue;
private import plain.plainstyledata;

debug private import std.stdio;


class PlainWindowBg : PlainVue
{
	enum {
		defFlags=PlainVue.defFlags
	};
	
	//////////// CREATION FUNCTIONS ////////////
	public this() {
		flags = defFlags|Flags.fixedLayer|Flags.fixedPosition|Flags.noItemFocus|Flags.noKeyFocus;
	}

	/*
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

	// vue's should define their own creation struct so they can be indirectly created via createUnknown()
	align(1) struct CreationStruct {
		const PlainVue.CreationStruct cs = {creator : &create};
		const States state = States.none;
		const wchar[] text;
	}

	static public PlainVue create(void* param)
	{
		return new PlainBgBare(cast(CreationStruct*) param);
	}*/

	//////////// BASIC NOTIFICATIONS ////////////
	override int draw()
	{
		//-debug writefln("drawing %X", this);

		DrawLayers(&PlainWindowBg_Layers,
			width, height,
			0,0,width,height,
			flags, 0,
			null, 0
		);

		return 0;
	}
	
	override int inserted()
	{
		debug writefln("Inserted %X into %X", this, container);
		left = 0;
		top = 0;
		width = container.width;
		height = container.height;
		return -1;
	}

}
