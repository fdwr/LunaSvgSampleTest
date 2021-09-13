#include "precomp.h"

#include <numeric>
#include "ShapeList.h"


array_ref<Vertex2f const> ShapeList::GetVertices() const
{
    return vertices;
}

array_ref<uint32_t const> ShapeList::GetShapeVertexIndices(ShapeList::Shape const& shape) const
{
    auto indexStart = shape.indexStart;
    auto indexCount = shape.indexCount;
    if (indexStart + indexCount < indexStart || indexStart + indexCount > shapeVertexIndices.size())
        throw std::overflow_error("Shape index out of vertex bounds");

    return make_array_ref(shapeVertexIndices.data() + indexStart, indexCount);
}

void ShapeList::AddShape(
    Shape::Type shapeType,
    array_ref<Vertex2f const> newVertices
)
{
    size_t vertexCountOld = this->vertices.size();
    size_t vertexCountAdded = newVertices.size();
    this->vertices.insert(this->vertices.end(), newVertices.begin(), newVertices.end());

    {
        size_t shapeVertexIndexCountOld = this->shapeVertexIndices.size();
        size_t shapeVertexIndexCountNew = shapeVertexIndexCountOld + vertexCountAdded;
        this->shapeVertexIndices.resize(shapeVertexIndexCountNew);
        auto it = this->shapeVertexIndices.begin();
        std::iota(it + shapeVertexIndexCountOld, it + shapeVertexIndexCountNew, vertexCountOld);
    }

    uint32_t indexStart = static_cast<uint32_t>(vertexCountOld);
    uint32_t indexCount = static_cast<uint32_t>(newVertices.size());
    this->shapes.emplace_back(Shape{ shapeType, indexStart, indexCount });
}
