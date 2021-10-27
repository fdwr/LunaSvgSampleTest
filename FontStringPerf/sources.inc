_NT_TARGET_VERSION=$(_NT_TARGET_VERSION_WIN7)

PRECOMPILED_INCLUDE=precomp.h
PRECOMPILED_CXX=1

INCLUDES=\
    $(SDK_INC_PATH); \
    $(WINDOWS_INC_PATH); \

# Use STL latest version.
USE_STL=1
STL_VER=100

# Treat wchar_t as a built-in type.
NO_WCHAR_T=1

# We are Unicode enabled.
# Enable C++ inline versions of common macros.
C_DEFINES = \
    /D_UNICODE \
    /D_USE_MATH_DEFINES \
    /D_WCTYPE_INLINE_DEFINED \
    /DINLINE_HRESULT_FROM_WIN32 \
    /DNOMINMAX \
    /DSTRICT \
    /DUNICODE \
    /DWIN32_LEAN_AND_MEAN \
    /DPRIVATE_BUILD \

# Use MSVCRT.DLL for better serviceability.
USE_MSVCRT=1

# Use synchronous C++ exception handling model (/EHsc).
USE_NATIVE_EH=1

# DevTest contains test code that is not a part of the product.
TEST_CODE=1

# Disable MUI for non-shipping code.
MUI=0
MUI_COMMENT="Disable MUI for internal tool"
