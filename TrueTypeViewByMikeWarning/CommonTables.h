struct ScriptRecord
{
    Tag                 Tag;
    BigEndian<Offset>   ScriptTable;
};


struct ScriptList
{
    BigEndian<USHORT>   ScriptCount;
    ScriptRecord        ScriptRecords[];
};
C_ASSERT(sizeof(ScriptList) == 2);


struct LangSysRecord
{
    Tag                 Tag;
    BigEndian<Offset>   LangSys;
};


struct ScriptTable
{
    BigEndian<Offset>   DefaultLangSys;
    BigEndian<USHORT>   LangSysCount;
    LangSysRecord       LangSysRecords[];
};
C_ASSERT(sizeof(ScriptTable) == 4);


struct LangSysTable
{
    BigEndian<USHORT>   LookupOrder;
    BigEndian<USHORT>   ReqFeatureIndex;
    BigEndian<USHORT>   FeatureCount;
    BigEndian<USHORT>   FeatureIndex[];
};
C_ASSERT(sizeof(LangSysTable) == 6);



struct FeatureRecord
{
    Tag                 Tag;
    BigEndian<Offset>   Feature;
};


struct FeatureList
{
    BigEndian<USHORT>   FeatureCount;
    FeatureRecord       FeatureRecords[];
};
C_ASSERT(sizeof(FeatureList) == 2);


struct Feature
{
    BigEndian<Offset>   FeatureParams;
    BigEndian<USHORT>   LookupCount;
    BigEndian<USHORT>   LookupListIndex[];
};
C_ASSERT(sizeof(Feature) == 4);


struct LookupList
{
    BigEndian<USHORT>   LookupCount;
    BigEndian<Offset>   Lookups[];
};
C_ASSERT(sizeof(LookupList) == 2);


struct Lookup
{
    BigEndian<USHORT>   LookupType;
    BigEndian<USHORT>   LookupFlag;
    BigEndian<USHORT>   SubTableCount;
    BigEndian<Offset>   SubTables[];
};
C_ASSERT(sizeof(Lookup) == 6);


struct CoverageFormat
{
    BigEndian<USHORT>   Format;
};
C_ASSERT(sizeof(CoverageFormat) == 2);


struct CoverageFormat1 : public CoverageFormat
{
    BigEndian<USHORT>   GlyphCount;
    BigEndian<USHORT>   GlyphID[];
};
C_ASSERT(sizeof(CoverageFormat1) == 4);


struct RangeRecord
{
    BigEndian<USHORT>   Start;
    BigEndian<USHORT>   End;
    BigEndian<USHORT>   StartCoverageIndex;
};
C_ASSERT(sizeof(RangeRecord) == 6);


struct CoverageFormat2 : public CoverageFormat
{
    BigEndian<USHORT>   RangeCount;
    RangeRecord         Ranges[];
};
C_ASSERT(sizeof(CoverageFormat2) == 4);
