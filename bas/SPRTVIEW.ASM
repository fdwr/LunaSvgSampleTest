;SpriteView 1.0 by FDwR
;simple com file to view graphics stored in Nintendo ROMs

;supports NES,GB,SNES formats
;low end machines (ie. 386 4MHz) have more than enough power
;requires very little memory (compared to most others)
;very fast, would scroll quicker than Naga if not for scroll timing
;can load snapshot palettes from pcx's or gif's or raw palettes
;can output current palette or viewing window
;has a simple file menu system with limited options
;most options are available with two or less keypresses
;has a file menu for loading ROMs or palettes
;supports a mouse and very simple object oriented system
;includes simple bitplane mode debugger
;supports copy to Windows clipboard

;memory estimates:
;  64k program itself (main code, routines, fonts)
;  4k for environment to hold miscellaneous variables
;  4k for screen/mouse boundaries and 'objects'
;
;  64k file window (for both viewing window and image importer)
;  32k export template and editing window
;  2k for row strip buffer
;  256 palette reduction colormap
;  256 inverse colormap
;  768 current screen palette
;  768 current viewing palette
;  768 palette copy buffer
;  32 palette copy mask
;  768*4 user palettes
;+ 128-1024 viewing window and palettes filenames
;+ 4k filename list
;+ 4k gif symbol stack
;+ 64k import image
;--------
;altogether about 220k
;
;'+' means that the memory is dynamic (allocated only when needed)
;    all other memory pieces are static and allocated when SpriteView starts
;    if there is not at least that much memory, it will quit with a message

;memory functions (an individual allocation can be up to 16 MBs)
;  malloc   allocate the needed space for the first time where it will fit
;           will call mqalloc if there are no fits
;  mresize  change the space needed for a prior allocation
;  mfree    give up some of the space used by an allocation
;  mqalloc  quick allocation at top of memory heap
;           will call malloc if MCB can not be resized
;  mtenter  enter a subroutine and create table for temporary variables
;           saves the address of the last temporary table
;           returns pointer to table
;  mtexit   exit a subroutine and free all temp variables allocated
;           restores table of code that called the sub
;  mtalloc  allocate a temporary variable to be released after sub is done
;  mtfree   same as mfree but works on temporary variables
;  mtresize same as mresize but works on temp vars
;  mtselect select a temporary variable table (rarely used)
;/  mtalloc  temporary allocation to be freed at end of subroutine
;/  msub     prepare to enter a subroutine for temporary allocations

;up to 248 colors are devoted to the SNES images. Only 8 out of 256 are
;reserved by SpriteView for its GUI. They are as follows:
;  0-Black   1-Dark Gray   2-Gray     3-White
;  4-Blue    2-Green       3-Yellow   4-Red
;the first four are generic for borders and menus
;the next four are just add some color in various places 

;keys:
;SpriteView does directly read the key port for input to tell whether a key
;currently still pressed and to catch key releases too, but does not take the
;BIOS handler out of the loop, so keys need to be cleared by calling keyread
;function to prevent the stupid keyboard buffer overflow beep. Key detection
;is handled by a little function that compares the current scancode the last
;one, and if there is a difference, a keychange is signaled.
;
;These keys function for the mouse if one is not present (numeric keypad only)
;  Ins  left mouse button
;  Del  right mouse button
;  4/6  left & right mouse movement
;  8/2  up & down mouse movement
;  +  double movement steps
;  -  half movement steps

;These keys are part of the menu. Assuming that no objects have taken control
;of key input (like a text prompt) all alphanumeric keys are also passed to
;the menu. To pass these keys over the object directly to the menu, the Alt
;key can first be pressed.
;  Alt  press and release to activate menu, again to deactivate
;  Enter  choose option (or open submenu)
;  BackSpc  close current submenu and go back one (or deactivate menu)
;  Esc  completely escape from and close all menus (deactivate)
;  Up/Down  open submenu or select choice in submenu
;  Left/Right  select main menu choice

;main keys in viewing mode
;  F1  simple help
;  F2  gray palette (press again for inverse gray)
;  F3  default VGA
;  F4  smooth rainbow
;  F5  user palette 1
;  F6  .. 2
;  F7  .. 3
;  F8  .. 4
;  F9  shift palette base forward by number of current colors
;  F10  ditto but backward
;  F11  shift palette vase forward by one
;  F12  ditto but backward

;main menu keys
;  G    goto byte position in ROM
;  L|R  select ROM file
;   |P  load palette into one of four user palettes
;  S|W  save a copy of current viewing window to a pcx image file
;   |P  save current palette to raw PAL, GIF, or PCX

;keys in palette editor
;  C  copy selected colors (using mouse or Ins/Del)
;  P  paste copied colors (pasted relative to cursor position)
;  X  exchange copied colors with current colors

	org 100
	bits 16

section .text

;pseudocode
;  change stupid PSP so file errors will not occur
;  allocate environment and stack
;  set video mode
;  set palette
;  allocate memory for file window, template, objects...
;  quit if not enough
;  draw screen (menu,viewing window,export template,status line)
;  check command line for filename
;  open file for viewing (add .SMC if not found)
;  display error message if could not open
;  display size and ROM name if possible
;  refresh viewing window
;  reset viewing window variables
;  make condensed palette for screen
;  draw a single row of tiles
;    translate tiles to row strip buffer
;    copy buffer to screen with colormap function
;  waste buffered keys
;  check keys
;    compare scancode with last scancode
;    if scroll key pressed and timer greater than last tick refresh window
;    if Alt pressed or released activate or deactivate menu (continue)
;    if Alt held down then pass key onto menu
;    if other key pressed then pass onto active object
;    then onto menu if not accepted by object
;      if submenu then save background and create menu
;      close menu and redraw background
;      do action, refresh window, change utility page, call help, exit...
;
;  if changes have been madde to tiles and file buffer needs to be refreshed
;   or is about to be overwritten, be sure to save buffer to file first
;
;  free memory
;  reset video to text
;  quit with message int

;mov ah,48h
;mov bx,space??
;int 21h

mov ax,13h	;video mode 13, 320x200 256clr
int 10h		;call BIOS

mov ax,4C01h	;die
int 21h


GetKeyScanCode:
;checks the keyboard for a change by reading directly from port
  in al,60h
  mov ah,al
  cmp al,[LastKeyScanCode]
  jnz SameKeyAgain
  xor al,al		;nothing different, just cancel out to zero
  SameKeyAgain:
  ret
;returns scancode in ah regardless of whether it is the same, al contains
;the scancode only if the key is different, otherwise it is zero

DrawBox:
;draws simply a box from one corner to another on screen in the given color
;color may be anywhere from 0-255
;uses 32 bit output for faster blitting
;supports one color solid or two color mesh

DrawBorder:
;call DrawBox four times to draw a shaded border

BlitFontCharString:
;blits an entire text string to the screen
;the font is already selected (there is only one)
;it can call either BlitFontChar or BlitFontAura
;color is simply passed on

BlitFontAura:
;makes a glow around a font character
;then simply calls BlitFontChar
;color simply passed on
;used less frequently than BlitFontChar

BlitFontChar:
;blits a single character to any row/col on screen using given color
;should include clipping for rows and columns off screen
;color may be anywhere from 0-255

BlitColormappedImage:
;blits a linear bitmap to the screen using the given palette

BlitLinearImage:
;simple pixel blitter to draw bitmap onto screen
;uses 32 bit output for faster blitting

BlitTransLinearImage:
;pixel blitter that draws transparent bitmaps onto screen
;uses 32 bit output for faster blitting

RefreshViewingWindow:
;refreshes a single row of the viewing window by calling BufferTilesToBitmap
;then BlitColormappedImage

BufferTilesToBitmap:
;fills the tile row buffer with a linear bitmap by calling the right tile
;translator routine
;used when updating the screen, copying to the export template, and exporting
;an image to file

BufferBitmapToTiles:
;fills the tile row buffer with tiles by calling the right tile retranslating
;routine
;used solely to reconvert the editing buffer back into tiles
;can produce strange results if mode to be reconverted back to is different
;than mode the tiles came from

CheckFileBuffer:
;makes sure the file buffer is loaded with the viewing part desired
;is so then simply return
;otherwise, if allowed to, copy a file chunk into the buffer (DOS call)
;return to caller with value of whether buffer was refreshed or not

MakeReducedPalette:
;searches through a source palette for nearest color matches and reduces
;them to fit in the destination palette, makes a colormap and palette
;for example, mode 7 can use 256 colors but SpriteView needs at least 8 of
;those for its simple GUI (leaving only 248); however most SNES palettes have
;duplicate colors which means they really use less than a full 256 colors
;anyway. Often times these redundant colors are exact matches which makes it
;easy, but if not, it just choose the colors that are closest to each other.
;the degredation is not even noticeable.

InputPcxRow:
;reads a single pcx row from the file buffer and blits it to the screen

InputGifRow:
;reads a single gif row from the file buffer and blits it to the screen

OutputPaletteToFile:
;prints a palette

DosErrorInterceptor:
;Intercepts the stupid 'errors' DOS cries about if something like a path does
;not exist or a drive is not ready
;if 'DOSsafety' on, it simply returns to code that caused it
;otherwise calls EmergencyQuit for serious things (although I don't know what)

EmergencyQuit:
;this is called when a fatal or possibly fatal error occurs
;such as memory fragmentation, out of memory
;accepts a pointer to an error message
;hides the mouse (if it was detected)
;sets screen mode to text
;prints the message if pointer not null
;(restores key handler)
;calls DOS to die
mov ax,4C01h	;die
int 21h

section .data

SmallFontTable:
; specifies the width of each individual character
; db 3,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8...
SmallFontChars:
; the actual bit data used