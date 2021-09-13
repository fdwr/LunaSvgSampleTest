#include "LayoutSpy.h"
#include "Panes.h"
#include "LayoutRecorder.h"
#include "TextFormatter.h"
#include "PropertyList.h"
#include "LexicalCast.h"


using std::wstring;
using std::vector;
using std::hex;
using std::boolalpha;
using std::endl;


HINSTANCE g_instance;
ID2D1FactoryPtr g_d2d;
IDWriteFactoryPtr g_dwrite;


extern CharactersPane * CreateCharactersPane();
extern GlyphsPane * CreateGlyphsPane();


D2D1_COLOR_F D2DSysColor(int colorIndex)
{
    COLORREF color = GetSysColor(colorIndex);
    color = ((color & 0xFF0000) >> 16) + (color & 0x00FF00) + ((color & 0x0000FF) << 16);
    return D2D1::ColorF(color);
}


D2D_POINT_2F ClientToD2D(ID2D1RenderTarget * renderTarget, int x, int y)
{
    float dpiX, dpiY;
    renderTarget->GetDpi(&dpiX, &dpiY);

    return D2D1::Point2F(x * 96 / dpiX, y * 96 / dpiY);
}


StringData::StringData()
      : text(L"Testing"),
        maxWidth(10000.0f),
        maxHeight(10000.0f),
        fontFamily(L"Arial"),
        fontWeight(DWRITE_FONT_WEIGHT_REGULAR),
        fontStyle(DWRITE_FONT_STYLE_NORMAL),
        fontStretch(DWRITE_FONT_STRETCH_NORMAL),
        fontSize(10.0f),
        localeName(L""),
        readingDirection(DWRITE_READING_DIRECTION_LEFT_TO_RIGHT)
{
    TIF( g_dwrite->GetSystemFontCollection(&fontCollection) );
}


void StringData::ApplyLayoutFormatting(LayoutFormatting formatting, const wstring & value, DWRITE_TEXT_RANGE range)
{
    LayoutFormat format;
    format.formatting = formatting;
    format.value = value;
    format.range = range;

    layoutFormatting.push_back(format);
}


void StringData::UpdateLayout()
{
    TIF( g_dwrite->CreateTextFormat(
                            fontFamily.c_str(), 
                            fontCollection, 
                            fontWeight, 
                            fontStyle, 
                            fontStretch, 
                            fontSize, 
                            localeName.c_str(), 
                            &format
                            ) );

    TIF( format->SetFlowDirection(flowDirection) );
    TIF( format->SetLineSpacing(lineSpacing, lineHeight, baselineDistance) );
    TIF( format->SetParagraphAlignment(paragraphAlignment) );
    TIF( format->SetTextAlignment(textAlignment) );
    TIF( format->SetReadingDirection(readingDirection) );
    TIF( format->SetWordWrapping(wordWrap) );

    TIF( g_dwrite->CreateTextLayout(
                            text.c_str(), 
                            (UINT32) text.length(), 
                            format, 
                            maxWidth, 
                            maxHeight, 
                            &layout) );

    for (vector<LayoutFormat>::const_iterator i = layoutFormatting.begin(); i != layoutFormatting.end(); ++i)
    {
        switch (i->formatting)
        {
        case FontFamilyFormatting:    layout->SetFontFamilyName(i->value.c_str(), i->range); break;
        case FontSizeFormatting:      layout->SetFontSize(lexical_cast<float>(i->value), i->range); break;
        case FontWeightFormatting:    layout->SetFontWeight(lexical_cast<DWRITE_FONT_WEIGHT>(i->value), i->range); break;
        case FontStyleFormatting:     layout->SetFontStyle(lexical_cast<DWRITE_FONT_STYLE>(i->value), i->range); break;
        case FontStretchFormatting:   layout->SetFontStyle(lexical_cast<DWRITE_FONT_STYLE>(i->value), i->range); break;
        case LocaleNameFormatting:    layout->SetLocaleName(i->value.c_str(), i->range); break;
        case UnderlineFormatting:     layout->SetUnderline(lexical_cast<BOOL>(i->value), i->range); break;
        case StrikethroughFormatting: layout->SetStrikethrough(lexical_cast<BOOL>(i->value), i->range); break;
        case TypographyFormatting:    ApplyTypographyFormatting(i->value, i->range); break;
        }
    }
}


void StringData::ApplyTypographyFormatting(const wstring & features, const DWRITE_TEXT_RANGE & range)
{
    if (features.empty())
        return;     // BUGBUG: differentiate between no formatting and formatting with 0 features

    IDWriteTypographyPtr typography;
    TIF( g_dwrite->CreateTypography(&typography) );

    size_t featureBegin = 0;
    do
    {
        size_t featureEnd = features.find(L',', featureBegin);
        if (featureEnd == wstring::npos)
            featureEnd = features.size();

        wstring tag(features.substr(featureBegin, featureEnd - featureBegin));
        wstring value(L"1");

        size_t valueBegin = tag.find('=');
        if (valueBegin != wstring::npos)
        {
            value = tag.substr(valueBegin + 1);
            tag = tag.substr(0, valueBegin);
        }

        tag = (tag + L"    ").substr(0, 4);

        DWRITE_FONT_FEATURE feature;
        feature.nameTag = (DWRITE_FONT_FEATURE_TAG) DWRITE_MAKE_OPENTYPE_TAG(tag[0], tag[1], tag[2], tag[3]);
        feature.parameter = lexical_cast<UINT32>(value);
        typography->AddFontFeature(feature);

        if (featureEnd == features.size())
            break;

        featureBegin = featureEnd + 1;
    }
    while (featureBegin != features.size());

    TIF( layout->SetTypography(typography, range) );
}


void StringData::UpdateAnalysis(ID2D1RenderTarget * renderTarget)
{
    analysisResults.resize(text.size());

    TextAnalysis analysis(text, localeName, readingDirection);
    for (size_t i = 0; i != text.size(); ++i)
        analysisResults[i] = analysis[i];

    UpdateGlyphRuns(layout, renderTarget);
}


wstring StringData::FamilyNameAt(size_t i, DWRITE_TEXT_RANGE & range)
{
    UINT32 familyNameLength;
    TIF( layout->GetFontFamilyNameLength((UINT32) i, &familyNameLength, &range) );
    
    wstring familyName(familyNameLength + 1, L'\0');
    TIF( layout->GetFontFamilyName((UINT32) i, &familyName[0], familyNameLength + 1, &range) );

    familyName.resize(familyName.size() - 1);

    return familyName;
}


wstring StringData::GetConsistent(wstring (StringData::* prop)(size_t, DWRITE_TEXT_RANGE &), size_t begin, size_t end)
{
    DWRITE_TEXT_RANGE range;
    wstring           value = (this->*prop)(begin, range);

    while (end > range.startPosition + range.length)
        if ((this->*prop)(range.startPosition + range.length, range) != value)
            return L"";

    return value;
}


wstring StringData::FontSizeAt(size_t i, DWRITE_TEXT_RANGE & range)
{
    float             fontSize;
    
    TIF( layout->GetFontSize((UINT32) i, &fontSize, &range) );

    return lexical_cast<wstring>(fontSize);
}


wstring StringData::FontWeightAt(size_t i, DWRITE_TEXT_RANGE & range)
{
    DWRITE_FONT_WEIGHT weight;
    
    TIF( layout->GetFontWeight((UINT32) i, &weight, &range) );

    return lexical_cast<wstring>(weight);
}


wstring StringData::TypographyAt(size_t i, DWRITE_TEXT_RANGE & range)
{
    IDWriteTypographyPtr typography;   
    TIF( layout->GetTypography((UINT32) i, &typography, &range) );

    if (!typography)
        return L""; // BUGBUG

    wstring       features;
    const WCHAR * seperator = L"";

    UINT32 featureCount = typography->GetFontFeatureCount();
    for (UINT32 i = 0; i != featureCount; ++i)
    {
        DWRITE_FONT_FEATURE feature;
        TIF( typography->GetFontFeature(i, &feature) );

        features += (WCHAR) ((static_cast<UINT32>(feature.nameTag) & 0xFF) >> 0);
        features += (WCHAR) ((static_cast<UINT32>(feature.nameTag) & 0xFF00) >> 8);
        features += (WCHAR) ((static_cast<UINT32>(feature.nameTag) & 0xFF0000) >> 16);
        features += (WCHAR) ((static_cast<UINT32>(feature.nameTag) & 0xFF000000) >> 24);

        // BUGBUG: some feature might have some significance to 1 beyond 
        //         "feature is on" and thus we should actually show the 1
        if (feature.parameter != 1)
            features += L"=" + lexical_cast<wstring>(feature.parameter);

        features += seperator;
        seperator = L", ";
    }

    return features;
}


class InfoPane : public Pane
{
public:

    bool Draw(ID2D1RenderTarget * renderTarget, ID2D1Brush * textBrush);

    InfoSink GetSink() {return InfoSink(this, &InfoPane::SetInfo);}
    void SetInfo(const TextFormatter & info);

private:

    IDWriteTextLayoutPtr m_layout;
};


bool InfoPane::Draw(ID2D1RenderTarget * renderTarget, ID2D1Brush * textBrush)
{
    renderTarget->Clear(D2D1::ColorF(D2D1::ColorF::AntiqueWhite));

    if (m_layout)
        renderTarget->DrawTextLayout(D2D1::Point2F(), m_layout, textBrush);

    return false;
}


void InfoPane::SetInfo(const TextFormatter & info)
{
    m_layout = info.GetLayout();
}


class MainWindow
{
    friend int WINAPI wWinMain(HINSTANCE, HINSTANCE, LPWSTR, int);

private:

    MainWindow(int showCmd);

    void CreateD2DResources();
    void Update();
    void ApplyLayoutFormatting();
    void InvalidateRect(const D2D1_RECT_F & rect);

    static LRESULT CALLBACK WindowProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam);
    BOOL    OnCreate(HWND, LPCREATESTRUCT lpCreateStruct);
    void    OnDestroy(HWND);
    void    OnLButtonDown(HWND, BOOL fDoubleClick, int x, int y, UINT keyFlags);
    void    OnLButtonUp(HWND, int x, int y, UINT keyFlags);
    void    OnMouseMove(HWND, int x, int y, UINT keyFlags);
    LRESULT OnNotify(HWND, int idCtrl, NMHDR * nmhdr);
    void    OnPaint(HWND);
    void    OnSize(HWND, UINT state, int cx, int cy);

    void    OnCharSelect(size_t selectionStart, size_t selectionEnd);
    void    OnPropertyChanged(const wstring & propertyName);

    HWND                     m_window;
    ID2D1HwndRenderTargetPtr m_renderTarget;
    ID2D1SolidColorBrushPtr  m_textBrush;
    IDWriteTextLayoutPtr     m_layout;

    PropertyList *           m_propertyList;
    FormattedPane            m_formattedPane;
    CharactersPane *         m_charactersPane;
    GlyphsPane *             m_glyphsPane;
    InfoPane                 m_infoPane;
    bool                     m_haveSelectionProperties;
    DWRITE_TEXT_RANGE        m_selectionRange;

    StringData               m_data;
};


MainWindow::MainWindow(int showCmd)
      : m_window(NULL),
        m_haveSelectionProperties(false),
        m_charactersPane(CreateCharactersPane()),
        m_glyphsPane(CreateGlyphsPane())
{
    WNDCLASSEX wndclass = {0};
    wndclass.cbSize = sizeof(wndclass);
    wndclass.lpfnWndProc = WindowProc;
    wndclass.hInstance = g_instance;
    wndclass.hIcon = LoadIcon(NULL, IDI_APPLICATION);
    wndclass.hCursor = LoadCursor(NULL, IDC_ARROW);
    wndclass.lpszClassName = L"MainWindow";

    if (!RegisterClassEx(&wndclass))
        throw std::runtime_error("RegisterClass");

    if (!CreateWindow(
                    L"MainWindow",
                    L"Layout Spy",
                    WS_OVERLAPPEDWINDOW | WS_CLIPCHILDREN,
                    CW_USEDEFAULT,
                    CW_USEDEFAULT,
                    CW_USEDEFAULT,
                    CW_USEDEFAULT,
                    NULL,
                    NULL,
                    g_instance,
                    this))
    {
        throw std::runtime_error("CreateWindow");
    }

    m_propertyList = new PropertyList(m_window);
    m_propertyList->AddProperty(L"Text", L"string", L"Hello العربية World!");
    m_propertyList->AddProperty(L"Font Family", L"string", L"Gabriola");
    m_propertyList->AddProperty(L"Font Size", L"float", L"40");
    m_propertyList->AddProperty(L"Font Weight", L"|Thin|100|Extra Light|200|Light|300|Regular|400|Medium|500|Demi Bold|600|Bold|700|Extra Bold|800|Black|900|Extra Black|950|", L"Regular");
    m_propertyList->AddProperty(L"Font Style", L"|Normal|0|Oblique|1|Italic|2|", L"Normal");
    m_propertyList->AddProperty(L"Font Stretch", L"|Ultra Condensed|1|Extra Condensed|2|Condensed|3|Semi Condensed|4|Normal|5|Semi Expanded|6|Expanded|7|Extra Expanded|8|Ultra Expanded|9|", L"Normal");
    m_propertyList->AddProperty(L"Layout Width", L"float", L"400");
    m_propertyList->AddProperty(L"Layout Height", L"float", L"100");
    m_propertyList->AddProperty(L"Locale Name", L"string", L"");
    m_propertyList->AddProperty(L"Reading Direction", L"|Left to right|0|Right to left|1|", L"Left to right");
    m_propertyList->AddProperty(L"Word Wrapping", L"|Wrap|0|No wrap|1|", L"Wrap");
    m_propertyList->AddProperty(L"Paragraph Alignment", L"|Near|0|Far|1|Center|2|", L"Near");
    m_propertyList->AddProperty(L"Text Alignment", L"|Leading|0|Trailing|1|Center|2|", L"Leading");
    m_propertyList->AddProperty(L"Line Spacing", L"|Default|0|Uniform|1|", L"Default");
    m_propertyList->AddProperty(L"Line Height", L"float", L"40");
    m_propertyList->AddProperty(L"Baseline Distance", L"float", L"30");
    m_propertyList->AddProperty(L"Flow Direction", L"|Top to bottom|0|", L"Top to bottom");
    m_propertyList->AddProperty(L"X Position", L"float", L"0");
    m_propertyList->AddProperty(L"Y Position", L"float", L"0");

    InfoSink infoSink = m_infoPane.GetSink();
    m_charactersPane->SetInfoSink(infoSink);
    m_glyphsPane->SetInfoSink(infoSink);

    m_charactersPane->SetCharSelectionSink(CharSelectionSink(this, &MainWindow::OnCharSelect));

    CreateD2DResources();
    Update();

    ShowWindow(m_window, showCmd);
}


void MainWindow::CreateD2DResources()
{
    RECT client;
    GetClientRect(m_window, &client);

    D2D1_SIZE_U win32Size = D2D1::SizeU(client.right - client.left, client.bottom - client.top);

    TIF( g_d2d->CreateHwndRenderTarget(
                                D2D1::RenderTargetProperties(),
                                D2D1::HwndRenderTargetProperties(m_window, win32Size, D2D1_PRESENT_OPTIONS_RETAIN_CONTENTS),
                                &m_renderTarget) );

    TIF( m_renderTarget->CreateSolidColorBrush(
                                D2D1::ColorF(D2D1::ColorF::Black),
                                &m_textBrush) );

    D2D1_POINT_2F d2dSize = ClientToD2D(m_renderTarget, win32Size.width, win32Size.height);
    D2D1_POINT_2F propertyWindowSize = ClientToD2D(m_renderTarget, 300, 300);

    m_formattedPane.Resize(D2D1::RectF(propertyWindowSize.x, 0, d2dSize.x - 150, d2dSize.y / 3));
    m_charactersPane->Resize(D2D1::RectF(propertyWindowSize.x, m_formattedPane.BottomRight().y, d2dSize.x - 150, 2 * d2dSize.y / 3));
    m_glyphsPane->Resize(D2D1::RectF(propertyWindowSize.x, m_charactersPane->BottomRight().y, d2dSize.x - 150, d2dSize.y));
    m_infoPane.Resize(D2D1::RectF(d2dSize.x - 150, 0, d2dSize.x, d2dSize.y));

    RECT propertyListRect;
    GetWindowRect(m_propertyList->GetHWND(), &propertyListRect);
    MapWindowRect(NULL, m_window, &propertyListRect);
    propertyListRect.top = client.top;
    propertyListRect.bottom = client.bottom;
    MoveWindow(
            m_propertyList->GetHWND(), 
            propertyListRect.left, 
            propertyListRect.top,
            propertyListRect.right - propertyListRect.left,
            propertyListRect.bottom - propertyListRect.top,
            true);
}


void MainWindow::Update()
{
    m_data.text = m_propertyList->GetProperty(L"Text");
    m_data.fontFamily = m_propertyList->GetProperty(L"Font Family");
    m_data.fontSize = m_propertyList->GetProperty(L"Font Size");
    m_data.fontWeight = (DWRITE_FONT_WEIGHT) (int) m_propertyList->GetProperty(L"Font Weight");
    m_data.fontStyle = (DWRITE_FONT_STYLE) (int) m_propertyList->GetProperty(L"Font Style");
    m_data.fontStretch = (DWRITE_FONT_STRETCH) (int) m_propertyList->GetProperty(L"Font Stretch");
    m_data.maxWidth = m_propertyList->GetProperty(L"Layout Width");
    m_data.maxHeight = m_propertyList->GetProperty(L"Layout Height");
    m_data.localeName = m_propertyList->GetProperty(L"Locale Name");
    m_data.flowDirection = (DWRITE_FLOW_DIRECTION) (int) m_propertyList->GetProperty(L"Flow Direction");
    m_data.lineSpacing = (DWRITE_LINE_SPACING_METHOD) (int) m_propertyList->GetProperty(L"Line Spacing");
    m_data.lineHeight = m_propertyList->GetProperty(L"Line Height");
    m_data.baselineDistance = m_propertyList->GetProperty(L"Baseline Distance");
    m_data.paragraphAlignment = (DWRITE_PARAGRAPH_ALIGNMENT) (int) m_propertyList->GetProperty(L"Paragraph Alignment");
    m_data.textAlignment = (DWRITE_TEXT_ALIGNMENT) (int) m_propertyList->GetProperty(L"Text Alignment");
    m_data.readingDirection = (DWRITE_READING_DIRECTION) (int) m_propertyList->GetProperty(L"Reading Direction");
    m_data.wordWrap = (DWRITE_WORD_WRAPPING) (int) m_propertyList->GetProperty(L"Word Wrapping");
    m_data.positionX = m_propertyList->GetProperty(L"X Position");
    m_data.positionY = m_propertyList->GetProperty(L"Y Position");

    m_data.UpdateLayout();    
    m_data.UpdateAnalysis(m_renderTarget);

    m_formattedPane.Update(m_data);
    m_charactersPane->Update(m_data);
    m_glyphsPane->Update(m_data);

    InvalidateRect(m_formattedPane.GetRect());
    InvalidateRect(m_charactersPane->GetRect());
    InvalidateRect(m_glyphsPane->GetRect());
}


void MainWindow::InvalidateRect(const D2D1_RECT_F & d2drect)
{
    float dpiX, dpiY;
    m_renderTarget->GetDpi(&dpiX, &dpiY);

    RECT win32rect;
    win32rect.left = (int) (d2drect.left * dpiX / 96);
    win32rect.top = (int) (d2drect.top * dpiY / 96);
    win32rect.right = (int) (d2drect.right * dpiX / 96);
    win32rect.bottom = (int) (d2drect.bottom * dpiY / 96);

    RECT rect;
    GetClientRect(m_window, &rect);

//    ::InvalidateRect(m_window, &win32rect, false);
    ::InvalidateRect(m_window, NULL, false);
}


void MainWindow::OnCharSelect(size_t selectionStart, size_t selectionEnd)
{
    if (!m_haveSelectionProperties)
    {
        m_propertyList->AddPropertyGroup(L"Selection Properties");
        m_propertyList->AddProperty(L"Selection\\Font Family", L"string", m_data.fontFamily);
        m_propertyList->AddProperty(L"Selection\\Font Size", L"float", L"40");
        m_propertyList->AddProperty(L"Selection\\Font Weight", L"|Thin|100|Extra Light|200|Light|300|Regular|400|Medium|500|Demi Bold|600|Bold|700|Extra Bold|800|Black|900|Extra Black|950|", L"Regular");
        m_propertyList->AddProperty(L"Selection\\Font Style", L"|Normal|0|Oblique|1|Italic|2|", L"Normal");
        m_propertyList->AddProperty(L"Selection\\Font Stretch", L"|Ultra Condensed|1|Extra Condensed|2|Condensed|3|Semi Condensed|4|Normal|5|Semi Expanded|6|Expanded|7|Extra Expanded|8|Ultra Expanded|9|", L"Normal");
        m_propertyList->AddProperty(L"Selection\\Locale Name", L"string", L"");
        m_propertyList->AddProperty(L"Selection\\Underline", L"|false|0|true|1|", L"false");
        m_propertyList->AddProperty(L"Selection\\Strikethrough", L"|false|0|true|1|", L"false");
        m_propertyList->AddProperty(L"Selection\\Typography", L"string", L"");

        m_haveSelectionProperties = true;
    }

    m_propertyList->SetProperty(L"Selection\\Font Family", m_data.GetConsistent(&StringData::FamilyNameAt, selectionStart, selectionEnd));
    m_propertyList->SetProperty(L"Selection\\Font Size",   m_data.GetConsistent(&StringData::FontSizeAt, selectionStart, selectionEnd));
    m_propertyList->SetProperty(L"Selection\\Font Weight", m_data.GetConsistent(&StringData::FontWeightAt, selectionStart, selectionEnd));
    m_propertyList->SetProperty(L"Selection\\Typography",  m_data.GetConsistent(&StringData::TypographyAt, selectionStart, selectionEnd));

    m_selectionRange.startPosition = (UINT32) selectionStart;
    m_selectionRange.length = (UINT32) (selectionEnd - selectionStart);
}


void MainWindow::OnPropertyChanged(const wstring & propertyName)
{
    if (propertyName.substr(0, 10) == L"Selection\\")
    {
        static const struct
        {
            wstring                      propertyName;
            StringData::LayoutFormatting formatting;
        }
        mapping[] = 
        {
            {L"Selection\\Font Family", StringData::FontFamilyFormatting},
            {L"Selection\\Font Size", StringData::FontSizeFormatting},
            {L"Selection\\Font Weight", StringData::FontWeightFormatting},
            {L"Selection\\Font Style", StringData::FontStyleFormatting},
            {L"Selection\\Font Stretch", StringData::FontStretchFormatting},
            {L"Selection\\Locale Name", StringData::LocaleNameFormatting},
            {L"Selection\\Underline", StringData::UnderlineFormatting},
            {L"Selection\\Strikethrough", StringData::StrikethroughFormatting},
            {L"Selection\\Typography", StringData::TypographyFormatting}
        };

        for (size_t i = 0; i != ARRAYSIZE(mapping); ++i)
            if (propertyName == mapping[i].propertyName)
                m_data.ApplyLayoutFormatting(
                                mapping[i].formatting,
                                m_propertyList->GetProperty(propertyName),
                                m_selectionRange);
    }

    Update();
}


LRESULT CALLBACK MainWindow::WindowProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    if (message == WM_NCCREATE)
        SetWindowLongPtr(hWnd, GWLP_USERDATA, (LONG_PTR) ((CREATESTRUCT *) lParam)->lpCreateParams);

    MainWindow * this_ = (MainWindow *) GetWindowLongPtr(hWnd, GWLP_USERDATA);
    
    try
    {
        if (this_)
        {
            switch (message)
            {
                HANDLE_MSG(hWnd, WM_CREATE,      this_->OnCreate);
                HANDLE_MSG(hWnd, WM_DESTROY,     this_->OnDestroy);
                HANDLE_MSG(hWnd, WM_LBUTTONDOWN, this_->OnLButtonDown);
                HANDLE_MSG(hWnd, WM_LBUTTONUP,   this_->OnLButtonUp);
                HANDLE_MSG(hWnd, WM_MOUSEMOVE,   this_->OnMouseMove);
                HANDLE_MSG(hWnd, WM_NOTIFY,      this_->OnNotify);
                HANDLE_MSG(hWnd, WM_PAINT,       this_->OnPaint);
                HANDLE_MSG(hWnd, WM_SIZE,        this_->OnSize);
            }
        }
    }
    catch (const std::exception & e)
    {
        OutputDebugStringA("Unhandled exception ");
        OutputDebugStringA(e.what());
        OutputDebugStringA("\r\n");

        MessageBoxA(NULL, e.what(), "LayoutSpy - Unhandled exception", MB_ICONERROR | MB_OK);
        ExitProcess(0);
    }

    return DefWindowProc(hWnd, message, wParam, lParam);
}


BOOL MainWindow::OnCreate(HWND hWnd, LPCREATESTRUCT /* lpCreateStruct */)
{
    m_window = hWnd;

    return true;
}


void MainWindow::OnDestroy(HWND)
{
    PostQuitMessage(0);
}


void MainWindow::OnLButtonDown(HWND, BOOL /* fDoubleClick */, int x, int y, UINT /* keyFlags */)
{
    D2D1_POINT_2F pt = ClientToD2D(m_renderTarget, x, y);

    if (m_charactersPane->Contains(pt))
        if (m_charactersPane->OnMouseDown(pt - m_charactersPane->TopLeft()))
            InvalidateRect(m_charactersPane->GetRect());

    if (m_glyphsPane->Contains(pt))
        if (m_glyphsPane->OnMouseDown(pt - m_glyphsPane->TopLeft()))
            InvalidateRect(m_glyphsPane->GetRect());
}


void MainWindow::OnLButtonUp(HWND, int x, int y, UINT /* keyFlags */)
{
    D2D1_POINT_2F pt = ClientToD2D(m_renderTarget, x, y);

    if (m_charactersPane->Contains(pt))
        if (m_charactersPane->OnMouseUp(pt - m_charactersPane->TopLeft()))
            InvalidateRect(m_charactersPane->GetRect());

    if (m_glyphsPane->Contains(pt))
        if (m_glyphsPane->OnMouseUp(pt - m_glyphsPane->TopLeft()))
            InvalidateRect(m_glyphsPane->GetRect());
}


void MainWindow::OnMouseMove(HWND, int x, int y, UINT /* keyFlags */)
{
    D2D1_POINT_2F pt = ClientToD2D(m_renderTarget, x, y);

    if (m_charactersPane->Contains(pt))
    {
        if (m_charactersPane->OnMouseMove(pt - m_charactersPane->TopLeft()))
            InvalidateRect(m_charactersPane->GetRect());
    }
    else if (m_glyphsPane->Contains(pt))
    {
        if (m_glyphsPane->OnMouseMove(pt - m_glyphsPane->TopLeft()))
            InvalidateRect(m_glyphsPane->GetRect());
    }
    else
    {
        m_infoPane.SetInfo(TextFormatter());
        InvalidateRect(m_infoPane.GetRect());
    }
}


LRESULT MainWindow::OnNotify(HWND, int /* idCtrl */, NMHDR * nmhdr)
{
    if (nmhdr->hwndFrom == m_propertyList->GetHWND())
        if (nmhdr->code == PropertyList::Notifications::PropertyChanged)
            OnPropertyChanged(reinterpret_cast<PropertyList::Notifications::PropertyChange *>(nmhdr)->propertyName);

    return 0;
}


void MainWindow::OnPaint(HWND)
{
    // GDI/User content need Begin/EndPaint to do thier thing properly
    PAINTSTRUCT ps;
    BeginPaint(m_window, &ps);

    m_renderTarget->BeginDraw();

    m_formattedPane.PreDraw(m_renderTarget);  
    if(m_formattedPane.Draw(m_renderTarget, m_textBrush))
        InvalidateRect(m_formattedPane.GetRect());
    m_formattedPane.PostDraw(m_renderTarget);  

    m_charactersPane->PreDraw(m_renderTarget);  
    if (m_charactersPane->Draw(m_renderTarget, m_textBrush))
        InvalidateRect(m_charactersPane->GetRect());
    m_charactersPane->PostDraw(m_renderTarget);  

    m_glyphsPane->PreDraw(m_renderTarget);  
    if (m_glyphsPane->Draw(m_renderTarget, m_textBrush))
        InvalidateRect(m_charactersPane->GetRect());
    m_glyphsPane->PostDraw(m_renderTarget);  

    m_infoPane.PreDraw(m_renderTarget);  
    if (m_infoPane.Draw(m_renderTarget, m_textBrush))
        InvalidateRect(m_infoPane.GetRect());
    m_infoPane.PostDraw(m_renderTarget);  

    HRESULT hr = m_renderTarget->EndDraw();
    
    if (hr == D2DERR_RECREATE_TARGET)
    {
        CreateD2DResources();
        return;
    }

    TIF( hr );

    EndPaint(m_window, &ps);
}


void MainWindow::OnSize(HWND, UINT state, int cx, int cy)
{
    if (state == SIZE_MINIMIZED)
        return;

    float dpiX;
    float dpiY;
    m_renderTarget->GetDpi(&dpiX, &dpiY);

    D2D1_SIZE_F newSize = D2D1::SizeF((float) cx, (float) cy);
    newSize.width *= 96.0f / dpiX;
    newSize.height *= 96.0f / dpiY;

    if (newSize == m_renderTarget->GetSize())
        return;

    CreateD2DResources();
}


int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE, LPWSTR, int showCmd)
{
    g_instance = hInstance;

    MSG msg;

    try
    {
        INITCOMMONCONTROLSEX icex;
        icex.dwSize = sizeof(INITCOMMONCONTROLSEX);
        icex.dwICC  = ICC_LISTVIEW_CLASSES;
        InitCommonControlsEx(&icex); 

        TIF( D2D1CreateFactory(D2D1_FACTORY_TYPE_SINGLE_THREADED, &g_d2d) );
        TIF( DWriteCreateFactory(DWRITE_FACTORY_TYPE_SHARED, __uuidof(IDWriteFactory), (IUnknown **) &g_dwrite) );

        MainWindow mainWindow(showCmd);

        while (GetMessage(&msg, NULL, 0, 0))
        {
            TranslateMessage(&msg);
            DispatchMessage(&msg);
        }
    }
    catch (const std::exception & e)
    {
        MessageBoxA(NULL, e.what(), "LayoutSpy - Unhandled exception", MB_ICONERROR | MB_OK);
        msg.wParam = 0;
    }

    return (int) msg.wParam;
}