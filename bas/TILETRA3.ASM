/*  Tile Translating routines, 5-8-98, FDwR
    assembly modified for C

Routines for SNES and GameBoy
Plan to also include some for NES and Sega
SNES (all tiles are 8x8, colormapped palettes)
  1bit,1bpl,2clr    linear monochrome
  2bit,2bpl,4clr    bitplane interleaved
  3bit,3bpl,8clr    compressed mode used for storage
  4bit,4bpl,16clr   native sprite format used by PPU
  8bit,8bpl,256clr  mostly used for highcolor still images
  8bit,1bpl,256clr  mode 7, used for rotational effects and such
GameBoy (all tiles are 8x8, grayscale palettes)
  1bit,1bpl,2clr    linear monochrome
  2bit,2bpl,4clr    bitplane interleaved

Note that the first two modes of the SNES are the same as the two used by
the GameBoy, so the very same routine can be used for both systems. Any of
modes with more than four colors are of course only for the SNES.
*/


// Bitplane tables //////////////////////////////

// This points into the BplPtrTable using the current bitmode
Int ModePtrTable[]={0,0,0,16,40,72,72,72,72};

// This contains all the patterns for the translating routine below
Int BplPtrTable[]={
  // SNES_? undefined mode, just select bitmode 1
  // SNES_8x8x1 SNES bit modes 1, 2, and GameBoy use the same table
  // SNES_8x8x2
  // GameBoy_8x8x2
    0,1,1,1,1,1,1,1
    1,1,1,1,1,1,1,1
  // SNES_8x8x3
    0,1,15,-14,1,14,-13,1,13,-12,1,12,-11,1,11,-10,1,10,-9,1,9,-8,1,8
  // SNES_8x8x4
    0,1,15,1,-15,1,15,1,-15,1,15,1,-15,1,15,1,-15,1,15,1,-15,1,15,1,-15,1,15,1,-15,1,15,1
  // SNES_8x8x8
    0,1,15,1,15,1,15,1,-47,1,15,1,15,1,15,1,-47,1,15,1,15,1,15,1,-47,1,15,1,15,1,15,1,-47,1,15,1,15,1,15,1,-47,1,15,1,15,1,15,1,-47,1,15,1,15,1,15,1,-47,1,15,1,15,1,15,1
};


// Example //////////////////////////////
/*
    Trans_SNES_GB_Bitplane(ROMtile, ViewWindow,
                           BplPtrTable[ModePtrTable[BitBpls]],
                           BitBpls, ViewWindowWidth)
*/


// Bitplane tile routine //////////////////////////////
/*
This routine works for both SNES and Gameboy graphics
Parameters passed:
  dword  SourceTile  (es:si)  Raw tile data input
  dword  Destination (fs:di)  Linear bitmap output
  dword  BplPtrTable (gs:bx)  Bitplane jump table
  byte   BitPlanes            Number of bitplanes for tile
  word   ImgWidth             Width of bitmap 
Registers used:
  bx=jump table index
  cl=bitplanes
  ch=row counter
  cl+=plane counter
  ch+=bitplane row data		(<---input)
  eax=left row (pixel columns 0-3)	(output-->)
  edx=right row (pixel columns 4-7)	(output-->)
  si=raw source data
  di=linear bitmap destination
  bp=bitmap width (or screen width, if mode 13h)
  cs=code segment, and for now, the jump table segment too
  es=source segment
  fs=destination segment
  gs=jump table segment

  ds is not used to prevent messing with the data segment (just for safety).
Notation:
  cl+ and ch+ mean the upper 16 bits of eax, only accessible after they
  have been shifted down (or actually, when the lower bits are shifted up)
  To save the bitplanes and row counter so they are not overwritten, they
  are simply shifted up into the 'safe' part of ecx. This saves a tiny bit
  of time by not writing and rereading their values to memory.
What it does:
   Basically, it uses a table to tell how the planes are parsed up, then
 loops the number of bitplanes, ORing each bitplane onto the pixel row and
 rolling them until the full pixel depth for eight pixels is achieved.
*/

void Trans_SNES_GB_Bitplane
    (
    char far *SourceTile,
    char far *Destination,
    char far *BplPtrTable,
    unsigned char BitPlanes,
    unsigned int ImgWidth
    )

    _asm {
	les si,SourceTile	//get all the parameters and put them in their registers
	lfs di,Destination
	lgs bx,BplPtrTable
	mov cx,BitPlanes	//get number of bitplanes
	mov bp,ImgWidth		//get bitmap width last
	mov ch,8		//set row counter to 8 rows

    //Now that all the setup is done, here is the most important part of it.
    //This is not the fastest code for translation, but it is the most versatile,
    //being able to handle any bitmode without compromising on too much speed.

    nextbplrow:
	mov al,cl	//copy bitplanes
	shl ecx,16	//save bitplanes and row counter 
	mov cl,al	//set plane counter to number of planes
	xor eax,eax	//set both to zero
	xor edx,edx

    nextbitplane:
    //cl=bitplane counter
    //ch=data
    //bx=source jump index

	add si,[gs:bx]	//move source to next bitplane (same row) using table
	add bx,2
	mov ch,[es:si]	//get next bitplane
	
	shr ch,1	//bt and shr take just as long, but shr is smaller
	jnc 1
	or edx,01000000h
    1:	shr ch,1
	jnc 2
	or edx,00010000h
    2:	shr ch,1
	jnc 3
	or edx,00000100h
    3:	shr ch,1
	jnc 4
	or edx,00000001h
    4:	shr ch,1
	jnc 5
	or eax,01000000h
    5:	shr ch,1
	jnc 6
	or eax,00010000h
    6:	shr ch,1
	jnc 7
	or eax,00000100h
    7:	shr ch,1
	jnc 8
	or eax,00000001h
    8:
	ror eax,1	//roll pixels left to not let the next bitplane clobber this one
	ror edx,1	//rolling right would reverse the the bits, not desirable,
			//unless you reverse everything

	dec cl
	jnz nextbitplane

	shr ecx,16	//get access to bitplanes and row counter
	rol eax,cl	//you need to compensate for the prior ror's by rolling it
			//left by an equal number of times it was rolled right above,
			//which is the number of bitplanes
	mov [fs:di],eax	//write first four left pixels
	rol edx,cl	//it stinks that you can not use anything but cl \:-(
	mov [fs:di+4],edx	//write second four right pixels
	add di,bp	//add bitmap width to dest for next row down

	dec ch
	jnz nextbplrow
    // 'jnz near nextbplrow' try if it complains of an out of range jump
    }
}


// Example //////////////////////////////
/*
    Trans_SNES_mode7(ROMtile, ViewWindow, ViewWindowWidth)
*/

// Mode 7 routine //////////////////////////////
/*
This routine only works for mode 7 SNES graphics
Parameters passed
  dword  SourceTile  (es:si)  Raw tile data input
  dword  Destination (fs:di)  Linear bitmap output
  word   ImgWidth             Width of bitmap 
Registers used
  cl=row counter
  ds=source segment
  si=raw source data
  es=destination segment
  di=linear bitmap destination
  bp=bitmap width
*/

void Trans_SNES_mode7
    (
    char far *SourceTile,
    char far *Destination,
    unsigned int ImgWidth
    )

    _asm {
	lds si,SourceTile
	les di,Destination
	mov bp,ImgWidth
	sub bp,8
	mov cl,8

    nextrow:
	movsd		//write first four left pixels
	movsd		//write second four right pixels
	add di,bp	//add bitmap width to dest for next row down
	dec cl
	jnz nextrow
    }
}