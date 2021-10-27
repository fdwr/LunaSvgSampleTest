//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   User interface container (no visible component).
//
//----------------------------------------------------------------------------
#pragma once

class UiContainer : public UiControl
{
public:
    typedef UiControl Base;

protected:
    Position preferredPosition_; // to avoid recursion upon resize
    std::vector<UiControlRefPtr> children_;
    RefCountPtr<UiControl> mouseFocusChild_;
    RefCountPtr<UiControl> keyFocusChild_;
    bool mouseCaptured_;

public:
    UiContainer(UiControl* parent);

    virtual bool Destroy() OVERRIDE;

    virtual bool Draw(RenderTarget& target, const Position& rect) OVERRIDE;

    // Management of children
    virtual bool InsertChild(UiControl* child) OVERRIDE;
    virtual bool InsertChild(UiControl* child, size_t index) OVERRIDE;
    virtual bool DeleteChild(UiControl* child) OVERRIDE;
    virtual bool DeleteChild(size_t index) OVERRIDE;
    virtual bool GetChild(const UiControl* child, __out size_t* index) OVERRIDE;
    virtual bool GetChild(size_t index, __out UiControlRefPtr& child) OVERRIDE;

    // Input dispatch
    virtual bool MouseEnter(MouseMessage& message) OVERRIDE;
    virtual bool MouseExit(MouseMessage& message) OVERRIDE;
    virtual bool MousePress(MouseMessage& message) OVERRIDE;
    virtual bool MouseRelease(MouseMessage& message) OVERRIDE;
    virtual bool MouseMove(MouseMessage& message) OVERRIDE;
    virtual bool MouseScroll(MouseMessage& message) OVERRIDE;
    virtual bool KeyEnter(KeyboardMessage& message) OVERRIDE;
    virtual bool KeyExit(KeyboardMessage& message) OVERRIDE;
    virtual bool KeyPress(KeyboardMessage& message) OVERRIDE;
    virtual bool KeyRelease(KeyboardMessage& message) OVERRIDE;
    virtual bool KeyCharacter(KeyboardMessage& message) OVERRIDE;

    virtual bool SetKeyFocus(UiControl* child, bool chainParents) OVERRIDE;
    virtual bool SetMouseFocus(UiControl* child, MouseMessage& message, bool chainParents) OVERRIDE;

    virtual bool GetPosition(PositionQuery positionQuery, __inout Position* position);

public:
    // These generic reflow behaviors may be used by any inheriting children
    // or even other non-window controls that maintain a list of children.

    enum ReflowOptions
    {
        ReflowOptionDefault      = 0,
        ReflowOptionQueryOnly    = 1,   // only want result; don't actually move anything.
        ReflowOptionMoveFloating = 2    // move floating windows too.
    };

    // Simply arranges them all in sequence, left to right, top to bottom,
    // advancing by each control's width. The style flags of the container
    // are used to determine the arrangment orientation (horizontal or
    // vertical) and reading direction, flipping if needed.
    static Position ReflowChildrenSequential(
        std::vector<UiControlRefPtr>& children,
        const Position& windowRect,
        float spacing = 0,
        StyleFlag styleFlags = StyleFlagNone,
        ReflowOptions reflowOptions = ReflowOptionDefault
        );

protected:
    void Init()
    {
        mouseCaptured_ = false;
        preferredPosition_.SetZero();
    }

    UiContainer::UiContainer()
    {
        Init();
    }

    size_t GetIndexOfChild(const UiControl* child);
    bool SelectMouseFocusChild(MouseMessage& message);
    bool RelayMouseMessage(UiControl* child, MouseMessage& message, MouseMessageDelegate mmd);
    bool SelectKeyFocusChild(KeyboardMessage& message);
    bool SelectNextKeyFocusChild(bool reverse);
    void SetKeyFocus(UiControl* newChild, __inout KeyboardMessage& message);
    void SetMouseFocus(UiControl* newChild, MouseMessage& message);
};

DEFINE_ENUM_FLAG_OPERATORS(UiContainer::ReflowOptions);
