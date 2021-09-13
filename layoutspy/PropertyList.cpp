#include "LayoutSpy.h"
#include "PropertyList.h"
#include <sstream>



#pragma comment(linker,"/manifestdependency:\"type='win32' name='Microsoft.Windows.Common-Controls' version='6.0.0.0' processorArchitecture='*' publicKeyToken='6595b64144ccf1df' language='*'\"")

using std::runtime_error;
using std::wstring;
using std::wstringstream;
using std::map;


ATOM PropertyList::m_class = 0;


static const int ListViewId = 100;
static const int ComboBoxId = 101;
static const int EditBoxId  = 102;


LRESULT CALLBACK EditBoxSubclassProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam, UINT_PTR /* idSubclass */, DWORD_PTR refData)
{
    if (message == WM_KEYDOWN && (wParam == VK_RETURN || wParam == VK_TAB))
    {
        NMHDR nmhdr;
        nmhdr.hwndFrom = hWnd;
        nmhdr.idFrom = EditBoxId;
        nmhdr.code = NM_RETURN;
        FORWARD_WM_NOTIFY(reinterpret_cast<HWND>(refData), EditBoxId, &nmhdr, SendMessage);
        return 0;
    }
    
    if (message == WM_KEYUP && (wParam == VK_RETURN || wParam == VK_TAB))
    {
        return 0;
    }

    if (message == WM_CHAR && (wParam == L'\r' || wParam == '\t'))
    {
        return 0;
    }

    return DefSubclassProc(hWnd, message, wParam, lParam);
}


enum PropertyType
{
    InvalidProperty,
    StringProperty,
    FloatProperty,
    EnumProperty
};


PropertyList::PropertyList(HWND parentWindow)   
      : m_listview(NULL),
        m_combobox(NULL),
        m_editbox(NULL),
        m_activeEditor(NULL),
        m_currentItem(-1),
        m_propertyChanged(false)
{
    if (!m_class)
    {
        WNDCLASS wndclass = {0};
        wndclass.lpfnWndProc = WindowProc;
        wndclass.hInstance = g_instance;
        wndclass.hbrBackground = (HBRUSH) (COLOR_WINDOW + 1);
        wndclass.lpszClassName = L"PropertyList";

        m_class = RegisterClass(&wndclass);
        if (!m_class)
            throw runtime_error("RegisterClass(PropertyList)");
    }


    if (!CreateWindow(
                MAKEINTRESOURCE(m_class),
                L"",
                WS_CHILD | WS_VISIBLE,
                0,
                0,
                300,
                300,
                parentWindow,
                0,
                g_instance,
                this))
    {
        throw runtime_error("CreateWindow(PropertyList)");
    }

    RECT rect;
    GetClientRect(m_window, &rect);

    m_listview = CreateWindowEx(
                        0,
                        WC_LISTVIEW,
                        L"",
                        WS_CHILD | WS_CLIPSIBLINGS | WS_VISIBLE | LVS_REPORT | LVS_NOCOLUMNHEADER | LVS_SHOWSELALWAYS,
                        rect.left,
                        rect.top,
                        rect.right - rect.left,
                        rect.bottom - rect.top,
                        m_window,
                        (HMENU) ListViewId,
                        g_instance,
                        NULL);

    if (!m_listview)
        throw runtime_error("CreateWindow(PropertyList listview)");

    ListView_SetExtendedListViewStyle(m_listview, LVS_EX_GRIDLINES | LVS_EX_FULLROWSELECT);

    LVCOLUMN column;
    column.mask = LVCF_WIDTH;
    column.cx = (rect.right - rect.left) / 2;    
    ListView_InsertColumn(m_listview, 0, &column);
    ListView_InsertColumn(m_listview, 1, &column);

    LVGROUP group;
    group.cbSize = sizeof(group);
    group.mask = LVGF_HEADER | LVGF_GROUPID;
    group.pszHeader = L"Base Properties";
    group.iGroupId = 0;
    ListView_InsertGroup(m_listview, -1, &group);
    ListView_EnableGroupView(m_listview, true);
    m_propertyGroups[L""] = 0;

    m_editbox = CreateWindowEx(
                        0,
                        WC_EDIT,
                        L"",
                        WS_CHILD | ES_AUTOHSCROLL,
                        0,
                        0,
                        0,
                        0,
                        m_window,
                        (HMENU) EditBoxId,
                        g_instance,
                        NULL);

    if (!m_editbox)
        throw runtime_error("CreateWindow(PropertyList listview)");

    // Subclass the editbox so it's response to enter and tab response can
    // be overriden to move the focus back to the listview (and save any 
    // changes) instead of just beeping.
    SetWindowSubclass(m_editbox, EditBoxSubclassProc, (UINT_PTR) this, reinterpret_cast<DWORD_PTR>(m_window));

    SetWindowFont(m_editbox, GetWindowFont(m_listview), false);

    m_combobox = CreateWindowEx(
                        0,
                        WC_COMBOBOX,
                        L"",
                        WS_CHILD | CBS_DROPDOWN | CBS_AUTOHSCROLL,
                        0,
                        0,
                        0,
                        0,
                        m_window,
                        (HMENU) ComboBoxId,
                        g_instance,
                        NULL);

    if (!m_combobox)
        throw runtime_error("CreateWindow(PropertyList listview)");

    // The editbox portion of the combobox needs to be subclassed so that
    // it's keyboard actions can be modified in the same manner as our own
    // editbox.  I can't find a better way to get at it than to just assume
    // it's the first child of the combo.
    SetWindowSubclass(GetWindow(m_combobox, GW_CHILD), EditBoxSubclassProc, (UINT_PTR) this, reinterpret_cast<DWORD_PTR>(m_window));

    SetWindowFont(m_combobox, GetWindowFont(m_listview), false);
}


LRESULT CALLBACK PropertyList::WindowProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    if (message == WM_NCCREATE)
        SetWindowLongPtr(hWnd, GWLP_USERDATA, (LONG_PTR) ((CREATESTRUCT *) lParam)->lpCreateParams);

    PropertyList * this_ = (PropertyList *) GetWindowLongPtr(hWnd, GWLP_USERDATA);
    
    if (this_)
    {
        try
        {
            switch (message)
            {
                HANDLE_MSG(hWnd, WM_COMMAND,    this_->OnCommand);
                HANDLE_MSG(hWnd, WM_CREATE,     this_->OnCreate);
                HANDLE_MSG(hWnd, WM_NOTIFY,     this_->OnNotify);
                HANDLE_MSG(hWnd, WM_SETFOCUS,   this_->OnSetFocus);
                HANDLE_MSG(hWnd, WM_SIZE,       this_->OnSize);
            }
        }
        catch (const std::exception & e)
        {
            OutputDebugStringA("Unhandled exception ");
            OutputDebugStringA(e.what());
            OutputDebugStringA("\r\n");

            MessageBoxA(NULL, e.what(), "LayoutSpy - Unhandled exception", MB_ICONERROR | MB_OK);
            ExitProcess(0);
        }
    }

    return DefWindowProc(hWnd, message, wParam, lParam);
}


void PropertyList::OnCommand(HWND, int id, HWND /* hwndCtl */, UINT codeNotify)
{
    if ( (id == ComboBoxId && codeNotify == CBN_EDITUPDATE)
         || (id == ComboBoxId && codeNotify == CBN_SELCHANGE)
         || (id == EditBoxId && codeNotify == EN_UPDATE) )
    {
        if (id == ComboBoxId && codeNotify == CBN_SELCHANGE)
        {
            int currentSelection = ComboBox_GetCurSel(m_combobox);
            wstring newValue(ComboBox_GetLBTextLen(m_combobox, currentSelection) + 1, L'\0');
            ComboBox_GetLBText(m_combobox, currentSelection, &newValue[0]);
            SetWindowText(m_combobox, newValue.c_str());
        }

        OnPropertyChanged();

        if (id == ComboBoxId && codeNotify == CBN_SELCHANGE)
            UpdateProperty(m_currentItem);
    }
}


BOOL PropertyList::OnCreate(HWND hwnd, LPCREATESTRUCT /* lpCreateStruct */)
{
    m_window = hwnd;
    return true;
}


LRESULT PropertyList::OnNotify(HWND, int idCtrl, NMHDR * nmhdr)
{
    if (idCtrl == ListViewId)
    {
        switch (nmhdr->code)
        {
        case LVN_ITEMCHANGED: OnListviewChanged(reinterpret_cast<const NMLISTVIEW *>(nmhdr)); return 0;
        case LVN_KEYDOWN:     OnListviewKeyDown(reinterpret_cast<const NMLVKEYDOWN *>(nmhdr)); return 0;
        }
    }
    else if (idCtrl == EditBoxId)
    {
        switch (nmhdr->code)
        {
        case NM_RETURN:       OnEditboxEnterKeyPressed(); return 0;
        }
    }

    return 0;
}


void PropertyList::OnSetFocus(HWND, HWND /* hwndOldFocus */)
{
    SetFocus(m_listview);
}


void PropertyList::OnSize(HWND, UINT /* state */, int cx, int cy)
{
    MoveWindow(m_listview, 0, 0, cx, cy, true);
}


void PropertyList::OnListviewChanged(const NMLISTVIEW * change)
{
    if (change->uChanged & LVIF_STATE)
    {
        if (change->uNewState & LVIS_FOCUSED)
            OnPropertyFocused(change->iItem);
        else
            OnPropertyUnFocused(change->iItem);
    }
}


void PropertyList::OnListviewKeyDown(const NMLVKEYDOWN * keydown)
{
    if (keydown->wVKey == VK_TAB && m_activeEditor)
    {
        SetFocus(m_activeEditor);
        Edit_SetSel(m_activeEditor, 0, -1);     // Works for combobox too
    }
}


void PropertyList::OnPropertyFocused(int iItem)
{
    m_currentItem = iItem;
    m_activeEditor = GetItemEditor(iItem);

    RECT rect;
    ListView_GetSubItemRect(m_listview, iItem, 1, LVIR_BOUNDS, &rect);

    if (m_activeEditor == m_editbox)
    {
        InflateRect(&rect, -2, -2);
    }
    else if (m_activeEditor == m_combobox)
    {
        OffsetRect(&rect, -1, -1);
        rect.bottom += 100;
        FillEnumDropdown(iItem);
    }

    SetWindowText(m_activeEditor, GetItemText(iItem, 1).c_str());
    m_propertyChanged = false;

    SetWindowPos(
            m_activeEditor,
            HWND_TOP,
            rect.left,
            rect.top,
            rect.right - rect.left,
            rect.bottom - rect.top,
            SWP_SHOWWINDOW);    
}


void PropertyList::OnPropertyUnFocused(int iItem)
{
    if (m_propertyChanged)
        UpdateProperty(iItem);

    if (m_activeEditor)
        ShowWindow(m_activeEditor, SW_HIDE);
}


void PropertyList::UpdateProperty(int iItem)
{
    LVITEM item;
    item.mask = LVIF_GROUPID;
    item.iItem = iItem;
    item.iSubItem = 0;
    if (ListView_GetItem(m_listview, &item) == -1)
        throw runtime_error("Update property unable to get item group");

    map<wstring, int>::const_iterator groupMapping;
    for (groupMapping = m_propertyGroups.begin(); groupMapping != m_propertyGroups.end(); ++groupMapping)
        if (groupMapping->second == item.iGroupId)
            break;

    assert(groupMapping != m_propertyGroups.end());

    // Copy the new value from the active editor to the listview
    wstring newPropertyValue(GetWindowTextLength(m_activeEditor) + 1, L'\0');
    GetWindowText(m_activeEditor, &newPropertyValue[0], (int) newPropertyValue.size());

    ListView_SetItemText(m_listview, iItem, 1, const_cast<LPWSTR>(newPropertyValue.c_str()));

    // Expand the full property name
    wstring propertyName = GetItemText(iItem, 0);

    if (!groupMapping->first.empty())
        propertyName = groupMapping->first + L"\\" + propertyName;

    // Notify our parent of the change
    Notifications::PropertyChange change;
    change.hwndFrom = m_window;
    change.idFrom = GetDlgCtrlID(m_window);
    change.code = Notifications::PropertyChanged;
    change.propertyName = propertyName.c_str();

    FORWARD_WM_NOTIFY(GetParent(m_window), change.idFrom, &change, SendMessage);

    m_propertyChanged = false;
}


void PropertyList::OnPropertyChanged()
{
    m_propertyChanged = true;
}


void PropertyList::OnEditboxEnterKeyPressed()
{
    if (m_propertyChanged)
        UpdateProperty(m_currentItem);

    SetFocus(m_listview);
}


wstring PropertyList::GetItemText(int iItem, int iSubItem)
{
    // There doesn't appear to be a way to get the length of a subitem
    // string except by looping
    LVITEM item;
    item.iItem = iItem;
    item.iSubItem = iSubItem;
    item.mask = LVIF_TEXT;

    wstring value;
    int     valueLength = 16;
    int     copiedLength;

    do
    {
        valueLength *= 2;

        value.resize(valueLength);
        item.pszText = &value[0];
        item.cchTextMax = valueLength;

        copiedLength = (int) SendMessage(m_listview, LVM_GETITEMTEXT, (WPARAM) item.iItem, (LPARAM) &item);

    }
    while (copiedLength == valueLength - 1);

    assert(copiedLength >= 0);
    value.resize(copiedLength);

    return value;
}


HWND PropertyList::GetItemEditor(int iItem)
{
    LVITEM item;
    item.mask = LVIF_PARAM;
    item.iItem = iItem;
    item.iSubItem = 0;
    ListView_GetItem(m_listview, &item);

    switch (item.lParam)
    {
    case StringProperty: return m_editbox;
    case FloatProperty:  return m_editbox;
    case EnumProperty:   return m_combobox;

    default: throw runtime_error("Invalid property item type");
    }
}


void PropertyList::FillEnumDropdown(int iItem)
{
    ComboBox_ResetContent(m_combobox);

    wstring propertyName = GetItemText(iItem, 0);
    const wstring & definition = m_propertyDefinitions[propertyName];

    size_t enumStart = definition.find(L'|');

    while (enumStart != wstring::npos)
    {
        ++enumStart;
        size_t enumEnd = definition.find(L'|', enumStart);
        if (enumEnd == wstring::npos)
            break;

        ComboBox_AddString(m_combobox, definition.substr(enumStart, enumEnd - enumStart).c_str());
        
        enumStart = definition.find(L'|', enumEnd + 1);
    }
}


void PropertyList::AddPropertyGroup(const wstring & name)
{
    LVGROUP group;
    group.iGroupId = 0;

    if (!name.empty())
    {
        group.mask = LVGF_GROUPID;
        group.iGroupId = (int) m_propertyGroups.size();
        if (-1 == ListView_InsertGroup(m_listview, -1, &group))
            throw runtime_error("Property list add group");
    }

    group.mask = LVGF_HEADER;
    group.pszHeader = const_cast<LPWSTR>(name.c_str());
    if (-1 == ListView_SetGroupInfo(m_listview, group.iGroupId, &group))
        throw runtime_error("Property list name group");
}


void PropertyList::AddProperty(const wstring & name, const wstring & definition, const wstring & defaultValue)
{
    PropertyType propertyType = InvalidProperty;
    
    if (definition == L"string")
        propertyType = StringProperty;
    else if (definition == L"float")
        propertyType = FloatProperty;
    else if (definition.find(L'|') != wstring::npos)
        propertyType = EnumProperty;
    else
        throw runtime_error("Invalid property definition");

    int     groupId;
    wstring propertyName = ParseName(name, &groupId);

    LVITEM item;

    item.mask = LVIF_TEXT | LVIF_PARAM | LVIF_GROUPID;
    item.iItem = INT_MAX;
    item.iSubItem = 0;
    item.iGroupId = groupId;
    item.pszText = const_cast<LPWSTR>(propertyName.c_str());
    item.lParam = propertyType;
    item.iItem = ListView_InsertItem(m_listview, &item);

    if (item.iItem == -1)
        throw runtime_error("PropertyList::AddProperty");

    item.mask = LVIF_TEXT;
    item.iSubItem = 1;
    item.pszText = const_cast<LPWSTR>(defaultValue.c_str());
    if (!ListView_SetItem(m_listview, &item))
        throw runtime_error("PropertyList::AddProperty defaultValue");

    m_propertyDefinitions[name] = definition;
}


int PropertyList::GetItem(const wstring & name)
{
    int     groupId;
    wstring propertyName = ParseName(name, &groupId);

    LVGROUP group;
    group.cbSize = sizeof(group);
    group.mask = LVGF_ITEMS;
    ListView_GetGroupInfo(m_listview, groupId, &group);

    int item = group.iFirstItem;
    while (item != -1)
    {
        if (GetItemText(item, 0) == propertyName)
            return item;

        item = ListView_GetNextItem(m_listview, item, LVNI_SAMEGROUPONLY);
    }

    throw runtime_error("PropertyList unable to find item");
}


PropertyList::Property PropertyList::GetProperty(const wstring & name)
{
    wstring value = GetItemText(GetItem(name), 1);
    wstring enumValue = TranslateEnumValue(name, value);

    return Property(value, enumValue);
}


void PropertyList::SetProperty(const wstring & name, const wstring & value)
{
    int iItem = GetItem(name);

    ListView_SetItemText(m_listview, iItem, 1, const_cast<LPWSTR>(value.c_str()));

    if (iItem == m_currentItem)
        SetWindowText(m_activeEditor, value.c_str());
}


void PropertyList::SetProperty(const wstring & name, float value)
{
    wstringstream s;
    s << value;
    SetProperty(name, s.str());
}


wstring PropertyList::TranslateEnumValue(const wstring & prop, const wstring & value)
{
    const wstring & definition = m_propertyDefinitions[prop];
    wstring enumEntry = L"|" + value + L"|";
    wstring enumValue;

    size_t valueStart = definition.find(enumEntry);
    
    if (valueStart != wstring::npos)
    {
        valueStart += enumEntry.size();
        size_t valueEnd = definition.find(L'|', valueStart);

        if (valueEnd != wstring::npos)
            enumValue = definition.substr(valueStart, valueEnd - valueStart);
    }

    return enumValue;
}


wstring PropertyList::ParseName(const wstring & name, int * groupId)
{
    wstring groupName;
    wstring propertyName;

    if (name.find(L'\\') != wstring::npos)
    {
        groupName = name.substr(0, name.find(L'\\'));
        propertyName = name.substr(groupName.length() + 1);
    }
    else
    {
        propertyName = name;
    }

    if (m_propertyGroups.find(groupName) == m_propertyGroups.end())
    {
        LVGROUP group;
        group.cbSize = sizeof(group);
        group.mask = LVGF_GROUPID;
        group.iGroupId = (int) m_propertyGroups.size();
        if (-1 == ListView_InsertGroup(m_listview, -1, &group))
            throw runtime_error("PropertyList new group");

        m_propertyGroups.insert(std::make_pair(groupName, group.iGroupId));
    }

    *groupId = m_propertyGroups[groupName];
    return propertyName;
}


HWND PropertyList::GetHWND()
{
    return m_window;
}


PropertyList::Property::Property(const wstring & value, const wstring & enumValue)
      : m_value(value),
        m_enumValue(enumValue)
{
}


PropertyList::Property::operator wstring ()
{
    return m_value;
}


PropertyList::Property::operator float ()
{
    std::wstringstream s(m_value);

    float value;
    s >> value;

    return value;
}


PropertyList::Property::operator int ()
{
    std::wstringstream s(m_enumValue);

    int value;
    s >> value;

    return value;
}
