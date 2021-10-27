#include "ttview.h"
#include "TextOutStream.h"
#include "AppWindow.h"
#include "FontNode.h"
#include "UINode.h"
#include "resource.h"

using namespace std;

#pragma comment(lib, "comdlg32.lib")
#pragma comment(lib, "comctl32.lib")

//
// External functions
//
Renderer * CreateHexDumpRenderer(const void * data, size_t length);

FontNode * CreateTTCNode(UINode &uinode, const byte * data, unsigned length, FontFile & fontfile);
FontNode * CreatecmapNode(UINode &uinode, const byte * data, unsigned length, FontFile & fontfile);
FontNode * CreateheadNode(UINode &uinode, const byte * data, unsigned length, FontFile & fontfile);

bool IsTTC(const byte * font);


HMODULE Globals::Instance;


struct DirectoryEntry
{
    Tag              tag;
    BigEndian<ULONG> checkSum;
    BigEndian<ULONG> offset;
    BigEndian<ULONG> length;
};
C_ASSERT(sizeof(DirectoryEntry) == 4 * 4);

struct sfnt_table
{
    Fixed               version;
    BigEndian<USHORT>   numTables;
    BigEndian<USHORT>   searchRange;
    BigEndian<USHORT>   entrySelector;
    BigEndian<USHORT>   rangeShift;

    DirectoryEntry  tables[];
};
C_ASSERT(sizeof(sfnt_table) == sizeof(Fixed) + 4 * 2);



class FileNotFoundException : public std::exception
{
public:

    FileNotFoundException(const wstring & filename);

    void Show(HWND parent_window = NULL) const;

private:

    wstring     m_filename;
};


FileNotFoundException::FileNotFoundException(const wstring & filename)
      : m_filename(filename)
{
}


void FileNotFoundException::Show(HWND parent_window) const
{
    wstring error(wstring(L"Can't find the file '") + m_filename + L"'.");

    MessageBox(parent_window, error.c_str(), L"TTView", MB_OK);
}



void FontFile::SetFaceName(const std::wstring & facename)
{
    m_facename = facename;

    if (m_glyph_font)   DeleteObject(m_glyph_font);
    if (m_label_font)   DeleteObject(m_label_font);

    HDC screen = GetDC(NULL);
    m_glyph_font = CreateFont(-MulDiv(24, GetDeviceCaps(screen, LOGPIXELSY), 72),
                              0,
                              0,
                              0,
                              FW_NORMAL,
                              false,
                              false,
                              false,
                              DEFAULT_CHARSET,
                              OUT_DEFAULT_PRECIS,
                              CLIP_DEFAULT_PRECIS,
                              DEFAULT_QUALITY,
                              DEFAULT_PITCH | FF_DONTCARE,
                              facename.c_str());

    TEXTMETRIC metrics;
    HFONT oldfont = SelectFont(screen, m_glyph_font);
    GetTextMetrics(screen, &metrics);

    m_label_font = CreateFont(-MulDiv(6, GetDeviceCaps(screen, LOGPIXELSY), 72),
                              0,
                              0,
                              0,
                              FW_NORMAL,
                              false,
                              false,
                              false,
                              DEFAULT_CHARSET,
                              OUT_DEFAULT_PRECIS,
                              CLIP_DEFAULT_PRECIS,
                              DEFAULT_QUALITY,
                              DEFAULT_PITCH | FF_DONTCARE,
                              L"Arial");

    SIZE extents;
    SIZE min_label_extents;
    SelectFont(screen, m_label_font);
    GetTextExtentPoint32(screen, L"U+AAAA", 6, &min_label_extents);
    GetTextExtentPoint32(screen, L"00000", 5, &extents);
    min_label_extents.cx += extents.cx;

    m_glyph_cell_size.cx = max(metrics.tmMaxCharWidth, min_label_extents.cx) + 1;   // +1 for the border
    m_glyph_cell_size.cy = min_label_extents.cy + 1 + metrics.tmHeight + 1;

    
    SelectFont(screen, oldfont);
    DeleteDC(screen);
}






UINode::UINode(HWND window, const wstring& root_name)
      : m_window(window),
        m_treenode(TVI_ROOT)
{
    UINode node = AddChild(root_name);
    m_treenode = node.m_treenode;
}


UINode::UINode(HWND window, HTREEITEM treenode)
      : m_window(window),
        m_treenode(treenode)
{
}


void UINode::SetFontNode(FontNode * fontnode)
{
    TVITEM item;
    item.mask = TVIF_HANDLE | TVIF_PARAM;
    item.hItem = m_treenode;
    item.lParam = (LPARAM) fontnode;
    TreeView_SetItem(m_window, &item);
}


UINode UINode::AddChild(const wstring& name)
{
    TVINSERTSTRUCT newitem = {0};

    newitem.hParent = m_treenode;
    newitem.item.mask = TVIF_TEXT;
    newitem.item.pszText = const_cast<LPWSTR>(name.c_str());

    return UINode(m_window, TreeView_InsertItem(m_window, &newitem));
}


void UINode::SetName(const wstring & name)
{
    TVITEM item;
    item.mask = TVIF_HANDLE | TVIF_TEXT;
    item.hItem = m_treenode;
    item.pszText = const_cast<LPWSTR>(name.c_str());
    TreeView_SetItem(m_window, &item);
}


void UINode::Select()
{
    TreeView_Select(m_window, m_treenode, TVGN_CARET);
}


void UINode::Expand()
{
    TreeView_Expand(m_window, m_treenode, TVE_EXPAND);
}


inline FontNode::FontNode(const byte * data, size_t length)
      : m_data(data),
        m_length(length)
{
}


inline FontNode::~FontNode()
{
}


void FontNode::SetupUI(HWND)
{
}


void FontNode::TeardownUI(HWND)
{
}


void FontNode::Render(HDC dc)
{
    // BUGBUG: maybe we should default to HexDumpRenderer?

    if (m_renderer.get())
        m_renderer->Render(dc);
}


void FontNode::SetScrollPos(unsigned pos)
{    
    if (m_renderer.get())
        m_renderer->SetScrollPos(pos);
}


size_t FontNode::GetTotalHeight(HDC dc)
{    
    if (m_renderer.get())
        return m_renderer->GetTotalHeight(dc);
    else
        return 0;
}


void FontNode::OnNotify(int /* UNREF id */, const NMHDR * /* UNREF notification */)
{
}


RegisteredFontNode * RegisteredFontNode::m_tag_list = NULL;

RegisteredFontNode::Creater RegisteredFontNode::GetCreater(Tag tag)
{
    RegisteredFontNode * node = m_tag_list;

    for ( ; node != NULL; node = node->next)
        if (node->tag == tag)
            return node->creater;

    return NULL;
}


UnknownNode::UnknownNode(const byte * data, size_t length, FontFile & fontfile)
      : FontNode(data, length),
        m_offset(data - fontfile.FileBase())
{
    if (!fontfile.IsInFile(data, length))
        m_invalid = L"The data for this table is invalid and lies outside the bounds of the file.";

    // BUGBUG: warn if the table is not 4-byte aligned.

    m_renderer.reset(CreateHexDumpRenderer(data, length));
}


wstring UnknownNode::GetTooltip()
{
    return L"";
}




FontNode * CreateXmlNode(const char * xml, const char * xmlend, UINode & /* UNREF uinode */, const byte * data, unsigned length, FontFile & /* UNREF fontfile */);

FontNode * GetXmlNode(Tag tag, UINode & uinode, const byte * data, unsigned length, FontFile & fontfile)
{
    wstring name = tag;

    HRSRC resource = FindResource(Globals::Instance, name.c_str(), L"XMLTABLE");
    if (!resource)
        return NULL;

    HGLOBAL hg = LoadResource(Globals::Instance, resource);
    if (!hg)
        return NULL;

    const char * xml = (const char *) LockResource(hg);
    if (!xml)
        return NULL;

    DWORD size = SizeofResource(Globals::Instance, resource);

    return CreateXmlNode(xml, xml + size, uinode, data, length, fontfile);
}


sfntNode::sfntNode(UINode & uinode, const byte * data, unsigned length, FontFile & fontfile)
      : FontNode(data, length)
{
    sfnt_table * sfnt = (sfnt_table *) data;

    for (unsigned i = 0; i < sfnt->numTables; ++i)
    {
        const DirectoryEntry & child = sfnt->tables[i];

        UINode child_ui = uinode.AddChild(child.tag);
        FontNode * node = NULL;

        RegisteredFontNode::Creater creater = RegisteredFontNode::GetCreater(child.tag);

        try
        {
            if (creater)
                node = creater(child_ui, fontfile.FileBase() + child.offset, child.length, fontfile);

            if (!node)
                node = GetXmlNode(child.tag, child_ui, fontfile.FileBase() + child.offset, child.length, fontfile);
        }
        catch (const exception &)
        {
            // BUGBUG: should popup a message box in debug modes
#if _DEBUG
            if (IsDebuggerPresent())
                __debugbreak();
#endif
        }

        if (!node)
            node = new UnknownNode(fontfile.FileBase() + child.offset, child.length, fontfile);

        child_ui.SetFontNode(node);
    }
}


wstring sfntNode::GetTooltip()
{
    return L"sfnt\ntest";
}


void sfntNode::Render(HDC dc)
{
    TextOut(dc, 0, 0, L"testx", 5);
}


class DetailWindow : public AppWindow
{
public:

    DetailWindow(HWND parent);

    void SetNode(FontNode * node);

private:

    static bool m_registered;
    FontNode *  m_fontnode;

    LRESULT WindowProc(UINT, WPARAM, LPARAM);

    void OnNotify(HWND, int control, NMHDR * notification);
    void OnPaint(HWND);
    void OnVScroll(HWND, HWND hwndCtl, UINT code, int pos);
    void OnMouseWheel(HWND hwnd, int xPos, int yPos, int zDelta, unsigned int fwKeys);
};


bool DetailWindow::m_registered = false;


DetailWindow::DetailWindow(HWND parent)
      : m_fontnode(NULL)
{
    if (!m_registered)
    {
        WNDCLASSEX wndclass;

        ZeroMemory(&wndclass, sizeof(wndclass));
        wndclass.cbSize = sizeof(wndclass);
        wndclass.lpfnWndProc = &BaseWindowProc;
        wndclass.hInstance = Globals::Instance;
        wndclass.hCursor = LoadCursor(NULL, IDC_ARROW);
        wndclass.hbrBackground = (HBRUSH) (COLOR_3DFACE + 1);
        wndclass.lpszClassName = L"DetailView";

        if (!RegisterClassEx(&wndclass))
            DebugBreak();

        m_registered = true;
    }

    m_window = CreateWindowEx(
                    WS_EX_CLIENTEDGE,
                    L"DetailView",
                    L"",
                    WS_CHILD | WS_VISIBLE,
                    0,
                    0,
                    10,
                    10,
                    parent,
                    (HMENU) DetailView,
                    Globals::Instance,
                    this);
}


void DetailWindow::SetNode(FontNode * node)
{
    if (node != m_fontnode)
    {
        if (m_fontnode)
        {
            m_fontnode->TeardownUI(m_window);
        }

        m_fontnode = node;
        m_fontnode->SetupUI(m_window);
        m_fontnode->SetScrollPos(0);

        RECT rect;
        GetClientRect(m_window, &rect);
        
        HDC  dc = GetDC(m_window);

        SCROLLINFO scrollinfo;
        scrollinfo.cbSize = sizeof(scrollinfo);
        scrollinfo.fMask = SIF_RANGE | SIF_POS | SIF_PAGE;
        scrollinfo.nMin = 0;
        scrollinfo.nMax = (int) m_fontnode->GetTotalHeight(dc);
        scrollinfo.nPage = rect.bottom - rect.top;
        SetScrollInfo(m_window, SB_VERT, &scrollinfo, true);

        // Semi-ugly hack.  If setting the scroll info turned on the scrollbar
        // it changes the width of the client area and (potentially) the range
        // of the scrollbar.  So requery the range.  This sort of thing should
        // really be handled in some sort of size change handler.

        if (scrollinfo.nMax > rect.bottom)
        {
            scrollinfo.cbSize = sizeof(scrollinfo);
            scrollinfo.fMask = SIF_RANGE | SIF_POS | SIF_PAGE;
            scrollinfo.nMin = 0;
            scrollinfo.nMax = (int) m_fontnode->GetTotalHeight(dc);
            scrollinfo.nPage = rect.bottom - rect.top;
            SetScrollInfo(m_window, SB_VERT, &scrollinfo, true);
        }

        InvalidateRect(m_window, NULL, true);

        ReleaseDC(m_window, dc);
    }
}


LRESULT DetailWindow::WindowProc(UINT message, WPARAM wParam, LPARAM lParam)
{
    switch (message)
    {
        HANDLE_MSG(m_window, WM_PAINT,      OnPaint);
        HANDLE_MSG(m_window, WM_VSCROLL,    OnVScroll);
        HANDLE_MSG(m_window, WM_MOUSEWHEEL, OnMouseWheel);

        // busted common control message crackers
        case WM_NOTIFY:
            HANDLE_WM_NOTIFY(m_window, wParam, lParam, OnNotify);
            return 0;
    }
    
    return DefWindowProc(m_window, message, wParam, lParam);
}


void DetailWindow::OnNotify(HWND, int control, NMHDR * notification)
{
    if (m_fontnode)
        m_fontnode->OnNotify(control, notification);
}


void DetailWindow::OnPaint(HWND)
{
    PAINTSTRUCT ps;

    HDC dc = BeginPaint(m_window, &ps);
    
    SelectObject(dc, GetStockObject(DEFAULT_GUI_FONT));
    SetBkColor(dc, GetSysColor(COLOR_3DFACE));

    if (m_fontnode)
        m_fontnode->Render(dc);

    EndPaint(m_window, &ps);
}


void DetailWindow::OnMouseWheel(HWND hwnd, int xPos, int yPos, int zDelta, unsigned int fwKeys)
{
    if (zDelta == 0)
    {
        return; // do nothing
    }

    SCROLLINFO scrollinfo;
    scrollinfo.cbSize = sizeof(scrollinfo);
    scrollinfo.fMask = SIF_POS | SIF_TRACKPOS | SIF_PAGE | SIF_RANGE;
    GetScrollInfo(m_window, SB_VERT, &scrollinfo);

    const int scrollDistance = 20;
    int newpos = scrollinfo.nPos;
    if (zDelta > 0)
    {
        newpos -= scrollDistance;
        if (newpos > scrollinfo.nMax)
        {
            newpos = scrollinfo.nMax;
        }
    }
    else if (zDelta < 0)
    {
        newpos += scrollDistance;
        if (newpos < scrollinfo.nMin)
        {
            newpos = scrollinfo.nMin;
        }
    }

    if (newpos != scrollinfo.nPos)
    {
        OnVScroll(hwnd, NULL, SB_THUMBPOSITION, newpos);
    }
}


void DetailWindow::OnVScroll(HWND, HWND, UINT code, int newpos)
{
    SCROLLINFO scrollinfo;
    scrollinfo.cbSize = sizeof(scrollinfo);
    scrollinfo.fMask = SIF_POS | SIF_TRACKPOS | SIF_PAGE | SIF_RANGE;
    GetScrollInfo(m_window, SB_VERT, &scrollinfo);

    int pos = scrollinfo.nPos;
    int oldpos = pos;
    int minpos = 0;
    int maxpos = scrollinfo.nMax - scrollinfo.nPage;
    int page = (int) scrollinfo.nPage;

    switch (code)
    {
    case SB_THUMBPOSITION:  pos = newpos;   break;
    case SB_THUMBTRACK:     pos = newpos;   break;
    case SB_LINEDOWN:       pos += 1;       break;
    case SB_LINEUP:         pos -= 1;       break;
    case SB_TOP:            pos = minpos;   break;
    case SB_BOTTOM:         pos = maxpos;   break;
    case SB_PAGEUP:         pos -= page;    break;
    case SB_PAGEDOWN:       pos += page;    break;

    default: return;
    }

    pos = min(pos, maxpos);
    pos = max(pos, minpos);

    m_fontnode->SetScrollPos(pos);

    scrollinfo.fMask = SIF_POS;
    scrollinfo.nPos = pos;
    SetScrollInfo(m_window, SB_VERT, &scrollinfo, true);
    
    ScrollWindow(m_window, 0, oldpos - pos, NULL, NULL);
}


class MainWindow
{
public:

    MainWindow();

    void Open(const wstring & filename);

    void MessageBox(const string& str, int type = MB_OK | MB_ICONERROR);

private:

    HWND            m_window;
    unsigned        m_splitter_pos;
    bool            m_splitter_adjust;
    DetailWindow *  m_detail_window;
    FontFile *      m_fontfile;
    bool            m_was_minimized;

    void LayoutChildWindows();

    static LRESULT CALLBACK WindowProc(HWND, UINT, WPARAM, LPARAM);

    void OnCommand(HWND, int id, HWND control, UINT code);
    void OnDestroy(HWND);
    void OnLButtonDown(HWND, BOOL fDoubleClick, int x, int y, UINT keyFlags);
    void OnLButtonUp(HWND, int x, int y, UINT keyFlags);
    void OnMouseMove(HWND, int x, int y, UINT keyFlags);
    void OnNotify(HWND, int control, NMHDR * notification);
    void OnPaint(HWND);
    BOOL OnSetCursor(HWND, HWND hwndCursor, UINT codeHitTest, UINT msg);
    void OnSize(HWND, UINT state, int cx, int cy);

    void OnOpen();
};


MainWindow::MainWindow()
      : m_splitter_pos(0),
        m_splitter_adjust(false),
        m_was_minimized(false)
{
    INITCOMMONCONTROLSEX common_controls;
    common_controls.dwSize = sizeof(common_controls);
    common_controls.dwICC = ICC_TREEVIEW_CLASSES | ICC_LISTVIEW_CLASSES;
    InitCommonControlsEx(&common_controls);

    WNDCLASSEX  wndclass;

    ZeroMemory(&wndclass, sizeof(wndclass));
    wndclass.cbSize = sizeof(wndclass);
    wndclass.lpfnWndProc = WindowProc;
    wndclass.hInstance = Globals::Instance;
    wndclass.hIcon = LoadIcon(NULL, IDI_APPLICATION);
    wndclass.hCursor = LoadCursor(NULL, IDC_ARROW);
    wndclass.hbrBackground = (HBRUSH) (COLOR_3DFACE + 1);
    wndclass.lpszMenuName = L"MainMenu";
    wndclass.lpszClassName = L"MainWindow";

    if (!RegisterClassEx(&wndclass))
        DebugBreak();

    m_window = CreateWindowEx(
                    0,
                    L"MainWindow",
                    L"TTView",
                    WS_OVERLAPPEDWINDOW,
                    CW_USEDEFAULT,
                    CW_USEDEFAULT,
                    CW_USEDEFAULT,
                    CW_USEDEFAULT,
                    NULL,
                    NULL,
                    Globals::Instance,
                    this);

    if (NULL == m_window)
        DebugBreak();

    // List of font files
    CreateWindowEx(
            WS_EX_CLIENTEDGE,
            WC_TREEVIEW,
            L"",
            WS_CHILD | WS_VISIBLE | TVS_HASBUTTONS | TVS_HASLINES | TVS_LINESATROOT | TVS_SHOWSELALWAYS | TVS_INFOTIP,
            0,
            0,
            10,
            10,
            m_window,
            (HMENU) FileNodes,
            Globals::Instance,
            NULL);

    m_detail_window = new DetailWindow(m_window);

    ShowWindow(m_window, SW_SHOW);
    LayoutChildWindows();
}


void MainWindow::LayoutChildWindows()
{
    RECT client_area;
    unsigned splitter_width = GetSystemMetrics(SM_CXEDGE);

    GetClientRect(m_window, &client_area);

    if (0 == m_splitter_pos)
        m_splitter_pos = client_area.right / 3;

    MoveWindow(GetDlgItem(m_window, FileNodes), client_area.left, client_area.top, (int) m_splitter_pos, client_area.bottom, true);
    MoveWindow(GetDlgItem(m_window, DetailView), client_area.left + m_splitter_pos + splitter_width, client_area.top, client_area.right - (client_area.left + m_splitter_pos + splitter_width), client_area.bottom, true);
    InvalidateRect(GetDlgItem(m_window, DetailView), NULL, true);
}


LRESULT MainWindow::WindowProc(HWND window, UINT message, WPARAM wParam, LPARAM lParam)
{
    MainWindow *_this;

#pragma warning (push)
#pragma warning (disable: 4244)
#pragma warning (disable: 4312)

    if (WM_NCCREATE == message)
    {
        _this = (MainWindow *) ((CREATESTRUCT *) lParam)->lpCreateParams;
        SetWindowLongPtr(window, GWLP_USERDATA, (LONG_PTR) _this);
    }
    else
    {
        _this = (MainWindow *) GetWindowLongPtr(window, GWLP_USERDATA);
    }

#pragma warning (pop)

    if (NULL != _this)
    {
        switch (message)
        {
            HANDLE_MSG(window, WM_COMMAND,      _this->OnCommand);
            HANDLE_MSG(window, WM_DESTROY,      _this->OnDestroy);
            HANDLE_MSG(window, WM_LBUTTONDOWN,  _this->OnLButtonDown);
            HANDLE_MSG(window, WM_LBUTTONUP,    _this->OnLButtonUp);
            HANDLE_MSG(window, WM_MOUSEMOVE,    _this->OnMouseMove);           
            HANDLE_MSG(window, WM_PAINT,        _this->OnPaint);
            HANDLE_MSG(window, WM_SETCURSOR,    _this->OnSetCursor);
            HANDLE_MSG(window, WM_SIZE,         _this->OnSize);

        // busted common control message crackers
        case WM_NOTIFY:
            HANDLE_WM_NOTIFY(window, wParam, lParam, _this->OnNotify);
            return 0;
        }
    }

    return DefWindowProc(window, message, wParam, lParam);
}


void MainWindow::OnCommand(HWND, int id, HWND /* UNREF control */, UINT /* UNREF code */)
{
    switch (id)
    {
    case MENU_EXIT:
        DestroyWindow(m_window);
        break;

    case MENU_OPEN:
        OnOpen();
        break;
    }
}

void MainWindow::OnDestroy(HWND)
{
    PostQuitMessage(0);
}


void MainWindow::OnLButtonDown(HWND, BOOL /* UNREF fDoubleClick */, int /* UNREF x */, int /* UNREF y */, UINT /* UNREF keyFlags */)
{
    SetCapture(m_window);
    m_splitter_adjust = true;
}


void MainWindow::OnLButtonUp(HWND, int /* UNREF x */, int /* UNREF y */, UINT /* UNREF keyFlags */)
{
    m_splitter_adjust = false;
    ReleaseCapture();
}


void MainWindow::OnMouseMove(HWND, int x, int /* UNREF y */, UINT /* UNREF keyFlags */)
{
    if (!m_splitter_adjust)
        return;

    RECT client_area;

    GetClientRect(m_window, &client_area);
    x = max(client_area.left + 10, (LONG) x);      // BUGBUG: better metric than '10'
    x = min(client_area.right - 10, (LONG) x);

    m_splitter_pos = x;
    LayoutChildWindows();
}


void MainWindow::OnNotify(HWND, int control, NMHDR * notification)
{
    if (control == FileNodes)
    {
        if (notification->code == TVN_GETINFOTIP)
        {
            NMTVGETINFOTIP * tipinfo = (NMTVGETINFOTIP *) notification;
            TVITEM item;

            item.mask = TVIF_HANDLE | TVIF_PARAM;
            item.hItem = tipinfo->hItem;

            TreeView_GetItem(notification->hwndFrom, &item);

            if (item.lParam)
            {
                wstring tooltip = ((FontNode *) item.lParam)->GetTooltip();

                wcscpy_s(tipinfo->pszText, tipinfo->cchTextMax, tooltip.c_str());
            }
        }
        else if (notification->code == TVN_SELCHANGED)
        {
            NMTREEVIEW * info = (NMTREEVIEW *) notification;

            m_detail_window->SetNode((FontNode *) info->itemNew.lParam);
        }
    }
}


void MainWindow::OnPaint(HWND)
{
    PAINTSTRUCT ps;

    // Just force the background to be cleared
    BeginPaint(m_window, &ps);
    EndPaint(m_window, &ps);
}


BOOL MainWindow::OnSetCursor(HWND, HWND hwndCursor, UINT codeHitTest, UINT msg)
{
    if (hwndCursor != m_window || codeHitTest != HTCLIENT)
        return FORWARD_WM_SETCURSOR(m_window, hwndCursor, codeHitTest, msg, DefWindowProc);

    SetCursor(LoadCursor(NULL, IDC_SIZEWE));
    return true;
}


void MainWindow::OnSize(HWND, UINT state, int /* UNREF cx */, int /* UNREF cy */)
{
    if (SIZE_MINIMIZED == state)
    {
        m_was_minimized = true;
        return;
    }

    if (!m_was_minimized)
        LayoutChildWindows();

    m_was_minimized = false;
}

#include "shobjidl.h"
void MainWindow::OnOpen()
{
    WCHAR        filename[MAX_PATH];
    /*
    IFileOpenDialog * filedialog;
    HRESULT hr = CoCreateInstance(CLSID_FileOpenDialog, NULL, CLSCTX_INPROC_SERVER, IID_IFileOpenDialog, (void **) &filedialog);
    if (SUCCEEDED(hr))
    {
        COMDLG_FILTERSPEC filters[1];
        filters[0].pszName = L"OpenType Fonts";
        filters[0].pszSpec = L"*.ttf;*.ttc";
//        hr = filedialog->SetFileTypes(1, filters);
        hr = filedialog->SetOptions(FOS_ALLNONSTORAGEITEMS | FOS_NOTESTFILECREATE | FOS_NOVALIDATE);
        hr = filedialog->Show(m_window);
        
        IShellItem * item;
        LPWSTR name;
        hr = filedialog->GetResult(&item);
        hr = item->GetDisplayName(SIGDN_FILESYSPATH, &name);
        hr = S_OK;
    }
*/

    OPENFILENAME openinfo;

    filename[0] = L'\0';

    ZeroMemory(&openinfo, sizeof(openinfo));
    openinfo.lStructSize = sizeof(openinfo);
    openinfo.hwndOwner = m_window;
    openinfo.hInstance = Globals::Instance;
    openinfo.lpstrFilter = L"Font files (*.ttf;*.ttc;*.otf)\0*.ttf;*.ttc;*.otf\0All files\0*\0";
    openinfo.lpstrFile = filename;
    openinfo.nMaxFile = ARRAYSIZE(filename);
    openinfo.Flags = OFN_DONTADDTORECENT | OFN_FILEMUSTEXIST | OFN_HIDEREADONLY;
    
    if (!GetOpenFileName(&openinfo))
    {
        CommDlgExtendedError();
        return;
    }

    Open(filename);
}


void MainWindow::Open(const wstring & filename)
{
    AddFontResourceEx(filename.c_str(), FR_PRIVATE, 0);

    HANDLE file = CreateFile(
                        filename.c_str(),
                        GENERIC_READ,
                        FILE_SHARE_READ,
                        NULL,
                        OPEN_EXISTING,
                        FILE_ATTRIBUTE_READONLY | FILE_FLAG_RANDOM_ACCESS,
                        NULL);

    if (INVALID_HANDLE_VALUE == file)
    {
        if (GetLastError() == ERROR_FILE_NOT_FOUND)
            throw FileNotFoundException(filename);
        else
            __debugbreak();
    }

    DWORD size = GetFileSize(file, NULL);   // BUGBUG: check high-order size

    HANDLE mapped_file = CreateFileMapping(
                                file,
                                NULL,
                                PAGE_READONLY,
                                0,
                                0,
                                NULL);

    byte * font = (byte *) MapViewOfFile(
                                mapped_file,
                                FILE_MAP_READ,
                                0,
                                0,
                                0);

    m_fontfile = new FontFile(font, size);

    // move somewhere nicer
    HFONT hf = GetWindowFont(GetDlgItem(m_window, FileNodes));
    LOGFONT lf;
    GetObject(hf, sizeof(lf), &lf);
    HFONT text_font = CreateFontIndirect(&lf);
    m_fontfile->SetTextFont(text_font);

    UINode root(GetDlgItem(m_window, FileNodes), filename);
    FontNode * fontnode;

    if (IsTTC(font))
        fontnode = CreateTTCNode(root, font, size, *m_fontfile);
    else
        fontnode = new sfntNode(root, font, size, *m_fontfile);
        
    root.SetFontNode(fontnode);

    root.Select();
    root.Expand();
}


void MainWindow::MessageBox(const string& str, int type)
{
    ::MessageBoxA(m_window, str.c_str(), "TTView", type);
}


class CommandLineParser
{
public:

    CommandLineParser(const wstring & command_line);

    wstring InitialFile();

private:

    wstring m_initial_file;

    wstring::const_iterator GetOptionStart(wstring::const_iterator start, wstring::const_iterator end);
    wstring::const_iterator GetOptionEnd(wstring::const_iterator start, wstring::const_iterator end);
};


CommandLineParser::CommandLineParser(const wstring & command_line)
{
    // Skip the program name
    wstring::const_iterator end = GetOptionEnd(command_line.begin(), command_line.end());
    wstring::const_iterator start = GetOptionStart(end, command_line.end());

    m_initial_file = wstring(start, GetOptionEnd(start, command_line.end()));
}


wstring::const_iterator CommandLineParser::GetOptionEnd(wstring::const_iterator start, wstring::const_iterator end)
{
    wstring::const_iterator option_end = start;
    bool in_quotes = false;

    for ( ; option_end != end; ++option_end)
    {
        if (*option_end == L'\"')
            in_quotes = !in_quotes;
        else if (iswspace(*option_end) && !in_quotes)
            break;
    }

    return option_end;
}

wstring::const_iterator CommandLineParser::GetOptionStart(wstring::const_iterator start, wstring::const_iterator end)
{
    for ( ; start != end; ++start)
        if (!iswspace(*start))
            break;

    return start;
}


wstring CommandLineParser::InitialFile()
{
    return m_initial_file;
}

int WINAPI WinMain(HINSTANCE instance, HINSTANCE, LPSTR, int)
{
    Globals::Instance = instance;

    RECT desktop;
    GetWindowRect(GetDesktopWindow(), &desktop);

    CommandLineParser options(GetCommandLine());

	MSG msg;
	MainWindow main_window;

    try
    {
        if (!options.InitialFile().empty())
            main_window.Open(options.InitialFile());  // BUGBUG: Should seperate window from doc handling
    }
    catch (const FileNotFoundException & notfound)
    {
        notfound.Show();
        return 0;
    }
    catch (const std::exception & e)
    {
        main_window.MessageBox(e.what());
    }

    while (GetMessage(&msg, NULL, 0, 0) > 0)
    {
        if (msg.message == WM_MOUSEWHEEL)
        {
            // Mouse wheel messages don't go to the control with mouse focus
            // (unlike every other mouse message) and go instead to the control
            // with keyboard focus. Make it behave more sensibly, like IE,
            // where the scrolling applies to the window you are over.
            POINT pt = {GET_X_LPARAM(msg.lParam), GET_Y_LPARAM(msg.lParam)};
            HWND mouseHwnd = WindowFromPoint(pt);
            if (mouseHwnd != NULL)
            {
                // Don't send to a different process by mistake
                DWORD pid = 0;
                if (GetWindowThreadProcessId(mouseHwnd, &pid) == GetCurrentThreadId())
                {
                    msg.hwnd = mouseHwnd;
                }
            }
        }

        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }

    return 0;
}

