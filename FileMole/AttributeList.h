#pragma once

////////////////////////////////////////////////////////////////////////////////
// Attribute List messages


class AttributeList
{
public:
    enum // menu command identifiers
    {
        IdPaste = 256,  // paste text into edit
        IdCopy,         // copy item text or label
        IdCopyAll,      // copy all text in attribute list
        IdClear,        // clear text from edit
        IdCommand,      // do button command
        IdToggle,       // switch toggle value
        IdHelp,         // get help on selected item
        IdMax = 300     // no IDs will be above this
    };

    struct Item
    {
        UINT16  id;     // identifier of item
        UINT8   flags;  // misc item flags indicating type, options, and id
        UINT8   value;  // value (meaning depends on type)
        PWSTR   label;  // text description of text field or button
        PWSTR   text;   // value string (typed text or pointer to checkbox words)
        UINT32  icon;   // index of icon in image list

        enum {MaxValue = 255};

        enum // attribute list flags
        {
            FlagTypeMask    = 0x07, // 3 bits allow 8 types

            FlagLabelType   = 0<<0, // filename prompt or blank separator
            FlagTitleType   = 1<<0, // main list title bar or section divider
            FlagEditType    = 2<<0, // editable text prompt
            FlagButtonType  = 3<<0, // simple push button
            FlagToggleType  = 4<<0, // toggle button with checked/unchecked
            FlagMenuType    = 5<<0, // multichoice menu
            FlagOptionType  = 6<<0, // multichoice items (mutually exclusize)

            FlagDisabled    = 1<<3, // item shown grayed but not selectable or editable
            FlagHidden      = 1<<4, // item hidden and neither shown nor selectable
            FlagRedraw      = 1<<5, // item needs redrawing next WM_PAINT

            // toggle and menu types
            FlagNoShowMark  = 1<<6, // don't display the check mark or triangle after the text
            FlagNumeric     = 1<<7, // text edit accepts numbers only

            FlagTitle       = FlagTitleType|FlagDisabled, // main list title bar or section divider
            FlagSeparator   = FlagLabelType|FlagDisabled,
        };

        static inline bool IsEnabledType(UINT32 flags, UINT32 itemType)
        {
            return (flags & (Item::FlagTypeMask|Item::FlagDisabled|Item::FlagHidden)) == itemType;
        }

        inline bool IsEnabledType(UINT32 itemType) const { return IsEnabledType(this->flags, itemType); }
        inline bool IsEnabled()                    const { return !(this->flags & (FlagHidden|FlagDisabled));  }
        inline bool IsVisible()                    const { return !(this->flags & FlagHidden); }
        inline unsigned int GetType()              const { return this->flags & FlagTypeMask;  }
        inline void SetRedraw()                          { this->flags |= FlagRedraw; }
    };

    enum // attribute list notifications
    {
        NotifyClicked   = 2<<16, // button was clicked, toggle, or new choice
        NotifyContext   = 3<<16, // context menu opened (lParam is actually the menu handle, not self)
        NotifyChoices   = 4<<16  // choice menu opened
    };

    struct NotifyMessage : NMHDR
    {
        UINT32 itemId;
        UINT32 value;
        BOOL   valueChanged;
    };

    enum
    {
        MessageSetItems = WM_USER + 1 // set new items list
    };

    enum
    {
        // *bit flags can be combined
        SelectionModeNone       = 0,
        SelectionModeDefault    = SelectionModeNone,
        SelectionModePage       = 1,    // scroll by page height
        SelectionModeParallel   = 2,    // move selection in parallel
        SelectionModeAbsolute   = 4,    // absolute
        SelectionModeScroll     = 8,    // ensure selection is visible, scrolling if not
        SelectionModeResetCaret = 16,   // set caret to end of edit text (if item is edit)
    };

public:
    AttributeList();

    AttributeList(__ecount(totalItems) Item* items, unsigned int totalItems);

    static bool RegisterWindowClass(HINSTANCE hModule);

    static LRESULT CALLBACK WindowProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam);

    // From hwnd to real object
    static inline AttributeList* GetClass(HWND hwnd)
    {
        return reinterpret_cast<AttributeList*>(GetWindowLongPtr(hwnd, GWLP_USERDATA));
    }

protected:
    class Overlay
    {
    public:
        Overlay();

        static LRESULT CALLBACK WindowProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam);

        // From hwnd to real object
        static inline Overlay* GetClass(HWND hwnd)
        {
            return reinterpret_cast<Overlay*>(GetWindowLongPtr(hwnd, GWLP_USERDATA));
        }

        HWND howner_;
        __nullterminated const WCHAR* text_;
    };

    struct ListMetrics
    {
        // filled in by GetListMetrics
        int itemHeight; // pixels height of a single
        int textHeight; // text cell height
        int iconHeight; // image list icon height (typically 16x16)
        int iconWidth;	// icon width (typically same as height)
        int itemRows;	// number of visible item rows in attribute list
        RECT clientRect;// rectangle of the client
    };

protected:
    HWND hwnd_;                 // handle to the associated window
    HWND hoverlay_;             // handle to the editing overlay/popup
    HIMAGELIST himl_;           // handle to image list
    unsigned int selectedIndex_;// currently selected item
    unsigned int topIndex_;     // item at scroll top
    unsigned int totalItems_;   // total attribute items (including disabled and separators)
    Item* items_;               // array of attribute list items

protected:
    void Init();

    LRESULT CALLBACK InternalWindowProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam);

    void GetListMetrics(ListMetrics* metrics);
    PWSTR GetItemText(unsigned int itemIndex);
    bool GetSelectedItemFlags(UINT32* flags);   // returns false if the item is invalid
    bool GetItemTextRect(unsigned int itemIndex, __out RECT* rectOut);
    bool GetItemTextRect(int y, __out unsigned int* itemIndex, __out RECT* rectOut);
    bool GetItemTextRect(unsigned int itemIndex, int topY, const ListMetrics& metrics, __out RECT* rectOut);
    int GetItemRow(unsigned int item, unsigned int top);
    unsigned int UpdateHoverItem(int y);

    int Seek(unsigned int itemIndex, int distance, UINT32 skipFlags, bool failIfShort = false);
    void SetCaretIndex(unsigned int newIndex);
    int Select(unsigned int newIndex);
    int SelectGiven(unsigned int newIndex, UINT32 options);
    void Scroll(int rowDif, const ListMetrics& metrics);
    void ScrollBy(int rowDif, UINT32 selectionMode);
    void SetScrollBars(const ListMetrics& metrics);

    void SetButtonValue(UINT8 value);
    void ShowChoiceMenu();
    void ShowContextMenu(unsigned int itemIndex, int x,int y);
    void SendClickCommand(unsigned int id);
    void SendNotification(unsigned int notification, unsigned int id, unsigned int value, bool valueChanged);
    void SendHelpToParent(const HELPINFO* helpInfo, unsigned int itemIndex, POINT& point);

    void Resize();
    bool ResizeOverlay();

    void PostRedraw();
    void PostRedrawOverlay();
    void FlagTitlesNeedRedraw();

    void DeleteChar();
    void InsertChar(unsigned int newchar);

    int CopyText(unsigned int itemIndex);
    int CopyAllText();
    int PasteText();
    int ClearText();
    static void AppendString(__deref_ecount(*previousMemoryLen) WCHAR** lockedMemText, __nullterminated const WCHAR* const text, __inout size_t* previousMemoryLen);
};
