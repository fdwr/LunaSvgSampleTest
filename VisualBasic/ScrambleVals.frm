VERSION 5.00
Begin VB.Form frmScrambleVals 
   Caption         =   "Scramble Values"
   ClientHeight    =   4575
   ClientLeft      =   60
   ClientTop       =   345
   ClientWidth     =   5175
   ForeColor       =   &H8000000F&
   Icon            =   "ScrambleVals.frx":0000
   KeyPreview      =   -1  'True
   LinkTopic       =   "Form1"
   ScaleHeight     =   305
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   345
   StartUpPosition =   3  'Windows Default
   Begin VB.ListBox lstPts 
      Height          =   4545
      Left            =   3840
      TabIndex        =   0
      Top             =   0
      Width           =   1335
   End
End
Attribute VB_Name = "frmScrambleVals"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
'Cheap, unrefined, unfinished 10 minute test program
'Peekin
'2003-05-23
'
'Makes a list of numbers that appear random (since no
'pattern is immediately noticeable), but there is a
'special property of these 'random' numbers. For one,
'there are no duplicates, since all operations produce
'unique outputs; and all numbers are reversible. If the
'exact opposite operations were performed, you would
'get the original pure sequence 0-255.

Option Explicit

Dim XorValue As Long

Private Sub Form_Click()
    Dim Count As Long
    Dim Bits As Long
    Dim Bit As Long
    Dim Offset  As Long
    Dim Offset2 As Long
    
    Cls
    lstPts.Clear
    Select Case 100
    Case 0:
        For Count = 0 To 255
            Bit = 1
            Bits = 0
            Do
                Bits = Bits * 2
                If Count And Bit Then Bits = Bits Or 1
                Bit = Bit * 2
            Loop Until Bit > 128
            Line (0, Count)-(Bits, Count), &HFFFFFF
            lstPts.AddItem Bits
        Next
    
    Case 1:
        Bits = 0
        For Count = 0 To 255
            Line (0, Count)-(Bits, Count), &HFFFFFF
            lstPts.AddItem Bits
            Bits = (Bits + 7) And 255
        Next

    Case 2:
        For Count = 0 To 255
            Bits = Count Xor XorValue
            Line (0, Count)-(Bits, Count), &HFFFFFF
            lstPts.AddItem Bits
        Next
    
    Case 100: 'combine all three
        Offset = 0
        For Count = 0 To 255
            Bit = 1
            Bits = 0
            'Offset2 = Offset Xor XorValue
            'Offset = Count
            Do
                Bits = Bits * 2
                If Offset And Bit Then Bits = Bits Or 1
                Bit = Bit * 2
            Loop Until Bit > 128
            Bits = Bits Xor XorValue
            'Bits = (Bits * 3) And 255
            Line (0, Count)-(Bits, Count), &HFFFFFF
            lstPts.AddItem Bits
            Offset = (Offset + 7) And 255
        Next
    End Select
End Sub


Private Sub Form_KeyDown(KeyCode As Integer, Shift As Integer)
    Select Case KeyCode
    Case vbKeyReturn:
        Form_Click
    Case vbKeyLeft:
        XorValue = XorValue + 1
        Form_Click
    Case vbKeyRight:
        XorValue = XorValue - 1
        Form_Click
    End Select
End Sub

Private Sub Form_Load()
    XorValue = 21
End Sub
