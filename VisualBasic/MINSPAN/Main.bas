Attribute VB_Name = "modMain"
DefInt A-Z
Option Explicit

Public Declare Function TextOut Lib "gdi32" Alias "TextOutA" (ByVal hdc As Long, ByVal X As Long, ByVal Y As Long, ByVal lpString As String, ByVal nCount As Long) As Long

Public Terminate As Boolean

Public Sub Main()
    Load frmPoints
    Load frmGraph
    PositionGraphWindows
    frmPoints.Show
    frmGraph.Show
    Do
        DoEvents
    Loop Until Terminate
    Unload frmGraph
    Unload frmPoints
    End
End Sub

Public Sub PositionGraphWindows()
    Dim ScreenHeight As Integer, ScreenWidth As Integer
    ScreenWidth = Screen.Width
    ScreenHeight = Screen.Height
    
    With frmPoints
    .WindowState = vbNormal
    .Top = 0
    .Left = 0
    .Height = ScreenHeight
    End With
    With frmGraph
    .WindowState = vbNormal
    .Top = 0
    .Left = frmPoints.Width
    .Height = ScreenHeight
    .Width = ScreenWidth - .Left
    End With
End Sub
