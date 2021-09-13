# Microsoft Developer Studio Project File - Name="ctest" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Application" 0x0101

CFG=ctest - Win32 Debug
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "ctest.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "ctest.mak" CFG="ctest - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "ctest - Win32 Release" (based on "Win32 (x86) Application")
!MESSAGE "ctest - Win32 Debug" (based on "Win32 (x86) Application")
!MESSAGE 

# Begin Project
# PROP AllowPerConfigDependencies 0
# PROP Scc_ProjName ""
# PROP Scc_LocalPath ""
CPP=cl.exe
MTL=midl.exe
RSC=rc.exe

!IF  "$(CFG)" == "ctest - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "Release"
# PROP BASE Intermediate_Dir "Release"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "."
# PROP Intermediate_Dir "c:\temp\ctest"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /D "_MBCS" /Yu"stdafx.h" /FD /c
# ADD CPP /nologo /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /D "_MBCS" /Yu"stdafx.h" /FD /c
# ADD BASE MTL /nologo /D "NDEBUG" /mktyplib203 /win32
# ADD MTL /nologo /D "NDEBUG" /mktyplib203 /win32
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:windows /machine:I386
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib comctl32.lib /nologo /subsystem:windows /machine:I386

!ELSEIF  "$(CFG)" == "ctest - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "Debug"
# PROP BASE Intermediate_Dir "Debug"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "."
# PROP Intermediate_Dir "c:\temp\ctestdbg"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /W3 /Gm /GX /ZI /Od /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /D "_MBCS" /Yu"stdafx.h" /FD /GZ /c
# ADD CPP /nologo /W3 /Gm /GX /ZI /Od /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /D "_MBCS" /Yu"stdafx.h" /FD /GZ /c
# ADD BASE MTL /nologo /D "_DEBUG" /mktyplib203 /win32
# ADD MTL /nologo /D "_DEBUG" /mktyplib203 /win32
# ADD BASE RSC /l 0x409 /d "_DEBUG"
# ADD RSC /l 0x409 /d "_DEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:windows /debug /machine:I386 /pdbtype:sept
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib comctl32.lib /nologo /subsystem:windows /debug /machine:I386 /out:"./ctestdbg.exe" /pdbtype:sept

!ENDIF 

# Begin Target

# Name "ctest - Win32 Release"
# Name "ctest - Win32 Debug"
# Begin Group "Source Files"

# PROP Default_Filter "cpp;c;cxx;rc;def;r;odl;idl;hpj;bat"
# Begin Source File

SOURCE=.\ctest.cpp
# End Source File
# Begin Source File

SOURCE=.\ctest.rc
# End Source File
# Begin Source File

SOURCE=.\layers.asm

!IF  "$(CFG)" == "ctest - Win32 Release"

# Begin Custom Build
IntDir=c:\temp\ctest
InputPath=.\layers.asm
InputName=layers

"$(IntDir)\$(InputName).obj" : $(SOURCE) "$(INTDIR)" "$(OUTDIR)"
	\src\nasmw.exe $(InputPath) -o $(IntDir)\$(InputName).obj -fwin32 -w+orphan-labels -i\src\common\ -i..\pgfx\ -i..\pgfx\ -d_MSLINK

# End Custom Build

!ELSEIF  "$(CFG)" == "ctest - Win32 Debug"

# Begin Custom Build
IntDir=c:\temp\ctestdbg
InputPath=.\layers.asm
InputName=layers

"$(IntDir)\$(InputName).obj" : $(SOURCE) "$(INTDIR)" "$(OUTDIR)"
	\src\nasmw.exe $(InputName).asm -o $(IntDir)\$(InputName).obj -fwin32 -w+orphan-labels -i\src\win\ -i..\src\ -d_MSLINK

# End Custom Build

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\pgfx\pgfxhl.asm

!IF  "$(CFG)" == "ctest - Win32 Release"

# Begin Custom Build
IntDir=c:\temp\ctest
InputPath=..\pgfx\pgfxhl.asm
InputName=pgfxhl

"$(IntDir)\$(InputName).obj" : $(SOURCE) "$(INTDIR)" "$(OUTDIR)"
	\src\nasmw.exe $(InputPath) -o $(IntDir)\$(InputName).obj -fwin32 -w+orphan-labels -i\src\common\ -i..\pgfx\ -i..\ui\ -d_MSLINK

# End Custom Build

!ELSEIF  "$(CFG)" == "ctest - Win32 Debug"

# Begin Custom Build
IntDir=c:\temp\ctestdbg
InputPath=..\pgfx\pgfxhl.asm
InputName=pgfxhl

"$(IntDir)\$(InputName).obj" : $(SOURCE) "$(INTDIR)" "$(OUTDIR)"
	\src\nasmw.exe $(InputPath) -o $(IntDir)\$(InputName).obj -fwin32 -w+orphan-labels -i\src\win\ -i..\pgfx\ -i..\ui\ -d_MSLINK

# End Custom Build

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\pgfx\pgfxlayr.asm

!IF  "$(CFG)" == "ctest - Win32 Release"

# Begin Custom Build
IntDir=c:\temp\ctest
InputPath=..\pgfx\pgfxlayr.asm
InputName=pgfxlayr

"$(IntDir)\$(InputName).obj" : $(SOURCE) "$(INTDIR)" "$(OUTDIR)"
	\src\nasmw.exe $(InputPath) -o $(IntDir)\$(InputName).obj -fwin32 -w+orphan-labels -i\src\common\ -i..\pgfx\ -i..\ui\ -d_MSLINK

# End Custom Build

!ELSEIF  "$(CFG)" == "ctest - Win32 Debug"

# Begin Custom Build
IntDir=c:\temp\ctestdbg
InputPath=..\pgfx\pgfxlayr.asm
InputName=pgfxlayr

"$(IntDir)\$(InputName).obj" : $(SOURCE) "$(INTDIR)" "$(OUTDIR)"
	\src\nasmw.exe $(InputPath) -o $(IntDir)\$(InputName).obj -fwin32 -w+orphan-labels -i\src\win\ -i..\pgfx\ -i..\ui\ -d_MSLINK

# End Custom Build

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\pgfx\pgfxll.asm

!IF  "$(CFG)" == "ctest - Win32 Release"

# Begin Custom Build
IntDir=c:\temp\ctest
InputPath=..\pgfx\pgfxll.asm
InputName=pgfxll

"$(IntDir)\$(InputName).obj" : $(SOURCE) "$(INTDIR)" "$(OUTDIR)"
	\src\nasmw.exe $(InputPath) -o $(IntDir)\$(InputName).obj -fwin32 -w+orphan-labels -i\src\common\ -i..\pgfx\ -i..\ui\ -d_MSLINK

# End Custom Build

!ELSEIF  "$(CFG)" == "ctest - Win32 Debug"

USERDEP__PGFXL="..\src\pgfx.h"	
# Begin Custom Build
IntDir=c:\temp\ctestdbg
InputPath=..\pgfx\pgfxll.asm
InputName=pgfxll

"$(IntDir)\$(InputName).obj" : $(SOURCE) "$(INTDIR)" "$(OUTDIR)"
	\src\nasmw.exe $(InputPath) -o $(IntDir)\$(InputName).obj -fwin32 -w+orphan-labels -i\src\win\ -i..\pgfx\ -i..\ui\ -d_MSLINK

# End Custom Build

!ENDIF 

# End Source File
# Begin Source File

SOURCE=.\StdAfx.cpp
# ADD CPP /Yc"stdafx.h"
# End Source File
# End Group
# Begin Group "Header Files"

# PROP Default_Filter "h;hpp;hxx;hm;inl"
# Begin Source File

SOURCE=.\ctest.h
# End Source File
# Begin Source File

SOURCE=..\..\common\macros32.inc
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

SOURCE=.\resource.h
# End Source File
# Begin Source File

SOURCE=.\StdAfx.h
# End Source File
# End Group
# Begin Group "Resource Files"

# PROP Default_Filter "ico;cur;bmp;dlg;rc2;rct;bin;rgs;gif;jpg;jpeg;jpe"
# Begin Source File

SOURCE=.\ctest.ico
# End Source File
# Begin Source File

SOURCE=..\data\plain.ico
# End Source File
# Begin Source File

SOURCE=.\small.ico
# End Source File
# End Group
# Begin Source File

SOURCE=.\ctest.manifest
# End Source File
# Begin Source File

SOURCE=.\data\sggate_1024_768.raw
# End Source File
# Begin Source File

SOURCE=.\sggate_1024_768.raw
# End Source File
# Begin Source File

SOURCE=.\data\stargate42.raw
# End Source File
# Begin Source File

SOURCE=.\stargate42.raw
# End Source File
# End Target
# End Project
