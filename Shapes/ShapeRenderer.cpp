#include "precomp.h"
#include <assert.h>
#include <windows.h>
#include <d2d1.h>
#include "Common.h"
#include "Common.ArrayRef.h"
#include "ShapeList.h"
#include "ShapeUtility.h"
#include "ShapeRenderer.h"


void DrawShape(
    ID2D1RenderTarget& target,
    ShapeList const& shapeList,
    ShapeList::Shape const& shape
)
{
    array_ref<Vertex2f const> vertices = shapeList.GetVertices();
    array_ref<uint32_t const> indices  = shapeList.GetShapeVertexIndices(shape);

    switch (shape.type)
    {
    case ShapeList::Shape::Type::Curve:
        switch (shape.indexCount)
        {
        case 1: DrawPoint(target, vertices[indices[0]]); break;
        case 2: DrawLine(target, vertices[indices[0]], vertices[indices[1]]); break;
        case 3: DrawCurve3Point(target, vertices[indices[0]], vertices[indices[1]], vertices[indices[2]]); break;
        case 4: DrawCurve4Point(target, vertices[indices[0]], vertices[indices[1]], vertices[indices[2]], vertices[indices[3]]); break;
        }
        break;

    case ShapeList::Shape::Type::Circle:
        break;

    case ShapeList::Shape::Type::Square:
        break;

    default:
        assert("Account for unknown type.");
        break;
    }
}


void DrawPoint(
    ID2D1RenderTarget& target,
    Vertex2f p0
)
{

}


void DrawLine(
    ID2D1RenderTarget& target,
    Vertex2f p0,
    Vertex2f p1
)
{

}


void DrawCurve3Point(
    ID2D1RenderTarget& target,
    Vertex2f p0,
    Vertex2f p1,
    Vertex2f p2
)
{

}


void DrawCurve4Point(
    ID2D1RenderTarget& target,
    Vertex2f p0,
    Vertex2f p1,
    Vertex2f p2,
    Vertex2f p3
)
{
    // What I want:
    //  target.DrawBezier(p0, p1, p2, p3);

    // What I need to do:
    //  Why....!#$??
    ComPtr<ID2D1PathGeometry> geometry;
    ComPtr<ID2D1GeometrySink> geometrySink;
    ComPtr<ID2D1SolidColorBrush> brush;
    ComPtr<ID2D1Factory> factory;

    target.GetFactory(OUT &factory);
    IFRV(factory->CreatePathGeometry(&geometry));
    IFRV(geometry->Open(OUT &geometrySink));
    //geometrySink->SetFillMode(D2D1_FILL_MODE_WINDING);
    geometrySink->BeginFigure(reinterpret_cast<D2D1_POINT_2F&>(p0), D2D1_FIGURE_BEGIN_HOLLOW);
    geometrySink->AddBezier(
        D2D1_BEZIER_SEGMENT{
            reinterpret_cast<D2D1_POINT_2F&>(p1),
            reinterpret_cast<D2D1_POINT_2F&>(p2),
            reinterpret_cast<D2D1_POINT_2F&>(p3)
        }
    );
    geometrySink->EndFigure(D2D1_FIGURE_END_OPEN);
    geometrySink->Close();
    IFRV(target.CreateSolidColorBrush(D2D1_COLOR_F{ 0.0, 0.0, 0.0, 1.0f }, OUT &brush));

    target.DrawGeometry(geometry, brush, /*strokeWidth*/3, nullptr);
}
