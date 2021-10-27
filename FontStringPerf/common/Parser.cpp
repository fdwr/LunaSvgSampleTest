//+---------------------------------------------------------------------------
//
//  Contents:   Parser
//
//  Author:     Dwayne Robinson
//
//  History:    2013-08-29   dwayner    Created
//
//----------------------------------------------------------------------------
#include "precomp.h"


uint32_t TextTree::GetNodeCount() const throw()
{
    return static_cast<uint32_t>(nodes_.size());
}


void TextTree::Clear()
{
    // Reset the tree and release all memory.
    nodes_.clear();
    nodes_.shrink_to_fit();
    nodesText_.clear();
    nodesText_.shrink_to_fit();
}


TextTree::Node& TextTree::GetNode(uint32_t nodeIndex)
{
    assert(nodeIndex < nodes_.size());
    if (nodeIndex > nodes_.size())
    {
        return *static_cast<Node*>(nullptr); // Force AV.
    }
    return nodes_[nodeIndex];
}


const TextTree::Node& TextTree::GetNode(uint32_t nodeIndex) const
{
    assert(nodeIndex < nodes_.size());
    if (nodeIndex > nodes_.size())
    {
        return *static_cast<Node*>(nullptr); // Force AV.
    }
    return nodes_[nodeIndex];
}


const wchar_t* TextTree::GetText(const Node& node, __out uint32_t& textLength) const throw()
{
    assert(size_t(&node - nodes_.data()) < nodes_.size());
    textLength = node.length;
    return &nodesText_[node.start];
}


void TextTree::GetText(const Node& node, OUT std::wstring& text) const
{
    assert(size_t(&node - nodes_.data()) < nodes_.size());
    auto textPointer = &nodesText_[node.start];
    text.assign(textPointer, textPointer + node.length);
}


bool TextTree::AdvanceNode(
    __inout uint32_t& nextNodeIndex,
    AdvanceNodeDirection direction,
    int32_t nodeCount
    ) const
{
    if (nodeCount == 0)
        return true; // Successfully advanced zero nodes.

    // Resolve the specific directions into a generic direction plus count, negated if needed.
    switch (direction)
    {
    case AdvanceNodeDirectionSibling:   break;
    case AdvanceNodeDirectionLineage:   break;
    case AdvanceNodeDirectionNext:      direction = AdvanceNodeDirectionSibling; break;
    case AdvanceNodeDirectionPrevious:  direction = AdvanceNodeDirectionSibling; nodeCount = -nodeCount; break;
    case AdvanceNodeDirectionChild:     direction = AdvanceNodeDirectionLineage; break;
    case AdvanceNodeDirectionParent:    direction = AdvanceNodeDirectionLineage; nodeCount = -nodeCount; break;
    default:                            return false; // Do nothing for unknown enumerant.
    }

    auto nodeIndex = nextNodeIndex;
    auto nodesCount = nodes_.size();
    auto startingNodeLevel = 0u;
    if (nodeIndex < nodesCount)
    {
        startingNodeLevel = GetNode(nodeIndex).level;
    }
    else if (nodeCount > 0)
    {
        return false; // Cannot move past end of list.
    }
    else // Clamp the count and leave level = 0.
    {
        nodeIndex = nodesCount;
    }

    if (nodeCount > 0) // Search forward.
    {
        nodeIndex++;
        while (nodeIndex < nodesCount)
        {
            auto nodeLevel = nodes_[nodeIndex].level;
            bool isMatch = false;
            // Look for sibling at same level or child at lower level.
            switch (direction)
            {
            case AdvanceNodeDirectionSibling:
                if (nodeLevel < startingNodeLevel)
                    return false;
                isMatch = (nodeLevel == startingNodeLevel);
                break;
            case AdvanceNodeDirectionLineage:
                isMatch = (nodeLevel < startingNodeLevel);
                break;
            }
            if (isMatch)
            {
                // Count another match and update the node index.
                nextNodeIndex = nodeIndex;
                if (--nodeCount <= 0)
                {
                    return true;
                }
            }
            ++nodeIndex;
        }
    }
    else // Search backward.
    {
        while (nodeIndex > 0)
        {
            --nodeIndex;
            auto nodeLevel = nodes_[nodeIndex].level;
            bool isMatch = false;
            switch (direction)
            {
            case AdvanceNodeDirectionSibling:
                if (nodeLevel < startingNodeLevel)
                    return false;
                isMatch = (nodeLevel == startingNodeLevel);
                break;
            case AdvanceNodeDirectionLineage:
                isMatch = (nodeLevel > startingNodeLevel);
                break;
            }
            if (isMatch)
            {
                nextNodeIndex = nodeIndex;
                if (++nodeCount >= 0)
                {
                    return true;
                }
            }
        }
    }

    return false;
}


bool TextTree::AdvanceNextNode(__inout uint32_t& nodeIndex) const
{
    return AdvanceNode(IN OUT nodeIndex, AdvanceNodeDirectionNext);
}


bool TextTree::AdvancePreviousNode(__inout uint32_t& nodeIndex) const
{
    return AdvanceNode(IN OUT nodeIndex, AdvanceNodeDirectionPrevious);
}


bool TextTree::AdvanceChildNode(__inout uint32_t& nodeIndex) const
{
    return AdvanceNode(IN OUT nodeIndex, AdvanceNodeDirectionChild);
}


bool TextTree::AdvanceParentNode(__inout uint32_t& nodeIndex) const
{
    return AdvanceNode(IN OUT nodeIndex, AdvanceNodeDirectionParent);
}


bool TextTree::GetKeySingleSubvalue(uint32_t keyNodeIndex, OUT std::wstring& text) const
{
    assert(keyNodeIndex < nodes_.size());

    // Reads the subvalue of a key, expecting exactly one. So an XML attribute
    // with no value (which is not technically valid, but you can see variants
    // of it in older HTML) would return false, along with any keys including
    // multiple values.
    //
    // True:    Phar:"lap"
    //          Phar="lap"
    //          Phar(lap)
    //
    // False:   Phar(lap,horse)
    //          LapTimes:[1,2].
    //          <Element Phar>
    //
    // The node index passed is for the key, not the value.

    text.clear();
    auto nodesCount = nodes_.size();
    auto nodeIndex = keyNodeIndex;
    if (keyNodeIndex >= nodesCount)
        return false;

    auto& keyNode = GetNode(nodeIndex);
    if (keyNode.GetType() != Node::TypeKey)
        return false;

    // Search for value node after key.
    auto keyNodeLevel = keyNode.level;
    for (++nodeIndex; nodeIndex < nodesCount; ++nodeIndex)
    {
        auto& node = GetNode(nodeIndex);
        if (node.level != keyNodeLevel + 1)
            return false; // Following node is not a child, so found no value.

        if (node.type == node.TypeValue)
            break; // Found the value, but still need to check if there is more than one value.

        if (node.type == node.TypeComment || node.type == node.TypeIgnorable)
            continue;
    }

    // Check that there is exactly one value node for this key.
    for (uint32_t nextNodeIndex = nodeIndex + 1; nextNodeIndex < nodesCount; ++nextNodeIndex)
    {
        auto& node = GetNode(nextNodeIndex);
        if (node.level <= keyNodeLevel)
            break; // The following node is at the same level as the key, so stop looking for values.

        if (node.type == node.TypeComment || node.type == node.TypeIgnorable)
            continue;

        // Any other type means that more than one value was found, not a single value.
        return false;
    }

    const Node& valueNode = GetNode(nodeIndex);
    auto textPointer = &nodesText_[valueNode.start];
    text.assign(textPointer, textPointer + valueNode.length);

    return true;
}


TextTree::Node::Type TextTree::Node::GetTypeDetail() const throw()
{
    return this->type;
}


TextTree::Node::Type TextTree::Node::GetType() const throw()
{
    return static_cast<TextTree::Node::Type>(this->type & TypeMask);
}


TextTreeParser::TextTreeParser(
    __in_ecount(textLength) const wchar_t* text, // Pointer should be valid for the lifetime of the class.
    uint32_t textLength,
    Options options
    )
    :   text_(text),
        textLength_(textLength),
        textIndex_(),
        textLevel_(),
        options_(options)
{
}


TextTreeParser::Syntax TextTreeParser::DetermineType(
    __in_ecount(textLength) const wchar_t* text,
    uint32_t textLength
    )
{
    for (uint32_t i = 0; i < textLength; ++i)
    {
        char16_t ch = text[i];
        if (ch == ' ' || ch == '\r' || ch == '\n') continue; // Skip all common forms of whitespace.
        if (ch == '{') return SyntaxJsonex;
        if (ch == '<') return SyntaxXml;
    }

    return SyntaxUnknown;
}


bool TextTreeParser::ReadNodes(__inout TextTree& textTree)
{
    TextTree::Node node;
    while (ReadNode(OUT node, OUT textTree.nodesText_))
    {
        textTree.nodes_.push_back(node);
    }
    return true;
}


uint32_t TextTreeParser::GetErrorCount()
{
    return static_cast<uint32_t>(errors_.size());
}


void TextTreeParser::GetErrorDetails(uint32_t errorIndex, __out uint32_t& errorTextIndex, __out const wchar_t** errorMessage)
{
    errorTextIndex = errors_[errorIndex].errorTextIndex;
    *errorMessage = errors_[errorIndex].errorMessage;
}


void TextTreeParser::ReportError(uint32_t errorTextIndex, const wchar_t* errorMessage)
{
    Error error = {errorTextIndex, errorMessage};
    errors_.push_back(error);
}


bool TextTreeParser::ReadNode(
    __out TextTree::Node& node,
    __inout std::wstring& nodeText
    )
{
    return false;
}


// Reads a single code unit, not full code point. This is okay because all the
// important functional code points are in the basic plane.
char32_t TextTreeParser::ReadCodeUnit()
{
    if (textIndex_ >= textLength_)
        return '\0';

    return text_[textIndex_++];
}


// Read, but do not advance.
char32_t TextTreeParser::PeekCodeUnit()
{
    if (textIndex_ >= textLength_)
        return '\0';

    return text_[textIndex_];
}


void TextTreeParser::AdvanceCodeUnit()
{
    if (textIndex_ >= textLength_)
        return;

    ++textIndex_;
}


void TextTreeParser::RecedeCodeUnit()
{
    if (textIndex_ <= 0)
        return;

    --textIndex_;
}


void TextTreeParser::AppendCharacter(
    __inout std::wstring& nodeText,
    char32_t ch
    )
{
    if (IsCharacterBeyondBmp(ch))
    {
        nodeText.push_back(GetLeadingSurrogate(ch));
        nodeText.push_back(GetTrailingSurrogate(ch));
    }
    else
    {
        nodeText.push_back(wchar_t(ch));
    }
}


JsonexParser::JsonexParser(
    __in_ecount(textLength) const wchar_t* text,
    uint32_t textLength,
    Options options
    )
    :   Base(text, textLength, options),
        expectedToken_(ExpectedTokenStart)
{
    // Test string:
    // Actions:foo, bar rod , cat{} {}, dog{bark} dog:{barkmore} bad:dog:{barklouder} (zig zag) "\b\\:" "a\b" , a:b:c  d:e:f{} ,, //hi
}


namespace
{
    bool JsonexIsValidWordCharacter(char32_t ch)
    {
        // This does not have the full Unicode database to follow the ECMA script identifier rules.
        char32_t lowerCaseAscii = ch & ~0x20;
        if (lowerCaseAscii >= 'A' && lowerCaseAscii <= 'Z')
        {
            return true;
        }
        else
        {
            switch (ch)
            {
            case '$': case '_': case '.': case '-': case '+':
            case '0': case '1': case '2': case '3': case '4':
            case '5': case '6': case '7': case '8': case '9':
                return true;
            }
        }
        return false;
    }

    bool JsonexIsControlCharacter(char32_t ch)
    {
        return (ch <= 0x001F || (ch >= 0x007F && ch <= 0x009F));
    }

    bool JsonexIsNewLineCharacter(char32_t ch)
    {
        return ch == '\r' || ch == '\n';
    }

    bool JsonexIsWordSeparator(char32_t ch)
    {
        switch (ch)
        {
        case ' ':
        case '\t':
        case '\r':
        case '\n':
        case ':':
        case '=':
        case ',':
        case '{':
        case '[':
        case '(':
        case '}':
        case ']':
        case ')':
        case '\0':
            return true;
        }
        return false;
    }

    char32_t JsonExGetEscapedNumber(
        __in_ecount(textLength) const wchar_t* text,
        uint32_t textIndex,
        uint32_t textLength,
        __out uint32_t& endingTextIndex,
        uint32_t radix = 10
        )
    {
        char32_t value = 0;
        for ( ; textIndex < textLength; ++textIndex)
        {
            char32_t ch = text[textIndex];
            if (ch < '0') break;
            if (ch >= '0' && ch <= '9')
            {
                ch -= '0';
            }
            else if (ch &= ~0x20, ch >= 'A' && ch <= 'Z')
            {
                ch -= 'A';
            }
            else
            {
                break; // Reached non alpha-numeric character.
            }
            if (ch > radix)
                break; // Reached a number beyond the radix.

            value *= radix;
            value += ch;
        }

        endingTextIndex = textIndex;

        return value;
    }

    TextTree::Node::Type JsonexGetNodeTypeFromCharacter(char32_t ch)
    {
        switch (ch)
        {
        case '{':
        case '}':
            return TextTree::Node::TypeDetailObject;

        case '[':
        case ']':
            return TextTree::Node::TypeDetailArray;

        case '(':
        case ')':
            return TextTree::Node::TypeDetailFunction;

        default:
            // Assume value for anything else.
            return TextTree::Node::TypeValue;
        }
    }
}


bool JsonexParser::SkipSpaces()
{
    if (textIndex_ >= textLength_)
        return false;

    bool skippedSpaces = false;
    for (; textIndex_ < textLength_; ++textIndex_)
    {
        wchar_t ch = text_[textIndex_];
        switch (ch)
        {
        case '\t': // tab
        case '\r': // carriage return
        case '\n': // line feed
        case ' ':  // space
            skippedSpaces = true;
            break; // Keep going.
        default:
            return skippedSpaces;
        }
    }
    return skippedSpaces;
}


void JsonexParser::SkipComment()
{
    for (; textIndex_ < textLength_; ++textIndex_)
    {
        wchar_t ch = text_[textIndex_];
        if (JsonexIsNewLineCharacter(ch))
            return;
    }
}


char32_t JsonexParser::GetEscapeCharacter()
{
    if (textIndex_ >= textLength_)
        return '\0';

    char32_t ch = text_[textIndex_++];

    switch (ch)
    {
    case L'r':  return L'\r';  // return
    case L'n':  return L'\n';  // new line
    case L't':  return L'\t';  // tab
    case L'q':  return L'\"';  // quote
    case L'b':  return 0x0008; // backspace
    case L'f':  return 0x000C; // form feed
    case L'\\': return L'\\';  // backslash
    case L'/':  return L'/';   // forward slash
    case L'"':  return L'"';   // double quote
    case L'0':  return L'\0';  // nul
#if 0
    case L'#':  return L'#';   // hash, since may be comment in INI files
    case L';':  return L';';   // semi-colon, since may be comment in INI files
    case L'=':  return L'=';   // equals, since delimiter in INI files
    case L':':  return L':';   // colon, since may be delimiter in INI files
#endif

    case L'x':
    case L'u':
        return JsonExGetEscapedNumber(
            text_,
            textIndex_,
            std::min(textLength_, textIndex_ + 4),
            OUT textIndex_,
            16
            );

    case L'X':
    case L'U':
        return JsonExGetEscapedNumber(
            text_,
            textIndex_,
            std::min(textLength_, textIndex_ + 8),
            OUT textIndex_,
            16
            );

    default:
        return '?';
    }

    return ch;
}


void JsonexParser::SkipInvalidWordCharacters()
{
    for (; textIndex_ < textLength_; ++textIndex_)
    {
        if (JsonexIsWordSeparator(text_[textIndex_]))
            return;
    }
}


bool JsonexParser::ReadWord(
    __out TextTree::Node& node,
    __inout std::wstring& nodeText
    )
{
    if (textIndex_ >= textLength_)
        return false;

    const uint32_t oldNodeTextSize = static_cast<uint32_t>(nodeText.size());
    const uint32_t startingTextIndex = textIndex_;

    char32_t ch = text_[textIndex_];
    if (JsonexIsWordSeparator(ch))
        return false;

    if (ch == '/') // Presume start of comment.
    {
        ++textIndex_;
        ch = PeekCodeUnit();
        if (ch != '/')
        {
            ReportError(startingTextIndex, L"Expect two forward slashes for a comment or for slashes to be used for named closure or in quoted strings.");
            SkipInvalidWordCharacters(); // Skip the invalid word.
            return false;
        }

        ++textIndex_;
        for (; textIndex_ < textLength_; ++textIndex_)
        {
            wchar_t ch = text_[textIndex_];
            if (JsonexIsControlCharacter(ch)) // Control character found inside string which was not escaped.
            {
                if (JsonexIsNewLineCharacter(ch)) // New line is a valid end to a comment.
                    break;
                    
                ReportError(textIndex_, L"Control characters found inside comment.");
                SkipComment(); // Skip the invalid word.
                return false;
            }

            nodeText.push_back(wchar_t(ch));
        }
        node.type = TextTree::Node::TypeComment;
    }
    else if (ch == '"') // Word is quoted.
    {
        ++textIndex_;
        while (textIndex_ < textLength_)
        {
            wchar_t ch = text_[textIndex_];
            if (JsonexIsControlCharacter(ch)) // Control character found inside string which was not escaped.
            {
                ReportError(startingTextIndex, L"Control characters found inside string. They must be escaped.");
                SkipInvalidWordCharacters(); // Skip the invalid word.
                return false;
            }

            ++textIndex_;
            if (ch == '"')
            {
                break;
            }
            else if (ch == '\\')
            {
                AppendCharacter(IN OUT nodeText, GetEscapeCharacter());
            }
            else
            {
                nodeText.push_back(wchar_t(ch));
            }
        }
        node.type = TextTree::Node::TypeValue;
    }
    else // Unquoted identifier or value.
    {
        while (textIndex_ < textLength_)
        {
            wchar_t ch = text_[textIndex_];
            if (!JsonexIsValidWordCharacter(ch))
            {
                if (JsonexIsWordSeparator(ch))
                    break; // Stopped due to word separator, which is okay.

                ReportError(startingTextIndex, L"Unsupported characters found inside identifier. Put the identifier in quotes.");
                SkipInvalidWordCharacters(); // Skip the invalid word.
                return false;
            }

            ++textIndex_;
            if (ch == '\\')
            {
                AppendCharacter(IN OUT nodeText, GetEscapeCharacter());
            }
            else
            {
                nodeText.push_back(wchar_t(ch));
            }
        }
        if (textIndex_ == startingTextIndex)
            return false;
        node.type = TextTree::Node::TypeValue;
    }

    uint32_t newNodeTextSize = static_cast<uint32_t>(nodeText.size());
    node.start  = oldNodeTextSize;
    node.length = newNodeTextSize - oldNodeTextSize;

    return true;
}


void JsonexParser::CheckClosingTag(
    __in const TextTree::Node& node,
    __in const std::wstring& nodeText
    )
{
    // Check that the explicit closing tag matches, if present.
    if (PeekCodeUnit() != '/')
        return;

    ++textIndex_;
    if (PeekCodeUnit() == '/')
    {
        RecedeCodeUnit(); // Don't eat the comment.
        return;
    }

    TextTree::Node closingNode;
    std::wstring closingTag;
    uint32_t textIndex = textIndex_;
    if (!ReadWord(IN OUT closingNode, IN OUT closingTag))
    {
        ReportError(textIndex, L"Expected explicit closing identifier.");
        return;
    }

    if (nodeText.size() < node.start + node.length)
        return; // The caller's node text does not contain the previous state to compare against.

    if (nodeText.compare(node.start, node.length, closingTag) != 0)
    {
        ReportError(textIndex, L"Closing identifier did not match opening identifier.");
    }
}


void JsonexParser::ClearAttributeOnStack()
{
    // If an unresolved attribute is on the stack, pop it, and restore the level.
    while (!nodeStack_.empty())
    {
        auto& back = nodeStack_.back();
        if (back.type != TextTree::Node::TypeDetailAttribute)
            break;

        textLevel_ = back.level;
        nodeStack_.pop_back();
    }
}


bool JsonexParser::ReadNode(
    __out TextTree::Node& node,
    __inout std::wstring& nodeText
    )
{
    while (true)
    {
        if (textIndex_ >= textLength_)
            return false;

        SkipSpaces();

        node.start = 0;
        node.length = 0;
        node.level = textLevel_;
        node.type = TextTree::Node::TypeNone;

        bool haveWord = ReadWord(IN OUT node, IN OUT nodeText);

        if (node.type == TextTree::Node::TypeComment)
        {
            break; // Return now for any comment read, since the rest does not apply.
        }

        bool skippedSpaces = SkipSpaces();

        // We read the word but do not know what type the node is.
        // So read ahead one to decide that.
        char32_t ch = ReadCodeUnit();
        switch (ch)
        {
        case ':':
        case '=':
            if (!haveWord)
            {
                ReportError(textIndex_ - 1, L"Assignment must have a keyword.");
            }

            // Followed by either an opening bracket or a value.
            SkipSpaces();
            ch = ReadCodeUnit();
            switch (ch)
            {
            case '{':
            case '[':
            case '(':
                node.type = JsonexGetNodeTypeFromCharacter(ch);
                break;

            default:
                RecedeCodeUnit(); // Leave this character for a later read.
                node.type = TextTree::Node::TypeDetailAttribute;
            }
            break;

        case ',':
            ClearAttributeOnStack();
            break;

        case '{':
        case '[':
        case '(':
            if (haveWord && skippedSpaces)
            {
                RecedeCodeUnit(); // Leave this character for a later read.
                ClearAttributeOnStack();
            }
            else
            {
                node.type = JsonexGetNodeTypeFromCharacter(ch);
                haveWord = true; // Set it true even if empty name.
            }
            break;

        case '}':
        case ']':
        case ')':
            // Confirm the closing type matches the opening one.
            if (nodeStack_.empty())
            {
                ReportError(textIndex_ - 1, L"Closing brace did not match opening brace.");
            }
            else
            {
                auto& back = nodeStack_.back();
                textLevel_ = back.level;
                if (back.type != JsonexGetNodeTypeFromCharacter(ch))
                {
                    ReportError(textIndex_ - 1, L"Closing brace did not match opening brace.");
                }

                CheckClosingTag(back, nodeText);
                nodeStack_.pop_back();
            }
            ClearAttributeOnStack();
            break;

        case '\0':
            ClearAttributeOnStack();
            break;

        default:
            RecedeCodeUnit(); // Leave this character for a later read.
            ClearAttributeOnStack();
            break;
        }

        if (node.GetType() == TextTree::Node::TypeKey)
        {
            nodeStack_.push_back(node);
            ++textLevel_;
            break;
        }

        if (node.type != TextTree::Node::TypeNone)
        {
            break;
        }
    }

    return true;
}
