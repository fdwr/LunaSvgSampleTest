/*
File: uceborder.cpp
Project: Plain
Date: 2005-04-08

Window functions.
*/


#define uceborder_cpp
#include "guidefs.h"
#include "pgfx.h"

#ifdef PlainUsePreview

// for other languages to call entry member
extern "C" int (* const BorderObjEntry)() = (int (__cdecl * const)(void))&BorderObj::entry;
// ?entry@BorderObj@@SAHPAVGuiObj@@HUGuiMsgParams@@ZZ
extern "C" OwnerCallbackObj BorderObjInstance = {(int (__cdecl *)(GuiObj *,int,...))&BorderObj::entry};


// 2005-04-08
int BorderObj::entry(GuiObj* obj, int msg, GuiMsgParams gmp, ...)
{
	BorderObj* const self = (BorderObj*)obj;

	switch (msg & GuiMsg::mask) {
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
	case GuiMsg::mouseRelease:
		break;
	case GuiMsg::mouseMove:
		//self->sendMouse(msg, gmp.mouse.col, gmp.mouse.row);
		break;
	case GuiMsg::mouseIn:
		//self->sendMouse(msg, gmp.mouse.col, gmp.mouse.row);
		break;
	case GuiMsg::mouseOut:
		//self->sendMouse(msg, gmp.mouse.col, gmp.mouse.row);
		break;
	}


	return 0;
}

extern "C" PgtLayer BorderObj_Layer;

// 2005-04-08
int BorderObj::draw()
{
	DrawLayers(&BorderObj_Layer,
		width,
		height,
		0,0,borderWidth,borderHeight,
		NULL, 0
	);
	return 0;
}

#endif
