#include <sstream>


template <typename To, typename From>
To lexical_cast(const From &);


template <>
inline std::wstring lexical_cast(const int & v)
{
    std::wstringstream stream;
    stream << v;
    return stream.str();
}


template <>
inline std::wstring lexical_cast(const UINT32 & v)
{
    std::wstringstream stream;
    stream << v;
    return stream.str();
}


template <>
inline std::wstring lexical_cast(const float & v)
{
    std::wstringstream stream;
    stream << v;
    return stream.str();
}


template <typename T>
inline T lexical_cast(const std::wstring & s)
{
    T t;
    std::wstringstream stream(s);
    stream >> t;
    return t;
}


__declspec(selectany) struct
{
    std::wstring       str; 
    DWRITE_FONT_WEIGHT value;
} 
DWriteFontWeightMapping[] =
{
    {L"Thin",        DWRITE_FONT_WEIGHT_THIN},
    {L"Extra Light", DWRITE_FONT_WEIGHT_EXTRA_LIGHT},
    {L"Light",       DWRITE_FONT_WEIGHT_LIGHT},
    {L"Regular",     DWRITE_FONT_WEIGHT_REGULAR},
    {L"Medium",      DWRITE_FONT_WEIGHT_MEDIUM},
    {L"Demi-Bold",   DWRITE_FONT_WEIGHT_DEMI_BOLD},
    {L"Bold",        DWRITE_FONT_WEIGHT_BOLD},
    {L"Extra Bold",  DWRITE_FONT_WEIGHT_EXTRA_BOLD},
    {L"Black",       DWRITE_FONT_WEIGHT_BLACK},
    {L"Extra Black", DWRITE_FONT_WEIGHT_EXTRA_BLACK}
};


template <>
inline DWRITE_FONT_WEIGHT lexical_cast(const std::wstring & s)
{
    for (size_t i = 0; i != ARRAYSIZE(DWriteFontWeightMapping); ++i)
        if (DWriteFontWeightMapping[i].str == s)
            return DWriteFontWeightMapping[i].value;

    return static_cast<DWRITE_FONT_WEIGHT>(lexical_cast<int>(s));
}


template <>
inline std::wstring lexical_cast(const DWRITE_FONT_WEIGHT & weight)
{
    for (size_t i = 0; i != ARRAYSIZE(DWriteFontWeightMapping); ++i)
        if (DWriteFontWeightMapping[i].value == weight)
            return DWriteFontWeightMapping[i].str;

    return lexical_cast<std::wstring>(static_cast<int>(weight));
}


__declspec(selectany) struct 
{
    std::wstring      str;
    DWRITE_FONT_STYLE value;
}
DWriteFontStyleMapping[] = 
{

    {L"Normal",  DWRITE_FONT_STYLE_NORMAL},
    {L"Oblique", DWRITE_FONT_STYLE_OBLIQUE}, 
    {L"Italic",  DWRITE_FONT_STYLE_ITALIC}
};


template <>
inline DWRITE_FONT_STYLE lexical_cast(const std::wstring & s)
{
    for (size_t i = 0; i != ARRAYSIZE(DWriteFontStyleMapping); ++i)
        if (DWriteFontStyleMapping[i].str == s)
            return DWriteFontStyleMapping[i].value;

    return static_cast<DWRITE_FONT_STYLE>(lexical_cast<int>(s));
}


__declspec(selectany) struct 
{
    std::wstring        str;
    DWRITE_FONT_STRETCH value;
}
DWriteFontStretchMapping[] = 
{
    {L"Ultra Condensed", DWRITE_FONT_STRETCH_ULTRA_CONDENSED},
    {L"Extra Condensed", DWRITE_FONT_STRETCH_EXTRA_CONDENSED},
    {L"Condensed",       DWRITE_FONT_STRETCH_CONDENSED},
    {L"Semi Condensed",  DWRITE_FONT_STRETCH_SEMI_CONDENSED},
    {L"Normal",          DWRITE_FONT_STRETCH_NORMAL},
    {L"Semi Expanded",   DWRITE_FONT_STRETCH_SEMI_EXPANDED},
    {L"Expanded",        DWRITE_FONT_STRETCH_EXPANDED},
    {L"Extra Expanded",  DWRITE_FONT_STRETCH_EXTRA_EXPANDED},
    {L"Ultra Expanded",  DWRITE_FONT_STRETCH_ULTRA_EXPANDED}
};


template <>
inline DWRITE_FONT_STRETCH lexical_cast(const std::wstring & s)
{
    for (size_t i = 0; i != ARRAYSIZE(DWriteFontStretchMapping); ++i)
        if (DWriteFontStretchMapping[i].str == s)
            return DWriteFontStretchMapping[i].value;

    return static_cast<DWRITE_FONT_STRETCH>(lexical_cast<int>(s));
}


__declspec(selectany) struct 
{
    std::wstring            str;
    DWRITE_MEASURING_MODE   value;
}
DWriteMeasuringModeMapping[] = 
{
    {L"Natural", DWRITE_MEASURING_MODE_NATURAL},
    {L"GDI compatible", DWRITE_MEASURING_MODE_GDI_CLASSIC},
    {L"GDI compatible natural", DWRITE_MEASURING_MODE_GDI_NATURAL}
};


template <>
inline std::wstring lexical_cast(const DWRITE_MEASURING_MODE & mode)
{
    for (size_t i = 0; i != ARRAYSIZE(DWriteMeasuringModeMapping); ++i)
        if (DWriteMeasuringModeMapping[i].value == mode)
            return DWriteMeasuringModeMapping[i].str;

    return lexical_cast<std::wstring>((int) mode);
}


__declspec(selectany) struct 
{
    std::wstring            str;
    DWRITE_FONT_SIMULATIONS value;
}
DWriteFontSimulationsMapping[] = 
{
    {L"None", DWRITE_FONT_SIMULATIONS_NONE},
    {L"Bold", DWRITE_FONT_SIMULATIONS_BOLD},
    {L"Oblique", DWRITE_FONT_SIMULATIONS_OBLIQUE},
    {L"Bold Oblique", DWRITE_FONT_SIMULATIONS_BOLD | DWRITE_FONT_SIMULATIONS_OBLIQUE}
};


template <>
inline std::wstring lexical_cast(const DWRITE_FONT_SIMULATIONS & mode)
{
    for (size_t i = 0; i != ARRAYSIZE(DWriteFontSimulationsMapping); ++i)
        if (DWriteFontSimulationsMapping[i].value == mode)
            return DWriteFontSimulationsMapping[i].str;

    return lexical_cast<std::wstring>((int) mode);
}


