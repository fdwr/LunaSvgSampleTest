; Function to return full path to a file based on the current path and a
; new relative one.


;   C:\Windows
; + System\VgaDrv.Sys
; = C:\Windows\System\VgaDrv.Sys
;
;   C:\Windows
; + ..\Emu\Mario.Spc
; = C:\Emu\Mario.Spc
;
;   C:\Windows
; + System\Nowhere\Somefile.txt
; = C:\Windows\System (error)
;
;   C:\Windows
; + ..\..\Somefile.txt
; = C:\ (error)
;
;   C:\Windows
; + D:
; = D:\WhoKnows
;

; search for colon
; if drive included
;   try to change to drive
;   if drive does not exist or is not ready, return drive failure
;   if next character is slash then skip character
; endif
; start path loop
;   find next slash or end of string
;   parse first element of path
;   try to set directory, if error return path change error
;   if dots
;     get current directory
;   endif
; loop while directory can be set
; get current directory
; if no more elements, return path success
; if last element is a file, return file success
; if last element does not exist, return file error
; if last element is a wildcard, return mask success

; Starting from:        Going to:
;   D:\Images             C:\Windows\System\VgaDrv.Sys
;
;   Drive included "C:"
;   Attempt to set drive, success
;   Continue path search since more characters come after drive
;   Skip backslash included after drive, C:[\]Windows\System\VgaDrv.Sys
;   Find next backslash, C:\Windows[\]System\VgaDrv.Sys
;   Try to set path, "\Windows", success
;   Find next backslash, C:\Windows\System[\]VgaDrv.Sys
;   Try to set path, "System", success
;   Find next backslash, C:\Windows\System\VgaDrv.Sys[], end of string
;   Try to set path, "VgaDrv.Sys", failure
;   Last element is an existing file, return success
