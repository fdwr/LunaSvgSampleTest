VERSION 5.00
Begin VB.Form frmShellExDemo 
   Caption         =   "Open Program | Document | Folder | Url | Email Demo"
   ClientHeight    =   2010
   ClientLeft      =   60
   ClientTop       =   345
   ClientWidth     =   6075
   Icon            =   "ShellExDemo.frx":0000
   KeyPreview      =   -1  'True
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   2010
   ScaleWidth      =   6075
   StartUpPosition =   2  'CenterScreen
   Begin VB.ComboBox cboDisplay 
      Height          =   315
      ItemData        =   "ShellExDemo.frx":000C
      Left            =   1080
      List            =   "ShellExDemo.frx":002E
      TabIndex        =   9
      Top             =   1560
      Width           =   2775
   End
   Begin VB.TextBox txtPath 
      Height          =   285
      Left            =   1080
      TabIndex        =   7
      Top             =   1200
      Width           =   4935
   End
   Begin VB.TextBox txtParams 
      Height          =   285
      Left            =   1080
      TabIndex        =   5
      Top             =   840
      Width           =   4935
   End
   Begin VB.ComboBox cboAddress 
      Height          =   315
      ItemData        =   "ShellExDemo.frx":00EF
      Left            =   1080
      List            =   "ShellExDemo.frx":0105
      TabIndex        =   1
      Top             =   120
      Width           =   4935
   End
   Begin VB.CommandButton cmdBrowse 
      Caption         =   "Browse..."
      Height          =   375
      Left            =   5040
      TabIndex        =   11
      Top             =   1560
      Width           =   975
   End
   Begin VB.ComboBox cboAction 
      Height          =   315
      ItemData        =   "ShellExDemo.frx":0190
      Left            =   1080
      List            =   "ShellExDemo.frx":01A9
      TabIndex        =   3
      Top             =   480
      Width           =   4935
   End
   Begin VB.CommandButton cmdDoAction 
      Caption         =   "Execute"
      Default         =   -1  'True
      Height          =   375
      Left            =   3960
      TabIndex        =   10
      Top             =   1560
      Width           =   975
   End
   Begin VB.Label Label5 
      Caption         =   "Display:"
      Height          =   255
      Left            =   120
      TabIndex        =   8
      Top             =   1560
      Width           =   855
   End
   Begin VB.Label Label4 
      Caption         =   "Path:"
      Height          =   255
      Left            =   120
      TabIndex        =   6
      Top             =   1200
      Width           =   855
   End
   Begin VB.Label Label3 
      Caption         =   "Parameters:"
      Height          =   255
      Left            =   120
      TabIndex        =   4
      Top             =   840
      Width           =   855
   End
   Begin VB.Label Label2 
      Caption         =   "Action:"
      Height          =   255
      Left            =   120
      TabIndex        =   2
      Top             =   480
      Width           =   735
   End
   Begin VB.Label Label1 
      Caption         =   "Address:"
      Height          =   255
      Left            =   120
      TabIndex        =   0
      Top             =   120
      Width           =   735
   End
End
Attribute VB_Name = "frmShellExDemo"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

'ShellExecute Parameters:
'
'lpFile
'Address of a null-terminated string that specifies the file or object on
'which to execute the specified verb. To specify a shell namespace object,
'pass the fully-qualified parse name. Note that not all verbs are supported
'on all objects. For example, not all document types support the "print" verb.
'
'lpParameters
'If the lpFile parameter specifies an executable file, lpParameters is an
'address to a null-terminated string that specifies the parameters to be
'passed to the application.The format of this string is determined by the
'verb that is to be invoked. If lpFile specifies a document file,
'lpParameters should be NULL.
'
'lpDirectory
'Address of a null-terminated string that specifies the default directory.
'
'nShowCmd
'Flags that specify how an application is to be displayed when it is opened.
'If lpFile specifies a document file, the flag is simply passed to the
'associated application. It is up to the application to decide how to handle
'it.
'
'Read more about it at:
'http://msdn.microsoft.com/library/psdk/shellcc/shell/Functions/ShellExecute.htm
'http://www.vbcode.com/
'
'You might try:
'Opening a webpage
'  open           http://fdwr.tripod.com/snes.htm
'Mailing someone
'  open           mailto:FDwR@hotmail.com
'Opening a program
'  open           c:\windows\progman.exe
'Opening a document, automatically starting the correct program:
'  open           c:\windows\printers.txt
'Exploring a drive or folder's contents
'  explore/open   c:\windows
'Editing a batch file with NotePad
'  edit           c:\autoexec.bat
'
'ShellExecute simply performs the given action on the specified file.
'It does not tell what program was started to perform it. If you are
'interested in that, you might use the ShellExecuteEx command instead.
'
'http://msdn.microsoft.com/library/psdk/shellcc/shell/Functions/ShellExecuteEx.htm

'used for shelling out to the default web browser

Private Declare Function ShellExecute Lib "shell32.dll" Alias "ShellExecuteA" (ByVal hwnd As Long, ByVal lpOperation As String, ByVal lpFile As String, ByVal lpParameters As String, ByVal lpDirectory As String, ByVal nShowCmd As Long) As Long
Const SW_HIDE = 0, SW_SHOWNORMAL = 1, SW_SHOWMINIMIZED = 2
Const SW_SHOWMAXIMIZED = 3, SW_SHOWNOACTIVATE = 4, SW_SHOW = 5
Const SW_MINIMIZE = 6, SW_SHOWMINNOACTIVE = 7, SW_SHOWNA = 8
Const SW_SHOWDEFAULT = 10

Const ERROR_FILE_NOT_FOUND = 2&
Const ERROR_PATH_NOT_FOUND = 3&
Const SE_ERR_ACCESSDENIED = 5&
Const ERROR_BAD_FORMAT = 11&
Const SE_ERR_SHARE = 26&
Const SE_ERR_ASSOCINCOMPLETE = 27&
Const SE_ERR_NOASSOC = 31&

Private Type OPENFILENAME
    lStructSize As Long
    hwndOwner As Long
    hInstance As Long
    lpstrFilter As String
    lpstrCustomFilter As String
    nMaxCustFilter As Long
    nFilterIndex As Long
    lpstrFile As String
    nMaxFile As Long
    lpstrFileTitle As String
    nMaxFileTitle As Long
    lpstrInitialDir As String
    lpstrTitle As String
    flags As Long
    nFileOffset As Integer
    nFileExtension As Integer
    lpstrDefExt As String
    lCustData As Long
    lpfnHook As Long
    lpTemplateName As String
End Type
'http://www.vbcode.com/asp/showsn.asp?theID=1401

Private Declare Function GetOpenFileName Lib "comdlg32.dll" Alias "GetOpenFileNameA" (pOpenfilename As OPENFILENAME) As Long
Const OFNHideReadOnly = 4, OFNFileMustExist = 4096

Dim ofn As OPENFILENAME

Private Sub Form_Load()
    cboAddress.ListIndex = 0
    cboDisplay.ListIndex = 1
    cboAction.ListIndex = 0
End Sub

Private Sub cmdDoAction_Click()
    Dim Count As Integer
    Dim Result As Long, ResultMsg As String
    Dim Params As String, Path As String, Adr As String

    If Len(txtParams.Text) Then Params = txtParams.Text Else Params = vbNullString
    If Len(txtPath.Text) Then Path = txtPath.Text & vbNullChar Else Path = vbNullString
    Adr = cboAddress.Text
    'path does not work correctly??

    Result = ShellExecute(Me.hwnd, cboAction.Text, Adr, Params, Path, Val(cboDisplay.Text))
    If Result > 32 Then 'success
        Count = 0
        Do While Count < cboAddress.ListCount
            If cboAddress.List(Count) = Adr Then
                cboAddress.RemoveItem Count
            Else
                Count = Count + 1
            End If
        Loop
        If cboAddress.ListCount > 10 Then cboAddress.RemoveItem 0
        cboAddress.AddItem Adr
        'If cboAddress.ListCount Then
        cboAddress.ListIndex = cboAddress.ListCount - 1
    Else
        'I don't know if any of these are correct since I could not find
        'the constants for return codes. So these are my best guess.
        Select Case Result
        Case ERROR_FILE_NOT_FOUND: ResultMsg = "file not found"
        Case ERROR_PATH_NOT_FOUND: ResultMsg = "path not found"
        Case SE_ERR_ACCESSDENIED: ResultMsg = "access denied"
        Case ERROR_BAD_FORMAT: ResultMsg = "bad data format"
        Case SE_ERR_SHARE: ResultMsg = "sharing violation"
        Case SE_ERR_ASSOCINCOMPLETE: ResultMsg = "incomplete association"
        Case SE_ERR_NOASSOC: ResultMsg = "no association"
        Case Else: ResultMsg = "unknown"
        End Select
        MsgBox "That action could not be performed, error code: " & Result & " (" & ResultMsg & ")"
    End If
End Sub

Private Sub cmdBrowse_Click()
    Dim Result As Long

    ofn.lStructSize = Len(ofn)
    ofn.hwndOwner = Me.hwnd
    ofn.hInstance = App.hInstance
    ofn.lpstrFilter = "All Files (*.*)" + vbNullChar + "*.*" + vbNullChar _
                    + "Executables (*.exe)" + vbNullChar + "*.exe" + vbNullChar _
                    + "Hypertext Documents (*.htm)" + vbNullChar + "*.htm;*.html" + vbNullChar _
                    + "Text Files (*.txt)" + vbNullChar + "*.txt" + vbNullChar _
                    + "Rich Text Files (*.rtf)" + vbNullChar + "*.rtf" + vbNullChar
    ofn.lpstrFile = Space$(254)
    ofn.nMaxFile = 255
    ofn.lpstrFileTitle = Space$(254)
    ofn.nMaxFileTitle = 255
    ofn.lpstrInitialDir = CurDir
    ofn.lpstrTitle = "Browse"
    ofn.flags = OFNHideReadOnly Or OFNFileMustExist

    If GetOpenFileName(ofn) Then cboAddress.Text = Trim$(ofn.lpstrFile)
End Sub

Private Sub Form_KeyPress(KeyAscii As Integer)
    If KeyAscii = vbKeyEscape Then Unload Me
End Sub
