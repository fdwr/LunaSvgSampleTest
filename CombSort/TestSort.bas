Attribute VB_Name = "modCallBack"
' This module was simply added because of VB's inability to handle
' callbacks in forms. You can only call functions located in modules.
' Don't bother adding any if you don't want to use callbacks; however,
' it IS polite to allow the user an opportunity to abort the process.
Option Explicit
DefLng A-Z

'Note that VB to find this DLL you must either:
' -Start it from the project (NOT open VB and then simply open the project) so
'  that the current directory points correctly. In other words, double click
'  on the VBP file.
' -Include the full path in the Lib statement below.
' -Compile the program and run that.
' -Copy the DLL to WINDOWS\SYSTEM (bad choice).

Public Declare Sub CombOrder Lib "asmorder.dll" _
   (ByRef ArrayPtr As Any, _
    ByVal ArraySize As Long, _
    ByVal CmpCb As Long, _
    ByVal EscCb As Long)
Public Declare Sub CombOrderX3 Lib "asmorder.dll" Alias "CombOrderX" _
   (ByVal TotalArrays As Long, _
    ByVal OrderArrays As Long, _
    ByVal ArraySize As Long, _
    ByVal EscCb As Long, _
    ByRef ArrayPtr1 As Any, _
    ByVal ArrayType1 As Long, _
    ByRef ArrayPtr2 As Any, _
    ByVal ArrayType2 As Long, _
    ByRef ArrayPtr3 As Any, _
    ByVal ArrayType3 As Long)

Public Const LongArraySize As Long = 10000
Public Const SingleArraySize As Long = 10000
Public Const StringArraySize As Long = 10000
Public LongArray(LongArraySize - 1) As Long
Public SingleArray(SingleArraySize - 1) As Single
Public StringArray(StringArraySize - 1) As String

Public Counter As Long             'generic counting variable
Public SubCounter As Long
Public EscCallbacks As Long        'number of callbacks (purely informative)
Public AbortSort As Boolean        'abort the sort!!

'internal DLL comparison callbacks
'A=ascending D=descending
'S=signed    U=unsigned
Public Const CmpVoid     As Long = 0  '<- does nothing (for completeness ;)
Public Const CmpReserved As Long = 1  '<- might use for variants, might not
Public Const CmpLongSA   As Long = 2  '<- 32bit signed integers
Public Const CmpLongSD   As Long = 3
Public Const CmpLongUA   As Long = 4  '<- 32bit unsigned integers
Public Const CmpLongUD   As Long = 5
Public Const CmpSngA     As Long = 6  '<- floating point singles
Public Const CmpSngD     As Long = 7
Public Const CmpStrAA    As Long = 8  '<- ASCII null terminated C strings
Public Const CmpStrAD    As Long = 9
Public Const CmpStrWA    As Long = 10 '<- Widebyte Unicode C strings
Public Const CmpStrWD    As Long = 11
Public Const CmpStrBA    As Long = 12 '<- BSTR Visual Basic 4+ strings
Public Const CmpStrBD    As Long = 13

'This callback is called each entire pass through the array
'It provides the caller a chance to show progress and check for
'messages in case the user wants to abort.
Public Function EscCallBack() As Long
    On Error Resume Next
    EscCallbacks = EscCallbacks + 1
    frmTestSort.Caption = EscCallbacks & " escape calls"
    DoEvents
    EscCallBack = AbortSort
End Function

'Simply compares two longs and returns True (that should be swapped)
'if they are not already in ascending order
Public Function CmpLongAscCb(ByRef First As Long, ByRef Second As Long) As Long
    If First > Second Then CmpLongAscCb = True
End Function

'Simply compares two singles and returns True (that should be swapped)
'if they are not already in ascending order
Public Function CmpSngAscCb(ByRef First As Single, ByRef Second As Single) As Long
    If First > Second Then CmpSngAscCb = True
End Function

'Simply compares two strings and returns True (that should be swapped)
'if they are not already in ascending order
Public Function CmpStrAscCb(ByRef First As String, ByRef Second As String) As Long
    If First > Second Then CmpStrAscCb = True
End Function
