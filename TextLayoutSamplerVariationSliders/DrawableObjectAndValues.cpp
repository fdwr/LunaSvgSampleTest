//----------------------------------------------------------------------------
//  Author:         Dwayne Robinson
//  History:        2015-06-19 Created
//  Description:    Generic drawable object instance with attribute values.
//----------------------------------------------------------------------------
#include "precomp.h"

#include "common.listsubstringprioritizer.h"

namespace
{              
    LOGFONT s_defaultLabelLogFont = {
        16,                 // lfHeight
        0,                  // lfWidth
        0,                  // lfEscapement
        0,                  // lfOrientation
        400,                // lfWeight
        false,              // lfItalic
        false,              // lfUnderline
        false,              // lfStrikeOut
        DEFAULT_CHARSET,    // lfCharSet
        OUT_DEFAULT_PRECIS, // lfOutPrecision
        CLIP_DEFAULT_PRECIS,// lfClipPrecision
        DEFAULT_QUALITY,    // lfQuality
        DEFAULT_PITCH,      // lfPitchAndFamily
        L"Segoe UI"         // lfFaceName[LF_FACESIZE]
    };

    static const COLORREF s_defaultLabelTextColor = 0x00FFFFFF;
    static const COLORREF s_defaultErrorTextColor = 0x004040FF;
}


const float g_axisSlidersFontSize = 30;
const float g_axisSlidersLineSpacing = 35;
const float g_axisSlidersFontX = 20;
const float g_axisSlidersSliderX1 = 160;
const float g_axisSlidersSliderWidth = 1000;
const float g_axisSlidersSliderHeight = 20;
const float g_axisSlidersSliderTagResolution = 1000;
const float g_axisSlidersSliderX2 = g_axisSlidersSliderX1 + g_axisSlidersSliderWidth;
const float g_axisSlidersButtonWidth = 20;
const float g_axisSlidersButtonHeight = 30;
const float g_axisSlidersSliderYOffset = (g_axisSlidersButtonHeight - g_axisSlidersSliderHeight) / 2;


void DrawFontAxisSliders(
    DrawingCanvas& drawingCanvas,
    DrawableObjectAndValues drawableObject
    )
{
    array_ref<uint32_t const> axisTags;
    array_ref<float const> axisCoordinates;
    drawableObject.GetValues(DrawableObjectAttributeAxisTags, OUT axisTags);
    drawableObject.GetValues(DrawableObjectAttributeAxisValues, OUT axisCoordinates);

    if (axisTags.empty())
        return;

    // Clamp size to the smaller one of the two.
    auto const tagCount = axisTags.size();

    ID2D1RenderTarget* d2dRenderTarget = drawingCanvas.GetD2DRenderTargetWeakRef();
    IDWriteFactory* dwriteFactory = drawingCanvas.GetDWriteFactoryWeakRef();
    ID2D1SolidColorBrush* d2dBrush = drawingCanvas.GetD2DBrushWeakRef();
    //d2dRenderTarget->SetTransform(&DrawableObject::identityTransform.d2d);

    ComPtr<IDWriteTextFormat> textFormat;
    dwriteFactory->CreateTextFormat(L"Segoe UI", nullptr, DWRITE_FONT_WEIGHT_NORMAL, DWRITE_FONT_STYLE_NORMAL, DWRITE_FONT_STRETCH_NORMAL, g_axisSlidersFontSize, L"en-us", OUT &textFormat);

    // Determine the starting row of the labels.
    SIZE size = drawingCanvas.GetSize();
    float topY = size.cy - (tagCount * g_axisSlidersLineSpacing);

    union Tag4CC { uint32_t i; Attribute::char8_t c[4]; };

    for (size_t i = 0; i < tagCount; ++i)
    {
        // Expand the 32-bit tag into a string, and calculate the layout bounds.
        Tag4CC const tag = { axisTags[i] };
        wchar_t const tagString[5] = { tag.c[0], tag.c[1], tag.c[2], tag.c[3] };

        float y = topY + (i * g_axisSlidersLineSpacing);
        D2D_RECT_F layoutRect = { g_axisSlidersFontX, y, g_axisSlidersSliderX1 - g_axisSlidersFontX, y + g_axisSlidersFontSize };
        d2dBrush->SetColor(ToD2DColor(0xFFFFFFFF));
        d2dRenderTarget->DrawText(tagString, 4, textFormat, layoutRect, d2dBrush);

        // Draw the slider background.
        D2D_RECT_F fillRect = { g_axisSlidersSliderX1, y + g_axisSlidersSliderYOffset, g_axisSlidersSliderX2, y + g_axisSlidersSliderYOffset + g_axisSlidersSliderHeight };
        d2dBrush->SetColor(ToD2DColor(0xFF80C080));
        d2dRenderTarget->FillRectangle(&fillRect, d2dBrush);

        // Draw the slider button.
        float axisValue = (i < axisCoordinates.size()) ? axisCoordinates[i] : 0;
        float buttonX = axisValue * (g_axisSlidersSliderWidth - g_axisSlidersButtonWidth) / g_axisSlidersSliderTagResolution;
        D2D_RECT_F buttonRect = { g_axisSlidersSliderX1 + buttonX, y, g_axisSlidersSliderX1 + buttonX + g_axisSlidersButtonWidth, y + g_axisSlidersButtonHeight };
        d2dBrush->SetColor(ToD2DColor(0xFFA0D0FF));
        d2dRenderTarget->FillRectangle(&buttonRect, d2dBrush);

        // todo: !!! draw axis values
    }
}


bool DrawableObjectAndValues::GetFontAxisSliderValue(
    DrawableObjectAndValues& drawableObject,
    DrawingCanvas& drawingCanvas,
    int32_t x,
    int32_t y,
    _Out_ uint32_t& axisIndex,
    _Out_ float& axisValue
    )
{
    array_ref<uint32_t const> axisTags;
    drawableObject.GetValues(DrawableObjectAttributeAxisTags, OUT axisTags);

    SIZE size = drawingCanvas.GetSize();
    int32_t topY = int32_t(size.cy - (axisTags.size() * g_axisSlidersLineSpacing));

    if (y < topY || y >= size.cx || x < g_axisSlidersSliderX1 - g_axisSlidersButtonWidth || x >= g_axisSlidersSliderX2 + g_axisSlidersButtonWidth)
        return false;

    axisIndex = int32_t((y - topY) / g_axisSlidersLineSpacing);
    int32_t axisValueInt = int32_t((x - g_axisSlidersSliderX1 - g_axisSlidersButtonWidth/2) * g_axisSlidersSliderTagResolution / (g_axisSlidersSliderWidth - g_axisSlidersButtonWidth));
    axisValue = float(std::min(std::max(axisValueInt, 0), 1000));
    return true;
}


void DrawableObjectAndValues::SetFontAxisValue(
    array_ref<DrawableObjectAndValues> drawableObjects,
    DrawingCanvas& drawingCanvas,
    uint32_t axisIndex,
    float newAxisValue
    )
{
    for (auto& drawableObject : drawableObjects)
    {
        // Get values and overwrite.
        array_ref<float const> axisCoordinates;
        drawableObject.GetValues(DrawableObjectAttributeAxisValues, OUT axisCoordinates);
        std::vector<float> newAxisCoordinates(axisCoordinates.begin(), axisCoordinates.end());
        newAxisCoordinates.resize(std::max(axisCoordinates.size(), axisIndex + 1));
        newAxisCoordinates[axisIndex] = newAxisValue;

        SetFontAxisValues(drawableObject, drawingCanvas, newAxisCoordinates);
    }
}


void DrawableObjectAndValues::SetFontAxisValues(
    DrawableObjectAndValues& drawableObject,
    DrawingCanvas& drawingCanvas,
    array_ref<float const> newAxisCoordinates
    )
{
    // Produce string from values.
    std::u16string axisValuesString;
    for (size_t i = 0, ci = newAxisCoordinates.size(); i < ci; ++i)
    {
        if (i != 0)
            axisValuesString.push_back(' ');
        AppendFormattedString(IN OUT axisValuesString, u"%0.3f", newAxisCoordinates[i]);
    }

    drawableObject.Set(DrawableObjectAttributeAxisValues, axisValuesString.c_str());
    drawableObject.Update(); // todo: change to invalidate
}


void DrawableObjectAndValues::Draw(
    array_ref<DrawableObjectAndValues> drawableObjects,
    DrawingCanvas& drawingCanvas,
    DX_MATRIX_3X2F const& canvasTransform
    )
{
    size_t const totalDrawableObjects = drawableObjects.size();

    HDC hdc = drawingCanvas.GetHDC();
    HBRUSH gdiDcBrush = static_cast<HBRUSH>(GetStockObject(DC_BRUSH));
    GdiFontHandle labelFont = CreateFontIndirect(&s_defaultLabelLogFont);
    SetGraphicsMode(hdc, GM_ADVANCED);

    DX_MATRIX_3X2F finalTransform;
    ComPtr<DrawingCanvas> spareDrawingCanvas;

    ////////////////////
    // Draw background colors and objects.

    for (auto& objectAndValues : drawableObjects)
    {
        if (!objectAndValues.IsVisible())
            continue;

        ////////////////////
        // Create a spare drawing canvas if we need to zoom into the pixels.

        DrawingCanvas* currentCanvas = &drawingCanvas;
        uint32_t pixelZoom = objectAndValues.GetValue(DrawableObjectAttributePixelZoom, 0);
        if (pixelZoom > 0)
        {
            if (spareDrawingCanvas == nullptr)
            {
                if (drawingCanvas.GetSharedResource(u"SpareDrawingCanvas", OUT &spareDrawingCanvas) == E_NOT_SET)
                {
                    drawingCanvas.Clone(OUT &spareDrawingCanvas);
                    drawingCanvas.SetSharedResource(u"SpareDrawingCanvas", spareDrawingCanvas.Get());
                }
                auto* renderTarget = drawingCanvas.GetDWriteBitmapRenderTargetWeakRef();
                SIZE size = {};
                renderTarget->GetSize(OUT &size);
                spareDrawingCanvas->CreateRenderTargetsOnDemand(hdc, size);
                spareDrawingCanvas->ResizeRenderTargets(size);
            }

            if (spareDrawingCanvas != nullptr)
                currentCanvas = spareDrawingCanvas;
            if (spareDrawingCanvas == nullptr)
                pixelZoom = 0;
        }

        ////////////////////
        // Calculate object position and transform.

        D2D_POINT_2F position = objectAndValues.GetValue(DrawableObjectAttributePosition, D2D_POINT_2F{0,0});
        DX_MATRIX_3X2F objectTransform = objectAndValues.transform_;

        if (pixelZoom > 0)
        {
            objectTransform.dx += objectAndValues.origin_.x;
            objectTransform.dy += objectAndValues.origin_.y;
            finalTransform = objectTransform;
        }
        else
        {
            objectTransform.dx += (objectAndValues.origin_.x + objectAndValues.objectRect_.left);
            objectTransform.dy += (objectAndValues.origin_.y + objectAndValues.objectRect_.top);
            CombineMatrix(objectTransform, canvasTransform, OUT finalTransform);
        }

        ////////////////////
        // Clear background (once per object if pixel zoom).

        if (pixelZoom > 0)
        {
            currentCanvas->ClearBackground(DrawableObject::defaultCanvasColor);
        }

        ////////////////////
        // Draw background colors.

        uint32_t bgraLayoutColor = objectAndValues.GetValue(DrawableObjectAttributeLayoutColor, DrawableObject::defaultLayoutColor);
        uint32_t bgraBackColor = objectAndValues.GetValue(DrawableObjectAttributeBackColor, DrawableObject::defaultBackColor);

        auto* d2dRenderTarget = currentCanvas->GetD2DRenderTargetWeakRef();
        auto* d2dBrush = currentCanvas->GetD2DBrushWeakRef();
        HDC currentHdc = currentCanvas->GetHDC();

        drawingCanvas.SwitchRenderingAPI(DrawingCanvas::CurrentRenderingApiD2D);
        //--d2dRenderTarget->BeginDraw();

        d2dRenderTarget->SetTransform(&finalTransform.d2d);
        if (bgraLayoutColor & 0xFF000000)
        {
            d2dBrush->SetColor(ToD2DColor(bgraLayoutColor));
            d2dRenderTarget->FillRectangle(&objectAndValues.layoutBounds_, d2dBrush);
        }

        if (bgraBackColor & 0xFF000000)
        {
            d2dBrush->SetColor(ToD2DColor(bgraBackColor));
            d2dRenderTarget->FillRectangle(&objectAndValues.contentBounds_, d2dBrush);
        }
        d2dRenderTarget->SetTransform(&DrawableObject::identityTransform.d2d);
        //--d2dRenderTarget->EndDraw();

        ////////////////////
        // Draw object.

        drawingCanvas.SwitchRenderingAPI(DrawingCanvas::CurrentRenderingApiAny);

        auto functionId = objectAndValues.GetValue(DrawableObjectAttributeFunction, DrawableObjectFunctionNop);
        if (!DrawableObject::IsD2DFunction(functionId))
        {
            drawingCanvas.SwitchRenderingAPI(DrawingCanvas::CurrentRenderingApiAny);
        }
        HRESULT hr = objectAndValues.drawableObject_->Draw(objectAndValues, *currentCanvas, position.x, position.y, finalTransform);

        if (FAILED(hr))
        {
            drawingCanvas.SwitchRenderingAPI(DrawingCanvas::CurrentRenderingApiGdi);

            std::u16string errorString;
            GetFormattedString(OUT errorString, u"Error drawing object: 0x%08X", hr);
            RECT errorRect = {LONG(position.x), LONG(position.y), LONG(position.x), LONG(position.y)};

            SetWorldTransform(currentHdc, &finalTransform.gdi);
            HFONT previousFont = SelectFont(currentHdc, labelFont);
            SetTextColor(currentHdc, s_defaultErrorTextColor);
            SetBkMode(currentHdc, TRANSPARENT);
            DrawText(currentHdc, ToWChar(errorString.c_str()), int(errorString.size()), &errorRect, DT_NOCLIP | DT_NOPREFIX);
            SelectFont(currentHdc, previousFont);
            SetWorldTransform(currentHdc, &DrawableObject::identityTransform.gdi);
        }

        if (pixelZoom > 0)
        {
            drawingCanvas.SwitchRenderingAPI(DrawingCanvas::CurrentRenderingApiGdi);

            // Stretch the new pixels to the final display.
            HDC spareHdc = spareDrawingCanvas->GetHDC();
            LONG width = LONG(objectAndValues.objectRect_.right - objectAndValues.objectRect_.left);
            LONG height = LONG(objectAndValues.objectRect_.bottom - objectAndValues.objectRect_.top);

            SetWorldTransform(hdc, &canvasTransform.gdi);
            StretchBlt(
                hdc,
                int(objectAndValues.objectRect_.left),
                int(objectAndValues.objectRect_.top),
                int(width),
                int(height),
                spareHdc,
                0,
                0,
                int(width / pixelZoom),
                int(height / pixelZoom),
                SRCCOPY
                );
            SetWorldTransform(hdc, &DrawableObject::identityTransform.gdi);
        }
    }

    ////////////////////
    // Draw labels.

    #if 0
    drawingCanvas.SwitchRenderingAPI(DrawingCanvas::CurrentRenderingApiGdi);
    SetWorldTransform(hdc, &canvasTransform.gdi);
    for (auto& objectAndValues : drawableObjects)
    {
        if (!objectAndValues.IsVisible())
            continue;

        // Draw label.
        if (!objectAndValues.label_.empty() && objectAndValues.label_.compare(u" ") != 0)
        {
            HFONT previousFont = SelectFont(hdc, labelFont);
            SetTextColor(hdc, s_defaultLabelTextColor);
            SetBkMode(hdc, TRANSPARENT);
            DrawText(hdc, ToWChar(objectAndValues.label_.data()), int(objectAndValues.label_.size()), &objectAndValues.labelRect_, DT_NOCLIP | DT_NOPREFIX);
            SelectFont(hdc, previousFont);
        }
    }
    SetWorldTransform(hdc, &DrawableObject::identityTransform.gdi);
    #endif

    if (!drawableObjects.empty())
    {
        drawingCanvas.SwitchRenderingAPI(DrawingCanvas::CurrentRenderingApiD2D);
        DrawFontAxisSliders(drawingCanvas, drawableObjects.front());
    }

    drawingCanvas.SwitchRenderingAPI(DrawingCanvas::CurrentRenderingApiAny);

    #if 0 // todo::: delete hack
    DrawingCanvas::RawPixels rawPixels = drawingCanvas.GetRawPixels();
    std::vector<Edge> edges = {{0,1},{1,2},{2,3},{3,4},{4,5},{5,6},{6,7},{7,0},  {8,9},{9,10},{10,11},{11,8},  {12,13},{13,14},{14,15},{15,12}};
    std::vector<PointI> points = {{100,100},{150,0},{250,150},{250,0},{300,100},{250,200},{150,50},{150,200},  {400,150},{600,200},{350,350},{300,250},  {400,200},{450,250},{400,275},{350,250}};
    FillPolyline(rawPixels, canvasTransform, points, IN OUT edges, 0xFFE080C0);
    //DrawLineTransformed(
    //    rawPixels,
    //    canvasTransform,
    //    100,
    //    100,
    //    100,
    //    200,
    //    0xFFE080C0
    //    );
    #endif
}


void DrawableObjectAndValues::Arrange(
    array_ref<DrawableObjectAndValues> drawableObjects,
    DrawingCanvas& drawingCanvas
    )
{
    size_t const totalDrawableObjects = drawableObjects.size();

    float y = 0;
    float defaultPadding = 8;
    float previousPadding = defaultPadding;

    GdiFontHandle font = CreateFontIndirect(&s_defaultLabelLogFont);
    HDC hdc = drawingCanvas.GetHDC();
    LONG widestLabelWidth = 0;
    float leftmostBounds = 0, rightmostBounds = 0;

    ////////////////////
    // First pass is just to get the sizes of the label and object.

    for (size_t drawableObjectIndex = 0; drawableObjectIndex < drawableObjects.size(); ++drawableObjectIndex)
    {
        auto& objectAndValues = drawableObjects[drawableObjectIndex];
        if (!objectAndValues.IsVisible())
            continue;

        ZeroStructure(objectAndValues.labelRect_);
        objectAndValues.layoutBounds_ = { 0,0, DrawableObject::defaultWidth, DrawableObject::defaultHeight };
        objectAndValues.contentBounds_ = DrawableObject::emptyRect;

        // Measure the label.
        if (!objectAndValues.label_.empty())
        {
            SIZE& labelSize = *reinterpret_cast<SIZE*>(&objectAndValues.labelRect_.right);
            HFONT previousFont = SelectFont(hdc, font);
            GetTextExtentPoint32(hdc, ToWChar(objectAndValues.label_.data()), int(objectAndValues.label_.size()), OUT &labelSize);
            SelectFont(hdc, previousFont);
            widestLabelWidth = std::max(widestLabelWidth, labelSize.cx);
        }

        // Measure the object in layout space.
        auto hr = objectAndValues.drawableObject_->GetBounds(
            objectAndValues, // attributeSource
            drawingCanvas,
            OUT objectAndValues.layoutBounds_,
            OUT objectAndValues.contentBounds_
            );

        // If measurement failed, keep bounds at least as large as will be
        // needed to display an error label.
        if (FAILED(hr))
        {
            objectAndValues.layoutBounds_.bottom = std::max(objectAndValues.layoutBounds_.bottom, float(s_defaultLabelLogFont.lfHeight));
            objectAndValues.contentBounds_ = DrawableObject::emptyRect;
        }

        // Translate layout coordinates to world coordinates.
        optional_value<D2D_POINT_2F> optionalPosition = objectAndValues.GetOptionalValue<D2D_POINT_2F>(DrawableObjectAttributePosition);
        if (!optionalPosition.empty())
        {
            TranslateRect(optionalPosition.value(), IN OUT objectAndValues.layoutBounds_);
            TranslateRect(optionalPosition.value(), IN OUT objectAndValues.contentBounds_);
        }

        // Transform both content and layout rectangles, taking the max of them both.
        // This gives the actual hit-testable bounds of the object.
        objectAndValues.transform_.Update(objectAndValues);
        auto const& transform = objectAndValues.transform_.transform.d2d;
        D2D_RECT_F objectRect;
        if (memcmp(&transform, &DrawingCanvas::g_identityMatrix.d2d, sizeof(transform)) == 0)
        {
            // Simple if identity - already transformed.
            objectRect = objectAndValues.layoutBounds_;
            UnionRect(objectAndValues.contentBounds_, IN OUT objectRect);
        }
        else
        {
            // Transform both layout and content bounds.
            TransformRect(transform, objectAndValues.layoutBounds_, OUT objectRect);
            D2D_RECT_F transformedContentBounds;
            TransformRect(transform, objectAndValues.contentBounds_, OUT transformedContentBounds);
            UnionRect(transformedContentBounds, IN OUT objectRect);
        }

        // Apply pixel zoom.
        PixelAlignRect(IN OUT objectRect);
        objectAndValues.origin_.x = -objectRect.left;
        objectAndValues.origin_.y = -objectRect.top;
        uint32_t pixelZoom = objectAndValues.GetValue(DrawableObjectAttributePixelZoom, 0);
        if (pixelZoom > 0)
        {
            objectRect.left   *= pixelZoom;
            objectRect.right  *= pixelZoom;
            objectRect.top    *= pixelZoom;
            objectRect.bottom *= pixelZoom;
        }
        objectAndValues.objectRect_ = objectRect;

        // Record largest accumulated bounds for left and right edges so far of all objects.
        leftmostBounds  = std::min(leftmostBounds,  objectRect.left);
        rightmostBounds = std::max(rightmostBounds, objectRect.right);
    }

    leftmostBounds  = floor(leftmostBounds);
    rightmostBounds = floor(rightmostBounds);

    ////////////////////
    // Second pass sets the positions for the label and object.

    for (size_t drawableObjectIndex = 0; drawableObjectIndex < drawableObjects.size(); ++drawableObjectIndex)
    {
        auto& objectAndValues = drawableObjects[drawableObjectIndex];
        if (!objectAndValues.IsVisible())
            continue;

        float x = defaultPadding;
        float labelY = y;
        float labelX = defaultPadding;

        // Skip arrangement of any explicitly positioned objects.
        if (objectAndValues.HasValue<D2D_POINT_2F>(DrawableObjectAttributePosition))
        {
            labelX = objectAndValues.objectRect_.right + defaultPadding;
            labelY = objectAndValues.objectRect_.top;
        }
        else
        {
            // Move down, leaving some padding between the previous object.
            float padding = objectAndValues.GetValue(DrawableObjectAttributePadding, defaultPadding);
            y = ceil(y + std::max(padding, previousPadding));
            previousPadding = padding;
            labelY = y;

            // The object rect is in post-transform canvas coordinates, but it is
            // not positioned yet relative to the arrangement.
            float top = objectAndValues.objectRect_.top;
            float bottom = objectAndValues.objectRect_.bottom;
            float height = bottom - top;
            float verticalAdvance = std::max(height, 0.0f);

            // Move the object origin further down if part of it extends above the top.
            if (top < 0)
            {
                y = ceil(y - top);
                verticalAdvance = bottom;
            }
            verticalAdvance = std::max(verticalAdvance, 0.0f);

            // Shift the object rect to its new position.
            x += -leftmostBounds;
            objectAndValues.objectRect_.left   += x;
            objectAndValues.objectRect_.right  += x;
            objectAndValues.objectRect_.top    += y;
            objectAndValues.objectRect_.bottom += y;

            // widestLabelWidth
            labelX = x + rightmostBounds + defaultPadding;
            objectAndValues.labelRect_.right = objectAndValues.labelRect_.left + widestLabelWidth;

            // Next object.
            y = ceil(y + verticalAdvance);
        }

        // Shift the label rect to its new position.
        objectAndValues.labelRect_.left   += int(labelX);
        objectAndValues.labelRect_.right  += int(labelX);
        objectAndValues.labelRect_.top    += int(labelY);
        objectAndValues.labelRect_.bottom += int(labelY);
    }
}


void DrawableObjectAndValues::Load(
    TextTree::NodePointer objectsNode,
    _Inout_ std::vector<DrawableObjectAndValues>& drawableObjects
    )
{
    DrawableObjectAndValues sharedDrawableObject;
    bool isFirstObject = true;

    // The node points to the beginning of the objects list.

    std::map<std::u16string, uint32_t> attributeNameMap;
    for (auto const& attribute : DrawableObject::attributeList)
    {
        attributeNameMap[attribute.name] = attribute.id;
    }
    auto attributeNameMapEnd = attributeNameMap.end();

    size_t oldDrawableObjectsSize = drawableObjects.size();

    for (TextTree::NodePointer objectNode = objectsNode.begin(), objectNodeEnd = objectsNode.end(); objectNode != objectNodeEnd; ++objectNode)
    {
        // Add another object, or fill in the shared object if first entry.
        if (!isFirstObject)
        {
            drawableObjects.push_back(sharedDrawableObject);
        }
        DrawableObjectAndValues& drawableObject = isFirstObject ? sharedDrawableObject : drawableObjects.back();
        isFirstObject = false;

        // Read all key value pairs, setting new object properties.
        for (TextTree::NodePointer node = objectNode.begin(), nodeEnd = objectNode.end(); node != nodeEnd; ++node)
        {
            std::u16string text = node.GetText();
            std::u16string value = node.GetSubvalue();

            auto nameMapResult = attributeNameMap.find(text);
            if (nameMapResult != attributeNameMapEnd)
            {
                auto id = DrawableObjectAttribute(nameMapResult->second);
                drawableObject.Set(id, value.c_str());
            }
        }
    }

    size_t newDrawableObjectsSize = drawableObjects.size();

    // Update all the newly created objects, now that their attribute strings have been set.
    for (auto& drawableObject : make_iterator_range(drawableObjects.data(), oldDrawableObjectsSize, newDrawableObjectsSize))
    {
        drawableObject.Invalidate();
        drawableObject.Update();
    }
}


void DrawableObjectAndValues::Merge(
    DrawableObjectAndValues const& overridingDrawableObject,
    _Inout_ array_ref<DrawableObjectAndValues> drawableObjects
    )
{
    for (uint32_t attributeId = 0; attributeId < countof(DrawableObject::attributeList); ++attributeId)
    {
        AttributeValue const& newValue = overridingDrawableObject.values_[attributeId];
        if (newValue.stringValue.empty())
            continue;

        for (auto& drawableObject : drawableObjects)
        {
            drawableObject.Set(DrawableObjectAttribute(attributeId), newValue.stringValue.c_str());
        }
    }

    for (auto& drawableObject : drawableObjects)
    {
        drawableObject.Invalidate();
        drawableObject.Update();
    }
}


void StoreDrawableObject(
    DrawableObjectAndValues const& drawableObject,
    _In_opt_ DrawableObjectAndValues const* sharedDrawableObject,
    TextTree::NodePointer objectNode
    )
{
    for (uint32_t attributeId = 0; attributeId < countof(DrawableObject::attributeList); ++attributeId)
    {
        AttributeValue const& value = drawableObject.values_[attributeId];
        if (value.stringValue.empty())
            continue; // Don't store empty strings in the settings file.

        if (sharedDrawableObject != nullptr
        &&  sharedDrawableObject->values_[attributeId].stringValue == value.stringValue)
        {
            continue; // Skip this attribute since it's identical to the shared object.
        }


        Attribute const& attribute = DrawableObject::attributeList[attributeId];
        objectNode.SetKeyValue(
            attribute.name,
            value.stringValue.c_str(),
            static_cast<uint32_t>(value.stringValue.size())
            );
    }
}


void DrawableObjectAndValues::Store(
    array_ref<DrawableObjectAndValues> drawableObjects,
    TextTree::NodePointer objectsNode
    )
{
    DrawableObjectAndValues sharedDrawableObject;
    bool isFirstObject = true;

    if (!drawableObjects.empty())
    {
        for (uint32_t attributeId = 0; attributeId < countof(DrawableObject::attributeList); ++attributeId)
        {
            // Find all attributes that are shared between drawable objects.
            // That way we can store them just once in the settings file.
            array_ref<char16_t> previousValueData;
            for (auto& drawableObject : drawableObjects)
            {
                array_ref<char16_t> valueData = drawableObject.values_[attributeId].stringValue;
                if (previousValueData.empty())
                {
                    // Keep track if the first time.
                    if (valueData.empty())
                        break;
                    previousValueData = valueData;
                }
                // Compare to previous value.
                else if (valueData.size() != previousValueData.size()
                      || memcmp(valueData.data(), previousValueData.data(), valueData.size_in_bytes()) != 0)
                {
                    previousValueData.clear(); // Attribute values differ.
                    break;
                }
            }

            // If the attribute had an identical value between all drawable objects,
            // copy it to the shared settings.
            if (!previousValueData.empty())
            {
                sharedDrawableObject.values_[attributeId] = drawableObjects[0].values_[attributeId];
            }
        }
    }

    auto sharedObjectNode = objectsNode.AppendChild(TextTree::Node::TypeObject, u"", 0);
    StoreDrawableObject(sharedDrawableObject, nullptr, sharedObjectNode);
    for (auto const& drawableObject : drawableObjects)
    {
        auto node = objectsNode.AppendChild(TextTree::Node::TypeObject, u"", 0);
        StoreDrawableObject(drawableObject, &sharedDrawableObject, node);
    }
}


void DrawableObjectAndValues::Update()
{
    // Create the drawable object on demand.
    if (drawableObject_ == nullptr)
    {
        auto functionId = GetValue(DrawableObjectAttributeFunction, DrawableObjectFunctionNop);
        drawableObject_ = DrawableObject::Create(functionId);
    }

    DrawableObject::GenerateLabel(*this, IN OUT label_);

    if (drawableObject_ != nullptr)
    {
        drawableObject_->Update(*this);
    }
}


void DrawableObjectAndValues::Update(
    array_ref<DrawableObjectAndValues> drawableObjects,
    array_ref<uint32_t const> drawableObjectsIndices
    )
{
    size_t const totalDrawableObjects = drawableObjects.size();
    for (uint32_t i : drawableObjectsIndices)
    {
        ThrowIf(i >= totalDrawableObjects, "Drawing object index is not consistent with internal array size!");
        drawableObjects[i].Update();
    }
}


char16_t const* DrawableObjectAndValues::GetStringValue(
    array_ref<DrawableObjectAndValues> drawableObjects,
    array_ref<uint32_t> drawableObjectIndices,
    uint32_t attributeIndex,
    _In_z_ char16_t const* defaultStringIfMixedValues
    )
{
    ThrowIf(attributeIndex >= countof(DrawableObject::attributeList), "attributeIndex is greater than attributeList.size()!");

    array_ref<char16_t const> previousString;
    char16_t const* stringValue = u"";

    for (auto drawableObjectIndex : drawableObjectIndices)
    {
        if (drawableObjectIndex >= drawableObjects.size())
            continue;

        auto const& drawableObject = drawableObjects[drawableObjectIndex];
        auto const& objectValue = drawableObject.values_[attributeIndex];
        array_ref<char16_t const> currentString = objectValue.stringValue;
        if (previousString.empty())
        {
            previousString = currentString;
            stringValue = currentString.data();
        }
        else if (currentString.size() != previousString.size()
              || memcmp(currentString.data(), previousString.data(), currentString.size_in_bytes()) != 0)
        {
            stringValue = defaultStringIfMixedValues; // e.g. u"<mixed values>"
            break;
        }
    }

    return stringValue;
}


void DrawableObjectAndValues::Set(
    array_ref<DrawableObjectAndValues> drawableObjects,
    array_ref<uint32_t const> drawableObjectsIndices,
    uint32_t attributeIndex,
    std::u16string const& newText
    )
{
    ThrowIf(attributeIndex >= countof(DrawableObject::attributeList), "attributeIndex is greater than attributeList.size()!");

    if (drawableObjectsIndices.empty())
        return;

    size_t const totalDrawableObjects = drawableObjects.size();
    uint32_t const firstMatchingIndex = drawableObjectsIndices[0];
    ThrowIf(firstMatchingIndex >= totalDrawableObjects, "drawableObjectsIndices is greater than drawableObjects.size()!");

    auto& firstObjectValue = drawableObjects[firstMatchingIndex].values_[attributeIndex];

    for (uint32_t i : drawableObjectsIndices)
    {
        ThrowIf(i >= totalDrawableObjects, "Drawing object listview is not consistent with internal array size!");

        auto& drawableObjectAndValues = drawableObjects[i];
        if (i == firstMatchingIndex)
        {
            // If the first index, set the new text and cache the numeric values too.
            firstObjectValue.Set(DrawableObject::attributeList[attributeIndex], newText.c_str());
        }
        else
        {
            // Otherwise just copy what we already have.
            auto& objectValue = drawableObjectAndValues.values_[attributeIndex];
            objectValue = firstObjectValue;
        }

        // If the drawing function is being changed, then clear the old object.
        if (attributeIndex == DrawableObjectAttributeFunction)
        {
            drawableObjectAndValues.Invalidate();
        }
    }
}


bool DrawableObjectAndValues::IsVisible() const
{
    if (drawableObject_ == nullptr)
        return false;

    auto& mutableThis = const_cast<DrawableObjectAndValues&>(*this);
    array_ref<uint8_t> data = mutableThis.values_[DrawableObjectAttributeVisibility].Get();
    if (data.empty())
        return true;
    
    return data[0] != 0;
}


HRESULT DrawableObjectAndValues::Set(DrawableObjectAttribute attributeIndex, _In_z_ char16_t const* stringValue)
{
    // Set a single attribute's value, parsing the string according to attribute data type.

    static_assert(_countof(values_) == countof(DrawableObject::attributeList), "Attribute and value arrays differ in size.");
    if (attributeIndex >= countof(values_))
        E_INVALIDARG;

    // If the drawing function is being changed, then clear the old object.
    if (attributeIndex == DrawableObjectAttributeFunction)
    {
        drawableObject_.clear();
    }

    return values_[attributeIndex].Set(DrawableObject::attributeList[attributeIndex], stringValue);
}


HRESULT DrawableObjectAndValues::Set(DrawableObjectAttribute attributeIndex, _In_z_ uint32_t value)
{
    char16_t buffer[12];
    auto stringValue = to_u16string(value, OUT buffer);
    return Set(attributeIndex, stringValue.data());
}


void DrawableObjectAndValues::Invalidate()
{
    drawableObject_.clear();
}


bool DrawableObjectAndValues::IsPointInside(float x, float y) const
{
    D2D_RECT_F unionRect = objectRect_;
    D2D_RECT_F floatLabelRect;
    ConvertRect(labelRect_, OUT floatLabelRect);
    UnionRect(floatLabelRect, IN OUT unionRect);
    return IsPointInRect(unionRect, x, y);
}


HRESULT DrawableObjectAndValues::GetString(uint32_t id, _Out_ array_ref<char16_t>& value)
{
    value.clear();

    if (id >= countof(values_))
        E_INVALIDARG;

    value = values_[id].stringValue;

    return S_OK;
}


HRESULT DrawableObjectAndValues::GetValueData(uint32_t id, _Out_ Attribute::Type& type, _Out_ array_ref<uint8_t>& value)
{
    // Return a direct ranged pointer to the data, which may be found in the
    // data field, dataArray, or stringValue, depending on attribute type.
    // This function may be called often during drawing. So except for some
    // minor input checking, it needs to just return the value quickly.

    value.clear();

    if (id >= countof(values_))
        E_INVALIDARG;

    auto& v = values_[id];
    type = v.data.type;
    value = v.Get();

    return S_OK;
}


HRESULT DrawableObjectAndValues::GetCookie(uint32_t id, _Inout_ uint32_t& cookieValue)
{
    cookieValue = 0;

    if (id >= countof(values_))
        E_INVALIDARG;

    cookieValue = values_[id].cookieValue;
    return S_OK;
}
