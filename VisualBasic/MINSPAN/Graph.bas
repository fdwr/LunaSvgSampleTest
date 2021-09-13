Attribute VB_Name = "modGraph"
DefLng A-Z
Option Explicit

Type VertexType
X As Integer
Y As Integer
Used As Integer
Dummy As Integer
End Type

Type EdgeType
A As Integer
B As Integer
Weight As Integer
Highlight As Integer
End Type

Public Const EdgesMax As Long = 100
Public Const VertexesMax As Long = 200
Private Const VertexSize As Long = 8
Public Vertexes(EdgesMax) As VertexType
Public Edges(VertexesMax) As EdgeType
Public EdgesTotal As Long
Public VertexesTotal As Long
Public EdgeSelected As Long
Public VertexSelected As Long

Public GraphRedrawOnAdd As Boolean
Public GraphDrawLabels As Boolean
Public GraphPoints As String

Private Surface As Form
Private SurfaceHdc As Long
Private MessageObject As Object

Public Sub GraphSetSurface(NewSurface As Object)
    NewSurface.ScaleMode = vbPixels 'just in case
    Set Surface = NewSurface
    SurfaceHdc = NewSurface.hdc
End Sub

Public Sub GraphDraw()
    Dim Count As Long, Clr As Long

    For Count = 0 To VertexesTotal - 1
        GraphDrawVertex Count
    Next
    For Count = 0 To EdgesTotal - 1
        GraphDrawEdge Count
    Next

End Sub

Public Sub GraphDrawVertex(Vertex As Long)
    Dim Clr As Long
    If Vertex >= VertexesTotal Or Vertex < 0 Then Exit Sub
    If Vertex = VertexSelected Then Clr = &HFFFFFF Else Clr = &HDDDDFF
    Surface.Circle (Vertexes(Vertex).X, Vertexes(Vertex).Y), VertexSize, Clr
    If GraphDrawLabels Then
        SurfaceHdc = Surface.hdc
        TextOut SurfaceHdc, Vertexes(Vertex).X - VertexSize * 2, Vertexes(Vertex).Y - VertexSize \ 2, Chr$(Vertex + 65), 1
    End If
End Sub

Public Sub GraphDrawEdge(Edge As Long)
    Dim A As Integer, B As Integer
    Dim X1, X2, Y1, Y2
    Dim Clr As Long

    If Edge >= EdgesTotal Or Edge < 0 Then Exit Sub
    A = Edges(Edge).A
    B = Edges(Edge).B
    X1 = Vertexes(A).X
    Y1 = Vertexes(A).Y
    X2 = Vertexes(B).X
    Y2 = Vertexes(B).Y
    
    If Edges(Edge).Highlight = True Then Clr = &HFFDDEE Else Clr = &HFF0000
    Surface.Line (X1, Y1)-(X2, Y2), Clr
    If GraphDrawLabels Then
        Dim Label  As String
        Label = Str$(Edges(Edge).Weight)
        TextOut SurfaceHdc, (X1 + X2) \ 2, (Y1 + Y2) \ 2, Label, Len(Label)
    End If
End Sub

Public Sub GraphClear()
    EdgesTotal = 0
    VertexesTotal = 0
    Surface.Cls
End Sub

Public Sub GraphAddVertex(X As Long, Y As Long)
    If VertexesTotal < VertexesMax Then
        Vertexes(VertexesTotal).X = X
        Vertexes(VertexesTotal).Y = Y
        Vertexes(VertexesTotal).Used = False
        VertexesTotal = VertexesTotal + 1
        If GraphRedrawOnAdd Then GraphDrawVertex VertexesTotal - 1
    End If
End Sub

Public Sub GraphAddEdge(A As Long, B As Long, Weight As Long)
    If EdgesTotal < EdgesMax Then
        If A >= VertexesTotal Then Exit Sub
        If B >= VertexesTotal Then Exit Sub
        Edges(EdgesTotal).A = A
        Edges(EdgesTotal).B = B
        Edges(EdgesTotal).Weight = Weight
        Edges(EdgesTotal).Highlight = False
        EdgesTotal = EdgesTotal + 1
        If GraphRedrawOnAdd Then GraphDrawEdge EdgesTotal - 1
    End If
End Sub

Public Function GraphNearestVertex(X As Long, Y As Long)
    Dim Count As Long

    For Count = 0 To VertexesTotal - 1
        If Abs(X - Vertexes(Count).X) <= VertexSize Then
            If Abs(Y - Vertexes(Count).Y) <= VertexSize Then
                GraphNearestVertex = Count
                Exit Function
            End If
        End If
    Next
    GraphNearestVertex = -1
End Function

Public Sub GraphFlip(Direction As Long, Center As Long)

End Sub

Public Sub GraphRotate(Direction As Long, Center As Long)

End Sub

Public Sub GraphCenter(Center As Long)

End Sub


Public Sub GraphPrimsMinimalTree()
    Dim Count As Long
    Dim Edge As Long
    Dim A As Long, B As Long
    Dim CurrentWeight As Long
    Dim LabelSum As Long

    GraphPoints = ""
    For Count = 0 To EdgesTotal - 1
        Edges(Count).Highlight = False
    Next
    For Count = 0 To VertexesTotal - 1
        Vertexes(Count).Used = False
    Next
    If VertexSelected < 0 Or VertexSelected > VertexesTotal Then VertexSelected = 0
    Vertexes(VertexSelected).Used = True

    GoTo PrimsInside
    Do
        Edges(Edge).Highlight = True
        A = Edges(Edge).A
        B = Edges(Edge).B
        Vertexes(A).Used = True
        Vertexes(B).Used = True
        GraphPoints = GraphPoints & Chr$(A + 65) & Chr$(B + 65) & ","
PrimsInside:
        'choose smallest edge along current tree
        'that does not form a cycle
        CurrentWeight = 2147483647
        LabelSum = 2147483647
        For Count = EdgesTotal - 1 To 0 Step -1
            If Edges(Count).Highlight = False Then
                A = Edges(Count).A
                B = Edges(Count).B
                If Vertexes(A).Used And Vertexes(B).Used Then
                    Edges(Count).Highlight = 1
                ElseIf Vertexes(A).Used Or Vertexes(B).Used Then
                    If Edges(Count).Weight < CurrentWeight _
                    Or (Edges(Count).Weight = CurrentWeight _
                    And A + B < LabelSum) Then
                        Edge = Count
                        CurrentWeight = Edges(Count).Weight
                        LabelSum = A + B
                    End If
                End If
            End If
        Next
    Loop Until CurrentWeight = 2147483647
End Sub

Public Sub GraphKruskalsMinimalTree()
    'MsgBox "Kruskal's Minimal Tree is unfinished"
    Dim Count As Long
    Dim ActiveEdgesTotal As Long
    Dim Edge As Long
    Dim Weight As Long
    Dim CurrentWeight As Long
    Dim NextWeight As Long
    Dim A As Long, B As Long
    Dim ActiveEdges(EdgesMax) As Integer

    GraphPoints = ""
    ActiveEdgesTotal = EdgesTotal
    CurrentWeight = 2147483647
    For Count = 0 To EdgesTotal - 1
        ActiveEdges(Count) = Count
        If Edges(Count).Weight < CurrentWeight Then
            CurrentWeight = Edges(Count).Weight
        End If
        Edges(Count).Highlight = False
    Next
    For Count = 0 To VertexesTotal - 1
        Vertexes(Count).Used = False
    Next
    Do Until ActiveEdgesTotal <= 0
        NextWeight = -2147483647
        Count = 0
        Do Until Count >= ActiveEdgesTotal
            Edge = ActiveEdges(Count)
            Weight = Edges(Edge).Weight
            If Weight >= CurrentWeight Then
                'delete edge
                A = Edges(Edge).A
                B = Edges(Edge).B
                If Vertexes(A).Used And Vertexes(B).Used Then
                    'simply delete edge from active list
                Else
                    Edges(Edge).Highlight = True
                    Vertexes(A).Used = True
                    Vertexes(B).Used = True
                End If
                ActiveEdgesTotal = ActiveEdgesTotal - 1
                ActiveEdges(Count) = ActiveEdges(ActiveEdgesTotal)
            Else
                If Weight > NextWeight Then NextWeight = Weight
                Count = Count + 1
            End If
        Loop
        'ActiveEdgesTotal = ActiveEdgesTotal - 1
        CurrentWeight = NextWeight
    Loop
End Sub

