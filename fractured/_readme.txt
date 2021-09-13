This is your roadmap to this project...

* My apologies to anyone trying to follow in my footsteps.
The project ended up being only a fraction what I envisioned.
Though the code is certainly not messy, it certainly not
complete either.


<< what do you want from this >>

You are probably looking into this project for one of two reasons:

(1) you want to know how one of the fractals works and/or copy code.
    Just dive into the corresponding Paint$$$.cpp file.

(2) you want to add a new fractal to the framework.
    First create a new class than inherits from and implements
    FracturedPainter. Look at any of the Paint$$$.h header files
    for an example. Then add your class to the list of enums in
    fractured.h:FracturedFamily (technically unnecessary but useful).
    For the UI, add a tree list entry in main.cpp:PopulatePaintersTree
    and a case statement in main.cpp:CreateGivenPainter. Lastly,
    in your new class, edit the supported flags, load, and store
    methods so the framework knows about your fractals properties.
    And of course, add the necessary pixel drawing code in draw()
    specific to your new fractal. (more notes below...)


<< topology >>

All the main user interface code can be found in:
	main.cpp - main startup and window
	DockFrame.cpp - moveable frames that snap to nearest windows
	AttribList.cpp - attribute list with editable properties
	fractured.rc - menus, icons, and other resources

Shared fractal code is in:
	fractured.cpp - canvas code, painter interface...

Specific fractal code in:
	Paint$$$.cpp
	PaintComplex.cpp - complex number fractals
	PaintLife.cpp - life cellular automata
	...

Terminology:
	canvas - pixel surface that can be painted to
	painter - fractal or other entity that paints to a canvas


<< implementation decisions >>

Drawing library:
This project does not use any drawing libraries since all of the
fractals implemented are simple enough (most are just point
operators anyway), and a library would just slow down the drawing.
Direct pixel is the way to go. Simply blit the whole image.

However, some fractals (like Lindenmeyer systems) could easily
become complex enough to warrant a library for drawing circles,
lines, gradients, and 3D primitives. If you need these, I recommend
incorporating ImageMagick, GDI+, OpenGL, Antigrain Geometry,
PixelToaster, or any other library you are fond of.

User interface:
I chose the Win32 API because it has the largest user base, but
none of the fractal code is tied to the OS. You could use another
UI like wxWidgets, FOX toolkit, or GTK.


<< compiling and requirements >>

Compiler:
	Visual C++ 2005 Express (the free version)
	Possibly MingW or LCC (untested)

OS:
	Windows XP
	maybe 9x
	maybe Wine for Linux

System:
	Minimal hard drive (200kb EXE as of 200605)
	Small amount of RAM, 3-6 MBs (increases with # layers!)
