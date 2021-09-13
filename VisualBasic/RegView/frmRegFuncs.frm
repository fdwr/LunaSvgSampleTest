VERSION 5.00
Begin VB.Form frmRegFuncs 
   BorderStyle     =   1  'Fixed Single
   Caption         =   "Registry Functions"
   ClientHeight    =   6105
   ClientLeft      =   45
   ClientTop       =   330
   ClientWidth     =   6480
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   6105
   ScaleWidth      =   6480
   StartUpPosition =   2  'CenterScreen
   Begin prjRegFuncs.ctlDataByteViewer ctlViewAscii 
      Height          =   2775
      Left            =   4560
      TabIndex        =   37
      Top             =   1200
      Width           =   1575
      _ExtentX        =   2778
      _ExtentY        =   4895
   End
   Begin VB.ComboBox cboHistory 
      Height          =   315
      ItemData        =   "frmRegFuncs.frx":0000
      Left            =   960
      List            =   "frmRegFuncs.frx":0002
      Style           =   2  'Dropdown List
      TabIndex        =   5
      Top             =   840
      Width           =   5415
   End
   Begin VB.ListBox lstValues 
      Height          =   1035
      ItemData        =   "frmRegFuncs.frx":0004
      Left            =   4560
      List            =   "frmRegFuncs.frx":0006
      TabIndex        =   32
      Top             =   4560
      Visible         =   0   'False
      Width           =   975
   End
   Begin VB.CommandButton cmdModify 
      Caption         =   "&Modify"
      Height          =   375
      Left            =   1920
      TabIndex        =   11
      ToolTipText     =   "Opens the selected key/value for editing."
      Top             =   4080
      Width           =   855
   End
   Begin VB.CheckBox chkStrikeOver 
      Caption         =   "Strk&Over"
      Height          =   375
      Left            =   5400
      Style           =   1  'Graphical
      TabIndex        =   15
      TabStop         =   0   'False
      ToolTipText     =   "Toggles between insert and strike over editing."
      Top             =   4080
      Width           =   855
   End
   Begin VB.TextBox txtName 
      Height          =   285
      Left            =   960
      TabIndex        =   17
      ToolTipText     =   "You you can enter a name for a new key, but Windows does allow you to change the name of an existing key."
      Top             =   4560
      Width           =   3495
   End
   Begin VB.ComboBox cboType 
      Height          =   315
      ItemData        =   "frmRegFuncs.frx":0008
      Left            =   960
      List            =   "frmRegFuncs.frx":0024
      TabIndex        =   21
      Top             =   5280
      Width           =   2055
   End
   Begin VB.TextBox txtViewAscii 
      BeginProperty Font 
         Name            =   "Terminal"
         Size            =   6
         Charset         =   255
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   2775
      HideSelection   =   0   'False
      Left            =   120
      Locked          =   -1  'True
      MultiLine       =   -1  'True
      TabIndex        =   7
      Top             =   1200
      Visible         =   0   'False
      Width           =   1575
   End
   Begin VB.CommandButton cmdGotoForward 
      Caption         =   ">"
      Height          =   315
      Left            =   5040
      TabIndex        =   2
      Top             =   120
      Width           =   375
   End
   Begin VB.CommandButton cmdGotoBack 
      Caption         =   "<"
      Height          =   315
      Left            =   4680
      TabIndex        =   1
      Top             =   120
      Width           =   375
   End
   Begin VB.CommandButton cmdGoto 
      Caption         =   "&Goto"
      Height          =   315
      Left            =   5520
      TabIndex        =   3
      Top             =   120
      Width           =   855
   End
   Begin VB.TextBox txtValue 
      Height          =   285
      Left            =   960
      TabIndex        =   19
      Top             =   4920
      Width           =   3495
   End
   Begin VB.TextBox txtViewHex 
      BeginProperty Font 
         Name            =   "Terminal"
         Size            =   6
         Charset         =   255
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   2775
      HideSelection   =   0   'False
      Left            =   1800
      Locked          =   -1  'True
      MultiLine       =   -1  'True
      ScrollBars      =   2  'Vertical
      TabIndex        =   8
      Top             =   1200
      Visible         =   0   'False
      Width           =   4575
   End
   Begin VB.ListBox lstKeys 
      Height          =   2790
      Left            =   120
      TabIndex        =   6
      Top             =   1200
      Visible         =   0   'False
      Width           =   6255
   End
   Begin VB.ComboBox cboHiveKey 
      Height          =   315
      ItemData        =   "frmRegFuncs.frx":00B3
      Left            =   960
      List            =   "frmRegFuncs.frx":00CC
      TabIndex        =   0
      Top             =   120
      Width           =   3255
   End
   Begin VB.TextBox txtPath 
      Height          =   285
      Left            =   960
      TabIndex        =   4
      Text            =   "Software\Microsoft\Windows\CurrentVersion"
      Top             =   480
      Width           =   5415
   End
   Begin VB.OptionButton optList 
      Caption         =   "&List"
      Height          =   375
      Left            =   120
      Style           =   1  'Graphical
      TabIndex        =   9
      ToolTipText     =   "Switches to list view, showing the registry keys/values."
      Top             =   4080
      Width           =   855
   End
   Begin VB.OptionButton optEdit 
      Caption         =   "&Edit"
      Height          =   375
      Left            =   960
      Style           =   1  'Graphical
      TabIndex        =   10
      ToolTipText     =   "Switches to edit view, showing the key values in both ASCII and hexadecimal."
      Top             =   4080
      Width           =   855
   End
   Begin VB.CommandButton cmdSave 
      Caption         =   "&Save"
      Enabled         =   0   'False
      Height          =   375
      Left            =   1920
      TabIndex        =   29
      ToolTipText     =   "Stores any changes you made to the key/value back into the registry."
      Top             =   4080
      Width           =   855
   End
   Begin VB.CommandButton cmdCreateValue 
      Caption         =   "&Create"
      Enabled         =   0   'False
      Height          =   375
      Left            =   2760
      TabIndex        =   12
      TabStop         =   0   'False
      ToolTipText     =   "Creates a new value with the given name."
      Top             =   4080
      Width           =   855
   End
   Begin VB.CommandButton cmdDelete 
      Caption         =   "&Delete"
      Enabled         =   0   'False
      Height          =   375
      Left            =   4440
      TabIndex        =   14
      TabStop         =   0   'False
      ToolTipText     =   "Deletes the selected key or value"
      Top             =   4080
      Width           =   855
   End
   Begin VB.CommandButton cmdCreateKey 
      Caption         =   "New &Key"
      Enabled         =   0   'False
      Height          =   375
      Left            =   3600
      TabIndex        =   13
      TabStop         =   0   'False
      ToolTipText     =   "Creates a new key with the given name and value."
      Top             =   4080
      Width           =   855
   End
   Begin VB.CommandButton cmdGotoUp 
      Caption         =   "/\"
      Height          =   315
      Left            =   4320
      TabIndex        =   36
      Top             =   120
      Width           =   375
   End
   Begin VB.Label lblSize 
      BorderStyle     =   1  'Fixed Single
      Height          =   255
      Left            =   3720
      TabIndex        =   35
      Top             =   5280
      Width           =   735
   End
   Begin VB.Label Label10 
      Alignment       =   1  'Right Justify
      Caption         =   "History:"
      Height          =   255
      Left            =   120
      TabIndex        =   34
      Top             =   840
      Width           =   735
   End
   Begin VB.Label Label9 
      Alignment       =   1  'Right Justify
      Caption         =   "Size:"
      Height          =   255
      Left            =   3120
      TabIndex        =   33
      Top             =   5280
      Width           =   495
   End
   Begin VB.Label lblValueData 
      Height          =   255
      Left            =   5520
      TabIndex        =   27
      Top             =   5280
      Width           =   735
   End
   Begin VB.Label Label7 
      Alignment       =   1  'Right Justify
      Caption         =   "Date:"
      Height          =   255
      Left            =   4680
      TabIndex        =   26
      Top             =   5280
      Width           =   735
   End
   Begin VB.Label Label8 
      Alignment       =   1  'Right Justify
      Caption         =   "&Name:"
      Height          =   255
      Left            =   120
      TabIndex        =   16
      Top             =   4560
      Width           =   735
   End
   Begin VB.Label lblStatus 
      BorderStyle     =   1  'Fixed Single
      Height          =   315
      Left            =   120
      TabIndex        =   28
      Top             =   5700
      Width           =   6255
   End
   Begin VB.Label lblTotalValues 
      Height          =   255
      Left            =   5520
      TabIndex        =   25
      Top             =   4920
      Width           =   735
   End
   Begin VB.Label lblTotalKeys 
      Height          =   255
      Left            =   5520
      TabIndex        =   23
      Top             =   4560
      Width           =   735
   End
   Begin VB.Label Label6 
      Alignment       =   1  'Right Justify
      Caption         =   "&Type:"
      Height          =   255
      Left            =   120
      TabIndex        =   20
      Top             =   5280
      Width           =   735
   End
   Begin VB.Label Label5 
      Alignment       =   1  'Right Justify
      Caption         =   "Values:"
      Height          =   255
      Left            =   4680
      TabIndex        =   24
      Top             =   4920
      Width           =   735
   End
   Begin VB.Label Label4 
      Alignment       =   1  'Right Justify
      Caption         =   "Subkeys:"
      Height          =   255
      Left            =   4680
      TabIndex        =   22
      Top             =   4560
      Width           =   735
   End
   Begin VB.Label Label3 
      Alignment       =   1  'Right Justify
      Caption         =   "&Value:"
      Height          =   255
      Left            =   120
      TabIndex        =   18
      Top             =   4920
      Width           =   735
   End
   Begin VB.Label Label2 
      Alignment       =   1  'Right Justify
      Caption         =   "&Path:"
      Height          =   255
      Left            =   120
      TabIndex        =   31
      Top             =   480
      Width           =   735
   End
   Begin VB.Label Label1 
      Alignment       =   1  'Right Justify
      Caption         =   "&Hive Key:"
      Height          =   255
      Left            =   120
      TabIndex        =   30
      Top             =   120
      Width           =   735
   End
End
Attribute VB_Name = "frmRegFuncs"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit
Option Base 0
Option Compare Binary

Private Declare Sub CopyMemory Lib "Kernel32" Alias "RtlMoveMemory" _
  (xdest As Any, xsource As Any, ByVal xsize As Long)
Private Declare Function SendMessage Lib _
  "user32" Alias "SendMessageA" (ByVal hWnd _
  As Long, ByVal wMsg As Integer, ByVal _
  wParam As Integer, lParam As Any) As Long

Const LB_FINDSTRING = &H18F

Public oRegFuncs As RegistryAccess, hKey As Long
Public CurRegHive As String, CurRegPath As String
Public ValueSelStart As Long, ValueSelLength As Long
Private RegData(32767) As Byte, RegDataLen As Long

Private Sub cboHistory_Click()
    txtPath.Text = cboHistory.Text
End Sub

Private Sub cboHistory_GotFocus()
    'SelectModifySave False
    cmdGoto.Default = True
End Sub

Private Sub cmdGoto_Click()
    optList.Value = True
    ReadKeyList
    'cboHistory.AddItem FormatRegPath
    'cboHistory.ListIndex = cboHistory.ListCount - 1
End Sub

Private Sub cmdModify_Click()
    Dim Text As String

    'transfer values
    If Left(lstKeys.Text, 2) = "> " Then
        txtName.Text = Mid(lstKeys.Text, 3)
    Else
        txtName.Text = Mid(lstKeys.Text, 4)
    End If
    'oRegFuncs.GetKeyValue Val(CurRegHive), CurRegPath & txtName.Text, Text
    txtViewAscii.Text = lstValues.List(lstKeys.ListIndex)
    
    optEdit.Value = True
End Sub

Private Sub cmdSave_Click()
    'write values back into registry
    optList.Value = True
End Sub

Private Sub optType_GotFocus()
    SelectModifySave True
End Sub

Private Sub optHashKey_GotFocus()
    cmdGoto.Default = True
End Sub

Private Sub Form_Load()
    cboHiveKey.ListIndex = rgLocalMachine And 255
    Set oRegFuncs = New RegistryAccess

    Show
    cmdGoto_Click
    'ctlViewAscii.SetDataSource RegData
End Sub

Private Sub Form_Unload(Cancel As Integer)
Set frmRegFuncs = Nothing
End Sub

Private Sub lstKeys_Click()
    Dim NewKey As String
    If Left(lstKeys.Text, 2) = "> " Then
        NewKey = Mid(lstKeys.Text, 3)
        cmdGoto.Default = True
    Else
        NewKey = Mid(lstKeys.Text, 4)
        cmdModify.Default = True
    End If
    ChangeKeyPath NewKey
    GetListValue lstKeys.ListIndex
End Sub

Private Sub lstKeys_DblClick()
    'display key's value
    txtPath.Text = CurRegPath
    cboHiveKey.Text = CurRegHive
    lstKeys_Click
    If Left(lstKeys.Text, 2) = "> " Then
        cmdGoto_Click
    Else
        cmdModify_Click
    End If
End Sub

Private Sub lstKeys_GotFocus()
    lstKeys_Click
End Sub

Private Sub optEdit_Click()
    lstKeys.Visible = False
    txtViewAscii.Visible = True
    txtViewHex.Visible = True
    txtViewAscii.SetFocus
    cmdModify.Visible = False
    cmdSave.Visible = True
End Sub

Private Sub optList_Click()
    lstKeys.Visible = True
    txtViewAscii.Visible = False
    txtViewHex.Visible = False
    lstKeys.SetFocus
    cmdModify.Visible = True
    cmdSave.Visible = False
End Sub

Private Sub txtName_GotFocus()
    SelectModifySave True
End Sub

Private Sub txtPath_GotFocus()
    cmdGoto.Default = True
End Sub

Private Sub txtValue_GotFocus()
    SelectModifySave True
End Sub

Private Sub txtViewAscii_GotFocus()
    SelectModifySave True
End Sub

Private Sub txtViewAscii_KeyPress(KeyAscii As Integer)
    'test
    Dim CurPos As Long
    CurPos = txtViewAscii.SelStart

    txtViewAscii.SelStart = CurPos
    txtViewHex.SelStart = CurPos * 3
    If CurPos >= Len(txtViewAscii.Text) Then
        If CurPos >= 32768 Then Exit Sub
        RegData(RegDataLen) = KeyAscii
        RegDataLen = RegDataLen + 1
        txtViewAscii.SelLength = 0
        txtViewAscii.SelLength = 0
    ElseIf chkStrikeOver.Value Then
        RegData(CurPos) = KeyAscii
        txtViewAscii.SelLength = 1
        txtViewHex.SelLength = 3
    Else
        Call CopyMemory(RegData(CurPos), RegData(CurPos) + 1, 32768 - CurPos)
        RegData(CurPos) = KeyAscii
        txtViewAscii.SelLength = 0
        txtViewHex.SelLength = 0
    End If
    txtViewAscii.SelText = Chr(KeyAscii)
    txtViewHex.SelText = Right("0" & Hex(KeyAscii) & " ", 3)
End Sub

Private Sub AddByte(KeyAscii As Integer, CurPos As Integer)



End Sub

Private Sub txtViewAscii_MouseUp(Button As Integer, Shift As Integer, X As Single, Y As Single)
'Select other edit window accordingly
    ValueSelStart = txtViewAscii.SelStart
    ValueSelLength = txtViewAscii.SelLength
    SelectValueRange
End Sub

Private Sub txtViewHex_GotFocus()
    SelectModifySave True
End Sub

Private Sub txtViewHex_KeyPress(KeyAscii As Integer)
    Dim lValue As Long

    Select Case KeyAscii
    Case 48 To 57: lValue = KeyAscii - 48
    Case 65 To 90: lValue = KeyAscii - 55
    Case 97 To 122: lValue = KeyAscii - 87
    End Select


End Sub

'Private Sub Form_Load()
'With List1
'  .Clear
'  .AddItem "CPU"
'  .AddItem "RAM"
'  .AddItem "ROM"
'  .AddItem "Cache"
'  .AddItem "Motherboard"
'  .AddItem "Hard Disk"
'  .AddItem "Floppy Disk"
'End With
'End Sub

Private Sub Text1_Change()
List1.ListIndex = SendMessage(List1.hWnd, _
LB_FINDSTRING, -1, ByVal Text1.Text)
Text1.Text = List1.Text
End Sub

Private Sub ReadKeyList()
    Dim sValue As String
    Dim vData As Variant
    Dim lType As Long
    Dim Count As Long

    lblStatus.Caption = "Reading key entries"
    If oRegFuncs.OpenKey(Val("&h0" & cboHiveKey.Text), txtPath.Text, True, hKey) Then
        lstKeys.Clear
        lstValues.Clear
        Count = 0
        Do While oRegFuncs.GetKeybyNumber(hKey, Count, sValue)
            lstKeys.AddItem "> " & sValue
            lstValues.AddItem ""
            Count = Count + 1
        Loop
        lblTotalKeys.Caption = CStr(Count)
        Count = 0
        Do While oRegFuncs.GetValueByNumber(hKey, Count, sValue, lType, vData)
            lstKeys.AddItem "   " & sValue
            AddListValue vData, lType, Len(vData)
            'If lType = rgStringZ Then
            '    lstValues.AddItem "String=" & vData
            'ElseIf lType = rgDWord Then
            '    lstValues.AddItem "Dword " & vData
            'ElseIf lType = rgBinary Then
            '    lstValues.AddItem "Binary Size=" & UBound(vData)
            'Else
            '    lstValues.AddItem "Type " & CStr(lType) & " Size=" & UBound(vData)
            'End If
            Count = Count + 1
        Loop
        Call oRegFuncs.CloseKey(hKey)
        lblTotalValues.Caption = CStr(Count)

        CurRegPath = txtPath.Text
        CurRegHive = cboHiveKey.Text
        If Right(CurRegPath, 1) = "\" Then CurRegPath = Left(CurRegPath, Len(CurRegPath) - 1)
        cboHistory.ToolTipText = CurRegPath

        lblStatus.Caption = "List read, with " & (Val(lblTotalKeys.Caption) + Count) & " total entries"
        'txtValue.Text = lstValues.List(lstKeys.ListIndex)
    Else
        lblStatus.Caption = "Unable to open key: " & oRegFuncs.LastErrorSource & ":" & CStr(oRegFuncs.LastErrorNumber)
    End If
End Sub

Private Sub SelectModifySave(Mode As Boolean)
    If Mode And optEdit.Value = True Then
        cmdSave.Visible = True
        cmdModify.Visible = False
        cmdSave.Default = True
    Else
        cmdModify.Visible = True
        cmdSave.Visible = False
        cmdModify.Default = True
    End If
End Sub

Private Sub ChangeKeyPath(NewKey As String)
    'Dim CurPath As String, SlashPos As Integer
    'CurPath = txtPath.Text
    'SlashPos = InStrRev(CurPath, "\")
    'If SlashPos > 0 Then
    '    CurPath = Left(CurPath, SlashPos) & NewKey
    'Else
    '    CurPath = NewKey
    'End If
    If cboHiveKey.Text <> CurRegHive Then
        cboHiveKey.Text = CurRegHive
    End If
    If Len(CurRegPath) > 0 Then
        txtPath.Text = CurRegPath & "\" & NewKey
    Else
        txtPath.Text = NewKey
    End If
End Sub

Private Sub AddListValue(vData As Variant, lType As Long, lSize As Long)
    lstValues.AddItem lType & "," & lSize & "," & vData
End Sub

Private Sub GetListValue(lListIndex)
    Dim lCount As Long, sValues As String

    sValues = lstValues.List(lListIndex)
    lCount = Val(sValues)
    If lCount < cboType.ListCount Then cboType.ListIndex = lCount

    lCount = InStr(sValues, ",") + 1
    If lCount <= 1 Then
        lblSize.Caption = "(none)"
    Else
        lblSize.Caption = Val(Mid(sValues, lCount))
    End If

    lCount = InStr(lCount, sValues, ",") + 1
    If lCount <= 1 Then
        txtValue.Text = ""
    Else
        txtValue.Text = Mid(sValues, lCount)
    End If
End Sub

Private Sub SelectValueRange()
    If ValueSelStart * 3 <> txtViewHex.SelStart _
      Or ValueSelLength * 3 <> txtViewHex.SelLength Then
        txtViewHex.SelStart = ValueSelStart * 3
        txtViewHex.SelLength = ValueSelLength * 3
    End If
    If ValueSelStart <> txtViewAscii.SelStart _
      Or ValueSelLength <> txtViewAscii.SelLength Then
        txtViewAscii.SelStart = ValueSelStart
        txtViewAscii.SelLength = ValueSelLength
    End If
End Sub

Private Sub txtViewHex_MouseUp(Button As Integer, Shift As Integer, X As Single, Y As Single)
'Select other edit window accordingly
    ValueSelStart = txtViewHex.SelStart \ 3
    ValueSelLength = (txtViewHex.SelStart + txtViewHex.SelLength + 2) \ 3
    SelectValueRange
End Sub



'Private Declare Function SendMessage Lib _
'    "user32" Alias "SendMessageA" (ByVal hWnd As _
'    Long, ByVal wMsg As Long, ByVal wParam As _
'    Long, lParam As Any) As Long
Private Const LB_SETTABSTOPS = &H192

Public Sub SetListTabStops(ListHandle As Long, _
    ParamArray ParmList() As Variant)
    Dim i As Long
    Dim ListTabs() As Long
    Dim NumColumns As Long

    ReDim ListTabs(UBound(ParmList))
    For i = 0 To UBound(ParmList)
        ListTabs(i) = ParmList(i)
    Next i
    NumColumns = UBound(ParmList) + 1

    Call SendMessage(ListHandle, LB_SETTABSTOPS, _
        NumColumns, ListTabs(0))
End Sub

Call the routine in Form_Load to set the tab stops where MyListBox is the listbox and the tab stop will be around the 12th character. Generally speaking, TabStop divided by four equals roughly the number of characters per column:

Call SetListTabStops(lstMyListBox.hWnd, 48)
If more columns are needed, simply add them to the function call:

Call SetListTabStops(lstMyListBox.hWnd, 48, 74, _
    100)
Add items to the listbox using vbTab to separate columns:

lstMyListBox.AddItem "Column1" & vbTab & "Column2"
 



