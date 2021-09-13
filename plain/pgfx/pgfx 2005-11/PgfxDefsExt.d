/**
Author:	Dwayne Robinson
Date:	2005-11-09
Since:	2005-11-09
Remark:	External variables and functions (to avoid D's silliness with multiple definitions)
*/
module pgfx.pgfxdefsext;

private import pgfx.pgfxdefs;

////////////////////////////////////////////////////////////////////////////////

extern (C) int PgfxInit();

extern (C) void BlitOpaque32i32i(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, void* srcPtr, int srcWrap, int srcLeft, int srcTop);
extern (C) void BlitOpaque32i32c(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, int srcColor);
extern (C) void BlitOpaqueLeft32i32i(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, void* srcPtr, int srcWrap, int srcLeft, int srcTop);
extern (C) void BlitOpaque8i8i(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, void* srcPtr, int srcWrap, int srcLeft, int srcTop);
extern (C) void BlitOpaque8i8c(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, int srcColor);

extern (C) void BlitTrans32i32i(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, void* srcPtr, int srcWrap, int srcLeft, int srcTop);
extern (C) void BlitTrans32i32c(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, int srcColor);
extern (C) void BlitTrans32i8i32c(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, void* srcPtr, int srcWrap, int srcLeft, int srcTop, int srcColor);
extern (C) void BlitTransFast32i32i(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, void* srcPtr, int srcWrap, int srcLeft, int srcTop);
extern (C) void BlitTransFast8i8i(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, void* srcPtr, int srcWrap, int srcLeft, int srcTop);

extern (C) void BlitAdd32i32i(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, void* srcPtr, int srcWrap, int srcLeft, int srcTop);
extern (C) void BlitAdd32i32c(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, int srcColor);
extern (C) void BlitAdd8i8i(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, void* srcPtr, int srcWrap, int srcLeft, int srcTop);
extern (C) void BlitAdd8i8c(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, int srcColor);

extern (C) void BlitSub32i32i(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, void* srcPtr, int srcWrap, int srcLeft, int srcTop);

extern (C) void BlitMul32i32i(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, void* srcPtr, int srcWrap, int srcLeft, int srcTop);
extern (C) void BlitMul8i8i(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, void* srcPtr, int srcWrap, int srcLeft, int srcTop);

extern (C) void BlitGreater32i32i(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, void* srcPtr, int srcWrap, int srcLeft, int srcTop);
extern (C) void BlitGreater8i8i(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, void* srcPtr, int srcWrap, int srcLeft, int srcTop);
extern (C) void BlitGreater32i32c(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, int srcColor);
extern (C) void BlitGreater8i8c(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, int srcColor);

extern (C) void BlitLesser32i32i(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, void* srcPtr, int srcWrap, int srcLeft, int srcTop);
extern (C) void BlitLesser8i8i(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, void* srcPtr, int srcWrap, int srcLeft, int srcTop);
extern (C) void BlitLesser32i32c(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, int srcColor);
extern (C) void BlitLesser8i8c(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, int srcColor);

extern (C) void BlitAnd32i32i(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, void* srcPtr, int srcWrap, int srcLeft, int srcTop);
extern (C) void BlitOr32i32i(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, void* srcPtr, int srcWrap, int srcLeft, int srcTop);

extern (C) void BlitScale32i32i(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, void* srcPtr, int srcWrap, int srcLeft, int srcTop, int srcWidth, int srcHeight, int scaleLeft, int scaleTop, int scaleWidth, int scaleHeight);
//extern (C) void BlitAndOr32i32c32c

extern (C) void BlitPal32i8i32p(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, void* srcPtr, int srcWrap, int srcLeft, int srcTop, PgfxPalEntry* palPtr);
extern (C) void BlitPal8i32i32p(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, void* srcPtr, int srcWrap, int srcLeft, int srcTop, PgfxPalEntry* palPtr);
extern (C) void BlitPal32i32i32p(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, void* srcPtr, int srcWrap, int srcLeft, int srcTop, PgfxPalEntry* palPtr);

extern (C) void BlitDist32i32i(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, void* srcPtr, int srcWrap, int srcLeft, int srcTop);

extern (C) void DrawLayers(
	PgfxLayer* layerPtr,	/// pointer to layer array
	int areaWidth,		/// pixel width of control
	int areaHeight,
	int sectLeft,		/// pixel offset from left
	int sectTop,		/// pixel offset from top
	int sectRight,		/// pixel offset from right ???is this correct, or is it offset from left side
	int sectBottom,		/// pixel offset from bottom
	uint stateGeneric,		/// bit flags state of item (i.e. show different look for disabled or hovered)
	uint stateSpecific,	/// arbitrary bit flags unique to item (i.e. show different state for button pushed). Added as convenience.
	PgfxLayerImage* imagesPtr,	/// pointer to additional image array
	int imagesNum		/// number of images passed
);


////////////////////////////////////////////////////////////////////////////////

extern (C) int PgfxCurrentFlags;
extern (C) PgfxDisplayFull PgfxCurrentDisplay; /// static instance of the a full display structure, holding current info
extern (C) PgfxCursor PgfxCurrentCursor;

//PgfxDisplayFull PgfxCurrentDisplay;
//extern (C) PgtImage PgfxDisplayImage;
/*
	static if (PgfxOptions.PlainUseCursor==1) {
		//extern (C) PgtCursor PgfxCursor;
		static assert(false);
		extern (C) void PgfxCursorShow();
		extern (C) void PgfxCursorHide();
		extern (Windows) __stdcall PgfxCursorSet(PgtLayer* layer);
	}
*/
//extern (C) void BlitImage(int pop, int destLeft, int destTop, int destWidth, int destHeight, PgtImage* srcPtr, int srcLeft, int srcTop, ...);
