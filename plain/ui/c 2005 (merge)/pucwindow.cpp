/*
File: ucewindow.cpp
Project: Plain
Date: 2005-04-08

Window functions.
*/


#define ucewindow_cpp
#include "guidefs.h"
#include "pgfx.h"

#ifdef PlainUseWindow

// for other languages to call entry member
extern "C" int (* const WindowObjEntry)() = (int (__cdecl * const)(void))&WindowObj::entry;
// ?entry@WindowObj@@SAHPAVGuiObj@@HUGuiMsgParams@@ZZ


// 2005-04-08
int WindowObj::entry(GuiObj* obj, int msg, GuiMsgParams gmp, ...)
{
	WindowObj* const self = (WindowObj*)obj;

	switch (msg & GuiMsg::mask) {
	case GuiMsg::created:
	case GuiMsg::destroyed:
		self->sendAllItems(msg);
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


// 2005-04-08
int WindowObj::draw()
{
    // save window clips
    // combine window redraw area with its container's redraw area
    // draw all items
    //   preclip for item
    //   redraw item (send it a message)
    //   or item's redrawn area to accumulated window redraw
    // loop
    // return clips to container

	PgtDisplay display = PgfxDisplay.display; // save clips
	ContainerObjItem* pwoi = itemList;
	for (int idx = totalItems; idx > 0; idx--, pwoi++) {
		GuiObj* child = pwoi->child;
		if ( child != NULL
		&& !(child->flags & (GuiObj::null|GuiObj::hidden)))
		{
			if (child->setBorderClips(&display)) {
				child->border->code(child, GuiMsg::draw);
			}
			if (child->setClips(&display)) {
				child->code(child, GuiMsg::draw);
			}
			child->flags &= ~GuiObj::redrawAny;
		}
	}
	PgfxDisplay.display = display; // restore clips
	return 0;
}

// Sends a single short message to all items contained in a window
// 2005-04-08
int WindowObj::sendAllItems(int msg)
{
	ContainerObjItem* pwoi = itemList;
	for (int idx = totalItems; idx > 0; idx--, pwoi++) {
		GuiObj* child = pwoi->child;
		if ( child != NULL && !(child->flags & GuiObj::null)) {
			pwoi->child->code(pwoi->child, msg);
		}
	}
	return 0;
}

// 2005-04-08
int WindowObj::setItemFocus(int focusFlags)
{




	return 0;
}

// 2005-04-09
int WindowObj::sendKey(int msg, int code)
{
	if ( keyItem != NULL
	&& !(keyItem->flags & (GuiObj::null|GuiObj::disabled))) // |GuiObj::noKeyFocus
	{
		return keyItem->code(keyItem, msg, code);
	}
	return -1;
}

// 2005-04-09
int WindowObj::setKeyFocus(int msg, GuiObj* newChild)
{
	if (newChild == NULL
	|| (newChild->flags & (GuiObj::noKeyFocus|GuiObj::disabled|GuiObj::null)))
		return -1;

	if (msg & KeyMsgFlags::silent) {
		keyItem = newChild;
	}
	else if (flags & GuiObj::keyFocus) {
		// only if new item different
		if (newChild != keyItem) {
			GuiObj* oldChild = keyItem;
			keyItem = newChild;
			msg &= ~(GuiMsg::mask | KeyMsgFlags::setItem);
			if (!(flags & GuiObj::null|GuiObj::disabled|GuiObj::noKeyFocus)) {
				oldChild->flags &= ~GuiObj::keyFocus;
				oldChild->code(oldChild, msg | GuiMsg::keyOut);
			}
			if (!(flags & GuiObj::null|GuiObj::disabled|GuiObj::noKeyFocus)) {
				newChild->flags |= GuiObj::keyFocus;
				return newChild->code(newChild, msg | GuiMsg::keyOut| KeyMsgFlags::setItem);
			}
		}
	}
	else { // window has no focus
		keyItem = newChild;
		// chain up containers
		if (msg & KeyMsgFlags::setContainer) {
			return container->code(container, msg, this);
		}
	}
	return 0;
}

// 2005-04-09
int WindowObj::relayKeyFocus(int msg)
{
	if (keyItem == NULL) return -1;
	if (msg & KeyMsgFlags::setItem) {
		keyItem->flags |= GuiObj::keyFocus;
	}
	else {
		keyItem->flags &= ~GuiObj::keyFocus;
	}
	if (!(keyItem->flags & GuiObj::noKeyFocus|GuiObj::disabled|GuiObj::null)) {
		return keyItem->code(keyItem, msg, this);
	}
	return -1;
}

// 2005-04-09
GuiObj* WindowObj::getKeyFocus(int msg)
{
	if ( msg & KeyMsgFlags::recurse
	&& !(keyItem->flags & (GuiObj::disabled|GuiObj::noKeyFocus|GuiObj::null)))
	{
		return (GuiObj*)keyItem->code(keyItem, msg, this);
	}
	else {
		return keyItem;
	}
}

// 2005-04-09
int WindowObj::sendMouse(int msg, int col, int row)
{
	GuiObj* child = getItemAt(col, row);
	if (child != mouseItem) {
		sendMouseFocus(mouseItem, msg, 0, col, row);
		mouseItem = child;
		return sendMouseFocus(child, msg, GuiObj::mouseFocus, col, row);
	}
	// relay msg without modification
	if (!(flags & (GuiObj::noMouseFocus|GuiObj::disabled|GuiObj::null))) {
		col -= child->left;
		row -= child->top;
		return child->code(child, msg, col, row);
	}
	return -1;
}

// 2005-04-09
int WindowObj::sendMouseFocus(GuiObj* child, int msg, int focusFlag, int col, int row)
{
	child->flags &= ~GuiObj::mouseFocus;

	if (!(child->flags & (GuiObj::noMouseFocus|GuiObj::disabled|GuiObj::null))) {
		msg &= ~GuiMsg::mask;
		msg |= (focusFlag) ? (GuiMsg::mouseIn|MouseMsgFlags::setItem) : GuiMsg::mouseOut;
		child->flags |= focusFlag;
		col -= child->left;
		row -= child->top;
		return child->code(child, msg, col, row);
	}
	return -1;
}


// 2005-04-09
GuiObj* WindowObj::getItemAt(int col, int row)
{
	int idx = totalItems-1;
	ContainerObjItem* pwoi = &itemList[idx];
	for (; idx >= 0; idx--, pwoi--) {
		GuiObj* child = pwoi->child;

		if ( child != NULL
		&& !(child->flags & (GuiObj::null|GuiObj::noMouseFocus|GuiObj::disabled)))
		{
			if (col >= child->left &&  col < child->left + child->width
			&&  row >= child->top  &&  row < child->top  + child->height)
			{
				//mouseItem = child;
				return child;
			}
		}
	}
	return &NullGuiObj;
}

#endif
