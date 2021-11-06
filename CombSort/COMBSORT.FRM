VERSION 5.00
Begin VB.Form frmSortDemo 
   Caption         =   "Sort Demo"
   ClientHeight    =   4080
   ClientLeft      =   60
   ClientTop       =   345
   ClientWidth     =   7665
   LinkTopic       =   "Form1"
   ScaleHeight     =   272
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   511
   StartUpPosition =   3  'Windows Default
   Begin VB.CommandButton cmdSort 
      Caption         =   "Sort"
      Height          =   495
      Left            =   120
      TabIndex        =   0
      Top             =   3480
      Width           =   1215
   End
   Begin VB.Label lblTimes 
      Height          =   495
      Left            =   1440
      TabIndex        =   1
      Top             =   3480
      Width           =   1455
   End
End
Attribute VB_Name = "frmSortDemo"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit
Const TestSize As Long = 500
Dim Test(TestSize - 1) As Long
Dim Swaps As Long

Private Sub cmdSort_Click()
    RandomizeTest
    'Sort
    lblTimes.Caption = "linear=" & Swaps

    RandomizeTest
    Combsort
    lblTimes.Caption = lblTimes.Caption & vbNewLine & "comb sort=" & Swaps
End Sub

Public Sub Sort()
    Dim X As Long, Y As Long
    Dim Temp As Long
    For X = 0 To TestSize - 2
        For Y = X + 1 To TestSize - 1
            If Test(X) > Test(Y) Then
                Temp = Test(X)
                Test(X) = Test(Y)
                Test(Y) = Temp
                DisplayLine X
                DisplayLine Y
                Swaps = Swaps + 1
            End If
        Next Y
    Next X
End Sub

Public Sub Combsort()
    Dim I As Long, J As Long, Temp As Long
    Const Shrink = 1.3
    Dim Gap As Long
    Dim Swapped As Boolean
    Gap = TestSize
    Do
        Gap = Int(Gap / Shrink)
        Swapped = False
        For J = 0 To TestSize - Gap - 1
            I = J + Gap
            If Test(J) > Test(I) Then
                Temp = Test(J)
                Test(J) = Test(I)
                Test(I) = Temp
                Swapped = True
                Swaps = Swaps + 1

                DisplayLine J
                DisplayLine I
            End If
        Next J
    Loop While Swapped Or Gap > 1
    DisplayAllLines
End Sub

Public Sub OldCombsort()
    Dim I As Long, J As Long, Temp As Long
    Const Shrink = 1.3
    Dim Gap As Single
    Dim Swapped As Boolean
    Gap = 500 - 1
    Do
        Gap = Int(Gap / Shrink)
        Swapped = True
        For J = 0 To 499 - Gap
            If Test(J) > Test(J + Gap) Then
                Temp = Test(J)
                Test(J) = Test(J + Gap)
                Test(J + Gap) = Temp
                Swapped = False
                Swaps = Swaps + 1
                
                DisplayLine J
                DisplayLine J + Gap
            End If
        Next J
    Loop While Swapped Or Gap > 1
End Sub

Public Sub DisplayLine(Col As Long)
    Line (Col, 0)-(Col, Test(Col) - 1), &HFFFFFF
    Line (Col, Test(Col))-(Col, 200), 0
End Sub

Public Sub DisplayAllLines()
Dim Counter As Long

For Counter = 0 To TestSize - 1
    Line (Counter, 0)-(Counter, Test(Counter) - 1), &HEEEEFF
    Line (Counter, Test(Counter))-(Counter, 200), 0
Next
End Sub

Public Sub RandomizeTest()
Dim Counter As Long

For Counter = 0 To TestSize - 1
    Test(Counter) = Int(Rnd * 200)
Next
DisplayAllLines
Swaps = 0

End Sub
