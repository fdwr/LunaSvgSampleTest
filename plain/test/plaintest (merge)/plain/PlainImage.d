/**
Author:	Dwayne Robinson
Date:	2005-12-08
Since:	2005-12-08
Remark:	Image.
*/
module plain.plainimage;

//top,left,text,imageidx,flags,additional items

public import plain.plainvue;
private import plain.plainstyledata;

debug private import std.stdio;

/// Message identifiers
struct PlainMsgImage {
	enum : PlainMsg.Mids {
		activate=PlainMsg.midNext,	/// clicked
	}
	union { PlainMsg msg; PlainMsg.Mids mid; PlainMsg.Flags flags; }
}

class PlainImage : PlainVue
{
	enum {
		defFlags=PlainVue.defFlags
	};
	enum States {
		none=0,
	};

	PgfxLayer* layers;	// list of layers
	States state = States.none;
	
	//////////// CREATION FUNCTIONS ////////////
	public this() {
		flags = defFlags;
	}

	// vue's should define their own creation struct so they can be indirectly created via createUnknown()
	align(1) struct CreationStruct {
		const PlainVue.CreationStruct cs = {creator : &create};
		//const States state = States.none;
		const wchar[] filename;
	}

	public this(CreationStruct* cs)
	{
		this();
		//text = cs.text; todo: parse menu entries
		//state = cs.state;
	}
	
	public this(wchar[] file_, States state_)
	{
		this();
		layers = null;
		state = state_;
		// load file? or from memory?
	}

	public this(PgfxLayer* layers_, States state_)
	{
		this();
		layers = layers_;
		state = state_;
		// load file? or from memory?
	}

	static public PlainVue create(void* param)
	{
		return new PlainImage(cast(CreationStruct*) param);
	}

	//////////// BASIC NOTIFICATIONS ////////////
	override int draw()
	{
		//-debug writefln("drawing %X text=(%s)  state=%d", this, text, cast(int)state);

		if (layers != null) {
			DrawLayers(layers,
				width, height,
				0,0,width,height,
				flags, state,
				null, 0
			);
		}
		return 0;
	}

	override int mousePress(PlainMsgMouse.Flags mouseFlags, int button, int down, int x,int y, int pressTime)
	{
		// todo: replace all static code with current style based code
		debug(verbose) writefln("PlainImage.mousePress");
		const static PlainMsgImage m = {mid: PlainMsgImage.activate};
		owner(this, m.msg); // ignore whether owner paid attention to it
		return 0;
	}
		
	/*
	override int mouseRelease(PlainMsgMouse.Flags mouseFlags, int button, int down, int x,int y, int pressTime)
	{
		return 0;
	}
	*/

	override int mouseIn(PlainMsgMouse.Flags mouseFlags, int down, int x,int y)
	{
		redraw(Flags.redrawPartial);	// just in case style dictates different appearance for hover
		return 0;
	}
	
	override int mouseOut(PlainMsgMouse.Flags mouseFlags, int down, int x,int y)
	{
		redraw(Flags.redrawPartial);	// just in case style dictates different appearance for hover
		return 0;
	}

	//////////// PRIVATE STUFF ////////////

	/// Sets/clears state flags.
	public int layersSet(PgfxLayer* layers_)
	{
		layers = layers_;
		redraw(Flags.redrawBg);
		return 0;
	}

}
