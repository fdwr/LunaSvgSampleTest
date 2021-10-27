#include "ttview.h"
#include "FontNode.h"
#include "resource.h"
#include <vector>

using namespace std;

class nameNode : public FontNode
{
    struct NameRecord
    {
        BigEndian<USHORT>   platformID;
        BigEndian<USHORT>   encodingID;
        BigEndian<USHORT>   languageID;
        BigEndian<USHORT>   nameID;
        BigEndian<USHORT>   length;
        BigEndian<USHORT>   offset;

        enum 
        {
            MacintoshPlatform = 1,
            MicrosoftPlatform = 3
        };

        std::wstring NameIDString() const;
        std::wstring Text(const byte * string_table) const;
        std::wstring Language() const;
    };

    struct Header
    {
        BigEndian<USHORT>   format;
        BigEndian<USHORT>   count;
        BigEndian<USHORT>   stringOffset;
        NameRecord          nameRecord[0];
    };

public:

    static FontNode * Create(UINode &uinode, const byte * data, size_t length, FontFile & fontfile);
    
    nameNode(UINode & uinode, const byte * data, size_t length, FontFile & fontfile);

    virtual std::wstring GetTooltip();
    virtual void         SetupUI(HWND parent_window);
    virtual void         TeardownUI(HWND);
    virtual void         OnNotify(int control, const NMHDR * notification);

private:

    HWND            m_name_info;
    int             m_sort_column;

    static int CALLBACK IntegerSort(LPARAM item_data1, LPARAM item_data2, LPARAM _namenode);
    static int CALLBACK TextSort(LPARAM item_data1, LPARAM item_data2, LPARAM _namenode);

    void OnRightClick(POINT point);
};


FontNode * nameNode::Create(UINode &uinode, const byte * data, size_t length, FontFile & fontfile)
{
    return new nameNode(uinode, data, length, fontfile);
}


nameNode::nameNode(UINode & /* UNREF uinode */, const byte * data, size_t length, FontFile & fontfile)
      : FontNode(data, length),
        m_name_info(NULL)
{
    if (!fontfile.IsInFile(data, length))
    {
        m_invalid = L"The data for this table is invalid and lies outside the bounds of the file.";
        return;
    }

    // BUGBUG: warn if the table is not 4-byte aligned.

    const Header * header = (const Header *) m_data;

    if (!fontfile.IsInFile(header, sizeof(*header)))
    {
        m_invalid = L"The table does not have enough room for the table header";
        return;
    }

    const NameRecord * records = header->nameRecord;

    if (!fontfile.IsInFile(records, header->count * sizeof(records[0])))
    {
        m_invalid = L"The table does not have enough room for the string records";
        return;
    }

    // BUGBUG: verify strings are in the table
    const byte * string_table = m_data + header->stringOffset;

    // Extract the font name GDI-style.
    //
    // GDI wants all four of unique name, full name, family name, and subfamily name.
    // It tries the system language, then the system primary language,
    // the English, the whatever has all four.

    
    wstring unique_name;
    wstring full_name;
    wstring family_name;
    wstring subfamily_name;

    USHORT system_language = GetSystemDefaultLangID();

    for (int l = 0; l < 3; ++l)
    {
        for (USHORT i = 0; i < header->count; ++i)
        {
            const NameRecord & record = records[i];

            if (record.platformID != NameRecord::MicrosoftPlatform)
                continue;

            USHORT desired_language = 0;
            USHORT record_language = 1;

            switch (l)
            {
            case 0: 
                desired_language = system_language; 
                record_language = record.languageID;
                break;

            case 1: 
                desired_language = PRIMARYLANGID(system_language);
                record_language = PRIMARYLANGID(record.languageID);

            case 2:
                desired_language = LANG_ENGLISH;
                record_language = PRIMARYLANGID(record.languageID);
            }

            if (desired_language != record_language)
                continue;

            // BUGBUG: use an enum instead of hardcoding
            switch (record.nameID)
            {
            case 1: family_name = record.Text(string_table); break;
            case 2: subfamily_name = record.Text(string_table); break;
            case 3: unique_name = record.Text(string_table); break;
            case 4: full_name = record.Text(string_table); break;
            }

            if (!family_name.empty() && !subfamily_name.empty() && 
                !unique_name.empty() && !full_name.empty())
            {
                fontfile.SetFaceName(full_name);
                break;
            }
        }

        if (!fontfile.GetFaceName().empty())
            break;

        family_name.clear();
        subfamily_name.clear();
        unique_name.clear();
        full_name.clear();
    }
}


wstring nameNode::GetTooltip()
{
    return L"Name table, including localized font names, copyright notices, etc.";
}


wstring nameNode::NameRecord::NameIDString() const
{
    static const wchar_t * strings[] = 
    {
        L"Copyright (0)",
        L"Family Name (1)",
        L"Subfamily Name (2)",
        L"Font ID (3)",
        L"Full Name (4)",
        L"Version (5)",
        L"Postscript Name (6)",
        L"Trademark (7)",
        L"Manufacturer (8)",
        L"Designer (9)",
        L"Description (10)",
        L"Vendor URL (11)",
        L"Designer URL (12)",
        L"License Description (13)",
        L"License URL (14)",
        L"(reserved) (15)",
        L"Preferred Family (16)",
        L"Preferred Subfamily (17)",
        L"Compatible Full Name (18)",
        L"Sample Text (19)",
        L"PostScript CID findfont name (20)",
        L"WWS Family (21)",
        L"WWS Subfamily (22)"
    };

    if (nameID < ARRAYSIZE(strings))
        return strings[nameID];
    else 
        return L"(unknown)";
}


wstring nameNode::NameRecord::Text(const byte * string_table) const
{
    wstring text(L"(unable to parse)");

    if (platformID == MacintoshPlatform)
    {
        if (encodingID == 0)
        {
            wchar_t * s = new wchar_t[length + 1];
            for (USHORT j = 0; j < length; ++j)
                s[j] = *(string_table + offset + j);
            s[length] = L'\0';
            text = s;
            delete [] s;
        }
    }
    else if (platformID == MicrosoftPlatform)
    {
        if (encodingID == 1)
        {
            wchar_t * s = new wchar_t[length + 1];
            const BigEndian<USHORT> * string = (const BigEndian<USHORT> *) (string_table + offset);
            for (USHORT j = 0; j < length/2; ++j)
                s[j] = string[j];
            s[length/2] = L'\0';
            text = s;
            delete [] s;
        }
    }

    return text;
}


wstring nameNode::NameRecord::Language() const
{
    WCHAR lang[1024];
    lang[0] = L'\0';

    if (platformID == MicrosoftPlatform)
    {
        USHORT lcid = languageID;
        GetLocaleInfo(lcid, LOCALE_SLANGUAGE, lang, 1024);
    }

    return lang;
}


void nameNode::SetupUI(HWND parent_window)
{
    RECT client_area;

    GetClientRect(parent_window, &client_area);

    m_name_info = CreateWindowEx(
                        0,
                        WC_LISTVIEW,
                        L"",
                        WS_CHILD | WS_VISIBLE | LVS_REPORT,
                        client_area.left,
                        client_area.top,
                        client_area.right - client_area.left,
                        client_area.bottom - client_area.top,
                        parent_window,
                        (HMENU) 0,
                        Globals::Instance,
                        NULL);              

    if (!m_name_info)
        return;

    ListView_SetExtendedListViewStyle(m_name_info, LVS_EX_LABELTIP | LVS_EX_INFOTIP);

    SetWindowRedraw(m_name_info, false);

    LVCOLUMN column;
    column.mask = LVCF_TEXT;

    column.pszText = L"Index";
    ListView_InsertColumn(m_name_info, 0, &column);

    column.pszText = L"Name ID";
    ListView_InsertColumn(m_name_info, 1, &column);

    column.pszText = L"Text";
    ListView_InsertColumn(m_name_info, 2, &column);

    column.pszText = L"Language";
    ListView_InsertColumn(m_name_info, 3, &column);


    const Header * header = (const Header *) m_data;
    const byte * string_table = m_data + header->stringOffset;
    int   text_width = 0;

    for (USHORT i = 0; i < header->count; ++i)
    {
        const NameRecord & record = header->nameRecord[i];

        wstringstream itoa;
        itoa << i;
        wstring index = itoa.str();

        // Insert the new row
        LVITEM newitem;
        newitem.mask = LVIF_TEXT | LVIF_PARAM;
        newitem.pszText = const_cast<LPWSTR>(index.c_str());
        newitem.iItem = i;
        newitem.iSubItem = 0;
        newitem.lParam = i;
        int item_index = ListView_InsertItem(m_name_info, &newitem);

        wstring name_id = record.NameIDString();
        wstring text = record.Text(string_table);
        wstring language = record.Language();

        if (record.nameID == 0) // copyright notice
            text_width = max(text_width, ListView_GetStringWidth(m_name_info, text.c_str()));

        ListView_SetItemText(m_name_info, item_index, 1, const_cast<LPWSTR>(name_id.c_str()));
        ListView_SetItemText(m_name_info, item_index, 2, const_cast<LPWSTR>(text.c_str()));
        ListView_SetItemText(m_name_info, item_index, 3, const_cast<LPWSTR>(language.c_str()));

        LVSETINFOTIP tooltip;
        tooltip.cbSize = sizeof(tooltip);
        tooltip.dwFlags = 0;
        tooltip.pszText = L"a";
        tooltip.iItem = item_index;
        tooltip.iSubItem = 0;
        ListView_SetInfoTip(m_name_info, &tooltip);
    }

    for (int i = 0; i < 4; ++i)
        ListView_SetColumnWidth(m_name_info, i, LVSCW_AUTOSIZE);

    if (text_width)
        ListView_SetColumnWidth(m_name_info, 2, text_width * 10 / 9);

    SetWindowRedraw(m_name_info, true);
    InvalidateRect(m_name_info, NULL, true);
}


void nameNode::TeardownUI(HWND)
{
    if (m_name_info)
        DestroyWindow(m_name_info);
}


void nameNode::OnNotify(int /* UNREF control */, const NMHDR * notification)
{
    if (notification->hwndFrom == m_name_info)
    {
        if (notification->code == LVN_COLUMNCLICK)
        {
            const NMLISTVIEW * info = (const NMLISTVIEW *) notification;

            m_sort_column = info->iSubItem;

            if (0 == info->iSubItem)
                ListView_SortItems(m_name_info, IntegerSort, (LPARAM) this);
            else
                ListView_SortItems(m_name_info, TextSort, (LPARAM) this);
        }
        else if (notification->code == NM_RCLICK)
        {
            const NMITEMACTIVATE * info = (const NMITEMACTIVATE *) notification;

            OnRightClick(info->ptAction);
        }
    }
}


int nameNode::IntegerSort(LPARAM item_data1, LPARAM item_data2, LPARAM /* UNREF _namenode */)
{
    if (item_data1 < item_data2)
        return -1;
    else
        return 1;
}


int nameNode::TextSort(LPARAM item1_data, LPARAM item2_data, LPARAM _namenode)
{
    const nameNode * _this = (const nameNode *) _namenode;

    WCHAR text1[256], text2[256];

    LVFINDINFO find;
    LVITEM     item;

    find.flags = LVFI_PARAM;
    find.lParam = item1_data;
    item.mask = LVIF_TEXT;
    item.pszText = text1;
    item.cchTextMax = ARRAYSIZE(text1);
    item.iItem = ListView_FindItem(_this->m_name_info, -1, &find);
    item.iSubItem = _this->m_sort_column;
    ListView_GetItem(_this->m_name_info, &item);

    find.flags = LVFI_PARAM;
    find.lParam = item2_data;
    item.mask = LVIF_TEXT;
    item.pszText = text2;
    item.cchTextMax = ARRAYSIZE(text2);
    item.iItem = ListView_FindItem(_this->m_name_info, -1, &find);
    item.iSubItem = _this->m_sort_column;
    ListView_GetItem(_this->m_name_info, &item);

    int ret = CompareString(LOCALE_USER_DEFAULT, 0, text1, -1, text2, -1);

    if (0 == ret)
        __debugbreak();

    return ret - 2;
}


void SetClipboardData(const WCHAR * text)
{
    if (!OpenClipboard(NULL))
        return;

    size_t cch = wcslen(text) + 1;
    HLOCAL hLocal = LocalAlloc(LMEM_FIXED, cch * sizeof(WCHAR));
    if (hLocal)
    {
        wcscpy_s((WCHAR *) hLocal, cch, text);
        SetClipboardData(CF_UNICODETEXT, hLocal);
    }

    CloseClipboard();
}


void nameNode::OnRightClick(POINT point)
{
    HMENU context_menu = LoadMenu(Globals::Instance, L"NameNodePopup");

    if (!context_menu)
        return;

    POINT screen_point = point;
    ClientToScreen(m_name_info, &screen_point);

    int i = TrackPopupMenu(
                    GetSubMenu(context_menu, 0), 
                    TPM_LEFTALIGN | TPM_TOPALIGN | TPM_NONOTIFY | TPM_RETURNCMD | TPM_RIGHTBUTTON,
                    screen_point.x,
                    screen_point.y,
                    0,
                    m_name_info,
                    NULL);

    if (i == MENU_COPY)
    {
        LVHITTESTINFO hittest;
        hittest.pt = point;
        
        ListView_SubItemHitTest(m_name_info, &hittest);

        // Listviews don't appear to have any way to query the length of
        // thier text.  So we are forced to loop with progressively bigger
        // buffers until we're sure we've got it all.

        vector<WCHAR> text_data;
        text_data.resize(128);

        LRESULT text_length;
        do
        {
            text_data.resize(text_data.capacity() * 2);    // not really elegant to immediately increment

            LVITEM item;
            item.mask = LVIF_TEXT;
            item.iItem = hittest.iItem;
            item.iSubItem = hittest.iSubItem;
            item.pszText = &text_data[0];
            item.cchTextMax = (int) text_data.capacity();

            text_length = SendMessage(m_name_info, LVM_GETITEMTEXT, item.iItem, (LPARAM) &item);
        }
        while ((size_t) text_length == (text_data.capacity() - 1));

        SetClipboardData(&text_data[0]);
    }

    DestroyMenu(context_menu);
}



RegisteredFontNode name_registration('name', &nameNode::Create);
