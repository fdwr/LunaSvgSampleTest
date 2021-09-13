# Microsoft Developer Studio Project File - Name="CardGame" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Application" 0x0101

CFG=CardGame - Win32 Debug
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "CardGame.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "CardGame.mak" CFG="CardGame - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "CardGame - Win32 Release" (based on "Win32 (x86) Application")
!MESSAGE "CardGame - Win32 Debug" (based on "Win32 (x86) Application")
!MESSAGE "CardGame - Win32 Final" (based on "Win32 (x86) Application")
!MESSAGE 

# Begin Project
# PROP AllowPerConfigDependencies 0
# PROP Scc_ProjName ""
# PROP Scc_LocalPath ""
CPP=cl.exe
MTL=midl.exe
RSC=rc.exe

!IF  "$(CFG)" == "CardGame - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "C:\WINDOWS\TEMP\Release"
# PROP BASE Intermediate_Dir "C:\WINDOWS\TEMP\Release"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "C:\WINDOWS\TEMP\Release"
# PROP Intermediate_Dir "C:\WINDOWS\TEMP\Release"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /D "_MBCS" /YX /FD /c
# ADD CPP /nologo /W3 /GX /O1 /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /D "_MBCS" /Yu"WINDOWS.H" /FD /c
# SUBTRACT CPP /Fr
# ADD BASE MTL /nologo /D "NDEBUG" /mktyplib203 /win32
# ADD MTL /nologo /D "NDEBUG" /mktyplib203 /win32
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:windows /machine:I386
# ADD LINK32 kernel32.lib user32.lib gdi32.lib comctl32.lib /nologo /subsystem:windows /incremental:yes /machine:I386

!ELSEIF  "$(CFG)" == "CardGame - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "C:\WINDOWS\TEMP\Debug"
# PROP BASE Intermediate_Dir "C:\WINDOWS\TEMP\Debug"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "C:\WINDOWS\TEMP\Debug"
# PROP Intermediate_Dir "C:\WINDOWS\TEMP\Debug"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /W3 /Gm /GX /ZI /Od /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /D "_MBCS" /YX /FD /GZ /c
# ADD CPP /nologo /W3 /Gm /GX /ZI /Od /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /D "_MBCS" /Yu"windows.h" /FD /GZ /c
# ADD BASE MTL /nologo /D "_DEBUG" /mktyplib203 /win32
# ADD MTL /nologo /D "_DEBUG" /mktyplib203 /win32
# ADD BASE RSC /l 0x409 /d "_DEBUG"
# ADD RSC /l 0x409 /d "_DEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:windows /debug /machine:I386 /pdbtype:sept
# ADD LINK32 kernel32.lib user32.lib gdi32.lib comctl32.lib /nologo /subsystem:windows /debug /machine:I386 /pdbtype:sept
# SUBTRACT LINK32 /nodefaultlib

!ELSEIF  "$(CFG)" == "CardGame - Win32 Final"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "C:\WINDOWS\TEMP\Final"
# PROP BASE Intermediate_Dir "C:\WINDOWS\TEMP\Final"
# PROP BASE Ignore_Export_Lib 0
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "C:\WINDOWS\TEMP\Final"
# PROP Intermediate_Dir "C:\WINDOWS\TEMP\Final"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /W3 /GX /O1 /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /D "_MBCS" /YX"WINDOWS.H" /FD /c
# ADD CPP /nologo /W3 /GX /O1 /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /D "_MBCS" /Yu"WINDOWS.H" /FD /c
# ADD BASE MTL /nologo /D "NDEBUG" /mktyplib203 /win32
# ADD MTL /nologo /D "NDEBUG" /mktyplib203 /win32
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib comctl32.lib /nologo /subsystem:windows /machine:I386
# ADD LINK32 kernel32.lib user32.lib gdi32.lib comctl32.lib /nologo /subsystem:windows /machine:I386 /nodefaultlib

!ENDIF 

# Begin Target

# Name "CardGame - Win32 Release"
# Name "CardGame - Win32 Debug"
# Name "CardGame - Win32 Final"
# Begin Group "Source Files"

# PROP Default_Filter "cpp;c;cxx;rc;def;r;odl;idl;hpj;bat"
# Begin Source File

SOURCE=.\CardGame.c
# End Source File
# End Group
# Begin Group "Header Files"

# PROP Default_Filter "h;hpp;hxx;hm;inl"
# Begin Source File

SOURCE=.\CardGame.h
# End Source File
# Begin Source File

SOURCE=.\resource.h
# End Source File
# End Group
# Begin Group "Resource Files"

# PROP Default_Filter "ico;cur;bmp;dlg;rc2;rct;bin;rgs;gif;jpg;jpeg;jpe"
# Begin Source File

SOURCE=.\01.bmp
# End Source File
# Begin Source File

SOURCE=.\02.bmp
# End Source File
# Begin Source File

SOURCE=.\03.bmp
# End Source File
# Begin Source File

SOURCE=.\04.bmp
# End Source File
# Begin Source File

SOURCE=.\05.bmp
# End Source File
# Begin Source File

SOURCE=.\06.bmp
# End Source File
# Begin Source File

SOURCE=.\07.bmp
# End Source File
# Begin Source File

SOURCE=.\08.bmp
# End Source File
# Begin Source File

SOURCE=.\09.bmp
# End Source File
# Begin Source File

SOURCE=.\10.bmp
# End Source File
# Begin Source File

SOURCE=.\11.bmp
# End Source File
# Begin Source File

SOURCE=.\12.bmp
# End Source File
# Begin Source File

SOURCE=.\13.bmp
# End Source File
# Begin Source File

SOURCE=.\14.bmp
# End Source File
# Begin Source File

SOURCE=.\15.bmp
# End Source File
# Begin Source File

SOURCE=.\16.bmp
# End Source File
# Begin Source File

SOURCE=.\17.bmp
# End Source File
# Begin Source File

SOURCE=.\18.bmp
# End Source File
# Begin Source File

SOURCE=.\19.bmp
# End Source File
# Begin Source File

SOURCE=.\20.bmp
# End Source File
# Begin Source File

SOURCE=.\21.bmp
# End Source File
# Begin Source File

SOURCE=.\22.bmp
# End Source File
# Begin Source File

SOURCE=.\23.bmp
# End Source File
# Begin Source File

SOURCE=.\24.bmp
# End Source File
# Begin Source File

SOURCE=.\25.bmp
# End Source File
# Begin Source File

SOURCE=.\26.bmp
# End Source File
# Begin Source File

SOURCE=.\27.bmp
# End Source File
# Begin Source File

SOURCE=.\28.bmp
# End Source File
# Begin Source File

SOURCE=.\29.bmp
# End Source File
# Begin Source File

SOURCE=.\30.bmp
# End Source File
# Begin Source File

SOURCE=.\31.bmp
# End Source File
# Begin Source File

SOURCE=.\32.bmp
# End Source File
# Begin Source File

SOURCE=.\33.bmp
# End Source File
# Begin Source File

SOURCE=.\34.bmp
# End Source File
# Begin Source File

SOURCE=.\35.bmp
# End Source File
# Begin Source File

SOURCE=.\36.bmp
# End Source File
# Begin Source File

SOURCE=.\37.bmp
# End Source File
# Begin Source File

SOURCE=.\38.bmp
# End Source File
# Begin Source File

SOURCE=.\39.bmp
# End Source File
# Begin Source File

SOURCE=.\40.bmp
# End Source File
# Begin Source File

SOURCE=.\41.bmp
# End Source File
# Begin Source File

SOURCE=.\42.bmp
# End Source File
# Begin Source File

SOURCE=.\43.bmp
# End Source File
# Begin Source File

SOURCE=.\44.bmp
# End Source File
# Begin Source File

SOURCE=.\45.bmp
# End Source File
# Begin Source File

SOURCE=.\46.bmp
# End Source File
# Begin Source File

SOURCE=.\47.bmp
# End Source File
# Begin Source File

SOURCE=.\48.bmp
# End Source File
# Begin Source File

SOURCE=.\49.bmp
# End Source File
# Begin Source File

SOURCE=.\50.bmp
# End Source File
# Begin Source File

SOURCE=.\51.bmp
# End Source File
# Begin Source File

SOURCE=.\52.bmp
# End Source File
# Begin Source File

SOURCE=.\54.bmp
# End Source File
# Begin Source File

SOURCE=.\67.bmp
# End Source File
# Begin Source File

SOURCE=.\Cardgame.ico
# End Source File
# Begin Source File

SOURCE=.\CardGame.rc
# End Source File
# Begin Source File

SOURCE=.\CardHand.cur
# End Source File
# End Group
# End Target
# End Project
