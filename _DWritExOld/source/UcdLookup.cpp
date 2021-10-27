//---------------------------------------------------------------------------
//
//  No copyright. No rights reserved. No royalties nor permission needed.
//
//  This library is not produced by, endorsed by, or supported by Microsoft.
//  It is merely a supplementary library, dependent on the real DirectWrite,
//  written to augment and fill in functionality holes.
//
//  Feel free to use it for any projects, commercial or not, as a whole or in
//  parts. No warranty or guarantees of correctness! You have the code. Come
//  to your own conclusion regarding the robustness.
//
//----------------------------------------------------------------------------

enum {
  TotalProperties = 8,
  offset2 = TotalProperties * sizeof(uint32_t),
  bits0   = 4,
  bits1   = 8,
  bits2   = 9,
  size0   = 1 << bits0,
  size1   = 1 << bits1,
  size2   = 1 << bits2,
  mask0   = size0 - 1,
  mask1   = size1 - 1,
  mask2   = size2 - 1,
  shift0  = 0,
  shift1  = bits0,
  shift2  = bits0 + bits1,
};

struct UcdHeader
{
  struct PropertyOffset
  {
    uint32 offset; // relative to UCD data
  } propertyOffsets[UcdTotalProperties];
  struct Directory
  {
    uint16 offset[2 << bits2]; // relative to UCD data
  } directory[UcdTotalProperties];
  struct Tables
  {
    uint16 offset[2 << bits1]; // relative to UCD data
  } tables[1]; // variable count

  // property values, variable size data.
}

union Ptr {
  const uint8_t * ui8;
  const uint16_t* ui16;
  const uint32_t* ui32;
  const int8_t  * si8;
  const int16_t * si16;
  const int32_t * si32;
};
union UcdPropertyTable {
  Ptr ptr;
  uint32_t index;
}

UcdPropertyTable GetUcdPropertyTable(uint32_t propertyId, char32_t ch)
{
    unsigned int index2 = (ch >> shift2) & mask2;
    unsigned int index1 = (ch >> shift1) & mask1;
    unsigned int index0 = (ch >> shift0) & mask0;

#if 0
    UcdPropertyTable table;
    Ptr ptr;

    ptr.ui8       = g_ucd.ui8 + offset2 + propertyId * size2 * sizeof(uint16_t);
    ptr.ui8       = g_ucd.ui8 + ptr.ui16[index2]; // + offset 0 to 64k
    table.ptr.ui8 = g_ucd.ui8 + g_ucd.uint32[propertyId];
    table.index   = ptr.ui16[index1] * size0 + index0;
#elif 1
    UcdPropertyTable table;
    const UcdHeader& header = reinterpret_cast<UcdHeader*>(g_ucd);

    table.ptr.ui8 = g_ucd.ui8 + header.propertyOffsets[propertyId];
    tableIndex    = header.directory[propertyId][index2];
    table.index   = header.tables[tableIndex][index1] * size0 + index0;
#endif

    return table;
}

/*
push esi,edi
mov eax,[property]
mov esi,[g_ucd]
mov ecx,[ch]
mov edi,[esi+eax*4]
mov [esp+4+8],edi
mov edi,eax
mov edx,ecx
shl edi,shift2+1
shr edx,shift2
and edx,mask2
add edi,esi
movzx edi,[edi+edx*2]
mov edx,ecx
add edi,esi
shr edx,shift1
and edx,mask1
movzx edi,[edi+edx*2]
shl edx,bits0
and eax,mask0
add eax,edx
mov [esp+8+8],eax
pop esi,edi
ret
*/

/*
from Hien Le:

template<size_t LVL1, size_t LVL2, size_t LVL3, bool DEFAULT>
class Table {
	Table<LVL2, LVL3> *table[1<<LVL1];
	
	bool operator[](size_t idx) {
		size_t lvl1idx = idx >> (LVL2+LVL3);
		if (table[lvl1idx] == NULL)
			return DEFAULT;
		else 
			return table[lvl1idx][lvl2idx];
	}
};

template<size_t LVL2, size_t LVL3> 
class Table {
	Table<LVL3> table[1<<LVL2];
};

template<size_t LVL3>
class Root {
	bool table[1<<LVL3]; 
};
*/


BidiClass GetBidiClass(char32_t ch)
{
    UcdPropertyTable table = GetUcdPropertyTable(PropertyBidiClass, ch);
    return table.ptr.ui8[table.index];
}


char32_t GetMirrorCharacter(char32_t ch)
{
    UcdPropertyTable table = GetUcdPropertyTable(PropertyMirrorCharacter, ch);
    char32_t mirrorCh = table.ptr.ui32[table.index];
    return mirrorCh ? mirrorCh : ch;
}


char32_t IsWhitespaceCharacter(char32_t ch)
{
    UcdPropertyTable table = GetUcdPropertyTable(PropertyIsWhitespace, ch);
    return BitTest(table.ptr.ui8, table.index);
}


char32_t GetMinisculeCharacter(char32_t ch)
{
    UcdPropertyTable table = GetUcdPropertyTable(PropertyMajusculeCharacter, ch);
    return ch + table.ptr.si16[table.index];
}


char32_t GetMajusculeCharacter(char32_t ch)
{
    UcdPropertyTable table = GetUcdPropertyTable(PropertyMajusculeCharacter, ch);
    return ch - table.ptr.si16[table.index];
}
