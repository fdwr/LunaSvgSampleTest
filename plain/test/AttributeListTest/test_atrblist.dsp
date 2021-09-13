# Microsoft Developer Studio Project File - Name="test_atrblist" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Application" 0x0101

CFG=test_atrblist - Win32 Debug
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "test_atrblist.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "test_atrblist.mak" CFG="test_atrblist - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "test_atrblist - Win32 Release" (based on "Win32 (x86) Application")
!MESSAGE "test_atrblist - Win32 Debug" (based on "Win32 (x86) Application")
!MESSAGE 

# Begin Project
# PROP AllowPerConfigDependencies 0
# PROP Scc_ProjName ""
# PROP Scc_LocalPath ""
CPP=cl.exe
MTL=midl.exe
RSC=rc.exe

!IF  "$(CFG)" == "test_atrblist - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "Release"
# PROP BASE Intermediate_Dir "Release"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "c:\temp\test_atrblist"
# PROP Intermediate_Dir "c:\temp\test_atrblist"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /D "_MBCS" /YX /FD /c
# ADD CPP /nologo /W3 /GX /O2 /I "." /I "..\ui" /I "..\pgfx" /I "..\..\common" /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /D "_MBCS" /YX /FD /c
# ADD BASE MTL /nologo /D "NDEBUG" /mktyplib203 /win32
# ADD MTL /nologo /D "NDEBUG" /mktyplib203 /win32
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:windows /machine:I386
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:windows /machine:I386 /out:"test_atrblist.exe"

!ELSEIF  "$(CFG)" == "test_atrblist - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "Debug"
# PROP BASE Intermediate_Dir "Debug"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "c:\temp\test_atrblist_dbg"
# PROP Intermediate_Dir "c:\temp\test_atrblist_dbg"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /W3 /Gm /GX /ZI /Od /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /D "_MBCS" /YX /FD /GZ /c
# ADD CPP /nologo /W3 /Gm /GX /ZI /Od /I "." /I "..\ui" /I "..\pgfx" /I "..\..\common" /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /D "_MBCS" /YX /FD /GZ /c
# ADD BASE MTL /nologo /D "_DEBUG" /mktyplib203 /win32
# ADD MTL /nologo /D "_DEBUG" /mktyplib203 /win32
# ADD BASE RSC /l 0x409 /d "_DEBUG"
# ADD RSC /l 0x409 /d "_DEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:windows /debug /machine:I386 /pdbtype:sept
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:windows /debug /machine:I386 /out:"test_atrblist_dbg.exe" /pdbtype:sept

!ENDIF 

# Begin Target

# Name "test_atrblist - Win32 Release"
# Name "test_atrblist - Win32 Debug"
# Begin Group "Source Files"

# PROP Default_Filter "cpp;c;cxx;rc;def;r;odl;idl;hpj;bat"
# Begin Source File

SOURCE=.\guioptions.h
# End Source File
# Begin Source File

SOURCE=.\main.cpp
# End Source File
# Begin Source File

SOURCE=.\main.h
# End Source File
# Begin Source File

SOURCE=.\pgfxoptions.h
# End Source File
# Begin Source File

SOURCE=.\resources.asm

!IF  "$(CFG)" == "test_atrblist - Win32 Release"

# Begin Custom Build
IntDir=c:\temp\test_atrblist
InputPath=.\resources.asm
InputName=resources

"$(IntDir)\$(InputName).obj" : $(SOURCE) "$(INTDIR)" "$(OUTDIR)"
	..\..\nasmw.exe $(InputPath) -o $(IntDir)\$(InputName).obj -fwin32 -w+orphan-labels -i..\..\common\ -i..\pgfx\ -i..\ui\ -d_MSLINK -d_WINDOWS

# End Custom Build

!ELSEIF  "$(CFG)" == "test_atrblist - Win32 Debug"

# Begin Custom Build
IntDir=c:\temp\test_atrblist_dbg
InputPath=.\resources.asm
InputName=resources

"$(IntDir)\$(InputName).obj" : $(SOURCE) "$(INTDIR)" "$(OUTDIR)"
	..\..\nasmw.exe $(InputPath) -o $(IntDir)\$(InputName).obj -fwin32 -w+orphan-labels -i..\..\common\ -i..\pgfx\ -i..\ui\ -d_MSLINK -d_WINDOWS

# End Custom Build

!ENDIF 

# End Source File
# End Group
# Begin Group "Header Files"

# PROP Default_Filter "h;hpp;hxx;hm;inl"
# End Group
# Begin Group "Resource Files"

# PROP Default_Filter "ico;cur;bmp;dlg;rc2;rct;bin;rgs;gif;jpg;jpeg;jpe"
# End Group
# Begin Group "Pgfx"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\pgfx\pgfx.h
# End Source File
# Begin Source File

SOURCE=..\pgfx\pgfxhl.asm

!IF  "$(CFG)" == "test_atrblist - Win32 Release"

# Begin Custom Build
IntDir=c:\temp\test_atrblist
InputPath=..\pgfx\pgfxhl.asm
InputName=pgfxhl

"$(IntDir)\$(InputName).obj" : $(SOURCE) "$(INTDIR)" "$(OUTDIR)"
	..\..\nasmw.exe $(InputPath) -o $(IntDir)\$(InputName).obj -fwin32 -w+orphan-labels -i..\..\common\ -i..\pgfx\ -i..\ui\ -d_MSLINK -d_WINDOWS

# End Custom Build

!ELSEIF  "$(CFG)" == "test_atrblist - Win32 Debug"

# Begin Custom Build
IntDir=c:\temp\test_atrblist_dbg
InputPath=..\pgfx\pgfxhl.asm
InputName=pgfxhl

"$(IntDir)\$(InputName).obj" : $(SOURCE) "$(INTDIR)" "$(OUTDIR)"
	..\..\nasmw.exe $(InputPath) -o $(IntDir)\$(InputName).obj -fwin32 -w+orphan-labels -i..\..\common\ -i..\pgfx\ -i..\ui\ -d_MSLINK -d_WINDOWS

# End Custom Build

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\pgfx\pgfxlayr.asm

!IF  "$(CFG)" == "test_atrblist - Win32 Release"

# Begin Custom Build
IntDir=c:\temp\test_atrblist
InputPath=..\pgfx\pgfxlayr.asm
InputName=pgfxlayr

"$(IntDir)\$(InputName).obj" : $(SOURCE) "$(INTDIR)" "$(OUTDIR)"
	..\..\nasmw.exe $(InputPath) -o $(IntDir)\$(InputName).obj -fwin32 -w+orphan-labels -i..\..\common\ -i..\pgfx\ -i..\ui\ -d_MSLINK -d_WINDOWS

# End Custom Build

!ELSEIF  "$(CFG)" == "test_atrblist - Win32 Debug"

# Begin Custom Build
IntDir=c:\temp\test_atrblist_dbg
InputPath=..\pgfx\pgfxlayr.asm
InputName=pgfxlayr

"$(IntDir)\$(InputName).obj" : $(SOURCE) "$(INTDIR)" "$(OUTDIR)"
	..\..\nasmw.exe $(InputPath) -o $(IntDir)\$(InputName).obj -fwin32 -w+orphan-labels -i..\..\common\ -i..\pgfx\ -i..\ui\ -d_MSLINK -d_WINDOWS

# End Custom Build

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\pgfx\pgfxlayr.h
# End Source File
# Begin Source File

SOURCE=..\pgfx\pgfxll.asm

!IF  "$(CFG)" == "test_atrblist - Win32 Release"

# Begin Custom Build
IntDir=c:\temp\test_atrblist
InputPath=..\pgfx\pgfxll.asm
InputName=pgfxll

"$(IntDir)\$(InputName).obj" : $(SOURCE) "$(INTDIR)" "$(OUTDIR)"
	..\..\nasmw.exe $(InputPath) -o $(IntDir)\$(InputName).obj -fwin32 -w+orphan-labels -i..\..\common\ -i..\pgfx\ -i..\ui\ -d_MSLINK -d_WINDOWS

# End Custom Build

!ELSEIF  "$(CFG)" == "test_atrblist - Win32 Debug"

# Begin Custom Build
IntDir=c:\temp\test_atrblist_dbg
InputPath=..\pgfx\pgfxll.asm
InputName=pgfxll

"$(IntDir)\$(InputName).obj" : $(SOURCE) "$(INTDIR)" "$(OUTDIR)"
	..\..\nasmw.exe $(InputPath) -o $(IntDir)\$(InputName).obj -fwin32 -w+orphan-labels -i..\..\common\ -i..\pgfx\ -i..\ui\ -d_MSLINK -d_WINDOWS

# End Custom Build

!ENDIF 

# End Source File
# End Group
# Begin Group "Ui"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\ui\cursors.asm

!IF  "$(CFG)" == "test_atrblist - Win32 Release"

# Begin Custom Build
IntDir=c:\temp\test_atrblist
InputPath=..\ui\cursors.asm
InputName=cursors

"$(IntDir)\$(InputName).obj" : $(SOURCE) "$(INTDIR)" "$(OUTDIR)"
	..\..\nasmw.exe $(InputPath) -o $(IntDir)\$(InputName).obj -fwin32 -w+orphan-labels -i..\..\common\ -i..\pgfx\ -i..\ui\ -d_MSLINK -d_WINDOWS

# End Custom Build

!ELSEIF  "$(CFG)" == "test_atrblist - Win32 Debug"

# Begin Custom Build
IntDir=c:\temp\test_atrblist_dbg
InputPath=..\ui\cursors.asm
InputName=cursors

"$(IntDir)\$(InputName).obj" : $(SOURCE) "$(INTDIR)" "$(OUTDIR)"
	..\..\nasmw.exe $(InputPath) -o $(IntDir)\$(InputName).obj -fwin32 -w+orphan-labels -i..\..\common\ -i..\pgfx\ -i..\ui\ -d_MSLINK -d_WINDOWS

# End Custom Build

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\ui\guicode.cpp
# End Source File
# Begin Source File

SOURCE=..\ui\guidefs.h
# End Source File
# Begin Source File

SOURCE=..\ui\guiobj.cpp
# End Source File
# Begin Source File

SOURCE=..\ui\uceattriblist.cpp
# End Source File
# Begin Source File

SOURCE=..\ui\uceborder.cpp
# End Source File
# Begin Source File

SOURCE=..\ui\ucebutton.cpp
# End Source File
# Begin Source File

SOURCE=..\ui\ucepreview.cpp
# End Source File
# Begin Source File

SOURCE=..\ui\ucerootwindow.cpp
# End Source File
# Begin Source File

SOURCE=..\ui\ucetitlebar.cpp
# End Source File
# Begin Source File

SOURCE=..\ui\ucewindow.cpp
# End Source File
# Begin Source File

SOURCE=..\ui\ucewindowbg.cpp
# End Source File
# End Group
# Begin Group "Common"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\..\common\basictypes.h
# End Source File
# Begin Source File

SOURCE=..\..\common\macros32.inc
# End Source File
# Begin Source File

SOURCE=..\..\common\winnasm.inc
# End Source File
# End Group
# End Target
# End Project
