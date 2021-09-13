#include "LayoutSpy.h"
#include "Panes.h"
#include "LayoutRecorder.h"


void FormattedPane::Update(const StringData & data)
{
    m_layout = data.layout;
    m_position.x = data.positionX;
    m_position.y = data.positionY;
}


bool FormattedPane::Draw(ID2D1RenderTarget * renderTarget, ID2D1Brush * textBrush)
{
    renderTarget->Clear(D2D1::ColorF(D2D1::ColorF::AliceBlue));

    D2D1_MATRIX_3X2_F transform;
    renderTarget->GetTransform(&transform);

    renderTarget->DrawTextLayout(m_position, m_layout, textBrush);

    return false;
}


