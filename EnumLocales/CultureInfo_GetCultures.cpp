// cl /clr CultureInfo_GetCultures.cpp
using namespace System;
using namespace System::Collections::Generic;
using namespace System::Globalization;


String^ CultureTypeString(CultureTypes type)
{
    switch (type)
    {
    case CultureTypes::FrameworkCultures:
        return L"Fra";
    case CultureTypes::InstalledWin32Cultures:
        return L"Ins";
    case CultureTypes::NeutralCultures:
        return L"Neu";
    case CultureTypes::ReplacementCultures:
        return L"Rep";
    case CultureTypes::SpecificCultures:
        return L"Spe";
    case CultureTypes::UserCustomCulture:
        return L"Usr";
    case CultureTypes::WindowsOnlyCultures:
        return L"Win";
    }
    return L"Unknown";
}

public ref struct CultureData : IComparable<CultureData^>
{
    CultureTypes cultureType;
    CultureInfo^ cultureInfo;

    CultureData(CultureTypes type, CultureInfo^ info) : cultureType(type), cultureInfo(info)
    {
    }

    virtual Int32 CompareTo(CultureData^ other)
    {
        int result = cultureInfo->Name->CompareTo(other->cultureInfo->Name);
        if (result == 0)    // if same name, sort descending by culture type
        {
            return -CultureTypeString(cultureType)->CompareTo(CultureTypeString(other->cultureType));
        }
        return result;
    }
};

int main()
{
    List<CultureData^>^ allCultures = gcnew List<CultureData^>();
    array<CultureInfo^>^ cultures;

    cultures = CultureInfo::GetCultures(CultureTypes::FrameworkCultures);
    for each (CultureInfo^ culture in cultures)
    {
        allCultures->Add(gcnew CultureData(CultureTypes::FrameworkCultures, culture));
    }
    cultures = CultureInfo::GetCultures(CultureTypes::InstalledWin32Cultures);
    for each (CultureInfo^ culture in cultures)
    {
        allCultures->Add(gcnew CultureData(CultureTypes::InstalledWin32Cultures, culture));
    }
    cultures = CultureInfo::GetCultures(CultureTypes::NeutralCultures);
    for each (CultureInfo^ culture in cultures)
    {
        allCultures->Add(gcnew CultureData(CultureTypes::NeutralCultures, culture));
    }
    cultures = CultureInfo::GetCultures(CultureTypes::ReplacementCultures);
    for each (CultureInfo^ culture in cultures)
    {
        allCultures->Add(gcnew CultureData(CultureTypes::ReplacementCultures, culture));
    }
    cultures = CultureInfo::GetCultures(CultureTypes::SpecificCultures);
    for each (CultureInfo^ culture in cultures)
    {
        allCultures->Add(gcnew CultureData(CultureTypes::SpecificCultures, culture));
    }
    cultures = CultureInfo::GetCultures(CultureTypes::UserCustomCulture);
    for each (CultureInfo^ culture in cultures)
    {
        allCultures->Add(gcnew CultureData(CultureTypes::UserCustomCulture, culture));
    }
    cultures = CultureInfo::GetCultures(CultureTypes::WindowsOnlyCultures);
    for each (CultureInfo^ culture in cultures)
    {
        allCultures->Add(gcnew CultureData(CultureTypes::WindowsOnlyCultures, culture));
    }

    allCultures->Sort();

    /****
    // Discard duplicates, keeping the max culture type
    for (int idx = 0; idx < allCultures->Count - 1; ++idx)
    {
        for (int next = idx + 1; next < allCultures->Count; ++next)
        {
            if (allCultures[idx]->cultureInfo->Name->Equals(allCultures[next]->cultureInfo->Name))
            {
                allCultures[next]->cultureType = allCultures[idx]->cultureType;
            }
        }
    }
    ****/

    for each (CultureData^ cultureData in allCultures)
    {
        CultureInfo^ info = cultureData->cultureInfo;
        Console::WriteLine(L"{0}\t{1,-13}\t{2,-50}\t{3:X4}",
            CultureTypeString(cultureData->cultureType), info->Name, info->DisplayName, info->LCID);
    }

   return 0;
}
