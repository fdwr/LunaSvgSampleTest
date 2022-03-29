// LunaSvgTest.cpp: Main application.

#include "precomp.h"
#include "LunaSvgTest.h"
#include "lunasvg.h"

// Global Variables:
constexpr size_t MAX_LOADSTRING = 100;
HINSTANCE g_instanceHandle;                     // Current process base memory address.
HWND g_windowHandle;
HWND g_toolTipWindowHandle;
WCHAR g_applicationTitle[MAX_LOADSTRING];       // The title bar text.
WCHAR g_windowClassName[MAX_LOADSTRING];        // The main window class name.
const HBRUSH g_backgroundWindowBrush = HBRUSH(COLOR_3DFACE+1);

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

enum class BitmapSizingDisplay
{
    FixedSize,
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

// A single item on the screen, either SVG document or size label.
struct CanvasItem
{
    enum class ItemType : uint8_t
    {
        SizeLabel,
        SvgDocument,
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
        uint32_t svgDocumentIndex;
    } value;
    uint32_t x; // Left edge of item box
    uint32_t y; // Top edge of item box
    uint32_t w; // Width
    uint32_t h; // Height
};

DEFINE_ENUM_FLAG_OPERATORS(CanvasItem::Flags);

// Horrible assortment of (gasp) global variables rather than a proper class instance.
std::vector<std::unique_ptr<lunasvg::Document>> g_svgDocuments;
std::vector<CanvasItem> g_canvasItems;
std::vector<std::wstring> g_filenameList;
lunasvg::Bitmap g_bitmap; // Rendered bitmap of all SVG documents.
bool g_svgNeedsRedrawing = true; // Set true after any size changes, layout changes, or background color (not just scrolling or zoom).
bool g_realignBitmap = false; // Set true after loading new files to recenter/realign the new bitmap.
bool g_constrainBitmapOffsets = false; // Set true after resizing to constrain the view over the current bitmap.
std::wstring g_errorMessage;
const std::wstring_view g_defaultMessage =
    L"No SVG loaded\r\n"
    L"\r\n"
    L"Use File/Open or drag&drop filenames to load SVG documents.\r\n"
    L"\r\n"
    L"mouse wheel = pan vertically\r\n"
    L"mouse wheel + shift = pan horizontally\r\n"
    L"mouse wheel + ctrl = zoom\r\n"
    L"middle mouse drag = pan\r\n"
    L"arrow keys/home/end/pgup/pgdn = pan\r\n";

const uint32_t g_waterfallBitmapSizes[] = {16,20,24,28,32,40,48,56,64,72,80,96,112,128,160,192,224,256};
const uint32_t g_zoomFactors[] = {1,2,3,4,6,8,12,16,24,32};
const uint32_t g_gridSizes[] = {1,2,3,4,5,6,7,8,12,16,24,32};
const uint32_t g_bitmapScrollStep = 64;

BitmapSizingDisplay g_bitmapSizingDisplay = BitmapSizingDisplay::Waterfall;
BackgroundColorMode g_backgroundColorMode = BackgroundColorMode::GrayCheckerboard;
uint32_t g_bitmapSizePerDocument = 64; // in pixels
uint32_t g_bitmapPixelZoom = 1; // Assert > 0.
uint32_t g_gridSize = 8;
int32_t g_bitmapOffsetX = 0; // In effective screen pixels (in terms of g_bitmapPixelZoom) rather than g_bitmap pixels. Positive pans right.
int32_t g_bitmapOffsetY = 0; // In effective screen pixels (in terms of g_bitmapPixelZoom) rather than g_bitmap pixels. Positive pans down.
CanvasItem::FlowDirection g_canvasFlowDirection = CanvasItem::FlowDirection::RightDown;
bool g_bitmapSizeWrapped = false; // Wrap the items to the window size.
bool g_invertColors = false; // Negate all the bitmap colors.
bool g_gridVisible = false; // Display rectangular grid using g_gridSize.

int32_t g_previousMouseX = 0; // Used for middle drag.
int32_t g_previousMouseY = 0;

struct PixelBgra
{
    uint8_t b;
    uint8_t g;
    uint8_t r;
    uint8_t a;
};

// Redefine the bitmap header structs so inheritance works.
// Who needlessly prefixed every field with {bi, bc, bv5} so that generic
// code could not work with different versions of the structs? (sigh, face palm)
struct BITMAPHEADERv2 // BITMAPCOREHEADER
{
    DWORD        size;
    WORD         width;
    WORD         height;
    WORD         planes;
    WORD         bitCount;
};

struct BITMAPHEADERv3 // BITMAPINFOHEADER (not v3 is not backwards compatible with v2, as the width/height are LONG)
{
    DWORD        size;
    LONG         width;
    LONG         height;
    WORD         planes;
    WORD         bitCount;
    DWORD        compression;
    DWORD        sizeImage;
    LONG         xPelsPerMeter;
    LONG         yPelsPerMeter;
    DWORD        clrImportant;
    DWORD        clrUsed;
};

struct BITMAPHEADERv4 : BITMAPHEADERv3 // BITMAPV4HEADER
{
    DWORD        redMask;
    DWORD        greenMask;
    DWORD        blueMask;
    DWORD        alphaMask;
    DWORD        csType;
    CIEXYZTRIPLE endpoints;
    DWORD        gammaRed;
    DWORD        gammaGreen;
    DWORD        gammaBlue;
};

struct BITMAPHEADERv5 : BITMAPHEADERv4 // BITMAPV5HEADER
{
    DWORD        intent;
    DWORD        profileData;
    DWORD        profileSize;
    DWORD        reserved;
};

////////////////////////////////////////////////////////////////////////////////

// Forward declarations of functions included in this code module:
ATOM RegisterMainWindowClass(HINSTANCE instanceHandle);
BOOL InitializeWindowInstance(HINSTANCE instanceHandle, int commandShow);
LRESULT CALLBACK WindowProcedure(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam);
INT_PTR CALLBACK AboutDialogProcedure(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam);
void ClearSvgList();
void LoadSvgFile(const wchar_t* filePath);
void AppendSingleSvgFile(wchar_t const* filePath);
void RedrawSvgLater(HWND hwnd);
void RedrawSvg(HWND hwnd);


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
        ClearSvgList();
        for (int argumentIndex = 1; argumentIndex < argumentCount; ++argumentIndex)
        {
            AppendSingleSvgFile(arguments[argumentIndex]);
        }
        RedrawSvgLater(g_windowHandle);
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
        .hCursor        = LoadCursor(nullptr, IDC_ARROW),
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

    //SendMessage(TtHwnd, TTM_SETMAXTIPWIDTH, 0, sz.cx); // No wrapping. Just let it be as wide as it needs to be.
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
    KillTimer(hwnd, uIDEvent);
    HideToolTip();
}


// Save the process base memory address in a global variable, and
// create the main program window.
BOOL InitializeWindowInstance(HINSTANCE instanceHandle, int commandShow)
{
    g_instanceHandle = instanceHandle; // Store instance handle in our global variable

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


// Draw horizontal and vertical lines using the given color.
void DrawBitmapGrid(
    HDC hdc,
    int32_t xOffset,
    int32_t yOffset,
    uint32_t width,
    uint32_t height,
    uint32_t xSpacing,
    uint32_t ySpacing,
    HBRUSH brush
)
{
    xSpacing = std::max(xSpacing, 1u);
    ySpacing = std::max(ySpacing, 1u);

    const bool drawLines = true;
    if (drawLines)
    {
        // Vertical lines left to right.
        for (int32_t x = xOffset; x < int32_t(xOffset + width); x += xSpacing)
        {
            RECT rect = { .left = x, .top = yOffset, .right = x + 1, .bottom = int32_t(yOffset + height) };
            FillRect(hdc, &rect, brush);
        }

        // Horizontal lines top to bottom.
        for (int32_t y = yOffset; y < int32_t(yOffset + height); y += ySpacing)
        {
            RECT rect = { .left = xOffset, .top = y, .right = int32_t(xOffset + width), .bottom = y + 1 };
            FillRect(hdc, &rect, brush);
        }
    }
    else
    {
        // SetPixel is really slow. Might need to use lines with dashes instead.
        // Leave disabled for now.
        for (int32_t y = yOffset; y < int32_t(yOffset + height); y += ySpacing)
        {
            for (int32_t x = xOffset; x < int32_t(xOffset + width); x += xSpacing)
            {
                SetPixel(hdc, x, y, 0x00000000);
            }
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
                pixel += sizeof(uint32_t);
                ++digitPixels;
            }
            pixel += rowByteDelta;
        }

        x += g_smallDigitAdvance + 1;
    }
}


// Given the SVG document and a desired size, compute the transformation matrix.
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
    const uint32_t rowByteDelta = byteStridePerRow - (width * sizeof(uint32_t));
    uint8_t* pixel = pixels + y * byteStridePerRow + x * sizeof(uint32_t);

    for (uint32_t j = 0; j < height; ++j)
    {
        for (uint32_t i = 0; i < width; ++i)
        {
            const uint32_t backgroundColor = ((i & 8) ^ (j & 8)) ? 0xFF202020 : 0xFF404040;
            assert(pixel >= pixels && pixel < pixels + height * byteStridePerRow);
            *reinterpret_cast<uint32_t*>(pixel) = backgroundColor;
            pixel += sizeof(uint32_t);
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
    g_errorMessage.clear();
}


void AppendSingleSvgFile(wchar_t const* filePath)
{
    auto document = lunasvg::Document::loadFromFile(filePath);
    if (document)
    {
        g_svgDocuments.push_back(std::move(document));
        g_filenameList.push_back(filePath);
    }
    else
    {
        wchar_t errorMessage[1000];
        _snwprintf_s(errorMessage, sizeof(errorMessage), L"Error loading: %s\n", filePath);
        g_errorMessage += errorMessage;
    }
    RealignBitmapOffsetsLater();
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

    if (!g_errorMessage.empty())
    {
        // Show error messages, after two second delay.
        ShowToolTip(g_errorMessage.c_str());
        SetTimer(g_windowHandle, IDM_OPEN_FILE, 2000, &HideToolTipTimerProc);
    }
}


// Helper to append one canvas item per SVG document at the given pixel size.
void AppendCanvasItemsGivenSize(std::vector<CanvasItem>& canvasItems, uint32_t documentPixelSize)
{
    const uint32_t totalDocuments = static_cast<uint32_t>(g_svgDocuments.size());

    for (uint32_t documentIndex = 0; documentIndex < totalDocuments; ++documentIndex)
    {
        CanvasItem canvasItem =
        {
            .itemType = CanvasItem::ItemType::SvgDocument,
            .flags = CanvasItem::Flags::Default,
            .value = {.svgDocumentIndex = documentIndex},
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
    const uint32_t totalDocuments = static_cast<uint32_t>(g_svgDocuments.size());
    const bool isHorizontalLayout = (flowDirection == CanvasItem::FlowDirection::RightDown);
    static_assert(uint32_t(CanvasItem::FlowDirection::Total) == 2);

    // Draw the image to a bitmap.
    switch (g_bitmapSizingDisplay)
    {
    case BitmapSizingDisplay::FixedSize:
        AppendCanvasItemsGivenSize(canvasItems, g_bitmapSizePerDocument);
        break;

    case BitmapSizingDisplay::Waterfall:
        {
            for (uint32_t bitmapSize : g_waterfallBitmapSizes)
            {
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

                // Append all SVG documents at the current size.
                for (uint32_t documentIndex = 0; documentIndex < totalDocuments; ++documentIndex)
                {
                    auto& document = g_svgDocuments[documentIndex];
                    CanvasItem svgCanvasItem =
                    {
                        .itemType = CanvasItem::ItemType::SvgDocument,
                        .flags = CanvasItem::Flags::Default,
                        .value = {.svgDocumentIndex = documentIndex},
                        .w = bitmapSize,
                        .h = bitmapSize,
                    };
                    canvasItems.push_back(std::move(svgCanvasItem));
                }
            }
        }
        break;

    case BitmapSizingDisplay::WindowSize:
        {
            const uint32_t bitmapMaximumSize = std::min(boundingRect.bottom, boundingRect.right) / g_bitmapPixelZoom;
            AppendCanvasItemsGivenSize(canvasItems, bitmapMaximumSize);
        }
        break;

    case BitmapSizingDisplay::Natural:
        {
            AppendCanvasItemsGivenSize(canvasItems, /*documentPixelSize*/ 0);
            // Set the height and width each of canvas item to its natural dimensions.
            for (uint32_t documentIndex = 0; documentIndex < totalDocuments; ++documentIndex)
            {
                auto& canvasItem = canvasItems[documentIndex];
                auto& document = *g_svgDocuments[documentIndex];
                canvasItem.w = static_cast<uint32_t>(std::ceil(document.width()));
                canvasItem.h = static_cast<uint32_t>(std::ceil(document.height()));
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
        RECT currentRect =
        {
            .left = LONG(x),
            .top = LONG(y),
            .right = LONG(x + canvasItem.w),
            .bottom = LONG(y + canvasItem.h),
        };
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
        RECT currentRect =
        {
            .left = LONG(canvasItem.x),
            .top = LONG(canvasItem.y),
            .right = LONG(canvasItem.x + canvasItem.w),
            .bottom = LONG(canvasItem.y + canvasItem.h),
        };
        UnionRect(/*out*/&boundingRect, &boundingRect, &currentRect);
    }
    return boundingRect;
}


// Redraw all canvas items into the given bitmap.
// The screen was already cleared.
void RedrawCanvasItems(std::span<CanvasItem const> canvasItems, lunasvg::Bitmap& bitmap)
{
    constexpr uint32_t maximumSmallDigitNumbers = 4;
    lunasvg::Bitmap subbitmap;

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
            {
                assert(canvasItem.value.svgDocumentIndex < g_svgDocuments.size());
                auto& document = g_svgDocuments[canvasItem.value.svgDocumentIndex];

                // Draw the icon into a subrect of the larger atlas texture,
                // adjusting the pointer offset while keeping the correct stride.
                // This will also force clipping into the item's window.
                uint32_t pixelOffset = canvasItem.y * g_bitmap.stride() + canvasItem.x * sizeof(uint32_t);
                subbitmap.reset(bitmap.data() + pixelOffset, canvasItem.w, canvasItem.h, bitmap.stride());

                uint32_t pixelSize = std::min(canvasItem.w, canvasItem.h);
                auto matrix = GetMatrixForSize(*document, pixelSize);
                document->render(subbitmap, matrix);
            }
            break;
        }
    }
}


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


// Redraw the background behind the SVG, such as transparent black or checkerboard.
void RedrawSvgBackground()
{
    switch (g_backgroundColorMode)
    {
    case BackgroundColorMode::TransparentBlack:
        g_bitmap.clear(0x00000000);
        break;

    case BackgroundColorMode::GrayCheckerboard:
        DrawCheckerboardBackground(g_bitmap.data(), 0, 0, g_bitmap.width(), g_bitmap.height(), g_bitmap.stride());
        break;

    case BackgroundColorMode::OpaqueWhite:
    case BackgroundColorMode::OpaqueGray:
        // Beware LunaSvg uses backwards alpha (RGBA rather than ARGB) whereas
        // typically most pixel formats put the alpha in the *top* byte.
        g_bitmap.clear((g_backgroundColorMode == BackgroundColorMode::OpaqueGray) ? 0x808080FF : /*OpaqueWhite*/ 0xFFFFFFFF);
        break;
    }
}


void RedrawSvg(RECT const& clientRect)
{
    if (g_svgDocuments.empty() || !g_svgDocuments.front())
    {
        return;
    }

    RECT const& layoutRect = g_bitmapSizeWrapped ? clientRect : RECT{0,0, INT_MAX, INT_MAX};
    GenerateCanvasItems(clientRect, g_canvasFlowDirection, /*inout*/g_canvasItems);
    LayoutCanvasItems(layoutRect, g_canvasFlowDirection, /*inout*/g_canvasItems);
    RECT boundingRect = DetermineCanvasItemsBoundingRect(g_canvasItems);
    g_bitmap.reset(boundingRect.right, boundingRect.bottom);
    RedrawSvgBackground();
    RedrawCanvasItems(g_canvasItems, g_bitmap);

    if (g_realignBitmap)
    {
        RealignBitmapOffsets(clientRect);
    }

    if (g_constrainBitmapOffsets)
    {
        ConstrainBitmapOffsets(clientRect);
    }
}


// Enqueue the bitmap for redraw later in WM_PAINT, without redrawing the SVG
// (such as with a pure translation or zoom).
void RedrawBitmapLater(HWND hwnd)
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


// Enqueue redrawing the SVG to the bitmap later in WM_PAINT.
void RedrawSvgLater(HWND hwnd)
{
    g_svgNeedsRedrawing = true;
    InvalidateRect(hwnd, nullptr, true);
}


void RedrawSvg(HWND hwnd)
{
    // Redraw the SVG document(s) into the bitmap, computing the new bitmap size.

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
    _snwprintf_s(windowTitle, sizeof(windowTitle), L"%s (%1.6fms, %ux%u, %s)", g_applicationTitle, durationMs, g_bitmap.width(), g_bitmap.height(), filename);
    SetWindowText(hwnd, windowTitle);

    if (g_invertColors)
    {
        NegateBitmap(g_bitmap);
    }

    RedrawBitmapLater(hwnd);
    g_svgNeedsRedrawing = false;
}


// Fill in a GDI BITMAPHEADER from the bitmap information.
void FillBitmapInfoFromLunaSvgBitmap(
    lunasvg::Bitmap const& bitmap,
    /*out*/ BITMAPHEADERv5& bitmapInfo
    )
{
    bitmapInfo.size = sizeof(bitmapInfo);
    bitmapInfo.width = bitmap.width();
    bitmapInfo.height = -LONG(bitmap.height());
    bitmapInfo.planes = 1;
    bitmapInfo.bitCount = 32;
    bitmapInfo.compression = BI_BITFIELDS;
    bitmapInfo.sizeImage = bitmap.stride() * bitmap.height();
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
    HWND hwnd
    )
{
    if (bitmap.valid())
    {
        if (OpenClipboard(hwnd))
        {
            EmptyClipboard();

            BITMAPHEADERv5 bitmapInfo;
            FillBitmapInfoFromLunaSvgBitmap(bitmap, /*out*/bitmapInfo);

            uint32_t totalBytes = sizeof(bitmapInfo) + bitmapInfo.sizeImage;

            // Although DIB sections understand negative height just fine (the standard top-down image layout used by
            // most image formats), other programs sometimes choke when seeing it. IrfanView display the image upside
            // down. XnView fails to load it. At least this happens on Windows 7, whereas later versions of IrfanView
            // appear on Windows 10 understand upside down images just fine.
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
                    uint32_t bytesPerRow = (bitmapInfo.width * bitmapInfo.bitCount) / 8u; // Already 32-bit aligned.
                    assert(bitmapInfo.height * bytesPerRow == bitmapInfo.sizeImage);

                    // Copy the rows backwards for the sake of silly programs that don't understand top-down bitmaps.
                    uint8_t* bitmapData = bitmap.data() + bitmap.stride() * bitmap.height();
                    for (uint32_t y = 0; y < uint32_t(bitmapInfo.height); ++y)
                    {
                        bitmapData -= bytesPerRow;
                        memcpy(clipboardPixels, bitmapData, bytesPerRow);
                        clipboardPixels += bytesPerRow;
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
            int srcOffsetX = destOffsetX * srcW / destW;
            destOffsetX = srcOffsetX * destW / srcW;
            destX += destOffsetX;
            destW -= destOffsetX;
            srcX += srcOffsetX;
            srcW -= srcOffsetX;
        }
        if (destX + destW > clipRight)
        {
            int destOffsetX = clipRight - destX;
            int srcOffsetX = (destOffsetX * srcW + destW - 1) / destW;
            destOffsetX = srcOffsetX * destW / srcW;
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


void RepaintWindow(HWND hwnd)
{
    if (g_svgNeedsRedrawing)
    {
        RedrawSvg(hwnd);
        UpdateBitmapScrollbars(hwnd);
    }

    PAINTSTRUCT ps;
    HDC hdc = BeginPaint(hwnd, &ps);

    RECT clientRect;
    GetClientRect(hwnd, &clientRect);

    // Buffer the drawing to avoid flickering.
    HDC memoryDc = CreateCompatibleDC(ps.hdc);
    
    // Create the temporary composited bitmap.
    // Note we can't just call CreateCompatibleBitmap, or else StretchDIBits incorrectly draws the content upside down.
    HBITMAP memoryBitmap = CreateCompatibleBitmap(ps.hdc, clientRect.right, clientRect.bottom);

    SelectObject(memoryDc, memoryBitmap);
    SetStretchBltMode(memoryDc, COLORONCOLOR);
    SetGraphicsMode(memoryDc, GM_ADVANCED);
    SetBkMode(memoryDc, TRANSPARENT);

    // Display message if no SVG document loaded.
    if (!g_bitmap.valid())
    {
        FillRect(memoryDc, &clientRect, g_backgroundWindowBrush);
        HFONT oldFont = static_cast<HFONT>(SelectObject(memoryDc, GetStockObject(DEFAULT_GUI_FONT)));
        DrawText(memoryDc, g_defaultMessage.data(), int(g_defaultMessage.size()), &clientRect, DT_NOCLIP | DT_NOPREFIX | DT_WORDBREAK);
        SelectObject(memoryDc, oldFont);
    }
    // Draw bitmap.
    else // g_bitmap.valid()
    {
        BITMAPHEADERv5 bitmapInfo = {};
        FillBitmapInfoFromLunaSvgBitmap(g_bitmap, /*out*/ bitmapInfo);

        // Erase background around drawing.
        const uint32_t effectiveBitmapWidth = g_bitmap.width() * g_bitmapPixelZoom;
        const uint32_t effectiveBitmapHeight = g_bitmap.height() * g_bitmapPixelZoom;
        RECT bitmapRect = {
            LONG(-g_bitmapOffsetX),
            LONG(-g_bitmapOffsetY),
            LONG(effectiveBitmapWidth - g_bitmapOffsetX),
            LONG(effectiveBitmapHeight - g_bitmapOffsetY)
        };
        DrawRectangleAroundRectangle(memoryDc, ps.rcPaint, bitmapRect, g_backgroundWindowBrush);

        // Draw the SVG bitmap.
        if (g_bitmapPixelZoom == 1)
        {
            SetDIBitsToDevice(
                memoryDc,
                -g_bitmapOffsetX,
                -g_bitmapOffsetY,
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
        else // Draw scaled.
        {
            // todo:
            // This would be faster if cached, but shrug, it's fast enough.
            // Could alternately call StretchDIBits instead.
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

            StretchBltFixed(
                memoryDc,
                -g_bitmapOffsetX,
                -g_bitmapOffsetY,
                g_bitmap.width() * g_bitmapPixelZoom,
                g_bitmap.height() * g_bitmapPixelZoom,
                sourceHdc,
                0,
                0,
                g_bitmap.width(),
                g_bitmap.height(),
                SRCCOPY,
                ps.rcPaint// clientRect
            );
            DeleteDC(sourceHdc);
            DeleteObject(bitmap);
        }
    }

    // Draw the grid.
    int32_t gridSpacing = g_gridSize * g_bitmapPixelZoom;
    if (g_gridVisible)
    {
        gridSpacing = std::max(gridSpacing, 2);
        // Clamp the grid to the actual client area to avoid overdraw.
        RECT gridRect =
        {
            g_bitmapOffsetX <= 0 ? -g_bitmapOffsetX : (-(g_bitmapOffsetX % gridSpacing)),
            g_bitmapOffsetY <= 0 ? -g_bitmapOffsetY : (-(g_bitmapOffsetY % gridSpacing)),
            std::min(LONG(g_bitmap.width() * g_bitmapPixelZoom - g_bitmapOffsetX), clientRect.right),
            std::min(LONG(g_bitmap.height() * g_bitmapPixelZoom - g_bitmapOffsetY), clientRect.bottom),
        };
        DrawBitmapGrid(
            memoryDc,
            gridRect.left,
            gridRect.top,
            gridRect.right - gridRect.left,
            gridRect.bottom - gridRect.top,
            gridSpacing,
            gridSpacing,
            reinterpret_cast<HBRUSH>(GetStockObject(BLACK_BRUSH))
        );
    }

    // Draw composited image to screen.
    BitBlt(ps.hdc, 0, 0, clientRect.right, clientRect.bottom, memoryDc, 0, 0, SRCCOPY);
    DeleteDC(memoryDc);
    DeleteObject(memoryBitmap);

    EndPaint(hwnd, &ps);
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
        {IDM_COLOR, IDM_COLOR_FIRST, IDM_COLOR_LAST, []() -> uint32_t {return uint32_t(g_backgroundColorMode); }},
        {IDM_COLOR, IDM_INVERT_COLORS, 0, []() -> uint32_t {return uint32_t(g_invertColors); }},
        {IDM_SIZE, IDM_SIZE_FIRST, IDM_SIZE_LAST, []() -> uint32_t {return g_bitmapSizingDisplay == BitmapSizingDisplay::FixedSize ? uint32_t(FindValueIndexGE<uint32_t>(g_waterfallBitmapSizes, g_bitmapSizePerDocument)) : 0xFFFFFFFF; }},
        {IDM_SIZE, IDM_SIZE_DISPLAY_FIRST, IDM_SIZE_DISPLAY_LAST, []() -> uint32_t {return uint32_t(g_bitmapSizingDisplay); }},
        {IDM_SIZE, IDM_SIZE_WRAPPED, 0, []() -> uint32_t {return uint32_t(g_bitmapSizeWrapped); }},
        {IDM_SIZE, IDM_SIZE_FLOW_FIRST, IDM_SIZE_FLOW_LAST, []() -> uint32_t {return uint32_t(g_canvasFlowDirection); }},
        {IDM_VIEW, IDM_ZOOM_FIRST, IDM_ZOOM_LAST, []() -> uint32_t {return uint32_t(FindValueIndexGE<uint32_t>(g_zoomFactors, g_bitmapPixelZoom)); }},
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


// Handle 2D scrolling like middle mouse drag.
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
            RedrawBitmapLater(hwnd); // Invalidate using current zoom.
            g_bitmapOffsetX = (g_bitmapOffsetX + mouseCoordinate.x) * newPixelZoom / g_bitmapPixelZoom - mouseCoordinate.x;
            g_bitmapOffsetY = (g_bitmapOffsetY + mouseCoordinate.y) * newPixelZoom / g_bitmapPixelZoom - mouseCoordinate.y;
            g_bitmapPixelZoom = newPixelZoom;
            RedrawBitmapLater(hwnd); // Invalidate using new zoom.
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

    RedrawBitmapLater(hwnd);

    // Compute the centerpoint of the window.
    RECT clientRect;
    GetClientRect(hwnd, &clientRect);
    uint32_t centerX = clientRect.right / 2;
    uint32_t centerY = clientRect.bottom / 2;
    g_bitmapOffsetX = (g_bitmapOffsetX + centerX) * newBitmapPixelZoom / g_bitmapPixelZoom - centerX;
    g_bitmapOffsetY = (g_bitmapOffsetY + centerY) * newBitmapPixelZoom / g_bitmapPixelZoom - centerY;
    g_bitmapPixelZoom = newBitmapPixelZoom;
    ConstrainBitmapOffsets(clientRect);

    RedrawBitmapLater(hwnd); // Enqueue another invalidated rect at the new zoom.
    UpdateBitmapScrollbars(hwnd);
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
                        .lpstrFilter = L"SVG\0" L"*.svg\0"
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

                        LoadSvgFiles(std::move(filenameList));
                        RedrawSvgLater(hwnd);
                    }
                }
                break;

            case IDM_FILE_RELOAD:
                // Reload the previous SVG files, useful if you update the SVG file in a text editor and resave it.
                if (!g_filenameList.empty())
                {
                    LoadSvgFiles(std::move(g_filenameList));
                    RedrawSvgLater(hwnd);
                }
                break;

            case IDM_FILE_UNLOAD:
                ClearSvgList();
                RedrawSvgLater(hwnd);
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
                static_assert(IDM_SIZE17 + 1 - IDM_SIZE0 == _countof(g_waterfallBitmapSizes));
                static_assert(IDM_SIZE_LAST + 1 - IDM_SIZE_FIRST == _countof(g_waterfallBitmapSizes));
                g_bitmapSizePerDocument = g_waterfallBitmapSizes[wmId - IDM_SIZE0];
                g_bitmapSizingDisplay = BitmapSizingDisplay::FixedSize;
                RedrawSvgLater(hwnd);
                RealignBitmapOffsetsLater();
                break;

            case IDM_SIZE_FIXED:
                // Leave g_bitmapSizePerDocument as previous value.
                g_bitmapSizingDisplay = BitmapSizingDisplay::FixedSize;
                RedrawSvgLater(hwnd);
                RealignBitmapOffsetsLater();
                break;

            case IDM_SIZE_WINDOW:
                g_bitmapSizingDisplay = BitmapSizingDisplay::WindowSize;
                RedrawSvgLater(hwnd);
                RealignBitmapOffsetsLater();
                break;

            case IDM_SIZE_WATERFALL:
                g_bitmapSizingDisplay = BitmapSizingDisplay::Waterfall;
                RedrawSvgLater(hwnd);
                RealignBitmapOffsetsLater();
                break;

            case IDM_SIZE_NATURAL:
                g_bitmapSizingDisplay = BitmapSizingDisplay::Natural;
                RedrawSvgLater(hwnd);
                RealignBitmapOffsetsLater();
                break;

            case IDM_SIZE_WRAPPED:
                g_bitmapSizeWrapped = !g_bitmapSizeWrapped;
                RedrawSvgLater(hwnd);
                RealignBitmapOffsetsLater();
                break;

            case IDM_SIZE_FLOW_RIGHT_DOWN:
                g_canvasFlowDirection = CanvasItem::FlowDirection::RightDown;
                RedrawSvgLater(hwnd);
                RealignBitmapOffsetsLater();
                break;

            case IDM_SIZE_FLOW_DOWN_RIGHT:
                g_canvasFlowDirection = CanvasItem::FlowDirection::DownRight;
                RedrawSvgLater(hwnd);
                RealignBitmapOffsetsLater();
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
                static_assert(IDM_ZOOM9 + 1 - IDM_ZOOM0 == _countof(g_zoomFactors), "g_zoomFactors is not the correct size");
                ChangeBitmapZoomCentered(hwnd, g_zoomFactors[wmId - IDM_ZOOM0]);
                break;

            case IDM_ZOOM_IN:
            case IDM_ZOOM_OUT:
                ChangeBitmapZoomCentered(hwnd, FindValueNextPrevious<uint32_t>(g_zoomFactors, g_bitmapPixelZoom, wmId == IDM_ZOOM_IN ? 1 : -1));
                break;

            case IDM_COPY_BITMAP:
                CopyBitmapToClipboard(g_bitmap, hwnd);
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
                ConstrainBitmapOffsetsLater();
                break;

            case IDM_INVERT_COLORS:
                g_invertColors = !g_invertColors;
                RedrawSvgLater(hwnd);
                ConstrainBitmapOffsetsLater();
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
                static_assert(IDM_GRID_SIZE_1 == IDM_GRID_SIZE_FIRST);
                static_assert(IDM_GRID_SIZE_32 == IDM_GRID_SIZE_LAST);
                static_assert(IDM_GRID_SIZE_LAST + 1 - IDM_GRID_SIZE_FIRST == _countof(g_gridSizes), "g_gridSizes is not the correct size");
                g_gridSize = g_gridSizes[wmId - IDM_GRID_SIZE_FIRST];
                RedrawBitmapLater(hwnd);
                break;

            case IDM_NAVIGATE_UP: HandleBitmapScrolling(hwnd, SB_LINEUP, g_bitmapScrollStep, /*isHorizontal*/ false); break;
            case IDM_NAVIGATE_DOWN: HandleBitmapScrolling(hwnd, SB_LINEDOWN, g_bitmapScrollStep, /*isHorizontal*/ false); break;
            case IDM_NAVIGATE_LEFT: HandleBitmapScrolling(hwnd, SB_LINELEFT, g_bitmapScrollStep, /*isHorizontal*/ true); break;
            case IDM_NAVIGATE_RIGHT: HandleBitmapScrolling(hwnd, SB_LINERIGHT, g_bitmapScrollStep, /*isHorizontal*/ true); break;
            case IDM_NAVIGATE_PRIOR: HandleBitmapScrolling(hwnd, SB_PAGEUP, g_bitmapScrollStep, /*isHorizontal*/ false); break;
            case IDM_NAVIGATE_NEXT: HandleBitmapScrolling(hwnd, SB_PAGEDOWN, g_bitmapScrollStep, /*isHorizontal*/ false); break;
            case IDM_NAVIGATE_HOME: HandleBitmapScrolling(hwnd, SB_PAGELEFT, g_bitmapScrollStep, /*isHorizontal*/ true); break;
            case IDM_NAVIGATE_END: HandleBitmapScrolling(hwnd, SB_PAGERIGHT, g_bitmapScrollStep, /*isHorizontal*/ true); break;

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
                RedrawSvgLater(hwnd);
                LoadSvgFiles(std::move(filenameList));
                RedrawSvgLater(hwnd);
            }
        }
        break;

    case WM_INITMENUPOPUP:
        InitializePopMenu(hwnd, reinterpret_cast<HMENU>(wParam), LOWORD(lParam));
        break;

    case WM_WINDOWPOSCHANGED:
        if (!(reinterpret_cast<WINDOWPOS*>(lParam)->flags & SWP_NOSIZE))
        {
            RedrawSvgLater(hwnd);
            ConstrainBitmapOffsetsLater();
        }
        break;

    case WM_ERASEBKGND:
        return 1;

    case WM_PAINT:
        RepaintWindow(hwnd);
        break;

    case WM_HSCROLL:
    case WM_VSCROLL:
        HandleBitmapScrolling(hwnd, LOWORD(wParam), g_bitmapScrollStep, /*isHorizontal*/ message == WM_HSCROLL);
        break;

    case WM_MOUSEWHEEL:
        OnMouseWheel(hwnd, GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam), GET_WHEEL_DELTA_WPARAM(wParam), GET_KEYSTATE_WPARAM(wParam));
        break;

    case WM_MBUTTONDOWN:
        g_previousMouseX = LOWORD(lParam);
        g_previousMouseY = HIWORD(lParam);
        break;

    case WM_MOUSEMOVE:
        if (wParam & MK_MBUTTON)
        {
            int32_t x = LOWORD(lParam);
            int32_t y = HIWORD(lParam);
            HandleBitmapScrolling(hwnd, g_previousMouseX - x, g_previousMouseY - y);
            g_previousMouseX = x;
            g_previousMouseY = y;
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
