//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2006. All rights reserved.
//
//  File:       precomp.h
//
//  Contents:   Precompiled header for Text\Glyph\Rendering.
//
//  Author:     Niklas Borson (niklasb@microsoft.com)
//
//  History:    09-18-2006   niklasb    Created
//
//----------------------------------------------------------------------------

#pragma once

// Rendering depends on a large fraction of the font library
#include "../../Font/precomp.h"

// Include font cache core logic
#include "../../FontCache/Logic/MemoryLayout.h"
#include "../../FontCache/Logic/Shared.h"
#include "../../FontCache/Logic/IFontCacheElement.h"
#include "../../FontCache/Logic/IBaseCacheContext.h"
#include "../../FontCache/Logic/FontCacheContext.h"
#include "../../FontCache/Logic/CacheReader.h"
#include "../../FontCache/Logic/CacheWriter.h"
#include "../../FontCache/Logic/CacheElementTypeFactory.h"

// Include all the cache elements we need
#include "../FontRasterizers/IFontRasterizer.h"
#include "../../FontCache/Elements/CachedBitmap.h"
#include "../../FontCache/Elements/GlyphDataBlock.h"
#include "../../FontCache/Elements/GlyphDataBlock.inl"
#include "../../FontCache/Elements/FontFaceElement.h"
#include "../../FontCache/Elements/MetricsConverter.h"

// Include readering header files
#include "GlyphTransform.h"
#include "GammaTable.h"
#include "EnhancedContrastTable.h"
#include "ClearTypeFilter.h"
#include "GlyphRenderingParams.h"
#include "GlyphPositions.h"
#include "GlyphRunAnalysis.h"
#include "ClearType.h"
#include "RenderOutlines.h"
