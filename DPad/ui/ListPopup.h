//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   Popup holder for a list of items.
//
//----------------------------------------------------------------------------
#pragma once


class ListPopup : public Window, public ListControl::Owner, public Button::Owner
{
public:
    typedef Window Base;

    interface Owner
    {
        virtual bool Showing(ListPopup* source, int id) = NULL;
        virtual bool Shown(ListPopup* source, int id) = NULL;
        virtual bool Activated(ListPopup* source, int id, size_t selectedItem) = NULL;
        virtual bool Canceled(ListPopup* source, int id) = NULL;
    };

public:
    ListPopup(UiControl* parent, int id);

    virtual bool Destroy() OVERRIDE;

    virtual bool KeyPress(KeyboardMessage& message) OVERRIDE;
    virtual bool KeyExit(KeyboardMessage& message) OVERRIDE;

    virtual bool InsertChild(UiControl* child) OVERRIDE;
    virtual bool InsertChild(UiControl* child, size_t childIndex) OVERRIDE;

    void SetOwner(RefCountBase* target, Owner* listener);
    bool GetOwner(__deref_opt_out RefCountBase** target, __deref_opt_out Owner** listener);

    // Attaches to the given button so that whenever it is clicked,
    // the list will appear. This DOES change the owner of the button.
    void ShowOnClick(Button* anchor);

    // Show the popup relative to the given control.
    void Show(__maybenull UiControl* anchor);

    // Show the popup relative to the given position (in the same coordinate
    // system as the popup).
    void Show(Position& anchorPosition);

public:
    // List owner implementation.
    virtual bool SelectionChanged(ListControl* source, int id, size_t selectedItem);
    virtual bool Activated(ListControl* source, int id, size_t selectedItem);
    virtual bool Scrolled(ListControl* source, int id);

    virtual bool Activated(Button* source, int id, int value);

protected:
    ListPopup()
    {
        Init();
    }

    inline void Init()
    {
    }

    void CancelActivate();

protected:
    UiDelegate<Owner> owner_;
};
