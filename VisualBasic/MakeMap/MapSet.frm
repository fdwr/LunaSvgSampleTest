VERSION 5.00
Begin VB.Form frmMapSet 
   AutoRedraw      =   -1  'True
   Caption         =   "Map Set Maker"
   ClientHeight    =   5910
   ClientLeft      =   60
   ClientTop       =   630
   ClientWidth     =   10125
   ClipControls    =   0   'False
   Icon            =   "MapSet.frx":0000
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   ScaleHeight     =   5910
   ScaleWidth      =   10125
   StartUpPosition =   2  'CenterScreen
   Begin VB.ComboBox cboSelectField 
      BackColor       =   &H80000016&
      Height          =   315
      ItemData        =   "MapSet.frx":000C
      Left            =   120
      List            =   "MapSet.frx":000E
      Style           =   2  'Dropdown List
      TabIndex        =   15
      ToolTipText     =   "Map selected in mapset"
      Top             =   5040
      Visible         =   0   'False
      Width           =   1335
   End
   Begin VB.TextBox txtMap 
      BackColor       =   &H80000016&
      BeginProperty Font 
         Name            =   "Terminal"
         Size            =   6
         Charset         =   255
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   5295
      HideSelection   =   0   'False
      Left            =   1560
      MultiLine       =   -1  'True
      ScrollBars      =   2  'Vertical
      TabIndex        =   14
      Top             =   480
      Visible         =   0   'False
      Width           =   6855
   End
   Begin VB.VScrollBar VScroll1 
      Height          =   285
      Left            =   1200
      TabIndex        =   1
      Top             =   120
      Width           =   255
   End
   Begin VB.TextBox txtOrder 
      BackColor       =   &H80000016&
      Height          =   285
      Left            =   120
      TabIndex        =   0
      Top             =   120
      Width           =   1095
   End
   Begin VB.Timer Timer1 
      Enabled         =   0   'False
      Interval        =   200
      Left            =   0
      Top             =   3600
   End
   Begin VB.TextBox txtName 
      BackColor       =   &H80000016&
      Height          =   285
      Left            =   1560
      MaxLength       =   7
      TabIndex        =   2
      ToolTipText     =   "Field text"
      Top             =   120
      Width           =   975
   End
   Begin VB.TextBox txtLabel 
      BackColor       =   &H80000016&
      Height          =   285
      Left            =   2640
      TabIndex        =   3
      ToolTipText     =   "Field text"
      Top             =   120
      Width           =   7335
   End
   Begin VB.ListBox lstExtAttributes 
      BackColor       =   &H80000016&
      Height          =   735
      ItemData        =   "MapSet.frx":0010
      Left            =   120
      List            =   "MapSet.frx":001D
      Style           =   1  'Checkbox
      TabIndex        =   8
      ToolTipText     =   "Field(s) extended attributes"
      Top             =   3480
      Width           =   1335
   End
   Begin VB.TextBox txtLength 
      BackColor       =   &H80000016&
      Height          =   285
      Left            =   1080
      MaxLength       =   3
      TabIndex        =   6
      ToolTipText     =   "Length"
      Top             =   480
      Width           =   375
   End
   Begin VB.TextBox txtColumn 
      BackColor       =   &H80000016&
      Height          =   285
      Left            =   600
      Locked          =   -1  'True
      TabIndex        =   5
      ToolTipText     =   "Column"
      Top             =   480
      Width           =   375
   End
   Begin VB.TextBox txtRow 
      BackColor       =   &H80000016&
      Height          =   285
      Left            =   120
      Locked          =   -1  'True
      TabIndex        =   4
      ToolTipText     =   "Row"
      Top             =   480
      Width           =   375
   End
   Begin VB.ListBox lstAttributes 
      BackColor       =   &H80000016&
      Height          =   2535
      ItemData        =   "MapSet.frx":003F
      Left            =   120
      List            =   "MapSet.frx":0064
      Style           =   1  'Checkbox
      TabIndex        =   7
      ToolTipText     =   "Field(s) attributes - PROT UNPROT ASKIP NUM NORM BRT DRK FSET IC"
      Top             =   840
      Width           =   1335
   End
   Begin VB.ComboBox cboColor 
      BackColor       =   &H80000016&
      Height          =   315
      ItemData        =   "MapSet.frx":00D1
      Left            =   120
      List            =   "MapSet.frx":00ED
      TabIndex        =   9
      ToolTipText     =   "Field(s) color"
      Top             =   4320
      Width           =   1335
   End
   Begin VB.ComboBox cboMapSelected 
      BackColor       =   &H80000016&
      Height          =   315
      ItemData        =   "MapSet.frx":012E
      Left            =   120
      List            =   "MapSet.frx":013E
      Style           =   2  'Dropdown List
      TabIndex        =   10
      ToolTipText     =   "Map selected in mapset"
      Top             =   4680
      Width           =   1335
   End
   Begin VB.PictureBox picMap 
      BackColor       =   &H00000000&
      BeginProperty Font 
         Name            =   "Courier New"
         Size            =   8.25
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00FF0000&
      Height          =   5355
      Left            =   1560
      ScaleHeight     =   353
      ScaleMode       =   3  'Pixel
      ScaleWidth      =   561
      TabIndex        =   11
      Top             =   480
      Width           =   8475
   End
   Begin VB.Label Label2 
      Caption         =   "      x"
      Height          =   255
      Left            =   720
      TabIndex        =   13
      Top             =   480
      Width           =   375
   End
   Begin VB.Label Label1 
      Caption         =   " :"
      Height          =   255
      Left            =   480
      TabIndex        =   12
      Top             =   480
      Width           =   135
   End
   Begin VB.Menu mnuFile 
      Caption         =   "&File"
      Begin VB.Menu mnuLoad 
         Caption         =   "&Load"
      End
      Begin VB.Menu mnuSave 
         Caption         =   "&Save"
      End
      Begin VB.Menu munExport 
         Caption         =   "&Export"
      End
      Begin VB.Menu mnu0 
         Caption         =   "-"
      End
      Begin VB.Menu mnuExit 
         Caption         =   "E&xit"
      End
   End
   Begin VB.Menu mnuMap 
      Caption         =   "&Map"
      Begin VB.Menu mnuDelMap 
         Caption         =   "&Delete map"
      End
      Begin VB.Menu mnuInsMap 
         Caption         =   "&Insert map"
      End
      Begin VB.Menu mnu2 
         Caption         =   "-"
      End
      Begin VB.Menu mnuSetSort 
         Caption         =   "Leave &unsorted"
         Index           =   0
      End
      Begin VB.Menu mnuSetSort 
         Caption         =   "Sort by &position"
         Checked         =   -1  'True
         Index           =   1
      End
   End
   Begin VB.Menu mnuSwitchMode 
      Caption         =   "&Edit text"
   End
   Begin VB.Menu mnuInsert 
      Caption         =   "Insert"
   End
   Begin VB.Menu mnuDelete 
      Caption         =   "Delete"
   End
   Begin VB.Menu mnuAbout 
      Caption         =   "&About"
   End
   Begin VB.Menu mnuFieldOptions 
      Caption         =   ""
      Visible         =   0   'False
      Begin VB.Menu mnuPmInsert 
         Caption         =   "&Insert"
      End
      Begin VB.Menu mnuPmDelete 
         Caption         =   "&Delete"
      End
      Begin VB.Menu mnuSelectAll 
         Caption         =   "Select &All"
      End
      Begin VB.Menu mnu1 
         Caption         =   "-"
      End
      Begin VB.Menu mnuColors 
         Caption         =   "&Color"
         Begin VB.Menu mnuColor 
            Caption         =   "(default)"
            Index           =   0
         End
         Begin VB.Menu mnuColor 
            Caption         =   "Blue"
            Index           =   1
         End
         Begin VB.Menu mnuColor 
            Caption         =   "Red"
            Index           =   2
         End
         Begin VB.Menu mnuColor 
            Caption         =   "Pink"
            Index           =   3
         End
         Begin VB.Menu mnuColor 
            Caption         =   "Green"
            Index           =   4
         End
         Begin VB.Menu mnuColor 
            Caption         =   "Turquoise"
            Index           =   5
         End
         Begin VB.Menu mnuColor 
            Caption         =   "Yellow"
            Index           =   6
         End
         Begin VB.Menu mnuColor 
            Caption         =   "White"
            Index           =   7
         End
      End
   End
End
Attribute VB_Name = "frmMapSet"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Const MaxFields = 100
Const MapFileName = "c:\temp\vids3d"
Const MapFileNameO = "c:\temp\vids3d.tmp"

Dim Fields(MaxFields - 1) As FieldInfo

Dim SelectedField As Long
Dim SelectedMap As Long
Dim TotalFields As Long
Dim AttributeByte As Long
Dim FieldColor As Long
Dim FieldGrabbed As Long
Dim GrabRow As Long
Dim GrabCol As Long
Dim MapHasFocus As Boolean
Dim MultiplesSelected As Boolean
Dim MapChanged As Boolean
Dim PreventCascade As Boolean
Dim SortMode As Long

'Dim MapCharHeight As Long, MapCharWidth As Long
Const MapCharHeight = 14, MapCharWidth = 7
Const FieldWidth = 80, FieldHeight = 24

Dim MapRedrawTop As Long, MapRedrawBtm As Long
Dim MapRedrawLeft As Long, MapRedrawRight As Long
Dim MapRedrawBg As Boolean, MapRedrawRect As RECT

'Dim MapFileName As String
Dim MapsetName As String
Dim MapSetText As String 'text of entire mapset

Private Sub Form_Load()
    'AddField "Fresno               CA 93222", 9, 31, 0

    PreventCascade = True
    cboColor.ListIndex = 0
    PreventCascade = False

    MapSetText = _
    "         PRINT NOGEN" & vbCrLf & _
    "VIDS3D   DFHMSD TYPE=&SYSPARM,                                         -" & vbCrLf & _
    "               LANG=COBOL,                                             -" & vbCrLf & _
    "               MODE=INOUT,                                             -" & vbCrLf & _
    "               TERM=3270-2,                                            -" & vbCrLf & _
    "               CTRL=FREEKB,                                            -" & vbCrLf & _
    "               STORAGE=AUTO,                                           -" & vbCrLf & _
    "               DSATTS=(COLOR,HILIGHT),                                 -" & vbCrLf & _
    "               MAPATTS=(COLOR,HILIGHT),                                -" & vbCrLf & _
    "               TIOAPFX = YES" & vbCrLf & _
    "***********************************************************************" & vbCrLf & _
    "VIDS3M1  DFHMDI SIZE=(24,80),                                          -" & vbCrLf & _
    "               LINE=1,                                                 -" & vbCrLf & _
    "               COLUMN=1" & vbCrLf & _
    "***********************************************************************"
    FieldGrabbed = -1
    RedrawSection 0, 25, 0, 80
    'RedrawMap
End Sub

Private Sub cboMapSelected_Click()
    If cboMapSelected.ListIndex = SelectedMap Then Exit Sub
    SelectedMap = cboMapSelected.ListIndex
    RedrawSection 0, 25, 0, 80
    RedrawMap
End Sub

Private Sub cboFieldSelected_Change()
    'select new field
End Sub

Private Sub AddField(Label As String, Top As Long, Left As Long, Map As Long)
    Fields(TotalFields).Label = Label
    Fields(TotalFields).Top = Top
    Fields(TotalFields).Left = Left
    Fields(TotalFields).Length = Len(Label)
    Fields(TotalFields).Map = Map
    Fields(TotalFields).Kind = FkField
    'get text from attributes

    'cboFieldSelected.AddItem Label
    TotalFields = TotalFields + 1
    MapChanged = True
End Sub

Private Sub cboColor_Click()
    Dim count As Long

    If PreventCascade Then Exit Sub
    If MultiplesSelected Then
        For count = 0 To TotalFields - 1
            If Fields(count).Selected Then
                Fields(count).Color = cboColor.ListIndex
                Fields(count).Redraw = True
            End If
        Next
        RedrawMap
    ElseIf SelectedField < TotalFields Then
        If Fields(SelectedField).Selected Then
            Fields(SelectedField).Color = cboColor.ListIndex
            Fields(SelectedField).Redraw = True
            'RedrawField SelectedField
            MapRedrawBg = True
            RedrawMap
        End If
    End If
    MapChanged = True
End Sub

Private Sub cboColor_KeyPress(KeyAscii As Integer)
    Dim count As Long, Text As String, TextLen As Long
    
    FindComboEntry cboColor, KeyAscii
    Exit Sub

    'if keypress was letter, look through list for match
    'ignore key if control or not alphabetic
    If KeyAscii >= 65 Then
        cboColor.SelText = Chr(KeyAscii)
        Text = LCase(cboColor.Text)
        TextLen = Len(Text)
        For count = 0 To cboColor.ListCount - 1
            If LCase(Left(cboColor.List(count), TextLen)) = Text Then
                cboColor.ListIndex = count
                cboColor.SelStart = TextLen
                cboColor.SelLength = 10000
            End If
        Next
        KeyAscii = 0
    End If
End Sub

Private Sub lstAttributes_ItemCheck(Item As Integer)
    Dim count As Long
    Static Ignore As Boolean

    If PreventCascade Or Ignore Then Exit Sub
    Ignore = True

    If picMap.Visible Then
    
        Select Case Item
        Case 0: lstAttributes.Selected(1) = Not lstAttributes.Selected(0)
        Case 1: lstAttributes.Selected(0) = Not lstAttributes.Selected(1)
        Case 2: lstAttributes.Selected(3) = Not lstAttributes.Selected(2)
        Case 3: lstAttributes.Selected(2) = Not lstAttributes.Selected(3)
        Case 4: lstAttributes.Selected(5) = Not lstAttributes.Selected(4)
        Case 5: lstAttributes.Selected(4) = Not lstAttributes.Selected(5)
        Case 6, 7, 8
            With lstAttributes
                .Selected(6) = Item = 6
                .Selected(7) = Item = 7
                .Selected(8) = Item = 8
            End With
        End Select
        
        AttributeByte = 0
        With lstAttributes
            If .Selected(1) Then AttributeByte = AttributeByte Or FaProtected
            If .Selected(3) Then AttributeByte = AttributeByte Or FaSkip
            If .Selected(5) Then AttributeByte = AttributeByte Or FaNumeric
            If .Selected(7) Then AttributeByte = AttributeByte Or FaBright
            If .Selected(8) Then AttributeByte = AttributeByte Or FaNoDisplay
            If .Selected(9) Then AttributeByte = AttributeByte Or FaModified
            If .Selected(10) Then AttributeByte = AttributeByte Or FaCursor
        End With
        For count = 0 To TotalFields - 1
            If Fields(count).Selected Then
                Fields(count).Attributes = AttributeByte
            End If
        Next
    Else
    End If
    MapChanged = True

    Ignore = False
End Sub

'Reads settings from the field array into the GUI items
Public Sub GetFieldSettings()

End Sub

'Sets settings from the GUI items into the array
Public Sub SetFieldSettings()

End Sub

Public Sub StoreFieldSettings()

End Sub

Public Sub LoadFieldSettings()

End Sub

Private Sub lstAttributes_MouseMove(Button As Integer, Shift As Integer, X As Single, Y As Single)
    lstAttributes.SetFocus
End Sub

Private Sub lstExtAttributes_MouseMove(Button As Integer, Shift As Integer, X As Single, Y As Single)
    lstExtAttributes.SetFocus
End Sub

Private Sub mnuAbout_Click()
    'MsgBox "Map Set Maker" & vbNewLine & "by Dwayne Robinson" & vbNewLine & "2000.11.15", vbInformation
    ParseTextToFields
End Sub

Private Sub mnuDelMap_Click()
' if in map view mode
'   search through all the fields for ones that are in the current map
'   find the next available map
'   remove map name from Combo
'   completely redraw
' else if in text mode
'   find map cursor is currently in
'   delete from start of map to end of map
' endif
    Dim count As Long, ShiftCount As Long

    ShiftCount = 0
    For count = 0 To TotalFields - 1
        If Fields(count).Map = SelectedMap Then
            TotalFields = TotalFields - 1
        Else
            Fields(ShiftCount) = Fields(count)
            'If Fields(ShiftCount).Map > SelectedMap Then
            '    Fields(ShiftCount).Map = Fields(ShiftCount).Map - 1
            'End If
            ShiftCount = ShiftCount + 1
        End If
    Next
    For count = 0 To cboMapSelected.ListCount
        If cboMapSelected.ItemData(count) = SelectedMap Then
            cboMapSelected.RemoveItem SelectedMap
            Exit For
        End If
    Next
    count = 0
    Do While count < cboSelectField.ListCount
        If cboSelectField.ItemData(count) = SelectedMap Then
            cboSelectField.RemoveItem SelectedMap
        Else
            count = count + 1
        End If
    Loop
    If cboMapSelected.ListCount <= 1 Then cboMapSelected.AddItem "Map " & SelectedMap

    MultiplesSelected = False
    MapChanged = True
    RedrawSection 0, 25, 0, 80
    RedrawMap
End Sub

Private Sub mnuInsMap_Click()
    Dim NewMap As Long, count As Long

    For count = 0 To TotalFields - 1
        If Fields(count).Map >= NewMap Then NewMap = Fields(count).Map
    Next
    SelectedMap = NewMap
    cboMapSelected.AddItem "Map " & (SelectedMap + 1)
    cboMapSelected.ItemData((cboMapSelected.NewIndex)) = SelectedMap
    cboMapSelected.ListIndex = cboMapSelected.NewIndex
End Sub

Private Sub mnuExit_Click()
    Unload Me
End Sub

Private Sub mnuColor_Click(Index As Integer)
    cboColor.ListIndex = Index
End Sub

Private Sub mnuDelete_Click()
    Dim count As Long, ShiftCount As Long

    ShiftCount = 0
    For count = 0 To TotalFields - 1
        If Fields(count).Selected Then
            TotalFields = TotalFields - 1
            RedrawField count
        Else
            Fields(ShiftCount) = Fields(count)
            ShiftCount = ShiftCount + 1
        End If
    Next
    'SelectField 0
    MapChanged = True
    MultiplesSelected = False
    RedrawMap
End Sub

Private Sub mnuInsert_Click()
    Dim count As Long, TopRow As Long, LeftCol As Long

    For count = 0 To TotalFields - 1
        If Fields(count).Selected And Fields(count).Map = SelectedMap Then Exit For
    Next
    If count >= TotalFields Then
        If TotalFields < MaxFields Then
            'Fields(TotalFields).Redraw = True
            'Fields(TotalFields).Selected = True
            AddField "New Field", 12, 34, SelectedMap
            SelectField TotalFields - 1, False
            'RedrawField TotalFields
            'TotalFields = TotalFields + 1
            MapChanged = True
        End If
    Else
        For count = count To TotalFields - 1
            If Fields(count).Selected Then
                If TotalFields >= MaxFields Then Exit For
                Fields(TotalFields) = Fields(count)
                TopRow = Fields(TotalFields).Top + 1
                If TopRow >= 24 Then TopRow = 23
                Fields(TotalFields).Top = TopRow
                LeftCol = Fields(TotalFields).Left + 1
                If LeftCol >= 80 Then LeftCol = 23
                Fields(TotalFields).Left = LeftCol
    
                Fields(count).Selected = False
                Fields(TotalFields).Selected = True
                Fields(TotalFields).Redraw = True
                RedrawField count
                SelectedField = TotalFields
                TotalFields = TotalFields + 1
            End If
        Next
        MapChanged = True
    End If
    RedrawMap
End Sub

Private Sub mnuPmDelete_Click()
    mnuDelete_Click
End Sub

Private Sub mnuPmInsert_Click()
    mnuInsert_Click
End Sub

Private Sub mnuLoad_Click()
    LoadMapSet
    PreventCascade = True
    txtMap.Text = MapSetText
    PreventCascade = False

    RedrawSection 0, 25, 0, 80
    RedrawMap
    'ParseTextToFields
End Sub

Private Sub mnuSave_Click()
    SaveMapSet
End Sub

Private Sub mnuSelectAll_Click()
    Dim count As Long

    For count = 0 To TotalFields - 1
        If Not Fields(count).Selected Then
        If Fields(count).Map = SelectedMap Then
        If Fields(count).Kind = FkField Then
                Fields(count).Selected = True
                Fields(count).Redraw = True
        End If
        End If
        End If
    Next
    MultiplesSelected = True
    RedrawMap
End Sub

Private Sub mnuSetSort_Click(Index As Integer)
    mnuSetSort(SortMode).Checked = False
    mnuSetSort(Index).Checked = True
    SortMode = Index
    If SortMode Then SortFields
End Sub

Private Sub mnuSwitchMode_Click()
    If picMap.Visible Then
        mnuSwitchMode.Caption = "&Edit map"
        If MapChanged Then
            ConcatFieldsToText
            txtMap.Text = MapSetText
            MapChanged = False
        End If
        lstAttributes.Enabled = False
        lstExtAttributes.Enabled = False
        picMap.Visible = False
        txtMap.Visible = True
        txtMap.SetFocus
    Else
        mnuSwitchMode.Caption = "&Edit text"
        If MapChanged Then
            MapSetText = txtMap.Text
            ParseTextToFields
            MapChanged = False
        End If
        lstAttributes.Enabled = True
        lstExtAttributes.Enabled = True
        txtMap.Visible = False
        picMap.Visible = True
    End If
End Sub

Private Sub picMap_DblClick()
    If FieldGrabbed < 0 And MultiplesSelected = False Then
        mnuSelectAll_Click
    Else
    End If
End Sub

Private Sub picMap_KeyPress(KeyAscii As Integer)
    If KeyAscii >= vbKeySpace Then
        txtLabel.SelText = Chr(KeyAscii)
    ElseIf KeyAscii = vbKeyBack Then
        If txtLabel.SelStart > 0 Then
            txtLabel.SelStart = txtLabel.SelStart - 1
            txtLabel.SelLength = 1
            txtLabel.SelText = ""
        End If
    End If
End Sub

'Private Sub txtField_KeyDown(KeyCode As Integer, Shift As Integer)
'    Dim NewIndex As Long
'
'    If KeyCode = vbKeyUp Then
'        NewIndex = -1
'    ElseIf KeyCode = vbKeyDown Then
'        NewIndex = 1
'    Else
'        NewIndex = -32767
'    End If
'    NewIndex = lstFields.ListIndex + NewIndex
'    If NewIndex >= 0 And NewIndex < lstFields.ListCount Then
'        lstFields.ListIndex = NewIndex
'    End If
'
'End Sub

Private Sub picMap_KeyDown(KeyCode As Integer, Shift As Integer)
    Select Case KeyCode
    Case vbKeyDelete: mnuDelete_Click
    Case vbKeyInsert: mnuInsert_Click
    Case vbKeyUp
    Case vbKeyDown
    End Select
End Sub

Private Sub picMap_MouseDown(Button As Integer, Shift As Integer, X As Single, Y As Single)
    'find field the mouse grabbed, or none if
    Dim TopRow As Long, LeftCol As Long

    GrabRow = Y \ MapCharHeight
    GrabCol = X \ MapCharWidth

    If Button And 1 Then
        FieldGrabbed = FieldAtPos(GrabRow, GrabCol)
        SelectField (FieldGrabbed), Shift And 1
        If FieldGrabbed >= 0 Then
            If Fields(FieldGrabbed).Selected Then
                TopRow = Fields(FieldGrabbed).Top
                LeftCol = Fields(FieldGrabbed).Left
                GrabRow = TopRow - GrabRow
                GrabCol = LeftCol - GrabCol
                UpdateRowCol
            Else
                FieldGrabbed = -1
            End If
        End If
        RedrawMap
    ElseIf Button And 2 Then
        PopupMenu mnuFieldOptions
    End If
End Sub

Private Sub picMap_MouseMove(Button As Integer, Shift As Integer, X As Single, Y As Single)
    Dim Row As Long, Col As Long, NewField As Long
    
    If MapHasFocus Then
        Row = Y \ MapCharHeight
        Col = X \ MapCharWidth
        If FieldGrabbed >= 0 Then
            RepositionField GrabRow + Row, GrabCol + Col
            UpdateRowCol
        ElseIf FieldGrabbed = -2 Then
            NewField = FieldAtPos(Row, Col)
            If NewField >= 0 Then
                If Not Fields(NewField).Selected Then
                    Fields(NewField).Selected = True
                    RedrawField NewField
                    'SelectField (FieldGrabbed), Shift And 1
                    MultiplesSelected = True
                    RedrawMap
                End If
            End If
        End If
    Else
        picMap.SetFocus
    End If
End Sub

Private Sub picMap_MouseUp(Button As Integer, Shift As Integer, X As Single, Y As Single)
    FieldGrabbed = -1
End Sub

Public Sub RepositionField(NewRow As Long, NewCol As Long)
    Dim Row As Long, Col As Long, Length As Long

    If SelectedField < TotalFields Then
        Row = Fields(SelectedField).Top
        Col = Fields(SelectedField).Left
        Length = Fields(SelectedField).Length
        If NewRow < 0 Then
            NewRow = 0
        ElseIf NewRow >= 24 Then
            NewRow = 23
        End If
        If NewCol < 0 Then
            NewCol = 0
        ElseIf NewCol + Length >= 80 Then
            NewCol = 79 - Length
        End If
        If NewRow <> Row Or NewCol <> Col Then
            RedrawField SelectedField 'marks field for redrawing

            Fields(SelectedField).Top = NewRow
            Fields(SelectedField).Left = NewCol
            
            MapChanged = True
            RedrawMap
        End If
    End If
End Sub

Private Function FieldAtPos(Row As Long, Column As Long) As Long
    Dim count As Long
    FieldAtPos = -2
    For count = TotalFields - 1 To 0 Step -1
        If Fields(count).Kind = FkField Then
            If Fields(count).Top = Row And _
             Fields(count).Left <= Column And _
             Fields(count).Left + Fields(count).Length >= Column And _
             Fields(count).Map = SelectedMap Then
                FieldAtPos = count
                Exit For
            End If
        End If
    Next
End Function

Private Sub SelectField(NewField As Long, Multiple As Boolean)
' if selecting multiples (by holding shift)
'   if NewField < 0 exit sub
'   if field already selected
'     deselect it
'   else
'     select the new field (and redraw it)
'   endif
' elseif NewField < 0
'   if multiples were previously selected
'     deselect all old selected fields
'   endif
' elseif new field unselected
'   if multiples were previously selected
'     deselect all old selected fields
'   else
'     simply deselect previous field
'   endif
'   select new field
' endif
    Dim count As Long

    If NewField < 0 Or NewField >= TotalFields Then
        If Multiple Then Exit Sub
        'deselect any multiple selections
        For count = 0 To TotalFields - 1
            If Fields(count).Selected Then
                Fields(count).Selected = False
                RedrawField count
            End If
        Next
        MultiplesSelected = False
    ElseIf Fields(NewField).Selected Then
        'simply deselect previously selected choice
        'do not change currently selected field
        If Multiple Then
            'MultiplesSelected = True 'may be unnecessary
            Fields(NewField).Selected = False
            RedrawField NewField
        ElseIf NewField <> SelectedField Then
            GoTo SelectNewField
        End If
    ElseIf Fields(NewField).Kind = FkField Then 'field is valid unselected choice
        If Multiple Then
            MultiplesSelected = True
        ElseIf MultiplesSelected Then
            For count = 0 To TotalFields
                If Fields(count).Selected Then
                    Fields(count).Selected = False
                    RedrawField count
                End If
            Next
            MultiplesSelected = False
        Else 'just single change of selection
            Fields(SelectedField).Selected = False
            RedrawField SelectedField 'marks field for redrawing
        End If
SelectNewField:
        Fields(NewField).Selected = True
        Fields(NewField).Redraw = True
        SelectedField = NewField
        
        PreventCascade = True
        cboColor.ListIndex = Fields(NewField).Color
        txtOrder.Text = NewField
        txtLabel.Text = Fields(NewField).Label
        txtName.Text = Fields(NewField).Name
        txtLabel.SelLength = 1000
        'combine current attributes with attributes of new item
        AttributeByte = Fields(NewField).Attributes
        
        With lstAttributes
        .Selected(1) = AttributeByte And FaProtected
        .Selected(0) = (AttributeByte And FaProtected) = 0
        If AttributeByte And FaProtected Then
            .Selected(2) = (AttributeByte And FaSkip) = 0
            .Selected(3) = AttributeByte And FaSkip
            .Selected(4) = False
            .Selected(5) = False
        Else
            .Selected(2) = False
            .Selected(3) = False
            .Selected(4) = (AttributeByte And FaNumeric) = 0
            .Selected(5) = AttributeByte And FaNumeric
        End If
        .Selected(6) = (AttributeByte And FaNoDisplay) = FaNormal
        .Selected(7) = (AttributeByte And FaNoDisplay) = FaBright
        .Selected(8) = (AttributeByte And FaNoDisplay) = FaNoDisplay
        .Selected(9) = AttributeByte And FaModified
        .Selected(10) = AttributeByte And FaCursor
        End With
        
        PreventCascade = False
    End If
End Sub

Private Sub picMap_GotFocus()
    'picMap.BackColor = &H404040
    MapHasFocus = True
End Sub

Private Sub picMap_LostFocus()
    'picMap.BackColor = 0
    FieldGrabbed = -1
    MapHasFocus = False
End Sub

Private Sub UpdateRowCol()
    txtRow.Text = Fields(SelectedField).Top + 1
    txtColumn.Text = Fields(SelectedField).Left + 1
    txtLength.Text = Fields(SelectedField).Length
End Sub

Private Sub picMap_Paint()
    Dim count As Long, Text As String, UpdateRect As Long

    'UpdateRect = GetUpdateRect(picMap.hwnd, MapRedrawRect, 0)
    'txtLabel.Text = MapRedrawRect.Top & "," & MapRedrawRect.Bottom & "," & MapRedrawRect.Left & "," & MapRedrawRect.Right & "  " & Int(Rnd * 20)
    'txtlabel.
    'lstAttributes.Text
    RedrawSection 0, 25, 0, 80
    RedrawMap
End Sub

Private Sub RedrawSection(TopRow As Long, BtmRow As Long, LeftCol As Long, RightCol As Long)
    MapRedrawBg = True
    If TopRow < MapRedrawTop Then MapRedrawTop = TopRow
    If BtmRow > MapRedrawBtm Then MapRedrawBtm = BtmRow
    If LeftCol < MapRedrawLeft Then MapRedrawLeft = LeftCol
    If RightCol > MapRedrawRight Then MapRedrawRight = RightCol
End Sub

Private Sub RedrawField(NewField As Long)
    Dim TopRow As Long, LeftCol As Long, Length As Long

    TopRow = Fields(NewField).Top
    LeftCol = Fields(NewField).Left
    Length = Fields(NewField).Length

    MapRedrawBg = True
    Fields(NewField).Redraw = True
    If TopRow < MapRedrawTop Then MapRedrawTop = TopRow
    If TopRow >= MapRedrawBtm Then MapRedrawBtm = TopRow + 1
    If LeftCol < MapRedrawLeft Then MapRedrawLeft = LeftCol
    If LeftCol + Length >= MapRedrawRight Then MapRedrawRight = LeftCol + Length + 1
End Sub

Private Sub RedrawMap()
    'loop through all the fields
    'if field needs to be redrawn
    'or intersects the redraw area rectangle
    '  redraw field
    '    write field text in given color
    '    if field selected, draw border around it
    '  end redraw
    'endif
    Dim count As Long, TopRow As Long, LeftCol As Long
    Dim Text As String, TextHdc As Long

    TextHdc = picMap.hdc
    If MapRedrawBg And MapRedrawTop < 32767 Then
        picMap.Line (MapRedrawLeft * MapCharWidth, MapRedrawTop * MapCharHeight)-(MapRedrawRight * MapCharWidth - 1, MapRedrawBtm * MapCharHeight - 1), 0, BF
        'picMap.Line (MapRedrawLeft * MapCharWidth, MapRedrawTop * MapCharHeight)-(MapRedrawRight * MapCharWidth - 1, MapRedrawBtm * MapCharHeight - 1), Int(Rnd * 16777215), BF
        MapRedrawBg = False
    End If
    'picMap.ForeColor = Int(Rnd * 16777215)
    For count = 0 To TotalFields - 1
        If Fields(count).Map = SelectedMap Then
        If Fields(count).Kind = FkField Then
            TopRow = Fields(count).Top
            LeftCol = Fields(count).Left
            If Fields(count).Redraw Then GoTo RedrawFieldNow
            If TopRow < MapRedrawBtm Then
            If TopRow >= MapRedrawTop Then
            If LeftCol < MapRedrawRight Then
            If LeftCol + Fields(count).Length >= MapRedrawLeft Then
RedrawFieldNow:
                If Len(Fields(count).Label) Then
                    Text = "·" & Left(Fields(count).Label, Fields(count).Length)
                Else
                    Text = "·" & String(Fields(count).Length, 88)
                End If
                SetTextColor TextHdc, BasicColors(Fields(count).Color)
                TextOut TextHdc, LeftCol * MapCharWidth, TopRow * MapCharHeight, Text, Len(Text)
                If Fields(count).Selected Then
                    picMap.Line (LeftCol * MapCharWidth, TopRow * MapCharHeight)-((LeftCol + Fields(count).Length) * MapCharWidth + MapCharWidth - 1, TopRow * MapCharHeight + MapCharHeight - 1), &HFFFFF, B
                End If
                Fields(count).Redraw = False
            End If
            End If
            End If
            End If
        End If
        End If
    Next
    MapRedrawLeft = 32767
    MapRedrawRight = 0
    MapRedrawTop = 32767
    MapRedrawBtm = 0
End Sub

Private Sub Timer1_Timer()
    'txtName.Text = Fields(0).Attributes & "," & Fields(1).Attributes
    PreventCascade = True
    txtLabel.Text = Fields(SelectedField).Kind & " total=" & TotalFields
    PreventCascade = False
    'txtName.Text = Fields(0).Selected
End Sub

Private Sub txtLabel_Change()
    Dim count As Long, TextLen As Long

    If PreventCascade Then Exit Sub
    TextLen = Len(txtLabel.Text)
    For count = 0 To TotalFields - 1
        If Fields(count).Selected Then
            Fields(count).Label = txtLabel.Text
            If Fields(count).Length < TextLen Then
                Fields(count).Length = TextLen
                PreventCascade = True
                txtLength.Text = TextLen
                PreventCascade = False
            End If
            MapChanged = True
            RedrawField count
        End If
    Next
    RedrawMap
End Sub

Private Sub txtlabel_MouseMove(Button As Integer, Shift As Integer, X As Single, Y As Single)
    txtLabel.SetFocus
End Sub

Private Sub txtLength_Change()
    Dim Value As Long

    If PreventCascade Then Exit Sub
    Value = Val(txtLength.Text)
    If Value >= FieldWidth Then
        Value = FieldWidth - 1
    ElseIf Value < Len(Fields(SelectedField).Label) Then
        Value = Len(Fields(SelectedField).Label)
    End If
    If Value = Fields(SelectedField).Length Then Exit Sub
    RedrawField SelectedField
    Fields(SelectedField).Length = Value
    MapChanged = True
    RedrawMap
End Sub

Private Sub txtMap_Change()
    If PreventCascade Then Exit Sub
    MapChanged = True
End Sub

Private Sub txtMap_MouseMove(Button As Integer, Shift As Integer, X As Single, Y As Single)
    txtMap.SetFocus
End Sub

Private Sub txtName_Change()
    If PreventCascade Then Exit Sub
    Fields(SelectedField).Name = txtName.Text
    MapChanged = True
End Sub

Private Function LoadMapSet() As Boolean
    Dim TextLine As String, NextLine As String
    Dim Continued As Boolean, Recognized As Boolean
    Dim CurMap As Long, NextMap As Long, Name As String

    Open MapFileName For Input As 1
    MapSetText = Input(LOF(1), 1)
    Close 1
    
    ParseTextToFields
    SelectedMap = 0
    If cboMapSelected.ListCount Then cboMapSelected.ListIndex = 0
    
    'If TotalFields >= MaxFields Then
    '    MsgBox "File was too large to be completely loaded. Do not resave it or else you will lose information.", vbExclamation, "File to Large"
    '    Close 1
    '    Exit Function
    'End If

End Function

Private Sub SaveMapSet()
    Dim count As Long, TextLine As String, NextLine As String

    Open MapFileNameO For Output As 1
    For count = 0 To TotalFields - 1
        If Fields(count).Kind = FkField Then
            TextLine = "         DFHMDF POS=(" & Fields(count).Top + 1 & "," & Fields(count).Left + 1 & ")"
            AddContinuedLine TextLine, "LENGTH=" & Fields(count).Length
            AddContinuedLine TextLine, "COLOR=" & BasicColorNames(Fields(count).Color)
            If Len(Fields(count).Label) Then
                AddContinuedLine TextLine, "INITIAL='" & Fields(count).Label & "'"
            End If
            Mid(TextLine, 1, 7) = Fields(count).Name
            Print #1, TextLine
        Else
            Print #1, Fields(count).Text
        End If
    Next
    'ConcatFieldsToText
    'Print #1, MapSetText;
    Close 1
End Sub

Private Sub AddContinuedLine(TextLine As String, NextLine)
    Const ContinueLine As String = "                                                                      -" & vbNewLine & "               "
    TextLine = TextLine & "," & Mid(ContinueLine, (Len(TextLine) Mod 74) + 1) & NextLine
End Sub


'Parses a mapset into maps, fields, and comments
'  DFHMSD is the start or end of a mapset
'  DFHMDI is the start of a map
'  DFHMDF is a map field
'  An asterisk in the first column makes the line a comment.
'  Any nonunderstood field as treated as a comment,
'  loaded as is and left intact.
Private Sub ParseTextToFields()
    Dim CharPos As Long, NextPos As Long, TextLen As Long
    Dim TextLine As String, NextLine As String, Continued As Byte
    Dim CurMap As Long, NextMap As Long, Name As String, Kind As Long

    cboMapSelected.Clear
    cboSelectField.Clear
    'txtMap.Text = ""

    NextMap = -1
    TotalFields = 0
    Kind = 255
    CharPos = 1
    TextLen = Len(MapSetText)
    GoTo InnerLoop
    Do
        NextLine = Mid(MapSetText, CharPos, NextPos - CharPos)
        If Left(NextLine, 1) = "*" Then
            If Continued And 1 Then GoSub AdvanceLine: Continued = 0
            Kind = 255
        Else
            Name = Trim(Left(NextLine, 7))
            Select Case Mid(NextLine, 10, 6)
            Case "      "
            Case "DFHMDF"
                If Continued Then GoSub AdvanceLine
                Continued = 1
                If Len(Name) Then
                    cboSelectField.AddItem Name
                    cboSelectField.ItemData(cboSelectField.NewIndex) = TotalFields
                End If
                Kind = FkField
            Case "DFHMDI"
                If Continued Then GoSub AdvanceLine
                Continued = 1
                Kind = FkMap
                cboMapSelected.AddItem Name
            Case "DFHMSD"
                If Continued Then GoSub AdvanceLine
                Continued = 1
                NextMap = NextMap + 1
                CurMap = NextMap
                Kind = FkMapset
            Case Else
                If Continued And 1 Then GoSub AdvanceLine: Continued = 0
                Kind = 255
            End Select
        End If

        If Continued = 3 Then
            TextLine = TextLine & " " & Trim(Mid(NextLine, 10, 62))
        ElseIf Continued = 1 Then
            TextLine = RTrim(Mid(NextLine, 1, 71))
            Fields(TotalFields).Name = Name
            Continued = 3
        ElseIf Continued = 2 Then
            TextLine = TextLine & vbCrLf & NextLine
        Else 'Continued = 0
            TextLine = NextLine
            Continued = 2
        End If
        CharPos = NextPos + 2
InnerLoop:
        NextPos = InStr(CharPos, MapSetText, vbCrLf)
        If NextPos = 0 Then NextPos = TextLen + 1
    Loop While NextPos < TextLen
    GoSub AdvanceLine
    Exit Sub

AdvanceLine:
    'txtMap.SelText = TextLine & vbNewLine & String(72, 196) & vbNewLine '!!
    Fields(TotalFields).Text = TextLine
    Fields(TotalFields).Map = CurMap
    Fields(TotalFields).Kind = Kind
    If Kind = FkField Then GetFieldAtrs TotalFields
    TotalFields = TotalFields + 1
    'If cboMapSelected.ListCount > 0 Then cboMapSelected.ListIndex = 0
    Return

End Sub

'Sorts all fields so that the mapset entry is first,
'maps starts are next, and fields for each map follow.
'This sort is done linearly to preserve order, however
'if desired, the fields can be subsorted from top to
'bottom, left to right for efficiency.
'
'Converts all the changed field information into text.
'
'Concatenates all the fields into a large multiline string.
Private Sub ConcatFieldsToText()
    Dim count As Long

    MapSetText = ""
    For count = 0 To TotalFields - 1
        MapSetText = MapSetText & Fields(count).Text & vbNewLine
    Next count
End Sub

Private Sub SortFields()
    Dim TempField As FieldInfo, count As Long, CmpCount As Long

    For count = 0 To TotalFields - 2
        ' if following field > current field then
        '   copy following field into temp
        '   count backwards to beginning
        '   while compare field > (current field+1) then
        '     move compare field to (compare field+1)
        '   endwhile
        '   copy temp into lowest field
        ' endif
        If Fields(count + 1).Map < Fields(count).Map Then
            TempField = Fields(count + 1)
            'CmpCount = Count
            'Do
            '    Fields(CmpCount + 1) = Fields(CmpCount)
            '    CmpCount = CmpCount - 1
            '    If CmpCount < 0 Then Exit Do
            'Loop
            For CmpCount = count To 0 Step -1
                If Fields(CmpCount).Map <= TempField.Map Then Exit For
                Fields(CmpCount + 1) = Fields(CmpCount)
            Next
            Fields(CmpCount + 1) = TempField
        End If
    Next
End Sub

Private Sub GetFieldAtrs(Index As Long)
    'charpos - current character position
    'atrbpos - starting character of attribute values
    'seppos  - ending character of attribute values
    'nextpos - position of next field attribute
    'temppos - used in parsing attribute values and misc.
    Dim Text As String, UcText As String
    Dim CharPos As Long, AtrbPos As Long, SepPos As Long, NextPos As Long
    Dim TempPos As Long

    Dim FieldTop As Long
    Dim FieldLeft As Long
    Dim Atrs As Byte:      'Atrs = 0
    Dim Length As Long:    'Length = 1
    Dim Initial As String: 'Initial = ""
    Dim Color As Long:     'Color = 0
    Dim Askip As Long
    Atrs = FaProtected Or FaSkip

    If Fields(Index).Kind <> FkField Then Exit Sub

    Text = Fields(Index).Text
    UcText = UCase(Text)
    CharPos = 17
    Do
        AtrbPos = InStr(CharPos, UcText, "=") + 1
        If AtrbPos <= 1 Then Exit Do
        TempPos = AtrbPos
        If Mid(UcText, AtrbPos, 1) = "(" Then
            AtrbPos = AtrbPos + 1
            SepPos = InStr(AtrbPos, UcText, "),")
            NextPos = SepPos + 3
        ElseIf Mid(UcText, AtrbPos, 1) = "'" Then
            AtrbPos = AtrbPos + 1
            SepPos = InStr(AtrbPos, UcText, "',")
            NextPos = SepPos + 3
        Else
            SepPos = InStr(AtrbPos, UcText, ",")
            NextPos = SepPos + 2
        End If
        If SepPos <= 0 Then SepPos = Len(UcText) + 1: NextPos = SepPos

        Select Case Mid(UcText, CharPos, TempPos - CharPos - 1)
        Case "POS"
            FieldTop = Val(Mid(UcText, AtrbPos)) - 1
            AtrbPos = InStr(AtrbPos, UcText, ",")
            If AtrbPos Then FieldLeft = Val(Mid(UcText, AtrbPos + 1)) - 1
        Case "ATTRB"
            Askip = 0
            Do
                TempPos = InStr(AtrbPos, UcText, ",")
                If TempPos > SepPos Or TempPos = 0 Then
                    TempPos = SepPos
                End If
                Select Case Mid(UcText, AtrbPos, TempPos - AtrbPos)
                Case "UNPROT": Atrs = Atrs And Not (FaProtected Or FaSkip)
                Case "PROT": Atrs = Atrs Or FaProtected
                Case "NORM": Atrs = Atrs And Not FaBright
                'Case alphanumeric
                Case "NUM": Atrs = Atrs Or FaNumeric
                'Case stop
                Case "ASKIP": Atrs = Atrs Or FaSkip
                Case "BRT": Atrs = Atrs Or FaBright
                Case "DRK": Atrs = Atrs Or FaNoDisplay
                Case "IC": Atrs = Atrs Or FaCursor
                Case "FSET": Atrs = Atrs Or FaModified
                End Select
                Atrs = Atrs Or Askip
                AtrbPos = TempPos + 1
            Loop Until TempPos >= SepPos
        Case "LENGTH": Length = Val(Mid(UcText, AtrbPos))
        Case "INITIAL": Initial = Mid(Text, AtrbPos, SepPos - AtrbPos - 1)
        Case "COLOR"
            Select Case Mid(UcText, AtrbPos, SepPos - AtrbPos)
            Case "BLUE": Color = 1
            Case "RED": Color = 2
            Case "PINK": Color = 3
            Case "GREEN": Color = 4
            Case "TURQUOISE": Color = 5
            Case "YELLOW": Color = 6
            Case "WHITE": Color = 7
            End Select
        End Select
        CharPos = NextPos
    Loop
    Fields(Index).Attributes = Atrs
    Fields(Index).Length = Length
    Fields(Index).Label = Initial
    Fields(Index).Color = Color
    Fields(Index).Top = FieldTop
    Fields(Index).Left = FieldLeft
    Exit Sub
End Sub

Private Sub txtName_MouseMove(Button As Integer, Shift As Integer, X As Single, Y As Single)
    txtName.SetFocus
End Sub

Private Sub txtOrder_MouseMove(Button As Integer, Shift As Integer, X As Single, Y As Single)
    txtOrder.SetFocus
End Sub

Private Sub txtRow_MouseMove(Button As Integer, Shift As Integer, X As Single, Y As Single)
    txtRow.SetFocus
End Sub

Private Sub txtColumn_MouseMove(Button As Integer, Shift As Integer, X As Single, Y As Single)
    txtColumn.SetFocus
End Sub

Private Sub txtLength_MouseMove(Button As Integer, Shift As Integer, X As Single, Y As Single)
    txtLength.SelLength = 32760
    txtLength.SetFocus
End Sub
