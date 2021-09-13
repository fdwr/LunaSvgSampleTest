;%include "pgfx.h"
%include "pgfxlayr.h"

%macro csym 1.nolist
	global _%1
	_%1:
	global %1
	%1:
%endmacro


section .data

align 4, db 0
csym PlainCursor_Default
	DefPgtLayer1 ImageDefault, PgtLayer.BopTrans, 0,0, 0,0
	DefPgtLayerEnd

csym PlainCursor_Pan
	DefPgtLayer1 ImagePan, PgtLayer.BopTrans, 0,0, 0,0
	DefPgtLayerEnd

csym PlainCursor_Edit
	DefPgtLayer1 ImageEdit, PgtLayer.BopTrans, 0,0, 0,0
	DefPgtLayerEnd


; (pixels, type&flags, bpp, wrap, left, top, height, width)
align 4, db 0
ImageDefault:	DefPgtImage PixelsDefault,	PgtImage.typeImage, 5, 32*4, 27,1,	32,32
ImagePan:		DefPgtImage PixelsPan,		PgtImage.typeImage, 5, 32*4, 14,14,	32,32
ImageEdit:		DefPgtImage PixelsEdit,	PgtImage.typeImage, 5, 12*4, 2,12,	12,31

align 4, db 0
PixelsDefault:	incbin "styles\cursor_default.raw"
PixelsPan:		incbin "styles\cursor_pan.raw"
PixelsEdit:		incbin "styles\cursor_edit.raw"
