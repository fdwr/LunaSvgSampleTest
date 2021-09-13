Attribute VB_Name = "modSysTray"
'------------------------------------------------------
' VB CENTER
'
' Tutorial: Using the system tray
' 09/26/98
'
' You may distribute this file as long as all the credits
' Are given to VB Center
'
' For more tutorials and a detailed explanation of this
' tutorial, visit our page: http://vbcenter.cjb.net
'
'------------------------------------------------------

Declare Function Shell_NotifyIcon Lib "shell32.dll" (ByVal dwMessage As Long, lpData As NOTIFYICONDATA) As Long
'If you get an error message at the beginning of the program,
'use the declaration below:
'Declare Function Shell_NotifyIcon Lib "shell32.dll" Alias " Shell_NotifyIconA" (ByVal dwMessage As Long, lpData As NOTIFYICONDATA) As Long

'These three constants specify what you want to do
Public Const NIM_ADD = &H0
Public Const NIM_DELETE = &H2
Public Const NIM_MODIFY = &H1

Public Const NIF_ICON = &H2
Public Const NIF_MESSAGE = &H1
Public Const NIF_TIP = &H4

Public Const WM_LBUTTONDBLCLK = &H203
Public Const WM_LBUTTONDOWN = &H201
Public Const WM_LBUTTONUP = &H202
Public Const WM_MOUSEMOVE = &H200
Public Const WM_RBUTTONDBLCLK = &H206
Public Const WM_RBUTTONDOWN = &H204
Public Const WM_RBUTTONUP = &H205

Type NOTIFYICONDATA
        cbSize As Long
        hwnd As Long
        uID As Long
        uFlags As Long
        uCallbackMessage As Long
        hIcon As Long
        szTip As String * 64
End Type

Public IconData As NOTIFYICONDATA
