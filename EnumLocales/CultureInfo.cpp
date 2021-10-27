// cl /clr CultureInfo.cpp
using namespace System;
using namespace System::Collections;
using namespace System::Collections::Generic;
using namespace System::Globalization;

// http://msdn.microsoft.com/en-us/library/system.globalization.cultureinfo.aspx


int main(array<String^>^ args)
{
    List<CultureInfo^>^ allCultures = gcnew List<CultureInfo^>();
    CultureInfo^ culture;

    for (Int32 lcid = 0x846; lcid <= 0x846; ++lcid)
    {
        try
        {
            culture = gcnew CultureInfo(lcid, false);
        }
        catch (ArgumentException^ aex)
        {
            // lcid is not a valid culture identifier
            Console::WriteLine(L"LCID 0x{0:X4} is not a valid culture identifier!", lcid);
            continue;
        }

        allCultures->Add(culture);

        Console::WriteLine(L"0x{0:X4} {1,-40}0x{2:X4}", lcid, culture->DisplayName, culture->LCID);
    }

    return 0;
}
