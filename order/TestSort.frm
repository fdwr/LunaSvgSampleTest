VERSION 5.00
Begin VB.Form frmTestSort 
   Caption         =   "Test Sort"
   ClientHeight    =   4170
   ClientLeft      =   60
   ClientTop       =   345
   ClientWidth     =   6225
   Icon            =   "TestSort.frx":0000
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   4170
   ScaleWidth      =   6225
   StartUpPosition =   2  'CenterScreen
   Begin VB.OptionButton optMultiple 
      Caption         =   "Multiple"
      Height          =   255
      Left            =   120
      TabIndex        =   8
      ToolTipText     =   "Order multiple columns of data"
      Top             =   3120
      Value           =   -1  'True
      Width           =   1215
   End
   Begin VB.CheckBox chkInternalCb 
      Caption         =   "Internal Callback"
      Height          =   375
      Left            =   120
      TabIndex        =   7
      ToolTipText     =   "Use faster internal DLL callback or slower VB callback"
      Top             =   3600
      Value           =   1  'Checked
      Width           =   1215
   End
   Begin VB.CommandButton cmdAbort 
      Cancel          =   -1  'True
      Caption         =   "Abort"
      Enabled         =   0   'False
      Height          =   495
      Left            =   120
      TabIndex        =   2
      ToolTipText     =   "Signals the ordering routine to abort"
      Top             =   1320
      Width           =   1215
   End
   Begin VB.OptionButton optStrings 
      Caption         =   "Strings"
      Height          =   255
      Left            =   120
      TabIndex        =   5
      ToolTipText     =   "Orders OLE2 BTSRs using internal callback"
      Top             =   2760
      Width           =   1215
   End
   Begin VB.OptionButton optSingles 
      Caption         =   "Singles"
      Height          =   255
      Left            =   120
      TabIndex        =   4
      ToolTipText     =   "Orders IEEE 32bit reals"
      Top             =   2400
      Width           =   1215
   End
   Begin VB.OptionButton optLongs 
      Caption         =   "Longs"
      Height          =   255
      Left            =   120
      TabIndex        =   3
      ToolTipText     =   "Orders signed 32bit integers using internal callback"
      Top             =   2040
      Width           =   1215
   End
   Begin VB.CommandButton cmdSort 
      Caption         =   "Sort"
      Height          =   495
      Left            =   120
      TabIndex        =   1
      ToolTipText     =   "Starts ordering the selected array type"
      Top             =   720
      Width           =   1215
   End
   Begin VB.ListBox lstValues 
      Height          =   3960
      Left            =   1440
      TabIndex        =   6
      Top             =   120
      Width           =   4695
   End
   Begin VB.CommandButton cmdRandomize 
      Caption         =   "Randomize"
      Height          =   495
      Left            =   120
      TabIndex        =   0
      ToolTipText     =   "Randomizes the selected array type"
      Top             =   120
      Width           =   1215
   End
End
Attribute VB_Name = "frmTestSort"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
'Ordering example using Comb sort
'Example of DLL calls and VB callbacks
'
'The DLL was written in assembler for SPEED :)
'The called ordering routine can theoretically order any kind of 32bit data,
'because it doesn't do any comparisons itself. Instead, it uses a called
'function to tell it whether or not to swap (yes, it's an old concept).
'
'The DLL includes a few built in comparison functions for the most common
'types of data (32bit signed integers, floating point singles, typical null
'terminated char strings, Unicode strings, and VB strings). Each type includes
'both ascending and descending order. For other types of data, or for other
'less common preferences of sorting, a callback can be given. For example,
'imagine you want to sort an array of color values (32bit integers) by
'brightness (sum of R+G+B).
'
'This example includes both internal (within the DLL) and external (routines
'in VB) callbacks. Unless you have special ordering needs, use the internal
'ones because as you will notice, (no surprise) they are siginificantly faster.
'The example VB callbacks are just that, examples. I find it strange that the
'VB FPU callback is actually faster than the integer callback. Also, I must
'give VB credit for their string comparison. Mine is only three times faster,
'and honestly I expected it to be more.
'
'This was tested on a 350MHz machine, so if yours is slower, reduce the
'size of the arrays to lessen intolerable waiting.
'
'                         Unsorted            Already Ordered
'                   External    Internal    External    Internal
' 100,000 longs      9.8          .89        3.2         .26
' 100,000 singles    9.6         1.02        3.1         .30
' 100,000 strings   16.4         6.14        5.4        2.00
'
'The results above are averages of the tests after the first one, since the
'first test was always slower than later ones (in both internal and external),
'probably something to do with uncached memory or something similar. The comb
'ordering routine performs well on already ordered data too, taking a third as
'long as unordered data.
'
'
'The code this was based on (from www.vbcode.com)
'
'    Dim I, J, Temp As Integer
'    Const Shrink = 1.3
'    Dim Gap As Single
'    Dim Swapped As Boolean
'    Gap = Arrsize - 1
'
'    Do
'        Gap = Int(Gap / Shrink)
'        Swapped = True
'        Combcom = Combcom + 1
'        For J = 0 To Arrsize - Gap
'            If Array3(J) > Array3(J + Gap) Then
'            Temp = Array3(J)
'            Array3(J) = Array3(J + Gap)
'            Array3(J + Gap) = Temp
'            Swapped = False
'            Combswap = Combswap + 1
'            End If
'        Next J
'    Loop Until Not Swapped And Gap = 1
'
'    For I = 0 To Arrsize
'       lstcomb.AddItem Array3(I)
'    Next I
'
'
'Just happened to be listening to this cool song while writing this:
'Kaliya - Ritual Tibetan (Gigi D'Agostino Remix (Radio Mix))

Option Explicit
DefLng A-Z

Private Declare Function SendMessage Lib "user32" Alias "SendMessageA" (ByVal hwnd As Long, ByVal wMsg As Long, ByVal wParam As Long, lParam As Any) As Long
Private Const LB_SETTABSTOPS = &H192

Private Sub cmdAbort_Click()
AbortSort = True
Caption = "Aborting sort"
End Sub

Private Sub cmdRandomize_Click()

Caption = "Randomizing values..."
DoEvents

If optLongs.Value Or LongArray(0) = 0 Then
    For Counter = 0 To LongArraySize - 1
        LongArray(Counter) = Int(Rnd * 10000) - 5000
    Next
End If
If optSingles.Value Or SingleArray(0) = 0 Then
    For Counter = 0 To SingleArraySize - 1
        SingleArray(Counter) = (Rnd * 10000) - 5000
    Next
End If
If optStrings.Value Or Len(StringArray(0)) <= 0 Then
    Dim TempStr As String
    For Counter = 0 To StringArraySize - 1
        TempStr = Space$(Int(Rnd * 5) + 10)
        For SubCounter = 1 To Len(TempStr)
            Mid$(TempStr, SubCounter, 1) = Chr$(Int(Rnd * 26) + 65)
        Next
        StringArray(Counter) = TempStr
    Next
End If
If optMultiple.Value Then
    StringArray(0) = "Ranma": LongArray(0) = 3: SingleArray(0) = 28.5
    StringArray(1) = "Ranma": LongArray(1) = 2: SingleArray(1) = 27.3
    StringArray(2) = "Ranma": LongArray(2) = 4: SingleArray(2) = 29.1
    StringArray(3) = "Cowboy Bebop": LongArray(3) = 5: SingleArray(3) = 24.6
    StringArray(4) = "Cowboy Bebop": LongArray(4) = 1: SingleArray(4) = 22.1
    StringArray(5) = "Cowboy Bebop": LongArray(5) = 9: SingleArray(5) = 20.5
    StringArray(6) = "Inuyasha": LongArray(6) = 5: SingleArray(6) = 27.4
    StringArray(7) = "Inuyasha": LongArray(7) = 20: SingleArray(7) = 26.3
    StringArray(8) = "Inuyasha": LongArray(8) = 3: SingleArray(8) = 25.5
    StringArray(9) = "Inuyasha": LongArray(9) = 4: SingleArray(9) = 26.6
End If

AddListItems
Caption = "Test Sort"

End Sub

Private Sub cmdSort_Click()
Dim StartTime As Single, EndTime As Single
Dim Entries As Long
Dim InternalCb As Boolean

EscCallbacks = 0
AbortSort = False
cmdAbort.Enabled = True
cmdSort.Enabled = False
cmdRandomize.Enabled = False
InternalCb = chkInternalCb.Value

StartTime = Timer
Select Case True
Case optLongs.Value
    If InternalCb Then
        CombOrder LongArray(0), LongArraySize, CmpLongSA, AddressOf EscCallBack
    Else
        CombOrder LongArray(0), LongArraySize, AddressOf CmpLongAscCb, AddressOf EscCallBack
    End If
    Entries = LongArraySize
Case optSingles.Value
    If InternalCb Then
        CombOrder SingleArray(0), SingleArraySize, CmpSngA, AddressOf EscCallBack
    Else
        CombOrder SingleArray(0), SingleArraySize, AddressOf CmpSngAscCb, AddressOf EscCallBack
    End If
    Entries = SingleArraySize
Case optStrings.Value
    If InternalCb Then
        CombOrder ByVal VarPtr(StringArray(0)), StringArraySize, CmpStrBA, AddressOf EscCallBack
    Else
        CombOrder ByVal VarPtr(StringArray(0)), StringArraySize, AddressOf CmpStrAscCb, AddressOf EscCallBack
    End If
    Entries = StringArraySize
Case optMultiple.Value
    CombOrderX3 3, 2, 10, AddressOf EscCallBack, _
        ByVal VarPtr(StringArray(0)), CmpStrBA, _
        LongArray(0), CmpLongSA, _
        SingleArray(0), CmpSngA
    'CombOrderX3 3, 3, 10, AddressOf EscCallBack, _
    '    LongArray(0), CmpLongSA, _
    '    SingleArray(0), CmpSngA, _
    '    ByVal VarPtr(StringArray(0)), CmpStrBA
    Entries = 10
End Select
EndTime = Timer

Caption = Entries & " array entries in " & EndTime - StartTime & " seconds"
cmdAbort.Enabled = False
cmdSort.Enabled = True
cmdRandomize.Enabled = True
AddListItems

End Sub

Private Sub Form_Load()
Show
cmdRandomize_Click
SetListTabStops lstValues.hwnd, 80, 110
End Sub

Private Sub optLongs_Click()
AddListItems
End Sub

Private Sub optMultiple_Click()
AddListItems
End Sub

Private Sub optSingles_Click()
AddListItems
End Sub

Private Sub optStrings_Click()
AddListItems
End Sub

Private Sub AddListItems()
Dim CountStep As Long

lstValues.Clear
Select Case True
Case optLongs.Value
    CalcCounterStep LongArraySize, 5000, CountStep
    For Counter = 0 To LongArraySize - 1 Step CountStep
        lstValues.AddItem Str$(LongArray(Counter))
    Next
Case optSingles.Value
    CalcCounterStep SingleArraySize, 5000, CountStep
    For Counter = 0 To SingleArraySize - 1 Step CountStep
        lstValues.AddItem Str$(SingleArray(Counter))
    Next
Case optStrings.Value
    CalcCounterStep StringArraySize, 5000, CountStep
    For Counter = 0 To StringArraySize - 1 Step CountStep
        lstValues.AddItem StringArray(Counter)
    Next
Case optMultiple.Value
    For Counter = 0 To 9
        lstValues.AddItem StringArray(Counter) & vbTab & LongArray(Counter) & vbTab & SingleArray(Counter)
    Next
End Select

End Sub

'Loading over 5000 entries takes too long, so calculate
'a step count for the FOR loop to skip every few items.
Private Sub CalcCounterStep(LoopCount, LoopMax, CountStep)

If LoopCount > LoopMax Then
    CountStep = LoopCount \ LoopMax
Else
    CountStep = 1
End If

End Sub

Public Sub SetListTabStops(ListHandle As Long, _
    ParamArray ParmList() As Variant)
    Dim i As Long
    Dim ListTabs() As Long
    Dim NumColumns As Long

    ReDim ListTabs(UBound(ParmList))
    For i = 0 To UBound(ParmList)
        ListTabs(i) = ParmList(i)
    Next i
    NumColumns = UBound(ParmList) + 1

    Call SendMessage(ListHandle, LB_SETTABSTOPS, _
        NumColumns, ListTabs(0))
End Sub
