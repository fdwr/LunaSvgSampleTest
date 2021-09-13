/**
Author:	Dwayne Robinson
Date:	2005-11-11
Since:	2005-11-11
Brief:	Root container for all other UI elements (special handling of certain functions).
Remark:	You can create your own root if you want to handle drawing differently (using OGL or DX?)
*/
module plain.plainroot;

public import plain.plaincontainer;

private import plain.plainmain; // minimize dependency on this module :/

debug private import std.stdio;

version (Windows) private import common.windows;

class PlainRoot : PlainWindow
{
protected:
	version (Windows) {
		HWND hwnd;
	}
	
	enum {
		defFlags=PlainVue.defFlags|Flags.keyFocus // <- keyFocus is a hack for now
	};

	//////////// CREATION FUNCTIONS ////////////
	public this() {
		flags = defFlags;
	}

	public this(CreationStruct* cs)
	{
		flags = defFlags;
		//text = cs.text;
	}

	// vue's should define their own creation struct so they can be indirectly created via createUnknown()
	align(1) struct CreationStruct {
		const PlainVue.CreationStruct cs = {creator : &create};
		//const wchar[] text;
	}

	static public PlainVue create(void* param)
	{
		return new PlainRoot(cast(CreationStruct*) param);
	}

	version (Windows)
	/**
	Sets the window handle. This can't be done with the constructor because
	the window creation requires a root, but the root does not even exist
	before the object is created.
	*/
	final public void setHwnd(HWND hwnd_)
	{
		assert(IsWindow(hwnd_));
		hwnd = hwnd_;
	}

	//////////// BASIC NOTIFICATIONS ////////////
	version (Windows)
	override public int moved(PlainMsgMove.Flags moveFlags)
	{
		RECT rect;
		GetClientRect(hwnd, &rect);
		if (moveFlags & (moveFlags.sizeWidth|moveFlags.sizeHeight)) {
			// TODO: change size of image too ... later
			width = rect.right;
			height = rect.bottom;
		}
		/* // don't care about x,y changes
		if (moveFlags & (moveFlags.moveLeft|moveFlags.moveTop)) {
			left = 0;
			top = 0;
		}*/
		return 0;
	}



	override public int redraw(PlainMsgDraw.Flags redrawFlags)
	{
		debug(verbose) writefln("PlainRoot.redraw item=%X", this);
		redrawFlags &= Flags.redrawAny; // exclude any message or other flags
		if (flags & (Flags.redrawAny|Flags.hidden|Flags.dead)) {
			// return early if any flags set
			flags |= redrawFlags;
			return 0;
		}
		flags |= redrawFlags;
		//container.redraw(PlainMsg.redraw | Flags.redrawPartial);
		PgfxCurrentFlags |= PgfxFlags.redraw;

		return 0;
	}

	version (Windows) {
		static RECT desktopBoundary;
		static POINT cursorOrigin;
	}

	override public int mousePress(PlainMsgMouse.Flags mouseFlags, int button, int down, int x,int y, int pressTime)
	{
		int status = sendMouse(mouseFlags, 0, down, x,y, 0);
		if (status == -1 && button == 1) {
			SystemParametersInfoW(SPI_GETWORKAREA, 0,&desktopBoundary, false);
			RECT rect;
			GetWindowRect(hwnd, &rect);
			desktopBoundary.right -= (rect.right-rect.left);
			desktopBoundary.bottom -= (rect.bottom-rect.top);
			//call CommonItemCode.CaptureMouse
			cursorOrigin.x = x;
			cursorOrigin.y = y;
			//SetCursorImage(GuiCursor.Move);
			//-debug writefln("PlainMouse.x=%d  cursorOrigin.x=%d", PlainMouse.x, cursorOrigin.x);
			mouseHolder = this;
			return 0;
		}
		return status;
	}

	override public int mouseMove(PlainMsgMouse.Flags mouseFlags, int down, int x,int y)
	{
		if (mouseHolder == this) {
			if (down & PlainMsgMouse.Buttons.leftDown) {
				//debug writefln("held move");
				int alignEdge(int actual, int nearest)
				{
					int dif = nearest - actual;
					if (dif >= -16 && dif < 16) actual = nearest;
					return actual;
				};
				int left_,top_;
				left_ = x - cursorOrigin.x;
				top_ = y - cursorOrigin.y;
				//-debug writefln("PlainMouse.x=%d  cursorOrigin.x=%d", PlainMouse.x, cursorOrigin.x);
				//top_ = PlainMouse.y - cursorOrigin.y;
				//alignEdge(left_, desktopBoundary.left);
				//alignEdge(left_, desktopBoundary.right);
				//alignEdge(top_, desktopBoundary.top);
				//alignEdge(top_, desktopBoundary.bottom);
				move(PlainMsgMove.Flags.moveRelative, left_,top_, 0,0, 0);
			} else {
				//-debug writefln("release");
				mouseHolder = PlainVueDead;
			}
			return 0;
		} else {
			return sendMouse(mouseFlags, 0, down, x,y, 0);
		}
	}

	version (Windows)
	override public int move(PlainMsgMove.Flags moveFlags, int left_, int top_, int width_, int height_, int layer_)
	{
		int swpFlags = SWP_NOZORDER|SWP_NOACTIVATE|SWP_NOSIZE;
		RECT rect;
		GetWindowRect(hwnd, &rect);
		if (moveFlags & PlainMsgMove.Flags.relative) {
			//-debug writefln("mouseMove relative (%d,%d)", left_, top_);
			left_ += rect.left; top_ += rect.top;
		}
		if (moveFlags & PlainMsgMove.Flags.move) {
			//-debug writefln("mouseMove move");
			if (!(moveFlags & PlainMsgMove.Flags.moveLeft)) left_ = rect.left;
			if (!(moveFlags & PlainMsgMove.Flags.moveTop)) top_ = rect.top;
		} else {
			swpFlags |= SWP_NOMOVE;
		}
		if (moveFlags & PlainMsgMove.Flags.size) {
			if (!(moveFlags & PlainMsgMove.Flags.sizeWidth)) width_ = rect.right-rect.left;
			if (!(moveFlags & PlainMsgMove.Flags.sizeHeight)) height_ = rect.bottom-rect.top;
		} else {
			swpFlags |= SWP_NOSIZE;
		}
		SetWindowPos(hwnd, null, left_,top_, width_,height_, swpFlags);
		//SetWindowPos(hwnd, null, 0,0, 500,500, SWP_NOZORDER|SWP_NOACTIVATE|SWP_NOSIZE);
		return 0;
	}

	override public int keyPress(PlainMsgKey.Flags keyFlags, int code)
	{
		int status = super.keyPress(keyFlags, code);
		if (status == -1 && code == VK_ESCAPE) { // only if no other item intercepted Escape keypress
			// todo: verify cast correctness
			//PostThreadMessageW(GetCurrentThreadId(), WM_DESTROY, cast(uint)hwnd, cast(LPARAM)cast(void*)this);
			//PostQuitMessage(0);
			//debug writefln("PlainRoot.keyPress");
			PostMessageW(hwnd, WM_CLOSE, 0,0);
			return 0;
		}
		return status;
	}
}
