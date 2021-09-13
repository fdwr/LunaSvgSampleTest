VERSION 5.00
Begin VB.Form frmGraph 
   Caption         =   "Graph"
   ClientHeight    =   6525
   ClientLeft      =   60
   ClientTop       =   345
   ClientWidth     =   7065
   BeginProperty Font 
      Name            =   "Small Fonts"
      Size            =   6.75
      Charset         =   0
      Weight          =   400
      Underline       =   0   'False
      Italic          =   0   'False
      Strikethrough   =   0   'False
   EndProperty
   Icon            =   "Graph.frx":0000
   LinkTopic       =   "Form1"
   ScaleHeight     =   435
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   471
   ShowInTaskbar   =   0   'False
   StartUpPosition =   3  'Windows Default
   Visible         =   0   'False
End
Attribute VB_Name = "frmGraph"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Private MouseDown As Boolean

Private Sub Form_Load()
    GraphRedrawOnAdd = True
    GraphDrawLabels = True
    GraphSetSurface Me
End Sub

Private Sub Form_MouseDown(Button As Integer, Shift As Integer, Xs As Single, Ys As Single)
    Dim Vertex As Long, X As Long, Y As Long
    X = Xs 'to prevent retarded ByRef mismatch errors,
    Y = Ys 'WHY does mouse down send them as singles anyway?

    If (Button And 1) = 0 Then Exit Sub
    MouseDown = True

    Vertex = GraphNearestVertex(X, Y)

    Dim Temp As Long
    Temp = VertexSelected
    If Vertex >= 0 Then
        VertexSelected = Vertex
        GraphDrawVertex Temp
        GraphDrawVertex VertexSelected
    Else
        VertexSelected = VertexesTotal
        GraphDrawVertex Temp
        GraphAddVertex X, Y
    End If
End Sub

Private Sub Form_MouseUp(Button As Integer, Shift As Integer, Xs As Single, Ys As Single)
    Dim Vertex As Long, X As Long, Y As Long
    X = Xs 'to prevent retarded ByRef mismatch errors,
    Y = Ys 'WHY does mouse down send them as singles anyway?

    If (Button And 1) = 0 Then Exit Sub
    If Not MouseDown Then Exit Sub
    MouseDown = False
    If VertexSelected < 0 Then Exit Sub

    Vertex = GraphNearestVertex(X, Y)
    If Vertex >= 0 Then
        If Vertex <> VertexSelected Then
            GraphAddEdge VertexSelected, Vertex, frmEdgeWeight.GetEdgeWeight(X * Screen.TwipsPerPixelX + Left, Y * Screen.TwipsPerPixelY + Top)
        End If
    End If
End Sub

Private Sub Form_Paint()
    GraphDraw
End Sub

Private Sub Form_Resize()
    If WindowState = vbMinimized Then
        If frmPoints.WindowState <> vbMinimized Then frmPoints.WindowState = vbMinimized
    ElseIf WindowState = vbNormal Then
        If frmPoints.WindowState <> vbNormal Then frmPoints.WindowState = vbNormal
    End If
End Sub

Private Sub Form_Unload(Cancel As Integer)
    Terminate = True
End Sub

