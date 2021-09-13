/*
File: ucepreview.cpp
Project: Plain
Date: 2005-04-08

Window functions.
*/


#define ucepreview_cpp
#include "guidefs.h"
#include "pgfx.h"

#ifdef PlainUsePreview

// for other languages to call entry member
extern "C" int (* const PreviewObjEntry)() = (int (__cdecl * const)(void))&PreviewObj::entry;
// ?entry@PreviewObj@@SAHPAVGuiObj@@HUGuiMsgParams@@ZZ


// 2005-04-08
int PreviewObj::entry(GuiObj* obj, int msg, GuiMsgParams gmp, ...)
{
	PreviewObj* const self = (PreviewObj*)obj;

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
		PgfxCursorSet(&PlainCursor_Pan);
		break;
	case GuiMsg::mouseRelease:
		PgfxCursorSet(&PlainCursor_Default);
		break;
	case GuiMsg::mouseMove:
		if (msg & MouseMsgFlags::leftButton) {
			self->scrollLeft -= PlainMouse.colDif;
			self->scrollTop -= PlainMouse.rowDif;
			self->redraw(GuiObj::redrawPartial);
		}
		break;
	case GuiMsg::mouseIn:
		//self->sendMouse(msg, gmp.mouse.col, gmp.mouse.row);
		break;
	case GuiMsg::mouseOut:
		PgfxCursorSet(&PlainCursor_Default);
		//self->sendMouse(msg, gmp.mouse.col, gmp.mouse.row);
		break;
	}


	return 0;
}

// 2005-04-08
int PreviewObj::draw()
{
    // save window clips
    // combine window redraw area with its container's redraw area
    // draw all items
    //   preclip for item
    //   redraw item (send it a message)
    //   or item's redrawn area to accumulated window redraw
    // loop
    // return clips to container

	/*
	BlitOpaque32i32i(PgfxDisplay.pixels, PgfxDisplay.wrap,
		left, top+128,  128, 128,
		image->pixels,128*4,  0,0);
		*/
	if (image == NULL || image->pixels == NULL) return -1;

	BlitImage(PgtBop_opaque,
		scrollLeft, scrollTop, image->width, image->height,
		image, 0,0);

	return 0;
}

#endif
