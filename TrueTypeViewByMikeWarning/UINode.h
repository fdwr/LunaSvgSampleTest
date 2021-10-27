class UINode
{
public:

    UINode(HWND window, const std::wstring& root_name);
    UINode(HWND m_window, HTREEITEM treenode);

    void SetFontNode(FontNode * fontnode);
    UINode AddChild(const std::wstring& name);

    void SetName(const std::wstring & name);

    void Select();
    void Expand();

private:

    HWND      m_window;
    HTREEITEM m_treenode;
};


