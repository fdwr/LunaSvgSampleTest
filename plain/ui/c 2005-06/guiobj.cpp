/*
File: guiobj.cpp
Project: Plain
Date: 2005-04-08 / 2004-04-09

Miscellaneous GUI object functions.
*/

#define ucewindowbg_cpp
#include "guidefs.h"
#include "pgfx.h"


int GuiObj::draw()
{



	return 0;
}

// sets clips for an object, in preparation for drawing.
int GuiObj::setClips(PgtDisplay* display)
{
	PgfxDisplay.left = display->left + left;
	PgfxDisplay.top  = display->top  + top;
	PgfxDisplay.clip.left   = (left         > display->clip.left)   ? left         : display->clip.left;
	PgfxDisplay.clip.top    = (top          > display->clip.top )   ? top          : display->clip.top;
	PgfxDisplay.clip.right  = (left + width < display->clip.right)  ? left + width : display->clip.right;
	PgfxDisplay.clip.bottom = (top + height < display->clip.bottom) ? top + height : display->clip.right;
	if (PgfxDisplay.clip.bottom <= PgfxDisplay.clip.top
	 || PgfxDisplay.clip.right <= PgfxDisplay.clip.left) {
		return 0; // no visible area
	}
	return 1;
}

// sets clips for an object's border, in preparation for drawing.
int GuiObj::setBorderClips(PgtDisplay* display)
{
	PgfxDisplay.left = display->left + borderLeft;
	PgfxDisplay.top  = display->top  + borderTop;
	PgfxDisplay.clip.left   = (borderLeft               > display->clip.left)   ? borderLeft               : display->clip.left;
	PgfxDisplay.clip.top    = (borderTop                > display->clip.top )   ? borderTop                : display->clip.top;
	PgfxDisplay.clip.right  = (borderLeft + borderWidth < display->clip.right)  ? borderLeft + borderWidth : display->clip.right;
	PgfxDisplay.clip.bottom = (borderTop + borderHeight < display->clip.bottom) ? borderTop + borderHeight : display->clip.right;
	if (PgfxDisplay.clip.bottom <= PgfxDisplay.clip.top
	 || PgfxDisplay.clip.right <= PgfxDisplay.clip.left) {
		return 0; // no visible area
	}
	return 1;
}

// Meant to be called by an object in itself. Can be called on other objects,
// but should not be called on parent directly (since skipping a level in the
// heirarchy could cause a item to not be redrawn).
//
// obj->redraw(GuiObj::redrawBg) or GuiObj::redrawPartial
int GuiObj::redraw(int redrawFlags)
{
	redrawFlags &= GuiObj::redrawAny;
	if (!(flags & (GuiObj::redrawAny|GuiObj::hidden|GuiObj::null))) {
		flags |= redrawFlags;
		return container->code(container, GuiMsg::redraw);
	}
	flags |= redrawFlags;
	return 0; // return false, since no redraw posted
}
