class PropertyList
{
    class Property
    {
    public:

        Property(const std::wstring & value, const std::wstring & enumValue);

        operator std::wstring ();
        operator float ();
        operator int ();

    private:

        std::wstring m_value;
        std::wstring m_enumValue;
    };

public:

    PropertyList(HWND parentWindow);

    void     AddPropertyGroup(const std::wstring & name);
    void     AddProperty(const std::wstring & name, const std::wstring & definition, const std::wstring & defaultValue);
    Property GetProperty(const std::wstring & name);
    void     SetProperty(const std::wstring & name, const std::wstring & value);
    void     SetProperty(const std::wstring & name, float value);

    HWND GetHWND();

    struct Notifications
    {
        enum
        {
            PropertyChanged = 1
        };

        struct PropertyChange : NMHDR
        {
            LPCWSTR propertyName;
        };
    };

private:

    std::wstring TranslateEnumValue(const std::wstring & prop, const std::wstring & value);

    static LRESULT CALLBACK WindowProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam);   
    void    OnCommand(HWND, int id, HWND hwndCtl, UINT codeNotify);
    BOOL    OnCreate(HWND hwnd, LPCREATESTRUCT lpCreateStruct);
    LRESULT OnNotify(HWND, int idCtrl, NMHDR * nmhdr);
    void    OnSetFocus(HWND, HWND hwndOldFocus);
    void    OnSize(HWND, UINT state, int cx, int cy);

    void OnListviewChanged(const NMLISTVIEW * change);
    void OnListviewKeyDown(const NMLVKEYDOWN * keydown);
    void OnPropertyFocused(int iItem);
    void OnPropertyUnFocused(int iItem);
    void OnPropertyChanged();
    void OnEditboxEnterKeyPressed();

    std::wstring GetItemText(int iItem, int iSubItem);
    HWND         GetItemEditor(int iItem);
    void         FillEnumDropdown(int iItem);
    void         UpdateProperty(int iItem);    
    std::wstring ParseName(const std::wstring & name, int * groupId);
    int          GetItem(const std::wstring & name);

    HWND m_window;
    HWND m_listview;
    HWND m_combobox;
    HWND m_editbox;
    HWND m_activeEditor;
    int  m_currentItem;
    bool m_propertyChanged;

    std::map<std::wstring, std::wstring> m_propertyDefinitions;
    std::map<std::wstring, int>          m_propertyGroups;

    static ATOM m_class;
};
