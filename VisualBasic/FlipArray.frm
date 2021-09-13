VERSION 5.00
Begin VB.Form frmFlipArray 
   Caption         =   "Array Flipping Test"
   ClientHeight    =   4530
   ClientLeft      =   60
   ClientTop       =   345
   ClientWidth     =   5955
   LinkTopic       =   "Form1"
   ScaleHeight     =   4530
   ScaleWidth      =   5955
   StartUpPosition =   3  'Windows Default
   Begin VB.Image imgFlipArray 
      Height          =   2775
      Left            =   0
      Top             =   0
      Width           =   3615
   End
End
Attribute VB_Name = "frmFlipArray"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Const ArrayHeight = 13, ArrayWidth = 13
Const UnitHeight = 200, UnitWidth = 400
Dim UnitSelected As Integer
Dim FlipArray(ArrayHeight * ArrayWidth) As Integer

Private Sub Form_Load()
    Call SizeArrayDims
    Call ResetArray
    Show
    Call RedrawArray
End Sub

Sub ResetArray()
    Dim Index As Integer

    For Index = 0 To UBound(FlipArray)
        FlipArray(Index) = Index
    Next Index
End Sub

Sub SizeArrayDims()
    imgFlipArray.Height = ArrayHeight * UnitHeight
    imgFlipArray.Width = ArrayWidth * UnitWidth
End Sub

Private Sub imgFlipArray_MouseDown(Button As Integer, Shift As Integer, X As Single, Y As Single)
    Dim Row As Integer, Column As Integer, LastUnitSelected As Integer

    Column = (X \ UnitWidth)
    If Column < ArrayWidth And Column >= 0 Then
        Row = (Y \ UnitHeight)
        If Row < ArrayHeight And Row >= 0 Then
            LastUnitSelected = UnitSelected
            UnitSelected = Row * ArrayWidth + Column
        End If
    End If
    Cls
    'Call RedrawArrayCell(LastUnitSelected)
    Call RedrawArray
    Print
    Print "Selected unit:"; UnitSelected;
End Sub

Private Sub RedrawArray()
    Dim Count As Integer

    For Count = 0 To UBound(FlipArray)
        RedrawArrayCell Count
    Next Count
End Sub

Private Sub RedrawArrayCell(UnitToSelect As Integer)
    frmFlipArray.CurrentX = (UnitToSelect Mod ArrayWidth) * UnitWidth
    frmFlipArray.CurrentY = (UnitToSelect \ ArrayWidth) * UnitHeight
    If UnitToSelect = UnitSelected Then
        Font.Bold = True
        Print Str(UnitToSelect);
        Font.Bold = False
    Else
        Print Str(UnitToSelect);
    End If
End Sub

Private Sub imgFlipArray_MouseUp(Button As Integer, Shift As Integer, X As Single, Y As Single)
    Dim Row As Integer, Column As Integer, LastUnitSelected As Integer

    Column = (X \ UnitWidth)
    If Column < ArrayWidth And Column >= 0 Then
        Row = (Y \ UnitHeight)
        If Row < ArrayHeight And Row >= 0 Then
            LastUnitSelected = UnitSelected
            UnitSelected = Row * ArrayWidth + Column
        End If
    End If
End Sub
