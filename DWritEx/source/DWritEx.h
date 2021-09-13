//----------------------------------------------------------------------------
//
//  No copyright. No rights reserved. No royalties nor permission needed.
//
//  Microsoft does not produce, endorse, or provide support this library.
//  It is merely a supplementary library, dependent on the real DirectWrite,
//  written to augment and fill in functionality holes.
//
//  Feel free to use it for any projects, commercial or not, as a whole or in
//  parts. No warranty or guarantees of correctness! You have the code. Come
//  to your own conclusion regarding the robustness.
//
//----------------------------------------------------------------------------
//
//  General coding conventions used:
//    - Use intuitive variable naming in the first place rather than
//      redundant crutches like Hungarian notation.
//    - For bad input, return bad HRESULTs (when possible to validate)
//    - For bad output, fault hard and fast on any mandatory NULL
//      output parameters.
//
//----------------------------------------------------------------------------

#if defined(_MSC_VER) && _MSC_VER < 1000
#error "Seriously, upgrade your compiler..."
#endif

#pragma once

#include "BaseTsd.h"


// The following standard sized types should be defined in stdint.h,
// but VC *still* doesn't define this include this file, so we have
// to do it ourselves.
//
// {char32_t, char16_t, uint8_t, uint16_t, uint32_t}

namespace DWritEx
{


// The DWrite macro does not cast to a DWRITE_FONT_FEATURE_TAG,
// which is rather silly, since it needs to be such a type to
// put it into a DWRITE_FONT_FEATURE. So redefine it correctly.

#undef DWRITE_MAKE_OPENTYPE_TAG
#define DWRITE_MAKE_OPENTYPE_TAG(a,b,c,d) DWRITE_FONT_FEATURE_TAG( \
    (static_cast<uint32_t>(static_cast<uint8_t>(d)) << 24) | \
    (static_cast<uint32_t>(static_cast<uint8_t>(c)) << 16) | \
    (static_cast<uint32_t>(static_cast<uint8_t>(b)) <<  8) | \
     static_cast<uint32_t>(static_cast<uint8_t>(a)))

#define DWRITEX_MAKE_FONT_TAG(a,b,c,d) DWRITEX_FONT_TAG( \
    (static_cast<uint32_t>(static_cast<uint8_t>(d)) << 24) | \
    (static_cast<uint32_t>(static_cast<uint8_t>(c)) << 16) | \
    (static_cast<uint32_t>(static_cast<uint8_t>(b)) <<  8) | \
     static_cast<uint32_t>(static_cast<uint8_t>(a)))

enum DWRITEX_FONT_TAG
{
    DWRITEX_FONT_TAG_NULL                                       = 0x00000000, // wildcard
    DWRITEX_FONT_TAG_GSUB_TABLE                                 = DWRITEX_MAKE_FONT_TAG('G','S','U','B'),
    DWRITEX_FONT_TAG_GPOS_TABLE                                 = DWRITEX_MAKE_FONT_TAG('G','P','O','S'),
    DWRITEX_FONT_TAG_VERTICAL_FORMS                             = DWRITEX_MAKE_FONT_TAG('v','e','r','t'),
    DWRITEX_FONT_TAG_VERTICAL_KERNING                           = DWRITEX_MAKE_FONT_TAG('v','k','r','n'),

    // todo: Confirm these aren't swapped. I recall spec retardly made them
    // the opposite of what you expect (the lowercase default for the
    // uppercase language and the uppercase DEFAULT for lower scripts).

    DWRITEX_FONT_TAG_DEFAULT_LANGUAGE                           = DWRITEX_MAKE_FONT_TAG('d','f','l','t'),
    DWRITEX_FONT_TAG_DEFAULT_SCRIPT                             = DWRITEX_MAKE_FONT_TAG('D','F','L','T'),
    
    DWRITEX_FONT_TAG_FORCE_DWORD = 0x7FFFFFFF,
};

inline operator DWRITE_FONT_FEATURE_TAG(const DWRITEX_FONT_TAG a) { return DWRITE_FONT_FEATURE_TAG(tag); }

inline DWRITE_FONT_FEATURE_TAG cast(const DWRITEX_FONT_TAG p)
{
    return DWRITE_FONT_FEATURE_TAG(p);
}

enum DWRITEX_FONT_TAG_TYPE
{
    DWRITEX_FONT_TAG_TYPE_TABLES,
    DWRITEX_FONT_TAG_TYPE_SCRIPTS,
    DWRITEX_FONT_TAG_TYPE_LANGUAGES,
    DWRITEX_FONT_TAG_TYPE_FEATURES,
};

enum DWRITEX_INFORMATIONAL_STRING_ID
{
    DWRITEX_INFORMATIONAL_STRING_NONE                       = DWRITE_INFORMATIONAL_STRING_NONE,
    DWRITEX_INFORMATIONAL_STRING_COPYRIGHT_NOTICE           = DWRITE_INFORMATIONAL_STRING_COPYRIGHT_NOTICE,
    DWRITEX_INFORMATIONAL_STRING_VERSION_STRINGS            = DWRITE_INFORMATIONAL_STRING_VERSION_STRINGS,
    DWRITEX_INFORMATIONAL_STRING_TRADEMARK                  = DWRITE_INFORMATIONAL_STRING_TRADEMARK,
    DWRITEX_INFORMATIONAL_STRING_MANUFACTURER               = DWRITE_INFORMATIONAL_STRING_MANUFACTURER,
    DWRITEX_INFORMATIONAL_STRING_DESIGNER                   = DWRITE_INFORMATIONAL_STRING_DESIGNER,
    DWRITEX_INFORMATIONAL_STRING_DESIGNER_URL               = DWRITE_INFORMATIONAL_STRING_DESIGNER_URL,
    DWRITEX_INFORMATIONAL_STRING_DESCRIPTION                = DWRITE_INFORMATIONAL_STRING_DESCRIPTION,
    DWRITEX_INFORMATIONAL_STRING_FONT_VENDOR_URL            = DWRITE_INFORMATIONAL_STRING_FONT_VENDOR_URL,
    DWRITEX_INFORMATIONAL_STRING_LICENSE_DESCRIPTION        = DWRITE_INFORMATIONAL_STRING_LICENSE_DESCRIPTION,
    DWRITEX_INFORMATIONAL_STRING_LICENSE_INFO_URL           = DWRITE_INFORMATIONAL_STRING_LICENSE_INFO_URL,
    DWRITEX_INFORMATIONAL_STRING_WIN32_FAMILY_NAMES         = DWRITE_INFORMATIONAL_STRING_WIN32_FAMILY_NAMES,
    DWRITEX_INFORMATIONAL_STRING_WIN32_SUBFAMILY_NAMES      = DWRITE_INFORMATIONAL_STRING_WIN32_SUBFAMILY_NAMES,
    DWRITEX_INFORMATIONAL_STRING_PREFERRED_FAMILY_NAMES     = DWRITE_INFORMATIONAL_STRING_PREFERRED_FAMILY_NAMES,
    DWRITEX_INFORMATIONAL_STRING_PREFERRED_SUBFAMILY_NAMES  = DWRITE_INFORMATIONAL_STRING_PREFERRED_SUBFAMILY_NAMES,
    DWRITEX_INFORMATIONAL_STRING_SAMPLE_TEXT                = DWRITE_INFORMATIONAL_STRING_SAMPLE_TEXT,

    DWRITEX_INFORMATIONAL_STRING_FULL_FAMILY_NAME           = 100,
    DWRITEX_INFORMATIONAL_STRING_FULL_POSTSCRIPT_NAME,
};

enum DWRITEX_BASELINE
{
    DWRITEX_BASELINE_ROMAN,
    DWRITEX_BASELINE_IDEOGRAPHIC,
    DWRITEX_BASELINE_HANGING,
    DWRITEX_BASELINE_MATHEMATICAL,
    DWRITEX_BASELINE_CENTER,

    // BaselineAlignment http://msdn.microsoft.com/en-us/library/system.windows.baselinealignment(VS.85).aspx
    DWRITEX_BASELINE_TOP,
    DWRITEX_BASELINE_BOTTOM,
    DWRITEX_BASELINE_SUPERSCRIPT,
    DWRITEX_BASELINE_SUBSCRIPT,
    // I'm unsure exactly how "text-top" and "text-bottom" work :/
};


/* todo:
http://injun.ru/flash10api/flash/text/engine/TextBaseline.html

Constant	Defined By
 	 	ASCENT : String = "ascent"
[static] Specifies an ascent baseline.	TextBaseline
 	 	DESCENT : String = "descent"
[static] Specifies a descent baseline.	TextBaseline
 	 	IDEOGRAPHIC_BOTTOM : String = "ideographicBottom"
[static] Specifies an ideographic bottom baseline.	TextBaseline
 	 	IDEOGRAPHIC_CENTER : String = "ideographicCenter"
[static] Specifies an ideographic center baseline.	TextBaseline
 	 	IDEOGRAPHIC_TOP : String = "ideographicTop"
[static] Specifies an ideographic top baseline.	TextBaseline
 	 	ROMAN : String = "roman"
[static] Specifies a roman baseline.	TextBaseline
 	 	SUBSCRIPT : String = "subscript"
[static] Specifies a sub script baseline.	TextBaseline
 	 	SUPERSCRIPT : String = "superscript"
[static] Specifies a super script baseline.	TextBaseline
 	 	USE_DOMINANT_BASELINE : String = "useDominantBaseline"
[static] Specifies that the alignmentBaseline should be the same as the dominantBaseline.
*/


enum DWRITEX_TEXTURE_TYPE
{
    DWRITEX_TEXTURE_ALIASED_1x1     = DWRITE_TEXTURE_ALIASED_1x1,
    DWRITEX_TEXTURE_CLEARTYPE_3x1   = DWRITE_TEXTURE_CLEARTYPE_3x1,

    // Grayscale 0-255, 1 pixel per byte.
    DWRITEX_TEXTURE_GRAYSCALE_1x1   = 100,

    // Binary 0-1, 1 bit per pixel.
    // The first bit of the first byte contains the leftmost pixel.
    // This format is easily testable via the bittest instruction.
    DWRITEX_TEXTURE_BINARY_1x1,

    // Binary 0-1, 1 bit per pixel.
    // The last bit of the first byte contains the leftmost pixel.
    // This format is used in old VGA monitors and GDI DIBs, so while
    // it's less intuitive and much more awkward for bit-testing
    // (can't just easily use the bt instruction on it), it still
    // has use.
    DWRITEX_TEXTURE_BINARY_1x1_MSB_FIRST,
};


enum DWRITEX_RENDERING_MODE
{
    DWRITEX_RENDERING_MODE_0x0  = 0x00000000,
    DWRITEX_RENDERING_MODE_1x1  = 0x00000101,
    DWRITEX_RENDERING_MODE_6x1  = 0x00000601,
    DWRITEX_RENDERING_MODE_6x5  = 0x00000605,
 
    // Align all coordinates to nearest pixels.
    DWRITEX_RENDERING_MODE_PIXEL_ALIGN          = 00010000,
 
    // Hint all text; otherwise unhinted, or rather, hinted to design units
    DWRITEX_RENDERING_MODE_HINT_GLYPHS          = 00020000,
 
    // Hint natural.
    DWRITEX_RENDERING_MODE_HINT_NATURAL         = 00040000,
 
    // Use gdi gamma instead of WPF/DWrite gamma.
    DWRITEX_RENDERING_MODE_GDI_GAMMA            = 00080000,
 
    // Use embedded bitmaps where available, otherwise use TrueType outlines.
    DWRITEX_RENDERING_MODE_EMBEDDED_BITMAPS     = 00100000,
 
    // Increase overscale on rotation (switch 6x1 -> 6x5 on rotation)
    DWRITEX_RENDERING_MODE_OVERSCALE_ROTATION   = 00200000,
 
    // Coerce grayscale (force all glyphs to grayscale if any are)
    DWRITEX_RENDERING_MODE_COERCE_GRAYSCALE     = 00400000,
 
    // Use outline primitives instead of rasterized bitmaps.
    DWRITEX_RENDERING_MODE_NO_BITMAPS           = 00800000,
 
    /// <summary>
    /// Specifies that the rendering mode is determined automatically based on the font and size.
    /// </summary>
    DWRITEX_RENDERING_MODE_DEFAULT = DWRITEX_RENDERING_MODE_HINT_GLYPHS
                                   | DWRITEX_RENDERING_MODE_EMBEDDED_BITMAPS,
 
    /// <summary>
    /// Specifies that no anti-aliasing is performed. Each pixel is either set to the foreground 
    /// color of the text or retains the color of the background.
    /// </summary>
    DWRITEX_RENDERING_MODE_ALIASED = DWRITEX_RENDERING_MODE_1x1
                                   | DWRITE_RENDERING_MODE_DEFAULT;
 
    /// <summary>
    /// Specifies ClearType rendering with the same metrics as aliased text. Glyphs can only
    /// be positioned on whole-pixel boundaries.
    /// </summary>
    DWRITEX_RENDERING_MODE_CLEARTYPE_GDI_CLASSIC = DWRITEX_RENDERING_MODE_6x1
                                                 | DWRITEX_RENDERING_MODE_GDI_GAMMA
                                                 | DWRITE_RENDERING_MODE_DEFAULT,
 
    /// <summary>
    /// Specifies ClearType rendering with the same metrics as text rendering using GDI using a font
    /// created with CLEARTYPE_NATURAL_QUALITY. Glyph metrics are closer to their ideal values than 
    /// with aliased text, but glyphs are still positioned on whole-pixel boundaries.
    /// </summary>
    DWRITEX_RENDERING_MODE_CLEARTYPE_GDI_NATURAL = DWRITEX_RENDERING_MODE_6x1
                                                 | DWRITEX_RENDERING_MODE_GDI_GAMMA
                                                 | DWRITEX_RENDERING_MODE_HINT_NATURAL
                                                 | DWRITEX_RENDERING_MODE_DEFAULT,
 
    /// <summary>
    /// Specifies ClearType rendering with anti-aliasing in the horizontal dimension only. This is 
    /// typically used with small to medium font sizes (up to 16 ppem).
    /// </summary>
    DWRITEX_RENDERING_MODE_CLEARTYPE_NATURAL     = DWRITEX_RENDERING_MODE_6x1
                                                 | DWRITEX_RENDERING_MODE_DEFAULT,
 
    /// <summary>
    /// Specifies ClearType rendering with anti-aliasing in both horizontal and vertical dimensions. 
    /// This is typically used at larger sizes to makes curves and diagonal lines look smoother, at 
    /// the expense of some softness.
    /// </summary>
    DWRITEX_RENDERING_MODE_CLEARTYPE_NATURAL_SYMMETRIC   = DWRITEX_RENDERING_MODE_6x5
                                                         | DWRITEX_RENDERING_MODE_DEFAULT,
 
    /// <summary>
    /// Specifies that rendering should bypass the rasterizer and use the outlines directly. This is 
    /// typically used at very large sizes.
    /// </summary>
    DWRITEX_RENDERING_MODE_OUTLINE = DWRITEX_RENDERING_MODE_0x0
                                   | DWRITEX_RENDERING_MODE_NO_BITMAPS,
};


// todo: rename this enum
enum DWRITE_GLYPH_GRAVITY
{
    DWRITE_GLYPH_GRAVITY_UPRIGHT,   // Always upright, such as CJK
    DWRITE_GLYPH_GRAVITY_ROTATED,   // Should be rotated, like Arabic, where stacking breaks cursive joining
    DWRITE_GLYPH_GRAVITY_EITHER,    // Can be either rotated or upright
};


enum DWRITEX_TEXT_DECORATION_TYPE
{
    DWRITEX_TEXT_DECORATION_TYPE_UNDERLINE      = 0x00000001,
    DWRITEX_TEXT_DECORATION_TYPE_STRIKETHROUGH  = 0x00000002,
    DWRITEX_TEXT_DECORATION_TYPE_OVERLINE       = 0x00000004,
    DWRITEX_TEXT_DECORATION_TYPE_SHADE          = 0x00000008,
    DWRITEX_TEXT_DECORATION_TYPE_HIGHLIGHT      = 0x00000010,
    DWRITEX_TEXT_DECORATION_TYPE_BORDER         = 0x00000020,
    DWRITEX_TEXT_DECORATION_TYPE_EMPHASIS_MARK  = 0x00000040,
};


enum DWRITEX_TEXT_DIRECTION
{
    DWRITEX_TEXT_DIRECTION_LTR_TTB, // Latin, Cyrillic, Greek, CJK when horizontal
    DWRITEX_TEXT_DIRECTION_RTL_TTB, // Arabic, Hebrew, Syriac
    DWRITEX_TEXT_DIRECTION_LTR_BTT, // -
    DWRITEX_TEXT_DIRECTION_RTL_BTT, // -
    DWRITEX_TEXT_DIRECTION_TTB_LTR, // Mongolian
    DWRITEX_TEXT_DIRECTION_TTB_RTL, // Japanese
    DWRITEX_TEXT_DIRECTION_BTT_LTR, // -
    DWRITEX_TEXT_DIRECTION_BTT_RTL, // Arabic in Asian vertical text

    // todo: should this map to LOCALESIGNATURE::lsUsb?
    //
    // 123  Windows 2000 or later: Layout progress, horizontal from right to left
    // 124  Windows 2000 or later: Layout progress, vertical before horizontal
    // 125  Windows 2000 or later: Layout progress, vertical bottom to to
    //
    // http://blogs.msdn.com/michkap/archive/2008/10/05/8977109.aspx

    DWRITEX_TEXT_DIRECTION_HORIZONTAL_MASK  = 1,    // RTL instead of LTR
    DWRITEX_TEXT_DIRECTION_VERTICAL_MASK    = 2,    // BTT instead of TTB
    DWRITEX_TEXT_DIRECTION_ORIENTATION_MASK = 4,    // vertical reading instead horizontal
    DWRITEX_TEXT_DIRECTION_LTR_XXX          = 0,
    DWRITEX_TEXT_DIRECTION_RTL_XXX          = 1,
    DWRITEX_TEXT_DIRECTION_XXX_TTB          = 0,
    DWRITEX_TEXT_DIRECTION_XXX_BTT          = 2,
    DWRITEX_TEXT_DIRECTION_XXX_LTR          = 0|4,
    DWRITEX_TEXT_DIRECTION_XXX_RTL          = 1|4,
    DWRITEX_TEXT_DIRECTION_TTB_XXX          = 0|4,
    DWRITEX_TEXT_DIRECTION_BTT_XXX          = 2|4,
};


enum DWRITEX_FONT_SIZE_NORMALIZATION
{
    /// Default Em box
    DWRITEX_FONT_SIZE_NORMALIZATION_EM,

    /// Normalized to majuscule capital-height
    DWRITEX_FONT_SIZE_NORMALIZATION_CAP,

    // Normalized to miniscule/x-height
    DWRITEX_FONT_SIZE_NORMALIZATION_X,

    // Normalized to cell height (ascent+descent)
    DWRITEX_FONT_SIZE_NORMALIZATION_CELL,
};


enum DWRITEX_TEXT_LAYOUT_ATTRIBUTE_TYPE
{
    underline,
    strikethrough,
    link,
    font,
    fontName,
    fontWeight,
    fontSlope,
    fontStretch,
    font...
    visibility,
    colorbrush,
    locale,
    orientation,
    direction,
    list,
    table,
    indent,
    anchor,


};

/// How much to cache.
enum DWRITEX_TEXT_LAYOUT_CACHE_DEGREE
{
    /// Cache glyphs as needed. This only caches the glyphs recently needed,
    /// either because of a hit-test call or drawing call.
    DWRITEX_TEXT_LAYOUT_CACHE_DEGREE_DEFAULT,

    /// Do not cache any glyphs, advances, clusters, offsets,
    /// or block/line/inline positioning information.
    /// This is useful for a small label that is rarely
    /// resized or redrawn, to save some memory. Alternately,
    /// you could just destroy the layout if it's infrequent
    /// enough.
    DWRITEX_TEXT_LAYOUT_CACHE_DEGREE_NONE,

    /// Do not cache any glyphs, advances, clusters, or offsets.
    /// The block/line/inline heirarchy is still cached.
    /// Glyphs need to be regenerated for display or hit-testing.
    DWRITEX_TEXT_LAYOUT_CACHE_DEGREE_POSITIONS,

    /// Cache all glyph indices, advances, clusters, or offsets.
    /// This speeds up drawing and hit-testing because the text need need not
    /// be reshaped, at the expense of 4-7x memory usage of text quantity.
    DWRITEX_TEXT_LAYOUT_CACHE_DEGREE_FULL,
};


enum UnicodeCategory;
enum UnicodeScript;


////////////////////////////////////////////////////////////////////////////////


struct DWRITEX_UNICODE_RANGE
{
    char32_t first;
    char32_t count;
};


typedef DWRITE_SCRIPT_SHAPES DWRITEX_SCRIPT_SHAPES;

/// <summary>
/// Association of text and its writing system script as well as some display attributes.
/// </summary>
struct DWRITEX_SCRIPT_ANALYSIS
{
    /// <summary>
    /// ISO 4-letter code of script.
    /// http://unicode.org/iso15924/iso15924-codes.html
    /// </summary>
    uint32_t script;
 
    /// <summary>
    /// Additional shaping requirement of text.
    /// </summary>
    DWRITEX_SCRIPT_SHAPES shapes;
};


/// Merge the mostly redundant UNDERLINE and STRIKETHROUGH, while allowing them
/// to be more extensible.


struct DWRITEX_TEXT_DECORATION
{
    DWRITEX_TEXT_DECORATION_TYPE type;

    /// Left side of the decoration.
    float left;

    /// Top side of the decoration.
    float top;

    /// Width of the decoration, measured parallel to the baseline.
    float width;

    /// Height of the tallest run where the decoration applies.
    float height;

    /// Thickness of the decoration, measured perpendicular to the
    /// baseline.
    float thickness;

    /// Offset of the decoration from the baseline.
    /// A positive offset represents a position below the baseline and
    /// a negative offset is above.
    float offset;

    /// Reading/flow direction of the text associated with the decoration.
    DWRITEX_TEXT_DIRECTION textDirection;

    // todo: delete?
    /// Reading direction of the text associated with the decoration.  This 
    /// value is used to interpret whether the width value runs horizontally 
    /// or vertically.
    DWRITE_READING_DIRECTION readingDirection;

    /// Flow direction of the text associated with the decoration.  This value
    /// is used to interpret whether the thickness value advances top to 
    /// bottom, left to right, or right to left.
    DWRITE_FLOW_DIRECTION flowDirection;

    /// Locale of the text the decoration is being drawn under. Can be
    /// pertinent where the locale affects how the decoration is drawn.
    /// For example, in vertical text, the decoration belongs on the
    /// left for Chinese but on the right for Japanese.
    /// This choice is completely left up to higher levels.
    __nullterminated char16_t const* localeName;

    /// The measuring mode can be useful to the renderer to determine how
    /// decorations are rendered, e.g. rounding the thickness to a whole pixel
    /// in GDI-compatible modes.
    DWRITE_MEASURING_MODE measuringMode;
};

struct DWRITEX_RASTER_RECT
{
    uint16_t x1; 
    uint16_t y1;
    uint16_t x2; 
    uint16_t y2;
};


__if_not_exists(DX_MATRIX_3X2F)
{
// Union of D2D and DWrite's matrix to facilitate
// usage between them, while not breaking existing
// applications that use one or the other.
union DX_MATRIX_3X2F
{
    // Explicity named fields for clarity.
    struct { // Win8
        FLOAT xx; // x affects x (horizontal scaling / cosine of rotation)
        FLOAT xy; // x affects y (vertical shear / sine of rotation)
        FLOAT yx; // y affects x (horizontal shear / negative sine of rotation)
        FLOAT yy; // y affects y (vertical scaling / cosine of rotation)
        FLOAT dx; // displacement of x, always orthogonal regardless of rotation
        FLOAT dy; // displacement of y, always orthogonal regardless of rotation
    };
    struct { // D2D Win7
        FLOAT _11;
        FLOAT _12;
        FLOAT _21;
        FLOAT _22;
        FLOAT _31;
        FLOAT _32;
    };
    struct { // DWrite Win7
        FLOAT m11;
        FLOAT m12;
        FLOAT m21;
        FLOAT m22;
        FLOAT m31;
        FLOAT m32;
    };
    float m[6]; // Would [3][2] be better, more useful?
};

inline const DWRITE_MATRIX* CastToDWrite(const DX_MATRIX_3X2F* matrix)
{
    return reinterpret_cast<const DWRITE_MATRIX*>(matrix);
}

inline const D2D1_MATRIX_3X2_F* CastToD2D(const DX_MATRIX_3X2F* matrix)
{
    return reinterpret_cast<const D2D1_MATRIX_3X2_F*>(matrix);
}


/// <summary>
/// The DWRITE_GLYPH_METRICS structure specifies the metrics of an individual glyph.
/// The units depend on how the metrics are obtained.
/// </summary>
struct DWRITEX_GLYPH_METRICS

{

    INT32 left;

    INT32 top;

    INT32 right;

    INT32 bottom;

 

    uint32_t advanceWidth;

    uint32_t advanceHeight;

 

    INT32 verticalOriginX;

    INT32 verticalOriginY;

};


struct DWRITEX_TEXT_LAYOUT_POSITION
{
    // Absolute text position in backing store.
    uint32_t textPosition;

    // Index of the current element.
    uint32_t elementReference;

    // Detects when a position has been invalidated.
    uint32_t editCount;
};


struct DWRITEX_TEXT_LAYOUT_ATTRIBUTE
{
    // The type of attribute (DWRITEX_TEXT_LAYOUT_ATTRIBUTE_TYPE).
    uint8_t type;

    /// This attribute is implicitly derived from the underlying text
    /// and should not be saved upon writing outbound. Some examples
    /// might include bidi direction, font face, and script.
    uint8_t isDerivedAttribute: 1;

    /// Number of characters until next attribute.
    /// Note this is NOT the length
    uint32_t textLengthToNextAttribute;

    /// Points to the next attribute.
    uint32_t nextIndex;

    /// The opposite opening or closing attribute to this one.
    /// If it points to itself, it is solitary or stateful
    /// forward.
    uint32_t partnerIndex;

    union VALUE
    {
        void* customResource;
        IUnknown* iunknown;
        IDWriteInlineObject* inlineObject;
        IDWriteFontFace* fontFace;
        float fontSize;
        char16_t* fontName;
        uint8_t bidiLevel;
        uint32_t anchorIndex;
        DWRITEX_TEXT_DECORATION textDecorations;
    } value;
};


////////////////////////////////////////////////////////////////////////////////


interface DECLSPEC_UUID("0000") DECLSPEC_NOVTABLE IDWritExTextAnalysisSource : public IDWriteTextAnalysisSource
{
};


interface DECLSPEC_UUID("0000") DECLSPEC_NOVTABLE IDWritExTextAnalysisSink : public IDWriteTextAnalysisSink
{
    STDMETHOD(SetVertical)(
        uint32_t textPosition,
        uint32_t textLength,
        DWRITE_GLYPH_GRAVITY
        ) PURE;
};


interface DECLSPEC_UUID("0000") DECLSPEC_NOVTABLE IDWritExPlainTextLayout
{
    // based off RichEdit text object model
    // query given line metrics
    // get text position
    // get text of given line, current word, selection, paragraph
    // get text of range
    // set/insert text of range
    // seek next/previous line, word, paragraph, home/end
    // find text
    // 4 wrapping modes
    // get/set font
    // undo
};


interface DECLSPEC_UUID("0000") DECLSPEC_NOVTABLE IDWritExFlowTextLayout
{






};


interface DWRITE_DECLARE_INTERFACE("0000") IDWritExDCRenderTarget : public IUnknown
{
    STDMETHOD(BindDC)(
        __in const HDC hDC,
        __in const RECT* pSubRect 
        ) PURE;

    STDMETHOD_(void, BeginDraw)() PURE;
    
    // Ends drawing on the render target, error results can be retrieved at this time,
    // or when calling flush.
    STDMETHOD(EndDraw)() PURE;

    STDMETHOD(DrawGlyphRun)(
        float baselineOriginX,
        float baselineOriginY,
        DWRITE_MEASURING_MODE measuringMode,
        __in DWRITE_GLYPH_RUN const* glyphRun,
        IDWriteRenderingParams* renderingParams,
        COLORREF textColor,
        __out_opt RECT* blackBoxRect = NULL
        ) PURE;
};


// - There should be no need to call a completely separate function
//   just to get hinted layout. It should just be a parameter on the
//   creation call.
// - The Boolean useGdiNatural is unnecessarily confusing and masks the
//   otherwise clear correlation to measuring modes.
// - The matrix transform on CreateGdiCompatibleLayout mimics GDI's,
//   hideous jittered glyph placement, which is something that needs
//   to die once and for all.
//
HRESULT /*IDWriteFactory::*/CreateTextLayout(
    IDWriteFactory* factory,
    __in_ecount(stringLength) char16_t const* string,
    uint32_t stringLength,
    IDWriteTextFormat* textFormat,
    float maxWidth,
    float maxHeight,
    DWRITE_MEASURING_MODE measuringMode,
    __out IDWriteTextLayout** textLayout
    ) throw();

HRESULT /*IDWriteGdiInterop::*/CreateDCRenderTarget(
    IDWriteGdiInterop* gdiInterrop,
    __deref_out IDWritExDCRenderTarget** dcRenderTarget 
    ) throw();

// Draws to any arbitrary HDC.
// It accomplishes this via a BitBlt both directions.
// If you are drawing several strings of text, it's more
// efficient to draw to a DC render target.
//
// todo: fix outline bug
//
HRESULT /*IDWriteGdiInterop::*/DrawGlyphRun(
    HDC hdc,
    float baselineOriginX,
    float baselineOriginY,
    DWRITEX_BASELINE baseline, // todo: keep?
    DWRITE_MEASURING_MODE measuringMode,
    __in const DWRITE_GLYPH_RUN* glyphRun,
    IDWriteRenderingParams* renderingParams,
    COLORREF textColor,
    BOOL drawAlphaChannel,
    __out_opt RECT* blackBoxRect = NULL
    ) throw();

HRESULT /*IDWriteGdiInterop::*/DrawGlyphRun(
    const DIBSECTION& dibSection,
    float baselineOriginX,
    float baselineOriginY,
    DWRITE_MEASURING_MODE measuringMode,
    __in const DWRITE_GLYPH_RUN* glyphRun,
    IDWriteRenderingParams* renderingParams,
    COLORREF textColor,
    BOOL drawAlphaChannel,
    __out_opt RECT* blackBoxRect = NULL
    ) throw();

HRESULT /*IDWriteGlyphRunAnalysis::*/GetAlphaTexture(
    IDWriteGlyphRunAnalysis* glyphRunAnalysis,
    DWRITEX_TEXTURE_TYPE textureType,
    __in RECT const* textureBounds,
    __out_bcount(bufferSize) uint8_t* alphaValues,
    uint32_t bufferSize
    ) throw();

// The most logical, intuitive place to retrieve the file path would be from
// the FontFile. Instead, we need to go through this convoluted path that
// no one would ever figure out on their own. Even given the argument that
// it's the font file loader which understands the semantics of the file path
// rather than the file object, it's still trivial (+intuitive and convenient)
// to have the FontFile call its own loader with its key.
//
HRESULT /*IDWriteFontFile::*/GetFilePath(
    IDWriteFontFile* fontFile,
    __out_ecount_z(filePathSize) char16_t* filePath,
    uint32_t filePathSize
    );

HRESULT /*IDWriteFontFace::*/GetFilePath(
    IDWriteFontFace* fontFace,
    __out_ecount_z(filePathSize) char16_t* filePath,
    uint32_t filePathSize
    );

// todo:    read CMAP table directly, since it's inefficient
//          to call HasCharacter several times for sparse ranges
//          of the vast Unicode space (0 - 10FFFFh).
//
//          http://www.microsoft.com/Typography/otspec/cmap.htm
//
HRESULT /*IDWriteFont::*/GetCodepointRanges(
    IDWriteFont* font,
    uint32_t maxRangeCount,
    __out uint32_t* actualRangeCount,
    __out_ecount(maxRangeCount) DWRITEX_UNICODE_RANGE* ranges // todo: make SAL similar to GetLineMetrics()
    ) throw();

UnicodeScript /*IDWriteTextAnalyzer::*/GetUnicodeScript(
    char32_t ch
    ) throw();

HRESULT /*IDWriteTextAnalyzer::*/GetUnicodeScripts(
    __in_ecount(textCount) char16_t text,
    uint32_t textCount,
    __out_ecount(textCount) UnicodeScript* scripts
    ) throw();

UnicodeCategory /*IDWriteTextAnalyzer::*/GetUnicodeCategory(
    char32_t ch
    ) throw();

HRESULT /*IDWriteTextAnalyzer::*/GetUnicodeCategories(
    __in_ecount(textCount) char16_t text,
    uint32_t textCount,
    __out_ecount(textCount) UnicodeCategory* categories
    ) throw();

HRESULT /*IDWriteTextAnalyzer::*/MirrorCodepoints(
    __in_ecount(textCount) char16_t text,
    uint32_t textCount,
    __out_ecount(textCount) char16_t* mirroredText
    ) throw();

HRESULT /*IDWriteTextAnalyzer::*/AnalyzeFonts(
    IDWritExTextAnalysisSource* source,
    uint32_t offset,
    uint32_t length,
    IDWritExTextAnalysisSink* sink
    ) throw();

HRESULT /*IDWriteTextAnalyzer::*/AnalyzeVertical(
    IDWritExTextAnalysisSource* source,
    uint32_t textPosition,
    uint32_t textLength,
    IDWritExTextAnalysisSink* sink
    ) throw();

/// This is similar to ScriptLayout, except that you don't need to pointlessly
/// extract an array of bidi levels into an array (unless they are in a linked
/// list). The function only provides a mapping from sequential to visual,
/// not the reverse (I've honestly never needed it, even for hit-testing).
///
HRESULT /*IDWriteTextAnalyzer::*/GetBidiVisualOrdering(
    __in_ecount(bidiLevelsCount) const uint8_t* bidiLevels,
    uint32_t bidiLevelsStride,
    uint32_t bidiLevelsCount,
    __out_ecount(bidiLevelsCount) uint32_t* visualOrdering
    ) throw();

/// This is similar to ScriptCPtoX.
/// Note that for vertical text, x is actually y.
///
HRESULT /*IDWriteTextAnalyzer::*/GetCaretOffset(
    __range(0, textCount) uint32_t textPosition,
    bool isTrailingEdge,
    uint32_t glyphCount,
    uint32_t textCount,
    __in_ecount(glyphCount) const float* glyphAdvances,
    __in_ecount(textCount) const uint16_t* textToGlyphMap,
    float width,
    DWRITEX_TEXT_DIRECTION readingDirection,
    __out float* x
    ) throw();

/// The input and output arrays may be the same.
///
HRESULT /*IDWriteTextAnalyzer::*/ApplyCharacterSpacing(
    float characterSpacing,
    uint32_t glyphCount,
    __in_ecout(glyphCount) float* glyphAdvances,
    __out_ecout(glyphCount) float* spacedGlyphAdvances
    ) throw();

/// Applies old style kerning using the pair table from KERN.
/// This should not be applied if the font also has GSUB kerning.
///
HRESULT /*IDWriteTextAnalyzer::*/ApplyKerning(
    IDWriteFontFace* fontFace,
    float fontEmSize,
    uint32_t glyphCount,
    __in_ecount(glyphCount) const uint16_t* glyphIndices,
    __inout_ecount(glyphCount) float* glyphAdvances,
    ) throw();

HRESULT /*IDWriteTextAnalyzer::*/ApplyJustification(
    IDWriteFontFace* fontFace,
    float fontEmSize,
    float lineWidth,
    uint32_t maxGlyphCount,
    __inout uint32_t* glyphCount,
    __in_ecount(*glyphCount) const DWRITE_SHAPING_GLYPH_PROPERTIES* glyphProps,
    __inout_ecount_part(*glyphCount, maxGlyphCount) UINT16* glyphIndices,
    __inout_ecount_part(*glyphCount, maxGlyphCount) float* glyphAdvances,
    ) throw();

// Pass DWRITEX_FONT_TAG_NULL as a wildcard for any of these.
//
HRESULT /*IDWriteFontFace::*/EnumerateFeatureTags(
    IDWriteFontFace* fontFace,
    DWRITEX_FONT_TAG_TYPE desiredTagType,
    DWRITEX_FONT_TAG table,
    DWRITEX_FONT_TAG script,
    DWRITEX_FONT_TAG language,
    DWRITEX_FONT_TAG feature,
    __out_ecount(tagBufferMaxCount) tagBuffer,
    uint32_t tagBufferMaxCount,
    __out uint32_t* tagBufferActualCount
    ) throw();
    
// If the given baseline is valid, but the font does not have any
// information for it, the function returns a heuristically computed
// baseline, and sets baselineExists to false.
//
// todo: is it safe to normalize all baselines to the Roman baseline?
HRESULT /*IDWriteFontFace::*/GetBaseline(
    IDWriteFontFace* fontFace,
    DWRITEX_BASELINE desiredBaseline,
    __out int32_t* baselineOffset,
    __out BOOL* baselineExists
    ) throw();

HRESULT /*IDWriteFactory::*/CreateFontFace(
    IDWriteFactory* factory,
    DWRITE_FONT_FACE_TYPE fontFaceType,
    uint32_t numberOfFiles,
    __in_z char16_t const* filePath,
    uint32_t faceIndex,
    DWRITE_FONT_SIMULATIONS fontFaceSimulationFlags,
    __out IDWriteFontFace** fontFace
    ) throw();

// todo: see whether or not this is safe
HRESULT /*IDWriteFactory::*/CreateCustomFontCollection(
    IDWriteFactory* factory,
    IDWriteFontCollectionLoader* collectionLoader,
    __in_bcount(collectionKeySize) void const* collectionKey,
    size_t collectionKeySize,
    __out IDWriteFontCollection** fontCollection
    ) throw();

HRESULT /*IDWriteFontFace::*/GetGlyphBitmap(
    IDWriteFontFace* fontFace,
    float fontEmSize,
    DWRITE_MEASURING_MODE measuringMode,
    __in_opt DWRITE_MATRIX const* transform,
    __out POINT* origin,
    __out_bcount(bufferSize) uint8_t* alphaValues,
    size_t maxBufferSize
    __out size_t* actualBufferSize
    ) throw();

HRESULT /*IDWriteFontFace::*/DetermineSimpleGlyphBits(
    IDWriteFontFace* fontFace,
    DWRITEX_FONT_TAG tableTag,
    __in_ecount(desiredFeaturesCount) uint32_t const* desiredFeatures,
    size_t desiredFeaturesCount,
    uint16_t minGlyphId,
    uint16_t maxGlyphId,
    size_t glyphBitsSize,
    __in_ecount(glyphBitsSize) uint8_t const* interestedGlyphBits,
    __inout_ecount(glyphBitsSize) uint8_t* simpleGlyphBits
    ) throw();

// Use the given table data, rather than reading the font.
HRESULT /*IDWriteFontFace::*/DetermineSimpleGlyphBits(
    IDWriteFontFace* fontFace,
    __in_bcount(tableSize) const uint8_t* table,
    size_t tableSize,
    DWRITEX_FONT_TAG tableTag,
    __in_ecount(desiredFeaturesCount) uint32_t const* desiredFeatures,
    size_t desiredFeaturesCount,
    uint16_t minGlyphId,
    uint16_t maxGlyphId,
    bool clearOutBits,
    size_t glyphBitsSize,
    __in_ecount(glyphBitsSize) uint8_t const* interestedGlyphBits,
    __inout_ecount(glyphBitsSize) uint8_t* simpleGlyphBits
    ) throw();

// todo: make extern
static const uint32_t DesiredGsubFeatures[] = {
    DWRITE_MAKE_OPENTYPE_TAG('r','l','i','g'), // Required ligatures
    DWRITE_MAKE_OPENTYPE_TAG('l','o','c','l'), // Localized forms
    DWRITE_MAKE_OPENTYPE_TAG('c','c','m','p'), // Composition/decomposition
    DWRITE_MAKE_OPENTYPE_TAG('c','a','l','t'), // Contextual alternates
    DWRITE_MAKE_OPENTYPE_TAG('l','i','g','a'), // Standard ligatures
    DWRITE_MAKE_OPENTYPE_TAG('c','l','i','g'), // Contextual ligatures
};
static const uint32_t DesiredGposFeatures[] = {
    DWRITE_MAKE_OPENTYPE_TAG('k','e','r','n'), // Kerning
    DWRITE_MAKE_OPENTYPE_TAG('m','a','r','k'), // Mark positioning
    DWRITE_MAKE_OPENTYPE_TAG('m','k','m','k'), // Mark to mark positioning
};



const static float MapDirectionToProgression[8][2] = {
        { 1, 1},
        {-1, 1},
        { 1,-1},
        {-1,-1},
        { 1, 1},
        {-1, 1},
        { 1,-1},
        {-1,-1},
    };

DWRITE_READING_DIRECTION cast(DWRITEX_TEXT_DIRECTION textDirection)
{
    // Modes that have no mapping are intentionally invalid.
    const static DWRITE_READING_DIRECTION remap[8] = {
        DWRITE_READING_DIRECTION_LEFT_TO_RIGHT,
        DWRITE_READING_DIRECTION_RIGHT_TO_LEFT,
        DWRITE_READING_DIRECTION_LEFT_TO_RIGHT,
        DWRITE_READING_DIRECTION_RIGHT_TO_LEFT,
        DWRITE_READING_DIRECTION(-1),   // would be top-to-bottom, if it existed
        DWRITE_READING_DIRECTION(-1),   // would be top-to-bottom
        DWRITE_READING_DIRECTION(-1),   // would be bottom-to-top
        DWRITE_READING_DIRECTION(-1)    // would be bottom-to-top
    };
    return remap[textDirection & 7];
}

DWRITE_FLOW_DIRECTION cast(DWRITEX_TEXT_DIRECTION textDirection)
{
    // Modes that have no mapping are intentionally invalid.
    const static DWRITE_FLOW_DIRECTION remap[8] = {
        DWRITE_FLOW_DIRECTION_TOP_TO_BOTTOM,
        DWRITE_FLOW_DIRECTION_TOP_TO_BOTTOM,
        DWRITE_FLOW_DIRECTION(-1),      // would be bottom-to-top, if it existed
        DWRITE_FLOW_DIRECTION(-1),      // would be bottom-to-top
        DWRITE_FLOW_DIRECTION(-1),      // would be left-to-right
        DWRITE_FLOW_DIRECTION(-1),      // would be right-to-left
        DWRITE_FLOW_DIRECTION(-1),      // would be left-to-right
        DWRITE_FLOW_DIRECTION(-1)       // would be right-to-left
    };
    return remap[textDirection & 7];
}

DWRITEX_TEXT_DIRECTION cast(DWRITE_READING_DIRECTION readingDirection, DWRITE_FLOW_DIRECTION flowDirection)
{
    const static DWRITEX_TEXT_DIRECTION remap[16] = {
        DWRITEX_TEXT_DIRECTION_LTR_TTB, // Latin, Cyrillic, Greek, CJK when horizontal
        DWRITEX_TEXT_DIRECTION_RTL_TTB, // Arabic, Hebrew, Syriac
    };
    return remap[(readingDirection & 3) | ((flowDirection & 3) << 2)];
}


bool IsReversedReadingDirection(DWRITEX_TEXT_DIRECTION textDirection)
{
    // These directions have an opposite character reading direction.
    const uint32_t reversedDirections = 
        (1 << DWRITEX_TEXT_DIRECTION_RTL_TTB) |
        (1 << DWRITEX_TEXT_DIRECTION_RTL_BTT) |
        (1 << DWRITEX_TEXT_DIRECTION_BTT_LTR) |
        (1 << DWRITEX_TEXT_DIRECTION_BTT_RTL);

    return (1 << textDirection) & reversedDirections;
}

bool IsReversedFlowDirection(DWRITEX_TEXT_DIRECTION textDirection)
{
    // These directions have an opposite line flow direction.
    const uint32_t reversedDirections = 
        (1 << DWRITEX_TEXT_DIRECTION_LTR_BTT) |
        (1 << DWRITEX_TEXT_DIRECTION_RTL_BTT) |
        (1 << DWRITEX_TEXT_DIRECTION_TTB_RTL) |
        (1 << DWRITEX_TEXT_DIRECTION_BTT_RTL);

    return (1 << textDirection) & reversedDirections;
}


} // namespace DWritEx




#if 0

// todo:
// Better architecture to support font fallback is one of the frequent
// feedback from Word and IE. This work is to investigate composite font
// and the current set of requirements from Adobe and Apple in composite
// font mailing list, as well as specific needs from Word and IE, and to come
// up with a model that would allow composite font to be programmatically built
// up and used by the app as a way to control font fallback behavior across all
// writing systems.
//

// CSS cursive fantasy monospace sans-serif serif

// JRE Dialog DialogInput Monospaced SansSerif Serif

/*

Dialog Lucida Sans or Arial plus extra chars in Vista. comes with JRE
DialogInput Courier New comes with Windows
Monospaced Courier New comes with Windows
SansSerif Lucida Sans or Arial plus extra chars in Vista. comes with JRE
Serif Times New Roman comes with Windows

Combines Uniscribe's font fallback with GDI's font linking

GDI
HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\Current Version\FontSubstitutes.
HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontLink\SystemLink

*/

// todo: add to factory GetDefaultFontFallback()

// todo: add to factory CreateFontMapping()

// Hard-coded.
// todo: add to factory GetDefaultFontMapping()

// Creates a simplistic character fallback mapping given a font collection.
// They will simply be prioritized according to order, without consideration
// of similarity or locale or general style similarity.
// todo: add to factory CreateFontMappingFromCollection()


enum DWRITE_FONT_FALLBACK_GRANULARITY
{
    /// <summary>
    /// Fallback occurs per character. This is what GDI and GDI+ do.
    /// </summary>
    DWRITE_FONT_FALLBACK_GRANULARITY_CHARACTER,

    /// <summary>
    /// Attempt to find the longest match in a word to improve overall
    /// consistency of appearance (rather than individual characters
    /// falling back within a word which look out of place).
    /// </summary>
    DWRITE_FONT_FALLBACK_GRANULARITY_WORD,
};


enum DWRITE_FONT_MAPPING_TYPE
{
    /// <summary>
    /// Simply font fallback chain.
    /// </summary>
    DWRITE_FONT_MAPPING_TYPE_LINK_CHAIN,

    /// <summary>
    /// Fallback chain based on a generic font family
    /// (purely a virtual font family that does not exist).
    /// </summary>
    DWRITE_FONT_MAPPING_TYPE_GENERIC_FAMILY,

    /// <summary>
    /// Substitution entry, from virtual font to actual font
    /// (for example, MS Shell Dlg -> Microsoft Sans Serif).
    /// </summary>
    DWRITE_FONT_MAPPING_TYPE_SUBSTITUTION,
};


enum DWRITE_FONT_MAPPING_FIELDS
{
    DWRITE_FONT_MAPPING_FIELD_NONE              = 0x00000000,
    DWRITE_FONT_MAPPING_FIELD_CHARACTER_RANGE   = 0x00000001,
    DWRITE_FONT_MAPPING_FIELD_LOCALE            = 0x00000002,
    DWRITE_FONT_MAPPING_FIELD_FAMILIES          = 0x00000004,
    DWRITE_FONT_MAPPING_FIELD_ROOT_FAMILY_NAME  = 0x00000008,
    DWRITE_FONT_MAPPING_FIELD_MAPPING_TYPE      = 0x00000010,
    DWRITE_FONT_MAPPING_FIELD_SCALE             = 0x00000020,

    // Most typical usage for GetBestMatch().
    DWRITE_FONT_MAPPING_FIELD_FAMILIES_TYPE_SCALE = DWRITE_FONT_MAPPING_FIELD_FAMILY_NAMES
                                                  | DWRITE_FONT_MAPPING_FIELD_MAPPING_TYPE
                                                  | DWRITE_FONT_MAPPING_FIELD_SCALE,

    DWRITE_FONT_MAPPING_FIELD_FORCE_DWORD = 0xFFFFFFFF
};

#ifdef DEFINE_ENUM_FLAG_OPERATORS
DEFINE_ENUM_FLAG_OPERATORS(DWRITE_FONT_MAPPING_FIELDS);
#endif


struct DWRITE_FONT_MAPPING_ENTRY
{
    /// <summary>
    /// Which fields are present. All other fields do not exist and should
    /// be ignored by the caller (as they are left untouched).
    /// </summary>
    DWRITE_FONT_MAPPING_FIELDS presentFields;

    /// <summary>
    /// Character range supported for this mapping.
    /// </summary>
    DWRITE_CHARACTER_RANGE characterRange;

    /// <summary>
    /// What type of entry it is, such as a substitution or generic family.
    /// </summary>
    DWRITE_FONT_MAPPING_TYPE mappingType;

    /// <summary>
    /// Locale name, for localized font fallback.
    /// </summary>
    __nullterminated char16_t* localeName;

    /// <summary>
    /// Generic family name
    /// </summary>
    __nullterminated char16_t* rootFamilyName;

    /// <summary>
    /// Horizontal shift (always orthogonal regardless of rotation)
    /// </summary>
    __nullterminated char16_t* familyNames;

    /// <summary>
    /// Horizontal shift (always orthogonal regardless of rotation)
    /// </summary>
    float scale;
};


/// <summary>
/// Holds font mappings for font fallback/linking/substitution. This is just
/// the data itself. It performs no actual font matching, which is done by
/// IDWriteFontMapper.
/// </summary>
interface DWRITE_DECLARE_INTERFACE("B9A640F1-28DC-42EC-B303-72C56A8061E4") IDWriteFontMapping : public IUnknown
{
/// <summary>
/// Adds a new mapping entry.
/// </summary>
/// <returns>
/// Standard HRESULT error code.
/// BeginUpdate() must be called before modifying the mappings,
/// otherwise you will get E_ACCESSDENIED.
/// </returns>
STDMETHOD(AddMapping)(
    uint32_t firstCharacter,
    uint32_t lastCharacter,
    DWRITE_FONT_MAPPING_TYPE mappingType,
    __in_z char16_t const* fontFamilyNames
    __in_opt_z char16_t const* localeName = NULL,
    __in_opt_z char16_t const* rootFamilyName = NULL
) PURE;

/// <summary>
/// Removes the given mapping entry.
/// </summary>
/// <returns>
/// Standard HRESULT error code.
/// BeginUpdate() must be called before modifying the mappings,
/// otherwise you will get E_ACCESSDENIED.
/// </returns>
STDMETHOD(RemoveMapping)(
    uint32_t index
) PURE;

/// <summary>
/// Clears all mappings.
/// </summary>
/// <remarks>
/// </remarks>
/// <returns>
/// Standard HRESULT error code.
/// BeginUpdate() must be called before modifying the mappings,
/// otherwise you will get E_ACCESSDENIED.
/// </returns>
STDMETHOD(ClearMappings)(
    uint32_t index
) PURE;

/// <summary>
/// Returns the number of mapping entries.
/// </summary>
STDMETHOD_(uint32_t, GetMappingCount) PURE ();

/// <summary>
/// Returns information about the given mapping.
/// </summary>
/// <param name="desiredFields">Which fields are desired to fill in the
/// mappingEntry.</param>
/// <param name="mappingData">Additional buffer to fill in with variable
/// size field information like string names. The mappingEntry fields
/// will point into this.</param>
/// <param name="mappingEntry">Mapping entry information. The desired
/// fields will be filled in.</param>
/// <returns>
/// Standard HRESULT error code.
/// If an unrecognized desiredField was set, DWRITE_E_PARTIALINFORMATION
/// will be returned, with only those fields that were recognized being
/// set (check DWRITE_FONT_MAPPING_ENTRY::presentFields). Upon success,
/// presentFields will equal desiredFields, and all fields will be filled.
/// </returns>
/// <remarks>
/// This always returns the current mapping regardless of whether the
/// mapping is being updated or not.
/// </remarks>
/// <remarks>
/// The longest font chain entry in GlobalUserInterface is 170 characters,
/// so mappingData[] should be at least 340 bytes to avoid an insufficient
/// buffer error (512 should be safe).
/// </remarks>
STDMETHOD(GetMapping)(
    uint32_t index,
    DWRITE_FONT_MAPPING_FIELDS desiredFields,
    __in uint32_t maxMappingDataSize,
    __out uint32_t* neededMappingDataSize,
    __out_bcount_part(0, maxEntryByteSize) void* mappingData,
    __out DWRITE_FONT_MAPPING_ENTRY* mappingEntry
);

/// <summary>
/// Begins updating the mapping, either for addition of new entries or
/// removal of old ones.
/// </summary>
/// <returns>
/// Standard HRESULT error code.
/// Any other threads that attempt to modify the mapping will fail
/// with DWRITE_E_BUSY.
/// Note that the default mapping based on DWrite's internal font fallback
/// cannot be modified, and you will always get E_ACCESSDENIED.
/// </returns>
/// <remarks>
/// EndUpdate() must be called when finished.
/// </remarks>
STDMETHOD(BeginUpdate)() PURE;

/// <summary>
/// Commits the new mappings. Until then, any mapping calls will be stale.
/// </summary>
/// <returns>
/// Standard HRESULT error code.
/// Note that the default mapping based on DWrite's internal font fallback
/// cannot be modified, and you will always get E_ACCESSDENIED.
/// </returns>
STDMETHOD(EndUpdate)() PURE;

/// <summary>
/// Returns the most specific match, given a character code, optional
/// locale, and an optional root family name. Typically you will only be
/// interested in retrieving the list of family names, plus the mapping
/// type and scale.
/// </summary>
/// <param name="character">UTF32 character code to search for. If no
/// entries match the given character, an empty string is returned
/// for the font family names. You should then just use the base
/// font, which will display missing glyphs (if the font family is
/// a virtual name like MS Shell Dlg, use the actual substituted
/// family Microsoft Sans Serif instead). If you want to always
/// display something, instead of missing glyphs, you can add an
/// entry for a last-resort font spanning the entire Unicode range
/// 0-1FFFFF.</param>
/// <param name="localeName">Locale to search for. If the given locale
/// is not found, it will look for an empty locale that satisfies
/// the other criteria.</param>
/// <param name="rootFamilyName">This can be either the original font
/// family name (useful for substituting virtual family names like
/// MS Shell Dlg) or a generic font family name (such as Monospace
/// or SansSerif). If not supplied, the search just uses the character
/// code and locale. If the best match found is a substitution, then
/// you may need to perform a second lookup for fallback/linking using
/// that actual font name. An example case would be the user applying
/// MS Shell Dlg on CJK text, which would resolve to Microsoft Sans
/// Serif, but that font lacks any CJK. So you would look up a second
/// time for the full linking/fallback list.
/// </param>
/// <param name="desiredFields">Which fields are desired to fill in the
/// mappingEntry.</param>
/// <param name="mappingData">Additional buffer to fill in with variable
/// size field information like string names. The mappingEntry fields
/// will point into this.</param>
/// <param name="mappingEntry">Mapping entry information. The desired
/// fields will be filled in.</param>
/// <returns>
/// Standard HRESULT error code.
/// If it returns insufficient buffer, you need mappingData at least as
/// large as neededMappingDataSize. None of the data can be considered
/// valid.
/// If an unrecognized desiredField was set, DWRITE_E_PARTIALINFORMATION
/// will be returned, with only those fields that were recognized being
/// set (check DWRITE_FONT_MAPPING_ENTRY::presentFields). Upon success,
/// presentFields will equal desiredFields, and all fields will be filled.
/// </returns>
/// <remarks>
/// This function will only return current results after the mapping is
/// done being updated. So long as it is being updated, it will return
/// stale mappings.
/// </remarks>
/// <remarks>
/// The longest font chain entry in GlobalUserInterface is 170 characters,
/// so mappingData[] should be at least 340 bytes to avoid an insufficient
/// buffer error (512 should be safe).
/// </remarks>
STDMETHOD(GetBestMatch)(
    uint32_t character,
    __in_opt_z char16_t const* localeName,
    __in_opt_z char16_t const* rootFamilyName,
    DWRITE_FONT_MAPPING_FIELDS desiredFields,
    __in uint32_t maxMappingDataSize,
    __out uint32_t* neededMappingDataSize,
    __out_bcount_part(0, maxEntryByteSize) void* mappingData,
    __out DWRITE_FONT_MAPPING_ENTRY* mappingEntry
) PURE;
};


/// <summary>
/// Processes a text to return an appropriate font to use.
/// This can be implemented by the application.
/// </summary>
interface DWRITE_DECLARE_INTERFACE("F9D88B21-C715-48C0-9205-4462FA0DC127") IDWriteFontMapper : public IUnknown
{
/// <summary>
/// Maps a string of text to the font that best supports it.
/// </summary>
/// <remarks>
/// The DWrite default mapper implementation will keep diacritics together
/// with their base characters.
/// </remarks>
STDMETHOD(MapCharacters)(
    __ecount(textLength) char16_t const* text,
    uint32_t textLength,
    __maybenull IDWriteFont* baseFont,
    __in_z char16_t const* baseFamilyName,
    __in_z char16_t const* localeName,
    DWRITE_FONT_WEIGHT baseWeight,
    DWRITE_FONT_STYLE baseStyle,
    DWRITE_FONT_STRETCH baseStretch,
    __out uint32_t* mappedLength,
    __out IDWriteFont** mappedFont,
    __out float* scale
) PURE;

STDMETHOD(SetFontMapping)(
    IDWriteFontMapping* fontMapping
) PURE;

STDMETHOD(SetFontCollection)(
    IDWriteFontCollection* fontMapping
) PURE;

STDMETHOD(SetGranularity)(
    DWRITE_FONT_FALLBACK_GRANULARITY granularity
) PURE;
};
#endif
