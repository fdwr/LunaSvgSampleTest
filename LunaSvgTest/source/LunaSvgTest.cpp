/*
LunaSvgTest.cpp: Main application.

TODO:

Fix void Canvas::rgba() to use macros. canvas.cpp line 195
    plutovg-private.h
    #define plutovg_alpha_shift 24
    #define plutovg_red_shift 0
    #define plutovg_green_shift 8
    #define plutovg_blue_shift 16

Gridfitting prototype - add extended SVG attributes for gridfitting
    Anchor points
    Grid alignment rounding: fraction/halves + up, down, left, right, floor, ceil, toZero, toInfinity, in, out (so halves-up, fraction-toZero...)
    Round relative another point
    Round at a fraction of the grid, such as half pixels
    Round even/odd (e.g. 1 and 3 pixel lines vs 2 and 4 pixel lines)
    Translate anchor and entire grouped object and then stretch by other anchor
    Set minimum path width minimum-strokewidth="1dpx" (e.g. no thinner than 1 pixel)
    Conditional visibility based on device pixels per canvas unit
    rounding-origin for in (toward zero) and out (toward infinity) rounding
    inward and outward rounding based on path direction clockwise vs counterclockwise
    Ensure minimum 1-pixel gap between lines (e.g. Outlook office calendar icon)
    Align 1/3/5/any odd pixel width lines/paths to half pixel
    Align 2/4/6/any even pixel width lines/paths to pixel intersection

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

Example:
    Grid alignment cannot be part of transform or else any unrecognized transform ignores the entire transform in Chrome, ruining forwards compatibility with older clients (e.g. transform="grid-align(plusSignCenter)").

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

    todo: Can you just declare values inline, rather than require anchor?
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
        <circle cx="50" cy="50" r="10" stroke="#70F800" stroke-width="3" minimum-stroke-width="1dpx"/>
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

enum class BitmapSizingDisplay
{
    SingleSize,
    WindowSize,
    Waterfall,
};

enum class BackgroundColorMode
{
    TransparentBlack,
    GrayCheckerboard,
    OpaqueWhite,
};

std::unique_ptr<lunasvg::Document> g_document;
lunasvg::Bitmap g_bitmap;

const uint32_t g_waterfallBitmapSizes[] = {16,20,24,28,32,40,48,56,64,80,96,112,128,160,192,224,256};
const uint32_t g_waterfallBitmapWidth = 832;
const uint32_t g_waterfallBitmapHeight = 400;
const uint32_t g_zoomFactors[] = {1,2,4,8};

unsigned int g_bitmapMaximumSize = 16;
BitmapSizingDisplay g_bitmapSizingDisplay = BitmapSizingDisplay::Waterfall;
BackgroundColorMode g_backgroundColorMode = BackgroundColorMode::GrayCheckerboard;
uint32_t g_bitmapPixelZoom = 1;
std::wstring g_fileLastLoaded;

// Forward declarations of functions included in this code module:
ATOM MyRegisterClass(HINSTANCE hInstance);
BOOL InitializeInstance(HINSTANCE, int);
LRESULT CALLBACK WindowProcedure(HWND, UINT, WPARAM, LPARAM);
INT_PTR CALLBACK AboutDialogProcedure(HWND, UINT, WPARAM, LPARAM);
void LoadSvgFile(const wchar_t* filePath);
void RedrawSvg(HWND hWnd);

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

    // Initialize global strings
    LoadStringW(instanceHandle, IDS_APP_TITLE, szTitle, MAX_LOADSTRING);
    LoadStringW(instanceHandle, IDC_LUNASVGTEST, szWindowClass, MAX_LOADSTRING);
    MyRegisterClass(instanceHandle);

    // Perform application initialization:
    if (!InitializeInstance(instanceHandle, nCmdShow))
    {
        return FALSE;
    }

    // Load the file name if given.
    if (fileName[0])
    {
        g_document = lunasvg::Document::loadFromFile(fileName);
        if (g_document)
        {
            RedrawSvg(g_windowHandle);
        }
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


//  FUNCTION: MyRegisterClass()
//
//  PURPOSE: Registers the window class.
//
ATOM MyRegisterClass(HINSTANCE instanceHandle)
{
    WNDCLASSEXW wcex;

    wcex.cbSize = sizeof(WNDCLASSEX);

    wcex.style          = CS_HREDRAW | CS_VREDRAW;
    wcex.lpfnWndProc    = &WindowProcedure;
    wcex.cbClsExtra     = 0;
    wcex.cbWndExtra     = 0;
    wcex.hInstance      = instanceHandle;
    wcex.hIcon          = LoadIcon(instanceHandle, MAKEINTRESOURCE(IDI_LUNASVGTEST));
    wcex.hCursor        = LoadCursor(nullptr, IDC_ARROW);
    wcex.hbrBackground  = (HBRUSH)(COLOR_WINDOW+1);
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

    HWND hWnd = CreateWindowExW(
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

    if (!hWnd)
    {
        return FALSE;
    }

    ShowWindow(hWnd, nCmdShow);
    UpdateWindow(hWnd);

    g_windowHandle = hWnd;

    return TRUE;
}


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
        {1,3,1,0,0},
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
    struct PixelBgra
    {
        uint8_t b;
        uint8_t g;
        uint8_t r;
        uint8_t a;
    };
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


void LoadSvgFile(const wchar_t* filePath)
{
    g_document = lunasvg::Document::loadFromFile(filePath);
    g_bitmap = lunasvg::Bitmap();
    g_fileLastLoaded = filePath;
}


void RedrawSvg(HWND hwnd)
{
    InvalidateRect(hwnd, nullptr, true);

    if (!g_document)
    {
        return;
    }

    const uint32_t backgroundColor = 0x00000000u; // Transparent black

    LARGE_INTEGER startTime;
    LARGE_INTEGER endTime;
    LARGE_INTEGER cpuFrequency;
    QueryPerformanceFrequency(&cpuFrequency);
    QueryPerformanceCounter(&startTime);

    // Draw the image to a bitmap.
    switch (g_bitmapSizingDisplay)
    {
    case BitmapSizingDisplay::SingleSize:
        {
            unsigned int bitmapMaximumSize = g_bitmapMaximumSize;
            g_bitmap.reset(bitmapMaximumSize, bitmapMaximumSize);
            memset(g_bitmap.data(), 0u, g_bitmap.height() * g_bitmap.stride()); // Clear to zero.
            auto matrix = GetMatrixForSize(*g_document, bitmapMaximumSize);

            // Don't call renderToBitmap() directly because it distorts
            // the aspect ratio, unless the viewport is exactly square.
            //
            // g_bitmap = g_document->renderToBitmap(bitmapMaximumSize, bitmapMaximumSize, backgroundColor);
            //
            // Compute the matrix ourselves instead, and use that:
            g_document->render(g_bitmap, matrix, backgroundColor);
        }
        break;

    case BitmapSizingDisplay::Waterfall:
        {
            // Determine the total bitmap size to display all sizes.
            uint32_t totalBitmapWidth = g_waterfallBitmapWidth;
            uint32_t totalBitmapHeight = g_waterfallBitmapHeight;
            g_bitmap.reset(totalBitmapWidth, totalBitmapHeight);
            memset(g_bitmap.data(), 0u, g_bitmap.height() * g_bitmap.stride()); // Clear to zero.
            lunasvg::Bitmap bitmap;

            // Draw each size, left to right, top to bottom.
            uint32_t x = 0, y = 0, previousSize = 1;
            for (uint32_t size : g_waterfallBitmapSizes)
            {
                if (x + size > totalBitmapWidth)
                {
                    y += previousSize + g_smallDigitHeight + 1;
                    x = 0;
                }
                if (y + size + g_smallDigitHeight + 1 > totalBitmapHeight)
                {
                    break;
                }

                // Draw the icon.
                uint32_t pixelOffset = y * g_bitmap.stride() + x * sizeof(uint32_t);
                bitmap.reset(g_bitmap.data() + pixelOffset, size, size, g_bitmap.stride());
                auto matrix = GetMatrixForSize(*g_document, size);
                g_document->render(bitmap, matrix, backgroundColor);

                // Draw little digits for icon pixel size.
                char digits[4] = {};
                auto result = std::to_chars(std::begin(digits), std::end(digits), size);
                uint32_t digitCount = static_cast<uint32_t>(result.ptr - std::begin(digits));
                DrawSmallDigits(
                    g_bitmap.data(),
                    reinterpret_cast<unsigned char*>(digits),
                    digitCount,
                    x + (size - g_smallDigitWidth * digitCount) / 2, // centered across icon
                    y + size + 1, // y, 1 pixel under icon
                    g_bitmap.width(),
                    g_bitmap.height(),
                    g_bitmap.stride()
                );

                previousSize = size;
                x += size;
            }
        }
        break;

    case BitmapSizingDisplay::WindowSize:
        {
            RECT clientRect;
            GetClientRect(hwnd, /*out*/&clientRect);
            unsigned int bitmapMaximumSize = std::min(clientRect.bottom, clientRect.right) / g_bitmapPixelZoom;
            g_bitmap.reset(bitmapMaximumSize, bitmapMaximumSize);
            memset(g_bitmap.data(), 0u, g_bitmap.height() * g_bitmap.stride()); // Clear to zero.
            auto matrix = GetMatrixForSize(*g_document, bitmapMaximumSize);
            g_document->render(g_bitmap, matrix, backgroundColor);
        }
        break;
    }

    QueryPerformanceCounter(&endTime);
    double durationMs = static_cast<double>(endTime.QuadPart - startTime.QuadPart);
    durationMs /= static_cast<double>(cpuFrequency.QuadPart);
    durationMs *= 1000.0;
    wchar_t windowTitle[1000];
    _snwprintf_s(windowTitle, sizeof(windowTitle), L"%s (%1.6fms)", szTitle, durationMs);
    SetWindowText(hwnd, windowTitle);

    // Premultiply pixels so that edges are antialiased.
    // hack:::PremultiplyBgraData(g_bitmap.data(), g_bitmap.stride() * g_bitmap.height());

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
        DrawBackgroundColorUnderneath(
            g_bitmap.data(),
            0,
            0,
            g_bitmap.width(),
            g_bitmap.height(),
            g_bitmap.stride(),
            0xFFFFFFFF
        );
        break;
    }
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
                    std::array<wchar_t, MAX_PATH> fileName;
                    fileName[0] = '\0';
                    OPENFILENAME openFileName = {};

                    openFileName.lStructSize = sizeof(openFileName);
                    openFileName.hwndOwner = hwnd;
                    openFileName.hInstance = g_instanceHandle;
                    openFileName.lpstrFilter = L"SVG\0" L"*.svg\0"
                                               L"All files\0" L"*\0"
                                               L"\0";
                    openFileName.lpstrFile = fileName.data();
                    openFileName.nMaxFile = static_cast<DWORD>(fileName.size());
                    openFileName.Flags = OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST | OFN_HIDEREADONLY | OFN_LONGNAMES | OFN_NOTESTFILECREATE;

                    if (GetOpenFileName(&openFileName))
                    {
                        LoadSvgFile(fileName.data());
                        RedrawSvg(hwnd);
                        g_fileLastLoaded = fileName.data();
                    }
                }
                break;

            case IDM_RELOAD:
                if (!g_fileLastLoaded.empty())
                {
                    LoadSvgFile(g_fileLastLoaded.data());
                    RedrawSvg(hwnd);
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
                g_bitmapMaximumSize = g_waterfallBitmapSizes[wmId - IDM_SIZE0];
                g_bitmapSizingDisplay = BitmapSizingDisplay::SingleSize;
                RedrawSvg(hwnd);
                break;

            case IDM_SIZE_WINDOW:
                g_bitmapSizingDisplay = BitmapSizingDisplay::WindowSize;
                RedrawSvg(hwnd);
                break;

            case IDM_SIZE_WATERFALL:
                g_bitmapSizingDisplay = BitmapSizingDisplay::Waterfall;
                RedrawSvg(hwnd);
                break;

            case IDM_ZOOM0:
            case IDM_ZOOM1:
            case IDM_ZOOM2:
            case IDM_ZOOM3:
                static_assert(IDM_ZOOM3 + 1 - IDM_ZOOM0 == _countof(g_zoomFactors), "g_zoomFactors is not the correct size");
                g_bitmapPixelZoom = g_zoomFactors[wmId - IDM_ZOOM0];
                RedrawSvg(hwnd);
                break;

            case IDM_COPY:
                CopySvgBitmapToClipboard(g_bitmap, hwnd);
                break;

            case IDM_COLOR_GRAY_CHECKERBOARD:
            case IDM_COLOR_TRANSPARENT_BLACK:
            case IDM_COLOR_OPAQUE_WHITE:
                static_assert(IDM_COLOR_GRAY_CHECKERBOARD - IDM_COLOR_FIRST == static_cast<uint32_t>(BackgroundColorMode::GrayCheckerboard), "");
                static_assert(IDM_COLOR_TRANSPARENT_BLACK - IDM_COLOR_FIRST == static_cast<uint32_t>(BackgroundColorMode::TransparentBlack), "");
                static_assert(IDM_COLOR_OPAQUE_WHITE - IDM_COLOR_FIRST == static_cast<uint32_t>(BackgroundColorMode::OpaqueWhite), "");

                g_backgroundColorMode = static_cast<BackgroundColorMode>(wmId - IDM_COLOR_FIRST);
                RedrawSvg(hwnd);
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
                    
            if (DragQueryFile(dropHandle, 0, fileName.data(), static_cast<uint32_t>(fileName.size())))
            {
                LoadSvgFile(fileName.data());
                RedrawSvg(hwnd);
            }
        }
        break;

    case WM_WINDOWPOSCHANGED:
        if (!(reinterpret_cast<WINDOWPOS*>(lParam)->flags & SWP_NOSIZE) && g_bitmapSizingDisplay == BitmapSizingDisplay::WindowSize)
        {
            RedrawSvg(hwnd);
        }
        break;

    case WM_PAINT:
        {
            PAINTSTRUCT ps;
            HDC hdc = BeginPaint(hwnd, &ps);

            if (g_bitmap.valid())
            {
                BITMAPV5HEADER bitmapInfo = {};
                FillBitmapInfoFromLunaSvgBitmap(g_bitmap, /*out*/ bitmapInfo);

#if 1
                if (g_bitmapPixelZoom == 1)
                {
                    SetDIBitsToDevice(
                        ps.hdc,
                        0,
                        0,
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
                        0,
                        0,
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
            }
            else
            {
                HFONT oldFont = static_cast<HFONT>(SelectObject(ps.hdc, GetStockObject(DEFAULT_GUI_FONT)));
                TextOut(ps.hdc, 0, 0, L"No SVG loaded", _countof(L"No SVG loaded") - 1);
                SelectObject(ps.hdc, oldFont);
            }
            EndPaint(hwnd, &ps);
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
