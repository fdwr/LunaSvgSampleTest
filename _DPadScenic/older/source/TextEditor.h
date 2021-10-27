//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2009. All rights reserved.
//
//  Contents:   UI formatted text editor.
//
//----------------------------------------------------------------------------
#pragma once


//todo:delete
struct MouseMessage
{
};
struct KeyboardMessage
{
};

class DECLSPEC_UUID("2EF2C6E3-5352-41c1-89D0-1C7F7F99359B") TextEditor
    :   public ComBase<QiList<IUnknown> >
{
public:
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

    interface DECLSPEC_UUID("7ACECA7C-D8A3-43e8-B176-E055C42B02A8") IOwner : IUnknown
    {
        virtual bool OnTextEdited(TextEditor* source,   int id) = NULL;
        virtual bool OnFormatEdited(TextEditor* source, int id) = NULL;
        virtual bool OnCaretMoved(TextEditor* source,   int id) = NULL;
        virtual bool OnViewChanged(TextEditor* source,  int id) = NULL;
        virtual bool OnContextMenu(TextEditor* source,  int id) = NULL;
    };

    Position position_;
    int id_; // todo:
    
public:
    ////////////////////
    // Creation/destruction
    TextEditor(HWND parentHwnd, __notnull IDWriteEditableTextLayout* layout);

    static ATOM RegisterWindowClass();
    static LRESULT CALLBACK WindowProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam);
    HWND GetHwnd() {return hwnd_;}
    void OnDestroy();
    void SetOwner(IOwner* owner);

    ////////////////////
    // Input dispatch
    void OnMousePress(UINT message, float x, float y);
    void OnMouseRelease(UINT message, float x, float y);
    void OnMouseMove(float x, float y);
    void OnMouseScroll(float xScroll, float yScroll);
    void OnMouseExit();
    void OnKeyPress(UINT32 keyCode);
    void OnKeyCharacter(UINT32 charCode);

    ////////////////////
    // Drawing/view change
    void OnDraw();
    void DrawPage(RenderTarget& target);
    void OnSize(UINT width, UINT height);
    void OnScroll(UINT message, UINT request);
    void UpdateCaretPosition();
    void SetRedraw() { InvalidateRect(hwnd_, NULL, FALSE); }
    void SetRenderTarget(RenderTarget* target) { renderTarget_.Set(target); }

    ////////////////////
    // Used by the main app to respond to button commands.
    void CopyToClipboard();
    void DeleteSelection();
    void PasteFromClipboard();

    ////////////////////
    // Layout/editing/caret navigation
    void SetTextLayout(IDWriteEditableTextLayout* layout);
    void UpdateCaretFormatting();
    bool SetSelection(SetSelectionMode moveMode, UINT32 advance, bool extendSelection, bool updateCaretFormat = true);
    DWRITE_TEXT_RANGE GetSelectionRange();
    UINT32 GetCaretPosition();
    EditableLayout::CaretFormat& GetCaretFormat() { return caretFormat_; }

    ////////////////////
    // Current view
    float GetAngle() {return angle_;}
    float SetAngle(float angle, bool relativeAdjustement);
    void  SetScale(float scaleX, float scaleY, bool relativeAdjustement);
    void  GetScale(__out float* scaleX, __out float* scaleY);
    void  GetViewMatrix(__out DWRITE_MATRIX* matrix) const;
    void  GetInverseViewMatrix(__out DWRITE_MATRIX* matrix) const;
    void  ResetView();
    void  RefreshView();

protected:
    void InitDefaults();
    void InitViewDefaults();

    bool SetSelectionFromPoint(float x, float y, bool extendSelection);
    void AlignCaretToNearestCluster(bool isTrailingHit = false, bool skipZeroWidth = false);

    void UpdateScrollInfo();
    void ConstrainOrigin();
    void TextWasEdited();

    void GetLineMetrics(__out std::vector<DWRITE_LINE_METRICS>& lineMetrics);
    void GetLineFromPosition(
        __in_ecount(lineCount) DWRITE_LINE_METRICS* lineMetrics,
        UINT32 lineCount,
        UINT32 textPosition,
        __out UINT32* lineOut,
        __out UINT32* linePositionOut
        );

protected:
    HWND hwnd_;

    ComPtr<IDWriteEditableTextLayout>   textLayout_;
    ComPtr<RenderTarget>                renderTarget_;
    ComPtr<IOwner>                      owner_;
    ComPtr<DrawingEffect>               pageBackgroundEffect_;
    ComPtr<DrawingEffect>               textSelectionEffect_;

    ////////////////////
    // Selection/Caret navigation
    ///
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

    // Current attributes of the caret, which can be independent
    // of the text.
    EditableLayout::CaretFormat caretFormat_;

    ////////////////////
    // Mouse manipulation
    bool currentlySelecting_ : 1;
    bool currentlyPanning_   : 1;
    float previousMouseX;
    float previousMouseY;

    enum {MouseScrollFactor = 10};

    ////////////////////
    // Current view
    float scaleX_;          // horizontal scaling
    float scaleY_;          // vertical scaling
    float angle_;           // in degrees
    float originX_;         // focused point in document (moves on panning and caret navigation)
    float originY_;
    float contentWidth_;    // page size - margin left - margin right (can be fixed or variable)
    float contentHeight_;
};
