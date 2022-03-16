/*
LunaSvgTest.cpp: Main application.

TODO:
    - KeepBitmapInClientRect
    - Wrap waterfall to window width
    - Allow multiple icons at natural size
    - Cleanup RedrawSvg layout
    - Upload to GitHub
    - Menu should display dot or check marks
    - Move these thoughts below to another file

Fix void Canvas::rgba() to use macros. canvas.cpp line 195
    plutovg-private.h
    #define plutovg_alpha_shift 24
    #define plutovg_red_shift 0
    #define plutovg_green_shift 8
    #define plutovg_blue_shift 16

Gridfitting prototype - add extended SVG attributes for gridfitting
    Anchor points
    Grid fitting
        Align group of objects to adjusted/aligned point
        Translate anchor and entire grouped object and then stretch by other anchor
        transform-grid(translate(...) scale(...)
    Rounding
        Grid alignment rounding: fraction/halves + up, down, left, right, floor, ceil, toZero, toInfinity, in, out (so halves-up, fraction-toZero...)
        rounding-origin for in (toward zero) and out (toward infinity) rounding
        inward and outward rounding based on path direction clockwise vs counterclockwise
        Round relative another point
        Round even/odd (e.g. 1/3/5 odd pixel lines to half pixel vs 2/4/6 even pixel lines to pixel intersection) grid-rounding="evenodd(2)"
        Round at a fraction of the grid, such as half pixels grid-rounding="x floor half"? grid-scale="0.5 0.5"? grid-transform="scale(0.5 0.5)"
    Conditional details
        Conditional visibility based on device pixels per canvas unit (PPU)
    Minimum constraints
        Set minimum path width minimum-strokewidth="1px" (e.g. no thinner than 1 pixel)
        Ensure minimum 1-pixel gap between lines (e.g. Outlook office calendar icon)

Read:
    A vector format for Flutter by Google
    https://docs.google.com/document/d/1YWffrlc6ZqRwfIiR1qwp1AOkS9JyA_lEURI8p5PsZlg/edit#heading=h.8crpi5305nr
    http://people.redhat.com/otaylor/grid-fitting/ Rendering good looking text with resolution-independent layout

Investigate callstack for pixel coordinate rounding / grid-fitting:
    lunasvgtest.exe!sw_ft_outline_convert(const plutovg_path * path, const plutovg_matrix_t * matrix) Line 128	C
    lunasvgtest.exe!plutovg_rle_rasterize(plutovg_rle_t * rle, const plutovg_path * path, const plutovg_matrix_t * matrix, const plutovg_rect_t * clip, const plutovg_stroke_data_t * stroke, plutovg_fill_rule_t winding) Line 268	C
    lunasvgtest.exe!plutovg_fill_preserve(plutovg * pluto) Line 464	C
    lunasvgtest.exe!plutovg_fill(plutovg * pluto) Line 426	C
    lunasvgtest.exe!lunasvg::Canvas::fill(const lunasvg::Path & path, const lunasvg::Transform & transform, lunasvg::WindRule winding, lunasvg::BlendMode mode, double opacity) Line 111	C++
    lunasvgtest.exe!lunasvg::FillData::fill(lunasvg::RenderState & state, const lunasvg::Path & path) Line 332	C++
    lunasvgtest.exe!lunasvg::LayoutShape::render(lunasvg::RenderState & state) Line 409	C++
    lunasvgtest.exe!lunasvg::LayoutContainer::renderChildren(lunasvg::RenderState & state) Line 88	C++
    lunasvgtest.exe!lunasvg::LayoutGroup::render(lunasvg::RenderState & state) Line 180	C++
    lunasvgtest.exe!lunasvg::LayoutContainer::renderChildren(lunasvg::RenderState & state) Line 88	C++
    lunasvgtest.exe!lunasvg::LayoutSymbol::render(lunasvg::RenderState & state) Line 160	C++
    lunasvgtest.exe!lunasvg::Document::render(lunasvg::Bitmap bitmap, const lunasvg::Matrix & matrix, unsigned int backgroundColor) Line 212	C++

    lunasvgtest.exe!lunasvg::to_plutovg_path(plutovg * pluto, const lunasvg::Path & path) Line 293	C++
    lunasvgtest.exe!lunasvg::Canvas::fill(const lunasvg::Path & path, const lunasvg::Transform & transform, lunasvg::WindRule winding, lunasvg::BlendMode mode, double opacity) Line 106	C++
    lunasvgtest.exe!lunasvg::FillData::fill(lunasvg::RenderState & state, const lunasvg::Path & path) Line 332	C++
    lunasvgtest.exe!lunasvg::LayoutShape::render(lunasvg::RenderState & state) Line 409	C++
    lunasvgtest.exe!lunasvg::LayoutContainer::renderChildren(lunasvg::RenderState & state) Line 88	C++
    lunasvgtest.exe!lunasvg::LayoutGroup::render(lunasvg::RenderState & state) Line 180	C++
    lunasvgtest.exe!lunasvg::LayoutContainer::renderChildren(lunasvg::RenderState & state) Line 88	C++
    lunasvgtest.exe!lunasvg::LayoutSymbol::render(lunasvg::RenderState & state) Line 160	C++
    lunasvgtest.exe!lunasvg::Document::render(lunasvg::Bitmap bitmap, const lunasvg::Matrix & matrix, unsigned int backgroundColor) Line 212	C++

    lunasvgtest.exe!plutovg_matrix_map_point(const plutovg_matrix_t * matrix, const plutovg_point_t * src, plutovg_point_t * dst) Line 128	C
    lunasvgtest.exe!sw_ft_outline_convert(const plutovg_path * path, const plutovg_matrix_t * matrix) Line 108	C
    lunasvgtest.exe!plutovg_rle_rasterize(plutovg_rle_t * rle, const plutovg_path * path, const plutovg_matrix_t * matrix, const plutovg_rect_t * clip, const plutovg_stroke_data_t * stroke, plutovg_fill_rule_t winding) Line 268	C
    lunasvgtest.exe!plutovg_fill_preserve(plutovg * pluto) Line 464	C
    lunasvgtest.exe!plutovg_fill(plutovg * pluto) Line 426	C

Elements:
    anchor

Attribute:
    grid-fit - fit potentially multiple points via scaling (stretch/scale) to display pixel grid
    grid-align - align via translation to display pixel grid, passing an anchor name or coordinates.
    grid-origin - relative origin in user coordinates. When anchor names are given, it's relative to the snapped position, not the original.
    grid-offset - adjustment in device pixels, such as shifting to a half pixel.
    grid-scale - multiplier for the device grid, such as rounding to every half pixel instead.
    grid-rounding - left/right/up/down/in/out/floor/ceil/to-infinity/to-zero
    anchors - list of relative anchors for a path

Example:
    Grid alignment cannot be part of transform() as browsers (Chrome and Edge anyway) ignore the entire transform attribute upon seenig any unrecognized calls, ruining forwards compatibility with older clients (e.g. transform="grid-align(plusSignCenter) translate(13 24)" ignores the translate).

        <!-- icons8-fluency-add-ot-clipboard-4-sizes.svg -->
        <anchor id="plusSignTopLeftCorner" x="37.5" y="37.5" grid-rounding="up left">
        <g grid-align="plusSignTopLeftCorner">
            <anchor id="plusSignCenter" x="38" y="38" grid-rounding="nearest" grid-multiple="0.5"/><!-- round to nearest half pixel -->
            <g grid-align="plusSignCenter">
                <circle cx="38" cy="38" r="10"/>
                <path d="m 38.5,43 h -1 C 37.224,43 37,42.776 37,42.5 v -9 C 37,33.224 37.224,33 37.5,33 h 1 c 0.276,0 0.5,0.224 0.5,0.5 v 9 c 0,0.276 -0.224,0.5 -0.5,0.5 z" fill="#FFFFFF">
                <path d="m 33,38.5 v -1 C 33,37.224 33.224,37 33.5,37 h 9 c 0.276,0 0.5,0.224 0.5,0.5 v 1 c 0,0.276 -0.224,0.5 -0.5,0.5 h -9 C 33.224,39 33,38.776 33,38.5 z" fill="#FFFFFF">

                ...
                <!-- 3 anchors are used in the path for displacement.
                     Multiple anchors can apply to multiple points,
                     such as leftPart (#0) and anotherPart (#2) applying to the last point. -->
                <path anchors="leftPart rightPart anotherPart" d="m 10 10 h20 v20 z" ext:d="an0 m 10 10 an1 h20 an0 2 v20 z"/>
            </g>
        </g>

    One anchor can be defined relative to another one.
    Below, the bottom component is kept at least 1 pixel away from the top component so there is separation between them.
    todo: second anchor is relative to the rounded location rather than user coordinates, right?
    todo: should I use an explicit attribute like grid-minimum="1px" instead of rounding, that way nearest can be used?
    todo: what if you want *exactly* 1 device pixel regardless of size, not just a minimum? round up combined with minimum?
    todo: what about 45 degree angles, so that two octagons keep the same distance from each other? It's okay if the corners
    todo: should origin be the final device pixels or the user coordinates? rounding to nearest half pixel would be useful, e.g. grid-origin="0.5px 0.5px"
          are antialiased if the straight lines are snapped, and probably more important they have the same relative thickness.
          A grid-rounding attribute like "tangential" or "linear" or "fromOrigin" or "alongOriginAxis"...?

        <anchor id="topComponentBottomAnchor" y="40" grid-rounding="nearest">
        <anchor id="bottomComponentTopAnchor" y="41" grid-rounding="down" grid-origin="topComponentBottomAnchor"><!-- ensure at least one pixel away -->
        <path id="topComponent" anchors="topComponentBottomAnchor" d="an m0 0 h80 an0 v40 h-80 z"/><!-- first "an" sets to no anchors, second "an" sets anchor -->
        <path id="bottomComponent" anchors="bottomComponentTopAnchor" d="an0 m0 41 h80 an v40 h-80 z"/><!-- first "an" sets anchor, second "an" resets to no anchors -->

    todo: Can you just declare values inline with shorthand, rather than require anchor?

        <g grid-align="37.5 37.5 halves-up fraction-left">

    Referring to the same anchor twice in a nested group will be a nop, since the outer group
    already aligned the anchor.

        <anchor id="plusSignTopLeftCorner" x="37.5" y="37.5" grid-rounding="up left">
        <g grid-align="plusSignTopLeftCorner">
            <g grid-align="plusSignTopLeftCorner"><!-- nop since already pixel aligned -->
                <path d="m 10 10 h20 v20 z"/>
            </g>
        </g>

    You should be able to stretch components too between the bounds, which translates to a tranform scale and translate:

        <anchor id="topLeftCorner" x="40" y="40" grid-rounding="up left">
        <anchor id="bottomRightCorner" x="60" y="60" grid-rounding="down right">
        <g grid-fit="topLeftCorner bottomRightCorner">
            <circle cx="50" cy="50" r="10"/>
        </g>

    Minimum stroke:
        <circle cx="50" cy="50" r="10" stroke="#70F800" stroke-width="3" minimum-stroke-width="1px"/>

Related:
    WPF SnapsToDevicePixels and UseLayoutRounding. https://blog.benoitblanchon.fr/wpf-blurry-images/
    WPF GuidelineSets https://www.wpftutorial.net/DrawOnPhysicalDevicePixels.html
    Images and Icons for Visual Studio https://docs.microsoft.com/en-us/visualstudio/extensibility/ux-guidelines/images-and-icons-for-visual-studio?view=vs-2022
    
    Microsoft W3C rep for SVG https://github.com/atanassov, https://www.w3.org/groups/wg/svg/participants
    SVG specification https://github.com/w3c/svgwg/tree/master
    TrueType hinting is overkill https://docs.microsoft.com/en-us/typography/opentype/spec/ttch01

    For computing ppuc along minimum axis, think of computing the minor axis length along a sheared/rotated ellipse.
      Possibly use matrix inverse and rotate a point to axis aligned unit vector? [a b; c d] Possibly det = a*d - b*c. 2D inverse = [d -b; -c a] / det.
      Possibly use eigen vector?
      Possibly just check x and y after rotating the transform back to axis alignment?
*/

#include "precomp.h"
#include "LunaSvgTest.h"

#include "lunasvg.h"

constexpr size_t MAX_LOADSTRING = 100;
// Global Variables:
HINSTANCE g_instanceHandle;                     // current process instance
HWND g_windowHandle;
WCHAR szTitle[MAX_LOADSTRING];                  // The title bar text
WCHAR szWindowClass[MAX_LOADSTRING];            // the main window class name
const HBRUSH g_backgroundWindowBrush = HBRUSH(COLOR_3DFACE+1);

enum class BitmapSizingDisplay
{
    SingleSize,
    WindowSize,
    Waterfall,
    Natural,
};

enum class BackgroundColorMode
{
    TransparentBlack,
    GrayCheckerboard,
    OpaqueWhite,
    OpaqueGray,
};

std::vector<std::unique_ptr<lunasvg::Document>> g_svgDocuments;
std::vector<std::wstring> g_filenameList;
lunasvg::Bitmap g_bitmap;
bool g_svgNeedsRedrawing = true;

const uint32_t g_waterfallBitmapSizes[] = {16,20,24,28,32,40,48,56,64,80,96,112,128,160,192,224,256};
const uint32_t g_waterfallBitmapWidth = 832;
const uint32_t g_waterfallBitmapHeight = 400;
const uint32_t g_zoomFactors[] = {1,2,4,8,16};
const uint32_t g_gridSizes[] = {1,2,3,4,5,6,7,8,12,16,24,32};
const uint32_t g_bitmapScrollStep = 64;

unsigned int g_bitmapSizePerDocument = 16; // in pixels
BitmapSizingDisplay g_bitmapSizingDisplay = BitmapSizingDisplay::Waterfall;
BackgroundColorMode g_backgroundColorMode = BackgroundColorMode::GrayCheckerboard;
uint32_t g_bitmapPixelZoom = 1;
uint32_t g_gridSize = 8;
uint32_t g_bitmapXOffset = 0; // In effective screen pixels (in terms of g_bitmapPixelZoom) rather than g_bitmap pixels.
uint32_t g_bitmapYOffset = 0; // In effective screen pixels (in terms of g_bitmapPixelZoom) rather than g_bitmap pixels.
bool g_invertColors = false;
bool g_gridVisible = false;

// Forward declarations of functions included in this code module:
ATOM RegisterMainWindowClass(HINSTANCE hInstance);
BOOL InitializeInstance(HINSTANCE, int);
LRESULT CALLBACK WindowProcedure(HWND, UINT, WPARAM, LPARAM);
INT_PTR CALLBACK AboutDialogProcedure(HWND, UINT, WPARAM, LPARAM);
void LoadSvgFile(const wchar_t* filePath);
void RedrawSvgLater(HWND hWnd);
void RedrawSvg(HWND hWnd);

struct PixelBgra
{
    uint8_t b;
    uint8_t g;
    uint8_t r;
    uint8_t a;
};


int APIENTRY wWinMain(
    _In_ HINSTANCE instanceHandle,
    _In_opt_ HINSTANCE previousInstance,
    _In_ LPWSTR commandLine,
    _In_ int nCmdShow
    )
{
    UNREFERENCED_PARAMETER(previousInstance);
    UNREFERENCED_PARAMETER(commandLine);

    // Parse parameters.
    wchar_t fileName[MAX_PATH];
    fileName[0] = 0;
    int argumentCount = 0;
    wchar_t** arguments = CommandLineToArgvW(GetCommandLine(), &argumentCount);
    if (arguments != nullptr && argumentCount > 1)
    {
        wcsncpy_s(fileName, arguments[1], wcslen(arguments[1]));
        LocalFree(arguments);
    }

    // Initialize global strings.
    LoadStringW(instanceHandle, IDS_APP_TITLE, szTitle, MAX_LOADSTRING);
    LoadStringW(instanceHandle, IDC_LUNASVGTEST, szWindowClass, MAX_LOADSTRING);
    RegisterMainWindowClass(instanceHandle);

    // Perform application initialization:
    if (!InitializeInstance(instanceHandle, nCmdShow))
    {
        return FALSE;
    }

    // Load the file name if given.
    if (fileName[0])
    {
        LoadSvgFile(fileName);
        RedrawSvgLater(g_windowHandle);
    }

    HACCEL hAccelTable = LoadAccelerators(instanceHandle, MAKEINTRESOURCE(IDC_LUNASVGTEST));

    MSG msg;

    // Main message loop:
    while (GetMessage(&msg, nullptr, 0, 0))
    {
        if (!TranslateAccelerator(msg.hwnd, hAccelTable, &msg))
        {
            TranslateMessage(&msg);
            DispatchMessage(&msg);
        }
    }

    return (int) msg.wParam;
}


ATOM RegisterMainWindowClass(HINSTANCE instanceHandle)
{
    WNDCLASSEXW wcex;

    wcex.cbSize = sizeof(WNDCLASSEX);

    wcex.style          = CS_HREDRAW | CS_VREDRAW | CS_DBLCLKS;
    wcex.lpfnWndProc    = &WindowProcedure;
    wcex.cbClsExtra     = 0;
    wcex.cbWndExtra     = 0;
    wcex.hInstance      = instanceHandle;
    wcex.hIcon          = LoadIcon(instanceHandle, MAKEINTRESOURCE(IDI_LUNASVGTEST));
    wcex.hCursor        = LoadCursor(nullptr, IDC_ARROW);
    wcex.hbrBackground  = g_backgroundWindowBrush;
    wcex.lpszMenuName   = MAKEINTRESOURCEW(IDC_LUNASVGTEST);
    wcex.lpszClassName  = szWindowClass;
    wcex.hIconSm        = wcex.hIcon;

    return RegisterClassExW(&wcex);
}

//   FUNCTION: InitializeInstance(HINSTANCE, int)
//
//   PURPOSE: Saves instance handle and creates main window
//
//   COMMENTS:
//        In this function, we save the instance handle in a global variable and
//        create and display the main program window.
//
BOOL InitializeInstance(HINSTANCE instanceHandle, int nCmdShow)
{
    g_instanceHandle = instanceHandle; // Store instance handle in our global variable

    HWND hwnd = CreateWindowExW(
        WS_EX_ACCEPTFILES,
        szWindowClass,
        szTitle,
        WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT,
        0,
        CW_USEDEFAULT,
        0,
        nullptr,
        nullptr,
        instanceHandle,
        nullptr
    );

    if (!hwnd)
    {
        return FALSE;
    }

    ShowScrollBar(hwnd, SB_BOTH, true);

    ShowWindow(hwnd, nCmdShow);
    UpdateWindow(hwnd);

    g_windowHandle = hwnd;

    return TRUE;
}

template <typename T>
std::tuple<bool, T> FindAdjustedValue(std::span<const T> valueList, T currentValue, size_t delta)
{
    assert(!valueList.empty());
    auto it = std::lower_bound(valueList.begin(), valueList.end(), currentValue);
    ptrdiff_t index = (it - valueList.begin()) + delta;
    if (size_t(index) >= valueList.size())
    {
        return {false, currentValue};
    }
    else
    {
        return {true, valueList[index]};
    }
}


void SetScrollbars(
    HWND hwnd,
    uint32_t xMin,
    uint32_t xMax,
    uint32_t xPage,
    uint32_t xPos,
    uint32_t yMin,
    uint32_t yMax,
    uint32_t yPage,
    uint32_t yPos
    )
{
    SCROLLINFO scrollInfo =
    {
        sizeof(scrollInfo), // cbSize
        SIF_DISABLENOSCROLL|SIF_PAGE|SIF_POS|SIF_RANGE, // fMask
        int(yMin), // nMin
        int(yMax), // nMax
        yPage, // nPage
        int(yPos), // nPos
        0, // nTrackPos
    };
    SetScrollInfo(hwnd, SB_VERT, &scrollInfo, /*redraw*/ true);

    scrollInfo.nMin = xMin;
    scrollInfo.nMax = xMax;
    scrollInfo.nPage = xPage;
    scrollInfo.nPos = xPos;
    SetScrollInfo(hwnd, SB_HORZ, &scrollInfo, /*redraw*/ true);
}


uint32_t HandleScrollbar(HWND hwnd, uint32_t scrollBarCode, uint32_t scrollBarType, int32_t lineSize)
{
    // Why do we have to repeat this function for something that should be built into Windows?
    SCROLLINFO scrollInfo = {sizeof(scrollInfo), SIF_ALL};
    GetScrollInfo(hwnd, scrollBarType, &scrollInfo);  // get information about the scroll
    int32_t newPosition = scrollInfo.nPos;

    switch (scrollBarCode)
    {
    case SB_BOTTOM:
        newPosition = 0;
        break;

    case SB_LINEDOWN:
        newPosition += lineSize;
        break;

    case SB_LINEUP:
        newPosition -= lineSize;
        break;

    case SB_PAGEDOWN:
        newPosition += scrollInfo.nPage;
        break;

    case SB_PAGEUP:
        newPosition -= scrollInfo.nPage;
        break;

    case SB_THUMBTRACK:
    case SB_THUMBPOSITION:
        newPosition = scrollInfo.nTrackPos;
        break;

    case SB_TOP:
        newPosition = 0;
        break;

    case SB_ENDSCROLL:
    default:
        return newPosition;
    }

    newPosition = std::min(newPosition, int32_t(scrollInfo.nMax - scrollInfo.nPage + 1));
    newPosition = std::max(newPosition, 0);

    scrollInfo.fMask = SIF_POS;
    scrollInfo.nPos = newPosition;
    SetScrollInfo(hwnd, scrollBarType, &scrollInfo,/*redraw*/ true);

    return newPosition;
}


#if INCLUDE_PREMULTIPY_FUNCTIONAL_TEST
void PremultiplyBgraData(uint8_t* pixels, uint32_t pixelByteCount)
{
    uint8_t* data = g_bitmap.data();
    for (uint32_t i = 0; i < pixelByteCount; i += 4)
    {
        data[i + 0] = data[i + 0] * data[i + 3] / 255;
        data[i + 1] = data[i + 1] * data[i + 3] / 255;
        data[i + 2] = data[i + 2] * data[i + 3] / 255;
    }
}

void Unpremultiply1(
    lunasvg::Bitmap& bitmap,
    int ri,
    int gi,
    int bi,
    int ai,
    bool unpremultiply
    )
{
    const uint32_t width = bitmap.width();
    const uint32_t height = bitmap.height();
    const uint32_t stride = bitmap.stride();
    auto rowData = bitmap.data();

    // warning C4018: '<': signed/unsigned mismatch
    for (uint32_t y = 0; y < height; ++y)
    {
        auto data = rowData;
        for (uint32_t x = 0; x < width; ++x)
        {
            auto b = data[0];
            auto g = data[1];
            auto r = data[2];
            auto a = data[3];

            if (unpremultiply && a != 0)
            {
                r = (r * 255) / a;
                g = (g * 255) / a;
                b = (b * 255) / a;
            }

            //data[ri] = r;
            //data[gi] = g;
            //data[bi] = b;
            //data[ai] = a;
            data[0] = b;
            data[1] = g;
            data[2] = r;
            data[3] = a;
            data += 4;
        }
        rowData += stride;
    }
}


void Unpremultiply2(
    lunasvg::Bitmap& bitmap,
    int ri,
    int gi,
    int bi,
    int ai,
    bool unpremultiply
    )
{
    const uint32_t width = bitmap.width();
    const uint32_t height = bitmap.height();
    const uint32_t stride = bitmap.stride();
    auto rowData = bitmap.data();

    for (uint32_t y = 0; y < height; ++y)
    {
        auto data = rowData;
        for (uint32_t x = 0; x < width; ++x)
        {
            auto b = data[0];
            auto g = data[1];
            auto r = data[2];
            auto a = data[3];

            uint32_t adjustedA = a - 1;
            //if (unpremultiply && adjustedA <= 254)
            // 282ms vs 200ms
            if (unpremultiply && a != 0)
            {
                uint32_t f = (16777215 / a);
                r = (r * f) >> 16;
                g = (g * f) >> 16;
                b = (b * f) >> 16;
                //r = (r * 255) / a;
                //g = (g * 255) / a;
                //b = (b * 255) / a;
            }

            //data[ri] = r;
            //data[gi] = g;
            //data[bi] = b;
            //data[ai] = a;
            data[0] = b;
            data[1] = g;
            data[2] = r;
            data[3] = a;
            data += 4;
        }
        rowData += stride;
    }
}


void Unpremultiply3(
    lunasvg::Bitmap& bitmap,
    int ri,
    int gi,
    int bi,
    int ai,
    bool unpremultiply
    )
{
    const uint32_t width = bitmap.width();
    const uint32_t height = bitmap.height();
    const uint32_t stride = bitmap.stride();
    auto rowData = bitmap.data();
    uint8_t alphaTable[256][256];

    for (uint32_t i = 0; i < 255; ++i)
    {
        alphaTable[i][0] = i;
    }
    for (uint32_t i = 0; i < 255; ++i)
    {
        for (uint32_t a = 1; a < 256; ++a)
        {
            alphaTable[i][a] = (i * 255) / a;
        }
    }

    for (uint32_t y = 0; y < height; ++y)
    {
        auto data = rowData;
        for (uint32_t x = 0; x < width; ++x)
        {
            auto b = data[0];
            auto g = data[1];
            auto r = data[2];
            auto a = data[3];

            if (unpremultiply && a != 0)
            {
                r = alphaTable[r][a];
                g = alphaTable[g][a];
                b = alphaTable[b][a];
            }

            //data[ri] = r;
            //data[gi] = g;
            //data[bi] = b;
            //data[ai] = a;
            data[0] = b;
            data[1] = g;
            data[2] = r;
            data[3] = a;
            data += 4;
        }
        rowData += stride;
    }
}
#endif


void DrawBitmapGrid(
    HDC hdc,
    int32_t xOffset,
    int32_t yOffset,
    uint32_t width,
    uint32_t height,
    uint32_t xSpacing,
    uint32_t ySpacing
)
{
    for (int32_t x = xOffset; x < int32_t(width); x += xSpacing)
    {
        Rectangle(hdc, x, yOffset, x + 1, yOffset + height);
    }
    for (int32_t y = yOffset; y < int32_t(height); y += ySpacing)
    {
        Rectangle(hdc, xOffset, y, xOffset + width, y + 1);
    }
}


void NegateBitmap(lunasvg::Bitmap& bitmap)
{
    const uint32_t width = bitmap.width();
    const uint32_t height = bitmap.height();
    const uint32_t stride = bitmap.stride();
    auto rowData = bitmap.data();

    for (uint32_t y = 0; y < height; ++y)
    {
        auto data = rowData;
        for (uint32_t x = 0; x < width; ++x)
        {
            auto b = data[0];
            auto g = data[1];
            auto r = data[2];
            auto a = data[3];
            b = a - b;
            g = a - g;
            r = a - r;
            data[0] = b;
            data[1] = g;
            data[2] = r;
            data[3] = a;
            data += 4;
        }
        rowData += stride;
    }
}


const uint32_t g_smallDigitHeight = 7;
const uint32_t g_smallDigitWidth = 5;
const uint32_t g_smallDigitAdvance = 3;
const uint8_t g_smallDigitPixels[10][g_smallDigitHeight][g_smallDigitWidth] =
{
    { // 0
        {0,1,1,1,0},
        {1,2,3,2,1},
        {1,3,1,3,1},
        {1,3,1,3,1},
        {1,3,1,3,1},
        {1,2,3,2,1},
        {0,1,1,1,0},
    },
    { // 1
        {0,0,1,0,0},
        {0,1,3,1,0},
        {1,2,3,1,0},
        {0,1,3,1,0},
        {0,1,3,1,0},
        {1,2,3,2,1},
        {0,1,1,1,0},
    },
    { // 2
        {0,1,1,1,0},
        {1,3,3,2,1},
        {0,1,1,3,1},
        {0,1,3,1,0},
        {1,3,1,1,0},
        {1,3,3,3,1},
        {0,1,1,1,0},
    },
    { // 3
        {0,1,1,0,0},
        {1,3,3,1,0},
        {0,1,1,3,1},
        {1,3,3,2,1},
        {0,1,1,3,1},
        {1,3,3,1,0},
        {0,1,1,0,0},
    },
    { // 4
        {0,1,0,1,0},
        {1,3,1,3,1},
        {1,3,1,3,1},
        {1,3,3,3,1},
        {0,1,1,3,1},
        {0,0,1,3,1},
        {0,0,0,1,0},
    },
    { // 5
        {0,1,1,1,0},
        {1,3,3,3,1},
        {1,3,1,1,0},
        {1,3,3,1,0},
        {0,1,1,3,1},
        {1,3,3,1,0},
        {0,1,1,0,0},
    },
    { // 6
        {0,1,1,1,0},
        {1,2,3,3,1},
        {1,3,1,1,0},
        {1,3,3,2,1},
        {1,3,1,3,1},
        {1,2,3,2,1},
        {0,1,1,1,0},
    },
    { // 7
        {0,1,1,1,0},
        {1,3,3,3,1},
        {0,1,1,3,1},
        {0,0,1,3,1},
        {0,1,3,1,0},
        {0,1,3,1,0},
        {0,0,1,0,0},
    },
    { // 8
        {0,1,1,1,0},
        {1,2,3,2,1},
        {1,3,1,3,1},
        {1,2,3,2,1},
        {1,3,1,3,1},
        {1,2,3,2,1},
        {0,1,1,1,0},
    },
    { // 9
        {0,1,1,1,0},
        {1,2,3,2,1},
        {1,3,1,3,1},
        {0,1,3,3,1},
        {0,0,1,3,1},
        {0,0,1,3,1},
        {0,0,0,1,0},
    },
};

void DrawSmallDigits(
    uint8_t* pixels, // BGRA
    const unsigned char* digits,
    uint32_t digitCount,
    uint32_t x,
    uint32_t y,
    uint32_t width,
    uint32_t height,
    uint32_t byteStridePerRow
    )
{
    if (y + g_smallDigitHeight > height)
    {
        return;
    }

    // transparent, black, gray, white.
    const uint32_t digitPixelColors[4] = { 0x00000000, 0xFF000000, 0xFFC0C0C0, 0xFFFFFFFF };

    pixels += y * byteStridePerRow;
    const uint32_t rowByteDelta = byteStridePerRow - (g_smallDigitWidth * sizeof(uint32_t));

    for (uint32_t digitIndex = 0; digitIndex < digitCount; ++digitIndex)
    {
        if (x + g_smallDigitWidth > width)
        {
            return;
        }

        uint32_t digit = digits[digitIndex] - '0';
        const uint8_t* digitPixels = &g_smallDigitPixels[std::min(digit, 9u)][0][0];
        uint8_t* pixel = pixels + x * sizeof(uint32_t);
        for (uint32_t j = 0; j < g_smallDigitHeight; ++j)
        {
            for (uint32_t i = 0; i < g_smallDigitWidth; ++i)
            {
                // Check for transparency (0), black (1), or white (2).
                uint32_t digitPixelValue = *digitPixels;
                if (digitPixelValue > 0)
                {
                    assert(digitPixelValue < std::size(digitPixelColors));
                    *reinterpret_cast<uint32_t*>(pixel) = digitPixelColors[digitPixelValue];
                }
                pixel += sizeof(uint32_t);
                ++digitPixels;
            }
            pixel += rowByteDelta;
        }

        x += g_smallDigitAdvance + 1;
    }
}


lunasvg::Matrix GetMatrixForSize(lunasvg::Document& document, uint32_t width, uint32_t height)
{
    auto documentWidth = document.width();
    auto documentHeight = document.height();
    if (documentWidth == 0.0 || documentHeight == 0.0)
    {
        return {};
    }

    double actualWidth = width;
    double actualHeight = height;
    if (width == 0 && height == 0)
    {
        actualWidth = documentWidth;
        actualHeight = documentHeight;
    }
    else if (width != 0 && height == 0)
    {
        actualHeight = actualWidth * documentHeight / documentWidth;
    }
    else if (height != 0 && width == 0)
    {
        actualWidth = actualHeight * documentWidth / documentHeight;
    }

    lunasvg::Matrix matrix{actualWidth / documentWidth, 0, 0, actualHeight / documentHeight, 0, 0};
    return matrix;
}


lunasvg::Matrix GetMatrixForSize(lunasvg::Document& document, uint32_t minimumSize)
{
    auto documentWidth = document.width();
    auto documentHeight = document.height();
    if (documentWidth == 0.0 || documentHeight == 0.0)
    {
        return {};
    }
    auto largerDocumentSize = std::max(documentWidth, documentHeight);
    lunasvg::Matrix matrix{minimumSize / largerDocumentSize, 0, 0, minimumSize / largerDocumentSize, 0, 0};
    return matrix;
}


void DrawCheckerboardBackgroundUnderneath(
    uint8_t* pixels, // BGRA
    uint32_t x,
    uint32_t y,
    uint32_t width,
    uint32_t height,
    uint32_t byteStridePerRow
    )
{
    struct PixelBgra
    {
        uint8_t b;
        uint8_t g;
        uint8_t r;
        uint8_t a;
    };

    //blend(source, dest)  =  source.rgb + (dest.rgb * (1 - source.a))
    const uint32_t rowByteDelta = byteStridePerRow - (width * sizeof(uint32_t));
    uint8_t* pixel = pixels + y * byteStridePerRow + x * sizeof(uint32_t);

    for (uint32_t j = 0; j < height; ++j)
    {
        for (uint32_t i = 0; i < width; ++i)
        {
            const PixelBgra backgroundColor = ((i & 8) ^ (j & 8)) ? PixelBgra{0x20, 0x20, 0x20, 0xFF} : PixelBgra{0x40, 0x40, 0x40, 0xFF};
            const PixelBgra bitmapColor = *reinterpret_cast<PixelBgra const*>(pixel);
            const uint32_t bitmapAlpha = bitmapColor.a;
            const uint32_t inverseBitmapAlpha = 255 - bitmapAlpha;
            
            uint32_t blue  = (inverseBitmapAlpha * backgroundColor.b / 255) + bitmapColor.b;
            uint32_t green = (inverseBitmapAlpha * backgroundColor.g / 255) + bitmapColor.g;
            uint32_t red   = (inverseBitmapAlpha * backgroundColor.r / 255) + bitmapColor.r;
            uint32_t alpha = (inverseBitmapAlpha * backgroundColor.a / 255) + bitmapColor.a;
            uint32_t pixelValue = (blue << 0) | (green << 8) | (red << 16) | (alpha << 24);
            
            // blend(source, dest) =  source.bgra + (dest.bgra * (1 - source.a))
            assert(pixel >= pixels && pixel < pixels + height * byteStridePerRow);
            *reinterpret_cast<uint32_t*>(pixel) = pixelValue;
            pixel += sizeof(uint32_t);
        }
        pixel += rowByteDelta;
    }
}


void DrawBackgroundColorUnderneath(
    uint8_t* pixels, // BGRA
    uint32_t x,
    uint32_t y,
    uint32_t width,
    uint32_t height,
    uint32_t byteStridePerRow,
    uint32_t backgroundColor // BGRA
    )
{
    PixelBgra bgraColor = *reinterpret_cast<PixelBgra*>(&backgroundColor);

    //blend(source, dest)  =  source.rgb + (dest.rgb * (1 - source.a))
    const uint32_t rowByteDelta = byteStridePerRow - (width * sizeof(uint32_t));
    uint8_t* pixel = pixels + y * byteStridePerRow + x * sizeof(uint32_t);

    for (uint32_t j = 0; j < height; ++j)
    {
        for (uint32_t i = 0; i < width; ++i)
        {
            const PixelBgra bitmapColor = *reinterpret_cast<PixelBgra const*>(pixel);
            const uint32_t bitmapAlpha = bitmapColor.a;
            const uint32_t inverseBitmapAlpha = 255 - bitmapAlpha;
            
            uint32_t blue  = (inverseBitmapAlpha * bgraColor.b / 255) + bitmapColor.b;
            uint32_t green = (inverseBitmapAlpha * bgraColor.g / 255) + bitmapColor.g;
            uint32_t red   = (inverseBitmapAlpha * bgraColor.r / 255) + bitmapColor.r;
            uint32_t alpha = (inverseBitmapAlpha * bgraColor.a / 255) + bitmapColor.a;
            uint32_t pixelValue = (blue << 0) | (green << 8) | (red << 16) | (alpha << 24);
            
            // blend(source, dest) =  source.bgra + (dest.bgra * (1 - source.a))
            assert(pixel >= pixels && pixel < pixels + height * byteStridePerRow);
            *reinterpret_cast<uint32_t*>(pixel) = pixelValue;
            pixel += sizeof(uint32_t);
        }
        pixel += rowByteDelta;
    }
}


void ClearSvgList()
{
    g_svgDocuments.clear();
    g_filenameList.clear();
    g_bitmap = lunasvg::Bitmap();
}


void AppendSingleSvgFile(wchar_t const* fileName)
{
    auto document = lunasvg::Document::loadFromFile(fileName);
    if (document)
    {
        g_svgDocuments.push_back(std::move(document));
        g_filenameList.push_back(fileName);
    }
}


void LoadSvgFile(wchar_t const* fileName)
{
    ClearSvgList();
    AppendSingleSvgFile(fileName);
}


void LoadSvgFiles(std::vector<std::wstring>&& fileList)
{
    auto movedFileList = std::move(fileList);
    ClearSvgList();
    for (auto& fileName : movedFileList)
    {
        AppendSingleSvgFile(fileName.c_str());
    }
}


struct CanvasItem
{
    enum class ItemType
    {
        Size,
        SVG,
    };
    ItemType itemType;
    uint32_t value; // Document index value for SVG or pixel value for Size.
    uint32_t x;
    uint32_t y;
    uint32_t w;
    uint32_t h;
};


void GenerateSvgItems(RECT const& clientRect)
{
    //std::vector<CanvasItem> canvasItems;

#if 0
    constexpr uint32_t maximumSmallDigitNumbers = 4;
    const uint32_t maximumDigitPixelsWide = (g_smallDigitWidth + 1) * maximumSmallDigitNumbers;

    // Draw the image to a bitmap.
    switch (g_bitmapSizingDisplay)
    {
    case BitmapSizingDisplay::SingleSize:
        {
            unsigned int bitmapMaximumWidth = clientRect.right / g_bitmapPixelZoom;

            uint32_t totalDocuments = static_cast<uint32_t>(g_svgDocuments.size());
            uint32_t currentBitmapSize = g_bitmapSizePerDocument;
            uint32_t bitmapsPerRow = std::max(std::min(bitmapMaximumWidth / currentBitmapSize, totalDocuments), 1u);
            uint32_t bitmapsPerColumn = (totalDocuments + bitmapsPerRow - 1) / bitmapsPerRow;
            uint32_t totalBitmapWidth = bitmapsPerRow * currentBitmapSize;
            uint32_t totalBitmapHeight = bitmapsPerColumn * currentBitmapSize;

            uint32_t x = 0, y = 0;
            for (uint32_t documentIndex = 0; documentIndex < totalDocuments; ++documentIndex)
            {
                lunasvg::Document& document = *g_svgDocuments[documentIndex];
            }
        }
        break;

    case BitmapSizingDisplay::Waterfall:
        {
            const uint32_t totalDocuments = static_cast<uint32_t>(g_svgDocuments.size());
            const bool drawNumbersLeft = totalDocuments > 1;
            const bool drawNumbersBelow = !drawNumbersLeft;

            const uint32_t startingX = drawNumbersLeft ? maximumDigitPixelsWide : 0;
            const uint32_t separationY = drawNumbersBelow ? g_smallDigitHeight + 1 : 0;

            // Determine the total bitmap size to display all sizes.
            uint32_t totalBitmapWidth = g_waterfallBitmapWidth;
            uint32_t totalBitmapHeight = g_waterfallBitmapHeight;

            if (totalDocuments > 1)
            {
                totalBitmapWidth = startingX + totalDocuments * std::end(g_waterfallBitmapSizes)[-1];
                totalBitmapHeight = 0;
                for (uint32_t size : g_waterfallBitmapSizes)
                {
                    totalBitmapHeight += size + separationY;
                }
            }

            g_bitmap.reset(totalBitmapWidth, totalBitmapHeight);
            g_bitmap.clear(backgroundColor);
            lunasvg::Bitmap bitmap;

            // Draw each size, left to right, top to bottom.
            uint32_t x = startingX, y = 0, previousSize = 1;
            for (uint32_t size : g_waterfallBitmapSizes)
            {
                for (uint32_t documentIndex = 0; documentIndex < totalDocuments; ++documentIndex)
                {
                    auto& document = g_svgDocuments[documentIndex];
                    // Draw the icon into a subrect of the larger atlas texture,
                    // adjusting the pointer offset while keeping the correct stride.
                }

                previousSize = size;
            }
        }
        break;

    case BitmapSizingDisplay::WindowSize:
        {
            unsigned int bitmapMaximumSize = std::min(clientRect.bottom, clientRect.right) / g_bitmapPixelZoom;
        }
        break;

    case BitmapSizingDisplay::Natural:
        {
            uint32_t documentWidth  = static_cast<uint32_t>(std::ceil(firstDocument.width()));
            uint32_t documentHeight = static_cast<uint32_t>(std::ceil(firstDocument.height()));
            g_bitmap.reset(documentWidth, documentHeight);
        }
        break;
    }

#endif
}


void LayoutSvgItems()
{
    RECT boundingRect = {};
    //std::vector<CanvasItem> canvasItems;
}


void RedrawSvgItems()
{
    //std::vector<CanvasItem> canvasItems;
#if 0
    const uint32_t backgroundColor = 0x00000000u; // Transparent black

    for (const auto& item : canvasItems)
    {
        g_bitmap.reset(totalBitmapWidth, totalBitmapHeight);
        g_bitmap.clear(backgroundColor);
        lunasvg::Bitmap bitmap;

        // Draw each size, left to right, top to bottom.
        switch (item.itemType)
        {
        case CanvasItem::ItemType::Size:
            {
                uint32_t pixelSize = item.value;

                // Draw little digits for icon pixel size.
                if (drawNumbersBelow || (drawNumbersLeft && x == startingX))
                {
                    char digits[maximumSmallDigitNumbers] = {};
                    const auto result = std::to_chars(std::begin(digits), std::end(digits), size);
                    const uint32_t digitCount = static_cast<uint32_t>(result.ptr - std::begin(digits));

                    uint32_t digitX = drawNumbersLeft ?
                        x - g_smallDigitWidth * digitCount : // left of icon
                        x + (size - g_smallDigitWidth * digitCount) / 2; // centered horizontally across icon
                    uint32_t digitY = drawNumbersLeft ?
                        y + (size - g_smallDigitHeight * digitCount) / 2 : // centered vertical across icon
                        y + size + 1; // 1 pixel under icon

                    DrawSmallDigits(
                        g_bitmap.data(),
                        reinterpret_cast<unsigned char*>(digits),
                        digitCount,
                        digitX, 
                        digitY, // y, 1 pixel under icon
                        g_bitmap.width(),
                        g_bitmap.height(),
                        g_bitmap.stride()
                    );
                }
            }
        case CanvasItem::ItemType::SVG:
            {
                auto& document = g_svgDocuments[item.value];
                // Draw the icon into a subrect of the larger atlas texture,
                // adjusting the pointer offset while keeping the correct stride.
                uint32_t pixelOffset = y * g_bitmap.stride() + x * sizeof(uint32_t);
                bitmap.reset(g_bitmap.data() + pixelOffset, size, size, g_bitmap.stride());
                bitmap.clear(backgroundColor);
                auto matrix = GetMatrixForSize(*document, size);
                document->render(bitmap, matrix);
            }
        }
    }

#endif
}


void RedrawSvg(RECT const& clientRect)
{
    if (g_svgDocuments.empty() || !g_svgDocuments.front())
    {
        return;
    }

    lunasvg::Document& firstDocument = *g_svgDocuments.front();

    const uint32_t backgroundColor = 0x00000000u; // Transparent black

    constexpr uint32_t maximumSmallDigitNumbers = 4;
    const uint32_t maximumDigitPixelsWide = (g_smallDigitWidth + 1) * maximumSmallDigitNumbers;

    // Draw the image to a bitmap.
    switch (g_bitmapSizingDisplay)
    {
    case BitmapSizingDisplay::SingleSize:
        {
            unsigned int bitmapMaximumWidth = clientRect.right / g_bitmapPixelZoom;

            uint32_t totalDocuments = static_cast<uint32_t>(g_svgDocuments.size());
            uint32_t currentBitmapSize = g_bitmapSizePerDocument;
            uint32_t bitmapsPerRow = std::max(std::min(bitmapMaximumWidth / currentBitmapSize, totalDocuments), 1u);
            uint32_t bitmapsPerColumn = (totalDocuments + bitmapsPerRow - 1) / bitmapsPerRow;
            uint32_t totalBitmapWidth = bitmapsPerRow * currentBitmapSize;
            uint32_t totalBitmapHeight = bitmapsPerColumn * currentBitmapSize;
            g_bitmap.reset(totalBitmapWidth, totalBitmapHeight);
            g_bitmap.clear(backgroundColor);
            lunasvg::Bitmap bitmap;

            uint32_t x = 0, y = 0;
            for (uint32_t documentIndex = 0; documentIndex < totalDocuments; ++documentIndex)
            {
                if (x + currentBitmapSize > totalBitmapWidth)
                {
                    y += currentBitmapSize;
                    x = 0;
                }
                if (y + currentBitmapSize > totalBitmapHeight)
                {
                    break;
                }

                lunasvg::Document& document = *g_svgDocuments[documentIndex];
                auto matrix = GetMatrixForSize(document, currentBitmapSize);

                // Don't call renderToBitmap() directly because it distorts
                // the aspect ratio, unless the viewport is exactly square.
                //
                // g_bitmap = document.renderToBitmap(bitmapMaximumSize, bitmapMaximumSize, backgroundColor);
                //
                // Compute the matrix ourselves instead, and use that:
                uint32_t pixelOffset = y * g_bitmap.stride() + x * sizeof(uint32_t);
                bitmap.reset(g_bitmap.data() + pixelOffset, currentBitmapSize, currentBitmapSize, g_bitmap.stride());
                document.render(bitmap, matrix);

                x += currentBitmapSize;
            }
        }
        break;

    case BitmapSizingDisplay::Waterfall:
        {
            const uint32_t totalDocuments = static_cast<uint32_t>(g_svgDocuments.size());
            const bool drawNumbersLeft = totalDocuments > 1;
            const bool drawNumbersBelow = !drawNumbersLeft;

            const uint32_t startingX = drawNumbersLeft ? maximumDigitPixelsWide : 0;
            const uint32_t separationY = drawNumbersBelow ? g_smallDigitHeight + 1 : 0;

            // Determine the total bitmap size to display all sizes.
            uint32_t totalBitmapWidth = g_waterfallBitmapWidth;
            uint32_t totalBitmapHeight = g_waterfallBitmapHeight;

            if (totalDocuments > 1)
            {
                totalBitmapWidth = startingX + totalDocuments * std::end(g_waterfallBitmapSizes)[-1];
                totalBitmapHeight = 0;
                for (uint32_t size : g_waterfallBitmapSizes)
                {
                    totalBitmapHeight += size + separationY;
                }
            }

            g_bitmap.reset(totalBitmapWidth, totalBitmapHeight);
            g_bitmap.clear(backgroundColor);
            lunasvg::Bitmap bitmap;

            // Draw each size, left to right, top to bottom.
            uint32_t x = startingX, y = 0, previousSize = 1;
            for (uint32_t size : g_waterfallBitmapSizes)
            {
                if (x + size > totalBitmapWidth || (totalDocuments > 1 && x > startingX))
                {
                    y += previousSize + separationY;
                    x = startingX;
                }
                if (y + size + separationY > totalBitmapHeight)
                {
                    break;
                }

                for (uint32_t documentIndex = 0; documentIndex < totalDocuments; ++documentIndex)
                {
                    auto& document = g_svgDocuments[documentIndex];
                    // Draw the icon into a subrect of the larger atlas texture,
                    // adjusting the pointer offset while keeping the correct stride.
                    uint32_t pixelOffset = y * g_bitmap.stride() + x * sizeof(uint32_t);
                    bitmap.reset(g_bitmap.data() + pixelOffset, size, size, g_bitmap.stride());
                    bitmap.clear(backgroundColor);
                    auto matrix = GetMatrixForSize(*document, size);
                    document->render(bitmap, matrix);

                    // Draw little digits for icon pixel size.
                    if (drawNumbersBelow || (drawNumbersLeft && x == startingX))
                    {
                        char digits[maximumSmallDigitNumbers] = {};
                        const auto result = std::to_chars(std::begin(digits), std::end(digits), size);
                        const uint32_t digitCount = static_cast<uint32_t>(result.ptr - std::begin(digits));

                        uint32_t digitX = drawNumbersLeft ?
                            x - g_smallDigitWidth * digitCount : // left of icon
                            x + (size - g_smallDigitWidth * digitCount) / 2; // centered horizontally across icon
                        uint32_t digitY = drawNumbersLeft ?
                            y + (size - g_smallDigitHeight * digitCount) / 2 : // centered vertical across icon
                            y + size + 1; // 1 pixel under icon

                        DrawSmallDigits(
                            g_bitmap.data(),
                            reinterpret_cast<unsigned char*>(digits),
                            digitCount,
                            digitX, 
                            digitY, // y, 1 pixel under icon
                            g_bitmap.width(),
                            g_bitmap.height(),
                            g_bitmap.stride()
                        );
                    }

                    x += size;
                }

                previousSize = size;
            }
        }
        break;

    case BitmapSizingDisplay::WindowSize:
        {
            unsigned int bitmapMaximumSize = std::min(clientRect.bottom, clientRect.right) / g_bitmapPixelZoom;
            g_bitmap.reset(bitmapMaximumSize, bitmapMaximumSize);
            g_bitmap.clear(backgroundColor);
            auto matrix = GetMatrixForSize(firstDocument, bitmapMaximumSize);
            firstDocument.render(g_bitmap, matrix);
        }
        break;

    case BitmapSizingDisplay::Natural:
        {
            lunasvg::Matrix matrix; // Defaults to identity.
            uint32_t documentWidth  = static_cast<uint32_t>(std::ceil(firstDocument.width()));
            uint32_t documentHeight = static_cast<uint32_t>(std::ceil(firstDocument.height()));
            g_bitmap.reset(documentWidth, documentHeight);
            g_bitmap.clear(backgroundColor);
            firstDocument.render(g_bitmap, matrix);
        }
        break;
    }

    #if INCLUDE_PREMULTIPY_FUNCTIONAL_TEST // hack:::
    // Premultiply pixels so that edges are antialiased.
    // hack:::PremultiplyBgraData(g_bitmap.data(), g_bitmap.stride() * g_bitmap.height());

    SetThreadPriority(GetCurrentThread(), THREAD_PRIORITY_HIGHEST);
    LARGE_INTEGER endTime1, endTime2, endTime3;
    QueryPerformanceCounter(&startTime);

    for (uint32_t i = 0; i < 300; ++i)
        Unpremultiply1(g_bitmap, 2,1,0,3, true);
    QueryPerformanceCounter(&endTime1);

    for (uint32_t i = 0; i < 300; ++i)
        Unpremultiply2(g_bitmap, 2,1,0,3, true);
    QueryPerformanceCounter(&endTime2);

    for (uint32_t i = 0; i < 300; ++i)
        Unpremultiply3(g_bitmap, 2,1,0,3, true);
    QueryPerformanceCounter(&endTime3);
    SetThreadPriority(GetCurrentThread(), THREAD_PRIORITY_NORMAL);

    auto GetDuration = [=](LARGE_INTEGER startTime, LARGE_INTEGER endTime) -> double
    {
        return double(endTime.QuadPart - startTime.QuadPart) * 1000 / double(cpuFrequency.QuadPart);
    };
    double durationMs1 = GetDuration(startTime, endTime1);
    double durationMs2 = GetDuration(endTime1, endTime2);
    double durationMs3 = GetDuration(endTime2, endTime3);
    _snwprintf_s(windowTitle, sizeof(windowTitle), L"%s (%1.6fms, %1.6fms, %1.6fms)", szTitle, durationMs1, durationMs2, durationMs3);
    SetWindowText(hwnd, windowTitle);
    #endif
}

void RedrawSvgBackground()
{
    switch (g_backgroundColorMode)
    {
    case BackgroundColorMode::TransparentBlack:
        // Nothing to do since they were already drawn atop transparent black.
        break;

    case BackgroundColorMode::GrayCheckerboard:
        DrawCheckerboardBackgroundUnderneath(
            g_bitmap.data(),
            0,
            0,
            g_bitmap.width(),
            g_bitmap.height(),
            g_bitmap.stride()
        );
        break;

    case BackgroundColorMode::OpaqueWhite:
    case BackgroundColorMode::OpaqueGray:
        DrawBackgroundColorUnderneath(
            g_bitmap.data(),
            0,
            0,
            g_bitmap.width(),
            g_bitmap.height(),
            g_bitmap.stride(),
            (g_backgroundColorMode == BackgroundColorMode::OpaqueGray) ? 0xFF808080 : /*OpaqueWhite*/ 0xFFFFFFFF
        );
        break;
    }
}


void UpdateBitmapScrollbars(HWND hwnd, const RECT& clientRect)
{
    const uint32_t effectiveBitmapWidth = g_bitmap.width() * g_bitmapPixelZoom;
    const uint32_t effectiveBitmapHeight = g_bitmap.height() * g_bitmapPixelZoom;

    SetScrollbars(
        hwnd,
        0,
        effectiveBitmapWidth,
        clientRect.right,
        g_bitmapXOffset,
        0,
        effectiveBitmapHeight,
        clientRect.bottom,
        g_bitmapYOffset
    );
}


void KeepBitmapInClientRect(HWND hwnd)
{
    RECT clientRect;
    GetClientRect(hwnd, /*out*/&clientRect);
    const uint32_t effectiveBitmapWidth = g_bitmap.width() * g_bitmapPixelZoom;
    const uint32_t effectiveBitmapHeight = g_bitmap.height() * g_bitmapPixelZoom;
    // TODO: Implement
    // g_bitmapXOffset = std::min(g_bitmapXOffset, uint32_t(effectiveBitmapWidth - clientRect.right));
    // g_bitmapYOffset = std::min(g_bitmapYOffset, uint32_t(effectiveBitmapHeight - clientRect.bottom));
}


void RedrawBitmapLater(HWND hwnd)
{
    RECT invalidationRect = {
        -LONG(g_bitmapXOffset),
        -LONG(g_bitmapYOffset),
        LONG(g_bitmap.width()  * g_bitmapPixelZoom) - LONG(g_bitmapXOffset),
        LONG(g_bitmap.height() * g_bitmapPixelZoom) - LONG(g_bitmapYOffset)
    };

    // Force at least one pixel to be invalidated so the WM_PAINT is generated.
    if (!g_bitmap.valid())
    {
        invalidationRect.right = 1;
        invalidationRect.top = 1;
    }
    InvalidateRect(hwnd, &invalidationRect, true);
}


void RedrawSvgLater(HWND hwnd)
{
    g_svgNeedsRedrawing = true;
    RedrawBitmapLater(hwnd);
}


void RedrawSvg(HWND hwnd)
{
    RECT clientRect;
    GetClientRect(hwnd, /*out*/&clientRect);

    LARGE_INTEGER startTime;
    LARGE_INTEGER endTime;
    LARGE_INTEGER cpuFrequency;
    QueryPerformanceFrequency(&cpuFrequency);
    QueryPerformanceCounter(&startTime);

    RedrawSvg(clientRect);

    QueryPerformanceCounter(&endTime);
    double durationMs = static_cast<double>(endTime.QuadPart - startTime.QuadPart);
    durationMs /= static_cast<double>(cpuFrequency.QuadPart);
    durationMs *= 1000.0;
    wchar_t windowTitle[1000];
    wchar_t const* filename = !g_filenameList.empty() ? g_filenameList.front().c_str() : L"";
    _snwprintf_s(windowTitle, sizeof(windowTitle), L"%s (%1.6fms, %ux%u, %s)", szTitle, durationMs, g_bitmap.width(), g_bitmap.height(), filename);
    SetWindowText(hwnd, windowTitle);

    RedrawSvgBackground();
    if (g_invertColors)
    {
        NegateBitmap(g_bitmap);
    }

    RedrawBitmapLater(hwnd);
    g_svgNeedsRedrawing = false;
}


void FillBitmapInfoFromLunaSvgBitmap(
    lunasvg::Bitmap const& bitmap,
    /*out*/ BITMAPV5HEADER& bitmapInfo
    )
{
    bitmapInfo.bV5Size = sizeof(bitmapInfo);
    bitmapInfo.bV5Width = bitmap.width();
    bitmapInfo.bV5Height = -LONG(bitmap.height());
    bitmapInfo.bV5Planes = 1;
    bitmapInfo.bV5BitCount = 32;
    bitmapInfo.bV5Compression = BI_RGB; // BI_BITFIELDS
    bitmapInfo.bV5SizeImage = g_bitmap.stride() * g_bitmap.height();
    bitmapInfo.bV5XPelsPerMeter = 3780;
    bitmapInfo.bV5YPelsPerMeter = 3780;
    bitmapInfo.bV5ClrUsed = 0;
    bitmapInfo.bV5ClrImportant = 0;

    bitmapInfo.bV5RedMask = 0x00FF0000;
    bitmapInfo.bV5GreenMask = 0x0000FF00;
    bitmapInfo.bV5BlueMask = 0x000000FF;
    bitmapInfo.bV5AlphaMask = 0xFF000000;
    bitmapInfo.bV5CSType = 0;// LCS_sRGB;
    bitmapInfo.bV5Endpoints = {};
    bitmapInfo.bV5GammaRed = 0;
    bitmapInfo.bV5GammaGreen = 0;
    bitmapInfo.bV5GammaBlue = 0;
    bitmapInfo.bV5Intent = 0;// LCS_GM_IMAGES;
    bitmapInfo.bV5ProfileData = 0;
    bitmapInfo.bV5ProfileSize = 0;
    bitmapInfo.bV5Reserved = 0;
}


void DrawRectangleAroundRectangle(
    HDC hdc,
    const RECT& outerRect,
    const RECT& innerRect,
    HBRUSH brush
    )
{
    RECT fillRect = outerRect;

    // Top
    fillRect.top = outerRect.top;
    fillRect.bottom = innerRect.top;
    fillRect.left = outerRect.left;
    fillRect.right = outerRect.right;
    FillRect(hdc, &fillRect, g_backgroundWindowBrush);

    // Bottom
    fillRect.top = innerRect.bottom;
    fillRect.bottom = outerRect.bottom;
    // fillRect.left = outerRect.left;
    // fillRect.right = outerRect.right;
    FillRect(hdc, &fillRect, g_backgroundWindowBrush);

    // Left
    fillRect.top = innerRect.top;
    fillRect.bottom = innerRect.bottom;
    fillRect.left = outerRect.left;
    fillRect.right = innerRect.right;
    FillRect(hdc, &fillRect, g_backgroundWindowBrush);

    // Right
    // fillRect.top = innerRect.top;
    // fillRect.bottom = innerRect.bottom;
    fillRect.left = innerRect.left;
    fillRect.right = outerRect.right;
    FillRect(hdc, &fillRect, g_backgroundWindowBrush);
}


void CopySvgBitmapToClipboard(
    lunasvg::Bitmap& bitmap,
    HWND hwnd
    )
{
    if (bitmap.valid())
    {
        if (OpenClipboard(hwnd))
        {
            EmptyClipboard();

            BITMAPV5HEADER bitmapInfo;
            FillBitmapInfoFromLunaSvgBitmap(bitmap, /*out*/bitmapInfo);
            uint32_t totalBytes = sizeof(BITMAPINFO) + bitmapInfo.bV5SizeImage;

            HGLOBAL memory = GlobalAlloc(GMEM_MOVEABLE, totalBytes);
            if (memory != nullptr)
            {
                void* lockedMemory= GlobalLock(memory);
                if (lockedMemory != nullptr)
                {
                    BITMAPINFO& clipboardBitmapInfo = *reinterpret_cast<BITMAPINFO*>(lockedMemory);
                    memcpy(&clipboardBitmapInfo, &bitmapInfo, sizeof(clipboardBitmapInfo));
                    clipboardBitmapInfo.bmiHeader.biSize = sizeof(clipboardBitmapInfo.bmiHeader);
                    uint8_t* clipboardPixels = reinterpret_cast<uint8_t*>(lockedMemory) + sizeof(clipboardBitmapInfo.bmiHeader);
                    memcpy(clipboardPixels, bitmap.data(), bitmapInfo.bV5SizeImage);
                }
                GlobalUnlock(memory);

                SetClipboardData(CF_DIB, memory);
            }
            CloseClipboard();
        }
    }
}


//  FUNCTION: WindowProcedure(HWND, UINT, WPARAM, LPARAM)
//
//  PURPOSE: Processes messages for the main window.
//
//  WM_COMMAND  - process the application menu
//  WM_PAINT    - Paint the main window
//  WM_DESTROY  - post a quit message and return
//
LRESULT CALLBACK WindowProcedure(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    switch (message)
    {
    case WM_COMMAND:
        {
            int wmId = LOWORD(wParam);
            switch (wmId)
            {
            case IDM_ABOUT:
                DialogBox(g_instanceHandle, MAKEINTRESOURCE(IDD_ABOUTBOX), hwnd, &AboutDialogProcedure);
                break;

            case IDM_EXIT:
                DestroyWindow(hwnd);
                break;

            case IDM_OPEN:
                {
                    wchar_t fileNameBuffer[32768];
                    fileNameBuffer[0] = '\0';
                    OPENFILENAME openFileName = {};

                    openFileName.lStructSize = sizeof(openFileName);
                    openFileName.hwndOwner = hwnd;
                    openFileName.hInstance = g_instanceHandle;
                    openFileName.lpstrFilter = L"SVG\0" L"*.svg\0"
                                               L"All files\0" L"*\0"
                                               L"\0";
                    openFileName.lpstrFile = std::data(fileNameBuffer);
                    openFileName.nMaxFile = static_cast<DWORD>(std::size(fileNameBuffer));
                    openFileName.Flags = OFN_EXPLORER | OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST | OFN_HIDEREADONLY | OFN_LONGNAMES | OFN_NOTESTFILECREATE | OFN_ALLOWMULTISELECT;

                    if (GetOpenFileName(&openFileName) && openFileName.nFileOffset > 0)
                    {
                        std::vector<std::wstring> filenameList;
                        std::wstring filePath;

                        // Read all filenames, in case multiple were selected.
                        fileNameBuffer[openFileName.nFileOffset - 1] = '\\'; // Restore missing backslash.
                        for (const wchar_t* fileName = &fileNameBuffer[openFileName.nFileOffset];
                            *fileName && fileName < std::end(fileNameBuffer);
                            /*increment inside loop*/)
                        {
                            // Concatenate the leading path with the filename for each file.
                            size_t fileNameLength = wcslen(fileName);
                            filePath.reserve(openFileName.nFileOffset + fileNameLength);
                            filePath.append(std::data(fileNameBuffer), openFileName.nFileOffset);
                            filePath.append(fileName);
                            filenameList.push_back(std::move(filePath));
                            fileName += fileNameLength + 1;
                        }

                        RedrawSvgLater(hwnd);
                        LoadSvgFiles(std::move(filenameList));
                        RedrawSvgLater(hwnd);
                    }
                }
                break;

            case IDM_RELOAD:
                if (!g_filenameList.empty())
                {
                    LoadSvgFiles(std::move(g_filenameList));
                    RedrawSvgLater(hwnd);
                }
                break;

            case IDM_SIZE0:
            case IDM_SIZE1:
            case IDM_SIZE2:
            case IDM_SIZE3:
            case IDM_SIZE4:
            case IDM_SIZE5:
            case IDM_SIZE6:
            case IDM_SIZE7:
            case IDM_SIZE8:
            case IDM_SIZE9:
            case IDM_SIZE10:
            case IDM_SIZE11:
            case IDM_SIZE12:
            case IDM_SIZE13:
            case IDM_SIZE14:
            case IDM_SIZE15:
            case IDM_SIZE16:
                static_assert(IDM_SIZE16 + 1 - IDM_SIZE0 == _countof(g_waterfallBitmapSizes), "g_waterfallBitmapSizes is not the correct size");
                g_bitmapSizePerDocument = g_waterfallBitmapSizes[wmId - IDM_SIZE0];
                g_bitmapSizingDisplay = BitmapSizingDisplay::SingleSize;
                RedrawSvgLater(hwnd);
                break;

            case IDM_SIZE_WINDOW:
                g_bitmapSizingDisplay = BitmapSizingDisplay::WindowSize;
                RedrawSvgLater(hwnd);
                break;

            case IDM_SIZE_WATERFALL:
                g_bitmapSizingDisplay = BitmapSizingDisplay::Waterfall;
                RedrawSvgLater(hwnd);
                break;

            case IDM_SIZE_NATURAL:
                g_bitmapSizingDisplay = BitmapSizingDisplay::Natural;
                RedrawSvgLater(hwnd);
                break;

            case IDM_ZOOM0:
            case IDM_ZOOM1:
            case IDM_ZOOM2:
            case IDM_ZOOM3:
            case IDM_ZOOM4:
                static_assert(IDM_ZOOM4 + 1 - IDM_ZOOM0 == _countof(g_zoomFactors), "g_zoomFactors is not the correct size");
                RedrawSvgLater(hwnd);
                g_bitmapPixelZoom = g_zoomFactors[wmId - IDM_ZOOM0];
                KeepBitmapInClientRect(hwnd);
                break;

            case IDM_COPY:
                CopySvgBitmapToClipboard(g_bitmap, hwnd);
                break;

            case IDM_COLOR_GRAY_CHECKERBOARD:
            case IDM_COLOR_TRANSPARENT_BLACK:
            case IDM_COLOR_OPAQUE_WHITE:
            case IDM_COLOR_OPAQUE_GRAY:
                static_assert(IDM_COLOR_GRAY_CHECKERBOARD - IDM_COLOR_FIRST == static_cast<uint32_t>(BackgroundColorMode::GrayCheckerboard));
                static_assert(IDM_COLOR_TRANSPARENT_BLACK - IDM_COLOR_FIRST == static_cast<uint32_t>(BackgroundColorMode::TransparentBlack));
                static_assert(IDM_COLOR_OPAQUE_WHITE - IDM_COLOR_FIRST == static_cast<uint32_t>(BackgroundColorMode::OpaqueWhite));
                static_assert(IDM_COLOR_OPAQUE_GRAY - IDM_COLOR_FIRST == static_cast<uint32_t>(BackgroundColorMode::OpaqueGray));

                g_backgroundColorMode = static_cast<BackgroundColorMode>(wmId - IDM_COLOR_FIRST);
                RedrawSvgLater(hwnd);
                break;

            case IDM_INVERT_COLORS:
                g_invertColors = !g_invertColors;
                RedrawSvgLater(hwnd);
                break;

            case IDM_GRID_VISIBLE:
                g_gridVisible = !g_gridVisible;
                RedrawBitmapLater(hwnd);
                break;

            case IDM_GRID_SIZE_1:
            case IDM_GRID_SIZE_2:
            case IDM_GRID_SIZE_3:
            case IDM_GRID_SIZE_4:
            case IDM_GRID_SIZE_5:
            case IDM_GRID_SIZE_6:
            case IDM_GRID_SIZE_7:
            case IDM_GRID_SIZE_8:
            case IDM_GRID_SIZE_12:
            case IDM_GRID_SIZE_16:
            case IDM_GRID_SIZE_24:
            case IDM_GRID_SIZE_32:
                g_gridVisible = true;
                static_assert(IDM_GRID_SIZE_32 + 1 - IDM_GRID_SIZE_1 == _countof(g_gridSizes), "g_gridSizes is not the correct size");
                g_gridSize = g_gridSizes[wmId - IDM_GRID_SIZE_1];
                RedrawBitmapLater(hwnd);
                break;

            default:
                return DefWindowProc(hwnd, message, wParam, lParam);
            }
        }
        break;

    case WM_DROPFILES:
        {
            // Get the filename.
            std::array<wchar_t, MAX_PATH> fileName;
            fileName[0] = '\0';
            HDROP dropHandle = reinterpret_cast<HDROP>(wParam);
            std::vector<std::wstring> filenameList;

            uint32_t fileCount = DragQueryFile(dropHandle, 0xFFFFFFFF, nullptr, 0);
            for (uint32_t fileIndex = 0; fileIndex < fileCount; ++fileIndex)
            {
                if (DragQueryFile(dropHandle, fileIndex, fileName.data(), static_cast<uint32_t>(fileName.size())))
                {
                    filenameList.push_back({fileName.data(), fileName.size()});
                }
            }
            if (!filenameList.empty())
            {
                RedrawSvgLater(hwnd);
                LoadSvgFiles(std::move(filenameList));
                RedrawSvgLater(hwnd);
            }
        }
        break;

    case WM_MENUSELECT:
        {
            uint32_t index = LOWORD(wParam);
            auto hmenu = reinterpret_cast<HMENU>(lParam);
            if (hmenu == nullptr || (HIWORD(wParam) & MF_SYSMENU))
            {
                break;
            }
            // Change this to be data driven, using an array mapping id to corresponding variable address.
            // e.g. {IDM_FILE, IDM_INVERT_COLORS, 0, &g_invertColors}, // CheckMenuItem
            //      {IDM_ZOOM, IDM_ZOOM0, IDM_ZOOM4, &g_bitmapZoom}, // CheckMenuRadioItem
            // todo: map id to more useful id.
            //      https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getmenuitemid
            //      https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getmenu
            switch (index)
            {
            case 2:
                CheckMenuItem(hmenu, IDM_INVERT_COLORS, MF_BYCOMMAND | (g_invertColors ? MF_CHECKED : MF_UNCHECKED));
                break;
            case 5:
                CheckMenuItem(hmenu, IDM_GRID_VISIBLE, MF_BYCOMMAND | (g_gridVisible ? MF_CHECKED : MF_UNCHECKED));
                break;
            }
        }
        break;

    case WM_WINDOWPOSCHANGED:
        if (!(reinterpret_cast<WINDOWPOS*>(lParam)->flags & SWP_NOSIZE))
        {
            RedrawSvgLater(hwnd);
        }
        break;

    case WM_ERASEBKGND:
        return 1;

    case WM_PAINT:
        {
            if (g_svgNeedsRedrawing)
            {
                RedrawSvg(hwnd);
                RECT clientRect;
                GetClientRect(hwnd, /*out*/&clientRect);
                UpdateBitmapScrollbars(hwnd, clientRect);
            }

            PAINTSTRUCT ps;
            HDC hdc = BeginPaint(hwnd, &ps);

            if (g_bitmap.valid())
            {
                BITMAPV5HEADER bitmapInfo = {};
                FillBitmapInfoFromLunaSvgBitmap(g_bitmap, /*out*/ bitmapInfo);

                // Erase background around drawing.
                const uint32_t effectiveBitmapWidth = g_bitmap.width() * g_bitmapPixelZoom;
                const uint32_t effectiveBitmapHeight = g_bitmap.height() * g_bitmapPixelZoom;
                RECT bitmapRect = {
                    -LONG(g_bitmapXOffset),
                    -LONG(g_bitmapYOffset),
                    LONG(effectiveBitmapWidth - g_bitmapXOffset),
                    LONG(effectiveBitmapHeight - g_bitmapYOffset)
                };
                DrawRectangleAroundRectangle(ps.hdc, ps.rcPaint, bitmapRect, g_backgroundWindowBrush);

                #if 1
                if (g_bitmapPixelZoom == 1)
                {
                    SetDIBitsToDevice(
                        ps.hdc,
                        -int(g_bitmapXOffset),
                        -int(g_bitmapYOffset),
                        g_bitmap.width(),
                        g_bitmap.height(),
                        0,
                        0,
                        0,
                        g_bitmap.height(),
                        g_bitmap.data(),
                        reinterpret_cast<BITMAPINFO*>(&bitmapInfo),
                        0 // colorUse
                    );
                }
                else // Scale
                {
                    HBITMAP bitmap = CreateDIBitmap(
                        hdc,
                        reinterpret_cast<BITMAPINFOHEADER*>(&bitmapInfo),
                        CBM_INIT,
                        g_bitmap.data(),
                        reinterpret_cast<BITMAPINFO*>(&bitmapInfo),
                        DIB_RGB_COLORS
                    );
                    HDC sourceHdc = CreateCompatibleDC(ps.hdc);
                    SelectObject(sourceHdc, bitmap);
                    StretchBlt(
                        ps.hdc,
                        -int(g_bitmapXOffset),
                        -int(g_bitmapYOffset),
                        g_bitmap.width() * g_bitmapPixelZoom,
                        g_bitmap.height() * g_bitmapPixelZoom,
                        sourceHdc,
                        0,
                        0,
                        g_bitmap.width(),
                        g_bitmap.height(),
                        SRCCOPY
                    );
                    DeleteDC(sourceHdc);
                    DeleteObject(bitmap);
                }
                #else // Why is GDI so stupidly complicated, lacking a simple DrawBitmap call?
                HBITMAP bitmap = CreateDIBitmap(
                    hdc,
                    reinterpret_cast<BITMAPINFOHEADER*>(&bitmapInfo),
                    CBM_INIT,
                    g_bitmap.data(),
                    reinterpret_cast<BITMAPINFO*>(&bitmapInfo),
                    DIB_RGB_COLORS
                );
                BLENDFUNCTION blendFunction = {};
                blendFunction.BlendOp = AC_SRC_OVER,
                blendFunction.BlendFlags = 0;
                blendFunction.SourceConstantAlpha = 255;
                blendFunction.AlphaFormat = AC_SRC_ALPHA;
                SelectObject(ps.hdc, ...)
                AlphaBlend(
                    ps.hdc,
                    0,
                    0,
                    g_bitmap.width(),
                    g_bitmap.height(),
                    0,
                    0,
                    0,
                    g_bitmap.width(),
                    g_bitmap.height(),
                    blendFunction
                );
                #endif
                const int32_t gridSpacing = g_gridSize * g_bitmapPixelZoom;
                if (g_gridVisible && gridSpacing > 1)
                {
                    DrawBitmapGrid(
                        ps.hdc,
                        -int(g_bitmapXOffset),
                        -int(g_bitmapYOffset),
                        g_bitmap.width() * g_bitmapPixelZoom,
                        g_bitmap.height() * g_bitmapPixelZoom,
                        gridSpacing,
                        gridSpacing
                    );
                }
            }
            else
            {
                // Draw text informing no SVG is loaded.
                FillRect(ps.hdc, &ps.rcPaint, g_backgroundWindowBrush);
                HFONT oldFont = static_cast<HFONT>(SelectObject(ps.hdc, GetStockObject(DEFAULT_GUI_FONT)));
                TextOut(ps.hdc, 0, 0, L"No SVG loaded", _countof(L"No SVG loaded") - 1);
                SelectObject(ps.hdc, oldFont);
            }
            EndPaint(hwnd, &ps);
        }
        break;

    case WM_HSCROLL:
    case WM_VSCROLL:
        {
            const bool isHorizontal = (message == WM_HSCROLL);
            uint32_t& currentOffsetRef = isHorizontal ? g_bitmapXOffset : g_bitmapYOffset;
            const uint32_t previousOffset = currentOffsetRef;
            const uint32_t scrollBarType = isHorizontal ? SB_HORZ : SB_VERT;
            const uint32_t currentOffset = HandleScrollbar(hwnd, LOWORD(wParam), scrollBarType, g_bitmapScrollStep);

            if (previousOffset != currentOffset)
            {
                currentOffsetRef = currentOffset;
                const int32_t offsetDelta = (int32_t(previousOffset) - int32_t(currentOffset));
                RECT updatedRect = {};
                ScrollWindowEx(
                    hwnd,
                    isHorizontal ? offsetDelta : 0,
                    isHorizontal ? 0 : offsetDelta,
                    nullptr, // prcScroll,
                    nullptr, // prcClip,
                    nullptr, // hrgnUpdate,
                    nullptr, // prcUpdate
                    SW_ERASE | SW_INVALIDATE
                );
            }
        }
        break;

    case WM_MOUSEWHEEL:
        if (wParam & MK_CONTROL) // No need for GET_KEYSTATE_WPARAM.
        {
            // Adjust zoom.
            int32_t zDelta = GET_WHEEL_DELTA_WPARAM(wParam);
            RedrawBitmapLater(hwnd);
            auto [valueChanged, newPixelZoom] = FindAdjustedValue<uint32_t>(g_zoomFactors, g_bitmapPixelZoom, zDelta > 0 ? 1 : -1);
            if (valueChanged)
            {
                // Fix mouse coordinates to be window relative.
                POINT mouseCoordinate = {GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam)};
                ScreenToClient(hwnd, &mouseCoordinate);

                // Adjust bitmap x and y appropriately based on mouse cursor.
                const int32_t xOffset = (mouseCoordinate.x + g_bitmapXOffset) / g_bitmapPixelZoom;
                const int32_t yOffset = (mouseCoordinate.y + g_bitmapYOffset) / g_bitmapPixelZoom;
                g_bitmapXOffset = xOffset * newPixelZoom - mouseCoordinate.x;
                g_bitmapYOffset = yOffset * newPixelZoom - mouseCoordinate.y;
                g_bitmapPixelZoom = newPixelZoom;

                RedrawBitmapLater(hwnd);
                RECT clientRect;
                GetClientRect(hwnd, /*out*/&clientRect);
                UpdateBitmapScrollbars(hwnd, clientRect);
            }
        }
        else
        {
            int32_t zDelta = -GET_WHEEL_DELTA_WPARAM(wParam);
            zDelta = zDelta * int32_t(g_bitmapScrollStep) / WHEEL_DELTA;

            // TODO: Consolidate this code with WM_HSCROLL/WM_VSCROLL.
            const bool isHorizontal = (wParam & MK_SHIFT);
            const uint32_t scrollBarType = isHorizontal ? SB_HORZ : SB_VERT;
            uint32_t& currentOffsetRef = isHorizontal ? g_bitmapXOffset : g_bitmapYOffset;
            const uint32_t previousOffset = currentOffsetRef;
            const uint32_t currentOffset = HandleScrollbar(hwnd, SB_LINEDOWN, scrollBarType, zDelta);

            if (previousOffset != currentOffset)
            {
                currentOffsetRef = currentOffset;
                const int32_t offsetDelta = (int32_t(previousOffset) - int32_t(currentOffset));
                RECT updatedRect = {};
                ScrollWindowEx(
                    hwnd,
                    isHorizontal ? offsetDelta : 0,
                    isHorizontal ? 0 : offsetDelta,
                    nullptr, // prcScroll,
                    nullptr, // prcClip,
                    nullptr, // hrgnUpdate,
                    nullptr, // prcUpdate
                    SW_ERASE | SW_INVALIDATE
                );
            }
        }
        break;

    case WM_DESTROY:
        PostQuitMessage(0);
        break;

    default:
        return DefWindowProc(hwnd, message, wParam, lParam);
    }
    return 0;
}

// Message handler for about box.
INT_PTR CALLBACK AboutDialogProcedure(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
    UNREFERENCED_PARAMETER(lParam);
    switch (message)
    {
    case WM_INITDIALOG:
        return (INT_PTR)TRUE;

    case WM_COMMAND:
        if (LOWORD(wParam) == IDOK || LOWORD(wParam) == IDCANCEL)
        {
            EndDialog(hDlg, LOWORD(wParam));
            return (INT_PTR)TRUE;
        }
        break;
    }
    return (INT_PTR)FALSE;
}
