#define ISOLATION_AWARE_ENABLED 1
#define NOMINMAX
#include <windows.h>
#include <windowsx.h>
#include <comip.h>
#include <comdef.h>
#include <d2d1.h>
#include <dwrite.h>
#include <shlobj.h>
#include <stdexcept>
#include <vector>
#include <string>
#include <map>
#include <algorithm>
#include <ios>
#include <iomanip>
#include <math.h>
#include <assert.h>

#pragma warning(disable: 4127) // conditional expression is constant (for TIF)
#pragma warning(disable: 4481) // nonstandard extension used: override specifier


#define TIF(x) do {if (FAILED(x)) throw std::runtime_error(#x);} while (false)


_COM_SMARTPTR_TYPEDEF(ID2D1Factory, __uuidof(ID2D1Factory));
_COM_SMARTPTR_TYPEDEF(ID2D1GeometrySink, __uuidof(ID2D1GeometrySink));
_COM_SMARTPTR_TYPEDEF(ID2D1HwndRenderTarget, __uuidof(ID2D1HwndRenderTarget));
_COM_SMARTPTR_TYPEDEF(ID2D1PathGeometry, __uuidof(ID2D1PathGeometry));
_COM_SMARTPTR_TYPEDEF(ID2D1StrokeStyle, __uuidof(ID2D1StrokeStyle));
_COM_SMARTPTR_TYPEDEF(ID2D1SolidColorBrush, __uuidof(ID2D1SolidColorBrush));

_COM_SMARTPTR_TYPEDEF(IDWriteFactory, __uuidof(IDWriteFactory));
_COM_SMARTPTR_TYPEDEF(IDWriteFontCollection, __uuidof(IDWriteFontCollection));
_COM_SMARTPTR_TYPEDEF(IDWriteFontFace, __uuidof(IDWriteFontFace));
_COM_SMARTPTR_TYPEDEF(IDWriteFontFile, __uuidof(IDWriteFontFile));
_COM_SMARTPTR_TYPEDEF(IDWriteFontFileLoader, __uuidof(IDWriteFontFileLoader));
_COM_SMARTPTR_TYPEDEF(IDWriteLocalFontFileLoader, __uuidof(IDWriteLocalFontFileLoader));
_COM_SMARTPTR_TYPEDEF(IDWriteTextAnalyzer, __uuidof(IDWriteTextAnalyzer));
_COM_SMARTPTR_TYPEDEF(IDWriteTextFormat, __uuidof(IDWriteTextFormat));
_COM_SMARTPTR_TYPEDEF(IDWriteTextLayout, __uuidof(IDWriteTextLayout));
_COM_SMARTPTR_TYPEDEF(IDWriteTypography, __uuidof(IDWriteTypography));


extern HINSTANCE g_instance;
extern IDWriteFactoryPtr g_dwrite;
extern ID2D1FactoryPtr g_d2d;


inline bool operator == (const D2D1_SIZE_F & a, const D2D1_SIZE_F & b)
{
    return a.width == b.width && a.height == b.height;
}


inline D2D1_POINT_2F operator+ (D2D1_POINT_2F a, D2D1_POINT_2F b)
{
    return D2D1::Point2F(a.x + b.x, a.y + b.y);
}


inline D2D1_POINT_2F operator- (D2D1_POINT_2F a, D2D1_POINT_2F b)
{
    return D2D1::Point2F(a.x - b.x, a.y - b.y);
}


