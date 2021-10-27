/*
Dwayne Robinson
2003-07-01

What:
    A selectable list of attributes, like one of Visual Studio's property
    lists. Each item can behave like a different kind of basic dialog
    control, acting like a menu, toggle button, push button, and even
    edit box.

Why:
    A few programs of mine (a file browser, music player, 3D model viewer)
    needed to display a lot of modifiable choices in limited space. The use
    of multiple dialog controls was getting too crowded and unflexible.
    It's not nearly as extensible or as mature as Visual Studio's property
    list, but it satisfies the basic needs.

Which:
    Items can be any one of the following types:

    label - simply text display, nonmodifiable
    push buttons/hyperlinks - one click actions/commands
    toggle buttons/checkboxes - two state values (true/false, yes/no, up/down)
    menu buttons - clicking opens a multivalue menu of choices
    text edit - Unicode single line text string
    title bar - caption for single list or separator for multiple sections
    separator - just some white space to separate attributes (empty label)

Example:
    Include: *Chrono*;*.jpg;*.gif
    Exclude: *Cross*
    Size >= 1024
    Size <= 2048
    Date >= 1990-03-01
    Date <= 2003-03-01

    Case specific: yes
    Recurse containers: yes
    Search direction: up

    Find
    Reset form
    Clear list
    Queue
    Copy
*/
////////////////////////////////////////////////////////////////////////////////

#include "precomp.h"
#include "attributelist.h"


#ifndef HINST_THISCOMPONENT
EXTERN_C IMAGE_DOS_HEADER __ImageBase;
#define HINST_THISCOMPONENT ((HINSTANCE)&__ImageBase)
#endif

#ifndef IDC_HAND
#define IDC_HAND 32649
#endif


////////////////////////////////////////////////////////////////////////////////


HFONT g_guiFont;
HFONT g_guiFontTitle;
HFONT g_guiFontStale;
HCURSOR g_cursorArrow;
HCURSOR g_cursorIbeam;
HCURSOR g_cursorHand;

HWND g_hoverHwnd = nullptr;
RECT g_hoverRect = {0};
unsigned int g_caretIndex = 0;

static uint32_t g_clipboardFormats[2] = {CF_UNICODETEXT, CF_TEXT};

enum {PixelImageWidth = 8, PixelImageHeight = 7};

const static UINT32 g_menuPixels[7]      = {128,192,224,240,224,192,128};   // triangle for menu item
const static UINT32 g_closedPixels[7]      = {128,192,224,240,224,192,128};   // triangle for closed node
const static UINT32 g_openPixels[7]      = {0,0,254,124,56,16,0};   // triangle for open node
const static UINT32 g_checkedPixels[7]   = {2,6,142,220,248,112,32};        // check mark
const static UINT32 g_uncheckedPixels[7] = {198,238,124,56,124,238,198};    // x mark


////////////////////////////////////////////////////////////////////////////////


void AttributeList::Init()
{
    hwnd_           = nullptr;
    hoverlay_       = nullptr;
    himl_           = nullptr;
    selectedIndex_  = 0;
    hoveredIndex_   = UINT_MAX;
    topIndex_       = 0;     
    totalItems_     = 0;   
    items_          = nullptr;
}


AttributeList::AttributeList()
{
    Init();
}


AttributeList::AttributeList(__ecount(totalItems) Item* items, unsigned int totalItems)
{
    Init();
    items_ = items;
    totalItems_ = totalItems;
}


////////////////////////////////////////////////////////////////////////////////

// purpose:
//		counts how many choices are in a menu item.
//		the last choice is terminated by a double null.
// !assumes:
//		text is double null terminated (so it is from a menu item)
//
static UINT8 TotalChoices(const __nullnullterminated WCHAR* text)
{
    UINT8 total = 0;
    if (text != nullptr)
    {
        while (*text != '\0')
        {
            if (total >= UINT8_MAX)
            {
                break;
            }
            total++;
            text += wcslen(text)+1; // skip ahead by size of string + NULL
        }
    }
    return total;
}


static inline UINT32 ReverseBGR(UINT32 rgb)
{
    // Remedy the unexpected inconsistency between DIB pixels and RGBQUAD.
    return (rgb & 0xFF000000) | ((rgb & 0x000000FF) << 16) | (rgb & 0x0000FF00) | ((rgb & 0x00FF0000) >> 16);
}


// purpose:
//		returns the appropriate graphic beside an item depending on type.
//
static const UINT32* GetItemTypePixels(UINT32 itemFlags, UINT32 value)
{
    if (itemFlags & AttributeList::Item::FlagHideMark)
    {
        return nullptr;
    }

    switch (itemFlags & AttributeList::Item::FlagTypeMask)
    {
    case AttributeList::Item::FlagOptionType:
        return g_menuPixels;

    case AttributeList::Item::FlagNodeType:
        return (value > 0) ? g_openPixels : g_closedPixels;

    case AttributeList::Item::FlagToggleType:
        return (value > 0) ? g_checkedPixels : g_uncheckedPixels;
        break;
    }
    return nullptr;
}


UINT32 AttributeList::GetItemValue(uint16_t id, AttributeList::Item* items, unsigned int totalItems)
{
    AttributeList::Item* item = FindMatchingItem(id, items, totalItems);
    if (item != nullptr)
    {
        return item->value;
    }
    return -1;
}


AttributeList::Item* AttributeList::FindMatchingItem(uint16_t id, AttributeList::Item* items, unsigned int totalItems)
{
    for (unsigned int i = 0; i < totalItems; ++i)
    {
        if (items[i].id == id)
        {
            return &items[i];
        }
    }

    return nullptr;
}


unsigned int AttributeList::FindMatchingItemIndex(uint16_t id, AttributeList::Item* items, unsigned int totalItems)
{
    auto item = FindMatchingItem(id, items, totalItems);
    if (item == nullptr )
        return -1;

    return static_cast<unsigned int>(item - items);
}


AttributeList::Item* AttributeList::FindMatchingItem(uint16_t id)
{
    return FindMatchingItem(id, items_, totalItems_);
}


////////////////////////////////////////////////////////////////////////////////


bool AttributeList::RegisterWindowClass(HINSTANCE hModule)
{
    WNDCLASSEX wcAtrList        = {sizeof(WNDCLASSEX)},
               wcAtrOverlay     = {sizeof(WNDCLASSEX)};

	wcAtrList.style             = CS_OWNDC|CS_DBLCLKS;
	wcAtrList.lpfnWndProc       = &AttributeList::WindowProc;
	wcAtrList.hInstance         = hModule;
	wcAtrList.hCursor           = LoadCursor(nullptr, IDC_ARROW);
	wcAtrList.lpszClassName     = L"AttributeList";

	wcAtrOverlay.style          = CS_NOCLOSE;
	wcAtrOverlay.lpfnWndProc    = &AttributeList::Overlay::WindowProc;
	wcAtrOverlay.hInstance      = hModule;
	wcAtrOverlay.hCursor        = LoadCursor(nullptr, IDC_ARROW);
	wcAtrOverlay.lpszClassName  = L"AttributeListOverlay";

	return RegisterClassEx(&wcAtrList)    != 0
        && RegisterClassEx(&wcAtrOverlay) != 0;
}


LRESULT CALLBACK AttributeList::WindowProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    AttributeList* list = reinterpret_cast<AttributeList*>(GetWindowLongPtr(hwnd, GWLP_USERDATA));
    return list->InternalWindowProc(hwnd, message, wParam, lParam);
}


LRESULT CALLBACK AttributeList::InternalWindowProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    // Many messages use these two variables.
    ListMetrics metrics;
    UINT32 flags;

    switch (message)
    {

    case WM_NCCREATE:
    {
        // Create the window.
        CREATESTRUCT* pcs = reinterpret_cast<CREATESTRUCT*>(lParam);
        AttributeList* classInstance = reinterpret_cast<AttributeList*>(pcs->lpCreateParams);

        if (classInstance == nullptr)
            classInstance = new(std::nothrow) AttributeList();

        if (classInstance == nullptr)
            return -1; // failed creation

        SetWindowLongPtr(hwnd, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(classInstance));
        classInstance->hwnd_ = hwnd;

        return DefWindowProc(hwnd, message, wParam, lParam);
    }

    case WM_CREATE:
    {
        // Initialize display context to have standard GUI font
        // transparent blitting, and no useless pen.

        HDC hdc = GetDC(hwnd);

        if (g_guiFont == nullptr)
        {
            LOGFONT lf;
            SystemParametersInfo(SPI_GETICONTITLELOGFONT, sizeof(LOGFONT), &lf, 0);
            HFONT guiFont = CreateFontIndirect(&lf);
            g_guiFont = guiFont;
            if (g_guiFont != guiFont)
            {
                DeleteObject(guiFont);
            }
        }
        SelectObject(hdc, g_guiFont);

        if (g_guiFontTitle == nullptr)
        {
            NONCLIENTMETRICS ncm;
            ncm.cbSize = sizeof(NONCLIENTMETRICS);
            SystemParametersInfo(SPI_GETNONCLIENTMETRICS, 0, &ncm, 0);
            GetObject(g_guiFont, sizeof(LOGFONT), &ncm.lfMessageFont);

            ncm.lfCaptionFont.lfHeight = ncm.lfMessageFont.lfHeight;
            ncm.lfCaptionFont.lfWeight = FW_BOLD;

            HFONT guiFont = CreateFontIndirect(&ncm.lfCaptionFont);
            g_guiFontTitle = guiFont;
            if (g_guiFontTitle != guiFont)
            {
                DeleteObject(guiFont);
            }
        }

        if (g_guiFontStale == nullptr)
        {
            LOGFONT lf;
            SystemParametersInfo(SPI_GETICONTITLELOGFONT, sizeof(LOGFONT), &lf, 0);
            lf.lfStrikeOut = true;
            HFONT guiFont = CreateFontIndirect(&lf);
            g_guiFontStale = guiFont;
            if (g_guiFontStale != guiFont)
            {
                DeleteObject(guiFont);
            }
        }

        SetBkMode(hdc, TRANSPARENT);
        SelectObject(hdc, GetStockObject(NULL_PEN));

        if (g_cursorArrow == nullptr)
            g_cursorArrow = LoadCursor(0,IDC_ARROW);
        if (g_cursorIbeam == nullptr)
            g_cursorIbeam = LoadCursor(0,IDC_IBEAM);
        if (g_cursorHand  == nullptr)
            g_cursorHand = LoadCursor(0,IDC_HAND);

        //hoverlay_ = CreateWindowEx(0, L"AttributeListOverlay",L"AttributeListOverlay", WS_CHILD, 0,0, 100,24, GetParent(hwnd),nullptr, HINST_THISCOMPONENT, nullptr);
        hoverlay_ = CreateWindowEx(0, L"AttributeListOverlay",L"AttributeListOverlay", WS_POPUP|WS_CHILD, 0,0, 100,24, hwnd,nullptr, HINST_THISCOMPONENT, nullptr);
        if (hoverlay_ != nullptr)
        {
            // Set our hwnd into the overlay so it can find its creator.
            AttributeList::Overlay& overlay = *AttributeList::Overlay::GetClass(hoverlay_);
            overlay.howner_ = hwnd;
            overlay.text_ = nullptr;
        }

        return 0;
    }

    case MessageSetItems:
    {
        if (lParam == NULL)
        {
            return LB_ERR;
        }

        items_ = reinterpret_cast<Item*>(lParam);
        totalItems_ = static_cast<unsigned int>(wParam);
        selectedIndex_ = 0;
        hoveredIndex_ = UINT_MAX;
        topIndex_ = 0;

        GetListMetrics(&metrics);

        SetScrollBars(metrics);
        ResizeOverlay();

        // Select the first non-disabled item.
        if (GetSelectedItemFlags(OUT &flags))
        {
            if (!Item::IsEnabled(flags))
            {
                selectedIndex_ = Seek(0, 1, Item::FlagHidden|Item::FlagNoSelect);
            }
        }

        if (GetSelectedItemFlags(OUT &flags))
        {
            SetCaretIndex(UINT_MAX);
        }

        g_hoverRect.bottom = 0; // force mouse recalc upon next mouse move

        InvalidateRect(hwnd, nullptr, FALSE);
        return TRUE;
    }

	case WM_DESTROY:
    {
        // Destroy the overlay and class instance.
        DestroyWindow(hoverlay_);
        LRESULT result = DefWindowProc(hwnd, message, wParam, lParam);
        delete this;
        return result;
    }
    
    case WM_PAINT:
    {
        DWORD   captionTextColor            = GetSysColor(COLOR_CAPTIONTEXT),
                activeTextColor             = GetSysColor(COLOR_HIGHLIGHTTEXT),
                inactiveTextColor           = GetSysColor(COLOR_INACTIVECAPTIONTEXT),
                selectedTextColor           = GetSysColor(COLOR_BTNTEXT),
                unselectedTextColor         = GetSysColor(COLOR_WINDOWTEXT),
                disabledTextColor           = GetSysColor(COLOR_GRAYTEXT),
                activeBackgroundColor       = GetSysColor(COLOR_HIGHLIGHT),
                selectedBackgroundColor     = GetSysColor(COLOR_BTNFACE),
                unselectedBackgroundColor   = GetSysColor(COLOR_WINDOW);
                //selectedBackgroundColor = ((activeBackgroundColor & 0xFEFEFE) + (unselectedBackgroundColor & 0xFEFEFE)) >> 1; // blend halfway

        bool hasFocus = (GetFocus()==hwnd);
        bool isSecondPass = false;          // two pass counter
        DWORD bgColor, textColor;           // color of background and text
        unsigned int len;                   // length of string, either text or label
        HRGN urgn = CreateRectRgn(0,0,0,0); // create dummy region

        // get update regions
        HDC hdc = GetDC(hwnd);

        RECT updateRect;
        GetUpdateRect(hwnd, &updateRect, FALSE);
        GetUpdateRgn(hwnd, urgn, FALSE);
        ValidateRect(hwnd, nullptr);

        GetListMetrics(&metrics);
        int caretY  = (metrics.itemHeight - metrics.textHeight)>>1;
        int iconY   = (metrics.itemHeight - metrics.iconHeight)>>1;
        RECT rect;

        // draw all items in two pass loop
        for (;;)
        {
            // set item rectangle
            rect        = metrics.clientRect;
            rect.bottom = metrics.itemHeight;

            if (totalItems_ == 0 && !isSecondPass)
            {
                SetBkColor(hdc, unselectedBackgroundColor);
                SetTextColor(hdc, unselectedTextColor);

                WCHAR text[128];
                ExtTextOutW(hdc, 0,0, ETO_OPAQUE, &rect, nullptr,0, nullptr);
                SelectObject(hdc, g_guiFont);
                int len = GetWindowText(hwnd, text, ARRAYSIZE(text));
                TextOutW(hdc, rect.left + 2, rect.top + caretY, text,len);
            }

            for (unsigned int itemIndex = topIndex_; itemIndex < totalItems_; ++itemIndex)
            {
                // if visible and needs redrawing

                Item& item = items_[itemIndex];

                flags = item.flags;
                if (!(flags & Item::FlagHidden))
                {
                    if (flags & Item::FlagRedraw)
                    {
                        item.flags &= ~Item::FlagRedraw;
                        bool hasItemFocus = ((itemIndex == selectedIndex_) & hasFocus);

                        // Set initial text offset.
                        int x = 2 + item.indent * metrics.itemIndent;

                        UINT32 itemType = (flags & Item::FlagTypeMask);

                        // set colors according to type and whether selected
                        if (hasItemFocus)                           bgColor = activeBackgroundColor;
                        else if (itemIndex == selectedIndex_)       bgColor = selectedBackgroundColor;
                        else                                        bgColor = unselectedBackgroundColor;
                        SetBkColor(hdc, bgColor);

                        if (hasItemFocus)                           textColor = activeTextColor;
                        else if (flags & Item::FlagGray)            textColor = disabledTextColor;
                        else if (itemType == Item::FlagTitleType)   textColor = (hasFocus) ? captionTextColor : inactiveTextColor;
                        else if (itemIndex == selectedIndex_)       textColor = selectedTextColor;
                        else                                        textColor = unselectedTextColor;
                        SetTextColor(hdc, textColor);

                        // draw background
                        ExtTextOutW(hdc, 0,0, ETO_OPAQUE, &rect, nullptr,0, nullptr);

                        // set font bold if title, and draw background
                        HFONT hlf = g_guiFont;
                        if (itemType == Item::FlagTitleType)
                        {
                            hlf = g_guiFontTitle;
                            int colorIndex = (flags & Item::FlagGray) ? COLOR_BTNFACE : (hasFocus ? COLOR_ACTIVECAPTION : COLOR_INACTIVECAPTION);
                            SelectObject(hdc, GetSysColorBrush(colorIndex));
                            RoundRect(hdc, 1,rect.top+1, rect.right,rect.bottom, 11,12);
                            x += 4;
                        }
                        else if (flags & Item::FlagStale)
                        {
                            hlf = g_guiFontStale;
                        }
                        SelectObject(hdc, hlf);

                        // draw icon at very left (usually 16x16)
                        if (item.icon > 0 && himl_ != nullptr)
                        {
                            ImageList_Draw(himl_, item.icon, hdc, 2, rect.top + iconY, ILD_TRANSPARENT);
                            x += metrics.iconWidth + 2;
                        }
                        else
                        {
                            // select correct little graphic to display beside text (in addition to the icon)
                            const UINT32* pixels = GetItemTypePixels(flags, item.value);

                            // display little check mark, chevron, or other graphic
                            if (pixels != nullptr)
                            {
                                struct {
                                    BITMAPINFOHEADER bih;
                                    UINT32 pal[2]; //RGBQUAD array
                                }
                                itemBitmap = {sizeof(BITMAPINFOHEADER),PixelImageWidth,-PixelImageHeight, 1,1,BI_RGB, PixelImageHeight*4,96,96, 2,2};

                                // Why are bitmaps upside down??
                                // Why aren't DIB pixels consistent with RGBQUADS??
                                itemBitmap.pal[0] = ReverseBGR(bgColor);
                                itemBitmap.pal[1] = ReverseBGR(textColor);
                                SetDIBitsToDevice(
                                    hdc,
                                    x, rect.top+((metrics.itemHeight-PixelImageHeight)>>1),
                                    PixelImageWidth,PixelImageHeight,
                                    0,0,
                                    0,PixelImageHeight,
                                    pixels,
                                    (BITMAPINFO*)&itemBitmap,
                                    DIB_RGB_COLORS
                                    );
                                x += PixelImageWidth + 2;
                            }
                        }

                        // print label, regardless of type
                        if (item.label != nullptr)
                        {
                            __nullterminated const WCHAR* text = item.label;
                            len = wcslen(text);
                            TextOutW(hdc, x, rect.top + caretY, text,len);
                            //DrawState(hdc, nullptr, nullptr, "test",4, x,rect.top, 0,0, DST_TEXT|DSS_DISABLED);
                            SIZE sz;
                            GetTextExtentPoint32W(hdc, text, len, &sz);
                            x += sz.cx;
                        }

                        // print text, dependent on type
                        if (item.text != nullptr)
                        {
                            __nullterminated const WCHAR* text = GetItemText(itemIndex); // for check/group/menu, nop for others
                            len  = wcslen(text);
                            TextOutW(hdc, x,rect.top + caretY, text,len);
                            SIZE sz;
                            GetTextExtentPoint32W(hdc, text, len, &sz);
                            x += sz.cx;
                        }
                    }
                    else if (!isSecondPass) // mark if needs redrawing next pass
                    {
                        RECT intersectRect;
                        if (IntersectRect(&intersectRect, &updateRect, &rect))
                            item.SetRedraw();
                    }

                    // move current row down one
                    rect.top    += metrics.itemHeight;
                    rect.bottom += metrics.itemHeight;
                }
            }

            if (isSecondPass)
                break;
            isSecondPass = true;

            SelectClipRgn(hdc, urgn); // clip to update region
        } // end two passes

        // Fill remainder of attribute list below last row
        rect.bottom = 16384;
        FillRect(hdc, &rect, (HBRUSH)(COLOR_WINDOW+1));
        SelectClipRgn(hdc, nullptr); // no clip region
        DeleteObject(urgn);

        ReleaseDC(hwnd_, hdc);

        return 0;
    }

    case WM_ERASEBKGND:
        return TRUE;

    case WM_MOUSEMOVE:
        if (!GetCapture())
        {
            int x = GET_X_LPARAM(lParam);
            int y = GET_Y_LPARAM(lParam);

            if (UpdateHoverItem(y) < UINT_MAX)
            {
                UINT32 flags = items_[hoveredIndex_].flags;
                switch (flags & Item::FlagTypeMask) {
                case Item::FlagButtonType:
                case Item::FlagToggleType:
                case Item::FlagOptionType:
                    SetCursor((x < g_hoverRect.right) ? g_cursorHand : g_cursorArrow);
                    break;

                case Item::FlagEditType:
                    SetCursor((x >= g_hoverRect.left) ? g_cursorIbeam : g_cursorArrow);
                    break;

                default: // else label, title, or separator
                    SetCursor(g_cursorArrow);
                    break;
                }
            } else {
                SetCursor(g_cursorArrow);
            }
        }
        return 0;

    case WM_LBUTTONDBLCLK:
    case WM_LBUTTONDOWN:
    {
        int x = GET_X_LPARAM(lParam);
        int y = GET_Y_LPARAM(lParam);
        int wantFocus = TRUE;

        // select choice and set caret or activate choice
        if (UpdateHoverItem(y) < UINT_MAX)
        {
            const Item& item = items_[hoveredIndex_];
            if (item.IsEnabled())
            {
                switch (item.GetType())
                {
                case Item::FlagEditType:
                {
                    SetFocus(hwnd);
                    wantFocus = FALSE; // already have it, so don't set it again below

                    // preset focus or else I have problems putting
                    // the caret where it should not be.
                    SelectGiven(hoveredIndex_, (x < g_hoverRect.left) ? SelectionModeResetCaret : SelectionModeNone );

                    __nullterminated const WCHAR* text;

                    if (selectedIndex_ == hoveredIndex_
                    &&  x >= g_hoverRect.left
                    &&  (text = item.text) != nullptr)
                    {
                        // 2003-09-12 now works for Japanese fonts without needing to
                        // set the character set to Japanese. Does NOT work with RTL
                        // texts like Hebrew though :/

                        HDC hdc = GetDC(hwnd);
                        SelectObject(hdc, g_guiFont);
                        x -= g_hoverRect.left;

                        unsigned int len = wcslen(text) + 1;
                        if (len > Item::MaxValue+1)
                            len = Item::MaxValue+1;

                        //todo:verify
                        // NT only, does not work on 9x

                        SIZE sz;
                        int caret[Item::MaxValue + 2];
                        GetTextExtentExPointW(hdc, text,len, 0,nullptr, &caret[1],&sz);
                        caret[0] = 0;

                        ReleaseDC(hwnd, hdc);

                        int newIndex = 0, width = 32767;

                        for (unsigned int idx = 0; idx < len; idx++)
                        {
                            int dif = x - caret[idx]; //get pixel difference
                            if (dif < 0)
                                dif = -dif;
                            if (dif < width) {
                                width = dif;
                                newIndex = idx;
                            }
                        }
                        SetCaretIndex(newIndex);
                    }
                    break;
                }

                case Item::FlagOptionType:
                    SelectGiven(hoveredIndex_, SelectionModeNone);
                    if (x < g_hoverRect.right)
                    {
                        wantFocus = false;
                        SetFocus(hwnd); // set focus -before- displaying menu
                        ShowChoiceMenu();
                    }
                    break;

                case Item::FlagButtonType:
                    if (x < g_hoverRect.right)
                    {
                        wantFocus = false; // do not set focus is clicked on button
                        if (item.text == nullptr) // Just a single click button.
                        {
                            SendClickCommand(item.id);
                        }
                        else // else it has subchoices, so display menu.
                        {
                            SetFocus(hwnd); // set focus -before- displaying menu
                            ShowChoiceMenu(hoveredIndex_);
                        }
                    }
                    else
                    {
                        SelectGiven(hoveredIndex_, SelectionModeNone);
                    }
                    break;

                case Item::FlagToggleType:
                    SelectGiven(hoveredIndex_, SelectionModeNone);
                    if (x < g_hoverRect.right)
                    {
                        SetButtonValue((item.value) ? 0 : 1);
                    }
                    break;

                case Item::FlagLabelType:
                default:
                    SelectGiven(hoveredIndex_, SelectionModeNone);
                }
            }
        }

        if (wantFocus)
            SetFocus(hwnd); // set focus if clicked on disabled, title, separator

        return 0;
    }

    case WM_MOUSEACTIVATE:
        return MA_NOACTIVATE;
        //SetFocus(hwnd);

    case WM_RBUTTONUP:
        return TRUE;

    case WM_RBUTTONDOWN:
        {
            int x = GET_X_LPARAM(lParam);
            int y = GET_Y_LPARAM(lParam);

            SelectGiven(UpdateHoverItem(y), SelectionModeResetCaret);
            ShowContextMenu(hoveredIndex_, x, y);
        }
        return 0;

    case WM_CONTEXTMENU:
    {
        if ((HWND)wParam != hwnd || !GetSelectedItemFlags(OUT &flags) || GET_X_LPARAM(lParam) != -1)
            return DefWindowProc(hwnd, message, wParam, lParam);

        RECT rect;
        GetItemTextRect(selectedIndex_, &rect); //show menu just below selected row
        ShowContextMenu(selectedIndex_, rect.left,rect.bottom);
        return 0;
    }

    case WM_MENUSELECT: // relay help messages to parent
    {
        // should ignore if group popup menu
        HELPINFO hi = {
           sizeof(HELPINFO),
           HELPINFO_MENUITEM,
           wParam & 0xFFFF,
           (HANDLE)lParam,
           (DWORD_PTR)hwnd,
           0, 0
        };
        SendMessage(GetParent(hwnd), WM_HELP, 0, (LPARAM)&hi);
        return 0;
    }

    case WM_COMMAND:
        {
            unsigned id = LOWORD(wParam);

            if (id <= 255) // choice menu sent message for selected option
            {
                if (GetSelectedItemFlags(OUT &flags) && Item::IsEnabledType(flags, Item::FlagOptionType))
                {
                    if (id < TotalChoices(items_[selectedIndex_].text))
                        SetButtonValue((UINT8)id);
                }
            }
            else if (id >= IdMax) // special msg relayed to parent, or a choice menu sent message for selected command
            {
                return SendMessage(GetParent(hwnd), WM_COMMAND, wParam, lParam);
            }
            else // context menu sent message
            {
                if (id == IdCopyAll)
                {
                    return CopyAllText();
                }

                if (!GetSelectedItemFlags(OUT &flags))
                    return 0;

                switch (id)
                {
                case IdCopy:
                    return CopyText(selectedIndex_);

                case IdPaste:
                    return PasteText();

                case IdClear:
                    return ClearText();

                case IdToggle: 
                    if (Item::IsEnabledType(flags, Item::FlagToggleType))
                        SetButtonValue(items_[selectedIndex_].value ? 0 : 1);
                    return 0;

                case IdCommand:
                    if (Item::IsEnabledType(flags, Item::FlagButtonType))
                        SendClickCommand(items_[selectedIndex_].id);
                    return 0;

                case IdHelp:
                    {
                        HELPINFO helpInfo = {
                            sizeof(HELPINFO),
                            HELPINFO_WINDOW,
                            0, 0, 0,
                            0, 0
                        };
                        helpInfo.hItemHandle = hwnd; //set source to self
                        helpInfo.iCtrlId = GetDlgCtrlID(hwnd);
                        helpInfo.iContextType = HELPINFO_WINDOW;
                        POINT pt = {0};
                        SendHelpToParent(&helpInfo, selectedIndex_, pt);
                    }
                }
            }
        }
        return 0;

    case WM_COPY:
        if (wParam == -1) // special case message to copy all item's text
            return CopyAllText();

        return CopyText(selectedIndex_);

    case WM_PASTE:
        return PasteText();

    case WM_CLEAR:
        return ClearText();

    case WM_MOUSEWHEEL:
        {
            // Retrieve the lines-to-scroll user setting. 
            INT userSetting = 3;
            BOOL success = SystemParametersInfo(
                                SPI_GETWHEELSCROLLLINES,
                                0, 
                                &userSetting, 
                                0
                                );
            if (success == FALSE)
                userSetting = 3;

            int zDelta = GET_WHEEL_DELTA_WPARAM(wParam) * userSetting / -WHEEL_DELTA;
            if (zDelta == 0) // must have one of those slow-scroll mice
                zDelta = GET_WHEEL_DELTA_WPARAM(wParam) > 0 ? -1 : 1;
            ScrollBy(zDelta, SelectionModeDefault);
        }
        return TRUE;

    case WM_VSCROLL:
    {
        int dif;
        UINT32 selectionMode = SelectionModeDefault;
        ListMetrics metrics;
        GetListMetrics(&metrics);

        switch (wParam & 0xFFFF)
        {
        case SB_LINEUP:     dif = -1;                                                       break;
        case SB_LINEDOWN:   dif =  1;                                                       break;
        case SB_PAGEUP:     dif = -1;               selectionMode = SelectionModePage;      break;
        case SB_PAGEDOWN:   dif =  1;               selectionMode = SelectionModePage;      break;
        case SB_THUMBTRACK: dif = HIWORD(wParam);   selectionMode = SelectionModeAbsolute;  break;
        case SB_TOP:        dif = 0;                selectionMode = SelectionModeAbsolute;  break;
        case SB_BOTTOM:     dif = totalItems_;      selectionMode = SelectionModeAbsolute;  break;
        default:
            return 0;
        }
        ScrollBy(dif, selectionMode);
        return 0;
    }

    case WM_GETDLGCODE:
        if (wParam == VK_RETURN && GetSelectedItemFlags(OUT &flags))
            if ((flags & Item::FlagTypeMask) == Item::FlagButtonType)
                return DLGC_WANTCHARS|DLGC_WANTARROWS|DLGC_WANTALLKEYS;

        return DLGC_WANTARROWS|DLGC_WANTCHARS;

    case WM_KEYDOWN:
        {
            bool isKeyHandled = true;

            // generic keys for all types
            switch (wParam)
            {
            case VK_DOWN:
            case VK_UP:
                Select(Seek(selectedIndex_, (wParam == VK_DOWN) ? 1 : -1, Item::FlagHidden|Item::FlagNoSelect));
                break;

            case VK_NEXT:
            case VK_PRIOR:
                ScrollBy((wParam == VK_NEXT) ? 1:-1, SelectionModePage|SelectionModeParallel);
                break;

            case VK_HOME: 
            case VK_END:
                if (GetKeyState(VK_CONTROL) & 0x80)
                    Select(Seek(selectedIndex_, wParam == VK_HOME ? -int(totalItems_) : totalItems_, Item::FlagHidden|Item::FlagNoSelect));
                else
                    isKeyHandled = false;
                break;

            case VK_INSERT:
                if (GetKeyState(VK_CONTROL) & 0x80)
                    CopyText(selectedIndex_); // Ctrl+Ins to copy
                break;

            default:
                isKeyHandled = false;
                break;
            }

            // Specific keys for individual types, if not handled generically.
            if (!isKeyHandled)
            {
                // a disabled item or separator should never be selected, but just in case
                // some program code has changed things behind this code's back
                if (!GetSelectedItemFlags(OUT &flags) || !Item::IsEnabled(flags))
                    return 0;

                Item& item = items_[selectedIndex_];

                switch (flags & Item::FlagTypeMask) {

                case Item::FlagEditType:
                    switch (wParam)
                    {
                    case VK_LEFT:
                        if (g_caretIndex > 0)
                            SetCaretIndex(g_caretIndex - 1);
                        break;

                    case VK_RIGHT:
                        SetCaretIndex(g_caretIndex + 1);
                        break;

                    case VK_HOME: 
                        SetCaretIndex(0);
                        break;

                    case VK_END:
                        SetCaretIndex(UINT_MAX);
                        break;

                    case VK_DELETE:
                        DeleteChar();
                        break;

                    case VK_BACK:
                        if (g_caretIndex > 0)
                        {
                            SetCaretIndex(g_caretIndex - 1);
                            DeleteChar();
                        }
                        break;

                    case VK_INSERT:
                        if (GetKeyState(VK_SHIFT) & 0x80)
                            PasteText(); // Shift+Ins to paste
                    }
                    break;

                case Item::FlagToggleType:
                    {
                        if (lParam & (1<<30))
                            break; // catch, ignore repeated keypresses

                        UINT32 value = item.value;

                        switch (wParam)
                        {
                        case VK_HOME:
                        case VK_LEFT:
                            if (value != 0)
                                SetButtonValue(0);
                            break;

                        case VK_END:
                        case VK_RIGHT:
                            if (value != 1)
                                SetButtonValue(1);
                            break;

                        case VK_SPACE:
                        case VK_RETURN:
                            SetButtonValue(value ? 0 : 1); // toggle check state
                        }
                    }
                    break;

                case Item::FlagOptionType:
                    {
                        UINT32 value = item.value;

                        switch (wParam) {
                        case VK_SPACE:
                        case VK_RETURN:
                        {
                            MSG msg; // solely to remove the extra space character that makes the ding
                            PeekMessage(&msg, 0,WM_KEYFIRST,WM_KEYLAST,PM_REMOVE);
                            ShowChoiceMenu();
                            break;
                        }
                        case VK_HOME: // set to first, left-most choice
                            SetButtonValue(0);
                            break;

                        case VK_END: // set to last, right-most choice
                            value = TotalChoices(items_[selectedIndex_].text);
                            if (value > 0)
                                SetButtonValue(value - 1);
                            break;

                        case VK_RIGHT:
                            if (value < Item::MaxValue && value + 1 < TotalChoices(items_[selectedIndex_].text))
                                SetButtonValue(value + 1);
                            break;

                        case VK_LEFT:
                            if (value > 0)
                                SetButtonValue(value - 1);
                            break;
                        }
                    }
                    break;

                case Item::FlagButtonType:
                    if (wParam == VK_SPACE || wParam == VK_RETURN)
                    {
                        if (item.text == nullptr) // No suboptions, so just send click immediately.
                        {
                            SendClickCommand(item.id);
                        }
                        else // Suboptions, so show menu.
                        {
                            MSG msg; // solely to remove the extra space character that makes the ding
                            PeekMessage(&msg, 0,WM_KEYFIRST,WM_KEYLAST,PM_REMOVE);
                            ShowChoiceMenu();
                        }
                    }

                    break;
                } // switch
            }
        }

        return 0;

    case WM_CHAR:
        //  if text edit and flags allow
        //	  if valid character
        //	    if room in prompt
        //        insert char
        //    elif backspace
        //      if caret not at leftmost column
        //        move caret one column back
        //        delete character
        //      endif
        //    endif
        //  endif
        if (GetSelectedItemFlags(OUT &flags)
        && Item::IsEnabledType(flags, Item::FlagEditType))
        {
            // if IS edit, and not disabled, hidden, or locked
            if (wParam >= 32) {
                if ((wParam >= 48 && wParam <= 57) || !(flags & Item::FlagNumeric))
                    InsertChar(static_cast<unsigned int>(wParam));
            }
        }
        return 0;

    case WM_KILLFOCUS:
    case WM_SETFOCUS:
        ResizeOverlay();
        if (GetSelectedItemFlags(OUT &flags))
        {
            items_[selectedIndex_].SetRedraw();
            if (message == WM_SETFOCUS)
                SetCaretIndex(UINT_MAX);
        }
        FlagTitlesNeedRedraw();
        PostRedraw();
        return 0;

    case LB_SETCURSEL:
        return Select(static_cast<unsigned int>(wParam));

    case WM_MOVE:
        if (GetFocus() == hwnd)
            ResizeOverlay();
        return 0;

    case WM_WINDOWPOSCHANGED:
        if (!(((LPWINDOWPOS)lParam)->flags & SWP_NOSIZE))
            Resize();
        return 0;

    case WM_SIZE:
        Resize();
        return 0;

    case WM_WINDOWPOSCHANGING:
        {
            // redraw titles if sized horizontally
            RECT rect;
            GetWindowRect(hwnd, &rect);
            if (((WINDOWPOS*)lParam)->cx != (rect.right-rect.left))
            {
                FlagTitlesNeedRedraw();
                PostRedraw();
            }
        }
        return 0;

    case WM_HELP:
    {
        const HELPINFO* helpInfo = (HELPINFO*)lParam;

        unsigned int itemIndex = UINT_MAX;
        POINT pt = {0};
        if (GetKeyState(VK_F1) & 0x80)
        {
            itemIndex = selectedIndex_;
        }
        else
        {
            pt.x = helpInfo->MousePos.x;
            pt.y = helpInfo->MousePos.y;
            ScreenToClient(hwnd, &pt);
            //rect.top  = helpInfo->MousePos.y - rect.top;
            //rect.left = helpInfo->MousePos.x - rect.left;
        }
        SendHelpToParent(helpInfo, itemIndex, pt);
        return TRUE;
    }

    case WM_SETCURSOR:
        if ((lParam & 0xFFFF) == HTCLIENT)
            return TRUE;
        __fallthrough;

    default:
        return DefWindowProc(hwnd, message, wParam, lParam);
    }
}


int AttributeList::CopyText(unsigned int itemIndex)
{
    if (itemIndex >= totalItems_)
        return -1; // just in case no choices

    __nullterminated const WCHAR* text = items_[itemIndex].text;
    if (text != nullptr)
        text = GetItemText(itemIndex);
    if (text == nullptr)
        text = items_[itemIndex].label;

    if (text == nullptr)
        return -1;

    unsigned int textLen = wcslen(text);
    if (textLen > Item::MaxValue)
        textLen = Item::MaxValue;

    if (!OpenClipboard(hwnd_))
        return -1;

    EmptyClipboard();

    HGLOBAL hmWideText = GlobalAlloc(GMEM_MOVEABLE|GMEM_DDESHARE,(textLen+1) * sizeof(wchar_t));
    #ifdef ATTRIBUTE_LIST_COPY_ANSI
    HGLOBAL hmAnsiText = GlobalAlloc(GMEM_MOVEABLE|GMEM_DDESHARE,(textLen+1));
    #endif

    if (hmWideText != nullptr
    #ifdef ATTRIBUTE_LIST_COPY_ANSI
    &&  hmAnsiText != nullptr
    #endif
        )
    {
        __ecount(textLen+1) PWSTR wideText = reinterpret_cast<PWSTR>(GlobalLock(hmWideText));
        RtlMoveMemory(wideText, text, (textLen + 1) * sizeof(wideText[0]));
        GlobalUnlock(hmWideText);
        if (SetClipboardData(CF_UNICODETEXT, hmWideText) != nullptr)
        {
            hmWideText = nullptr; // now owned by system
        }

        #ifdef ATTRIBUTE_LIST_COPY_ANSI
        __ecount(textLen+1) PSTR ansiText = reinterpret_cast<PSTR>(GlobalLock(hmAnsiText));
        WideCharToMultiByte(CP_ACP|WC_NO_BEST_FIT_CHARS, 0, text,textLen + 1, ansiText, 256, nullptr,nullptr);
        GlobalUnlock(hmAnsiText);
        if (SetClipboardData(CF_TEXT, hmAnsiText) != nullptr)
            hmAnsiText = nullptr; // now owned by system
        #endif
    }

    GlobalFree(hmWideText);
    #ifdef ATTRIBUTE_LIST_COPY_ANSI
    GlobalFree(hmAnsiText);
    #endif

    CloseClipboard();

    return 0;
}


int AttributeList::CopyAllText()
{
    if (!OpenClipboard(hwnd_))
        return -1;

    EmptyClipboard();

    HGLOBAL hmWideText = GlobalAlloc(GMEM_MOVEABLE|GMEM_DDESHARE, 7);
    #ifdef ATTRIBUTE_LIST_COPY_ANSI
    HGLOBAL hmAnsiText = nullptr;
    #endif

    if (hmWideText != nullptr)
    {
        PWSTR wideText = reinterpret_cast<PWSTR>(GlobalLock(hmWideText));

        size_t textLength = 0;

        // build Unicode version of text chunk by appending the text of all items.
        for (unsigned int itemIndex = topIndex_; itemIndex < totalItems_; itemIndex++)
        {
            const Item& item = items_[itemIndex];

            if (item.IsVisible())   // only add if visible and
            {
                AppendString(&wideText, item.label, &textLength);
                AppendString(&wideText, GetItemText(itemIndex), &textLength);
                AppendString(&wideText, L"\r\n", &textLength);
            }
        }

        #ifdef ATTRIBUTE_LIST_COPY_ANSI
        // build ANSI version of text chunk
        hmAnsiText = GlobalAlloc(GMEM_MOVEABLE|GMEM_DDESHARE, textLength + 1);
        if (hmAnsiText != nullptr)
        {
            PSTR ansiText = reinterpret_cast<PSTR>(GlobalLock(hmAnsiText));
            WideCharToMultiByte(CP_ACP|WC_NO_BEST_FIT_CHARS, 0, wideText,int(textLength), ansiText, int(textLength), nullptr,nullptr);
            GlobalUnlock(hmAnsiText);
            if (SetClipboardData(CF_TEXT, hmAnsiText) != nullptr)
            {
                hmAnsiText = NULL; // now owned by system
            }
        }
        #endif

        // set the Unicode text
        GlobalUnlock(hmWideText);
        if (SetClipboardData(CF_UNICODETEXT, hmWideText) != nullptr)
        {
            hmWideText = nullptr; // now owned by system
        }
    }

    GlobalFree(hmWideText);
    #ifdef ATTRIBUTE_LIST_COPY_ANSI
    GlobalFree(hmAnsiText);
    #endif

    CloseClipboard();

    return 0;
}


int AttributeList::PasteText()
{
    UINT32 flags;
    if (!GetSelectedItemFlags(OUT &flags))
        return -1; // just in case no choices

    Item& item = items_[selectedIndex_];
    const size_t maxItemLen = item.value;
    PWSTR itemText = item.text;

    // ensure IS edit, not disabled, hidden, or locked
    // ensure edit allows at least one character in buffer
    // ensure clipboard could be opened
    if (maxItemLen <= 0
    ||  itemText == nullptr
    ||  !Item::IsEnabledType(flags, Item::FlagEditType)
    ||  !OpenClipboard(hwnd_))
    {
        return -1;
    }

    const int format = GetPriorityClipboardFormat(&g_clipboardFormats[0],2);

    PWSTR clipboardText;
    HGLOBAL hmWideText = GetClipboardData(format); //memory handle to Unicode text

    if ((hmWideText != nullptr)
    && (clipboardText = reinterpret_cast<PWSTR>(GlobalLock(hmWideText))) != nullptr)
    {
        size_t memorySize = GlobalSize(clipboardText); // max size of memory object
        size_t clipboardTextLen = (format == CF_UNICODETEXT) ? memorySize / sizeof(clipboardText[0]) : memorySize;
        if (clipboardTextLen > maxItemLen)
            clipboardTextLen = maxItemLen; // length INCLUDES null

        if (format == CF_UNICODETEXT)
        {
            RtlMoveMemory(itemText, clipboardText, clipboardTextLen * sizeof(clipboardText[0]));
        }
        else
        {
            MultiByteToWideChar(
                CP_ACP, MB_PRECOMPOSED,
                reinterpret_cast<PSTR>(clipboardText), int(clipboardTextLen),
                itemText, int(clipboardTextLen)
                );
        }
        itemText[clipboardTextLen - 1] = '\0'; // append null

        GlobalUnlock(hmWideText);
        ResizeOverlay();
        SetCaretIndex(UINT_MAX);
    };
    CloseClipboard();

    return 0;
}


int AttributeList::ClearText()
{
    UINT32 flags;
    if (!GetSelectedItemFlags(OUT &flags))
        return -1; // just in case no choices

    Item& item = items_[selectedIndex_];
    const size_t maxItemLen = item.value;

    if (!Item::IsEnabledType(flags, Item::FlagEditType)
    || (maxItemLen <= 0))
    {
        return -1;
    }

    PWSTR text = items_[selectedIndex_].text;
    if (text == nullptr)
    {
        return -1;
    }

    text[0] = '\0'; // truncate string to zero length
    ResizeOverlay();
    SetCaretIndex(0);

    return 0;
}


void AttributeList::SendHelpToParent(const HELPINFO* baseHelpInfo, unsigned int itemIndex, POINT& pt)
{
    #if 0
    HELPINFO helpInfo(*baseHelpInfo);

    // !assumes the helpinfo is valid and partially filled in
    // expects itemIndex is set valid or is -1
    RECT rect;
    if (GetItemTextRect(itemIndex, pt.y, &rect)
    && (items_[itemIndex].id > 0)) // must have an ID
    {  
        // ensure tooltip is not way outside control
        if (!IsWindowVisible((HWND)GetWindowLong(hwnd, GWL_OVERLAY))
        || itemIndex != selectedIndex_)
        {
            RECT clientRect;
            GetClientRect(hwnd,&clientRect);
            if (rect.right > clientRect.right)
                rect.right = clientRect.right;
        }
        helpInfo.iContextType = HELPINFO_WINDOW;
        helpInfo.hItemHandle = hwnd;
        helpInfo.iCtrlId = flags & AlfIdMask;
        helpInfo.iContextType = HELPINFO_WINDOW+4;
        helpInfo.MousePos.y = rect.top;
        helpInfo.MousePos.x = rect.right+2;
    }
    SendMessage(GetParent(hwnd), WM_HELP, wParam, (LPARAM)&helpInfo);
    #endif
}


AttributeList::Overlay::Overlay()
{
    howner_ = nullptr;
    text_   = nullptr;
}


// This is the little text window shown whenever an editable item is
// selected in the attribute list. This code only does the very basic
// tasks necessary, such as repainting itself. Most of it is controlled
// by its parent, including key control, character editing, what text
// should be shown, and where the window is displayed.
//
LRESULT CALLBACK AttributeList::Overlay::WindowProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    AttributeList::Overlay* overlay = (AttributeList::Overlay*)GetWindowLongPtr(hwnd, GWLP_USERDATA);

    switch (message)
    {

    case WM_NCCREATE:
    {
        // Create the window.
        CREATESTRUCT* pcs = reinterpret_cast<CREATESTRUCT*>(lParam);
        AttributeList::Overlay* classInstance = reinterpret_cast<AttributeList::Overlay*>(pcs->lpCreateParams);

        if (classInstance == nullptr)
            classInstance = new(std::nothrow) AttributeList::Overlay();

        if (classInstance == nullptr)
            return -1; // failed creation

        SetWindowLongPtr(hwnd, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(classInstance));

        return DefWindowProc(hwnd, message, wParam, lParam);
    }

    case WM_CREATE:
        SetClassLongPtr(hwnd, GCLP_HCURSOR, (ULONG_PTR)g_cursorIbeam);
        return 0;

	case WM_DESTROY:
    {
        LRESULT result = DefWindowProc(hwnd, message, wParam, lParam);
        delete overlay;
        return result;
    }

    case WM_SETCURSOR:
    case WM_ERASEBKGND:
        return TRUE;

    case WM_PAINT:
    {
        const WCHAR* text = overlay->text_;
        if (text == nullptr)
            text = L"";

        PAINTSTRUCT ps;
        RECT rect;

        BeginPaint(hwnd, &ps);
        SelectObject(ps.hdc, g_guiFont);
        SetBkColor(ps.hdc, GetSysColor(COLOR_HIGHLIGHT)); //COLOR_BTNFACE
        SetTextColor(ps.hdc, GetSysColor(COLOR_HIGHLIGHTTEXT));
        GetClientRect(hwnd, &rect);

        // todo:
        int caretY = 0;//(metrics.itemHeight - metrics.textHeight)>>1;
        ExtTextOutW(ps.hdc, 0, caretY, ETO_OPAQUE, &rect, text,wcslen(text), nullptr);
        EndPaint(hwnd, &ps);
        return 0;
    }

    case WM_LBUTTONDOWN: // for caret positioning
    case WM_RBUTTONDOWN: // for context menu
    case WM_MBUTTONDOWN: // just in case for future compat
    case WM_MOUSEMOVE:
    {
        // relay all mouse messages to owner
        HWND owner = overlay->howner_;
        if (owner == nullptr)
            return -1; // error

        lParam = GetMessagePos();
        POINT pt = {GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam)};
        ScreenToClient(owner, &pt);
        lParam = MAKELONG(pt.x, pt.y);

        return AttributeList::WindowProc(owner, message, wParam, lParam);
    }
    case WM_NCLBUTTONDOWN:
    case WM_NCMBUTTONDOWN:
    case WM_NCRBUTTONDOWN:
    case WM_ACTIVATE: // ignore any possible activation
    case WM_WINDOWPOSCHANGING:
    case WM_WINDOWPOSCHANGED:
        return 0;

    case WM_MOUSEACTIVATE:
        return MA_NOACTIVATE;

    case WM_HELP: // relay help msg to parent
    {
        HWND owner = overlay->howner_;
        if (owner == nullptr)
            return FALSE; // error

        return AttributeList::WindowProc(owner, message, wParam, lParam);
    }

    default:
        return DefWindowProc(hwnd, message, wParam, lParam);
    }
}


// purpose:
//		Seeks up/down from an item index by the given distance (+/-),
//		ignoring all hidden items in the list.
//
//		item - index of item in list to start from
//		distance - amount to go up/down
//		flagmask - items to skip and behavior flags
//      failIfShort - fail if could not be reached
//
//		Default flagmask is (Item::FlagHidden | Item::FlagSeparator | Item::FlagNoSelect)
//
// returns:
//		new item number
//
int AttributeList::Seek(unsigned int itemIndex, int distance, UINT32 skipFlags, bool failIfShort)
{
    unsigned int totalItems = totalItems_;
    if (itemIndex > totalItems)
        itemIndex = totalItems;

    unsigned int seekedIndex = itemIndex;
    int traveled = distance;

    if (traveled > 0 && itemIndex < totalItems)
        while (++itemIndex < totalItems)
        {
            const UINT32 flags = items_[itemIndex].flags;
            if (!(flags & Item::FlagHidden))
            {
                traveled--;
                if (!(flags & skipFlags))
                {
                    seekedIndex = itemIndex;
                    if (traveled <= 0)
                        break;
                }
            }
        }
    else if (traveled < 0 && itemIndex > 0)
        while (itemIndex > 0)
        {
            --itemIndex;
            const UINT32 flags = items_[itemIndex].flags;
            if (!(flags & Item::FlagHidden))
            {
                traveled++;
                if (!(flags & skipFlags))
                {
                    seekedIndex = itemIndex;
                    if (traveled >= 0)
                        break;
                }
            }
        }

    // if distance requested could not be reached, return -1
    traveled = distance - traveled;
    if ((traveled != distance) && failIfShort) 
        seekedIndex = UINT_MAX; //-1
    else
        if (seekedIndex >= totalItems_)
            seekedIndex = failIfShort ? UINT_MAX : 0; // clamp to zero or failure

    return seekedIndex;
}


// purpose:
//		Determines an item's screen row, relative to top of list,
//		ignoring all hidden items. Can return either positive or
//		negative row offsets from top. Can also be used to tell
//		the row difference between two items.
//
//		itemIndex - item to get row position of (must be 0 to total-1)
//		topIndex  - top item that all rows are relative to
//			  pass topIndex_ if for relative to top of list
//
// returns:
//		zero based position (in rows, not pixels, can be +/-)
//
int AttributeList::GetItemRow(unsigned int itemIndex, unsigned int topIndex)
{
    unsigned int total = totalItems_;
    if (itemIndex > total)
        itemIndex = total;
    if (topIndex > total)
        topIndex = total;

    unsigned int traveled = 0;

    if (itemIndex >= topIndex)
        while (itemIndex > topIndex) {
            --itemIndex;
            if (items_[itemIndex].IsVisible())
                ++traveled;
        }
    else
        while (itemIndex < topIndex) {
            if (items_[itemIndex].IsVisible())
                --traveled;
            ++itemIndex;
        }

    return traveled;
}


// purpose:
//		sets scroll bar size and handle position
//		scrolls items into view if empty space on bottom side
//
void AttributeList::Resize()
{
    LONG style = GetWindowLong(hwnd_, GWL_STYLE); // get initial style

    ListMetrics metrics;
    GetListMetrics(&metrics);

    // scroll items if necessary
    unsigned int itemIndex = Seek(totalItems_, -metrics.itemRows, Item::FlagHidden);
    if (itemIndex < topIndex_)
    {
        topIndex_ = itemIndex;
        //Scroll(GetItemRow(topIndex_, itemIndex), metrics); // dif between old and new top
        InvalidateRect(hwnd_, nullptr, false);
    }
    else
    {
        ResizeOverlay();
    }

    // set scroll bar visibility
    // if all item rows (excluding hidden) are taller than
    // than window client area, show scroll bar.
    SetScrollBars(metrics);

    // if scroll bar visibility changed, either from visible to hidden vice versa,
    // then redraw all titles, since their edges depend on the width of the client
    if ((style ^ GetWindowLong(hwnd_, GWL_STYLE)) & WS_VSCROLL)
    {
        FlagTitlesNeedRedraw();
        PostRedraw();
    }
}


// purpose:
//		sizes and positions overlay window according to selected item
//		hides if offscreen, lost focus, or item is not displayable
//
bool AttributeList::ResizeOverlay()
{
    // Only show overlay if current selected item is valid, if it has text,
    // and if the attribute list has focus (otherwise it would show when created)
    UINT32 flags;
    if (!GetSelectedItemFlags(OUT &flags) || items_[selectedIndex_].text == nullptr || (GetFocus() != hwnd_))
    {
        //DestroyCaret();
        ShowWindow(hoverlay_, SW_HIDE);
        return false;
    }

    // Figure out where the item is on the screen
    ListMetrics metrics;
    GetListMetrics(&metrics);

    RECT itemRect;
    itemRect.top = GetItemRow(selectedIndex_, topIndex_) * metrics.itemHeight;

    // hide overlay when item scrolled off screen
    if (itemRect.top < 0 || itemRect.top + metrics.itemHeight > metrics.clientRect.bottom)
    {
        ShowWindow(hoverlay_, SW_HIDE);
        return false;
    }

    // Figure out the subrect within the item (label vs text position)
    GetItemTextRect(selectedIndex_, itemRect.top, metrics, &itemRect);

    Item& item = items_[selectedIndex_];

    // don't bother showing the overlay if it's completely within the client region
    // (and not an edit)
    if (itemRect.right <= metrics.clientRect.right
    &&  !item.IsEnabledType(Item::FlagEditType))
    {
        ShowWindow(hoverlay_, SW_HIDE);
        return false;
    }

    // position of overlay is based on item's text rect
    // convert to left/top & width/height instead of rect.
    POINT pt = {itemRect.left, itemRect.top};
    SIZE sz  = {itemRect.right - itemRect.left, itemRect.bottom - itemRect.top};

    if (pt.x > metrics.clientRect.right)
        pt.x = metrics.clientRect.right; // so that it does not appear floating off to the right side

    ClientToScreen(hwnd_, &pt);
    //ScreenToClient(GetParent(hwnd_), &pt);

    // keep overlay on screen and in work area
    #if 0 // figure a better way, since this puts it on the wrong monitor for dual monitor setup
    RECT workRect;
    SystemParametersInfo(SPI_GETWORKAREA,0, &workRect, FALSE);
    if (pt.x > workRect.right - sz.cx)	pt.x = workRect.right - sz.cx;
    if (pt.x < workRect.left)           pt.x = workRect.left;
    if (pt.y > workRect.bottom - sz.cy) pt.y = workRect.bottom - sz.cy;
    if (pt.y < workRect.top)            pt.y = workRect.top;
    #endif

    // adjust pos/size if overlay has an nonclient edge
    RECT adjustedRect = {0,0,0,0};
    AdjustWindowRectEx(&adjustedRect, GetWindowLong(hoverlay_,GWL_STYLE), FALSE, GetWindowLong(hoverlay_,GWL_EXSTYLE));
    pt.x  += adjustedRect.left;
    pt.y  += adjustedRect.top;
    sz.cx += adjustedRect.right  - adjustedRect.left;
    sz.cy += adjustedRect.bottom - adjustedRect.top;


    // position and size overlay, show if hidden
    if (hoverlay_ != nullptr)
    {
        sz.cx += 2; // compensate for caret

        AttributeList::Overlay& overlay = *AttributeList::Overlay::GetClass(hoverlay_);
        SetWindowPos(hoverlay_,nullptr, pt.x,pt.y, sz.cx,sz.cy, SWP_NOACTIVATE|SWP_NOCOPYBITS|SWP_NOZORDER);
        SetWindowPos(hoverlay_, nullptr, 0,0,0,0, SWP_NOMOVE|SWP_NOSIZE|SWP_NOZORDER|SWP_NOACTIVATE|SWP_SHOWWINDOW);
        SetWindowLong(hoverlay_, GWL_ID, item.id);

        __nullterminated const WCHAR* text = GetItemText(selectedIndex_); // for check/group buttons
        SetWindowText(hoverlay_, text);
        overlay.text_ = text;

        PostRedrawOverlay(); // must be called explicitly since pasting text of exact same window size would not update the window

        // only show caret if IS edit and not locked
        if (item.IsEnabledType(Item::FlagEditType) && item.value > 0)
        {
            CreateCaret(hoverlay_, nullptr, 2, metrics.itemHeight);
            ShowCaret(hoverlay_); // GetSystemMetrics(SM_CXBORDER) is too thin a caret
        }
        else
        {
            DestroyCaret();
        }
    }
    return true;
}


// purpose:
//		selects the given item and ensures selection is visible
//
int AttributeList::Select(unsigned int newIndex)
{
    return SelectGiven(newIndex, SelectionModeScroll|SelectionModeResetCaret); // ensure visible and set caret x
}


// purpose:
//		selects the given item.
//
// returns:
//		LB_OKAY or LB_ERR
//		[selected]
//		[flags]
//
// options:
//      SelectionModeScroll
//		SelectionModeResetCaret
//
int AttributeList::SelectGiven(unsigned int newIndex, UINT32 options)
{
    // check selection validity
    if (newIndex >= totalItems_)
        return LB_ERR;

    Item& item = items_[newIndex];
    if (!item.IsEnabled())
        return LB_ERR;

    if (newIndex != selectedIndex_)
    {
        // mark old and new items as needing redraw
        if (selectedIndex_ < totalItems_)
            items_[selectedIndex_].SetRedraw();

        item.SetRedraw();
        selectedIndex_ = newIndex;
    }

    // ensure selection is visible if option set
    // scroll into view if not
    if (options & SelectionModeScroll)
    {
        unsigned int oldTop = topIndex_, newTop = oldTop;
        ListMetrics metrics;
        GetListMetrics(&metrics);

        if (selectedIndex_ < oldTop)
        {
            newTop = selectedIndex_;
        }
        else
        {
            // todo: check whether first item being disabled
            // causes issue when pressing Down on small list.
            unsigned int itemIndex = Seek(selectedIndex_, 1 - metrics.itemRows, Item::FlagHidden);
            if (itemIndex > oldTop)
                newTop = itemIndex;
        }
        if (newTop != oldTop)
        {
            topIndex_ = newTop;
            Scroll(-GetItemRow(newTop, oldTop), metrics);
        }
    }

    ResizeOverlay();
    if (item.IsEnabledType(Item::FlagEditType) && (options & SelectionModeResetCaret))
        SetCaretIndex(UINT_MAX);

    PostRedraw();
    return LB_OKAY;
}


// purpose:
//		Sets caret index for text editing.
//		Puts caret at end of text if -1 passed.
// !assumes:
//		selected is valid (GetSelectedFlags has been called)
//
void AttributeList::SetCaretIndex(unsigned int newIndex)
{
    Item& item = items_[selectedIndex_];
    __nullterminated const WCHAR* text = item.text;
    if (text == nullptr)
        return; // prevent access violation in case item has only a label

    unsigned int len = wcslen(text);
    if (len > Item::MaxValue)
        len = Item::MaxValue; // limit caret index
    if (newIndex >= len)
        newIndex  = len; // force caret pos valid
    if (newIndex == g_caretIndex)
        return; // caret pos same, so do nothing more

    g_caretIndex = newIndex;

    if (newIndex > 0)
    {
        int caretX[Item::MaxValue + 2];
        caretX[newIndex] = 0;
        caretX[0]        = 0;

        HDC hdc = GetDC(hwnd_);
        SelectObject(hdc, g_guiFont);
        SIZE sz = {0,0};

        #if 0
        unsigned short reorder[Item::MaxValue];
        GCP_RESULTSW gcp = {
            sizeof(GCP_RESULTS),
            &reorder[0], nullptr, nullptr, nullptr,
            nullptr,
            nullptr,0,
            0
        };

        // Would use the gcp function below so that caret positioning would be
        // correct on Hebrew and other Arabic backwards reading languages,
        // but I'm having trouble figuring out to correctly place the caret
        // on the left or right side, depending on directionality.
        GetCharacterPlacementW(hdc, text, len,0, &gcp, GCP_REORDER| GCP_GLYPHSHAPE);
        sz.cx = CaretPos[CaretX];
        #endif

        GetTextExtentExPointW(hdc, text,len+1, 0,nullptr, &caretX[1], &sz);
        SetCaretPos(caretX[newIndex], 0);

        ReleaseDC(hwnd_, hdc);
    }
    else
    {
        SetCaretPos(0,0);
    }
    
    item.SetRedraw();
    PostRedraw();
    PostRedrawOverlay();
}


// purpose:
//		Deletes a single character.
// !assumes:
//		selected is the currently selected choice
//		flags is the flags of the selected choice
//
void AttributeList::DeleteChar()
{
    Item& item = items_[selectedIndex_];
    __nullterminated PWSTR text = item.text;
    size_t len = wcslen(text);
    if (g_caretIndex >= len)
    {
        g_caretIndex = static_cast<unsigned int>(len);
        return;
    }
    if (g_caretIndex >= item.value)
        return;

    text += g_caretIndex;
    RtlMoveMemory(text, text+1, (len-g_caretIndex)*sizeof(wchar_t));

    // item.SetRedraw();
    // PostRedraw();
    ResizeOverlay();
}


// !assumes:
//          selected is the currently selected choice
//          flags is the flags of the selected choice
//
// Inserts a character into the string at the current caret index.
// (does not support chars beyond BMP)
//
void AttributeList::InsertChar(unsigned int newChar)
{
    Item& item = items_[selectedIndex_];
    __nullterminated PWSTR text = item.text;
    size_t len = wcslen(text);

    if (g_caretIndex > len)
    {
        g_caretIndex = static_cast<unsigned int>(len);
        return;
    }
    if (len >= item.value)
        return;

    text += g_caretIndex;
    RtlMoveMemory(text+1, text, (len-g_caretIndex+1)*sizeof(wchar_t));
    text[0] = wchar_t(newChar);
    SetCaretIndex(g_caretIndex+1);

    //item.SetRedraw();
    //PostRedraw();
    ResizeOverlay();
}

void AttributeList::PostRedraw()
{
    PostMessage(hwnd_, WM_PAINT, 0,0);
}

void AttributeList::PostRedrawOverlay()
{
    InvalidateRect(hoverlay_, nullptr, FALSE);
}


// Gets the item flags of the selected item. returning true if the selected
// item is valid (false if total items = 0).
//
bool AttributeList::GetSelectedItemFlags(__out UINT32* flags)
{
    if (selectedIndex_ >= totalItems_)
    {
        *flags = Item::FlagReadOnly | Item::FlagNoSelect | Item::FlagHidden;		
        return false; //safety just in case
    }
    *flags = items_[selectedIndex_].flags;
    return true;
}


// purpose:
//		Sets the coordinates for the hover rectangle which the cursor
//		moves over.
//
// returns:
//		the item hovered over (UINT_MAX if none)
//		[flags] of hovered item (if over valid item)
//		[HoverRect] sets the rectangular coordinates
//
unsigned int AttributeList::UpdateHoverItem(int y)
{
    if (hwnd_ != g_hoverHwnd || y < g_hoverRect.top || y >= g_hoverRect.bottom)
    {
        g_hoverHwnd = hwnd_;
        GetItemTextRect(y, &hoveredIndex_, &g_hoverRect);
    }
    return hoveredIndex_;
}


// purpose:
//		Calculates the rectangle surrounding an item
//		either by item number or y coordinate.
// returns:
//		the item hovered over (UINT_MAX if none)
//		if the item is beyond the total, it returns  the bottom of the list
//		and sets the rectangular coordinates in rect
//
bool AttributeList::GetItemTextRect(unsigned int itemIndex, __out RECT* rectOut)
{
    // get list item height, using current font
    ListMetrics metrics;
    GetListMetrics(&metrics);

    return GetItemTextRect(
        itemIndex,
        GetItemRow(itemIndex, topIndex_) * metrics.itemHeight,
        metrics,
        rectOut
        );
}


bool AttributeList::GetItemTextRect(int y, __out unsigned int* itemIndexOut, __out RECT* rectOut)
{
    // get list item height, using current font
    ListMetrics metrics;
    GetListMetrics(&metrics);

    // determine item and top from mouse coordinate
    unsigned int itemIndex = Seek(topIndex_, y / metrics.itemHeight, 0, true);
    *itemIndexOut = itemIndex;

    return GetItemTextRect(
        itemIndex,
        y - (y % metrics.itemHeight),
        metrics,
        rectOut
        );
}


bool AttributeList::GetItemTextRect(unsigned int itemIndex, int topY, const ListMetrics& metrics, __out RECT* rectOut)
{
    if (totalItems_ <= 0)
    {
        *rectOut = metrics.clientRect;
        return false;
    }

    RECT rect;
    rect.top    = topY;
    rect.bottom = rect.top + metrics.itemHeight;
    rect.left   = 2;
    rect.right  = rect.left;

    if (itemIndex < totalItems_) // over valid item
    {
        const Item& item = items_[itemIndex];

        rect.left += item.indent * metrics.itemIndent;

        if (item.icon > 0)
        {
            rect.left += metrics.iconWidth + 2;
        }
        else if (GetItemTypePixels(item.flags, item.value) != nullptr)
        {
            rect.left += PixelImageWidth + 2;
        }

        HDC hdc = GetDC(hwnd_);
        SIZE sz = {0}; // in case there is no text
        __nullterminated const WCHAR* text = item.label;
        if (text != nullptr)
        {
            int len = wcslen(text);
            GetTextExtentPoint32W(hdc, text, len, &sz);
            rect.left += sz.cx;
            rect.right = rect.left;
        }
        text = item.text;
        if (text != nullptr)
        {
            text = GetItemText(itemIndex); // for check/group buttons
            int len = wcslen(text);
            GetTextExtentPoint32W(hdc, text, len, &sz);
            rect.right += sz.cx;
        }
        ReleaseDC(hwnd_, hdc);
    }
    else // beyond end of list
    {
        rect.right = 0;
        rect.bottom = 16384; //set to really high number
        *rectOut = rect;
        return false;
    }
    *rectOut = rect;
    return true;
}


// purpose
//		Sends command message to parent, for when button clicked.
//		A message will only be sent if the item has an ID.
//
void AttributeList::SendClickCommand(unsigned int id)
{
    if (id > 0)
    {
        SendMessage(
            GetParent(hwnd_),
            WM_COMMAND,
            id | NotifyClicked,
            (LPARAM)hwnd_
            );
    }
}


// purpose
//		Sends notification message to parent, for when toggle/menu choice changes.
//		A message will only be sent if the item has an ID.
//
void AttributeList::SendNotification(unsigned int notification, unsigned int id, unsigned int value, bool valueChanged)
{
    if (id > 0)
    {
        NotifyMessage nmh;
        nmh.code = notification;
        nmh.idFrom = GetDlgCtrlID(hwnd_);
        nmh.hwndFrom = hwnd_;
        nmh.itemId = id;
        nmh.value = value;
        nmh.valueChanged = valueChanged;
        SendMessage(
            GetParent(hwnd_),
            WM_NOTIFY,
            nmh.idFrom,
            (LPARAM)&nmh
            );
    }
}


// purpose:
//		Redraws all title 
//		either by item number or y coordinate.
//
void AttributeList::FlagTitlesNeedRedraw()
{
    for (unsigned int itemIndex = topIndex_; itemIndex < totalItems_; itemIndex++)
    {
        Item& item = items_[itemIndex];
        if (item.GetType() == Item::FlagTitleType)
            item.SetRedraw();
    }
}

// purpose:
//		get list item's height
//		font height
//		and image list icon's size
//
// returns:
//		itemHeight - pixel height of single item row
//		textHeight - text cell height
//		iconHeight - image list icon height
//		iconWidth - icon width
//		itemRows - number of visible whole rows
//
void AttributeList::GetListMetrics(ListMetrics* metrics)
{
    assert(hwnd_ != nullptr);
    assert(g_guiFont != nullptr);

    TEXTMETRIC tm;
    RECT rect;

    GetClientRect(hwnd_, &rect);
    HDC hdc = GetDC(hwnd_);
    SelectObject(hdc, g_guiFont);
    GetTextMetrics(hdc, &tm);
    ReleaseDC(hwnd_, hdc);

    metrics->textHeight = tm.tmHeight;
    if (metrics->textHeight < 1)
        metrics->textHeight = 1; // sanity check to prevent possible div by zero

    metrics->iconWidth   = 1;
    metrics->iconHeight  = 1;
    if (himl_ != nullptr)
        ImageList_GetIconSize(himl_, &metrics->iconWidth, &metrics->iconHeight);

    // set item height to the larger of icon or text
    metrics->itemIndent = metrics->textHeight;
    metrics->itemHeight = (metrics->iconHeight > metrics->textHeight) ? metrics->iconHeight : metrics->textHeight;
    metrics->itemRows   = rect.bottom / metrics->itemHeight;
    metrics->clientRect = rect;
};


// purpose:
//		scrolls list by number of rows, and sets new top of list.
//
void AttributeList::ScrollBy(int rowDif, UINT32 selectionMode)
{
    unsigned int oldTop = topIndex_, newTop;
    int topDif;
    
    ListMetrics metrics;
    GetListMetrics(&metrics);

    if (selectionMode & SelectionModeAbsolute)
    {
        newTop = Seek(0, rowDif, Item::FlagHidden);
    }
    else
    {
        if (selectionMode & SelectionModePage)
            rowDif *= metrics.itemRows;

        newTop = Seek(oldTop, rowDif, Item::FlagHidden);
    }
    if (newTop > oldTop)
    {
        unsigned int itemIndex = Seek(totalItems_, -metrics.itemRows, Item::FlagHidden);
        if (newTop > itemIndex)
            newTop = itemIndex;
    }
    if (newTop == oldTop)
        return; // no change

    topIndex_ = newTop;

    topDif = GetItemRow(newTop, oldTop);

    if (selectionMode & SelectionModePage)
    {
        // todo:
        //Seek(selectedIndex_, TopDif, Item::FlagHidden);
        //Seek(item, (TopDif >= 0) ? -1:1, Item::FlagHidden|Item::FlagNoSelect|AlfSeparator);
        //LanAtrs[*(LanListPtr+LanListSelect)].flags |= LlfRedraw;
        //LanListSelect+=newTop-LanListTop;
        //LanAtrs[*(LanListPtr+LanListSelect)].flags |= LlfRedraw;
    }
    Scroll(-topDif, metrics);
}


// purpose:
//		scrolls client area pixels
// !assumes:
//		itemHeight is set by a call to GetListMetrics
//		textHeight  ...
//		iconHeight  ...
//		iconWidth   ...
//
void AttributeList::Scroll(int rowDif, const ListMetrics& metrics)
{
    g_hoverRect.bottom = 0; // force mouse recalc upon next mouse move
    ScrollWindow(hwnd_, 0, rowDif * metrics.itemHeight, nullptr,nullptr);
    SetScrollBars(metrics);
    ResizeOverlay();
}


// purpose:
//		sets scroll bar range and position
// !assumes:
//		itemHeight is set by a call to GetListMetrics
//		textHeight  ...
//		iconHeight  ...
//		iconWidth   ...
//
void AttributeList::SetScrollBars(const ListMetrics& metrics)
{
    SCROLLINFO scrollInfo = {
        sizeof(SCROLLINFO), SIF_ALL,
        0, 100,
        10, 45,
        0
    };

    scrollInfo.nMax     = GetItemRow(totalItems_, 0) - 1;
    scrollInfo.nPage    = metrics.itemRows;
    scrollInfo.nPos     = GetItemRow(topIndex_,0);
    SetScrollInfo(hwnd_, SB_VERT, &scrollInfo, TRUE);
}


// purpose:
//		selects the correct choice text of text for a toggle/menu/button.
//		it returns the text ptr alone if other type.
PWSTR AttributeList::GetItemText(unsigned int itemIndex)
{
    if (itemIndex >= totalItems_)
    {
        return L"";
    }

    Item& item = items_[itemIndex];
    WCHAR* text = item.text;
    if (text == nullptr || (item.flags & Item::FlagNoText))
    {
        return L"";
    }

    if (item.value == 0 || text[0] == '\0')
    {
        return text;
    }

    switch (item.GetType())
    {
    case Item::FlagButtonType:
    case Item::FlagOptionType:
    case Item::FlagToggleType:
        {
            // Find the substring in the double-NULL terminated string.
            unsigned int value = item.value;

            do {
                text += wcslen(text) + 1; // skip ahead by size of string + NULL
            } while ((signed)(--value) > 0);
        }
    }
    return text;
}


// purpose:
//		appends a Unicode string to a moveable memory object.
//		resizes it if necessary.
//		calculuates length of existing string if size NULL or -1 passed
//
// !assumes:
//		the passed memory object must have been alloced as fixed
//		or moveable object that has been locked. Either way, the locked
//		address needs to be passed, not the moveable global handle.
//
//		GlobalAlloc(GMEM_FIXED, 2048) // for internal use
//		GlobalLock(GlobalAlloc(GMEM_MOVEABLE|GMEM_DDESHARE, 2048)) // for clipboard
//
// returns:
//		nothing
//
void AttributeList::AppendString(
    __deref_inout_ecount(*previousMemoryLen) WCHAR** memoryBlock,
    __in_z const WCHAR* const text,
    __inout size_t* previousMemoryLen
    )
{
    if (text == nullptr)
    {
        return;
    }

    size_t currentLen  = *previousMemoryLen;
    size_t textLen     = wcslen(text); // new text size
    size_t memorySize  = GlobalSize(*memoryBlock); // max size of memory object
    size_t neededSize  = (currentLen + textLen + 1) * sizeof(text[0]);
    const size_t byteGranularity = 512;

    if (neededSize + byteGranularity < memorySize)
    {
        return; // overflow
    }

    if (neededSize > memorySize)
    {
        // reallocate if necessary
        HGLOBAL hmTarget = GlobalHandle(*memoryBlock);
        if (hmTarget == nullptr)
        {
            return;
        }

        HGLOBAL newTarget = GlobalReAlloc(hmTarget, neededSize + byteGranularity, GMEM_MOVEABLE);
        if (newTarget == nullptr)
        {
            return;
        }

        GlobalUnlock(hmTarget);
        *memoryBlock = reinterpret_cast<PWSTR>(GlobalLock(hmTarget));
    }
    __bcount(neededSize) WCHAR* memoryText = reinterpret_cast<WCHAR*>(*memoryBlock);

    RtlMoveMemory(memoryText + currentLen, text, textLen * sizeof(text[0]));

    currentLen += textLen;
    *previousMemoryLen = currentLen;
    #pragma prefast(suppress:__WARNING_BUFFER_OVERFLOW, "No buffer overflow occurs here because the memory buffer is resized above via ReAlloc.")
    memoryText[currentLen] = '\0';
}


// purpose:
//		displays the context menu for an item and picks the appropriate menu
//		choices based on the selected item type and clipboard contents.
// input:
//		item - selected item 0 to total-1 or -1 for none
//		x - left of menu
//		y - top of menu
// returns:
//		nothing, WM_COMMAND is sent to window procedure
//
void AttributeList::ShowContextMenu(unsigned int itemIndex, int x,int y)
{
    HMENU menu = CreatePopupMenu();

    // dynamically create menu based on whatever is selected, or just the bare choices if nothing selected
    UINT32 flags = Item::FlagHidden;
    unsigned int id = 0;

    if (itemIndex < totalItems_)
    {
        const Item& item = items_[itemIndex];
        flags = item.flags;
        id    = item.id;
    }

    if (!(flags & Item::FlagHidden))
    {
        UINT32 itemType = (flags & Item::FlagTypeMask);

        UINT menuFlags = MF_STRING | ((flags & Item::FlagReadOnly) ? MF_DISABLED : 0);

        switch (itemType)
        {
        case Item::FlagToggleType:
            AppendMenu(menu, menuFlags, IdToggle, L"&Toggle");
            SetMenuDefaultItem(menu, 0, TRUE);
            break;

        case Item::FlagButtonType:
            AppendMenu(menu, menuFlags, IdCommand, L"&Do command");
            SetMenuDefaultItem(menu, 0, TRUE);
            break;

        //case Item::FlagFileType:
        //     AppendMenu(menu, menuFlags, MidBrowse, L"&Browse");
        //     SetMenuDefaultItem(menu, 0, TRUE);
        //     break;
        }

        AppendMenu(menu, MF_STRING, IdCopy, L"&Copy");

        if (itemType == Item::FlagEditType) // ensure IS edit and is NOT locked
        {
            if (GetPriorityClipboardFormat(&g_clipboardFormats[0], 2) > 0)
                AppendMenu(menu, menuFlags, IdPaste, L"&Paste");
            AppendMenu(menu, menuFlags, IdClear, L"C&lear");
        }
        AppendMenu(menu, MF_SEPARATOR, 0 ,0);
    }
    AppendMenu(menu, MF_STRING, IdCopyAll, L"Copy &all");
    AppendMenu(menu, MF_STRING, IdHelp, L"&Help");

    SendNotification(NotifyContext, id, 0, false);

    POINT pt = {x,y};
    ClientToScreen(hwnd_, &pt);
    SetCursor(g_cursorArrow); // otherwise menu does not show arrow
    TrackPopupMenuEx(
        menu,
        TPM_LEFTALIGN|TPM_RIGHTBUTTON|TPM_NONOTIFY,
        pt.x, pt.y,
        hwnd_,
        nullptr
        );
    DestroyMenu(menu);
}


// purpose:
//		displays the popup menu for a multi choice menu item.
// !assumes:
//		selected is valid (GetSelectedFlags has been checked)
// input:
//		[selected] - currently selected item
// returns:
//		nothing, WM_COMMAND is sent to window procedure
//
void AttributeList::ShowChoiceMenu(unsigned int itemIndex)
{
    if (itemIndex == UINT_MAX)
        itemIndex = selectedIndex_;

    assert(selectedIndex_ < totalItems_);
    assert(itemIndex < totalItems_);

    const Item& item = items_[itemIndex];

    HMENU menu;
    __nullterminated const WCHAR* text = item.text;
            
    if (text != nullptr
    && ((menu = CreatePopupMenu()) != nullptr))
    {
        int menuId = 0;
        const bool isButtonType = Item::IsEnabledType(item.flags, Item::FlagButtonType);
        if (isButtonType)
        {
            // Set initial menu id to that of item so that each command id is set.
            menuId = item.id;
        }

        // build menu choices
        for (/*menuId above*/; *text; text += wcslen(text)+1, menuId++)
        {
            AppendMenu(menu, MF_STRING, menuId, text);
        }
        if (!isButtonType) // Highlight current item if option list.
        {
            SetMenuDefaultItem(menu, item.value, /*byPosition*/TRUE);
        }

        RECT rect;
        GetItemTextRect(itemIndex, &rect);
        rect.left = 0;
        rect.top = rect.bottom; // setup for ClientToScreen to make POINT
        ClientToScreen(hwnd_, (POINT*)&rect);
        TrackPopupMenuEx(
            menu,
            TPM_LEFTALIGN|TPM_LEFTBUTTON|TPM_NONOTIFY,
            rect.left, rect.top,
            hwnd_,
            nullptr
            );
        DestroyMenu(menu);
    }
}


// purpose:
//		sets the flags for a toggle or menu button.
//		very simple function, but I saw myself using this exact same
//		code in several places and decided to consolidate.
//		no error checking since so much has already happened by any
//		part of the code that would call this function.
// !assumes:
//		selected is valid (GetSelectedFlags has been checked)
// input:
//		[selected] - currently selected item
//		flags - new flags to set
// returns:
//		nothing
//
void AttributeList::SetButtonValue(UINT32 value)
{
    assert(selectedIndex_ < totalItems_);

    Item& item = items_[selectedIndex_];
    bool valueChanged = (value != item.value);
    if (valueChanged)
    {
        item.value = value;
        item.flags &= ~Item::FlagStale;
        item.SetRedraw();

        PostRedraw(); //redraw toggle or menu item
        ResizeOverlay();
    }
    SendNotification(NotifyClicked, item.id, value, valueChanged);

    g_hoverRect.bottom=0; // force mouse recalc upon next mouse move
}
