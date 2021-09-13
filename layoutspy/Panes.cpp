#include "LayoutSpy.h"
#include "Panes.h"
#include "LayoutRecorder.h"
#include "TextFormatter.h"


using std::max;
using std::min;
using std::swap;


extern D2D1_COLOR_F D2DSysColor(int colorIndex);


bool Pane::Contains(D2D1_POINT_2F pt)
{
    return pt.x >= m_bounds.left && pt.x < m_bounds.right
           && pt.y >= m_bounds.top && pt.y < m_bounds.bottom;
}


float Pane::Width()
{
    return m_bounds.right - m_bounds.left;
}


float Pane::Height()
{
    return m_bounds.bottom - m_bounds.top;
}


const D2D1_RECT_F & Pane::GetRect()
{
    return m_bounds;
}


D2D1_POINT_2F Pane::TopLeft()
{
    return D2D1::Point2F(m_bounds.left, m_bounds.top);
}


D2D1_POINT_2F Pane::BottomRight()
{
    return D2D1::Point2F(m_bounds.right, m_bounds.bottom);
}


void Pane::Resize(D2D1_RECT_F bounds)
{
    m_bounds = bounds;
}


void Pane::PreDraw(ID2D1RenderTarget * renderTarget)
{
    renderTarget->SetTransform(D2D1::Matrix3x2F::Translation(D2D1::SizeF(m_bounds.left, m_bounds.top)));
    renderTarget->PushAxisAlignedClip(D2D1::RectF(0, 0, m_bounds.right - m_bounds.left, m_bounds.bottom - m_bounds.top), D2D1_ANTIALIAS_MODE_PER_PRIMITIVE);
}


void Pane::PostDraw(ID2D1RenderTarget * renderTarget)
{
    renderTarget->PopAxisAlignedClip();
}


UnitPane::UnitPane()
      : m_firstUnit(0),
        m_highlightedNavArrow(NoNavArrow),
        m_haveInfoUnit(false),
        m_lButtonDown(false),
        m_animating(false),
        m_selectionState(NoSelection)
{
    TIF( g_d2d->CreatePathGeometry(&m_navArrow) );

    ID2D1GeometrySinkPtr sink;
    TIF( m_navArrow->Open(&sink) );
    sink->BeginFigure(D2D1::Point2F(0.0f, 0.0f), D2D1_FIGURE_BEGIN_FILLED);
    sink->AddLine(D2D1::Point2F(10.0f, -10.0f));
    sink->AddLine(D2D1::Point2F(10.0f, 10.0f));
    sink->EndFigure(D2D1_FIGURE_END_CLOSED);
    TIF( sink->Close() );

    TIF( g_d2d->CreateStrokeStyle(
                    D2D1::StrokeStyleProperties(D2D1_CAP_STYLE_ROUND, D2D1_CAP_STYLE_ROUND, D2D1_CAP_STYLE_FLAT, D2D1_LINE_JOIN_ROUND), 
                    NULL, 
                    0, 
                    &m_roundJoins) );
}


bool UnitPane::Draw(ID2D1RenderTarget * renderTarget, ID2D1Brush * textBrush)
{
    renderTarget->Clear(D2D1::ColorF(D2D1::ColorF::White)); // BUGBUG syscolor
    
    if (!UnitCount())
        return false;

    // leave half a width on either side for the nav arrows
    int widthInChars = max(1, (int) ((Width() - 72.0f) / 72.0f));
    int heightInChars = max(1, (int) (Height() / 72.0f));

    D2D1_MATRIX_3X2_F originalTransform;
    renderTarget->GetTransform(&originalTransform);
    m_navArrowPos[NavLeft] = D2D1::Matrix3x2F::Translation(D2D1::SizeF(10.0f, 36.0f)) * originalTransform;
    m_navArrowPos[NavRight] = D2D1::Matrix3x2F::Rotation(180.0f) * D2D1::Matrix3x2F::Translation(Width() - 10, 72.0f * heightInChars - 36.0f) * originalTransform;
    
    for (NavArrow nav = NavArrowBegin; nav != NavArrowEnd; nav = (NavArrow) (nav + 1))
    {
        renderTarget->SetTransform(m_navArrowPos[nav]);

        if (nav == m_highlightedNavArrow)
        {
            ID2D1SolidColorBrushPtr highlight;
            renderTarget->CreateSolidColorBrush(D2DSysColor(COLOR_HIGHLIGHT), &highlight);

            renderTarget->DrawGeometry(m_navArrow, highlight, 3.0f, m_roundJoins);
        }
        else
        {
            renderTarget->DrawGeometry(m_navArrow, textBrush);
        }
    }

    renderTarget->SetTransform(originalTransform);
    renderTarget->PushAxisAlignedClip(D2D1::RectF(36.0f, 0, 36.0f + 72.0f * widthInChars, Height() - 2), D2D1_ANTIALIAS_MODE_PER_PRIMITIVE);

    D2D1_RECT_F glyphRect = D2D1::RectF(0.0f, 0.0f, 72.0f, 72.0f);
    glyphRect.left += 36.0f;
    glyphRect.right += 36.0f;

    if (m_animating)
    {
        DWORD frame = timeGetTime() - m_animationStartTime;
        if (frame >= m_animationPeriod)
        {
            switch (m_highlightedNavArrow)
            {
            case NavLeft:  ++m_firstUnit; break;
            case NavRight: --m_firstUnit; break;
            }
            
            m_animating = false;

            if (m_lButtonDown)
                OnMouseDown(D2D1::Point2F());
        }
        
        if (m_animating)
        {
            float adjustment = 72.0f * (frame % m_animationPeriod) / m_animationPeriod;

            switch (m_highlightedNavArrow)
            {
            case NavLeft:
                glyphRect.left -= adjustment;
                glyphRect.right -= adjustment;
                break;

            case NavRight:
                glyphRect.left += adjustment;
                glyphRect.right += adjustment;
                break;
            }
        }
    }

    size_t i = m_firstUnit;
    while (i != UnitCount())
    {
        DrawUnit(renderTarget, textBrush, glyphRect, i);

        ++i;
        glyphRect.left += 72.0f;
        glyphRect.right += 72.0f;

        if (((i - m_firstUnit) % widthInChars) == 0)
        {
            glyphRect.left = 36.0f;
            glyphRect.right = 36 + 72.0f;
            glyphRect.top += 75.0f;
            glyphRect.bottom += 75.0f;

            if (glyphRect.top > Height() - 2)
                break;
        }
    }

    DrawSelection(renderTarget);

    renderTarget->PopAxisAlignedClip();

    return m_animating;
}


void UnitPane::DrawSelection(ID2D1RenderTarget * renderTarget)
{
    if (m_selectionState == NoSelection)
        return;

    ID2D1SolidColorBrushPtr selectionBrush;
    TIF( renderTarget->CreateSolidColorBrush(D2DSysColor(COLOR_HIGHLIGHT), D2D1::BrushProperties(0.75f), &selectionBrush) );

    size_t begin = m_selectionStart;
    size_t end   = m_selectionStop;

    if (begin > end)
        swap(begin, end);

    ++end;

    size_t widthInChars = max((size_t) 1, (size_t) floor((Width() - 72.0f) / 72.0f));
    size_t row = (begin - m_firstUnit) / widthInChars;
    size_t unitStart = row * widthInChars + m_firstUnit;
    size_t column = begin - unitStart;

    while (unitStart < end)
    {
        size_t columnEnd = min(widthInChars, end - unitStart);
        renderTarget->DrawRectangle(D2D1::RectF(column * 72.0f + 36.0f, row * 75.0f, columnEnd * 72.0f + 36.0f, row * 75.0f + 72.0f), selectionBrush, 5);
        ++row;
        unitStart += widthInChars;
        column = 0;
    }
}


bool UnitPane::OnMouseDown(D2D_POINT_2F pt)
{
    if (UnitCount() == 0)
        return false;

    if (   (m_highlightedNavArrow == NavLeft && m_firstUnit < UnitCount() - 1)
        || (m_highlightedNavArrow == NavRight && m_firstUnit > 0) )
    {
        m_lButtonDown = true;
        m_animating = true;
        m_animationPeriod = GetDoubleClickTime() / 4;
        m_animationStartTime = timeGetTime();
    }

    SelectionState oldSelectionState = m_selectionState;
    m_selectionState = NoSelection;
    size_t unit = UnitFromPoint(pt);
    if (unit != UnitCount())
    {
        m_selectionState = Selecting;
        m_selectionStart = unit;
        m_selectionStop  = unit;
        SetSelectionInfo();
    }

    return m_animating || m_selectionState != oldSelectionState;
}


bool UnitPane::OnMouseMove(D2D_POINT_2F pt)
{
    bool redraw = false;

    if (m_selectionState == Selecting)
    {
        size_t unit = UnitFromPoint(pt);
        redraw = (unit != m_selectionStop);

        if (unit != UnitCount())
            m_selectionStop = unit;
    }

    if (m_selectionState != NoSelection)
    {
        if (redraw)
            SetSelectionInfo();

        return redraw;
    }

    NavArrow navArrow;

    for (navArrow = NavArrowBegin; navArrow != NavArrowEnd; navArrow = (NavArrow) (navArrow + 1))
    {
        BOOL inFigure;
        TIF( m_navArrow->FillContainsPoint(pt + TopLeft(), m_navArrowPos[navArrow], &inFigure) );
        
        if (inFigure)
            break;
    }
    
    if (navArrow == NavArrowEnd)
        navArrow = NoNavArrow;

    size_t infoUnit = UnitFromPoint(pt);
    bool haveInfoUnit = (infoUnit != UnitCount());

    if (navArrow == m_highlightedNavArrow && haveInfoUnit == m_haveInfoUnit && infoUnit == m_infoUnit)
        return false;

    TextFormatter info;

    if (haveInfoUnit)
        GetUnitInfo(info, infoUnit);

    m_infoSink(info);

    m_highlightedNavArrow = navArrow;
    return true;
}


bool UnitPane::OnMouseUp(D2D_POINT_2F /* pt */)
{
    m_lButtonDown = false;

    if (m_selectionState == Selecting)
        m_selectionState = Selected;

    return false;
}


size_t UnitPane::UnitFromPoint(D2D_POINT_2F pt)
{
    int   column = (int) floor((pt.x - 36.0f) / 72.0f);
    int   row = (int) floor(pt.y / 75.0f);
    int   widthInChars = max(1, (int) floor((Width() - 72.0f) / 72.0f));

    if (column < 0 || column >= widthInChars || row < 0)
        return UnitCount();

    size_t unit = row * widthInChars + column + m_firstUnit;

    return  min(unit, UnitCount());
}


void UnitPane::SetInfoSink(const InfoSink & infoSink)
{
    m_infoSink = infoSink;
}


/*
CharactersPane::NavArrow CharactersPane::operator++ (CharactersPane::NavArrow & nav)
{
    assert(nav >= NavArrowBegin && nav < NavArrowEnd);

    nav = static_cast<NavArrow>(nav + 1);
    return nav;
}
*/

