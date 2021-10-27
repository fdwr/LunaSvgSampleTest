//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   Main user interface window.
//
//----------------------------------------------------------------------------
#include "precomp.h"


class ProfilerWindow : public Window, public Button::Owner, public ListPopup::Owner, public ListControl::Owner
{
public:
    typedef Window Base;

    ProfilerWindow(
        UiControl* parent,
        IDWriteTextEditLayout* textLayout,
        IDWriteFactory* dwriteFactory,
        ID2D1Factory* d2dFactory,
        HWND hwnd // since so many functions rely on one
        );

public:
    virtual bool Draw(RenderTarget& target, const Position& rect) OVERRIDE;

    virtual bool KeyPress(KeyboardMessage& message) OVERRIDE;

    virtual bool Destroy() OVERRIDE;

    // Callbacks

    virtual bool Activated(Button* source, int id, int value);

    virtual bool SelectionChanged(ListControl* source, int id, size_t selectedItem);
    virtual bool Activated(ListControl* source, int id, size_t selectedItem);
    virtual bool Scrolled(ListControl* source, int id) { return false; };

    virtual bool Showing(ListPopup* source, int id);
    virtual bool Shown(ListPopup* source, int id);
    virtual bool Activated(ListPopup* source, int id, size_t selectedItem);
    virtual bool Canceled(ListPopup* source, int id);

public:
    void Dummy();
    void MeasureDWriteLayout();
    void MeasureUserGdi();
    void MeasureGdiPlus();
    void DrawLayoutDWrite();
    void DrawLayoutD2dSoft();
    void DrawLayoutD2dHard();
    void DrawLayoutGdi();
    void DrawLayoutGdiPlus();
    void DrawLayoutNullDraw();
    void DrawTextUserGdi();
    void DrawTextGdiPlus();
    void AnalyzeScript();
    void AnalyzeBidi();
    void AnalyzeNumberSubstitution();
    void AnalyzeLineBreakpoints();
    void ScriptItemize();
    void ScriptBreak();
    void ScriptShape();
    void ScriptPlace();

protected:
    enum ControlId
    {
        ControlIdTests,
        ControlIdIterations,
        ControlIdRenderVisibly,
        ControlIdRun,
        ControlIdClose
    };

    enum RenderTargetType
    {
        RenderTargetTypeD2D,
        RenderTargetTypeGDI,
        RenderTargetTypeTotal
    };

    void InitializeControls();

    ComPtr<IDWriteFactory> dwriteFactory_;
    ComPtr<ID2D1Factory> d2dFactory_;
    ComPtr<IDWriteTextEditLayout> textLayout_;
    HWND hwnd_;

    size_t selectedTest_;
    unsigned int iterations_;
    HANDLE threadHandle_;
    ULONG64 accumulatedCycleCount_;
    ULONG64 lastCycleCount_;

    RefCountPtr<Label> timerLabel_;

    void RunTest();
    void BeginProfile();
    void EndProfile();

    void DrawTextUserGdi(bool measureOnly);
    void DrawLayoutToRenderTarget(RenderTarget& renderTarget);
    void DrawTextGdiPlus(bool measureOnly);

private:
    void Init()
    {
        selectedTest_   = 0;
        iterations_     = 100;
        hwnd_           = NULL;
    }
};
