VERSION 5.00
Begin VB.Form frmGravityCenter 
   Caption         =   "Gravity Center"
   ClientHeight    =   3195
   ClientLeft      =   165
   ClientTop       =   735
   ClientWidth     =   4680
   Icon            =   "GravityCenter.frx":0000
   LinkTopic       =   "Form1"
   ScaleHeight     =   213
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   312
   StartUpPosition =   3  'Windows Default
   Begin VB.Menu mnuQuit 
      Caption         =   "&Quit"
   End
   Begin VB.Menu mnuRedraw 
      Caption         =   "&Redraw"
   End
   Begin VB.Menu mnuPlanetSize 
      Caption         =   "Planet &size"
   End
   Begin VB.Menu mnuCalcGraph 
      Caption         =   "Calc &graph"
   End
End
Attribute VB_Name = "frmGravityCenter"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
DefLng A-Z
Option Explicit

Private Points(1000000, 2) As Integer
Private PlanetSize As Long, PointsTtl As Long
Private SatelliteX As Integer, SatelliteY As Integer
Private PlanetX As Integer, PlanetY As Integer
Private SpaceX As Integer, SpaceY As Integer
Private TotalGravity As Single, ExpectGravity As Single

Private Sub Form_Load()
    Me.Move 0, 0, Screen.Width, Screen.Height
    PlanetSize = 100
    'mnuPlanetSize_Click
    If PlanetSize < 0 Then Exit Sub

    SatelliteX = SpaceX \ 2
    SatelliteY = 20
    CalcPoints2D
    Show
    DoEvents
    'DrawPoints
End Sub

Private Sub CalcPoints2D()
    Dim Row As Single, Col As Single
    Dim RowRnd As Single, ColRnd As Single
    Dim Counter As Long
    Dim SideX As Single
    Dim PtsDec As Single, PtsHalf As Single
    
    PtsDec = PlanetSize - 1
    PtsHalf = PtsDec / 2
    
    PlanetX = SpaceX \ 2
    PlanetY = SpaceY - PlanetSize * 2 - 10
    
    PointsTtl = 0
    For Row = -PtsHalf To PtsHalf
        SideX = Sqr(PtsHalf * PtsHalf - Row * Row + 1)
        
        For Col = -PtsHalf To PtsHalf
            If Col <= SideX And Col >= -SideX Then
                Points(PointsTtl, 0) = Col * 4 + PlanetX
                Points(PointsTtl, 1) = Row * 4 + PlanetY
                PointsTtl = PointsTtl + 1
            End If
        Next
    Next
    'For PointsTtl = 0 To 4000
    '    RowRnd = PtsDec * Rnd - PtsHalf
    '    SideX = Sqr(PtsHalf * PtsHalf - RowRnd * RowRnd + 1)
    '    ColRnd = PtsDec * Rnd - PtsHalf
    '    If ColRnd <= SideX And ColRnd >= -SideX Then
    '        Points(PointsTtl, 0) = ColRnd * 10 + PlanetX
    '        Points(PointsTtl, 1) = RowRnd * 10 + PlanetY
    '    End If
    'Next
End Sub

Private Sub DrawPoints()
    Dim Counter As Long
    Circle (SatelliteX, SatelliteY), 2, &H99CCFF

    For Counter = 0 To PointsTtl - 1
        'Line (Points(Counter, 0), Points(Counter, 1))-(Points(Counter, 0) + 1, Points(Counter, 1) + 1), &HFFCCCC, BF
        PSet (Points(Counter, 0), Points(Counter, 1)), &HFFCCCC
    Next
End Sub

Private Sub DrawGravityLines()
    Dim Counter As Long

    For Counter = 0 To PointsTtl - 1
        Line (SatelliteX, SatelliteY)-(Points(Counter, 0), Points(Counter, 1)), &HFF0000
    Next
End Sub

Private Sub CalcGravity2D()
    Dim Distance As Single, Gravity As Single, GravityY As Single
    Dim GravityDif  As Single
    Dim Counter As Long

    TotalGravity = 0
    For Counter = 0 To PointsTtl - 1
        'determine length between satellite and point of mass
        'using pythagorean formula
        Distance = Sqr((Points(Counter, 0) - SatelliteX) ^ 2 + (Points(Counter, 1) - SatelliteY) ^ 2)
        If Distance > 5 Then
            'gravity = G * m / r^2
            'simplified to eliminate G by setting to 1
            'and setting mass of a single point to 1000
            'distance is the radius in this case
            Gravity = 1000 / (Distance * Distance)
            'determine acceleration in the vertical direction only
            'by scaling the calculated gravity according to sine
            'of the angle between the satellite and the center of the
            'planet (sine=y/h, so y distance / hypotenuse distance)
            GravityY = Gravity * (Points(Counter, 1) - SatelliteY) / Distance
        Else
            GravityY = 1000 / (10 * 10) '1000/(5*5)
            If SatelliteY > Points(Counter, 1) Then GravityY = -GravityY
        End If
        'accumulate total gravity of all points to determine
        'integral planet gravity
        TotalGravity = TotalGravity + GravityY
        'Line (SatelliteX, SatelliteY)-(Points(Counter, 0) + 1, Points(Counter, 1) + 1), &HFF0000
    Next
    Distance = Abs(PlanetY - SatelliteY)
    If Distance >= 4 Then
        'use a simpler formula that works for most cases, but
        'starts to show large discreptancies when the satellite
        'distance becomes to close to the planet. The values are
        'completely wrong for when the satellite is inside the planet.
        ExpectGravity = PointsTtl * 1000 / (Distance * Distance)
        GravityDif = TotalGravity / ExpectGravity
    Else
        ExpectGravity = PointsTtl * 1000 / (4 * 4)
        GravityDif = 1
    End If
    If SatelliteY > PlanetY Then ExpectGravity = -ExpectGravity
    Caption = "Integral_g=" & Format(TotalGravity, "########.########") & " Expected_g=" & Format(ExpectGravity, "########.########") & " Dif=" & GravityDif & " distance=" & Distance
End Sub

Private Sub CalcMultiplePoints()
    Dim Counter As Long, Dir As Long
    Dim LX As Long, Clr As Long
    
    If SatelliteY < PlanetY Then Dir = 1 Else Dir = -1
    
    For SatelliteY = SatelliteY To PlanetY Step Dir
        Circle (SatelliteX, SatelliteY), 2, &H99CCFF
        CalcGravity2D
        If SatelliteY And 1 Then
            LX = TotalGravity \ 10
            Clr = &HFFCCCC
        Else
            LX = ExpectGravity \ 10
            Clr = &HCCCCFF
        End If
        If LX < -32768 Then LX = -32768
        If LX > 32767 Then LX = 32767
        Line (PlanetX, SatelliteY)-(LX + PlanetX, SatelliteY), Clr
    Next
End Sub

Private Sub Form_MouseDown(Button As Integer, Shift As Integer, X As Single, Y As Single)
    If Button And 1 Then
        'SatelliteX = X
        SatelliteY = Y
        'CalcPoints2D
        Cls
        DrawPoints
        DrawGravityLines
        CalcGravity2D
    ElseIf Button And 2 Then
        CalcMultiplePoints
    End If
End Sub

Private Sub Form_MouseMove(Button As Integer, Shift As Integer, X As Single, Y As Single)
    Dim LX As Long
    SatelliteY = Y
    CalcGravity2D
    
    If SatelliteY And 1 Then
        LX = TotalGravity \ 10
        If LX > 32767 Then LX = 32767
        Line (PlanetX, SatelliteY)-(LX + PlanetX, SatelliteY), &HFFCCCC
    Else
        LX = ExpectGravity \ 10
        If LX > 32767 Then LX = 32767
        Line (PlanetX, SatelliteY)-(LX + PlanetX, SatelliteY), &HCCCCFF
    End If
End Sub

Private Sub Form_Paint()
    DrawPoints
End Sub

Private Sub Form_Resize()
    SpaceX = ScaleWidth
    SpaceY = ScaleHeight
End Sub

Private Sub mnuCalcGraph_Click()
    CalcMultiplePoints
End Sub

Private Sub mnuPlanetSize_Click()
    Do
        PlanetSize = frmGetInput.GetInput("Points", "Enter the number of points per dimension for the gravity sphere", Me)
    Loop Until PlanetSize * PlanetSize < UBound(Points)
    If PlanetSize < 1 Then PlanetSize = 1
End Sub

Private Sub mnuQuit_Click()
    Unload Me
End Sub

Private Sub mnuRedraw_Click()
    Cls
    DrawPoints
End Sub
