// <SnippetTextAnalysiscpp>
// THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF
// ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO
// THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
// PARTICULAR PURPOSE.
//
// Copyright (c) Microsoft Corporation. All rights reserved
//
// Contents:    Implementation of text analyzer source and sink.
//
//----------------------------------------------------------------------------
#include "common.h"
#include "TextAnalysis.h"


TextAnalysis::TextAnalysis(
    const wchar_t* text,
    UINT32 textLength,
    const wchar_t* localeName,
    IDWriteNumberSubstitution* numberSubstitution,
    DWRITE_READING_DIRECTION readingDirection
    )
:   text_(text),
    textLength_(textLength),
    localeName_(localeName),
    readingDirection_(readingDirection),
    numberSubstitution_(numberSubstitution),
    currentPosition_(0),
    currentRunIndex_(0)
{
}


STDMETHODIMP TextAnalysis::GenerateResults(
    IDWriteTextAnalyzer* textAnalyzer,
    OUT std::vector<TextAnalysis::Run>& runs,
    OUT std::vector<DWRITE_LINE_BREAKPOINT>& breakpoints
    )
{
    // Analyzes the text using each of the analyzers and returns
    // their results as a series of runs.

    HRESULT hr = S_OK;

    try
    {
        // Initially start out with one result that covers the entire range.
        // This result will be subdivided by the analysis processes.
        runs_.resize(1);
        LinkedRun& initialRun   = runs_[0];
        initialRun.nextRunIndex = 0;
        initialRun.textStart    = 0;
        initialRun.textLength   = textLength_;
        initialRun.bidiLevel    = (readingDirection_ == DWRITE_READING_DIRECTION_RIGHT_TO_LEFT);

        // Allocate enough room to have one breakpoint per code unit.
        breakpoints_.resize(textLength_);

        // Call each of the analyzers in sequence, recording their results.
        if (SUCCEEDED(hr = textAnalyzer->AnalyzeLineBreakpoints(   this, 0, textLength_, this))
        &&  SUCCEEDED(hr = textAnalyzer->AnalyzeBidi(              this, 0, textLength_, this))
        &&  SUCCEEDED(hr = textAnalyzer->AnalyzeScript(            this, 0, textLength_, this))
        &&  SUCCEEDED(hr = textAnalyzer->AnalyzeNumberSubstitution(this, 0, textLength_, this))
        &&  SUCCEEDED(hr = AnalyzeOrientation(this, 0, textLength_, this))
        )
        {
            // Exchange our results with the caller's.
            breakpoints.swap(breakpoints_);

            // Resequence the resulting runs in order before returning to caller.
            size_t totalRuns = runs_.size();
            runs.resize(totalRuns);

            UINT32 nextRunIndex = 0;
            for (size_t i = 0; i < totalRuns; ++i)
            {
                runs[i]         = runs_[nextRunIndex];
                nextRunIndex    = runs_[nextRunIndex].nextRunIndex;
            }
        }
    }
    catch (...)
    {
        return ExceptionToHResult();
    }

    return hr;
}


////////////////////////////////////////////////////////////////////////////////
// IDWriteTextAnalysisSource source implementation

IFACEMETHODIMP TextAnalysis::GetTextAtPosition(
    UINT32 textPosition,
    OUT WCHAR const** textString,
    OUT UINT32* textLength
    ) throw()
{
    if (textPosition >= textLength_)
    {
        // Return no text if a query comes for a position at the end of
        // the range. Note that is not an error and we should not return
        // a failing HRESULT. Although the application is not expected
        // to return any text that is outside of the given range, the
        // analyzers may probe the ends to see if text exists.
        *textString = NULL;
        *textLength = 0;
    }
    else
    {
        *textString = &text_[textPosition];
        *textLength = textLength_ - textPosition;
    }
    return S_OK;
}


IFACEMETHODIMP TextAnalysis::GetTextBeforePosition(
    UINT32 textPosition,
    OUT WCHAR const** textString,
    OUT UINT32* textLength
    ) throw()
{
    if (textPosition == 0 || textPosition > textLength_)
    {
        // Return no text if a query comes for a position at the end of
        // the range. Note that is not an error and we should not return
        // a failing HRESULT. Although the application is not expected
        // to return any text that is outside of the given range, the
        // analyzers may probe the ends to see if text exists.
        *textString = NULL;
        *textLength = 0;
    }
    else
    {
        *textString = &text_[0];
        *textLength = textPosition - 0; // text length is valid from current position backward
    }
    return S_OK;
}


DWRITE_READING_DIRECTION STDMETHODCALLTYPE TextAnalysis::GetParagraphReadingDirection() throw()
{
    return readingDirection_;
}


IFACEMETHODIMP TextAnalysis::GetLocaleName(
    UINT32 textPosition,
    OUT UINT32* textLength,
    OUT WCHAR const** localeName
    ) throw()
{
    // The pointer returned should remain valid until the next call,
    // or until analysis ends. Since only one locale name is supported,
    // the text length is valid from the current position forward to
    // the end of the string.

    *localeName = localeName_;
    *textLength = textLength_ - textPosition;

    return S_OK;
}


IFACEMETHODIMP TextAnalysis::GetNumberSubstitution(
    UINT32 textPosition,
    OUT UINT32* textLength,
    OUT IDWriteNumberSubstitution** numberSubstitution
    ) throw()
{
    if (numberSubstitution_ != NULL)
        numberSubstitution_->AddRef();

    *numberSubstitution = numberSubstitution_;
    *textLength = textLength_ - textPosition;

    return S_OK;
}


STDMETHODIMP TextAnalysis::GetBidiLevel(
    UINT32 textPosition,
    OUT UINT32* textLength,
    OUT UINT8* resolvedLevel
    ) throw()
{
    SetCurrentRun(textPosition);
    LinkedRun& run = runs_[currentRunIndex_];
    *resolvedLevel = run.bidiLevel;
    *textLength    = textLength_ - textPosition;

    return S_OK;
}


////////////////////////////////////////////////////////////////////////////////
// IDWriteTextAnalysisSink implementation

IFACEMETHODIMP TextAnalysis::SetLineBreakpoints(
    UINT32 textPosition,
    UINT32 textLength,
    DWRITE_LINE_BREAKPOINT const* lineBreakpoints   // [textLength]
    ) throw()
{
    if (textLength > 0)
    {
        memcpy(&breakpoints_[textPosition], lineBreakpoints, textLength * sizeof(lineBreakpoints[0]));
    }
    return S_OK;
}


IFACEMETHODIMP TextAnalysis::SetScriptAnalysis(
    UINT32 textPosition,
    UINT32 textLength,
    DWRITE_SCRIPT_ANALYSIS const* scriptAnalysis
    ) throw()
{
    try
    {
        SetCurrentRun(textPosition);
        SplitCurrentRun(textPosition);
        while (textLength > 0)
        {
            LinkedRun& run  = FetchNextRun(&textLength);
            run.script      = *scriptAnalysis;
        }
    }
    catch (...)
    {
        return E_FAIL; // Unknown error, probably out of memory.
    }

    return S_OK;
}


IFACEMETHODIMP TextAnalysis::SetBidiLevel(
    UINT32 textPosition,
    UINT32 textLength,
    UINT8 explicitLevel,
    UINT8 resolvedLevel
    ) throw()
{
    try
    {
        SetCurrentRun(textPosition);
        SplitCurrentRun(textPosition);
        while (textLength > 0)
        {
            LinkedRun& run  = FetchNextRun(&textLength);
            run.bidiLevel   = resolvedLevel;
        }
    }
    catch (...)
    {
        return E_FAIL; // Unknown error, probably out of memory.
    }

    return S_OK;
}


IFACEMETHODIMP TextAnalysis::SetNumberSubstitution(
    UINT32 textPosition,
    UINT32 textLength,
    IDWriteNumberSubstitution* numberSubstitution
    ) throw()
{
    try
    {
        SetCurrentRun(textPosition);
        SplitCurrentRun(textPosition);
        while (textLength > 0)
        {
            LinkedRun& run          = FetchNextRun(&textLength);
            run.isNumberSubstituted = (numberSubstitution != NULL);
        }
    }
    catch (...)
    {
        return E_FAIL; // Unknown error, probably out of memory.
    }

    return S_OK;
}


IFACEMETHODIMP TextAnalysis::SetOrientation(
    UINT32 textPosition,
    UINT32 textLength,
    DWRITEX_READING_DIRECTION readingDirection,
    DWRITEX_GLYPH_ORIENTATION glyphOrientation,
    const DWRITE_MATRIX* transform,
    bool isSideways,
    bool isReversed,
    UINT8 adjustedBidiLevel
    ) throw()
{
    try
    {
        SetCurrentRun(textPosition);
        SplitCurrentRun(textPosition);
        while (textLength > 0)
        {
            LinkedRun& run  = FetchNextRun(&textLength);
            run.direction   = UINT8(readingDirection);
            run.orientation = UINT8(glyphOrientation);
            run.bidiLevel   = adjustedBidiLevel;
        }
    }
    catch (...)
    {
        return E_FAIL; // Unknown error, probably out of memory.
    }

    return S_OK;
}


////////////////////////////////////////////////////////////////////////////////
// Vertical specific code


enum CharOrientationClass
{
    CharOrientationClassIDU,    // ideographic upright, stacked, never mirrored (Chinese)
                                //      S LTR={L0 R0 T0 B270,180}
    CharOrientationClassSRD,    // rotatable and stackable discrete (Latin/Hebrew)
                                //      RS LTR={L0 R90,180 T0 B270} RTL={L270,180 R0 T0 B90}
    CharOrientationClassRC,     // rotating connected (Devanagari/Arabic/Ogham?)
                                //      RC LTR={L0 R180 T90 B270} RTL={L180 R0 T270 B90}
    CharOrientationClassRCU,    // rotating connected/can rotate upside-down 180 (Mongolian/Rongo Rongo)
                                //      RUC LTR={L0 R180 T90 B270}
    CharOrientationClassRCUD,   // rotating discrete/can rotate upside-down 180 (Rongo Rongo)
                                //      RU LTR={L0 R180 T90 B270}
    CharOrientationClassSMD,    // stackable and mirrorable discrete (Egyptian hieroglyphs/Mayan/Runic/(rarely)Orkhon)
                                //      SM {L0 RM0 TL0 TRM0}
    CharOrientationClassARNW,   // narrow width arrows
                                //      SRARW (do not mirror, though, technically could)
    CharOrientationClassARFW,   // full width arrows
                                //      SRFARW
    CharOrientationClassNWRMP,  // rotated punctuation/symbol (rotated in stacked TTB, but has no vert feature, like "(")
                                //      R
    CharOrientationClassFWR,    // full width rotating punctuation (typically stay upright and rotate via a 'vert' feature)
                                //      RF
    CharOrientationClassBOX,    // Box drawing shapes
                                //      SRBOX
    CharOrientationClassBLK,    // Block elements
                                //      SRBLK (L0 R0 T0 B0)
    CharOrientationClassN,      // neutral orientation, all are possible
                                //      SMR
    CharOrientationClassSMRD,   // stackable rotatable mirroable discrete (Latin/Greek)
                                //      SMRD
};

struct CharOrientation
{
    // Each 32bit dword contains a combination of valid
    // reading directions and glyph orientations. If the
    // bit is not set for that combination, the resolution
    // process should select another one based on the
    // orientation mode.

    UINT32 horizontalDirections;
    UINT32 verticalDirections;

    // bool isArrow : 1;        // use class instead
    // bool isInherited : 1;    // check general category instead
};


// One combination of direction and orientation.
// The "& 3" masks it to the minor axis character progression.
#define DIR1(direction, orientation) ( 1u << ( ((DWRITEX_READING_DIRECTION_ ## direction) & 3) * 8 + (DWRITEX_GLYPH_ORIENTATION_ ## orientation)) )

// One character direction, both line progression directions.
// The "^ 2" flips to the other line progression direction.
#define DIR(direction, orientation)  ( 1u << ( ((DWRITEX_READING_DIRECTION_ ## direction) & 3)      * 8 + (DWRITEX_GLYPH_ORIENTATION_ ## orientation)) \
                                     | 1u << ((((DWRITEX_READING_DIRECTION_ ## direction) & 3) ^ 2) * 8 + (DWRITEX_GLYPH_ORIENTATION_ ## orientation)) )

// List of equivalence classes, rather than properties for each character.
const static CharOrientation g_CharOrientationClasses[] =
{
    //  ---/    \---    \-->    <--/   |   /|  |\  /\  /\  /|  |\  /\
    //    /      \       \        /    |  / |  | \  |  |  / |  | \  |
    //   /        \       \      /     | /  |  |  \ |  | /  |  |  \ |
    //  /-->    <--\    ---\    /---   |/  \/  |   \|  |/   |  |   \|
    //
    //
    //  XXXX     XXXX   X   X   X   X  XXXXXX   XX  X  X  XX    XX  X
    //  X   X   X   X   X   X   X   X  X  X    X  XX    XX  X  X  XX
    //  XXXX     XXXX   XXXX     XXXX  X  XX   X  X      X  X  X  X
    //  X   X   X   X   X   X   X   X   XX  X  XXXXXX  XXXXXX  XXXXXX
    //  X   X   X   X   XXXX     XXXX        

    // IDU
    {
        DIR(E, CW0) | DIR(W, CW0),
        DIR(S, CW0)
    },

    // SRD
    {
        DIR(E, CW0) | DIR(W, CW0),
        DIR(S, CW0) | DIR(S, CW90) | DIR(N, CW270)
    },

    // RC 
    {
        DIR(E, CW0),
        DIR(S, CW90) | DIR(S, CW90)
    },

    // RCU
    {
        0,
        0
    },

    // RCUD
    {
        0,
        0
    },

    // SMD
    {
        0,
        0
    },

    // ARNW
    {
        0,
        0
    },

    // ARFW
    {
        0,
        0
    },

    // NWRMP
    {
        0,
        0
    },

    // FWR
    {
        0,
        0
    },

    // BOX
    {
        0,
        0
    },

    // BLK
    {
        0,
        0
    },

    // N  
    {
        0,
        0
    },

    // SMRD    */
    {
        DIR(E, CW0) | DIR(W, FH),
        DIR(S, CW0) | DIR(S, CW90) | DIR(N, CW270)
    },



#if 0 // delete
    // todo:
    /* 00 Latin                  */ {DIR(LTR, UPRIGHT) | DIR(TTB, CW ) | DIR(TTB,  UPRIGHT) | DIR(BTT, CCW)},
    /* 01 Arabic                 */ {DIR(RTL, UPRIGHT) | DIR(TTB, CCW) | DIR(BTT,  CW )},
    /* 02 Egyptian hieroglyphics */ {DIR(LTR, UPRIGHT) | DIR(RTL, FLIP_H)},
    /* 03 Kanji, Hangul          */ {DIR(LTR, UPRIGHT) | DIR(TTB, UPRIGHT)},
    /* 04 Arrows                 */ {DIR(LTR, UPRIGHT) | DIR(TTB, UPRIGHT) | DIR(TTB, CW) | DIR(TTB, CCW) | DIR(BTT, CCW) | DIR(BTT, CW), true, false},
    /* 05 Ogham                  */ {DIR(LTR, UPRIGHT) | DIR(BTT, CCW)},
    /* 06 Combining mark         */ {DIR(LTR, UPRIGHT) | DIR(RTL, UPRIGHT), false, true},
    /* 07 Bidi neutral           */ {~0u},
    /* 08 Hebrew                 */ {DIR(RTL, UPRIGHT) | DIR(TTB, UPRIGHT)| DIR(TTB, CCW) | DIR(BTT,  CW )},
    /* 09 All forms              */ {~0u},
    /* 10 Always upright         */ {DIR(LTR, UPRIGHT) | DIR(RTL, UPRIGHT) | DIR(TTB, UPRIGHT) | DIR(BTT, UPRIGHT)},
    /* 11                        */ {},
    /* 12                        */ {},
    /* 13                        */ {},
    /* 14                        */ {},
#endif
};

#undef DIR

struct CharacterRangeIndex
{
    UINT32 rangeLow;
    UINT32 rangeHigh;
    UINT32 orientationClass;
};

// Map a character 
const static CharacterRangeIndex g_CharToCharOrientation[] =
{
    { 0x0000, 0x0020,  CharOrientationClassSMRD     }, // control characters
    { 0x0000, 0x02FF,  CharOrientationClassSMRD     }, // simple Latin (plus other punctuation)
    { 0x0300, 0x036F,  6                            }, // Combining marks
    { 0x0600, 0x06EF,  CharOrientationClassRC       }, // Arabic
    { 0x0590, 0x05FF,  8 }, // Hebrew
    { 0x1100, 0x11FF,  3 }, // Hangul Jamo
    { 0x1680, 0x169F,  5 }, // Ogham
    { 0x2000, 0x206F,  7 }, // General Punctuation, 
    { 0x2100, 0x214F,  7 }, // Letterlike Symbols 
    { 0x2460, 0x24FF,  3 }, // Enclosed Alphanumerics
    { 0x25A0, 0x25FF,  4 }, // Geometric Shapes
    { 0x2600, 0x26FF,  4 }, // Miscellaneous Symbols 
    { 0x2700, 0x27FF,  4 }, // Dingbats (supplemental arrows, misc math symbols)
    { 0x3001, 0x303F,  3 }, // CJK Symbols and Punctuation 
    { 0x3040, 0x309F,  CharOrientationClassIDU }, // HIRAGANA
    { 0x30A0, 0x30FF,  CharOrientationClassIDU }, // KATAKANA
    { 0x3100, 0x312F,  CharOrientationClassIDU }, // Bopomofo
    { 0x3130, 0x318F,  CharOrientationClassIDU }, // Hangul Compatibility Jamo         
    { 0x3190, 0x319F,  CharOrientationClassIDU }, // Kanbun (CJK Miscellaneous) 
    { 0x31F0, 0x31FF,  CharOrientationClassIDU }, // Katakana Phonetic Extensions
    { 0x3200, 0x32FF,  CharOrientationClassIDU }, // Enclosed CJK Letters & Months 
    { 0x3300, 0x33FF,  CharOrientationClassIDU }, // CJK Compatibility, 
    { 0x3400, 0x4DFF,  CharOrientationClassIDU }, // ExtA range
    { 0x4E00, 0x9FFF,  CharOrientationClassIDU }, // CJK_UNIFIED_IDOGRAPHS
    { 0xA000, 0xA48F,  CharOrientationClassIDU }, // Yi Syllables
    { 0xA490, 0xA4CF,  CharOrientationClassIDU }, // Yi Radicals
    { 0xAC00, 0xD7A3,  CharOrientationClassIDU }, // HANGUL
    { 0xE000, 0xF8FF,  CharOrientationClassIDU }, // Private Use Area (PUA)
    { 0xF900, 0xFAFF,  CharOrientationClassIDU }, // CJK Compatibility Ideographs
    { 0xFE30, 0xFE4F,  CharOrientationClassIDU }, // CJK Compatibility forms
    { 0xFF01, 0xFF60,  3 }, // Halfwidth
                            // Note: halfwidth Katakana and hangul are not included. 
    { 0xFFE0, 0xFFEE, 03 }  // Fullwidth forms 
};


const DWRITE_MATRIX g_CharOrientationMatrices[8] =
{
    { 1, 0, // 0 identify
      0, 1,
      0, 0},
    {-1, 0, // 1 horizontal flip
      0, 1,
      0, 0},
    { 1, 0, // 2 vertical flip
      0,-1,
      0, 0},
    {-1, 0, // 3 horizontal/vertical flip
      0,-1,
      0, 0},
    { 0, 1, // 5 transpose
      1, 0,
      0, 0},
    { 0, 1, // 4 transpose, horizontal flip
     -1, 0,
      0, 0},
    { 0,-1, // 6 transpose, vertical flip
     -1, 0,
      0, 0},
    { 0,-1, // 7 transpose, horizontal/vertical flip
      1, 0,
      0, 0},
};


void TextAnalysis::MapReadingDirectionToOrientation(
    DWRITEX_READING_DIRECTION readingDirection,
    DWRITEX_GLYPH_ORIENTATION glyphOrientation,
    __out CompleteOrientation& orientation
    ) throw()
{
    bool isSideways = false;
    bool isReversed = false;
    /*
    bool isSideways  = !!(glyphOrientation & DWRITEX_GLYPH_ORIENTATION_TRANSPOSE);
    bool isReversed  = !!(readingDirection & DWRITEX_READING_DIRECTION_REVERSE);
    UINT32 transformIndex = glyphOrientation & (DWRITEX_GLYPH_ORIENTATION_FLIP_H
                                             |  DWRITEX_GLYPH_ORIENTATION_FLIP_V
                                             |  DWRITEX_GLYPH_ORIENTATION_TRANSPOSE);

    UINT32 doubleReversalBit = DWRITEX_GLYPH_ORIENTATION_FLIP_H;

    if (readingDirection & DWRITEX_READING_DIRECTION_VERTICAL)
    {
        // Rotate transform and use vertical mirroring instead of horizontal
        // to swap the reversal flag.
        transformIndex += 4;
        isSideways = !isSideways;
        doubleReversalBit = DWRITEX_GLYPH_ORIENTATION_FLIP_V;
    }
    if (glyphOrientation & doubleReversalBit)
    {
        // Reversals cancel out
        isReversed = !isReversed;
    }
    */

    orientation.transform  = &g_CharOrientationMatrices[0]; // todo:transformIndex];
    orientation.isReversed = isReversed;
    orientation.isSideways = isSideways;
}


const UINT32 GetUcdCharacterOrientationClass(UINT32 ch)
{
    for (UINT32 i = 0; i < ARRAYSIZE(g_CharToCharOrientation); ++i)
    {
        const CharacterRangeIndex& range = g_CharToCharOrientation[i];
        if (ch >= range.rangeLow && ch <= range.rangeHigh)
        {
            return range.orientationClass;
        }
    }

    return 0;
}


STDMETHODIMP TextAnalysis::AnalyzeOrientation(
    IDWriteTextAnalysisSource* analysisSource,
    UINT32 firstPosition,
    UINT32 textLength,
    IDWriteTextAnalysisSink* analysisSink
    ) throw()
{
    if (firstPosition + textLength < firstPosition)
        return E_INVALIDARG;

    DWRITEX_READING_DIRECTION preferredDirection = DWRITEX_READING_DIRECTION(GetParagraphReadingDirection());

    UINT32 previousTextOffset = 0;
    //UINT32 previousOrientationClass = ~0u;
    UINT32 nextBidiLevelChangeOffset = 0;
    UINT8  bidiLevel = 0;

    DWRITEX_READING_DIRECTION readingDirection = preferredDirection;
    DWRITEX_READING_DIRECTION previousReadingDirection = readingDirection;
    DWRITEX_GLYPH_ORIENTATION glyphOrientation = DWRITEX_GLYPH_ORIENTATION_CW0;

    // For each character.
    for (UINT32 textOffset = 0; /* terminates inside */ ; ++textOffset)
    {
        const bool reachedEnd = (textOffset >= textLength);

        if (readingDirection != previousReadingDirection || reachedEnd)
        {
            // Conclude sideways, reverse, and matrix from reading direction.
            UINT8 adjustedBidiLevel = bidiLevel; // todo:
            CompleteOrientation orientation;
            MapReadingDirectionToOrientation(readingDirection, glyphOrientation, orientation);

            SetOrientation(
                firstPosition + previousTextOffset,
                textLength,
                readingDirection,
                glyphOrientation,
                orientation.transform,
                orientation.isSideways,
                orientation.isReversed,
                adjustedBidiLevel
                );

            previousReadingDirection = readingDirection;
            previousTextOffset = textOffset;
        }

        if (reachedEnd)
        {
            break; // no more orientation ranges to report
        }

        if (textOffset >= nextBidiLevelChangeOffset)
        {
            UINT32 textLengthUntilNextLevelChange = 0;
            GetBidiLevel(firstPosition + textOffset, &textLengthUntilNextLevelChange, &bidiLevel);
            nextBidiLevelChangeOffset = textOffset + textLengthUntilNextLevelChange;
        }

        UINT32 ch = text_[firstPosition + textOffset];

        UINT32 orientationClass = GetUcdCharacterOrientationClass(ch);
        const CharOrientation& charOrientation = g_CharOrientationClasses[orientationClass];
        charOrientation; // todo:delete

        //if (orientationClass != previousOrientationClass)

        /*
        Try to map the text to the preferred glyph orientation. If not possible,
        gracefully degrade in order.

        todo: decide how to incorporate bidi into all of this
        todo: decide how to handle neutrals and arrows.
        todo: decide how to handle 'vert' conflict

        1. Try reading direction and given glyph orientation first (Latin in LTR, CJK in TTB)
        2. Try reading direction and mirrored glyph orientation (hieroglyphics in RTL)
        2. Try reading direction and other glyph orientations, like Devanagari trying TTB Upright (changed to CW)
        3. Try glyph orientation and opposite reading direction (Arabic)
        4. Try reading direction and ANY glyph orientation (CJK in TTB with clockwise orientation)
        5. Try opposite reading direction and ANY glyph orientation (CJK in BTT, Ogham in TTB)
        6. Force reading direction and rotation
        */

        readingDirection = preferredDirection;
        #if 0
        if (charOrientation.isInherited)
        {
            // Combining marks simply adopt whatever came before them.
            readingDirection = previousReadingDirection;
        }
        else if (charOrientation.allowedDirections & (1u<<preferredDirection))
        {
            // The character allows the given reading direction and
            // glyph orientation, so we're done.
            readingDirection = preferredDirection;
        }
        else if (charOrientation.allowedDirections & (1u<<(preferredDirection ^ DWRITEX_READING_DIRECTION_CHARACTER_PROGRESSION)))
        {
            readingDirection = preferredDirection;
        }
        else
        {
            // Gracefully degrade.
            //readingDirection = GetBestReadingDirection(previousReadingDirection);
            readingDirection = preferredDirection;
        }


        /*
        if (charOrientation.isArrow)
        {
            // Disable 'vert' feature. It should not be applied.
        }
        */
        #endif
    }

    return S_OK;
}


////////////////////////////////////////////////////////////////////////////////
// Run modification.

TextAnalysis::LinkedRun& TextAnalysis::FetchNextRun(
    IN OUT UINT32* textLength
    )
{
    // Used by the sink setters, this returns a reference to the next run.
    // Position and length are adjusted to now point after the current run
    // being returned.

    UINT32 runIndex      = currentRunIndex_;
    UINT32 runTextLength = runs_[currentRunIndex_].textLength;

    // Split the tail if needed (the length remaining is less than the
    // current run's size).
    if (*textLength < runTextLength)
    {
        runTextLength       = *textLength; // Limit to what's actually left.
        UINT32 runTextStart = runs_[currentRunIndex_].textStart;

        SplitCurrentRun(runTextStart + runTextLength);
    }
    else
    {
        // Just advance the current run.
        currentRunIndex_ = runs_[currentRunIndex_].nextRunIndex;
    }
    *textLength -= runTextLength;


    // Return a reference to the run that was just current.
    return runs_[runIndex];
}


void TextAnalysis::SetCurrentRun(UINT32 textPosition)
{
    // Move the current run to the given position.
    // Since the analyzers generally return results in a forward manner,
    // this will usually just return early. If not, find the
    // corresponding run for the text position.

    if (currentRunIndex_ < runs_.size()
    &&  runs_[currentRunIndex_].ContainsTextPosition(textPosition))
    {
        return;
    }

    currentRunIndex_ = static_cast<UINT32>(
                            std::find(runs_.begin(), runs_.end(), textPosition)
                            - runs_.begin()
                            );
}


void TextAnalysis::SplitCurrentRun(UINT32 splitPosition)
{
    // Splits the current run and adjusts the run values accordingly.

    UINT32 runTextStart = runs_[currentRunIndex_].textStart;

    if (splitPosition <= runTextStart)
        return; // no change

    // Grow runs by one.
    size_t totalRuns = runs_.size();
    try
    {
        runs_.resize(totalRuns + 1);
    }
    catch (...)
    {
        return; // Can't increase size. Return same run.
    }

    // Copy the old run to the end.
    LinkedRun& frontHalf = runs_[currentRunIndex_];
    LinkedRun& backHalf  = runs_.back();
    backHalf             = frontHalf;

    // Adjust runs' text positions and lengths.
    UINT32 splitPoint       = splitPosition - runTextStart;
    backHalf.textStart     += splitPoint;
    backHalf.textLength    -= splitPoint;
    frontHalf.textLength    = splitPoint;
    frontHalf.nextRunIndex  = static_cast<UINT32>(totalRuns);
    currentRunIndex_        = static_cast<UINT32>(totalRuns);
}
// </SnippetTextAnalysiscpp>
