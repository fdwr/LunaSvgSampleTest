!IF EXIST ($(SDXROOT)\testsrc\windowstest\project.mk)
!INCLUDE $(SDXROOT)\testsrc\windowstest\project.mk
!ELSE
!MESSAGE No Project.mk found
!ENDIF


APP_PATH=$(SDXROOT)\testsrc\windowstest\dgt\text\Samples\DPad
APP_OBJ_PATH=$(OBJECT_ROOT)\testsrc\windowstest\dgt\text\Samples\DPad

# Enable warnings as errors.
BUILD_ALLOW_ALL_WARNINGS=1

# Warning level 4 catches more coding mistakes.
MSC_WARNING_LEVEL=-W4

# Do not enable 64 bit portability warnings. They are more noisy than useful for projects that perform real 64 bit builds.
# MSC_WARNING_LEVEL=$(MSC_WARNING_LEVEL) -Wp64

# Unreferenced formal parameters. Perfectly legal C++.
MSC_WARNING_LEVEL=$(MSC_WARNING_LEVEL) -wd4100

# Enable override keyword that is used to implement OVERRIDE macro.
MSC_WARNING_LEVEL=$(MSC_WARNING_LEVEL) -wd4481

# Copy constructor could not be generated. Good.
MSC_WARNING_LEVEL=$(MSC_WARNING_LEVEL) -wd4511

# Assignment operator could not be generated. Good.
MSC_WARNING_LEVEL=$(MSC_WARNING_LEVEL) -wd4512

# Unreferenced inline function has been removed. Happens all the time.
MSC_WARNING_LEVEL=$(MSC_WARNING_LEVEL) -wd4514

# The class you defined inherits from two classes, one of which inherits from the other.
# This is legal C++, and is useful in some cases.
MSC_WARNING_LEVEL=$(MSC_WARNING_LEVEL) -wd4584

# Disable warning when the decorated name is longer than the compiler limit (4K in VC8).
# The name is automatically truncated. This could be the result of template specialization
# in the expression template of some long and complex template type. Disabling this
# warning will not affect the correctness of the program, but since the name is
# truncated it'll make debugging harder. To avoid this warning in the first place,
# try to factor the type into a less complex ones.
MSC_WARNING_LEVEL=$(MSC_WARNING_LEVEL) -wd4503


# Use synchronous C++ exception handling model (/EHsc).
USE_NATIVE_EH=1

# Do we need this now?
!if $(FREEBUILD)
LINK_TIME_CODE_GENERATION=1
!else
C_DEFINES = $(C_DEFINES) /D_SECURE_SCL=1 /D_DEBUG
!endif

# DWrite runs on Windows Vista and later
_NT_TARGET_VERSION=$(_NT_TARGET_VERSION_LONGHORN)

# Use MSVCRT.DLL for better serviceability.
USE_MSVCRT=1

# Use STL.
USE_STL=1

# Disable MUI for sample application.
MUI=0

# Treat wchar_t as a built-in type.
NO_WCHAR_T=1

# We are Unicode enabled.
# Enable secure versions of CRT and Win32 functions.
# Enable C++ inline versions of common macros.
C_DEFINES = $(C_DEFINES) \
    /D_UNICODE \
    /D_USE_MATH_DEFINES \
    /D_WCTYPE_INLINE_DEFINED \
    /DINLINE_HRESULT_FROM_WIN32 \
    /DNOMINMAX \
    /DRPC_USE_NATIVE_WCHAR \
    /DSECURITY_WIN32 \
    /DSTRICT \
    /DUNICODE \
    /DWIN32_LEAN_AND_MEAN \
