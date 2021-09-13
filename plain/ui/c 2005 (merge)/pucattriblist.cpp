/*
File: uceattriblist.cpp
Project: Plain
Date: 2005-06-25

Window functions.
*/


#define uceattriblist_cpp
#include "guidefs.h"
#include "pgfx.h"

/*
string label
string text
int value
int lowvalue
int highvalue
int smallstep
int usualstep
int largestep
int flags

*/

#ifdef PlainUseAttribList

// for other languages to call entry member
extern "C" int (* const AttribListObjEntry)() = (int (__cdecl * const)(void))&AttribListObj::entry;
// ?entry@AttribListObj@@SAHPAVGuiObj@@HUGuiMsgParams@@ZZ

// 2005-04-08
int AttribListObj::entry(GuiObj* obj, int msg, GuiMsgParams gmp, ...)
{
	AttribListObj* const self = (AttribListObj*)obj;

	switch (msg & PucMsg::mask) {
	case GuiMsg::created:
	case GuiMsg::destroyed:
		break;

	case GuiMsg::draw:
		self->draw();
		break;

	case GuiMsg::redraw:
		self->redraw(GuiObj::redrawPartial);
		break;

	case GuiMsg::mousePress:
		self->activate(true);
		/*
		get clicked row
		if row not current row, set current row
		if clicked on name, done
		if clicked on value,
			if support internal pop up
				show pop up
			else alert owner
		*/
		break;
	case GuiMsg::mouseRelease:
		self->activate(false);
		break;
	//case GuiMsg::mouseMove:
	//	self->sendMouse(msg, gmp.mouse.col, gmp.mouse.row);
	//	break;
	case GuiMsg::mouseIn:
		self->redraw(GuiObj::redrawPartial);
		//self->sendMouse(msg, gmp.mouse.col, gmp.mouse.row);
		break;
	case GuiMsg::mouseOut:
		self->state &= ~stateDown;
		self->redraw(GuiObj::redrawPartial);
		//self->sendMouse(msg, gmp.mouse.col, gmp.mouse.row);
		break;
	}


	return 0;
}

//extern "C" PgtLayer ButtonObj_LayerNormal;
//extern "C" PgtLayer ButtonObj_LayerHover;
//extern "C" PgtLayer ButtonObj_LayerDown;

// 2005-04-08
int AttribListObj::draw()
{
	/*
	if (state & stateDown) {
		DrawLayers(&ButtonObj_LayerDown,
			width,
			height,
			0,0,width,height,
			NULL, 0
		);
	}
	else if (flags & GuiObj::mouseFocus) {
		DrawLayers(&ButtonObj_LayerHover,
			width,
			height,
			0,0,width,height,
			NULL, 0
		);
	}
	else {
		DrawLayers(&ButtonObj_LayerNormal,
			width,
			height,
			0,0,width,height,
			NULL, 0
		);
	}
	// Windows hack for text
	SetTextColor(PgfxDisplay.hdcc, 0x555555);
	TextOutW(PgfxDisplay.hdcc, left+11,top+4, text,textLen);
	SetTextColor(PgfxDisplay.hdcc, 0xFFFFFF);
	if (state & stateDown) {
		TextOutW(PgfxDisplay.hdcc, left+11,top+4, text,textLen);
	} else {
		TextOutW(PgfxDisplay.hdcc, left+10,top+3, text,textLen);
	}
	*/

	return 0;
}

// 2005-04-12
/*
void AttribListObj::activate(bool mode)
{
	int prestate = state;
	bool trigger = true;
	if (state & stateLock) {
		if (mode) state |= stateDown;
	}
	else if (state & stateToggle) {
		state ^= stateDown;
	}
	else {
		if (mode)	{state |= stateDown; trigger = false;}
		else		{state &= ~stateDown;}
	}
	if (state != prestate) {
		redraw(GuiObj::redrawPartial);
		if (trigger) {			
			// send owner message
			owner->code(this, ButtonObj::msg::click);
		}
	}
}
*/
#endif
