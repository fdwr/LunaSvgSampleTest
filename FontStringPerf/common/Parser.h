//+---------------------------------------------------------------------------
//
//  Contents:   Generic Parser
//
//  Author:     Dwayne Robinson
//
//  History:    2013-08-29   dwayner    Created
//
//----------------------------------------------------------------------------
#pragma once


class TextTreeParser;


class TextTree
{
    friend TextTreeParser;

public:
    struct Node
    {
        // What type the parsed node is.
        //
        // When reading a node, it's better to be mostly agnostic about the specific syntax
        // details. This means it does not matter whether you read JSON or XML, and it
        // removes the annoying ambiguity in XML where you may encounter files that either
        // use elements or attributes.
        //
        // When writing, the detail may matter more if you do not want to lose information.
        enum Type
        {
            TypeMask            = 0xFFFFFFF0,   // Mask off the detail

            TypeNone            = 0x00000000,   // Invalid node or empty.

            TypeValue           = 0x00000010,   // Single value with no children (JSON and XML attribute)
            TypeDetailText,                     // Document text (XML)
            TypeDetailData,                     // Data dump (XML CDATA)

            TypeKey             = 0x00000020,   // Key with 0..many children keys or values.
            TypeDetailElement,                  // Element/key name (XML).
            TypeDetailAttribute,                // Attribute of an element, containing a single value (XML,JSON). The phar in <a phar="lap"> or {phar:"lap"}.
            TypeDetailFunction,                 // Function call (JSON). The rgb in "rgb(12,34,56)".
            TypeDetailArray,                    // Array (JSON). The phar in phar[].
            TypeDetailObject,                   // Object (JSON). The phar in phar{}.

            TypeComment         = 0x00000030,   // Detail types: Comment

            TypeIgnorable       = 0x00000040,   // Detail types: Directive
            TypeDetailDirective,                // Out of band information (XML). <!DOCTYPE html>
        };

        uint32_t start;                 // Starting character offset.
        uint32_t length;                // Character count of identifier/value/data.
        uint32_t level;                 // Nesting level. The first node is zero.
        Type type;                      // Type of node.

        Type GetType() const throw();
        Type GetTypeDetail() const throw();
    };

    enum AdvanceNodeDirection
    {
        AdvanceNodeDirectionSibling,    // Move between nodes at the same level
        AdvanceNodeDirectionLineage,    // Move between nodes that are heirarchically connected (Child/Parent)
        AdvanceNodeDirectionNext,       // Next sibling at the same level
        AdvanceNodeDirectionPrevious,   // Previous sibling at the same level
        AdvanceNodeDirectionChild,      // First child of current node
        AdvanceNodeDirectionParent,     // Parent of current node
    };

public:
    void Clear();
    uint32_t GetNodeCount() const throw();

    // Returns reference that remains valid until the tree is modified.
    Node& GetNode(uint32_t nodeIndex);
    const Node& GetNode(uint32_t nodeIndex) const;

    // Returns a weak pointer that remains valid until the tree is modified. It is not nul-terminated!
    const wchar_t* GetText(const Node& node, __out uint32_t& textLength) const throw();

    // Reads the text into the string.
    void GetText(const Node& node, OUT std::wstring& text) const;

    // Advances from one node to another given the direction and count.
    // A negative count reverses direction. For example, moving Next with a
    // negative value will move Previous. Moving in (Child) with a negative
    // direction will actually move out (Parent).
    //
    // It returns false if it reaches the end of the list in either direction before
    // satisfying the requested node count. If it made no progress at all, nodeIndex
    // remains unchanged, else it returns the last node it was able to advance to.
    bool AdvanceNode(__inout uint32_t& nextNodeIndex, AdvanceNodeDirection direction, int32_t nodeCount = 1) const;

    bool AdvanceNextNode(__inout uint32_t& nodeIndex) const;
    bool AdvancePreviousNode(__inout uint32_t& nodeIndex) const;
    bool AdvanceChildNode(__inout uint32_t& nodeIndex) const;
    bool AdvanceParentNode(__inout uint32_t& nodeIndex) const;

    // Reads the text value of an attribute into the string. It will be empty if there is none.
    // The following are considered subvalues.
    //
    // JSON   - Key:value
    // JSON   - Key:"value"
    // BibTeX - Key = "value"
    // BibTeX - Key = {value}
    // XML    - <A Key="value"/>
    // XML    - <Key>value</Key>
    //
    bool GetKeySingleSubvalue(uint32_t keyNodeIndex, OUT std::wstring& text) const;

private:
    std::vector<Node> nodes_;
    std::wstring nodesText_;  // Holds decoded text for cases for numeric codes: \u03A3 or &#931; or &#x03A3.
};


class TextTreeParser // Base class, supporting either tree or iterative pull approaches.
{
public:
    enum Syntax
    {
        SyntaxUnknown,
        SyntaxJsonex,
        SyntaxBibTeX, // *No concatenation support
        SyntaxXml,
    };

    enum Options
    {
        OptionsDefault              = 0x00000000,
        OptionsUnquotedKeys         = 0x00000001,   // (JSON) Allow unquoted keys if purely alphanumeric ASCII. So phar:"lap" is legal instead of needing "phar":"lap".
        OptionsUnquotedValues       = 0x00000002,   // (JSON) Allow unquoted values if numbers or purely alphanumeric ASCII. So axis:top is legal instead of needing axis:"top".
        OptionsNoRedundantColons    = 0x00000004,   // (JSON) Allow no colons between the identifier and opening brace. So object{} is legal instead of needing object:{}.
        OptionsDiscardPureWhitespace= 0x00000008,   // (XML) Ignore spans of pure whitespace (space and CR/LF).
    };

    struct Error
    {
        uint32_t errorTextIndex;
        const wchar_t* errorMessage;
    };

public:
    static Syntax DetermineType(
        __in_ecount(textLength) const wchar_t* text,
        uint32_t textLength
        );

    TextTreeParser(
        __in_ecount(textLength) const wchar_t* text, // Pointer should be valid for the lifetime of the class.
        uint32_t textLength,
        Options options
        );

    virtual bool ReadNode(
        __out TextTree::Node& node,
        __inout std::wstring& nodeText
        );

    bool ReadNodes(__inout TextTree& textTree); // Reads string and fills an empty tree with nodes.

    uint32_t GetErrorCount();
    void GetErrorDetails(uint32_t errorIndex, __out uint32_t& errorTextIndex, __out const wchar_t** userErrorMessage);

protected:
    static void AppendCharacter(
        __inout std::wstring& nodeText,
        char32_t ch
        );

    void AdvanceCodeUnit();
    void RecedeCodeUnit();
    char32_t PeekCodeUnit();
    char32_t ReadCodeUnit();

    void ReportError(uint32_t errorTextIndex, const wchar_t* userErrorMessage);

protected:
    __field_ecount_opt(textLength_) wchar_t const* text_;   // Weak pointer should be valid for lifetime of the class.
    uint32_t textLength_;
    uint32_t textIndex_; // Current read index
    uint32_t textLevel_; // Current heirarchy level
    Options options_;
    uint32_t errorTextIndex_;
    std::vector<Error> errors_;
};


class JsonexParser : public TextTreeParser
{
    //  The parser reads pure JSON with the following relaxations for brevity/convenience:
    //  - unquoted strings for both keys and values if purely alphanumeric ASCII.
    //    mandatory quoting of keys in object literals is just silly.
    //  - redundant comma between values is optional when whitespace is sufficient.
    //  - redundant colon between key and values is optional when no whitespace.
    //  - nested colon scope. some:command:value instead of some:{command:{value}}.
    //  - named closure is allowed to find the matching scope for readers.
    //  - trailing comma is fine.
    //
    //  It advances in a single forward pass without backtracking, and needs to
    //  look ahead at most two tokens to determine a node's type.
    //
    //      Key              = KeyName : Key                            // So "a:b:c:d" is legal rather than needing "a:{b:{c:d}}"
    //                       | KeyName : Element<NoWS>Closure
    //                       | KeyName<NoWS>NestedElement<NoWS>Closure  // "a{}" is one named object, but "a {}" is a value followed by an unnamed object.
    //      NestedElement    = Array | Object | Function
    //      Object           = { Elements }
    //      Array            = [ Elements ]
    //      Function         = ( Elements )
    //      Closure          = <empty>
    //      Closure          | /Value
    //      Elements         = <empty>
    //                       | Element
    //                       | Element ElementSeparator                 // Trailing comma is intentionally legal
    //                       | Element ElementSeparator Elements
    //      NestedElement    = Array | Object | Function
    //      Element          = Value | Array | Object | Function
    //      Value            = String | UnquotedString
    //      ElementSeparator = Whitespace | Comma
    //      KeyName          = String | UnquotedString
    //      String           = ""
    //                       | " Characters "
    //      UnquotedString   = AlphanumericCharacters
    //
    //  The following nodes may be returned.
    //      Object      - { Elements }
    //                  - Value{ Elements }
    //                  - Value : { Elements }
    //      Array       - [ Elements ]
    //                  - Value[ Elements ]
    //                  - Value : [ Elements ]
    //      Function    - ( Elements )
    //                  - Value( Elements )
    //                  - Value : ( Elements )
    //      Attribute   - KeyName : Value
    //      Value       - Value

    typedef TextTreeParser Base;

public:
    JsonexParser(
        __in_ecount(textLength) const wchar_t* text,
        uint32_t textLength,
        Options options
        );

    virtual bool ReadNode(
        __out TextTree::Node& node,
        __inout std::wstring& nodeText
        );

protected:
    enum ExpectedToken
    {
        ExpectedTokenStart,
        ExpectedTokenValue,
        ExpectedTokenIdentifier,
    };

    bool ReadWord(
        __out TextTree::Node& node,
        __inout std::wstring& nodeText
        );

    void CheckClosingTag(
        __in const TextTree::Node& node,
        __in const std::wstring& nodeText
        );

    bool SkipSpaces();

    void SkipComment();

    void SkipInvalidWordCharacters();

    char32_t GetEscapeCharacter();

    void ClearAttributeOnStack();

protected:
    ExpectedToken expectedToken_;
    std::vector<TextTree::Node> nodeStack_;
};


class BibTeXParser : public TextTreeParser
{
    // Note that it does not support concatenation. So the following...
    //
    //      @string{btx = "{\textsc{Bib}\TeX}"}
    //      Title = btx # "ing"
    //
    // ...for Title would be returned as an array of three nodes ["btx" "#" "ing"].

    typedef TextTreeParser Base;
};


class XmlParser : public TextTreeParser
{
    // Note this is a pure parser, not a DTD validator or nor any other fluffiness.
    // Only syntax errors are handled. Semantic errors are the task of the higher layer.
    // It only reads the following named entities: &lt; &gt; &quot; &amp; &quot;

    typedef TextTreeParser Base;

};


class TextTreeWriter // Base class
{
public:
    enum Syntax
    {
        SyntaxUnknown   = TextTreeParser::SyntaxUnknown,
        SyntaxJsonex    = TextTreeParser::SyntaxUnknown,
        SyntaxBibTeX    = TextTreeParser::SyntaxBibTeX, // *No concatenation support
        SyntaxXml       = TextTreeParser::SyntaxXml,
    };

    enum Options
    {
        OptionsDefault              = TextTreeParser::OptionsDefault,
        OptionsUnquotedKeys         = TextTreeParser::OptionsUnquotedKeys,      // (JSON) Quote all keys. Keys are usually not quoted if purely alphanumeric ASCII.
        OptionsUnquotedValues       = TextTreeParser::OptionsUnquotedValues,    // (JSON) Quote all values. Values are usually not quoted if numbers or purely alphanumeric ASCII.
        OptionsNoRedundantColons    = TextTreeParser::OptionsNoRedundantColons, // (JSON) Quote all values. Values are usually not quoted if numbers or purely alphanumeric ASCII.
    };

public:
    TextTreeWriter(
        __in_ecount(textLength) const wchar_t* text,
        uint32_t textLength,
        Options options
        );

    // Write an entire parse tree or parse tree fragment.
    HRESULT WriteNodes(const TextTree& textTree);

    virtual HRESULT WriteNode(
        TextTree::Node::Type type,
        __in_ecount(textLength) const wchar_t* text,
        uint32_t textLength
        );

    //virtual HRESULT WriteNode(
    //    TextTree::Node& node,
    //    __in std::wstring& nodeText
    //    );

    virtual HRESULT EnterNode();

    virtual HRESULT ExitNode();

    const wchar_t* GetText(uint32_t nodeIndex, __out uint32_t& textLength); // Returns a weak pointer that remains valid until the tree is modified. It is not nul-terminated!
    void GetText(uint32_t nodeIndex, OUT std::wstring& text); // Reads the text into the string.

private:
    std::wstring text_; // Starts empty and grows with each written node.
    uint32_t textLevel_; // Current heirarchy level
    Options options_;
};


class JsonexWriter : public TextTreeWriter
{
    virtual HRESULT WriteNode(
        TextTree::Node::Type type,
        __in_ecount(textLength) const wchar_t* text,
        uint32_t textLength
        );

    virtual HRESULT EnterNode();

    virtual HRESULT ExitNode();
};


class XmlWriter : public TextTreeWriter
{
    virtual HRESULT WriteNode(
        TextTree::Node::Type type,
        __in_ecount(textLength) const wchar_t* text,
        uint32_t textLength
        );

    virtual HRESULT EnterNode();

    virtual HRESULT ExitNode();
};
