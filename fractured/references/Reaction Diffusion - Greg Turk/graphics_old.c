/*

Simple (and slow) interface to X11.

Permission is granted to modify and/or distribute this program so long
as the program is distributed free of charge and this header is retained
as part of the program.

Copyright (c) Greg Turk, 1991

*/

#include <stdio.h>
#include <X11/Xlib.h>
#include <X11/Xatom.h>
#include <math.h>

static Display *display;
static int screen;
static Window root;

static unsigned long foreground, background;
static Cursor root_cursor;
static int defDepth;
static Visual 	*defVisual;
static Colormap defColormap;

static XFontStruct *RegFont;
static XFontStruct *SmallFont;
static XFontStruct *BigFont;

static GC gc_reg_font;		/* graphics context with regular font */
static GC gc_small_font;	/* graphics context with small font */
static GC gc_big_font;		/* graphics context with big font */

static GC gc;
static XGCValues gcvalues;
static XColor colors[256];

static num_colors;		/* number of colors allocated to window */
static int psize = 1;		/* size of pixels */

static int screen_x;		/* screen size */
static int screen_y;
static int corner_x = 20;
static int corner_y = 20;

static void draw_proc();

int (*press1)() = NULL;
int (*press2)() = NULL;
int (*press3)() = NULL;
int (*release1)() = NULL;
int (*release2)() = NULL;
int (*release3)() = NULL;


/******************************************************************************
Create a window for graphics.

Entry:
  w,h     - width and height of screen in pixels
  ncolors - number of colors to allocate
******************************************************************************/

init_graphics(w,h,ncolors)
  int w,h;
  int ncolors;
{
  XSetWindowAttributes	attrib;

  /* Open a connection to the display. */
  if ((display = XOpenDisplay (NULL)) == NULL) {
    printf ("Couldn't open display:\n");
    printf ("Make sure X11 is running and DISPLAY is set correctly\n");
    exit (-1);
  }
  screen = XDefaultScreen (display);
  num_colors = ncolors;

/*
XSetErrorHandler (my_error_handler);
*/

  /* set up foreground, background colors (to Xdefaults, if any) */
  if (XDisplayCells (display, screen) > 2)	/* this is a color display */
    defColormap = XDefaultColormap (display, screen);

  foreground = XWhitePixel (display, screen);
  background = XBlackPixel (display, screen);

  /* set up default depth, visual params */
  defDepth = XDefaultDepth (display, screen);
  defVisual = XDefaultVisual (display, screen);

  /* set up fonts */

  RegFont   = XLoadQueryFont (display, "8x13");
  SmallFont = XLoadQueryFont (display, "6x10");
  BigFont   = XLoadQueryFont (display, "9x15");

  if (RegFont == NULL || SmallFont == NULL || BigFont == NULL) {
    printf ("Couldn't find all fonts.\n");
  }

  /* create root cursor (left arrow) */
  root_cursor = XCreateFontCursor (display, 68);

  screen_x = w;
  screen_y = h;

  /* create root window */
  attrib.background_pixel = background;
  attrib.border_pixel = foreground;
  attrib.override_redirect = True;
  attrib.event_mask = ButtonPressMask | ButtonReleaseMask | ExposureMask |
		      StructureNotifyMask;
  attrib.cursor = root_cursor;
  root = XCreateWindow (display, RootWindow(display, screen),
	      corner_x, corner_y,
	      screen_x, screen_y, 1, defDepth, InputOutput,
	      defVisual, CWBackPixel|CWBorderPixel|CWOverrideRedirect|
	      CWEventMask|CWCursor, &attrib);
  XChangeProperty (display, root, XA_WM_NAME, XA_STRING, 8, PropModeReplace,
      "Icon", 5);

  /* mapping windows */
  XMapWindow (display, root);

  /* set up some graphics contexts */

  gcvalues.foreground = foreground;
  gcvalues.background = background;
  gcvalues.line_width = 1;
  gcvalues.font = RegFont->fid;
  gc_reg_font = XCreateGC (display, root,
		  GCForeground|GCBackground|GCLineWidth|GCFont,
		  &gcvalues);
  gcvalues.font = SmallFont->fid;
  gc_small_font = XCreateGC (display, root,
		  GCForeground|GCBackground|GCLineWidth|GCFont,
		  &gcvalues);
  gcvalues.font = BigFont->fid;
  gc_big_font = XCreateGC (display, root,
		  GCForeground|GCBackground|GCLineWidth|GCFont,
		  &gcvalues);

  /* setup colors */
  init_colormap();
}


/******************************************************************************
Specify the text to appear on the main window's icon.
******************************************************************************/

window_name(name)
  char *name;
{
  XChangeProperty (display, root, XA_WM_NAME, XA_STRING, 8, PropModeReplace,
      name, strlen (name));
}


/******************************************************************************
Specify upper left corner of window.
******************************************************************************/

window_corner(x,y)
  int x,y;
{
  corner_x = x;
  corner_y = y;
}


/******************************************************************************
My own error handler.
******************************************************************************/

my_error_handler(disp,event)
  Display *disp;
  XErrorEvent *event;
{
  float x;

  printf ("You got an error.\n");
  x = 0;
  x = 1 / x;
}


/******************************************************************************
Make grey ramp.
******************************************************************************/

grey_ramp()
{
  XStoreColors (display, defColormap, colors, num_colors);
}


/******************************************************************************
Initialize the color map.
******************************************************************************/

init_colormap()
{
  int i;
  int status;
  float t;
  unsigned long plane_masks[8];
  unsigned long pixels[256];

  status = XAllocColorCells (display, defColormap,
	   0, plane_masks, 0, pixels, num_colors);

  if (status == 0) {
    printf ("bad status from XAllocColorCells\n");
    return;
  }

  /* create grey ramp */

  for (i = 0; i < num_colors; i++) {
    t = 65535 * i / (num_colors - 1.0);
    colors[i].red   = t;
    colors[i].green = t;
    colors[i].blue  = t;
    colors[i].pixel = pixels[i];
    colors[i].flags = DoRed | DoGreen | DoBlue;
  }

  XStoreColors (display, defColormap, colors, num_colors);

  gcvalues.foreground = foreground;
  gcvalues.background = background;
  gc = XCreateGC (display, root, GCForeground|GCBackground, &gcvalues);
}


/******************************************************************************
Place a red,green,blue triple in the color lookup table.

Entry:
  index - index to place color
  r,g,b - red, green and blue values to place in table
******************************************************************************/

makecolor (index,r,g,b)
  int index;
  int r,g,b;
{
  XColor col;

  index = (index / 255.0) * (num_colors - 1);

  if (index < 0 || index >= num_colors) {
    printf ("makecolor index out of bounds: %d\n", index);
    return;
  }

  col.red   = 65535 * (r / 255.0);
  col.green = 65535 * (g / 255.0);
  col.blue  = 65535 * (b / 255.0);
  col.pixel = colors[index].pixel;
  col.flags = DoRed | DoGreen | DoBlue;
  XStoreColor (display, defColormap, &col);
}


/******************************************************************************
Set the size of pixels.
******************************************************************************/

set_pixel_size (size)
int size;
{
  psize = size;
}


/******************************************************************************
Write a pixel to the screen.
******************************************************************************/

writepixel (x,y,color)
  int x,y;
  int color;
{
  color = (color / 255.0) * (num_colors - 1);

  gcvalues.foreground = colors[color].pixel;
  XChangeGC (display, gc, GCForeground, &gcvalues);
  XFillRectangle (display, root, gc, x * psize, y * psize, psize, psize);
}


/******************************************************************************
Flush the pixel buffers.
******************************************************************************/

flushbuffers()
{
  XFlush (display);
}


/******************************************************************************
Clear the screen.
******************************************************************************/

clear_screen()
{
  XClearWindow (display, root);
  XFlush (display);
}


/******************************************************************************
Draw a line.

Entry:
  x,y   - one endpoint of line
  x2,y2 - other endpoint
  color - color of line
******************************************************************************/

line (x,y,x2,y2,color)
  int x,y;
  int x2,y2;
  int color;
{
  if (abs(x - x2) > 4 * screen_x || abs(y - y2) > 4 * screen_y) {
    printf ("error in line(), x y x2 y2: %d %d %d %d\n", x, y, x2, y2);
    return;
  }

  color = (color / 255.0) * (num_colors - 1);

  gcvalues.foreground = colors[color].pixel;
  XChangeGC (display, gc, GCForeground, &gcvalues);
  XDrawLine (display, root, gc, x * psize, y * psize, x2 * psize, y2 * psize);
}


/******************************************************************************
Draw a string of text.
******************************************************************************/

draw_text(text,x,y)
  char *text;
  int x,y;
{
  XDrawString (display, root, gc_reg_font, x, y, text, strlen (text));
}


/******************************************************************************
Event handler for drawing area.
******************************************************************************/

static void draw_proc (data,event)
  char *data;
  XEvent *event;
{
  XButtonEvent *button;

  button = (XButtonEvent *) event;
  
  switch(event->type) {

    case ButtonPress:
      switch (button->button) {
	case Button1:
	  if (press1)
	    (*press1)(button->x, button->y);
	  break;
	case Button2:
	  if (press2)
	    (*press2)(button->x, button->y);
	  break;
	case Button3:
	  if (press3)
	    (*press3)(button->x, button->y);
	  break;
      }
      break;

    case ButtonRelease:
      switch (button->button) {
	case Button1:
	  if (release1)
	    (*release1)(button->x, button->y);
	  break;
	case Button2:
	  if (release2)
	    (*release2)(button->x, button->y);
	  break;
	case Button3:
	  if (release3)
	    (*release3)(button->x, button->y);
	  break;
      }
      break;

    case Expose:
      break;
  }
}


/******************************************************************************
Check to see if events need processing.
******************************************************************************/

check_events()
{
  XEvent event;
  XAnyEvent *e;

  while (XPending (display)) {

    XNextEvent (display, &event);
    e = (XAnyEvent *) &event;

    if (e->window == root)
      draw_proc (NULL, &event);
    else {
      printf ("check_events(): Oops, unknown event.\n");
    }
  }
}


/******************************************************************************
Set up callback functions for button presses.
******************************************************************************/

setup_buttons(p1,p2,p3,r1,r2,r3)
  int (*p1)();
  int (*p2)();
  int (*p3)();
  int (*r1)();
  int (*r2)();
  int (*r3)();
{
  press1 = p1;
  press2 = p2;
  press3 = p3;
  release1 = r1;
  release2 = r2;
  release3 = r3;
}

