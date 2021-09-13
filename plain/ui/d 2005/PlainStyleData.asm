; Default style data for various controls.
; Leave this out of the final compile if you want to use your own.

; TODO: DELETE THIS FILE, ONCE THE STYLE MAKER TOOL IS FINISHED
;	It is too much work to create layers manually.

%define pgfx_layer_data ; do not include exports or any structures, just defs
%include "pgfx.h"
%include "pgfxlayr.h"

; VERY DANGEROUS
; Defining some constants here. If they ever change in the D file, these MUST change as well.
; Really wish D and asm could share same header file. :-/

PlainButton.StateDown equ 1<<0;
PlainVue.FlagsMouseFocus equ 1<<2;
PlainVue.FlagsKeyFocus equ 1<<4;
PlainEdit.StateInvalid equ 32;

//%define PlainStyleIslandPastelsFlat
%define PlainStyleLavenderCut

////////////////////////////// BUTTONS //////////////////////////////
%ifdef nothing
%elifdef PlainStyleIslandPastelsFlat

alignd
csym PlainButton_Layers

DefPgtLayerState PgtLayer.BopStateSpecific, PlainButton.StateDown, 0 // if button state down

	; pushed
	DefPgtLayer1 PlainButton_ImageDownHT, PgtLayer.BopOpaque|PgtLayer.FlagLTRT|PgtLayer.FlagTile, 12,0,-12,12
	DefPgtLayer1 PlainButton_ImageDownHV, PgtLayer.BopOpaque|PgtLayer.FlagLTRB|PgtLayer.FlagTile, 12,12,-12,-12
	DefPgtLayer1 PlainButton_ImageDownHB, PgtLayer.BopOpaque|PgtLayer.FlagLBRB|PgtLayer.FlagTile, 12,-12,-12,0

	DefPgtLayer1 PlainButton_ImageDownLT, PgtLayer.BopTrans|PgtLayer.FlagLTLT, 0,0,12,12
	DefPgtLayer1 PlainButton_ImageDownLV, PgtLayer.BopOpaque|PgtLayer.FlagLTLB|PgtLayer.FlagTile, 0,12,12,-12
	DefPgtLayer1 PlainButton_ImageDownLT, PgtLayer.BopTrans|PgtLayer.FlagLBLB|PgtLayer.FlagAlignBottom, 0,-12,12,0

	DefPgtLayer1 PlainButton_ImageDownRT, PgtLayer.BopTrans|PgtLayer.FlagRTRT, -12,0,0,12
	DefPgtLayer1 PlainButton_ImageDownRV, PgtLayer.BopOpaque|PgtLayer.FlagLeftOpposite|PgtLayer.FlagTile, -12,12,0,-12
	DefPgtLayer1 PlainButton_ImageDownRT, PgtLayer.BopTrans|PgtLayer.FlagRBRB|PgtLayer.FlagAlignBottom, -12,-12,0,0

DefPgtLayerState PgtLayer.BopStateSpecific, 0, PlainButton.StateDown // else
DefPgtLayerState PgtLayer.BopStateGeneric, PlainVue.FlagsMouseFocus, 0 // if mouse focus

	; hovered
	DefPgtLayer1 PlainButton_ImageHoverHT, PgtLayer.BopOpaque|PgtLayer.FlagLTRT|PgtLayer.FlagTile, 12,0,-12,12
	DefPgtLayer1 PlainButton_ImageHoverHV, PgtLayer.BopOpaque|PgtLayer.FlagLTRB|PgtLayer.FlagTile, 12,12,-12,-12
	DefPgtLayer1 PlainButton_ImageHoverHB, PgtLayer.BopOpaque|PgtLayer.FlagLBRB|PgtLayer.FlagTile, 12,-12,-12,0

	DefPgtLayer1 PlainButton_ImageHoverLT, PgtLayer.BopTrans|PgtLayer.FlagLTLT, 0,0,12,12
	DefPgtLayer1 PlainButton_ImageHoverLV, PgtLayer.BopOpaque|PgtLayer.FlagLTLB|PgtLayer.FlagTile, 0,12,12,-12
	DefPgtLayer1 PlainButton_ImageHoverLT, PgtLayer.BopTrans|PgtLayer.FlagLBLB|PgtLayer.FlagAlignBottom, 0,-12,12,0

	DefPgtLayer1 PlainButton_ImageHoverRT, PgtLayer.BopTrans|PgtLayer.FlagRTRT, -12,0,0,12
	DefPgtLayer1 PlainButton_ImageHoverRV, PgtLayer.BopOpaque|PgtLayer.FlagLeftOpposite|PgtLayer.FlagTile, -12,12,0,-12
	DefPgtLayer1 PlainButton_ImageHoverRT, PgtLayer.BopTrans|PgtLayer.FlagRBRB|PgtLayer.FlagAlignBottom, -12,-12,0,0

DefPgtLayerState PgtLayer.BopStateGeneric, 0, PlainVue.FlagsMouseFocus // else

	; normal
	DefPgtLayer1 PlainButton_ImageNormalHT, PgtLayer.BopOpaque|PgtLayer.FlagLTRT|PgtLayer.FlagTile, 12,0,-12,12
	DefPgtLayer1 PlainButton_ImageNormalHV, PgtLayer.BopOpaque|PgtLayer.FlagLTRB|PgtLayer.FlagTile, 12,12,-12,-12
	DefPgtLayer1 PlainButton_ImageNormalHB, PgtLayer.BopOpaque|PgtLayer.FlagLBRB|PgtLayer.FlagTile, 12,-12,-12,0

	DefPgtLayer1 PlainButton_ImageNormalLT, PgtLayer.BopTrans|PgtLayer.FlagLTLT, 0,0,12,12
	DefPgtLayer1 PlainButton_ImageNormalLV, PgtLayer.BopOpaque|PgtLayer.FlagLTLB|PgtLayer.FlagTile, 0,12,12,-12
	DefPgtLayer1 PlainButton_ImageNormalLT, PgtLayer.BopTrans|PgtLayer.FlagLBLB|PgtLayer.FlagAlignBottom, 0,-12,12,0

	DefPgtLayer1 PlainButton_ImageNormalRT, PgtLayer.BopTrans|PgtLayer.FlagRTRT, -12,0,0,12
	DefPgtLayer1 PlainButton_ImageNormalRV, PgtLayer.BopOpaque|PgtLayer.FlagLeftOpposite|PgtLayer.FlagTile, -12,12,0,-12
	DefPgtLayer1 PlainButton_ImageNormalRT, PgtLayer.BopTrans|PgtLayer.FlagRBRB|PgtLayer.FlagAlignBottom, -12,-12,0,0

// endif, endif
DefPgtLayerEnd

PlainButton_ImageNormalHT:	DefPgtImage PlainButton_Pixels, 0, 32,24,	12,0, 1,12,  0,0
PlainButton_ImageNormalHV:	DefPgtImage PlainButton_Pixels, 0, 32,24,	12,12, 1,1,  0,0
PlainButton_ImageNormalHB:	DefPgtImage PlainButton_Pixels, 0, 32,24,	12,12, 1,12,  0,0

PlainButton_ImageNormalLT:	DefPgtImage PlainButton_Pixels, 0, 32,24,	0,0, 12,24,  0,0
PlainButton_ImageNormalLV:	DefPgtImage PlainButton_Pixels, 0, 32,24,	0,12, 12,1,  0,0

PlainButton_ImageNormalRT:	DefPgtImage PlainButton_Pixels, 0, 32,24,	12,0, 12,24,  0,0
PlainButton_ImageNormalRV:	DefPgtImage PlainButton_Pixels, 0, 32,24,	12,12, 12,1,  0,0

PlainButton_ImageHoverHT:	DefPgtImage PlainButton_Pixels, 0, 32,24,	12,0+24, 1,12,  0,0
PlainButton_ImageHoverHV:	DefPgtImage PlainButton_Pixels, 0, 32,24,	12,12+24, 1,1,  0,0
PlainButton_ImageHoverHB:	DefPgtImage PlainButton_Pixels, 0, 32,24,	12,12+24, 1,12,  0,0

PlainButton_ImageHoverLT:	DefPgtImage PlainButton_Pixels, 0, 32,24,	0,0+24, 12,24,  0,0
PlainButton_ImageHoverLV:	DefPgtImage PlainButton_Pixels, 0, 32,24,	0,12+24, 12,1,  0,0

PlainButton_ImageHoverRT:	DefPgtImage PlainButton_Pixels, 0, 32,24,	12,0+24, 12,24,  0,0
PlainButton_ImageHoverRV:	DefPgtImage PlainButton_Pixels, 0, 32,24,	12,12+24, 12,1,  0,0

PlainButton_ImageDownHT:	DefPgtImage PlainButton_Pixels, 0, 32,24,	12,0+48, 1,12,  0,0
PlainButton_ImageDownHV:	DefPgtImage PlainButton_Pixels, 0, 32,24,	12,12+48, 1,1,  0,0
PlainButton_ImageDownHB:	DefPgtImage PlainButton_Pixels, 0, 32,24,	12,12+48, 1,12,  0,0

PlainButton_ImageDownLT:	DefPgtImage PlainButton_Pixels, 0, 32,24,	0,0+48, 12,24,  0,0
PlainButton_ImageDownLV:	DefPgtImage PlainButton_Pixels, 0, 32,24,	0,12+48, 12,1,  0,0

PlainButton_ImageDownRT:	DefPgtImage PlainButton_Pixels, 0, 32,24,	12,0+48, 12,24,  0,0
PlainButton_ImageDownRV:	DefPgtImage PlainButton_Pixels, 0, 32,24,	12,12+48, 12,1,  0,0

alignq
PlainButton_Pixels:  incbin "styles/islandpastels/button.raw" ;"button-opaque.raw"

%elifdef PlainStyleLavenderCut

alignd
csym PlainButton_Layers

DefPgtLayerState PgtLayer.BopStateSpecific, PlainButton.StateDown, 0 // if button state down

	; pushed
	DefPgtLayer1 PlainButton_ImageDownHT, PgtLayer.BopOpaque|PgtLayer.FlagLTRT|PgtLayer.FlagTile, 12,0,-12,12
	DefPgtLayer1 PlainButton_ImageDownHV, PgtLayer.BopOpaque|PgtLayer.FlagLTRB|PgtLayer.FlagTile, 12,12,-12,-12
	DefPgtLayer1 PlainButton_ImageDownHB, PgtLayer.BopOpaque|PgtLayer.FlagLBRB|PgtLayer.FlagTile, 12,-12,-12,0

	DefPgtLayer1 PlainButton_ImageDownLT, PgtLayer.BopTrans|PgtLayer.FlagLTLT, 0,0,12,12
	DefPgtLayer1 PlainButton_ImageDownLV, PgtLayer.BopOpaque|PgtLayer.FlagLTLB|PgtLayer.FlagTile, 0,12,12,-12
	DefPgtLayer1 PlainButton_ImageDownLT, PgtLayer.BopTrans|PgtLayer.FlagLBLB|PgtLayer.FlagAlignBottom, 0,-12,12,0

	DefPgtLayer1 PlainButton_ImageDownRT, PgtLayer.BopTrans|PgtLayer.FlagRTRT, -12,0,0,12
	DefPgtLayer1 PlainButton_ImageDownRV, PgtLayer.BopOpaque|PgtLayer.FlagLeftOpposite|PgtLayer.FlagTile, -12,12,0,-12
	DefPgtLayer1 PlainButton_ImageDownRT, PgtLayer.BopTrans|PgtLayer.FlagRBRB|PgtLayer.FlagAlignBottom, -12,-12,0,0

DefPgtLayerState PgtLayer.BopStateSpecific, 0, PlainButton.StateDown // else
DefPgtLayerState PgtLayer.BopStateGeneric, PlainVue.FlagsMouseFocus, 0 // if mouse focus

	; hovered
	DefPgtLayer1 PlainButton_ImageHoverHT, PgtLayer.BopOpaque|PgtLayer.FlagLTRT|PgtLayer.FlagTile, 12,0,-12,12
	DefPgtLayer1 PlainButton_ImageHoverHV, PgtLayer.BopOpaque|PgtLayer.FlagLTRB|PgtLayer.FlagTile, 12,12,-12,-12
	DefPgtLayer1 PlainButton_ImageHoverHB, PgtLayer.BopOpaque|PgtLayer.FlagLBRB|PgtLayer.FlagTile, 12,-12,-12,0

	DefPgtLayer1 PlainButton_ImageHoverLT, PgtLayer.BopTrans|PgtLayer.FlagLTLT, 0,0,12,12
	DefPgtLayer1 PlainButton_ImageHoverLV, PgtLayer.BopOpaque|PgtLayer.FlagLTLB|PgtLayer.FlagTile, 0,12,12,-12
	DefPgtLayer1 PlainButton_ImageHoverLT, PgtLayer.BopTrans|PgtLayer.FlagLBLB|PgtLayer.FlagAlignBottom, 0,-12,12,0

	DefPgtLayer1 PlainButton_ImageHoverRT, PgtLayer.BopTrans|PgtLayer.FlagRTRT, -12,0,0,12
	DefPgtLayer1 PlainButton_ImageHoverRV, PgtLayer.BopOpaque|PgtLayer.FlagLeftOpposite|PgtLayer.FlagTile, -12,12,0,-12
	DefPgtLayer1 PlainButton_ImageHoverRT, PgtLayer.BopTrans|PgtLayer.FlagRBRB|PgtLayer.FlagAlignBottom, -12,-12,0,0

DefPgtLayerState PgtLayer.BopStateGeneric, 0, PlainVue.FlagsMouseFocus // else

	; normal
	DefPgtLayer1 PlainButton_ImageNormalHT, PgtLayer.BopOpaque|PgtLayer.FlagLTRT|PgtLayer.FlagTile, 12,0,-12,12
	DefPgtLayer1 PlainButton_ImageNormalHV, PgtLayer.BopOpaque|PgtLayer.FlagLTRB|PgtLayer.FlagTile, 12,12,-12,-12
	DefPgtLayer1 PlainButton_ImageNormalHB, PgtLayer.BopOpaque|PgtLayer.FlagLBRB|PgtLayer.FlagTile, 12,-12,-12,0

	DefPgtLayer1 PlainButton_ImageNormalLT, PgtLayer.BopTrans|PgtLayer.FlagLTLT, 0,0,12,12
	DefPgtLayer1 PlainButton_ImageNormalLV, PgtLayer.BopOpaque|PgtLayer.FlagLTLB|PgtLayer.FlagTile, 0,12,12,-12
	DefPgtLayer1 PlainButton_ImageNormalLT, PgtLayer.BopTrans|PgtLayer.FlagLBLB|PgtLayer.FlagAlignBottom, 0,-12,12,0

	DefPgtLayer1 PlainButton_ImageNormalRT, PgtLayer.BopTrans|PgtLayer.FlagRTRT, -12,0,0,12
	DefPgtLayer1 PlainButton_ImageNormalRV, PgtLayer.BopOpaque|PgtLayer.FlagLeftOpposite|PgtLayer.FlagTile, -12,12,0,-12
	DefPgtLayer1 PlainButton_ImageNormalRT, PgtLayer.BopTrans|PgtLayer.FlagRBRB|PgtLayer.FlagAlignBottom, -12,-12,0,0

// endif, endif
DefPgtLayerEnd

PlainButton_ImageNormalHT:	DefPgtImage PlainButton_Pixels, 0, 32,24,	12,0, 1,12,  0,0
PlainButton_ImageNormalHV:	DefPgtImage PlainButton_Pixels, 0, 32,24,	12,12, 1,1,  0,0
PlainButton_ImageNormalHB:	DefPgtImage PlainButton_Pixels, 0, 32,24,	12,12, 1,12,  0,0

PlainButton_ImageNormalLT:	DefPgtImage PlainButton_Pixels, 0, 32,24,	0,0, 12,24,  0,0
PlainButton_ImageNormalLV:	DefPgtImage PlainButton_Pixels, 0, 32,24,	0,12, 12,1,  0,0

PlainButton_ImageNormalRT:	DefPgtImage PlainButton_Pixels, 0, 32,24,	12,0, 12,24,  0,0
PlainButton_ImageNormalRV:	DefPgtImage PlainButton_Pixels, 0, 32,24,	12,12, 12,1,  0,0

PlainButton_ImageHoverHT:	DefPgtImage PlainButton_Pixels, 0, 32,24,	12,0+24, 1,12,  0,0
PlainButton_ImageHoverHV:	DefPgtImage PlainButton_Pixels, 0, 32,24,	12,12+24, 1,1,  0,0
PlainButton_ImageHoverHB:	DefPgtImage PlainButton_Pixels, 0, 32,24,	12,12+24, 1,12,  0,0

PlainButton_ImageHoverLT:	DefPgtImage PlainButton_Pixels, 0, 32,24,	0,0+24, 12,24,  0,0
PlainButton_ImageHoverLV:	DefPgtImage PlainButton_Pixels, 0, 32,24,	0,12+24, 12,1,  0,0

PlainButton_ImageHoverRT:	DefPgtImage PlainButton_Pixels, 0, 32,24,	12,0+24, 12,24,  0,0
PlainButton_ImageHoverRV:	DefPgtImage PlainButton_Pixels, 0, 32,24,	12,12+24, 12,1,  0,0

PlainButton_ImageDownHT:	DefPgtImage PlainButton_Pixels, 0, 32,24,	12,0+48, 1,12,  0,0
PlainButton_ImageDownHV:	DefPgtImage PlainButton_Pixels, 0, 32,24,	12,12+48, 1,1,  0,0
PlainButton_ImageDownHB:	DefPgtImage PlainButton_Pixels, 0, 32,24,	12,12+48, 1,12,  0,0

PlainButton_ImageDownLT:	DefPgtImage PlainButton_Pixels, 0, 32,24,	0,0+48, 12,24,  0,0
PlainButton_ImageDownLV:	DefPgtImage PlainButton_Pixels, 0, 32,24,	0,12+48, 12,1,  0,0

PlainButton_ImageDownRT:	DefPgtImage PlainButton_Pixels, 0, 32,24,	12,0+48, 12,24,  0,0
PlainButton_ImageDownRV:	DefPgtImage PlainButton_Pixels, 0, 32,24,	12,12+48, 12,1,  0,0

alignq
PlainButton_Pixels:  incbin "styles/lavendercut/button.raw" ;"button-opaque.raw"

%elifdef PlainStyleNeonMist

%else ;%elifdef PlainStyleTealOnGray
alignd
csym PlainButton_Layers

DefPgtLayerState PgtLayer.BopStateSpecific, PlainButton.StateDown, 0 // if button state down

	; pushed
	DefPgtLayer1 PlainButton_ImageDownHT, PgtLayer.BopOpaque|PgtLayer.FlagLTRT|PgtLayer.FlagTile, 12,0,-12,12
	DefPgtLayer1 PlainButton_ImageDownHV, PgtLayer.BopOpaque|PgtLayer.FlagLTRB|PgtLayer.FlagTile, 12,12,-12,-12
	DefPgtLayer1 PlainButton_ImageDownHB, PgtLayer.BopOpaque|PgtLayer.FlagLBRB|PgtLayer.FlagTile, 12,-12,-12,0

	DefPgtLayer1 PlainButton_ImageDownLT, PgtLayer.BopTrans|PgtLayer.FlagLTLT, 0,0,12,12
	DefPgtLayer1 PlainButton_ImageDownLV, PgtLayer.BopOpaque|PgtLayer.FlagLTLB|PgtLayer.FlagTile, 0,12,12,-12
	DefPgtLayer1 PlainButton_ImageDownLT, PgtLayer.BopTrans|PgtLayer.FlagLBLB|PgtLayer.FlagAlignBottom, 0,-12,12,0

	DefPgtLayer1 PlainButton_ImageDownRT, PgtLayer.BopTrans|PgtLayer.FlagRTRT, -12,0,0,12
	DefPgtLayer1 PlainButton_ImageDownRV, PgtLayer.BopOpaque|PgtLayer.FlagLeftOpposite|PgtLayer.FlagTile, -12,12,0,-12
	DefPgtLayer1 PlainButton_ImageDownRT, PgtLayer.BopTrans|PgtLayer.FlagRBRB|PgtLayer.FlagAlignBottom, -12,-12,0,0

DefPgtLayerState PgtLayer.BopStateSpecific, 0, PlainButton.StateDown // else
DefPgtLayerState PgtLayer.BopStateGeneric, PlainVue.FlagsMouseFocus, 0 // if mouse focus

	; hovered
	DefPgtLayer1 PlainButton_ImageHoverHT, PgtLayer.BopOpaque|PgtLayer.FlagLTRT|PgtLayer.FlagTile, 12,0,-12,12
	DefPgtLayer1 PlainButton_ImageHoverHV, PgtLayer.BopOpaque|PgtLayer.FlagLTRB|PgtLayer.FlagTile, 12,12,-12,-12
	DefPgtLayer1 PlainButton_ImageHoverHB, PgtLayer.BopOpaque|PgtLayer.FlagLBRB|PgtLayer.FlagTile, 12,-12,-12,0

	DefPgtLayer1 PlainButton_ImageHoverLT, PgtLayer.BopTrans|PgtLayer.FlagLTLT, 0,0,12,12
	DefPgtLayer1 PlainButton_ImageHoverLV, PgtLayer.BopOpaque|PgtLayer.FlagLTLB|PgtLayer.FlagTile, 0,12,12,-12
	DefPgtLayer1 PlainButton_ImageHoverLT, PgtLayer.BopTrans|PgtLayer.FlagLBLB|PgtLayer.FlagAlignBottom, 0,-12,12,0

	DefPgtLayer1 PlainButton_ImageHoverRT, PgtLayer.BopTrans|PgtLayer.FlagRTRT, -12,0,0,12
	DefPgtLayer1 PlainButton_ImageHoverRV, PgtLayer.BopOpaque|PgtLayer.FlagLeftOpposite|PgtLayer.FlagTile, -12,12,0,-12
	DefPgtLayer1 PlainButton_ImageHoverRT, PgtLayer.BopTrans|PgtLayer.FlagRBRB|PgtLayer.FlagAlignBottom, -12,-12,0,0

DefPgtLayerState PgtLayer.BopStateGeneric, 0, PlainVue.FlagsMouseFocus // else

	; normal
	DefPgtLayer1 PlainButton_ImageNormalHT, PgtLayer.BopOpaque|PgtLayer.FlagLTRT|PgtLayer.FlagTile, 12,0,-12,12
	DefPgtLayer1 PlainButton_ImageNormalHV, PgtLayer.BopOpaque|PgtLayer.FlagLTRB|PgtLayer.FlagTile, 12,12,-12,-12
	DefPgtLayer1 PlainButton_ImageNormalHB, PgtLayer.BopOpaque|PgtLayer.FlagLBRB|PgtLayer.FlagTile, 12,-12,-12,0

	DefPgtLayer1 PlainButton_ImageNormalLT, PgtLayer.BopTrans|PgtLayer.FlagLTLT, 0,0,12,12
	DefPgtLayer1 PlainButton_ImageNormalLV, PgtLayer.BopOpaque|PgtLayer.FlagLTLB|PgtLayer.FlagTile, 0,12,12,-12
	DefPgtLayer1 PlainButton_ImageNormalLT, PgtLayer.BopTrans|PgtLayer.FlagLBLB|PgtLayer.FlagAlignBottom, 0,-12,12,0

	DefPgtLayer1 PlainButton_ImageNormalRT, PgtLayer.BopTrans|PgtLayer.FlagRTRT, -12,0,0,12
	DefPgtLayer1 PlainButton_ImageNormalRV, PgtLayer.BopOpaque|PgtLayer.FlagLeftOpposite|PgtLayer.FlagTile, -12,12,0,-12
	DefPgtLayer1 PlainButton_ImageNormalRT, PgtLayer.BopTrans|PgtLayer.FlagRBRB|PgtLayer.FlagAlignBottom, -12,-12,0,0

// endif, endif
DefPgtLayerEnd

PlainButton_ImageNormalHT:	DefPgtImage PlainButton_PixelsNormal, 0, 32,24,	12,0, 1,12,  0,0
PlainButton_ImageNormalHV:	DefPgtImage PlainButton_PixelsNormal, 0, 32,24,	12,12, 1,1,  0,0
PlainButton_ImageNormalHB:	DefPgtImage PlainButton_PixelsNormal, 0, 32,24,	12,12, 1,12,  0,0

PlainButton_ImageNormalLT:	DefPgtImage PlainButton_PixelsNormal, 0, 32,24,	0,0, 12,24,  0,0
PlainButton_ImageNormalLV:	DefPgtImage PlainButton_PixelsNormal, 0, 32,24,	0,12, 12,1,  0,0

PlainButton_ImageNormalRT:	DefPgtImage PlainButton_PixelsNormal, 0, 32,24,	12,0, 12,24,  0,0
PlainButton_ImageNormalRV:	DefPgtImage PlainButton_PixelsNormal, 0, 32,24,	12,12, 12,1,  0,0

alignq
PlainButton_PixelsNormal:  incbin "styles/tealongray/buttonnormal.raw"

PlainButton_ImageHoverHT:	DefPgtImage PlainButton_PixelsHover, 0, 32,24,	12,0, 1,12,  0,0
PlainButton_ImageHoverHV:	DefPgtImage PlainButton_PixelsHover, 0, 32,24,	12,12, 1,1,  0,0
PlainButton_ImageHoverHB:	DefPgtImage PlainButton_PixelsHover, 0, 32,24,	12,12, 1,12,  0,0

PlainButton_ImageHoverLT:	DefPgtImage PlainButton_PixelsHover, 0, 32,24,	0,0, 12,24,  0,0
PlainButton_ImageHoverLV:	DefPgtImage PlainButton_PixelsHover, 0, 32,24,	0,12, 12,1,  0,0

PlainButton_ImageHoverRT:	DefPgtImage PlainButton_PixelsHover, 0, 32,24,	12,0, 12,24,  0,0
PlainButton_ImageHoverRV:	DefPgtImage PlainButton_PixelsHover, 0, 32,24,	12,12, 12,1,  0,0

alignq
PlainButton_PixelsHover:  incbin "styles/tealongray/buttonhover.raw"

PlainButton_ImageDownHT:	DefPgtImage PlainButton_PixelsDown, 0, 32,24,	12,0, 1,12,  0,0
PlainButton_ImageDownHV:	DefPgtImage PlainButton_PixelsDown, 0, 32,24,	12,12, 1,1,  0,0
PlainButton_ImageDownHB:	DefPgtImage PlainButton_PixelsDown, 0, 32,24,	12,12, 1,12,  0,0

PlainButton_ImageDownLT:	DefPgtImage PlainButton_PixelsDown, 0, 32,24,	0,0, 12,24,  0,0
PlainButton_ImageDownLV:	DefPgtImage PlainButton_PixelsDown, 0, 32,24,	0,12, 12,1,  0,0

PlainButton_ImageDownRT:	DefPgtImage PlainButton_PixelsDown, 0, 32,24,	12,0, 12,24,  0,0
PlainButton_ImageDownRV:	DefPgtImage PlainButton_PixelsDown, 0, 32,24,	12,12, 12,1,  0,0

alignq
PlainButton_PixelsDown:  incbin "styles/tealongray/buttondown.raw"
%endif






////////////////////////////// WINDOW BG //////////////////////////////
%ifdef nothing
%elifdef PlainStyleIslandPastelsFlat
alignd
csym PlainWindowBg_Layers
//DefPgtLayer1 WindowBg_ImageKirei, PgtLayer.BopOpaque|PgtLayer.FlagLTRB, 0,0, 0,0
DefPgtLayer1 WindowBg_ImageHV, PgtLayer.BopOpaque|PgtLayer.FlagLTRB|PgtLayer.FlagTile, 4,4,-4,-4
DefPgtLayer1 WindowBg_ImageHT, PgtLayer.BopOpaque|PgtLayer.FlagLTRT|PgtLayer.FlagTileHorz, 4,0,-4,4
DefPgtLayer1 WindowBg_ImageHB, PgtLayer.BopOpaque|PgtLayer.FlagLBRB|PgtLayer.FlagTileHorz, 4,-4,-4,0
DefPgtLayer1 WindowBg_ImageLV, PgtLayer.BopOpaque|PgtLayer.FlagLTLB|PgtLayer.FlagTileVert, 0,4,4,-4
DefPgtLayer1 WindowBg_ImageRV, PgtLayer.BopOpaque|PgtLayer.FlagRTRB|PgtLayer.FlagTileVert, -4,4,0,-4
DefPgtLayer1 WindowBg_ImageLT, PgtLayer.BopOpaque|PgtLayer.FlagLTLT|PgtLayer.FlagAlignTop, 0,0,4,4
DefPgtLayer1 WindowBg_ImageRT, PgtLayer.BopOpaque|PgtLayer.FlagRTRT|PgtLayer.FlagAlignTop, -4,0,0,4
DefPgtLayer1 WindowBg_ImageLB, PgtLayer.BopOpaque|PgtLayer.FlagLBLB|PgtLayer.FlagAlignBottom, 0,-4,4,0
DefPgtLayer1 WindowBg_ImageRB, PgtLayer.BopOpaque|PgtLayer.FlagRBRB|PgtLayer.FlagAlignBottom, -4,-4,0,0
DefPgtLayer1 WindowBg_ImageStar, PgtLayer.BopTrans, -4,-4,0,0
DefPgtLayerEnd

WindowBg_ImageHV:	DefPgtImage WindowBg_Pixels, 0,	32,12,	4,4, 1,1,  0,0
WindowBg_ImageHT:	DefPgtImage WindowBg_Pixels, 0,	32,12,	4,0, 1,4,  0,0
WindowBg_ImageHB:	DefPgtImage WindowBg_Pixels, 0,	32,12,	4,8, 1,4,  0,0
WindowBg_ImageLV:	DefPgtImage WindowBg_Pixels, 0,	32,12,	0,4, 4,1,  0,0
WindowBg_ImageRV:	DefPgtImage WindowBg_Pixels, 0,	32,12,	8,4, 4,1,  0,0
WindowBg_ImageLT:	DefPgtImage WindowBg_Pixels, 0,	32,12,	0,0, 4,4,  0,0
WindowBg_ImageRT:	DefPgtImage WindowBg_Pixels, 0,	32,12,	8,0, 4,4,  0,0
WindowBg_ImageLB:	DefPgtImage WindowBg_Pixels, 0,	32,12,	0,8, 4,4,  0,0
WindowBg_ImageRB:	DefPgtImage WindowBg_Pixels, 0,	32,12,	8,8, 4,4,  0,0
WindowBg_ImageStar:	DefPgtImage WindowBg_PixelsStar, 0,	32,40,	0,0, 40,40,  0,0

//WindowBg_ImageKirei:	DefPgtImage WindowBg_PixelsStar, 0,	32,320,	0,0, 320,240,  0,0

alignq
WindowBg_Pixels:  incbin "styles/islandpastels/borderconvex.raw"
WindowBg_PixelsStar:  incbin "styles/islandpastels/windowrootstar.raw"
//WindowBg_PixelsKirei:	incbin "styles/islandpastels/gensho-sugiyama_NGMA2_004.raw"

;%elifdef PlainStyleNeonMist

%elifdef PlainStyleLavenderCut
alignd
csym PlainWindowBg_Layers
//DefPgtLayer1 WindowBg_ImageKirei, PgtLayer.BopOpaque|PgtLayer.FlagLTRB, 0,0, 0,0
DefPgtLayer1 WindowBg_ImageHV, PgtLayer.BopOpaque|PgtLayer.FlagLTRB|PgtLayer.FlagTile, 4,4,-4,-4
DefPgtLayer1 WindowBg_ImageHT, PgtLayer.BopOpaque|PgtLayer.FlagLTRT|PgtLayer.FlagTileHorz, 4,0,-4,4
DefPgtLayer1 WindowBg_ImageHB, PgtLayer.BopOpaque|PgtLayer.FlagLBRB|PgtLayer.FlagTileHorz, 4,-4,-4,0
DefPgtLayer1 WindowBg_ImageLV, PgtLayer.BopOpaque|PgtLayer.FlagLTLB|PgtLayer.FlagTileVert, 0,4,4,-4
DefPgtLayer1 WindowBg_ImageRV, PgtLayer.BopOpaque|PgtLayer.FlagRTRB|PgtLayer.FlagTileVert, -4,4,0,-4
DefPgtLayer1 WindowBg_ImageLT, PgtLayer.BopOpaque|PgtLayer.FlagLTLT|PgtLayer.FlagAlignTop, 0,0,4,4
DefPgtLayer1 WindowBg_ImageRT, PgtLayer.BopOpaque|PgtLayer.FlagRTRT|PgtLayer.FlagAlignTop, -4,0,0,4
DefPgtLayer1 WindowBg_ImageLB, PgtLayer.BopOpaque|PgtLayer.FlagLBLB|PgtLayer.FlagAlignBottom, 0,-4,4,0
DefPgtLayer1 WindowBg_ImageRB, PgtLayer.BopOpaque|PgtLayer.FlagRBRB|PgtLayer.FlagAlignBottom, -4,-4,0,0
DefPgtLayer1 WindowBg_ImageStar, PgtLayer.BopTrans, -4,-4,0,0
DefPgtLayerEnd

WindowBg_ImageHV:	DefPgtImage WindowBg_Pixels, 0,	32,12,	4,4, 1,1,  0,0
WindowBg_ImageHT:	DefPgtImage WindowBg_Pixels, 0,	32,12,	4,0, 1,4,  0,0
WindowBg_ImageHB:	DefPgtImage WindowBg_Pixels, 0,	32,12,	4,8, 1,4,  0,0
WindowBg_ImageLV:	DefPgtImage WindowBg_Pixels, 0,	32,12,	0,4, 4,1,  0,0
WindowBg_ImageRV:	DefPgtImage WindowBg_Pixels, 0,	32,12,	8,4, 4,1,  0,0
WindowBg_ImageLT:	DefPgtImage WindowBg_Pixels, 0,	32,12,	0,0, 4,4,  0,0
WindowBg_ImageRT:	DefPgtImage WindowBg_Pixels, 0,	32,12,	8,0, 4,4,  0,0
WindowBg_ImageLB:	DefPgtImage WindowBg_Pixels, 0,	32,12,	0,8, 4,4,  0,0
WindowBg_ImageRB:	DefPgtImage WindowBg_Pixels, 0,	32,12,	8,8, 4,4,  0,0
WindowBg_ImageStar:	DefPgtImage WindowBg_PixelsStar, 0,	32,40,	0,0, 40,40,  0,0

//WindowBg_ImageKirei:	DefPgtImage WindowBg_PixelsStar, 0,	32,320,	0,0, 320,240,  0,0

alignq
WindowBg_Pixels:  incbin "styles/lavendercut/borderconvex.raw"
WindowBg_PixelsStar:  incbin "styles/lavendercut/windowrootstar.raw"
//WindowBg_PixelsKirei:	incbin "styles/lavendercut/gensho-sugiyama_NGMA2_004.raw"

;%elifdef PlainStyleNeonMist

%else ;elifdef PlainStyleTealOnGray
alignd
csym PlainWindowBg_Layers
DefPgtLayer1 WindowBg_ImageHV, PgtLayer.BopOpaque|PgtLayer.FlagLTRB|PgtLayer.FlagTile, 4,4,-4,-4
DefPgtLayer1 WindowBg_ImageHT, PgtLayer.BopOpaque|PgtLayer.FlagLTRT|PgtLayer.FlagTileHorz, 4,0,-4,4
DefPgtLayer1 WindowBg_ImageHB, PgtLayer.BopOpaque|PgtLayer.FlagLBRB|PgtLayer.FlagTileHorz, 4,-4,-4,0
DefPgtLayer1 WindowBg_ImageLV, PgtLayer.BopOpaque|PgtLayer.FlagLTLB|PgtLayer.FlagTileVert, 0,4,4,-4
DefPgtLayer1 WindowBg_ImageRV, PgtLayer.BopOpaque|PgtLayer.FlagRTRB|PgtLayer.FlagTileVert, -4,4,0,-4
DefPgtLayer1 WindowBg_ImageLT, PgtLayer.BopOpaque|PgtLayer.FlagLTLT|PgtLayer.FlagAlignTop, 0,0,4,4
DefPgtLayer1 WindowBg_ImageRT, PgtLayer.BopOpaque|PgtLayer.FlagRTRT|PgtLayer.FlagAlignTop, -4,0,0,4
DefPgtLayer1 WindowBg_ImageLB, PgtLayer.BopOpaque|PgtLayer.FlagLBLB|PgtLayer.FlagAlignBottom, 0,-4,4,0
DefPgtLayer1 WindowBg_ImageRB, PgtLayer.BopOpaque|PgtLayer.FlagRBRB|PgtLayer.FlagAlignBottom, -4,-4,0,0
DefPgtLayerEnd

WindowBg_ImageHV:	DefPgtImage WindowBg_Pixels, 0,	32,12,	4,4, 1,1,  0,0
WindowBg_ImageHT:	DefPgtImage WindowBg_Pixels, 0,	32,12,	4,0, 1,4,  0,0
WindowBg_ImageHB:	DefPgtImage WindowBg_Pixels, 0,	32,12,	4,8, 1,4,  0,0
WindowBg_ImageLV:	DefPgtImage WindowBg_Pixels, 0,	32,12,	0,4, 4,1,  0,0
WindowBg_ImageRV:	DefPgtImage WindowBg_Pixels, 0,	32,12,	8,4, 4,1,  0,0
WindowBg_ImageLT:	DefPgtImage WindowBg_Pixels, 0,	32,12,	0,0, 4,4,  0,0
WindowBg_ImageRT:	DefPgtImage WindowBg_Pixels, 0,	32,12,	8,0, 4,4,  0,0
WindowBg_ImageLB:	DefPgtImage WindowBg_Pixels, 0,	32,12,	0,8, 4,4,  0,0
WindowBg_ImageRB:	DefPgtImage WindowBg_Pixels, 0,	32,12,	8,8, 4,4,  0,0

alignq
WindowBg_Pixels:  incbin "styles/neonmist/borderconvex.raw"
%endif






////////////////////////////// TEXT EDITS //////////////////////////////
%ifdef nothing
%elifdef PlainStyleIslandPastelsFlat

alignd
csym PlainEdit_Layers

DefPgtLayerState PgtLayer.BopStateSpecific, PlainEdit.StateInvalid, 0 // if edit state Invalid

	; invalid
	DefPgtLayer1 PlainEdit_ImageInvalidHT, PgtLayer.BopOpaque|PgtLayer.FlagLTRT|PgtLayer.FlagTile, 10,0,-10,10
	DefPgtLayer1 PlainEdit_ImageInvalidHV, PgtLayer.BopOpaque|PgtLayer.FlagLTRB|PgtLayer.FlagTile, 10,10,-10,-10
	DefPgtLayer1 PlainEdit_ImageInvalidHB, PgtLayer.BopOpaque|PgtLayer.FlagLBRB|PgtLayer.FlagTile, 10,-10,-10,0

	DefPgtLayer1 PlainEdit_ImageInvalidLT, PgtLayer.BopTrans|PgtLayer.FlagLTLT, 0,0,10,10
	DefPgtLayer1 PlainEdit_ImageInvalidLV, PgtLayer.BopOpaque|PgtLayer.FlagLTLB|PgtLayer.FlagTile, 0,10,10,-10
	DefPgtLayer1 PlainEdit_ImageInvalidLT, PgtLayer.BopTrans|PgtLayer.FlagLBLB|PgtLayer.FlagAlignBottom, 0,-10,10,0

	DefPgtLayer1 PlainEdit_ImageInvalidRT, PgtLayer.BopTrans|PgtLayer.FlagRTRT, -10,0,0,10
	DefPgtLayer1 PlainEdit_ImageInvalidRV, PgtLayer.BopOpaque|PgtLayer.FlagLeftOpposite|PgtLayer.FlagTile, -10,10,0,-10
	DefPgtLayer1 PlainEdit_ImageInvalidRT, PgtLayer.BopTrans|PgtLayer.FlagRBRB|PgtLayer.FlagAlignBottom, -10,-10,0,0

DefPgtLayerState PgtLayer.BopStateSpecific, 0, PlainEdit.StateInvalid // else

	; normal
	DefPgtLayer1 PlainEdit_ImageNormalHT, PgtLayer.BopOpaque|PgtLayer.FlagLTRT|PgtLayer.FlagTile, 10,0,-10,10
	DefPgtLayer1 PlainEdit_ImageNormalHV, PgtLayer.BopOpaque|PgtLayer.FlagLTRB|PgtLayer.FlagTile, 10,10,-10,-10
	DefPgtLayer1 PlainEdit_ImageNormalHB, PgtLayer.BopOpaque|PgtLayer.FlagLBRB|PgtLayer.FlagTile, 10,-10,-10,0

	DefPgtLayer1 PlainEdit_ImageNormalLT, PgtLayer.BopTrans|PgtLayer.FlagLTLT, 0,0,10,10
	DefPgtLayer1 PlainEdit_ImageNormalLV, PgtLayer.BopOpaque|PgtLayer.FlagLTLB|PgtLayer.FlagTile, 0,10,10,-10
	DefPgtLayer1 PlainEdit_ImageNormalLT, PgtLayer.BopTrans|PgtLayer.FlagLBLB|PgtLayer.FlagAlignBottom, 0,-10,10,0

	DefPgtLayer1 PlainEdit_ImageNormalRT, PgtLayer.BopTrans|PgtLayer.FlagRTRT, -10,0,0,10
	DefPgtLayer1 PlainEdit_ImageNormalRV, PgtLayer.BopOpaque|PgtLayer.FlagLeftOpposite|PgtLayer.FlagTile, -10,10,0,-10
	DefPgtLayer1 PlainEdit_ImageNormalRT, PgtLayer.BopTrans|PgtLayer.FlagRBRB|PgtLayer.FlagAlignBottom, -10,-10,0,0

DefPgtLayerState PgtLayer.BopStateSpecific, 0, 0 // else
DefPgtLayerState PgtLayer.BopStateGeneric, PlainVue.FlagsKeyFocus, 0 // if key focus

	; focused
	DefPgtLayer1 PlainEdit_ImageFocusHT, PgtLayer.BopOpaque|PgtLayer.FlagLTRT|PgtLayer.FlagTile, 10,0,-10,2
	//DefPgtLayer1 PlainEdit_ImageFocusHV, PgtLayer.BopOpaque|PgtLayer.FlagLTRB|PgtLayer.FlagTile, 10,10,-10,-10
	DefPgtLayer1 PlainEdit_ImageFocusHB, PgtLayer.BopOpaque|PgtLayer.FlagLBRB|PgtLayer.FlagTile, 10,-2,-10,0

	DefPgtLayer1 PlainEdit_ImageFocusLT, PgtLayer.BopTrans|PgtLayer.FlagLTLT, 0,0,10,10
	DefPgtLayer1 PlainEdit_ImageFocusLV, PgtLayer.BopOpaque|PgtLayer.FlagLTLB|PgtLayer.FlagTile, 0,10,1,-10
	DefPgtLayer1 PlainEdit_ImageFocusLT, PgtLayer.BopTrans|PgtLayer.FlagLBLB|PgtLayer.FlagAlignBottom, 0,-10,10,0

	DefPgtLayer1 PlainEdit_ImageFocusRT, PgtLayer.BopTrans|PgtLayer.FlagRTRT, -10,0,0,10
	DefPgtLayer1 PlainEdit_ImageFocusRV, PgtLayer.BopOpaque|PgtLayer.FlagLeftOpposite|PgtLayer.FlagTile, -1,10,0,-10
	DefPgtLayer1 PlainEdit_ImageFocusRT, PgtLayer.BopTrans|PgtLayer.FlagRBRB|PgtLayer.FlagAlignBottom, -10,-10,0,0

//DefPgtLayerState PgtLayer.BopStateGeneric, 0, 0 // endif

// endif
DefPgtLayerEnd

PlainEdit_ImageNormalHT:	DefPgtImage PlainEdit_Pixels, 0, 32,20,	10,0, 1,10,  0,0
PlainEdit_ImageNormalHV:	DefPgtImage PlainEdit_Pixels, 0, 32,20,	10,10, 1,1,  0,0
PlainEdit_ImageNormalHB:	DefPgtImage PlainEdit_Pixels, 0, 32,20,	10,10, 1,10,  0,0

PlainEdit_ImageNormalLT:	DefPgtImage PlainEdit_Pixels, 0, 32,20,	0,0, 10,20,  0,0
PlainEdit_ImageNormalLV:	DefPgtImage PlainEdit_Pixels, 0, 32,20,	0,10, 10,1,  0,0

PlainEdit_ImageNormalRT:	DefPgtImage PlainEdit_Pixels, 0, 32,20,	10,0, 10,20,  0,0
PlainEdit_ImageNormalRV:	DefPgtImage PlainEdit_Pixels, 0, 32,20,	10,10, 10,1,  0,0

PlainEdit_ImageFocusHT:	DefPgtImage PlainEdit_Pixels, 0, 32,20,	10,0+20, 1,1,  0,0
//PlainEdit_ImageFocusHV:	DefPgtImage PlainEdit_Pixels, 0, 32,20,	10,10+20, 1,1,  0,0
PlainEdit_ImageFocusHB:	DefPgtImage PlainEdit_Pixels, 0, 32,20,	10,19+20, 1,1,  0,0

PlainEdit_ImageFocusLT:	DefPgtImage PlainEdit_Pixels, 0, 32,20,	0,0+20, 10,20,  0,0
PlainEdit_ImageFocusLV:	DefPgtImage PlainEdit_Pixels, 0, 32,20,	0,10+20, 1,1,  0,0

PlainEdit_ImageFocusRT:	DefPgtImage PlainEdit_Pixels, 0, 32,20,	10,0+20, 10,20,  0,0
PlainEdit_ImageFocusRV:	DefPgtImage PlainEdit_Pixels, 0, 32,20,	10,10+20, 1,1,  0,0

PlainEdit_ImageInvalidHT:	DefPgtImage PlainEdit_Pixels, 0, 32,20,	10,0+40, 1,10,  0,0
PlainEdit_ImageInvalidHV:	DefPgtImage PlainEdit_Pixels, 0, 32,20,	10,10+40, 1,1,  0,0
PlainEdit_ImageInvalidHB:	DefPgtImage PlainEdit_Pixels, 0, 32,20,	10,10+40, 1,10,  0,0

PlainEdit_ImageInvalidLT:	DefPgtImage PlainEdit_Pixels, 0, 32,20,	0,0+40, 10,20,  0,0
PlainEdit_ImageInvalidLV:	DefPgtImage PlainEdit_Pixels, 0, 32,20,	0,10+40, 10,1,  0,0

PlainEdit_ImageInvalidRT:	DefPgtImage PlainEdit_Pixels, 0, 32,20,	10,0+40, 10,20,  0,0
PlainEdit_ImageInvalidRV:	DefPgtImage PlainEdit_Pixels, 0, 32,20,	10,10+40, 10,1,  0,0

PlainEdit_ImageDisableHT:	DefPgtImage PlainEdit_Pixels, 0, 32,20,	10,0+40, 1,10,  0,0
PlainEdit_ImageDisableHV:	DefPgtImage PlainEdit_Pixels, 0, 32,20,	10,10+40, 1,1,  0,0
PlainEdit_ImageDisableHB:	DefPgtImage PlainEdit_Pixels, 0, 32,20,	10,10+40, 1,10,  0,0

PlainEdit_ImageDisableLT	DefPgtImage PlainEdit_Pixels, 0, 32,20,	0,0+40, 10,20,  0,0
PlainEdit_ImageDisableLV	DefPgtImage PlainEdit_Pixels, 0, 32,20,	0,10+40, 10,1,  0,0

PlainEdit_ImageDisableRT:	DefPgtImage PlainEdit_Pixels, 0, 32,20,	10,0+40, 10,20,  0,0
PlainEdit_ImageDisableRV:	DefPgtImage PlainEdit_Pixels, 0, 32,20,	10,10+40, 10,1,  0,0

alignq
PlainEdit_Pixels:  incbin "styles/islandpastels/edit.raw"

alignd
csym PlainEditCaret_Layers

DefPgtLayerState PgtLayer.BopStateGeneric, PlainVue.FlagsKeyFocus, 0 // if key focus

	; key focus
	DefPgtLayer1 PlainEditCaret_ImageFocusHT, PgtLayer.BopTrans|PgtLayer.FlagLTLT|PgtLayer.FlagTile, 0,2,2,4
	DefPgtLayer1 PlainEditCaret_ImageFocusHV, PgtLayer.BopOpaque|PgtLayer.FlagLTLB|PgtLayer.FlagTile, 0,4,2,-4
	DefPgtLayer1 PlainEditCaret_ImageFocusHT, PgtLayer.BopTrans|PgtLayer.FlagLBLB|PgtLayer.FlagTile, 0,-4,2,-2

//DefPgtLayerState PgtLayer.BopStateGeneric, 0, PlainVue.FlagsKeyFocus // else

PlainEditCaret_ImageFocusHT:	DefPgtImage PlainEditCaret_Pixels, 0, 32,1,	0,0, 1,1,  0,0
PlainEditCaret_ImageFocusHV:	DefPgtImage PlainEditCaret_Pixels, 0, 32,1,	0,1, 1,1,  0,0

alignq
PlainEditCaret_Pixels:  ;incbin "styles/islandpastels/editcaret.raw"
db 255,128,128,192,  255,128,128,255

%elifdef PlainStyleLavenderCut

alignd
csym PlainEdit_Layers

DefPgtLayerState PgtLayer.BopStateSpecific, PlainEdit.StateInvalid, 0 // if edit state Invalid

	; invalid
	DefPgtLayer1 PlainEdit_ImageInvalidHT, PgtLayer.BopOpaque|PgtLayer.FlagLTRT|PgtLayer.FlagTile, 10,0,-10,10
	DefPgtLayer1 PlainEdit_ImageInvalidHV, PgtLayer.BopOpaque|PgtLayer.FlagLTRB|PgtLayer.FlagTile, 10,10,-10,-10
	DefPgtLayer1 PlainEdit_ImageInvalidHB, PgtLayer.BopOpaque|PgtLayer.FlagLBRB|PgtLayer.FlagTile, 10,-10,-10,0

	DefPgtLayer1 PlainEdit_ImageInvalidLT, PgtLayer.BopTrans|PgtLayer.FlagLTLT, 0,0,10,10
	DefPgtLayer1 PlainEdit_ImageInvalidLV, PgtLayer.BopOpaque|PgtLayer.FlagLTLB|PgtLayer.FlagTile, 0,10,10,-10
	DefPgtLayer1 PlainEdit_ImageInvalidLT, PgtLayer.BopTrans|PgtLayer.FlagLBLB|PgtLayer.FlagAlignBottom, 0,-10,10,0

	DefPgtLayer1 PlainEdit_ImageInvalidRT, PgtLayer.BopTrans|PgtLayer.FlagRTRT, -10,0,0,10
	DefPgtLayer1 PlainEdit_ImageInvalidRV, PgtLayer.BopOpaque|PgtLayer.FlagLeftOpposite|PgtLayer.FlagTile, -10,10,0,-10
	DefPgtLayer1 PlainEdit_ImageInvalidRT, PgtLayer.BopTrans|PgtLayer.FlagRBRB|PgtLayer.FlagAlignBottom, -10,-10,0,0

DefPgtLayerState PgtLayer.BopStateSpecific, 0, PlainEdit.StateInvalid // else

	; normal
	DefPgtLayer1 PlainEdit_ImageNormalHT, PgtLayer.BopOpaque|PgtLayer.FlagLTRT|PgtLayer.FlagTile, 10,0,-10,10
	DefPgtLayer1 PlainEdit_ImageNormalHV, PgtLayer.BopOpaque|PgtLayer.FlagLTRB|PgtLayer.FlagTile, 10,10,-10,-10
	DefPgtLayer1 PlainEdit_ImageNormalHB, PgtLayer.BopOpaque|PgtLayer.FlagLBRB|PgtLayer.FlagTile, 10,-10,-10,0

	DefPgtLayer1 PlainEdit_ImageNormalLT, PgtLayer.BopTrans|PgtLayer.FlagLTLT, 0,0,10,10
	DefPgtLayer1 PlainEdit_ImageNormalLV, PgtLayer.BopOpaque|PgtLayer.FlagLTLB|PgtLayer.FlagTile, 0,10,10,-10
	DefPgtLayer1 PlainEdit_ImageNormalLT, PgtLayer.BopTrans|PgtLayer.FlagLBLB|PgtLayer.FlagAlignBottom, 0,-10,10,0

	DefPgtLayer1 PlainEdit_ImageNormalRT, PgtLayer.BopTrans|PgtLayer.FlagRTRT, -10,0,0,10
	DefPgtLayer1 PlainEdit_ImageNormalRV, PgtLayer.BopOpaque|PgtLayer.FlagLeftOpposite|PgtLayer.FlagTile, -10,10,0,-10
	DefPgtLayer1 PlainEdit_ImageNormalRT, PgtLayer.BopTrans|PgtLayer.FlagRBRB|PgtLayer.FlagAlignBottom, -10,-10,0,0

DefPgtLayerState PgtLayer.BopStateSpecific, 0, 0 // else
DefPgtLayerState PgtLayer.BopStateGeneric, PlainVue.FlagsKeyFocus, 0 // if key focus

	; focused
	DefPgtLayer1 PlainEdit_ImageFocusHT, PgtLayer.BopOpaque|PgtLayer.FlagLTRT|PgtLayer.FlagTile, 10,0,-10,10
	DefPgtLayer1 PlainEdit_ImageFocusHV, PgtLayer.BopOpaque|PgtLayer.FlagLTRB|PgtLayer.FlagTile, 10,10,-10,-10
	DefPgtLayer1 PlainEdit_ImageFocusHB, PgtLayer.BopOpaque|PgtLayer.FlagLBRB|PgtLayer.FlagTile, 10,-10,-10,0

	DefPgtLayer1 PlainEdit_ImageFocusLT, PgtLayer.BopTrans|PgtLayer.FlagLTLT, 0,0,10,10
	DefPgtLayer1 PlainEdit_ImageFocusLV, PgtLayer.BopOpaque|PgtLayer.FlagLTLB|PgtLayer.FlagTile, 0,10,10,-10
	DefPgtLayer1 PlainEdit_ImageFocusLT, PgtLayer.BopTrans|PgtLayer.FlagLBLB|PgtLayer.FlagAlignBottom, 0,-10,10,0

	DefPgtLayer1 PlainEdit_ImageFocusRT, PgtLayer.BopTrans|PgtLayer.FlagRTRT, -10,0,0,10
	DefPgtLayer1 PlainEdit_ImageFocusRV, PgtLayer.BopOpaque|PgtLayer.FlagLeftOpposite|PgtLayer.FlagTile, -10,10,0,-10
	DefPgtLayer1 PlainEdit_ImageFocusRT, PgtLayer.BopTrans|PgtLayer.FlagRBRB|PgtLayer.FlagAlignBottom, -10,-10,0,0

//DefPgtLayerState PgtLayer.BopStateGeneric, 0, 0 // endif

// endif
DefPgtLayerEnd

PlainEdit_ImageNormalHT:	DefPgtImage PlainEdit_Pixels, 0, 32,20,	10,0, 1,10,  0,0
PlainEdit_ImageNormalHV:	DefPgtImage PlainEdit_Pixels, 0, 32,20,	10,10, 1,1,  0,0
PlainEdit_ImageNormalHB:	DefPgtImage PlainEdit_Pixels, 0, 32,20,	10,10, 1,10,  0,0

PlainEdit_ImageNormalLT:	DefPgtImage PlainEdit_Pixels, 0, 32,20,	0,0, 10,20,  0,0
PlainEdit_ImageNormalLV:	DefPgtImage PlainEdit_Pixels, 0, 32,20,	0,10, 10,1,  0,0

PlainEdit_ImageNormalRT:	DefPgtImage PlainEdit_Pixels, 0, 32,20,	10,0, 10,20,  0,0
PlainEdit_ImageNormalRV:	DefPgtImage PlainEdit_Pixels, 0, 32,20,	10,10, 10,1,  0,0

PlainEdit_ImageFocusHT:	DefPgtImage PlainEdit_Pixels, 0, 32,20,	10,0+20, 1,10,  0,0
PlainEdit_ImageFocusHV:	DefPgtImage PlainEdit_Pixels, 0, 32,20,	10,10+20, 1,1,  0,0
PlainEdit_ImageFocusHB:	DefPgtImage PlainEdit_Pixels, 0, 32,20,	10,19+20, 1,1,  0,0

PlainEdit_ImageFocusLT:	DefPgtImage PlainEdit_Pixels, 0, 32,20,	0,0+20, 10,20,  0,0
PlainEdit_ImageFocusLV:	DefPgtImage PlainEdit_Pixels, 0, 32,20,	0,10+20, 1,1,  0,0

PlainEdit_ImageFocusRT:	DefPgtImage PlainEdit_Pixels, 0, 32,20,	10,0+20, 10,20,  0,0
PlainEdit_ImageFocusRV:	DefPgtImage PlainEdit_Pixels, 0, 32,20,	10,10+20, 1,1,  0,0

PlainEdit_ImageInvalidHT:	DefPgtImage PlainEdit_Pixels, 0, 32,20,	10,0+40, 1,10,  0,0
PlainEdit_ImageInvalidHV:	DefPgtImage PlainEdit_Pixels, 0, 32,20,	10,10+40, 1,1,  0,0
PlainEdit_ImageInvalidHB:	DefPgtImage PlainEdit_Pixels, 0, 32,20,	10,10+40, 1,10,  0,0

PlainEdit_ImageInvalidLT:	DefPgtImage PlainEdit_Pixels, 0, 32,20,	0,0+40, 10,20,  0,0
PlainEdit_ImageInvalidLV:	DefPgtImage PlainEdit_Pixels, 0, 32,20,	0,10+40, 10,1,  0,0

PlainEdit_ImageInvalidRT:	DefPgtImage PlainEdit_Pixels, 0, 32,20,	10,0+40, 10,20,  0,0
PlainEdit_ImageInvalidRV:	DefPgtImage PlainEdit_Pixels, 0, 32,20,	10,10+40, 10,1,  0,0

PlainEdit_ImageDisableHT:	DefPgtImage PlainEdit_Pixels, 0, 32,20,	10,0+40, 1,10,  0,0
PlainEdit_ImageDisableHV:	DefPgtImage PlainEdit_Pixels, 0, 32,20,	10,10+40, 1,1,  0,0
PlainEdit_ImageDisableHB:	DefPgtImage PlainEdit_Pixels, 0, 32,20,	10,10+40, 1,10,  0,0

PlainEdit_ImageDisableLT	DefPgtImage PlainEdit_Pixels, 0, 32,20,	0,0+40, 10,20,  0,0
PlainEdit_ImageDisableLV	DefPgtImage PlainEdit_Pixels, 0, 32,20,	0,10+40, 10,1,  0,0

PlainEdit_ImageDisableRT:	DefPgtImage PlainEdit_Pixels, 0, 32,20,	10,0+40, 10,20,  0,0
PlainEdit_ImageDisableRV:	DefPgtImage PlainEdit_Pixels, 0, 32,20,	10,10+40, 10,1,  0,0

alignq
PlainEdit_Pixels:  incbin "styles/lavendercut/edit.raw"

alignd
csym PlainEditCaret_Layers

DefPgtLayerState PgtLayer.BopStateGeneric, PlainVue.FlagsKeyFocus, 0 // if key focus

	; key focus
	DefPgtLayer1 PlainEditCaret_ImageFocusHT, PgtLayer.BopTrans|PgtLayer.FlagLTLT|PgtLayer.FlagTile, 0,2,2,4
	DefPgtLayer1 PlainEditCaret_ImageFocusHV, PgtLayer.BopOpaque|PgtLayer.FlagLTLB|PgtLayer.FlagTile, 0,4,2,-4
	DefPgtLayer1 PlainEditCaret_ImageFocusHT, PgtLayer.BopTrans|PgtLayer.FlagLBLB|PgtLayer.FlagTile, 0,-4,2,-2

//DefPgtLayerState PgtLayer.BopStateGeneric, 0, PlainVue.FlagsKeyFocus // else

PlainEditCaret_ImageFocusHT:	DefPgtImage PlainEditCaret_Pixels, 0, 32,1,	0,0, 1,1,  0,0
PlainEditCaret_ImageFocusHV:	DefPgtImage PlainEditCaret_Pixels, 0, 32,1,	0,1, 1,1,  0,0

alignq
PlainEditCaret_Pixels:  ;incbin "styles/lavendercut/editcaret.raw"
db 255,128,128,192,  255,128,128,255

%elifdef PlainStyleNeonMist

%else ;%elifdef PlainStyleTealOnGray
alignd
csym PlainButton_Layers
%endif



////////////////////////////// LISTS //////////////////////////////
%ifdef nothing
%elifdef PlainStyleIslandPastelsFlat

alignd
csym PlainList_Layers

	; normal
	DefPgtLayer1 PlainList_ImageNormalHT, PgtLayer.BopOpaque|PgtLayer.FlagLTRT|PgtLayer.FlagTile, 10,0,-10,10
	DefPgtLayer1 PlainList_ImageNormalHV, PgtLayer.BopOpaque|PgtLayer.FlagLTRB|PgtLayer.FlagTile, 10,10,-10,-10
	DefPgtLayer1 PlainList_ImageNormalHB, PgtLayer.BopOpaque|PgtLayer.FlagLBRB|PgtLayer.FlagTile, 10,-10,-10,0

	DefPgtLayer1 PlainList_ImageNormalLT, PgtLayer.BopTrans|PgtLayer.FlagLTLT, 0,0,10,10
	DefPgtLayer1 PlainList_ImageNormalLV, PgtLayer.BopOpaque|PgtLayer.FlagLTLB|PgtLayer.FlagTile, 0,10,10,-10
	DefPgtLayer1 PlainList_ImageNormalLT, PgtLayer.BopTrans|PgtLayer.FlagLBLB|PgtLayer.FlagAlignBottom, 0,-10,10,0

	DefPgtLayer1 PlainList_ImageNormalRT, PgtLayer.BopTrans|PgtLayer.FlagRTRT, -10,0,0,10
	DefPgtLayer1 PlainList_ImageNormalRV, PgtLayer.BopOpaque|PgtLayer.FlagLeftOpposite|PgtLayer.FlagTile, -10,10,0,-10
	DefPgtLayer1 PlainList_ImageNormalRT, PgtLayer.BopTrans|PgtLayer.FlagRBRB|PgtLayer.FlagAlignBottom, -10,-10,0,0

DefPgtLayerState PgtLayer.BopStateGeneric, PlainVue.FlagsKeyFocus, 0 // if key focus

	; focused
	DefPgtLayer1 PlainList_ImageFocusHT, PgtLayer.BopOpaque|PgtLayer.FlagLTRT|PgtLayer.FlagTile, 10,0,-10,2
	//DefPgtLayer1 PlainList_ImageFocusHV, PgtLayer.BopOpaque|PgtLayer.FlagLTRB|PgtLayer.FlagTile, 10,10,-10,-10
	DefPgtLayer1 PlainList_ImageFocusHB, PgtLayer.BopOpaque|PgtLayer.FlagLBRB|PgtLayer.FlagTile, 10,-2,-10,0

	DefPgtLayer1 PlainList_ImageFocusLT, PgtLayer.BopTrans|PgtLayer.FlagLTLT, 0,0,10,10
	DefPgtLayer1 PlainList_ImageFocusLV, PgtLayer.BopOpaque|PgtLayer.FlagLTLB|PgtLayer.FlagTile, 0,10,2,-10
	DefPgtLayer1 PlainList_ImageFocusLT, PgtLayer.BopTrans|PgtLayer.FlagLBLB|PgtLayer.FlagAlignBottom, 0,-10,10,0

	DefPgtLayer1 PlainList_ImageFocusRT, PgtLayer.BopTrans|PgtLayer.FlagRTRT, -10,0,0,10
	DefPgtLayer1 PlainList_ImageFocusRV, PgtLayer.BopOpaque|PgtLayer.FlagLeftOpposite|PgtLayer.FlagTile, -2,10,0,-10
	DefPgtLayer1 PlainList_ImageFocusRT, PgtLayer.BopTrans|PgtLayer.FlagRBRB|PgtLayer.FlagAlignBottom, -10,-10,0,0

//DefPgtLayerState PgtLayer.BopStateGeneric, 0, 0 // endif

// endif
DefPgtLayerEnd

PlainList_ImageNormalHT:	DefPgtImage PlainList_Pixels, 0, 32,20,	10,0, 1,10,  0,0
PlainList_ImageNormalHV:	DefPgtImage PlainList_Pixels, 0, 32,20,	10,10, 1,1,  0,0
PlainList_ImageNormalHB:	DefPgtImage PlainList_Pixels, 0, 32,20,	10,10, 1,10,  0,0

PlainList_ImageNormalLT:	DefPgtImage PlainList_Pixels, 0, 32,20,	0,0, 10,20,  0,0
PlainList_ImageNormalLV:	DefPgtImage PlainList_Pixels, 0, 32,20,	0,10, 10,1,  0,0

PlainList_ImageNormalRT:	DefPgtImage PlainList_Pixels, 0, 32,20,	10,0, 10,20,  0,0
PlainList_ImageNormalRV:	DefPgtImage PlainList_Pixels, 0, 32,20,	10,10, 10,1,  0,0

PlainList_ImageFocusHT:	DefPgtImage PlainList_Pixels, 0, 32,20,	10,0+20, 1,1,  0,0
//PlainList_ImageFocusHV:	DefPgtImage PlainList_Pixels, 0, 32,20,	10,10+20, 1,1,  0,0
PlainList_ImageFocusHB:	DefPgtImage PlainList_Pixels, 0, 32,20,	10,19+20, 1,1,  0,0

PlainList_ImageFocusLT:	DefPgtImage PlainList_Pixels, 0, 32,20,	0,0+20, 10,20,  0,0
PlainList_ImageFocusLV:	DefPgtImage PlainList_Pixels, 0, 32,20,	0,10+20, 1,1,  0,0

PlainList_ImageFocusRT:	DefPgtImage PlainList_Pixels, 0, 32,20,	10,0+20, 10,20,  0,0
PlainList_ImageFocusRV:	DefPgtImage PlainList_Pixels, 0, 32,20,	10,10+20, 1,1,  0,0

PlainList_ImageDisableHT:	DefPgtImage PlainList_Pixels, 0, 32,20,	10,0+40, 1,10,  0,0
PlainList_ImageDisableHV:	DefPgtImage PlainList_Pixels, 0, 32,20,	10,10+40, 1,1,  0,0
PlainList_ImageDisableHB:	DefPgtImage PlainList_Pixels, 0, 32,20,	10,10+40, 1,10,  0,0

PlainList_ImageDisableLT	DefPgtImage PlainList_Pixels, 0, 32,20,	0,0+40, 10,20,  0,0
PlainList_ImageDisableLV	DefPgtImage PlainList_Pixels, 0, 32,20,	0,10+40, 10,1,  0,0

PlainList_ImageDisableRT:	DefPgtImage PlainList_Pixels, 0, 32,20,	10,0+40, 10,20,  0,0
PlainList_ImageDisableRV:	DefPgtImage PlainList_Pixels, 0, 32,20,	10,10+40, 10,1,  0,0

alignq
PlainList_Pixels:  incbin "styles/islandpastels/list.raw"

alignd
csym PlainListSelect_Layers

DefPgtLayerState PgtLayer.BopStateGeneric, PlainVue.FlagsKeyFocus, 0 // if key focus

	; key focus
	DefPgtLayer1 PlainListSelect_ImageFocusHT, PgtLayer.BopTrans|PgtLayer.FlagLTLT|PgtLayer.FlagTile, 0,2,2,4
	DefPgtLayer1 PlainListSelect_ImageFocusHV, PgtLayer.BopOpaque|PgtLayer.FlagLTLB|PgtLayer.FlagTile, 0,4,2,-4
	DefPgtLayer1 PlainListSelect_ImageFocusHT, PgtLayer.BopTrans|PgtLayer.FlagLBLB|PgtLayer.FlagTile, 0,-4,2,-2

//DefPgtLayerState PgtLayer.BopStateGeneric, 0, PlainVue.FlagsKeyFocus // else

PlainListSelect_ImageFocusHT:	DefPgtImage PlainListSelect_Pixels, 0, 32,1,	0,0, 1,1,  0,0
PlainListSelect_ImageFocusHV:	DefPgtImage PlainListSelect_Pixels, 0, 32,1,	0,1, 1,1,  0,0

alignq
PlainListSelect_Pixels:  ;incbin "styles/islandpastels/listselect.raw"
db 255,128,128,192,  255,128,128,255

%elifdef PlainStyleLavenderCut

alignd
csym PlainList_Layers

	; normal
	DefPgtLayer1 PlainList_ImageNormalHT, PgtLayer.BopOpaque|PgtLayer.FlagLTRT|PgtLayer.FlagTile, 10,0,-10,10
	DefPgtLayer1 PlainList_ImageNormalHV, PgtLayer.BopOpaque|PgtLayer.FlagLTRB|PgtLayer.FlagTile, 10,10,-10,-10
	DefPgtLayer1 PlainList_ImageNormalHB, PgtLayer.BopOpaque|PgtLayer.FlagLBRB|PgtLayer.FlagTile, 10,-10,-10,0

	DefPgtLayer1 PlainList_ImageNormalLT, PgtLayer.BopTrans|PgtLayer.FlagLTLT, 0,0,10,10
	DefPgtLayer1 PlainList_ImageNormalLV, PgtLayer.BopOpaque|PgtLayer.FlagLTLB|PgtLayer.FlagTile, 0,10,10,-10
	DefPgtLayer1 PlainList_ImageNormalLT, PgtLayer.BopTrans|PgtLayer.FlagLBLB|PgtLayer.FlagAlignBottom, 0,-10,10,0

	DefPgtLayer1 PlainList_ImageNormalRT, PgtLayer.BopTrans|PgtLayer.FlagRTRT, -10,0,0,10
	DefPgtLayer1 PlainList_ImageNormalRV, PgtLayer.BopOpaque|PgtLayer.FlagLeftOpposite|PgtLayer.FlagTile, -10,10,0,-10
	DefPgtLayer1 PlainList_ImageNormalRT, PgtLayer.BopTrans|PgtLayer.FlagRBRB|PgtLayer.FlagAlignBottom, -10,-10,0,0

//DefPgtLayerState PgtLayer.BopStateGeneric, 0, 0 // endif

// endif
DefPgtLayerEnd

PlainList_ImageNormalHT:	DefPgtImage PlainList_Pixels, 0, 32,20,	10,0, 1,10,  0,0
PlainList_ImageNormalHV:	DefPgtImage PlainList_Pixels, 0, 32,20,	10,10, 1,1,  0,0
PlainList_ImageNormalHB:	DefPgtImage PlainList_Pixels, 0, 32,20,	10,10, 1,10,  0,0

PlainList_ImageNormalLT:	DefPgtImage PlainList_Pixels, 0, 32,20,	0,0, 10,20,  0,0
PlainList_ImageNormalLV:	DefPgtImage PlainList_Pixels, 0, 32,20,	0,10, 10,1,  0,0

PlainList_ImageNormalRT:	DefPgtImage PlainList_Pixels, 0, 32,20,	10,0, 10,20,  0,0
PlainList_ImageNormalRV:	DefPgtImage PlainList_Pixels, 0, 32,20,	10,10, 10,1,  0,0

PlainList_ImageFocusHT:	DefPgtImage PlainList_Pixels, 0, 32,20,	10,0+20, 1,1,  0,0
//PlainList_ImageFocusHV:	DefPgtImage PlainList_Pixels, 0, 32,20,	10,10+20, 1,1,  0,0
PlainList_ImageFocusHB:	DefPgtImage PlainList_Pixels, 0, 32,20,	10,19+20, 1,1,  0,0

PlainList_ImageFocusLT:	DefPgtImage PlainList_Pixels, 0, 32,20,	0,0+20, 10,20,  0,0
PlainList_ImageFocusLV:	DefPgtImage PlainList_Pixels, 0, 32,20,	0,10+20, 1,1,  0,0

PlainList_ImageFocusRT:	DefPgtImage PlainList_Pixels, 0, 32,20,	10,0+20, 10,20,  0,0
PlainList_ImageFocusRV:	DefPgtImage PlainList_Pixels, 0, 32,20,	10,10+20, 1,1,  0,0

PlainList_ImageDisableHT:	DefPgtImage PlainList_Pixels, 0, 32,20,	10,0+40, 1,10,  0,0
PlainList_ImageDisableHV:	DefPgtImage PlainList_Pixels, 0, 32,20,	10,10+40, 1,1,  0,0
PlainList_ImageDisableHB:	DefPgtImage PlainList_Pixels, 0, 32,20,	10,10+40, 1,10,  0,0

PlainList_ImageDisableLT	DefPgtImage PlainList_Pixels, 0, 32,20,	0,0+40, 10,20,  0,0
PlainList_ImageDisableLV	DefPgtImage PlainList_Pixels, 0, 32,20,	0,10+40, 10,1,  0,0

PlainList_ImageDisableRT:	DefPgtImage PlainList_Pixels, 0, 32,20,	10,0+40, 10,20,  0,0
PlainList_ImageDisableRV:	DefPgtImage PlainList_Pixels, 0, 32,20,	10,10+40, 10,1,  0,0

alignq
PlainList_Pixels:  incbin "styles/lavendercut/list.raw"

alignd
csym PlainListSelect_Layers

DefPgtLayerState PgtLayer.BopStateGeneric, PlainVue.FlagsKeyFocus, 0 // if key focus

	; key focus
	DefPgtLayer1 PlainListSelect_ImageNormalHT, PgtLayer.BopOpaque|PgtLayer.FlagLTRT|PgtLayer.FlagTile, 10,0,-10,10
	DefPgtLayer1 PlainListSelect_ImageNormalHV, PgtLayer.BopOpaque|PgtLayer.FlagLTRB|PgtLayer.FlagTile, 10,10,-10,-10
	DefPgtLayer1 PlainListSelect_ImageNormalHB, PgtLayer.BopOpaque|PgtLayer.FlagLBRB|PgtLayer.FlagTile, 10,-10,-10,0

	DefPgtLayer1 PlainListSelect_ImageNormalLT, PgtLayer.BopTrans|PgtLayer.FlagLTLT, 0,0,10,10
	DefPgtLayer1 PlainListSelect_ImageNormalLV, PgtLayer.BopOpaque|PgtLayer.FlagLTLB|PgtLayer.FlagTile, 0,10,10,-10
	DefPgtLayer1 PlainListSelect_ImageNormalLT, PgtLayer.BopTrans|PgtLayer.FlagLBLB|PgtLayer.FlagAlignBottom, 0,-10,10,0

	DefPgtLayer1 PlainListSelect_ImageNormalRT, PgtLayer.BopTrans|PgtLayer.FlagRTRT, -10,0,0,10
	DefPgtLayer1 PlainListSelect_ImageNormalRV, PgtLayer.BopOpaque|PgtLayer.FlagLeftOpposite|PgtLayer.FlagTile, -10,10,0,-10
	DefPgtLayer1 PlainListSelect_ImageNormalRT, PgtLayer.BopTrans|PgtLayer.FlagRBRB|PgtLayer.FlagAlignBottom, -10,-10,0,0

//DefPgtLayerState PgtLayer.BopStateGeneric, 0, PlainVue.FlagsKeyFocus // else
DefPgtLayerEnd

PlainListSelect_ImageNormalHT:	DefPgtImage PlainList_Pixels, 0, 32,20,	10,0+20, 1,10,  0,0
PlainListSelect_ImageNormalHV:	DefPgtImage PlainList_Pixels, 0, 32,20,	10,10+20, 1,1,  0,0
PlainListSelect_ImageNormalHB:	DefPgtImage PlainList_Pixels, 0, 32,20,	10,10+20, 1,10,  0,0

PlainListSelect_ImageNormalLT:	DefPgtImage PlainList_Pixels, 0, 32,20,	0,0+20, 10,20,  0,0
PlainListSelect_ImageNormalLV:	DefPgtImage PlainList_Pixels, 0, 32,20,	0,10+20, 10,1,  0,0

PlainListSelect_ImageNormalRT:	DefPgtImage PlainList_Pixels, 0, 32,20,	10,0+20, 10,20,  0,0
PlainListSelect_ImageNormalRV:	DefPgtImage PlainList_Pixels, 0, 32,20,	10,10+20, 10,1,  0,0

%elifdef PlainStyleNeonMist

%else ;%elifdef PlainStyleTealOnGray
alignd
csym PlainMenu_Layers
%endif



////////////////////////////// MENUS //////////////////////////////
%ifdef nothing
%elifdef PlainStyleIslandPastelsFlat

alignd
csym PlainMenu_Layers

	; normal
	DefPgtLayer1 PlainMenu_ImageNormalHT, PgtLayer.BopOpaque|PgtLayer.FlagLTRT|PgtLayer.FlagTile, 10,0,-10,10
	DefPgtLayer1 PlainMenu_ImageNormalHV, PgtLayer.BopOpaque|PgtLayer.FlagLTRB|PgtLayer.FlagTile, 10,10,-10,-10
	DefPgtLayer1 PlainMenu_ImageNormalHB, PgtLayer.BopOpaque|PgtLayer.FlagLBRB|PgtLayer.FlagTile, 10,-10,-10,0

	DefPgtLayer1 PlainMenu_ImageNormalLT, PgtLayer.BopTrans|PgtLayer.FlagLTLT, 0,0,10,10
	DefPgtLayer1 PlainMenu_ImageNormalLV, PgtLayer.BopOpaque|PgtLayer.FlagLTLB|PgtLayer.FlagTile, 0,10,10,-10
	DefPgtLayer1 PlainMenu_ImageNormalLT, PgtLayer.BopTrans|PgtLayer.FlagLBLB|PgtLayer.FlagAlignBottom, 0,-10,10,0

	DefPgtLayer1 PlainMenu_ImageNormalRT, PgtLayer.BopTrans|PgtLayer.FlagRTRT, -10,0,0,10
	DefPgtLayer1 PlainMenu_ImageNormalRV, PgtLayer.BopOpaque|PgtLayer.FlagLeftOpposite|PgtLayer.FlagTile, -10,10,0,-10
	DefPgtLayer1 PlainMenu_ImageNormalRT, PgtLayer.BopTrans|PgtLayer.FlagRBRB|PgtLayer.FlagAlignBottom, -10,-10,0,0

DefPgtLayerState PgtLayer.BopStateGeneric, PlainVue.FlagsKeyFocus, 0 // if key focus

	; focused
	DefPgtLayer1 PlainMenu_ImageFocusHT, PgtLayer.BopOpaque|PgtLayer.FlagLTRT|PgtLayer.FlagTile, 10,0,-10,2
	//DefPgtLayer1 PlainMenu_ImageFocusHV, PgtLayer.BopOpaque|PgtLayer.FlagLTRB|PgtLayer.FlagTile, 10,10,-10,-10
	DefPgtLayer1 PlainMenu_ImageFocusHB, PgtLayer.BopOpaque|PgtLayer.FlagLBRB|PgtLayer.FlagTile, 10,-2,-10,0

	DefPgtLayer1 PlainMenu_ImageFocusLT, PgtLayer.BopTrans|PgtLayer.FlagLTLT, 0,0,10,10
	DefPgtLayer1 PlainMenu_ImageFocusLV, PgtLayer.BopOpaque|PgtLayer.FlagLTLB|PgtLayer.FlagTile, 0,10,2,-10
	DefPgtLayer1 PlainMenu_ImageFocusLT, PgtLayer.BopTrans|PgtLayer.FlagLBLB|PgtLayer.FlagAlignBottom, 0,-10,10,0

	DefPgtLayer1 PlainMenu_ImageFocusRT, PgtLayer.BopTrans|PgtLayer.FlagRTRT, -10,0,0,10
	DefPgtLayer1 PlainMenu_ImageFocusRV, PgtLayer.BopOpaque|PgtLayer.FlagLeftOpposite|PgtLayer.FlagTile, -2,10,0,-10
	DefPgtLayer1 PlainMenu_ImageFocusRT, PgtLayer.BopTrans|PgtLayer.FlagRBRB|PgtLayer.FlagAlignBottom, -10,-10,0,0

//DefPgtLayerState PgtLayer.BopStateGeneric, 0, 0 // endif

// endif
DefPgtLayerEnd

PlainMenu_ImageNormalHT:	DefPgtImage PlainMenu_Pixels, 0, 32,20,	10,0, 1,10,  0,0
PlainMenu_ImageNormalHV:	DefPgtImage PlainMenu_Pixels, 0, 32,20,	10,10, 1,1,  0,0
PlainMenu_ImageNormalHB:	DefPgtImage PlainMenu_Pixels, 0, 32,20,	10,10, 1,10,  0,0

PlainMenu_ImageNormalLT:	DefPgtImage PlainMenu_Pixels, 0, 32,20,	0,0, 10,20,  0,0
PlainMenu_ImageNormalLV:	DefPgtImage PlainMenu_Pixels, 0, 32,20,	0,10, 10,1,  0,0

PlainMenu_ImageNormalRT:	DefPgtImage PlainMenu_Pixels, 0, 32,20,	10,0, 10,20,  0,0
PlainMenu_ImageNormalRV:	DefPgtImage PlainMenu_Pixels, 0, 32,20,	10,10, 10,1,  0,0

PlainMenu_ImageFocusHT:	DefPgtImage PlainMenu_Pixels, 0, 32,20,	10,0+20, 1,1,  0,0
//PlainMenu_ImageFocusHV:	DefPgtImage PlainMenu_Pixels, 0, 32,20,	10,10+20, 1,1,  0,0
PlainMenu_ImageFocusHB:	DefPgtImage PlainMenu_Pixels, 0, 32,20,	10,19+20, 1,1,  0,0

PlainMenu_ImageFocusLT:	DefPgtImage PlainMenu_Pixels, 0, 32,20,	0,0+20, 10,20,  0,0
PlainMenu_ImageFocusLV:	DefPgtImage PlainMenu_Pixels, 0, 32,20,	0,10+20, 1,1,  0,0

PlainMenu_ImageFocusRT:	DefPgtImage PlainMenu_Pixels, 0, 32,20,	10,0+20, 10,20,  0,0
PlainMenu_ImageFocusRV:	DefPgtImage PlainMenu_Pixels, 0, 32,20,	10,10+20, 1,1,  0,0

PlainMenu_ImageDisableHT:	DefPgtImage PlainMenu_Pixels, 0, 32,20,	10,0+40, 1,10,  0,0
PlainMenu_ImageDisableHV:	DefPgtImage PlainMenu_Pixels, 0, 32,20,	10,10+40, 1,1,  0,0
PlainMenu_ImageDisableHB:	DefPgtImage PlainMenu_Pixels, 0, 32,20,	10,10+40, 1,10,  0,0

PlainMenu_ImageDisableLT	DefPgtImage PlainMenu_Pixels, 0, 32,20,	0,0+40, 10,20,  0,0
PlainMenu_ImageDisableLV	DefPgtImage PlainMenu_Pixels, 0, 32,20,	0,10+40, 10,1,  0,0

PlainMenu_ImageDisableRT:	DefPgtImage PlainMenu_Pixels, 0, 32,20,	10,0+40, 10,20,  0,0
PlainMenu_ImageDisableRV:	DefPgtImage PlainMenu_Pixels, 0, 32,20,	10,10+40, 10,1,  0,0

alignq
PlainMenu_Pixels:  incbin "styles/islandpastels/menu.raw"

alignd
csym PlainMenuSelect_Layers

DefPgtLayerState PgtLayer.BopStateGeneric, PlainVue.FlagsKeyFocus, 0 // if key focus

	; key focus
	DefPgtLayer1 PlainMenuSelect_ImageNormalHT, PgtLayer.BopOpaque|PgtLayer.FlagLTRT|PgtLayer.FlagTile, 10,0,-10,10
	DefPgtLayer1 PlainMenuSelect_ImageNormalHV, PgtLayer.BopOpaque|PgtLayer.FlagLTRB|PgtLayer.FlagTile, 10,10,-10,-10
	DefPgtLayer1 PlainMenuSelect_ImageNormalHB, PgtLayer.BopOpaque|PgtLayer.FlagLBRB|PgtLayer.FlagTile, 10,-10,-10,0

	DefPgtLayer1 PlainMenuSelect_ImageNormalLT, PgtLayer.BopTrans|PgtLayer.FlagLTLT, 0,0,10,10
	DefPgtLayer1 PlainMenuSelect_ImageNormalLV, PgtLayer.BopOpaque|PgtLayer.FlagLTLB|PgtLayer.FlagTile, 0,10,10,-10
	DefPgtLayer1 PlainMenuSelect_ImageNormalLT, PgtLayer.BopTrans|PgtLayer.FlagLBLB|PgtLayer.FlagAlignBottom, 0,-10,10,0

	DefPgtLayer1 PlainMenuSelect_ImageNormalRT, PgtLayer.BopTrans|PgtLayer.FlagRTRT, -10,0,0,10
	DefPgtLayer1 PlainMenuSelect_ImageNormalRV, PgtLayer.BopOpaque|PgtLayer.FlagLeftOpposite|PgtLayer.FlagTile, -10,10,0,-10
	DefPgtLayer1 PlainMenuSelect_ImageNormalRT, PgtLayer.BopTrans|PgtLayer.FlagRBRB|PgtLayer.FlagAlignBottom, -10,-10,0,0

//DefPgtLayerState PgtLayer.BopStateGeneric, 0, PlainVue.FlagsKeyFocus // else
DefPgtLayerEnd

PlainMenuSelect_ImageNormalHT:	DefPgtImage PlainMenu_Pixels, 0, 32,20,	10,0+40, 1,10,  0,0
PlainMenuSelect_ImageNormalHV:	DefPgtImage PlainMenu_Pixels, 0, 32,20,	10,10+40, 1,1,  0,0
PlainMenuSelect_ImageNormalHB:	DefPgtImage PlainMenu_Pixels, 0, 32,20,	10,10+40, 1,10,  0,0

PlainMenuSelect_ImageNormalLT:	DefPgtImage PlainMenu_Pixels, 0, 32,20,	0,0+40, 10,20,  0,0
PlainMenuSelect_ImageNormalLV:	DefPgtImage PlainMenu_Pixels, 0, 32,20,	0,10+40, 10,1,  0,0

PlainMenuSelect_ImageNormalRT:	DefPgtImage PlainMenu_Pixels, 0, 32,20,	10,0+40, 10,20,  0,0
PlainMenuSelect_ImageNormalRV:	DefPgtImage PlainMenu_Pixels, 0, 32,20,	10,10+40, 10,1,  0,0

alignq
//PlainMenuSelect_Pixels:  ;incbin "styles/islandpastels/menuselect.raw"
//db 255,128,128,192,  255,128,128,255

%elifdef PlainStyleLavenderCut

alignd
csym PlainMenu_Layers

	; normal
	DefPgtLayer1 PlainMenu_ImageNormalHT, PgtLayer.BopOpaque|PgtLayer.FlagLTRT|PgtLayer.FlagTile, 10,0,-10,10
	DefPgtLayer1 PlainMenu_ImageNormalHV, PgtLayer.BopOpaque|PgtLayer.FlagLTRB|PgtLayer.FlagTile, 10,10,-10,-10
	DefPgtLayer1 PlainMenu_ImageNormalHB, PgtLayer.BopOpaque|PgtLayer.FlagLBRB|PgtLayer.FlagTile, 10,-10,-10,0

	DefPgtLayer1 PlainMenu_ImageNormalLT, PgtLayer.BopTrans|PgtLayer.FlagLTLT, 0,0,10,10
	DefPgtLayer1 PlainMenu_ImageNormalLV, PgtLayer.BopOpaque|PgtLayer.FlagLTLB|PgtLayer.FlagTile, 0,10,10,-10
	DefPgtLayer1 PlainMenu_ImageNormalLT, PgtLayer.BopTrans|PgtLayer.FlagLBLB|PgtLayer.FlagAlignBottom, 0,-10,10,0

	DefPgtLayer1 PlainMenu_ImageNormalRT, PgtLayer.BopTrans|PgtLayer.FlagRTRT, -10,0,0,10
	DefPgtLayer1 PlainMenu_ImageNormalRV, PgtLayer.BopOpaque|PgtLayer.FlagLeftOpposite|PgtLayer.FlagTile, -10,10,0,-10
	DefPgtLayer1 PlainMenu_ImageNormalRT, PgtLayer.BopTrans|PgtLayer.FlagRBRB|PgtLayer.FlagAlignBottom, -10,-10,0,0

//DefPgtLayerState PgtLayer.BopStateGeneric, 0, 0 // endif

// endif
DefPgtLayerEnd

PlainMenu_ImageNormalHT:	DefPgtImage PlainMenu_Pixels, 0, 32,20,	10,0, 1,10,  0,0
PlainMenu_ImageNormalHV:	DefPgtImage PlainMenu_Pixels, 0, 32,20,	10,10, 1,1,  0,0
PlainMenu_ImageNormalHB:	DefPgtImage PlainMenu_Pixels, 0, 32,20,	10,10, 1,10,  0,0

PlainMenu_ImageNormalLT:	DefPgtImage PlainMenu_Pixels, 0, 32,20,	0,0, 10,20,  0,0
PlainMenu_ImageNormalLV:	DefPgtImage PlainMenu_Pixels, 0, 32,20,	0,10, 10,1,  0,0

PlainMenu_ImageNormalRT:	DefPgtImage PlainMenu_Pixels, 0, 32,20,	10,0, 10,20,  0,0
PlainMenu_ImageNormalRV:	DefPgtImage PlainMenu_Pixels, 0, 32,20,	10,10, 10,1,  0,0

%if 0
PlainMenu_ImageFocusHT:	DefPgtImage PlainMenu_Pixels, 0, 32,20,	10,0+20, 1,1,  0,0
//PlainMenu_ImageFocusHV:	DefPgtImage PlainMenu_Pixels, 0, 32,20,	10,10+20, 1,1,  0,0
PlainMenu_ImageFocusHB:	DefPgtImage PlainMenu_Pixels, 0, 32,20,	10,19+20, 1,1,  0,0

PlainMenu_ImageFocusLT:	DefPgtImage PlainMenu_Pixels, 0, 32,20,	0,0+20, 10,20,  0,0
PlainMenu_ImageFocusLV:	DefPgtImage PlainMenu_Pixels, 0, 32,20,	0,10+20, 1,1,  0,0

PlainMenu_ImageFocusRT:	DefPgtImage PlainMenu_Pixels, 0, 32,20,	10,0+20, 10,20,  0,0
PlainMenu_ImageFocusRV:	DefPgtImage PlainMenu_Pixels, 0, 32,20,	10,10+20, 1,1,  0,0
%endif

PlainMenu_ImageDisableHT:	DefPgtImage PlainMenu_Pixels, 0, 32,20,	10,0+40, 1,10,  0,0
PlainMenu_ImageDisableHV:	DefPgtImage PlainMenu_Pixels, 0, 32,20,	10,10+40, 1,1,  0,0
PlainMenu_ImageDisableHB:	DefPgtImage PlainMenu_Pixels, 0, 32,20,	10,10+40, 1,10,  0,0

PlainMenu_ImageDisableLT	DefPgtImage PlainMenu_Pixels, 0, 32,20,	0,0+40, 10,20,  0,0
PlainMenu_ImageDisableLV	DefPgtImage PlainMenu_Pixels, 0, 32,20,	0,10+40, 10,1,  0,0

PlainMenu_ImageDisableRT:	DefPgtImage PlainMenu_Pixels, 0, 32,20,	10,0+40, 10,20,  0,0
PlainMenu_ImageDisableRV:	DefPgtImage PlainMenu_Pixels, 0, 32,20,	10,10+40, 10,1,  0,0

alignq
PlainMenu_Pixels:  incbin "styles/lavendercut/menu.raw"

alignd
csym PlainMenuSelect_Layers

DefPgtLayerState PgtLayer.BopStateGeneric, PlainVue.FlagsKeyFocus, 0 // if key focus

	; key focus
	DefPgtLayer1 PlainMenuSelect_ImageNormalHT, PgtLayer.BopOpaque|PgtLayer.FlagLTRT|PgtLayer.FlagTile, 10,0,-10,10
	DefPgtLayer1 PlainMenuSelect_ImageNormalHV, PgtLayer.BopOpaque|PgtLayer.FlagLTRB|PgtLayer.FlagTile, 10,10,-10,-10
	DefPgtLayer1 PlainMenuSelect_ImageNormalHB, PgtLayer.BopOpaque|PgtLayer.FlagLBRB|PgtLayer.FlagTile, 10,-10,-10,0

	DefPgtLayer1 PlainMenuSelect_ImageNormalLT, PgtLayer.BopTrans|PgtLayer.FlagLTLT, 0,0,10,10
	DefPgtLayer1 PlainMenuSelect_ImageNormalLV, PgtLayer.BopOpaque|PgtLayer.FlagLTLB|PgtLayer.FlagTile, 0,10,10,-10
	DefPgtLayer1 PlainMenuSelect_ImageNormalLT, PgtLayer.BopTrans|PgtLayer.FlagLBLB|PgtLayer.FlagAlignBottom, 0,-10,10,0

	DefPgtLayer1 PlainMenuSelect_ImageNormalRT, PgtLayer.BopTrans|PgtLayer.FlagRTRT, -10,0,0,10
	DefPgtLayer1 PlainMenuSelect_ImageNormalRV, PgtLayer.BopOpaque|PgtLayer.FlagLeftOpposite|PgtLayer.FlagTile, -10,10,0,-10
	DefPgtLayer1 PlainMenuSelect_ImageNormalRT, PgtLayer.BopTrans|PgtLayer.FlagRBRB|PgtLayer.FlagAlignBottom, -10,-10,0,0

//DefPgtLayerState PgtLayer.BopStateGeneric, 0, PlainVue.FlagsKeyFocus // else
DefPgtLayerEnd

PlainMenuSelect_ImageNormalHT:	DefPgtImage PlainMenu_Pixels, 0, 32,20,	10,0+20, 1,10,  0,0
PlainMenuSelect_ImageNormalHV:	DefPgtImage PlainMenu_Pixels, 0, 32,20,	10,10+20, 1,1,  0,0
PlainMenuSelect_ImageNormalHB:	DefPgtImage PlainMenu_Pixels, 0, 32,20,	10,10+20, 1,10,  0,0

PlainMenuSelect_ImageNormalLT:	DefPgtImage PlainMenu_Pixels, 0, 32,20,	0,0+20, 10,20,  0,0
PlainMenuSelect_ImageNormalLV:	DefPgtImage PlainMenu_Pixels, 0, 32,20,	0,10+20, 10,1,  0,0

PlainMenuSelect_ImageNormalRT:	DefPgtImage PlainMenu_Pixels, 0, 32,20,	10,0+20, 10,20,  0,0
PlainMenuSelect_ImageNormalRV:	DefPgtImage PlainMenu_Pixels, 0, 32,20,	10,10+20, 10,1,  0,0

alignq
//PlainMenuSelect_Pixels:  ;incbin "styles/lavendercut/menuselect.raw"
//db 255,128,128,192,  255,128,128,255

%elifdef PlainStyleNeonMist

%else ;%elifdef PlainStyleTealOnGray
alignd
csym PlainMenu_Layers
%endif



////////////////////////////// IMAGES //////////////////////////////
%ifdef nothing
%else //elifdef PlainStyleIslandPastelsFlat

alignd
csym PlainImage_Layers1
	DefPgtLayer1 PlainImage_ImageNormal1, PgtLayer.BopTrans|PgtLayer.FlagLTRB, 0,0,0,0
	//DefPgtLayerState PgtLayer.BopStateGeneric, 0, 0 // endif
DefPgtLayerEnd
csym PlainImage_Layers2
	DefPgtLayer1 PlainImage_ImageNormal2, PgtLayer.BopTrans|PgtLayer.FlagLTRB, 0,0,0,0
	//DefPgtLayerState PgtLayer.BopStateGeneric, 0, 0 // endif
DefPgtLayerEnd
csym PlainImage_Layers3
	DefPgtLayer1 PlainImage_ImageNormal3, PgtLayer.BopTrans|PgtLayer.FlagLTRB, 0,0,0,0
	//DefPgtLayerState PgtLayer.BopStateGeneric, 0, 0 // endif
DefPgtLayerEnd

PlainImage_ImageNormal1:	DefPgtImage PlainImage_Pixels1, 0, 32,120,	0,0, 120,171,  0,0
PlainImage_ImageNormal2:	DefPgtImage PlainImage_Pixels2, 0, 32,120,	0,0, 120,200,  0,0
PlainImage_ImageNormal3:	DefPgtImage PlainImage_Pixels3, 0, 32,120,	0,0, 120,200,  0,0

alignq
PlainImage_Pixels1:  incbin "styles/lavendercut/image1.raw"
PlainImage_Pixels2:  incbin "styles/lavendercut/image2.raw"
PlainImage_Pixels3:  incbin "styles/lavendercut/image3.raw"
%endif
