VERSION 5.00
Begin VB.Form frmPoints 
   BorderStyle     =   1  'Fixed Single
   Caption         =   "Graph Points"
   ClientHeight    =   6435
   ClientLeft      =   150
   ClientTop       =   720
   ClientWidth     =   2655
   HasDC           =   0   'False
   Icon            =   "Points.frx":0000
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   ScaleHeight     =   6435
   ScaleWidth      =   2655
   StartUpPosition =   3  'Windows Default
   Visible         =   0   'False
   Begin VB.TextBox txtPoints 
      Height          =   285
      Left            =   0
      TabIndex        =   2
      Top             =   0
      Width           =   2655
   End
   Begin VB.ListBox lstEdges 
      Height          =   5715
      Left            =   1320
      TabIndex        =   1
      Top             =   360
      Width           =   1335
   End
   Begin VB.ListBox lstVertexes 
      Height          =   5715
      Left            =   0
      TabIndex        =   0
      Top             =   360
      Width           =   1290
   End
   Begin VB.Menu mnuGraph 
      Caption         =   "&Graph"
      Begin VB.Menu mnuNew 
         Caption         =   "&New"
      End
      Begin VB.Menu mnuDehighlight 
         Caption         =   "&Dehighlight"
      End
      Begin VB.Menu mnuDumbSep0 
         Caption         =   "-"
      End
      Begin VB.Menu mnuAlignWindows 
         Caption         =   "Re&align windows"
      End
      Begin VB.Menu mnuClose 
         Caption         =   "&Close"
      End
   End
   Begin VB.Menu mnuFind 
      Caption         =   "&Find"
      Begin VB.Menu mnuPrims 
         Caption         =   "&Prim's minimal tree"
      End
      Begin VB.Menu mnuKruskal 
         Caption         =   "&Kruskal's minimal tree"
      End
   End
End
Attribute VB_Name = "frmPoints"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Private Sub Form_Resize()
    lstVertexes.Height = Me.ScaleHeight
    lstEdges.Height = Me.ScaleHeight
    If WindowState = vbMinimized Then
        If frmGraph.WindowState <> vbMinimized Then frmGraph.WindowState = vbMinimized
    ElseIf WindowState = vbNormal Then
        If frmGraph.WindowState <> vbNormal Then frmGraph.WindowState = vbNormal
    End If
End Sub

Private Sub Form_Unload(Cancel As Integer)
    Terminate = True
End Sub

Private Sub mnuAlignWindows_Click()
    PositionGraphWindows
End Sub

Private Sub mnuClose_Click()
    Terminate = True
End Sub

Private Sub mnuDehighlight_Click()
    Dim Count As Long
    For Count = 0 To EdgesTotal - 1
        Edges(Count).Highlight = False
    Next
    GraphDraw
End Sub

Private Sub mnuKruskal_Click()
    GraphKruskalsMinimalTree
    GraphDraw
    txtPoints.Text = GraphPoints
End Sub

Private Sub mnuNew_Click()
    GraphClear
End Sub

Private Sub mnuPrims_Click()
    GraphPrimsMinimalTree
    GraphDraw
    txtPoints.Text = GraphPoints
End Sub
