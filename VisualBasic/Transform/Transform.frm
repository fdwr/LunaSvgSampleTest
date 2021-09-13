VERSION 5.00
Begin VB.Form frmTransform 
   Caption         =   "Point Transformation - Scale/Flip/Rotate/Shear"
   ClientHeight    =   5595
   ClientLeft      =   165
   ClientTop       =   735
   ClientWidth     =   7485
   Icon            =   "Transform.frx":0000
   LinkTopic       =   "Form1"
   ScaleHeight     =   373
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   499
   StartUpPosition =   3  'Windows Default
   Begin VB.HScrollBar hsbFieldFactor 
      Height          =   240
      Index           =   8
      LargeChange     =   1024
      Left            =   720
      Min             =   -32768
      SmallChange     =   16
      TabIndex        =   13
      Top             =   1440
      Width           =   6735
   End
   Begin VB.HScrollBar hsbFieldFactor 
      Height          =   240
      Index           =   7
      LargeChange     =   1024
      Left            =   720
      Min             =   -32768
      SmallChange     =   16
      TabIndex        =   12
      Top             =   1080
      Width           =   6735
   End
   Begin VB.HScrollBar hsbFieldFactor 
      Height          =   120
      Index           =   6
      LargeChange     =   1024
      Left            =   720
      Min             =   -32768
      SmallChange     =   16
      TabIndex        =   8
      Top             =   960
      Width           =   6735
   End
   Begin VB.HScrollBar hsbFieldFactor 
      Height          =   120
      Index           =   5
      LargeChange     =   1024
      Left            =   720
      Min             =   -32768
      SmallChange     =   16
      TabIndex        =   7
      Top             =   840
      Width           =   6735
   End
   Begin VB.HScrollBar hsbFieldFactor 
      Height          =   120
      Index           =   4
      LargeChange     =   1024
      Left            =   720
      Min             =   -32768
      SmallChange     =   16
      TabIndex        =   6
      Top             =   720
      Width           =   6735
   End
   Begin VB.PictureBox picField 
      AutoRedraw      =   -1  'True
      BackColor       =   &H00000000&
      Height          =   3495
      Left            =   0
      ScaleHeight     =   229
      ScaleMode       =   3  'Pixel
      ScaleWidth      =   493
      TabIndex        =   0
      Top             =   1800
      Width           =   7455
   End
   Begin VB.HScrollBar hsbFieldFactor 
      Height          =   240
      Index           =   3
      LargeChange     =   1024
      Left            =   720
      Min             =   -32768
      SmallChange     =   16
      TabIndex        =   4
      Top             =   360
      Value           =   8192
      Width           =   6735
   End
   Begin VB.HScrollBar hsbFieldFactor 
      Height          =   120
      Index           =   2
      LargeChange     =   1024
      Left            =   720
      Min             =   -32768
      SmallChange     =   16
      TabIndex        =   3
      Top             =   240
      Value           =   8192
      Width           =   6735
   End
   Begin VB.HScrollBar hsbFieldFactor 
      Height          =   120
      Index           =   1
      LargeChange     =   1024
      Left            =   720
      Min             =   -32768
      SmallChange     =   16
      TabIndex        =   2
      Top             =   120
      Value           =   8192
      Width           =   6735
   End
   Begin VB.HScrollBar hsbFieldFactor 
      Height          =   120
      Index           =   0
      LargeChange     =   1024
      Left            =   720
      Min             =   -32768
      SmallChange     =   16
      TabIndex        =   1
      Top             =   0
      Value           =   8192
      Width           =   6735
   End
   Begin VB.Label Label3 
      Alignment       =   1  'Right Justify
      BorderStyle     =   1  'Fixed Single
      Caption         =   "Rotate "
      Height          =   255
      Left            =   0
      TabIndex        =   11
      Top             =   1440
      Width           =   705
   End
   Begin VB.Label Label2 
      Alignment       =   1  'Right Justify
      BorderStyle     =   1  'Fixed Single
      Caption         =   "Skew "
      Height          =   615
      Left            =   0
      TabIndex        =   10
      Top             =   720
      Width           =   705
   End
   Begin VB.Label Label1 
      Alignment       =   1  'Right Justify
      BorderStyle     =   1  'Fixed Single
      Caption         =   "Scale "
      Height          =   615
      Left            =   0
      TabIndex        =   9
      Top             =   0
      Width           =   705
   End
   Begin VB.Label lblFormula 
      Caption         =   "x = (x * xs) + (y * yr);  y = (y * ys) - (x * xr)"
      Height          =   240
      Left            =   0
      TabIndex        =   5
      Top             =   5310
      Width           =   7455
   End
   Begin VB.Menu mnuFile 
      Caption         =   "&File"
      Begin VB.Menu mnuStore 
         Caption         =   "&Store"
         Enabled         =   0   'False
      End
      Begin VB.Menu mnuLoad 
         Caption         =   "&Load"
         Enabled         =   0   'False
      End
      Begin VB.Menu mnu0 
         Caption         =   "-"
      End
      Begin VB.Menu mnuQuit 
         Caption         =   "E&xit"
      End
   End
   Begin VB.Menu mnuTransforms 
      Caption         =   "&Transforms"
      Begin VB.Menu mnuTransformNormal 
         Caption         =   "Normal"
      End
      Begin VB.Menu mnu1 
         Caption         =   "-"
      End
      Begin VB.Menu mnuScalewide 
         Caption         =   "Scale wide"
      End
      Begin VB.Menu mnuScalethin 
         Caption         =   "Scale thin"
      End
      Begin VB.Menu mnuScaletall 
         Caption         =   "Scale tall"
      End
      Begin VB.Menu mnuScaleshort 
         Caption         =   "Scale short"
      End
      Begin VB.Menu mnuScalelarge 
         Caption         =   "Scale large"
      End
      Begin VB.Menu mnuScalesmall 
         Caption         =   "Scale small"
      End
      Begin VB.Menu mnu2 
         Caption         =   "-"
      End
      Begin VB.Menu mnuFlipvertical 
         Caption         =   "Flip vertical"
      End
      Begin VB.Menu nmuFliphorizontal 
         Caption         =   "Flip horizontal"
      End
      Begin VB.Menu mnuFlipboth 
         Caption         =   "Flip both"
      End
      Begin VB.Menu mnu3 
         Caption         =   "-"
      End
      Begin VB.Menu mnuSkewleft 
         Caption         =   "Skew left"
      End
      Begin VB.Menu mnuSkewright 
         Caption         =   "Skew right"
      End
      Begin VB.Menu mnuSkewup 
         Caption         =   "Skew up"
      End
      Begin VB.Menu mnuSkewdown 
         Caption         =   "Skew down"
      End
      Begin VB.Menu mnu4 
         Caption         =   "-"
      End
      Begin VB.Menu mnuRotateleft 
         Caption         =   "Rotate left"
      End
      Begin VB.Menu mnuRotateright 
         Caption         =   "Rotate right"
      End
      Begin VB.Menu mnuRotateOpposite 
         Caption         =   "Rotate opposite"
      End
   End
   Begin VB.Menu mnuView 
      Caption         =   "&View"
      Begin VB.Menu mnuViewAngle 
         Caption         =   "Flat"
         Checked         =   -1  'True
         Enabled         =   0   'False
         Index           =   0
      End
      Begin VB.Menu mnuViewAngle 
         Caption         =   "Tilted"
         Enabled         =   0   'False
         Index           =   1
      End
      Begin VB.Menu mnuViewAngle 
         Caption         =   "Diagonal"
         Enabled         =   0   'False
         Index           =   2
      End
      Begin VB.Menu mnuHorizon 
         Caption         =   "Horizon"
         Checked         =   -1  'True
         Enabled         =   0   'False
      End
   End
   Begin VB.Menu mnuHelp 
      Caption         =   "&Help"
      Begin VB.Menu mnuSummary 
         Caption         =   "Summary"
         Enabled         =   0   'False
      End
      Begin VB.Menu mnuCredit 
         Caption         =   "Credit"
      End
   End
End
Attribute VB_Name = "frmTransform"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Private Type Point2D
X As Integer
Y As Integer
End Type

Private Type Point3D
X As Integer
Y As Integer
Z As Integer
End Type

Dim FieldOriginX As Long
Dim FieldOriginY As Long
Dim FieldOriginZ As Long
Dim FieldScaleX As Single
Dim FieldScaleY As Single
Dim FieldScaleZ As Single
Dim FieldSkewX As Single
Dim FieldSkewY As Single
Dim FieldSkewZ As Single
Dim FieldViewAngle As Long

Const FieldPointsMax As Long = 1000
Dim FieldPointsTotal As Long
Dim FieldPoints(FieldPointsMax)  As Point2D

Dim FieldCoords(FieldPointsMax)  As Point3D
Dim FieldCoords2(FieldPointsMax) As Point3D

Const HsbFactorBase As Single = 8192
Dim HsbFactorIgnoreChange As Boolean

Private Sub Form_Load()
    Dim Count As Long

    FieldPointsTotal = 10
    'FieldCoords(0).X = 30:  FieldCoords(0).Y = 40
    'FieldCoords(1).X = 40:  FieldCoords(1).Y = -70
    'FieldCoords(2).X = -60: FieldCoords(2).Y = 80
    'FieldCoords(3).X = 10: FieldCoords(3).Y = 0
    FieldCoords(0).X = -60:  FieldCoords(0).Y = 60
    FieldCoords(1).X = 55:  FieldCoords(1).Y = 60
    FieldCoords(2).X = 65:  FieldCoords(2).Y = 60
    FieldCoords(3).X = -60: FieldCoords(3).Y = -55
    FieldCoords(4).X = -68: FieldCoords(4).Y = -65
    FieldCoords(5).X = -52: FieldCoords(5).Y = -65
    FieldCoords(6).X = 55: FieldCoords(6).Y = -55
    FieldCoords(7).X = 65: FieldCoords(7).Y = -55
    FieldCoords(8).X = 55: FieldCoords(8).Y = -65
    FieldCoords(9).X = 65: FieldCoords(9).Y = -65
    
    FieldPointsTotal = FieldPointsMax
    For Count = 0 To FieldPointsTotal - 1
        FieldCoords(Count).X = Int(Rnd * 800) - 400
        FieldCoords(Count).Y = Int(Rnd * 800) - 400
    Next
    
    FieldScaleX = 1
    FieldScaleY = 1
    FieldScaleZ = 1
    FieldSkewX = 0
    FieldSkewY = 0
    FieldSkewZ = 0
    
End Sub

Private Sub Form_Resize()
    Dim FormWidth As Long
    Dim FormHeight As Long
    Dim Count As Long

    FormWidth = Me.ScaleWidth
    FormHeight = Me.ScaleHeight
    
    On Error GoTo IDontFreakinCareAboutResizeErrors
    With picField
    .Move 0, 120, FormWidth, FormHeight - (120 + 18)
    FieldOriginX = .ScaleWidth \ 2
    FieldOriginY = .ScaleHeight \ 2
    End With
    With lblFormula
    .Move 0, FormHeight - 16, FormWidth, 16
    End With
    For Count = hsbFieldFactor.LBound To hsbFieldFactor.UBound
        hsbFieldFactor(Count).Width = FormWidth - 48
    Next
IDontFreakinCareAboutResizeErrors:
    FieldRender
End Sub

Private Sub FieldRender()
    picField.Cls
    FieldApplyViewAngle FieldCoords, FieldPoints
    FieldDraw FieldPoints, &HFFD0FF
    
    FieldApplyTransformation FieldCoords, FieldCoords2
    FieldApplyViewAngle FieldCoords2, FieldPoints
    FieldDraw FieldPoints, &HFFFF&

    picField.PSet (FieldOriginX, FieldOriginY), &HFFFFFF
    
    lblFormula.Caption = "xp = (x * " & Format(FieldScaleX, "0.000") _
                       & ") + (y * " & Format(FieldSkewY, "0.000") _
                       & ");  yp = (y * " & Format(FieldScaleY, "0.000") _
                       & ") - (x * " & Format(FieldSkewX, "0.000") _
                       & ");  zp = (z * " & Format(FieldScaleZ, "0.000") _
                       & ") - (? * " & Format(FieldSkewZ, "0.000") _
                       & ")"
                       
    DoEvents
End Sub

Private Sub FieldLoad()

End Sub

Private Sub FieldStore()

End Sub

Private Sub FieldApplyTransformation(CoordsIn() As Point3D, CoordsOut() As Point3D)
    Dim Count As Long
    For Count = 0 To FieldPointsTotal - 1
        CoordsOut(Count).X = CoordsIn(Count).X * FieldScaleX + CoordsIn(Count).Y * FieldSkewX
        CoordsOut(Count).Y = CoordsIn(Count).Y * FieldScaleY - CoordsIn(Count).X * FieldSkewY
    Next
End Sub


Private Sub FieldApplyViewAngle(CoordsIn() As Point3D, CoordsOut() As Point2D)
'flattens 3D coordinates for 2D screen using current angle
    Dim Count As Long
    Select Case FieldViewAngle
    Case 0 'simple flat
        For Count = 0 To FieldPointsTotal - 1
            CoordsOut(Count).X = CoordsIn(Count).X
            CoordsOut(Count).Y = CoordsIn(Count).Y
        Next
    End Select
End Sub

Private Sub FieldDraw(CoordsIn() As Point2D, Clr As Long)
'draws single layer of points
    Dim Count As Long

    picField.ForeColor = Clr
    For Count = 0 To FieldPointsTotal - 1
        'picField.PSet (CoordsIn(Count).X + FieldOriginX, FieldOriginY - CoordsIn(Count).Y)
        picField.Line (CoordsIn(Count).X + FieldOriginX, FieldOriginY - CoordsIn(Count).Y)-(FieldCoords(Count).X + FieldOriginX, FieldOriginY - FieldCoords(Count).Y)
        'picField.Line (CoordsIn(Count).X + FieldOriginX, FieldOriginY - CoordsIn(Count).Y)-(FieldOriginX, FieldOriginY)
    Next
End Sub

Private Sub hsbFieldFactor_Change(Index As Integer)
    Dim MiscValue As Double

    If HsbFactorIgnoreChange Then Exit Sub
    HsbFactorIgnoreChange = True
    Select Case Index
    Case 0: FieldScaleX = hsbFieldFactor(0).Value / HsbFactorBase
    Case 1: FieldScaleY = hsbFieldFactor(1).Value / HsbFactorBase
    Case 2: FieldScaleZ = hsbFieldFactor(2).Value / HsbFactorBase
    Case 3: FieldScaleX = hsbFieldFactor(3).Value / HsbFactorBase
            FieldScaleY = FieldScaleX
            FieldScaleZ = FieldScaleX
            hsbFieldFactor(0).Value = FieldScaleX * HsbFactorBase
            hsbFieldFactor(1).Value = FieldScaleX * HsbFactorBase
            hsbFieldFactor(2).Value = FieldScaleX * HsbFactorBase
    Case 4: FieldSkewX = hsbFieldFactor(4).Value / HsbFactorBase
    Case 5: FieldSkewY = hsbFieldFactor(5).Value / HsbFactorBase
    Case 6: FieldSkewZ = hsbFieldFactor(6).Value / HsbFactorBase
    Case 7: FieldSkewX = hsbFieldFactor(7).Value / HsbFactorBase
            FieldSkewY = FieldSkewX
            FieldSkewZ = FieldSkewX
            hsbFieldFactor(4).Value = FieldSkewX * HsbFactorBase
            hsbFieldFactor(5).Value = FieldSkewX * HsbFactorBase
            hsbFieldFactor(6).Value = FieldSkewX * HsbFactorBase
    Case 8: MiscValue = hsbFieldFactor(8).Value / HsbFactorBase
            FieldSkewX = Sin(MiscValue)
            FieldSkewY = FieldSkewX
            FieldScaleX = Cos(MiscValue)
            FieldScaleY = FieldScaleX
            hsbFieldFactor(0).Value = FieldScaleX * HsbFactorBase
            hsbFieldFactor(1).Value = FieldScaleY * HsbFactorBase
            hsbFieldFactor(2).Value = FieldScaleZ * HsbFactorBase
            hsbFieldFactor(3).Value = FieldScaleX * HsbFactorBase
            hsbFieldFactor(4).Value = FieldSkewX * HsbFactorBase
            hsbFieldFactor(5).Value = FieldSkewY * HsbFactorBase
            hsbFieldFactor(6).Value = FieldSkewZ * HsbFactorBase
            hsbFieldFactor(7).Value = FieldSkewX * HsbFactorBase
    End Select
    HsbFactorIgnoreChange = False
    FieldRender
End Sub

Private Sub hsbFieldFactor_Scroll(Index As Integer)
    hsbFieldFactor_Change Index
End Sub

Private Sub mnuCredit_Click()
    MsgBox "Point Transform demo" & vbNewLine & "Achieves simultaneous scaling, skewing, flipping, and rotation with only two simple formulas, using multiplication and addition.", vbInformation
End Sub

Private Sub mnuFlipboth_Click()
    FieldScaleX = -1
    FieldScaleY = -1
    FieldSkewX = 0
    FieldSkewY = 0
    SetFieldFactors
End Sub

Private Sub mnuFlipvertical_Click()
    FieldScaleX = 1
    FieldScaleY = -1
    FieldSkewX = 0
    FieldSkewY = 0
    SetFieldFactors
End Sub

Private Sub mnuQuit_Click()
    Unload Me
End Sub

Private Sub mnuRefresh_Click()
    FieldRender
End Sub

Private Sub mnuRotateleft_Click()
    FieldScaleX = 0
    FieldScaleY = 0
    FieldSkewX = 1
    FieldSkewY = 1
    SetFieldFactors
End Sub

Private Sub mnuRotateOpposite_Click()
    FieldScaleX = -1
    FieldScaleY = -1
    FieldSkewX = 0
    FieldSkewY = 0
    SetFieldFactors
End Sub

Private Sub mnuRotateright_Click()
    FieldScaleX = 0
    FieldScaleY = 0
    FieldSkewX = -1
    FieldSkewY = -1
    SetFieldFactors
End Sub

Private Sub mnuScalelarge_Click()
    FieldScaleX = 2
    FieldScaleY = 2
    FieldSkewX = 0
    FieldSkewY = 0
    SetFieldFactors
End Sub

Private Sub mnuScaleshort_Click()
    FieldScaleX = 1
    FieldScaleY = 0.5
    FieldSkewX = 0
    FieldSkewY = 0
    SetFieldFactors
End Sub

Private Sub mnuScalesmall_Click()
    FieldScaleX = 0.5
    FieldScaleY = 0.5
    FieldSkewX = 0
    FieldSkewY = 0
    SetFieldFactors
End Sub

Private Sub mnuScaletall_Click()
    FieldScaleX = 1
    FieldScaleY = 2
    FieldSkewX = 0
    FieldSkewY = 0
    SetFieldFactors
End Sub

Private Sub mnuScalethin_Click()
    FieldScaleX = 0.5
    FieldScaleY = 1
    FieldSkewX = 0
    FieldSkewY = 0
    SetFieldFactors
End Sub

Private Sub mnuScalewide_Click()
    FieldScaleX = 2
    FieldScaleY = 1
    FieldSkewX = 0
    FieldSkewY = 0
    SetFieldFactors
End Sub

Private Sub mnuSkewdown_Click()
    FieldScaleX = 1
    FieldScaleY = 1
    FieldSkewX = 0
    FieldSkewY = 1
    SetFieldFactors
End Sub

Private Sub mnuSkewleft_Click()
    FieldScaleX = 1
    FieldScaleY = 1
    FieldSkewX = 1
    FieldSkewY = 0
    SetFieldFactors
End Sub

Private Sub mnuSkewright_Click()
    FieldScaleX = 1
    FieldScaleY = 1
    FieldSkewX = -1
    FieldSkewY = 0
    SetFieldFactors
End Sub

Private Sub mnuSkewup_Click()
    FieldScaleX = 1
    FieldScaleY = 1
    FieldSkewX = 0
    FieldSkewY = -1
    SetFieldFactors
End Sub

Private Sub mnuTransformNormal_Click()
    FieldScaleX = 1
    FieldScaleY = 1
    FieldSkewX = 0
    FieldSkewY = 0
    SetFieldFactors
End Sub

Public Sub SetFieldFactors()
    HsbFactorIgnoreChange = True
    hsbFieldFactor(0).Value = FieldScaleX * HsbFactorBase
    hsbFieldFactor(1).Value = FieldScaleY * HsbFactorBase
    hsbFieldFactor(2).Value = FieldScaleZ * HsbFactorBase
    hsbFieldFactor(3).Value = (FieldScaleX + FieldScaleY) * HsbFactorBase \ 2
    hsbFieldFactor(4).Value = FieldSkewX * HsbFactorBase
    hsbFieldFactor(5).Value = FieldSkewY * HsbFactorBase
    hsbFieldFactor(6).Value = FieldSkewZ * HsbFactorBase
    hsbFieldFactor(7).Value = (FieldSkewX + FieldSkewY) * HsbFactorBase \ 2
    HsbFactorIgnoreChange = False
    FieldRender
End Sub

Private Sub nmuFliphorizontal_Click()
    FieldScaleX = -1
    FieldScaleY = 1
    FieldSkewX = 0
    FieldSkewY = 0
    SetFieldFactors
End Sub
