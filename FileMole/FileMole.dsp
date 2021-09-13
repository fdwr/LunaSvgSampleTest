# Microsoft Developer Studio Project File - Name="FileMole" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Application" 0x0101

CFG=FileMole - Win32 Debug
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "FileMole.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "FileMole.mak" CFG="FileMole - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "FileMole - Win32 Release" (based on "Win32 (x86) Application")
!MESSAGE "FileMole - Win32 Debug" (based on "Win32 (x86) Application")
!MESSAGE "FileMole - Win32 Test" (based on "Win32 (x86) Application")
!MESSAGE 

# Begin Project
# PROP AllowPerConfigDependencies 0
# PROP Scc_ProjName ""
# PROP Scc_LocalPath ""
CPP=cl.exe
MTL=midl.exe
RSC=rc.exe

!IF  "$(CFG)" == "FileMole - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "Release"
# PROP BASE Intermediate_Dir "Release"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "c:\WINDOWS\TEMP\filemole_RELEASE"
# PROP Intermediate_Dir "c:\WINDOWS\TEMP\filemole_RELEASE"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /D "_MBCS" /YX /FD /c
# ADD CPP /nologo /W3 /GX /O1 /D "NDEBUG" /D "WIN32" /D "_WINDOWS" /D "UNICODE" /D "_UNICODE" /D MICROSOFT_LAYER_FOR_UNICODE=1 /FD /c
# SUBTRACT CPP /Fr /YX /Yc /Yu
# ADD BASE MTL /nologo /D "NDEBUG" /mktyplib203 /win32
# ADD MTL /nologo /D "NDEBUG" /mktyplib203 /win32
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# SUBTRACT BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:windows /machine:I386
# ADD LINK32 unicows.lib kernel32.lib advapi32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib comctl32.lib mpr.lib wsock32.lib /nologo /entry:"WinMain" /subsystem:windows /pdb:none /machine:I386 /nodefaultlib /out:"FileMole.exe"
# SUBTRACT LINK32 /verbose

!ELSEIF  "$(CFG)" == "FileMole - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "c:\WINDOWS\TEMP\Debug"
# PROP BASE Intermediate_Dir "c:\WINDOWS\TEMP\Debug"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "c:\WINDOWS\TEMP\filemole_DEBUG"
# PROP Intermediate_Dir "c:\WINDOWS\TEMP\filemole_DEBUG"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /W3 /Gm /GX /ZI /Od /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /D "_MBCS" /YX /FD /GZ /c
# ADD CPP /nologo /W3 /Gm /Gi /GX /ZI /Od /D "MYDEBUG" /D "WIN32" /D "_WINDOWS" /D "UNICODE" /D "_UNICODE" /D MICROSOFT_LAYER_FOR_UNICODE=1 /YX"FileMole.h" /FD /GZ /c
# ADD BASE MTL /nologo /D "_DEBUG" /mktyplib203 /win32
# ADD MTL /nologo /D "_DEBUG" /mktyplib203 /win32
# ADD BASE RSC /l 0x409 /d "_DEBUG"
# ADD RSC /l 0x409 /d "_DEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:windows /debug /machine:I386 /pdbtype:sept
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib comctl32.lib mpr.lib wsock32.lib /nologo /subsystem:windows /debug /machine:I386 /out:"FileMole_debug.exe" /pdbtype:sept
# SUBTRACT LINK32 /pdb:none

!ELSEIF  "$(CFG)" == "FileMole - Win32 Test"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "c:\WINDOWS\TEMP\Test"
# PROP BASE Intermediate_Dir "c:\WINDOWS\TEMP\Test"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "c:\WINDOWS\TEMP\filemole_test"
# PROP Intermediate_Dir "c:\WINDOWS\TEMP\filemole_test"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /D "_MBCS" /YX /FD /c
# ADD CPP /nologo /W3 /Gi /GX /D "NDEBUG" /D "MYDEBUG" /D "MYDEBUGLIST" /D "WIN32" /D "_WINDOWS" /D "UNICODE" /D "_UNICODE" /D MICROSOFT_LAYER_FOR_UNICODE=1 /FD /c
# SUBTRACT CPP /Fr /YX /Yc /Yu
# ADD BASE MTL /nologo /D "NDEBUG" /mktyplib203 /win32
# ADD MTL /nologo /D "NDEBUG" /mktyplib203 /win32
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib comctl32.lib mpr.lib /nologo /entry:"WinMain" /subsystem:windows /machine:I386 /nodefaultlib
# SUBTRACT BASE LINK32 /pdb:none
# ADD LINK32 unicows.lib kernel32.lib advapi32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib comctl32.lib mpr.lib wsock32.lib /nologo /entry:"WinMain" /subsystem:windows /pdb:none /machine:I386 /nodefaultlib /out:"FileMole_test.exe"
# SUBTRACT LINK32 /verbose

!ENDIF 

# Begin Target

# Name "FileMole - Win32 Release"
# Name "FileMole - Win32 Debug"
# Name "FileMole - Win32 Test"
# Begin Group "Sources"

# PROP Default_Filter "cpp;c;cxx;rc;def;r;odl;idl;hpj;bat;asm"
# Begin Source File

SOURCE=..\win\AtrbList\AtrbList.c
# End Source File
# Begin Source File

SOURCE=.\DebugOut.c

!IF  "$(CFG)" == "FileMole - Win32 Release"

# PROP Exclude_From_Build 1

!ELSEIF  "$(CFG)" == "FileMole - Win32 Debug"

!ELSEIF  "$(CFG)" == "FileMole - Win32 Test"

# ADD CPP /YX"winuser.h"

!ENDIF 

# End Source File
# Begin Source File

SOURCE=.\DlgPanel.c
# PROP Exclude_From_Build 1
# End Source File
# Begin Source File

SOURCE=.\FileList.c

!IF  "$(CFG)" == "FileMole - Win32 Release"

# ADD CPP /Gy /YX
# SUBTRACT CPP /Fr

!ELSEIF  "$(CFG)" == "FileMole - Win32 Debug"

# ADD CPP /Gi /YX"FileMole.h"

!ELSEIF  "$(CFG)" == "FileMole - Win32 Test"

# ADD CPP /Gy /YX"FileMole.h"
# SUBTRACT CPP /Gf /Fr

!ENDIF 

# End Source File
# Begin Source File

SOURCE=.\FileMole.c

!IF  "$(CFG)" == "FileMole - Win32 Release"

# ADD CPP /YX
# SUBTRACT CPP /Fr

!ELSEIF  "$(CFG)" == "FileMole - Win32 Debug"

# ADD CPP /Gi /YX"FileMole.h"

!ELSEIF  "$(CFG)" == "FileMole - Win32 Test"

# ADD BASE CPP /Yu"resource.h"
# SUBTRACT BASE CPP /Fr
# ADD CPP /Gy /YX
# SUBTRACT CPP /Gf /Fr

!ENDIF 

# End Source File
# Begin Source File

SOURCE=.\FLanScan.asm

!IF  "$(CFG)" == "FileMole - Win32 Release"

# PROP Exclude_From_Build 1

!ELSEIF  "$(CFG)" == "FileMole - Win32 Debug"

# PROP Exclude_From_Build 1

!ELSEIF  "$(CFG)" == "FileMole - Win32 Test"

# PROP BASE Exclude_From_Build 1
# PROP Exclude_From_Build 1

!ENDIF 

# End Source File
# Begin Source File

SOURCE=.\RsizeBar.c

!IF  "$(CFG)" == "FileMole - Win32 Release"

# ADD CPP /YX

!ELSEIF  "$(CFG)" == "FileMole - Win32 Debug"

!ELSEIF  "$(CFG)" == "FileMole - Win32 Test"

!ENDIF 

# End Source File
# Begin Source File

SOURCE=.\ustring.c

!IF  "$(CFG)" == "FileMole - Win32 Release"

# ADD CPP /YX

!ELSEIF  "$(CFG)" == "FileMole - Win32 Debug"

!ELSEIF  "$(CFG)" == "FileMole - Win32 Test"

!ENDIF 

# End Source File
# End Group
# Begin Group "Headers"

# PROP Default_Filter "h;hpp;hxx;hm;inl"
# Begin Source File

SOURCE=..\win\AtrbList\AtrbList.h
# End Source File
# Begin Source File

SOURCE=.\DebugOut.h
# End Source File
# Begin Source File

SOURCE=.\FileList.h
# End Source File
# Begin Source File

SOURCE=.\FileMole.h
# End Source File
# Begin Source File

SOURCE=.\resource.h
# End Source File
# Begin Source File

SOURCE=.\RsizeBar.h
# End Source File
# Begin Source File

SOURCE=.\Version.h
# End Source File
# End Group
# Begin Group "Resources"

# PROP Default_Filter "ico;cur;bmp;dlg;rc2;rct;bin;rgs;gif;jpg;jpeg;jpe"
# Begin Source File

SOURCE=.\Images\delete_warning.ico
# End Source File
# Begin Source File

SOURCE=.\Images\file_list4b.bmp
# End Source File
# Begin Source File

SOURCE=.\IMAGES\file_list8b.bmp
# End Source File
# Begin Source File

SOURCE=.\Images\FileMole.ico
# End Source File
# Begin Source File

SOURCE=.\FileMole.manifest
# End Source File
# Begin Source File

SOURCE=.\FileMole.rc
# End Source File
# Begin Source File

SOURCE=.\images\linkhand.cur
# End Source File
# Begin Source File

SOURCE=.\Images\Rsz_horz.cur
# End Source File
# Begin Source File

SOURCE=.\Images\Rsz_vert.cur
# End Source File
# Begin Source File

SOURCE=.\Images\tool_bar8b.bmp
# End Source File
# End Group
# Begin Group "Documents"

# PROP Default_Filter "*.txt;*.log;*.html"
# Begin Source File

SOURCE=.\FileMole.log
# PROP Exclude_From_Build 1
# End Source File
# Begin Source File

SOURCE=.\FileMole.txt
# PROP Exclude_From_Build 1
# End Source File
# End Group
# End Target
# End Project
