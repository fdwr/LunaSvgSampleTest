class Pane
{
public:

    bool Contains(D2D1_POINT_2F pt);

    float         Width();
    float         Height();

    const D2D1_RECT_F & GetRect();
    D2D1_POINT_2F       TopLeft();
    D2D1_POINT_2F       BottomRight();

    void          Resize(D2D1_RECT_F bounds);

public:

    void PreDraw(ID2D1RenderTarget * renderTarget);
    void PostDraw(ID2D1RenderTarget * renderTarget);

protected:

    D2D1_RECT_F m_bounds;
};


struct StringData;


class FormattedPane : public Pane
{
public:

    void Update(const StringData & data);
    bool Draw(ID2D1RenderTarget * renderTarget, ID2D1Brush * textBrush);

private:

    IDWriteTextLayoutPtr        m_layout;
    D2D_POINT_2F                m_position;
};


class InfoPane;
class TextFormatter;

struct InfoSink
{
    typedef void (InfoPane::* Sink)(const TextFormatter &);

    Sink       sink;
    InfoPane * this_;

    InfoSink(InfoPane * this_ = NULL, Sink sink = NULL) : this_(this_), sink(sink) {}
    void operator() (const TextFormatter & info) {(this_->*sink)(info);}
};


class UnitPane : public Pane
{
public:

    bool Draw(ID2D1RenderTarget * renderTarget, ID2D1Brush * textBrush);

    bool OnMouseDown(D2D_POINT_2F pt);
    bool OnMouseMove(D2D_POINT_2F pt);
    bool OnMouseUp(D2D_POINT_2F pt);

    void SetInfoSink(const InfoSink & infoSink);

protected:

    UnitPane();

    virtual size_t UnitCount() = 0;
    virtual void   DrawUnit(ID2D1RenderTarget * renderTarget, ID2D1Brush * textBrush, const D2D1_RECT_F & glyphRect, size_t i) = 0;
    virtual void   GetUnitInfo(TextFormatter & /* info */, size_t /* i */) {}
    virtual void   SetSelectionInfo() {}

    size_t UnitFromPoint(D2D_POINT_2F pt);
    void   DrawSelection(ID2D1RenderTarget * renderTarget);

    enum NavArrow
    {
        NavLeft,
        NavRight,
        NavDown,
        NavUp,

        NavArrowCount,
        NoNavArrow,

        NavArrowBegin = NavLeft,
        NavArrowEnd = NavDown
    };

    enum SelectionState
    {
        NoSelection,
        Selecting,
        Selected
    };

//    NavArrow operator++ (NavArrow & nav);

    size_t                     m_firstUnit;
    ID2D1StrokeStylePtr        m_roundJoins;
    ID2D1PathGeometryPtr       m_navArrow;
    D2D1_MATRIX_3X2_F          m_navArrowPos[NavArrowCount];
    NavArrow                   m_highlightedNavArrow;
    bool                       m_haveInfoUnit;
    size_t                     m_infoUnit;
    bool                       m_lButtonDown;
    bool                       m_animating;
    DWORD                      m_animationStartTime;
    DWORD                      m_animationPeriod;
    InfoSink                   m_infoSink;
    SelectionState             m_selectionState;
    size_t                     m_selectionStart;
    size_t                     m_selectionStop;
};


class MainWindow;
struct CharSelectionSink
{
    typedef void (MainWindow::* Sink)(size_t selectionBegin, size_t selectionEnd);

    Sink         sink;
    MainWindow * this_;

    CharSelectionSink(MainWindow * this_ = NULL, Sink sink = NULL) : this_(this_), sink(sink) {}
    void operator() (size_t selectionBegin, size_t selectionEnd) {(this_->*sink)(selectionBegin, selectionEnd);}
};


class CharactersPane : public UnitPane
{
public:

    virtual void   Update(const StringData & data) = 0;
    virtual void   SetCharSelectionSink(const CharSelectionSink & sink) = 0;
};


class GlyphsPane : public UnitPane
{
public:

    virtual void   Update(const StringData & data) = 0;
};
