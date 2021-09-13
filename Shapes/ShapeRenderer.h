#pragma once


void DrawShape(
    ID2D1RenderTarget& target,
    ShapeList const& shapeList,
    ShapeList::Shape const& shape
);

void DrawPoint(
    ID2D1RenderTarget& target,
    Vertex2f p0
);

void DrawLine(
    ID2D1RenderTarget& target,
    Vertex2f p0,
    Vertex2f p1
);

void DrawCurve3Point(
    ID2D1RenderTarget& target,
    Vertex2f p0,
    Vertex2f p1,
    Vertex2f p2
);

void DrawCurve4Point(
    ID2D1RenderTarget& target,
    Vertex2f p0,
    Vertex2f p1,
    Vertex2f p2,
    Vertex2f p3
);
