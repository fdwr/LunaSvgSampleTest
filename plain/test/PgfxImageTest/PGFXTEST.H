;// pgfxtest.h

; TEMPORARILY CHANGED BACK to plain Nasm .98
; since I don't have my modified version down
; here, and don't have inet to recompile it.



%define IdBlitFirst						40000
%define IdBlitNop						40000
%define IdBlitOpaque32i32i				40001
%define IdBlitOpaque8i8i				40002
%define IdBlitOpaque32i32c				40003
%define IdBlitOpaque8i8c				40004
%define IdBlitTransFast32i32i			40005
%define IdBlitAdd32i32i					40006
%define IdBlitAdd8i8i					40007
%define IdBlitAdd32i32c					40008
%define IdBlitAdd8i8c					40009
%define IdBlitSub32i32i					40010
%define IdBlitMul32i32i					40011
%define IdBlitAnd32i32i					40012
%define IdBlitOr32i32i					40013
%define IdBlitTrans32i32i				40014
%define IdBlitTrans32i32c				40015
%define IdBlitOpaqueLeft32i32i			40016
%define IdBlitTransFast8i8i				40017
%define IdBlitMul8i8i					40018
%define IdBlitPal32i8i32p				40019
%define IdBlitPal8i32i32p				40020
%define IdBlitTrans32i8i32c				40021
%define IdBlitGreater32i32i				40022
%define IdBlitLesser32i32i				40023
%define IdBlitGreater8i8i				40024
%define IdBlitLesser8i8i				40025
%define IdBlitGreater8i8c				40026
%define IdBlitLesser8i8c				40027
%define IdBlitScale32i32i				40028
%define IdBlitPal32i32i32p				40029
%define IdBlitLast						40029

%define IdBlitMMX						40200

%define IdGfxSrc0						40210
%define IdGfxSrc1						40211
%define IdGfxSrc2						40212
%define IdGfxSrc3						40213

%define IdGfxReset						40214
%define IdLogo							40215

%ifdef __NASM_MAJOR__

GfxSrcInfo:
;.types:; bitmask of supported source types
.type_color	equ 1
.type_image	equ 2
.type_pal	equ 4
.type_mask	equ 8

%endif

