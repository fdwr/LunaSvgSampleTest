#pragma once

#include "../common/common.h"
#include "../ui/precomp.h"

#include "Common.h"
#include "ExtendedInterfaces.h"
#include "Clipboard.h"

#include "Error.h"

_COM_SMARTPTR_TYPEDEF(IDWriteFactory, __uuidof(IDWriteFactory));
_COM_SMARTPTR_TYPEDEF(IDWriteTextLayout, __uuidof(IDWriteTextLayout));
_COM_SMARTPTR_TYPEDEF(IDWriteTextEditLayout, __uuidof(IDWriteTextEditLayout));
_COM_SMARTPTR_TYPEDEF(IDWriteInlineObject, __uuidof(IDWriteInlineObject));
_COM_SMARTPTR_TYPEDEF(IDWriteTextFormat, __uuidof(IDWriteTextFormat));
_COM_SMARTPTR_TYPEDEF(IDWriteFontCollection, __uuidof(IDWriteFontCollection));
_COM_SMARTPTR_TYPEDEF(IUnknown, __uuidof(IUnknown));
_COM_SMARTPTR_TYPEDEF(IDWriteInlineObject, __uuidof(IDWriteInlineObject));
_COM_SMARTPTR_TYPEDEF(IDWriteTypography, __uuidof(IDWriteTypography));

#include "EditableLayout.h"

#include "TextEditor.h"
