//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   Font String Perf test app.
//
//  Author:     Dwayne Robinson (dwayner@microsoft.com)
//
//  History:    2012-09-12   dwayner    Created
//
//----------------------------------------------------------------------------
#include "precomp.h"

#include "../resources/resource.h"

////////////////////////////////////////
// UI related

#pragma prefast(disable:__WARNING_HARD_CODED_STRING_TO_UI_FN, "It's an internal test program.")
#define IddMainDialogCount IddMainLastDialog - IddMainFirstDialog + 1
#define WM_PROFILE_RESULT WM_USER+100


////////////////////////////////////////


MainWindow::MainWindow(HWND hwnd)
:   hwnd_(hwnd),
    currentPaneId_(),
    newestFontInfoId_(),
    profilingThread_(),
    preventListViewRecursion_(),
    insideAutomatedAction_(),
    skipPartialCoverageFonts_(true),
    automatedActionIndex_(),
    perfGrouping_(PerfGroupingString|PerfGroupingFont),
#if 0
    perfMeasurementType_(PerfMeasurementTypeDefault)
#else
    perfMeasurementType_(PerfMeasurementTypeShaping) //todo:
#endif
{
    accelTable_ = LoadAccelerators(Application::g_hModule, MAKEINTRESOURCE(IdaMainWindow));
    InitializeCriticalSection(OUT &profilingThreadLock_);
}


MainWindow::~MainWindow()
{
    DeleteCriticalSection(&profilingThreadLock_);
    ::DestroyAcceleratorTable(accelTable_);
}


void MainWindow::RegisterCustomClasses()
{
    // Ensure that the common control DLL is loaded.
    // (probably not needed, but do it anyway)
    INITCOMMONCONTROLSEX icex;
    icex.dwSize = sizeof(INITCOMMONCONTROLSEX);
    icex.dwICC  = ICC_STANDARD_CLASSES|ICC_LISTVIEW_CLASSES|ICC_TAB_CLASSES|ICC_PROGRESS_CLASS;
    InitCommonControlsEx(&icex); 

    AttributeList::RegisterWindowClass(Application::g_hModule);
}


namespace
{
    struct ThisId
    {
        MainWindow* window;
        int id;
    };


    struct ColumnInfo
    {
        int attributeType;
        int width;
        const wchar_t* name;
    };

    const static ColumnInfo g_FontListColumnInfo[] = {
        {0, 200, L"Family name"},
        {1, 80,  L"Style"},
        {2, 440, L"File path"},
        {3, 40,  L"Index"},
    };

    const static ColumnInfo g_StringsListColumnInfo[] = {
        {0, 130, L"Description"},
        {1, 520, L"String"},
        {2, 60,  L"Coverage"},
        {3, 50,  L"Simple"},
    };

    enum PerfScoreColumnIndex
    {
        PerfScoreColumnIndexString,
        PerfScoreColumnIndexFont,
        PerfScoreColumnIndexFile,
        PerfScoreColumnIndexLayoutTime,
        PerfScoreColumnIndexShapingTime,
        PerfScoreColumnIndexTotal,
    };
    const static ColumnInfo g_PerfScoreColumnInfo[] = {
        {0, 100, L"String"},
        {1, 100, L"Font"},
        {2, 240, L"File"},
        {3, 160, L"Layout time"},
        {4, 160, L"Shaping time"},
    };

    const static ColumnInfo g_LookupsListColumnInfo[] = {
        {0, 760, L"Font lookup"},
    };

    const static ColumnInfo g_ActionsListColumnInfo[] = {
        {0, 200, L"Action"},
        {1, 560, L"Value"},
    };

    const static ColumnInfo g_HelpColumnInfo[] = {
        {0, 200, L"Command"},
        {1, 560, L"Description"},
    };

    void InitializeSysListView(
        HWND hwnd,
        __in_ecount(columnInfoCount) const ColumnInfo* columnInfo,
        size_t columnInfoCount
        )
    {
        ListView_SetExtendedListViewStyle(hwnd, LVS_EX_FULLROWSELECT | LVS_EX_LABELTIP | LVS_EX_DOUBLEBUFFER | LVS_EX_HEADERDRAGDROP);

        // Columns
        LVCOLUMN lc;
        lc.mask = LVCF_TEXT | LVCF_WIDTH | LVCF_SUBITEM;

        for (size_t i = 0; i < columnInfoCount; ++i)
        {
            lc.iSubItem = columnInfo[i].attributeType;
            lc.cx       = columnInfo[i].width;
            lc.pszText  = (LPWSTR)columnInfo[i].name;
            ListView_InsertColumn(hwnd, lc.iSubItem, &lc);
        }
    }

    const uint32_t g_defaultTypographicFeatures[] = {
        DWRITE_MAKE_OPENTYPE_TAG('r','l','i','g'), // Required ligatures
        DWRITE_MAKE_OPENTYPE_TAG('r','c','l','t'), // Required contextual alternates
        DWRITE_MAKE_OPENTYPE_TAG('l','o','c','l'), // Localized forms
        DWRITE_MAKE_OPENTYPE_TAG('c','c','m','p'), // Composition/decomposition
        DWRITE_MAKE_OPENTYPE_TAG('c','a','l','t'), // Contextual alternates
        DWRITE_MAKE_OPENTYPE_TAG('l','i','g','a'), // Standard ligatures
        DWRITE_MAKE_OPENTYPE_TAG('c','l','i','g'), // Contextual ligatures
        DWRITE_MAKE_OPENTYPE_TAG('k','e','r','n'), // Kerning
        DWRITE_MAKE_OPENTYPE_TAG('m','a','r','k'), // Mark positioning
        DWRITE_MAKE_OPENTYPE_TAG('m','k','m','k'), // Mark to mark positioning
        DWRITE_MAKE_OPENTYPE_TAG('d','i','s','t')  // Distance
    };

    bool EqualsDefaultTypographicFeatures(std::vector<uint32_t> const& fontFeatures)
    {
        return fontFeatures.size() == ARRAY_SIZE(g_defaultTypographicFeatures)
            && std::equal(fontFeatures.begin(), fontFeatures.end(), g_defaultTypographicFeatures);
    }

    const static wchar_t* g_fontFeatureLists[] = {
        L"default generic shaping features — "
            L"rlig " // Required ligatures
            L"rclt " // Required contextual alternates
            L"locl " // Localized forms
            L"ccmp " // Composition/decomposition
            L"calt " // Contextual alternates
            L"liga " // Standard ligatures
            L"clig " // Contextual ligatures
            L"kern " // Kerning
            L"mark " // Mark positioning
            L"mkmk " // Mark to mark positioning
            L"dist " // Distance
            ,
        L"default shaping features combined — "
            L"abvf "
            L"abvm "
            L"abvs "
            L"akhn "
            L"blwf "
            L"blwm "
            L"blws "
            L"calt "
            L"ccmp "
            L"cjct "
            L"clig "
            L"cswh "
            L"curs "
            L"dist "
            L"fin2 "
            L"fin3 "
            L"fina "
            L"half "
            L"haln "
            L"init "
            L"isol "
            L"kern "
            L"liga "
            L"locl "
            L"mark "
            L"med2 "
            L"medi "
            L"mkmk "
            L"mset "
            L"nukt "
            L"pref "
            L"pres "
            L"pstf "
            L"psts "
            L"rclt "
            L"rkrf "
            L"rlig "
            L"rphf "
            L"vatu "
            L"vkrn "
            L"vpal "
            ,
        L"required features — "
            L"rlig " // Required ligatures
            L"rclt " // Required contextual alternates
            L"ccmp " // Composition/decomposition
            L"mark " // Mark positioning
            L"mkmk " // Mark to mark positioning
            L"dist " // Distance
            ,
        L"vertical features — "
            L"vert " // Vertical writing
            L"vkrn " // Vertical kerning
            L"vpal " // Vertical proportional alternates
            ,
        L"all features — "
            L"* "    // wildcard
            ,
        L"no features — "
            L""
    };

    const wchar_t* g_defaultStrings[][2] = {
        L"English pangram", L"the quick brown fox jumps over the lazy dog.",
        L"Arabic pangram", L"صِف خَلقَ خَودِ كَمِثلِ الشَمسِ إِذ بَزَغَت - يَحظى الضَجيعُ بِها نَجلاءَ مِعطارِ",
        L"Bulgarian pangram", L"За миг бях в чужд плюшен скърцащ фотьойл.",
        L"Greek pangram", L"Τάχιστη αλώπηξ βαφής ψημένη γη, δρασκελίζει υπέρ νωθρού κυνός",
        L"Hebrew pangram", L"דג סקרן שט בים מאוכזב ולפתע מצא חברה",
        L"Icelandic pangram", L"Kæmi ný öxi hér, ykist þjófum nú bæði víl og ádrepa.",
        L"Japanese pangram", L"とりなくこゑす ゆめさませ みよあけわたる ひんかしを そらいろはえて おきつへに ほふねむれゐぬ もやのうち",
        L"Korean pangram", L"키스의 고유조건은 입술끼리 만나야 하고 특별한 기술은 필요치 않다.",
        L"Myanmar pangram", L"သီဟိုဠ်မှ ဉာဏ်ကြီးရှင်သည် အာယုဝဍ္ဎနဆေးညွှန်းစာကို ဇလွန်ဈေးဘေးဗာဒံပင်ထက် အဓိဋ္ဌာန်လျက် ဂဃနဏဖတ်ခဲ့သည်။",
        L"Thai pangram", L"เป็นมนุษย์สุดประเสริฐเลิศคุณค่า กว่าบรรดาฝูงสัตว์เดรัจฉาน จงฝ่าฟันพัฒนาวิชาการ อย่าล้างผลาญฤๅเข่นฆ่าบีฑาใคร ไม่ถือโทษโกรธแช่งซัดฮึดฮัดด่า หัดอภัยเหมือนกีฬาอัชฌาสัย ปฏิบัติประพฤติกฎกำหนดใจ พูดจาให้จ๊ะๆ จ๋าๆ น่าฟังเอยฯ",
        L"Arabic", L"عربية",
        L"Arabic Persian", L"یونی‌کُد",
        L"Armenian", L"Յունիկօդ",
        L"Bengali", L"য়ূনিকোড",
        L"Bopomofo", L"ㄊㄨㄥ˅ ㄧˋ ㄇㄚ˅",
        L"Braille", L"⠠⠃⠗⠁⠊⠇⠇⠑",
        L"Canadian Aboriginal", L"ᔫᗂᑰᑦ",
        L"Cherokee", L"ᏳᏂᎪᏛ",
        L"Cyrillic", L"Юникод",
        L"Devanagari", L"यूनिकोड",
        L"Ethiopic", L"ዩኒኮድ",
        L"Georgian", L"უნიკოდი",
        L"Greek", L"Γιούνικοντ",
        L"Gujarati", L"યૂનિકોડ",
        L"Gurmukhi", L"ਯੂਨਿਕੋਡ",
        L"Han", L"统一码",
        L"Han Ext-B", L"𠀀𠀁𠀂𠀃𠀄𠀅𠀆𠀇𠀈𠀉𠀊𠀋𠀌𠀍𠀎𠀏",
        L"Hangul", L"유니코드",
        L"Hangul Old", L"갭〔걺〮겈〯〕",
        L"Hebrew", L"יוניקוד",
        L"Japanese", L"ひらがな、カタカナ、漢字",
        L"Hiragana", L"ゆにこおど",
        L"Katakana", L"ユニコード",
        L"Kannada", L"ಯೂನಿಕೋಡ್",
        L"Khmer", L"យូនីគោដ",
        L"Latin IPA", L"ˈjunɪˌkoːd", // L"ˈjunɪˌkoːd", omit
        L"Lao", L"ພາສາລາວ",
        L"Malayalam", L"യൂനികോഡ്",
        L"Mongolian", L"ᠮᠣᠩᠭᠣᠯ",
        L"Myanmar", L"မြန်မာအက္ခရာ",
        L"N'Ko", L"ߒߞߏ",
        L"Ogham", L"ᚔᚒᚅᚔᚉᚑᚇ",
        L"Oriya", L"ୟୂନିକୋଡ",
        L"'Phags-pa", L"ꡁꡅꡜꡤ",
        L"Runic", L"ᛡᚢᚾᛁᚳᚩᛞ",
        L"Sinhala", L"යණනිකෞද්",
        L"Syriac", L"ܝܘܢܝܩܘܕ",
        L"Tamil", L"யூனிகோட்",
        L"Telegu", L"యూనికోడ్",
        L"Thai", L"ภาษาไทย, สวัสดีเช้านี้",
        L"Tibetan (Dzongkha)", L"ཨུ་ནི་ཀོཌྲ།",
        L"Vai", L"ꕙꔤ",
        L"Yi", L"ꆈꌠꁱꂷ",
        L"Numbers", L"0123,456.789",
        };


    typedef AttributeList::Item Ali;

    wchar_t g_iterationCountEdit[11] = L"5000";
    wchar_t g_maxTimeEdit[11] = L"20";

    static AttributeList::Item g_attributeListItems[] = {
        {0,                                 Ali::FlagTitle,                         0,  L"Common"},
        {IdcCommonSelectList,               Ali::FlagButtonType,                    0,  L"Select all list items"},
        {IdcCommonDeselectList,             Ali::FlagButtonType,                    0,  L"Deselect all list items"},
        {IdcCommonInvertList,               Ali::FlagButtonType,                    0,  L"Invert selection of list items"},
        {IdcCommonClearList,                Ali::FlagButtonType,                    0,  L"Clear all list items"},
        {IdcCommonCopyList,                 Ali::FlagButtonType,                    0,  L"Copy list items to clipboard"},
        {0,                                 Ali::FlagSeparator},
                                            
        {IddFontsList,                      Ali::FlagTitle,                         0,  L"Fonts"},
        {IdcFontsLoadFontFiles,             Ali::FlagButtonType,                    0,  L"Load font files..."},
        {IdcFontsLoadSystemFont,            Ali::FlagButtonType,                    0,  L"Load system font..."},
        {IdcFontsLoadAllSystemFonts,        Ali::FlagButtonType,                    0,  L"Load all system fonts"},
        {IdcFontsCopyAllCharacters,         Ali::FlagButtonType|Ali::FlagHidden,    0,  L"Copy all characters in selected fonts"},
        {IdcFontsCopySharedCharacters,      Ali::FlagButtonType|Ali::FlagHidden,    0,  L"Copy shared characters in fonts"},
        {IdcFontsCopyUniqueCharacters,      Ali::FlagButtonType|Ali::FlagHidden,    0,  L"Copy unique characters in fonts"},
        {IdcFontsCopyCharactersFirst,       Ali::FlagButtonMenuType|Ali::FlagHideMark,0,  L"Copy characters ▶", L"in all selected fonts (union)\0" L"shared in fonts (intersection)\0" L"unique in fonts (difference)\0"},
        {IdcFontsCopyCharactersFirst,       Ali::FlagButtonMenuType|Ali::FlagHideMark,0,  L"Select fonts ▶", L"fonts that support current string\0" L"deselect all duplicate font groups\0"},
        {IdcFontsSelectSupportingFonts,     Ali::FlagButtonType|Ali::FlagHidden,    0,  L"Select "},
        {IdcFontsDeselectOtherDuplicates,   Ali::FlagButtonType|Ali::FlagHidden,    0,  L"Deselect other duplicate fonts"},
        {IdcFontsDeselectAllDuplicates,     Ali::FlagButtonType|Ali::FlagHidden,    0,  L"Deselect all duplicate fonts"},

        {IddFontsList,                      Ali::FlagSeparator},

        {IddStringsList,                    Ali::FlagTitle,                         0,  L"Strings"},
        {IdcStringsSelectFirst,             Ali::FlagButtonMenuType|Ali::FlagHideMark,0,  L"Select strings ▶", L"shared strings in fonts\0" L"simple strings in fonts\0" L"all strings in fonts\0"},


        {IdcStringsCopyStrings,             Ali::FlagButtonType,                    0,  L"Copy selected strings"},
        {IdcStringsEditStrings,             Ali::FlagButtonType|Ali::FlagHidden,    0,  L"Edit with editor..."},
        {IdcStringsReloadFile,              Ali::FlagButtonType|Ali::FlagHidden,    0,  L"Reload file"},
        {IdcStringsResetDefaults,           Ali::FlagButtonType,                    0,  L"Reset string defaults"},
        {IddStringsList,                    Ali::FlagSeparator},

        {IddPerfScore,                      Ali::FlagTitle,                         0,  L"Perf"},
        {IdcPerfIterations,                 Ali::FlagEditType,                      ARRAY_SIZE(g_iterationCountEdit) - 1, L"Iterations: ", g_iterationCountEdit},
        {IdcPerfMaxTime,                    Ali::FlagEditType,                      ARRAY_SIZE(g_maxTimeEdit) - 1, L"Max time: ", g_maxTimeEdit},
        {IdcPerfGrouping,                   Ali::FlagOptionType|Ali::FlagHideMark,  0,  L"Grouping: ", L"String/font\0" L"Font file\0" L"String\0" L"None\0"  L"All\0"},
        {IdcPerfSkipPartialCoverageFonts,   Ali::FlagOptionType|Ali::FlagHideMark,  1,  L"Partial font coverage: ", L"Profile anyway\0" L"Skip\0"},
        {IdcPerfProfileStart,               Ali::FlagButtonType,                    0,  L"Start profile"},
        {IdcPerfProfileStop,                Ali::FlagButtonType,                    0,  L"Stop profile"},
        {IdcPerfResultsSave,                Ali::FlagButtonType,                    0,  L"Save results..."},
        {IddPerfScore,                      Ali::FlagSeparator},

        {IddLookupsList,                    Ali::FlagTitle,                         0,  L"Lookups"},
        {IdcLookupsIdentifyApplicable,      Ali::FlagButtonType,                    0,  L"Identify applicable lookups"},
        {IdcLookupsIdentifySimple,          Ali::FlagButtonType,                    0,  L"Identify lookups on simple text"},
        {IdcLookupsIdentifyFeatures,        Ali::FlagButtonType,                    0,  L"Identify current feature lookups"},
        {IdcLookupsShowAll,                 Ali::FlagButtonType,                    0,  L"Show all font lookups"},
        {IdcLookupsShowItemDetails,         Ali::FlagOptionType|Ali::FlagHideMark,  2,  L"Details: ", L"Least\0" L"Less\0" L"More\0" L"Most\0"},
        {IddLookupsList,                    Ali::FlagSeparator},

        {IddActionsList,                    Ali::FlagTitle,                         0,  L"Actions"},
        {IdcActionsListStart,               Ali::FlagButtonType,                    0,  L"Start"},
        {IdcActionsListPause,               Ali::FlagButtonType,                    0,  L"Pause"},
        {IdcActionsListStop,                Ali::FlagButtonType,                    0,  L"Stop"},
        {IdcActionsListLoad,                Ali::FlagButtonType,                    0,  L"Load..."},
        {IddActionsList,                    Ali::FlagSeparator},

        {IDCANCEL,                          Ali::FlagButtonType,                    0,  L"Exit"},
    };

    const uint32_t g_commandToPaneIdMap[][2] = {
        IddFontsList,                   IddFontsList,
        IdcFontsLoadFontFiles,          IddFontsList,
        IdcFontsLoadSystemFont,         IddFontsList,
        IdcFontsLoadAllSystemFonts,     IddFontsList,
        IdcFontsCopyAllCharacters,      IddFontsList,
        IdcFontsCopySharedCharacters,   IddFontsList,
        IdcFontsCopyUniqueCharacters,   IddFontsList,
        IdcFontsSelectSupportingFonts,  IddFontsList,
        IdcFontsDeselectOtherDuplicates,IddFontsList,
        IdcFontsDeselectAllDuplicates,  IddFontsList,

        IddStringsList,                 IddStringsList,
        IdcStringsSelectSharedInFonts,  IddStringsList,
        IdcStringsSelectSimpleInFonts,  IddStringsList,
        IdcStringsSelectAllInFonts,     IddStringsList,
        IdcStringsCopyStrings,          IddStringsList,
        IdcStringsEditStrings,          IddStringsList,
        IdcStringsReloadFile,           IddStringsList,
        IdcStringsResetDefaults,        IddStringsList,
        IdcStringsListAddString,        IddStringsList,

        IddPerfScore,                   IddPerfScore,
        IdcPerfIterations,              IddPerfScore,
        IdcPerfMaxTime,                 IddPerfScore,
        IdcPerfGrouping,                IddPerfScore,
        IdcPerfSkipPartialCoverageFonts,IddPerfScore,
        IdcPerfProfileStart,            IddPerfScore,
        IdcPerfProfileStop,             IddPerfScore,
        IdcPerfResultsSave,             IddPerfScore,

        IddLookupsList,                 IddLookupsList,
        IdcLookupsIdentifyApplicable,   IddLookupsList,
        IdcLookupsIdentifySimple,       IddLookupsList,
        IdcLookupsIdentifyFeatures,     IddLookupsList,
        IdcLookupsShowAll,              IddLookupsList,
        IdcLookupsShowItemDetails,      IddLookupsList,

        IddActionsList,                 IddActionsList,
        IdcActionsListStart,            IddActionsList,
        IdcActionsListPause,            IddActionsList,
        IdcActionsListStop,             IddActionsList,
        IdcActionsListLoad,             IddActionsList,
    };

    const static wchar_t* g_helpText[][2] = {
        L"Load font files",
            L"Load specific font files (multiple selection via Control and Shift keys).",
        L"Load system font",
            L"Load a single system font via the font chooser.",
        L"Load all system fonts",
            L"Load all the Windows system fonts at once.",
        L"Copy all characters in selected fonts",
            L"Copy all the characters from all selected fonts (union).",
        L"Copy shared characters in fonts",
            L"Copy characters common to all selected fonts (intersection).",
        L"Copy unique characters in fonts",
            L"Copy characters unique to each font.",
        L"Select fonts that support string",
            L"Select all fonts that completely support the string.",
        L"Select shared strings in fonts",
            L"Select sample strings that are common to all selected fonts (intersection).",
        L"Select simple strings in fonts",
            L"Select only the shared strings in fonts which are also simple.",
        L"Select all strings in fonts",
            L"Select strings that any fonts fully support.",
        L"Copy selected strings",
            L"Copy the strings selected to the clipboard.",
        L"Reset string defaults",
            L"Reload the default sample strings.",
        L"Iterations",
            L"Maximum number of times to repeat layout and shaping calls.",
        L"Max time",
            L"Maximum time to profile (to cap the profiling).",
        L"Start profile",
            L"Start profiling layout and shaping time.",
        L"Stop profile",
            L"Stop profiling layout and shaping time.",
        L"Save perf results",
            L"Save the profiled perf results to a file.",
        L"Skip identical fonts",
            L"Skip the second font if it has identical bits to an earlier one.",
        L"Skip partial coverage fonts",
            L"Skip the a font if it only covers some characters in the string.",
        L"Identify all non-simple lookups",
            L"Identify any lookups that cause a slowdown for previously simple text (regardless of string selection).",
        L"Identify applicable lookups",
            L"Identify lookups that apply to the text in the selected strings and features.",
        L"Show all font lookups",
            L"Display all lookups in the font tables.",
        };

    const uint32_t g_automatedActionTimeOut = 20;
    const uint32_t g_automatedActionMaximum = 1024; // Arbitrary, but prevents self-referential recursion if including a file from itself
    const uint32_t g_automatedActionIdleTimeOut = 1000;

    enum AutomatedAction
    {
        AutomatedActionInvalid,
        AutomatedActionLoadActionsFile,
        AutomatedActionLoadFont,
        AutomatedActionAddString,
        AutomatedActionSelectString,
        AutomatedActionSelectFullySupportedStrings,
        AutomatedActionSelectPartiallySupportedStrings,
        AutomatedActionStartProfile,
        AutomatedActionStopProfile,
        AutomatedActionWaitProfile,
        AutomatedActionSavePerfResults,
        AutomatedActionPerfGrouping,
        AutomatedActionSkipPartialCoverageFonts,
        AutomatedActionIterations,
        AutomatedActionMaxTime,
        AutomatedActionShowAllLookups,
        AutomatedActionDeselectDuplicateFonts,
        AutomatedActionDeselectAllDuplicateFonts,
        AutomatedActionExit,
    };

    struct NameToValueMapping
    {
        const wchar_t* name;
        const wchar_t* description;
        uint32_t value;
    };

    const static NameToValueMapping g_automatedActionMap[] = {
        {L"Actions", L"Load actions text file", AutomatedActionLoadActionsFile},
        {L"LoadFont", L"Load given font (d:\\fonts\\**\\cursive\\an*.?tf)", AutomatedActionLoadFont},
        {L"AddString", L"Add string to strings list", AutomatedActionAddString},
        {L"SelectString", L"Select given string", AutomatedActionSelectString},
        {L"SelectFullySupportedStrings", L"Select all strings fully supported by selected fonts", AutomatedActionSelectFullySupportedStrings},
        {L"SelectPartiallySupportedStrings", L"Select all strings at least partially supported by selected fonts", AutomatedActionSelectPartiallySupportedStrings},
        {L"StartProfile", L"Start profiling", AutomatedActionStartProfile},
        {L"StartProfile", L"Stop profiling", AutomatedActionStopProfile},
        {L"WaitProfile", L"Wait for profiling to finish before continuing", AutomatedActionWaitProfile},
        {L"DeselectDuplicateFonts", L"Deselect other identical fonts, leaving one font of that group", AutomatedActionDeselectDuplicateFonts},
        {L"DeselectAllDuplicateFonts", L"Deselect all identical duplicates of a group", AutomatedActionDeselectAllDuplicateFonts},
        {L"PerfGrouping", L"How to group perf results", AutomatedActionPerfGrouping},
        {L"SavePerfResults", L"Write completed performance report", AutomatedActionSavePerfResults},
        {L"SkipPartialCoverageFonts", L"Skip fonts that partially cover the string", AutomatedActionSkipPartialCoverageFonts},
        {L"Iterations", L"Maximum number of times to repeat layout and shaping calls", AutomatedActionIterations},
        {L"MaxTime", L"Maximum number of seconds to repeat layout and shaping calls", AutomatedActionMaxTime},
        {L"ShowAllLookups", L"Identify lookups that apply to the text in the selected strings and features.", AutomatedActionShowAllLookups},
        {L"Exit", L"Exit the program", AutomatedActionExit},
    };

    ////////////////////////////////////////

    struct ListViewWriter : LVITEM
    {
    public:
        HWND hwnd;

    public:
        ListViewWriter(HWND listHwnd)
        {
            ZeroStructure(*(LVITEM*)this);
            this->mask = LVIF_TEXT; // LVIF_PARAM | LVIF_IMAGE | LVIF_STATE; 
            this->hwnd = listHwnd;
        }

        void InsertItem(wchar_t const* text = L"")
        {
            this->pszText = (LPWSTR)text;
            this->iSubItem = 0;
            ListView_InsertItem(this->hwnd, this);
        }

        void SetItemText(int j, wchar_t const* text)
        {
            this->pszText  = (LPWSTR)text;
            this->iSubItem = j;
            ListView_SetItem(this->hwnd, this);
        }

        void AdvanceItem()
        {
            ++this->iItem;
        }

        void SelectAndFocusItem(int i)
        {
            uint32_t state = (i == -1) ? LVIS_SELECTED : LVIS_FOCUSED|LVIS_SELECTED;
            ListView_SetItemState(this->hwnd, i, state, state);
        }

        void SelectItem(int i)
        {
            uint32_t state = LVIS_SELECTED;
            ListView_SetItemState(this->hwnd, i, state, state);
        }

        void SelectItem()
        {
            SelectItem(this->iItem);
        }

        void FocusItem(int i)
        {
            assert(i != -1);
            uint32_t state = LVIS_FOCUSED;
            ListView_SetItemState(this->hwnd, i, state, state);
        }

        void DisableDrawing()
        {
            SendMessage(this->hwnd, WM_SETREDRAW, 0, 0);
        }

        void EnableDrawing()
        {
            SendMessage(this->hwnd, WM_SETREDRAW, 1, 0);
        }

        void EnsureVisible()
        {
            ListView_EnsureVisible(this->hwnd, this->iItem, false); // scroll down if needed
        }
    };


    std::wstring GetListViewText(
        HWND listViewHwnd,
        __in_z const wchar_t* separator
        )
    {
        std::wstring text;
        wchar_t itemTextBuffer[256];
        wchar_t groupTextBuffer[256];

        LVITEMINDEX listViewIndex = {-1, -1};

        // Setup the item to retrieve text.
        LVITEM listViewItem;
        listViewItem.mask       = LVIF_TEXT | LVIF_GROUPID;
        listViewItem.iSubItem   = 0;

        // Setup the group to retrieve text.
        LVGROUP listViewGroup;
        listViewGroup.cbSize    = sizeof(LVGROUP);
        listViewGroup.mask      = LVGF_HEADER | LVGF_GROUPID;
        listViewGroup.iGroupId  = 0;
        int previousGroupId     = -1;

        const uint32_t columnCount = Header_GetItemCount(ListView_GetHeader(listViewHwnd));
        std::vector<int32_t> columnOrdering(columnCount);
        ListView_GetColumnOrderArray(listViewHwnd, columnCount, OUT columnOrdering.data());

        // Find the first selected row. If nothing is selected, then we'll copy the entire text.
        uint32_t searchMask = LVNI_SELECTED;
        ListView_GetNextItemIndex(listViewHwnd, &listViewIndex, searchMask);
        if (listViewIndex.iItem < 0)
        {
            searchMask = LVNI_ALL;
            ListView_GetNextItemIndex(listViewHwnd, &listViewIndex, searchMask);
        }

        // Build up a concatenated string.
        // Append next item's column to the text. (either the next selected or all)
        while (listViewIndex.iItem >= 0)
        {
            for (uint32_t column = 0; column < columnCount; ++column)
            {
                int32_t columnIndex = columnOrdering[column];

                if (ListView_GetColumnWidth(listViewHwnd, columnIndex) <= 0)
                    continue; // Skip zero-width columns.

                // Set up fields for call. We must reset the string pointer
                // and count for virtual listviews because while it copies the
                // text out to our buffer, it also messes with the pointer.
                // Otherwise the next call will crash.
                itemTextBuffer[0]       = '\0';
                listViewItem.iItem      = listViewIndex.iItem;
                listViewItem.iSubItem   = columnIndex;
                listViewItem.pszText    = (LPWSTR)itemTextBuffer;
                listViewItem.cchTextMax = ARRAYSIZE(itemTextBuffer);
                ListView_GetItem(listViewHwnd, &listViewItem);

                // Append the group name if we changed to a different group.
                if (listViewItem.iGroupId != previousGroupId)
                {
                    // Add an extra blank line between the previous group.
                    if (previousGroupId >= 0)
                    {
                        text += L"\r\n";
                    }
                    previousGroupId = listViewItem.iGroupId;

                    // Add group header (assuming it belongs to a group).
                    if (listViewItem.iGroupId >= 0)
                    {
                        groupTextBuffer[0]      = '\0';
                        listViewGroup.pszHeader = (LPWSTR)groupTextBuffer;
                        listViewGroup.cchHeader = ARRAYSIZE(groupTextBuffer);
                        ListView_GetGroupInfo(listViewHwnd, listViewItem.iGroupId, &listViewGroup);

                        text += L"― ";
                        text += groupTextBuffer;
                        text += L" ―\r\n";
                    }
                }

                text += itemTextBuffer;

                // Append a new line if last column, or the separator if between columns.
                if (column + 1 >= columnCount)
                {
                    text += L"\r\n";
                }
                else
                {
                    text += separator; // may be a tab, or other separator such as comma or field/value pair ": "
                }
            } // for column
        
            if (!ListView_GetNextItemIndex(listViewHwnd, &listViewIndex, searchMask))
                break;
        } // while iItem

        text.shrink_to_fit();

        return text;
    }


    void InvertListViewSelection(HWND listHwnd)
    {
        auto itemCount = ListView_GetItemCount(listHwnd);

        for (int i = 0; i < itemCount; ++i)
        {
            uint32_t state = ListView_GetItemState(listHwnd, i, LVIS_SELECTED);
            ListView_SetItemState(listHwnd, i, ~state & LVIS_SELECTED, LVIS_SELECTED);
        }
    }


    ////////////////////////////////////////

    class CustomPrivateFontCollectionEnumerator : public ComBase<IDWriteFontFileEnumerator>
    {
    protected:
        IFACEMETHODIMP QueryInterface(IID const& iid, __out void** object) OVERRIDE
        {
            COM_BASE_RETURN_INTERFACE(iid, IDWriteFontFileEnumerator, object);
            COM_BASE_RETURN_INTERFACE(iid, IUnknown, object);
            COM_BASE_RETURN_NO_INTERFACE(object);
        }
  
    public:  
        CustomPrivateFontCollectionEnumerator()
        :   remainingFontFileNames_(nullptr),
            findHandle_(INVALID_HANDLE_VALUE)
        { }  


        ~CustomPrivateFontCollectionEnumerator()
        {
            if (findHandle_ != INVALID_HANDLE_VALUE)
            {
                FindClose(findHandle_);
            }
        }


        HRESULT Initialize(
            _In_ IDWriteFactory* factory,
            _In_bytecount_(fontFileNamesKeySize) const wchar_t* fontFileNames,
            uint32_t fontFileNamesKeySize
            )
        {  
            if (factory == nullptr || fontFileNames == nullptr || !fontFileNames[0])
                return E_INVALIDARG;

            factory_ = factory;
            remainingFontFileNames_ = fontFileNames;
            remainingFontFileNamesEnd_ = PtrAddByteOffset(fontFileNames, fontFileNamesKeySize);
            return S_OK;
        }


        static const wchar_t* FindFileNameStart(const wchar_t* fileName, const wchar_t* fileNamesEnd)
        {
            const wchar_t* p = std::find(fileName, fileNamesEnd, '\0');
            while (p != fileName)
            {
                --p;
                wchar_t ch = *p;
                if (ch == '\\' || ch == '/' || ch == ':')
                {
                    ++p;
                    break;
                }
            }

            return p;
        }
  

        IFACEMETHODIMP MoveNext(_Out_ BOOL* hasCurrentFile)  
        {  
            HRESULT hr = S_OK;
            *hasCurrentFile = false;
            currentFontFile_ = nullptr;

            try
            {
                // Get next filename.
                for (;;)
                {
                    // Check for the end of the list, either reaching the end
                    // of the key or double-nul termination.
                    if (remainingFontFileNames_ >= remainingFontFileNamesEnd_
                    ||  remainingFontFileNames_[0] == '\0')
                    {
                        return hr;
                    }

                    // Get either the first file or next one matching the mask.
                    if (findHandle_ == INVALID_HANDLE_VALUE)
                    {
                        findHandle_ = FindFirstFile(remainingFontFileNames_, OUT &findData_);
                        if (findHandle_ == INVALID_HANDLE_VALUE)
                        {
                            return HRESULT_FROM_WIN32(ERROR_INSUFFICIENT_BUFFER);
                        }
                    }
                    else if (!FindNextFile(findHandle_, OUT &findData_))
                    {
                        // Move to next filename (skipping the nul).
                        remainingFontFileNames_ += wcslen(remainingFontFileNames_) + 1;

                        FindClose(findHandle_);
                        findHandle_ = INVALID_HANDLE_VALUE;

                        continue; // Move to next file mask.
                    }

                    if (!(findData_.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)) // Skip directories.
                        break; // Have our file.
                }

                // Concatenate the path and current file name.
                const wchar_t* fileNameStart = FindFileNameStart(remainingFontFileNames_, remainingFontFileNamesEnd_);
                fullPath_.assign(remainingFontFileNames_, fileNameStart);
                fullPath_ += findData_.cFileName;

                currentFontFile_.Clear();
                IFR(factory_->CreateFontFileReference(
                    fullPath_.c_str(),
                    &findData_.ftLastWriteTime,
                    &currentFontFile_
                    ));

                *hasCurrentFile = true;
            }
            catch (...)
            {
                hr = ExceptionToHResult();
            }

            return hr;
        }  
  
        IFACEMETHODIMP GetCurrentFontFile(_Out_ IDWriteFontFile** fontFile)  
        {  
            *fontFile = currentFontFile_;
            currentFontFile_->AddRef();
            return S_OK;
        }  
  
    private:  
        ComPtr<IDWriteFactory> factory_;
        ComPtr<IDWriteFontFile> currentFontFile_;
        const wchar_t* remainingFontFileNames_;
        const wchar_t* remainingFontFileNamesEnd_;
        HANDLE findHandle_;
        WIN32_FIND_DATA findData_;
        std::wstring fullPath_;
    };


    class CustomPrivateFontCollectionLoader : public ComBase<IDWriteFontCollectionLoader, RefCountBaseStatic>
    {
    protected:
        IFACEMETHODIMP QueryInterface(IID const& iid, __out void** object) OVERRIDE
        {
            COM_BASE_RETURN_INTERFACE(iid, IDWriteFontCollectionLoader, object);
            COM_BASE_RETURN_INTERFACE(iid, IUnknown, object);
            COM_BASE_RETURN_NO_INTERFACE(object);
        }
  
    public:
        IFACEMETHODIMP CreateEnumeratorFromKey(
            _In_ IDWriteFactory* factory,
            _In_bytecount_(collectionKeySize) void const* collectionKey,
            uint32_t collectionKeySize,
            _Out_ IDWriteFontFileEnumerator** fontFileEnumerator
            )
        {
            ComPtr<CustomPrivateFontCollectionEnumerator> p(new CustomPrivateFontCollectionEnumerator());

            HRESULT hr;
            // The collectionKeySize is ignored here, since it is double-nul terminated.
            const wchar_t* fontFileNames = reinterpret_cast<const wchar_t*>(collectionKey);
            IFR(hr = p->Initialize(factory, fontFileNames, collectionKeySize));

            *fontFileEnumerator = p.Detach();
  
            return hr;
        }  
  
        static IDWriteFontCollectionLoader* GetInstance()  
        {  
            return &singleton_;
        }  
  
    private:  
        static CustomPrivateFontCollectionLoader singleton_;
    };
  
    CustomPrivateFontCollectionLoader CustomPrivateFontCollectionLoader::singleton_;
  
 
    HRESULT CreateFontCollection(
        _In_ IDWriteFactory* factory,
        _In_bytecount_(fontFileNamesByteSize) const wchar_t* fontFileNames,
        _In_ uint32_t fontFileNamesByteSize,
        _Out_ IDWriteFontCollection** fontCollection
        )
    {  
        RETURN_ON_ZERO(CustomPrivateFontCollectionLoader::GetInstance(), E_FAIL);

        HRESULT hr = S_OK;
        
        IFR(factory->RegisterFontCollectionLoader(CustomPrivateFontCollectionLoader::GetInstance()));
        hr = factory->CreateCustomFontCollection(CustomPrivateFontCollectionLoader::GetInstance(), fontFileNames, fontFileNamesByteSize, fontCollection);
        IFR(factory->UnregisterFontCollectionLoader(CustomPrivateFontCollectionLoader::GetInstance()));

        return hr;
    }  
  

    HRESULT CreateFontFace(
        const wchar_t* fontFilePath,
        uint32_t fontFaceIndex,
        __out IDWriteFontFace** fontFace
        )
    {
        ComPtr<IDWriteFontFile> fontFile;

        IFR(Application::g_DWriteFactory->CreateFontFileReference(
                fontFilePath,
                nullptr, 
                &fontFile
                ));

        BOOL isSupportedFontType;
        DWRITE_FONT_FILE_TYPE fontFileType;
        DWRITE_FONT_FACE_TYPE fontFaceType;
        uint32_t numberOfFaces;

        IFR(fontFile->Analyze(
                &isSupportedFontType,
                &fontFileType,
                &fontFaceType,
                &numberOfFaces
                ));

        if (!isSupportedFontType)
        {
            return DWRITE_E_FILEFORMAT;
        }

        assert(fontFaceIndex < numberOfFaces);

        IDWriteFontFile* fontFileArray[] = {fontFile};
        IFR(Application::g_DWriteFactory->CreateFontFace(
                fontFaceType,
                ARRAYSIZE(fontFileArray),
                fontFileArray,
                fontFaceIndex ,
                DWRITE_FONT_SIMULATIONS_NONE,
                fontFace
                ));

        return S_OK;
    }


    HRESULT CreateTextLayout(
        IDWriteFactory* factory,
        __in_ecount(textLength) wchar_t const* text,
        uint32_t textLength,
        IDWriteTextFormat* textFormat,
        float maxWidth,
        float maxHeight,
        DWRITE_MEASURING_MODE measuringMode,
        __out IDWriteTextLayout** textLayout
        )
    {
        if (measuringMode == DWRITE_MEASURING_MODE_NATURAL)
        {
            return factory->CreateTextLayout(
                                text,
                                textLength,
                                textFormat,
                                maxWidth,
                                maxHeight,
                                textLayout
                                );
        }
        else
        {
            return factory->CreateGdiCompatibleTextLayout(
                                text,
                                textLength,
                                textFormat,
                                maxWidth,
                                maxHeight,
                                1, // pixels per DIP
                                nullptr, // no transform
                                (measuringMode == DWRITE_MEASURING_MODE_GDI_NATURAL) ? true : false,
                                textLayout
                                );
        }
    }


    ////////////////////////////////////////

    bool IsFeatureTagSeparator(char32_t ch)
    {
        return ch == ' ' || ch == ',';
    }

    bool IsCommentDivider(char32_t ch)
    {
        return ch == '-' || ch == 0x2014;
    }

    std::vector<uint32_t> GetFeatureTagsFromText(const wchar_t* text)
    {
        std::vector<uint32_t> desiredFeatures;

        const size_t textLength = wcslen(text);
        union
        {
            uint8_t  tag[4];
            uint32_t tag4CC;
        } tag;

        // Find any comment dividers by walking backwards.
        size_t i = textLength;
        for (; i > 0; --i)
        {
            if (IsCommentDivider(text[i - 1]))
                break;
        }

        // Read each space/comma separated tag.
        while (i < textLength)
        {
            tag.tag4CC = '    '; // pad empty part of tag with space (not null)

            // Skip all separators.
            while (IsFeatureTagSeparator(text[i])) {++i;}
            if (i >= textLength)
                break;

            // Wildcard returns empty list to indicate everything.
            if (text[i] == '*')
            {
                desiredFeatures.clear();
                break;
            }

            // Copy tag and append.
            for (size_t j = 0; text[i] && !IsFeatureTagSeparator(text[i]); ++i, ++j)
            {
                if (j < 4)
                    tag.tag[j] = uint8_t(text[i]);
            }
            if (tag.tag4CC != '    ')
                desiredFeatures.push_back(tag.tag4CC);
        }

        return desiredFeatures;   
    }


    bool GetBooleanValue(__in_z_opt const wchar_t* string, bool defaultValue)
    {
        if (string == nullptr || string[0] == '\0')
            return defaultValue;

        if (_wcsicmp(string, L"true") == 0
        ||  _wcsicmp(string, L"yes") == 0
        ||  _wcsicmp(string, L"on") == 0)
        {
            return true;
        }
        if (_wcsicmp(string, L"false") == 0
        ||  _wcsicmp(string, L"no") == 0
        ||  _wcsicmp(string, L"off") == 0)
        {
            return false;
        }

        return defaultValue;
    }


    void FormatPerfTime(
        IN OUT std::wstring& text,
        MainWindow::PerfTime result
        )
    {
        if (result.IsEmpty())
        {
            text.assign(L"⏳", 1);
        }
        else
        {
            result.PreventDivisionByZero();
            MainWindow::Format(text, L"%f\t (%f×%d)", result.Seconds(), result.SecondsPerIteration(), result.iterations);
        }
    }

    void FormatPerfTimeDelta(
        IN OUT std::wstring& text,
        MainWindow::PerfTime fastestResult,
        MainWindow::PerfTime slowestResult
        )
    {
        MainWindow::Format(
            text,
            L"%1.2fx\t (%f/%f)",
            float(slowestResult.milliseconds) / std::max(fastestResult.milliseconds, 1u),
            slowestResult.Seconds(),
            fastestResult.Seconds()
            );
    }

    ////////////////////////////////////////

    class TextRendererRecorder : public ComBase<IDWriteTextRenderer, RefCountBaseStatic>
    {
    public:
        struct InlineImageInfo
        {
            float originX;
            float originY;
            bool  isRightToLeft;
            bool  isSideways;
        };

        uint32_t totalGlyphRuns_;
        std::vector<uint16_t> glyphIds_;
        std::vector<DWRITE_GLYPH_OFFSET> glyphOffsets_;
        std::vector<InlineImageInfo> inlineImageInfo_;

    public:
        TextRendererRecorder()
            :   totalGlyphRuns_()
        { }

        HRESULT Record(IDWriteTextLayout* textLayout)
        {
            Clear();
            return textLayout->Draw(nullptr, this, 0, 0);
        }

        void Clear()
        {
            totalGlyphRuns_ = 0;
            glyphIds_.clear();
            glyphOffsets_.clear();
            inlineImageInfo_.clear();
        }

        // IDWriteTextRenderer interface

        HRESULT STDMETHODCALLTYPE DrawGlyphRun(
            __maybenull void* clientDrawingContext,
            FLOAT baselineOriginX,
            FLOAT baselineOriginY,
            DWRITE_MEASURING_MODE measuringMode,
            __in DWRITE_GLYPH_RUN const* glyphRun,
            __in DWRITE_GLYPH_RUN_DESCRIPTION const* glyphRunDescription,
            __maybenull IUnknown* clientDrawingEffect
            ) throw() OVERRIDE
        {
            // Record the glyph id's and (if given) offsets.
            DWRITE_GLYPH_RUN const& gr = *glyphRun;

            glyphIds_.insert(glyphIds_.end(), gr.glyphIndices, gr.glyphIndices + gr.glyphCount);
            if (gr.glyphOffsets != nullptr)
            {
                glyphOffsets_.insert(glyphOffsets_.end(), gr.glyphOffsets, gr.glyphOffsets + gr.glyphCount);
            }
            else
            {
                const static DWRITE_GLYPH_OFFSET zeroGlyphOffset = {};
                glyphOffsets_.insert(glyphOffsets_.end(), gr.glyphCount, zeroGlyphOffset);
            }

            ++totalGlyphRuns_;

            return S_OK;
        }

        HRESULT STDMETHODCALLTYPE DrawUnderline(
            __maybenull void* clientDrawingContext,
            FLOAT baselineOriginX,
            FLOAT baselineOriginY,
            __in DWRITE_UNDERLINE const* underline,
            __maybenull IUnknown* clientDrawingEffect
            ) throw() OVERRIDE
        {
            return S_OK;
        }

        HRESULT STDMETHODCALLTYPE DrawStrikethrough(
            __maybenull void* clientDrawingContext,
            FLOAT baselineOriginX,
            FLOAT baselineOriginY,
            __in DWRITE_STRIKETHROUGH const* strikethrough,
            __maybenull IUnknown* clientDrawingEffect
            ) throw() OVERRIDE
        {
            return S_OK;
        }

        HRESULT STDMETHODCALLTYPE DrawInlineObject(
            __maybenull void* clientDrawingContext,
            FLOAT originX,
            FLOAT originY,
            IDWriteInlineObject* inlineObject,
            BOOL isSideways,
            BOOL isRightToLeft,
            __maybenull IUnknown* clientDrawingEffect
            ) throw() OVERRIDE
        {
            InlineImageInfo info = {};
            info.originX        = originX;
            info.originY        = originY;
            info.isRightToLeft  = !!isRightToLeft;
            info.isSideways     = !!isSideways;

            inlineImageInfo_.push_back(info);
            return S_OK;
        }

        HRESULT STDMETHODCALLTYPE IsPixelSnappingDisabled(
            __maybenull void* clientDrawingContext,
            __out BOOL* isDisabled
            ) throw() OVERRIDE
        {
            *isDisabled = true;
            return S_OK;
        }

        HRESULT STDMETHODCALLTYPE GetCurrentTransform(
            __maybenull void* clientDrawingContext,
            __out DWRITE_MATRIX* transform
            ) throw() OVERRIDE
        {
            const static DWRITE_MATRIX identityTransform = {1,0,0,1,0,0};
            *transform = identityTransform;
            return S_OK;
        }

        HRESULT STDMETHODCALLTYPE GetPixelsPerDip(
            __maybenull void* clientDrawingContext,
            __out FLOAT* pixelsPerDip
            ) throw() OVERRIDE
        {
            *pixelsPerDip = 1.0f;
            return S_OK;
        }

        ////////////////////////////////////////
        // Static IUnknown interface
        // *It's test code, and there will only be one instance!

        IFACEMETHODIMP QueryInterface(IID const& iid, __out void** object) OVERRIDE
        {
            COM_BASE_RETURN_INTERFACE(iid, IDWriteTextRenderer, object);
            COM_BASE_RETURN_INTERFACE(iid, IDWritePixelSnapping, object);
            COM_BASE_RETURN_INTERFACE(iid, IUnknown, object);
            COM_BASE_RETURN_NO_INTERFACE(object);
        }
    };


    ////////////////////////////////////////

    class RegistryValueIterator
    {
    public:
        RegistryValueIterator(HKEY hiveKey, __in_z wchar_t const* keyName)
        :   haveHandle_(false),
            valueIndex_(0),
            valueCount_(0),
            currentValueName_(MAX_PATH, L'\0'),
            currentValueData_(MAX_PATH * sizeof(wchar_t))
        {
            long err = RegOpenKeyEx(
                            hiveKey,
                            keyName,
                            0,
                            KEY_READ,
                            reinterpret_cast<HKEY *>(&handle_)
                            );

            if (err == ERROR_SUCCESS)
            {
                haveHandle_ = true;

                RegQueryInfoKey(
                    handle_,
                    nullptr, // lpClass,
                    nullptr, // lpcClass,
                    nullptr, // lpReserved,
                    nullptr, // lpcSubKeys,
                    nullptr, // lpcMaxSubKeyLen,
                    nullptr, // lpcMaxClassLen,
                    (DWORD*)OUT &valueCount_, // lpcValues,
                    nullptr, // lpcMaxValueNameLen,
                    nullptr, // lpcMaxValueLen,
                    nullptr, // lpcbSecurityDescriptor,
                    nullptr  // lpftLastWriteTime
                    );
            }
        }


        ~RegistryValueIterator()
        {
            if (haveHandle_)
                RegCloseKey(handle_);
        }


        bool Advance()
        {
            if (!haveHandle_)
                return false;

            currentValueName_.resize(currentValueName_.capacity());
            currentValueData_.resize(currentValueData_.capacity());

            DWORD nameSize = currentValueName_.size();
            DWORD dataSize = currentValueData_.size();

            for(;;)
            {
                long err = RegEnumValue(
                            handle_,
                            valueIndex_,
                            &currentValueName_[0],
                            &nameSize,
                            nullptr,
                            reinterpret_cast<DWORD*>(&currentValueType_),
                            &currentValueData_[0],
                            &dataSize
                            );

                if (err == ERROR_SUCCESS)
                {
                    break;
                }
                else if (err == ERROR_NO_MORE_ITEMS)
                {
                    return false;
                }
                else if (err != ERROR_MORE_DATA)
                {
                    if (haveHandle_)
                    {
                        RegCloseKey(handle_);
                        haveHandle_ = false;
                    }
                    return false;
                }

                currentValueName_.resize(std::max(currentValueName_.size(), (size_t) nameSize));
                currentValueData_.resize(std::max(currentValueData_.size(), (size_t) dataSize));
            }

            currentValueName_.resize(nameSize);
            currentValueData_.resize(dataSize);

            ++valueIndex_;
            return true;
        }


        wchar_t const* GetCurrentValueName()
        {
            return currentValueName_.data();
        }


        wchar_t const* GetCurrentValueString()
        {
            // Only return single strings, not multistrings or binary data.
            if (currentValueType_ != REG_SZ)
                return nullptr;

            // The data length should include the trailing null.
            const size_t dataLength = currentValueData_.size() / sizeof(wchar_t);
            if (dataLength == 0)
                return nullptr;

            wchar_t const* str = ((wchar_t const*) &currentValueData_[0]);

            // If the string length equals the data length,
            // then our data is missing a trailing null.
            // Note we ignore any additional text after the
            // first null.
            if (wcsnlen(str, dataLength) == dataLength)
                return nullptr;
            else 
                return str;
        }


        std::pair<uint32_t, uint32_t> GetProgress()
        {
            return std::pair<uint32_t, uint32_t>(valueIndex_, valueCount_);
        }

    private:
        bool haveHandle_;
        HKEY handle_;
        uint32_t valueIndex_;
        uint32_t valueCount_;
        std::wstring currentValueName_;
        std::vector<uint8_t> currentValueData_;
        uint32_t currentValueType_;
    };


#if 0 // Refer to FileHelpers.cpp instead.
    enum PathPartType
    {
        PathPartTypeInvalid             = 0x80000000,
        PathPartTypeFileName            = 0x00000000,   // "arial.ttf" (default enum value)
        PathPartTypeMask                = 0x00000001,   // "*.ttf"
        PathPartTypeMultipleMasks       = 0x00000002,   // "*.ttf;*.ttc;*.otf"
        PathPartTypeDirectory           = 0x00000004,   // windows in "c:\windows"
        PathPartTypeDirectoryRecursion  = 0x00000008,   // ** in "c:\users\**\*.otf"
    };

    PathPartType GetNextPathPart(
        const wchar_t* filePath,
        size_t filePathStart,
        OUT size_t* filePathPartBegin,
        OUT size_t* filePathPartEnd
        )
    {
        // Retrieve the next part of the path from the given start, returning
        // the beginning, ending, and type of the path part.
        //
        // Exactly one file with full path.
        //      "c:\windows\fonts\arial.ttf"
        //
        //      "c:"            - Directory
        //      "windows"       - Directory
        //      "fonts"         - Directory
        //      "arial.ttf"     - Filename
        //
        // All font files (TrueType or OpenType) starting with 'a' in all
        // subfolders.
        //
        //      "d:\fonts\micro*\**\a*.ttf;a*.otf"
        //
        //      "d:"            - Directory
        //      "fonts"         - Directory
        //      "micro*"        - Directory Mask
        //      "**"            - Directory Recursion
        //      "a*.ttf;a*.otf" - FileName Mask
        //
        *filePathPartBegin = filePathStart;
        *filePathPartEnd   = filePathStart;

        if (filePath[filePathStart] == '\0')
            return PathPartTypeInvalid;

        PathPartType type = PathPartTypeFileName;
        size_t offset = filePathStart;

        // Skip any leading slashes.
        wchar_t ch;
        while (ch = filePath[offset], ch != '\0')
        {
            if (ch != '\\' && ch != '/')
                break;

            ++offset;
        }
        size_t offsetStart = offset;
        *filePathPartBegin = offset;

        // Read up to a slash or end of the string.
        while (ch = filePath[offset], ch != '\0')
        {
            if (ch == '\\' || ch == '/')
            {
                type = PathPartType(type | PathPartTypeDirectory);
                break;
            }
            else if (ch == '*' || ch == '?')
            {
                type = PathPartType(type | PathPartTypeMask);
            }
            else if (ch == ';')
            {
                type = PathPartType(type | PathPartTypeMultipleMasks);
            }

            ++offset;
        }

        // Set the type according to what was found.
        if (type & PathPartTypeMask)
        {
            if (type & PathPartTypeDirectory)
            {
                if (offset - offsetStart == 2
                &&  filePath[offsetStart] == '*'
                &&  filePath[offsetStart + 1] == '*')
                {
                    type = PathPartType(type | PathPartTypeDirectoryRecursion);
                }
            }
        }

        *filePathPartBegin = offsetStart;
        *filePathPartEnd   = offset;

        return type;
    }


    void EnumerateAndAddToQueue(
        PathPartType type,
        size_t filePathFileNameBegin,
        size_t fileMaskOffset,
        IN OUT std::wstring& filePath,      // full path plus mask on input, but arbitrarily modified on output
        IN OUT std::wstring& fileNames,     // accumulated list of nul-terminated filenames
        IN OUT std::wstring& directoryQueue // accumulated list of nul-terminated subdirectories remaining to process
        )
    {
        // Read all the files in from the given filePath, and appending to the
        // fileNames and directoryQueue.
        //
        // Exactly one file with full path.
        //
        //      "c:\windows\fonts\arial.ttf"
        //
        // All font files (TrueType or OpenType) starting with 'a' in all
        // subfolders.
        //
        //      "d:\fonts\micro*\**\a*.ttf;a*.otf"

        std::wstring mask;
        if (type & PathPartTypeMultipleMasks)
        {
            // If the string contains multiple wildcards separated by
            // semicolons ("*.ttf;*.otf"), which FindFirstFile doesn't
            // understand, then set the FindFirstFile file mask to a
            // wildcard, and explicitly match each filename.
            mask = filePath.substr(filePathFileNameBegin);
            filePath.resize(filePathFileNameBegin);
            filePath.push_back('*');
        }

        WIN32_FIND_DATA findData;
        HANDLE findHandle = FindFirstFile(filePath.c_str(), OUT &findData);
        if (findHandle != INVALID_HANDLE_VALUE)
        {
            bool isFullPathAlreadyStoredInQueue = false;
            do
            {
                if (type & PathPartTypeMultipleMasks)
                {
                    // FindFirstFile returns all filenames, so match explicitly.
                    HRESULT hr = PathMatchSpecEx(findData.cFileName, mask.c_str(), PMSF_MULTIPLE);
                    if (hr != S_OK)
                    {
                        continue; // Skip this one, error or S_FALSE
                    }
                }

                if (findData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)
                {
                    if (type & PathPartTypeDirectory)
                    {
                        // Skip the unnecessary self-referential entries.
                        if (findData.cFileName[0] == '.'
                        && (findData.cFileName[1] == '.' || findData.cFileName[1] == '\0'))
                        {
                            continue;
                        }

                        if (!isFullPathAlreadyStoredInQueue)
                        {
                            // Store the full directory path into the queue for
                            // the following subdirectory names.
                            filePath.resize(filePathFileNameBegin);
                            directoryQueue.push_back('\\');
                            directoryQueue.push_back(wchar_t(fileMaskOffset + 1)); // store the offset as a wchar_t
                            directoryQueue.append(filePath);
                            directoryQueue.push_back('\0');
                            isFullPathAlreadyStoredInQueue = true;
                        }

                        // Append subdirectory name to queue.
                        directoryQueue.append(findData.cFileName);
                        directoryQueue.push_back('\0');
                    }
                }
                else
                {
                    if (!(type & PathPartTypeDirectory))
                    {
                        // Record filename.
                        filePath.resize(filePathFileNameBegin);
                        filePath.append(findData.cFileName);
                        fileNames.append(filePath);
                        fileNames.push_back('\0');
                    }
                }
            }
            while (FindNextFile(findHandle, OUT &findData));

            FindClose(findHandle);
        }
    }


    HRESULT EnumerateMatchingFiles(
        __in_z_opt const wchar_t* fileDirectory,
        __in_z_opt wchar_t const* originalFileMask,
        OUT std::wstring& fileNames
        )
    {
        if (fileDirectory == nullptr)
            fileDirectory = L"";

        if (originalFileMask == nullptr)
            originalFileMask = L"*";

        std::wstring fileMask;      // file mask, combined with the file directory
        std::wstring filePath;      // current file path being enumerated
        std::wstring queuePath;     // most recent path from the queue
        std::wstring directoryQueue;// list of nul-terminated filenames

        size_t queueOffset = 0;
        size_t queueFileMaskOffset = 0;
        size_t fileMaskOffset = 0;
        size_t fileMaskPartBegin = 0;
        size_t fileMaskPartEnd = 0;

        // Combine the mask with file directory.
        fileMask.resize(MAX_PATH);
        PathCombine(&fileMask[0], fileDirectory, originalFileMask);
        fileMask.resize(wcslen(fileMask.data()));

        // Initialize the queue with the first directory to look at (it's actually empty).
        directoryQueue.push_back('\\');
        directoryQueue.push_back(wchar_t(1)); // fileMaskOffset=0+1
        directoryQueue.push_back('\0');

        // Pop an entry from the queue and read all the matching files/directories,
        // pushing any directories onto the queue.
        //
        // The queue stores a series of nul-terminated strings consisting of
        // file paths and subsequent subdirectory names. A file path starts
        // with a '\' and stores a 16-bit index value of where in the mask it
        // should continue matching from.
        //
        for (;;)
        {
            if (queueOffset >= directoryQueue.size())
                break;

            const wchar_t* queueEntryStart = &directoryQueue[queueOffset];
            const size_t queueEntryLength = wcslen(queueEntryStart);
            queueOffset += queueEntryLength + 1;

            // Reading a directory path
            if (*queueEntryStart == '\\')
            {
                queueEntryStart++;
                queueFileMaskOffset = size_t(*queueEntryStart) - 1; // Read wchar_t as size_t, number stored as character
                queueEntryStart++;
                queuePath.assign(queueEntryStart);
                filePath.assign(queuePath);
                if (!filePath.empty())
                {
                    // We're just setting the current path, not enumerating subfolders yet.
                    // If the file path is empty, then it's the special case of the first
                    // time through the loop where the queue doesn't yet have any entries.
                    continue;
                }
            }
            else
            {
                // Reading a subdirectory of the previous full directory path
                filePath.resize(queuePath.size());
                filePath.append(queueEntryStart, queueEntryLength);
                filePath.push_back('\\');
            }
            fileMaskOffset = queueFileMaskOffset;

            PathPartType type = GetNextPathPart(fileMask.data(), fileMaskOffset, OUT &fileMaskPartBegin, OUT &fileMaskPartEnd);
            while (type == PathPartTypeDirectory)
            {
                filePath.append(&fileMask[fileMaskPartBegin], fileMaskPartEnd - fileMaskPartBegin);
                filePath.push_back('\\');
                fileMaskOffset = fileMaskPartEnd;
                type = GetNextPathPart(fileMask.data(), fileMaskOffset, OUT &fileMaskPartBegin, OUT &fileMaskPartEnd);
            }

            const size_t filePathFileNameBegin = filePath.size();

            if (type & PathPartTypeDirectoryRecursion)
            {
                // Read all subdirectories in the current path.
                filePath.push_back(L'*');
                EnumerateAndAddToQueue(
                    type,
                    filePathFileNameBegin,
                    fileMaskPartBegin,
                    IN OUT filePath,
                    IN OUT fileNames,
                    IN OUT directoryQueue
                    );
                filePath.resize(filePathFileNameBegin);

                fileMaskOffset = fileMaskPartEnd;
                type = GetNextPathPart(fileMask.data(), fileMaskOffset, OUT &fileMaskPartBegin, OUT &fileMaskPartEnd);
            }

            // Append the file or folder mask to complete the search path.
            filePath.append(&fileMask[fileMaskPartBegin], fileMaskPartEnd - fileMaskPartBegin);

            EnumerateAndAddToQueue(
                type,
                filePathFileNameBegin,
                fileMaskPartEnd,
                IN OUT filePath,
                IN OUT fileNames,
                IN OUT directoryQueue
                );
        }

        return S_OK;
    }
#endif


    void UnescapeString(
        const wchar_t* escapedText,
        OUT std::wstring& expandedText
        )
    {
        expandedText.clear();

        const wchar_t* p = escapedText;

        for (;;)
        {
            char32_t ch = *p;
            if (ch == '\0')
                break;

            // Check escape codes.
            if (ch == '\\')
            {
                const wchar_t* escapeStart = p;
                wchar_t* escapeEnd = const_cast<wchar_t*>(escapeStart + 1);
                char32_t replacement = L'?';
                ++p;

                switch (*escapeEnd)
                {
                case L'r': // return
                    replacement = L'\r';
                    ++escapeEnd;
                    break;

                case L'n': // new line
                    replacement = L'\n';
                    ++escapeEnd;
                    break;

                case L't': // tab
                    replacement = L'\t';
                    ++escapeEnd;
                    break;

                case L'q': // quote
                    replacement = L'\"';
                    ++escapeEnd;
                    break;

                case L'b': // backspace
                    replacement = 0x0008;
                    ++escapeEnd;
                    break;

                case L'f': // form feed
                    replacement = 0x000C;
                    ++escapeEnd;
                    break;

                case L'x':
                case L'u':
                case L'U':
                    replacement = (char32_t) wcstoul(escapeStart + 2, OUT &escapeEnd, 16);
                    break;

                case L'0': case L'1': case L'2': case L'3': case L'4':
                case L'5': case L'6': case L'7': case L'8': case L'9':
                    // Support decimal here (octal is not supported)
                    replacement = (char32_t) wcstoul(escapeStart + 1, OUT &escapeEnd, 10);
                    break;

                case L'\\':
                    replacement = L'\\';
                    ++escapeEnd;
                    break;

                // Anything else is a question mark.
                }

                if (IsCharacterBeyondBmp(replacement))
                {
                    expandedText.push_back(GetLeadingSurrogate(replacement));
                    expandedText.push_back(GetTrailingSurrogate(replacement));
                }
                else
                {
                    expandedText.push_back(wchar_t(replacement));
                }
                p = escapeEnd;
            }
            else // Just push ordinary code unit
            {
                expandedText.push_back(wchar_t(ch));
                p++;
            }
        }
    }


    ////////////////////////////////////////

    struct Range
    {
        uint32_t start;         // first position
        uint32_t end;           // one-past last 

        Range(uint32_t initialStart, uint32_t initialEnd)
        :   start(initialStart),
            end(initialEnd)
        { }

        Range()
        :   start(0),
            end(UINT32_MAX)
        { }

        static Range FromCount(uint32_t initialStart, uint32_t initialCount) throw()
        {
            return Range(initialStart, initialStart + initialCount);
        }

        uint32_t GetCount() const throw()
        {
            // Empty ranges are clamped to zero.
            return IsEmpty() ? 0 : end - start;
        }

        bool IsEmpty() const throw()
        {
            return end <= start;
        }

        bool IsWellOrdered() const throw()
        {
            return end >= start;
        }

        void MakeWellOrdered() throw()
        {
            if (!IsWellOrdered())
                std::swap(start, end);
        }

        void ClampHigh(uint32_t total) throw()
        {
            if (start >= total) start = total;
            if (end   >= total) end   = total;
        }

        bool ContainsInclusive(uint32_t value) const throw()
        {
            return value >= start && value <= end;
        }

        bool IsWithin(uint32_t startLimit, uint32_t endLimit) const throw()
        {
            return start >= startLimit && end <= endLimit;
        }

        bool IsWithin(const Range& range) const throw()
        {
            return IsWithin(range.start, range.end);
        }

        static Range Intersect(const Range& left, const Range& right) throw()
        {
            // * Returns inverted empty ranges if the ranges do not overlap.
            return Range(left).Intersect(right);
        }

        Range& Intersect(const Range& right) throw()
        {
            start = std::max(start, right.start);
            end   = std::min(end,   right.end);

            return *this;
        }

        static Range Union(const Range& left, const Range& right) throw()
        {
            return Range(left).Union(right);
        }

        Range& Union(const Range& right) throw()
        {
            start = std::min(start, right.start);
            end   = std::max(end,   right.end);

            return *this;
        }
    };


    ////////////////////////////////////////

    struct IntSequence
    {
        IntSequence (int initialValue = 0) : value(initialValue) { }
        int operator() () { return value++; }
        int value;
    };


    template<typename T>
    void GrowVectorTo(std::vector<T>& v, size_t newSize)
    {
        if (newSize > v.size())
            v.resize(newSize);
    }


    uint32_t ConvertUtf16To32(
        const std::wstring& utf16text,
        OUT std::vector<char32_t>& utf32text
        )
    {
        // Convert to UTF32 for simplicity.
        const uint32_t utf16codeUnitLength = static_cast<uint32_t>(utf16text.size());
        GrowVectorTo(utf32text, utf16codeUnitLength);
        const uint32_t utf32textLength =
            ConvertUtf16ToUtf32(
                utf16text.c_str(),
                utf16codeUnitLength,
                OUT utf32text.data(),
                utf16codeUnitLength
                );
        utf32text.resize(utf32textLength);
        return utf32textLength;
    }


    // Return a per-character (0..UnicodeTotal-1) coverage count for all the
    // font faces, where the array index corresponds to each Unicode code point
    // and is incremented once for each font that supports it. If a specific
    // string of characters is passed, the counts for each character are returned.
    std::vector<uint16_t> GetFontCharacterCoverageCounts(
        __in_ecount(fontFacesCount) IDWriteFontFace** fontFaces,
        uint32_t fontFacesCount,
        __in_ecount(unicodeCharactersCount) const char32_t* unicodeCharacters,
        char32_t unicodeCharactersCount,
        std::function<void(uint32_t i, uint32_t total)> progress
        )
    {
        const bool useEntireUnicodeRange = (unicodeCharactersCount == 0);
        if (useEntireUnicodeRange)
        {
            unicodeCharactersCount = UnicodeTotal;
        }

        std::vector<char32_t> allUnicodeCharacters;
        std::vector<uint16_t> coverageCounts(unicodeCharactersCount);
        std::vector<uint16_t> glyphs(unicodeCharactersCount);

        if (useEntireUnicodeRange)
        {
            // No list of characters given, so return the whole Unicode array.
            allUnicodeCharacters.resize(unicodeCharactersCount);
            std::generate(allUnicodeCharacters.begin(), allUnicodeCharacters.end(), IntSequence());
            unicodeCharacters = allUnicodeCharacters.data();
        }

        // Get all the glyphs the font faces support, and increment for each covered character.
        for (uint32_t i = 0; i < fontFacesCount; ++i)
        {
            auto* counts = coverageCounts.data();
            fontFaces[i]->GetGlyphIndices(reinterpret_cast<uint32_t const*>(unicodeCharacters), unicodeCharactersCount, glyphs.data());
            for (char32_t ch = 0; ch < unicodeCharactersCount; ++ch)
            {
                if (glyphs[ch] != 0)
                {
                    if (++counts[ch] == 0)
                        counts[ch] = UINT16_MAX;
                }
            }
            progress(i, fontFacesCount);
        }

        return coverageCounts;
    }


    // Return a UTF-16 string of all the characters supported in the coverage
    // count array. The character coverage range acts as filter to essentially
    // apply boolean operations (union, intersection, uniqueness) across font
    // coverage arrays, as if each font had its own separate parallel coverage
    // array instead of being summed into a single count per character.
    std::wstring GetStringFromCoverageCount(
        __in_ecount(UnicodeTotal) const uint16_t* characterCounts,
        Range characterCountRange
        )
    {
        // Calculate size first, determining needed size for UTF-16.
        size_t textSize = 0;
        for (char32_t ch = 1; ch < UnicodeTotal; ++ch)
        {
            if (characterCountRange.ContainsInclusive(characterCounts[ch]))
            {
                textSize += IsCharacterBeyondBmp(ch) ? 2 : 1;
            }
        }

        // Convert the UTF-32 string (with nul's) to UTF-16.
        // The code points are already in ascending order.
        std::wstring text(textSize, '\0');

        size_t textOffset = 0;
        for (char32_t ch = 1; ch < UnicodeTotal; ++ch)
        {
            if (characterCountRange.ContainsInclusive(characterCounts[ch]))
            {
                textOffset += ConvertUtf32ToUtf16(
                                &ch,
                                1,
                                &text[textOffset],
                                textSize - textOffset
                                );
            }
        }

        return text;
    }


    bool IsCharacterCommonlyCovered(char32_t ch)
    {
        // These characters are commonly covered in fonts, and so they should
        // be ignored when checking for font coverage of a particular script.
        return ch == ' ' || ch == '.' || ch == ',' || ch == 0x2014 || ch == '-';
    }


    enum SelectCoveredStrings_Options
    {
        SelectCoveredStrings_OptionsSkipCommon           = 0x00000001, // ignore all common characters when determining importance
        SelectCoveredStrings_OptionsSkipComplex          = 0x00000002, // skip any complex characters
        SelectCoveredStrings_OptionsSkipComplexAndCommon = SelectCoveredStrings_OptionsSkipCommon | SelectCoveredStrings_OptionsSkipComplex,
        SelectCoveredStrings_OptionsSelectAnyCoverage    = 0x00000004
    };


    void SelectCoveredStrings(
        __in_ecount(stringsListCount) MainWindow::StringInfo* stringsList,
        uint32_t stringsListCount,
        uint32_t fontFacesCount,
        __in_ecount(UnicodeTotal) const uint16_t* characterCounts,
        SelectCoveredStrings_Options options
        )
    {
        std::vector<char32_t> utf32text;

        for (uint32_t i = 0; i < stringsListCount; ++i) // first unselect all strings
            stringsList[i].isSelected = false;

        // Selected all strings that are covered by the fonts.
        for (uint32_t i = 0; i < stringsListCount; ++i)
        {
            auto& stringInfo = stringsList[i];

            if ((options & SelectCoveredStrings_OptionsSkipComplex) && !stringInfo.isSimple)
                continue; // skip complex strings

            // Convert to UTF32 for simplicity.
            const uint32_t utf32textLength = ConvertUtf16To32(stringInfo.sample, OUT utf32text);

            // Count the number of characters covered for this string.
            uint32_t coverageCount = 0;
            uint32_t commonCount = 0;
            uint32_t maxCoverageCount = 0;

            static_assert(sizeof(*characterCounts) == 2, "Expect that charactersCounts[i] is limited to UINT16_MAX.");
            const uint32_t maxCoverageCountPerCharacter = std::min(fontFacesCount, uint32_t(UINT16_MAX));
            maxCoverageCount = maxCoverageCountPerCharacter * utf32textLength;

            // Check each character's coverage.
            for (uint32_t j = 0; j < utf32textLength; ++j)
            {
                auto ch = utf32text[j];
                auto characterCount = characterCounts[ch];
                if (characterCount > 0)
                {
                    if ((options & SelectCoveredStrings_OptionsSkipCommon) && IsCharacterCommonlyCovered(ch))
                    {
                        commonCount += characterCount;
                        maxCoverageCount -= maxCoverageCountPerCharacter; // discount this character
                    }
                    else
                    {
                        coverageCount += characterCount;
                    }
                }
            }

            stringInfo.coverageCount = coverageCount;
            stringInfo.maxCoverageCount = maxCoverageCount;

            // Select the string if all characters were covered by all fonts.
            if (coverageCount >= maxCoverageCount
            ||  ((options & SelectCoveredStrings_OptionsSelectAnyCoverage) && coverageCount > 0))
            {
                stringInfo.isSelected = true;
            }
        }
    }


    int32_t GetValueFromName(
        __in_ecount(mappingsCount) const NameToValueMapping* mappings,
        uint32_t mappingsCount,
        __in_z const wchar_t* name,
        uint32_t defaultValue = 0xFFFFFFFF // if not found
        )
    {
        for (uint32_t i = 0; i < mappingsCount; ++i)
        {
            if (_wcsicmp(name, mappings[i].name) == 0)
            {
                return mappings[i].value;
            }
        }
        return defaultValue;
    }
}


HWND MainWindow::GetSubdialogItem(int dialogId, int childId)
{
    return GetDlgItem(GetDlgItem(hwnd_, dialogId), childId);
}


HWND MainWindow::GetPaneList(int paneId)
{
    static_assert(IddMainDialogCount == 6, "Update this code for new dialog count");

    int childId = 0;
    switch (paneId)
    {
    case IddFontsList:   childId = IdcFontsListFonts;       break;
    case IddStringsList: childId = IdcStringsListStrings;   break;
    case IddPerfScore:   childId = IdcPerfScoreResults;     break;
    case IddLookupsList: childId = IdcLookupsListLookups;   break;
    case IddActionsList: childId = IdcActionsList;          break;
    case IddHelp:        childId = IdcHelp;                 break;
    default: return nullptr;
    }
    return GetSubdialogItem(currentPaneId_, childId);
}


int MainWindow::GetCommandPaneId(int commandId)
{
    for (uint32_t i = 0; i < ARRAYSIZE(g_commandToPaneIdMap); ++i)
    {
        if (g_commandToPaneIdMap[i][0] == commandId)
        {
            return g_commandToPaneIdMap[i][1];;
        }
    }

    return -1;
}


HWND MainWindow::GetCurrentPaneList()
{
    return GetPaneList(currentPaneId_);
}


int MainWindow::GetCurrentPaneDefaultId()
{
    static_assert(IddMainDialogCount == 6, "Update this code for new dialog count");

    switch (currentPaneId_)
    {
    case IddFontsList:   return IdcStringsSelectSharedInFonts;
    case IddStringsList: return IdcPerfProfileStart;
    case IddPerfScore:   return IdcLookupsIdentifyApplicable;
    case IddLookupsList: return IdcLookupsIdentifyApplicable;
    case IddActionsList: return IdcActionsListExecuteSelected;
    case IddHelp:
    default:             return IDOK;
    }
}


bool MainWindow::Initialize(__in_z const wchar_t* options)
{
    ResetDefaultStringsList();
    UpdateStringsListUi();

    if (ParseAutomatedActions(options, OUT automatedActions_))
    {
        UpdateActionsListUi();
        StartAutomatedActions();
    }

    return true;
}


bool MainWindow::ParseAutomatedActions(
    __in_z const wchar_t* actions,
    OUT std::vector<KeyValuePair>& keyValues
    )
{
    if (actions == nullptr || actions[0] == '\0')
        return true; // Empty actions is success.

    uint32_t textLength = static_cast<uint32_t>(wcslen(actions));
    JsonexParser parser(actions, textLength, JsonexParser::OptionsDefault);

    TextTree::Node node;
    std::wstring nodeText;
    KeyValuePair keyValue;

    while (parser.ReadNode(OUT node, IN OUT nodeText))
    {
#if 1
        std::wstring spaceBuffer;
        const size_t spacesPerIndent = 4;
        const size_t spacesToIndent = std::min(size_t(48), node.level * spacesPerIndent);
        spaceBuffer.assign(spacesToIndent, ' ');
        AppendLog(spaceBuffer.c_str());

        AppendLog(L"'%s' %X \r\n", nodeText.c_str() + node.start, node.type);
#endif

        switch (node.GetType())
        {
        case TextTree::Node::TypeValue:
            if (node.level == 0 || (node.level == 1 && !keyValue.key.empty()))
            {
                auto& string = keyValue.key.empty() ? keyValue.key : keyValue.value;
                string.assign(nodeText, node.start, node.length);
                keyValues.push_back(keyValue);
            }
            keyValue.Clear();
            break;

        case TextTree::Node::TypeKey:
            if (node.level == 0)
            {
                keyValue.Clear();
                keyValue.key.assign(nodeText, node.start, node.length);
            }
            break;

        case TextTree::Node::TypeComment:
        case TextTree::Node::TypeIgnorable:
            // Just skip it.
            break;

        default:
            keyValue.Clear();
            break;
        }
    }

#if 1
    for (uint32_t i = 0, c = parser.GetErrorCount(); i < c; ++i)
    {
        uint32_t errorTextIndex = 0;
        const wchar_t* userErrorMessage;
        parser.GetErrorDetails(i, OUT errorTextIndex, OUT &userErrorMessage);
        AppendLog(L" error @%d '%s'\r\n", errorTextIndex, userErrorMessage);
    }
#endif
    return true;
}


void MainWindow::LogUnexpectedAutomatedAction(const KeyValuePair& action)
{
    AppendLog(L"Unexpected value \"%s\" in action \"%s\"\r\n", action.value.c_str(), action.key.c_str());
}


HRESULT MainWindow::ExecuteSelectedAutomatedAction()
{
    HWND listViewHwnd = GetSubdialogItem(IddActionsList, IdcActionsList);
    int itemIndex = ListView_GetNextItem(listViewHwnd, -1, LVNI_FOCUSED|LVNI_SELECTED);
    
    if (uint32_t(itemIndex) < automatedActions_.size())
    {
        automatedActionIndex_ = itemIndex;
        ProcessNextAutomatedAction();
    }

    return S_OK;
}


HRESULT MainWindow::StartAutomatedActions()
{
    SetTimer(hwnd_, IdtAutomatedAction, g_automatedActionTimeOut, nullptr);
    AppendLog(L"Start automated actions...\r\n");

    return S_OK;
}


HRESULT MainWindow::PauseAutomatedActions()
{
    KillTimer(hwnd_, IdtAutomatedAction);
    // Do not reset automatedActionIndex_.
    AppendLog(L"Automated actions paused...\r\n");

    return S_OK;
}


HRESULT MainWindow::StopAutomatedActions()
{
    KillTimer(hwnd_, IdtAutomatedAction);
    automatedActionIndex_ = 0;
    AppendLog(L"Automated actions stopped...\r\n");

    return S_OK;
}


HRESULT MainWindow::LoadAutomatedActionsFile()
{
    ////////////////////
    // Get the filename from the user.

    wchar_t fileName[MAX_PATH];
    fileName[0] = '\0'; // Must initialize to empty path (else GetOpenFileName fails)

    // Initialize OPENFILENAME
    OPENFILENAME ofn;
    ZeroStructure(ofn);
    ofn.lStructSize     = sizeof(ofn);
    ofn.hwndOwner       = hwnd_;
    ofn.lpstrFile       = &fileName[0];
    ofn.nMaxFile        = ARRAYSIZE(fileName);
    ofn.lpstrFilter     = L"Actions text file\0*.txt\0"
                          L"All\0*.*\0"
                          ;
    ofn.nFilterIndex    = 1;
    ofn.lpstrFileTitle  = nullptr;
    ofn.nMaxFileTitle   = 0;
    ofn.lpstrInitialDir = nullptr;
    ofn.Flags = OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST | OFN_EXPLORER | OFN_HIDEREADONLY;

    if (!GetOpenFileName(&ofn))
    {
        return S_FALSE;
    }

    ////////////////////
    // Load the file and parse actions.

    std::wstring actionsText;

    AppendLog(L"Loading actions file \"%s\" ...", fileName);
    HRESULT hr = ReadTextFile(fileName, OUT actionsText);
    if (FAILED(hr))
    {
        AppendLog(L"Failed\r\n");
        return hr;
    }
    automatedActions_.clear();
    ParseAutomatedActions(actionsText.c_str(), OUT automatedActions_);
    AppendLog(L"Read %d actions\r\n", uint32_t(automatedActions_.size()));

    UpdateActionsListUi();

    return S_OK;
}


// Rebuild the UI to the internal list.
void MainWindow::UpdateActionsListUi()
{
    ListViewWriter lw(GetSubdialogItem(IddActionsList, IdcActionsList));
    lw.DisableDrawing();
    ListView_DeleteAllItems(lw.hwnd);

    for (auto p = automatedActions_.begin(); p != automatedActions_.end(); ++p)
    {
        lw.InsertItem();
        lw.SetItemText(0, p->key.c_str());
        lw.SetItemText(1, p->value.c_str());
        lw.AdvanceItem();
    }
    lw.EnableDrawing();
}


bool MainWindow::ProcessNextAutomatedAction()
{
    if (automatedActionIndex_ >= automatedActions_.size())
    {
        StopAutomatedActions();
        return false;
    }

    KeyValuePair& action = automatedActions_[automatedActionIndex_];
    ++automatedActionIndex_;

    if (action.level > 0)
    {
        AppendLog(L"Nested actions ignored \"%s\"\r\n", action.key.c_str());
        return false;
    }

    insideAutomatedAction_ = true;

    // Find matching key name to get action.
    AutomatedActionInvalid;

    AutomatedAction actionType =
        AutomatedAction(
            GetValueFromName(
                g_automatedActionMap,
                ARRAY_SIZE(g_automatedActionMap),
                action.key.c_str(),
                AutomatedActionInvalid
                ));

    bool success = true;

    switch (actionType)
    {
    case AutomatedActionInvalid:
        if (action.key.c_str()[0] != '#') // Ignore actions with # in front
        {
            AppendLog(L"Invalid action \"%s\"\r\n", action.key.c_str());
            success = false;
        }
        break;

    case AutomatedActionLoadActionsFile:
        if (action.value.empty())
        {
            LogUnexpectedAutomatedAction(action);
            success = false;
        }
        else if (automatedActions_.size() < g_automatedActionMaximum)
        {
            std::vector<KeyValuePair> automatedActions;
            std::wstring actionsText;

            AppendLog(L"Loading actions file \"%s\" ...", action.value.c_str());
            if (FAILED(ReadTextFile(action.value.c_str(), OUT actionsText)))
            {
                AppendLog(L"Failed\r\n");
                break;
            }
            if (ParseAutomatedActions(actionsText.c_str(), OUT automatedActions))
            {
                // Once loaded, comment the action so that later reruns don't repeatedly expand it.
                action.key.insert(0, L"#", 1);
            }
            AppendLog(L"Read %d actions\r\n", uint32_t(automatedActions.size()));
            automatedActions_.insert(automatedActions_.begin() + automatedActionIndex_, automatedActions.begin(), automatedActions.end());

            UpdateActionsListUi();

            // ! action& is now invalid
        }
        break;

    case AutomatedActionLoadFont:
        if (action.value.empty())
        {
            LogUnexpectedAutomatedAction(action);
            success = false;
        }
        else
        {
            AppendLog(L"Loading font \"%s\"...\r\n", action.value.c_str());

            std::wstring fileNames;
            wchar_t currentPath[MAX_PATH];
            GetCurrentDirectory(ARRAY_SIZE(currentPath), currentPath);

            EnumerateMatchingFiles(currentPath, action.value.c_str(), OUT fileNames);
            fileNames.push_back('\0'); // double nul termination
            LoadFontFiles(
                L"", // fileDirectory
                fileNames.data()
                );
        }
        break;

    case AutomatedActionAddString:
        if (action.value.empty())
        {
            LogUnexpectedAutomatedAction(action);
            success = false;
        }
        else
        {
            AppendLog(L"Adding string \"%s\"\r\n", action.value.c_str());

            stringsList_.resize(stringsList_.size() + 1);
            auto& stringInfo       = stringsList_.back();
            stringInfo.description = L"User string";
            stringInfo.sample      = action.value.c_str();
            stringInfo.isSelected  = true;
            stringInfo.isSimple    = IsStringSimple(stringInfo.sample.c_str(), stringInfo.sample.size());

            UpdateStringsListUi();
        }
        break;

    case AutomatedActionSelectString:
        {
            AppendLog(L"Selecting string \"%s\"\r\n", action.value.c_str());

            // Find the string matching the description.
            for (auto it = stringsList_.begin(), end = stringsList_.end(); it != end; ++it)
            {
                if (_wcsicmp(it->description.c_str(), action.value.c_str()) == 0)
                {
                    it->isSelected = true;
                    UpdateStringsListUi();
                    break;
                }
            }
        }
        break;

    case AutomatedActionSelectFullySupportedStrings:
        // todo:
        break;

    case AutomatedActionSelectPartiallySupportedStrings:
        // todo:
        break;

    case AutomatedActionDeselectDuplicateFonts:
        SelectDuplicateFonts(/*selection*/true, false);
        break;

    case AutomatedActionDeselectAllDuplicateFonts:
        SelectDuplicateFonts(/*selection*/true, true);
        break;

    case AutomatedActionStartProfile:
        SelectCurrentPane(IddPerfScore);
        ProfileStart();
        break;

    case AutomatedActionStopProfile:
        ProfileStop();
        break;

    case AutomatedActionWaitProfile:
        {
            uint32_t timeUntilNextAction = g_automatedActionTimeOut;
            if (!ProfileIsDone())
            {
                // Repeat this action, and poll with a longer timer.
                --automatedActionIndex_;
                timeUntilNextAction = g_automatedActionIdleTimeOut;
            }
            SetTimer(hwnd_, IdtAutomatedAction, timeUntilNextAction, nullptr);
        }
        break;

    case AutomatedActionSavePerfResults:
        // todo:
        break;

    case AutomatedActionPerfGrouping:
        {
            const static NameToValueMapping g_perfGroupingMapping[] = {
                {L"string", L"", PerfGroupingString },
                {L"stringfont", L"", PerfGroupingString|PerfGroupingFont },
                {L"font", L"", PerfGroupingFont },
                {L"file", L"", PerfGroupingFile },
                {L"all", L"", PerfGroupingString|PerfGroupingFont|PerfGroupingFile },
                {L"none", L"", 0 },
            };

            perfGrouping_ = GetValueFromName(
                                g_perfGroupingMapping,
                                ARRAY_SIZE(g_perfGroupingMapping),
                                action.value.c_str(),
                                PerfGroupingString|PerfGroupingFont
                                );
        }
        break;

    case AutomatedActionSkipPartialCoverageFonts:
        skipPartialCoverageFonts_ = GetBooleanValue(action.value.c_str(), true);
        break;

    case AutomatedActionIterations:
        if (action.value.empty())
        {
            LogUnexpectedAutomatedAction(action);
            success = false;
        }
        else
        {
            wcscpy_s(g_iterationCountEdit, action.value.c_str());
            InvalidateRect(GetDlgItem(hwnd_, IdcAttributeList), nullptr, false);
        }
        break;

    case AutomatedActionMaxTime:
        if (action.value.empty())
        {
            LogUnexpectedAutomatedAction(action);
            success = false;
        }
        else
        {
            wcscpy_s(g_maxTimeEdit, action.value.c_str());
            InvalidateRect(GetDlgItem(hwnd_, IdcAttributeList), nullptr, false);
        }
        break;

    case AutomatedActionExit:
        if (!action.value.empty())
        {
            LogUnexpectedAutomatedAction(action);
            success = false;
            break;
        }
        PostMessage(Application::g_mainHwnd, WM_CLOSE, 0,0);
        break;

    default:
        success = false;
        break;
    }

    insideAutomatedAction_ = false;

    return success;
}


INT_PTR CALLBACK MainWindow::StaticDialogProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    MainWindow* window = GetClassFromWindow<MainWindow>(hwnd);
    if (window == nullptr)
    {
        window = new(std::nothrow) MainWindow(hwnd);
        if (window == nullptr)
        {
            return -1; // failed creation
        }

        ::SetWindowLongPtr(hwnd, DWLP_USER, (LONG_PTR)window);
    }

    const DialogProcResult result = window->DialogProc(hwnd, message, wParam, lParam);
    if (result.handled)
    {
        ::SetWindowLongPtr(hwnd, DWLP_MSGRESULT, result.value);
    }
    return result.handled;
}


INT_PTR CALLBACK MainWindow::StaticSubDialogProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    MainWindow* window = GetClassFromWindow<MainWindow>(hwnd);
    if (window == nullptr && message != WM_INITDIALOG)
    {
        return false;
    }

    const DialogProcResult result = window->SubDialogProc(hwnd, message, wParam, lParam);
    if (result.handled)
    {
        ::SetWindowLongPtr(hwnd, DWLP_MSGRESULT, result.value);
    }
    return result.handled;
}


DialogProcResult CALLBACK MainWindow::DialogProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    switch (message)
    {
    case WM_INITDIALOG:
        return !!InitializeMainDialog(hwnd);

    case WM_COMMAND:
        return ProcessCommand(hwnd, message, wParam, lParam);

    case WM_NOTIFY:
        return ProcessNotification(hwnd, message, wParam, lParam);

    case WM_MOVE:
        {
            // Let the attribute list move it's overlay properly.
            HWND attributeList = GetDlgItem(hwnd, IdcAttributeList);
            if (GetFocus() == attributeList)
            {
                POINT pt = {(int)(short) LOWORD(lParam), (int)(short) HIWORD(lParam)};

                ClientToScreen(hwnd, &pt);
                ScreenToClient(attributeList, &pt);
                SendMessage(attributeList, WM_MOVE, wParam, (LPARAM)POINTTOPOINTS(pt));
            }
        }
        break;

    case WM_KEYDOWN:
        return DialogProcResult(!!TranslateAccelerator(hwnd, accelTable_, &Application::g_msg), 1);

    case WM_TIMER:
        switch (wParam)
        {
        case IdcStringsListStrings:
            UpdateTextFromSelectedStrings();
            break;

        case IdtAutomatedAction:
            ProcessNextAutomatedAction();
            break;
        }
        break;

    case WM_PROFILE_RESULT:
        switch (wParam)
        {
        case IdmPerfProfileResult:
            {
                // Print another profile timing result.

                ProfileResult const& result = *reinterpret_cast<ProfileResult*>(lParam);
                auto& stringInfo = stringsList_[result.stringIndex];
                auto& fontInfo = fontsList_[result.fontIndex];

                ListViewWriter lw(GetSubdialogItem(IddPerfScore, IdcPerfScoreResults));
                lw.iItem = ListView_GetItemCount(lw.hwnd);
                std::wstring text;

                if (result.layout.IsEmpty() && result.shaping.IsEmpty())
                {
                    lw.InsertItem(stringInfo.description.c_str());

                    Format(text, L"%s - %s", fontInfo.familyName.c_str(), fontInfo.styleName.c_str());
                    lw.SetItemText(PerfScoreColumnIndexFont, text.c_str());

                    Format(text, L"%s#%d", fontInfo.filePath.c_str(), fontInfo.faceIndex);
                    lw.SetItemText(PerfScoreColumnIndexFile, text.c_str());
                }
                else
                {
                    --lw.iItem; // fill in columns of last item
                }

                // Print layout result.
                FormatPerfTime(IN OUT text, result.layout);
                lw.SetItemText(PerfScoreColumnIndexLayoutTime, text.c_str());

                // Print shaping result.
                FormatPerfTime(IN OUT text, result.shaping);
                lw.SetItemText(PerfScoreColumnIndexShapingTime, text.c_str());

                // Scroll down if the currently selected item is the bottom.
                const int topIndex = ListView_GetTopIndex(lw.hwnd);
                const int countPerPage = ListView_GetCountPerPage(lw.hwnd);
                if (topIndex + countPerPage >= lw.iItem - 1)
                {
                    lw.SelectAndFocusItem(lw.iItem);
                    lw.EnsureVisible();
                }
            }
            break;

        case IdmPerfProfileAggregateResult:
            {
                // Print another profile timing result.

                ProfileAggregateResult const& result = *reinterpret_cast<ProfileAggregateResult*>(lParam);

                ListViewWriter lw(GetSubdialogItem(IddPerfScore, IdcPerfScoreResults));
                lw.iItem = ListView_GetItemCount(lw.hwnd);
                std::wstring text;

                lw.InsertItem(L"Result");

                // Print layout result.
                FormatPerfTimeDelta(IN OUT text, result.layoutFastest, result.layoutSlowest);
                lw.SetItemText(PerfScoreColumnIndexLayoutTime, text.c_str());

                FormatPerfTimeDelta(IN OUT text, result.shapingFastest, result.shapingSlowest);
                lw.SetItemText(PerfScoreColumnIndexShapingTime, text.c_str());
            }
            break;

        case IdmPerfProfileTotalResult:
            {
                // Print another profile timing result.

                ProfileResult const& result = *reinterpret_cast<ProfileResult*>(lParam);

                ListViewWriter lw(GetSubdialogItem(IddPerfScore, IdcPerfScoreResults));
                lw.iItem = ListView_GetItemCount(lw.hwnd);
                std::wstring text;

                lw.InsertItem(L"Total");

                // Print layout result.
                FormatPerfTime(IN OUT text, result.layout);
                lw.SetItemText(PerfScoreColumnIndexLayoutTime, text.c_str());

                // Print shaping result.
                FormatPerfTime(IN OUT text, result.shaping);
                lw.SetItemText(PerfScoreColumnIndexShapingTime, text.c_str());
            }
            break;

        case IdmPerfProfileString:
            {
                ListViewWriter lw(GetSubdialogItem(IddPerfScore, IdcPerfScoreResults));
                lw.iItem = ListView_GetItemCount(lw.hwnd);
                lw.InsertItem(reinterpret_cast<wchar_t*>(lParam));
                lw.EnsureVisible();
            }
            break;

        case IdmPerfProfileLog:
            AppendLog(reinterpret_cast<wchar_t*>(lParam));
            break;
        }
        break;

    case WM_DROPFILES:
        return ProcessDragAndDrop(hwnd, message, wParam, lParam);

    case WM_NCDESTROY:
        delete this; // do NOT reference class after this
        return false;

    case WM_SIZE:
        Resize(IddMainWindow);
        break;

    default:
        return false;
    }

    return true;
}


DialogProcResult CALLBACK MainWindow::SubDialogProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    switch (message)
    {
    case WM_INITDIALOG:
        {
            ThisId* thisId = reinterpret_cast<ThisId*>(lParam);
            MainWindow* window = thisId->window;
            ::SetWindowLong(hwnd, GWL_ID, thisId->id);
            ::SetWindowLongPtr(hwnd, DWLP_USER, (LONG_PTR)window);

            static_assert(IddMainDialogCount == 6, "Update this code for new dialog count");

            switch (thisId->id)
            {
            case IddFontsList:
                window->InitializeFontsListDialog(hwnd);
                break;
            case IddStringsList:
                window->InitializeStringsListDialog(hwnd);
                break;
            case IddPerfScore:
                window->InitializePerfScoreDialog(hwnd);
                break;
            case IddLookupsList:
                window->InitializeLookupsListDialog(hwnd);
                break;
            case IddActionsList:
                window->InitializeActionsListDialog(hwnd);
                break;
            case IddHelp:
                window->InitializeHelpDialog(hwnd);
                break;
            }
        }
        break; // Break to return true and set default key focus.

    case WM_COMMAND:
        return ProcessCommand(hwnd, message, wParam, lParam);

    case WM_NOTIFY:
        return ProcessNotification(hwnd, message, wParam, lParam);

    case WM_SIZE:
        Resize(GetDlgCtrlID(hwnd));
        break;

    default:
        return false;
    }

    return true;
}


INT_PTR MainWindow::InitializeMainDialog(HWND hwnd)
{
    DefWindowProc(hwnd, WM_SETICON, ICON_BIG, LPARAM(LoadIcon(Application::g_hModule, MAKEINTRESOURCE(1))));
    SetWindowText(
        hwnd,
        BUILD_TITLE_STRING L", "
        TEXT(__DATE__) L", "
        BUILD_ARCHITECTURE_STRING L", "
        BUILD_OPTIMIZATION_STRING
        );

    // Create the tabs
    TCITEM tabItem;
    tabItem.mask = TCIF_TEXT;
            
    static_assert(IddMainDialogCount == 6, "Update this code for new dialog count");
    HWND tabControl = GetDlgItem(hwnd, IdcMainTabs);
    tabItem.pszText = L"(1) Fonts";   TabCtrl_InsertItem(tabControl, 0, &tabItem);
    tabItem.pszText = L"(2) Strings"; TabCtrl_InsertItem(tabControl, 1, &tabItem);
    tabItem.pszText = L"(3) Perf";    TabCtrl_InsertItem(tabControl, 2, &tabItem);
    tabItem.pszText = L"(4) Lookups"; TabCtrl_InsertItem(tabControl, 3, &tabItem);
    tabItem.pszText = L"Actions";     TabCtrl_InsertItem(tabControl, 4, &tabItem);
    tabItem.pszText = L"Help";        TabCtrl_InsertItem(tabControl, 5, &tabItem);

    // Create the subdialogs and set id's accordingly (since CreateDialog sets no id initially).
    ThisId thisId = {this};

    static_assert(IddMainDialogCount == 6, "Update this code for new dialog count");

    thisId.id = IddFontsList;
    ::CreateDialogParam(Application::g_hModule, MAKEINTRESOURCE(IddFontsList), hwnd, &MainWindow::StaticSubDialogProc, (LPARAM)&thisId);

    thisId.id = IddStringsList;
    ::CreateDialogParam(Application::g_hModule, MAKEINTRESOURCE(IddStringsList), hwnd, &MainWindow::StaticSubDialogProc, (LPARAM)&thisId);

    thisId.id = IddPerfScore;
    ::CreateDialogParam(Application::g_hModule, MAKEINTRESOURCE(IddPerfScore), hwnd, &MainWindow::StaticSubDialogProc, (LPARAM)&thisId);

    thisId.id = IddLookupsList;
    ::CreateDialogParam(Application::g_hModule, MAKEINTRESOURCE(IddLookupsList), hwnd, &MainWindow::StaticSubDialogProc, (LPARAM)&thisId);

    thisId.id = IddActionsList;
    ::CreateDialogParam(Application::g_hModule, MAKEINTRESOURCE(IddActionsList), hwnd, &MainWindow::StaticSubDialogProc, (LPARAM)&thisId);

    thisId.id = IddHelp;
    ::CreateDialogParam(Application::g_hModule, MAKEINTRESOURCE(IddHelp), hwnd, &MainWindow::StaticSubDialogProc, (LPARAM)&thisId);

    const HWND hwndAttributeList = GetDlgItem(hwnd, IdcAttributeList);
    const HWND hwndLog = GetDlgItem(hwnd, IdcLog);

    // Initialize the attribute list.
    SendMessage(hwndAttributeList, AttributeList::MessageSetItems, ARRAYSIZE(g_attributeListItems), (LPARAM)&g_attributeListItems[0]);
    SendMessage(hwndAttributeList, LB_SETCURSEL, AttributeList::FindMatchingItemIndex(IdcFontsLoadFontFiles, g_attributeListItems, ARRAYSIZE(g_attributeListItems)), 0);

    // Move log and attribute window to last item in tab order (otherwise it will be awkwardly in front because it was created before the panes)
    SetWindowPos(hwndAttributeList, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOMOVE|SWP_NOSIZE);
    SetWindowPos(hwndLog, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOMOVE|SWP_NOSIZE);

    Edit_LimitText(hwndLog, 1048576);

    SelectCurrentPane(IddFontsList);

    Resize(IddMainWindow);

    AppendLog(L"Select a font to test...\r\n");

    SetFocus(GetDlgItem(hwnd, IdcAttributeList));

    return false; // do not permit user32 code to set focus
}


INT_PTR MainWindow::InitializeFontsListDialog(HWND hwnd)
{
    HWND listHwnd = GetDlgItem(hwnd, IdcFontsListFonts);
    InitializeSysListView(listHwnd, g_FontListColumnInfo, ARRAY_SIZE(g_FontListColumnInfo));

    return true;
}


INT_PTR MainWindow::InitializeStringsListDialog(HWND hwnd)
{
    HWND listHwnd = GetDlgItem(hwnd, IdcStringsListStrings);
    InitializeSysListView(listHwnd, g_StringsListColumnInfo, ARRAY_SIZE(g_StringsListColumnInfo));

    return true;
}


INT_PTR MainWindow::InitializePerfScoreDialog(HWND hwnd)
{
    HWND listHwnd = GetDlgItem(hwnd, IdcPerfScoreResults);
    InitializeSysListView(listHwnd, g_PerfScoreColumnInfo, ARRAY_SIZE(g_PerfScoreColumnInfo));
    ListViewWriter lw(listHwnd);
    lw.SelectAndFocusItem(0);

    // Add list of OpenType features.
    HWND featuresHwnd = GetDlgItem(hwnd, IdcPerfFeatures);
    for (uint32_t i = 0; i < ARRAY_SIZE(g_fontFeatureLists); ++i)
    {
        ComboBox_AddString(featuresHwnd, g_fontFeatureLists[i]);
    }
    ComboBox_SetText(featuresHwnd, g_fontFeatureLists[0]);

    return true;
}


INT_PTR MainWindow::InitializeLookupsListDialog(HWND hwnd)
{
    HWND listHwnd = GetDlgItem(hwnd, IdcLookupsListLookups);
    InitializeSysListView(listHwnd, g_LookupsListColumnInfo, ARRAY_SIZE(g_LookupsListColumnInfo));

    // Add list of OpenType features.
    HWND featuresHwnd = GetDlgItem(hwnd, IdcLookupsFeatures);
    for (uint32_t i = 0; i < ARRAY_SIZE(g_fontFeatureLists); ++i)
    {
        ComboBox_AddString(featuresHwnd, g_fontFeatureLists[i]);
    }
    ComboBox_SetText(featuresHwnd, g_fontFeatureLists[0]);

    return true;
}


INT_PTR MainWindow::InitializeActionsListDialog(HWND hwnd)
{
    HWND listHwnd = GetDlgItem(hwnd, IdcActionsList);
    InitializeSysListView(listHwnd, g_ActionsListColumnInfo, ARRAY_SIZE(g_ActionsListColumnInfo));

    return true;
}


INT_PTR MainWindow::InitializeHelpDialog(HWND hwnd)
{
    HWND listHwnd = GetDlgItem(hwnd, IdcHelp);
    InitializeSysListView(listHwnd, g_HelpColumnInfo, ARRAY_SIZE(g_HelpColumnInfo));

    ListViewWriter lw(listHwnd);

    lw.InsertItem(L"User commands"); lw.AdvanceItem();
    lw.InsertItem(L"——————————"); lw.AdvanceItem();
    for (uint32_t i = 0; i < ARRAY_SIZE(g_helpText); ++i)
    {
        lw.InsertItem(g_helpText[i][0]);
        lw.SetItemText(1, g_helpText[i][1]);
        lw.AdvanceItem();
    }

    lw.InsertItem(L""); lw.AdvanceItem();
    lw.InsertItem(L"Automated actions"); lw.AdvanceItem();
    lw.InsertItem(L"——————————"); lw.AdvanceItem();
    for (uint32_t i = 0; i < ARRAY_SIZE(g_automatedActionMap); ++i)
    {
        lw.InsertItem(g_automatedActionMap[i].name);
        lw.SetItemText(1, g_automatedActionMap[i].description);
        lw.AdvanceItem();
    }

    return true;
}


namespace
{
    template<typename T>
    T GetWrappedIncrement(T v, T increment, T low, T high)
    {
        v += increment;
        if (v < low) v = high;
        if (v > high) v = low;
        return v;
    }
}


DialogProcResult CALLBACK MainWindow::ProcessCommand(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    uint32_t wmId    = LOWORD(wParam);
    uint32_t wmEvent = HIWORD(wParam);
    UNREFERENCED_PARAMETER(wmEvent);

    // Select the appropriate pane for the command.
    static_assert(IddMainDialogCount == 6, "Update this code for new dialog count");

    int newPaneId = GetCommandPaneId(wmId);

    switch (wmId)
    {
    case IDCANCEL:
    case IDCLOSE:
        {
            ProfileStop(true);
            DestroyWindow(hwnd); // Do not reference class after this
            PostQuitMessage(0);
        }
        break;

    case IdcFontsLoadSystemFont:
        if (EnsureUiConditionTrue(!profilingThread_, L"Stop profiling first.", IddPerfScore))
        {
            SelectCurrentPane(newPaneId);
            LoadSystemFont();
            goto SetFontsListFocus;
        }
        break;

    case IdcFontsLoadAllSystemFonts:
        if (EnsureUiConditionTrue(!profilingThread_, L"Stop profiling first.", IddPerfScore))
        {
            SelectCurrentPane(newPaneId);
            UpdateWindow(hwnd_);
            LoadAllSystemFonts();
            goto SetFontsListFocus;
        }
        break;

    case IdcFontsLoadFontFiles:
        if (EnsureUiConditionTrue(!profilingThread_, L"Stop profiling first.", IddPerfScore))
        {
            SelectCurrentPane(newPaneId);
            UpdateWindow(hwnd_);
            LoadFontFiles();
            goto SetFontsListFocus;
        }
        break;

    SetFontsListFocus:
        if (!fontsList_.empty())
        {
            auto listHwnd = GetSubdialogItem(IddFontsList, IdcFontsListFonts);
            if (GetFontsListSelectionCount() <= 0)
            {
                ListView_SetItemState(listHwnd, 0, LVIS_FOCUSED, LVIS_FOCUSED);
            }
            SetFocus(listHwnd);
        }
        break;

    case IdcCommonSelectList:
        ListView_SetItemState(GetCurrentPaneList(), -1, LVIS_SELECTED, LVIS_SELECTED);
        AppendLog(L"Selected all list items.\r\n");
        break;
        
    case IdcCommonDeselectList:
        ListView_SetItemState(GetCurrentPaneList(), -1, 0, LVIS_SELECTED);
        AppendLog(L"Deselected all list items.\r\n");
        break;

    case IdcCommonInvertList:
        InvertListViewSelection(GetCurrentPaneList());
        AppendLog(L"Inverted selection of all list items.\r\n");
        break;
        
    case IdcCommonCopyList:
        {
            // Get current list as tab separated text.
            auto listHwnd = GetCurrentPaneList();
            std::wstring text = GetListViewText(listHwnd, L"\t");
            if (EnsureUiConditionTrue(!text.empty(), L"No items to copy."))
            {
                CopyToClipboard(text);
                AppendLog(L"Copied list items to clipboard.\r\n");
            }
        }
        break;

    case IdcCommonClearList:
        if (EnsureUiConditionTrue(!profilingThread_, L"Stop profiling first.", IddPerfScore))
        {
            bool shouldClear = true;
            switch (currentPaneId_)
            {
            case IddFontsList:      fontsList_.clear();         break;
            case IddStringsList:    stringsList_.clear();       break;
            case IddActionsList:    automatedActions_.clear();  break;
            case IddHelp:           shouldClear = false;        break; // don't clear the help!
            }
            if (shouldClear)
            {
                ListView_DeleteAllItems(GetCurrentPaneList());
                AppendLog(L"Cleared all list items.\r\n");
            }
        }
        break;

    case IdcFontsCopyAllCharacters:
    case IdcFontsCopySharedCharacters:
    case IdcFontsCopyUniqueCharacters:
        if (EnsureUiConditionTrue(GetFontsListSelectionCount() > 0, L"No fonts are selected.\r\n\r\nLoad fonts, and select the ones you are interested in.", IddFontsList))
        {
            UpdateWindow(hwnd_);

            std::vector<ComPtr<IDWriteFontFace> > fontFaces = GetSelectedFontFaces();
            const uint32_t fontFaceCount = static_cast<uint32_t>(fontFaces.size());
            std::vector<uint16_t> characterCounts =
                GetFontCharacterCoverageCounts(
                    fontFaces.data()->Address(),
                    fontFaceCount,
                    nullptr, // unicodeCharacters
                    0, // unicodeCharactersCount
                    [&](uint32_t i, uint32_t total) {SetProgress(i, total);}
                    );

            Range range;
            switch (wmId)
            {
            default:
            case IdcFontsCopyAllCharacters:      range = Range(1, UINT_MAX); break;
            case IdcFontsCopyUniqueCharacters:   range = Range(1, 1); break;
            case IdcFontsCopySharedCharacters:   range = Range(fontFaceCount, fontFaceCount); break;
            }

            SetProgress(0,0);
            std::wstring text = GetStringFromCoverageCount(characterCounts.data(), range);
            CopyToClipboard(text);

            AppendLog(L"Copied characters.\r\n");
        }
        break;

    case IdcStringsSelectSharedInFonts:
    case IdcStringsSelectSimpleInFonts:
    case IdcStringsSelectAllInFonts:
        if (EnsureUiConditionTrue(GetFontsListSelectionCount() > 0, L"No fonts are selected.\r\n\r\nLoad fonts, and select the ones you are interested in.", IddFontsList))
        {
            SelectCurrentPane(newPaneId);
            UpdateWindow(hwnd_);

            std::vector<ComPtr<IDWriteFontFace> > fontFaces = GetSelectedFontFaces();
            const uint32_t fontFaceCount = static_cast<uint32_t>(fontFaces.size());
            std::vector<uint16_t> characterCounts =
                GetFontCharacterCoverageCounts(
                    fontFaces.data()->Address(),
                    fontFaceCount,
                    nullptr, // unicodeCharacters
                    0, // unicodeCharactersCount
                    [&](uint32_t i, uint32_t total) {SetProgress(i, total);}
                    );

            SetProgress(0,0);
            SelectCoveredStrings_Options selectionOptions = static_cast<SelectCoveredStrings_Options>(
                  ((wmId == IdcStringsSelectSimpleInFonts) ? SelectCoveredStrings_OptionsSkipComplexAndCommon : SelectCoveredStrings_OptionsSkipCommon)
                | ((wmId == IdcStringsSelectAllInFonts)    ? SelectCoveredStrings_OptionsSelectAnyCoverage : 0)
                );
                
            SelectCoveredStrings(
                stringsList_.data(),
                static_cast<uint32_t>(stringsList_.size()),
                fontFaceCount,
                characterCounts.data(),
                selectionOptions
                );
            UpdateStringsListUi();
            UpdateTextFromSelectedStrings();

            AppendLog(L"Selected %d strings supported by %d selected fonts.\r\n", GetStringsListSelectionCount(), GetFontsListSelectionCount());
        }
        break;

    case IdcStringsCopyStrings:
        {
            std::wstring text = GetSelectedStringsText(L"\r\n");
            if (EnsureUiConditionTrue(!text.empty(), L"No strings are selected.\r\n\r\nSelect the ones you are interested in.", IddStringsList))
            {
                SelectCurrentPane(newPaneId);
                CopyToClipboard(text);
                AppendLog(L"Copied to clipboard.\r\n");
            }
        }
        break;

    case IdcStringsEditStrings:
        AppendLog(L"Launched external editor.\r\n");
        break;

    case IdcStringsResetDefaults:
        if (EnsureUiConditionTrue(!profilingThread_, L"Stop profiling first.", IddPerfScore))
        {
            SelectCurrentPane(newPaneId);
            ResetDefaultStringsList();
            UpdateStringsListUi();
            AppendLog(L"Reset default strings.\r\n");
        }
        break;

    case IdcStringsListString:
        switch (wmEvent)
        {
        case EN_MAXTEXT:
            // EN_MAXTEXT means they pressed Enter...
            goto AddString;

        case EN_SETFOCUS:
            {
                const static EDITBALLOONTIP balloonTip = {
                    sizeof(balloonTip),
                    L"Test string",
                    L"Press Enter or click the '+' to add the string to the list. "
                    L"This string will be used when identifying applicable lookups.",
                    TTI_INFO
                };
                Edit_ShowBalloonTip(GetSubdialogItem(IddStringsList, IdcStringsListString), &balloonTip);
            }
            break;

        default:
            return false;
        }
        break;

    case IdcStringsListAddString:
    AddString:
        if (EnsureUiConditionTrue(!profilingThread_, L"Stop profiling first.", IddPerfScore))
        {
            const auto stringHwnd = GetSubdialogItem(IddStringsList, IdcStringsListString);
            const uint32_t testStringLength = Edit_GetTextLength(stringHwnd);
            if (testStringLength == 0)
                break;

            std::wstring testString(testStringLength+1, '\0');
            Edit_GetText(stringHwnd, &testString[0], testStringLength+1);
            testString.resize(testStringLength);

            stringsList_.resize(stringsList_.size() + 1);
            auto& stringInfo = stringsList_.back();
            stringInfo.description = L"User string";
            stringInfo.sample = testString;
            Edit_SetSel(stringHwnd, 0, 32767);
            stringInfo.isSimple = IsStringSimple(testString.c_str(), testStringLength);
            stringInfo.isSelected = true;
            UpdateStringsListUi(static_cast<uint32_t>(stringsList_.size() - 1));

            AppendLog(L"Added string.\r\n");
        }
        break;

    case IdcPerfProfileStart:
        SelectCurrentPane(newPaneId);
        ProfileStart();
        break;

    case IdcPerfProfileStop:
        ProfileStop();
        break;

    case IdcPerfResultsSave:
        break;

    case IdcLookupsIdentifySimple:
        IdentifyLookups(IdentifyLookupsOptionSimple);
        break;

    case IdcLookupsIdentifyApplicable:
        IdentifyLookups(IdentifyLookupsOptionStrings);
        break;

    case IdcLookupsShowAll:
        IdentifyLookups(IdentifyLookupsOptionAll);
        break;

    case IdcLookupsIdentifyFeatures:
        IdentifyLookups(IdentifyLookupsOptionFeatures);
        break;

    case IdcFontsSelectSupportingFonts:
        SelectFontsSupportingCharacters();
        break;

    case IdcFontsDeselectOtherDuplicates:
        SelectDuplicateFonts(/*selection*/true, false);
        break;

    case IdcFontsDeselectAllDuplicates:
        SelectDuplicateFonts(/*selection*/true, true);
        break;

    case IdcActionsListExecuteSelected:
        ExecuteSelectedAutomatedAction();
        break;
    case IdcActionsListStart:
        StartAutomatedActions();
        break;

    case IdcActionsListPause:
        PauseAutomatedActions();
        break;

    case IdcActionsListStop:
        StopAutomatedActions();
        break;

    case IdcActionsListLoad:
        LoadAutomatedActionsFile();
        break;

    case IdcMainTabsMoveNext:
    case IdcMainTabsMovePrevious:
        {
            int newPaneId = GetWrappedIncrement(currentPaneId_, (wmId == IdcMainTabsMoveNext) ? 1 : -1, IddMainFirstDialog, IddMainLastDialog);
            SelectCurrentPane(newPaneId, true);
        }
        break;

    default:
        return DialogProcResult(false, -1); // unhandled
    }

    return DialogProcResult(true, 0); // handled
}


#ifndef LVN_GETEMPTYTEXTW
#define LVN_GETEMPTYTEXTW          (LVN_FIRST-61) 
#define LVM_RESETEMPTYTEXT         0x1054
#endif

namespace
{
    bool HandleListViewEmptyText(LPARAM lParam, const wchar_t* text)
    {
        LV_DISPINFO& di = *(LV_DISPINFO*)lParam;
        if (di.hdr.code != LVN_GETEMPTYTEXTW)
            return false;

        if (di.item.mask & LVIF_TEXT)
        {  
            StringCchCopyW(
                di.item.pszText,
                di.item.cchTextMax,
                text
                );
            return true;
        }
        return false;
    }
}


DialogProcResult CALLBACK MainWindow::ProcessNotification(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    int idCtrl = (int) wParam; 
    NMHDR const& nmh = *(NMHDR*)lParam;

    switch (idCtrl)
    {
    case IdcStringsListStrings:
        switch (nmh.code)
        {
        case LVN_ODSTATECHANGED:
        case LVN_ITEMCHANGED:
            // Select the internal flags according to user input.
            if (!preventListViewRecursion_)
            {
                std::function<void(uint32_t, uint32_t, bool)> f = [this](uint32_t start, uint32_t end, bool state) mutable
                {
                    end = std::min(end, static_cast<uint32_t>(stringsList_.size()));
                    for (uint32_t i = start; i < end; ++i)
                        this->stringsList_[i].isSelected = state;
                };
                if (HandleListViewSelectionChange(nmh.code, lParam, f))
                    SetTimer(hwnd_, IdcStringsListStrings, 100, nullptr);
            }
            break;

        case LVN_GETDISPINFO:
            {
                // Return listview text of internal data.
                NMLVDISPINFO& di = *(NMLVDISPINFO*)lParam;
                if ((unsigned)di.item.iItem >= stringsList_.size())
                    return false;

                const StringInfo& si = stringsList_[di.item.iItem];
                if (di.item.mask & LVIF_TEXT)
                {
                    switch (di.item.iSubItem)
                    {
                    case 0: di.item.pszText = (LPWSTR)si.description.c_str();   break;
                    case 1: di.item.pszText = (LPWSTR)si.sample.c_str();        break;
                    case 2: 
                        if (si.coverageCount == -1)
                        {
                            di.item.pszText = L"";
                        }
                        else
                        {
                            uint32_t coveragePercentage = si.coverageCount * 100 / std::max(si.maxCoverageCount, 1u);
                            StringCchPrintf(di.item.pszText, di.item.cchTextMax, L"%d%%", std::max(coveragePercentage, 1u));
                        }
                        break;
                    case 3: di.item.pszText = si.isSimple ? L" ✔" : L"";        break;
                    }
                }
                if (di.item.mask & LVIF_STATE)
                {
                    di.item.stateMask = LVIS_SELECTED;
                    di.item.state = (di.item.state & ~LVIS_SELECTED) | (si.isSelected ? LVIS_SELECTED : 0);
                }
            }
            break;

        case LVN_ODFINDITEM:
            {
                // Find matching string in the strings list, called when the user starts typing in the listview.
                NMLVFINDITEM& findInfo = *(NMLVFINDITEM*)lParam;

                if (!(findInfo.lvfi.flags & LVFI_STRING))
                    return DialogProcResult(false, -1);

                int index = -1;
                const bool findPartialMatch = !!(findInfo.lvfi.flags & (LVFI_PARTIAL|LVFI_SUBSTRING));
                const size_t comparingStringLength = wcslen(findInfo.lvfi.psz);

                for (uint32_t i = 0, ci = static_cast<uint32_t>(stringsList_.size()); i < ci; ++i)
                {
                    const uint32_t j = (i + findInfo.iStart) % ci; // Wrap around
                    const auto& stringInfo = stringsList_[j];
                     
                    if (findPartialMatch
                    ?   (_wcsnicmp(findInfo.lvfi.psz, stringInfo.description.c_str(), comparingStringLength) == 0)
                    :   (wcscmp(findInfo.lvfi.psz, stringInfo.description.c_str()) == 0))
                    {
                        index = j;
                        break; // Found our matching index to return.
                    }
                }
                
                return DialogProcResult(true, index);
            }
            break;

        case NM_RETURN:
        case NM_DBLCLK:
            UpdateTextFromSelectedStrings();
            ProcessCommand(hwnd, WM_COMMAND, IdcPerfProfileStart, (LPARAM)nmh.hwndFrom);
            break;

        case LVN_GETEMPTYTEXTW:
            HandleListViewEmptyText(lParam, L"\r\nNo strings are loaded.\r\n\r\nAdd custom ones or reset to the defaults.");
            return DialogProcResult(true, 1);

        default:
            return false;
        }
        break;

    case IdcMainTabs:
        switch (nmh.code)
        {
        case TCN_SELCHANGE:
            SelectCurrentPane(IddMainFirstDialog + (int)TabCtrl_GetCurSel(nmh.hwndFrom), true);
            break;

        default:
            return false;
        }
        break;

    case IdcAttributeList:
        {
            AttributeList::NotifyMessage const& nm = *(AttributeList::NotifyMessage*)lParam;
            if (nm.code != AttributeList::NotifyClicked)
                break;

            const unsigned int value = nm.value;
            const bool isNonzeroValue = (value != 0);

            switch (nm.itemId)
            {
            case IdcPerfGrouping:
                {
                    const static uint32_t g_perfGroupingValues[] = {
                        PerfGroupingString|PerfGroupingFont,
                        PerfGroupingFile,
                        PerfGroupingString,
                        PerfGroupingString|PerfGroupingFont|PerfGroupingFile,
                        PerfGroupingNone
                    };
                    if (value < ARRAYSIZE(g_perfGroupingValues))
                    {
                        perfGrouping_ = g_perfGroupingValues[value];
                    }
                }

            case IdcPerfSkipPartialCoverageFonts:
                skipPartialCoverageFonts_ = isNonzeroValue;
                break;
            };
        }
        break;

    case IdcFontsListFonts:
        switch (nmh.code)
        {
        case LVN_GETEMPTYTEXTW:
            HandleListViewEmptyText(
                lParam,
                L"\r\n"
                L"No fonts are loaded.\r\n\r\n"
                L"To compare a new font to an old one (like an updated Segoe UI), \r\nload both the font files (the Open dialog supports multiple selection), \r\nselect the strings to test, and then profile them.\r\n\r\n"
                L"To compare different system fonts, load the system fonts, \r\nselect the ones you want to test, select strings, and then profile."
                );
            return DialogProcResult(true, 1);

        case LVN_ODSTATECHANGED:
        case LVN_ITEMCHANGED:
            {
                std::function<void(uint32_t, uint32_t, bool)> f = [this](uint32_t start, uint32_t end, bool state) mutable
                {
                    end = std::min(end, static_cast<uint32_t>(fontsList_.size()));
                    for (uint32_t i = start; i < end; ++i)
                        fontsList_[i].isSelected = state;
                };
                HandleListViewSelectionChange(nmh.code, lParam, f);
            }
            break;

        case NM_RETURN:
        case NM_DBLCLK:
            ProcessCommand(hwnd, WM_COMMAND, IdcStringsSelectSharedInFonts, (LPARAM)nmh.hwndFrom);
            break;

        default:
            return false;
        }
        break;

    case IdcPerfScoreResults:
        return HandleListViewEmptyText(lParam, L"\r\nNo perf results yet.\r\n\r\nProfile to record them.")
            ? DialogProcResult(true, 1)
            : false;

    case IdcLookupsListLookups:
        return HandleListViewEmptyText(lParam, L"\r\nNo lookups identified yet.\r\n\r\nSelect fonts and identify lookups.")
            ? DialogProcResult(true, 1)
            : false;

    case IdcActionsList:
        switch (nmh.code)
        {
        case NM_RETURN:
        case NM_DBLCLK:
            ExecuteSelectedAutomatedAction();
            break;

        case LVN_GETEMPTYTEXTW:
            HandleListViewEmptyText(lParam, L"\r\nNo actions loaded.\r\n\r\nSpecify Actions=file.txt from the command line.");
            return DialogProcResult(true, 1);
        }
        break;

    default:
        return false;

    } // switch idCtrl

    return true;
}


DialogProcResult CALLBACK MainWindow::ProcessDragAndDrop(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    std::vector<wchar_t> fileNames;
    HDROP hDrop = (HDROP)wParam;

    // Get the number of files being dropped.
    const uint32_t fileCount = DragQueryFile(hDrop, 0xFFFFFFFF, nullptr, 0);

    // Accumulate all the filenames into a list to load.
    for (uint32_t i = 0; i < fileCount; ++i)
    {
        const uint32_t fileNamesOldSize = static_cast<uint32_t>(fileNames.size());
        const uint32_t fileNameSize = DragQueryFile(hDrop, i, nullptr, 0);
        if (fileNameSize == 0)
            continue;

        fileNames.resize(fileNamesOldSize + fileNameSize + 1);
        if (!DragQueryFile(hDrop, i, &fileNames[fileNamesOldSize], fileNameSize + 1))
        {
            fileNames.resize(fileNamesOldSize); // restore old size
        }
    }
    DragFinish(hDrop);

    // Load the font files.
    fileNames.push_back('\0'); // double nul termination
    LoadFontFiles(
        L"", // fileDirectory
        fileNames.data()
        );

    SelectCurrentPane(IddFontsList);

    return DialogProcResult(/*handled*/ true, /*value*/ 0);
}


void MainWindow::Resize(int id)
{
    // Resize the subdialog of the given id and all contained controls.

    HWND hwnd;
    long const spacing = 4;
    RECT clientRect;

    static_assert(IddMainDialogCount == 6, "Update this code for new dialog count");

    switch (id)
    {
    case IddMainWindow:
        {
            hwnd = hwnd_;
            GetClientRect(hwnd, OUT &clientRect);
            RECT paddedClientRect = clientRect;
            InflateRect(IN OUT &paddedClientRect, -spacing, -spacing);

            const size_t attributeListIndex     = 2;
            const size_t logIndex               = 4;
            const long mainWindowThirdWidth     = paddedClientRect.right / 3;
            const long mainWindowQuarterHeight  = paddedClientRect.bottom / 4;
            WindowPosition windowPositions[] = {
                WindowPosition( GetDlgItem(hwnd, IdcMainTabs), PositionOptionsFillWidth|PositionOptionsAlignTop),
                WindowPosition( GetDlgItem(hwnd, currentPaneId_), PositionOptionsFillWidth|PositionOptionsFillHeight|PositionOptionsNewLine),
                WindowPosition( GetDlgItem(hwnd, IdcAttributeList), PositionOptionsFillHeight|PositionOptionsAlignLeft),
                WindowPosition( GetDlgItem(hwnd, IdcProgress), PositionOptionsFillWidth|PositionOptionsAlignTop|PositionOptionsNewLine),
                WindowPosition( GetDlgItem(hwnd, IdcLog), PositionOptionsFillWidth|PositionOptionsAlignTop|PositionOptionsNewLine),
            };
            // Attribute list
            windowPositions[attributeListIndex].rect.left   = 0;
            windowPositions[attributeListIndex].rect.right  = std::min(mainWindowThirdWidth, 200l);
            // Log
            windowPositions[logIndex].rect.top              = 0;
            windowPositions[logIndex].rect.bottom           = std::min(mainWindowQuarterHeight, 80l);

            WindowPosition::ReflowGrid(windowPositions, ARRAY_SIZE(windowPositions), paddedClientRect, spacing, 0, PositionOptionsFlowHorizontal|PositionOptionsUnwrapped);
            WindowPosition::Update(windowPositions, ARRAY_SIZE(windowPositions));
        }
        break;

    case IddFontsList:
        {
            hwnd = GetDlgItem(hwnd_, id);
            GetClientRect(hwnd, OUT &clientRect);

            WindowPosition windowPositions[] = {
                WindowPosition( GetDlgItem(hwnd, IdcFontsListFonts), PositionOptionsFillWidth|PositionOptionsFillHeight|PositionOptionsNewLine),
                WindowPosition( GetDlgItem(hwnd, IdcStringsSelectSharedInFonts), PositionOptionsAlignRight|PositionOptionsUseSlackWidth|PositionOptionsAlignTop|PositionOptionsNewLine),
            };

            WindowPosition::ReflowGrid(windowPositions, ARRAY_SIZE(windowPositions), clientRect, spacing, 0, PositionOptionsDefault);
            WindowPosition::Update(windowPositions, ARRAY_SIZE(windowPositions));
        }
        break;

    case IddStringsList:
        {
            hwnd = GetDlgItem(hwnd_, id);
            GetClientRect(hwnd, OUT &clientRect);

            WindowPosition windowPositions[] = {
                WindowPosition( GetDlgItem(hwnd, IdcStringsListStrings), PositionOptionsFillWidth|PositionOptionsFillHeight|PositionOptionsNewLine),
                WindowPosition( GetDlgItem(hwnd, IdcStringsListStringStatic), PositionOptionsAlignLeft|PositionOptionsAlignTop|PositionOptionsNewLine),
                WindowPosition( GetDlgItem(hwnd, IdcStringsListString), PositionOptionsFillWidth|PositionOptionsAlignTop),
                WindowPosition( GetDlgItem(hwnd, IdcStringsListAddString), PositionOptionsAlignRight|PositionOptionsAlignTop),
                WindowPosition( GetDlgItem(hwnd, IdcFontsSelectSupportingFonts), PositionOptionsAlignLeft|PositionOptionsAlignTop|PositionOptionsNewLine),
                WindowPosition( GetDlgItem(hwnd, IdcPerfProfileStart), PositionOptionsAlignRight|PositionOptionsUseSlackWidth|PositionOptionsAlignTop),
            };

            WindowPosition::ReflowGrid(windowPositions, ARRAY_SIZE(windowPositions), clientRect, spacing, 0, PositionOptionsDefault);
            WindowPosition::Update(windowPositions, ARRAY_SIZE(windowPositions));
        }
        break;

    case IddPerfScore:
        {
            hwnd = GetDlgItem(hwnd_, id);
            GetClientRect(hwnd, OUT &clientRect);

            WindowPosition windowPositions[] = {
                WindowPosition( GetDlgItem(hwnd, IdcPerfScoreResults), PositionOptionsFillWidth|PositionOptionsFillHeight|PositionOptionsNewLine),
                WindowPosition( GetDlgItem(hwnd, IdcPerfFeaturesStatic), PositionOptionsAlignLeft|PositionOptionsAlignBottom|PositionOptionsNewLine),
                WindowPosition( GetDlgItem(hwnd, IdcPerfFeatures), PositionOptionsFillWidth|PositionOptionsAlignTop),
                WindowPosition( GetDlgItem(hwnd, IdcPerfProfileStart), PositionOptionsAlignLeft|PositionOptionsAlignTop|PositionOptionsNewLine),
                WindowPosition( GetDlgItem(hwnd, IdcPerfProfileStop), PositionOptionsAlignLeft|PositionOptionsAlignTop),
                WindowPosition( GetDlgItem(hwnd, IdcLookupsIdentifyApplicable), PositionOptionsAlignRight|PositionOptionsUseSlackWidth|PositionOptionsAlignTop),
            };

            WindowPosition::ReflowGrid(windowPositions, ARRAY_SIZE(windowPositions), clientRect, spacing, 0, PositionOptionsDefault);
            WindowPosition::Update(windowPositions, ARRAY_SIZE(windowPositions));
        }
        break;

    case IddLookupsList:
        {
            hwnd = GetDlgItem(hwnd_, id);
            GetClientRect(hwnd, OUT &clientRect);

            WindowPosition windowPositions[] = {
                WindowPosition( GetDlgItem(hwnd, IdcLookupsListLookups), PositionOptionsFillWidth|PositionOptionsFillHeight|PositionOptionsNewLine),
                WindowPosition( GetDlgItem(hwnd, IdcLookupsFeaturesStatic), PositionOptionsAlignLeft|PositionOptionsAlignBottom|PositionOptionsNewLine),
                WindowPosition( GetDlgItem(hwnd, IdcLookupsFeatures), PositionOptionsFillWidth|PositionOptionsAlignTop),
                WindowPosition( GetDlgItem(hwnd, IdcLookupsIdentifyApplicable), PositionOptionsAlignLeft|PositionOptionsAlignTop|PositionOptionsNewLine),
                WindowPosition( GetDlgItem(hwnd, IdcLookupsIdentifySimple), PositionOptionsAlignLeft|PositionOptionsAlignTop),
                WindowPosition( GetDlgItem(hwnd, IdcLookupsShowAll), PositionOptionsAlignLeft|PositionOptionsUseSlackWidth|PositionOptionsAlignTop),
            };

            WindowPosition::ReflowGrid(windowPositions, ARRAY_SIZE(windowPositions), clientRect, spacing, 0, PositionOptionsDefault);
            WindowPosition::Update(windowPositions, ARRAY_SIZE(windowPositions));
        }
        break;

    case IddActionsList:
        {
            hwnd = GetDlgItem(hwnd_, id);
            GetClientRect(hwnd, OUT &clientRect);

            WindowPosition windowPositions[] = {
                WindowPosition( GetDlgItem(hwnd, IdcActionsList), PositionOptionsFillWidth|PositionOptionsFillHeight),
                WindowPosition( GetDlgItem(hwnd, IdcActionsListStart), PositionOptionsAlignLeft|PositionOptionsAlignTop|PositionOptionsNewLine),
                WindowPosition( GetDlgItem(hwnd, IdcActionsListPause), PositionOptionsAlignLeft|PositionOptionsAlignTop),
                WindowPosition( GetDlgItem(hwnd, IdcActionsListStop), PositionOptionsAlignLeft|PositionOptionsAlignTop),
            };

            WindowPosition::ReflowGrid(windowPositions, ARRAY_SIZE(windowPositions), clientRect, spacing, 0, PositionOptionsDefault);
            WindowPosition::Update(windowPositions, ARRAY_SIZE(windowPositions));
        }
        break;

    case IddHelp:
        {
            hwnd = GetDlgItem(hwnd_, id);
            GetClientRect(hwnd, OUT &clientRect);

            WindowPosition windowPositions[] = {
                WindowPosition( GetDlgItem(hwnd, IdcHelp), PositionOptionsFillWidth|PositionOptionsFillHeight),
            };

            WindowPosition::ReflowGrid(windowPositions, ARRAY_SIZE(windowPositions), clientRect, spacing, 0, PositionOptionsDefault);
            WindowPosition::Update(windowPositions, ARRAY_SIZE(windowPositions));
        }
        break;
    }
}


void MainWindow::SelectCurrentPane(int newCurrentPane, bool shouldSetKeyFocus)
{
    if (newCurrentPane == currentPaneId_ || newCurrentPane == -1)
    {
        return;
    }

    HWND oldFocus  = GetFocus();
    HWND oldWindow = GetDlgItem(hwnd_, currentPaneId_);
    HWND newWindow = GetDlgItem(hwnd_, newCurrentPane);

    if (oldWindow != nullptr)
    {
        ShowWindow(oldWindow, SW_HIDE);
    }

    // Update tabs too.
    TabCtrl_SetCurSel(GetDlgItem(hwnd_, IdcMainTabs), newCurrentPane - IddMainFirstDialog);
    currentPaneId_ = newCurrentPane;

    // Need to resize the newly exposed pane.
    Resize(IddMainWindow);
    Resize(currentPaneId_);

    if (newWindow != nullptr)
    {
        ShowWindow(newWindow, SW_SHOW);

        // Set so that when the Enter key is pressed, that we get a useful action.
        SendMessage(newWindow, DM_SETDEFID, GetCurrentPaneDefaultId(), 0);

        // Set key focus if the caller asked for it, or if we're hiding a
        // window that previous had focus (leaving no current key focus).
        if (shouldSetKeyFocus || IsChild(oldWindow, oldFocus))
        {
            HWND focusControl = GetNextDlgTabItem(newWindow, nullptr, false);
            SendMessage(newWindow, WM_NEXTDLGCTL, (WPARAM)focusControl, TRUE); // instead of SetFocus directly
        }
    }

    for (uint32_t i = 0; i < ARRAYSIZE(g_attributeListItems); ++i)
    {
        int paneId = GetCommandPaneId(g_attributeListItems[i].id);
        if (paneId != -1)
        {
            auto& item = g_attributeListItems[i];
            item.UpdateFlags(AttributeList::Item::FlagGray, paneId != currentPaneId_);
            item.SetRedraw();
        }
    }

    PostMessage(GetDlgItem(hwnd_, IdcAttributeList), WM_PAINT, 0, 0);
}


namespace
{
    std::wstring GetConcatenatedFamilyNames(IDWriteLocalizedStrings* familyNames)
    {
        std::wstring familyNamesConcatenated;
        wchar_t familyName[256]; familyName[0] = '\0';

        // Read all the font family names and contenate them.
        const uint32_t familyNamesCount = familyNames->GetCount();
        for (uint32_t i = 0; i < familyNamesCount; ++i)
        {
            familyNames->GetString(i, familyName, ARRAY_SIZE(familyName));
            familyNamesConcatenated.append(familyName);
            familyNamesConcatenated.append(1, '\0');
        }

        return familyNamesConcatenated;
    }


    HRESULT /*IDWriteFontFile::*/GetFilePath(
        IDWriteFontFile* fontFile,
        __out_ecount_z(filePathSize) wchar_t* filePath,
        uint32_t filePathSize
        )
    {
        // A few hoops to get the filename...

        uint32_t fontFileReferenceKeySize = 0;
        void const* fontFileReferenceKey = nullptr;

        ComPtr<IDWriteFontFileLoader> fontFileLoader;
        ComPtr<IDWriteLocalFontFileLoader> localFontFileLoader;

        IFR(fontFile->GetLoader(&fontFileLoader));

        IFR(fontFile->GetReferenceKey(
                &fontFileReferenceKey,
                &fontFileReferenceKeySize
                ));

        IFR(fontFileLoader->QueryInterface(&localFontFileLoader));

        return localFontFileLoader->GetFilePathFromKey(fontFileReferenceKey, fontFileReferenceKeySize, filePath, filePathSize);
    }


    UINT_PTR CALLBACK ChooseFontHookProc(
        HWND dialogHandle,
        UINT message,
        WPARAM wParam,
        LPARAM lParam
        )
    {
        if (message == WM_COMMAND && HIWORD(wParam) == BN_CLICKED)
        {
            // If Apply is clicked, update the layout now without closing the font chooser dialog.
            if (LOWORD(wParam) == WM_CHOOSEFONT_GETLOGFONT + 1)
            {
                LOGFONT logFont = {};
                SendMessage(dialogHandle, WM_CHOOSEFONT_GETLOGFONT, 0, (LPARAM)&logFont);
                HWND owner = GetWindow(dialogHandle, GW_OWNER);
                if (owner == nullptr)
                    return 0;
            
                MainWindow* window = GetClassFromWindow<MainWindow>(owner);
                if (window == nullptr)
                    return 0;

                window->LoadSystemFileFromLogFont(logFont);

                return true;
            }
        }

        return 0;
    }
}


HRESULT MainWindow::LoadSystemFont()
{
    //////////////////////////////
    // Initialize the LOGFONT from the current format.
    LOGFONT logFont = {};

    BOOL hasUnderline = false;
    BOOL hasStrikethrough = false;
    DWRITE_FONT_STYLE fontStyle = DWRITE_FONT_STYLE_NORMAL;
    DWRITE_FONT_WEIGHT fontWeight = DWRITE_FONT_WEIGHT_NORMAL;
    float fontSize = 20;

    logFont.lfHeight            = -static_cast<LONG>(floor(fontSize));
    logFont.lfWidth             = 0;
    logFont.lfEscapement        = 0;
    logFont.lfOrientation       = 0;
    logFont.lfWeight            = fontWeight;
    logFont.lfItalic            = (fontStyle > DWRITE_FONT_STYLE_NORMAL);
    logFont.lfUnderline         = static_cast<BYTE>(hasUnderline);
    logFont.lfStrikeOut         = static_cast<BYTE>(hasStrikethrough);
    logFont.lfCharSet           = DEFAULT_CHARSET;
    logFont.lfOutPrecision      = OUT_DEFAULT_PRECIS;
    logFont.lfClipPrecision     = CLIP_DEFAULT_PRECIS;
    logFont.lfQuality           = DEFAULT_QUALITY;
    logFont.lfPitchAndFamily    = DEFAULT_PITCH;

    //////////////////////////////
    // Initialize CHOOSEFONT for the dialog.

    #ifndef CF_INACTIVEFONTS
    #define CF_INACTIVEFONTS  0x02000000L
    #endif
    CHOOSEFONT chooseFont   = {};
    chooseFont.lpfnHook     = &ChooseFontHookProc;
    chooseFont.lStructSize  = sizeof(chooseFont);
    chooseFont.hwndOwner    = hwnd_;
    chooseFont.lpLogFont    = &logFont;
    chooseFont.iPointSize   = INT(fontSize * 10 + .5f);
    chooseFont.rgbColors    = 0;
    chooseFont.Flags        = CF_SCREENFONTS
                            | CF_PRINTERFONTS
                            | CF_INACTIVEFONTS  // DON'T HIDE FONTS!
                            | CF_NOVERTFONTS
                            | CF_NOSCRIPTSEL
                            | CF_EFFECTS
                            | CF_INITTOLOGFONTSTRUCT
                            | CF_ENABLEHOOK
                            | CF_APPLY
                            ;
    // We don't show fake vertical fonts, and we don't bitmap fonts because
    // DirectWrite doesn't support them.

    // Show the common font dialog box.
    if (!ChooseFont(&chooseFont))
    {
        return S_FALSE; // user canceled.
    }

    return LoadSystemFileFromLogFont(logFont);
}


HRESULT MainWindow::LoadSystemFileFromLogFont(LOGFONT const& logFont)
{
    ComPtr<IDWriteGdiInterop> gdiInterop;
    ComPtr<IDWriteFont> font;

    Application::g_DWriteFactory->GetGdiInterop(&gdiInterop);
    if (gdiInterop != nullptr)
    {
        gdiInterop->CreateFontFromLOGFONT(&logFont, &font);
        if (font != nullptr)
        {
            ComPtr<IDWriteFontFace> fontFace;
            IFR(font->CreateFontFace(&fontFace));

            ComPtr<IDWriteFontFile> fontFile;
            uint32_t numberOfFiles = 1;
            IFR(fontFace->GetFiles(&numberOfFiles, &fontFile));
            wchar_t filePath[MAX_PATH];
            IFR(GetFilePath(
                fontFile,
                filePath,
                ARRAYSIZE(filePath)
                ));

            uint32_t firstFontInfoId = newestFontInfoId_;
            uint32_t addedFontCount = AppendFontToFontsList(
                                        font,
                                        filePath,
                                        true, // shouldSelectFiles
                                        fontFace->GetIndex()
                                        );

            AppendLog(L"Loaded system fonts = %d, %s\r\n", addedFontCount, logFont.lfFaceName);
            RemoveDuplicateInFontsList();
            UpdateFontsListUi(firstFontInfoId);
        }
    }

    return S_OK;
}


HRESULT MainWindow::LoadAllSystemFonts()
{
    // Enumerate all the fonts in the registry. This is much faster than
    // determining the file path from the system font collection, which
    // requires you to create the heavy weight font face for each one.
    // *Note this leaves out any virtually added fonts that aren't actually
    // in the system font collection like Marlett (which DWrite injects
    // manually even if not referenced by the registry).

    wchar_t const static fontsRegistryKeyName[] = L"SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Fonts";

    wchar_t systemFontsPath[MAX_PATH]; systemFontsPath[0] = '\0';
    SHGetFolderPath(nullptr, CSIDL_FONTS, nullptr, SHGFP_TYPE_CURRENT, systemFontsPath);

    RegistryValueIterator fontsIterator(HKEY_LOCAL_MACHINE, fontsRegistryKeyName);
    wchar_t filePath[MAX_PATH + 1];
    uint32_t addedFontCount = 0;
    uint32_t fontFileCount = 0;

    while (fontsIterator.Advance())
    {
        const wchar_t* keyValue = fontsIterator.GetCurrentValueString();
        if (keyValue == nullptr)
            continue;

        PathCombine(filePath, systemFontsPath, keyValue);
        const uint32_t filePathLength = static_cast<uint32_t>(wcslen(filePath));
        const uint32_t filePathKeySize = (filePathLength + 1 + 1) * sizeof(*filePath);
        filePath[filePathLength + 1] = '\0'; // ensure double null terminated
        ++fontFileCount;

        HRESULT hr = S_OK;
        ComPtr<IDWriteFontCollection> fontCollection;

        if (SUCCEEDED(hr = CreateFontCollection(
            Application::g_DWriteFactory,
            filePath,
            filePathKeySize,
            &fontCollection
            )))
        {
            addedFontCount += AppendCollectionToFontsList(fontCollection, filePath, false);
        }
        else
        {
            AppendLog(L"Failed to load font file: %s (hr=%X)\r\n", filePath, hr);
        }

        std::pair<uint32_t, uint32_t> progress = fontsIterator.GetProgress();
        SetProgress(progress.first, progress.second);
    }

    AppendLog(L"Loaded %d system fonts from %d files\r\n", addedFontCount, fontFileCount);
    RemoveDuplicateInFontsList();
    UpdateFontsListUi();

    SetProgress(0,0);

    return S_OK;
}


HRESULT MainWindow::LoadFontFiles()
{
    // Allocate sizeable buffer for file names, since the user can multi-select.
    // This should be enough for some of those large directories of 3000 names
    // of typical filename length.
    std::wstring fileNames(65536, '\0');

    // Initialize OPENFILENAME
    OPENFILENAME ofn;
    ZeroStructure(ofn);
    ofn.lStructSize     = sizeof(ofn);
    ofn.hwndOwner       = hwnd_;
    ofn.lpstrFile       = &fileNames[0];
    ofn.nMaxFile        = fileNames.size() - 1;
    ofn.lpstrFilter     = L"Fonts\0*.ttf;*.ttc;*.otf;*.otc;*.tte\0"
                          L"TrueType (ttf)\0*.ttf\0"
                          L"TrueType Collection (ttc)\0*.ttc\0"
                          L"OpenType (ttf)\0*.otf\0"
                          L"OpenType Collection (ttc)\0*.otc\0"
                          L"TrueType EUDC (tte)\0*.tte\0"
                          L"All\0*.*\0"
                          ;
    ofn.nFilterIndex    = 1;
    ofn.lpstrFileTitle  = nullptr;
    ofn.nMaxFileTitle   = 0;
    ofn.lpstrInitialDir = nullptr;
    ofn.Flags = OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST | OFN_ALLOWMULTISELECT | OFN_EXPLORER | OFN_HIDEREADONLY;

    if (!GetOpenFileName(&ofn))
    {
        return S_FALSE;
    }

    // Explicitly separate the preceding path from filename for consistency
    // since the dialog returns things differently for one filename vs multiple.
    if (ofn.nFileOffset > 0)
    {
        fileNames[ofn.nFileOffset - 1] = '\0';
    }

    return LoadFontFiles(
        fileNames.data(),
        &fileNames[ofn.nFileOffset]
        );
}


HRESULT MainWindow::LoadFontFiles(
    __in_z const wchar_t* fileDirectory,
    __in __nullnullterminated const wchar_t* fileNames
    )
{
    wchar_t filePath[MAX_PATH + 1];
    uint32_t addedFileCount = 0;
    uint32_t addedFontCount = 0;
    uint32_t fontFileCount = 0;
    uint32_t firstFontInfoId = newestFontInfoId_;

    // Quickly check how many files there are total.
    for (uint32_t fileNamesIndex = 0; // start at first filename
         fileNames[fileNamesIndex] != '\0'; // while we have filenames
         fileNamesIndex += wcslen(&fileNames[fileNamesIndex]) + 1 // next filename
        )
    {
        ++fontFileCount;
    }

    // Create each file and add to collection.
    for (uint32_t fileNamesIndex = 0; // start at first filename
         fileNames[fileNamesIndex] != '\0'; // while we have filenames
         fileNamesIndex += wcslen(&fileNames[fileNamesIndex]) + 1 // next filename
        )
    {
        // Build full path name.
        PathCombine(filePath, fileDirectory, &fileNames[fileNamesIndex]);
        const uint32_t filePathLength = static_cast<uint32_t>(wcslen(filePath));
        const uint32_t filePathKeySize = (filePathLength + 1 + 1) * sizeof(*filePath);
        filePath[filePathLength + 1] = '\0'; // ensure double null terminated
        ++addedFileCount;

        HRESULT hr = S_OK;
        ComPtr<IDWriteFontCollection> fontCollection;

        if (SUCCEEDED(hr = CreateFontCollection(
            Application::g_DWriteFactory,
            filePath,
            filePathKeySize,
            &fontCollection
            )))
        {
            addedFontCount += AppendCollectionToFontsList(fontCollection, filePath, true);
        }
        else
        {
            AppendLog(L"Failed to load font file: %s (hr=%X)\r\n", filePath, hr);
        }

        SetProgress(++addedFileCount, fontFileCount);
    }

    AppendLog(L"Loaded %d fonts from %d files.\r\n", addedFontCount, fontFileCount);
    RemoveDuplicateInFontsList();
    UpdateFontsListUi(firstFontInfoId);

    SetProgress(0,0);

    return S_OK;
}


// Add all the fonts in a collection to the font info list.
uint32_t MainWindow::AppendFontToFontsList(
    IDWriteFont* font,
    __in_z const wchar_t* filePath,
    bool shouldSelectFiles,
    uint32_t familyIndex
    )
{
    // Get the name from the family.
    ComPtr<IDWriteFontFamily> fontFamily;
    HRESULT hr = font->GetFontFamily(&fontFamily);
    if (fontFamily == nullptr)
    {
        AppendLog(L"Could get font family from font, hr=%X??\r\n", hr);
        return 0;
    }

    ComPtr<IDWriteLocalizedStrings> familyNames;
    hr = fontFamily->GetFamilyNames(&familyNames);
    if (familyNames == nullptr)
    {
        AppendLog(L"Could not read font family name from font %d, hr=%X??\r\n", hr);
        return 0;
    }

    const std::wstring familyNamesConcatenated = GetConcatenatedFamilyNames(familyNames);

    return AppendFontToFontsList(
        font,
        filePath,
        shouldSelectFiles,
        familyNamesConcatenated,
        familyIndex, // important for determining which face index to create the font face from later
        0 // fontIndex
        );
}


// Add all the fonts in a collection to the font info list.
uint32_t MainWindow::AppendFontToFontsList(
    IDWriteFont* font,
    __in_z const wchar_t* filePath,
    bool shouldSelectFiles,
    const std::wstring& familyNames,
    uint32_t familyIndex,
    uint32_t fontIndex
    )
{
    HRESULT hr;
    wchar_t styleName[256]; styleName[0] = '\0';

    // Get the style name (which is more involved due to localization of face names).
    ComPtr<IDWriteLocalizedStrings> styleNames;
    hr = font->GetFaceNames(&styleNames);
    if (styleNames == nullptr)
    {
        AppendLog(L"Could not read font style names at font index %d, hr=%X??\r\n", fontIndex, hr);
    }
    else if (styleNames->GetCount() > 0)
    {
        // Look for English name first.
        uint32_t styleNameIndex = 0;
        BOOL dummyExists;
        styleNames->FindLocaleName(L"en-us", &styleNameIndex, &dummyExists);
        if (styleNameIndex >= styleNames->GetCount())
        {
            styleNameIndex = 0; // default to first name index
        }

        styleNames->GetString(styleNameIndex, styleName, ARRAY_SIZE(styleName));

        // Append a little asterisk if it's not a true face (simulated)
        if (font->GetSimulations() != DWRITE_FONT_SIMULATIONS_NONE)
            StringCchCat(styleName, ARRAY_SIZE(styleName), L"*");
    }

    fontsList_.resize(fontsList_.size() + 1);
    FontInfo& fontInfo = fontsList_.back();

#if 0 // debug hack

    ComPtr<IDWriteFontFace> fontFace;
    font->CreateFontFace(OUT &fontFace);
    FontTablePtr fontTablePtr(fontFace, '2/SO');
    uint16_t value = 0;
    if (!fontTablePtr.empty())
    {
        auto& os2Table = fontTablePtr.ReadAt<OS2TableV0>(0);
        //value = (os2Table.fsSelection & 0xFF00) >> 8;
        value = os2Table.version;
    }
    wchar_t buffer[200];
    
    StringCchPrintf(buffer, ARRAY_SIZE(buffer), L"%s - %d", familyNames.c_str(), value);
    fontInfo.familyName = buffer;

#else
    fontInfo.familyName = familyNames;
#endif

    fontInfo.styleName = styleName;
    fontInfo.filePath = filePath;
    fontInfo.faceIndex = familyIndex;
    fontInfo.weight = font->GetWeight();
    fontInfo.stretch = font->GetStretch();
    fontInfo.style = font->GetStyle();
    fontInfo.isSelected = shouldSelectFiles;
    fontInfo.id = newestFontInfoId_++;

    return 1;
}


// Add all the fonts in a collection to the font info list.
uint32_t MainWindow::AppendCollectionToFontsList(
    IDWriteFontCollection* fontCollection,
    __in_z const wchar_t* filePath,
    bool shouldSelectFiles,
    bool shouldIncludeSimulations
    )
{
    // A single file can have multiple families in (like Meiryo and Meiryo UI)
    // and multiple fonts within each family, so we loop through them all.

    HRESULT hr;

    uint32_t addedFontCount = 0;

    for (uint32_t familyIndex = 0, familyCount = fontCollection->GetFontFamilyCount(); familyIndex < familyCount; ++familyIndex)
    {
        // Get family.
        ComPtr<IDWriteFontFamily> fontFamily;
        hr = fontCollection->GetFontFamily(familyIndex, &fontFamily);
        if (fontFamily == nullptr)
        {
            AppendLog(L"Could not read font family at family index %d, hr=%X??\r\n", familyIndex, hr);
            continue;
        }

        ComPtr<IDWriteLocalizedStrings> familyNames;
        hr = fontFamily->GetFamilyNames(&familyNames);
        if (familyNames == nullptr)
        {
            AppendLog(L"Could not read font family name at family index %d, hr=%X??\r\n", familyIndex, hr);
            continue;
        }

        std::wstring familyNamesConcatenated = GetConcatenatedFamilyNames(familyNames);

        // Read all the fonts in the current family
        for (uint32_t fontIndex = 0, fontCount = fontFamily->GetFontCount(); fontIndex < fontCount; ++fontIndex)
        {
            ComPtr<IDWriteFont> font;
            hr = fontFamily->GetFont(fontIndex, &font);
            if (font == nullptr)
            {
                AppendLog(L"Could not read font font index %d, hr=%X??\r\n", fontIndex, hr);
                continue;
            }

            if (!shouldIncludeSimulations && font->GetSimulations())
            {
                continue; // Skip all simulated fonts
            }

            addedFontCount += AppendFontToFontsList(
                                font,
                                filePath,
                                shouldSelectFiles,
                                familyNamesConcatenated,
                                familyIndex,
                                fontIndex
                                );
        }
    }

    return addedFontCount;
}


// Rebuild the UI to the internal list.
void MainWindow::RemoveDuplicateInFontsList()
{
    // Ensure they're all sorted before adding, and remove duplicates.
    std::stable_sort(fontsList_.begin(), fontsList_.end());
    fontsList_.erase(std::unique(fontsList_.begin(), fontsList_.end()), fontsList_.end());
}


// Rebuild the UI to the internal list.
void MainWindow::UpdateFontsListUi(uint32_t idToScrollTo)
{
    ListViewWriter lw(GetSubdialogItem(IddFontsList, IdcFontsListFonts));
    lw.DisableDrawing();
    ListView_DeleteAllItems(lw.hwnd);

    wchar_t buffer[1000]; buffer[0] = 0;
    uint32_t indexToScrollTo = -1;
    std::wstring familyNamesConcatenated;

    for (auto p = fontsList_.begin(); p != fontsList_.end(); ++p)
    {
        lw.InsertItem();
        lw.SetItemText(0, p->familyName.c_str());
        lw.SetItemText(1, p->styleName.c_str());
        lw.SetItemText(2, p->filePath.c_str());
        StringCchPrintf(buffer, ARRAY_SIZE(buffer), L"%d", p->faceIndex);
        lw.SetItemText(3, buffer);

        if (p->isSelected)
            lw.SelectItem();

        if (p->id == idToScrollTo)
            indexToScrollTo = lw.iItem;

        lw.AdvanceItem();
    }
    lw.EnableDrawing();

    if (indexToScrollTo != -1)
        ListView_EnsureVisible(lw.hwnd, indexToScrollTo, false);
}


bool MainWindow::EnsureUiConditionTrue(bool condition, const wchar_t* message, uint32_t paneId)
{
    if (!condition)
    {
        // Either display a dialog box and switch to the needed pane,
        // or write to the log instead of a blocking dialog.
        if (insideAutomatedAction_)
        {
            AppendLogCached(L"--------------------\r\n");
            AppendLogCached(message);
            AppendLog(L"\r\n--------------------\r\n");
        }
        else
        {
            MessageBoxShaded::Show(hwnd_, message, APPLICATION_TITLE, MB_OK|MB_ICONWARNING);
            if (paneId > 0 && paneId != -1)
            {
                SelectCurrentPane(paneId);
            }
        }
    }
    return condition;
}


// Returns the number of fonts selected.
uint32_t MainWindow::GetFontsListSelectionCount()
{
    return uint32_t(std::count_if(fontsList_.begin(), fontsList_.end(), [](const FontInfo& fontInfo) -> bool {return fontInfo.isSelected;}));
}


uint32_t MainWindow::GetStringsListSelectionCount()
{
    return uint32_t(std::count_if(stringsList_.begin(), stringsList_.end(), [](const StringInfo& stringInfo) -> bool {return stringInfo.isSelected;}));
}


bool MainWindow::HandleListViewSelectionChange(UINT code, LPARAM lParam, std::function<void(uint32_t start, uint32_t end, bool state)> f)
{
    // Record the listView selection changes into our own corresponding data structure.

    static_assert(offsetof(NMLISTVIEW, uOldState) == offsetof(NMLVODSTATECHANGE, uOldState),
                  "Offsets of NMLISTVIEW::uOldState and NMLVODSTATECHANGE::uOldState mismatch.");

    NMLISTVIEW const& nlv = *(NMLISTVIEW*)lParam;
    NMLVODSTATECHANGE const& nsc = *(NMLVODSTATECHANGE*)lParam;

    if (!((nlv.uOldState ^ nlv.uNewState) & LVIS_SELECTED))
        return false; // Ignore changes except selection.

    // Get the range from the code. (sure would be simpler if there was just one notification type :/)
    Range range;
    switch (code)
    {
    case LVN_ODSTATECHANGED:
        range.start = nsc.iFrom;
        range.end   = nsc.iTo + 1;
        break;

    case LVN_ITEMCHANGED:
        if (nlv.iItem != -1)
        {
            range.start = nlv.iItem;
            range.end   = nlv.iItem + 1;
        }
        // else the range is already 0..UINT32_MAX
        break;

    default:
        return false;
    }

    f(range.start, range.end, !!(nlv.uNewState & LVIS_SELECTED));
    return true;
}


std::wstring MainWindow::GetSelectedStringsText(const wchar_t* separator)
{
    std::wstring text;

    // Concatenate all the strings together.
    for (uint32_t i = 0, ci = static_cast<uint32_t>(stringsList_.size()); i < ci; ++i)
    {
        if (!stringsList_[i].isSelected)
            continue;

        if (!text.empty())
            text += separator;

        text += stringsList_[i].sample;
    }

    return text;
}


void MainWindow::UpdateTextFromSelectedStrings()
{
    KillTimer(hwnd_, IdcStringsListStrings);

    // For whenever the user selects strings in the strings list, we update the
    // Edit with a concatenation of the strings.
    std::wstring text = GetSelectedStringsText(L" ");
    if (!text.empty())
    {
        Edit_SetText(GetSubdialogItem(IddStringsList, IdcStringsListString), text.c_str());
    }
}


// Get all the selected font faces.
std::vector<ComPtr<IDWriteFontFace> > MainWindow::GetSelectedFontFaces()
{
    std::vector<ComPtr<IDWriteFontFace> > fonts;

    for (uint32_t fontIndex = 0, fontCount = static_cast<uint32_t>(fontsList_.size());
         fontIndex < fontCount;
         ++fontIndex
         )
    {
        if (!fontsList_[fontIndex].isSelected)
            continue; // skip unselected font face

        ComPtr<IDWriteFontFace> fontFace;
        if (FAILED(CreateFontFace(
                    fontsList_[fontIndex].filePath.c_str(),
                    fontsList_[fontIndex].faceIndex,
                    &fontFace)))
        {
            continue;
        }

        fonts.push_back(fontFace);
    }

    return fonts;
}


// Reset the strings list to default.
void MainWindow::ResetDefaultStringsList()
{
    stringsList_.resize(ARRAY_SIZE(g_defaultStrings));
    for (uint32_t i = 0; i < ARRAY_SIZE(g_defaultStrings); ++i)
    {
        auto& stringInfo = stringsList_[i];
        stringInfo.description = g_defaultStrings[i][0];
        stringInfo.sample = g_defaultStrings[i][1];
        stringInfo.isSimple = IsStringSimple(stringInfo.sample.c_str(), stringInfo.sample.size());
    }
}


// Rebuild the UI strings list from the internal list.
void MainWindow::UpdateStringsListUi(uint32_t indexToScrollTo)
{
    auto listHwnd = GetSubdialogItem(IddStringsList, IdcStringsListStrings);
    ListView_SetCallbackMask(listHwnd, LVIS_SELECTED);
    ListView_SetItemCountEx(listHwnd, stringsList_.size(), LVSICF_NOSCROLL);

    // The listview caches the owner-drawn selection count incorrectly
    // which leaves previously selected items visible when selecting a new
    // item and yields an incorrect value for ListView_GetSelectedCount.
    // There seems to be no other cue or hint to get it to recompute it
    // other than a dummy SetItemState that just sets the item to its
    // current state. The count is corrected once you click on an item
    // but the ghost pixels last until the listview is redrawn.
    // (it's similar to KB311891)
    //
    // We also avoid the recursion (there seems to be no way to disable this)
    // of the listview calling back to us every time the item state is set,
    // which is unnecessary because the *app* is programmatically setting it,
    // not the user; and this can cascade to other undesired control changes.
    preventListViewRecursion_ = true;
    for (uint32_t i = 0, ci = stringsList_.size(); i < ci; ++i)
    {
        ListView_SetItemState(listHwnd, i, stringsList_[i].isSelected ? LVIS_SELECTED : 0, LVIS_SELECTED);
    }
    preventListViewRecursion_ = false;

    if (ListView_GetNextItem(listHwnd, 0, LVNI_FOCUSED) == -1)
    {
        ListView_SetItemState(listHwnd, 0, LVIS_FOCUSED, LVIS_FOCUSED);
    }

    if (indexToScrollTo != -1)
        ListView_EnsureVisible(listHwnd, indexToScrollTo, false);
}


bool MainWindow::ProfileIsDone()
{
    // Check whether the profiling thread still exists. It's okay to not put
    // this check under profilingThreadLock_ because we're not modifying it,
    // and a little delay is okay.
    HANDLE thread = profilingThread_;

    return thread == nullptr;
}


HRESULT MainWindow::ProfileStop(bool shouldTerminateIfNeeded)
{
    HRESULT hr = S_OK;

    EnterCriticalSection(&profilingThreadLock_);
    HANDLE thread = profilingThread_;
    profilingThread_ = nullptr;
    LeaveCriticalSection(&profilingThreadLock_);
    if (thread == nullptr)
    {
        return hr;
    }

    // Wait up to ten seconds, then kill it.
    if (WaitForSingleObject(thread, 10000) != WAIT_OBJECT_0)
    {
        if (shouldTerminateIfNeeded)
        {
            TerminateThread(thread, 0);
        }
    };
    CloseHandle(thread);

    AppendLog(L"Profiling stopped.\r\n");
    SendMessage(hwnd_, WM_PROFILE_RESULT, IdmPerfProfileString, (LPARAM)L"* Canceled");

    return hr;
}


HRESULT MainWindow::ProfileStart()
{
    if (!EnsureUiConditionTrue(GetFontsListSelectionCount() > 0, L"No fonts are selected.\r\n\r\nLoad fonts, and select the ones you are interested in for profiling.", IddFontsList))
        return S_FALSE;

    if (!EnsureUiConditionTrue(GetStringsListSelectionCount() > 0, L"No strings are selected.\r\n\r\nSelect the ones you are interested in for profiling.", IddStringsList))
        return S_FALSE;

    // If already profiling, then restart.
    ProfileStop();

    ////////////////////
    // Start appending results to list view.

    AppendLog(L"Profiling started.\r\n");

    ListViewWriter lw(GetSubdialogItem(IddPerfScore, IdcPerfScoreResults));
    lw.iItem = ListView_GetItemCount(lw.hwnd);

    // Add a separator between runs
    lw.InsertItem(L"");
    for (uint32_t i = 0; i < PerfScoreColumnIndexTotal; ++i)
    {
        lw.SetItemText(i, L"--------------------");
    }
    lw.FocusItem(lw.iItem);
    lw.AdvanceItem();
    ListView_SetItemState(lw.hwnd, -1, 0, LVIS_SELECTED); // Deselect any previous selected rows.

    ////////////////////
    // Get the OpenType feature tags.
    wchar_t featuresText[256];
    ComboBox_GetText(GetSubdialogItem(IddPerfScore, IdcPerfFeatures), featuresText, ARRAYSIZE(featuresText));
    fontFeatures_ = GetFeatureTagsFromText(featuresText);

    ////////////////////
    // Start profiling thread

    EnterCriticalSection(&profilingThreadLock_);
    profilingThread_ =
        CreateThread(
            nullptr,                        // threadAttributes
            0,                              // stackSize
            &StaticProfilingThreadEntry,    // startAddress
            this,                           // parameter
            0,                              // creationflags,
            nullptr                         // threadId is not needed
            );
    LeaveCriticalSection(&profilingThreadLock_);

    return S_OK;
}


bool MainWindow::SendMessageFromProfilingThread(UINT id, const void* data)
{
    // Calls send message within the critical section to avoid deadlock
    // in case the parent is waiting on the child.

    EnterCriticalSection(&profilingThreadLock_);
    bool isStillActive = (profilingThread_ != nullptr);
    if (data != nullptr && isStillActive)
    {
        SendMessage(hwnd_, WM_PROFILE_RESULT, id, (LPARAM)data);
    }
    LeaveCriticalSection(&profilingThreadLock_);
    return isStillActive;
}


DWORD WINAPI MainWindow::StaticProfilingThreadEntry(void* threadParameter)
{
    MainWindow& self = *reinterpret_cast<MainWindow*>(threadParameter);

    // Synchronize to creating thread.
    EnterCriticalSection(&self.profilingThreadLock_);
    LeaveCriticalSection(&self.profilingThreadLock_);

    DWORD result = self.ProfilingThread();

    EnterCriticalSection(&self.profilingThreadLock_);
    CloseHandle(self.profilingThread_);
    self.profilingThread_ = nullptr;
    LeaveCriticalSection(&self.profilingThreadLock_);

    return result;
}


namespace
{
    bool IsFontPartiallyCovered(
        std::vector<char32_t>& utf32text,
        IDWriteFontFace* fontFace
        )
    {
        const uint32_t utf32textLength = static_cast<uint32_t>(utf32text.size());

        std::vector<uint16_t> characterCounts =
            GetFontCharacterCoverageCounts(
                &fontFace,
                1, // fontFaceCount
                utf32text.data(), // unicodeCharacters
                utf32textLength, // unicodeCharactersCount
                [&](uint32_t i, uint32_t total) {}
                );

        // Check each character's coverage, returning true if any is a missing glyph.
        return std::any_of(characterCounts.begin(), characterCounts.end(), [](uint16_t c) {return c == 0;});
    }
}


DWORD WINAPI MainWindow::ProfilingThread()
{
    PerfTime timeLimit(wcstol(g_iterationCountEdit, nullptr, 10), wcstol(g_maxTimeEdit, nullptr, 10) * 1000);
    ProfileResult result, totalResult;
    std::vector<ProfileResult> results;
    std::wstring text;

    const wchar_t* localeName = L"en-us";
    IDWriteNumberSubstitution* numberSubstitution = nullptr;
    const float fontEmSize = 12.0f; // arbitrary size
    ComPtr<IDWriteTextAnalyzer> textAnalyzer;
    IFR(Application::g_DWriteFactory->CreateTextAnalyzer(OUT &textAnalyzer));
    GlyphShapingRunCache shapingRunCache;

    // Grab the typographic font features for layout and shaping.
    ComPtr<IDWriteTypography> typography;
    if (!EqualsDefaultTypographicFeatures(fontFeatures_))
    {
        IFR(Application::g_DWriteFactory->CreateTypography(OUT &typography));

        DWRITE_FONT_FEATURE f = {DWRITE_FONT_FEATURE_TAG(0), 1};
        for (auto it = fontFeatures_.begin(); it != fontFeatures_.end(); ++it)
        {
            f.nameTag = DWRITE_FONT_FEATURE_TAG(*it);
            typography->AddFontFeature(f);
        }
    }

    ////////////////////
    // Start profiling loop

    LARGE_INTEGER frequency;
    LARGE_INTEGER start;
    LARGE_INTEGER end;
    QueryPerformanceFrequency(&frequency);

    // For each string, test each font.

    std::vector<char32_t> utf32text;

    uint32_t stringIndex = 0, fontIndex = 0;
    const uint32_t stringIndexCount = static_cast<uint32_t>(stringsList_.size());
    const uint32_t fontIndexCount   = static_cast<uint32_t>(fontsList_.size());
    if (stringIndexCount <= 0 || fontIndexCount <= 0)
        return S_OK; // No fonts or strings to profile.

    std::function<bool(bool)> advanceIteration = [&](bool isInnerLoop) mutable
    {
        assert(fontIndex <= fontIndexCount);
        assert(stringIndex <= stringIndexCount);
        assert(fontIndexCount > 0);
        assert(stringIndexCount > 0);
        // also assert that fontsList_ is constant, not modified between calls

        uint32_t perfGrouping = perfGrouping_;
        if (isInnerLoop)
            perfGrouping = ~perfGrouping;

        if (perfGrouping & PerfGroupingString)
        {
            ++stringIndex;
            if (stringIndex < stringIndexCount)
                return true; // Haven't reached end yet, so just advance.

            stringIndex = 0; // Reset index for the sake of repeating another group
        }

        if (perfGrouping_ & PerfGroupingFont) // perfGrouping_ rather than perfGrouping
        {
            auto& previousFontInfo = fontsList_[fontIndex];
            ++fontIndex;

            // Check if within same font (but possibly a different file version of it).
            // If in the inner loop, resume if we're still in the same group.
            // If in the outer loop, resume if we're in a different group.
            if (fontIndex < fontIndexCount && (previousFontInfo.IsSameFont(fontsList_[fontIndex]) ^ !isInnerLoop))
            {
                return true; // Still testing same font, so just advance.
            }

            // Reset or advance the index for the sake of either repeating
            // an inner group or advancing an outer group.
            const int32_t fontIndexIncrement = isInnerLoop ? -1 : +1;
            for ( ; isInnerLoop ? fontIndex > 0 : fontIndex < fontIndexCount; fontIndex += fontIndexIncrement)
            {
                uint32_t comparedFontIndex = isInnerLoop ? fontIndex - 1 : fontIndex;
                if (!previousFontInfo.IsSameFont(fontsList_[comparedFontIndex]))
                    break; // Found a different font group, so keep comparedFontIndex as the first index of the group.
            }

            if (!isInnerLoop && fontIndex < fontIndexCount)
                return true;
        }
        else if (perfGrouping & PerfGroupingFile)
        {
            ++fontIndex;

            if (fontIndex < fontIndexCount)
                return true; // Haven't reached end yet, so just advance.

            fontIndex = 0; // Reset index for the sake of repeating another group
        }

        return false;
    };

    do // Outer loop of groupings
    {
        results.clear();

        do // Inner loop of grouped results
        {
            const auto& fontInfo = fontsList_[fontIndex];
            if (!fontInfo.isSelected)
                continue; // skip unselected

            const auto& stringInfo = stringsList_[stringIndex];
            if (!stringInfo.isSelected)
                continue; // skip unselected

            const auto& testString = stringInfo.sample;
            const uint32_t testStringLength = static_cast<uint32_t>(testString.size());

            ComPtr<IDWriteFontFace> fontFace;
            IFR(CreateFontFace(fontInfo.filePath.c_str(), fontInfo.faceIndex, OUT &fontFace));

            // Skip any fonts that do not coverage the string completely
            // (no missing glyphs, which would incur font fallback).
            if (skipPartialCoverageFonts_)
            {
                const uint32_t utf32textLength = ConvertUtf16To32(testString, OUT utf32text);
                if (IsFontPartiallyCovered(utf32text, fontFace))
                    continue;
            }

            // Set up values, clear timings, and send initial empty result to display.
            result.stringIndex = stringIndex;
            result.fontIndex = fontIndex;
            result.layout.Clear();
            result.shaping.Clear();

            SendMessageFromProfilingThread(IdmPerfProfileResult, &result);

            ////////////////////////////////////////
            // Profile layout

            // create custom font collection with just that font
            // create text layout using that font collection with no font fallback.

            if (perfMeasurementType_ & PerfMeasurementTypeLayout)
            {
                ComPtr<IDWriteTextFormat> textFormat;
                ComPtr<IDWriteFontCollection> fontCollection;
                CreateFontCollection(
                    Application::g_DWriteFactory,
                    fontInfo.filePath.c_str(),
                    (fontInfo.filePath.size() + 1) * sizeof(fontInfo.filePath[0]),
                    OUT &fontCollection
                    );

                IFR(Application::g_DWriteFactory->CreateTextFormat(
                    fontInfo.familyName.c_str(),
                    fontCollection,
                    fontInfo.weight,
                    fontInfo.style,
                    fontInfo.stretch,
                    fontEmSize,
                    localeName,
                    OUT &textFormat
                    ));
                textFormat->SetWordWrapping(DWRITE_WORD_WRAPPING_NO_WRAP);

                ProfileLayout(testString.data(), testStringLength, textFormat, typography); // prime once

                QueryPerformanceCounter(&start);
                for (;;)
                {
                    ProfileLayout(testString.data(), testStringLength, textFormat, typography);

                    QueryPerformanceCounter(&end);
                    ++result.layout.iterations;
                    result.layout.milliseconds = (unsigned) (1000 * (end.QuadPart - start.QuadPart) / frequency.QuadPart);
                    if (result.layout.IsDone(timeLimit) || profilingThread_ == nullptr)
                        break;
                }
                totalResult.layout += result.layout;

                if (!SendMessageFromProfilingThread(IdmPerfProfileResult, &result))
                    return S_FALSE;
            }

            ////////////////////////////////////////
            // Profile shaping

            if (perfMeasurementType_ & PerfMeasurementTypeShaping)
            {
                // Analyze the string.
                std::vector<TextAnalysis::LinkedRun> runs;
                std::vector<DWRITE_LINE_BREAKPOINT> breakpoints;
                TextAnalysis textAnalysis(
                    testString.data(),
                    testStringLength,
                    localeName,
                    numberSubstitution,
                    ReadingDirectionLeftToRightTopToBottom,
                    GlyphOrientationModeDefault,
                    nullptr,    // fontSelection,
                    nullptr,    // fontCollection,
                    fontFace    // fontFace
                    );

                IFR(textAnalysis.GenerateResults(
                    textAnalyzer,
                    IN OUT runs,
                    OUT breakpoints
                    ));

                ProfileShaping(textAnalyzer, textAnalysis, fontEmSize, fontFeatures_, IN OUT shapingRunCache); // prime once

                QueryPerformanceCounter(&start);
                for (;;)
                {
                    ProfileShaping(textAnalyzer, textAnalysis, fontEmSize, fontFeatures_, IN OUT shapingRunCache);

                    QueryPerformanceCounter(&end);
                    ++result.shaping.iterations;
                    result.shaping.milliseconds = (unsigned) (1000 * (end.QuadPart - start.QuadPart) / frequency.QuadPart);
                    if (result.shaping.IsDone(timeLimit) || profilingThread_ == nullptr)
                        break;
                }
                totalResult.shaping += result.shaping;

                if (!SendMessageFromProfilingThread(IdmPerfProfileResult, &result))
                    return S_FALSE;
            }

            ////////////////////////////////////////
            // Record results temporarily.
            results.push_back(result);

        } while (advanceIteration(/*isInnerLoop*/ true));

        // Check for timing differences greater than 5% from the fastest vs slowest
        ProfileAggregateResult aggregateResult = {PerfTime::Min(), PerfTime::Max(),
                                                    PerfTime::Min(), PerfTime::Max()};
        for (uint32_t i = 0, ci = static_cast<uint32_t>(results.size()); i < ci; ++i)
        {
            aggregateResult.layoutSlowest.TakeMax(results[i].layout);
            aggregateResult.layoutFastest.TakeMin(results[i].layout);
            aggregateResult.shapingSlowest.TakeMax(results[i].shaping);
            aggregateResult.shapingFastest.TakeMin(results[i].shaping);
        }

        // Send final result of the current group to display.
        if (!SendMessageFromProfilingThread(IdmPerfProfileAggregateResult, results.empty() ? nullptr : &aggregateResult))
            return S_OK;

    } while (advanceIteration(/*isInnerloop*/ false));

    SendMessageFromProfilingThread(IdmPerfProfileTotalResult, &totalResult);
    SendMessageFromProfilingThread(IdmPerfProfileString, text.c_str());
    SendMessageFromProfilingThread(IdmPerfProfileLog, L"Stopped.\r\n");

    return S_OK;
}


HRESULT MainWindow::ProfileLayout(
    const wchar_t* text,
    uint32_t textLength,
    IDWriteTextFormat* textFormat,
    __in_opt IDWriteTypography* typography
    )
{
    float maxWidth  = 100000; // just pick any large value
    float maxHeight = 100000;

    ComPtr<IDWriteTextLayout> textLayout;
    IFR(CreateTextLayout(
        Application::g_DWriteFactory,
        text,
        textLength,
        textFormat,
        maxWidth,
        maxHeight,
        DWRITE_MEASURING_MODE_NATURAL,
        &textLayout
        ));

    if (typography != nullptr)
    {
        DWRITE_TEXT_RANGE textRange = {0, UINT32_MAX};
        textLayout->SetTypography(typography, textRange);
    }

    // This call triggers the actual layout
    // (creation is lazy).
    DWRITE_TEXT_METRICS metrics;
    IFR(textLayout->GetMetrics(&metrics));

    return S_OK;
}


HRESULT MainWindow::ProfileShaping(
    IDWriteTextAnalyzer* textAnalyzer,
    TextAnalysis& textAnalysis,
    float fontEmSize,
    const std::vector<uint32_t>& fontFeatures,
    __inout GlyphShapingRunCache& shapingRunCache
    )
{
    const uint32_t safeGlyphCountEstimate = textAnalysis.textLength_ * 3 / 2 + 16;

    // Resize all the needed structures.
    GrowVectorTo(shapingRunCache.glyphIds,        safeGlyphCountEstimate);
    GrowVectorTo(shapingRunCache.glyphAdvances,   safeGlyphCountEstimate);
    GrowVectorTo(shapingRunCache.glyphOffsets,    safeGlyphCountEstimate);
    GrowVectorTo(shapingRunCache.glyphProperties, safeGlyphCountEstimate);
    GrowVectorTo(shapingRunCache.textProperties,  textAnalysis.textLength_);
    GrowVectorTo(shapingRunCache.clusterMap,      textAnalysis.textLength_);

    const bool useDefaultTypographicFeatures = EqualsDefaultTypographicFeatures(fontFeatures);

    // If we use anything other than the defaults, cache the font feature structures.
    if (useDefaultTypographicFeatures)
    {
        shapingRunCache.featureLengths.clear();
    }
    else if (shapingRunCache.featureSet.size() != fontFeatures.size()
         ||  !std::equal(fontFeatures.begin(),fontFeatures.end(), shapingRunCache.featureSet.begin(), [](uint32_t a, DWRITE_FONT_FEATURE& b)->bool {return a == b.nameTag;})
         ||  shapingRunCache.featureLengths.empty())
    {
        uint32_t const featureLength = UINT32_MAX; // just cover the whole range
        uint32_t const featureSetCount = static_cast<uint32_t>(fontFeatures.size());

        shapingRunCache.features.clear();
        shapingRunCache.featureLengths.clear();
        shapingRunCache.featureSet.resize(featureSetCount);

        DWRITE_FONT_FEATURE f = {DWRITE_FONT_FEATURE_TAG(0), 1};
        for (uint32_t i = 0; i < featureSetCount; ++i)
        {
            f.nameTag = DWRITE_FONT_FEATURE_TAG(fontFeatures[i]);
            shapingRunCache.featureSet[i] = f;
        }

        DWRITE_TYPOGRAPHIC_FEATURES feature = {};
        feature.featureCount = featureSetCount;
        shapingRunCache.features.push_back(feature);
        shapingRunCache.featureLengths.push_back(featureLength);

        // Setup up pointers to the feature sets (which the shaping call expects)
        // now that everything is stable.

        uint32_t featureSetIndex = 0;
        uint32_t featureCount = static_cast<uint32_t>(shapingRunCache.features.size());
        for (uint32_t i = 0, ci = featureCount; i < ci; ++i)
        {
            shapingRunCache.features[i].features =
                    (shapingRunCache.features[i].featureCount > 0)
                ? &shapingRunCache.featureSet[featureSetIndex]
                : nullptr;
            featureSetIndex += shapingRunCache.features[i].featureCount;
        }

        // What we have is an array of pointers to features, but what shaping
        // wants is an array of pointers to feature pointers.

        shapingRunCache.pointersToFeatures.resize(featureCount);

        for (uint32_t i = 0; i != featureCount; ++i)
        {
            shapingRunCache.pointersToFeatures[i] = &shapingRunCache.features[i];
        }
    }

    TextAnalysis::Run& run = textAnalysis.runs_[0];
    const DWRITE_SCRIPT_ANALYSIS scriptAnalysis = {UINT16(run.script.script), DWRITE_SCRIPT_SHAPES_DEFAULT};
    const uint32_t featureRangeCount = static_cast<uint32_t>(shapingRunCache.featureLengths.size());

    IFR(textAnalyzer->GetGlyphs(
        textAnalysis.text_,
        textAnalysis.textLength_,
        run.fontFace,
        run.isSideways,
        run.isReversed,
        &scriptAnalysis,
        textAnalysis.localeName_,
        nullptr,    // IDWriteNumberSubstitution (none)
        featureRangeCount > 0 ? shapingRunCache.pointersToFeatures.data() : nullptr,
        featureRangeCount > 0 ? shapingRunCache.featureLengths.data()     : nullptr,
        featureRangeCount,
        safeGlyphCountEstimate, // maxGlyphCount
        shapingRunCache.clusterMap.data(),
        shapingRunCache.textProperties.data(),
        shapingRunCache.glyphIds.data(),
        shapingRunCache.glyphProperties.data(),
        &run.glyphCount
        ));

    IFR(textAnalyzer->GetGlyphPlacements(
        textAnalysis.text_,
        shapingRunCache.clusterMap.data(),
        shapingRunCache.textProperties.data(),
        textAnalysis.textLength_,
        shapingRunCache.glyphIds.data(),
        shapingRunCache.glyphProperties.data(),
        run.glyphCount,
        run.fontFace,
        fontEmSize,
        run.isSideways,
        run.isReversed,
        &scriptAnalysis,
        textAnalysis.localeName_,
        nullptr, // fontFeatureListsPointer
        nullptr, // fontFeatureLengthsPointer
        0, // featureRangeCount
        shapingRunCache.glyphAdvances.data(),
        shapingRunCache.glyphOffsets.data()
        ));

    return S_OK;
}


HRESULT MainWindow::IdentifyLookups(
    IdentifyLookupsOption option
    )
{
    const uint32_t selectedFontCount = GetFontsListSelectionCount();
    if (!EnsureUiConditionTrue(selectedFontCount > 0, L"No fonts are selected.\r\n\r\nLoad fonts, and select the ones you are interested in.", IddFontsList))
        return S_FALSE;

    // Get the text for glyph ids to check against.
    //
    // If the caller supplies a specific string, we'll use that to test against.
    // Otherwise, prepare a list of which bits are presumed simple using known
    // fairly 'safe' ranges in the Unicode space. For any glyphs outside those
    // ranges, we play it safe and mark them as complex. Each simple codepoint
    // is marked for further coverage investigation of related lookups.
    // The final array is the intersection of the ones presumed safe with all
    // required GSUB and GPOS entries.

    std::vector<char32_t> utf32text;
    FontTableTree::Item::Flag requiredPrintFlags = FontTableTree::Item::FlagNone;

    switch (option)
    {
    case IdentifyLookupsOptionStrings:
        {
            const auto stringHwnd = GetSubdialogItem(IddStringsList, IdcStringsListString);
            const uint32_t textLength = Edit_GetTextLength(stringHwnd);

            if (!EnsureUiConditionTrue(textLength > 0, L"No string is given.\r\n\r\nType or select at least one string.", IddStringsList))
                return S_FALSE;

            // Convert to UTF32
            std::wstring text;
            text.resize(textLength+1);
            Edit_GetText(stringHwnd, &text[0], textLength+1);

            ConvertUtf16To32(text, OUT utf32text);
            requiredPrintFlags = FontTableTree::Item::FlagCovered;
        }
        break;

    case IdentifyLookupsOptionSimple:
        GetSimpleCharacters(OUT utf32text);
        requiredPrintFlags = FontTableTree::Item::FlagCovered; // Print only the lookups covered by the text.
        break;

    case IdentifyLookupsOptionFeatures:
        requiredPrintFlags = FontTableTree::Item::FlagApplicable; // Print only lookups under current applicable features.
        break;

    case IdentifyLookupsOptionAll:
        requiredPrintFlags = FontTableTree::Item::FlagNone; // Print them all.
        break;
    }

    SelectCurrentPane(IddLookupsList);

    const uint32_t utf32textLength = static_cast<uint32_t>(utf32text.size());

    // Get the OpenType feature tags.
    wchar_t featuresText[256];
    ComboBox_GetText(GetSubdialogItem(IddLookupsList, IdcLookupsFeatures), featuresText, ARRAYSIZE(featuresText));
    auto desiredFeatures = GetFeatureTagsFromText(featuresText);

    // Prepare to fill the listview.
    UpdateWindow(hwnd_);
    HWND listHwnd = GetSubdialogItem(IddLookupsList, IdcLookupsListLookups);
    ListViewWriter lw(listHwnd);
    lw.DisableDrawing();
    ListView_DeleteAllItems(lw.hwnd);

    ////////////////////
    // Printer callback vars.
    std::wstring textBuffer;
    GlyphCoverageRange* coverageRanges = nullptr;

    uint32_t fontCoveredLookupCount = 0;
    uint32_t totalCoveredLookupCount = 0;
    uint32_t heirarchyCount = 0;
    uint32_t examinedFontCount = 0;
    const uint32_t itemDetail = AttributeList::GetItemValue(IdcLookupsShowItemDetails, g_attributeListItems, ARRAYSIZE(g_attributeListItems));

#if 0
    struct LookupCountsPerFeature
    {
        uint32_t a[15];
        // SNGS SingleSub
        // MLTS MultipleSub
        // ALTS AlternateSub
        // LIGS LigatureSub
        // CTXS ContextualSub
        // CHNS ChainingSub
        // RCHS ReverseChainingSub
        // SNGP SinglePos
        // PARP PairPos
        // CRSP CursivePos
        // MTBP MarkToBasePos
        // MTLP MarkToLigaturePos
        // MTMP MarkToMarkPos
        // CTXP ContextualPos
        // CHNP ChainingPos
    };

    std::wstring currentFeatureName;
    std::map<std::wstring, LookupCountsPerFeature> lookupCountsByFeature;
    std::vector<bool> lookupTypePresence;
#endif

    // Define printer callback for the final font table tree.
    FontTableTree::PrintFunction listViewPrinter =
    [&](const FontTableTree::Item& item, uint32_t indent, const wchar_t* text) -> void
    {
        if (itemDetail == 0 && item.type == item.TypeLookup)
            return; // Sparse view doesn't show lookups.

#if 0
        if (item.type == item.TypeTable)
        {
            lookupTypePresence.clear();
        }

        if (item.type == item.TypeFeature)
        {
            currentFeatureName = text;
        }

        if (item.type == item.TypeLookup)
        {
            const static NameToValueMapping nameToIndexMapping[] = {
                {L"SNGS", L"",  0}, // SingleSub
                {L"MLTS", L"",  1}, // MultipleSub
                {L"ALTS", L"",  2}, // AlternateSub
                {L"LIGS", L"",  3}, // LigatureSub
                {L"CTXS", L"",  4}, // ContextualSub
                {L"CHNS", L"",  5}, // ChainingSub
                {L"RCHS", L"",  6}, // ReverseChainingSub

                {L"SNGP", L"",  7}, // SinglePos
                {L"PARP", L"",  8}, // PairPos
                {L"CRSP", L"",  9}, // CursivePos
                {L"MTBP", L"", 10}, // MarkToBasePos
                {L"MTLP", L"", 11}, // MarkToLigaturePos
                {L"MTMP", L"", 12}, // MarkToMarkPos
                {L"CTXP", L"", 13}, // ContextualPos
                {L"CHNP", L"", 14}, // ChainingPos
            };

            auto index = GetValueFromName(nameToIndexMapping, ARRAY_SIZE(nameToIndexMapping), text);
            if (index != ~0)
            {
                auto& count = lookupCountsByFeature[currentFeatureName];
                ++count.a[index];
            }
        }

        #if 0
        if (item.type == item.TypeLookup)
        {
            if (item.tableIndex != -1)
            {
                auto neededSize = item.tableIndex + 1;
                if (neededSize > lookupTypePresence.size())
                {
                    lookupTypePresence.resize(neededSize);
                }
                if (lookupTypePresence[item.tableIndex])
                {
                    return;
                }
                lookupTypePresence[item.tableIndex] = true;
            }
        }
        #endif
#endif

        if (item.type == item.TypeScript
        ||  item.type == item.TypeLanguage
        ||  item.type == item.TypeFeature)
        {
            ++heirarchyCount;
        }

        // Indent the line of text by a number of spaces.
        // (We could use the listview's own indent LVIF_INDENT
        // but we'd need an image too, and we'd need to add spaces
        // when copying the text out anyway.)
        const size_t spacesPerIndent = 4;
        const size_t spacesToIndent = std::min(size_t(48), indent * spacesPerIndent);
        textBuffer.assign(spacesToIndent, ' ');

        // Print a string: "text (typename tableindex) @tableoffset xcount : lookupglyphids"
        //            e.g.  CHNS (lookup 62) @1240 x12 : 23..25 31 612

        textBuffer += text;
        if (itemDetail > 1)
        {
            textBuffer += L" (";
            textBuffer += FontTableTree::GetItemTypeName(item.type);
            if (item.tableIndex != -1)
            {
                Append(textBuffer, L" %d", item.tableIndex);
            }
            textBuffer += L")";
            if (item.tableOffset != -1)
            {
                Append(textBuffer, L" @%d", item.tableOffset);
            }

            if (item.extraCounter > 0)
            {
                Append(textBuffer, L" x%d", item.extraCounter);
            }

            if (item.type == item.TypeLookup && coverageRanges != nullptr)
            {
                textBuffer += L" :";
                for (uint32_t i = 0, ci = std::min(item.extraCounter, 32u); i < ci; ++i)
                {
                    if (item.extraIndex != -1)
                    {
                        const auto& coverageRange = coverageRanges[item.extraIndex + i];
                        if (coverageRange.count <= 0)
                        {
                            Append(textBuffer, L" %d", coverageRange.first);
                        }
                        else
                        {
                            Append(textBuffer, L" %d..%d", coverageRange.first, coverageRange.first + coverageRange.count - 1);
                        }
                    }
                }

            }
        }

        lw.InsertItem(textBuffer.c_str());
        if (item.flags & item.FlagCovered)
        {
            ++fontCoveredLookupCount;
        }
        lw.AdvanceItem();
    };

    ////////////////////
    // Check each font.

    for (uint32_t fontIndex = 0, fontCount = static_cast<uint32_t>(fontsList_.size());
         fontIndex < fontCount;
         ++fontIndex
         )
    {
        ////////////////////
        // Get the next font face.
        FontInfo& fontInfo = fontsList_[fontIndex];
        if (!fontInfo.isSelected)
            continue; // skip unselected

        ComPtr<IDWriteFontFace> fontFace;
        IFR(CreateFontFace(
            fontInfo.filePath.c_str(),
            fontInfo.faceIndex,
            OUT &fontFace
            ));

        ////////////////////
        // Read the tables in the font file.
        FontTableTree tree;
        tree.AllocateItems(1, true);

        // Read both GSUB and GPOS tables.
        FontTablePtr gsubTable(fontFace, DWRITE_MAKE_OPENTYPE_TAG('G','S','U','B'));
        FontTablePtr gposTable(fontFace, DWRITE_MAKE_OPENTYPE_TAG('G','P','O','S'));

        const uint32_t tableCount = (gsubTable.IsNull() ? 0 : 1) + (gposTable.IsNull() ? 0 : 1);
        uint32_t fontRootIndex = 0;
        uint32_t tableRootIndex = tree.AllocateItems(tableCount, true);
        uint32_t gsubRootIndex = 0;
        uint32_t gposRootIndex = 0;

        {
            FontTableTree::Item& item   = tree.GetItem(fontRootIndex);
            item.type                   = item.TypeFont;
            item.childIndex             = tableRootIndex;
            item.tag4CC                 = DWRITE_MAKE_OPENTYPE_TAG('s','f','n','t');
        }

        if (!gsubTable.IsNull())
        {
            gsubRootIndex = tableRootIndex;
            ReadFontTable(
                gsubTable,
                DWRITE_MAKE_OPENTYPE_TAG('G','S','U','B'),
                IN OUT tree,
                gsubRootIndex,
                itemDetail >= 3 ? ReadFontTableOptionsLookupCoverage : ReadFontTableOptionsDefault
                );
            ++tableRootIndex;
        }
        if (!gposTable.IsNull())
        {
            gposRootIndex = tableRootIndex;
            ReadFontTable(
                gposTable,
                DWRITE_MAKE_OPENTYPE_TAG('G','P','O','S'),
                IN OUT tree,
                gposRootIndex,
                itemDetail >= 3 ? ReadFontTableOptionsLookupCoverage : ReadFontTableOptionsDefault
                );
        }

        ////////////////////
        // Mark the typographic features we want to test against.

        MarkMatchingFontFeaturesAsApplicable(
            desiredFeatures.data(),
            static_cast<uint32_t>(desiredFeatures.size()),
            IN OUT tree
            );

        tree.PropagateFlags(
            0, // rootIndex,
            FontTableTree::Item::FlagApplicable,
            FontTableTree::Item::FlagNone,
            FontTableTree::PropagateFlagsDirectionDownUp
            );

        std::vector<uint32_t> simpleGlyphBits;
        std::vector<uint32_t> interestedGlyphBits;
        bool glyphsWereRead = true;

        switch (option)
        {
        case IdentifyLookupsOptionSimple:
        case IdentifyLookupsOptionStrings:
            glyphsWereRead = ReadGlyphCoverage(fontFace, OUT interestedGlyphBits, OUT simpleGlyphBits, utf32text.data(), utf32textLength);
            break;

        case IdentifyLookupsOptionAll:
        case IdentifyLookupsOptionFeatures:
            interestedGlyphBits.resize((fontFace->GetGlyphCount() + 31) / 32, 0xFFFFFFFF);
            simpleGlyphBits = interestedGlyphBits;
            break;
        }

        const size_t glyphBitsSize = simpleGlyphBits.size();

        MarkCoveredFontLookups(
            tree,
            gsubRootIndex,
            gsubTable,
            DWRITE_MAKE_OPENTYPE_TAG('G','S','U','B'),
            0, // minGlyphId,
            0xFFFFu, // maxGlyphId,
            glyphBitsSize,
            interestedGlyphBits.data(),
            IN OUT simpleGlyphBits.data()
            );

        MarkCoveredFontLookups(
            tree,
            gposRootIndex,
            gposTable,
            DWRITE_MAKE_OPENTYPE_TAG('G','P','O','S'),
            0, // minGlyphId,
            0xFFFFu, // maxGlyphId,
            glyphBitsSize,
            interestedGlyphBits.data(),
            IN OUT simpleGlyphBits.data()
            );

        tree.PropagateFlags(
            0, // rootIndex,
            FontTableTree::Item::FlagCovered,
            FontTableTree::Item::FlagNone,
            FontTableTree::PropagateFlagsDirectionUp
            );

        ////////////////////
        // Print output.
        Format(textBuffer, L"%s - %s (%s#%d)", fontInfo.familyName.c_str(), fontInfo.styleName.c_str(), fontInfo.filePath.c_str(), fontInfo.faceIndex);
        lw.InsertItem(textBuffer.c_str()); lw.AdvanceItem();

        fontCoveredLookupCount = 0;
        heirarchyCount = 0;
        coverageRanges = tree.coverageRanges_.data();

        tree.Print(
            0, // rootIndex
            true, // shouldSkipRoot
            1, // initial indent
            requiredPrintFlags,
            FontTableTree::Item::FlagNone,
            listViewPrinter
            );
        totalCoveredLookupCount += fontCoveredLookupCount;

        Format(textBuffer, L"Coverage ranges = %d, Heirarchy count = %d", static_cast<uint32_t>(tree.coverageRanges_.size()), heirarchyCount);
        lw.InsertItem(textBuffer.c_str()); lw.AdvanceItem();

        if (fontCoveredLookupCount == 0 && option != IdentifyLookupsOptionAll)
        {
            lw.InsertItem(glyphsWereRead ? L"    (no matching lookups)" : L"    (font did not support glyphs for those characters)");
            lw.AdvanceItem();
        }

        SetProgress(++examinedFontCount, selectedFontCount);
    }

    lw.FocusItem(0);
    lw.EnableDrawing();

    AppendLog(L"Identified lookups (%d lookups in %d fonts).\r\n", totalCoveredLookupCount, examinedFontCount);
    SetProgress(0,0);

#if 0
    AppendLogCached(
        L"\t"
        L"SNGS\t" // SingleSub
        L"MLTS\t" // MultipleSub
        L"ALTS\t" // AlternateSub
        L"LIGS\t" // LigatureSub
        L"CTXS\t" // ContextualSub
        L"CHNS\t" // ChainingSub
        L"RCHS\t" // ReverseChainingSub

        L"SNGP\t" // SinglePos
        L"PARP\t" // PairPos
        L"CRSP\t" // CursivePos
        L"MTBP\t" // MarkToBasePos
        L"MTLP\t" // MarkToLigaturePos
        L"MTMP\t" // MarkToMarkPos
        L"CTXP\t" // ContextualPos
        L"CHNP\t" // ChainingPos
        L"\r\n"
        );        

    for (auto& f : lookupCountsByFeature)
    {
        AppendLogCached(L"%s", f.first.c_str());
        for (uint32_t i = 0; i < ARRAYSIZE(f.second.a); ++i)
        {
            AppendLogCached(L"\t%d", f.second.a[i]);
        }
        AppendLogCached(L"\r\n");
    }
    AppendLog(L"\r\n");
#endif

    return S_OK;
}


HRESULT MainWindow::SelectFontsSupportingCharacters()
{
    // Get the text for glyph ids to check against.

    std::vector<char32_t> utf32text;

    const auto stringHwnd = GetSubdialogItem(IddStringsList, IdcStringsListString);
    const uint32_t textLength = Edit_GetTextLength(stringHwnd);

    if (!EnsureUiConditionTrue(!fontsList_.empty(), L"No fonts are loaded.\r\n\r\nLoad fonts first.", IddFontsList))
        return S_FALSE;

    if (!EnsureUiConditionTrue(textLength > 0, L"No string is given.\r\n\r\nType or select at least one string.", IddStringsList))
        return S_FALSE;

    // Convert to UTF32
    std::wstring text;
    text.resize(textLength+1);
    Edit_GetText(stringHwnd, &text[0], textLength+1);

    const uint32_t utf32textLength = ConvertUtf16To32(text, OUT utf32text);

    return SelectFontsSupportingCharacters(utf32text.data(), utf32textLength);
}


HRESULT MainWindow::SelectFontsSupportingCharacters(
    __in_ecount(utf32textLength) char32_t const* utf32text,
    __in uint32_t utf32textLength
    )
{
    std::vector<uint16_t> glyphs(utf32textLength);

    ////////////////////
    // Check each font.

    uint32_t coveredFontCount = 0;
    uint32_t firstFontInfoId = -1;

    for (uint32_t fontIndex = 0, fontCount = static_cast<uint32_t>(fontsList_.size());
         fontIndex < fontCount;
         ++fontIndex
         )
    {
        ////////////////////
        // Get the next font face.
        FontInfo& fontInfo = fontsList_[fontIndex];
        fontInfo.isSelected = false;

        ComPtr<IDWriteFontFace> fontFace;
        IFR(CreateFontFace(
            fontInfo.filePath.c_str(),
            fontInfo.faceIndex,
            OUT &fontFace
            ));

        // Get all the glyphs from the string to see which ones are missing.
        // Select the font entry if we didn't find any missing glyphs.
        fontFace->GetGlyphIndices(reinterpret_cast<uint32_t const*>(utf32text), utf32textLength, glyphs.data());
        auto result = std::find_if(glyphs.begin(), glyphs.end(), [](uint16_t glyphId)->bool {return glyphId == 0;});
        if (result == glyphs.end())
        {
            ++coveredFontCount;
            fontInfo.isSelected = true;
            if (firstFontInfoId == -1)
                firstFontInfoId = fontInfo.id;
        }

        SetProgress(fontIndex, fontCount);
    }

    AppendLog(L"Identified %d fonts covering all characters in string.\r\n", coveredFontCount);
    SetProgress(0,0);

    UpdateFontsListUi(firstFontInfoId);

    return S_OK;
}


HRESULT MainWindow::SelectDuplicateFonts(
    bool selection, // select or deselect
    bool selectAllDuplicatesOfAGroup
    )
{
    // Deselect fonts that are exact duplicates of each other in file content.

    if (!EnsureUiConditionTrue(!fontsList_.empty(), L"No fonts are loaded.\r\n\r\nLoad fonts first.", IddFontsList))
        return S_FALSE;

    // Compare each adjacent pair of fonts. We can just compare pairs instead
    // of every font to every other font because the list is already ordered.

    HRESULT hr = S_OK;

    uint32_t fontIndexPrevious = ~0u;
    const wchar_t* fileNamePrevious = nullptr;
    WIN32_FIND_DATA findDataPrevious, findDataCurrent;
    std::vector<uint8_t> fontDataPrevious, fontDataCurrent;
    ZeroStructure(findDataPrevious);

    for (uint32_t fontIndex = 0, fontCount = static_cast<uint32_t>(fontsList_.size());
         fontIndex < fontCount;
         ++fontIndex
         )
    {
        FontInfo& fontInfo = fontsList_[fontIndex];
        if (!selection && !fontInfo.isSelected)
            continue; // deselecting, so skip if not already selected.

        auto fileName = fontInfo.filePath.c_str();

        // Get the file size from the directory.
        HANDLE findHandle_ = FindFirstFile(fileName, OUT &findDataCurrent);
        if (findHandle_ != INVALID_HANDLE_VALUE)
        {
            FindClose(findHandle_);

            // Compare binary contents if the file sizes are the same.
            if (findDataCurrent.nFileSizeLow  == findDataPrevious.nFileSizeLow
            &&  findDataCurrent.nFileSizeHigh == findDataPrevious.nFileSizeHigh)
            {
                if (fontDataPrevious.empty())
                {
                    // The previous file may not have been read yet.
                    hr = ReadBinaryFile(fileNamePrevious, OUT fontDataPrevious);
                    if (FAILED(hr))
                    {
                        AppendLog(L"Failed to read file \"%s\" (%08X)\r\n", fileNamePrevious, hr);
                    }
                }
                hr = ReadBinaryFile(fileName, OUT fontDataCurrent);
                if (FAILED(hr))
                {
                    AppendLog(L"Failed to read file \"%s\" (%08X)\r\n", fileName, hr);
                }

                // If the file contents match, then deselect the identical font.
                // If the caller wants all duplicate fonts deselected, then
                // deselect the earlier one too. This means that entire groups
                // of the same font will be skipped.
                if (fontDataCurrent == fontDataPrevious)
                {
                    fontInfo.isSelected = selection;
                    if (selectAllDuplicatesOfAGroup && fontIndexPrevious != ~0u)
                    {
                        fontsList_[fontIndexPrevious].isSelected = selection;
                    }
                }
            }
        }

        fontDataPrevious.clear();
        fontDataPrevious.swap(fontDataCurrent);
        findDataPrevious = findDataCurrent;
        fileNamePrevious = fileName;
        fontIndexPrevious = fontIndex;

        SetProgress(fontIndex, fontCount);
    }

    AppendLog(L"Deselected all duplicate fonts.\r\n");
    SetProgress(0,0);

    UpdateFontsListUi();

    return S_OK; // File reading errors earlier are continued and just logged instead.
}


void MainWindow::Format(__out std::wstring& returnString, const wchar_t* formatString, ...) 
{
    va_list vargs = nullptr;
    va_start(vargs, formatString); // initialize variable arguments
    Format(returnString, false, formatString, vargs);
    va_end(vargs); // Reset variable arguments
}


void MainWindow::Append(__inout std::wstring& returnString, const wchar_t* formatString, ...) 
{
    // Appends to a std::string rather than raw character buffer or ios stream.
    va_list vargs = nullptr;
    va_start(vargs, formatString); // initialize variable arguments
    Format(returnString, true, formatString, vargs);
    va_end(vargs); // Reset variable arguments
}


// Should call the other two overloads.
void MainWindow::Format(__inout std::wstring& returnString, bool shouldConcatenate, const wchar_t* formatString, va_list vargs) 
{
    // Appends to a std::string rather than raw character buffer or ios stream.

    if (formatString != nullptr)
    {
        const size_t increasedLen = _vscwprintf(formatString, vargs) + 1; // Get string length, plus one for NUL
        const size_t oldLen = shouldConcatenate ? returnString.size() : 0;
        const size_t newLen = oldLen + increasedLen;
        returnString.resize(newLen);
        _vsnwprintf_s(&returnString[oldLen], increasedLen, increasedLen, formatString, vargs);
        returnString.resize(newLen - 1); // trim off the NUL
    }
}


void MainWindow::AppendLogCached(const wchar_t* logMessage, ...)
{
    va_list argList;
    va_start(argList, logMessage);

    wchar_t buffer[1000];
    buffer[0] = 0;
    StringCchVPrintf(
        buffer,
        ARRAYSIZE(buffer),
        logMessage,
        argList
        );

    cachedLog_ += buffer;
}


void MainWindow::AppendLog(const wchar_t* logMessage, ...)
{
    HWND hwndLog = GetDlgItem(hwnd_, IdcLog);

    va_list argList;
    va_start(argList, logMessage);

    wchar_t buffer[1000];
    buffer[0] = 0;
    StringCchVPrintf(
        buffer,
        ARRAYSIZE(buffer),
        logMessage,
        argList
        );

    uint32_t textLength = Edit_GetTextLength(hwndLog);
    if (!cachedLog_.empty())
    {
        Edit_SetSel(hwndLog, textLength, textLength);
        Edit_ReplaceSel(hwndLog, cachedLog_.c_str());
        cachedLog_.clear();
        textLength = Edit_GetTextLength(hwndLog);
    }
    Edit_SetSel(hwndLog, textLength, textLength);
    Edit_ReplaceSel(hwndLog, buffer);
}


void MainWindow::ClearLog()
{
    HWND hwndLog = GetDlgItem(hwnd_, IdcLog);
    Edit_SetText(hwndLog, L"");

    std::wstring().swap(cachedLog_);
}


void MainWindow::SetProgress(uint32_t value, uint32_t total)
{
    HWND prograssBar = GetDlgItem(hwnd_, IdcProgress);
    SendMessage(prograssBar, PBM_SETRANGE32, 0, total);
    SendMessage(prograssBar, PBM_SETPOS, value, 0);
}
