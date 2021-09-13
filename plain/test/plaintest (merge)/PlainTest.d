//private import std.stdio, std.process;
debug private import std.stdio;
private import common.windows;

//private import pgfx.pgfxdefs;
//private import plain.plaindefs;
private import plain.plainvue;

private import plain.plainmain;
private import plain.plainbutton;
private import plain.plaincontainer;
private import plain.plainroot;
private import plain.plainedit;
private import plain.plainwindowbg;
private import plain.plainlabel;
private import plain.plainlist;
private import plain.plainmenu;
private import plain.plainimage;

private import plain.plainstyledata;

void main ()
{
	// initialize graphics
	debug writefln("Initializing pgfx");
	PgfxInit();

	////////////////////////////////////////
	// initialize main window
	PlainRoot root = new PlainRoot;
	HWND hwnd = PlainCreateWin(root, "Plain Demo suite\0", 0, 0, 420, 280);
	if (hwnd == null) FatalError("Could not create main window\0");	
	debug writefln("Created window");
	root.setHwnd(hwnd);
	PlainInit(root);
	debug writefln("Initialized root");

	// background
	PlainWindowBg bg = new PlainWindowBg;
	root.append(bg);

	////////////////////////////////////////
	// hello world!
	PlainButton helloButton = new PlainButton("Hello world!", 0);
	helloButton.move(20, 30, 120, 40);
	int helloButtonOwner(PlainVue source, inout PlainMsg msg)
	{
		if (msg.mid == PlainMsgButton.activate) {
			MessageBoxW(hwnd, "you clicked hello :)\0", "Greetings from the Hello Button owner\0", MB_OK);
			return 0;
		}
		return -1;
	}
	helloButton.owner = &helloButtonOwner;
	root.append(helloButton);

	////////////////////////////////////////
	// goodbye cruel world!
	PlainButton byeButton = new PlainButton("Goodbye world!", 0);
	byeButton.move(20, 80, 120, 40);
	//typedef int delegate(PlainVue source, inout PlainMsg msg) PlainDelegate;
	int byeButtonOwner(PlainVue source, inout PlainMsg msg)
	{
		if (msg.mid == PlainMsgButton.activate) {
			PostMessageW(hwnd, WM_CLOSE, 0,0);
			return 0;
		}
		return -1;
	}
	byeButton.owner = &byeButtonOwner;
	root.append(byeButton);

	////////////////////////////////////////
	// make beeping sound
	PlainButton beepButton = new PlainButton("Make beep!", 0);
	beepButton.move(20, 130, 120, 40);
	//typedef int delegate(PlainVue source, inout PlainMsg msg) PlainDelegate;
	int beepButtonOwner(PlainVue source, inout PlainMsg msg)
	{
		if (msg.mid == PlainMsgButton.activate) {
			MessageBeep(MB_ICONEXCLAMATION);
			return 0;
		}
		return -1;
	}
	beepButton.owner = &beepButtonOwner;
	root.append(beepButton);

	////////////////////////////////////////
	// edit test
	PlainEdit testEdit = new PlainEdit("Text edit", 0);
	testEdit.move(20, 180, 140, 20);
	root.append(testEdit);
	
	PlainEdit lockedEdit = new PlainEdit("Locked text edit", PlainEdit.States.locked);
	lockedEdit.move(20, 210, 140, 20);
	root.append(lockedEdit);
	
	PlainEdit filterEdit = new PlainEdit("*****", PlainEdit.States.invalid);
	filterEdit.move(20, 240, 140, 20);
	int filterEditOwner(PlainVue source, inout PlainMsg m_)
	{
		PlainMsgAll* m = cast(PlainMsgAll*)&m_;
		switch (m.mid) {
		case PlainMsgText.change:
			{
				wchar[] text;
				source.textGet(0, text);
				if (text.length >= 5) {
					source.stateSet(PlainEdit.States.invalid, 0);
				} else {
					source.stateSet(0, PlainEdit.States.invalid);
				}
			}
			break;
		case PlainMsg.keyChar:
			if (m.key.code > 32) m.key.code = '*';
			break;
		default:
			return -1;
		}
		return 0;
	}
	filterEdit.owner = &filterEditOwner;
	root.append(filterEdit);

	////////////////////////////////////////
	// label test
	PlainLabel testLabel = new PlainLabel("Window Label", 0);
	testLabel.move(40, 4, 140, 16);
	root.append(testLabel);

	////////////////////////////////////////
	// list test
	PlainList testList = new PlainList("Empty List", 0);
	testList.move(180, 180, 90, 80);
	root.append(testList);

	////////////////////////////////////////
	// image test
	PlainImage testImage = new PlainImage(&PlainImage_Layers1, 0);
	testImage.move(280, 70, 120, 200);
	testImage.flag(PlainVue.Flags.noMouseFocus,0);
	root.append(testImage);

	////////////////////////////////////////
	// menu test
	PlainMenu testMenu = new PlainMenu("Chobits Sumomo|Asuka|Rei", 0);
	PlainButton menuButton;
	testMenu.move(20, 240, 120, 64);
	testMenu.flags |= PlainVue.Flags.hidden;
	int testMenuOwner(PlainVue source, inout PlainMsg m_)
	{
		PlainMsgMenu* m = cast(PlainMsgMenu*)&m_;
		switch (m.mid) {
		case PlainMsgMenu.activate:
			{
				wchar[] text;
				source.textGet(m.selected, text);
				testEdit.textSet(0, text);
				PgfxLayer* layers;
				switch (m.selected) {
				case 0:	layers = &PlainImage_Layers1;	break;
				case 1:	layers = &PlainImage_Layers2;	break;
				case 2:	layers = &PlainImage_Layers3;	break;
				}
				testImage.layersSet(layers);//layers);
				root.redraw(PlainVue.Flags.redrawBg);
			}
			break;
		case PlainMsgMenu.close:
			//MessageBoxW(hwnd, "you clicked hello :)\0", "Greetings from the menu close\0", MB_OK);
			source.flag(PlainVue.Flags.hidden, 0);
			source.container.keyFocusSet(0, menuButton);
			break;
		default:
			return -1;
		}
		return 0;
	}
	testMenu.owner = &testMenuOwner;
	root.append(testMenu);

	menuButton = new PlainButton("Show menu...", 0);
	menuButton.move(280, 30, 120, 30);
	int menuButtonOwner(PlainVue source, inout PlainMsg msg)
	{
		switch (msg.mid) {
		case PlainMsgButton.activate:
			testMenu.move(PlainMsgMove.Flags.move, menuButton.left, menuButton.top+menuButton.height, 0,0, 0);
			testMenu.flag(0, PlainVue.Flags.hidden);
			break;
		default:
			return -1;
		}
		return 0;
	}
	menuButton.owner = &menuButtonOwner;
	root.append(menuButton);

	////////////////////////////////////////
	// container window
	PlainContainer pw = new PlainWindow;
	pw.move(150, 30, 120, 140);
	PlainWindowBg pwBg = new PlainWindowBg;
	pw.append(pwBg);
	PlainButton toggleButton = new PlainButton("Toggle me", PlainButton.States.toggle);
	PlainButton lockButton = new PlainButton("Lock me", PlainButton.States.lock);
	PlainButton unlockButton = new PlainButton("Unlock it", 0);
	toggleButton.move(10, 40, 100, 24);
	pw.append(toggleButton);
	lockButton.move(10, 70, 100, 24);
	pw.append(lockButton);
	unlockButton.move(10, 100, 100, 24);
	int unlockButtonOwner(PlainVue source, inout PlainMsg msg)
	{
		if (msg.mid == PlainMsgButton.activate) {
			lockButton.valueSet(0,0);
			return 0;
		}
		return -1;
	}
	unlockButton.owner = &unlockButtonOwner;
	pw.append(unlockButton);
	PlainLabel pwLabel = new PlainLabel("Subwindow", 0);
	pwLabel.move(40, 4, 140, 16);
	pw.append(pwLabel);

	root.append(pw);

	////////////////////////////////////////
	// entering main loop
    ShowWindow(hwnd, SW_SHOWDEFAULT);
	int status = PlainMainLoop(hwnd);
	debug writefln("Exited main loop");

	PlainDestroyWin(hwnd);
	debug writefln("Destroyed window");
	PlainDeinit(root);
	debug writefln("Freed everything");

	return status;
}

void FatalError(LPCWSTR message)
{
	//MessageBoxW(null, message, "Fatal Startup Error\0", MB_OK|MB_ICONSTOP|MB_TASKMODAL);
	MessageBoxW(null, PlainErrorStr, "Fatal Startup Error\0", MB_OK|MB_ICONSTOP|MB_TASKMODAL);
	ExitProcess(-1);
}
