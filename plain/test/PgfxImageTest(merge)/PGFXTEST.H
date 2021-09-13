// pgfxtest.h

#define IdBlitFirst						40000
#define IdBlitNop						40000
#define IdBlitOpaque32i32i				40001
#define IdBlitOpaque8i8i				40002
#define IdBlitOpaque32i32c				40003
#define IdBlitOpaque8i8c				40004
#define IdBlitTransFast32i32i			40005
#define IdBlitAdd32i32i					40006
#define IdBlitAdd8i8i					40007
#define IdBlitAdd32i32c					40008
#define IdBlitAdd8i8c					40009
#define IdBlitSub32i32i					40010
#define IdBlitLast						40010

#define IdBlitMMX						40200

#define IdGfxSrc1						40210
#define IdGfxSrc2						40211
#define IdGfxSrc3						40212

#ifdef __NASM_MAJOR__

GfxSrcInfo:
;.types:; bitmask of supported source types
.type_color	equ 1
.type_image	equ 2
.type_pal	equ 4
.type_mask	equ 8

#endif

