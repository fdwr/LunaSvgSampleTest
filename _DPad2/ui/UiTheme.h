//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   Visual style information.
//
//----------------------------------------------------------------------------
#pragma once

struct IWICBitmapSource;
struct IDWriteTextFormat;
class InlineImage;

// Encapsulates all the needed information for the current theme, including
// the atlas texture, part sizes/locations, and text format.
//
// There is one atlas image for all controls, which is divided into multiple
// parts. The coordinates for each of part is identified and retrieved by
// the control at drawing and positioning/measuring time.
//
// In addition to coordinates in the atlas image, image parts can also include
// margins (distance from the edges of the control to any text they display)
// and padding (distance from the edges to any children they contain).
//
// The theme also holds onto multiple identified TextFormat's. Each control
// can have its own formatting properties, like font family, size, and
// alignment.
//
class UiTheme : public RefCountBase
{
public:
    typedef unsigned int ThemePartId;

    enum FailureBehavior
    {
        FailureBehaviorDefault,
        FailureBehaviorNull,
        FailureBehaviorError
    };

    // These are used in the resource section.
    // For the sake of the demo, we'll just use a simple format,
    // rather than parsing a textual syntax like XML.
    struct PartIdCount
    {
        UINT16 id;
        UINT16 count;
    };

    struct SmallPosition
    {
        INT16 x,y,w,h;
    };

    template <typename ActualType, typename EnumType>
    class SmallEnum
    {
        ActualType value_;

    public:
        inline operator EnumType() const throw()
        {
            return static_cast<EnumType>(value_);
        }

        inline EnumType operator=(EnumType value) throw()
        {
            return value_ = static_cast<ActualType>(value);
        }
    };

    struct TextFormatInfo
    {
        UINT16 id;
        UINT16 size;
        SmallEnum<UINT16, DWRITE_FONT_WEIGHT> weight;
        SmallEnum<UINT16, DWRITE_FONT_STYLE> slope;
        SmallEnum<UINT16, DWRITE_FONT_STRETCH> stretch;
        SmallEnum<UINT16, DWRITE_TEXT_ALIGNMENT> textAlignment;
        SmallEnum<UINT16, DWRITE_PARAGRAPH_ALIGNMENT> paragraphAlignment;
        SmallEnum<UINT16, DWRITE_WORD_WRAPPING> lineWrapping;
        wchar_t fontFamilyName[1];
    };

private:
    // Global atlas texture
    ComPtr<IWICBitmapSource> image_;

    std::vector<Position> imageParts_;
    typedef std::map<ThemePartId, unsigned int> ImagePartsMap;
    ImagePartsMap imagePartsMap_;

    std::vector<ComPtr<IDWriteTextFormat> > textFormats_;
    typedef std::map<ThemePartId, unsigned int> TextFormatsMap;
    TextFormatsMap textFormatsMap_;

public:
    // Retrieves the main atlas image.
    inline IWICBitmapSource* GetImage()
    {
        return image_;
    }

    // Sets the main atlas image of all the UI control's.
    void SetImage(
        IWICBitmapSource* image
        );

    // Loads at atlas image from an executable resource.
    HRESULT LoadImageFromResource(
        const wchar_t* resourceName,
        const wchar_t* resourceType,
        IWICImagingFactory* wicFactory
        );

    // Loads an image resource from the executable into the given bitmap.
    static HRESULT LoadImageFromResource(
        const wchar_t* resourceName,
        const wchar_t* resourceType,
        IWICImagingFactory* wicFactory,
        __out ComPtr<IWICBitmapSource>& bitmap
        );

    // Loads an image resource from the executable into the current theme.
    HRESULT LoadImagePartsFromResource(
        const wchar_t* resourceName,
        const wchar_t* resourceType
        );

    // Adds an identified image part to the current theme,
    // holding the source coordinates in the atlas image.
    void AddImagePart(
        ThemePartId partId,
        const Position& rect
        );

    // Adds contiguous image parts to the current theme.
    void AddImageParts(
        ThemePartId partId,
        __in_ecount(rectsCount) const Position* rects,
        size_t rectsCount
        );

    // Retrieve an array of contiguous image parts by ID.
    // This is typically used for drawing the nine-grid them
    // of a whole UI control.
    __ecount(partCount) __maybenull const Position* GetImageParts(
        ThemePartId partId,
        size_t partCount = 3,
        FailureBehavior failureBehavior = FailureBehaviorDefault
        ) const;

    // Retrieve a single image part in the atlas image.
    // This is typically needed calculating the margin or
    // padding of a control. If the part does not exist,
    // it will return an empty rect.
    const Position& GetImagePart(
        ThemePartId partId
        ) const;

    // Given a rect, it returns a shrunken version, deflated by the amount
    // from the given partId's margin/padding.
    Position GetDeflatedImagePart(
        const Position& position,
        ThemePartId partId
        ) const;

    // Given a rect, it returns an enlarged version, inflated by the amount
    // from the given partId's margin/padding.
    Position GetInflatedImagePart(
        const Position& position,
        ThemePartId partId
        ) const;

    // Given a rect and partId, it returns the minimum size of the two.
    // This is useful for limiting a control to a given size.
    // The x,y offset is unaffacted.
    Position UiTheme::GetMinImagePart(
        const Position& position,
        ThemePartId partId
        ) const;

    // Given a rect and partId, it returns the maximum size of the two.
    // This is useful for preventing a control from being smaller than
    // a certain size. The x,y offset is unaffacted.
    Position UiTheme::GetMaxImagePart(
        const Position& position,
        ThemePartId partId
        ) const;

    // Adds the text formats found in the executable resource.
    HRESULT LoadTextFormatsFromResource(
        const wchar_t* resourceName,
        const wchar_t* resourceType,
        IDWriteFactory* dwriteFactory,
        DWRITE_READING_DIRECTION readingDirection,
        wchar_t const* locale
        );

    // Adds the identified text format to the theme.
    void AddTextFormat(
        ThemePartId formatId,
        IDWriteTextFormat* textFormat
        );

    // Retrieves the text format matching the id.
    // If the theme has no matching text format,
    // it returns the default one.
    // This is a weak reference that exists as long
    // as the theme.
    IDWriteTextFormat* GetTextFormat(
        ThemePartId formatId,
        FailureBehavior failureBehavior = FailureBehaviorDefault
        );

    // Creates a layout using the given theme's text format.
    void CreateTextLayout(
        IDWriteFactory* dwriteFactory,
        __in_z_opt const wchar_t* text,
        ThemePartId formatId,
        const Position& rect,
        __out ComPtr<IDWriteTextLayout>& textLayout
        );

    // Applies an inline object to the previously created layout,
    // searching for the Unicode object replacement character
    // in the string (U+FFFC). If the text is null, it will just
    // apply the image at the first text position of the layout.
    static void ApplyImageOverText(
        __maybenull InlineImage* image,
        __in_z_opt const wchar_t* text,
        __notnull IDWriteTextLayout* textLayout
        );

private:
    void AddImageParts(
        ThemePartId partId,
        __in_ecount(rectsCount) const SmallPosition* rects,
        size_t rectsCount
        );
};
