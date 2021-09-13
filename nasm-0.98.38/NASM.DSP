# Microsoft Developer Studio Project File - Name="nasm" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) External Target" 0x0106

CFG=nasm - Win32 Debug
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "nasm.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "nasm.mak" CFG="nasm - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "nasm - Win32 Release" (based on "Win32 (x86) External Target")
!MESSAGE "nasm - Win32 Debug" (based on "Win32 (x86) External Target")
!MESSAGE 

# Begin Project
# PROP AllowPerConfigDependencies 0
# PROP Scc_ProjName ""
# PROP Scc_LocalPath ""

!IF  "$(CFG)" == "nasm - Win32 Release"

# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "Release"
# PROP BASE Intermediate_Dir "Release"
# PROP BASE Cmd_Line "NMAKE /f Makefile.mak"
# PROP BASE Rebuild_Opt "/a"
# PROP BASE Target_File "Makefile.exe"
# PROP BASE Bsc_Name "Makefile.bsc"
# PROP BASE Target_Dir ""
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "Release"
# PROP Intermediate_Dir "Release"
# PROP Cmd_Line "NMAKE /f Makefile.mak"
# PROP Rebuild_Opt "/a"
# PROP Target_File "nasm.exe"
# PROP Bsc_Name "nasm.bsc"
# PROP Target_Dir ""

!ELSEIF  "$(CFG)" == "nasm - Win32 Debug"

# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "Debug"
# PROP BASE Intermediate_Dir "Debug"
# PROP BASE Cmd_Line "NMAKE /f Makefile.mak"
# PROP BASE Rebuild_Opt "/a"
# PROP BASE Target_File "Makefile.exe"
# PROP BASE Bsc_Name "Makefile.bsc"
# PROP BASE Target_Dir ""
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "Debug"
# PROP Intermediate_Dir "Debug"
# PROP Cmd_Line "NMAKE /f Makefile.mak"
# PROP Rebuild_Opt "/a"
# PROP Target_File "nasm.exe"
# PROP Bsc_Name "nasm.bsc"
# PROP Target_Dir ""

!ENDIF 

# Begin Target

# Name "nasm - Win32 Release"
# Name "nasm - Win32 Debug"

!IF  "$(CFG)" == "nasm - Win32 Release"

!ELSEIF  "$(CFG)" == "nasm - Win32 Debug"

!ENDIF 

# Begin Group "source"

# PROP Default_Filter "c"
# End Group
# Begin Group "headers"

# PROP Default_Filter "h"
# End Group
# Begin Source File

SOURCE=.\assemble.c
# End Source File
# Begin Source File

SOURCE=.\assemble.h
# End Source File
# Begin Source File

SOURCE=.\eval.c
# End Source File
# Begin Source File

SOURCE=.\eval.h
# End Source File
# Begin Source File

SOURCE=.\float.c
# End Source File
# Begin Source File

SOURCE=.\float.h
# End Source File
# Begin Source File

SOURCE=.\insns.h
# End Source File
# Begin Source File

SOURCE=.\insnsa.c
# End Source File
# Begin Source File

SOURCE=.\insnsi.h
# End Source File
# Begin Source File

SOURCE=.\labels.c
# End Source File
# Begin Source File

SOURCE=.\labels.h
# End Source File
# Begin Source File

SOURCE=.\listing.c
# End Source File
# Begin Source File

SOURCE=.\listing.h
# End Source File
# Begin Source File

SOURCE=.\Makefile.mak
# End Source File
# Begin Source File

SOURCE=.\nasm.c
# End Source File
# Begin Source File

SOURCE=.\nasm.h
# End Source File
# Begin Source File

SOURCE=.\nasmlib.c
# End Source File
# Begin Source File

SOURCE=.\nasmlib.h
# End Source File
# Begin Source File

SOURCE=.\output\outaout.c
# End Source File
# Begin Source File

SOURCE=.\output\outas86.c
# End Source File
# Begin Source File

SOURCE=.\output\outbin.c
# End Source File
# Begin Source File

SOURCE=.\output\outcoff.c
# End Source File
# Begin Source File

SOURCE=.\output\outdbg.c
# End Source File
# Begin Source File

SOURCE=.\output\outelf.c
# End Source File
# Begin Source File

SOURCE=.\outform.c
# End Source File
# Begin Source File

SOURCE=.\outform.h
# End Source File
# Begin Source File

SOURCE=.\output\outieee.c
# End Source File
# Begin Source File

SOURCE=.\output\outobj.c
# End Source File
# Begin Source File

SOURCE=.\output\outrdf.c
# End Source File
# Begin Source File

SOURCE=.\output\outrdf2.c
# End Source File
# Begin Source File

SOURCE=.\parser.c
# End Source File
# Begin Source File

SOURCE=.\parser.h
# End Source File
# Begin Source File

SOURCE=.\preproc.c
# End Source File
# Begin Source File

SOURCE=.\preproc.h
# End Source File
# End Target
# End Project
