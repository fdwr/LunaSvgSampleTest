//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   UI formatted text editor.
//
//----------------------------------------------------------------------------
#pragma once


class TextEditor : public UiControl
{
public:
    typedef UiControl Base;

    enum SetSelectionMode
    {
        SetSelectionModeLeft,               // cluster left
        SetSelectionModeRight,              // cluster right
        SetSelectionModeUp,                 // line up
        SetSelectionModeDown,               // line down
        SetSelectionModeLeftChar,           // single character left (backspace uses it)
        SetSelectionModeRightChar,          // single character right
        SetSelectionModeLeftWord,           // single word left
        SetSelectionModeRightWord,          // single word right
        SetSelectionModeHome,               // front of line
        SetSelectionModeEnd,                // back of line
        SetSelectionModeFirst,              // very first position
        SetSelectionModeLast,               // very last position
        SetSelectionModeAbsoluteLeading,    // explicit position (for mouse click)
        SetSelectionModeAbsoluteTrailing,   // explicit position, trailing edge
        SetSelectionModeAll                 // select all text
    };

    interface Owner
    {
        virtual bool TextEdited(TextEditor* source, int id) = NULL;
        virtual bool FormatEdited(TextEditor* source, int id) = NULL;
        virtual bool CaretMoved(TextEditor* source, int id) = NULL;
        virtual bool ViewChanged(TextEditor* source, int id) = NULL;
    };

public:
    TextEditor(UiControl* parent, int id, __notnull IDWriteTextEditLayout* layout);

    virtual bool Destroy() OVERRIDE;

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

    virtual bool Draw(RenderTarget& target, const Position& rect) OVERRIDE;

    void SetOwner(RefCountBase* target, Owner* listener);

    void SetTextLayout(IDWriteTextEditLayout* layout);

    // Selection/Caret navigation
    bool SetSelection(SetSelectionMode moveMode, UINT32 advance, bool extendSelection, bool updateCaretFormat = true);

    // These are used by the main app to respond to button presses.
    void CopyToClipboard();
    void DeleteSelection();
    void PasteFromClipboard();

    CaretFormattingAttributes& GetCaretFormat() { return caretFormat_; }

    DWRITE_TEXT_RANGE GetSelectionRange();

    UINT32 GetCaretPosition();

    void UpdateCaretFormatting();

    // Current view

    float GetAngle() {return angle_;}
    float SetAngle(float angle, bool relativeAdjustement);
    void SetScale(float scaleX, float scaleY, bool relativeAdjustement);
    void GetScale(__out float* scaleX, __out float* scaleY);

    void GetViewMatrix(__out DWRITE_MATRIX* matrix) const;
    void GetInverseViewMatrix(__out DWRITE_MATRIX* matrix) const;
    void ResetView() {InitView(); SetRedraw();}

protected:
    TextEditor()
    {
        Init();
    }

    inline void Init()
    {
        caretPosition_       = 0;
        caretAnchor_         = 0;
        caretPositionOffset_ = 0;

        currentlySelecting_  = false;
        currentlyPanning_    = false;
        previousMouseX       = 0;
        previousMouseY       = 0;

        InitView();
    }

    inline void InitView()
    {
        scaleX_         = 1;
        scaleY_         = 1;
        shearX_         = 0;
        shearY_         = 0;
        angle_          = 0;
        contentWidth_   = 750;
        contentHeight_  = 380;
        originX_        = contentWidth_  / 2;
        originY_        = contentHeight_ / 2;
    }

    void AlignCaretToNearestCluster(
        bool isTrailingHit = false,
        bool skipZeroWidth = false
        );

    void GetLineMetrics(
        __out std::vector<DWRITE_LINE_METRICS>& lineMetrics
        );

    void GetLineFromPosition(
        __in_ecount(lineCount) DWRITE_LINE_METRICS* lineMetrics,
        UINT32 lineCount,
        UINT32 textPosition,
        __out UINT32* lineOut,
        __out UINT32* linePositionOut
        );

    bool SetSelectionFromPoint(float x, float y, bool extendSelection);

protected:
    ComPtr<IDWriteTextEditLayout> textLayout_;
    UiDelegate<Owner> owner_;

    // Selection/Caret navigation

    // caretAnchor equals caretPosition when there is no selection.
    // Otherwise, the anchor holds the point where shift was held
    // or left drag started.
    //
    // The offset is used as a sort of trailing edge offset from
    // the caret position. For example, placing the caret on the
    // trailing side of a surrogate pair at the beginning of the
    // text would place the position at zero and offset of two.
    // So to get the absolute leading position, sum the two.
    UINT32 caretAnchor_;
    UINT32 caretPosition_;
    UINT32 caretPositionOffset_;    // > 0 used for trailing edge

    CaretFormattingAttributes caretFormat_;

    // Mouse manipulation

    bool currentlySelecting_ : 1;
    bool currentlyPanning_   : 1;
    float previousMouseX;
    float previousMouseY;

    enum {MouseScrollFactor = 10};

    // Current view

    float scaleX_;          // horizontal scaling
    float scaleY_;          // vertical scaling
    float shearX_;          // horizontal shift
    float shearY_;          // vertical shift
    float angle_;           // in degrees
    float originX_;         // focused point in document (moves on panning and caret navigation)
    float originY_;
    float contentWidth_;    // page size - margin left - margin right (can be fixed or variable)
    float contentHeight_;
};
