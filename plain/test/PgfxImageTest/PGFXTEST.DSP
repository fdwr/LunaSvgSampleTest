# Microsoft Developer Studio Project File - Name="pgfxtest" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Application" 0x0101

CFG=pgfxtest - Win32 Release
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "pgfxtest.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "pgfxtest.mak" CFG="pgfxtest - Win32 Release"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "pgfxtest - Win32 Release" (based on "Win32 (x86) Application")
!MESSAGE 

# Begin Project
# PROP AllowPerConfigDependencies 0
# PROP Scc_ProjName ""
# PROP Scc_LocalPath ""
CPP=cl.exe
MTL=midl.exe
RSC=rc.exe
# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "c:\windows\temp\pgfxtest"
# PROP BASE Intermediate_Dir "c:\windows\temp\pgfxtest"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "."
# PROP Intermediate_Dir "c:\temp\pgfxtest"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /D "_MBCS" /YX /FD /c
# ADD CPP /nologo /W3 /GX /O1 /I "\src\plain\test_pgfx" /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /D "_MBCS" /YX /FD /c
# ADD BASE MTL /nologo /D "NDEBUG" /mktyplib203 /win32
# ADD MTL /nologo /D "NDEBUG" /mktyplib203 /win32
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:windows /machine:I386
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib comctl32.lib /nologo /stack:0x200000 /entry:"main" /subsystem:windows /machine:I386 /nodefaultlib
# SUBTRACT LINK32 /pdb:none
# Begin Target

# Name "pgfxtest - Win32 Release"
# Begin Group "Source Files"

# PROP Default_Filter "cpp;c;cxx;rc;def;r;odl;idl;hpj;bat"
# Begin Source File

SOURCE=..\..\win\AtrbList\AtrbList.c
# End Source File
# Begin Source File

SOURCE=..\pgfx\pgfxhl.asm
# Begin Custom Build
IntDir=c:\temp\pgfxtest
InputPath=..\pgfx\pgfxhl.asm
InputName=pgfxhl

"$(IntDir)\$(InputName).obj" : $(SOURCE) "$(INTDIR)" "$(OUTDIR)"
	\src\nasmw.exe $(InputPath) -o $(IntDir)\$(InputName).obj -fwin32 -w+orphan-labels -i\src\win\ -i..\pgfx\ -i..\ui\ -i\src\common\ -d_MSLINK

# End Custom Build
# End Source File
# Begin Source File

SOURCE=..\pgfx\pgfxlayr.asm
# Begin Custom Build
IntDir=c:\temp\pgfxtest
InputPath=..\pgfx\pgfxlayr.asm
InputName=pgfxlayr

"$(IntDir)\$(InputName).obj" : $(SOURCE) "$(INTDIR)" "$(OUTDIR)"
	\src\nasmw.exe $(InputPath) -o $(IntDir)\$(InputName).obj -fwin32 -w+orphan-labels -i\src\win\ -i..\pgfx\ -i..\ui\ -i\src\common\ -d_MSLINK

# End Custom Build
# End Source File
# Begin Source File

SOURCE=..\pgfx\pgfxll.asm
# Begin Custom Build
IntDir=c:\temp\pgfxtest
InputPath=..\pgfx\pgfxll.asm
InputName=pgfxll

"$(IntDir)\$(InputName).obj" : $(SOURCE) "$(INTDIR)" "$(OUTDIR)"
	\src\nasmw.exe $(InputPath) -o $(IntDir)\$(InputName).obj -fwin32 -w+orphan-labels -i\src\win\ -i..\pgfx\ -i\src\common\ -d_MSLINK

# End Custom Build
# End Source File
# Begin Source File

SOURCE=.\Pgfxtest.asm
# Begin Custom Build
IntDir=c:\temp\pgfxtest
InputPath=.\Pgfxtest.asm
InputName=Pgfxtest

"$(IntDir)\$(InputName).obj" : $(SOURCE) "$(INTDIR)" "$(OUTDIR)"
	\src\nasmw.exe $(InputPath) -o $(IntDir)\$(InputName).obj -fwin32 -w+orphan-labels -i..\ui\ -i..\pgfx\ -i\src\win\ -i\src\common\ -d_MSLINK -d_WINDOWS

# End Custom Build
# End Source File
# End Group
# Begin Group "Header Files"

# PROP Default_Filter "h;hpp;hxx;hm;inl"
# Begin Source File

SOURCE=..\..\win\AtrbList\AtrbList.h
# End Source File
# Begin Source File

SOURCE=.\guioptions.h
# End Source File
# Begin Source File

SOURCE=..\..\win\macros32.inc
# PROP Exclude_From_Build 1
# End Source File
# Begin Source File

SOURCE=..\pgfx\pgfx.h
# End Source File
# Begin Source File

SOURCE=..\pgfx\pgfxlayr.h
# End Source File
# Begin Source File

SOURCE=.\pgfxoptions.h
# End Source File
# Begin Source File

SOURCE=.\pgfxtest.h
# End Source File
# Begin Source File

SOURCE=..\..\common\winnasm.inc
# End Source File
# End Group
# Begin Group "Resource Files"

# PROP Default_Filter "ico;cur;bmp;dlg;rc2;rct;bin;rgs;gif;jpg;jpeg;jpe"
# Begin Source File

SOURCE=.\Pgfxtest.rc
# End Source File
# End Group
# Begin Group "ZLIB Sources"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\..\zlib\adler32.c
# End Source File
# Begin Source File

SOURCE=..\..\zlib\compress.c
# End Source File
# Begin Source File

SOURCE=..\..\zlib\crc32.c
# End Source File
# Begin Source File

SOURCE=..\..\zlib\deflate.c
# End Source File
# Begin Source File

SOURCE=..\..\zlib\deflate.h
# End Source File
# Begin Source File

SOURCE=..\..\zlib\infblock.c
# End Source File
# Begin Source File

SOURCE=..\..\zlib\infblock.h
# End Source File
# Begin Source File

SOURCE=..\..\zlib\infcodes.c
# End Source File
# Begin Source File

SOURCE=..\..\zlib\infcodes.h
# End Source File
# Begin Source File

SOURCE=..\..\zlib\inffast.c
# End Source File
# Begin Source File

SOURCE=..\..\zlib\inffast.h
# End Source File
# Begin Source File

SOURCE=..\..\zlib\inffixed.h
# End Source File
# Begin Source File

SOURCE=..\..\zlib\inflate.c
# End Source File
# Begin Source File

SOURCE=..\..\zlib\inftrees.c
# End Source File
# Begin Source File

SOURCE=..\..\zlib\inftrees.h
# End Source File
# Begin Source File

SOURCE=..\..\zlib\infutil.c
# End Source File
# Begin Source File

SOURCE=..\..\zlib\infutil.h
# End Source File
# Begin Source File

SOURCE=..\..\zlib\trees.c
# End Source File
# Begin Source File

SOURCE=..\..\zlib\trees.h
# End Source File
# Begin Source File

SOURCE=..\..\zlib\uncompr.c
# End Source File
# Begin Source File

SOURCE=..\..\zlib\zconf.h
# End Source File
# Begin Source File

SOURCE=..\..\zlib\zlib.h
# End Source File
# Begin Source File

SOURCE=..\..\zlib\zutil.c
# End Source File
# Begin Source File

SOURCE=..\..\zlib\zutil.h
# End Source File
# End Group
# End Target
# End Project
