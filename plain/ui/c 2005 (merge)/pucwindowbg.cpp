/*
File: ucewindowbg.cpp
Project: Plain
Date: 2005-04-09

Window background functions.
*/

#define ucewindowbg_cpp
#include "guidefs.h"
#include "pgfx.h"

#ifdef PlainUseWindowBg

// for other languages to call entry member
extern "C" int (* const WindowBgObjEntry)() = (int (__cdecl * const)(void))&WindowBgObj::entry;
// ?entry@WindowBgObj@@SAHPAVGuiObj@@HUGuiMsgParams@@ZZ


int WindowBgObj::entry(GuiObj* obj, int msg, GuiMsgParams gmp, ...)
{
	WindowBgObj* const self = (WindowBgObj*)obj;

	switch (msg & GuiMsg::mask) {
	case GuiMsg::draw:
		self->draw();
		break;

	default:
		//__asm {jmp GuiObj::entry}
		break;
	}

	return 0;
}

int WindowBgObj::focus(int focusFlags)
{
	// redraw
	
	return 0;
}

int WindowBgObj::draw()
{
	return 0;
}

#endif
