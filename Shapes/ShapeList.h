#pragma once

#include <vector>
#include <stdint.h>
#include "Common.ArrayRef.h"

struct Vertex2f
{
    float x;
    float y;
};


struct ShapeList
{
    struct Shape
    {
        enum class Type : uint32_t
        {
            Curve,
            Circle,
            Square,
        };

        Type type;
        uint32_t indexStart; // First index in vertexIndices
        uint32_t indexCount; // Number of indices/vertices
    };

    std::vector<Vertex2f> vertices;
    std::vector<Shape> shapes;
    std::vector<uint32_t> shapeVertexIndices;
    std::vector<bool> selectedVertices;

    void AddShape(Shape::Type shapeType, array_ref<Vertex2f const> vertices);
    array_ref<Vertex2f const> GetVertices() const;
    array_ref<uint32_t const> GetShapeVertexIndices(Shape const& shape) const;
};
