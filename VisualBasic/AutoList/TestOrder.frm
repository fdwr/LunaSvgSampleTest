VERSION 5.00
Begin VB.Form frmTestOrder 
   Caption         =   "Test Order"
   ClientHeight    =   6645
   ClientLeft      =   150
   ClientTop       =   1095
   ClientWidth     =   8490
   Icon            =   "TestOrder.frx":0000
   LinkTopic       =   "Form1"
   ScaleHeight     =   6645
   ScaleWidth      =   8490
   Begin VB.CommandButton cmdClose 
      Cancel          =   -1  'True
      Caption         =   "Close"
      Height          =   375
      Left            =   1440
      TabIndex        =   2
      Top             =   6120
      Width           =   1215
   End
   Begin VB.CommandButton cmdOrder 
      Caption         =   "Order"
      Default         =   -1  'True
      Height          =   375
      Left            =   120
      TabIndex        =   1
      Top             =   6120
      Width           =   1215
   End
   Begin VB.ListBox lstFiles 
      Height          =   5910
      Left            =   120
      TabIndex        =   0
      Top             =   120
      Width           =   8295
   End
End
Attribute VB_Name = "frmTestOrder"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Private Declare Function SendMessage Lib "user32" Alias "SendMessageA" (ByVal hwnd As Long, ByVal wMsg As Long, ByVal wParam As Long, lParam As Any) As Long
Private Const LB_SETTABSTOPS = &H192

Private Sub cmdClose_Click()
    Unload Me
End Sub

Private Sub cmdOrder_Click()
'Just to make it easy for you:
'
'Array Size:  FileCount
'Sort By:     FileNames
'Sub Items():
'     FileSizes
'     FileDates
'     FilePath

    CombOrderX4 4, 1, FileCount, AddressOf CombOrderEscCb, _
        ByVal VarPtr(FileNames(1)), CmpStrBA, _
        FileSizes(1), CmpLongSA, _
        FileDates(1), CmpSngA, _
        FilePath(1), CmpLongSA

    ListFiles
End Sub

Private Sub Form_Load()
    SetListTabStops lstFiles.hwnd, 220, 270, 300
    ListFiles
End Sub

Public Sub ListFiles()
    Dim Count As Long

    With lstFiles
    .Clear
    For Count = 1 To FileCount
        .AddItem FileNames(Count) & vbTab _
               & FileSizes(Count) & vbTab _
               & CDate(FileDates(Count)) & vbTab _
               & FilePath(Count)
    Next
    End With
End Sub

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

