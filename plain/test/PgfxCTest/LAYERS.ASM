%include "pgfx.h"
%include "pgfxlayr.h"

section .data

align 4, db 0
csym TestLayer1
	DefPgtLayer1 TestImage1, PgtLayer.BopTrans|PgtLayer.FlagLeftOffset|PgtLayer.FlagAlignTop|PgtLayer.FlagAlignLeft, 0,0, 0,0
	DefPgtLayer1 TestImage1, PgtLayer.BopTrans|PgtLayer.FlagLeftOffset|PgtLayer.FlagAlignBottom|PgtLayer.FlagAlignRight, 0,0, 0,0
	DefPgtLayer1 TestImage1, PgtLayer.BopTrans|PgtLayer.FlagLeftOffset|PgtLayer.FlagAlignVert|PgtLayer.FlagAlignHorz, 0,0, 0,0
	DefPgtLayer1 TestImage2, PgtLayer.BopTrans|PgtLayer.FlagLeftOffset|PgtLayer.FlagAlignTop|PgtLayer.FlagAlignHorz, 0,0, 0,0
	DefPgtLayer1 TestImage3, PgtLayer.BopTrans|PgtLayer.FlagTile|PgtLayer.FlagAllOffset, 24,24, 128,128

	;DefPgtLayer1 TestImage, PgtLayer.BopOpaque|PgtLayer.FlagStrechHorz, 4,4, -4,-4
	DefPgtLayerEnd

csym W9xBtnNorm
	DefPgtLayer1 W9xBtnNormT, PgtLayer.BopOpaque|PgtLayer.FlagTile|PgtLayer.FlagBottomOpposite,  2, 0, -2, 2
	DefPgtLayer1 W9xBtnNormL, PgtLayer.BopOpaque|PgtLayer.FlagTile|PgtLayer.FlagRightOpposite,  0, 2,  2,-2
	DefPgtLayer1 W9xBtnNormB, PgtLayer.BopOpaque|PgtLayer.FlagTile|PgtLayer.FlagTopOpposite,  2,-2, -2, 0
	DefPgtLayer1 W9xBtnNormR, PgtLayer.BopOpaque|PgtLayer.FlagTile|PgtLayer.FlagLeftOpposite, -2, 2,  0,-2

	DefPgtLayer1 W9xBtnNormTL, PgtLayer.BopOpaque|PgtLayer.FlagAlignTop|PgtLayer.FlagAlignLeft, 0,0, 0,0
	DefPgtLayer1 W9xBtnNormTR, PgtLayer.BopOpaque|PgtLayer.FlagAlignTop|PgtLayer.FlagAlignRight, 0,0, 0,0
	DefPgtLayer1 W9xBtnNormBL, PgtLayer.BopOpaque|PgtLayer.FlagAlignBottom|PgtLayer.FlagAlignLeft, 0,0, 0,0
	DefPgtLayer1 W9xBtnNormBR, PgtLayer.BopOpaque|PgtLayer.FlagAlignBottom|PgtLayer.FlagAlignRight, 0,0, 0,0

	DefPgtLayer1 W9xBtnNormM, PgtLayer.BopOpaque|PgtLayer.FlagTile, 2,2, -2,-2
	DefPgtLayerEnd


csym WxpBtnNorm
	;DefPgtLayer1 WxpBtnNormBG, PgtLayer.BopOpaque|PgtLayer.FlagTile, -2,-2, 2,2

	DefPgtLayer1 WxpBtnNormT, PgtLayer.BopOpaque|PgtLayer.FlagTile|PgtLayer.FlagBottomOpposite,  3, 0, -3, 2
	DefPgtLayer1 WxpBtnNormL, PgtLayer.BopOpaque|PgtLayer.FlagTile|PgtLayer.FlagRightOpposite,  0, 3,  2,-3
	DefPgtLayer1 WxpBtnNormB, PgtLayer.BopOpaque|PgtLayer.FlagTile|PgtLayer.FlagTopOpposite,  3,-2, -3, 0
	DefPgtLayer1 WxpBtnNormR, PgtLayer.BopOpaque|PgtLayer.FlagTile|PgtLayer.FlagLeftOpposite, -2, 3,  0,-3

	DefPgtLayer1 WxpBtnNormTL, PgtLayer.BopTrans|PgtLayer.FlagAlignTop|PgtLayer.FlagAlignLeft, 0,0, 0,0
	DefPgtLayer1 WxpBtnNormTR, PgtLayer.BopTrans|PgtLayer.FlagAlignTop|PgtLayer.FlagAlignRight, 0,0, 0,0
	DefPgtLayer1 WxpBtnNormBL, PgtLayer.BopTrans|PgtLayer.FlagAlignBottom|PgtLayer.FlagAlignLeft, 0,0, 0,0
	DefPgtLayer1 WxpBtnNormBR, PgtLayer.BopTrans|PgtLayer.FlagAlignBottom|PgtLayer.FlagAlignRight, 0,0, 0,0

	DefPgtLayer1 WxpBtnNormM, PgtLayer.BopOpaque|PgtLayer.FlagTile, 2,2, -2,-2
	DefPgtLayerEnd


csym PcsBtnNorm
	DefPgtLayer1 PcsBtnNormM, PgtLayer.BopOpaque|PgtLayer.FlagAlignVert|PgtLayer.FlagTileHorz, 15,0, -15,0
	DefPgtLayer1 PcsBtnNormL, PgtLayer.BopOpaque|PgtLayer.FlagAlignVert|PgtLayer.FlagAlignLeft, 0,0, 0,0
	DefPgtLayer1 PcsBtnNormR, PgtLayer.BopOpaque|PgtLayer.FlagAlignVert|PgtLayer.FlagAlignRight, 0,0, 0,0
	DefPgtLayerEnd


; (pixels, type&flags, bpp, wrap, left, top, height, width)
; sizes all hard coded at 20x76 for now
align 4, db 0
TestImage1:		DefPgtImage1 TestPixels1, PgtImage.typeImage, 5, 20*4, 0,0, 20,76
TestImage2:		DefPgtImage1 TestPixels2, PgtImage.typeImage, 5, 64*4, 0,0, 64,16
TestImage3:		DefPgtImage1 TestPixels3, PgtImage.typeImage, 5, 4, 0,0, 1,1

TestPixels1:	incbin "data\testimage.raw"
TestPixels2:	incbin "data\testimage2.raw"
TestPixels3:	dd 80B080FFh

align 4, db 0
W9xBtnNormTL:	DefPgtImage1 W9xBtnNormPix+(4*0)+(6*4*0), PgtImage.typeImage, 5, 6*4, 0,0, 2,2
W9xBtnNormTR:	DefPgtImage1 W9xBtnNormPix+(4*4)+(6*4*0), PgtImage.typeImage, 5, 6*4, 0,0, 2,2
W9xBtnNormBL:	DefPgtImage1 W9xBtnNormPix+(4*0)+(6*4*4), PgtImage.typeImage, 5, 6*4, 0,0, 2,2
W9xBtnNormBR:	DefPgtImage1 W9xBtnNormPix+(4*4)+(6*4*4), PgtImage.typeImage, 5, 6*4, 0,0, 2,2
W9xBtnNormM:	DefPgtImage1 W9xBtnNormPix+(4*2)+(6*4*2), PgtImage.typeImage, 5, 6*4, 0,0, 1,1
W9xBtnNormL:	DefPgtImage1 W9xBtnNormPix+(4*0)+(6*4*2), PgtImage.typeImage, 5, 6*4, 0,0, 2,1
W9xBtnNormT:	DefPgtImage1 W9xBtnNormPix+(4*2)+(6*4*0), PgtImage.typeImage, 5, 6*4, 0,0, 1,2
W9xBtnNormR:	DefPgtImage1 W9xBtnNormPix+(4*4)+(6*4*2), PgtImage.typeImage, 5, 6*4, 0,0, 2,1
W9xBtnNormB:	DefPgtImage1 W9xBtnNormPix+(4*2)+(6*4*4), PgtImage.typeImage, 5, 6*4, 0,0, 1,2
W9xBtnNormPix:	incbin "data\W9xBtnNorm.raw"


align 4, db 0
WxpBtnNormTL:	DefPgtImage1 WxpBtnNormPix+(4*0)+(8*4*0), PgtImage.typeImage, 5, 8*4, 0,0, 3,3
WxpBtnNormTR:	DefPgtImage1 WxpBtnNormPix+(4*5)+(8*4*0), PgtImage.typeImage, 5, 8*4, 0,0, 3,3
WxpBtnNormBL:	DefPgtImage1 WxpBtnNormPix+(4*0)+(8*4*18), PgtImage.typeImage, 5, 8*4, 0,0, 3,3
WxpBtnNormBR:	DefPgtImage1 WxpBtnNormPix+(4*5)+(8*4*18), PgtImage.typeImage, 5, 8*4, 0,0, 3,3
WxpBtnNormM:	DefPgtImage1 WxpBtnNormPix+(4*2)+(8*4*12), PgtImage.typeImage, 5, 8*4, 0,0, 1,1
WxpBtnNormL:	DefPgtImage1 WxpBtnNormPix+(4*0)+(8*4*3), PgtImage.typeImage, 5, 8*4, 0,0, 2,1
WxpBtnNormT:	DefPgtImage1 WxpBtnNormPix+(4*3)+(8*4*0), PgtImage.typeImage, 5, 8*4, 0,0, 1,2
WxpBtnNormR:	DefPgtImage1 WxpBtnNormPix+(4*6)+(8*4*3), PgtImage.typeImage, 5, 8*4, 0,0, 2,1
WxpBtnNormB:	DefPgtImage1 WxpBtnNormPix+(4*3)+(8*4*19), PgtImage.typeImage, 5, 8*4, 0,0, 1,2

;WxpBtnNormBG:	DefPgtImage1 WxpBtnNormBg, PgtImage.typeImage, 5, 4, 0,0, 1,1
WxpBtnNormPix:	incbin "data\WxpBtnNorm.raw"
;WxpBtnNormBg:	dd 0FFE0DFE3h


align 4, db 0
PcsBtnNormM:	DefPgtImage1 PcsBtnNormPix+(4*15)+(32*4*0), PgtImage.typeImage, 5, 32*4, 0,0, 1,30
PcsBtnNormL:	DefPgtImage1 PcsBtnNormPix+(4*0)+(32*4*0), PgtImage.typeImage, 5, 32*4, 0,0, 15,30
PcsBtnNormR:	DefPgtImage1 PcsBtnNormPix+(4*17)+(32*4*0), PgtImage.typeImage, 5, 32*4, 0,0, 15,30
PcsBtnNormPix:	incbin "data\PcsBtnNorm.raw"
