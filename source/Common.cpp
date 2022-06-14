#include "precomp.h"
#include "Common.h"

void ComputeInverseMatrix(
    _In_  Matrix3x2f const& matrix,
    _Out_ Matrix3x2f& result
)
{
    assert(&matrix != &result);

    float invdet = 1.f / GetDeterminant(matrix);
    result.xx =  matrix.yy * invdet;
    result.xy = -matrix.xy * invdet;
    result.yx = -matrix.yx * invdet;
    result.yy =  matrix.xx * invdet;
    result.dx = (matrix.yx * matrix.dy - matrix.dx * matrix.yy) * invdet;
    result.dy = (matrix.dx * matrix.xy - matrix.xx * matrix.dy) * invdet;
}


#if 0
// In and out rects are allowed to be the same variable.
void TransformRect(Matrix3x2f const& transform, D2D_RECT_F const& rectIn, _Out_ D2D_RECT_F& rectOut)
{
    // Equivalent to calling D2D1::Matrix3x2f.TransformPoint on each
    // corner of the rect, but half the multiplies and additions.

    float leftX = rectIn.left * transform._11;
    float leftY = rectIn.left * transform._12;
    float rightX = rectIn.right * transform._11;
    float rightY = rectIn.right * transform._12;
    float topX = rectIn.top * transform._21;
    float topY = rectIn.top * transform._22;
    float bottomX = rectIn.bottom * transform._21;
    float bottomY = rectIn.bottom * transform._22;

    D2D_POINT_2F points[4];
    points[0].x = leftX + topX;
    points[0].y = leftY + topY;
    points[1].x = rightX + topX;
    points[1].y = rightY + topY;
    points[2].x = leftX + bottomX;
    points[2].y = leftY + bottomY;
    points[3].x = rightX + bottomX;
    points[3].y = rightY + bottomY;

    rectOut.left = rectOut.right = points[0].x;
    rectOut.top = rectOut.bottom = points[0].y;
    for (uint32_t i = 1; i < 4; ++i)
    {
        if (points[i].x < rectOut.left)   rectOut.left = points[i].x;
        if (points[i].x > rectOut.right)  rectOut.right = points[i].x;
        if (points[i].y < rectOut.top)    rectOut.top = points[i].y;
        if (points[i].y > rectOut.bottom) rectOut.bottom = points[i].y;
    }
    rectOut.left   += transform._31;
    rectOut.right  += transform._31;
    rectOut.top    += transform._32;
    rectOut.bottom += transform._32;
}
#endif


float GetDeterminant(_In_ Matrix3x2f const& matrix)
{
    return matrix.xx * matrix.yy - matrix.xy * matrix.yx;
}
