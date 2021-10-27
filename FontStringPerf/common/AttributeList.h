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
        IdMax = 300     // no internal attribute list IDs will be above this
    };

    struct Item
    {
        UINT16  id;     // identifier of item
        UINT16  flags;  // misc item flags indicating type, options, and id
        UINT32  value;  // value (meaning depends on type)
        PWSTR   label;  // text description of text field or button
        PWSTR   text;   // value string (typed text or pointer to checkbox words)
        UINT32  icon;   // index of icon in image list
        UINT8   indent; // indent value, 0..255
        UINT8   pad8;
        UINT16  pad16;

        enum {MaxValue = 255}; // todo: allow this to be greater than 2^8

        enum // attribute list flags
        {
            FlagTypeMask        = 0x0F, // up to 16 types

            FlagLabelType       = 0<<0, // filename prompt or blank separator
            FlagTitleType       = 1<<0, // main list title bar or section divider
            FlagEditType        = 2<<0, // editable text prompt
            FlagButtonType      = 3<<0, // simple push button
            FlagToggleType      = 4<<0, // toggle button with checked/unchecked
            FlagOptionType      = 6<<0, // multichoice items (mutually exclusive)
            FlagNodeType        = 7<<0, // tree node

            FlagNoSelect        = 1<<4, // item shown but not selectable
            FlagHidden          = 1<<5, // item hidden and neither shown nor selectable
            FlagRedraw          = 1<<6, // item needs redrawing next WM_PAINT
            FlagGray            = 1<<7, // item shown grayed (but still selectable and editable)
            FlagReadOnly        = 1<<8, // item cannot be modified

            // toggle and menu types
            FlagHideMark        = 1<<9, // don't display the check mark or triangle after the text
            FlagNumeric         = 1<<10, // text edit accepts numbers only
            FlagStale           = 1<<11, // data is not fresh anymore
            FlagNoText          = 1<<12, // don't display the text, only label

            FlagCollapsed       = 1<<13, // item is hidden due to being collapsed

            // Common combinations.
            FlagDisabled        = FlagNoSelect|FlagGray|FlagReadOnly, // item shown not selectable or editable
            FlagTitle           = FlagTitleType|FlagNoSelect|FlagReadOnly, // main list title bar or section divider
            FlagSeparator       = FlagLabelType|FlagNoSelect|FlagReadOnly,
            FlagButtonMenuType  = FlagButtonType|FlagNoText, // button with subchoices
        };

        static inline bool IsEnabled(UINT32 flags)
        {
            return !(flags & (Item::FlagReadOnly|Item::FlagHidden|Item::FlagCollapsed));
        }

        static inline bool IsEnabledType(UINT32 flags, UINT32 itemType)
        {
            return (flags & (Item::FlagTypeMask|Item::FlagReadOnly|Item::FlagHidden|Item::FlagCollapsed)) == itemType;
        }

        inline void UpdateFlags(UINT32 modifiedFlags, bool enabled)
        {
            this->flags = this->flags & ~modifiedFlags | (enabled ? modifiedFlags : 0);
        }

        inline bool IsEnabledType(UINT32 itemType) const { return IsEnabledType(this->flags, itemType); }
        inline bool IsEnabled()                    const { return IsEnabled(this->flags);  }
        inline bool IsVisible()                    const { return !(this->flags & (FlagHidden|FlagCollapsed)); }
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
        // also supports:
        //  WM_COPY
        //  WM_PASTE
        //  WM_CLEAR
        //  LB_SETCURSEL
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

    static UINT32 GetItemValue(UINT16 id, AttributeList::Item* items, unsigned int totalItems);
    static AttributeList::Item* FindMatchingItem(UINT16 id, AttributeList::Item* items, unsigned int totalItems);
    static unsigned int AttributeList::FindMatchingItemIndex(uint16_t id, AttributeList::Item* items, unsigned int totalItems); // return value can go to LB_SETCURSEL
    AttributeList::Item* FindMatchingItem(UINT16 id);

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
        int itemIndent; // amount to indent per indentation level
        RECT clientRect;// rectangle of the client
    };

protected:
    HWND hwnd_;                 // handle to the associated window
    HWND hoverlay_;             // handle to the editing overlay/popup
    HIMAGELIST himl_;           // handle to image list
    unsigned int selectedIndex_;// currently selected item
    unsigned int hoveredIndex_; // currently hovered item
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

    void SetButtonValue(unsigned int value);
    void ShowChoiceMenu(unsigned int itemIndex = UINT_MAX);
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
    static void AppendString(__deref_inout_ecount(*previousMemoryLen) WCHAR** lockedMemText, __in_z const WCHAR* const text, __inout size_t* previousMemoryLen);
};
