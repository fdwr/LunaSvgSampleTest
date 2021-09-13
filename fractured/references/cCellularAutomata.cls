VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "cCellularAutomata"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private Declare Sub CopyMemory Lib "kernel32" Alias "RtlMoveMemory" ( _
    lpvDest As Any, lpvSource As Any, ByVal cbCopy As Long)

Private Type SAFEARRAYBOUND
    cElements As Long
    lLbound As Long
End Type
Private Type SAFEARRAY2D
    cDims As Integer
    fFeatures As Integer
    cbElements As Long
    cLocks As Long
    pvData As Long
    Bounds(0 To 1) As SAFEARRAYBOUND
End Type
Private Declare Function VarPtrArray Lib "msvbvm50.dll" Alias "VarPtr" (Ptr() As Any) As Long

Private m_cDib As cDIBSection256
Private m_cDibLast As cDIBSection256
Private m_lWidth As Long
Private m_lHeight As Long
Private m_lStates As Long
Private Type tOffset
   x As Long
   y As Long
   bUse As Boolean
End Type
Private m_tNeighbourOffset(0 To 8) As tOffset
Private m_lColorLight As Long
Private m_lColorDark As Long

Public Property Get ColorDark() As OLE_COLOR
   ColorDark = m_lColorDark
End Property
Public Property Let ColorDark(ByVal lColor As OLE_COLOR)
   m_lColorDark = lColor
   States = m_lStates
End Property
Public Property Get ColorLight() As OLE_COLOR
   ColorLight = m_lColorLight
End Property
Public Property Let ColorLight(ByVal lColor As OLE_COLOR)
   m_lColorLight = lColor
   States = m_lStates
End Property
Public Property Get States() As Long
   States = m_lStates
End Property
Public Property Let States(ByVal lStates As Long)
   
   m_lStates = lStates
   ReDim lColor(0 To States) As Long
   Dim i As Long
   Dim rS As Long, gS As Long, bS As Long
   Dim rE As Long, gE As Long, bE As Long
   rS = m_lColorDark And &HFF&
   gS = (m_lColorDark And &HFF00&) \ &H100&
   bS = (m_lColorDark And &HFF0000) \ &H10000
   rE = m_lColorLight And &HFF&
   gE = (m_lColorLight And &HFF00&) \ &H100&
   bE = (m_lColorLight And &HFF0000) \ &H10000
   For i = 0 To States
      lColor(i) = RGB( _
         rS + (i * (rE - rS)) \ States, _
         gS + (i * (gE - gS)) \ States, _
         bS + (i * (bE - bS)) \ States _
         )
   Next i
   m_cDib.SetPalette lColor
   m_cDibLast.SetPalette lColor
   
End Property
Public Property Get Width() As Long
   Width = m_lWidth
End Property
Public Property Let Width(ByVal lWidth As Long)
   m_lWidth = lWidth
End Property
Public Property Get Height() As Long
   Height = m_lHeight
End Property
Public Property Let Height(ByVal lHeight As Long)
   m_lHeight = lHeight
End Property

Public Sub Init()
   If Not (m_lWidth = m_cDib.Width) Or Not (m_lHeight = m_cDib.Height) Then
      m_cDib.Create m_lWidth, m_lHeight
      m_cDibLast.Create m_lWidth, m_lHeight
   End If
   m_cDibLast.RandomiseBits m_lStates
   m_cDibLast.PaintPicture m_cDib.hdc
End Sub

Public Sub Paint( _
      ByVal lHDC As Long, _
      Optional ByVal lLeft As Long = 0, _
      Optional ByVal lTop As Long = 0 _
   )
   m_cDib.PaintPicture lHDC, lLeft, lTop, m_lWidth, m_lHeight
End Sub

Public Sub AddRandom(ByVal lPercent As Long)
Dim tSALast As SAFEARRAY2D
Dim bDibLast() As Byte
Dim x As Long
Dim y As Long

   lPercent = 100 - lPercent
   With tSALast
       .cbElements = 1
       .cDims = 2
       .Bounds(0).lLbound = 0
       .Bounds(0).cElements = m_cDibLast.Height
       .Bounds(1).lLbound = 0
       .Bounds(1).cElements = m_cDibLast.BytesPerScanLine()
       .pvData = m_cDibLast.DIBSectionBitsPtr
   End With
   CopyMemory ByVal VarPtrArray(bDibLast()), VarPtr(tSALast), 4

   For x = 0 To m_cDib.Width - 1
      For y = 0 To m_cDib.Height - 1
         If (Rnd * 100 > lPercent) Then
            bDibLast(x, y) = Rnd * m_lStates
         End If
      Next y
   Next x
   
   ' Clear the temporary array descriptor
   CopyMemory ByVal VarPtrArray(bDibLast), 0&, 4

End Sub

Public Sub Step()
Dim x As Long
Dim y As Long
Dim tSALast As SAFEARRAY2D
Dim tSA As SAFEARRAY2D
Dim bDibLast() As Byte
Dim bDibNext() As Byte
Dim lOldStateInc As Long
Dim i As Long
Dim j As Long
Dim lOffset As Long
   
   With tSALast
       .cbElements = 1
       .cDims = 2
       .Bounds(0).lLbound = 0
       .Bounds(0).cElements = m_cDibLast.Height
       .Bounds(1).lLbound = 0
       .Bounds(1).cElements = m_cDibLast.BytesPerScanLine()
       .pvData = m_cDibLast.DIBSectionBitsPtr
   End With
   CopyMemory ByVal VarPtrArray(bDibLast()), VarPtr(tSALast), 4

   With tSA
       .cbElements = 1
       .cDims = 2
       .Bounds(0).lLbound = 0
       .Bounds(0).cElements = m_cDib.Height
       .Bounds(1).lLbound = 0
       .Bounds(1).cElements = m_cDib.BytesPerScanLine()
       .pvData = m_cDib.DIBSectionBitsPtr
   End With
   CopyMemory ByVal VarPtrArray(bDibNext()), VarPtr(tSA), 4

   ' Run the cellular automata step:
   For x = 0 To m_cDib.Width - 1
      For y = 0 To m_cDib.Height - 1
         
         lOldStateInc = bDibLast(x, y) + 1
         If (lOldStateInc > m_lStates - 1) Then
            lOldStateInc = 0
         End If
         
         For lOffset = 0 To 8
            If (m_tNeighbourOffset(lOffset).bUse) Then
               i = x + m_tNeighbourOffset(lOffset).x
               If (i < 0) Then i = m_cDib.Width - 1
               If (i >= m_cDib.Width) Then i = 0
               j = y + m_tNeighbourOffset(lOffset).y
               If (j < 0) Then j = m_cDib.Height - 1
               If (j >= m_cDib.Height) Then j = 0
                  
               If (bDibLast(i, j) = lOldStateInc) Then
                  bDibNext(x, y) = bDibLast(i, j)
               End If
            End If
         Next lOffset
         
      Next y
   Next x
   
   ' Copy New -> Old
   m_cDib.PaintPicture m_cDibLast.hdc

   ' Clear the temporary array descriptor
   CopyMemory ByVal VarPtrArray(bDibNext), 0&, 4
   CopyMemory ByVal VarPtrArray(bDibLast), 0&, 4

End Sub

Public Property Get ConsiderNeighbour(ByVal xOffset As Long, ByVal yOffset As Long) As Boolean
Dim i As Long
   For i = 0 To 8
      If (m_tNeighbourOffset(i).x = xOffset) And (m_tNeighbourOffset(i).y = yOffset) Then
         ConsiderNeighbour = m_tNeighbourOffset(i).bUse
         Exit For
      End If
   Next i
End Property
Public Property Let ConsiderNeighbour(ByVal xOffset As Long, ByVal yOffset As Long, ByVal bState As Boolean)
Dim i As Long
Dim iFirstFree As Long
   
   iFirstFree = -1
   For i = 0 To 8
      If (m_tNeighbourOffset(i).x = xOffset) And (m_tNeighbourOffset(i).y = yOffset) Then
         m_tNeighbourOffset(i).bUse = bState
         ' done
         Exit Property
      Else
         If (m_tNeighbourOffset(i).x = 0) And (m_tNeighbourOffset(i).y = 0) Then
            iFirstFree = i
         End If
      End If
   Next i
   
   With m_tNeighbourOffset(iFirstFree)
      .x = xOffset
      .y = yOffset
      .bUse = bState
   End With
      
End Property

Private Sub Class_Initialize()
   
   m_lColorDark = RGB(22, 32, 64)
   m_lColorLight = RGB(90, 128, 255)

   With m_tNeighbourOffset(0)
      .x = 0
      .y = -1
   End With
   With m_tNeighbourOffset(1)
      .x = -1
      .y = 0
   End With
   With m_tNeighbourOffset(2)
      .x = 1
      .y = 0
   End With
   With m_tNeighbourOffset(3)
      .x = 0
      .y = 1
   End With
   Dim i As Long
   For i = 0 To 8
      m_tNeighbourOffset(i).bUse = (i <= 3)
   Next i
      
   m_lStates = 16
   
   m_lWidth = 256
   m_lHeight = 256
   
   Set m_cDib = New cDIBSection256
   Set m_cDibLast = New cDIBSection256
   Init
   States = m_lStates
      
End Sub
