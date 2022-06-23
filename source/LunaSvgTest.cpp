// LunaSvgTest.cpp: Main application.

#include "precomp.h"
#include "Common.h"
#include "LunaSvgTest.h"
#include "lunasvg.h"

using Microsoft::WRL::ComPtr;

////////////////////////////////////////////////////////////////////////////////
// Application-specific helper functions

enum class BitmapSizingDisplay
{
    FixedSize,
    WindowSize,
    WaterfallObjectThenSize,
    WaterfallSizeThenObject,
    Natural,
};

enum class BackgroundColorMode
{
    TransparentBlack,
    GrayCheckerboard,
    OpaqueWhite,
    OpaqueGray,
};

// A single item on the screen, either SVG document or size label.
struct CanvasItem
{
    enum class ItemType : uint8_t
    {
        None,
        SizeLabel,
        SvgDocument,
        RasterImage,
    };
    enum class Flags : uint8_t
    {
        Default = 0, // Default
        NewLine = 1, // Wrap this item to a new row/column (depending on flow direction)
        SetIndent = 2, // This items sets an indent for wrapped items
    };
    enum class FlowDirection
    {
        RightDown,
        DownRight,
        Total,
    };

    ItemType itemType;
    Flags flags;
    uint8_t padding1;
    uint8_t padding2;
    union
    {
        uint32_t labelSize;
        uint32_t imageIndex;
    } value;
    uint32_t x; // Left edge of item box
    uint32_t y; // Top edge of item box
    uint32_t w; // Width
    uint32_t h; // Height

    bool ContainsPoint(int32_t pointX, int32_t pointY) const noexcept
    {
        return pointX >= int32_t(x)
            && pointX <  int32_t(x + w)
            && pointY >= int32_t(y)
            && pointY <  int32_t(y + h);
    }
};


bool operator==(CanvasItem const& a, CanvasItem const& b) noexcept
{
    return a.itemType == b.itemType
        && a.flags == b.flags
        && memcmp(&a.value, &b.value, sizeof(b.value)) == 0
        && a.x == b.x
        && a.y == b.y
        && a.w == b.w
        && a.h == b.w;
}

struct RasterImage
{
    uint32_t width;
    uint32_t height;
    // uint32_t bitdepth implicitly 32-bit BGRA.
    std::unique_ptr<std::byte[]> pixels;
};

RECT ToRect(CanvasItem const& canvasItem) noexcept
{
    return {
        LONG(canvasItem.x),
        LONG(canvasItem.y),
        LONG(canvasItem.x + canvasItem.w),
        LONG(canvasItem.y + canvasItem.h)
    };
}

Gdiplus::Rect ToGdiplusRect(CanvasItem const& canvasItem) noexcept
{
    return {
        INT(canvasItem.x),
        INT(canvasItem.y),
        INT(canvasItem.w),
        INT(canvasItem.h)
    };
}

Gdiplus::RectF ToGdiplusRectF(CanvasItem const& canvasItem) noexcept
{
    return {
        float(canvasItem.x),
        float(canvasItem.y),
        float(canvasItem.w),
        float(canvasItem.h)
    };
}

SIZE ToSize(RECT const& rect) noexcept
{
    return { LONG(rect.right - rect.left), LONG(rect.bottom - rect.top) };
}

struct ImageOrSvgDocument :
    variantex<
        std::unique_ptr<RasterImage>,
        std::unique_ptr<lunasvg::Document>
    >
{
    CanvasItem::ItemType GetCanvasItemType() noexcept
    {
        switch (this->index())
        {
        case 0: return CanvasItem::ItemType::RasterImage;
        case 1: return CanvasItem::ItemType::SvgDocument;
        default: return CanvasItem::ItemType::None;
        }
    }

    // Unwrap the pointer.
    template <typename UnwrappedType>
    UnwrappedType& GetReference()
    {
        assert(this->index() == this->index_of_type<std::unique_ptr<UnwrappedType>>());
        return *this->get<std::unique_ptr<UnwrappedType>>();
    }
};

DEFINE_ENUM_FLAG_OPERATORS(CanvasItem::Flags);

union PixelBgra
{
    struct
    {
        uint8_t b;
        uint8_t g;
        uint8_t r;
        uint8_t a;
    };
    uint32_t i;

    // blend(dest, source) =  source.bgra + (dest.bgra * (1 - source.a))
    static inline PixelBgra Blend(PixelBgra existingColor, PixelBgra newColor) noexcept
    {
        const uint32_t bitmapAlpha = newColor.a;
        if (bitmapAlpha == 255)
            return newColor;

        const uint32_t inverseBitmapAlpha = 255 - bitmapAlpha;

        uint32_t blue  = (inverseBitmapAlpha * existingColor.b / 255) + newColor.b;
        uint32_t green = (inverseBitmapAlpha * existingColor.g / 255) + newColor.g;
        uint32_t red   = (inverseBitmapAlpha * existingColor.r / 255) + newColor.r;
        uint32_t alpha = (inverseBitmapAlpha * existingColor.a / 255) + newColor.a;
        uint32_t pixelValue = (blue << 0) | (green << 8) | (red << 16) | (alpha << 24);
        return PixelBgra{ .i = pixelValue };
    }

    // Lighten dark colors and darken light colors using the average grayscale,
    // useful for displaying grid lines or dots.
    static inline PixelBgra InvertSoftAverage(PixelBgra existingColor) noexcept
    {
        uint32_t shade = ((existingColor.r + existingColor.g + existingColor.b) * 341) >> 10;
        shade += (shade >= 96) ? -64 : 64;
        return PixelBgra{ .i = (shade << 0) | (shade << 8) | (shade << 16) | 0xFF000000 };
    }
};

////////////////////////////////////////////////////////////////////////////////
// Horrible assortment of (gasp) global variables rather than a proper class instance.

constexpr size_t MAX_LOADSTRING = 100;
HINSTANCE g_instanceHandle;                     // Current process base memory address.
HWND g_windowHandle;
HWND g_toolTipWindowHandle;
WCHAR g_applicationTitle[MAX_LOADSTRING];       // The title bar text.
WCHAR g_windowClassName[MAX_LOADSTRING];        // The main window class name.
const HBRUSH g_backgroundWindowBrush = HBRUSH(COLOR_3DFACE + 1);
bool g_isIconic = false;

TOOLINFO g_toolTipInfo =
{
    .cbSize = sizeof(TOOLINFO),
    .uFlags = TTF_IDISHWND | TTF_TRACK | TTF_TRANSPARENT | TTF_ABSOLUTE, //|TTF_CENTERTIP,
    .hwnd = nullptr, // containing hwnd
    .uId = 0, // tool id/handle
    .rect = {0,0,4096,4096},
    .hinst = nullptr, // instance handle
    .lpszText = const_cast<LPWSTR>(L""), // updated text
    .lParam = 0,
    .lpReserved = nullptr,
};

ULONG_PTR g_gdiplusStartupToken;
Gdiplus::GdiplusStartupOutput g_gdiplusStartupOutput;
ComPtr<IWICImagingFactory> g_wicFactory;

std::vector<ImageOrSvgDocument> g_images;
std::vector<CanvasItem> g_canvasItems;
std::vector<std::wstring> g_filenameList;

lunasvg::Bitmap g_bitmap; // Rendered bitmap of all SVG documents.
HBITMAP g_cachedScreenBitmap;
std::byte* g_cachedScreenBitmapPixels;
SIZE g_cachedScreenBitmapSize; // Most recent size of cached bitmap (may be slightly larger than the actual bitmap area).
bool g_canvasItemsNeedRedrawing = true; // Set true if items need redrawing after any size changes, layout changes, or background color (not just scrolling or zoom).
bool g_relayoutCanvasItems = false; // Set true when SVG content needs to be laid out again (e.g. resize window when wrapped).
bool g_realignBitmap = false; // Set true after loading new files to recenter/realign the new bitmap.
bool g_constrainBitmapOffsets = false; // Set true after resizing to constrain the view over the current bitmap.
std::wstring g_errorMessage;
const std::wstring_view g_defaultMessage =
    L"No SVG loaded - use File/Open or drag&drop filenames to load SVG documents.\r\n"
    L"\r\n"
    L"ctrl o = open files\r\n"
    L"drag&drop = open files\r\n"
    L"F5 = reload current files\r\n"
    L"ctrl c = copy bitmap to clipboard\r\n"
    L"\r\n"
    L"left mouse click = show item & coordinate\r\n"
    L"right mouse click = context menu\r\n"
    L"left mouse drag = pan\r\n"
    L"right mouse drag = select for copying\r\n"
    L"mouse wheel = pan vertically\r\n"
    L"mouse wheel + shift = pan horizontally\r\n"
    L"mouse wheel + ctrl = zoom\r\n"
    L"arrow keys/home/end/pgup/pgdn = pan\r\n"
    L"+/- = increase/decrease zoom\r\n"
    L"ctrl +/- = increase/decrease object size\r\n"
    L"\r\n"
    L"g = show/hide grid\r\n"
    L"shift g = show/hide pixel grid\r\n"
    L"o = show/hide outlines\r\n"
    L"r = show/hide raster fills and strokes\r\n"
    L"a = show/hide alpha channel\r\n"
    ;

const uint32_t g_waterfallBitmapSizes[] = {8,12,16,20,24,28,32,36,40,48,56,64,72,80,96,112,120,128,160,180,192,224,256};
const uint32_t g_zoomFactors[] = {1,2,3,4,5,6,8,12,16,24,32,48,64,96,128,192,256};
const uint32_t g_gridSizes[] = {0,1,2,3,4,5,6,8,12,16,24,32,48,64,96,128,192,256};
const uint32_t g_bitmapScrollStep = 64;

BitmapSizingDisplay g_bitmapSizingDisplay = BitmapSizingDisplay::WaterfallObjectThenSize;
BackgroundColorMode g_backgroundColorMode = BackgroundColorMode::GrayCheckerboard;
uint32_t g_bitmapSizePerDocument = 64; // in pixels
uint32_t g_bitmapMaximumSize = UINT32_MAX; // useful for the waterfall to set a maximum range
uint32_t g_bitmapPixelZoom = 1; // Assert > 0.
uint32_t g_gridSize = 8;
int32_t g_bitmapOffsetX = 0; // In effective screen pixels (in terms of g_bitmapPixelZoom) rather than g_bitmap pixels. Positive pans right.
int32_t g_bitmapOffsetY = 0; // In effective screen pixels (in terms of g_bitmapPixelZoom) rather than g_bitmap pixels. Positive pans down.
double g_svgNudgeOffsetX = 0; // A tiny adjustment to add to the rendering transform.
double g_svgNudgeOffsetY = 0; // A tiny adjustment to add to the rendering transform.
CanvasItem::FlowDirection g_canvasFlowDirection = CanvasItem::FlowDirection::RightDown;
bool g_bitmapSizeWrapped = false; // Wrap the items to the window size.
bool g_invertColors = false; // Negate all the bitmap colors.
bool g_showAlphaChannel = false; // Display alpha channel as monochrome grayscale.
bool g_gridVisible = false; // Display rectangular grid using g_gridSize.
bool g_outlinesVisible = false; // Display path outlines of each document.
bool g_rasterFillsStrokesVisible = true; // Fills and strokes are visible.
bool g_pixelGridVisible = false; // Display points per pixel.
bool g_snapToPixels = false; // Display points per pixel.

int32_t g_previousMouseX = 0; // Used for pan;
int32_t g_previousMouseY = 0;
int32_t g_selectionStartMouseX = 0; // Used for right drag.
int32_t g_selectionStartMouseY = 0;
bool g_isRightDragging = false;

////////////////////////////////////////////////////////////////////////////////

// Forward declarations of functions included in this code module:
ATOM RegisterMainWindowClass(HINSTANCE instanceHandle);
BOOL InitializeWindowInstance(HINSTANCE instanceHandle, int commandShow);
LRESULT CALLBACK WindowProcedure(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam);
INT_PTR CALLBACK AboutDialogProcedure(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam);
void ClearDocumentList();
void AppendSingleDocumentFile(wchar_t const* filePath);
void RelayoutAndRedrawCanvasItemsLater(HWND hwnd);
void RedrawCanvasItemsLater(HWND hwnd);
void RedrawCanvasBackgroundAndItems(HWND hwnd);
void ShowErrors();
void ShowError(std::wstring_view message);
void AppendError(std::wstring_view message);


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
    int argumentCount = 0;
    wchar_t** arguments = CommandLineToArgvW(GetCommandLine(), &argumentCount);

    // Initialize global strings.
    LoadStringW(instanceHandle, IDS_APP_TITLE, g_applicationTitle, MAX_LOADSTRING);
    LoadStringW(instanceHandle, IDC_LUNASVGTEST, g_windowClassName, MAX_LOADSTRING);
    RegisterMainWindowClass(instanceHandle);

    // Perform application initialization:
    if (!InitializeWindowInstance(instanceHandle, nCmdShow))
    {
        return FALSE;
    }

    // Load the file names if given.
    if (argumentCount > 1)
    {
        ClearDocumentList();
        for (int argumentIndex = 1; argumentIndex < argumentCount; ++argumentIndex)
        {
            AppendSingleDocumentFile(arguments[argumentIndex]);
        }
        ShowErrors();
        RelayoutAndRedrawCanvasItemsLater(g_windowHandle);
    }
    LocalFree(arguments);

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
    WNDCLASSEXW wcex =
    {
        .cbSize         = sizeof(WNDCLASSEX),
        .style          = CS_HREDRAW | CS_VREDRAW | CS_DBLCLKS,
        .lpfnWndProc    = &WindowProcedure,
        .cbClsExtra     = 0,
        .cbWndExtra     = 0,
        .hInstance      = instanceHandle,
        .hIcon          = LoadIcon(instanceHandle, MAKEINTRESOURCE(IDI_LUNASVGTEST)),
        .hCursor        = LoadCursor(nullptr, IDC_SIZEALL),
        .hbrBackground  = g_backgroundWindowBrush,
        .lpszMenuName   = MAKEINTRESOURCEW(IDC_LUNASVGTEST),
        .lpszClassName  = g_windowClassName,
        .hIconSm        = wcex.hIcon,
    };

    return RegisterClassExW(&wcex);
}


// Create singleton tooltip used for error messages.
void CreateToolTip(HINSTANCE instanceHandle, HWND parentHwnd)
{
    g_toolTipInfo.hinst = instanceHandle;
    g_toolTipInfo.hwnd = parentHwnd;

    g_toolTipWindowHandle = CreateWindowEx(
        0,
        TOOLTIPS_CLASS,
        NULL,
        WS_POPUP|TTS_NOANIMATE|TTS_NOFADE|TTS_NOPREFIX,//|TTS_BALLOON|TTS_ALWAYSTIP
        CW_USEDEFAULT, CW_USEDEFAULT,
        CW_USEDEFAULT, CW_USEDEFAULT,
        nullptr,
        nullptr,
        instanceHandle,
        0
    );

    SetWindowPos(g_toolTipWindowHandle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE | SWP_NOREDRAW);
    SendMessage(g_toolTipWindowHandle, TTM_ADDTOOL, 0, (LPARAM)&g_toolTipInfo);
}


void ShowToolTip(
    const wchar_t* message,
    int32_t toolTipX = 10,
    int32_t toolTipY = 10
    )
{
    // Adjust the client-relative coordinates to screen space.
    POINT toolTipPoint = { toolTipX, toolTipY };
    ClientToScreen(g_windowHandle, &toolTipPoint);
    // auto {toolTipScreenX, toolTipScreenY} = toolTipPoint; // Why C++, why? Be self-consistent, using curly braces.
    auto [toolTipScreenX, toolTipScreenY] = toolTipPoint;

    SendMessage(g_toolTipWindowHandle, TTM_SETMAXTIPWIDTH, 0, 1024); // No wrapping. Just let it be as wide as it needs to be.
    g_toolTipInfo.lpszText = const_cast<LPWSTR>(message);
    SendMessage(g_toolTipWindowHandle, TTM_UPDATETIPTEXT, 0, (LPARAM)&g_toolTipInfo);
    SendMessage(g_toolTipWindowHandle, TTM_TRACKPOSITION, 0, (LPARAM)(toolTipScreenX | toolTipScreenY << 16)); // reposition one last time
    SendMessage(g_toolTipWindowHandle, TTM_TRACKACTIVATE, (WPARAM)true, (LPARAM)&g_toolTipInfo); // now show it so it calcs size
}


void HideToolTip()
{
    SendMessage(g_toolTipWindowHandle, TTM_TRACKACTIVATE, (WPARAM)false, (LPARAM)&g_toolTipInfo); // now show it so it calcs size
}


/*TIMERPROC*/void CALLBACK HideToolTipTimerProc(HWND hwnd, UINT uElapse, UINT_PTR uIDEvent, DWORD dwTime)
{
    g_errorMessage.clear();
    KillTimer(hwnd, uIDEvent);
    HideToolTip();
}


// Save the process base memory address in a global variable, and
// create the main program window.
BOOL InitializeWindowInstance(HINSTANCE instanceHandle, int commandShow)
{
    g_instanceHandle = instanceHandle; // Store instance handle in our global variable

    Gdiplus::GdiplusStartupInput gdiplusStartupInput(nullptr, true, true);
    Gdiplus::GdiplusStartup(&g_gdiplusStartupToken, &gdiplusStartupInput, &g_gdiplusStartupOutput);

    RETURN_IF_FAILED_V(WICCreateImagingFactory_Proxy(WINCODEC_SDK_VERSION1, OUT &g_wicFactory), false);

    HWND hwnd = CreateWindowExW(
        WS_EX_ACCEPTFILES,
        g_windowClassName,
        g_applicationTitle,
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
    g_windowHandle = hwnd;

    ShowScrollBar(hwnd, SB_BOTH, true);

    ShowWindow(hwnd, commandShow);
    UpdateWindow(hwnd);

    CreateToolTip(instanceHandle, hwnd);

    return TRUE;
}


// Return the index of the value greater than or equal the given one.
// If there aren't any, return the last element (not end).
template <typename T>
size_t FindValueIndexGE(std::span<const T> valueList, T currentValue)
{
    assert(!valueList.empty());
    auto it = std::lower_bound(valueList.begin(), valueList.end(), currentValue);
    ptrdiff_t index = it - valueList.begin();
    if (size_t(index) >= valueList.size() && !valueList.empty())
    {
        --index;
    }
    return index;
}


// Find the next or previous value from the list, using the current value and
// a delta (if positive, look forward to the next one).
template <typename T>
T FindValueNextPrevious(std::span<const T> valueList, T currentValue, ptrdiff_t delta)
{
    if (valueList.empty())
    {
        return currentValue;
    }

    auto it = std::lower_bound(valueList.begin(), valueList.end(), currentValue);
    ptrdiff_t index = (it - valueList.begin()) + delta;
    index = std::clamp(index, ptrdiff_t(0), ptrdiff_t(valueList.size() - 1));
    return valueList[index];
}


// Set window scrollbar extents, both horizontal and vertical.
void SetScrollbars(
    HWND hwnd,
    int32_t xMin,
    int32_t xMax,
    int32_t xPage,
    int32_t xPos,
    int32_t yMin,
    int32_t yMax,
    int32_t yPage,
    int32_t yPos
    )
{
    SCROLLINFO scrollInfo =
    {
        sizeof(scrollInfo), // cbSize
        SIF_DISABLENOSCROLL|SIF_PAGE|SIF_POS|SIF_RANGE, // fMask
        int(yMin), // nMin
        int(yMax), // nMax
        uint32_t(yPage), // nPage
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


// Handle scroll bar events by updating the current position.
// Why isn't this logic just built into Windows??
uint32_t HandleScrollbarEvent(HWND hwnd, uint32_t scrollBarCode, uint32_t scrollBarType, int32_t lineSize)
{
    SCROLLINFO scrollInfo = {sizeof(scrollInfo), SIF_ALL};
    GetScrollInfo(hwnd, scrollBarType, &scrollInfo);  // get information about the scroll
    int32_t newPosition = scrollInfo.nPos;

    switch (scrollBarCode)
    {
    case SB_LINELEFT:       newPosition -= lineSize;            break;
    case SB_LINERIGHT:      newPosition += lineSize;            break;
    case SB_PAGELEFT:       newPosition -= scrollInfo.nPage;    break;
    case SB_PAGERIGHT:      newPosition += scrollInfo.nPage;    break;
    case SB_LEFT:           newPosition = scrollInfo.nMin;      break;
    case SB_RIGHT:          newPosition = scrollInfo.nMax;      break;
    case SB_THUMBTRACK:
    case SB_THUMBPOSITION:  newPosition = scrollInfo.nTrackPos; break;
    case SB_ENDSCROLL:
    default:                return newPosition;
    }

    newPosition = std::clamp(newPosition, scrollInfo.nMin, int32_t(scrollInfo.nMax - scrollInfo.nPage));

    scrollInfo.fMask = SIF_POS;
    scrollInfo.nPos = newPosition;
    SetScrollInfo(hwnd, scrollBarType, &scrollInfo,/*redraw*/ true);

    return newPosition;
}


void UpdateBitmapScrollbars(HWND hwnd)
{
    // Show disabled scroll bars for empty bitmap.
    if (!g_bitmap.valid())
    {
        SetScrollbars(hwnd, 0, 0, 0, 0, 0, 0, 0, 0);
        return;
    }

    RECT clientRect;
    GetClientRect(hwnd, /*out*/&clientRect);

    auto getRange = [](int32_t offset, int32_t bitmapSize, int32_t windowSize)
    {
        const int32_t pageSize = std::min(bitmapSize, windowSize);
        const int32_t minValue = std::min(offset, std::min(0, bitmapSize - windowSize));
        const int32_t maxValue = std::max(offset + pageSize, bitmapSize);
        return std::tuple<int32_t, int32_t, int32_t>(pageSize, minValue, maxValue);
    };

    const auto [xPageSize, xMin, xMax] = getRange(g_bitmapOffsetX, g_bitmap.width() * g_bitmapPixelZoom, int32_t(clientRect.right));
    const auto [yPageSize, yMin, yMax] = getRange(g_bitmapOffsetY, g_bitmap.height() * g_bitmapPixelZoom, int32_t(clientRect.bottom));
    SetScrollbars(hwnd, xMin, xMax, xPageSize, g_bitmapOffsetX, yMin, yMax, yPageSize, g_bitmapOffsetY);
}


// Enqueue a realignment later of the bitmap view after drawing.
void RealignBitmapOffsetsLater()
{
    g_realignBitmap = true;
}


// Enqueue constraining the bitmap view after drawing.
void ConstrainBitmapOffsetsLater()
{
    g_constrainBitmapOffsets = true;
}


#if 1
// GDI SetPixel is really slow even on memory bitmaps.
// So don't call this version.
// Draw horizontal and vertical lines using the given color.
void DrawGrid(
    HDC hdc,
    int32_t xOffset,
    int32_t yOffset,
    uint32_t width,
    uint32_t height,
    uint32_t xSpacing,
    uint32_t ySpacing,
    RECT boundingRect,
    HBRUSH brush,
    bool drawLines
    )
{
    xSpacing = std::max(xSpacing, 1u);
    ySpacing = std::max(ySpacing, 1u);

    // Clamp the grid to the actual client area to avoid overdraw.
    int32_t x0 = xOffset >= boundingRect.left ? xOffset : boundingRect.left - int32_t((boundingRect.left - xOffset) % xSpacing);
    int32_t x1 = std::min(int32_t(xOffset + width), int32_t(boundingRect.right));
    int32_t y0 = yOffset >= boundingRect.top ? yOffset : boundingRect.top - int32_t((boundingRect.top - yOffset) % ySpacing);
    int32_t y1 = std::min(int32_t(yOffset + height), int32_t(boundingRect.bottom));

    if (drawLines)
    {
        // Vertical lines left to right.
        for (int32_t x = x0; x < x1; x += xSpacing)
        {
            RECT rect = { .left = x, .top = y0, .right = x + 1, .bottom = y1 };
            FillRect(hdc, &rect, brush);
        }

        // Horizontal lines top to bottom.
        for (int32_t y = y0; y < y1; y += ySpacing)
        {
            RECT rect = { .left = x0, .top = y, .right = x1, .bottom = y + 1 };
            FillRect(hdc, &rect, brush);
        }
    }
    else
    {
        // SetPixel is really slow. Might need to use lines with dashes instead.
        // Leave disabled for now.
        for (int32_t y = y0; y < y1; y += ySpacing)
        {
            for (int32_t x = x0; x < x1; x += xSpacing)
            {
                SetPixel(hdc, x, y, 0x00000000);
            }
        }
    }
}
#endif


template<typename T>
T RoundUp(T value, T multiple)
{
    if (multiple == 0)
    {
        return value;
    }
    else if (value > 0)
    {
        T remainder = value % multiple;
        return value + (remainder ? multiple - remainder : T(0));
    }
    else // value <= 0
    {
        return value + (-value % multiple);
    }
}


// Draw a grid of the given color, using either points or horizontal and vertical lines.
// GDI SetPixel is sooo slow, even on memory bitmaps. So, just draw it ourselves :/.
void DrawGridFast32bpp(
    RECT const& gridRect,
    uint32_t xSpacing,
    uint32_t ySpacing,
    uint32_t color, // B,G,R,A in byte memory order (no alpha blending done). If 0, then softly invert the color.
    bool drawLines,
    std::byte* pixels,
    uint32_t rowByteStride,
    RECT const& bitmapBoundingRect
    )
{
    assert(bitmapBoundingRect.left >= 0);
    assert(bitmapBoundingRect.top >= 0);
    assert(rowByteStride >= bitmapBoundingRect.right * sizeof(uint32_t));

    xSpacing = std::max(xSpacing, 1u);
    ySpacing = std::max(ySpacing, 1u);

    // Clamp the grid to the actual client area to avoid overdraw.
    // Adjust the starting pixel so the grid aligns correctly.
    int32_t x0 = std::max(gridRect.left, bitmapBoundingRect.left);
    int32_t y0 = std::max(gridRect.top, bitmapBoundingRect.top);
    int32_t x1 = std::min(gridRect.right, bitmapBoundingRect.right);
    int32_t y1 = std::min(gridRect.bottom, bitmapBoundingRect.bottom);
    int32_t x0Adjusted = gridRect.left + RoundUp<int32_t>(x0 - gridRect.left, xSpacing);
    int32_t y0Adjusted = gridRect.top + RoundUp<int32_t>(y0 - gridRect.top, ySpacing);
    if (x0 > x1 || y0 > y1)
    {
        return;
    }

    PixelBgra bgraColor{ .i = color };

    auto drawHorizontalLine = [](PixelBgra* pixel, int32_t x0, int32_t x1, uint32_t xSpacing, PixelBgra bgraColor)
    {
        if (bgraColor.i == 0)
        {
            for (int32_t x = x0; x < x1; x += xSpacing)
            {
                pixel[x] = PixelBgra::InvertSoftAverage(pixel[x]);
            }
        }
        else
        {
            for (int32_t x = x0; x < x1; x += xSpacing)
            {
                pixel[x] = PixelBgra::Blend(pixel[x], bgraColor);
            }
        }
    };

    auto drawVerticalLine = [](PixelBgra* pixel, int32_t y0, int32_t y1, uint32_t ySpacing, uint32_t rowByteStride, PixelBgra bgraColor)
    {
        pixel = AddByteOffset(pixel, y0 * rowByteStride);
        if (bgraColor.i == 0)
        {
            for (int32_t y = y0; y < y1; ++y)
            {
                *pixel = PixelBgra::InvertSoftAverage(*pixel);
                pixel = AddByteOffset(pixel, rowByteStride);
            }
        }
        else
        {
            for (int32_t y = y0; y < y1; ++y)
            {
                *pixel = PixelBgra::Blend(*pixel, bgraColor);
                pixel = AddByteOffset(pixel, rowByteStride);
            }
        }
    };


    if (drawLines)
    {
        // Vertical lines drawn left to right.
        for (int32_t x = x0Adjusted; x < x1; x += xSpacing)
        {
            PixelBgra* pixel = AddByteOffset<std::byte, PixelBgra>(pixels, x * sizeof(PixelBgra));
            drawVerticalLine(pixel, y0, y1, 1, rowByteStride, bgraColor);
        }

        // Horizontal lines drawn top to bottom.
        for (int32_t y = y0Adjusted; y < y1; y += ySpacing)
        {
            PixelBgra* pixelRow = AddByteOffset<std::byte, PixelBgra>(pixels, y * rowByteStride);
            drawHorizontalLine(pixelRow, x0, x1, 1, bgraColor);
        }
    }
    else
    {
        // This is several times faster than GDI SetPixel,
        // where drawing a full page of dots on my 1920x1080
        // screen takes 6ms vs 166ms with SetPixel.
        for (int32_t y = y0Adjusted; y < y1; y += ySpacing)
        {
            PixelBgra* pixelRow = AddByteOffset<std::byte, PixelBgra>(pixels, y * rowByteStride);
            drawHorizontalLine(pixelRow, x0Adjusted, x1, xSpacing, bgraColor);
        }
    }
}


// Negate all the pixel values, respecting premultiplied alpha (not just 255 - v).
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
            data += sizeof(uint32_t);
        }
        rowData += stride;
    }
}


void AlphaToGrayscale(lunasvg::Bitmap& bitmap)
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
            auto a = data[3];
            data[0] = a;
            data[1] = a;
            data[2] = a;
            data += sizeof(uint32_t);
        }
        rowData += stride;
    }
}


// Tiny 5x7 digits for the pixel labels.
// 0 = transparent
// 1 = black
// 2 = gray
// 3 = white
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


// Draw a string of tiny digits.
void DrawSmallDigits(
    uint8_t* pixels, // BGRA
    char8_t const* digits,
    uint32_t digitCount,
    uint32_t x,
    uint32_t y,
    uint32_t bitmapWidth,
    uint32_t bitmapHeight,
    uint32_t bitmapByteStridePerRow
    )
{
    static_assert(sizeof(PixelBgra) == sizeof(uint32_t));

    // Cheap clipping (whole clip, not partial)
    if (y < 0 || y + g_smallDigitHeight > bitmapHeight)
    {
        return;
    }

    // transparent, black, gray, white.
    const uint32_t digitPixelColors[4] = { 0x00000000, 0xFF000000, 0xFFC0C0C0, 0xFFFFFFFF };

    pixels += y * bitmapByteStridePerRow;
    const uint32_t rowByteDelta = bitmapByteStridePerRow - (g_smallDigitWidth * sizeof(uint32_t));

    for (uint32_t digitIndex = 0; digitIndex < digitCount; ++digitIndex)
    {
        if (x < 0 || x + g_smallDigitWidth > bitmapWidth)
        {
            return;
        }

        uint32_t digit = digits[digitIndex] - '0';
        if (digit > 9u)
        {
            continue; // Skip non-numbers.
        }

        const uint8_t* digitPixels = &g_smallDigitPixels[std::min(digit, 9u)][0][0];
        uint8_t* pixel = pixels + x * sizeof(uint32_t);
        for (uint32_t j = 0; j < g_smallDigitHeight; ++j)
        {
            for (uint32_t i = 0; i < g_smallDigitWidth; ++i)
            {
                // Check for transparency (0). Otherwise draw black (1), gray (2), or white (3).
                uint32_t digitPixelValue = *digitPixels;
                if (digitPixelValue > 0)
                {
                    assert(digitPixelValue < std::size(digitPixelColors));
                    *reinterpret_cast<uint32_t*>(pixel) = digitPixelColors[digitPixelValue];
                }
                pixel += sizeof(PixelBgra);
                ++digitPixels;
            }
            pixel += rowByteDelta;
        }

        x += g_smallDigitAdvance + 1;
    }
}


// Given the SVG document and a desired size, compute the transformation matrix.
lunasvg::Matrix GetMatrixForSize(lunasvg::Document const& document, uint32_t xSize, uint32_t ySize)
{
    auto documentWidth = document.width();
    auto documentHeight = document.height();
    if (documentWidth == 0.0 || documentHeight == 0.0)
    {
        return {};
    }

    double xScale = xSize / documentWidth;
    double yScale = ySize / documentHeight;
    double scale  = std::min(xScale, yScale);

    lunasvg::Matrix matrix{ scale, 0, 0, scale, g_svgNudgeOffsetX, g_svgNudgeOffsetY };
    return matrix;
}


// Draw dark gray/light gray checkerboard of 8x8 pixels.
void DrawCheckerboardBackground(
    uint8_t* pixels, // 32-bits of {B,G,R,A}.
    uint32_t x,
    uint32_t y,
    uint32_t width,
    uint32_t height,
    uint32_t byteStridePerRow
    )
{
    static_assert(sizeof(PixelBgra) == sizeof(uint32_t));
    const uint32_t rowByteDelta = byteStridePerRow - (width * sizeof(PixelBgra));
    uint8_t* pixel = pixels + y * byteStridePerRow + x * sizeof(PixelBgra);

    for (uint32_t j = 0; j < height; ++j)
    {
        for (uint32_t i = 0; i < width; ++i)
        {
            const uint32_t backgroundColor = ((i & 8) ^ (j & 8)) ? 0xFF202020 : 0xFF404040;
            assert(pixel >= pixels && pixel < pixels + height * byteStridePerRow);
            *reinterpret_cast<uint32_t*>(pixel) = backgroundColor;
            pixel += sizeof(PixelBgra);
        }
        pixel += rowByteDelta;
    }
}


// Draws a color underneath the already existing image, as if the color had been drawn first and then the image later.
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
    static_assert(sizeof(PixelBgra) == sizeof(uint32_t));
    PixelBgra bgraColor{ .i = backgroundColor };

    //blend(source, dest)  =  source.rgb + (dest.rgb * (1 - source.a))
    PixelBgra* pixel = AddByteOffset<uint8_t, PixelBgra>(pixels, y * byteStridePerRow + x * sizeof(PixelBgra));

    for (uint32_t j = 0; j < height; ++j)
    {
        for (uint32_t i = 0; i < width; ++i)
        {
            pixel[i] = PixelBgra::Blend(bgraColor, pixel[i]);
        }
        pixel = AddByteOffset(pixel, byteStridePerRow);
    }
}


// Draw dark gray/light gray checkerboard of 8x8 pixels.
void DrawBitmap32Bit(
    uint8_t* destPixels, // 32-bits of {B,G,R,A}.
    int32_t destX,
    int32_t destY,
    uint32_t destWidth,
    uint32_t destHeight,
    uint32_t destByteStridePerRow,
    uint8_t const* sourcePixels, // 32-bits of {B,G,R,A}.
    uint32_t sourceWidth,
    uint32_t sourceHeight
    )
{
    static_assert(sizeof(PixelBgra) == sizeof(uint32_t));
    uint32_t const sourceByteStridePerRow = sourceWidth * sizeof(PixelBgra);
    uint32_t width = sourceWidth;
    uint32_t height = sourceHeight;
    uint32_t sourceX = 0;
    uint32_t sourceY = 0;

    if (destX < 0)
    {
        width += destX;
        sourceX = -destX;
        destX = 0;
    }
    if (uint32_t(destX) + width > destWidth)
    {
        width = destWidth - destX;
    }
    if (int32_t(width) <= 0)
    {
        return;
    }

    if (destY < 0)
    {
        height += destY;
        sourceY = -destY;
        destY = 0;
    }
    if (uint32_t(destY) + height > destHeight)
    {
        height = destHeight - destY;
    }
    if (int32_t(height) <= 0)
    {
        return;
    }

    #ifndef NDEBUG
    uint32_t totalSourceBytes = sourceHeight * sourceByteStridePerRow;
    uint32_t totalDestBytes = destHeight * destByteStridePerRow;
    #endif

    PixelBgra const* sourcePixel = AddByteOffset<uint8_t, PixelBgra>(sourcePixels, sourceY * sourceByteStridePerRow + sourceX * sizeof(PixelBgra));
    PixelBgra* destPixel = AddByteOffset<uint8_t, PixelBgra>(destPixels, uint32_t(destY) * destByteStridePerRow + uint32_t(destX) * sizeof(PixelBgra));

    for (uint32_t j = 0; j < height; ++j)
    {
        for (uint32_t i = 0; i < width; ++i)
        {
            destPixel[i] = PixelBgra::Blend(destPixel[i], sourcePixel[i]);
        }
        sourcePixel = AddByteOffset(sourcePixel, sourceByteStridePerRow);
        destPixel = AddByteOffset(destPixel, destByteStridePerRow);
    }
}


HRESULT LoadImageData(
    _In_z_ wchar_t const* inputFilename,
    /*out*/ std::array<uint32_t, 4>& dimensions, // width, height, channels, bytes per channel
    /*out*/ std::unique_ptr<std::byte[]>& pixelBytes
    )
{
    assert(g_wicFactory.Get() != nullptr);

    pixelBytes.reset();

    uint32_t const channelCount = 4;
    uint32_t const bytesPerChannel = 1;

    IWICImagingFactory* wicFactory = g_wicFactory.Get();

    // Decompress the image using WIC.
    ComPtr<IWICStream> stream;
    ComPtr<IWICBitmapDecoder> decoder;
    ComPtr<IWICBitmapFrameDecode> bitmapFrame;
    ComPtr<IWICFormatConverter> converter;
    IWICBitmapSource* pixelSource = nullptr;

    RETURN_IF_FAILED(wicFactory->CreateStream(&stream));
    RETURN_IF_FAILED(stream->InitializeFromFilename(inputFilename, GENERIC_READ));
    // If from memory instead: RETURN_IF_FAILED(stream->InitializeFromMemory(const_cast<uint8_t*>(fileBytes.data()), static_cast<uint32_t>(fileBytes.size_bytes())));
    RETURN_IF_FAILED(wicFactory->CreateDecoderFromStream(stream.Get(), nullptr, WICDecodeMetadataCacheOnLoad, /*out*/ &decoder));
    RETURN_IF_FAILED(decoder->GetFrame(0, /*out*/ &bitmapFrame));

    WICPixelFormatGUID actualPixelFormatGuid;
    RETURN_IF_FAILED(bitmapFrame->GetPixelFormat(/*out*/ &actualPixelFormatGuid));

    // Convert the image if not the needed format.
    // 32bppPBGRA is what Direct2D uses.
    WICPixelFormatGUID const* targetPixelFormatGuid = &GUID_WICPixelFormat32bppPBGRA;
    if (actualPixelFormatGuid != *targetPixelFormatGuid)
    {
        RETURN_IF_FAILED(wicFactory->CreateFormatConverter(&converter));
        RETURN_IF_FAILED(converter->Initialize(
            bitmapFrame.Get(),
            *targetPixelFormatGuid,
            WICBitmapDitherTypeNone,
            nullptr,
            0.f,
            WICBitmapPaletteTypeMedianCut
        ));
        pixelSource = converter.Get();
    }
    // Just use the type in the image, but verify that it's a type we actually recognize.
    else
    {
        pixelSource = bitmapFrame.Get();
    }

    // Copy the pixels out of the IWICBitmapSource.
    uint32_t width, height;
    RETURN_IF_FAILED(pixelSource->GetSize(/*out*/ &width, /*out*/ &height));
    uint32_t const bytesPerPixel = channelCount * bytesPerChannel;
    uint32_t const rowByteStride = width * bytesPerPixel;
    uint32_t const bufferByteSize = rowByteStride * height;
    pixelBytes.reset(new std::byte[bufferByteSize]);
    WICRect rect = { 0, 0, static_cast<INT>(width), static_cast<INT>(height) };
    RETURN_IF_FAILED(pixelSource->CopyPixels(&rect, rowByteStride, bufferByteSize, /*out*/ reinterpret_cast<uint8_t*>(pixelBytes.get())));

    dimensions = { uint32_t(width), uint32_t(height), uint32_t(channelCount), 1};

    return S_OK;
}


HRESULT StoreImageData(
    std::span<std::byte const> pixelBytes,
    std::array<uint32_t, 4> dimensions, // width, height, channels, bytes per channel
    _In_z_ wchar_t const* outputFilename
    )
{
    assert(g_wicFactory.Get() != nullptr);

    std::pair<std::wstring_view, GUID const*> static constexpr filenameExtensionToGuidMappings[] =
    {
        // The commented formats have issues on Windows 7 (hresult = 0x88982F50) or bad output.
        {L"BMP",  &GUID_ContainerFormatBmp},
        {L"PNG",  &GUID_ContainerFormatPng},
        {L"TIF",  &GUID_ContainerFormatTiff},
        {L"TIFF", &GUID_ContainerFormatTiff},
        // {L"ICO",  GUID_ContainerFormatIco}, // WIC lacks a native ICO encoder. -_-
        // {L"JPG",  GUID_ContainerFormatJpeg}, // Output colors look wrong.
        // {L"JPEG", GUID_ContainerFormatJpeg},
        // {L"GIF",  GUID_ContainerFormatGif}, // GIF supports up to 8-bit, not 32-bit.
        // {L"WMP",  GUID_ContainerFormatWmp}, // HDR isn't interesting here.
        // {L"DDS",  GUID_ContainerFormatDds},
        // {L"DNG",  GUID_ContainerFormatAdng},
        // {L"HEIF", GUID_ContainerFormatHeif},
        // {L"AVIF", GUID_ContainerFormatHeif},
        // {L"WEBP", GUID_ContainerFormatWebp},
    };

    uint32_t const width = dimensions[0];
    uint32_t const height = dimensions[1];
    uint32_t const channelCount = dimensions[2];
    uint32_t const bytesPerChannel = dimensions[3];
    uint32_t const bytesPerPixel = channelCount * bytesPerChannel;
    uint32_t const rowByteStride = width * bytesPerPixel;
    uint32_t const bufferByteSize = rowByteStride * height;

    assert(channelCount == 4 && bytesPerChannel == 1);
    assert(pixelBytes.size() == bufferByteSize);

    IWICImagingFactory* wicFactory = g_wicFactory.Get();

    std::wstring filePathUppercase(outputFilename);
    std::wstring_view filePathUppercaseView(filePathUppercase);
    CharUpper(filePathUppercase.data());
    std::wstring_view filenameExtension = filePathUppercaseView.substr(filePathUppercaseView.find_last_of(L".") + 1);

    GUID const* containerGuid = nullptr;
    for (auto& mapping : filenameExtensionToGuidMappings)
    {
        if (filenameExtension == mapping.first)
        {
            containerGuid = mapping.second;
            break;
        }
    }

    if (containerGuid == nullptr)
    {
        ShowError(std::format(L"Unknown file type extension: {}", outputFilename));
        return E_FAIL;
    }

    WICPixelFormatGUID const* targetPixelFormatGuid = &GUID_WICPixelFormat32bppPBGRA;

    // Decompress the image using WIC.
    ComPtr<IWICStream> stream;
    ComPtr<IWICBitmapEncoder> encoder;
    ComPtr<IWICBitmapFrameEncode> bitmapFrame;
    ComPtr<IPropertyBag2> propertybag;

    RETURN_IF_FAILED(wicFactory->CreateStream(&stream));
    RETURN_IF_FAILED(stream->InitializeFromFilename(outputFilename, GENERIC_WRITE));
    RETURN_IF_FAILED(wicFactory->CreateEncoder(*containerGuid, nullptr, /*out*/ &encoder));
    RETURN_IF_FAILED(encoder->Initialize(stream.Get(), WICBitmapEncoderNoCache));
    RETURN_IF_FAILED(encoder->CreateNewFrame(/*out*/ &bitmapFrame, &propertybag));

    // If TIFF, then compress.
    //if (*containerGuid == GUID_ContainerFormatTiff)
    //{
    //    PROPBAG2 option = {};
    //    option.pstrName = const_cast<wchar_t*>(L"TiffCompressionMethod");
    //    VARIANT varValue;
    //    VariantInit(&varValue);
    //    varValue.vt = VT_UI1;
    //    varValue.bVal = WICTiffCompressionZIP;
    //    RETURN_IF_FAILED(propertybag->Write(1, &option, &varValue));
    //    RETURN_IF_FAILED(bitmapFrame->Initialize(propertybag.Get()));
    //}
    WICPixelFormatGUID actualPixelFormatGuid = *targetPixelFormatGuid;
    RETURN_IF_FAILED(bitmapFrame->Initialize(propertybag.Get()));
    RETURN_IF_FAILED(bitmapFrame->SetSize(width, height));
    RETURN_IF_FAILED(bitmapFrame->SetPixelFormat(/*inout*/ &actualPixelFormatGuid));

    // Why is the WritePixels input parameter not const??
    BYTE* recastPixelBytes = const_cast<BYTE*>(reinterpret_cast<BYTE const*>(pixelBytes.data()));
    RETURN_IF_FAILED(bitmapFrame->WritePixels(height, rowByteStride, bufferByteSize, recastPixelBytes));
    RETURN_IF_FAILED(bitmapFrame->Commit());
    RETURN_IF_FAILED(encoder->Commit());

    return S_OK;
}


void ClearDocumentList()
{
    g_canvasItems.clear();
    g_images.clear();
    g_filenameList.clear();
    g_bitmap = lunasvg::Bitmap();
    g_errorMessage.clear();

    g_svgNudgeOffsetX = 0;
    g_svgNudgeOffsetY = 0;
}


HRESULT AppendSingleImageFile(wchar_t const* filePath)
{
    std::array<uint32_t, 4> dimensions; // width, height, channels, 1
    std::unique_ptr<std::byte[]> pixelBytes;
    RETURN_IF_FAILED(LoadImageData(filePath, /*out*/ dimensions,/*out*/ pixelBytes));

    std::unique_ptr<RasterImage> newImage(new RasterImage{ .width = dimensions[0], .height = dimensions[1], .pixels = std::move(pixelBytes) });
    g_images.emplace_back(std::move(newImage));
    return S_OK;
}


HRESULT AppendSingleSvgFile(wchar_t const* filePath)
{
    auto document = lunasvg::Document::loadFromFile(filePath);
    // LunaSvg doesn't return any form of more specific error code for us :/.
    RETURN_IF(!document, HRESULT_FROM_WIN32(ERROR_XML_PARSE_ERROR));

    g_images.emplace_back(std::move(document));
    return S_OK;
}


void AppendSingleDocumentFile(wchar_t const* filePath)
{
    HRESULT loadResult = S_OK;
    enum { UnknownType, SvgType, ImageType } documentType = UnknownType;

    std::pair<std::wstring_view, decltype(documentType)> static constexpr filenameExtensionMappings[] =
    {
        {L".SVG", SvgType},
        {L".PNG", ImageType},
        {L".BMP", ImageType},
        {L".ICO", ImageType},
        {L".JPG", ImageType},
        {L".JPEG", ImageType},
        {L".TIF", ImageType},
        {L".TIFF", ImageType},
        {L".GIF", ImageType},
        {L".TGA", ImageType}, // Might load if 3rd party codec installed.
        {L".DNG", ImageType}, // Does this require an extra codec?
        {L".WDP", ImageType}, // Requires at least Windows 8.
        {L".DDS", ImageType}, // Is this actually supported by WIC? I haven't found a .dds that loads yet.
    };

    // Capitalize filename extension for comparison.
    std::wstring filePathUppercase(filePath);
    CharUpper(filePathUppercase.data());

    for (auto& filenameExtensionMapping : filenameExtensionMappings)
    {
        if (filePathUppercase.ends_with(filenameExtensionMapping.first))
        {
            documentType = filenameExtensionMapping.second;
            break;
        }
    }

    switch (documentType)
    {
    case ImageType: loadResult = AppendSingleImageFile(filePath); break;
    case SvgType: loadResult = AppendSingleSvgFile(filePath); break;
    case UnknownType:
        AppendError(std::format(L"Unknown file type: {}", filePath));
        return;
    }

    if (FAILED(loadResult))
    {
        AppendError(std::format(L"Error loading file (0x{:08X}): {}", uint32_t(loadResult), filePath));
        return;
    }

    g_filenameList.push_back(filePath);
    RealignBitmapOffsetsLater();
}


void ShowErrors()
{
    if (!g_errorMessage.empty())
    {
        // Show error messages, after two second delay.
        ShowToolTip(g_errorMessage.c_str());
        SetTimer(g_windowHandle, IDM_OPEN_FILE, 3000, &HideToolTipTimerProc);
    }
}


void AppendError(std::wstring_view message)
{
    // To increase the tooltip visibility, add a blank line before and after.
    if (g_errorMessage.empty())
    {
        g_errorMessage.push_back('\n ');
    }

    g_errorMessage.append(message);

    if (!g_errorMessage.ends_with(L"\n "))
    {
        if (g_errorMessage.back() != '\n')
        {
            g_errorMessage.push_back('\n');
        }
        g_errorMessage.push_back(L' ');
    }
}


void ShowError(std::wstring_view message)
{
    AppendError(message);
    ShowErrors();
}


void LoadDocumentFiles(std::vector<std::wstring>&& fileList)
{
    auto movedFileList = std::move(fileList);
    ClearDocumentList();
    for (auto& fileName : movedFileList)
    {
        AppendSingleDocumentFile(fileName.c_str());
    }
    ShowErrors();
}


// Helper to append one canvas item per SVG document at the given pixel size.
void AppendCanvasItemsGivenSize(
    /*inout*/ std::vector<CanvasItem>& canvasItems,
    std::span<ImageOrSvgDocument const> images,
    uint32_t documentPixelSize
    )
{
    const uint32_t totalDocuments = static_cast<uint32_t>(images.size());

    for (uint32_t index = 0; index < totalDocuments; ++index)
    {
        auto& image = g_images[index];
        CanvasItem canvasItem =
        {
            .itemType = image.GetCanvasItemType(),
            .flags = CanvasItem::Flags::Default,
            .value = {.imageIndex = index},
            .w = documentPixelSize,
            .h = documentPixelSize,
        };
        canvasItems.push_back(std::move(canvasItem));
    }
}


// Generate all the items for the canvas given the current SVG documents, a bounding rectangle,
// flow direction, and bitmap sizing display. Layout of x,y coordinates occurs later.
void GenerateCanvasItems(
    RECT const& boundingRect,
    CanvasItem::FlowDirection flowDirection,
    /*out*/ std::vector<CanvasItem>& canvasItems
    )
{
    canvasItems.clear();

    constexpr uint32_t maximumSmallDigitNumbers = 4;
    const uint32_t maximumDigitPixelsWide = (g_smallDigitWidth + 1) * maximumSmallDigitNumbers;
    const uint32_t totalDocuments = static_cast<uint32_t>(g_images.size());
    const bool isHorizontalLayout = (flowDirection == CanvasItem::FlowDirection::RightDown);
    static_assert(uint32_t(CanvasItem::FlowDirection::Total) == 2);

    // Draw the image to a bitmap.
    switch (g_bitmapSizingDisplay)
    {
    case BitmapSizingDisplay::FixedSize:
        AppendCanvasItemsGivenSize(/*inout*/ canvasItems, g_images, g_bitmapSizePerDocument);
        break;

    case BitmapSizingDisplay::WaterfallObjectThenSize:
        if (totalDocuments > 0)
        {
            for (uint32_t bitmapSize : g_waterfallBitmapSizes)
            {
                if (bitmapSize > g_bitmapMaximumSize)
                    break;

                // Append a label of the current pixel size.
                CanvasItem labelCanvasItem =
                {
                    .itemType = CanvasItem::ItemType::SizeLabel,
                    .flags = CanvasItem::Flags::NewLine | CanvasItem::Flags::SetIndent,
                    .value = {.labelSize = bitmapSize},
                    .w = isHorizontalLayout ? maximumDigitPixelsWide : bitmapSize,
                    .h = isHorizontalLayout ? bitmapSize : g_smallDigitHeight,
                };
                canvasItems.push_back(std::move(labelCanvasItem));

                // Append all SVG documents or raster images at the current size.
                for (uint32_t index = 0; index < totalDocuments; ++index)
                {
                    auto& image = g_images[index];
                    CanvasItem svgCanvasItem =
                    {
                        .itemType = image.GetCanvasItemType(),
                        .flags = CanvasItem::Flags::Default,
                        .value = {.imageIndex = index},
                        .w = bitmapSize,
                        .h = bitmapSize,
                    };
                    canvasItems.push_back(std::move(svgCanvasItem));
                }
            }
        }
        break;

    case BitmapSizingDisplay::WaterfallSizeThenObject:
        {
            for (uint32_t index = 0; index < totalDocuments; ++index)
            {
                CanvasItem::Flags flags = CanvasItem::Flags::NewLine | CanvasItem::Flags::SetIndent;

                // Append all labels, one for each size.
                for (uint32_t bitmapSize : g_waterfallBitmapSizes)
                {
                    if (bitmapSize > g_bitmapMaximumSize)
                        break;

                    CanvasItem canvasItem =
                    {
                        .itemType = CanvasItem::ItemType::SizeLabel,
                        .flags = flags,
                        .value = {.labelSize = bitmapSize},
                        .w = !isHorizontalLayout ? maximumDigitPixelsWide : bitmapSize,
                        .h = !isHorizontalLayout ? bitmapSize : g_smallDigitHeight,
                    };
                    canvasItems.push_back(std::move(canvasItem));
                    flags = CanvasItem::Flags::Default;
                }

                flags = CanvasItem::Flags::NewLine | CanvasItem::Flags::SetIndent;

                // Append all SVG documents or raster images at the current size.
                for (uint32_t bitmapSize : g_waterfallBitmapSizes)
                {
                    if (bitmapSize > g_bitmapMaximumSize)
                        break;

                    auto& image = g_images[index];
                    CanvasItem canvasItem =
                    {
                        .itemType = image.GetCanvasItemType(),
                        .flags = flags,
                        .value = {.imageIndex = index},
                        .w = bitmapSize,
                        .h = bitmapSize,
                    };
                    canvasItems.push_back(std::move(canvasItem));
                    flags = CanvasItem::Flags::Default;
                }
            }
        }
        break;

    case BitmapSizingDisplay::WindowSize:
        {
            const uint32_t bitmapMaximumSize = std::min(boundingRect.bottom, boundingRect.right) / g_bitmapPixelZoom;
            AppendCanvasItemsGivenSize(canvasItems, g_images, bitmapMaximumSize);
        }
        break;

    case BitmapSizingDisplay::Natural:
        {
            AppendCanvasItemsGivenSize(canvasItems, g_images, /*documentPixelSize*/ 0);

            // Set the height and width each of canvas item to its natural dimensions.
            for (uint32_t index = 0; index < totalDocuments; ++index)
            {
                auto& canvasItem = canvasItems[index];
                auto& image = g_images[index];
                switch (image.GetCanvasItemType())
                {
                case CanvasItem::ItemType::SvgDocument:
                    {
                        lunasvg::Document& document = image.GetReference<lunasvg::Document>();
                        canvasItem.w = static_cast<uint32_t>(std::ceil(document.width()));
                        canvasItem.h = static_cast<uint32_t>(std::ceil(document.height()));
                    }
                    break;

                case CanvasItem::ItemType::RasterImage:
                    {
                        RasterImage& rasterImage = image.GetReference<RasterImage>();
                        canvasItem.w = rasterImage.width;
                        canvasItem.h = rasterImage.height;
                    }
                    break;
                }
            }
        }
        break;
    }
}


// Lay all the canvas item positions by flow direction.
void LayoutCanvasItems(
    RECT const& boundingRect,
    CanvasItem::FlowDirection flowDirection,
    /*inout*/ std::span<CanvasItem> canvasItems
    )
{
    assert(boundingRect.left == 0 && boundingRect.top == 0);
    const uint32_t bitmapMaximumVisibleWidth = boundingRect.right / g_bitmapPixelZoom;
    const uint32_t bitmapMaximumVisibleHeight = boundingRect.bottom / g_bitmapPixelZoom;

    uint32_t x = 0, y = 0; // Current canvas item's top left.
    uint32_t indentX = 0, indentY = 0;
    RECT lineRect = {}; // Accumulated rect of current line (row or column until next wrap).

    for (size_t canvasItemIndex = 0, itemCount = canvasItems.size(); canvasItemIndex < itemCount; ++canvasItemIndex)
    {
        auto& canvasItem = canvasItems[canvasItemIndex];
        uint32_t nextX = x, nextY = y;
        const bool isNewLine = bool(canvasItem.flags & CanvasItem::Flags::NewLine);
        const bool hasSetIndent = bool(canvasItem.flags & CanvasItem::Flags::SetIndent);

        switch (flowDirection)
        {
        case CanvasItem::FlowDirection::RightDown:
            if (x + canvasItem.w > bitmapMaximumVisibleWidth || isNewLine)
            {
                if (isNewLine)
                {
                    indentX = 0;
                }
                if (lineRect.right > int32_t(indentX))
                {
                    x = indentX;
                    y = lineRect.bottom;
                    nextY = y;
                    lineRect = {};
                }
            }
            nextX = x + canvasItem.w;
            if (hasSetIndent)
            {
                indentX = nextX;
            }
            break;

        case CanvasItem::FlowDirection::DownRight:
            if (y + canvasItem.h > bitmapMaximumVisibleHeight || isNewLine)
            {
                if (isNewLine)
                {
                    indentY = 0;
                }
                if (lineRect.bottom > int32_t(indentY))
                {
                    y = indentY;
                    x = lineRect.right;
                    nextX = x;
                    lineRect = {};
                }
            }
            nextY = y + canvasItem.h;
            if (hasSetIndent)
            {
                indentY = nextY;
            }
            break;
        };

        // Update the item position.
        canvasItem.x = x;
        canvasItem.y = y;

        // Accumulate the current line bounds with the item.
        RECT currentRect = ToRect(canvasItem);
        UnionRect(/*out*/&lineRect, &lineRect, &currentRect);

        // Update the coordinates for the next item.
        x = nextX;
        y = nextY;
    }
}


// Compute the union of all canvas items bounding rects to determine necessary bitmap size.
RECT DetermineCanvasItemsBoundingRect(std::span<CanvasItem const> canvasItems)
{
    RECT boundingRect = {};
    for (auto& canvasItem : canvasItems)
    {
        RECT currentRect = ToRect(canvasItem);
        UnionRect(/*out*/&boundingRect, &boundingRect, &currentRect);
    }
    return boundingRect;
}


// Returns the bounding rectangle of all canvas items that intersect the given rectangle.
// This is useful for highlighting based on a mouse selection/click.
RECT DetermineCanvasItemsRowBoundingRect(std::span<CanvasItem const> canvasItems, RECT const& intersectionRect)
{
    RECT boundingRect = {};
    RECT dummyRect = {};
    for (auto& canvasItem : canvasItems)
    {
        RECT currentRect = ToRect(canvasItem);
        if (IntersectRect(/*out*/ &dummyRect, &currentRect, &intersectionRect))
        {
            UnionRect(/*out*/&boundingRect, &boundingRect, &currentRect);
        }
    }
    return boundingRect;
}


// Redraw all canvas items into the given bitmap.
// The screen was already cleared.
void RedrawCanvasItems(std::span<CanvasItem const> canvasItems, lunasvg::Bitmap& bitmap)
{
    constexpr uint32_t maximumSmallDigitNumbers = 4;
    lunasvg::Bitmap subbitmap;
    const RECT bitmapRect = { 0, 0, LONG(bitmap.width()), LONG(bitmap.height()) };

    Gdiplus::Bitmap gdiplusSurface(bitmap.width(), bitmap.height(), bitmap.stride(), PixelFormat32bppPARGB, bitmap.data());
    Gdiplus::Graphics gdiplusGraphics(&gdiplusSurface);
    Gdiplus::ImageAttributes imageAttributes;
    imageAttributes.SetWrapMode(Gdiplus::WrapModeTileFlipXY); // Try WrapModeTileFlipXY if there are edges.
    gdiplusGraphics.SetInterpolationMode(Gdiplus::InterpolationModeBilinear);
    gdiplusGraphics.SetCompositingMode(Gdiplus::CompositingModeSourceOver); // TODO: use CompositingModeSourceCopy if no alpha for speed
    gdiplusGraphics.SetPixelOffsetMode(Gdiplus::PixelOffsetModeHalf); // Fix ridiculous default. Pixel corners are logical.

    for (const auto& canvasItem : canvasItems)
    {
        switch (canvasItem.itemType)
        {
        case CanvasItem::ItemType::SizeLabel:
            {
                uint32_t pixelSize = canvasItem.value.labelSize;

                char digits[maximumSmallDigitNumbers] = {};
                const auto result = std::to_chars(std::begin(digits), std::end(digits), pixelSize);
                const uint32_t digitCount = static_cast<uint32_t>(result.ptr - std::begin(digits));

                // Label is centered horizontally and vertically within canvas item box.
                uint32_t digitX = canvasItem.x + (canvasItem.w - g_smallDigitWidth * digitCount) / 2;
                uint32_t digitY = canvasItem.y + (canvasItem.h - g_smallDigitHeight) / 2;

                DrawSmallDigits(
                    bitmap.data(),
                    reinterpret_cast<char8_t const*>(digits),
                    digitCount,
                    digitX,
                    digitY,
                    bitmap.width(),
                    bitmap.height(),
                    bitmap.stride()
                );
            }
            break;

        case CanvasItem::ItemType::SvgDocument:
            if (g_rasterFillsStrokesVisible)
            {
                assert(canvasItem.value.imageIndex < g_images.size());
                auto& document = g_images[canvasItem.value.imageIndex].GetReference<lunasvg::Document>();

                // Draw the icon into a subrect of the larger atlas texture,
                // adjusting the pointer offset while keeping the correct stride.
                // This will also force clipping into the item's window.
                RECT subbitmapRect = ToRect(canvasItem);
                if (IntersectRect(/*out*/&subbitmapRect, &subbitmapRect, &bitmapRect))
                {
                    uint32_t pixelOffset = subbitmapRect.top * g_bitmap.stride() + subbitmapRect.left * sizeof(PixelBgra);
                    SIZE subbitmapSize = ToSize(subbitmapRect);
                    subbitmap.reset(
                        bitmap.data() + pixelOffset,
                        subbitmapSize.cx,
                        subbitmapSize.cy,
                        bitmap.stride()
                    );

                    // TODO: Check g_snapToPixels to pass pixel snapping flags to document::render.
                    auto matrix = GetMatrixForSize(document, canvasItem.w, canvasItem.h);
                    document.render(subbitmap, matrix);
                }
            }
            break;

        case CanvasItem::ItemType::RasterImage:
            {
                assert(canvasItem.value.imageIndex < g_images.size());
                auto& rasterImage = g_images[canvasItem.value.imageIndex].GetReference<RasterImage>();

                RECT subbitmapRect = ToRect(canvasItem);
                if (IntersectRect(/*out*/&subbitmapRect, &subbitmapRect, &bitmapRect))
                {
                    Gdiplus::Bitmap gdiplusImage(
                        int(rasterImage.width),
                        int(rasterImage.height),
                        int(rasterImage.width * sizeof(PixelBgra)),
                        PixelFormat32bppPARGB,
                        reinterpret_cast<BYTE*>(rasterImage.pixels.get())
                    );

                    // Compute the target rectangle while keeping a 1:1 aspect ratio (no distortion).
                    Gdiplus::RectF destRect = ToGdiplusRectF(canvasItem);
                    float scaledHeight = rasterImage.height * destRect.Width / rasterImage.width;
                    if (scaledHeight < destRect.Height)
                    {
                        destRect.Height = scaledHeight;
                    }
                    else
                    {
                        destRect.Width = rasterImage.width * destRect.Height / rasterImage.height;
                    }

                    gdiplusGraphics.DrawImage(
                        &gdiplusImage,
                        destRect,
                        0.0f, 0.0f, float(rasterImage.width), float(rasterImage.height),
                        Gdiplus::UnitPixel,
                        &imageAttributes,
                        nullptr, // callback
                        nullptr // callbackData
                    );
                }
            }
            break;
        }
    }
}


// Redraw grids atop all canvas items into the given bitmap.
// Realign the offsets to the new bitmap size (typically after loading a new file)
// so the bitmap is either centered in the window or anchored at the top left,
// rather than randomly wherever it was last.
void RealignBitmapOffsets(RECT const& clientRect)
{
    const int32_t effectiveBitmapWidth = g_bitmap.width() * g_bitmapPixelZoom;
    const int32_t effectiveBitmapHeight = g_bitmap.height() * g_bitmapPixelZoom;
    g_bitmapOffsetX = std::min((effectiveBitmapWidth - clientRect.right) / 2, 0L);
    g_bitmapOffsetY = std::min((effectiveBitmapHeight - clientRect.bottom) / 2, 0L);
    g_realignBitmap = false;
    g_constrainBitmapOffsets = false;
}


// Realign offsets, using the HWND to get the client rectangle.
void RealignBitmapOffsets(HWND hwnd)
{
    RECT clientRect;
    GetClientRect(hwnd, &clientRect);
    RealignBitmapOffsets(clientRect);
}


// Constrain the bitmap offsets so they are visible (not recentered like RealignBitmapOffsets).
void ConstrainBitmapOffsets(RECT const& clientRect)
{
    const int32_t effectiveBitmapWidth = g_bitmap.width() * g_bitmapPixelZoom;
    const int32_t effectiveBitmapHeight = g_bitmap.height() * g_bitmapPixelZoom;
    g_bitmapOffsetX = std::clamp(g_bitmapOffsetX, std::min(effectiveBitmapWidth - int32_t(clientRect.right), 0), std::max(effectiveBitmapWidth - int32_t(clientRect.right), 0));
    g_bitmapOffsetY = std::clamp(g_bitmapOffsetY, std::min(effectiveBitmapHeight - int32_t(clientRect.bottom), 0), std::max(effectiveBitmapHeight - int32_t(clientRect.bottom), 0));

    g_constrainBitmapOffsets = false;
}


bool IsBitmapSizingDisplayResizeable(BitmapSizingDisplay bitmapSizeDisplay)
{
    switch (bitmapSizeDisplay)
    {
    case BitmapSizingDisplay::FixedSize: return g_bitmapSizeWrapped;
    case BitmapSizingDisplay::WindowSize: return true;
    case BitmapSizingDisplay::WaterfallObjectThenSize: return g_bitmapSizeWrapped;
    case BitmapSizingDisplay::WaterfallSizeThenObject: return g_bitmapSizeWrapped;
    case BitmapSizingDisplay::Natural: return g_bitmapSizeWrapped;
    default: return false;
    }
}


uint32_t GetBitmapSizingDisplaySize(BitmapSizingDisplay bitmapSizeDisplay, RECT const& clientRect)
{
    switch (bitmapSizeDisplay)
    {
    case BitmapSizingDisplay::Natural:
        if (!g_canvasItems.empty())
        {
            auto& canvasItem = g_canvasItems.front();
            auto w = canvasItem.w;
            auto h = canvasItem.h;
            return std::max(w, h);
        }
        [[fallthrough]];

    case BitmapSizingDisplay::FixedSize:
    case BitmapSizingDisplay::WaterfallObjectThenSize:
    case BitmapSizingDisplay::WaterfallSizeThenObject:
    default:
        return g_bitmapSizePerDocument;

    case BitmapSizingDisplay::WindowSize:
        return std::min(clientRect.bottom, clientRect.right) / g_bitmapPixelZoom;
    }
}


// Redraw the background behind the SVG, such as transparent black or checkerboard.
void RedrawBackground(lunasvg::Bitmap& bitmap)
{
    // When the alpha channel is visible, do not draw the opaque background,
    // which would otherwise show nothing but whiteness.
    if (g_showAlphaChannel)
    {
        bitmap.clear(0x00000000);
        return;
    }

    switch (g_backgroundColorMode)
    {
    case BackgroundColorMode::TransparentBlack:
        bitmap.clear(0x00000000);
        break;

    case BackgroundColorMode::GrayCheckerboard:
        DrawCheckerboardBackground(bitmap.data(), 0, 0, bitmap.width(), bitmap.height(), bitmap.stride());
        break;

    case BackgroundColorMode::OpaqueWhite:
    case BackgroundColorMode::OpaqueGray:
        // Beware LunaSvg uses backwards alpha (RGBA rather than ARGB) whereas
        // typically most pixel formats put the alpha in the *top* byte.
        bitmap.clear((g_backgroundColorMode == BackgroundColorMode::OpaqueGray) ? 0x808080FF : /*OpaqueWhite*/ 0xFFFFFFFF);
        break;
    }
}


void RedrawCanvasBackgroundAndItems(RECT const& clientRect)
{
    if (g_images.empty())
    {
        return;
    }

    // If any significant change happened, such as loading new SVG files,
    // recompute the positions of all the items, and recreate the bitmap
    // with the new size.
    if (g_relayoutCanvasItems)
    {
        // Keep a copy of the old canvas items for later comparison to see redraw is necessary.
        std::vector<CanvasItem> canvasItemsCopy;
        if (!g_canvasItemsNeedRedrawing)
        {
            canvasItemsCopy = g_canvasItems;
        }

        RECT const& layoutRect = g_bitmapSizeWrapped ? clientRect : RECT{0,0, INT_MAX, INT_MAX};
        GenerateCanvasItems(clientRect, g_canvasFlowDirection, /*inout*/g_canvasItems);
        LayoutCanvasItems(layoutRect, g_canvasFlowDirection, /*inout*/g_canvasItems);

        RECT boundingRect = DetermineCanvasItemsBoundingRect(g_canvasItems);
        // Limit bitmap size to avoid std::bad_alloc in case too many SVG files were loaded.
        boundingRect.right = std::min(boundingRect.right, 32768L);
        boundingRect.bottom = std::min(boundingRect.bottom, 32768L);

        bool bitmapChangedSize = (g_bitmap.width() != boundingRect.right || g_bitmap.height() != boundingRect.bottom);
        if (bitmapChangedSize)
        {
            g_bitmap.reset(boundingRect.right, boundingRect.bottom);
            g_canvasItemsNeedRedrawing = true;
        }
        if (!g_canvasItemsNeedRedrawing && canvasItemsCopy != g_canvasItems)
        {
            // The relayout caused items to move around. So redraw.
            g_canvasItemsNeedRedrawing = true;
        }

        g_relayoutCanvasItems = false;
    }

    if (g_canvasItemsNeedRedrawing)
    {
        RedrawBackground(g_bitmap);
        RedrawCanvasItems(g_canvasItems, g_bitmap);
    }

    if (g_invertColors)
    {
        NegateBitmap(g_bitmap);
    }
    if (g_showAlphaChannel)
    {
        AlphaToGrayscale(g_bitmap);
    }
}


// Repaint the whole client rect later in WM_PAINT.
// This is useful for zooming.
void InvalidateClientRect(HWND hwnd)
{
    InvalidateRect(hwnd, nullptr, true);
}


// Repaint just the bitmap area in WM_PAINT, without redrawing the SVG
// or the background. This is useful for toggling the grid on/off.
void InvalidateClientRectBitmap(HWND hwnd)
{
    RECT invalidationRect =
    {
        LONG(-g_bitmapOffsetX),
        LONG(-g_bitmapOffsetY),
        LONG(g_bitmap.width()  * g_bitmapPixelZoom - LONG(g_bitmapOffsetX)),
        LONG(g_bitmap.height() * g_bitmapPixelZoom - LONG(g_bitmapOffsetY))
    };

    RECT clientRect;
    GetClientRect(hwnd, &clientRect);
    if (!IntersectRect(&invalidationRect, &invalidationRect, &clientRect))
    {
        // Force at least one pixel to be invalidated so the WM_PAINT is generated.
        invalidationRect.right = 1;
        invalidationRect.top = 1;
    }

    InvalidateRect(hwnd, &invalidationRect, true);
}


// Redraw all the SVG canvas items.
void RedrawCanvasItemsLater(HWND hwnd)
{
    g_canvasItemsNeedRedrawing = true;
    InvalidateClientRect(hwnd);
}


// Enqueue relayout and redrawing the SVG to the bitmap later in WM_PAINT.
void RelayoutAndRedrawCanvasItemsLater(HWND hwnd)
{
    g_relayoutCanvasItems = true;
    g_canvasItemsNeedRedrawing = true;
    InvalidateClientRect(hwnd);
}


void RelayoutCanvasItemsLater(HWND hwnd)
{
    g_relayoutCanvasItems = true;
    // Do not set g_canvasItemsNeedRedrawing because we only want that lazily
    // triggered when the layout changes the bitmap size.
    InvalidateClientRect(hwnd);
}


void RedrawCanvasBackgroundAndItems(HWND hwnd)
{
    // Redraw the SVG document(s) into the bitmap, computing the new bitmap size.

    RECT clientRect;
    GetClientRect(hwnd, /*out*/&clientRect);

    LARGE_INTEGER startTime;
    LARGE_INTEGER endTime;
    LARGE_INTEGER cpuFrequency;
    QueryPerformanceFrequency(&cpuFrequency);
    QueryPerformanceCounter(&startTime);

    RedrawCanvasBackgroundAndItems(clientRect);

    QueryPerformanceCounter(&endTime);
    double durationMs = static_cast<double>(endTime.QuadPart - startTime.QuadPart);
    durationMs /= static_cast<double>(cpuFrequency.QuadPart);
    durationMs *= 1000.0;
    wchar_t windowTitle[1000];
    wchar_t const* filename = !g_filenameList.empty() ? g_filenameList.front().c_str() : L"";
    _snwprintf_s(windowTitle, sizeof(windowTitle), L"%s - %1.3fms, %ux%u - %s", g_applicationTitle, durationMs, g_bitmap.width(), g_bitmap.height(), filename);
    SetWindowText(hwnd, windowTitle);

    InvalidateClientRectBitmap(hwnd);
    g_canvasItemsNeedRedrawing = false;
}


// Fill in a GDI BITMAPHEADER from the bitmap information.
void FillBitmapInfoFromLunaSvgBitmap(
    lunasvg::Bitmap const& bitmap,
    RECT const& clipRect,
    /*out*/ BITMAPHEADERv5& bitmapInfo
    )
{
    SIZE size = {LONG(bitmap.width()), LONG(bitmap.height())};
    size.cx   = std::min(clipRect.right, size.cx);
    size.cy   = std::min(clipRect.bottom, size.cy);
    size.cx  -= std::max(clipRect.left, LONG(0));
    size.cy  -= std::max(clipRect.top, LONG(0));
    LONG rowByteStride = (size.cx * sizeof(uint32_t) + 3) & ~3; // round to 4 byte multiple

    bitmapInfo.size = sizeof(bitmapInfo);
    bitmapInfo.width = size.cx;
    bitmapInfo.height = -size.cy;
    bitmapInfo.planes = 1;
    bitmapInfo.bitCount = 32;
    bitmapInfo.compression = BI_BITFIELDS;
    bitmapInfo.sizeImage = rowByteStride * size.cy;
    bitmapInfo.xPelsPerMeter = 3780;
    bitmapInfo.yPelsPerMeter = 3780;
    bitmapInfo.clrUsed = 0;
    bitmapInfo.clrImportant = 0;

    bitmapInfo.redMask = 0x00FF0000;
    bitmapInfo.greenMask = 0x0000FF00;
    bitmapInfo.blueMask = 0x000000FF;
    bitmapInfo.alphaMask = 0xFF000000;
    bitmapInfo.csType = LCS_WINDOWS_COLOR_SPACE;// LCS_sRGB;
    bitmapInfo.endpoints = {};
    bitmapInfo.gammaRed = 0; // Ignored unless csType == LCS_CALIBRATED_RGB.
    bitmapInfo.gammaGreen = 0; // Ignored unless csType == LCS_CALIBRATED_RGB.
    bitmapInfo.gammaBlue = 0; // Ignored unless csType == LCS_CALIBRATED_RGB.
    bitmapInfo.intent = LCS_GM_IMAGES;
    bitmapInfo.profileData = 0; // Ignored csType == PROFILE_LINKED or PROFILE_EMBEDDED.
    bitmapInfo.profileSize = 0;
    bitmapInfo.reserved = 0;
}


// Draw a rectangle minus the inner rectangle, filling in a frame.
// This 4-piece drawing eliminates the flicker would otherwise happen from
// filling the entire background followed by the image atop.
// ____________
// |  ______  |
// |  |    |  |
// |  |____|  |
// |__________|
//
void DrawRectangleAroundRectangle(
    HDC hdc,
    const RECT& outerRect,
    const RECT& innerRect,
    HBRUSH brush
    )
{
    RECT rects[4] =
    {
        /* Top */       { outerRect.left,  outerRect.top,    outerRect.right, innerRect.top, },
        /* Bottom */    { outerRect.left,  innerRect.bottom, outerRect.right, outerRect.bottom, },
        /* Left */      { outerRect.left,  innerRect.top,    innerRect.left,  innerRect.bottom, },
        /* Right */     { innerRect.right, innerRect.top,    outerRect.right, innerRect.bottom, },
    };

    for (auto& rect : rects)
    {
        if (!IsRectEmpty(&rect))
        {
            FillRect(hdc, &rect, brush);
        }
    }
}


// Why is using the clipboard so much more complicated than it ought to be?
void CopyBitmapToClipboard(
    lunasvg::Bitmap& bitmap,
    RECT const& clipRect,
    HWND hwnd
    )
{
    if (bitmap.valid())
    {
        if (OpenClipboard(hwnd))
        {
            EmptyClipboard();

            RECT clampedClipRect = {LONG(0), LONG(0), LONG(bitmap.width()), LONG(bitmap.height())};
            IntersectRect(/*out*/ &clampedClipRect, &clipRect, &clampedClipRect);

            BITMAPHEADERv5 bitmapInfo;
            FillBitmapInfoFromLunaSvgBitmap(bitmap, clampedClipRect, /*out*/bitmapInfo);

            uint32_t totalBytes = sizeof(bitmapInfo) + bitmapInfo.sizeImage;

            // Although DIB sections understand negative height just fine (the standard top-down image layout used by
            // most image formats), other programs sometimes choke when seeing it. IrfanView displays the image upside
            // down. XnView fails to load it. At least this happens on Windows 7, whereas later versions of IrfanView
            // appear on Windows 10 understand upside down images just fine. Word just displays an empty box with red X.
            bitmapInfo.height = abs(bitmapInfo.height);

            // InkScape does not recognize transparency anymore when setting BI_BITFIELDS
            // (even though it is identical to BI_RGB for 32-bit BGRA). So set it for compat.
            // If Word/Outlook/PowerPoint recognized transparency on BI_BITFIELDS, then I'd be
            // tempted to keep it anyway, but they always just display black pixels instead
            // (likely because they can't be sure whether to use premultiplied or not)
            // XnView recognizes transparency via BI_RGB or BI_BITFIELDS.
            bitmapInfo.compression = BI_RGB;

            HGLOBAL memory = GlobalAlloc(GMEM_MOVEABLE, totalBytes);
            if (memory != nullptr)
            {
                void* lockedMemory= GlobalLock(memory);
                if (lockedMemory != nullptr)
                {
                    assert(bitmapInfo.planes == 1);
                    assert(bitmapInfo.bitCount == 32);

                    // Copy the older bitmapinfo header (not v5) for greater compatibility with other
                    // applications reading the clipboard data.
                    auto& clipboardBitmapInfo = *reinterpret_cast<std::remove_reference_t<decltype(bitmapInfo)>*>(lockedMemory);
                    memcpy(&clipboardBitmapInfo, &bitmapInfo, sizeof(clipboardBitmapInfo));
                    clipboardBitmapInfo.size = sizeof(clipboardBitmapInfo);

                    // Point to the beginning of the pixel data.
                    uint8_t* clipboardPixels = reinterpret_cast<uint8_t*>(lockedMemory) + sizeof(clipboardBitmapInfo);
                    uint32_t const sourceBytesPerRow = bitmap.width() * bitmapInfo.bitCount / 8u;
                    uint32_t const destBytesPerRow = ((bitmapInfo.width * bitmapInfo.bitCount / 8u) + 3) & ~3u;
                    assert(bitmapInfo.height * destBytesPerRow == bitmapInfo.sizeImage);

                    // Copy the rows backwards for the sake of silly programs that don't understand top-down bitmaps.
                    uint8_t const* sourceBitmapData = bitmap.data() + bitmap.stride() * clampedClipRect.bottom + (bitmapInfo.bitCount * clampedClipRect.left / 8u);
                    for (uint32_t y = 0; y < uint32_t(bitmapInfo.height); ++y)
                    {
                        sourceBitmapData -= sourceBytesPerRow;
                        assert(sourceBitmapData >= bitmap.data());
                        memcpy(clipboardPixels, sourceBitmapData, destBytesPerRow);
                        clipboardPixels += destBytesPerRow;
                    }
                }
                GlobalUnlock(memory);

                SetClipboardData(CF_DIBV5, memory);
            }
            CloseClipboard();
        }
    }
}


// StretchBlt has a bug with larger scales where the aspect ratio becomes distorted if the
// total extents are greater than 32768 (e.g. 4000 bitmap width x 16 scale), even if 95%
// of the content is clipped/off screen. StretchDIBits instead just fails, and even for
// the smaller window draws the pixels incorrectly adjusted for top down bitmaps.
//
// So this near drop-in wrapper just virtually clips the stretch by adjusting the offsets
// and size according to the clip rect. Windows *should* just do this itself :/.
BOOL StretchBltFixed(
    HDC hdcDest,
    int destX,
    int destY,
    int destW,
    int destH,
    HDC hdcSrc,
    int srcX,
    int srcY,
    int srcW,
    int srcH,
    DWORD rop,
    RECT const& clipRect
    )
{
    if (srcW < 0 || srcH < 0 || destW < 0 || destH < 0)
    {
        return true; // No division by zero (would be an empty drawing anyway).
    }
    if (clipRect.right < clipRect.left || clipRect.bottom < clipRect.top)
    {
        return true; // No empty drawing.
    }

    auto adjustRangeToClip = [](
        int clipLeft,
        int clipRight,
        int& srcX,
        int& destX,
        int& srcW,
        int& destW
        )
    {
        if (destX < clipLeft)
        {
            int destOffsetX = clipLeft - destX;
            int srcOffsetX = int32_t(int64_t(destOffsetX) * srcW / destW);
            destOffsetX = int32_t(int64_t(srcOffsetX) * destW / srcW);
            destX += destOffsetX;
            destW -= destOffsetX;
            srcX += srcOffsetX;
            srcW -= srcOffsetX;
        }
        if (destX + destW > clipRight)
        {
            int destOffsetX = clipRight - destX;
            int srcOffsetX = int32_t((int64_t(destOffsetX) * srcW + destW - 1) / destW);
            destOffsetX = int32_t(int64_t(srcOffsetX) * destW / srcW);
            destW = destOffsetX;
            srcW = srcOffsetX;
        }
    };

    adjustRangeToClip(clipRect.left, clipRect.right, srcX, destX, srcW, destW);
    adjustRangeToClip(clipRect.top, clipRect.bottom, srcY, destY, srcH, destH);

    return StretchBlt(
        hdcDest,
        destX,
        destY,
        destW,
        destH,
        hdcSrc,
        srcX,
        srcY,
        srcW,
        srcH,
        rop
    );
}


// The cached bitmap is useful for frequent panning (rather than recreating it every WM_PAINT),
// but it can occupy megabytes of memory which are unnecessary when the application is inactive.
/*TIMERPROC*/void CALLBACK ReclaimCachedBitmapMemory(HWND hwnd, UINT uElapse, UINT_PTR uIDEvent, DWORD dwTime)
{
    KillTimer(hwnd, uIDEvent);
    DeleteObject(g_cachedScreenBitmap);
    g_cachedScreenBitmap = nullptr;
    g_cachedScreenBitmapPixels = nullptr;
}


std::tuple<
    HBITMAP /*bitmap*/,
    std::byte* /*pixels*/
>
CreateDIBSection32bpp(HDC memoryDc, SIZE size)
{
    BITMAPHEADERv3 memoryBitmapHeader =
    {
        .size = sizeof(memoryBitmapHeader),
        .width = size.cx,
        .height = -size.cy,
        .planes = 1,
        .bitCount = 32, // B,G,R,A
        .compression = BI_RGB,
        .sizeImage = size.cx * size.cy * sizeof(uint32_t),
        .xPelsPerMeter = 3780,
        .yPelsPerMeter = 3780,
        .clrUsed = 0,
        .clrImportant = 0,
    };

    std::byte* bitmapPixels = nullptr;
    HBITMAP bitmap = CreateDIBSection(
        nullptr, // memoryDc,
        reinterpret_cast<BITMAPINFO const*>(&memoryBitmapHeader),
        DIB_RGB_COLORS,
        reinterpret_cast<void**>(&bitmapPixels),
        nullptr,
        0
    );

    return {bitmap, bitmapPixels};
}


class GdiplusEnumerateContoursSink : public lunasvg::EnumerateContoursSink
{
private:
    Gdiplus::Graphics& graphics_;
    Gdiplus::Pen contourPen_{ Gdiplus::Color(0xFF0000FF), 0.0f }; // Blue
    Gdiplus::Pen nodePen_{ Gdiplus::Color(0xFFFFFF00), 0.0f }; // yellow
    Gdiplus::Pen handlePen_{ Gdiplus::Color(0xFFFF8000), 0.0f }; // orange
    Gdiplus::GraphicsPath contourPath_;
    Gdiplus::GraphicsPath nodePath_;
    Gdiplus::GraphicsPath handlePath_;
    Gdiplus::Matrix baseTransform_;
    Gdiplus::Matrix currentTransform_;
    float strokeScale_ = 1.0f;
    float effectiveStrokeScale_ = 1.0f; // Caller passed strokeScale_ scaled by current transform if small.

public:
    GdiplusEnumerateContoursSink(
        Gdiplus::Graphics& graphics,
        Gdiplus::Matrix const& transform,
        float strokeScale // Just affects path thickness - does not scale, which is done by the transform.
        )
    :   graphics_(graphics),
        strokeScale_(strokeScale)
    {
        // GDI+ seriously lacks a .SetElements(float*) method?? -_-
        float m[6];
        transform.GetElements(/*out*/ m);
        baseTransform_.SetElements(m[0], m[1], m[2], m[3], m[4], m[5]);
        currentTransform_.SetElements(m[0], m[1], m[2], m[3], m[4], m[5]);

        contourPen_.SetWidth(strokeScale_);
        nodePen_.SetWidth(strokeScale_);
        handlePen_.SetWidth(strokeScale_);
    }

    void DrawPointIndicator(double x, double y, float ellipseRadius = 0.5f)
    {
        Gdiplus::PointF point = {float(x), float(y)};
        currentTransform_.TransformPoints(&point);
        float const adjustedEllipseRadius = ellipseRadius * effectiveStrokeScale_;
        nodePath_.AddEllipse(
            float(point.X - adjustedEllipseRadius),
            float(point.Y - adjustedEllipseRadius),
            adjustedEllipseRadius * 2,
            adjustedEllipseRadius * 2
        );
    }

    void DrawDirectionIndicator(
        double baseX,
        double baseY,
        double nearX,
        double nearY,
        double farX,
        double farY,
        float triangleLength = 8.0f
        )
    {
        // x1/y1 is the initial point to draw from.
        // x2/y2 with x1/y1 form the vector direction.
        // x3/y3 with x1/y1 determine the vector lenth.
        Gdiplus::PointF triangleBase = {float(baseX), float(baseY)};
        Gdiplus::PointF nearPoint = {float(nearX), float(nearY)};
        Gdiplus::PointF farPoint = {float(farX), float(farY)};
        currentTransform_.TransformPoints(&triangleBase);
        currentTransform_.TransformPoints(&nearPoint);
        currentTransform_.TransformPoints(&farPoint);

        // Compute two directions for triangle head.
        Gdiplus::PointF primaryVector = nearPoint - triangleBase;
        Gdiplus::PointF farVector = farPoint - triangleBase;
        Gdiplus::PointF perpendicularVector = {primaryVector.Y, -primaryVector.X};

        // Normalize length for triangle size.
        // Ensure:
        // - the triangle points along the primary vector
        // - triangle length isn't greater than half the far vector length
        // - the scale doesn't blow up
        auto computeQuadrance = [](Gdiplus::PointF p) -> float { return (p.X * p.X) + (p.Y * p.Y);};
        float const maximumFarLengthFraction = 1.0f / 8.0f;
        float const primaryLength = sqrt(computeQuadrance(primaryVector));
        float const farLength = sqrt(computeQuadrance(farVector));
        float const finalTriangleLength = std::min(triangleLength * effectiveStrokeScale_, farLength * maximumFarLengthFraction);
        float const scale = finalTriangleLength / std::max(primaryLength, FLT_EPSILON);
        float const clampedScale = std::min(scale, 1.0f);

        // Scale triangle head.
        primaryVector.X *= clampedScale;
        primaryVector.Y *= clampedScale;
        perpendicularVector.X *= clampedScale / 2;
        perpendicularVector.Y *= clampedScale / 2;
        Gdiplus::PointF const triangleTip = triangleBase + primaryVector;
        Gdiplus::PointF const triangleFoot = triangleBase + perpendicularVector;

        // Draw the triangle head.
        nodePath_.StartFigure();
        nodePath_.AddLine(triangleBase, triangleTip);
        nodePath_.AddLine(triangleTip, triangleFoot);
        nodePath_.AddLine(triangleFoot, triangleBase);
        nodePath_.CloseFigure();
    }

    void SetTransform(const lunasvg::Matrix& transform) override
    {
        // Combine the base transform with the current path transform.
        currentTransform_.SetElements(float(transform.a), float(transform.b), float(transform.c), float(transform.d), float(transform.e), float(transform.f));
        currentTransform_.Multiply(&baseTransform_, Gdiplus::MatrixOrderAppend);
        graphics_.SetTransform(&currentTransform_);

        // Compute the effective stroke scale, so that really small transforms reduce the size of the strokes and indicators.
        float m[6];
        currentTransform_.GetElements(/*out*/ m);
        float majorScaleFactor = float(std::max(sqrt(m[0] * m[0] + m[1] * m[1]), sqrt(m[2] * m[2] + m[3] * m[3])));
        float clampedScaleFactor = std::min(majorScaleFactor, 1.0f);
        effectiveStrokeScale_ = strokeScale_ * clampedScaleFactor;

        // Invert the pen size, because otherwise GDI+ annoyingly scales the pen width along with the scaled outline.
        Gdiplus::Matrix* inverseTransform = currentTransform_.Clone();
        inverseTransform->Invert();
        if (majorScaleFactor < 1.0f)
        {
            inverseTransform->Scale(majorScaleFactor, majorScaleFactor, Gdiplus::MatrixOrderAppend);
        }
        contourPen_.SetTransform(inverseTransform);
        handlePen_.SetTransform(inverseTransform);
        delete inverseTransform;
    }

    void Begin() override
    {
        contourPath_.StartFigure();
    }

    void Move(double x, double y) override
    {
        DrawPointIndicator(x, y, /*ellipseRadius =*/ 2.0f);
        contourPath_.StartFigure();
    }

    void Line(double x1, double y1, double x2, double y2) override
    {
        contourPath_.AddLine(float(x1), float(y1), float(x2), float(y2));
        DrawPointIndicator(x2, y2);
        DrawDirectionIndicator(x1, y1, x2, y2, x2, y2);
    }

    void Cubic(double x1, double y1, double x2, double y2, double x3, double y3, double x4, double y4) override
    {
        contourPath_.AddBezier(float(x1), float(y1), float(x2), float(y2), float(x3), float(y3), float(x4), float(y4));

        // Draw handles
        handlePath_.StartFigure();
        handlePath_.AddLine(float(x1), float(y1), float(x2), float(y2));
        handlePath_.CloseFigure();
        handlePath_.StartFigure();
        handlePath_.AddLine(float(x3), float(y3), float(x4), float(y4));
        handlePath_.CloseFigure();

        // Draw nodes.
        DrawPointIndicator(x2, y2);
        DrawPointIndicator(x3, y3);
        DrawDirectionIndicator(x1, y1, x2, y2, x4, y4);
    }

    void Anchor(double x, double y) override
    {
        const float ellipseRadius = 2;
        Gdiplus::PointF point = { float(x), float(y) };
        currentTransform_.TransformPoints(&point);
        nodePath_.AddEllipse(float(x - ellipseRadius), float(y - ellipseRadius), ellipseRadius * 2, ellipseRadius * 2);
    }

    void Close() override
    {
        contourPath_.CloseFigure();
    }

    void End() override
    {
        if (contourPath_.GetPointCount() > 0
        ||  nodePath_.GetPointCount() > 0
        ||  handlePath_.GetPointCount() > 0)
        {
            graphics_.SetSmoothingMode(Gdiplus::SmoothingModeAntiAlias);

            graphics_.SetTransform(&currentTransform_);
            graphics_.DrawPath(&contourPen_, &contourPath_);
            graphics_.DrawPath(&handlePen_, &handlePath_);
            graphics_.ResetTransform();
            graphics_.DrawPath(&nodePen_, &nodePath_);

            // Clear all accumulated paths.
            contourPath_.Reset();
            nodePath_.Reset();
            handlePath_.Reset();
        }
    }
};


void RepaintWindow(HWND hwnd)
{
    RECT clientRect;
    GetClientRect(hwnd, &clientRect);

    const bool shouldUpdateScrollBars = g_canvasItemsNeedRedrawing | g_realignBitmap | g_constrainBitmapOffsets;

    if (g_canvasItemsNeedRedrawing || g_relayoutCanvasItems)
    {
        RedrawCanvasBackgroundAndItems(hwnd);
    }

    if (g_realignBitmap)
    {
        RealignBitmapOffsets(clientRect);
    }

    if (g_constrainBitmapOffsets)
    {
        ConstrainBitmapOffsets(clientRect);
    }

    if (shouldUpdateScrollBars)
    {
        UpdateBitmapScrollbars(hwnd);
    }

    HRGN updateRegion = CreateRectRgn(0, 0, 0, 0);
    GetUpdateRgn(hwnd, updateRegion, false);
    auto cleanupUpdateRegion = DeferCleanup([=]() {DeleteRgn(updateRegion); });

    PAINTSTRUCT ps;
    HDC hdc = BeginPaint(hwnd, &ps);
    auto cleanupBeginPaint = DeferCleanup([=, &ps]() {EndPaint(hwnd, &ps); });

    HDC memoryDc = CreateCompatibleDC(hdc); // Buffer the drawing to avoid flickering.
    auto cleanupMemoryDc = DeferCleanup([=]() {DeleteDC(memoryDc); });

    // Clear the existing bitmap if a bigger one is needed.
    if (clientRect.right > g_cachedScreenBitmapSize.cx
    ||  clientRect.bottom > g_cachedScreenBitmapSize.cy)
    {
        if (g_cachedScreenBitmap != nullptr)
        {
            DeleteObject(g_cachedScreenBitmap);
            g_cachedScreenBitmap = nullptr;
        }
        g_cachedScreenBitmapSize.cx = (clientRect.right + 15) & ~15;
        g_cachedScreenBitmapSize.cy = (clientRect.bottom + 15) & ~15;
    }

    // Create the temporary composited bitmap.
    // Use a DIB section instead of CreateCompatibleBitmap because:
    // a. StretchDIBits incorrectly draws the content upside-down because the source is top-down.
    // b. SetPixel is very slow, leaving us to set the pixels directly instead.
    if (g_cachedScreenBitmap == nullptr)
    {
        std::tie(g_cachedScreenBitmap, g_cachedScreenBitmapPixels) = CreateDIBSection32bpp(memoryDc, g_cachedScreenBitmapSize);
        if (g_cachedScreenBitmap == nullptr)
        {
            return; // Can't do anything about it. So at least don't crash.
        }
    }
    HBITMAP memoryBitmap = g_cachedScreenBitmap;
    std::byte* memoryBitmapPixels = g_cachedScreenBitmapPixels;
    const uint32_t memoryBitmapRowByteStride = uint32_t(g_cachedScreenBitmapSize.cx) * sizeof(PixelBgra);

    SelectObject(memoryDc, memoryBitmap);
    SetStretchBltMode(memoryDc, COLORONCOLOR);
    SetGraphicsMode(memoryDc, GM_COMPATIBLE);
    SetBkMode(memoryDc, TRANSPARENT);

    // Display message if no SVG document loaded.
    if (!g_bitmap.valid())
    {
        FillRect(memoryDc, &clientRect, g_backgroundWindowBrush);
        HFONT oldFont = static_cast<HFONT>(SelectObject(memoryDc, GetStockObject(DEFAULT_GUI_FONT)));
        const LONG padding = 4;
        RECT textRect = {clientRect.left + padding, clientRect.top + padding, clientRect.right - padding, clientRect.bottom - padding};
        DrawText(memoryDc, g_defaultMessage.data(), int(g_defaultMessage.size()), &textRect, DT_NOCLIP | DT_NOPREFIX | DT_WORDBREAK);
        SelectObject(memoryDc, oldFont);
    }
    // Draw bitmap.
    else // g_bitmap.valid()
    {
        BITMAPHEADERv5 bitmapInfo = {};
        FillBitmapInfoFromLunaSvgBitmap(g_bitmap, {0, 0, INT_MAX, INT_MAX}, /*out*/ bitmapInfo);

        // Erase background around drawing.
        const uint32_t effectiveBitmapWidth  = g_bitmap.width() * g_bitmapPixelZoom;
        const uint32_t effectiveBitmapHeight = g_bitmap.height() * g_bitmapPixelZoom;
        RECT bitmapRect = {0L, 0L, LONG(effectiveBitmapWidth), LONG(effectiveBitmapHeight)};
        OffsetRect(&bitmapRect, -g_bitmapOffsetX, -g_bitmapOffsetY);
        DrawRectangleAroundRectangle(memoryDc, ps.rcPaint, bitmapRect, g_backgroundWindowBrush);

        // Wrap the source and target bitmap (no extra copy) to draw at current zoom.
        // GDI+ DrawImage appears to be much faster than GDI StretchBlt without the bugs for large images.
        Gdiplus::Bitmap gdiplusSurface(INT(g_cachedScreenBitmapSize.cx), INT(g_cachedScreenBitmapSize.cy), memoryBitmapRowByteStride, PixelFormat32bppPARGB, reinterpret_cast<BYTE*>(memoryBitmapPixels));
        Gdiplus::Bitmap gdiplusImage(INT(g_bitmap.width()), INT(g_bitmap.height()), INT(g_bitmap.width() * sizeof(PixelBgra)), PixelFormat32bppPARGB, reinterpret_cast<BYTE*>(g_bitmap.data()));
        Gdiplus::Graphics gdiplusGraphics(&gdiplusSurface);
        Gdiplus::ImageAttributes imageAttributes;
        imageAttributes.SetWrapMode(Gdiplus::WrapModeClamp);
        gdiplusGraphics.SetInterpolationMode(Gdiplus::InterpolationModeNearestNeighbor);
        gdiplusGraphics.SetCompositingMode(Gdiplus::CompositingModeSourceCopy);
        gdiplusGraphics.SetPixelOffsetMode(Gdiplus::PixelOffsetModeHalf); // Fix ridiculous default. Pixel corners are logical.

        gdiplusGraphics.DrawImage(
            &gdiplusImage,
            Gdiplus::Rect{ -g_bitmapOffsetX, -g_bitmapOffsetY, INT(g_bitmap.width() * g_bitmapPixelZoom), INT(g_bitmap.height() * g_bitmapPixelZoom) },
            0, 0, INT(g_bitmap.width()), INT(g_bitmap.height()),
            Gdiplus::UnitPixel,
            &imageAttributes,
            nullptr, // callback
            nullptr // callbackData
        );
    }

    auto GetCanvasItemRect = [](CanvasItem const& canvasItem)->RECT
    {
        const int32_t x = -g_bitmapOffsetX + canvasItem.x * g_bitmapPixelZoom;
        const int32_t y = -g_bitmapOffsetY + canvasItem.y * g_bitmapPixelZoom;
        const int32_t w = canvasItem.w * g_bitmapPixelZoom;
        const int32_t h = canvasItem.h * g_bitmapPixelZoom;
        return RECT{ x, y, x + w, y + h };
    };

    // Draw the grid.
    int32_t gridSize = (g_gridSize > 0) ? g_gridSize : INT32_MAX / 2;
    int32_t gridSpacing = std::min(LONG(gridSize), clientRect.right) * g_bitmapPixelZoom;
    if (g_gridVisible || g_pixelGridVisible)
    {
        gridSpacing = std::max(gridSpacing, 2);

        GdiFlush();
        for (const auto& canvasItem : g_canvasItems)
        {
            switch (canvasItem.itemType)
            {
            case CanvasItem::ItemType::SvgDocument:
            case CanvasItem::ItemType::RasterImage:
                {
                    const RECT itemRect = GetCanvasItemRect(canvasItem);
                    RECT gridRectDummy; // We don't care about the values, just the boolean result.
                    if (!IntersectRect(/*out*/&gridRectDummy, &itemRect, &clientRect))
                    {
                        continue; // Off-screen.
                    }

                    if (g_gridVisible)
                    {
                        // Draw internal grid.
                        DrawGridFast32bpp(itemRect, gridSpacing, gridSpacing, 0x00000000, /*drawLines:*/true, memoryBitmapPixels, memoryBitmapRowByteStride, clientRect);

                        // Draw item border.
                        const uint32_t w = itemRect.right - itemRect.left;
                        const uint32_t h = itemRect.bottom - itemRect.top;
                        DrawGridFast32bpp(itemRect, w - 1, h - 1, 0xFF0080FF, /*drawLines:*/true, memoryBitmapPixels, memoryBitmapRowByteStride, clientRect);
                    }
                    if (g_pixelGridVisible && g_bitmapPixelZoom > 1)
                    {
                        // Draw internal points.
                        DrawGridFast32bpp(itemRect, g_bitmapPixelZoom, g_bitmapPixelZoom, 0x00000000, /*drawLines:*/false, memoryBitmapPixels, memoryBitmapRowByteStride, clientRect);
                    }
                }
                break;
            }
        }
    }

    // Draw outlines of each document.
    if (g_outlinesVisible)
    {
        GdiFlush();
        Gdiplus::Graphics graphics(memoryDc);
        graphics.SetPixelOffsetMode(Gdiplus::PixelOffsetModeHalf); // Fix ridiculous default. Pixel corners are logical.

        // Could use the DPI or screen size to enlarge the strokes...
        //  int const horizontalSize = GetDeviceCaps(ps.hdc, HORZRES);
        //  float const strokeScale = (horizontalSize > 2048) ? float(horizontalSize) / 2048 : 1.0f;
        // ...but keeping 1.0 for now.
        float const strokeScale = 1.0f;

        for (const auto& canvasItem : g_canvasItems)
        {
            switch (canvasItem.itemType)
            {
            case CanvasItem::ItemType::SvgDocument:
                {
                    assert(canvasItem.value.imageIndex < g_images.size());
                    auto const& document = g_images[canvasItem.value.imageIndex].GetReference<lunasvg::Document>();

                    RECT const itemRect = GetCanvasItemRect(canvasItem);
                    RECT gridRectDummy; // We don't care about the values, just the boolean result.

                    if (IntersectRect(/*out*/&gridRectDummy, &itemRect, &clientRect) && RectInRegion(updateRegion, &itemRect))
                    {
                        Gdiplus::Matrix const gdipMatrix(float(g_bitmapPixelZoom), 0, 0, float(g_bitmapPixelZoom), float(itemRect.left), float(itemRect.top));
                        GdiplusEnumerateContoursSink contourSink(graphics, gdipMatrix, strokeScale);

                        auto const svgMatrix = GetMatrixForSize(document, canvasItem.w, canvasItem.h);
                        document.enumerateContours(contourSink, svgMatrix);
                    }
                }
                break;
            }
        }
    }

    // Draw selection rectangle.
    if (g_isRightDragging)
    {
        RECT startMouseRect = {g_selectionStartMouseX, g_selectionStartMouseY, g_selectionStartMouseX + 1, g_selectionStartMouseY + 1};
        RECT mouseRect = {g_previousMouseX, g_previousMouseY, g_previousMouseX + 1, g_previousMouseY + 1};
        UnionRect(/*out*/ &mouseRect, &startMouseRect, &mouseRect);

        const uint32_t w = mouseRect.right - mouseRect.left;
        const uint32_t h = mouseRect.bottom - mouseRect.top;
        DrawGridFast32bpp(mouseRect, w - 1, h - 1, 0xFF0080FF, /*drawLines:*/true, memoryBitmapPixels, memoryBitmapRowByteStride, clientRect);
    }

    // Draw composited image to screen.
    BitBlt(ps.hdc, 0, 0, clientRect.right, clientRect.bottom, memoryDc, 0, 0, SRCCOPY);

    // DeleteDC, EndPaint, DeleteRgn implicitly called by cleanup.

    // Don't call DeleteObject(memoryBitmap) immediately, in case the user
    // is actively panning or resizing the window. Rather, delete this object later
    // after 1 second.
    SetTimer(hwnd, WM_PAINT, 1000, &ReclaimCachedBitmapMemory);
}


// Update the menu items to reflect actual program state.
// (Win32 really ought to have a better way to link menu item state to program state)
void InitializePopMenu(HWND hwnd, HMENU hmenu, uint32_t indexInTopLevelMenu)
{
    MENUITEMINFO menuItemInfo =
    {
        .cbSize = sizeof(menuItemInfo),
        .fMask = MIIM_ID,
    };

    // GetMenuItemID should work but it's useless because it doesn't return the id of menu
    // items that open submenus (face palm, win32 API). So use GetMenuItemInfo instead.
    if (!GetMenuItemInfo(GetMenu(hwnd), indexInTopLevelMenu, true, &menuItemInfo))
    {
        return;
    }
    uint32_t parentMenuId = menuItemInfo.wID;

    struct MenuItemData
    {
        uint32_t parentMenuId;
        uint32_t menuItemIdFirst;
        uint32_t menuItemIdLast;
        uint32_t(*valueGetter)();
    };
    const MenuItemData menuItemData[] =
    {
        {IDM_GRID, IDM_GRID_VISIBLE, 0, []() -> uint32_t {return uint32_t(g_gridVisible); }},
        {IDM_GRID, IDM_PIXEL_GRID_VISIBLE, 0, []() -> uint32_t {return uint32_t(g_pixelGridVisible); }},
        {IDM_BACKGROUND, IDM_BACKGROUND_FIRST, IDM_BACKGROUND_LAST, []() -> uint32_t {return uint32_t(g_backgroundColorMode); }},
        {IDM_BACKGROUND, IDM_INVERT_COLORS, 0, []() -> uint32_t {return uint32_t(g_invertColors); }},
        {IDM_BACKGROUND, IDM_SHOW_ALPHA_CHANNEL, 0, []() -> uint32_t {return uint32_t(g_showAlphaChannel); }},
        {IDM_SIZE, IDM_SIZE_FIRST, IDM_SIZE_LAST, []() -> uint32_t {return g_bitmapSizingDisplay == BitmapSizingDisplay::FixedSize ? uint32_t(FindValueIndexGE<uint32_t>(g_waterfallBitmapSizes, g_bitmapSizePerDocument)) : 0xFFFFFFFF; }},
        {IDM_SIZE, IDM_SIZE_DISPLAY_FIRST, IDM_SIZE_DISPLAY_LAST, []() -> uint32_t {return uint32_t(g_bitmapSizingDisplay); }},
        {IDM_SIZE, IDM_SIZE_WRAPPED, 0, []() -> uint32_t {return uint32_t(g_bitmapSizeWrapped); }},
        {IDM_SIZE, IDM_SIZE_FLOW_FIRST, IDM_SIZE_FLOW_LAST, []() -> uint32_t {return uint32_t(g_canvasFlowDirection); }},
        {IDM_VIEW, IDM_ZOOM_FIRST, IDM_ZOOM_LAST, []() -> uint32_t {return uint32_t(FindValueIndexGE<uint32_t>(g_zoomFactors, g_bitmapPixelZoom)); }},
        {IDM_VIEW, IDM_OUTLINES_VISIBLE, 0, []() -> uint32_t {return uint32_t(g_outlinesVisible); }},
        {IDM_VIEW, IDM_RASTER_FILLS_STROKES_VISIBLE, 0, []() -> uint32_t {return uint32_t(g_rasterFillsStrokesVisible); }},
        {IDM_GRID, IDM_GRID_SIZE_FIRST, IDM_GRID_SIZE_LAST, []() -> uint32_t {return uint32_t(FindValueIndexGE<uint32_t>(g_gridSizes, g_gridSize)); }},
    };

    for (auto& menuItem : menuItemData)
    {
        if (parentMenuId == menuItem.parentMenuId)
        {
            uint32_t value = menuItem.valueGetter();
            // If the id is a range, select the given option.
            // Otherwise treat it as a checkbox.
            if (menuItem.menuItemIdLast >= menuItem.menuItemIdFirst)
            {
                CheckMenuRadioItem(hmenu, menuItem.menuItemIdFirst, menuItem.menuItemIdLast, menuItem.menuItemIdFirst + value, MF_BYCOMMAND);
            }
            else
            {
                CheckMenuItem(hmenu, menuItem.menuItemIdFirst, MF_BYCOMMAND | (value ? MF_CHECKED : MF_UNCHECKED));
            }
        }
    }
}


// Handle 1D scrolling, like grabbing a horizontal or vertical scroll bar.
void HandleBitmapScrolling(HWND hwnd, uint32_t scrollBarCode, int32_t delta, bool isHorizontal)
{
    const uint32_t scrollBarType = isHorizontal ? SB_HORZ : SB_VERT;
    int32_t& currentOffsetRef = isHorizontal ? g_bitmapOffsetX : g_bitmapOffsetY;
    const int32_t previousOffset = currentOffsetRef;
    const int32_t currentOffset = HandleScrollbarEvent(hwnd, scrollBarCode, scrollBarType, delta);

    if (previousOffset != currentOffset)
    {
        currentOffsetRef = currentOffset;
        const int32_t offsetDelta = previousOffset - currentOffset;
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
        UpdateBitmapScrollbars(hwnd);
    }
}


// Handle 2D scrolling like mouse drag.
void HandleBitmapScrolling(HWND hwnd, int32_t deltaX, int32_t deltaY)
{
    if (deltaX == 0 && deltaY == 0)
    {
        return; // Nop.
    }

    // Clamp the adjustments to the new bitmap offset.
    auto updateOffset = [](HWND hwnd, uint32_t scrollBarType, int32_t previousOffset, int32_t delta) -> int32_t
    {
        SCROLLINFO scrollInfo = { sizeof(scrollInfo), SIF_ALL };
        GetScrollInfo(hwnd, scrollBarType, &scrollInfo);
        return std::clamp(previousOffset + delta, scrollInfo.nMin, int32_t(scrollInfo.nMax - scrollInfo.nPage));
    };
    int32_t newBitmapOffsetX = updateOffset(hwnd, SB_HORZ, g_bitmapOffsetX, deltaX);
    int32_t newBitmapOffsetY = updateOffset(hwnd, SB_VERT, g_bitmapOffsetY, deltaY);
    deltaX = g_bitmapOffsetX - newBitmapOffsetX;
    deltaY = g_bitmapOffsetY - newBitmapOffsetY;

    if (deltaX != 0 || deltaY != 0)
    {
        g_bitmapOffsetX = newBitmapOffsetX;
        g_bitmapOffsetY = newBitmapOffsetY;
        ScrollWindowEx(
            hwnd,
            deltaX,
            deltaY,
            nullptr, // prcScroll,
            nullptr, // prcClip,
            nullptr, // hrgnUpdate,
            nullptr, // prcUpdate
            SW_ERASE | SW_INVALIDATE
        );
        UpdateBitmapScrollbars(hwnd);
    }
}


void OnMouseWheel(HWND hwnd, int32_t cursorX, int32_t cursorY, int32_t delta, uint32_t keyFlags)
{
    // Adjust zoom.
    if (keyFlags & MK_CONTROL)
    {
        int32_t zDelta = delta;
        auto newPixelZoom = FindValueNextPrevious<uint32_t>(g_zoomFactors, g_bitmapPixelZoom, zDelta > 0 ? 1 : -1);
        if (newPixelZoom != g_bitmapPixelZoom)
        {
            // Adjust mouse message coordinates from desktop to window-relative.
            POINT mouseCoordinate = { cursorX, cursorY };
            ScreenToClient(hwnd, &mouseCoordinate);

            // Clamp the zoom origin to the actual bitmap size.
            const int32_t effectiveBitmapWidth = g_bitmap.width() * g_bitmapPixelZoom;
            const int32_t effectiveBitmapHeight = g_bitmap.height() * g_bitmapPixelZoom;
            mouseCoordinate.x = std::clamp(int32_t(mouseCoordinate.x), -g_bitmapOffsetX, effectiveBitmapWidth - g_bitmapOffsetX);
            mouseCoordinate.y = std::clamp(int32_t(mouseCoordinate.y), -g_bitmapOffsetY, effectiveBitmapHeight - g_bitmapOffsetY);

            // Compute zoom origin based on mouse cursor (not just the top/left of the current view like some apps).
            g_bitmapOffsetX = (g_bitmapOffsetX + mouseCoordinate.x) * newPixelZoom / g_bitmapPixelZoom - mouseCoordinate.x;
            g_bitmapOffsetY = (g_bitmapOffsetY + mouseCoordinate.y) * newPixelZoom / g_bitmapPixelZoom - mouseCoordinate.y;
            g_bitmapPixelZoom = newPixelZoom;
            InvalidateClientRect(hwnd);
            UpdateBitmapScrollbars(hwnd);
        }
    }
    // Normal mouse wheel, vertical or horizontal.
    else
    {
        int32_t zDelta = -delta * int32_t(g_bitmapScrollStep) / WHEEL_DELTA;
        HandleBitmapScrolling(hwnd, SB_LINEDOWN, zDelta, /*isHorizontal*/ keyFlags & MK_SHIFT);
    }
}


void ChangeBitmapZoomCentered(HWND hwnd, uint32_t newBitmapPixelZoom)
{
    if (newBitmapPixelZoom == g_bitmapPixelZoom)
    {
        return; // Nop.
    }

    // Compute the centerpoint of the window.
    RECT clientRect;
    GetClientRect(hwnd, &clientRect);
    uint32_t centerX = clientRect.right / 2;
    uint32_t centerY = clientRect.bottom / 2;
    g_bitmapOffsetX = (g_bitmapOffsetX + centerX) * newBitmapPixelZoom / g_bitmapPixelZoom - centerX;
    g_bitmapOffsetY = (g_bitmapOffsetY + centerY) * newBitmapPixelZoom / g_bitmapPixelZoom - centerY;
    g_bitmapPixelZoom = newBitmapPixelZoom;
    ConstrainBitmapOffsets(clientRect);

    InvalidateClientRect(hwnd);
    UpdateBitmapScrollbars(hwnd);
}


CanvasItem* GetCanvasItemAtPoint(int32_t pointX, int32_t pointY)
{
    for (auto& canvasItem : g_canvasItems)
    {
        if (canvasItem.ContainsPoint(pointX, pointY))
        {
            return &canvasItem;
        }
    }
    return nullptr;
}


POINT ClientSpaceMouseCoordinateToImageCoordinate(int32_t mouseX, int32_t mouseY)
{
    LONG const canvasPointX = (mouseX + g_bitmapOffsetX) / g_bitmapPixelZoom;
    LONG const canvasPointY = (mouseY + g_bitmapOffsetY) / g_bitmapPixelZoom;
    return {canvasPointX, canvasPointY};
}

void ShowClickedCanvasItem(HWND hwnd, int32_t mouseX, int32_t mouseY)
{
    // Find which canvas item was clicked after rescaling mouse coordinates.
    double const canvasPointX = double(mouseX + g_bitmapOffsetX) / g_bitmapPixelZoom;
    double const canvasPointY = double(mouseY + g_bitmapOffsetY) / g_bitmapPixelZoom;
    int32_t const intCanvasPointX = int32_t(canvasPointX);
    int32_t const intCanvasPointY = int32_t(canvasPointY);
    CanvasItem* canvasItem = GetCanvasItemAtPoint(intCanvasPointX, intCanvasPointY);

    if (canvasItem == nullptr || canvasItem->itemType == CanvasItem::ItemType::SizeLabel)
    {
        wchar_t windowTitle[1000];
        _snwprintf_s(
            windowTitle,
            sizeof(windowTitle),
            L"%s - (%0.2f,%0.2f) %ux%u - (background)",
            g_applicationTitle,
            canvasPointX,
            canvasPointY,
            g_bitmap.width(),
            g_bitmap.height()
        );
        SetWindowText(hwnd, windowTitle);

        return;
    }

    uint32_t const imageIndex = canvasItem->value.imageIndex;
    assert(imageIndex < g_images.size());
    assert(imageIndex < g_filenameList.size());

    // Get both the scaled size from the canvas item and the original image size.
    uint32_t const canvasItemWidth = canvasItem->w;
    uint32_t const canvasItemHeight = canvasItem->h;
    double imageWidth;
    double imageHeight;

    switch (canvasItem->itemType)
    {
    case CanvasItem::ItemType::RasterImage:
        {
            auto& image = g_images[imageIndex].GetReference<RasterImage>();
            imageWidth = image.width;
            imageHeight = image.height;
        }
        break;

    case CanvasItem::ItemType::SvgDocument:
        {
            auto& image = g_images[imageIndex].GetReference<lunasvg::Document>();
            imageWidth = image.width();
            imageHeight = image.height();
        }
        break;

    default:
        return;
    }

    // Get pixel color at clicked coordinate in bitmap.
    uint32_t redValue   = 0;
    uint32_t greenValue = 0;
    uint32_t blueValue  = 0;
    uint32_t alphaValue = 0;
    uint32_t const bitmapHeight = g_bitmap.height();
    uint32_t const bitmapWidth = g_bitmap.width();
    if (uint32_t(intCanvasPointX) <= bitmapWidth && uint32_t(intCanvasPointY) <= bitmapHeight)
    {
        size_t const byteOffset = intCanvasPointY * g_bitmap.stride() + intCanvasPointX * sizeof(PixelBgra);
        PixelBgra const pixel = *reinterpret_cast<PixelBgra const*>(g_bitmap.data() + byteOffset);
        redValue   = pixel.r;
        greenValue = pixel.g;
        blueValue  = pixel.b;
        alphaValue = pixel.a;
    }
    
    // Remap screen pixel coordinate back to original image coordinate.
    double const canvasItemPointX = canvasPointX - canvasItem->x;
    double const canvasItemPointY = canvasPointY - canvasItem->y;
    double const imagePointX = canvasItemPointX * imageWidth / canvasItemWidth;
    double const imagePointY = canvasItemPointY * imageHeight / canvasItemHeight;
    wchar_t const* fileName = g_filenameList[imageIndex].c_str();

    wchar_t windowTitle[1000];
    _snwprintf_s(
        windowTitle,
        sizeof(windowTitle),
        L"%s - (%0.2f,%0.2f) %ux%upx - (%0.2f,%0.2f) %0.2fx%0.2fus - r%u g%u b%u a%u - %s",
        g_applicationTitle,
        canvasItemPointX,
        canvasItemPointY,
        canvasItemWidth,
        canvasItemHeight,
        imagePointX,
        imagePointY,
        imageWidth,
        imageHeight,
        redValue,
        greenValue,
        blueValue,
        alphaValue,
        fileName
    );
    SetWindowText(hwnd, windowTitle);
}


// Processes messages for the main window.
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

            case IDM_OPEN_FILE:
                {
                    wchar_t fileNameBuffer[32768];
                    fileNameBuffer[0] = '\0';
                    OPENFILENAME openFileName =
                    {
                        .lStructSize = sizeof(openFileName),
                        .hwndOwner = hwnd,
                        .hInstance = g_instanceHandle,
                        .lpstrFilter = L"Images (SVG, PNG, BMP, ICO, DDS, HDP, JPEG, TIFF, GIF)\0" L"*.svg;*.png;*.bmp;*.ico;*.dds;*.hdp;*.wdp;*.wmp;*.jpg;*.jpeg;*.tif;*.tiff;*.gif\0"
                                       L"All files\0" L"*\0"
                                       L"\0",
                        .lpstrFile = std::data(fileNameBuffer),
                        .nMaxFile = static_cast<DWORD>(std::size(fileNameBuffer)),
                        .Flags = OFN_EXPLORER | OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST | OFN_HIDEREADONLY | OFN_LONGNAMES | OFN_NOTESTFILECREATE | OFN_ALLOWMULTISELECT,
                    };

                    // Get the filename(s) from the user.
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

                        LoadDocumentFiles(std::move(filenameList));
                        RelayoutAndRedrawCanvasItemsLater(hwnd);
                    }
                }
                break;

            case IDM_EXPORT_IMAGE:
                {
                    if (!g_bitmap.valid())
                    {
                        ShowError(L"Cannot export empty image.");
                        break;
                    }

                    wchar_t fileNameBuffer[32768];
                    fileNameBuffer[0] = '\0';
                    OPENFILENAME saveFileName =
                    {
                        .lStructSize = sizeof(saveFileName),
                        .hwndOwner = hwnd,
                        .hInstance = g_instanceHandle,
                        .lpstrFilter = L"Raster Images (PNG, BMP, TIFF)\0" L"*.png;*.bmp;*.tif;*.tiff\0"
                                       L"All files\0" L"*\0"
                                       L"\0",
                        .lpstrFile = std::data(fileNameBuffer),
                        .nMaxFile = static_cast<DWORD>(std::size(fileNameBuffer)),
                        .Flags = OFN_EXPLORER | OFN_PATHMUSTEXIST | OFN_HIDEREADONLY | OFN_LONGNAMES | OFN_NOTESTFILECREATE,
                        .lpstrDefExt = L"png",
                    };

                    // Get the filename(s) from the user.
                    if (GetSaveFileName(&saveFileName) && saveFileName.nFileOffset > 0)
                    {
                        std::array<uint32_t, 4> dimensions = {g_bitmap.width(), g_bitmap.height(), 4, 1};
                        std::byte const* pixelBytes = reinterpret_cast<std::byte const*>(g_bitmap.data());
                        HRESULT hr = StoreImageData(
                                        { pixelBytes, pixelBytes + g_bitmap.stride() * g_bitmap.height() },
                                        dimensions,
                                        fileNameBuffer
                                     );
                        if (FAILED(hr))
                        {
                            ShowError(std::format(L"Failed to write file (0x{:08X}): {}", uint32_t(hr), fileNameBuffer));
                        }
                    }
                }
                break;

            case IDM_FILE_RELOAD:
                // Reload the previous SVG files, useful if you update the SVG file in a text editor and resave it.
                if (!g_filenameList.empty())
                {
                    LoadDocumentFiles(std::move(g_filenameList));
                    ShowErrors();
                    RelayoutAndRedrawCanvasItemsLater(hwnd);
                }
                break;

            case IDM_FILE_UNLOAD:
                ClearDocumentList();
                RelayoutAndRedrawCanvasItemsLater(hwnd);
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
            case IDM_SIZE17:
            case IDM_SIZE18:
            case IDM_SIZE19:
            case IDM_SIZE20:
            case IDM_SIZE21:
            case IDM_SIZE22:
                static_assert(IDM_SIZE22 + 1 - IDM_SIZE0 == _countof(g_waterfallBitmapSizes));
                static_assert(IDM_SIZE_LAST + 1 - IDM_SIZE_FIRST == _countof(g_waterfallBitmapSizes));
                g_bitmapSizePerDocument = g_waterfallBitmapSizes[wmId - IDM_SIZE0];
                // If the shift key is held down, then just set the maximum size of whatever is currently set
                // (useful for waterfall displays) rather than change to fixed size.
                if (GetKeyState(VK_SHIFT) & 0x80)
                {
                    g_bitmapMaximumSize = g_bitmapSizePerDocument;
                }
                else
                {
                    g_bitmapSizingDisplay = BitmapSizingDisplay::FixedSize;
                }
                RelayoutAndRedrawCanvasItemsLater(hwnd);
                RealignBitmapOffsetsLater();
                break;

            case IDM_SIZE_FIXED:
                // Leave g_bitmapSizePerDocument as previous value.
                g_bitmapSizingDisplay = BitmapSizingDisplay::FixedSize;
                RelayoutAndRedrawCanvasItemsLater(hwnd);
                RealignBitmapOffsetsLater();
                break;

            case IDM_SIZE_WINDOW:
                g_bitmapSizingDisplay = BitmapSizingDisplay::WindowSize;
                RelayoutAndRedrawCanvasItemsLater(hwnd);
                RealignBitmapOffsetsLater();
                break;

            case IDM_SIZE_WATERFALL_OBJECT_THEN_SIZE:
                g_bitmapSizingDisplay = BitmapSizingDisplay::WaterfallObjectThenSize;
                RelayoutAndRedrawCanvasItemsLater(hwnd);
                RealignBitmapOffsetsLater();
                break;

            case IDM_SIZE_WATERFALL_SIZE_THEN_OBJECT:
                g_bitmapSizingDisplay = BitmapSizingDisplay::WaterfallSizeThenObject;
                RelayoutAndRedrawCanvasItemsLater(hwnd);
                RealignBitmapOffsetsLater();
                break;

            case IDM_SIZE_NATURAL:
                g_bitmapSizingDisplay = BitmapSizingDisplay::Natural;
                RelayoutAndRedrawCanvasItemsLater(hwnd);
                RealignBitmapOffsetsLater();
                break;

            case IDM_SIZE_WRAPPED:
                g_bitmapSizeWrapped = !g_bitmapSizeWrapped;
                RelayoutAndRedrawCanvasItemsLater(hwnd);
                RealignBitmapOffsetsLater();
                break;

            case IDM_OUTLINES_VISIBLE:
                g_outlinesVisible = !g_outlinesVisible;
                InvalidateClientRect(hwnd);
                break;

            case IDM_RASTER_FILLS_STROKES_VISIBLE:
                g_rasterFillsStrokesVisible = !g_rasterFillsStrokesVisible;
                RedrawCanvasItemsLater(hwnd);
                break;

            case IDM_SIZE_FLOW_RIGHT_DOWN:
                g_canvasFlowDirection = CanvasItem::FlowDirection::RightDown;
                RelayoutAndRedrawCanvasItemsLater(hwnd);
                RealignBitmapOffsetsLater();
                break;

            case IDM_SIZE_FLOW_DOWN_RIGHT:
                g_canvasFlowDirection = CanvasItem::FlowDirection::DownRight;
                RelayoutAndRedrawCanvasItemsLater(hwnd);
                RealignBitmapOffsetsLater();
                break;

            case IDM_SIZE_SMALLER:
            case IDM_SIZE_LARGER:
                {
                    // Increase or decrease the document size by 1 pixel from whatever it currently is.
                    RECT clientRect;
                    GetClientRect(hwnd, &clientRect);
                    uint32_t size = GetBitmapSizingDisplaySize(g_bitmapSizingDisplay, clientRect);
                    size += ((wmId == IDM_SIZE_SMALLER) ? -1 : 1);

                    g_bitmapSizePerDocument = std::clamp(size, 1u, 32768u);
                    g_bitmapSizingDisplay = BitmapSizingDisplay::FixedSize;
                    RelayoutAndRedrawCanvasItemsLater(hwnd);
                    ConstrainBitmapOffsetsLater();
                }
                break;

            case IDM_ZOOM0:
            case IDM_ZOOM1:
            case IDM_ZOOM2:
            case IDM_ZOOM3:
            case IDM_ZOOM4:
            case IDM_ZOOM5:
            case IDM_ZOOM6:
            case IDM_ZOOM7:
            case IDM_ZOOM8:
            case IDM_ZOOM9:
            case IDM_ZOOM10:
            case IDM_ZOOM11:
            case IDM_ZOOM12:
            case IDM_ZOOM13:
            case IDM_ZOOM14:
            case IDM_ZOOM15:
            case IDM_ZOOM16:
                static_assert(IDM_ZOOM16 + 1 - IDM_ZOOM0 == _countof(g_zoomFactors), "g_zoomFactors is not the correct size");
                ChangeBitmapZoomCentered(hwnd, g_zoomFactors[wmId - IDM_ZOOM0]);
                break;

            case IDM_ZOOM_IN:
            case IDM_ZOOM_OUT:
                ChangeBitmapZoomCentered(hwnd, FindValueNextPrevious<uint32_t>(g_zoomFactors, g_bitmapPixelZoom, wmId == IDM_ZOOM_IN ? 1 : -1));
                break;

            case IDM_COPY_BITMAP:
                CopyBitmapToClipboard(g_bitmap, {0, 0, INT_MAX, INT_MAX}, hwnd);
                break;

            case IDM_BACKGROUND_GRAY_CHECKERBOARD:
            case IDM_BACKGROUND_TRANSPARENT_BLACK:
            case IDM_BACKGROUND_OPAQUE_WHITE:
            case IDM_BACKGROUND_OPAQUE_GRAY:
                static_assert(IDM_BACKGROUND_GRAY_CHECKERBOARD - IDM_BACKGROUND_FIRST == static_cast<uint32_t>(BackgroundColorMode::GrayCheckerboard));
                static_assert(IDM_BACKGROUND_TRANSPARENT_BLACK - IDM_BACKGROUND_FIRST == static_cast<uint32_t>(BackgroundColorMode::TransparentBlack));
                static_assert(IDM_BACKGROUND_OPAQUE_WHITE - IDM_BACKGROUND_FIRST == static_cast<uint32_t>(BackgroundColorMode::OpaqueWhite));
                static_assert(IDM_BACKGROUND_OPAQUE_GRAY - IDM_BACKGROUND_FIRST == static_cast<uint32_t>(BackgroundColorMode::OpaqueGray));

                g_backgroundColorMode = static_cast<BackgroundColorMode>(wmId - IDM_BACKGROUND_FIRST);
                RedrawCanvasItemsLater(hwnd);
                break;

            case IDM_INVERT_COLORS:
                g_invertColors = !g_invertColors;
                RedrawCanvasItemsLater(hwnd);
                break;

            case IDM_SHOW_ALPHA_CHANNEL:
                g_showAlphaChannel = !g_showAlphaChannel;
                RedrawCanvasItemsLater(hwnd);
                break;

            case IDM_GRID_VISIBLE:
                g_gridVisible = !g_gridVisible;
                InvalidateClientRectBitmap(hwnd);
                break;

            case IDM_PIXEL_GRID_VISIBLE:
                g_pixelGridVisible = !g_pixelGridVisible;
                InvalidateClientRectBitmap(hwnd);
                break;

            case IDM_GRID_SIZE_0:
            case IDM_GRID_SIZE_1:
            case IDM_GRID_SIZE_2:
            case IDM_GRID_SIZE_3:
            case IDM_GRID_SIZE_4:
            case IDM_GRID_SIZE_5:
            case IDM_GRID_SIZE_6:
            case IDM_GRID_SIZE_8:
            case IDM_GRID_SIZE_12:
            case IDM_GRID_SIZE_16:
            case IDM_GRID_SIZE_24:
            case IDM_GRID_SIZE_32:
            case IDM_GRID_SIZE_48:
            case IDM_GRID_SIZE_64:
            case IDM_GRID_SIZE_96:
            case IDM_GRID_SIZE_128:
            case IDM_GRID_SIZE_192:
            case IDM_GRID_SIZE_256:
                g_gridVisible = true;
                static_assert(IDM_GRID_SIZE_0 == IDM_GRID_SIZE_FIRST);
                static_assert(IDM_GRID_SIZE_256 == IDM_GRID_SIZE_LAST);
                static_assert(IDM_GRID_SIZE_LAST + 1 - IDM_GRID_SIZE_FIRST == _countof(g_gridSizes), "g_gridSizes is not the correct size");
                g_gridSize = g_gridSizes[wmId - IDM_GRID_SIZE_FIRST];
                InvalidateClientRectBitmap(hwnd);
                break;

            case IDM_NAVIGATE_LINE_LEFT:  HandleBitmapScrolling(hwnd, SB_LINELEFT, g_bitmapScrollStep, /*isHorizontal*/ true); break;
            case IDM_NAVIGATE_LINE_RIGHT: HandleBitmapScrolling(hwnd, SB_LINERIGHT, g_bitmapScrollStep, /*isHorizontal*/ true); break;
            case IDM_NAVIGATE_LINE_UP:    HandleBitmapScrolling(hwnd, SB_LINEUP, g_bitmapScrollStep, /*isHorizontal*/ false); break;
            case IDM_NAVIGATE_LINE_DOWN:  HandleBitmapScrolling(hwnd, SB_LINEDOWN, g_bitmapScrollStep, /*isHorizontal*/ false); break;
            case IDM_NAVIGATE_PAGE_LEFT:  HandleBitmapScrolling(hwnd, SB_PAGELEFT, g_bitmapScrollStep, /*isHorizontal*/ true); break;
            case IDM_NAVIGATE_PAGE_RIGHT: HandleBitmapScrolling(hwnd, SB_PAGERIGHT, g_bitmapScrollStep, /*isHorizontal*/ true); break;
            case IDM_NAVIGATE_PAGE_UP:    HandleBitmapScrolling(hwnd, SB_PAGEUP, g_bitmapScrollStep, /*isHorizontal*/ false); break;
            case IDM_NAVIGATE_PAGE_DOWN:  HandleBitmapScrolling(hwnd, SB_PAGEDOWN, g_bitmapScrollStep, /*isHorizontal*/ false); break;
            case IDM_NAVIGATE_END_LEFT:   HandleBitmapScrolling(hwnd, SB_LEFT, g_bitmapScrollStep, /*isHorizontal*/ true); break;
            case IDM_NAVIGATE_END_RIGHT:  HandleBitmapScrolling(hwnd, SB_RIGHT, g_bitmapScrollStep, /*isHorizontal*/ true); break;
            case IDM_NAVIGATE_END_UP:     HandleBitmapScrolling(hwnd, SB_TOP, g_bitmapScrollStep, /*isHorizontal*/ false); break;
            case IDM_NAVIGATE_END_DOWN:   HandleBitmapScrolling(hwnd, SB_BOTTOM, g_bitmapScrollStep, /*isHorizontal*/ false); break;

            case IDM_NUDGE_LEFT:  g_svgNudgeOffsetX -= 0.125; RedrawCanvasItemsLater(hwnd); break;
            case IDM_NUDGE_RIGHT: g_svgNudgeOffsetX += 0.125; RedrawCanvasItemsLater(hwnd); break;
            case IDM_NUDGE_UP:    g_svgNudgeOffsetY -= 0.125; RedrawCanvasItemsLater(hwnd); break;
            case IDM_NUDGE_DOWN:  g_svgNudgeOffsetY += 0.125; RedrawCanvasItemsLater(hwnd); break;

            case IDM_PRESET_INSPECT:
                g_gridVisible = true;
                g_pixelGridVisible = true;
                g_outlinesVisible = true;
                ChangeBitmapZoomCentered(hwnd, 16);
                InvalidateClientRect(hwnd);
                break;

            case IDM_PRESET_OVERVIEW:
                g_gridVisible = false;
                g_pixelGridVisible = false;
                g_outlinesVisible = false;
                ChangeBitmapZoomCentered(hwnd, 1);
                InvalidateClientRect(hwnd);
                break;

            case IDM_PRESET_WRAPPED_IMAGES:
                g_canvasFlowDirection = CanvasItem::FlowDirection::RightDown;
                g_bitmapSizeWrapped = true;
                g_bitmapSizingDisplay = BitmapSizingDisplay::Natural;
                RelayoutAndRedrawCanvasItemsLater(hwnd);
                RealignBitmapOffsetsLater();
                break;

            case IDM_PRESET_WRAPPED_ICONS:
                g_canvasFlowDirection = CanvasItem::FlowDirection::RightDown;
                g_bitmapSizeWrapped = true;
                g_bitmapSizingDisplay = BitmapSizingDisplay::FixedSize;
                g_bitmapSizePerDocument = 64;
                RelayoutAndRedrawCanvasItemsLater(hwnd);
                RealignBitmapOffsetsLater();
                break;

            case IDM_SNAP_TO_PIXELS:
                g_snapToPixels = !g_snapToPixels;
                RedrawCanvasItemsLater(hwnd);
                break;

            default:
                return DefWindowProc(hwnd, message, wParam, lParam);
            }
        }
        break;

    case WM_DROPFILES:
        {
            // Get the filename(s).
            std::array<wchar_t, MAX_PATH> fileName;
            fileName[0] = '\0';
            HDROP dropHandle = reinterpret_cast<HDROP>(wParam);
            std::vector<std::wstring> filenameList;

            // Load each file.
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
                RedrawCanvasItemsLater(hwnd);
                LoadDocumentFiles(std::move(filenameList));
                RelayoutAndRedrawCanvasItemsLater(hwnd);
            }
        }
        break;

    case WM_INITMENUPOPUP:
        InitializePopMenu(hwnd, reinterpret_cast<HMENU>(wParam), LOWORD(lParam));
        break;

    case WM_WINDOWPOSCHANGED:
        if (!(reinterpret_cast<WINDOWPOS*>(lParam)->flags & (SWP_SHOWWINDOW | SWP_HIDEWINDOW | SWP_NOSIZE)))
        {
            // Only resize if the window actually changed size, not just minimizing or restoring
            // from being minimized. Sadly win32 offers no clear way to distinguish these cases
            // as the WM_SIZE SIZE_RESTORED is incorrectly reported for both restored windows
            // and also ordinary border resizing. So, keep track of the previous minimized state.
            bool wasIconic = g_isIconic;
            g_isIconic = IsIconic(hwnd);
            if (!(wasIconic | g_isIconic))
            {
                if (IsBitmapSizingDisplayResizeable(g_bitmapSizingDisplay))
                {
                    RelayoutCanvasItemsLater(hwnd);
                }
                else
                {
                    InvalidateClientRectBitmap(hwnd);
                }
                ConstrainBitmapOffsetsLater();
            }
        }
        break;

    case WM_ERASEBKGND:
        return 1;

    case WM_PAINT:
        try
        {
            RepaintWindow(hwnd);
        }
        catch (...) // std::bad_alloc can happen if the bitmap is too large.
        {
            ValidateRect(hwnd, nullptr);
        }
        break;

    case WM_HSCROLL:
    case WM_VSCROLL:
        HandleBitmapScrolling(hwnd, LOWORD(wParam), g_bitmapScrollStep, /*isHorizontal*/ message == WM_HSCROLL);
        break;

    case WM_MOUSEWHEEL:
        OnMouseWheel(hwnd, GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam), GET_WHEEL_DELTA_WPARAM(wParam), GET_KEYSTATE_WPARAM(wParam));
        break;

    case WM_LBUTTONDOWN:
        g_previousMouseX = GET_X_LPARAM(lParam);
        g_previousMouseY = GET_Y_LPARAM(lParam);
        ShowClickedCanvasItem(hwnd, g_previousMouseX, g_previousMouseY);
        SetCapture(hwnd);
        break;

    case WM_LBUTTONUP:
        ReleaseCapture();
        break;

    case WM_RBUTTONDOWN:
        g_selectionStartMouseX = g_previousMouseX = GET_X_LPARAM(lParam);
        g_selectionStartMouseY = g_previousMouseY = GET_Y_LPARAM(lParam);
        g_isRightDragging = true;
        InvalidateClientRect(hwnd);
        break;

    case WM_RBUTTONUP:
        {
            g_isRightDragging = false;

            POINT mousePoint = {GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam)};
            POINT menuPoint = {GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam)};
            ClientToScreen(hwnd, /*inout*/ &menuPoint);

            HMENU menu = LoadMenu(g_instanceHandle, (LPCWSTR)IDM_MAIN_CONTEXT_MENU);
            HMENU submenu = GetSubMenu(menu, 0);
            int command = TrackPopupMenu(
                submenu,
                TPM_LEFTALIGN | TPM_TOPALIGN | TPM_LEFTBUTTON | TPM_RIGHTBUTTON | TPM_NOANIMATION | TPM_RETURNCMD,
                menuPoint.x,
                menuPoint.y,
                0, // reserved
                hwnd,
                nullptr // optional rectangle
            );
            DestroyMenu(menu);

            switch (command)
            {
            // Can't handle this command in the standard WM_COMMAND because the clicked mouse coordinate is lost by then.
            case IDM_COPY_BITMAP_SELECTION:
                {
                    // Get the rectangle between the right button press and right button release.
                    POINT startPoint = ClientSpaceMouseCoordinateToImageCoordinate(mousePoint.x, mousePoint.y);
                    POINT endPoint = ClientSpaceMouseCoordinateToImageCoordinate(g_selectionStartMouseX, g_selectionStartMouseY);
                    RECT startMouseRect = {startPoint.x, startPoint.y, startPoint.x + 1, startPoint.y + 1};
                    RECT mouseRect = {endPoint.x, endPoint.y, endPoint.x + 1, endPoint.y + 1};
                    UnionRect(/*out*/ &mouseRect, &startMouseRect, &mouseRect);

                    RECT clipRect = DetermineCanvasItemsRowBoundingRect(g_canvasItems, mouseRect);
                    CopyBitmapToClipboard(g_bitmap, clipRect, hwnd);
                }
                break;

            case 0: // User canceled.
                break;

            default:
                PostMessage(hwnd, WM_COMMAND, command, 0);
                break;
            }

            InvalidateClientRect(hwnd);
        }
        break;

    case WM_MOUSEMOVE:
        if (wParam & MK_LBUTTON)
        {
            int32_t x = GET_X_LPARAM(lParam);
            int32_t y = GET_Y_LPARAM(lParam);
            HandleBitmapScrolling(hwnd, g_previousMouseX - x, g_previousMouseY - y);
            g_previousMouseX = x;
            g_previousMouseY = y;
        }
        else if (wParam & MK_RBUTTON)
        {
            g_previousMouseX = GET_X_LPARAM(lParam);
            g_previousMouseY = GET_Y_LPARAM(lParam);
            InvalidateClientRect(hwnd);
        }
        break;

    case WM_CAPTURECHANGED:
        g_isRightDragging = false;
        break;

    case WM_NCDESTROY:
        Gdiplus::GdiplusShutdown(g_gdiplusStartupToken);
        PostQuitMessage(0);
        break;

    default:
        return DefWindowProc(hwnd, message, wParam, lParam);
    }
    return 0;
}

// Message handler for about box.
INT_PTR CALLBACK AboutDialogProcedure(HWND dialogHandle, UINT message, WPARAM wParam, LPARAM lParam)
{
    UNREFERENCED_PARAMETER(lParam);
    switch (message)
    {
    case WM_INITDIALOG:
        return (INT_PTR)TRUE;

    case WM_COMMAND:
        if (LOWORD(wParam) == IDOK || LOWORD(wParam) == IDCANCEL)
        {
            EndDialog(dialogHandle, LOWORD(wParam));
            return (INT_PTR)TRUE;
        }
        break;
    }
    return (INT_PTR)FALSE;
}
