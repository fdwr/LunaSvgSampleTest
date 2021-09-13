; File: controls.cpp
; Project: CS419b HW1
; Date: 2005-04-10
; 
; Main program resources, including sample images, user controls,
; UI styles, and other misc. data.
;
; To compile in MSVC:
;	nasmw.exe $(InputPath) -o $(IntDir)\$(InputName).obj -fwin32 -w+orphan-labels -i..\common\ -i..\pgfx\ -i..\ui\ -d_MSLINK -d_WINDOWS

%define resources_asm
%include "pgfx.h"
%include "pgfxlayr.h"
%include "guidefs.h"
//#include "resource.h"

section .data
alignd


////////////////////////////////////////////////////////////////////////////////
// User controls

DefGuiControlsStart

DefGuiObj MainRoot, \
		RootWindowObjEntry, NullGuiObj, \
		RootWindowObj.defFlags, \
		0,			0,			1024,768
	DefWindowObj ButtonDummy, \
		MainTitleBar, \
		ButtonDummy
		//MainMenu, \


%define DefGuiObj_Container MainRoot
%define DefGuiObj_Border NullGuiObj

DefGuiObj MainTitleBar, \
		TitleBarObjEntry, default, \
		TitleBarObj.defFlags, \
		8,			8,		1024-16,24
	DefTitleBarObj \
		"Test Attribute List - Dwayne Robinson 2005-06-25"
	DefCallbackObj MainTitleBar

%define DefGuiObj_Border BorderObjInstance
//DefGuiObj MainMenu, \
//		PreviewObjEntry, NullGuiObj, \
//		PreviewObj.defFlags|GuiObj.hidden|GuiObj.noMouseFocus, \
//		8,			48,			232,712
//	DefPreviewObj \
//		_ImageDif

#define DefGuiObj_Border NullGuiObj
DefGuiObj ButtonDummy, \
		ButtonObjEntry, default, \
		ButtonObj.defFlags, \
		8,			48+28*0,		232,24
	DefButtonObj \
		"Load image..."
	DefCallbackObj ButtonDummy

//DefGuiObjIdx ButtonPainterlyDo3, \
//		ButtonObjEntry, ButtonPainterlyDoCallback, \
//		ButtonObj.defFlags, \
//		8,			48+28*13,		232,24, \
//		2
//	DefButtonObj \
//		"Do painterly, radius 2"




////////////////////////////////////////////////////////////////////////////////
// sample images

#if 0
; (pixels, type&flags, bpp, wrap, left, top, height, width)
alignd
csym SampleImage
	//DefPgtImage SampleImagePixels,	PgtImage.typeImage, 5, 128*4, 0,0,	128,128 // duck
	//DefPgtImage SampleImagePixels,	PgtImage.typeImage, 5, 256*4, 0,0,	256,256 // rose or lion
	DefPgtImage SampleImagePixels,	PgtImage.typeImage, 5, 320*4, 0,0,	320,240 // sample gradient

alignd
csym SampleImagePixels
	//incbin "data\duck.raw"
	//incbin "data\rose.raw"
	//incbin "data\lion.raw"
	incbin "data\gradient_test_simple.raw"

alignd
csym BrushRoundSoft05
	DefPgtImage BrushRoundSoft05px,	PgtImage.typeImage, 3, 8,	0,0,	8,8
csym BrushRoundSoft09
	DefPgtImage BrushRoundSoft09px,	PgtImage.typeImage, 3, 12,	0,0,	12,12
csym BrushRoundSoft17
	DefPgtImage BrushRoundSoft17px,	PgtImage.typeImage, 3, 20,	0,0,	20,20
BrushRoundSoft05px:
	incbin "data\brush_round_soft05.raw"
BrushRoundSoft09px:
	incbin "data\brush_round_soft09.raw"
BrushRoundSoft17px:
	incbin "data\brush_round_soft17.raw"
#endif

////////////////////////////////////////////////////////////////////////////////
// UI appearance styles


; (image ptr, blend&flags, left,top, right,bottom)
alignd
csym BorderObj_Layer
DefPgtLayer1 BorderObj_ImageT, PgtLayer.BopOpaque|PgtLayer.FlagBottomOpposite|PgtLayer.FlagTileHorz, 4,0,-4,4
DefPgtLayer1 BorderObj_ImageB, PgtLayer.BopOpaque|PgtLayer.FlagTopOpposite|PgtLayer.FlagBottomOffset|PgtLayer.FlagTileHorz, 4,-4,-4,0
DefPgtLayer1 BorderObj_ImageL, PgtLayer.BopOpaque|PgtLayer.FlagLeftOffset|PgtLayer.FlagRightOpposite|PgtLayer.FlagTileVert, 0,4,4,-4
DefPgtLayer1 BorderObj_ImageR, PgtLayer.BopOpaque|PgtLayer.FlagLeftOpposite|PgtLayer.FlagRightOffset|PgtLayer.FlagTileVert, -4,4,0,-4
DefPgtLayer1 BorderObj_ImageTL, PgtLayer.BopTrans|PgtLayer.FlagAllOffset|PgtLayer.FlagAlignLeft|PgtLayer.FlagAlignTop, 0,0,0,0
DefPgtLayer1 BorderObj_ImageTR, PgtLayer.BopTrans|PgtLayer.FlagAllOffset|PgtLayer.FlagAlignRight|PgtLayer.FlagAlignTop, 0,0,0,0
DefPgtLayer1 BorderObj_ImageBL, PgtLayer.BopTrans|PgtLayer.FlagAllOffset|PgtLayer.FlagAlignLeft|PgtLayer.FlagAlignBottom, 0,0,0,0
DefPgtLayer1 BorderObj_ImageBR, PgtLayer.BopTrans|PgtLayer.FlagAllOffset|PgtLayer.FlagAlignRight|PgtLayer.FlagAlignBottom, 0,0,0,0
DefPgtLayerEnd

csym BorderObj_ImageT
	DefPgtImage BorderObj_Pixels+4*(16*0+7),	PgtImage.typeImage, 5, 16*4, 0,0,	1,4
csym BorderObj_ImageB
	DefPgtImage BorderObj_Pixels+4*(16*12+7),	PgtImage.typeImage,5, 16*4, 0,0,	1,4
csym BorderObj_ImageL
	DefPgtImage BorderObj_Pixels+4*(16*7+0),	PgtImage.typeImage, 5, 16*4, 0,0,	4,1
csym BorderObj_ImageR
	DefPgtImage BorderObj_Pixels+4*(16*7+12),	PgtImage.typeImage, 5, 16*4, 0,0,	4,1
csym BorderObj_ImageTL
	DefPgtImage BorderObj_Pixels+4*(16*0+0),	PgtImage.typeImage, 5, 16*4, 0,0,	8,8
csym BorderObj_ImageTR
	DefPgtImage BorderObj_Pixels+4*(16*0+8),	PgtImage.typeImage, 5, 16*4, 0,0,	8,8
csym BorderObj_ImageBL
	DefPgtImage BorderObj_Pixels+4*(16*8+0),	PgtImage.typeImage, 5, 16*4, 0,0,	8,8
csym BorderObj_ImageBR
	DefPgtImage BorderObj_Pixels+4*(16*8+8),	PgtImage.typeImage, 5, 16*4, 0,0,	8,8

alignq
BorderObj_Pixels:  incbin "..\ui\styles\item_border.raw"

; (image ptr, blend&flags, left,top, right,bottom)
alignd
csym RootWindowObj_Layer
DefPgtLayer1 RootWindowObj_ImageM, PgtLayer.BopOpaque|PgtLayer.FlagAllOffset|PgtLayer.FlagTile, 4,4,-4,-4
DefPgtLayer1 RootWindowObj_ImageT, PgtLayer.BopOpaque|PgtLayer.FlagBottomOpposite|PgtLayer.FlagTileHorz, 4,0,-4,4
DefPgtLayer1 RootWindowObj_ImageB, PgtLayer.BopOpaque|PgtLayer.FlagTopOpposite|PgtLayer.FlagBottomOffset|PgtLayer.FlagTileHorz, 4,-4,-4,0
DefPgtLayer1 RootWindowObj_ImageL, PgtLayer.BopOpaque|PgtLayer.FlagLeftOffset|PgtLayer.FlagRightOpposite|PgtLayer.FlagTileVert, 0,4,4,-4
DefPgtLayer1 RootWindowObj_ImageR, PgtLayer.BopOpaque|PgtLayer.FlagLeftOpposite|PgtLayer.FlagRightOffset|PgtLayer.FlagTileVert, -4,4,0,-4
DefPgtLayer1 RootWindowObj_ImageTL, PgtLayer.BopOpaque|PgtLayer.FlagAllOffset|PgtLayer.FlagAlignLeft|PgtLayer.FlagAlignTop, 0,0,0,0
DefPgtLayer1 RootWindowObj_ImageTR, PgtLayer.BopOpaque|PgtLayer.FlagAllOffset|PgtLayer.FlagAlignRight|PgtLayer.FlagAlignTop, 0,0,0,0
DefPgtLayer1 RootWindowObj_ImageBL, PgtLayer.BopOpaque|PgtLayer.FlagAllOffset|PgtLayer.FlagAlignLeft|PgtLayer.FlagAlignBottom, 0,0,0,0
DefPgtLayer1 RootWindowObj_ImageBR, PgtLayer.BopOpaque|PgtLayer.FlagAllOffset|PgtLayer.FlagAlignRight|PgtLayer.FlagAlignBottom, 0,0,0,0
DefPgtLayerEnd

csym RootWindowObj_ImageM
	DefPgtImage RootWindowObj_Pixels+4*(12*4+4),	PgtImage.typeImage, 5, 12*4, 0,0,	1,1
csym RootWindowObj_ImageT
	DefPgtImage RootWindowObj_Pixels+4*(12*0+4),	PgtImage.typeImage, 5, 12*4, 0,0,	1,4
csym RootWindowObj_ImageB
	DefPgtImage RootWindowObj_Pixels+4*(12*8+4),	PgtImage.typeImage,5, 12*4, 0,0,	1,4
csym RootWindowObj_ImageL
	DefPgtImage RootWindowObj_Pixels+4*(12*4+0),	PgtImage.typeImage, 5, 12*4, 0,0,	4,1
csym RootWindowObj_ImageR
	DefPgtImage RootWindowObj_Pixels+4*(12*4+8),	PgtImage.typeImage, 5, 12*4, 0,0,	4,1
csym RootWindowObj_ImageTL
	DefPgtImage RootWindowObj_Pixels+4*(12*0+0),	PgtImage.typeImage, 5, 12*4, 0,0,	4,4
csym RootWindowObj_ImageTR
	DefPgtImage RootWindowObj_Pixels+4*(12*0+8),	PgtImage.typeImage, 5, 12*4, 0,0,	4,4
csym RootWindowObj_ImageBL
	DefPgtImage RootWindowObj_Pixels+4*(12*8+0),	PgtImage.typeImage, 5, 12*4, 0,0,	4,4
csym RootWindowObj_ImageBR
	DefPgtImage RootWindowObj_Pixels+4*(12*8+8),	PgtImage.typeImage, 5, 12*4, 0,0,	4,4

alignq
RootWindowObj_Pixels:  incbin "..\ui\styles\root_window_border.raw"

alignd
csym ButtonObj_LayerNormal
DefPgtLayer1 ButtonObj_ImageNormalM, PgtLayer.BopOpaque|PgtLayer.FlagAlignVert|PgtLayer.FlagAllOffset|PgtLayer.FlagTile, 12,0,-12,0
DefPgtLayer1 ButtonObj_ImageNormalL, PgtLayer.BopOpaque|PgtLayer.FlagAlignVert|PgtLayer.FlagRightOpposite, 0,0,12,0
DefPgtLayer1 ButtonObj_ImageNormalR, PgtLayer.BopOpaque|PgtLayer.FlagAlignVert|PgtLayer.FlagLeftOpposite, -12,0,0,0
DefPgtLayerEnd

csym ButtonObj_ImageNormalM
	DefPgtImage ButtonObj_PixelsNormal+4*(24*0+12),	PgtImage.typeImage, 5, 24*4, 0,0,	1,24
csym ButtonObj_ImageNormalL
	DefPgtImage ButtonObj_PixelsNormal+4*(24*0+0),	PgtImage.typeImage, 5, 24*4, 0,0,	12,24
csym ButtonObj_ImageNormalR
	DefPgtImage ButtonObj_PixelsNormal+4*(24*0+12),	PgtImage.typeImage, 5, 24*4, 0,0,	12,24

alignq
ButtonObj_PixelsNormal:  incbin "..\ui\styles\button_normal.raw"

alignd
csym ButtonObj_LayerHover
DefPgtLayer1 ButtonObj_ImageHoverM, PgtLayer.BopOpaque|PgtLayer.FlagAlignVert|PgtLayer.FlagAllOffset|PgtLayer.FlagTile, 12,0,-12,0
DefPgtLayer1 ButtonObj_ImageHoverL, PgtLayer.BopOpaque|PgtLayer.FlagAlignVert|PgtLayer.FlagRightOpposite, 0,0,12,0
DefPgtLayer1 ButtonObj_ImageHoverR, PgtLayer.BopOpaque|PgtLayer.FlagAlignVert|PgtLayer.FlagLeftOpposite, -12,0,0,0
DefPgtLayerEnd

csym ButtonObj_ImageHoverM
	DefPgtImage ButtonObj_PixelsHover+4*(24*0+12),	PgtImage.typeImage, 5, 24*4, 0,0,	1,24
csym ButtonObj_ImageHoverL
	DefPgtImage ButtonObj_PixelsHover+4*(24*0+0),	PgtImage.typeImage, 5, 24*4, 0,0,	12,24
csym ButtonObj_ImageHoverR
	DefPgtImage ButtonObj_PixelsHover+4*(24*0+12),	PgtImage.typeImage, 5, 24*4, 0,0,	12,24

alignq
ButtonObj_PixelsHover:  incbin "..\ui\styles\button_hover.raw"

alignd
csym ButtonObj_LayerDown
DefPgtLayer1 ButtonObj_ImageDownM, PgtLayer.BopOpaque|PgtLayer.FlagAlignVert|PgtLayer.FlagAllOffset|PgtLayer.FlagTile, 12,0,-12,0
DefPgtLayer1 ButtonObj_ImageDownL, PgtLayer.BopOpaque|PgtLayer.FlagAlignVert|PgtLayer.FlagRightOpposite, 0,0,12,0
DefPgtLayer1 ButtonObj_ImageDownR, PgtLayer.BopOpaque|PgtLayer.FlagAlignVert|PgtLayer.FlagLeftOpposite, -12,0,0,0
DefPgtLayerEnd

csym ButtonObj_ImageDownM
	DefPgtImage ButtonObj_PixelsDown+4*(24*0+12),	PgtImage.typeImage, 5, 24*4, 0,0,	1,24
csym ButtonObj_ImageDownL
	DefPgtImage ButtonObj_PixelsDown+4*(24*0+0),	PgtImage.typeImage, 5, 24*4, 0,0,	12,24
csym ButtonObj_ImageDownR
	DefPgtImage ButtonObj_PixelsDown+4*(24*0+12),	PgtImage.typeImage, 5, 24*4, 0,0,	12,24

alignq
ButtonObj_PixelsDown:  incbin "..\ui\styles\button_down.raw"

alignd
csym TitleBarObj_LayerNormal
DefPgtLayer1 TitleBarObj_ImageNormalM, PgtLayer.BopOpaque|PgtLayer.FlagAlignVert|PgtLayer.FlagAllOffset|PgtLayer.FlagTile, 12,0,-28,0
DefPgtLayer1 TitleBarObj_ImageNormalL, PgtLayer.BopOpaque|PgtLayer.FlagAlignVert|PgtLayer.FlagAlignLeft, 0,0,12,0
DefPgtLayer1 TitleBarObj_ImageNormalR, PgtLayer.BopOpaque|PgtLayer.FlagAlignVert|PgtLayer.FlagAlignRight, 0,0,0,0
DefPgtLayerEnd

csym TitleBarObj_ImageNormalM
	DefPgtImage TitleBarObj_PixelsNormal+4*(24*0+10),	PgtImage.typeImage, 5, 40*4, 0,0,	1,24
csym TitleBarObj_ImageNormalL
	DefPgtImage TitleBarObj_PixelsNormal+4*(24*0+0),	PgtImage.typeImage, 5, 40*4, 0,0,	12,24
csym TitleBarObj_ImageNormalR
	DefPgtImage TitleBarObj_PixelsNormal+4*(24*0+12),	PgtImage.typeImage, 5, 40*4, 0,0,	28,24

alignq
TitleBarObj_PixelsNormal:  incbin "..\ui\styles\title_bar.raw"
