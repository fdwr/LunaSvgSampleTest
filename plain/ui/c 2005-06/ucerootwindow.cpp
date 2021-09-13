/*
File: ucerootwindow.cpp
Project: Plain
Date: 2005-04-08

Window functions.
*/


#define ucerootwindow_cpp
#include "guidefs.h"
#include "pgfx.h"

#ifdef PlainUseWindow

// for other languages to call entry member
extern "C" int (* const RootWindowObjEntry)() = (int (__cdecl * const)(void))&RootWindowObj::entry;
// ?entry@RootWindowObj@@SAHPAVGuiObj@@HUGuiMsgParams@@ZZ


// 2005-04-08
int RootWindowObj::entry(GuiObj* obj, int msg, GuiMsgParams gmp, ...)
{
	RootWindowObj* const self = (RootWindowObj*)obj;

	switch (msg & GuiMsg::mask) {
	case GuiMsg::created:
	case GuiMsg::destroyed:
		self->sendAllItems(msg);
		break;

	case GuiMsg::draw:
		self->draw();
		break;

	case GuiMsg::redraw:
		//self->redraw(GuiObj::redrawPartial);
		self->flags |= (gmp.redraw.flags & GuiObj::redrawAny);
		PgfxFlags |= PgfxFlags_redraw;
		break;

	case GuiMsg::keyPress:
		switch (gmp.key.code) {
		case VK_ESCAPE:
			PostMessage(PgfxDisplay.hwnd, WM_CLOSE, 0,0);
			break;
		}
		break;

	case GuiMsg::mousePress:
	case GuiMsg::mouseRelease:
	case GuiMsg::mouseMove:
	case GuiMsg::mouseIn:
	case GuiMsg::mouseOut:
		self->sendMouse(msg, gmp.mouse.col, gmp.mouse.row);
		break;
	}

	return 0;
}


extern "C" PgtLayer RootWindowObj_Layer;

// 2005-04-08
int RootWindowObj::draw()
{
    // save window clips
    // combine window redraw area with its container's redraw area
    // draw all items
    //   preclip for item
    //   redraw item (send it a message)
    //   or item's redrawn area to accumulated window redraw
    // loop
    // return clips to container

	DrawLayers(&RootWindowObj_Layer,
		width,
		height,
		0,0,width,height,
		NULL, 0
	);

	return WindowObj::draw();
}

#endif
