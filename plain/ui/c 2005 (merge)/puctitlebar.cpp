/*
File: ucetitlebar.cpp
Project: Plain
Date: 2005-04-09

Title bar code.
*/

#define ucetitlebar_cpp
#include "guidefs.h"
#include "pgfx.h"

#ifdef PlainUseTitleBar

// for other languages to call entry member
extern "C" int (* const TitleBarObjEntry)() = (int (__cdecl * const)(void))&TitleBarObj::entry;
// ?entry@TitleBarObj@@SAHPAVGuiObj@@HUGuiMsgParams@@ZZ


// 2005-04-13
int TitleBarObj::entry(GuiObj* obj, int msg, GuiMsgParams gmp, ...)
{
	TitleBarObj* const self = (TitleBarObj*)obj;

	switch (msg & GuiMsg::mask) {
	case GuiMsg::draw:
		self->draw();
		break;

	case GuiMsg::mousePress:
		if (gmp.mouse.col > self->width - 28)
			self->owner->code(self, TitleBarObj::msg::close);
		break;
	case GuiMsg::mouseRelease:
		break;
	case GuiMsg::mouseMove:
		break;
	default:
		//__asm {jmp GuiObj::entry}
		break;
	}

	return 0;
}

int TitleBarObj::focus(int focusFlags)
{
	// redraw
	redraw(GuiObj::redrawPartial);
	return 0;
}

extern "C" PgtLayer TitleBarObj_LayerNormal;

// 2005-04-13
int TitleBarObj::draw()
{
	/*if (state & notContainerFocus) {
		DrawLayers(&TitleBarObj_LayerNoFocus,
			width,
			height,
			0,0,width,height,
			NULL, 0
		);
	}
	else {
		DrawLayers(&TitleBarObj_LayerFocus,
			width,
			height,
			0,0,width,height,
			NULL, 0
		);
	}*/
	DrawLayers(&TitleBarObj_LayerNormal,
		width,
		height,
		0,0,width,height,
		NULL, 0
	);

	// Windows hack for text
	SetTextColor(PgfxDisplay.hdcc, 0x555555);
	TextOutW(PgfxDisplay.hdcc, left+11,top+4, (unsigned short*) text,textLen);
	SetTextColor(PgfxDisplay.hdcc, 0xFFFFFF);
	TextOutW(PgfxDisplay.hdcc, left+10,top+3, (unsigned short*) text,textLen);
	return 0;
}

#endif
